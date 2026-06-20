//! Background power-limit autotuner for a single CUDA GPU.
//!
//! This intentionally tunes only the NVML power limit for now (not core/mem
//! clocks, not kernel selection). Power limit is the safest knob: it's
//! always within hardware/driver-enforced bounds, it can't desync a running
//! kernel, and undoing a bad value is just setting another power limit.
//! Clock-lock autotuning and kernel-variant switching can build on top of
//! this once the basic loop is proven out.
//!
//! Design notes:
//! - The autotuner runs on its own thread per GPU, with its own `Nvml`
//!   handle. It never touches the CUDA context/stream/kernel used for
//!   mining, so a failure here can't affect hashing correctness.
//! - Feedback comes from `AutotuneShared`, a small lock-free struct that the
//!   mining worker updates after every kernel launch (see `worker.rs`'s
//!   `sync()`). The autotuner reads the latest sample each tick; if it's
//!   stale (worker stalled), it skips that cycle instead of acting on bad
//!   data.
//! - Thermal safety always takes priority over the hill-climb: if temperature
//!   is at/above the configured ceiling, the autotuner drops power
//!   immediately regardless of where it was in the climb.
//! - On repeated NVML errors (e.g. insufficient permissions to set power
//!   limits), the autotuner logs a warning, disables itself for that GPU,
//!   and exits its thread. Mining continues unaffected.

use log::{error, info, warn};
use nvml_wrapper::enum_wrappers::device::TemperatureSensor;
use nvml_wrapper::Nvml;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{mpsc, Arc};
use std::thread;
use std::time::{Duration, Instant};

/// User-configured knobs for one GPU's autotuner, parsed from CLI options.
#[derive(Copy, Clone, Debug)]
pub struct AutotuneConfig {
    pub interval_secs: u64,
    pub step_w: u32,
    /// Lower bound, in watts. Falls back to the GPU's hardware minimum if unset.
    pub min_power_w: Option<u32>,
    /// Upper bound, in watts. Falls back to the GPU's hardware maximum (or to
    /// a static `--cuda-power-limits` value, if the user set one) if unset.
    pub max_power_w: Option<u32>,
    pub max_temp_c: u32,
}

/// Lock-free shared state between the mining worker thread (writer, one
/// sample per kernel launch) and the autotuner thread (reader, one sample
/// per tick). Stores only the most recent sample; the autotuner does not
/// need history to hill-climb, only "what's happening right now".
pub struct AutotuneShared {
    start: Instant,
    last_hashrate_bits: AtomicU64,
    last_sample_ms: AtomicU64,
}

impl AutotuneShared {
    pub fn new() -> Arc<Self> {
        Arc::new(Self { start: Instant::now(), last_hashrate_bits: AtomicU64::new(0), last_sample_ms: AtomicU64::new(0) })
    }

    /// Record one kernel launch's throughput. `elapsed_secs` is the wall
    /// time the kernel took for `hashes` nonces.
    pub fn record_sample(&self, hashes: f64, elapsed_secs: f64) {
        if elapsed_secs <= 0.0 || hashes <= 0.0 {
            return;
        }
        let hashrate = hashes / elapsed_secs;
        self.last_hashrate_bits.store(hashrate.to_bits(), Ordering::Relaxed);
        let now_ms = self.start.elapsed().as_millis() as u64;
        // Never store 0; that's reserved to mean "no sample yet" in `latest()`.
        self.last_sample_ms.store(now_ms.max(1), Ordering::Relaxed);
    }

    /// Returns the most recent hashrate sample (hashes/sec) and how long ago
    /// it was recorded, or `None` if no sample has been recorded yet.
    pub fn latest(&self) -> Option<(f64, Duration)> {
        let ms = self.last_sample_ms.load(Ordering::Relaxed);
        if ms == 0 {
            return None;
        }
        let hashrate = f64::from_bits(self.last_hashrate_bits.load(Ordering::Relaxed));
        let age = self.start.elapsed().saturating_sub(Duration::from_millis(ms));
        Some((hashrate, age))
    }
}

/// Handle owning the autotuner background thread. Dropping this signals the
/// thread to stop (promptly, not waiting for the next tick) and joins it.
pub struct AutotuneHandle {
    shutdown_tx: Option<mpsc::SyncSender<()>>,
    join: Option<thread::JoinHandle<()>>,
}

impl Drop for AutotuneHandle {
    fn drop(&mut self) {
        // Dropping the sender wakes the thread's recv_timeout immediately
        // with a Disconnected error, rather than waiting out the interval.
        self.shutdown_tx.take();
        if let Some(join) = self.join.take() {
            let _ = join.join();
        }
    }
}

pub fn spawn_autotuner(device_id: u32, shared: Arc<AutotuneShared>, config: AutotuneConfig) -> AutotuneHandle {
    let (tx, rx) = mpsc::sync_channel::<()>(0);
    let join = thread::Builder::new()
        .name(format!("cuda-autotune-{}", device_id))
        .spawn(move || run_autotune_loop(device_id, shared, config, rx))
        .expect("failed to spawn autotune thread");
    AutotuneHandle { shutdown_tx: Some(tx), join: Some(join) }
}

fn run_autotune_loop(device_id: u32, shared: Arc<AutotuneShared>, config: AutotuneConfig, shutdown_rx: mpsc::Receiver<()>) {
    let nvml = match Nvml::init() {
        Ok(n) => n,
        Err(e) => {
            error!("[autotune #{}] failed to init NVML, autotuning disabled for this GPU: {}", device_id, e);
            return;
        }
    };
    let mut device = match nvml.device_by_index(device_id) {
        Ok(d) => d,
        Err(e) => {
            error!("[autotune #{}] failed to open device, autotuning disabled for this GPU: {}", device_id, e);
            return;
        }
    };

    let constraints = match device.power_management_limit_constraints() {
        Ok(c) => c,
        Err(e) => {
            error!("[autotune #{}] power limit control not supported on this GPU/driver, autotuning disabled: {}", device_id, e);
            return;
        }
    };

    let mut current_limit_mw: u32 = match device.power_management_limit() {
        Ok(l) => l,
        Err(e) => {
            error!("[autotune #{}] could not read current power limit, autotuning disabled: {}", device_id, e);
            return;
        }
    };

    let hard_min_mw = config.min_power_w.map(|w| w * 1000).unwrap_or(constraints.min_limit).max(constraints.min_limit);
    let hard_max_mw = config.max_power_w.map(|w| w * 1000).unwrap_or(constraints.max_limit).min(constraints.max_limit);
    if hard_min_mw >= hard_max_mw {
        error!(
            "[autotune #{}] configured power bounds are invalid ({}..{} W after clamping to hardware limits), autotuning disabled",
            device_id,
            hard_min_mw / 1000,
            hard_max_mw / 1000
        );
        return;
    }
    let step_mw = (config.step_w.max(1) * 1000) as i64;

    let mut best_score: Option<f64> = None;
    // Start by probing downward (toward efficiency); will reverse as soon as
    // a move doesn't improve hashes/sec/watt.
    let mut direction: i64 = -step_mw;
    let mut consecutive_errors = 0u32;

    info!(
        "[autotune #{}] starting: bounds {}..{} W, step {} W, interval {}s, max temp {}C",
        device_id,
        hard_min_mw / 1000,
        hard_max_mw / 1000,
        config.step_w,
        config.interval_secs,
        config.max_temp_c
    );

    loop {
        match shutdown_rx.recv_timeout(Duration::from_secs(config.interval_secs)) {
            Ok(()) => break,
            Err(mpsc::RecvTimeoutError::Disconnected) => break,
            Err(mpsc::RecvTimeoutError::Timeout) => {}
        }

        let (hashrate, age) = match shared.latest() {
            Some(v) => v,
            None => continue, // worker hasn't completed a launch yet
        };
        if age > Duration::from_secs(config.interval_secs.saturating_mul(3).max(30)) {
            warn!("[autotune #{}] hashrate sample is {}s old, worker may be stalled; skipping this cycle", device_id, age.as_secs());
            continue;
        }

        let temp_c = match device.temperature(TemperatureSensor::Gpu) {
            Ok(t) => t,
            Err(e) => {
                warn!("[autotune #{}] failed to read temperature: {}", device_id, e);
                continue;
            }
        };

        // Safety override: always wins over the hill-climb, and resets the
        // climb's baseline since the operating point just changed for a
        // reason unrelated to efficiency.
        if temp_c >= config.max_temp_c {
            let safe_limit = hard_min_mw.max(current_limit_mw.saturating_sub(step_mw as u32));
            warn!("[autotune #{}] temp {}C >= limit {}C, dropping power to {} W", device_id, temp_c, config.max_temp_c, safe_limit / 1000);
            match device.set_power_management_limit(safe_limit) {
                Ok(()) => {
                    current_limit_mw = safe_limit;
                    best_score = None;
                }
                Err(e) => warn!("[autotune #{}] failed to apply safety power limit: {}", device_id, e),
            }
            continue;
        }

        let power_mw = match device.power_usage() {
            Ok(p) => p,
            Err(e) => {
                warn!("[autotune #{}] failed to read power usage: {}", device_id, e);
                continue;
            }
        };
        if power_mw == 0 {
            continue;
        }

        let score = hashrate / (power_mw as f64 / 1000.0); // hashes/sec/watt

        if let Some(prev) = best_score {
            if score <= prev {
                direction = -direction;
            }
        }
        best_score = Some(score);

        let proposed = current_limit_mw as i64 + direction;
        let clamped = proposed.clamp(hard_min_mw as i64, hard_max_mw as i64) as u32;

        if clamped == current_limit_mw {
            // Pinned against a bound; flip so we don't get stuck there forever.
            direction = -direction;
            continue;
        }

        match device.set_power_management_limit(clamped) {
            Ok(()) => {
                info!(
                    "[autotune #{}] {:.0} H/s @ {}W, {}C -> {:.2} H/s/W; adjusting power {}W -> {}W",
                    device_id,
                    hashrate,
                    power_mw / 1000,
                    temp_c,
                    score,
                    current_limit_mw / 1000,
                    clamped / 1000
                );
                current_limit_mw = clamped;
                consecutive_errors = 0;
            }
            Err(e) => {
                consecutive_errors += 1;
                warn!("[autotune #{}] failed to set power limit ({}): {}", device_id, consecutive_errors, e);
                if consecutive_errors >= 5 {
                    error!("[autotune #{}] disabling autotuner after repeated NVML errors (check driver permissions)", device_id);
                    break;
                }
            }
        }
    }

    info!("[autotune #{}] stopped", device_id);
}

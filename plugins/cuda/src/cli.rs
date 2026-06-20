use crate::Error;
use std::str::FromStr;

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum NonceGenEnum {
    Lean,
    Xoshiro,
}

impl FromStr for NonceGenEnum {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "lean" => Ok(Self::Lean),
            "xoshiro" => Ok(Self::Xoshiro),
            _ => Err("Unknown string".into()),
        }
    }
}

/// Selects which compiled variant of the `heavy_hash` kernel to load.
/// Only sm_70 (Volta) currently has more than one variant; every other
/// architecture ignores this and always loads its single PTX, regardless of
/// what's passed here. All variants produce identical hash output -- they
/// only differ in the __launch_bounds__ register/occupancy target the PTX
/// was compiled with. See plugins/cuda/README.md.
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum KernelVariant {
    /// The original kernel, no launch-bounds hint. Default; identical to
    /// pre-existing behavior for anyone not passing --cuda-kernel-variant.
    Baseline,
    /// Tuned for more resident blocks per SM at the cost of some
    /// per-thread register headroom.
    HighOccupancy,
    /// The most conservative register footprint of the three. Intended as
    /// a future safe-mode fallback profile; no automatic fallback-switching
    /// exists yet, so today this only takes effect if explicitly selected.
    LowRegister,
}

impl FromStr for KernelVariant {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().replace('_', "-").as_str() {
            "baseline" | "sm70-baseline" => Ok(Self::Baseline),
            "high-occupancy" | "sm70-high-occupancy" => Ok(Self::HighOccupancy),
            "low-register" | "sm70-low-register" => Ok(Self::LowRegister),
            _ => Err(format!("Unknown kernel variant '{}'. Expected one of: baseline, high-occupancy, low-register", s).into()),
        }
    }
}

impl Default for KernelVariant {
    fn default() -> Self {
        Self::Baseline
    }
}

#[cfg(feature = "overclock")]
#[derive(clap::Args, Debug, Default)]
pub struct OverClock {
    #[clap(long = "cuda-lock-mem-clocks", use_delimiter = true, help = "Lock mem clocks eg: ,810, [default: 0]")]
    pub cuda_lock_mem_clocks: Option<Vec<u32>>,
    #[clap(long = "cuda-lock-core-clocks", use_delimiter = true, help = "Lock core clocks eg: ,1200, [default: 0]")]
    pub cuda_lock_core_clocks: Option<Vec<u32>>,
    #[clap(long = "cuda-power-limits", use_delimiter = true, help = "Lock power limits eg: ,150, [default: 0]")]
    pub cuda_power_limits: Option<Vec<u32>>,

    #[clap(
        long = "cuda-autotune",
        help = "Continuously hill-climb the power limit to maximize hashes-per-watt [default: false]"
    )]
    pub cuda_autotune: bool,
    #[clap(long = "cuda-autotune-interval-secs", help = "Seconds between autotune adjustments", default_value = "15")]
    pub cuda_autotune_interval_secs: u64,
    #[clap(
        long = "cuda-autotune-power-step-watts",
        help = "Power limit step size per adjustment, in watts",
        default_value = "10"
    )]
    pub cuda_autotune_power_step_watts: u32,
    #[clap(
        long = "cuda-autotune-min-power-watts",
        use_delimiter = true,
        help = "Lower bound for autotune power limit, per GPU [default: GPU hardware minimum]"
    )]
    pub cuda_autotune_min_power_watts: Option<Vec<u32>>,
    #[clap(
        long = "cuda-autotune-max-power-watts",
        use_delimiter = true,
        help = "Upper bound for autotune power limit, per GPU [default: GPU hardware maximum, or --cuda-power-limits if set]"
    )]
    pub cuda_autotune_max_power_watts: Option<Vec<u32>>,
    #[clap(
        long = "cuda-autotune-max-temp-c",
        help = "Pause the hill-climb and drop power if GPU temperature reaches this, in Celsius",
        default_value = "83"
    )]
    pub cuda_autotune_max_temp_c: u32,
}

#[derive(clap::Args, Debug)]
pub struct CudaOpt {
    #[clap(long = "cuda-device", use_delimiter = true, help = "Which CUDA GPUs to use [default: all]")]
    pub cuda_device: Option<Vec<u16>>,
    #[clap(long = "cuda-workload", help = "Ratio of nonces to GPU possible parrallel run [default: 64]")]
    pub cuda_workload: Option<Vec<f32>>,
    #[clap(
        long = "cuda-workload-absolute",
        help = "The values given by workload are not ratio, but absolute number of nonces [default: false]"
    )]
    pub cuda_workload_absolute: bool,
    #[clap(long = "cuda-disable", help = "Disable cuda workers")]
    pub cuda_disable: bool,
    #[clap(
        long = "cuda-no-blocking-sync",
        help = "Actively wait for result. Higher CPU usage, but less red blocks. Can have lower workload.",
        long_help = "Actively wait for GPU result. Increases CPU usage, but removes delays that might result in red blocks. Can have lower workload."
    )]
    pub cuda_no_blocking_sync: bool,
    #[clap(
        long = "cuda-nonce-gen",
        help = "The random method used to generate nonces. Options: (i) xoshiro - each thread in GPU will have its own random state, creating a (pseudo-)independent xoshiro sequence (ii) lean - each GPU will have a single random nonce, and each GPU thread will work on nonce + thread id.",
        default_value = "lean"
    )]
    pub cuda_nonce_gen: NonceGenEnum,
    #[clap(
        long = "cuda-kernel-variant",
        use_delimiter = true,
        help = "Which heavy_hash kernel variant to load, per GPU. Only affects sm_70 (Volta) devices; all other architectures are unaffected regardless of this value. Options: baseline, high-occupancy, low-register [default: baseline]",
        long_help = "Which heavy_hash kernel variant to load, per GPU (comma-delimited, e.g. baseline,high-occupancy). All variants produce identical hash output -- they differ only in register/occupancy tuning. Only sm_70 (Volta) devices have more than one variant; every other architecture always loads its single PTX regardless of this flag. Options: baseline (default, identical to pre-existing behavior), high-occupancy (more resident blocks per SM), low-register (most conservative register footprint; intended as a future safe-mode profile)."
    )]
    pub cuda_kernel_variant: Option<Vec<KernelVariant>>,

    #[cfg(feature = "overclock")]
    #[clap(flatten)]
    pub overclock: OverClock,
}

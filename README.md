# Cryptix Miner (CPU & GPU)

Supports CPU and GPU mining with HTTP, Stratum Pool and Stratum Bridge support.

![cryptix-miner](https://github.com/user-attachments/assets/912d2770-8b90-4e43-bdc2-101799c47e3f)

---

## Features

- CPU and GPU mining
- Local mining via 127.0.0.1
- HTTP mining via node web address
- Stratum pool mining
- Stratum bridge support
- CUDA support (NVIDIA)
- OpenCL support (AMD / NVIDIA / Intel / iGPU)
- No dev fee (0%)

---

## Startup

The miner starts with OpenCL enabled by default for all devices (NVIDIA, AMD, Intel, iGPU).  
If OpenCL initialization fails, it automatically falls back to CUDA (NVIDIA only).

Disable OpenCL:

```
--opencl-disable
```

---

## Installation

Stratum Bridge is supported directly.  
External bridge (optional):

https://github.com/cryptix-network/cryptix-stratum-bridge

---

## Build from Source

Use Rust 1.65.0:

```
rustup install 1.65.0
rustup override set 1.65.0
```

Clone and build:

```
git clone https://github.com/cryptix-network/cryptix-miner.git
cd cryptix-miner
cargo build --release -p cryptix-miner -p cryptixcuda -p cryptixopencl
```

Alternative:

```
cargo build --release --all
```

Output:

```
target/release
```

---

## Binaries

Precompiled binaries are available here:

https://github.com/cryptix-network/cryptix-miner/releases

---

## Removing Plugins

Remove the corresponding file:

- `libcryptixcuda.so` / `libcryptixcuda.dll`
- `libcryptixopencl.so` / `libcryptixopencl.dll`

---

## Usage

Run `cryptixd` first:

https://github.com/cryptix-network/rusty-cryptix

Basic mining:

```
./cryptix-miner -s 127.0.0.1 --port 19201 --mining-address cryptix:XXXXX
```

CPU + GPU:

```
./cryptix-miner -s 127.0.0.1 --port 19201 --mining-address cryptix:XXXXX --threads 2
```

CPU only:

```
./cryptix-miner -s 127.0.0.1 --port 19201 --mining-address cryptix:XXXXX --threads 4 --cuda-disable
```

Disable OpenCL:

```
./cryptix-miner -s 127.0.0.1 --port 19201 --mining-address cryptix:XXXXX --opencl-disable
```

Pool connection:

```
./cryptix-miner -s stratum+tcp://stratum.cryptix-network.org:13095 --mining-address cryptix:XXXXX --threads 4
```

---

## Arguments

```
cryptix-miner

USAGE:
    cryptix-miner [OPTIONS] --mining-address <MINING_ADDRESS>

OPTIONS:
    -a, --mining-address <MINING_ADDRESS>
    --cuda-device <CUDA_DEVICE>
    --cuda-disable
    --cuda-lock-core-clocks <CUDA_LOCK_CORE_CLOCKS>
    --cuda-lock-mem-clocks <CUDA_LOCK_MEM_CLOCKS>
    --cuda-no-blocking-sync
    --cuda-power-limits <CUDA_POWER_LIMITS>
    --cuda-workload <CUDA_WORKLOAD>
    --cuda-workload-absolute
    -d, --debug
    --devfund-percent <DEVFUND_PERCENT>
    --experimental-amd
    -h, --help
    --mine-when-not-synced
    --nonce-gen <NONCE_GEN>
    --opencl-amd-disable
    --opencl-disable
    --opencl-device <OPENCL_DEVICE>
    --opencl-enable
    --opencl-no-amd-binary
    --opencl-platform <OPENCL_PLATFORM>
    --opencl-workload <OPENCL_WORKLOAD>
    --opencl-workload-absolute
    -p, --port <PORT>
    -s, --cryptixd-address <CRYPTIXD_ADDRESS>
    -t, --threads <NUM_THREADS>
    --testnet
```

---

## HiveOS

### Recommended Setup

- HiveOS: 0.6-229@250517
- Kernel: 6.6.60
- CUDA: 12.4
- Ubuntu: 22.04
- NVIDIA Driver: 550.144.03

No support for modified systems or hardware.

---

### HiveOS Flight Sheet

- Coin: Other (Unsupported)
- Custom Miner Name: cryptix_miner_hive_sheet_v0210
- Wallet: your wallet address
- Pool: Configure in miner
- Miner: Custom

Installation URL:

```
https://github.com/cryptix-network/cryptix-miner/releases/download/v0.2.10/cryptix_miner_hive_sheet_v0210.tar.gz
```

---

### HiveOS Shell Setup

```
mkdir cryptix
cd cryptix

wget https://github.com/cryptix-network/cryptix-miner/releases/download/v0.2.10/cryptix-miner-hiveos-v-0-2-10.tar
tar -xf cryptix-miner-hiveos-v-0-2-10.tar

cd cryptix-miner-hiveos-v-0-2-10
./cryptix-miner -s "POOL" --mining-address="WALLET" -t "THREADS"
```

---

## Compile CUDA PTX (Optional)

Example:

```
nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_80 --gpu-code=sm_80 -o plugins/cuda/resources/cryptix-cuda-sm80.ptx -Xptxas -O3 -Xcompiler -O3
```

---

## HiveOS CUDA Fix

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-6

sudo apt-get install -y nvidia-open
sudo apt-get install -y cuda-drivers
```

---

## Devfund

Default: 0%

Optional:

```
--devfund-percent=XX.YY
```

---

## Donation Addresses

Hotifx:
```
cryptix:qrjefk2r8wp607rmyvxmgjansqcwugjazpu2kk2r7057gltxetdvk8gl9fs0w
```

Elichai:
```
kaspa:qzvqtx5gkvl3tc54up6r8pk5mhuft9rtr0lvn624w9mtv4eqm9rvc9zfdmmpu
```

HauntedCook:
```
kaspa:qz4jdyu04hv4hpyy00pl6trzw4gllnhnwy62xattejv2vaj5r0p5quvns058f
```

---

## Discord

https://discord.cryptix-network.org/

---

## Credits

https://github.com/elichai/

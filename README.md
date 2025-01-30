# Cryptix-miner CPU & GPU
Supports CPU & GPU + HTTP + Stratum Pool
![cryptix-miner](https://github.com/user-attachments/assets/912d2770-8b90-4e43-bdc2-101799c47e3f)

### Supports:
- Local Mining on Node via 127.0.0.1
- HTTP Mining on Node via Webaddress
- Mining on Stratum Pools
- No Support now for Stratum Bridge
- Supports NVIDIA / CUDA
- No Support now for AMD / OPENCL


## Installation
If you have difficulties with our miner, you can also use this bridge with an external mining software:
[Cryptix Stratum Bridge](https://github.com/cryptix-network/cryptix-stratum-bridge)

### From Git Sources

If you are looking to build from the repository (for debug / extension), note that the plugins are additional
packages in the workspace. To compile a specific package, you run the following command or any subset of it

-- Use Rustup 1.65.0

rustup install 1.65.0

rustup override set 1.65.0

```sh
git clone git@github.com:cryptix-network/cryptix-miner.git
cd cryptix-miner
cargo build --release -p cryptix-miner -p cryptixcuda -p cryptixopencl
```
And, the miner (and plugins) will be in `targets/release`. You can replace the last line with
```sh
cargo build --release --all
```

### From Binaries
The [release page](https://github.com/cryptix-network/cryptix-miner/releases) includes precompiled binaries for Linux, and Windows (for the GPU version).

### Removing Plugins
To remove a plugin, you simply remove the corresponding `dll`/`so` for the directory of the miner. 

* `libcryptixcuda.so`, `libcryptixcuda.dll`: Cuda support for Cryptix-Miner
* `libcryptixopencl.so`, `libcryptixopencl.dll`: OpenCL support for Cryptix-Miner

# Usage
To start mining, you need to run [cryptixd](https://github.com/cryptix-network/rusty-cryptix) and have an address to send the rewards to.

# Hive OS
 Steps to Fix HiveOS Compatibility for Cryptix CPU & GPU Miner:

 Update HiveOS to the Latest Beta Release

 Run the Following Commands in the Terminal:

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-6

:three: Install the Required Drivers:

sudo apt-get install -y nvidia-open
sudo apt-get install -y cuda-drivers


This method has been tested successfully.

# Arguments
Help:
```
cryptix-miner 
A Cryptix high performance CPU miner

USAGE:
    cryptix-miner [OPTIONS] --mining-address <MINING_ADDRESS>

OPTIONS:
    -a, --mining-address <MINING_ADDRESS>                  The Cryptix address for the miner reward
        --cuda-device <CUDA_DEVICE>                        Which CUDA GPUs to use [default: all]
        --cuda-disable                                     Disable cuda workers
        --cuda-lock-core-clocks <CUDA_LOCK_CORE_CLOCKS>    Lock core clocks eg: ,1200, [default: 0]
        --cuda-lock-mem-clocks <CUDA_LOCK_MEM_CLOCKS>      Lock mem clocks eg: ,810, [default: 0]
        --cuda-no-blocking-sync                            Actively wait for result. Higher CPU usage, but less red blocks. Can have lower workload.
        --cuda-power-limits <CUDA_POWER_LIMITS>            Lock power limits eg: ,150, [default: 0]
        --cuda-workload <CUDA_WORKLOAD>                    Ratio of nonces to GPU possible parrallel run [default: 64]
        --cuda-workload-absolute                           The values given by workload are not ratio, but absolute number of nonces [default: false]
    -d, --debug                                            Enable debug logging level
        --devfund-percent <DEVFUND_PERCENT>                The percentage of blocks to send to the devfund (minimum 2%) [default: 2]
        --experimental-amd                                 Uses SMID instructions in AMD. Miner will crash if instruction is not supported
    -h, --help                                             Print help information
        --mine-when-not-synced                             Mine even when cryptixd says it is not synced
        --nonce-gen <NONCE_GEN>                            The random method used to generate nonces. Options: (i) xoshiro (ii) lean [default: lean]
        --opencl-amd-disable                               Disables AMD mining (does not override opencl-enable)
        --opencl-device <OPENCL_DEVICE>                    Which OpenCL GPUs to use on a specific platform
        --opencl-enable                                    Enable opencl, and take all devices of the chosen platform
        --opencl-no-amd-binary                             Disable fetching of precompiled AMD kernel (if exists)
        --opencl-platform <OPENCL_PLATFORM>                Which OpenCL platform to use (limited to one per executable)
        --opencl-workload <OPENCL_WORKLOAD>                Ratio of nonces to GPU possible parrallel run in OpenCL [default: 512]
        --opencl-workload-absolute                         The values given by workload are not ratio, but absolute number of nonces in OpenCL [default: false]
    -p, --port <PORT>                                      Cryptixd port [default: Mainnet = 19201, Testnet = 19202]
    -s, --cryptixd-address <CRYPTIXD_ADDRESS>                  The IP of the cryptixd instance [default: 127.0.0.1]
    -t, --threads <NUM_THREADS>                            Amount of CPU miner threads to launch [default: 0]
        --testnet                                          Use testnet instead of mainnet [default: false]
```

To start mining, you just need to run the following:

This will run the miner on all the available GPU devcies:

`./cryptix-miner -s 127.0.0.1 --port 19201 --mining-address cryptix:XXXXX`

This will run the miner on all the available CPU (2 Threads) and GPU devcies.

`./cryptix-miner -s 127.0.0.1 --port 19201  --mining-address cryptix:XXXXX --threads 2`

This will run the miner on the CPU (4 Threads) without CUDA GPU.

`./cryptix-miner -s 127.0.0.1 --port 19201  --mining-address cryptix:XXXXX --threads 4 --cuda-disable`


Connect a Pool:

`-s --mining-address cryptix:XXXXX stratum+tcp://stratum.cryptix-network.org:13095 --threads 4 `


## Discord

Join our discord server using the following link: [https://discord.cryptix-network.org/](https://discord.cryptix-network.org/)

# Devfund

The devfund is a fund managed by the Cryptix community in order to fund Cryptix development <br>
A miner that wants to mine higher percentage into the dev-fund can pass the following flags: <br>
`--devfund-precent=XX.YY` to mine only XX.YY% of the blocks into the devfund.

**This version automatically sets the devfund donation to the community designated address. 
Due to community decision, the minimum amount in the precompiled binaries is 1%**

# Donation Addresses
**Hotifx**: `cryptix:qrjefk2r8wp607rmyvxmgjansqcwugjazpu2kk2r7057gltxetdvk8gl9fs0w`

**Elichai**: `kaspa:qzvqtx5gkvl3tc54up6r8pk5mhuft9rtr0lvn624w9mtv4eqm9rvc9zfdmmpu`

**HauntedCook**: `kaspa:qz4jdyu04hv4hpyy00pl6trzw4gllnhnwy62xattejv2vaj5r0p5quvns058f`

## Kudos

- https://github.com/elichai/

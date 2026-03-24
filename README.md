# Cryptix-miner CPU & GPU
Supports CPU & GPU + HTTP + Stratum Pool + Stratum Bridge
![cryptix-miner](https://github.com/user-attachments/assets/912d2770-8b90-4e43-bdc2-101799c47e3f)

### Supports:
- Local Mining on Node via 127.0.0.1
- HTTP Mining on Node via Webaddress
- Mining on Stratum Pools
- Stratum Bridge Support
- Supports NVIDIA / CUDA
- OpenCL support for AMD / NVIDIA / Intel / onboard GPUs


## Installation
Stratum Bridge is supported directly. If you want to use external mining software, you can also use this bridge:
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


 Install the Required Drivers:


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
        --devfund-percent <DEVFUND_PERCENT>                The percentage of blocks to send to the devfund (0 disables devfund) [default: 0]
        --experimental-amd                                 Uses SMID instructions in AMD. Miner will crash if instruction is not supported
    -h, --help                                             Print help information
        --mine-when-not-synced                             Mine even when cryptixd says it is not synced
        --nonce-gen <NONCE_GEN>                            The random method used to generate nonces. Options: (i) xoshiro (ii) lean [default: lean]
        --opencl-amd-disable                               Disables AMD mining
        --opencl-disable                                   Disable OpenCL mining on all platforms and vendors
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

Disable OpenCL completely (AMD/NVIDIA/Intel/onboard):

`./cryptix-miner -s 127.0.0.1 --port 19201 --mining-address cryptix:XXXXX --opencl-disable`


Connect a Pool:

`-s --mining-address cryptix:XXXXX stratum+tcp://stratum.cryptix-network.org:13095 --threads 4 `

### Hive OS
This is the easiest way to get the miner running on HiveOS:

Recommended setup:
HiveOS Version: 0.6-229@250517 (latest),
Kernel: 6.6.60,
CUDA: 12.4,
Ubuntu: 22.04,
NVIDIA Driver: 550.144.03

We cannot provide support for modified HiveOS systems or rigs that do not use the recommended setup. We also cannot support modified hardware and firmware.
Via Flight Sheet

How to use HiveOS Flight sheet

Flight sheet

    Open Flight Sheets

Choose a generic coin like:

    Coin: Other (Unsupported) or without any Algo

Name:

    Custom Miner Name: cryptix_miner_hive_sheet_v0210

Wallet

    Enter your wallet address

Pool

    Choose: Configure in miner or Pool Address

Miner

    Choose: Custom
    A form with the following fields will appear

Custom miner configuration:

    Installation URL:
    https://github.com/cryptix-network/cryptix-miner/releases/download/v0.2.10/cryptix_miner_hive_sheet_v0210.tar.gz

Start it:

    Click Create Flight Sheet
    Assign it to your rig
    Start Button

sheet
OR Via Shell

Check CUDA (You need at least CUDA 12.4 - higher versions may also work. If not, switch to CUDA 12.4),
Go to the HiveOS console (important: the console, not the HiveOS flight sheets),
Use these commands one after the other in the correct order:,

Create the Folder:
mkdir cryptix
cd cryptix

Install the Miner Files:
wget https://github.com/cryptix-network/cryptix-miner/releases/download/v0.2.10/cryptix-miner-hiveos-v-0-2-10.tar
tar -xf cryptix-miner-hiveos-v-0-2-10.tar
cd cryptix-miner-hiveos-v-0-2-10

Start the Miner:
./cryptix-miner -s "xxxxxxx" --mining-address="xxxxxxxxxx" -t "x"
It is also possible to compile the PTX files for Cuda yourself from the CU file, so the CUDA file will definitely be suitable for the system.
Compile by yourself: (Rust and Cargo must be installed on the system.)
HiveOS

git clone --branch hive-os https://github.com/cryptix-network/cryptix-miner.git
cd cryptix-miner
cargo build --release
Linux

git clone https://github.com/cryptix-network/cryptix-miner.git
cd cryptix-miner
cargo build --release
Windows

git clone https://github.com/cryptix-network/cryptix-miner.git
cd cryptix-miner
cargo build --release
Compile own Cuda Files:
Linux & HiveOS

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_50 --gpu-code=sm_50 -o plugins/cuda/resources/cryptix-cuda-sm50.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_52 --gpu-code=sm_52 -o plugins/cuda/resources/cryptix-cuda-sm52.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_60 --gpu-code=sm_60 -o plugins/cuda/resources/cryptix-cuda-sm60.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_61 --gpu-code=sm_61 -o plugins/cuda/resources/cryptix-cuda-sm61.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_62 --gpu-code=sm_62 -o plugins/cuda/resources/cryptix-cuda-sm62.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_70 --gpu-code=sm_70 -o plugins/cuda/resources/cryptix-cuda-sm70.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_72 --gpu-code=sm_72 -o plugins/cuda/resources/cryptix-cuda-sm72.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_75 --gpu-code=sm_75 -o plugins/cuda/resources/cryptix-cuda-sm75.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_80 --gpu-code=sm_80 -o plugins/cuda/resources/cryptix-cuda-sm80.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_86 --gpu-code=sm_86 -o plugins/cuda/resources/cryptix-cuda-sm86.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_87 --gpu-code=sm_87 -o plugins/cuda/resources/cryptix-cuda-sm87.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_89 --gpu-code=sm_89 -o plugins/cuda/resources/cryptix-cuda-sm89.ptx -Xptxas -O3 -Xcompiler -O3

nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_90 --gpu-code=sm_90 -o plugins/cuda/resources/cryptix-cuda-sm90.ptx -Xptxas -O3 -Xcompiler -O3
Windows:

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_50 --gpu-code=sm_50 -o "plugins\cuda\resources\cryptix-cuda-sm50.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_52 --gpu-code=sm_52 -o "plugins\cuda\resources\cryptix-cuda-sm52.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_60 --gpu-code=sm_60 -o "plugins\cuda\resources\cryptix-cuda-sm60.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_61 --gpu-code=sm_61 -o "plugins\cuda\resources\cryptix-cuda-sm61.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_62 --gpu-code=sm_62 -o "plugins\cuda\resources\cryptix-cuda-sm62.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_70 --gpu-code=sm_70 -o "plugins\cuda\resources\cryptix-cuda-sm70.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_72 --gpu-code=sm_72 -o "plugins\cuda\resources\cryptix-cuda-sm72.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_75 --gpu-code=sm_75 -o "plugins\cuda\resources\cryptix-cuda-sm75.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_80 --gpu-code=sm_80 -o "plugins\cuda\resources\cryptix-cuda-sm80.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_86 --gpu-code=sm_86 -o "plugins\cuda\resources\cryptix-cuda-sm86.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_87 --gpu-code=sm_87 -o "plugins\cuda\resources\cryptix-cuda-sm87.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_89 --gpu-code=sm_89 -o "plugins\cuda\resources\cryptix-cuda-sm89.ptx" -Xptxas -O3 -Xcompiler -O3

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_90 --gpu-code=sm_90 -o "plugins\cuda\resources\cryptix-cuda-sm90.ptx" -Xptxas -O3 -Xcompiler -O3


## Discord

Join our discord server using the following link: [https://discord.cryptix-network.org/](https://discord.cryptix-network.org/)

# Devfund

The devfund is optional and defaults to 0%.
A miner that wants to mine a share into the dev-fund can pass:
`--devfund-percent=XX.YY`

# Donation Addresses
**Hotifx**: `cryptix:qrjefk2r8wp607rmyvxmgjansqcwugjazpu2kk2r7057gltxetdvk8gl9fs0w`

**Elichai**: `kaspa:qzvqtx5gkvl3tc54up6r8pk5mhuft9rtr0lvn624w9mtv4eqm9rvc9zfdmmpu`

**HauntedCook**: `kaspa:qz4jdyu04hv4hpyy00pl6trzw4gllnhnwy62xattejv2vaj5r0p5quvns058f`

## Kudos

- https://github.com/elichai/

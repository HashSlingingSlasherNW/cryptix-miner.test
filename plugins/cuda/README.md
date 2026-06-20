# Cuda Support For Cryptix-Miner

## Building

The plugin is a shared library file that resides in the same library as the miner. 
You can build the library by running
```sh
cargo build -p cryptixcuda
```

This version includes a precompiled PTX, which would work with most modern GPUs. To compile the PTX youself,
you have to clone the project:

```sh
git clone https://github.com/cryptix-network/cryptix-miner.git
cd cryptix-miner
# Compute version 8.6
/usr/local/cuda-11.5/bin/nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_86 --gpu-code=sm_86 -o plugins/cuda/resources/cryptix-cuda-sm86.ptx -Xptxas -O3 -Xcompiler -O3
# Compute version 7.5
/usr/local/cuda-11.5/bin/nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_75 --gpu-code=sm_75 -o plugins/cuda/resources/cryptix-cuda-sm75.ptx -Xptxas -O3 -Xcompiler -O3
# Compute version 6.1
/usr/local/cuda-11.2/bin/nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_61 --gpu-code=sm_61 -o plugins/cuda/resources/cryptix-cuda-sm61.ptx -Xptxas -O3 -Xcompiler -O3
# Compute version 3.0
/usr/local/cuda-9.2/bin/nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -ccbin=gcc-7 -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_30 --gpu-code=sm_30 -o plugins/cuda/resources/cryptix-cuda-sm30.ptx
# Compute version 2.0
/usr/local/cuda-8.0/bin/nvcc plugins/cuda/cryptix-cuda-native/src/cryptix-cuda.cu -ccbin=gcc-5 -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_20 --gpu-code=sm_20 -o plugins/cuda/resources/cryptix-cuda-sm20.ptx
 
cargo build --release
```

Manual build with nvcc:

nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_50 --gpu-code=sm_50 -o "plugins\cuda\resources\cryptix-cuda-sm50.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_52 --gpu-code=sm_52 -o "plugins\cuda\resources\cryptix-cuda-sm52.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_60 --gpu-code=sm_60 -o "plugins\cuda\resources\cryptix-cuda-sm60.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_61 --gpu-code=sm_61 -o "plugins\cuda\resources\cryptix-cuda-sm61.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_62 --gpu-code=sm_62 -o "plugins\cuda\resources\cryptix-cuda-sm62.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_70 --gpu-code=sm_70 -o "plugins\cuda\resources\cryptix-cuda-sm70.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_70 --gpu-code=sm_70 -DCRYPTIX_LB_THREADS=256 -DCRYPTIX_LB_BLOCKS=4 -o "plugins\cuda\resources\cryptix-cuda-sm70-high-occupancy.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_70 --gpu-code=sm_70 -DCRYPTIX_LB_THREADS=128 -DCRYPTIX_LB_BLOCKS=16 -o "plugins\cuda\resources\cryptix-cuda-sm70-low-register.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_72 --gpu-code=sm_72 -o "plugins\cuda\resources\cryptix-cuda-sm72.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_75 --gpu-code=sm_75 -o "plugins\cuda\resources\cryptix-cuda-sm75.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_80 --gpu-code=sm_80 -o "plugins\cuda\resources\cryptix-cuda-sm80.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_86 --gpu-code=sm_86 -o "plugins\cuda\resources\cryptix-cuda-sm86.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_87 --gpu-code=sm_87 -o "plugins\cuda\resources\cryptix-cuda-sm87.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_89 --gpu-code=sm_89 -o "plugins\cuda\resources\cryptix-cuda-sm89.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_90 --gpu-code=sm_90 -o "plugins\cuda\resources\cryptix-cuda-sm90.ptx" -Xptxas -O3 -Xcompiler -O3

## sm_70 (Volta) kernel variants

On sm_70 GPUs only (V100, CMP 100-210, Titan V), three pre-built `heavy_hash` kernel
variants are available, selected per GPU with `--cuda-kernel-variant`:

* `baseline` (default) -- the original kernel, no `__launch_bounds__` hint. Identical
  behavior to versions of this plugin without kernel variants.
* `high-occupancy` -- compiled with `__launch_bounds__(256, 4)`, trading some per-thread
  register headroom for more resident blocks per streaming multiprocessor.
* `low-register` -- compiled with `__launch_bounds__(128, 16)`, the most conservative
  register footprint of the three (more local-memory spillage, but the least likely to
  hit "too many resources requested for launch" on a register-constrained launch).

All three produce byte-identical hash output -- they are the same kernel body, compiled
with a different compiler hint for how many registers to target. None of the actual
hashing logic differs between them. Every architecture other than sm_70 is unaffected
by this flag and always loads its single PTX, exactly as before.

Example: `--cuda-device 0,1 --cuda-kernel-variant baseline,high-occupancy` runs GPU 0
with the original kernel and GPU 1 with the high-occupancy variant.

The two new variant PTX files are built with the same `nvcc` flags as every other
architecture in this README, plus `-DCRYPTIX_LB_THREADS` / `-DCRYPTIX_LB_BLOCKS` (see
the commands above). If you only build the default `cryptix-cuda-sm70.ptx`, the
`high-occupancy` and `low-register` options will fail to load at runtime since their
PTX files won't exist -- build all three if you intend to use them.

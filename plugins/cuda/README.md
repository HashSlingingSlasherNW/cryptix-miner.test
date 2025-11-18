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
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_72 --gpu-code=sm_72 -o "plugins\cuda\resources\cryptix-cuda-sm72.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_75 --gpu-code=sm_75 -o "plugins\cuda\resources\cryptix-cuda-sm75.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_80 --gpu-code=sm_80 -o "plugins\cuda\resources\cryptix-cuda-sm80.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_86 --gpu-code=sm_86 -o "plugins\cuda\resources\cryptix-cuda-sm86.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_87 --gpu-code=sm_87 -o "plugins\cuda\resources\cryptix-cuda-sm87.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_89 --gpu-code=sm_89 -o "plugins\cuda\resources\cryptix-cuda-sm89.ptx" -Xptxas -O3 -Xcompiler -O3
nvcc "plugins\cuda\cryptix-cuda-native\src\cryptix-cuda.cu" -std=c++11 -O3 --restrict --ptx --gpu-architecture=compute_90 --gpu-code=sm_90 -o "plugins\cuda\resources\cryptix-cuda-sm90.ptx" -Xptxas -O3 -Xcompiler -O3


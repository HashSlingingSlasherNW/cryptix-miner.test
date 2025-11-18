// Keccak-f[1600] permutation - matches CUDA implementation exactly
inline void keccakf_hash(ulong* a) {
    const ulong RC[24] = {
        0x0000000000000001UL, 0x0000000000008082UL, 0x800000000000808aUL, 0x8000000080008000UL,
        0x000000000000808bUL, 0x0000000080000001UL, 0x8000000080008081UL, 0x8000000000008009UL,
        0x000000000000008aUL, 0x0000000000000088UL, 0x0000000080008009UL, 0x000000008000000aUL,
        0x000000008000808bUL, 0x800000000000008bUL, 0x8000000000008089UL, 0x8000000000008003UL,
        0x8000000000008002UL, 0x8000000000000080UL, 0x000000000000800aUL, 0x800000008000000aUL,
        0x8000000080008081UL, 0x8000000000008080UL, 0x0000000080000001UL, 0x8000000080008008UL
    };
    
    const int rho[24] = {
        1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
        27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44
    };
    
    const int pi[24] = {
        10, 7,  11, 17, 18, 3,  5,  16, 8,  21, 24, 4,
        15, 23, 19, 13, 12, 2,  20, 14, 22, 9,  6,  1
    };
    
    for (int round = 0; round < 24; round++) {
        ulong b[5];
        ulong t;
        
        // Theta
        for (int x = 0; x < 5; x++) {
            b[x] = a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20];
        }
        for (int x = 0; x < 5; x++) {
            t = b[(x + 4) % 5] ^ rotl64(b[(x + 1) % 5], 1);
            for (int y = 0; y < 5; y++) {
                a[y * 5 + x] ^= t;
            }
        }
        
        // Rho and Pi
        t = a[1];
        for (int x = 0; x < 24; x++) {
            int j = pi[x];
            ulong temp = a[j];
            a[j] = rotl64(t, rho[x]);
            t = temp;
        }
        
        // Chi
        for (int y = 0; y < 5; y++) {
            for (int x = 0; x < 5; x++) {
                b[x] = a[y * 5 + x];
            }
            for (int x = 0; x < 5; x++) {
                a[y * 5 + x] = b[x] ^ ((~b[(x + 1) % 5]) & b[(x + 2) % 5]);
            }
        }
        
        // Iota
        a[0] ^= RC[round];
    }
}

// Hash function - matches CUDA keccak-tiny.c implementation exactly
void hash(const __constant uchar* initP, uchar* out, const uchar* in)
{
    ulong a[25];
    
    // XOR first 10 uint64_t (80 bytes) from input with initP
    for (int i = 0; i < 10; i++) {
        a[i] = ((const __constant ulong*)initP)[i] ^ ((const ulong*)in)[i];
    }
    
    // Copy remaining 15 uint64_t (120 bytes) from initP
    for (int i = 10; i < 25; i++) {
        a[i] = ((const __constant ulong*)initP)[i];
    }
    
    // Apply single keccakf permutation (NO SHA3 padding!)
    keccakf_hash(a);
    
    // Squeeze output - first 4 uint64_t (32 bytes)
    for (int i = 0; i < 4; i++) {
        ((ulong*)out)[i] = a[i];
    }
}

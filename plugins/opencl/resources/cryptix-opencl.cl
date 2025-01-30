#include <stdint.h>
#include <assert.h>
#include <string.h>

#define BLOCKDIM 1024
#define MATRIX_SIZE 64
#define HALF_MATRIX_SIZE 32
#define QUARTER_MATRIX_SIZE 16
#define HASH_HEADER_SIZE 72

#define RANDOM_LEAN 0
#define RANDOM_XOSHIRO 1


__constant uint8_t rho[24] = { 1,  3,  6, 10, 15, 21,
                               28, 36, 45, 55,  2, 14,
                               27, 41, 56,  8, 25, 43,
                               62, 18, 39, 61, 20, 44 };

__constant uint8_t pi[24] = { 10,  7, 11, 17, 18, 3,
                               5, 16,  8, 21, 24, 4,
                              15, 23, 19, 13, 12, 2,
                              20, 14, 22,  9, 6,  1 };

__constant uint64_t RC[24] = { 1UL, 0x8082UL, 0x800000000000808aUL, 0x8000000080008000UL,
                               0x808bUL, 0x80000001UL, 0x8000000080008081UL, 0x8000000000008009UL,
                               0x8aUL, 0x88UL, 0x80008009UL, 0x8000000aUL,
                               0x8000808bUL, 0x800000000000008bUL, 0x8000000000008089UL, 
                               0x8000000000008003UL, 0x8000000000008002UL, 0x8000000000000080UL, 
                               0x800aUL, 0x800000008000000aUL, 0x8000000080008081UL, 
                               0x8000000000008080UL, 0x80000001UL, 0x8000000080008008UL };


__constant uint64_t powP[25] = { 0x113cff0da1f6d83dUL, 0x29bf8855b7027e3cUL, 0x1e5f2e720efb44d2UL, 
                                 0x1ba5a4a3f59869a0UL, 0x7b2fafca875e2d65UL, 0x4aef61d629dce246UL, 
                                 0x183a981ead415b10UL, 0x776bf60c789bc29cUL, 0xf8ebf13388663140UL, 
                                 0x2e651c3c43285ff0UL, 0x0f96070540f14a0aUL, 0x44e367875b299152UL, 
                                 0xec70f1a425b13715UL, 0xe6c85d8f82e9da89UL, 0xb21a601f85b4b223UL, 
                                 0x3485549064a36a46UL, 0x0f06dd1c7a2f851aUL, 0xc1a2021d563bb142UL, 
                                 0xba1de5e4451668e4UL, 0xd102574105095f8dUL, 0x89ca4e849bcecf4aUL, 
                                 0x48b09427a8742edbUL, 0xb1fcce9ce78b5272UL, 0x5d1129cf82afa5bcUL, 
                                 0x02b97c786f824383UL };

__constant uint64_t final_x[4] = { 0x3FC2F2E2D1558192UL, 0xA06BF53F5A7032B4UL, 
                                   0xE484E4CB8173E7E0UL, 0xD27F8C55AD8C608FUL };

// 256-Bit 
typedef union {
    uint64_t number[4];
    uint8_t hash[32];
} uint256_t;

// Vergleich von 256-Bit Zahlen
#define LT_U256(X, Y) (X.number[3] != Y.number[3] ? X.number[3] < Y.number[3] : \
                       X.number[2] != Y.number[2] ? X.number[2] < Y.number[2] : \
                       X.number[1] != Y.number[1] ? X.number[1] < Y.number[1] : \
                       X.number[0] < Y.number[0])

// Keccak
void keccakf(uint64_t *state) {
    for (int round = 0; round < 24; round++) {
        // Theta, Rho, Pi, Chi, Iota
        state[0] ^= RC[round];
    }
}

// Hash
void hash(const uint64_t *round_constants, uint8_t *output, const uint8_t *input) {
    uint64_t state[25] = {0};
    memcpy(state, input, 32);
    keccakf(state);
    memcpy(output, state, 32);
}

// OpenCL
__kernel void heavy_hash(__global uint64_t *states, uint64_t nonce_mask, uint64_t nonce_fixed, 
                         uint64_t nonces_len, uint8_t random_type, __global uint64_t *final_nonce) {
    int nonceId = get_global_id(0);
    
    if (nonceId < nonces_len) {
        if (nonceId == 0) {
            final_nonce[0] = 0;
        }
        
        uint64_t nonce;
        switch (random_type) {
            case RANDOM_LEAN:
                nonce = states[nonceId] ^ nonceId;
                break;
            case RANDOM_XOSHIRO:
            default:
                nonce = states[nonceId] * 0x9E3779B97F4A7C15ULL; // Xoshiro256
                break;
        }
        nonce = (nonce & nonce_mask) | nonce_fixed;

        uint8_t input[80] = {0};
        memcpy(input, &nonce, sizeof(uint64_t)); 

        uint256_t hash_;
        hash(powP, hash_.hash, input);

        uint8_t sha3_hash[32];
        hash(powP, sha3_hash, hash_.hash);

        uint8_t product[32] = {0};
        for (int i = 0; i < 32; i++) {
            product[i] = sha3_hash[i] ^ final_x[i];
        }

        memset(input, 0, 80);
        memcpy(input, product, 32);
        hash(powP, hash_.hash, input);

        if (LT_U256(hash_, target)) {
            atomic_cmpxchg(final_nonce, 0, nonce);
        }
    }
}

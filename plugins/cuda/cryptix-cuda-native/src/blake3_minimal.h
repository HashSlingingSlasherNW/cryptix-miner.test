#pragma once

//@Credit - Optimized from https://github.com/BLAKE3-team/BLAKE3/tree/master
// Minimal BLAKE3 implementation for Cryptix mining
// @Cryptis

#include <stdint.h>
#include <stddef.h>

#define BLAKE3_KEY_LEN 32
#define BLAKE3_OUT_LEN 32
#define BLAKE3_BLOCK_LEN 64

__device__ __forceinline__ uint32_t rotr32(uint32_t w, uint32_t c)
{
    return (w >> c) | (w << (32 - c));
}

__device__ __forceinline__ uint32_t load32(const void* src)
{
    const uint8_t* p = (const uint8_t*)src;
    return ((uint32_t)(p[0]) << 0) | ((uint32_t)(p[1]) << 8) | ((uint32_t)(p[2]) << 16) |
           ((uint32_t)(p[3]) << 24);
}

__device__ __forceinline__ void store32(void* dst, uint32_t w)
{
    uint8_t* p = (uint8_t*)dst;
    p[0] = (uint8_t)(w >> 0);
    p[1] = (uint8_t)(w >> 8);
    p[2] = (uint8_t)(w >> 16);
    p[3] = (uint8_t)(w >> 24);
}

__device__ static const uint32_t IV[8] = {
    0x6A09E667UL, 0xBB67AE85UL, 0x3C6EF372UL, 0xA54FF53AUL,
    0x510E527FUL, 0x9B05688CUL, 0x1F83D9ABUL, 0x5BE0CD19UL
};

__device__ static const uint8_t MSG_SCHEDULE[7][16] = {
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    {2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8},
    {3, 4, 10, 12, 13, 2, 7, 14, 6, 5, 9, 0, 11, 15, 8, 1},
    {10, 7, 12, 9, 14, 3, 13, 15, 4, 0, 11, 2, 5, 8, 1, 6},
    {12, 13, 9, 11, 15, 10, 14, 8, 7, 2, 5, 3, 0, 1, 6, 4},
    {9, 14, 11, 5, 8, 12, 15, 1, 13, 3, 0, 10, 2, 6, 4, 7},
    {11, 15, 5, 0, 1, 9, 8, 6, 14, 10, 2, 12, 3, 4, 7, 13},
};

__device__ __forceinline__ void g(uint32_t* state, size_t a, size_t b, size_t c, size_t d, uint32_t x, uint32_t y)
{
    state[a] = state[a] + state[b] + x;
    state[d] = rotr32(state[d] ^ state[a], 16);
    state[c] = state[c] + state[d];
    state[b] = rotr32(state[b] ^ state[c], 12);
    state[a] = state[a] + state[b] + y;
    state[d] = rotr32(state[d] ^ state[a], 8);
    state[c] = state[c] + state[d];
    state[b] = rotr32(state[b] ^ state[c], 7);
}

__device__ __forceinline__ void round_fn(uint32_t state[16], const uint32_t* msg, size_t round)
{
    // Select the message schedule based on the round.
    const uint8_t* schedule = MSG_SCHEDULE[round];

    // Mix the columns.
    g(state, 0, 4, 8, 12, msg[schedule[0]], msg[schedule[1]]);
    g(state, 1, 5, 9, 13, msg[schedule[2]], msg[schedule[3]]);
    g(state, 2, 6, 10, 14, msg[schedule[4]], msg[schedule[5]]);
    g(state, 3, 7, 11, 15, msg[schedule[6]], msg[schedule[7]]);

    // Mix the rows.
    g(state, 0, 5, 10, 15, msg[schedule[8]], msg[schedule[9]]);
    g(state, 1, 6, 11, 12, msg[schedule[10]], msg[schedule[11]]);
    g(state, 2, 7, 8, 13, msg[schedule[12]], msg[schedule[13]]);
    g(state, 3, 4, 9, 14, msg[schedule[14]], msg[schedule[15]]);
}


__device__ __forceinline__ void blake3_hash_minimal(const uint8_t* input, uint8_t* output)
{
    uint32_t state[16];
    uint32_t block_words[16];
    

    #pragma unroll
    for (int i = 0; i < 8; i++) {
        block_words[i] = load32(input + 4 * i);
    }
    

    #pragma unroll
    for (int i = 8; i < 16; i++) {
        block_words[i] = 0;
    }
    
    #pragma unroll
    for (int i = 0; i < 8; i++) {
        state[i] = IV[i];
    }
    

    state[8] = IV[0];
    state[9] = IV[1];
    state[10] = IV[2];
    state[11] = IV[3];
    state[12] = 0;  // Counter low
    state[13] = 0;  // Counter high
    state[14] = BLAKE3_BLOCK_LEN;  // Block length
    state[15] = 0;  // Flags
    
    #pragma unroll
    for (int r = 0; r < 7; r++) {
        round_fn(state, block_words, r);
    }
    
    #pragma unroll
    for (int i = 0; i < 8; i++) {
        uint32_t out_word = state[i] ^ state[i + 8];
        store32(output + 4 * i, out_word);
    }
}

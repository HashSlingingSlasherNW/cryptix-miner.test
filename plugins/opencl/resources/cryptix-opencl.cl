// OpenCL not finish now - still on progress


#pragma OPENCL EXTENSION cl_khr_int64_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable

#define KECCAKF_ROUNDS 24

inline ulong rotl64(ulong x, uint y) {
    y &= 63;
    return (x << y) | (x >> ((64 - y) & 63));
}

void keccakf(__private ulong *st) {
    const ulong keccakf_rndc[24] = {
        0x0000000000000001UL, 0x0000000000008082UL, 0x800000000000808aUL,
        0x8000000080008000UL, 0x000000000000808bUL, 0x0000000080000001UL,
        0x8000000080008081UL, 0x8000000000008009UL, 0x000000000000008aUL,
        0x0000000000000088UL, 0x0000000080008009UL, 0x000000008000000aUL,
        0x000000008000808bUL, 0x800000000000008bUL, 0x8000000000008089UL,
        0x8000000000008003UL, 0x8000000000008002UL, 0x8000000000000080UL,
        0x000000000000800aUL, 0x800000008000000aUL, 0x8000000080008081UL,
        0x8000000000008080UL, 0x0000000080000001UL, 0x8000000080008008UL
    };

    const int keccakf_rotc[24] = {
        1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
        27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44
    };

    const int keccakf_piln[24] = {
        10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
        15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1
    };

    int i, j, r;
    ulong t, bc[5];

    for (r = 0; r < KECCAKF_ROUNDS; r++) {
        for (i = 0; i < 5; i++)
            bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];

        for (i = 0; i < 5; i++) {
            t = bc[(i + 4) % 5] ^ rotl64(bc[(i + 1) % 5], 1U);
            for (j = 0; j < 25; j += 5)
                st[j + i] ^= t;
        }

        t = st[1];
        for (i = 0; i < 24; i++) {
            j = keccakf_piln[i];
            bc[0] = st[j];
            st[j] = rotl64(t, (uint)keccakf_rotc[i]);
            t = bc[0];
        }

        for (j = 0; j < 25; j += 5) {
            for (i = 0; i < 5; i++)
                bc[i] = st[j + i];
            for (i = 0; i < 5; i++)
                st[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
        }

        st[0] ^= keccakf_rndc[r];
    }
}

typedef struct __attribute__((aligned(8))) {
    union {
        uchar b[200];
        ulong q[25];
    } st;
    int pt;
    int rsiz;
    int mdlen;
} sha3_ctx_t;

void sha3_init(__private sha3_ctx_t *c, int mdlen) {
    for (int i = 0; i < 25; i++)
        c->st.q[i] = 0UL;
    c->mdlen = mdlen;
    c->rsiz = 200 - 2 * mdlen;
    c->pt = 0;
}

void sha3_update(__private sha3_ctx_t *c, __private const uchar *data, uint len) {
    uint i;
    int j = c->pt;

    for (i = 0; i < len; i++) {
        c->st.b[j++] ^= data[i];
        if (j >= c->rsiz) {
            keccakf(c->st.q);
            j = 0;
        }
    }
    c->pt = j;
}

void sha3_final(__private uchar *md, __private sha3_ctx_t *c) {
    c->st.b[c->pt] ^= 0x06;
    c->st.b[c->rsiz - 1] ^= 0x80;
    keccakf(c->st.q);

    for (int i = 0; i < c->mdlen; i++)
        md[i] = c->st.b[i];
}

void sha3(__private uchar *out, uint outlen, __private const uchar *in, uint inlen) {
    __private sha3_ctx_t ctx;
    sha3_init(&ctx, (int)outlen);
    sha3_update(&ctx, in, inlen);
    sha3_final(out, &ctx);
}

void hash(__constant const uchar* initP, __private uchar* out, __private const uchar* in)
{
    __private ulong a[25];

    #pragma unroll
    for (int i = 0; i < 10; i++) {
        a[i] = (((__constant ulong*)initP)[i]) ^ (((__private ulong*)in)[i]);
    }
    
    #pragma unroll
    for (int i = 10; i < 25; i++) {
        a[i] = (((__constant ulong*)initP)[i]);
    }

    keccakf(a);
    
    #pragma unroll
    for (int i = 0; i < 4; i++) {
        ((__private ulong*)out)[i] = a[i];
    }
}

#define BLAKE3_KEY_LEN 32
#define BLAKE3_OUT_LEN 32
#define BLAKE3_BLOCK_LEN 64
#define BLAKE3_CHUNK_LEN 1024

#define CHUNK_START (1 << 0)
#define CHUNK_END (1 << 1)
#define PARENT (1 << 2)
#define ROOT (1 << 3)
#define KEYED_HASH (1 << 4)
#define DERIVE_KEY_CONTEXT (1 << 5)
#define DERIVE_KEY_MATERIAL (1 << 6)

inline uint rotr32(uint w, uint c)
{
    return (w >> c) | (w << (32 - c));
}

inline uint load32(__private const uchar* src)
{
    return ((uint)(src[0]) << 0) | ((uint)(src[1]) << 8) | ((uint)(src[2]) << 16) |
           ((uint)(src[3]) << 24);
}

inline void store32(__private uchar* dst, uint w)
{
    dst[0] = (uchar)(w >> 0);
    dst[1] = (uchar)(w >> 8);
    dst[2] = (uchar)(w >> 16);
    dst[3] = (uchar)(w >> 24);
}

__constant uint BLAKE3_IV[8] = {
    0x6A09E667U, 0xBB67AE85U, 0x3C6EF372U, 0xA54FF53AU,
    0x510E527FU, 0x9B05688CU, 0x1F83D9ABU, 0x5BE0CD19U
};

__constant uchar BLAKE3_MSG_SCHEDULE[7][16] = {
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    {2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8},
    {3, 4, 10, 12, 13, 2, 7, 14, 6, 5, 9, 0, 11, 15, 8, 1},
    {10, 7, 12, 9, 14, 3, 13, 15, 4, 0, 11, 2, 5, 8, 1, 6},
    {12, 13, 9, 11, 15, 10, 14, 8, 7, 2, 5, 3, 0, 1, 6, 4},
    {9, 14, 11, 5, 8, 12, 15, 1, 13, 3, 0, 10, 2, 6, 4, 7},
    {11, 15, 5, 0, 1, 9, 8, 6, 14, 10, 2, 12, 3, 4, 7, 13},
};

inline void blake3_g(__private uint* state, size_t a, size_t b, size_t c, size_t d, uint x, uint y)
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

inline void blake3_round_fn(__private uint state[16], __private const uint* msg, size_t round)
{
    const __constant uchar* schedule = BLAKE3_MSG_SCHEDULE[round];

    blake3_g(state, 0, 4, 8, 12, msg[schedule[0]], msg[schedule[1]]);
    blake3_g(state, 1, 5, 9, 13, msg[schedule[2]], msg[schedule[3]]);
    blake3_g(state, 2, 6, 10, 14, msg[schedule[4]], msg[schedule[5]]);
    blake3_g(state, 3, 7, 11, 15, msg[schedule[6]], msg[schedule[7]]);

    blake3_g(state, 0, 5, 10, 15, msg[schedule[8]], msg[schedule[9]]);
    blake3_g(state, 1, 6, 11, 12, msg[schedule[10]], msg[schedule[11]]);
    blake3_g(state, 2, 7, 8, 13, msg[schedule[12]], msg[schedule[13]]);
    blake3_g(state, 3, 4, 9, 14, msg[schedule[14]], msg[schedule[15]]);
}

inline void blake3_compress_in_place(__private uint cv[8], __private const uchar block[BLAKE3_BLOCK_LEN],
    uchar block_len, ulong counter, uchar flags)
{
    __private uint block_words[16];
    for (int i = 0; i < 16; i++) {
        block_words[i] = load32(block + 4 * i);
    }

    __private uint state[16];
    state[0] = cv[0];
    state[1] = cv[1];
    state[2] = cv[2];
    state[3] = cv[3];
    state[4] = cv[4];
    state[5] = cv[5];
    state[6] = cv[6];
    state[7] = cv[7];
    state[8] = BLAKE3_IV[0];
    state[9] = BLAKE3_IV[1];
    state[10] = BLAKE3_IV[2];
    state[11] = BLAKE3_IV[3];
    state[12] = (uint)counter;
    state[13] = (uint)(counter >> 32);
    state[14] = (uint)block_len;
    state[15] = (uint)flags;

    for (int r = 0; r < 7; r++) {
        blake3_round_fn(state, block_words, r);
    }

    cv[0] = state[0] ^ state[8];
    cv[1] = state[1] ^ state[9];
    cv[2] = state[2] ^ state[10];
    cv[3] = state[3] ^ state[11];
    cv[4] = state[4] ^ state[12];
    cv[5] = state[5] ^ state[13];
    cv[6] = state[6] ^ state[14];
    cv[7] = state[7] ^ state[15];
}

typedef struct __attribute__((aligned(8))) {
    uint cv[8];
    ulong chunk_counter;
    uchar buf[BLAKE3_BLOCK_LEN];
    uchar buf_len;
    uchar blocks_compressed;
    uchar flags;
} blake3_chunk_state;

typedef struct __attribute__((aligned(8))) {
    uint key[8];
    blake3_chunk_state chunk;
    uchar cv_stack_len;
    uchar cv_stack[55 * BLAKE3_OUT_LEN];
} blake3_hasher;

inline void chunk_state_init(__private blake3_chunk_state* self, __constant const uint* key, uchar flags)
{
    for (int i = 0; i < 8; i++) {
        self->cv[i] = key[i];
    }
    self->chunk_counter = 0;
    for (int i = 0; i < BLAKE3_BLOCK_LEN; i++) {
        self->buf[i] = 0;
    }
    self->buf_len = 0;
    self->blocks_compressed = 0;
    self->flags = flags;
}

inline uchar chunk_state_maybe_start_flag(__private const blake3_chunk_state* self)
{
    if (self->blocks_compressed == 0) {
        return CHUNK_START;
    } else {
        return 0;
    }
}

inline void chunk_state_update(__private blake3_chunk_state* self, __private const uchar* input, uint input_len)
{
    while (input_len > 0) {
        if (self->buf_len < BLAKE3_BLOCK_LEN) {
            uint take = BLAKE3_BLOCK_LEN - self->buf_len;
            if (take > input_len) {
                take = input_len;
            }
            for (uint i = 0; i < take; i++) {
                self->buf[self->buf_len + i] = input[i];
            }
            self->buf_len += take;
            input += take;
            input_len -= take;
        }
        
        if (self->buf_len == BLAKE3_BLOCK_LEN && input_len > 0) {
            blake3_compress_in_place(self->cv, self->buf, BLAKE3_BLOCK_LEN, self->chunk_counter,
                self->flags | chunk_state_maybe_start_flag(self));
            self->blocks_compressed += 1;
            self->buf_len = 0;
            for (int i = 0; i < BLAKE3_BLOCK_LEN; i++) {
                self->buf[i] = 0;
            }
        }
    }
}

inline void blake3_hasher_init(__private blake3_hasher* self)
{
    for (int i = 0; i < 8; i++) {
        self->key[i] = BLAKE3_IV[i];
    }
    chunk_state_init(&self->chunk, (__constant const uint*)BLAKE3_IV, 0);
    self->cv_stack_len = 0;
}

inline void blake3_hasher_update(__private blake3_hasher* self, __private const uchar* input, uint input_len)
{
    if (input_len == 0) {
        return;
    }
    
    if (self->chunk.buf_len > 0) {
        uint take = BLAKE3_BLOCK_LEN - self->chunk.buf_len;
        if (take > input_len) {
            take = input_len;
        }
        for (uint i = 0; i < take; i++) {
            self->chunk.buf[self->chunk.buf_len + i] = input[i];
        }
        self->chunk.buf_len += take;
        input += take;
        input_len -= take;
        
        if (self->chunk.buf_len == BLAKE3_BLOCK_LEN && input_len > 0) {
            uchar flags = self->chunk.flags;
            if (self->chunk.blocks_compressed == 0) {
                flags |= CHUNK_START;
            }
            blake3_compress_in_place(self->chunk.cv, self->chunk.buf, BLAKE3_BLOCK_LEN,
                                    self->chunk.chunk_counter, flags);
            self->chunk.blocks_compressed += 1;
            self->chunk.buf_len = 0;
            for (int i = 0; i < BLAKE3_BLOCK_LEN; i++) {
                self->chunk.buf[i] = 0;
            }
        }
    }
    
    while (input_len > BLAKE3_BLOCK_LEN) {
        uchar flags = self->chunk.flags;
        if (self->chunk.blocks_compressed == 0) {
            flags |= CHUNK_START;
        }
        blake3_compress_in_place(self->chunk.cv, input, BLAKE3_BLOCK_LEN,
                                self->chunk.chunk_counter, flags);
        self->chunk.blocks_compressed += 1;
        input += BLAKE3_BLOCK_LEN;
        input_len -= BLAKE3_BLOCK_LEN;
    }
    
    if (input_len > 0) {
        for (uint i = 0; i < input_len; i++) {
            self->chunk.buf[self->chunk.buf_len + i] = input[i];
        }
        self->chunk.buf_len += input_len;
    }
}

inline void blake3_hasher_finalize(__private const blake3_hasher* self, __private uchar* out, uint out_len)
{
    if (out_len == 0) {
        return;
    }
    
    uchar block_flags = self->chunk.flags | CHUNK_END;
    if (self->chunk.blocks_compressed == 0) {
        block_flags |= CHUNK_START;
    }
    
    __private uint cv[8];
    for (int i = 0; i < 8; i++) {
        cv[i] = self->chunk.cv[i];
    }
    
    blake3_compress_in_place(cv, self->chunk.buf, self->chunk.buf_len, 
                            self->chunk.chunk_counter, block_flags);
    
    for (int i = 0; i < 8 && (i * 4) < out_len; i++) {
        store32(out + 4 * i, cv[i]);
    }
}

inline void blake3_hasher_update_and_finalize(__private const uchar* input, uint input_len, __private uchar* output)
{
    __private blake3_hasher hasher;
    blake3_hasher_init(&hasher);
    blake3_hasher_update(&hasher, input, input_len);
    blake3_hasher_finalize(&hasher, output, 32);
}

typedef uchar u8;
typedef uint u32;
typedef ulong u64;
typedef long i64;

typedef u8 Hash[32];

typedef struct _uint256_t {
    u64 number[4];
} uint256_t;

inline ulong load64_le(__private const u8* p) {
    return ((ulong)p[0]) |
           ((ulong)p[1] << 8) |
           ((ulong)p[2] << 16) |
           ((ulong)p[3] << 24) |
           ((ulong)p[4] << 32) |
           ((ulong)p[5] << 40) |
           ((ulong)p[6] << 48) |
           ((ulong)p[7] << 56);
}

#define MATRIX_SIZE 64
#define HALF_MATRIX_SIZE 32
#define QUARTER_MATRIX_SIZE 16
#define HASH_HEADER_SIZE 72
#define RANDOM_LEAN 0
#define RANDOM_XOSHIRO 1
#define Plen 200

#define LT_U256(X,Y) ((X).number[3] != (Y).number[3] ? (X).number[3] < (Y).number[3] : (X).number[2] != (Y).number[2] ? (X).number[2] < (Y).number[2] : (X).number[1] != (Y).number[1] ? (X).number[1] < (Y).number[1] : (X).number[0] < (Y).number[0])

__constant u8 powP[Plen] = {
    0x3d,0xd8,0xf6,0xa1,0x0d,0xff,0x3c,0x11,0x3c,0x7e,0x02,0xb7,0x55,0x88,0xbf,0x29,
    0xd2,0x44,0xfb,0x0e,0x72,0x2e,0x5f,0x1e,0xa0,0x69,0x98,0xf5,0xa3,0xa4,0xa5,0x1b,
    0x65,0x2d,0x5e,0x87,0xca,0xaf,0x2f,0x7b,0x46,0xe2,0xdc,0x29,0xd6,0x61,0xef,0x4a,
    0x10,0x5b,0x41,0xad,0x1e,0x98,0x3a,0x18,0x9c,0xc2,0x9b,0x78,0x0c,0xf6,0x6b,0x77,
    0x40,0x31,0x66,0x88,0x33,0xf1,0xeb,0xf8,0xf0,0x5f,0x28,0x43,0x3c,0x1c,0x65,0x2e,
    0x0a,0x4a,0xf1,0x40,0x05,0x07,0x96,0x0f,0x52,0x91,0x29,0x5b,0x87,0x67,0xe3,0x44,
    0x15,0x37,0xb1,0x25,0xa4,0xf1,0x70,0xec,0x89,0xda,0xe9,0x82,0x8f,0x5d,0xc8,0xe6,
    0x23,0xb2,0xb4,0x85,0x1f,0x60,0x1a,0xb2,0x46,0x6a,0xa3,0x64,0x90,0x54,0x85,0x34,
    0x1a,0x85,0x2f,0x7a,0x1c,0xdd,0x06,0x0f,0x42,0xb1,0x3b,0x56,0x1d,0x02,0xa2,0xc1,
    0xe4,0x68,0x16,0x45,0xe4,0xe5,0x1d,0xba,0x8d,0x5f,0x09,0x05,0x41,0x57,0x02,0xd1,
    0x4a,0xcf,0xce,0x9b,0x84,0x4e,0xca,0x89,0xdb,0x2e,0x74,0xa8,0x27,0x94,0xb0,0x48,
    0x72,0x52,0x8b,0xe7,0x9c,0xce,0xfc,0xb1,0xbc,0xa5,0xaf,0x82,0xcf,0x29,0x11,0x5d,
    0x83,0x43,0x82,0x6f,0x78,0x7c,0xb9,0x02
};
__constant u8 heavyP[Plen] = {
    0x09,0x85,0x24,0xb2,0x52,0x4c,0xd7,0x3a,0x16,0x42,0x9f,0x2f,0x0e,0x9b,0x62,0x79,
    0xee,0xf8,0xc7,0x16,0x48,0xff,0x14,0x7a,0x98,0x64,0x05,0x80,0x4c,0x5f,0xa7,0x11,
    0xda,0xce,0xee,0x44,0xdf,0xe0,0x20,0xe7,0x69,0x40,0xf3,0x14,0x2e,0xd8,0xc7,0x72,
    0xba,0x35,0x89,0x93,0x2a,0xff,0x00,0xc1,0x62,0xc4,0x0f,0x25,0x40,0x90,0x21,0x5e,
    0x48,0x6a,0xcf,0x0d,0xa6,0xf9,0x39,0x80,0x0c,0x3d,0x2a,0x79,0x9f,0xaa,0xbc,0xa0,
    0x26,0xa2,0xa9,0xd0,0x5d,0xc0,0x31,0xf4,0x3f,0x8c,0xc1,0x54,0xc3,0x4c,0x1f,0xd3,
    0x3d,0xcc,0x69,0xa7,0x01,0x7d,0x6b,0x6c,0xe4,0x93,0x24,0x56,0xd3,0x5b,0xc6,0x2e,
    0x44,0xb0,0xcd,0x99,0x3a,0x4b,0xf7,0x4e,0xb0,0xf2,0x34,0x54,0x83,0x86,0x4c,0x77,
    0x16,0x94,0xbc,0x36,0xb0,0x61,0xe9,0x07,0x07,0xcc,0x65,0x77,0xb1,0x1d,0x8f,0x7e,
    0x39,0x6d,0xc4,0xba,0x80,0xdb,0x8f,0xea,0x58,0xca,0x34,0x7b,0xd3,0xf2,0x92,0xb9,
    0x57,0xb9,0x81,0x84,0x04,0xc5,0x76,0xc7,0x2e,0xc2,0x12,0x51,0x67,0x9f,0xc3,0x47,
    0x0a,0x0c,0x29,0xb5,0x9d,0x39,0xbb,0x92,0x15,0xc6,0x9f,0x2f,0x31,0xe0,0x9a,0x54,
    0x35,0xda,0xb9,0x10,0x7d,0x32,0x19,0x16
};

inline void amul4bit_row(__global const u8* row, __private const uchar4* packed_hash, __private uint *ret) {
    uint res = 0;
    for (int i = 0; i < QUARTER_MATRIX_SIZE; i++) {
        uchar4 bb = packed_hash[i];
        uchar4 aa = (uchar4)(row[4*i + 0], row[4*i + 1], row[4*i + 2], row[4*i + 3]);
        res += (uint)aa.x * (uint)bb.x;
        res += (uint)aa.y * (uint)bb.y;
        res += (uint)aa.z * (uint)bb.z;
        res += (uint)aa.w * (uint)bb.w;
    }
    *ret = res;
}

inline u32 wrapping_mul_32(u32 a, u32 b) {
    return (a * b) & 0xFFFFFFFFu;
}

inline u32 rotate_left_32(u32 value, u32 shift) {
    shift &= 31u;
    return (value << shift) | (value >> (32u - shift));
}

inline u32 rotate_right_32(u32 value, u32 shift) {
    shift &= 31u;
    return (value >> shift) | (value << (32u - shift));
}

inline u32 chaotic_random(u32 x) {
    return wrapping_mul_32(x, 362605u) ^ 0xA5A5A5A5u;
}

inline u32 memory_intensive_mix(u32 seed) {
    u32 acc = seed;
    for (int i = 0; i < 32; i++) {
        acc = wrapping_mul_32(acc, 16625u) ^ (u32)i;
    }
    return acc;
}

inline u32 recursive_fibonacci_modulated(u32 x, u8 depth) {
    u32 a = 1, b = x | 1u;
    u8 actual_depth = (depth < 8) ? depth : 8;
    for (int i = 0; i < actual_depth; i++) {
        u32 temp = b;
        b = b + (a ^ rotate_left_32(x, b % 17u));
        a = temp;
        x = rotate_right_32(x, a % 13u) ^ b;
    }
    return x;
}

inline u32 anti_fpga_hash(u32 input) {
    u32 x = input;
    u32 noise = memory_intensive_mix(x);
    u8 depth = (u8)(((noise & 0x0Fu) + 10u) & 0xFFu);
    u32 prime_factor_sum = (u32)popcount(x);
    x ^= prime_factor_sum;
    x = recursive_fibonacci_modulated(x ^ noise, depth);
    x ^= memory_intensive_mix(rotate_left_32(x, 9u));
    return x;
}


inline void compute_after_comp_product(__private const u8* pre_comp_product, __private u8* after_comp_product) {
    for (int i = 0; i < 32; i++) {
        u32 input = (u32)pre_comp_product[i] ^ ((u32)i << 8);
        u32 modified_input = chaotic_random(input % 256u);
        u32 hashed = anti_fpga_hash(modified_input);
        after_comp_product[i] = (u8)(hashed & 0xFFu);
    }
}


inline u8 rotate_left_8(u8 value, int shift) {
    shift &= 7;
    return (u8)((value << shift) | (value >> (8 - shift)));
}


inline u8 rotate_right_8(u8 value, int shift) {
    shift &= 7;
    return (u8)((value >> shift) | (value << (8 - shift)));
}


inline u64 wrapping_mul(i64 a, i64 b) {
    return (u64)((ulong)a * (ulong)b);
}

// Wrapping Add u8
inline u8 wrapping_add_8(u8 a, u8 b) {
    return (u8)((a + b) & 0xFF);
}

// Wrapping Mul u8
inline u8 wrapping_mul_8(u8 a, u8 b) {
    return (u8)((a * b) & 0xFF);
}


inline void octonion_multiply(__private const i64 *a, __private const i64 *b, __private i64 *result) {
    __private i64 res[8];

    res[0] = wrapping_mul(a[0], b[0]) - wrapping_mul(a[1], b[1]) - wrapping_mul(a[2], b[2]) - wrapping_mul(a[3], b[3]) 
             - wrapping_mul(a[4], b[4]) - wrapping_mul(a[5], b[5]) - wrapping_mul(a[6], b[6]) - wrapping_mul(a[7], b[7]);

    res[1] = wrapping_mul(a[0], b[1]) + wrapping_mul(a[1], b[0]) + wrapping_mul(a[2], b[3]) - wrapping_mul(a[3], b[2]) 
             + wrapping_mul(a[4], b[5]) - wrapping_mul(a[5], b[4]) - wrapping_mul(a[6], b[7]) + wrapping_mul(a[7], b[6]);

    res[2] = wrapping_mul(a[0], b[2]) - wrapping_mul(a[1], b[3]) + wrapping_mul(a[2], b[0]) + wrapping_mul(a[3], b[1]) 
             + wrapping_mul(a[4], b[6]) - wrapping_mul(a[5], b[7]) + wrapping_mul(a[6], b[4]) - wrapping_mul(a[7], b[5]);

    res[3] = wrapping_mul(a[0], b[3]) + wrapping_mul(a[1], b[2]) - wrapping_mul(a[2], b[1]) + wrapping_mul(a[3], b[0]) 
             + wrapping_mul(a[4], b[7]) + wrapping_mul(a[5], b[6]) - wrapping_mul(a[6], b[5]) + wrapping_mul(a[7], b[4]);

    res[4] = wrapping_mul(a[0], b[4]) - wrapping_mul(a[1], b[5]) - wrapping_mul(a[2], b[6]) - wrapping_mul(a[3], b[7]) 
             + wrapping_mul(a[4], b[0]) + wrapping_mul(a[5], b[1]) + wrapping_mul(a[6], b[2]) + wrapping_mul(a[7], b[3]);

    res[5] = wrapping_mul(a[0], b[5]) + wrapping_mul(a[1], b[4]) - wrapping_mul(a[2], b[7]) + wrapping_mul(a[3], b[6]) 
             - wrapping_mul(a[4], b[1]) + wrapping_mul(a[5], b[0]) + wrapping_mul(a[6], b[3]) + wrapping_mul(a[7], b[2]);

    res[6] = wrapping_mul(a[0], b[6]) + wrapping_mul(a[1], b[7]) + wrapping_mul(a[2], b[4]) - wrapping_mul(a[3], b[5]) 
             - wrapping_mul(a[4], b[2]) + wrapping_mul(a[5], b[3]) + wrapping_mul(a[6], b[0]) + wrapping_mul(a[7], b[1]);

    res[7] = wrapping_mul(a[0], b[7]) - wrapping_mul(a[1], b[6]) + wrapping_mul(a[2], b[5]) + wrapping_mul(a[3], b[4]) 
             - wrapping_mul(a[4], b[3]) + wrapping_mul(a[5], b[2]) + wrapping_mul(a[6], b[1]) + wrapping_mul(a[7], b[0]);

    for (int i = 0; i < 8; i++) {
        result[i] = res[i];
    }
}


inline void octonion_hash(__private const u8 *input_hash, __private i64 *oct) {
    for (int i = 0; i < 8; i++) {
        oct[i] = (i64)input_hash[i];
    }

    for (int i = 8; i < 32; i++) {
        __private i64 rotation[8];
        rotation[0] = (i64)input_hash[i % 32];
        rotation[1] = (i64)input_hash[(i + 1) % 32];
        rotation[2] = (i64)input_hash[(i + 2) % 32];
        rotation[3] = (i64)input_hash[(i + 3) % 32];
        rotation[4] = (i64)input_hash[(i + 4) % 32];
        rotation[5] = (i64)input_hash[(i + 5) % 32];
        rotation[6] = (i64)input_hash[(i + 6) % 32];
        rotation[7] = (i64)input_hash[(i + 7) % 32];
        
        __private i64 result[8];
        octonion_multiply(oct, rotation, result);
        for (int j = 0; j < 8; j++) {
            oct[j] = result[j];
        }
    }
}

inline ulong xoshiro256_next(__global ulong4 *state) {
    ulong4 s = *state;
    ulong result = rotate_left_32((uint)(s.y * 5u), 7u);
    result = (ulong)((uint)result * 9u);
    ulong t = s.y << 17;
    s.z ^= s.x;
    s.w ^= s.y;
    s.y ^= s.z;
    s.x ^= s.w;
    s.z ^= t;
    s.w = rotate_left_32((uint)s.w, 45u);
    *state = s;
    return result;
}

__kernel void heavy_hash(const ulong local_size,
                         const ulong nonce_mask,
                         const ulong nonce_fixed,
                         __global const u8 *hash_header,
                         __global const u8 *matrix,
                         __global const ulong *target,
                         uchar random_type,
                         __global ulong *states,
                         __global ulong *final_nonce,
                         __global ulong4 *final_hash) {
    size_t gid = get_global_id(0);
    ulong nonceId = (ulong)gid;
    if (gid == 0) final_nonce[0] = 0UL;
    
    ulong nonce;
    if (random_type == (uchar)RANDOM_LEAN) {
        nonce = states[0] ^ nonceId;
    } else {
        __global ulong4 *st4 = (__global ulong4 *)(states);
        nonce = xoshiro256_next(st4 + nonceId);
    }
    nonce = (nonce & nonce_mask) | nonce_fixed;
    
    __private u8 sha3_hash[32];
    __private u8 input[80];
    
    for (int i = 0; i < HASH_HEADER_SIZE; i++) {
        input[i] = hash_header[i];
    }
    
    uint256_t hash_;
    __private u8 hash_bytes[32];
    
    for (int i = 0; i < 8; i++) {
        input[HASH_HEADER_SIZE + i] = ((u8*)&nonce)[i];
    }
    
    hash((__constant u8*)powP, hash_bytes, input);
    
    // Sha3 - The first byte modulo 3, plus 1 for the range [1 - 2]
    u8 first_byte = hash_bytes[0]; 
    u8 iteration_count = (u8)((first_byte % 2) + 1);
    
    for (int i = 0; i < 32; i++) {
        sha3_hash[i] = hash_bytes[i];
    }
    
    // Iterative SHA3 process
    for (u8 it = 0; it < iteration_count; ++it) {
        sha3(sha3_hash, 32, sha3_hash, 32);  // Perform SHA3 operation on sha3_hash

        // Dynamic hash transformation based on conditions
        if (sha3_hash[1] % 4 == 0) {
            u8 repeat = (sha3_hash[2] % 4) + 1; // 1-4 iterations based on the value of byte 2
            for (u8 j = 0; j < repeat; ++j) {
                // Dynamically select the byte to modify based on a combination of hash bytes and iteration
                u8 target_byte = ((sha3_hash[1] + it) % 32);  // Dynamic byte position for XOR
                u8 xor_value = sha3_hash[it % 16] ^ 0xA5; // Dynamic XOR value based on iteration index and hash
                sha3_hash[target_byte] ^= xor_value;  // XOR on dynamically selected byte

                // Dynamically choose the byte to calculate rotation based on the current iteration
                u8 rotation_byte = sha3_hash[it % 32];  // Use different byte based on iteration index
                u8 rotation_amount = (sha3_hash[1] + sha3_hash[3]) % 4 + 2; // Combined rotation calculation

                // Perform rotation based on whether the rotation byte is even or odd
                if (rotation_byte % 2 == 0) {
                    // Rotate byte at dynamic position to the left by 'rotation_amount' positions
                    sha3_hash[target_byte] = rotate_left_8(sha3_hash[target_byte], rotation_amount);
                } else {
                    // Rotate byte at dynamic position to the right by 'rotation_amount' positions
                    sha3_hash[target_byte] = rotate_right_8(sha3_hash[target_byte], rotation_amount);
                }

                // Perform additional bitwise manipulation on the target byte using a shift
                u8 shift_amount = (sha3_hash[5] + sha3_hash[1]) % 3 + 1; // Combined shift calculation
                sha3_hash[target_byte] ^= rotate_left_8(sha3_hash[target_byte], shift_amount); // XOR with rotated value
            }
        } else if (sha3_hash[3] % 3 == 0) {
            u8 repeat = (sha3_hash[4] % 5) + 1;
            for (u8 j = 0; j < repeat; ++j) {
                u8 target_byte = ((sha3_hash[6] + it) % 32); 
                u8 xor_value = sha3_hash[it % 16] ^ 0x55;
                sha3_hash[target_byte] ^= xor_value;

                u8 rotation_byte = sha3_hash[it % 32];
                u8 rotation_amount = (sha3_hash[7] + sha3_hash[2]) % 6 + 1;
                if (rotation_byte % 2 == 0) {
                    sha3_hash[target_byte] = rotate_left_8(sha3_hash[target_byte], rotation_amount);
                } else {
                    sha3_hash[target_byte] = rotate_right_8(sha3_hash[target_byte], rotation_amount);
                }

                u8 shift_amount = (sha3_hash[1] + sha3_hash[3]) % 4 + 1; 
                sha3_hash[target_byte] ^= rotate_left_8(sha3_hash[target_byte], shift_amount);
            }
        } else if (sha3_hash[2] % 6 == 0) {
            u8 repeat = (sha3_hash[6] % 4) + 1;
            for (u8 j = 0; j < repeat; ++j) {
                u8 target_byte = ((sha3_hash[10] + it) % 32); 
                u8 xor_value = sha3_hash[it % 16] ^ 0xFF;
                sha3_hash[target_byte] ^= xor_value;

                u8 rotation_byte = sha3_hash[it % 32];  
                u8 rotation_amount = (sha3_hash[7] + sha3_hash[7]) % 7 + 1;
                if (rotation_byte % 2 == 0) {
                    sha3_hash[target_byte] = rotate_left_8(sha3_hash[target_byte], rotation_amount);
                } else {
                    sha3_hash[target_byte] = rotate_right_8(sha3_hash[target_byte], rotation_amount);
                }

                u8 shift_amount = (sha3_hash[3] + sha3_hash[5]) % 5 + 2; 
                sha3_hash[target_byte] ^= rotate_left_8(sha3_hash[target_byte], shift_amount);
            }
        } else if (sha3_hash[7] % 5 == 0) {
            u8 repeat = (sha3_hash[8] % 4) + 1;
            for (u8 j = 0; j < repeat; ++j) {
                u8 target_byte = ((sha3_hash[25] + it) % 32); 
                u8 xor_value = sha3_hash[it % 16] ^ 0x66;
                sha3_hash[target_byte] ^= xor_value;

                u8 rotation_byte = sha3_hash[it % 32]; 
                u8 rotation_amount = (sha3_hash[1] + sha3_hash[3]) % 4 + 2;
                if (rotation_byte % 2 == 0) {
                    sha3_hash[target_byte] = rotate_left_8(sha3_hash[target_byte], rotation_amount);
                } else {
                    sha3_hash[target_byte] = rotate_right_8(sha3_hash[target_byte], rotation_amount);
                }

                u8 shift_amount = (sha3_hash[1] + sha3_hash[3]) % 4 + 1; 
                sha3_hash[target_byte] ^= rotate_left_8(sha3_hash[target_byte], shift_amount);
            }
        } else if (sha3_hash[8] % 7 == 0) {
            u8 repeat = (sha3_hash[9] % 5) + 1;
            for (u8 j = 0; j < repeat; ++j) {
                u8 target_byte = ((sha3_hash[30] + it) % 32); 
                u8 xor_value = sha3_hash[it % 16] ^ 0x77; 
                sha3_hash[target_byte] ^= xor_value;

                u8 rotation_byte = sha3_hash[it % 32];  
                u8 rotation_amount = (sha3_hash[2] + sha3_hash[5]) % 5 + 1;
                if (rotation_byte % 2 == 0) {
                    sha3_hash[target_byte] = rotate_left_8(sha3_hash[target_byte], rotation_amount);
                } else {
                    sha3_hash[target_byte] = rotate_right_8(sha3_hash[target_byte], rotation_amount);
                }

                u8 shift_amount = (sha3_hash[7] + sha3_hash[9]) % 6 + 2; 
                sha3_hash[target_byte] ^= rotate_left_8(sha3_hash[target_byte], shift_amount);
            }
        }
    }

    // **Matrix Transformation**
    __private uchar4 packed_hash[QUARTER_MATRIX_SIZE];

    #pragma unroll
    for (int i = 0; i < QUARTER_MATRIX_SIZE; i++) {
        u8 h1 = sha3_hash[2 * i], h2 = sha3_hash[2 * i + 1];
        packed_hash[i] = (uchar4)((h1 >> 4), (h1 & 0xF), (h2 >> 4), (h2 & 0xF));
    }

    __private u8 product[32] = {0};
    __private u8 nibble_product[32] = {0};
    
    #pragma unroll
    for (int rowId = 0; rowId < HALF_MATRIX_SIZE; rowId++) {
        uint product1, product2, product3, product4;
        amul4bit_row(matrix + (2 * rowId) * MATRIX_SIZE, packed_hash, &product1);
        amul4bit_row(matrix + (2 * rowId + 1) * MATRIX_SIZE, packed_hash, &product2);
        amul4bit_row(matrix + (1 * rowId + 2) * MATRIX_SIZE, packed_hash, &product3);
        amul4bit_row(matrix + (1 * rowId + 3) * MATRIX_SIZE, packed_hash, &product4);

           
                // A
                uint a_nibble = (product1 & 0xF) ^ ((product2 >> 4) & 0xF) ^ ((product3 >> 8) & 0xF) 
                                ^ ((wrapping_mul_32(product1, 0xABCD) >> 12) & 0xF) 
                                ^ ((wrapping_mul_32(product1, 0x1234) >> 8) & 0xF)
                                ^ ((wrapping_mul_32(product2, 0x5678) >> 16) & 0xF)
                                ^ ((wrapping_mul_32(product3, 0x9ABC) >> 4) & 0xF)
                                ^ ((rotate_left_32(product1, 3) & 0xF) ^ (rotate_right_32(product3, 5) & 0xF));

                // B
                uint b_nibble = (product2 & 0xF) ^ ((product1 >> 4) & 0xF) ^ ((product4 >> 8) & 0xF) 
                                ^ ((wrapping_mul_32(product2, 0xDCBA) >> 14) & 0xF)
                                ^ ((wrapping_mul_32(product2, 0x8765) >> 10) & 0xF) 
                                ^ ((wrapping_mul_32(product1, 0x4321) >> 6) & 0xF)
                                ^ ((rotate_left_32(product4, 2) ^ rotate_right_32(product1, 1)) & 0xF);

                // C
                uint c_nibble = (product3 & 0xF) ^ ((product2 >> 4) & 0xF) ^ ((product2 >> 8) & 0xF) 
                                ^ ((wrapping_mul_32(product3, 0xF135) >> 10) & 0xF)
                                ^ ((wrapping_mul_32(product3, 0x2468) >> 12) & 0xF) 
                                ^ ((wrapping_mul_32(product4, 0xACEF) >> 8) & 0xF)
                                ^ ((wrapping_mul_32(product2, 0x1357) >> 4) & 0xF)
                                ^ ((rotate_left_32(product3, 5) & 0xF) ^ (rotate_right_32(product1, 7) & 0xF));

                // D
                uint d_nibble = (product1 & 0xF) ^ ((product4 >> 4) & 0xF) ^ ((product1 >> 8) & 0xF)
                                ^ ((wrapping_mul_32(product4, 0x57A3) >> 6) & 0xF)
                                ^ ((wrapping_mul_32(product3, 0xD4E3) >> 12) & 0xF)
                                ^ ((wrapping_mul_32(product1, 0x9F8B) >> 10) & 0xF)
                                ^ ((rotate_left_32(product4, 4) ^ (product1 + product2)) & 0xF);

        // Store in product array
        product[rowId] = (u8)((a_nibble << 4) | b_nibble);
   
        // Store in nibble_product array
        nibble_product[rowId] = (u8)((c_nibble << 4) | d_nibble);
    }
    
    __private u8 product_before_oct[32]; 

    // XOR the product with the original hash   
    #pragma unroll
    for (int i = 0; i < 32; i++) {
        product[i] ^= sha3_hash[i];
        product_before_oct[i] = product[i];
    }

    // XOR the nibble_product with the original hash   
    #pragma unroll
    for (int i = 0; i < 32; i++) {
        nibble_product[i] ^= sha3_hash[i];
    }

    // ** Octonion**
    __private i64 octonion_result[8];
    octonion_hash(product, octonion_result);

    #pragma unroll
    for (int i = 0; i < 32; i++) {
        i64 oct_value = octonion_result[i / 8];
    
        u8 oct_value_u8 = (u8)((oct_value >> (8 * (i % 8))) & 0xFF);
    
        product[i] ^= oct_value_u8;
    }

    // **Non-Linear S-Box**
    __private u8 sbox[256];

    for (int i = 0; i < 256; i++) {
        u8 i_u8 = (u8)i;
    
        __private u8* source_array;
        u8 rotate_left_val, rotate_right_val;
    
        if (i_u8 < 16) { source_array = product; rotate_left_val = ((nibble_product[3] ^ 0x4F) * 3) % 256; rotate_right_val = ((sha3_hash[2] ^ 0xD3) * 5) % 256; }
        else if (i_u8 < 32) { source_array = sha3_hash; rotate_left_val = ((product[7] ^ 0xA6) * 2) % 256; rotate_right_val = ((nibble_product[5] ^ 0x5B) * 7) % 256; }
        else if (i_u8 < 48) { source_array = nibble_product; rotate_left_val = ((product_before_oct[1] ^ 0x9C) * 9) % 256; rotate_right_val = ((product[0] ^ 0x8E) * 3) % 256; }
        else if (i_u8 < 64) { source_array = sha3_hash; rotate_left_val = ((product[6] ^ 0x71) * 4) % 256; rotate_right_val = ((product_before_oct[3] ^ 0x2F) * 5) % 256; }
        else if (i_u8 < 80) { source_array = product_before_oct; rotate_left_val = ((nibble_product[4] ^ 0xB2) * 3) % 256; rotate_right_val = ((sha3_hash[7] ^ 0x6D) * 7) % 256; }
        else if (i_u8 < 96) { source_array = sha3_hash; rotate_left_val = ((product[0] ^ 0x58) * 6) % 256; rotate_right_val = ((nibble_product[1] ^ 0xEE) * 9) % 256; }
        else if (i_u8 < 112) { source_array = product; rotate_left_val = ((product_before_oct[2] ^ 0x37) * 2) % 256; rotate_right_val = ((sha3_hash[6] ^ 0x44) * 6) % 256; }
        else if (i_u8 < 128) { source_array = sha3_hash; rotate_left_val = ((product[5] ^ 0x1A) * 5) % 256; rotate_right_val = ((sha3_hash[4] ^ 0x7C) * 8) % 256; }
        else if (i_u8 < 144) { source_array = product_before_oct; rotate_left_val = ((nibble_product[3] ^ 0x93) * 7) % 256; rotate_right_val = ((product[2] ^ 0xAF) * 3) % 256; }
        else if (i_u8 < 160) { source_array = sha3_hash; rotate_left_val = ((product[7] ^ 0x29) * 9) % 256; rotate_right_val = ((nibble_product[5] ^ 0xDC) * 2) % 256; }
        else if (i_u8 < 176) { source_array = nibble_product; rotate_left_val = ((product_before_oct[1] ^ 0x4E) * 4) % 256; rotate_right_val = ((sha3_hash[0] ^ 0x8B) * 3) % 256; }
        else if (i_u8 < 192) { source_array = sha3_hash; rotate_left_val = ((nibble_product[6] ^ 0xF3) * 5) % 256; rotate_right_val = ((product_before_oct[3] ^ 0x62) * 8) % 256; }
        else if (i_u8 < 208) { source_array = product_before_oct; rotate_left_val = ((product[4] ^ 0xB7) * 6) % 256; rotate_right_val = ((product[7] ^ 0x15) * 2) % 256; }
        else if (i_u8 < 224) { source_array = sha3_hash; rotate_left_val = ((product[0] ^ 0x2D) * 8) % 256; rotate_right_val = ((product_before_oct[1] ^ 0xC8) * 7) % 256; }
        else if (i_u8 < 240) { source_array = product; rotate_left_val = ((product_before_oct[2] ^ 0x6F) * 3) % 256; rotate_right_val = ((nibble_product[6] ^ 0x99) * 9) % 256; }
        else { source_array = sha3_hash; rotate_left_val = ((nibble_product[5] ^ 0xE1) * 7) % 256; rotate_right_val = ((sha3_hash[4] ^ 0x3B) * 5) % 256; }
                        
        u8 value = 
            (i_u8 < 16) ? (u8)((product[i_u8 % 32] * 0x03 + i_u8 * 0xAA) & 0xFF) :
            (i_u8 < 32) ? (u8)((sha3_hash[(i_u8 - 16) % 32] * 0x05 + (i_u8 - 16) * 0xBB) & 0xFF) :
            (i_u8 < 48) ? (u8)((product_before_oct[(i_u8 - 32) % 32] * 0x07 + (i_u8 - 32) * 0xCC) & 0xFF) :
            (i_u8 < 64) ? (u8)((nibble_product[(i_u8 - 48) % 32] * 0x0F + (i_u8 - 48) * 0xDD) & 0xFF) :
            (i_u8 < 80) ? (u8)((product[(i_u8 - 64) % 32] * 0x11 + (i_u8 - 64) * 0xEE) & 0xFF) :
            (i_u8 < 96) ? (u8)((sha3_hash[(i_u8 - 80) % 32] * 0x13 + (i_u8 - 80) * 0xFF) & 0xFF) :
            (i_u8 < 112) ? (u8)((product_before_oct[(i_u8 - 96) % 32] * 0x17 + (i_u8 - 96) * 0x11) & 0xFF) :
            (i_u8 < 128) ? (u8)((nibble_product[(i_u8 - 112) % 32] * 0x19 + (i_u8 - 112) * 0x22) & 0xFF) :
            (i_u8 < 144) ? (u8)((product[(i_u8 - 128) % 32] * 0x1D + (i_u8 - 128) * 0x33) & 0xFF) :
            (i_u8 < 160) ? (u8)((sha3_hash[(i_u8 - 144) % 32] * 0x1F + (i_u8 - 144) * 0x44) & 0xFF) :
            (i_u8 < 176) ? (u8)((product_before_oct[(i_u8 - 160) % 32] * 0x23 + (i_u8 - 160) * 0x55) & 0xFF) :
            (i_u8 < 192) ? (u8)((nibble_product[(i_u8 - 176) % 32] * 0x29 + (i_u8 - 176) * 0x66) & 0xFF) :
            (i_u8 < 208) ? (u8)((product[(i_u8 - 192) % 32] * 0x2F + (i_u8 - 192) * 0x77) & 0xFF) :
            (i_u8 < 224) ? (u8)((sha3_hash[(i_u8 - 208) % 32] * 0x31 + (i_u8 - 208) * 0x88) & 0xFF) :
            (i_u8 < 240) ? (u8)((product_before_oct[(i_u8 - 224) % 32] * 0x37 + (i_u8 - 224) * 0x99) & 0xFF) :
                           (u8)((nibble_product[(i_u8 - 240) % 32] * 0x3F + (i_u8 - 240) * 0xAA) & 0xFF);
   
        int rotate_left_shift = (product[(i + 1) % 32] + i) % 8;
        int rotate_right_shift = (sha3_hash[(i + 2) % 32] + i) % 8;
    
        int rotation_left = (rotate_left_val << rotate_left_shift) | (rotate_left_val >> (8 - rotate_left_shift));
        int rotation_right = (rotate_right_val >> rotate_right_shift) | (rotate_right_val << (8 - rotate_right_shift));
    
        rotation_left &= 0xFF;
        rotation_right &= 0xFF;
    
        int index = (i + rotation_left + rotation_right) % 32;
        sbox[i] = source_array[index] ^ value;
    }
    
    // Update Sbox Values
    size_t index = ((size_t)product_before_oct[2] % 8) + 1;  
    int iterations = 1 + (product[index] % 2);            

    __private u8 temp_sbox[256];

    #pragma unroll
    for (int iter = 0; iter < iterations; iter++) {
        for (int i = 0; i < 256; i++) {
            temp_sbox[i] = sbox[i];
        }

        for (int i = 0; i < 256; i++) {
            u8 value = temp_sbox[i];

            u8 rotate_left_shift = (product[(i + 1) % 32] + i + (i * 3)) % 8;
            u8 rotate_right_shift = (sha3_hash[(i + 2) % 32] + i + (i * 5)) % 8;

            u8 rotated_value = rotate_left_8(value, rotate_left_shift) | rotate_right_8(value, rotate_right_shift);

            u8 base_value = (u8)((i + (product[(i * 3) % 32] ^ sha3_hash[(i * 7) % 32])) & 0xFF) ^ 0xA5;
            u8 shifted_value = rotate_left_8(base_value, (u32)(i % 8));
            u8 xor_value = shifted_value ^ 0x55;

            value ^= rotated_value ^ xor_value;

            temp_sbox[i] = value;
        }

        for (int i = 0; i < 256; i++) {
            sbox[i] = temp_sbox[i];
        }
    }

    // Anti FPGA Sidedoor
    __private u8 after_comp_product[32];
    compute_after_comp_product(product, after_comp_product);

    // Blake3 Chaining - using proper hasher like CUDA
    size_t index_blake = ((size_t)product_before_oct[5] % 8) + 1;  
    int iterations_blake = 1 + (product[index_blake] % 3);            

    __private u8 product_blake3[32];  
    for (int i = 0; i < 32; i++) {
        product_blake3[i] = product[i];
    }

    #pragma unroll
    for (int iter = 0; iter < iterations_blake; iter++) {
        __private u8 temp_blake3[32];
        blake3_hasher_update_and_finalize(product_blake3, 32, temp_blake3);
        
        for (int i = 0; i < 32; i++) {
            product_blake3[i] = temp_blake3[i];
        }
    }

    // **Apply S-Box**
    #pragma unroll
    for (int i = 0; i < 32; i++) {
        int array_selector = (i * 31) % 4;
        __private const u8* ref_array;

        switch (array_selector) {
            case 0: ref_array = nibble_product; break;
            case 1: ref_array = sha3_hash; break;
            case 2: ref_array = product; break;
            default: ref_array = product_before_oct; break;
        }

        int byte_val = ref_array[(i * 13) % 32];  

        int idx = (byte_val 
                    + product[(i * 31) % 32] 
                    + sha3_hash[(i * 19) % 32] 
                    + i * 41) % 256;  

        product_blake3[i] ^= sbox[idx];
    }

    // Final XOR 
    #pragma unroll
    for (int i = 0; i < 32; i++) {
        product_blake3[i] ^= after_comp_product[i];
    }

    for (int i = 0; i < 80; i++) {
        input[i] = 0;
    }
    for (int i = 0; i < 32; i++) {
        input[i] = product_blake3[i];
    }
    hash((__constant u8*)heavyP, hash_bytes, input);

    hash_.number[0] = load64_le(&hash_bytes[0]);
    hash_.number[1] = load64_le(&hash_bytes[8]);
    hash_.number[2] = load64_le(&hash_bytes[16]);
    hash_.number[3] = load64_le(&hash_bytes[24]);
    
    uint256_t tgt;
    tgt.number[0] = target[0];
    tgt.number[1] = target[1];
    tgt.number[2] = target[2];
    tgt.number[3] = target[3];
    
    if (LT_U256(hash_, tgt)) {
        atom_cmpxchg(final_nonce, 0UL, nonce);
    }
}

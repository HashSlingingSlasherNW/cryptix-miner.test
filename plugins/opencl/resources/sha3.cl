// Cryptix sha3.cl - OpenCL implementation of SHA3 functions

// Constants
#define KECCAKF_ROUNDS 24

// Keccak-f permutation
void keccakf(ulong st[25])
{
    // Constants
    __constant ulong keccakf_rndc[24] = {
        0x0000000000000001UL, 0x0000000000008082UL, 0x800000000000808aUL,
        0x8000000080008000UL, 0x000000000000808bUL, 0x0000000080000001UL,
        0x8000000080008081UL, 0x8000000000008009UL, 0x000000000000008aUL,
        0x0000000000000088UL, 0x0000000080008009UL, 0x000000008000000aUL,
        0x000000008000808bUL, 0x800000000000008bUL, 0x8000000000008089UL,
        0x8000000000008003UL, 0x8000000000008002UL, 0x8000000000000080UL,
        0x000000000000800aUL, 0x800000008000000aUL, 0x8000000080008081UL,
        0x8000000000008080UL, 0x0000000080000001UL, 0x8000000080008008UL
    };
    
    __constant int keccakf_rotc[24] = {
        1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
        27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44
    };
    
    __constant int keccakf_piln[24] = {
        10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
        15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1
    };

    // Variables
    int i, j, r;
    ulong t, bc[5];

    // Actual iteration
    for (r = 0; r < KECCAKF_ROUNDS; r++) {
        // Theta
        for (i = 0; i < 5; i++)
            bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];

        for (i = 0; i < 5; i++) {
            t = bc[(i + 4) % 5] ^ rotate(bc[(i + 1) % 5], 1UL);
            for (j = 0; j < 25; j += 5)
                st[j + i] ^= t;
        }

        // Rho Pi
        t = st[1];
        for (i = 0; i < 24; i++) {
            j = keccakf_piln[i];
            bc[0] = st[j];
            st[j] = rotate(t, (ulong)keccakf_rotc[i]);
            t = bc[0];
        }

        // Chi
        for (j = 0; j < 25; j += 5) {
            for (i = 0; i < 5; i++)
                bc[i] = st[j + i];
            for (i = 0; i < 5; i++)
                st[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
        }

        // Iota
        st[0] ^= keccakf_rndc[r];
    }
}

// SHA3 context
typedef struct {
    union {
        uchar b[200];
        ulong q[25];
    } st;
    int pt, rsiz, mdlen;
} sha3_ctx_t;

// Initialize the SHA3 context
void sha3_init(sha3_ctx_t *c, int mdlen)
{
    for (int i = 0; i < 25; i++)
        c->st.q[i] = 0;
    c->mdlen = mdlen;
    c->rsiz = 200 - 2 * mdlen;
    c->pt = 0;
}

// Update state with more data
void sha3_update(sha3_ctx_t *c, const uchar *data, size_t len)
{
    size_t i;
    int j;

    j = c->pt;
    for (i = 0; i < len; i++) {
        c->st.b[j++] ^= data[i];
        if (j >= c->rsiz) {
            keccakf(c->st.q);
            j = 0;
        }
    }
    c->pt = j;
}

// Finalize and output a hash
void sha3_final(uchar *md, sha3_ctx_t *c)
{
    c->st.b[c->pt] ^= 0x06;
    c->st.b[c->rsiz - 1] ^= 0x80;
    keccakf(c->st.q);

    for (int i = 0; i < c->mdlen; i++) {
        md[i] = c->st.b[i];
    }
}

// Compute a SHA-3 hash (md) of given byte length from "in"
void sha3(uchar *out, uint outlen, const uchar *in, uint inlen)
{
    sha3_ctx_t sha3;

    sha3_init(&sha3, outlen);
    sha3_update(&sha3, in, inlen);
    sha3_final(out, &sha3);
}

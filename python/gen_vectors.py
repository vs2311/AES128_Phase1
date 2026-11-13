"""
gen_vectors.py : Generates test vectors for the Verilog testbench.

Writes  ../tb/test_vectors.mem   (read by tb_aes128_core.v with $readmemh)
        ../results/expected_vectors.csv  (same vectors in a readable table)

Each vector = 3 lines in the .mem file: key, plaintext, expected ciphertext.
The first two vectors are the official NIST FIPS-197 examples; the rest are
random (fixed seed, so every run gives the same file).

If the 'cryptography' package is installed, every vector is also cross-checked
against an independent AES implementation.

Usage:  python gen_vectors.py [number_of_random_vectors]   (default 100)
"""
import os
import random
import sys

from aes_ref import encrypt, hx

HERE = os.path.dirname(os.path.abspath(__file__))
TB_DIR = os.path.join(HERE, "..", "tb")
RES_DIR = os.path.join(HERE, "..", "results")

FIPS = [
    # FIPS-197 Appendix B
    (0x2b7e151628aed2a6abf7158809cf4f3c, 0x3243f6a8885a308d313198a2e0370734,
     0x3925841d02dc09fbdc118597196a0b32),
    # FIPS-197 Appendix C.1
    (0x000102030405060708090a0b0c0d0e0f, 0x00112233445566778899aabbccddeeff,
     0x69c4e0d86a7b0430d8cdb78070b4c55a),
]


def cross_check(key, pt, ct):
    try:
        from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    except ImportError:
        return None
    enc = Cipher(algorithms.AES(key.to_bytes(16, "big")), modes.ECB()).encryptor()
    ref = int.from_bytes(enc.update(pt.to_bytes(16, "big")) + enc.finalize(), "big")
    return ref == ct


def main():
    n_rand = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    rng = random.Random(2026)
    vectors = []
    for key, pt, ct in FIPS:
        assert encrypt(key, pt) == ct, "Python model fails FIPS-197 example!"
        vectors.append((key, pt, ct))
    for _ in range(n_rand):
        key, pt = rng.getrandbits(128), rng.getrandbits(128)
        vectors.append((key, pt, encrypt(key, pt)))

    checked = [cross_check(*v) for v in vectors]
    if None not in checked:
        assert all(checked), "Mismatch against 'cryptography' library!"
        print(f"Cross-checked all {len(vectors)} vectors against 'cryptography': OK")
    else:
        print("('cryptography' not installed: skipped independent cross-check)")

    os.makedirs(TB_DIR, exist_ok=True)
    os.makedirs(RES_DIR, exist_ok=True)
    with open(os.path.join(TB_DIR, "test_vectors.mem"), "w") as f:
        for key, pt, ct in vectors:
            f.write(f"{hx(key)}\n{hx(pt)}\n{hx(ct)}\n")
    with open(os.path.join(RES_DIR, "expected_vectors.csv"), "w") as f:
        f.write("index,key,plaintext,expected_ciphertext\n")
        for i, (key, pt, ct) in enumerate(vectors):
            f.write(f"{i},{hx(key)},{hx(pt)},{hx(ct)}\n")
    print(f"Wrote {len(vectors)} vectors ({len(FIPS)} FIPS + {n_rand} random)")
    print("  tb/test_vectors.mem")
    print("  results/expected_vectors.csv")
    print(f"NUM_VECTORS for the testbench = {len(vectors)}")


if __name__ == "__main__":
    main()

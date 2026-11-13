"""
avalanche.py : Avalanche-effect analysis of AES-128 (for the progress report).

Flips ONE plaintext bit (and separately one key bit) and counts how many of the
128 ciphertext bits change. A good cipher changes ~64 bits (50%) on average.
Also shows how the difference spreads round by round.

Needs: matplotlib (pip install matplotlib)
Output: ../results/avalanche_histogram.png, ../results/avalanche_by_round.png,
        ../results/avalanche_summary.txt
"""
import os
import random
import statistics

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from aes_ref import encrypt

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "results")
os.makedirs(RES, exist_ok=True)

N = 2000
rng = random.Random(7)
pt_flip, key_flip = [], []
by_round = [[] for _ in range(11)]

for _ in range(N):
    key, pt = rng.getrandbits(128), rng.getrandbits(128)
    bit = 1 << rng.randrange(128)
    ct, rows_a = encrypt(key, pt, trace=True)
    ct2, rows_b = encrypt(key, pt ^ bit, trace=True)
    pt_flip.append(bin(ct ^ ct2).count("1"))
    for r in range(11):
        by_round[r].append(bin(rows_a[r][2] ^ rows_b[r][2]).count("1"))
    ct3 = encrypt(key ^ (1 << rng.randrange(128)), pt)
    key_flip.append(bin(ct ^ ct3).count("1"))

mean_pt, sd_pt = statistics.mean(pt_flip), statistics.pstdev(pt_flip)
mean_k, sd_k = statistics.mean(key_flip), statistics.pstdev(key_flip)
round_means = [statistics.mean(x) for x in by_round]

# ---- Figure 1: histogram ----
fig, ax = plt.subplots(figsize=(7, 4))
bins = range(35, 95)
ax.hist(pt_flip, bins=bins, alpha=0.75, label=f"1 plaintext bit flipped (mean {mean_pt:.1f})")
ax.hist(key_flip, bins=bins, alpha=0.55, label=f"1 key bit flipped (mean {mean_k:.1f})")
ax.axvline(64, color="k", ls="--", lw=1)
ax.text(64.5, ax.get_ylim()[1] * 0.92, "64 = ideal (50%)", fontsize=9)
ax.set_xlabel("Ciphertext bits changed (out of 128)")
ax.set_ylabel(f"Count ({N} random trials)")
ax.set_title("AES-128 avalanche effect")
ax.legend(frameon=False, fontsize=9)
fig.tight_layout()
fig.savefig(os.path.join(RES, "avalanche_histogram.png"), dpi=150)

# ---- Figure 2: diffusion per round ----
fig, ax = plt.subplots(figsize=(7, 4))
ax.plot(range(11), round_means, marker="o")
ax.axhline(64, color="k", ls="--", lw=1)
ax.set_xticks(range(11))
ax.set_xlabel("After round")
ax.set_ylabel("Mean state bits different")
ax.set_ylim(0, 75)
ax.set_title("Diffusion of a 1-bit plaintext change through the rounds")
for r in (0, 1, 2):
    ax.annotate(f"{round_means[r]:.1f}", (r, round_means[r]), textcoords="offset points",
                xytext=(6, -12), fontsize=8)
fig.tight_layout()
fig.savefig(os.path.join(RES, "avalanche_by_round.png"), dpi=150)

with open(os.path.join(RES, "avalanche_summary.txt"), "w") as f:
    f.write(f"Trials: {N}\n")
    f.write(f"1-bit plaintext change: mean {mean_pt:.2f} bits ({mean_pt/1.28:.2f}%), std {sd_pt:.2f}\n")
    f.write(f"1-bit key change      : mean {mean_k:.2f} bits ({mean_k/1.28:.2f}%), std {sd_k:.2f}\n")
    f.write("Mean differing state bits after each round:\n")
    for r, m in enumerate(round_means):
        f.write(f"  round {r:2d}: {m:6.2f}\n")
print(open(os.path.join(RES, "avalanche_summary.txt")).read())

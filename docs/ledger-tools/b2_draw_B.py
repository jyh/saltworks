#!/usr/bin/env python3
"""b2_draw_B.py — EXECUTE the draw that was pre-registered before it existed.

ORDERING IS THE WHOLE POINT AND IT IS ENFORCED, NOT TRUSTED.
The rule (k, the index formula, the ordering) was fixed and PUBLISHED in
docs/compiler-B2-POOL-B-PREREG-0816.txt BEFORE any index was computed. This script
re-derives the pool from first principles, REFUSES unless it matches the published
hash, and only then applies the published rule. A draw derived after seeing the
population is worth nothing; a draw whose population is verified against a
pre-published hash cannot have been shopped.

⛔ THIS SCRIPT TAKES NO PARAMETERS. There is nothing to tune, which is the property
that makes it worth running: k and the formula come from the pre-registration, not
from a flag, so there is no knob to turn until the answer looks better.

The drawn ids ARE B-2 substance. They go to a committed artifact. Any bus line about
this run is a POINTER -- see b2_headline_fence.sh, which is fail-closed by default.
"""
import subprocess, sys, pathlib, hashlib, re

HERE = pathlib.Path(__file__).resolve()
DOCS = HERE.parents[1]
PREREG = DOCS / "compiler-B2-POOL-B-PREREG-0816.txt"
POOLSCRIPT = HERE.parent / "b2_pool_B.py"

def die(m):
    print(f"b2_draw_B: REFUSING -- {m}", file=sys.stderr); sys.exit(2)

for p in (PREREG, POOLSCRIPT):
    if not p.is_file():
        die(f"input not found: {p}")

# (1) THE PRE-REGISTERED RULE, read FROM the published file rather than restated here.
#     Restating it in this script would let the two drift, and the published one is
#     the one that was witnessed.
pre = PREREG.read_text()
m_k = re.search(r"k\s*=\s*(\d+)", pre)
m_n = re.search(r"where\s+N\s*=\s*(\d+)", pre)
m_sha = re.search(r"pool sha256/16\s*=\s*([0-9a-f]{16})", pre)
if not (m_k and m_n and m_sha):
    die("pre-registration does not carry k, N and the pool hash in the expected form")
K, N_PRE, SHA_PRE = int(m_k.group(1)), int(m_n.group(1)), m_sha.group(1)
print(f"b2_draw_B: pre-registration says k={K} · N={N_PRE} · pool sha256/16={SHA_PRE}")

# (2) RE-DERIVE THE POOL. Not read from the artifact -- recomputed from the same
#     inputs, so a corrupted artifact cannot silently define the draw.
res = subprocess.run([sys.executable, str(POOLSCRIPT)], capture_output=True, text=True)
if res.returncode != 0:
    die(f"pool script exited {res.returncode}: {res.stderr.strip()[:200]}")
m = re.search(r"POOL IDS \(ascending\).*?\n\s+([\d ]+)\n", res.stdout, re.S)
if not m:
    die("could not locate the pool id list in the pool script's output")
pool = [int(x) for x in m.group(1).split()]
sha = hashlib.sha256(" ".join(map(str, pool)).encode()).hexdigest()[:16]
print(f"b2_draw_B: re-derived pool · N={len(pool)} · sha256/16={sha}")

# (3) THE GATE. Any disagreement means the population moved after registration, and
#     a draw over a moved population is exactly what pre-registration exists to stop.
if len(pool) != N_PRE:
    die(f"pool size {len(pool)} != pre-registered N={N_PRE}. The population MOVED.")
if sha != SHA_PRE:
    die(f"pool hash {sha} != pre-registered {SHA_PRE}. The population MOVED.")
print("b2_draw_B: ✅ population matches the pre-registration EXACTLY (size and hash)")

# (4) THE DRAW. The published formula, applied verbatim.
pool.sort()
idx = [ (i * len(pool)) // K for i in range(K) ]
if len(set(idx)) != K:
    die(f"index rule produced {len(set(idx))} distinct indices for k={K} -- collision")
drawn = [pool[i] for i in idx]

print()
print(f"b2_draw_B: DRAW EXECUTED · k={K} · rule floor(i*N/{K}) over the ascending pool")
print(f"b2_draw_B: indices  : {' '.join(map(str, idx))}")
print(f"b2_draw_B: DRAWN IDS: {' '.join(map(str, drawn))}")
print(f"b2_draw_B: draw sha256/16 = {hashlib.sha256(' '.join(map(str,drawn)).encode()).hexdigest()[:16]}")
print()
print("b2_draw_B: ⚠️ THESE ROWS ARE NOT YET SCORED. Per the pre-registration's own")
print("           clauses: score from the ROW AND THE RULE ONLY, publish the verdicts")
print("           BEFORE checking them against anything, and DISCARD-and-report any")
print("           drawn row later found named by the codebook rather than re-labelling it.")

#!/usr/bin/env python3
"""b2_pool_B.py — OPTION (B): the B-2 eligible pool, derived mechanically.

RULED 2026-08-16 22:36 (helm): recusal protects against contaminated JUDGEMENT,
not against executing a MECHANISM. (B) contains no per-row judgement anywhere,
so it is reproducible, and reproducibility is what makes the author's exposure
irrelevant. Any hand may re-run this and get the same pool -- or convict it.

⛔ THIS SCRIPT COMPUTES A POOL. IT DOES NOT DRAW.
The ruling requires the pool and its derivation to be PUBLISHED BEFORE any index
is computed. A draw derived after seeing the population is worth nothing, so the
draw lives in a separate script that takes the published pool as input.

WHAT (B) IS: pool = disputed MINUS (disputed rows that appear in the codebook at all).

⚠️ AND THE ARITHMETIC I ALMOST SHIPPED. I stated (B) on the bus as "278 - 171 = 107".
   That subtracts a count measured over ONE population (the 388-row SAMPLE) from a
   DIFFERENT population (the 278 DISPUTED). It is only correct if every one of the
   171 lies inside the 278, which nothing established. This script computes the
   INTERSECTION instead and prints both figures so the difference is visible.

DECLARED LIMITATION, per the ruling, in the same breath as the result:
   the appearance test OVER-REJECTS. A row is removed if its id occurs anywhere in
   the codebook, including in prose that merely DISCUSSES it. 112 of the removals
   were hand-checked as prose whose dispositive-ness could not be mechanically
   separated. Those rows are discarded, not adjudicated. (C) -- a fresh unexposed
   hand adjudicating them -- remains the better answer and stays available.
"""
import json, re, sys, pathlib, hashlib

DOCS = pathlib.Path(__file__).resolve().parents[1]
P1 = DOCS / "compiler-doublecode-PASS1-compiler.json"
P2 = DOCS / "compiler-doublecode-PASS2-coder2.json"
CB = DOCS / "helm-doublecode-codebook-amendment-DRAFT2-0813.md"
SAMPLE = DOCS / "compiler-doublecode-sample-0813.txt"

def die(m):
    print(f"b2_pool_B: REFUSING -- {m}", file=sys.stderr); sys.exit(2)

# (1) DOMAIN. An instrument aimed at a missing file returns silence, and silence
#     reads exactly like a clean result. Refuse, and print what was found.
for p in (P1, P2, CB, SAMPLE):
    if not p.is_file():
        die(f"input not found: {p}")

def sha16(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]

print("b2_pool_B: INPUTS, pinned by content hash")
for p in (P1, P2, CB, SAMPLE):
    print(f"    {p.name:<52} {p.stat().st_size:>7} B  sha256/16={sha16(p)}")
print()

def load_classes(p):
    """-> {line:int -> class:str}. Reads ONLY line and class. Never reads `reason`
    -- the reasons are the other coder's judgement and this computation needs none."""
    # The two passes have DIFFERENT SHAPES -- pass2 is a bare array, pass1 is an
    # object whose `rows` key holds one. A loader that assumed a shape would parse
    # one file and mis-parse the other; the first version found the first "[" and
    # choked on pass1's trailing keys. It REFUSED rather than half-parsing, which
    # is the only reason this was a two-minute fix and not a wrong pool.
    try:
        doc = json.loads(p.read_text())
    except json.JSONDecodeError as e:
        die(f"{p.name}: JSON parse failed at {e.pos}: {e.msg}")
    if isinstance(doc, list):
        arr = doc
    elif isinstance(doc, dict):
        cands = [v for v in doc.values()
                 if isinstance(v, list) and v and isinstance(v[0], dict) and "line" in v[0]]
        if len(cands) != 1:
            die(f"{p.name}: expected exactly one row-array, found {len(cands)}")
        arr = cands[0]
    else:
        die(f"{p.name}: unexpected top-level type {type(doc).__name__}")
    out = {}
    for rec in arr:
        if "line" not in rec or "class" not in rec:
            continue
        out[int(rec["line"])] = str(rec["class"]).strip()
    return out

c1, c2 = load_classes(P1), load_classes(P2)
print(f"b2_pool_B: pass1 rows {len(c1)} · pass2 rows {len(c2)}")

# (2) THE DISPUTED SET, derived -- not taken from a published count.
both = sorted(set(c1) & set(c2))
disputed = sorted(n for n in both if c1[n] != c2[n])
agree = [n for n in both if c1[n] == c2[n]]
print(f"b2_pool_B: rows in BOTH passes {len(both)} · agree {len(agree)} · DISPUTED {len(disputed)}")

# (3) THE APPEARANCE TEST. Identical rule to the 08-16 re-cut: an id of >=4 digits
#     occurring anywhere in the codebook. Short ids (<=3 digits) are AMBIGUOUS --
#     they match years, counts and line numbers -- and are counted NEITHER way, so
#     they stay in the pool. That is the permissive direction and it is declared.
cb_text = CB.read_text()
cb_ids = set(int(m) for m in re.findall(r"\b(\d{4,})\b", cb_text))
print(f"b2_pool_B: distinct >=4-digit integers in the codebook {len(cb_ids)}")

short = [n for n in disputed if n < 1000]
appear = sorted(n for n in disputed if n >= 1000 and n in cb_ids)
pool = sorted(n for n in disputed if n not in set(appear))

# (4) THE SAMPLE-WIDE FIGURE, for comparison ONLY -- this is the 171 I quoted.
sample_ids = []
for ln in SAMPLE.read_text().splitlines():
    ln = ln.strip()
    if ln and not ln.startswith("#"):
        try: sample_ids.append(int(ln))
        except ValueError: pass
sample_appear = [n for n in sample_ids if n >= 1000 and n in cb_ids]

print()
print("b2_pool_B: ===================== THE POOL =====================")
print(f"    disputed population .............................. {len(disputed)}")
print(f"      of those, ids <=3 digits (ambiguous, KEPT) ..... {len(short)}")
print(f"      of those, appearing in the codebook (REMOVED) .. {len(appear)}")
print(f"    ⇒ ELIGIBLE POOL (option B) ....................... {len(pool)}")
print()
print(f"    for comparison, the figure quoted on the bus:")
print(f"      sample rows (all 388, NOT the disputed set) ..... {len(sample_ids)}")
print(f"      of those appearing in the codebook .............. {len(sample_appear)}")
print(f"      naive '278 - 171' would have given ............... {len(disputed) - len(sample_appear)}")
print(f"      ⇒ DIFFERENCE from the correct intersection ...... {abs(len(pool) - (len(disputed) - len(sample_appear)))}")
print()
print("b2_pool_B: ⚠️ LIMITATION, stated with the result: the appearance test OVER-REJECTS.")
print("           A row is removed if its id occurs ANYWHERE in the codebook, including")
print("           prose that merely discusses it. Those rows are DISCARDED, not adjudicated.")
print("           (C) -- a fresh unexposed hand ruling discussed-vs-decided -- is the better")
print("           answer and remains available; this is the defensible result available NOW.")
# (5) THE KNOB, SWEPT AND PUBLISHED. The <=3-digit ids are the one free parameter in
#     this mechanism: any 2-3 digit number occurs in a 102 KB document by accident, so
#     "does it appear" cannot discriminate for them. KEEPING them is the LARGER-pool
#     direction and therefore the LESS conservative one against contamination -- which
#     cuts against (B)'s whole purpose, so the sensitivity is published rather than
#     buried in a choice. A mechanical test with an unswept parameter is still a
#     parameterised test.
print()
print("b2_pool_B: ⚙️ THE ONE FREE PARAMETER, SWEPT (short-id handling):")
print(f"    KEEP  <=3-digit ids in the pool (as computed) .... {len(pool)}   <- PUBLISHED POOL")
print(f"    DROP  <=3-digit ids as presumed-named ............ {len(pool) - len(short)}")
print(f"    the {len(short)} rows at issue: {' '.join(str(n) for n in short)}")
print("    KEEP is the larger, LESS conservative pool. It is chosen because 'appears in")
print("    the codebook' is UNDECIDABLE for these ids, and a mechanism must not silently")
print("    resolve an undecidable case -- but a hand ruling (C) should revisit exactly these.")
print()
print("b2_pool_B: POOL IDS (ascending), the object any re-run must reproduce:")
print("    " + " ".join(str(n) for n in pool))
print()
print(f"b2_pool_B: pool sha256/16 = {hashlib.sha256(' '.join(map(str,pool)).encode()).hexdigest()[:16]}")
print("b2_pool_B: NO DRAW COMPUTED. The ruling requires this pool published FIRST.")

#!/usr/bin/env python3
"""CLEAN DRAW — pick corpus rows for a blind class-prediction test, with the
disjointness check INSIDE the draw instead of in the post-mortem.

    draw_clean.py <count> [--stride N] [--prox CHARS]

WHY THIS EXISTS.  On blind draw #3 (2026-08-14) I predicted a class for row
56531 and only afterwards discovered that its class is stated in RUNNING PROSE
in a file I had opened -- DRAFT2:535, "it splits pass 1's four wrong-scope calls
... 56531 fires it".  I had built my "already seen" exclusion set out of the
LISTS I had read.  The codebook also discloses classes in prose, and a prose
disclosure does not look like a list.  A LIST-SHAPED EXCLUSION FILTER CANNOT SEE
A PROSE-SHAPED LEAK.

Worse, I ran the check AFTER posting the predictions.  The blind positive in that
draw (67127) came back clean -- but had it not, I would have learned my headline
was contaminated after publishing it.  That was luck, and this file is the repair.

*** THE ONE DESIGN RULE, AND IT IS EASY TO GET BACKWARDS ***
This tool must never print WHICH class it found near a row.  A contamination
checker that reports the contaminant contaminates the caller -- it would leak
exactly the verdict the draw exists to withhold.  So every finding here is
reduced to a BOOLEAN before it reaches stdout.  Reasons are named by GATE, never
by content.  (If you extend it, keep that: the temptation to print the match for
"auditability" is the whole failure mode wearing a helpful face.)
"""
import argparse, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BUS = ROOT.parent / "FLEET.md"
DOCS = ROOT / "docs"
LEDGER = DOCS / "compiler-drawn-rows.txt"

# The vocabulary a disclosure would use.  Deliberately WIDE: a false exclusion
# costs one candidate row, a false inclusion costs the whole result.
CLASS_WORDS = re.compile(
    r"type-traps|misattributed|stale-citations|wrong-scope|OTHER|EXCLUDED"
    r"|DECIDED|AMBIG|UNDECIDED|fires it|fails the test",
    re.I,
)
HDR = re.compile(r"^\[\d{1,2}/\d{1,2}[ ,]")
# ⛔ NOT a generic digit pattern. The first version was r"(?<!\d)(\d{3,5})(?!\d)" and it
# STRUCTURALLY COULD NOT SEE ANY ROW BELOW 100 -- row 80 landed in a fence with its class
# disclosed in the codebook's own exemplar table ("| 80 | fires -> misattributed |"), because
# "80" is two digits. A blind spot CORRELATED with the variable (low line numbers are the
# earliest, most-quoted rows) fabricates safety exactly where it is least deserved.
# The population is KNOWN -- scan for the ACTUAL row numbers as tokens, no width assumption.
def _row_token(n):
    return re.compile(r"(?<!\d)%d(?!\d)" % n)


def header_lines():
    """1-indexed line numbers of every well-formed bus header."""
    if not BUS.exists():
        sys.exit(f"⛔ bus not found at {BUS}")
    text = BUS.read_text(errors="replace").split("\n")
    return [i + 1 for i, ln in enumerate(text) if HDR.match(ln)]


def disclosed(prox, population):
    """Rows whose number appears within `prox` chars of a class word in ANY doc.

    Scope is every file in docs/, not merely the ones I remember opening --
    "files I read" is a remembered set and this is exactly the place where a
    remembered set already failed once.
    """
    hits, scanned, texts = set(), 0, []
    for f in sorted(DOCS.rglob("*")):
        if not f.is_file() or f.suffix not in (".md", ".txt", ".json", ".tsv"):
            continue
        # ⛔ NEVER scan the ANSWER KEY. The PASS1/PASS2 files pair EVERY coded row with its
        # class by construction, so including them marks the whole corpus "disclosed" and
        # reports an exhausted pool. Found 13:32 by a threshold sweep that came back FLAT --
        # 309 excluded at every window from 40 to 400 chars. I nearly read that flatness as
        # ROBUSTNESS; it meant one source dominated and the parameter was irrelevant.
        # A withheld verdict record is the thing being protected, not a leak of it.
        if "PASS1" in f.name or "PASS2" in f.name or "COMPARE" in f.name:
            continue
        scanned += 1
        texts.append(f.read_text(errors="replace"))
    for n in population:
        pat = _row_token(n)
        for t in texts:
            hit = False
            for m in pat.finditer(t):
                a, b = max(0, m.start() - prox), m.end() + prox
                if CLASS_WORDS.search(t[a:b]):
                    hits.add(n); hit = True; break
            if hit:
                break
    return hits, scanned


def already_drawn():
    if not LEDGER.exists():
        return set()
    out = set()
    for ln in LEDGER.read_text().split("\n"):
        ln = ln.split("#")[0].strip()
        if ln.isdigit():
            out.add(int(ln))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("count", type=int)
    ap.add_argument("--stride", type=int, default=0)
    ap.add_argument("--prox", type=int, default=260)
    ap.add_argument("--commit", action="store_true",
                    help="append the drawn rows to the ledger so a later draw cannot reuse them")
    a = ap.parse_args()

    rows = header_lines()
    seen = already_drawn()
    leaked, nfiles = disclosed(a.prox, rows)

    clean = [r for r in rows if r not in seen and r not in leaked]
    stride = a.stride or max(1, len(clean) // max(1, a.count))
    picked = clean[::stride][: a.count]

    print(f"POPULATION      {len(rows)} bus headers")
    print(f"− already drawn {len(rows) - len([r for r in rows if r not in seen])}"
          f"   (ledger: {LEDGER.name})")
    print(f"− class-adjacent {len([r for r in rows if r not in seen and r in leaked])}"
          f"   (within {a.prox} chars of a class word, across {nfiles} docs)")
    print(f"= ELIGIBLE      {len(clean)}")
    print()
    if len(picked) < a.count:
        print(f"⚠️  asked for {a.count}, eligible pool yielded {len(picked)}. "
              f"NOT silently truncated -- this line is the disclosure.")
    print("DRAW:", " ".join(str(r) for r in picked))
    print()
    print("⚠️  This tool reports CONTAMINATED / CLEAN and never which class it saw.")
    print("⚠️  Clean here means 'not disclosed in docs/'. It cannot see what you were")
    print("    told on the bus, and the bus is not scanned -- state that when you publish.")

    if a.commit:
        with LEDGER.open("a") as fh:
            for r in picked:
                fh.write(f"{r}\n")
        print(f"✅ {len(picked)} rows appended to {LEDGER.name}")


if __name__ == "__main__":
    main()

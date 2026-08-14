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
    """Rows whose number sits within `prox` chars of a class word, in ANY doc.

    ONE PASS: walk each class-word occurrence and collect every number inside its
    window, instead of searching each row against every file.  The naive form was
    O(rows x corpus) and timed out twice at 5,178 rows -- and a check nobody can
    afford to run is a check that gets skipped, which is the same outcome as not
    having written it.

    ⚠️ THIS RULE IS KNOWN TO LEAK.  A bare LIST under a heading ("FIRES TEST 2: 80
    2008 ... 77740") puts its later members hundreds of characters from the label,
    so no window catches them without swallowing the corpus.  Reported only as the
    LOOSE bound beside the strict one; never used alone.
    """
    hits, scanned = set(), 0
    NUM_ANY = re.compile(r"\d+")
    pop = set(population)
    for f in sorted(DOCS.rglob("*")):
        if not f.is_file() or f.suffix not in (".md", ".txt", ".json", ".tsv"):
            continue
        if any(k in f.name for k in ("PASS1", "PASS2", "COMPARE", "FENCE22", "drawn-rows")):
            continue
        scanned += 1
        t = f.read_text(errors="replace")
        for cm in CLASS_WORDS.finditer(t):
            lo, hi = max(0, cm.start() - prox), cm.end() + prox
            for nm in NUM_ANY.finditer(t, lo, hi):
                v = int(nm.group())
                if v in pop:
                    hits.add(v)
    return hits, scanned


def named_anywhere(population):
    """Rows named AT ALL outside the answer key. PARAMETER-FREE and conservative.

    This is the rule that survived 2026-08-14's three withdrawn fence draws. It has no
    proximity window and no digit-width assumption, so it cannot be defeated by a list
    whose heading is far from its members, nor by a two-digit row number. It DOES
    over-exclude a row cited by line number with no verdict nearby -- that cost is one
    candidate row, against a false inclusion costing the whole validation.
    """
    # ONE PASS over the corpus, not one pass PER ROW. The naive form was O(rows x files)
    # and timed out at 5,178 bus headers -- correct and unusable, which is its own lesson:
    # a check nobody can afford to run is a check that will be skipped.
    tokens = set()
    ALLNUM = re.compile(r"\d+")
    for f in sorted(DOCS.rglob("*")):
        if not f.is_file() or f.suffix not in (".md", ".txt", ".json", ".tsv"):
            continue
        if any(k in f.name for k in ("PASS1", "PASS2", "COMPARE", "FENCE22", "drawn-rows")):
            continue
        tokens.update(int(m.group()) for m in ALLNUM.finditer(f.read_text(errors="replace")))
    return {n for n in population if n in tokens}


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

    # BOTH RULES, ALWAYS BOTH REPORTED. Neither is the truth and the gap is the honest
    # uncertainty -- proximity MISSES a bare list under a heading (proven 13:35: 37171 and
    # 77740 sit under "FIRES TEST 2:" with the label hundreds of chars away), and
    # named-anywhere over-excludes a row merely cited by line number with no verdict.
    named = named_anywhere(rows)
    clean = [r for r in rows if r not in seen and r not in named]
    loose = [r for r in rows if r not in seen and r not in leaked]
    stride = a.stride or max(1, len(clean) // max(1, a.count))
    picked = clean[::stride][: a.count]

    print(f"POPULATION      {len(rows)} bus headers")
    print(f"− already drawn {len(rows) - len([r for r in rows if r not in seen])}"
          f"   (ledger: {LEDGER.name})")
    print(f"− class-adjacent {len([r for r in rows if r not in seen and r in leaked])}"
          f"   (within {a.prox} chars of a class word, across {nfiles} docs)")
    print(f"= ELIGIBLE      {len(clean)}   (strict: named-anywhere rule)")
    print(f"  ...loose bound {len(loose)}   (proximity {a.prox} — LEAKS on lists, see docstring)")
    print(f"  ⇒ the true blind pool lies BETWEEN these two and no rule pins it: whether a")
    print(f"    row's class is recoverable from what you have read is not a lexical property.")
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

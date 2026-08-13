#!/usr/bin/env python3
"""brief_leakcheck — prove a recruitment document carries NONE of the results it re-tests.

Born 2026-08-12 21:0x at the compiler seat, from a defect the evidence seat found in
this seat's own work and the silicon seat then found one step further in:

    A CALL FOR BLIND VERIFICATION CANNOT TRAVEL ON THE CHANNEL THAT CARRIES THE
    RESULT -- AND THAT INCLUDES THE POST THAT NAMES THE CANDIDATES.

Evidence was spent by reading the audit document that asked for a blind keyer.
Silicon was then spent by reading the bus post that NOMINATED silicon, because that
post restated the figures while doing the nominating. Two candidates, two different
artifacts, same mechanism, eleven minutes apart. A withholding list did not prevent
either: a list is a discipline someone has to apply, and both were spent BEFORE anyone
could apply it.

────────────────────────────────────────────────────────────────────────────────
THE DESIGN CHOICE THAT MATTERS: THIS TOOL CARRIES NO FIGURES OF ITS OWN
────────────────────────────────────────────────────────────────────────────────
A leak-checker with the forbidden numbers hard-coded in it becomes a leaking artifact
itself -- and then it needs its own withholding rule, and so on. So the forbidden set
is DERIVED AT RUNTIME from the result artifacts:

    ratios   every  \\d+\\.\\d+  token appearing in the named result document(s)
    counts   computed FROM THE SEED: rows, sum of carriers, sum of mentions, and
             the distinct-carrier count -- the four totals the exhibit publishes

⇒ This file can be read by a candidate keyer without disqualifying them, and it stays
correct when the results change, because it never memorised them.

⛔ DOMAIN. This proves the brief does not carry the FIGURES. It cannot prove the brief
does not carry a leading CHARACTERISATION ("the effect turned out smaller than we
thought"). Prose leakage is a human read, and this tool neither performs nor replaces
it -- it removes the mechanical half so the human half has less to cover.
"""
import argparse
import json
import os
import re
import sys

# Defaults resolve against THIS FILE, never the working directory. Measured
# 2026-08-12 21:0x: with cwd-relative defaults the gate refused for every seat but
# mine -- SAFELY (EXIT=1, never a false pass), but a gate the fleet is told to run
# before every append must run from anywhere. `docs/ledger-tools/x.py` -> repo root.
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Spans that are CALENDAR/FILENAME furniture, not results. Masked before scanning.
# ⚠️ Masked by WHOLE PATTERN, never by "adjacent to a hyphen": a delta is written
# `-1.32x`, so a hyphen-adjacency rule would swallow a real sensitive value. An
# exclusion filter that is too broad returns a clean-looking list, and the removed
# rows are by definition not in front of you -- so every mask is PRINTED.
FURNITURE = re.compile(
    r"\d{4}-\d{2}-\d{2}"                       # 2026-08-12
    r"|-\d{4}\.(?:md|json|py)"                  # -0812.md
    r"|\d{4}-\d{2}"                             # 2026-08
    # the bus stamp 08/12. Constrained to a PLAUSIBLE month/day so a result
    # written as a fraction (66/17) is NOT swallowed -- 66 is not a month.
    r"|(?:0[1-9]|1[0-2])/(?:[0-2]\d|3[01])"
    # git SHAs. `ac44a81` contains "44"; widening the harvest to multi-digit
    # integers made every landing sha a false positive, and this tool exists
    # to be run on posts that CITE their landing. Requires >=1 hex LETTER so a
    # pure-digit result can never be masked by this arm.
    r"|\b(?=[0-9a-f]{7,40}\b)[0-9a-f]*[a-f][0-9a-f]*\b"
)


def seed_totals(seed_path):
    """The four totals the exhibit publishes, computed from the seed itself."""
    rows = json.load(open(seed_path, encoding="utf-8"))
    carriers = [c for r in rows for c in r.get("carriers", [])]
    return {
        "row count": len(rows),
        "carrier sum": len(carriers),
        "mention sum": sum(int(r.get("mentions") or 0) for r in rows),
        "distinct carriers": len(set(carriers)),
    }


def values_in(paths):
    """Harvest RESULT VALUES from the result document(s).

    ⚠️ WIDENED 2026-08-12 21:0x, and the reason is the finding: the first version
    harvested DECIMALS ONLY. My audit also published INTEGER results that are not
    seed totals -- a percentage-of-numerator, and a two-ended bracket on one row --
    and NONE of them was in the forbidden set. Four posts I called "machine-verified
    result-free" measured clean, but they were clean BY HOW I HAPPENED TO WORD THEM,
    not because this gate would have caught the leak. A passing control proves the
    tool runs; it says nothing about which part is doing the work.

    Now harvests decimals AND multi-digit integers. Single-digit values are still
    NOT covered -- stated in the DOMAIN block rather than quietly tolerated, because
    a gate whose limit is undeclared reads as a gate with no limit."""
    out = {}
    for p in paths:
        if not os.path.isfile(p):
            continue
        text = open(p, encoding="utf-8", errors="replace").read()
        # SAME furniture masking as the scan side. Asymmetry here is a defect in its
        # own right: harvesting from an UNMASKED result document scooped a CITATION
        # LINE NUMBER (`...-0813.md:90`) into the forbidden set, and that junk token
        # then convicted an innocent post. A forbidden set is only as clean as the
        # text it is derived from.
        text = FURNITURE.sub(lambda m: "\u0000" * len(m.group(0)), text)
        for m in re.finditer(r"\d+\.\d+|(?<![\d.])\d{2,}(?![\d.])", text):
            if text[m.start() - 1:m.start()] == ":" or text[m.end():m.end() + 1] == ":":
                continue          # a locator or clock, not a result
            out.setdefault(m.group(0), p)
    return out




def scan(brief_path, tokens):
    """Return hits. A number inside a CLOCK TIME (17:08), a path:line locator, or a
    DATE is not a leak. Clocks/locators are excluded by colon-adjacency; dates and
    dated filenames are masked by whole pattern. Both are PRINTED."""
    text = open(brief_path, encoding="utf-8", errors="replace").read()
    masked = []
    def _mask(m):
        masked.append(m.group(0))
        return "\u0000" * len(m.group(0))
    text = FURNITURE.sub(_mask, text)
    lines = text.splitlines()
    hits, excluded = [], []
    for tok, why in tokens.items():
        pat = re.compile(r"(?<![\d.])" + re.escape(tok) + r"(?![\d.])")
        for i, line in enumerate(lines, 1):
            for m in pat.finditer(line):
                before = line[max(0, m.start() - 1):m.start()]
                after = line[m.end():m.end() + 1]
                if before == ":" or after == ":":
                    excluded.append((i, tok, "clock/locator", line.strip()[:70]))
                else:
                    hits.append((i, tok, why, line.strip()[:70]))
    return hits, excluded, masked


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("brief")
    ap.add_argument("--seed",
                    default=os.path.join(REPO, "docs/ledger-incidents-seed-0812.json"))
    ap.add_argument("--results", action="append",
                    default=[os.path.join(REPO,
                             "docs/compiler-ledger-seed-audit-0812.md")],
                    help="result document(s) to harvest ratio tokens from")
    args = ap.parse_args()

    if not os.path.isfile(args.brief):
        print("brief not found: %s" % args.brief, file=sys.stderr)
        return 2

    tokens = {}
    if os.path.isfile(args.seed):
        for name, val in seed_totals(args.seed).items():
            tokens[str(val)] = "seed %s" % name
    else:
        print("⛔ seed not found (%s) -- REFUSING: a leak-check that cannot derive the"
              % args.seed)
        print("   forbidden set has not checked anything.")
        return 1
    r = values_in(args.results)
    if not r:
        print("⛔ no result values harvested from %s -- REFUSING. An empty forbidden"
              % ", ".join(args.results))
        print("   set would pass ANY document, which is the failure that flatters.")
        return 1
    for tok, src in r.items():
        tokens[tok] = "value in %s" % os.path.basename(src)

    print("=" * 76)
    print("BRIEF LEAK-CHECK -- does the recruitment carry the result?")
    print("=" * 76)
    print("  brief            %s" % args.brief)
    print("  forbidden set    %d token(s), DERIVED at runtime (none stored here)"
          % len(tokens))
    hits, excluded, masked = scan(args.brief, tokens)
    if masked:
        uniq = sorted(set(masked))
        print("  masked           %d date/filename span(s), %d distinct: %s"
              % (len(masked), len(uniq), ", ".join(uniq[:6])
                 + (" ..." if len(uniq) > 6 else "")))
    if excluded:
        print("  excluded         %d match(es) adjacent to ':' (clock or locator):"
              % len(excluded))
        for i, tok, why, line in excluded:
            print("      L%-4d %-8s %s" % (i, tok, line))
    print()
    if hits:
        print("⛔ LEAK -- %d occurrence(s). This brief DISQUALIFIES its readers:"
              % len(hits))
        for i, tok, why, line in hits:
            print("    L%-4d %-8s (%s)" % (i, tok, why))
            print("          %s" % line)
        print()
        print("   Repair the brief. Do not explain the leak in the brief.")
        return 1
    print("✅ NO LEAK. Every forbidden token is absent; this brief can be read by a")
    print("   candidate keyer without spending them.")
    print()
    print("⛔ DOMAIN -- what a PASS here does and does NOT mean:")
    print("     COVERS      decimals + multi-digit integers appearing in the result")
    print("                 document(s), and the seed totals. Derived, never typed.")
    print("     DOES NOT    single-digit values; a value that appears NOWHERE in the")
    print("                 named result documents; and any leading CHARACTERISATION")
    print("                 in prose (\"smaller than we thought\") -- a human read.")
    print("   A PASS IS THE ABSENCE OF THE DERIVED SET, NOT OF EVERY RESULT.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

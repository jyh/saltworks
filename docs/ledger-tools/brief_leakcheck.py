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


def ratios_in(paths):
    out = {}
    for p in paths:
        if not os.path.isfile(p):
            continue
        for m in re.finditer(r"\d+\.\d+", open(p, encoding="utf-8",
                                               errors="replace").read()):
            out.setdefault(m.group(0), p)
    return out


def scan(brief_path, tokens):
    """Return hits. A number inside a CLOCK TIME (17:08) or a path:line locator is not
    a leak, so matches adjacent to a colon are excluded -- and the exclusions are
    PRINTED, because an exclusion filter that is too broad returns a clean-looking
    list and the removed rows are by definition not in front of you."""
    text = open(brief_path, encoding="utf-8", errors="replace").read()
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
    return hits, excluded


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
    r = ratios_in(args.results)
    if not r:
        print("⛔ no ratio tokens harvested from %s -- REFUSING. An empty forbidden"
              % ", ".join(args.results))
        print("   set would pass ANY document, which is the failure that flatters.")
        return 1
    for tok, src in r.items():
        tokens[tok] = "ratio in %s" % os.path.basename(src)

    print("=" * 76)
    print("BRIEF LEAK-CHECK -- does the recruitment carry the result?")
    print("=" * 76)
    print("  brief            %s" % args.brief)
    print("  forbidden set    %d token(s), DERIVED at runtime (none stored here)"
          % len(tokens))
    hits, excluded = scan(args.brief, tokens)
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
    print("⛔ DOMAIN: proves the FIGURES are absent. Cannot prove a leading")
    print("   CHARACTERISATION is absent -- that half is a human read.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

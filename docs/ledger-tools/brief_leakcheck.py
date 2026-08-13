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

    ⛔ WIDENING TO INTEGERS WAS TRIED AND RETRACTED THE SAME HOUR. RECORDED, NOT
    DELETED, BECAUSE IT IS THE OBVIOUS FIX AND THE NEXT READER WILL THINK OF IT.

    The hole was real: this gate first harvested DECIMALS ONLY, so integer results
    (a percentage-of-numerator, a two-ended bracket) were never in the forbidden set
    at all. Four posts published as "machine-verified result-free" measured clean --
    but clean BY HOW THEY WERE WORDED, not because the gate could see the leak.

    So I widened to multi-digit integers. MEASURED against the last 120 real bus
    posts, all seats:

        decimals + multi-digit integers    convicts  60%   UNUSABLE
        decimals only                      convicts   8%   (3.9 collides with
                                                            build times "3.9s")
        decimals with 2+ fraction digits   convicts   3%   and those are GENUINE

    ⇒ THE VALUE CLASS IS NOT TOKEN-SHAPED. A bare integer cannot be gated at any
    threshold: tighten and it misses, widen and it convicts half the bus. The signal
    is CONTEXT and a gate reads TOKENS. This is the evidence seat's finding,
    confirmed here on this gate with its masking already in place.

    ⇒ SETTLED SCOPE: 2+ fraction digits. See the DOMAIN block -- the integers are
    covered by the OTHER mechanism (sequencing via the boot block), not by this."""
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
        for m in re.finditer(r"\d+\.\d{2,}", text):
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
    ap.add_argument("--show-tokens", action="store_true",
                    help="NAME the offending tokens. DOING SO SPENDS A CANDIDATE "
                         "READER -- verdict-only is the DEFAULT for that reason.")
    ap.add_argument("--verdict-only", action="store_true",
                    help="accepted and redundant: verdict-only is now the DEFAULT")
    args = ap.parse_args()

    if not os.path.isfile(args.brief):
        print("brief not found: %s" % args.brief, file=sys.stderr)
        return 2

    # ---- CHRONOLOGY PRE-CHECK (math seat's method, 2026-08-13) -----------------
    # A file whose last write PREDATES the birth of the seed and the results
    # document CANNOT carry a value derived from them. Math cleared SIX of TEN
    # fleet flags this way WITHOUT READING A TOKEN, measuring a 60% false-positive
    # rate over the raw flag set. Mechanised here so the argument is not re-made by
    # hand at midnight: NO FLAG FROM THIS TOOL IS A FINDING UNTIL ITS FILE'S MTIME
    # HAS BEEN CHECKED.
    src_m = [os.path.getmtime(q) for q in ([args.seed] + list(args.results))
             if os.path.isfile(q)]
    if src_m:
        born = min(src_m)
        if os.path.getmtime(args.brief) < born:
            import time as _t
            fmt = lambda s: _t.strftime("%Y-%m-%d %H:%M", _t.localtime(s))
            print("=" * 76)
            print("BRIEF LEAK-CHECK -- does the recruitment carry the result?")
            print("=" * 76)
            print("  brief            %s" % args.brief)
            print("✅ CLEARED BY CHRONOLOGY -- NOT SCANNED, NO TOKEN READ.")
            print("   file last written  %s" % fmt(os.path.getmtime(args.brief)))
            print("   sources born       %s" % fmt(born))
            print("   A file written before its sources existed cannot carry a value")
            print("   derived from them. This clearance is SAFE FOR A CANDIDATE to run")
            print("   AND to read: it names no token and reads no content.")
            return 0

    tokens = {}
    advisory_toks = []
    if os.path.isfile(args.seed):
        # ⛔ SEED TOTALS ARE NOT IN THE HARD SET. Measured on 120 real bus posts:
        # gating them convicts 19% -- they are ordinary small integers. They move
        # to the ADVISORY tier, where CO-OCCURRENCE supplies the context a single
        # token cannot: >=2 distinct totals close together convicts 5% instead,
        # and catches the one sentence that matters most ("ROOT a, CARRIER b,
        # MENTIONS c"). Still too noisy to BLOCK -- ordinary dense-numeric prose
        # trips it -- so it WARNS and never changes the exit code.
        advisory_toks = [str(v) for v in seed_totals(args.seed).values()]
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
        print("⛔ LEAK -- %d occurrence(s). This brief DISQUALIFIES its readers."
              % len(hits))
        if args.show_tokens:
            print("   ⛔ TOKENS NAMED BELOW -- READING FURTHER SPENDS YOU:")
            for i, tok, why, line in hits:
                print("    L%-4d %-8s (%s)" % (i, tok, why))
                print("          %s" % line)
        else:
            print("   Lines: %s" % ", ".join("L%d" % i for i, _, _, _ in hits[:12]))
            print("   ⛔ TOKENS NOT NAMED -- THIS OUTPUT IS SAFE FOR A CANDIDATE TO READ.")
            print("      A LEAK-CHECKER NAMES THE OFFENDING TOKEN WHEN IT FAILS, so on a")
            print("      real hit the gate would spend the very reader running it to")
            print("      prove they are clean (math seat, 2026-08-13: they masked every")
            print("      digit of this tool's stdout by hand to stay eligible).")
            print("      Re-run with --show-tokens ONLY IF ALREADY CONTAMINATED.")
        print()
        print("   Repair the brief. Do not explain the leak in the brief.")
        return 1
    print("✅ NO LEAK. Every forbidden token is absent; this brief can be read by a")
    print("   candidate keyer without spending them.")
    # ---- ADVISORY TIER: co-occurrence, not tokens ----------------------------
    if advisory_toks:
        atext = FURNITURE.sub(lambda m: "\u0000" * len(m.group(0)),
                              open(args.brief, encoding="utf-8",
                                   errors="replace").read())
        marks = []
        for tok in advisory_toks:
            for m in re.finditer(r"(?<![\d.])" + tok + r"(?![\d.])", atext):
                if (atext[m.start() - 1:m.start()] == ":"
                        or atext[m.end():m.end() + 1] == ":"):
                    continue
                marks.append((m.start(), tok))
        marks.sort()
        flagged = []
        for pos, _ in marks:
            near = {tk for pp, tk in marks if pos <= pp <= pos + 90}
            if len(near) >= 2:
                ln = atext[:pos].count("\n") + 1
                snippet = atext.splitlines()[ln - 1].strip()[:66]
                if (ln, snippet) not in flagged:
                    flagged.append((ln, snippet))
        if flagged:
            print()
            print("⚠️  ADVISORY (does NOT change the exit code) -- %d line(s) carry TWO"
                  % len(flagged))
            print("    OR MORE headline totals close together. Single totals are")
            print("    ordinary numbers; CO-OCCURRENCE is the cheapest proxy for the")
            print("    context a token gate cannot read. HUMAN READ THESE:")
            for ln, s in flagged:
                print("      L%-4d %s" % (ln, s))

    print()
    print("⛔ DOMAIN -- THIS GATE COVERS ONE OF TWO MECHANISMS. Read before quoting.")
    print("     COVERS      DISTINCTIVE DECIMALS (2+ fraction digits) from the result")
    print("                 document(s), plus the seed totals. Derived, never typed.")
    print("     ADVISES ON  the headline TOTALS, by co-occurrence, warning only.")
    print("     DOES NOT    BARE INTEGERS -- not an oversight and not fixable here.")
    print("                 Measured on 120 real bus posts: gating integers convicts")
    print("                 60%, decimals-only 8%, 2+ fraction digits 3%. The value")
    print("                 class is NOT TOKEN-SHAPED; the signal is CONTEXT.")
    print("                 Also not covered: a leading CHARACTERISATION in prose.")
    print("     THE REST    is covered by SEQUENCING -- the analysis those integers")
    print("                 belong to does not travel on this channel at all.")
    print("   ⛔ MEASURED MISS SURFACE -- every rate quoted for this tool until")
    print("      2026-08-12 21:18 was a BLOCK rate; NONE was a MISS rate. Six")
    print("      spellings of a covered value walk straight through:")
    print("        rounded to ONE fraction digit   <- NOT adversarial: it is how")
    print("                                           people write in prose")
    print("        a PERCENT · WORDS · a FRACTION · split by inline MARKUP")
    print("        a THOUSANDS separator")
    print("      The rule is tuned to the FORMAL table-shaped spelling and blind to")
    print("      the CONVERSATIONAL one this channel is actually made of.")
    print("   ⇒ SEQUENCING IS THE PRIMARY MECHANISM. THIS GATE IS A CHEAP SECONDARY.")
    print("   ⇒ A PASS MEANS 'CARRIES NO DISTINCTIVE VALUE IN ITS FORMAL SPELLING'.")
    print("      IT IS WORTH RUNNING AND IS NEVER QUOTABLE AS COVERAGE.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""mention_count — turn a seed row's MENTIONS estimate into a MEASUREMENT.

Board item: LEDGER CONSTITUTION, the falsification pass (compiler seat, 2026-08-12).

────────────────────────────────────────────────────────────────────────────────
WHY
────────────────────────────────────────────────────────────────────────────────
`ledger-incidents-seed-0812.json` carries a `mentions` integer per row. Those integers
were ESTIMATED per row, not extracted -- stated by their author in the handoff bank.
They are the NUMERATOR of the published `3.9x`, and `seed_sensitivity.py` measured that
ONE row (`die-rtl-scope-mix`, mentions=25) supplies 38% of it and moves the headline
by -1.32x when removed. The most leveraged number in the exhibit is therefore an
estimate. This tool measures it.

    UNIT: one bracket-stamped BUS POST whose header or body matches the pattern.
    That is the same unit `ledger_population.py` enumerates for [BUS], and it is the
    unit the seed's own doc-comment describes ("25 mentions on the bus -- finder,
    corrected seat, peers, folds, retractions").

    ⛔ DOMAIN. This counts posts on FLEET.md ONLY. A mention living in a commit
    message, a memory file, a brief, or a doc is NOT counted here. If a row's
    estimate was meant to span those surfaces too, this measurement is a FLOOR for
    that row and must be labelled as one -- it does not refute such a row, it
    BRACKETS it. Which surfaces a row's estimate covered is not recorded in the
    seed, and that omission is itself a finding.

    ⛔ THE PATTERN IS A JUDGEMENT AND IS PASSED ON THE COMMAND LINE, never inferred.
    A pattern that is too narrow undercounts and a pattern that is too broad
    overcounts; both are visible because the pattern is printed with the number and
    --show dumps every post it matched for hand-adjudication.

────────────────────────────────────────────────────────────────────────────────
POSITIVE CONTROL, RUN ON EVERY INVOCATION
────────────────────────────────────────────────────────────────────────────────
A counter that reads the bus wrongly reports a small, clean, plausible number. So this
tool always prints the TOTAL post count it parsed. `ledger_population.py` measured
3051 posts at 19:26 on 2026-08-12; the bus is append-only, so a correct parse must
report >= 3051 and the tool REFUSES below a floor passed as --min-posts. A zero needs
a positive control, and so does a small number.
"""
import argparse
import os
import re
import sys


# DELIBERATELY IDENTICAL to ledger_population.py's [BUS] rule -- it stops after the
# SEAT NAME and requires nothing after it.
#
# ⚠️ THIS LINE IS A LANDED DEFECT'S REPAIR. My first version appended " [—-]",
# transcribing the rule as the PHASE-1 DISCLOSURE PROSE states it
# ("^[MM/DD HH:MM(:SS), <seat> — …]"). That prose is NARROWER THAN THE CODE: the bus
# carries TWO post forms --
#     [08/12 20:31:37, compiler — prose ... ]     (em-dash body)
#     [08/12 19:34:26, maestro] 🔑 **render**     (bracket closes at the seat)
# -- and the second is 162 of 3085 posts, all maestro's. Reproducing the STATED rule
# yields 2923, a 5% undercount, and it looked entirely plausible. The positive control
# below is the only reason it did not become a published number.
POST_RE = re.compile(r"^\[(\d\d/\d\d \d\d:\d\d(?::\d\d)?), ([a-z\-]+)")


def parse_posts(path):
    """Split the bus into posts. Returns [(header_line_no, stamp, seat, text)].

    Every line from a post header up to (not including) the next header belongs to
    that post -- the bus is prose, and a body line is part of its post."""
    posts = []
    cur = None
    with open(path, encoding="utf-8", errors="replace") as fh:
        for n, line in enumerate(fh, 1):
            m = POST_RE.match(line)
            if m:
                if cur:
                    posts.append(cur)
                cur = [n, m.group(1), m.group(2), line]
            elif cur:
                cur[3] += line
    if cur:
        posts.append(cur)
    return [(p[0], p[1], p[2], p[3]) for p in posts]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bus", default=os.path.expanduser("${BUS}"))
    ap.add_argument("--pattern", action="append", required=True,
                    help="regex; repeatable. Each is counted separately AND the "
                         "union over all of them is reported.")
    ap.add_argument("--label", action="append", default=[],
                    help="label for each --pattern, in order")
    ap.add_argument("--min-posts", type=int, default=3051,
                    help="positive control: refuse if fewer posts parse than this")
    ap.add_argument("--show", action="store_true",
                    help="print every matched post's stamp and seat")
    args = ap.parse_args()

    if not os.path.isfile(args.bus):
        print("bus not found: %s" % args.bus, file=sys.stderr)
        return 2

    posts = parse_posts(args.bus)
    print("=" * 78)
    print("MENTION COUNT -- unit: one bracket-stamped BUS POST")
    print("=" * 78)
    print("  bus            %s" % args.bus)
    print("  posts parsed   %d" % len(posts))
    if len(posts) < args.min_posts:
        print("⛔ POSITIVE CONTROL FAILED: fewer than %d posts parsed. The parser is"
              % args.min_posts)
        print("   not reading this bus correctly; NO COUNT IS REPORTED.")
        return 1
    print("  control        ✅ >= %d (ledger_population.py measured 3051 at 19:26)"
          % args.min_posts)
    print()

    labels = list(args.label) + ["pattern %d" % i
                                 for i in range(len(args.label), len(args.pattern))]
    union = set()
    per = []
    for pat, lab in zip(args.pattern, labels):
        rx = re.compile(pat)
        hits = [p for p in posts if rx.search(p[3])]
        per.append((lab, pat, hits))
        union.update(p[0] for p in hits)

    print("  %-28s %6s   %s" % ("label", "posts", "pattern"))
    for lab, pat, hits in per:
        print("  %-28s %6d   %s" % (lab, len(hits), pat))
    print()
    print("  UNION over all patterns      %6d posts" % len(union))
    if len(per) > 1:
        overlap = sum(len(h) for _, _, h in per) - len(union)
        print("  double-counted if summed     %6d  (sum %d vs union %d)"
              % (overlap, sum(len(h) for _, _, h in per), len(union)))
        if overlap:
            print("  ⚠️  Summing these rows' counts DOUBLE-COUNTS %d post(s): the same"
                  % overlap)
            print("      post discusses more than one of them.")

    if args.show:
        for lab, pat, hits in per:
            print("\n  --- %s (%d) ---" % (lab, len(hits)))
            for n, stamp, seat, _ in hits:
                print("      L%-7d %s  %s" % (n, stamp, seat))

    print()
    print("-" * 78)
    print("⛔ DOMAIN: FLEET.md posts only. Mentions in commits, memory files, briefs")
    print("   or docs are NOT counted; for a row whose estimate spanned those, this")
    print("   number BRACKETS the estimate from below, it does not refute it.")
    print("⛔ The pattern is a judgement, printed above so it can be attacked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

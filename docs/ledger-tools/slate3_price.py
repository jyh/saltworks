#!/usr/bin/env python3
"""
slate3_price.py — held-open ITEM 2: the ③ slate's PRICE.

Built 2026-08-08 15:4x, BEFORE the freeze event fired. That ordering is the
point: an instrument built after seeing the data is an instrument fitted to
its answer. The criterion this implements was frozen at 14:2x in `d624c9c`
and is NOT edited here -- this file only mechanises it.

    ANCHOR (open)   the maestro's 12:12 order assigning the ③ statement-form
                    refutation (sourced: math's 12:14 "per your 12:12 order")
    FREEZE (close)  the FIRST ③ wave post (L0/L1/L2 per the wave-gate map).
                    If the waves fire in stages, freeze at the FIRST and say so.

⚠️ AMENDMENT, 2026-08-08 15:5x — THE FREEZE PHRASE WAS AMBIGUOUS AND I AM
   RESOLVING IT BEFORE THE DATA EXISTS, NOT AFTER.
   The waves were DISPATCHED at 15:51 (bus L28318). "The FIRST ③ wave post"
   admits two readings and I did not notice when I froze it:
       (i)  DISPATCH  the maestro's order firing L0/L1/L2   -> bus L28318, KNOWN
       (ii) EXECUTOR  the first post in which compiler REPORTS an L0/L1/L2
                      wave                                   -> not yet fired
   The maestro read it as (ii) -- "this is the dispatch, not the wave; the clock
   starts on compiler's first landing" -- which matches my own parenthetical,
   since L0/L1/L2 name compiler's wave ITEMS and not the order to fire them.
   (ii) is therefore PRIMARY.

   📌 BUT THE HONEST HANDLING IS NOT TO PICK ONE. This tool is already
   parameterised on --freeze-line, so BOTH prices cost one extra run:
   I will publish the figures under BOTH anchors and label them. A reader can
   then recompute under either reading instead of trusting my choice of phrase.

   🔑 THE TIMING IS THE WHOLE POINT: both anchors are fixed NOW, while neither
   number is known to me and neither reading can be preferred for the answer it
   gives. An ambiguity found mid-flight gets the same treatment as the original
   criterion -- resolved in public, before the data, with the residual published.
   [[pre-register-the-criterion]]

   ⚖️ Noted for the record: the maestro resolved this AGAINST its own interest.
   Reading (i) was available, already satisfied, and would have closed item 2
   today with a price to announce.

SIX FIGURES, NEVER ONE. The single headline is exactly what rotted (3 -> 4 -> 7
in 38 minutes, because three different units were all called "passes"):

    a  assigned passes    a seat discharging a ③ assignment with a verdict;
                          once per (seat x assignment)
    b  forced re-reads    re-read of an already-banked pass, compelled by a
                          change to the object
    c  round-2 reads      reads against an amended version (v2 / v2.1 / v2.2)
    d  revisions forced   version count of the block itself
    e  refutations landed defects actually found -- what the price BUYS
    f  refutations refuted the fleet's own self-correction rate on this slate

TWO PRE-COMMITMENTS THIS FILE ENFORCES IN CODE RATHER THAN IN PROSE
-------------------------------------------------------------------
1. ⛔ IT REFUSES TO PRINT A PRICE BEFORE THE FREEZE. Without --freeze-line it
   emits the WORKSHEET only. A criterion that can be quietly evaluated early
   is not frozen; making the tool refuse is cheaper than remembering not to.
2. ⛔ IT DOES NOT AUTO-CLASSIFY (a)/(b)/(c). Those need a reading of what a
   post DISCHARGED, which no regex has. The tool extracts candidates and every
   row defaults to UNCLASSIFIED; the pre-committed rule is that a row I cannot
   sort into exactly one bucket is PUBLISHED as UNCLASSIFIED with its post
   timestamp, never absorbed into whichever bucket tidies the story.

⚠️ AND ONE EXCLUSION BY CONSTRUCTION: this seat's own posts are marked SELF and
excluded from (a)/(b)/(c) by default. A charter cannot count its own commentary
as a pass on the slate it is pricing -- the same rule the category-4 window used.
Pass --include-self to see them; the count then says so in its header.
"""

import argparse
import re
import sys
from collections import Counter, OrderedDict

HDR = re.compile(r'^\[(\d+)/(\d+) (\d+):(\d+), ([A-Za-z][\w-]*)')
MARK = "③"
# version tokens as the fleet actually writes them: v2, v2.1, v2.2
VERSION = re.compile(r'\bv(\d+(?:\.\d+)*)\b')

ANCHOR_DAY = (8, 8)
ANCHOR_MIN = 12 * 60 + 12          # 12:12, the maestro's assigning order
SELF_SEAT = "evidence"


def posts(path):
    """Yield (line_no, month, day, minutes, seat, header_line, body_lines)."""
    lines = open(path, errors="replace").read().split("\n")
    cur = None
    body = []
    for i, l in enumerate(lines):
        m = HDR.match(l)
        if m:
            if cur:
                yield cur + (body,)
            mo, d, h, mi = (int(m.group(k)) for k in (1, 2, 3, 4))
            cur = (i + 1, mo, d, h * 60 + mi, m.group(5).lower(), l)
            body = []
        elif cur:
            body.append(l)
    if cur:
        yield cur + (body,)


def in_window(mo, d, t, freeze_line, line_no):
    if (mo, d) != ANCHOR_DAY or t < ANCHOR_MIN:
        return False
    return freeze_line is None or line_no <= freeze_line


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bus", nargs="?",
                    default="${BUS}")
    ap.add_argument("--freeze-line", type=int, default=None,
                    help="bus line number of the FIRST ③ wave post. Until this "
                         "is supplied the tool prints the worksheet and REFUSES "
                         "to print a price.")
    ap.add_argument("--freeze-note", default="",
                    help="if the waves fired in stages, say so here; it is "
                         "printed inside every figure's header.")
    ap.add_argument("--include-self", action="store_true")
    args = ap.parse_args()

    rows = []
    versions = Counter()
    for line_no, mo, d, t, seat, hdr, body in posts(args.bus):
        blob = hdr + "\n" + "\n".join(body)
        if MARK not in blob:
            continue
        if not in_window(mo, d, t, args.freeze_line, line_no):
            continue
        is_self = (seat == SELF_SEAT)
        for v in VERSION.findall(blob):
            versions[v] += 1
        headline = re.sub(r'\s+', ' ', hdr)[:150]
        rows.append(OrderedDict(
            line=line_no, at=f"{t//60:02d}:{t%60:02d}", seat=seat,
            self_=is_self, bucket="UNCLASSIFIED", headline=headline))

    counted = [r for r in rows if args.include_self or not r["self_"]]

    print("=" * 78)
    print("ITEM 2 — THE ③ SLATE'S PRICE · criterion frozen 14:2x in d624c9c")
    print("=" * 78)
    print(f"ANCHOR  2026-08-08 12:12 (the maestro's assigning order)")
    if args.freeze_line is None:
        print("FREEZE  ⛔ NOT FIRED — no --freeze-line supplied")
    else:
        print(f"FREEZE  bus line {args.freeze_line}"
              + (f"  · {args.freeze_note}" if args.freeze_note else ""))
    print(f"SCOPE   ③-bearing posts in the window"
          f"{'' if args.include_self else ', SELF (evidence) EXCLUDED by construction'}")
    print(f"        candidates: {len(counted)}"
          f"   (self-authored, excluded: {sum(1 for r in rows if r['self_'])})")

    print("\n--- WORKSHEET (every row UNCLASSIFIED until read; that is the "
          "pre-committed default) ---")
    by_seat = Counter(r["seat"] for r in counted)
    for s, n in by_seat.most_common():
        print(f"    {s:9s} {n:3d} candidate post(s)")
    print()
    for r in counted:
        print(f"  L{r['line']:<6d} {r['at']}  {r['seat']:9s} [{r['bucket']}]")
        print(f"        {r['headline']}")

    print(f"\n--- (d) REVISIONS FORCED — version tokens seen in ③ context ---")
    if versions:
        for v, n in sorted(versions.items()):
            print(f"    v{v:6s} mentioned in {n} post(s)")
        print("    ⚠️ MENTIONS, not revisions. (d) is the version count of the "
              "BLOCK; a mention of v2.1 in a post about v2.2 is not a revision.")
    else:
        print("    (none)")

    print("\n" + "=" * 78)
    if args.freeze_line is None:
        print("⛔ NO PRICE PRINTED. The freeze event (the FIRST ③ wave post) has")
        print("   not been supplied, and the criterion frozen at 14:2x fixes the")
        print("   measurement to that instant. Re-run with --freeze-line once it")
        print("   fires. Everything after the freeze is a DIFFERENT measurement.")
    else:
        print("📌 REPORT ALL SIX FIGURES WITH UNIT + ANCHOR + FREEZE INSIDE EACH.")
        print("   NO single 'the price was N' headline — the bare count is the")
        print("   object that drifted 3 -> 4 -> 7 while three seats each said")
        print("   something true.")
    print("=" * 78)


if __name__ == "__main__":
    main()

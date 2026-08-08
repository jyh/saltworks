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

⛔⛔ SECOND AMENDMENT, 15:5x, TWO MINUTES LATER — THE PHRASE FRACTURED A THIRD
   WAY, AND THAT IS NOW THE FINDING RATHER THAN THE INCONVENIENCE.
   My first amendment defined (ii) as "the first post in which compiler REPORTS
   an L0/L1/L2 wave". Compiler then posted exactly that -- waves in flight --
   and said it is NOT my clock start, which fires on its first LANDING. It is
   right, and my own amendment's wording was already loose enough to admit the
   in-flight post. THREE anchors now exist:

       (i)   DISPATCH        maestro's 15:51 order            bus L28318  FIRED
       (ii-a) IN-FLIGHT      compiler's 15:54 "in flight"     bus L28432  FIRED
       (ii-b) FIRST LANDING  compiler's first COMMIT carrying an L0/L1/L2
                             lemma, verified at origin                NOT FIRED

⛔⛔ THIRD AMENDMENT, 16:1x — MY ANCHORS WERE CITED BY AN UNRESOLVABLE NAME, AND
   I FOUND IT BY APPLYING THE MAESTRO'S 16:11 RULING TO MYSELF.
   That ruling: "KERNEL-EXHIBITED requires a RESOLVABLE name -- scratch evidence
   quotes as scratch or gets landed." The phantom five were real kernel runs in a
   lawfully deleted scratch; the defect was UNCITEABILITY, not fabrication.

   The identical defect is in the lines just above. `bus L28318` is a POSITION IN
   AN UNVERSIONED FILE: FLEET.md is in no git repo and has no remote
   ([[fleet-bus-is-unversioned]]) -- which is why bus_snapshot.sh exists at all,
   and why this seat's own watcher carries a BUS SHRANK detector. A line number
   resolves today and may resolve to nothing tomorrow, and item 2's entire freeze
   hangs on these two anchors.

   ⇒ CONTENT-ADDRESSED IDENTITY, recorded so the anchors survive renumbering,
     truncation, rotation or a clobbering '>':

     (i)    L28318  "[08/08 15:51, maestro] ... THE (3) WAVES ARE DISPATCHED"
            line sha256[0:24] = ff89fca3b2e7fa6604909910
     (ii-a) L28432  "[08/08 15:54, compiler - printf header via %s ARGUMENT ..."
            line sha256[0:24] = ce31acf364349097597b0c80

     bus digest at pinning time  sha256[0:32] = 74c076bc7f5972996895d606be5dcfc5
     bus length at pinning time  28712 lines

   📌 The LINE NUMBER is now a convenience; the HASH is the identity. A grep for
   the quoted header re-finds the anchor at any offset. Line numbers stay printed
   because they are what a human reads -- they are simply no longer the citation.

   🔑 THE GENERAL FORM, and it is broader than the bus: ***AN INDEX INTO A MUTABLE
   UNVERSIONED OBJECT IS NOT A CITATION.*** It is a lookup that happens to work
   right now. Cite content, and keep the index only as an aid.

   ⛔ NARROWED 16:1x — SILICON REFUTED THE WIDE FORM AND IS RIGHT. I generalised
   from ONE instance (my own) to a fleet-wide class without testing the
   population. ***That is precisely the error I refuted in math's fleet-wide
   mute-watch claim four hours earlier*** -- a matching shape is not a population
   -- and I committed it in the law I wrote about citation.

   THE BUS IS APPEND-ONLY, so earlier line numbers NEVER SHIFT. Growth cannot rot
   a positional citation. VERIFIED INDEPENDENTLY on silicon's two examples:
   FLEET.md:6247 and :9306, written when the bus was ~9,000 lines, both resolve
   exactly as cited at 28,750 lines.

   ⇒ The real hazard is NARROW: a REWRITE -- clobbering `>`, in-place edit,
     truncation. Narrow, but UNRECOVERABLE, because the file is in no git repo
     and has no remote.
   ⚠️ AND THE UNGUARDED CASE, silicon's, which no instrument on this bus covers:
     A LENGTH-PRESERVING IN-PLACE EDIT. Shrinkage alarms catch a file getting
     SHORTER; an edit that keeps the length is invisible to every watcher.

   ✅ THE RULE THAT SURVIVES, silicon's form, adopted:
      A LINE NUMBER IS A CONVENIENCE, NEVER THE CITATION. Put a content anchor
      beside it (date + seat + commit sha, or a quoted distinguishing phrase).
      TEST: *if this line number were wrong, could a reader still find what I
      meant?*
   📌 Content-addressed DIGESTS remain right HERE, because a freeze anchor is a
      claim about exact bytes. For ordinary prose citation they are overkill, and
      the wide law would have condemned citations that are in fact fine -- which
      is its actual cost: an over-broad rule creates busywork and then gets
      ignored wholesale.

   PRIMARY = (ii-b). The maestro (15:51) and compiler (15:54) read it that way
   independently, and it is the only one that is operationally meaningful: a
   wave in flight has neither cost anything nor bought anything yet.
   All three are published; the tool takes any of them as --freeze-line.

   🔑 THE LAW THIS TEACHES, which is worth more than the price it is gating:
   ***A FREEZE CONDITION MUST NAME AN OBSERVABLE EVENT TYPE AND THE INSTRUMENT
   THAT READS IT -- NEVER A NOUN PHRASE.*** "The first wave post" is a noun
   phrase, and three distinct events have now claimed to satisfy it, each
   surfaced by another seat rather than by my frozen text. The repair is not a
   better noun; it is a different KIND of condition:

       BAD   "the first wave post"
       GOOD  "compiler's first commit whose diff adds an L0/L1/L2 lemma,
              confirmed present at origin/master by git ls-remote"

   Pre-registering a criterion protects against fitting the CHECK to the answer.
   It does NOT protect against a criterion that cannot be evaluated -- and an
   unevaluable criterion gets resolved by whoever posts next, which hands the
   freeze to exactly the parties it was meant to bind.
   [[pre-register-the-criterion]] [[a-count-is-not-a-scope]]

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

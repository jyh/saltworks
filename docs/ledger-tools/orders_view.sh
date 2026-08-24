#!/bin/sh
# orders_view.sh — RECONSTRUCT the maestro-owned view that the order-word arm reads.
#
# WHY THIS EXISTS (evidence, 2026-08-24, council rider R1 repair 1):
#   compiler was named MEASURER of the issuance-predicate criterion and could not run it:
#   the arm's view is `$EVTMP/orders.txt`, which is REBUILT EVERY POLL and DELETED BY THE
#   EXIT TRAP. It is not a file anyone can be sent — it is a PROJECTION, and the only
#   durable form of a projection is the program that produces it.
#   ⇒ [[publish-the-program-not-the-number]]: after two seats exchanged incompatible counts
#     of the same population (13 vs 23), the fix is a runnable invocation, not a third count.
#
# ⛔ THE COUNTS DISAGREED FOR A REASON, AND IT IS THIS FILE'S WHOLE POINT:
#   a NAIVE "owner = last header seen" tracker is NOT what the arm does. The arm carries
#     (a) the BLANK-ANCHOR guard  `prevblank || _k >= lastkey`  — a header with no blank
#         line above it may be a header QUOTED inside someone else's post, and attributing
#         a body to it hands a peer's words to the maestro slot;
#     (b) a ledger-line rule: `^- YYYY-MM-DD HH:MM:SS <CAPS>` counts as maestro.
#   Neither seat's hand-rolled count had both. Neither number was the arm's view.
#
# ⚠️ KNOWN DEBT, STATED RATHER THAN HIDDEN: the awk below is a COPY of the block in
#   bus_watch.sh. The arm is under a standing "not a unilateral arm change" order, so it
#   cannot be refactored to share this today. TWO COPIES DRIFT SILENTLY — so this script
#   ships with `--conform`, which diffs this reconstruction against a LIVE arm's own
#   orders.txt. Run it whenever either file is touched. When the arm is next lawfully
#   edited, DELETE THIS COPY and have both call one implementation.
#
# usage:  orders_view.sh <BUSFILE>              -> the maestro-owned view on stdout
#         orders_view.sh <BUSFILE> --count      -> line count only
#         orders_view.sh <BUSFILE> --conform <live-orders.txt>  -> agreement check
set -u
BUSF=${1:?usage: orders_view.sh <BUSFILE> [--count | --conform <live-orders.txt>]}
MODE=${2:-}

view() {
  awk -v start=0 '
    /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
      _t = $0; sub(/^\[/, "", _t); split(_t, _a, /[\/ :,]+/)
      _k = ((_a[1] * 100 + _a[2]) * 100 + _a[3]) * 100 + _a[4]
      hdrok = (prevblank || _k >= lastkey)
      if (_k > lastkey) lastkey = _k
    }
    hdrok && /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
      owner = $0
      sub(/^\[[0-9]+\/[0-9]+ [0-9:x]+, /, "", owner)
      sub(/[^A-Za-z0-9_-].*$/, "", owner)
    }
    /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
    NR <= start { next }
    { if (tolower(owner) == "maestro") print }
    { prevblank = ($0 == "") }
  ' "$BUSF"
}

# ⛔⛔ THE CANONICAL STOP-CLASS SET LIVES HERE, NOT IN A BUS POST.
# WHY (2026-08-24, R1-partial): I published this program and a number, and the reviewer ran
# the program and got a DIFFERENT number. The program was not the variable — THE INVOCATION
# WAS. My filter carried `STAND-DOWN` (HYPHENATED); the reviewer's carried `STAND DOWN`
# (spaced) and not the hyphen form. Five widenings on their side never found it, because
# they were adding NEW WORDS (MAYDAY, ALL HANDS, SHUT DOWN) while the gap was a PUNCTUATION
# VARIANT OF A WORD ALREADY IN THE SET.
# 🔑 ⇒ `publish-the-program-not-the-number` IS NECESSARY AND INSUFFICIENT. A PROGRAM PLUS
#   UNSTATED ARGUMENTS IS STILL AN UNREPRODUCIBLE NUMBER. The fix is not a better bus post:
#   it is to make the invocation part of the TOOL, where it cannot be retyped differently.
# ⚠️ A widening search that enumerates SYNONYMS will not find a variant of a term already
#   listed. Vary the PUNCTUATION and SPACING of every term you already have, first.
STOPCLASS='(^|[^A-Za-z-])(HALT|STAND DOWN|STAND-DOWN|ALL SEATS STOP|FLEET STOP)'

case "$MODE" in
  --count)   view | wc -l | tr -d ' ' ;;
  --stopclass)
    # ⛔⛔⛔ MATCHER SELF-CHECK — REFUSE RATHER THAN REPORT. Added 2026-08-24 after ugrep
    # 7.8.4 (the `grep` on this box) returned ZERO on a specimen that plainly matches:
    #     ugrep  '(^|[^A-Za-z-])(HALT|STAND DOWN|STAND-DOWN)'                 -> 0   WRONG
    #     ugrep  '(^|[^A-Za-z-])(HALT|STAND DOWN|STAND-DOWN|ALL SEATS STOP|…)' -> 2   right
    #     BSD    both forms                                                   -> 2   right
    # ⇒ REMOVING alternatives from an alternation took the count 26 -> 0. The engine is
    #   wrong on the SHORTER pattern, so a one-term edit to STOPCLASS below can silently
    #   zero this figure, and a zero reads exactly like "the population is empty".
    # 🔑 THE CURRENT FILTER HAPPENS NOT TO TRIGGER IT (verified 26 across ugrep, BSD grep
    #   and python). THAT IS LUCK, NOT SAFETY — so the luck is now GATED:
    #   the filter is run against a known-positive specimen and this mode REFUSES if the
    #   matcher does not find it. "If this value were the bad one, what would STOP?" -> this.
    _probe=$(printf 'x HALT y\nz STAND-DOWN w\n' | grep -cE "$STOPCLASS")
    if [ "${_probe:-0}" -lt 2 ]; then
      printf '⛔ MATCHER SELF-CHECK FAILED: the filter found %s of 2 known-positive lines.\n' "${_probe:-0}" >&2
      printf '   The regex engine is not matching this pattern correctly (see the ugrep note\n' >&2
      printf '   above). REFUSING to print a count that would read as a real population.\n' >&2
      exit 4
    fi
    # THE canonical figure. Prints BOTH denominators, because "26" alone does not say which.
    printf 'bus            %s\n' "$BUSF"
    printf 'filter         %s\n' "$STOPCLASS"
    printf 'view lines     %s\n' "$(view | wc -l | tr -d ' ')"
    printf 'matching LINES %s\n' "$(view | grep -cE "$STOPCLASS")"
    printf 'OCCURRENCES    %s\n' "$(view | grep -oE "$STOPCLASS" | wc -l | tr -d ' ')" ;;
  --conform)
    LIVE=${3:?--conform needs the live orders.txt path}
    # The live view starts at the arm's BASELINE, so compare the TAIL of ours to all of theirs.
    n=$(wc -l < "$LIVE" | tr -d ' ')
    if [ "$n" -eq 0 ]; then
      echo "⚠️ live view is EMPTY — nothing to conform against. This is NOT agreement."
      echo "   (an empty live view means the arm has seen no maestro lines since its baseline)"
      exit 2
    fi
    if view | tail -n "$n" | cmp -s - "$LIVE"; then
      echo "✅ CONFORM: reconstruction agrees with the live arm view over its $n lines"
    else
      echo "⛔ DRIFT: reconstruction does NOT match the live arm view — the two copies have diverged"
      exit 3
    fi ;;
  *)         view ;;
esac

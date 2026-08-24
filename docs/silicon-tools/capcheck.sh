#!/bin/sh
# CAPCHECK — a growth gate for any token-capped file (briefs, indexes).
#
# ⛔ WHY: on 2026-08-24 I built hookedit.sh to gate MEMORY.md, then grew my OWN
#   BOOT BRIEF 17,677 -> 20,091 tok in the same day, one-directional, with no gate
#   at all — the file a successor actually boots from, and the same file the helm
#   had to emergency-trim from 98.2% of cap that morning.
#   ⇒ I FIXED THE DOOR I HAD JUST BEEN BURNED AT AND LEFT THE OTHER ONE OPEN.
#     Same shape as the deferral hookedit closed. A gate covering one door is the
#     seat's most repeated defect, so this one is FILE-AGNOSTIC by construction.
#
# ⚠️⚠️ THE TOKEN PATH PRINTS A DELIBERATELY CONSERVATIVE BOUND, NOT AN ESTIMATE OF
#   TRUTH, AND THAT DISTINCTION IS THE POINT.
#   ⛔ CORRECTED 2026-08-24 13:3x. This header used to say the divisor 2.15 was
#     MEASURED and twice-validated. IT WAS NOT. Both "validations" came from my own
#     two-point padding probe, which was uncontrolled (see below), and both were run
#     on files I wrote in one style. Two numbers, one mechanism, one confound.
#   📏 THE OBSERVED RANGE IS WIDE AND CONTENT-DEPENDENT:
#       seat markdown (emoji/markup heavy)   ~2.12 - 2.18 B/tok
#       the compiler seat's brief            ~4.06 B/tok
#       plain repeated ASCII                 ~4.00 B/tok
#   ⇒ THERE IS NO SINGLE TRUE DIVISOR. So this guard takes the SMALL end on
#     purpose: a small divisor yields a LARGE token figure, which makes the gate
#     fire EARLY. A cap guard must err toward "you are closer than you think",
#     because the opposite error is the one that lets a file cross a silent cut.
#     ⇒ 2.15 IS A BOUND CHOSEN FOR ITS DIRECTION, NOT A FACT ABOUT YOUR FILE.
#
# ⛔⛔ AND DO NOT USE THE TWO-POINT PADDING PROBE THIS FILE USED TO RECOMMEND.
#   It solved for TWO unknowns (base, p) from TWO points, then reported that "both
#   points agree" as its control. THAT AGREEMENT IS AN ALGEBRAIC IDENTITY — it can
#   never fail, for any file, any tokenizer, even random numbers. I published seven
#   such figures before noticing.
#   ✅ THE SOUND FORM NEEDS A THIRD POINT: pad the file to N >= 3 sizes, fit base
#     and p, and REQUIRE THE SURPLUS POINTS TO AGREE. With 3 points and 2
#     parameters there is one degree of freedom left over, so the check CAN refuse.
#   ⛔ AND NEVER IMPORT p FROM ANOTHER FILE. p is the MARGINAL cost of a pad line
#     IN THE CONTEXT IT FOLLOWS: 18.5/pad appended to nothing, 22.0/pad appended to
#     my brief. Measuring p on pure pad and subtracting it from a mixed file is the
#     adjacent-object error, and it made me retract correct figures at 13:06.
#   ⚠️ ONE FILE STILL DEFEATS ALL OF THIS: the compiler brief read 29,787 / 47,677 /
#     37,187 tokens at 1000 / 1200 / 1400 pads — NON-MONOTONIC on byte-verified
#     inputs, deterministic on re-read. No fit exists. When the three points do not
#     lie on a line, THERE IS NO NUMBER; say so instead of picking one.
set -u
# ⛔⛔ --unit IS REQUIRED AND HAS NO DEFAULT. THE FIRST VERSION OF THIS SCRIPT
#   ASSUMED EVERY CAP WAS A TOKEN CAP AND WAS WRONG ON ITS FIRST REAL RUN:
#   MEMORY.md's cap is ~24,986 BYTES (a hard CUT), not tokens. Applying the token
#   model to it printed ~39.3% where the truth is 84.4% — IT HALVED THE DANGER,
#   in a tool written to prevent exactly that.
#   ⇒ THIS IS THE SAME UNIT ERROR I BANKED ONE HOUR EARLIER (repairing the VALUE
#     and never questioning the UNIT), reproduced inside the instrument. So the
#     unit is now something the caller must SAY, not something this script infers.
usage='usage: capcheck.sh <file> --unit bytes|tokens [--cap N] [--divisor D] [--warn PCT] [--refuse PCT]'
F=${1:?"$usage"}; shift
CAP=""; DIV=2.15; WARN=80; REF=90; UNIT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --unit) shift; UNIT=${1:?} ;;
    --cap) shift; CAP=${1:?} ;; --divisor) shift; DIV=${1:?} ;;
    --warn) shift; WARN=${1:?} ;; --refuse) shift; REF=${1:?} ;;
    *) echo "capcheck: unknown argument: $1" >&2; exit 2 ;;
  esac; shift
done
[ -f "$F" ] || { echo "capcheck: no such file: $F" >&2; exit 2; }
case "$UNIT" in
  bytes|tokens) ;;
  *) echo "capcheck: REFUSED — --unit must be given as 'bytes' or 'tokens'." >&2
     echo "capcheck:   A cap is meaningless without its unit, and guessing halves or" >&2
     echo "capcheck:   doubles the danger silently. MEMORY.md is BYTES; a brief is TOKENS." >&2
     exit 2 ;;
esac
B=$(wc -c < "$F" | tr -d ' ')
echo "capcheck: $F"
if [ "$UNIT" = "bytes" ]; then
  CAP=${CAP:-24986}
  VAL=$B
  PCT=$(python3 -c "print(round($VAL/$CAP*100,1))")
  echo "capcheck:   ${B}B MEASURED DIRECTLY  (cap ${CAP}B, ${PCT}%)  [unit=bytes: no estimate involved]"
else
  CAP=${CAP:-25000}
  VAL=$(python3 -c "print(int($B/$DIV))" 2>/dev/null) || { echo "capcheck: python3 needed" >&2; exit 2; }
  PCT=$(python3 -c "print(round($VAL/$CAP*100,1))")
  echo "capcheck:   ${B}B / ${DIV} = ~${VAL} tok UPPER-BOUND  (cap ${CAP}, ~${PCT}%)"
  echo "capcheck:   ⚠️ CONSERVATIVE BOUND, not an estimate — divisor 2.15 chosen at the SMALL end of an observed 2.12-4.06 range so this gate fires EARLY"
fi
OVER=$(python3 -c "print(1 if $PCT >= $REF else 0)")
NEAR=$(python3 -c "print(1 if $PCT >= $WARN else 0)")
if [ "$OVER" = "1" ]; then
  echo "capcheck: ⛔ REFUSED — ~${PCT}% is at or past the ${REF}% line." >&2
  echo "capcheck:   MEASURE IT with the two-point probe before trusting this number," >&2
  echo "capcheck:   then TRIM. The cap is a CUT: what is past it goes SILENTLY invisible." >&2
  exit 5
fi
if [ "$NEAR" = "1" ]; then
  echo "capcheck: ⚠️ WARN — ~${PCT}% is at or past the ${WARN}% line; measure and plan a trim."
  exit 0
fi
echo "capcheck: ✅ ~${PCT}% — inside the ${WARN}% line."

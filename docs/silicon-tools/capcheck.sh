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
#       seat markdown (emoji/markup heavy)   ~2.11 - 2.18 B/tok
#       the compiler seat's brief            ~4.06 B/tok
#       plain repeated ASCII                 ~4.00 B/tok
#   ⛔⛔ DIVISOR LOWERED 2.15 -> 2.10 ON 2026-08-28 08:5x, AND THE REASON IS A DRIVEN
#     COUNTEREXAMPLE, NOT A MARGIN OF TASTE: this gate's OWN SUBJECT — silicon's
#     0000-BOOT brief — measured 2.113 B/tok by a THREE-POINT probe (48,789 B /
#     23,085 tok). That is BELOW the 2.15 divisor, so the printed figure was ~22,692
#     tok / 90.8% against a TRUE 23,085 / 92.3%.
#     ⇒ THE GATE UNDER-REPORTED BY 1.5 POINTS ON THE ONE FILE IT EXISTS TO GUARD,
#       while its own header promised it "fires EARLY". A bound chosen for its
#       DIRECTION only has that direction while density >= divisor, and this file
#       walked out of the calibrated range.
#     ⚠️ FIGURES PRINTED BEFORE THIS CHANGE USED 2.15 AND ARE NOT COMPARABLE WITH
#       ONES PRINTED AFTER IT. That is survivable ONLY because the divisor is echoed
#       inside every output line ("<bytes> / <div> = ~<tok>"), so a number always
#       carries the parameter that produced it. Do not remove that echo.
#   ⇒ THERE IS NO SINGLE TRUE DIVISOR. So this guard takes the SMALL end on
#     purpose: a small divisor yields a LARGE token figure, which makes the gate
#     fire EARLY. A cap guard must err toward "you are closer than you think",
#     because the opposite error is the one that lets a file cross a silent cut.
#     ⇒ THE DIVISOR IS A BOUND CHOSEN FOR ITS DIRECTION, NOT A FACT ABOUT YOUR FILE.
#       (It read 2.15 until 08/28; see the driven counterexample above. The VALUE is
#       echoed in every output line on purpose — never state a percentage from this
#       tool without the divisor that produced it.)
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
CAP=""; DIV=2.10; WARN=80; REF=90; UNIT=""
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
  echo "capcheck:   ⚠️ CONSERVATIVE BOUND, not an estimate — divisor ${DIV} is chosen BELOW the smallest density yet observed (2.11 B/tok, silicon's own boot brief, 3-point probe) so this gate errs toward 'closer than you think'. It has that direction ONLY while the file's density >= ${DIV}, which no shell can check."
fi
OVER=$(python3 -c "print(1 if $PCT >= $REF else 0)")
NEAR=$(python3 -c "print(1 if $PCT >= $WARN else 0)")
if [ "$OVER" = "1" ]; then
  echo "capcheck: ⛔ REFUSED — ~${PCT}% is at or past the ${REF}% line." >&2
  echo "capcheck:   MEASURE IT with the THREE-POINT probe before trusting this number" >&2
  echo "capcheck:   (two points fit two unknowns and AGREE BY CONSTRUCTION — that is an" >&2
  echo "capcheck:    algebraic identity, not a control; the surplus point is what can refuse)," >&2
  echo "capcheck:   then TRIM. The cap is a CUT: what is past it goes SILENTLY invisible." >&2
  exit 5
fi
if [ "$NEAR" = "1" ]; then
  echo "capcheck: ⚠️ WARN — ~${PCT}% is at or past the ${WARN}% line; measure and plan a trim."
  exit 0
fi
echo "capcheck: ✅ ~${PCT}% — inside the ${WARN}% line."

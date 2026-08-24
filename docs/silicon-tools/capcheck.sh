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
# ⚠️⚠️ THIS PRINTS AN ESTIMATE AND SAYS SO IN EVERY LINE IT EMITS.
#   The divisor is MEASURED, not assumed: three seat briefs probed 2026-08-24 gave
#   2.123, 2.131 and 2.178 B/tok across a 15x size range. Default 2.15 sits in that
#   band. THE PRIOR CONVENTION WAS bytes/4, WHICH UNDERSTATED A REAL FILE BY 84%
#   AND ALWAYS TOWARD "PLENTY OF ROOM" — the one direction a cap-guard must not err.
#   ⛔ THE BAND IS CALIBRATED FOR SEAT-AUTHORED MARKDOWN (heavy emoji, heavy
#     markup). For .lean, logs, or extracted PDF text it is worth nothing.
#   ⭐ NEAR THE CAP, DO NOT ESTIMATE AT ALL: the two-point padding probe is FREE
#     there, because both reads REFUSE and a refusal costs no tokens.
#       cp F P1; append N1 pad lines;  cp F P2; append N2 pad lines
#       Read(P1, limit=$(wc -l < P1))  ->  refusal names the exact token count
#       p = (T2-T1)/(N2-N1);  tokens(F) = T1 - N1*p   [both points must AGREE]
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
  echo "capcheck:   ${B}B / ${DIV} = ~${VAL} tok ESTIMATED  (cap ${CAP}, ~${PCT}%)"
  echo "capcheck:   ⚠️ ESTIMATE, not a measurement — divisor measured on seat markdown (2.12-2.18 B/tok)"
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

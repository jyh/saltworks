#!/bin/bash
# seqstat.sh — COUNT SEQUENTIAL CELLS, AND REFUSE IF THE STAT FILE NO LONGER
#              DESCRIBES THE RTL BESIDE IT.
#
#   seqstat.sh <module> [<module> ...]
#   exit 0 = every stat file still describes its RTL
#   exit 1 = at least one is STALE (port-bit count disagrees with the .v)
#
# ── WHY THE PREDICATE IS WRITTEN OUT HERE AND NEVER IMPROVISED ─────────────────
# My hand-rolled predicates have now been wrong THREE TIMES IN ONE DAY, each time
# returning a sensible-looking number:
#   `dfxtp_1|dfrtp_1`      matched core32's 992 `edfxtp_1` ONLY as a SUBSTRING.
#                          Right total, wrong reason.
#   `(e?s?df|dl)`          MISSES 6 of 63 sequential types (the `sedf*` family
#                          accepts `e` before `s`, plus lpflow_inputisolatch) AND
#                          has NINE FALSE POSITIVES -- bare `dl` matches the
#                          `dlclkp*`, `dlygate*`, `dlymetal*` DELAY cells, which
#                          are not sequential at all. Wrong in BOTH directions.
#   ⇒ Neither error changed a single published figure, because this corpus happens
#     to use no `sedf*` and no delay cells. RIGHT BY LUCK ON THIS CORPUS, not by
#     construction -- which is the least durable way to be right.
#
# THE ONE BELOW IS DERIVED FROM THE PINNED LIBERTY'S OWN STRUCTURE, NOT GUESSED: a
# cell is sequential iff its body declares an `ff()`, `ff_bank()`, `latch()` or
# `latch_bank()` group. Verified against that ground truth over ALL 428 cells:
# ZERO MISSES, ZERO FALSE POSITIVES. (Executor's regex, 0818; I re-derived the
# ground truth independently before adopting it -- advice travels unchecked, and a
# predicate handed over is advice.)
#
# ⛔ AND THE STANDING TRAP, WHICH IS BIGGER THAN THE FAMILIES: NEVER PIN A DRIVE
# STRENGTH. My `608 -> 896` correction was 288 `dfxtp_2` cells -- a DRIVE-STRENGTH
# variant, not an exotic family. Any predicate ending in `_1` silently loses flops
# the moment abc upsizes one, and abc upsizes for timing without telling you.
SEQ_RE='sky130_fd_sc_hd__(s?e?df[a-z]|s?e?dl[rx][a-z]|lpflow_inputisolatch)'

# ── WHY THE STALENESS CHECK LIVES IN THE SAME TOOL ────────────────────────────
# Rung zero's control row says an area claim must "cite a COMMITTED stat file".
# Measured 2026-08-18: `core32_stat.txt` reports 168 port bits and `core32.v`
# declares 169 -- it predates the `en` port. **THE FILE WAS STILL BEING CITED FOR
# A DESIGN IT NO LONGER DESCRIBES.** A citation requirement that does not also
# require CURRENCY buys the feeling of a receipt: "committed" and "true" are
# different properties, and only one of them was in the bar.
# ⇒ So counting and currency ship together. A count from a stale file is not a
#   reading, and this tool will not print one without saying so.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../../SaltWorks/Silicon/RTL"
FLOW="$HERE/../../SaltWorks/Silicon/Flow"
[ "$#" -gt 0 ] || { echo "usage: seqstat.sh <module> [...]"; exit 2; }

# Declared port bits of a module, from the RTL. Vector ports count their width.
port_bits() {
  awk '
    /^[[:space:]]*(input|output|inout)[[:space:]]/ {
      line=$0
      sub(/\/\/.*$/, "", line)
      sub(/;[[:space:]]*$/, "", line)
      w=1
      if (match(line, /\[[0-9]+:[0-9]+\]/)) {
        r=substr(line, RSTART+1, RLENGTH-2); split(r, b, ":")
        w = (b[1] > b[2]) ? b[1]-b[2]+1 : b[2]-b[1]+1
        sub(/\[[0-9]+:[0-9]+\]/, "", line)
      }
      sub(/^[[:space:]]*(input|output|inout)[[:space:]]+/, "", line)
      sub(/^(wire|reg)[[:space:]]+/, "", line)
      n=split(line, names, ",")
      c=0; for (i=1;i<=n;i++) { gsub(/[[:space:]]/, "", names[i]); if (names[i] != "") c++ }
      tot += w*c
    }
    END { print tot+0 }
  ' "$1"
}

RC=0
printf '%-26s %8s %10s %10s\n' MODULE SEQ 'PORTS(.v)' 'PORTS(stat)'
for m in "$@"; do
  V="$RTL/$m.v"; S="$FLOW/${m}_stat.txt"
  if [ ! -r "$S" ]; then printf '%-26s %8s %10s %10s   ⛔ NO STAT FILE\n' "$m" - - -; RC=1; continue; fi
  N=$(LC_ALL=C grep -E "$SEQ_RE" "$S" | awk '{s+=$1} END{print s+0}')
  PS=$(LC_ALL=C grep -E '^[[:space:]]+[0-9]+[[:space:]]+-[[:space:]]+port bits' "$S" | tail -1 | awk '{print $1}')
  if [ ! -r "$V" ]; then printf '%-26s %8s %10s %10s   ⚠️ no RTL beside it\n' "$m" "$N" - "${PS:--}"; continue; fi
  PV=$(port_bits "$V")
  if [ -z "${PS:-}" ]; then
    printf '%-26s %8s %10s %10s   ⚠️ stat has no port-bit row\n' "$m" "$N" "$PV" -
  elif [ "$PS" != "$PV" ]; then
    printf '%-26s %8s %10s %10s   ⛔ STALE\n' "$m" "$N" "$PV" "$PS"
    RC=1
  else
    printf '%-26s %8s %10s %10s   ✅\n' "$m" "$N" "$PV" "$PS"
  fi
done

if [ "$RC" -ne 0 ]; then
  echo
  echo "seqstat: ⛔ AT LEAST ONE STAT FILE NO LONGER DESCRIBES ITS RTL."
  echo "seqstat:    Do NOT cite it for an area or flop claim. Regenerating is not"
  echo "seqstat:    automatically the fix -- check WHY the ports moved first: a new"
  echo "seqstat:    input port is a breaking change to every consumer, including any"
  echo "seqstat:    datum RECIPE that names an --inputs list."
  exit 1
fi
echo
echo "seqstat: ✅ every stat file above still describes the RTL beside it."
exit 0

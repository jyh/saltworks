#!/bin/sh
# run_firmware_replay.sh — GATE THE RP2040 FIRMWARE'S PROTOCOL CORE AGAINST THE
# VERILOG BENCH'S OWN PIN TRACE, WITH A MUTATION CONTROL.
#
# ARM GREEN  ndf_memserver.c as shipped        -> 6/6, zero mismatches
# ARM RED    the option (2) lookup DEFEATED    -> F2 must go RED
#
# ⛔ WITHOUT THE RED ARM THIS IS A PRINTOUT. The green arm alone cannot say
#    whether the comparison can fail at all — and this bench's comparison is
#    RESTRICTED to phases the DUT consumes, which is exactly the shape that goes
#    vacuous without being noticed.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
SIM="$HERE/../../Sim/reghost"; RTL="$HERE/../../RTL"
T=${TMPDIR:-/tmp}/ndf_fw.$$; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT

iverilog -g2005 -DTRACE -o "$T/trace.vvp" "$SIM/tb_plane32bus_reghost.v" \
         "$RTL/plane32bus.v" "$RTL/core32.v" "$RTL/busadapt8.v"
vvp "$T/trace.vvp" > "$T/trace.txt" 2>&1
NT=$(grep -c '^TRACE' "$T/trace.txt" || true)
echo "pin trace from tb_plane32bus_reghost: $NT cycles"
# ⛔ AND THE TRACE MUST COME FROM A GREEN BENCH. Replaying a trace produced by a
#   FAILING bench would compare the firmware against a machine that is not working.
if ! grep -q 'ALL PASS (6/6)' "$T/trace.txt"; then
  echo "FIRMWARE_REPLAY=FAIL (the source bench is not green — its trace proves nothing)"; exit 2
fi

cc -std=c99 -O1 -Wall -Wextra -o "$T/green" "$HERE/ndf_memserver.c" "$HERE/ndf_memserver_replay.c" -I"$HERE"

sed -e "s|s->word = rd32(s->mem, s->a\[0\]);|s->word = 0; /* MUTATED: the +4 lookup defeated */|" \
    "$HERE/ndf_memserver.c" > "$T/ndf_memserver_mut.c"
NMUT=$(grep -c 'MUTATED' "$T/ndf_memserver_mut.c" || true)
if [ "$NMUT" -ne 1 ]; then
  echo "FIRMWARE_REPLAY=FAIL (mutation did not apply: $NMUT/1 — the control is inert)"; exit 2
fi
cc -std=c99 -O1 -o "$T/red" "$T/ndf_memserver_mut.c" "$HERE/ndf_memserver_replay.c" -I"$HERE"

echo "--- ARM GREEN (firmware as shipped) ---"
"$T/green" < "$T/trace.txt" > "$T/green.out" 2>&1 || true
cat "$T/green.out"
echo "--- ARM RED (option (2) lookup defeated) ---"
"$T/red" < "$T/trace.txt" > "$T/red.out" 2>&1 || true
grep -E 'mismatches=|F-FAIL|REPLAY' "$T/red.out" || true

G=$(grep -c 'F-FAIL' "$T/green.out" || true)
RF2=$(grep -c 'F-FAIL  F2' "$T/red.out" || true)
if [ "$G" -eq 0 ] && [ "$RF2" -ge 1 ]; then
  echo "FIRMWARE_REPLAY=PASS (green 6/6; the mutation is CAUGHT by F2)"; exit 0
else
  echo "FIRMWARE_REPLAY=FAIL (green F-FAIL=$G, red F2 fails=$RF2)"; exit 1
fi

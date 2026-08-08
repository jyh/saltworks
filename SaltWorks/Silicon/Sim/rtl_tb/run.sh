#!/bin/sh
# Run the RTL-level frame validation. Requires iverilog only (no PDK, no flow).
#
# WHY THIS EXISTS, beside frame_sim.py rather than instead of it:
# frame_sim.py validates the PROTOCOL and decodes its strobes from a loop
# variable, so it has no frame counter — every frame it simulates is perfectly
# phased by construction. Its "200 arbitrary power-up states" row therefore
# varies the twelve elements' act/sel registers and nothing else. The spec names
# TWO init surfaces (§5) and that row can only reach one of them.
#
# These benches drive the REAL banyan_fabric.v and vary BOTH: the 48 routing
# bits AND the frame counter, with rst_n never asserted.
#
#   tb_counter_init.v  arms A/B/C/D — is the first well-phased frame already
#                      correct, and does waiting for a second one repair phase?
#                      Carries a TREATMENT ASSERTION (arm A verifies cnt==0 at
#                      frame start on every seed) because rev 1 of this bench
#                      silently failed to apply its own independent variable.
#   tb_param_p.v       does the counter's period actually track PAYLOAD?
#
# Both controls must fail or the result means nothing: arm B/C (phase withheld)
# and the mutant element below (the 8/6 routing bug, restored on purpose).

set -e
HERE=$(cd "$(dirname "$0")" && pwd)
RTL="$HERE/../../RTL"
OUT="${TMPDIR:-/tmp}/saltworks-rtl-tb.$$"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

echo "=== init surfaces: real element ==============================="
iverilog -g2005 -o "$OUT/real.vvp" \
    "$HERE/tb_counter_init.v" "$RTL/banyan_fabric.v" "$RTL/bitserial_switch.v"
vvp "$OUT/real.vvp"

echo
echo "=== CONTROL: the same bench against the MUTANT element ========"
echo "    (must fail, or the checker cannot see routing errors at all)"
iverilog -g2005 -o "$OUT/mut.vvp" \
    "$HERE/tb_counter_init.v" "$RTL/banyan_fabric.v" "$HERE/mutant/bitserial_switch.v"
vvp "$OUT/mut.vvp" | tail -6

echo
echo "=== parametricity in PAYLOAD =================================="
iverilog -g2005 -o "$OUT/param.vvp" \
    "$HERE/tb_param_p.v" "$RTL/banyan_fabric.v" "$RTL/bitserial_switch.v"
vvp "$OUT/param.vvp"

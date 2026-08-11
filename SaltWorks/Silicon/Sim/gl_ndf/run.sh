#!/bin/sh
# Gate-level smoke test of the SUBMITTED NDF, on the MAPPED sky130 netlist.
#
#   sh SaltWorks/Silicon/Sim/gl_ndf/run.sh <path-to-tt_um_saltworks_ndf.nl.v>
#
# WHY: TinyTapeout's `gds` workflow runs the bench against the gate-level netlist
# in its gl_test job, and a failure there reddens the workflow -- it is BLOCKING.
# This asks the question locally so TT's CI is not the first to answer it.
#
# ⚠️ SCOPE, stated inside the verdict: this is OUR LibreLane netlist of the
# submitted RTL, not TinyTapeout's own hardening. It checks the DESIGN's
# gate-level behaviour, not TT's build of it.
#
# ⭐ IT RUNS ITS OWN NEGATIVE CONTROL AND YOU SHOULD READ BOTH LINES. A check only
# ever run on passing input has not been shown to discriminate.
#   `+held_in_reset` keeps rst_n LOW for the whole run and MUST make it FAIL.
# 📌 AND THE CONTROL'S OWN LIMIT, because "2 of 3 caught it" is not "discriminating":
#   the uio_oe check STILL PASSES under the control, correctly -- uio_oe is a static
#   assign with no dependence on reset. That arm is exercised by a WRONG MASK, not
#   by a dead design, and this control does not test it.
set -eu
NL="${1:?usage: run.sh <tt_um_saltworks_ndf.nl.v>}"
[ -f "$NL" ] || { echo "⛔ no such netlist: $NL"; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
PDK=$(find "$HOME/.volare" -maxdepth 8 -type d -path '*sky130_fd_sc_hd/verilog' 2>/dev/null | head -1)
[ -n "$PDK" ] || { echo "⛔ sky130 functional models not found under \$HOME/.volare"; exit 2; }
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o "$W/gl.vvp" \
  "$HERE/tb_gl_ndf.v" "$PDK/primitives.v" "$PDK/sky130_fd_sc_hd.v" "$NL"
echo "=== DESIGN ==="            ; vvp "$W/gl.vvp"                | grep -E 'PASS|FAIL|deviations|edges|SUBMITTED'
echo "=== NEGATIVE CONTROL ===" ; vvp "$W/gl.vvp" +held_in_reset | grep -E 'PASS|FAIL|deviations|edges'
vvp "$W/gl.vvp" | grep -q 'GL SMOKE PASS' || { echo "⛔ design run did not pass"; exit 1; }
vvp "$W/gl.vvp" +held_in_reset | grep -q 'GL SMOKE FAIL' || { echo "⛔ CONTROL DID NOT FAIL — the harness proves nothing"; exit 1; }
echo "✅ design PASSES and the control FAILS — the harness discriminates."

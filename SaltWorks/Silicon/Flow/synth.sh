#!/bin/bash
# SILICON seat (leg 3) — sky130 synthesis, reproducible.
#
#   ./synth.sh comparator          # -> comparator_nl.v + comparator_stat.txt
#   ./synth.sh bitserial_switch
#
# This is the LOCAL DEV LOOP only. It is NOT the artifact the equivalence proof
# targets: the netlist that gets fabricated is built by TinyTapeout's CI
# (librelane==3.0.5, PDK 0536d02d…) and shipped as tt_submission/<top>.v in the
# POWERED form. See ../Flow-docs/hardware-versions.md for why, and for the pins.
#
# Everything here is UNTRUSTED by design. A bug in yosys or abc cannot produce a
# false theorem; it produces a netlist that FAILS the equivalence check.
set -e -u

TOP="${1:?usage: synth.sh <top-module>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../RTL"

# The PDK. Pinned; see Flow-docs/hardware-versions.md.
PDK_VER="${PDK_VER:-c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
PDK_ROOT="${PDK_ROOT:-$HOME/.volare/volare/sky130/versions/$PDK_VER}"
LIB="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

[ -f "$LIB" ] || { echo "synth: liberty not found at $LIB"; echo "  fetch with: volare enable --pdk sky130 $PDK_VER"; exit 1; }

yosys -q -p "
  read_verilog $RTL/$TOP.v
  synth -top $TOP
  dfflibmap -liberty $LIB
  abc -liberty $LIB
  opt_clean -purge
  write_verilog -noattr $HERE/${TOP}_nl.v
  tee -o $HERE/${TOP}_stat.txt stat -liberty $LIB
"
echo "synth: wrote ${TOP}_nl.v and ${TOP}_stat.txt"
grep -E "^ +[0-9]+ +[0-9.]+ +sky130" "$HERE/${TOP}_stat.txt" || true

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

# ⚠️ THIS SCRIPT USED TO READ `$RTL/$TOP.v` ALONE, AND COULD NOT SYNTHESIZE
# `banyan_fabric` AT ALL: it instantiates `bitserial_switch`, so yosys quits with
#   ERROR: Module `\bitserial_switch' referenced in module `\banyan_fabric' in
#   cell `\e23' is not part of the design.
# The script documented as "reproducible" could not reproduce the netlist the
# equivalence proof is taken against. Fixed by reading the DEPENDENCY CLOSURE.
#
# Not `$RTL/*.v`: reading an unrelated module (comparator.v) advances yosys's
# anonymous-net counter and shifts every `_NNN_` name in the output, so the
# artifact stops being byte-stable. The closure keeps it byte-stable.
# Assumes file name == module name, which holds and is checked below.
SRCS="$TOP.v"
changed=1
while [ "$changed" = 1 ]; do
  changed=0
  for f in "$RTL"/*.v; do
    b="$(basename "$f")"; m="${b%.v}"
    case " $SRCS " in *" $b "*) continue ;; esac
    for s in $SRCS; do
      if grep -qE "^[[:space:]]*$m[[:space:]]+[A-Za-z_]" "$RTL/$s"; then
        SRCS="$SRCS $b"; changed=1; break
      fi
    done
  done
done
READ=""; for s in $SRCS; do READ="$READ $RTL/$s"; done
echo "synth: reading$READ"

# ⚠️ AND `-flatten` IS NOT A PREFERENCE. LibreLane flattens, so an unflattened
# local netlist keeps boundaries for a reason that has nothing to do with design
# intent, and is VOID as a proxy for any question flattening decides. Measured
# 8/6: without `-flatten` the `(* keep *)` A/B arms come out BYTE-IDENTICAL --
# the local flow could not see the attribute's effect at all. With both fixes
# this reproduces the committed banyan_fabric_nl.v BYTE-FOR-BYTE.
# ⚠️ STRUCTURAL INPUT NEEDS THE LIBRARY READ FIRST, AND THE DEFAULT PATH MUST NOT
# CHANGE. Measured 8/7 during the C3 probe: a source that INSTANTIATES sky130
# cells cannot be read at all by the default sequence —
#   ERROR: Module `\sky130_fd_sc_hd__or2_1' referenced in module `\adder8s' in
#          cell `\cy7' is not part of the design.
# because nothing has told yosys those modules exist. `read_liberty -lib` before
# `read_verilog` declares them as BLACKBOXES, and that single line is what makes
# synthesis-as-passthrough possible: abc cannot restructure through a blackbox,
# so an already-mapped design comes out as it went in.
#
# OPT-IN, never default: `SYNTH_STRUCTURAL=1 ./synth.sh <top>`. The committed
# netlists were produced by the default path and must stay byte-reproducible by
# it — `Importer/reimport.sh` checks exactly that.
PRELUDE=""
if [ "${SYNTH_STRUCTURAL:-0}" = "1" ]; then
  PRELUDE="read_liberty -lib $LIB"
  echo "synth: STRUCTURAL mode — cells declared as blackboxes before read_verilog"
fi
yosys -q -p "
  $PRELUDE
  read_verilog $READ
  synth -top $TOP -flatten
  dfflibmap -liberty $LIB
  abc -liberty $LIB
  opt_clean -purge
  write_verilog -noattr $HERE/${TOP}_nl.v
  tee -o $HERE/${TOP}_stat.txt stat -liberty $LIB
"
echo "synth: wrote ${TOP}_nl.v and ${TOP}_stat.txt"
# ⛔ THE SUMMARY PATTERN USED TO DROP ROWS SILENTLY (silicon, 8/8 19:1x).
# It was `[0-9.]+` for the AREA column — but yosys prints a large per-cell-type
# area in SCIENTIFIC NOTATION (`992  1.12E+04  sky130_fd_sc_hd__mux2_1`), which
# contains `E` and `+` and therefore never matched. MEASURED over the 30
# committed stat files: 28 of 593 cell-type rows were invisible, and for
# `readtreem` — 992 cells, one type — the summary printed NOTHING AT ALL, so a
# synthesized module looked like it had no cells.
# I inherited this pattern into my own analysis and published a table with 14 of
# 30 cell counts wrong, `core32` by 3.1x, before the nonsense reading caught it.
# A tool whose SUMMARY silently omits rows teaches everyone who copies it.
awk '/sky130_fd_sc_hd__/ && NF>=3' "$HERE/${TOP}_stat.txt" || true
awk '/sky130_fd_sc_hd__/ && NF>=3 {n+=$1} END{printf "  TOTAL CELLS: %d\n", n+0}' "$HERE/${TOP}_stat.txt" || true
awk -F": " '/Chip area for module/ {printf "  CHIP AREA:   %.0f um2\n", $2}' "$HERE/${TOP}_stat.txt" || true

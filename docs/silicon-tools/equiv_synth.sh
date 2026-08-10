#!/bin/sh
# equiv_synth.sh — LINK (4): is the SYNTHESISED netlist the EMITTED one?
#
#   sh docs/silicon-tools/equiv_synth.sh <emitted.v> <synthesised.nl.v> <top>
#   sh docs/silicon-tools/equiv_synth.sh --selftest <emitted.v> <synth.nl.v> <top>
#
# SILICON seat. Built 2026-08-09 19:3x, on compiler's four-link chain:
#
#   (1) the DESIGN computes acc - v          kernel theorems + mutants   compiler
#   (2) the EMITTED artifact IS the design   emitS fidelity              compiler
#   (3) the emitted SHAPE matches            criterion (d) + controls    evidence
#   (4) the SYNTHESISED netlist IS the        <- THIS FILE. Was unowned.
#       emitted one
#
# WHY (4) NEEDED ITS OWN INSTRUMENT: the fabbed thing is not the emitted netlist,
# it is the SYNTHESISED one, and NET NAMES DO NOT SURVIVE SYNTHESIS. So criterion
# (d) -- which anchors on net indices carried into net names -- is checkable on
# the emitted netlist and NOT on the synthesised one. Measured the same evening:
# yosys drops 3 unobservable gates (and2 97->95, or2 32->31) and adds 63 buf_2.
# A histogram-plus-named-mechanism correspondence CONSTRAINS the netlist; it does
# not IDENTIFY it. This does, by SAT.
#
# ⛔ THE TRAP THIS FILE WAS ALMOST SHIPPED WITH, recorded because it is the whole
# reason the selftest exists: the first run used `yosys -q`, which produced an
# EMPTY LOG AND EXIT 0. That is indistinguishable from a proof. An exit code is
# not a verdict -- the tool must SHOW you `no model found: SUCCESS!`.
#
# ⛔ AND THE ONE BEFORE IT: `read_liberty -lib` imports cells as BLACKBOXES with
# no functional model, and SAT then refuses ("No SAT model available for cell
# ..."). It refused loudly, which is the good case. Use -ignore_miss_func WITHOUT
# -lib so the `function` attributes come in.
#
# EXIT 0 = equivalent (proof shown) · 1 = NOT equivalent (counterexample found)
#          2 = could not run
set -u
PDK_VER="${PDK_VER:-c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
LIB="${LIB:-$HOME/.volare/volare/sky130/versions/$PDK_VER/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib}"

SELFTEST=0
if [ "${1:-}" = "--selftest" ]; then SELFTEST=1; shift; fi
EMITTED="${1:?usage: equiv_synth.sh [--selftest] <emitted.v> <synthesised.nl.v> <top>}"
SYNTH="${2:?missing <synthesised.nl.v>}"
TOP="${3:?missing <top>}"

[ -f "$LIB" ]     || { echo "equiv_synth: liberty not found: $LIB"; exit 2; }
[ -f "$EMITTED" ] || { echo "equiv_synth: no such file: $EMITTED"; exit 2; }
[ -f "$SYNTH" ]   || { echo "equiv_synth: no such file: $SYNTH"; exit 2; }
command -v yosys >/dev/null 2>&1 || { echo "equiv_synth: yosys absent"; exit 2; }

TMP="${TMPDIR:-/tmp}/equiv_synth.$$"
mkdir -p "$TMP" || exit 2
trap 'rm -rf "$TMP"' EXIT

run_miter() {   # $1 = gate-side netlist, $2 = label
  cat > "$TMP/m.ys" <<EOF
read_liberty -ignore_miss_func $LIB
read_verilog $EMITTED
hierarchy -top $TOP
flatten
rename $TOP gold
design -stash g
read_liberty -ignore_miss_func $LIB
read_verilog $1
hierarchy -top $TOP
flatten
rename $TOP gate
design -stash h
design -copy-from g -as gold gold
design -copy-from h -as gate gate
miter -equiv -flatten gold gate miter
hierarchy -top miter
sat -verify -prove trigger 0 miter
EOF
  # NOT -q: the verdict line IS the deliverable.
  yosys -s "$TMP/m.ys" > "$TMP/$2.log" 2>&1
  echo $?
}

if [ "$SELFTEST" = "1" ]; then
  # NEGATIVE CONTROL: flip exactly ONE and2 into an or2 and require FAIL.
  # A check that has only ever been run on passing input has not been shown
  # to discriminate.
  awk 'BEGIN{d=0} {if(!d && /sky130_fd_sc_hd__and2_1 /){sub(/and2_1/,"or2_1"); d=1} print}' \
      "$SYNTH" > "$TMP/mutant.v"
  if ! command diff "$SYNTH" "$TMP/mutant.v" >/dev/null 2>&1; then
    RC=$(run_miter "$TMP/mutant.v" mut)
    if [ "$RC" = "1" ] && command grep -q 'model found: FAIL' "$TMP/mut.log"; then
      echo "SELFTEST ✅ one flipped gate -> counterexample found, exit 1. The check DISCRIMINATES."
    else
      echo "SELFTEST ⛔ mutant was NOT caught (rc=$RC). The check proves nothing; do not trust a green."
      exit 2
    fi
  else
    echo "SELFTEST ⛔ could not build a mutant (no and2_1 in $SYNTH)"; exit 2
  fi
fi

RC=$(run_miter "$SYNTH" real)
command grep -E 'Solving problem with|proof finished' "$TMP/real.log"
if [ "$RC" = "0" ] && command grep -q 'no model found: SUCCESS' "$TMP/real.log"; then
  echo "✅ EQUIVALENT — $EMITTED == $SYNTH over all inputs (SAT, proof shown above)."
  exit 0
elif command grep -q 'model found: FAIL' "$TMP/real.log"; then
  echo "⛔ NOT EQUIVALENT — synthesis changed the function. Counterexample exists."
  exit 1
else
  echo "⛔ COULD NOT DECIDE (yosys rc=$RC) — read the log, do NOT read this as a pass."
  exit 2
fi

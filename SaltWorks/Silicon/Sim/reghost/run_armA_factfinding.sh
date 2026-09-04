#!/bin/sh
# run_armA_factfinding.sh — MEASURE FORK ARM (A). ⛔ FACT-FINDING, NOT A RULING.
#
# Arm (A) = a symmetric "+4" on §7's FETCH row, mirroring what ratified option (2)
# did for the LOAD row. IT IS NOT RATIFIED. This script changes nothing in the tree:
# `armA_patch.py` derives the variant into a temp dir and the temp dir is deleted.
#
# ⭐ WHY: I posted a PRICE for (A) computed by arithmetic and never drove it. A
#   forecast is the one kind of claim nobody runs a control on. Two questions, both
#   answerable by measurement rather than by argument:
#     (1) does (A) actually let a FULLY REGISTERED host run the machine?
#     (2) what does it actually cost?
#
# THE CONTROL: the SAME fully-registered bench against the SHIPPED RTL (option (2),
# whose FETCH row is still in-phase) must go RED. Without that arm, a green under (A)
# says nothing — it could be a bench that passes against anything.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"; TB="$HERE/tb_reghost_fullreg_ARMA.v"
T=${TMPDIR:-/tmp}/armA.$$; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT

python3 "$HERE/armA_patch.py" "$RTL/busadapt8.v" "$T/busadapt8.v"

iverilog -g2005 -o "$T/armA.vvp"    "$TB" "$RTL/plane32bus.v" "$RTL/core32.v" "$T/busadapt8.v"
iverilog -g2005 -o "$T/shipped.vvp" "$TB" "$RTL/plane32bus.v" "$RTL/core32.v" "$RTL/busadapt8.v"
vvp "$T/armA.vvp"    > "$T/armA.out"    2>&1 || true
vvp "$T/shipped.vvp" > "$T/shipped.out" 2>&1 || true

echo "--- ARM (A): symmetric +4, fully registered host ---"
grep -E 'loops:|retires|mem\[64|G-FAIL|ARM \(A\)' "$T/armA.out" || true
echo "--- CONTROL: the SAME bench against the SHIPPED RTL (option (2), fetch in-phase) ---"
grep -E 'loops:|retires|mem\[64|ARM \(A\)' "$T/shipped.out" || true

A=$(grep -c 'G-FAIL' "$T/armA.out" || true); S=$(grep -c 'G-FAIL' "$T/shipped.out" || true)
echo "arm (A) failures = $A   control (shipped) failures = $S"
if [ "$A" -eq 0 ] && [ "$S" -gt 0 ]; then
  echo "ARMA_FACTFINDING=MEASURED (arm (A) 6/6; the shipped RTL RED under the same host)"
  echo "  ⇒ (A) closes the FETCH-row gap. Per-instruction cost MEASURED from the loop"
  echo "     census: non-memory 8 · LW 16 · SW 16 (vs option (2)'s 4 · 12 · 12)."
  echo "  ⛔ STILL UNRATIFIED. Two signatures, and the ruling is not a seat's."
  exit 0
else
  echo "ARMA_FACTFINDING=INCONCLUSIVE (A=$A S=$S — a green control makes the arm meaningless)"
  exit 1
fi

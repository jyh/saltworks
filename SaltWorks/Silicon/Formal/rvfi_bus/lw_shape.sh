#!/bin/sh
# lw_shape.sh <tapped source dir (run_aaj.sh: $OUT/tap)> <out> — bmc (depth 48), prove (k-induction),
# cover (non-vacuity), and the MUTANT (the RV32I claim in place of the shape: must FAIL).
set -eu
C=$1; OUT=$2; HERE=$(cd "$(dirname "$0")" && pwd); RVF=${RVF:-$HOME/src/riscv-formal}; mkdir -p "$OUT"
for task in bmc prove cover mutant; do
  mode=$task; def=""; [ $task = mutant ] && { mode=bmc; def="-DLW_SHAPE_MUTANT"; }
  cat > "$OUT/lw_$task.sby" <<SBY
[options]
mode $mode
depth $( [ $task = prove ] && echo 16 || echo 48 )

[engines]
smtbmc bitwuzla

[script]
read -formal -DAAJ_LW_SHAPE $def rvfi_macros.vh lw_shape.sv wrapper.sv core32.v busadapt8.v plane32bus.v
prep -flatten -nordff -top lw_shape
chformal -early

[files]
$RVF/checks/rvfi_macros.vh
$HERE/lw_shape.sv
$HERE/wrapper.sv
$C/core32.v
$C/busadapt8.v
$C/plane32bus.v
SBY
  ( cd "$OUT" && sby -f "lw_$task.sby" >/dev/null 2>&1 ) || true
  echo "lw_$task $(cat "$OUT/lw_$task/status" 2>/dev/null || echo MISSING)"
done

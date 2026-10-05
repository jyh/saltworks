#!/bin/sh
# vac.sh <riscv-formal core dir> <out> — NON-VACUITY for every PASSING check of a run_aaj.sh run.
# riscv-formal checks ASSUME a retirement at their trigger/check cycle; if no trace satisfies the
# assumptions to that cycle, BMC proves the asserts VACUOUSLY and prints PASS. Here each passing
# check is re-run in sby COVER mode with its own files and assumptions, plus ONE added statement in
# the testbench: `vac: cover (cycle == CHECK_CYCLE)`. REACHED = the PASS was not vacuous.
set -eu
C=$1; OUT=$2; mkdir -p "$OUT"; RVF=$(cd "$C/../.." && pwd)
sed 's|^`ifdef RISCV_FORMAL_ASSUME|	always @* if (!reset) vac: cover (cycle == `RISCV_FORMAL_CHECK_CYCLE);\n`ifdef RISCV_FORMAL_ASSUME|' \
  "$RVF/checks/rvfi_testbench.sv" > "$OUT/rvfi_testbench.sv"
grep -c -F 'vac: cover' "$OUT/rvfi_testbench.sv" | grep -qx 1 || { echo "⛔ vac cover not inserted"; exit 2; }
for d in "$C"/checks/*/; do
  n=$(basename "$d"); [ "$(cut -d' ' -f1 "$d/status")" = PASS ] || continue
  sed -e 's/^mode bmc$/mode cover/' -e '/^skip /d' -e '/^expect /d' \
      -e "s|^.*/checks/rvfi_testbench.sv\$|$OUT/rvfi_testbench.sv|" "$C/checks/$n.sby" > "$OUT/$n.sby"
  grep -q -F "$OUT/rvfi_testbench.sv" "$OUT/$n.sby" || { echo "$n VOID(testbench not swapped)"; continue; }
  ( cd "$C/checks" && sby -f -d "$OUT/$n" "$OUT/$n.sby" >/dev/null 2>&1 ) || true
  if grep -q -E 'Reached cover statement .*vac' "$OUT/$n/logfile.txt"; then v=REACHED
  elif grep -q -E 'Unreached cover statement .*vac' "$OUT/$n/logfile.txt"; then v=UNREACHED
  else v="UNKNOWN($(cat "$OUT/$n/status" 2>/dev/null))"; fi
  echo "$n $v"
done

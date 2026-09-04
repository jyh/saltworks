#!/bin/sh
# run_sof_wait_state.sh — CAN `sof` SERVE AS A WAIT STATE FOR A REGISTERED HOST?
#
# THREE ARMS, ONE VARIABLE (the sof pulse). The host is the TRACKED combinational
# one, unchanged, so nothing but the pulse differs between arms.
#
#   0  no pulse (CONTROL)                     expect 21 LOAD / 43 STORE loops, 6/6
#   1  one cycle at a RETIRING phase-3 edge   expect 20 / 45 — a store RE-ISSUED,
#                                             and expect 6/6 ANYWAY (the gap)
#   2  one cycle at a NON-retiring edge       expect 21 / 44 and L5 RED
#
# ⛔ ARM 1 SCORING 6/6 IS THE FINDING, NOT A PASS: an idempotent store hides its
#    own duplication and L5 constrains a store's SHAPE, never the COUNT of stores.
# Write-up: docs/silicon-ndf-registered-host-results-0903.md
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"
for A in 0 1 2; do
  iverilog -g2005 -Ptb.SOF_AT_RETIRE=$A -o "/tmp/sofws_$A.vvp" -s tb \
    "$HERE/tb_sof_at_retire.v" "$RTL/plane32bus.v" "$RTL/busadapt8.v" "$RTL/core32.v"
  printf 'ARM %s  ' "$A"
  vvp "/tmp/sofws_$A.vvp" 2>&1 | grep -E 'MEASURED_FINAL' | sed 's/ *MEASURED_FINAL: //'
  vvp "/tmp/sofws_$A.vvp" 2>&1 | grep -E 'ALL PASS|RED:' | sed 's/^/        verdict: /'
done
echo
echo "EXPECTED: arm1 shows store_loops 45 (a re-issued store) AND a 6/6 green."
echo "If arm1 shows 43 stores, the re-issue did not happen and the finding is void."

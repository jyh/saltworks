#!/bin/sh
# run_sof_wait_state.sh — CAN `sof` SERVE AS A WAIT STATE FOR A REGISTERED HOST?
#                         AND IS L7 A CRITERION THAT CAN ACTUALLY FAIL?
#
# THREE ARMS, ONE VARIABLE (the `sof` pulse). The host is the TRACKED combinational
# one and the criteria are the TRACKED ones — this script DERIVES its bench from
# ../wordonly/tb_plane32bus_lwsw.v at run time and injects only the pulse, so the
# probe can never drift out of sync with the criteria it is testing.
#
#   0  no pulse (CONTROL)                     21 LOAD / 43 STORE loops, 7/7 green
#   1  one cycle at a RETIRING phase-3 edge   20 / 45 — a store RE-ISSUED ⇒ L7 RED
#   2  one cycle at a NON-retiring edge       21 / 44 ⇒ L5 RED
#
# ⛔ ARM 1 IS THE RED-FIRST PROOF FOR L7, ordered by the helm's desk-FF word. Before
#    L7 existed this arm scored 6/6 GREEN while injecting an ENTIRE EXTRA STORE
#    TRANSACTION: an idempotent store hides its own duplication (L2 re-checks the same
#    word at the same address) and L5 constrains a store's SHAPE, never the COUNT of
#    stores. A SHAPE CRITERION CANNOT SEE A COUNT DEFECT.
# ⇒ IF ARM 1 GOES GREEN ON L7, THIS CONTROL IS BROKEN AND ARM 0's GREEN MEANS NOTHING.
# Write-up: docs/silicon-ndf-registered-host-results-0903.md
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"; SRC="$HERE/../wordonly/tb_plane32bus_lwsw.v"
[ -f "$SRC" ] || { echo "⛔ tracked bench not found: $SRC"; exit 2; }
T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT

# derive: add the parameter, and inject the pulse driver
sed -e 's/^module tb;/module tb;\n  parameter integer SOF_AT_RETIRE = 0;/' "$SRC" > "$T/tb.v"
python3 - "$T/tb.v" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
inj = '''
  integer sof_pulses = 0;
  always @(posedge clk) if (rst_n && SOF_AT_RETIRE != 0) begin
    if (SOF_AT_RETIRE == 1 && dut.u_bus.phase == 2'd3 && retire_w && sof_pulses == 0
        && dut.u_bus.kind == 2'b11 && dut.u_bus.store_beat) begin
      sof <= 1'b1; sof_pulses = sof_pulses + 1;
      $display("    >> arm 1: sof at a RETIRING phase-3 edge (store data loop)");
    end
    else if (SOF_AT_RETIRE == 2 && dut.u_bus.phase == 2'd3 && !retire_w && sof_pulses == 0) begin
      sof <= 1'b1; sof_pulses = sof_pulses + 1;
      $display("    >> arm 2: sof at a NON-retiring phase-3 edge (mid transaction)");
    end
    else sof <= 1'b0;
  end
'''
i = s.index('  initial begin')
io.open(p,'w',encoding='utf-8').write(s[:i] + inj + '\n' + s[i:])
PY

rc=0
for A in 0 1 2; do
  iverilog -g2005 -Ptb.SOF_AT_RETIRE=$A -o "$T/a$A.vvp" -s tb \
    "$T/tb.v" "$RTL/plane32bus.v" "$RTL/busadapt8.v" "$RTL/core32.v"
  out=$(vvp "$T/a$A.vvp" 2>&1)
  printf 'ARM %s  ' "$A"
  echo "$out" | grep -E 'store transactions completed' | sed 's/^ *//'
  echo "$out" | grep -E '^ *L-FAIL|ALL PASS|RED:' | sed 's/^ */        /'
  # the gate: arm 1 MUST fail L7
  if [ "$A" = 1 ]; then
    if echo "$out" | grep -q 'L-FAIL  L7'; then echo "        ✅ RED-FIRST HELD: L7 fails on the injected duplicate"
    else echo "        ⛔ L7 DID NOT FIRE ON ARM 1 — the criterion is broken, arm 0's green is worthless"; rc=1; fi
  fi
  if [ "$A" = 0 ]; then
    if echo "$out" | grep -q 'ALL PASS'; then echo "        ✅ control clean"
    else echo "        ⛔ CONTROL IS RED — fix the bench before trusting any arm"; rc=1; fi
  fi
done
echo
[ $rc = 0 ] && echo "SOF_WAIT_STATE=PASS (control green, arm 1 RED on L7 — the criterion discriminates)" \
            || echo "SOF_WAIT_STATE=BROKEN"
exit $rc

#!/bin/sh
# REACHABILITY SWEEP — of all the cycles at which a host may legitimately assert
# `sof`, WHAT FRACTION CORRUPT? One compile, N runs via +sofcyc plusarg.
set -e
S=/Users/jyh/projects/claude/seats/silicon/saltworks/SaltWorks/Silicon
RTL="$S/RTL"; SRC="$S/Sim/wordonly/tb_plane32bus_lwsw.v"
T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT
cp "$SRC" "$T/tb.v"
python3 - "$T/tb.v" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
inj = r'''
  integer sofcyc = -1, cyccnt = 0, n_lw_exec = 0, n_sw_exec = 0;
  initial begin if (!$value$plusargs("sofcyc=%d", sofcyc)) sofcyc = -1; end
  always @(posedge clk) if (rst_n) begin
    cyccnt = cyccnt + 1;
    sof <= (sofcyc >= 0 && cyccnt == sofcyc) ? 1'b1 : 1'b0;
    if (retire_w) begin
      if (dut.u_bus.c_instr[6:0] == 7'b0000011) n_lw_exec = n_lw_exec + 1;
      if (dut.u_bus.c_instr[6:0] == 7'b0100011) n_sw_exec = n_sw_exec + 1;
    end
  end
'''
i = s.index('  initial begin')
s = s[:i] + inj + '\n' + s[i:]
extra = r'''    $display("SWEEP sofcyc=%0d unacc=%0d lw=%0d sw=%0d", sofcyc, store_unaccounted, n_lw_exec, n_sw_exec);
    $finish;'''
s = s.replace('    $finish;', extra, 1)
io.open(p,'w',encoding='utf-8').write(s)
PY
iverilog -g2005 -o "$T/s.vvp" -s tb "$T/tb.v" "$RTL/plane32bus.v" "$RTL/busadapt8.v" "$RTL/core32.v"
# baseline (no pulse)
base=$(vvp "$T/s.vvp" | sed -n 's/.*SWEEP .*lw=\([0-9]*\) sw=\([0-9]*\)/\1 \2/p')
bl=$(echo "$base" | cut -d' ' -f1); bs=$(echo "$base" | cut -d' ' -f2)
echo "BASELINE (no sof): lw_exec=$bl sw_exec=$bs"
echo
bad=0; tot=0; lost=0
# ⛔ THE RANGE IS A PARAMETER, NOT A CONSTANT, AND IT IS NAMED IN THE OUTPUT.
# It was hardcoded 40..160 and labelled "steady state" — a sensible window, and NOT the
# simulation. I then used a 0-corrupt result over that window to say "the repair is complete",
# which is a coverage claim the window cannot support. Same defect as an arm-based census one
# level up: A RANGE I PICKED IS NOT A COVERAGE CLAIM.
# Widened check (SWEEP_LO=1 SWEEP_HI=260, the whole run including bring-up), measured 09/06:
#   tape-out 4226396  72 deviating arrivals of 260   (an UPPER BOUND: bring-up rows differ for
#                                                     reasons that are not this defect)
#   complete (B)       0 of 260                      (exact: nothing differed from anything)
SWEEP_LO="${SWEEP_LO:-40}"; SWEEP_HI="${SWEEP_HI:-160}"
for c in $(seq "$SWEEP_LO" "$SWEEP_HI"); do
  out=$(vvp "$T/s.vvp" +sofcyc=$c | grep '^SWEEP')
  u=$(echo "$out" | sed -n 's/.*unacc=\([0-9]*\).*/\1/p')
  l=$(echo "$out" | sed -n 's/.*lw=\([0-9]*\).*/\1/p')
  tot=$((tot+1))
  if [ "$u" != 0 ]; then bad=$((bad+1)); fi
  if [ "$l" -lt "$bl" ]; then lost=$((lost+1)); fi
done
echo "ARRIVAL CYCLES SWEPT ........... $tot   (cycles $SWEEP_LO..$SWEEP_HI$([ "$SWEEP_LO" = 40 ] && [ "$SWEEP_HI" = 160 ] && echo ', steady state'))"
echo "CORRUPTED (a store unaccounted)  $bad"
echo "INSTRUCTION LOST (lw_exec down)  $lost"
echo "REACHABILITY ................... $(echo "scale=1; 100*$bad/$tot" | bc)% of arrival cycles corrupt"

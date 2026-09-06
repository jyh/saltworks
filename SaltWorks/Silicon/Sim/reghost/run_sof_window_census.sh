#!/bin/sh
# run_sof_window_census.sh — HOW WIDE IS THE `sof`-AT-RETIRE HAZARD, AND WHAT DRIVES IT?
#
# AMENDMENT 2's own wording is "a one-cycle `sof` at a retiring phase-3 edge re-issues a
# completed transaction". This census MEASURES that window and finds it is THREE cycles
# wide, not one, and that the consequence is architectural, not merely bus traffic.
#
# ONE VARIABLE (the cycle at which a single `sof` pulse is presented). The DUT is the
# SHIPPED busadapt8.v — NOTHING IS MUTATED. The bench and its criteria are DERIVED at run
# time from the tracked ../wordonly/tb_plane32bus_lwsw.v, so the probe cannot drift out of
# sync with the criteria it is testing.
#
#   ARM  0    no pulse                                        CONTROL — must be 7/7
#   ARM 10    sof during phase 0 of the fetch loop following a completed MEMORY instr
#   ARM 11    ... phase 1
#   ARM 12    ... phase 2
#   ARM 13    ... phase 3
#   ARM 20    sof during phase 0 of a fetch loop following a NON-memory instr
#             FAIRNESS CONTROL — `instr_r` holds nothing memory-shaped, so this must be
#             CLEAN. If arm 20 is also damaging, the finding is "sof is broken" and NOT
#             the narrow one this census claims.
#
# ⛔ THE GATE, AND IT IS THE POINT OF THE SCRIPT: arms 10/11/12 MUST go RED on L7 and arms
#    0/13/20 MUST be clean. If every arm passes, the criterion cannot fail and arm 0's
#    green is worth nothing — this script REFUSES rather than reporting a green.
#
# ⚠️ A MUTATION CONTROL WAS TRIED FIRST AND WAS THE DEFECTIVE PART. Defeating the
#    instruction bypass to test WHY phase 3 is safe broke the whole arbitration (2/7 red),
#    so store accounting no longer measured the same quantity and arm 13 stayed clean for
#    an unrelated reason. The mechanism is established below by OBSERVATION instead: the
#    census prints the decode the `sof` arm actually consumes at the sampling edge.
#    ⇒ WHEN A MUTATION CHANGES MORE THAN THE QUANTITY UNDER TEST, IT IS NOT A CONTROL.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"
SRC="$HERE/../wordonly/tb_plane32bus_lwsw.v"
[ -f "$SRC" ] || { echo "⛔ tracked bench not found: $SRC"; exit 2; }
T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT

sed -e 's/^module tb;/module tb;\n  parameter integer ARM = 0;/' "$SRC" > "$T/tb.v"
python3 - "$T/tb.v" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
inj = r'''
  // ---- the single injected variable: one sof pulse, at a chosen cycle ----------
  integer sof_pulses = 0, armed = 0, cnt = 0, ph_target = 0, showed = 0;
  wire mem_retire     = (dut.u_bus.phase==2'd3) && retire_w &&
                        (dut.u_bus.kind==2'b10 || dut.u_bus.kind==2'b11);
  wire non_mem_retire = (dut.u_bus.phase==2'd3) && retire_w && (dut.u_bus.kind==2'b01);
  wire trig = (ARM >= 10 && ARM <= 13) ? mem_retire
            : (ARM == 20)              ? non_mem_retire : 1'b0;
  always @(posedge clk) if (rst_n && ARM != 0) begin
    sof <= 1'b0;
    ph_target = (ARM == 20) ? 0 : (ARM - 10);
    if (sof_pulses == 0 && armed == 0 && trig) begin
      if (ph_target == 0) begin sof <= 1'b1; sof_pulses = 1; end
      else begin armed = 1; cnt = 0; end
    end else if (armed == 1) begin
      cnt = cnt + 1;
      if (cnt == ph_target) begin sof <= 1'b1; sof_pulses = 1; armed = 0; end
    end
  end

  // ---- pure observation: the ARCHITECTURAL census the shape criteria cannot see --
  integer n_lw_exec = 0, n_sw_exec = 0;
  always @(posedge clk) if (rst_n && retire_w) begin
    if (dut.u_bus.c_instr[6:0] == 7'b0000011) n_lw_exec = n_lw_exec + 1;
    if (dut.u_bus.c_instr[6:0] == 7'b0100011) n_sw_exec = n_sw_exec + 1;
  end

  // ---- pure observation: WHAT THE `sof` ARM READS at the sampling edge ----------
  always @(negedge clk) if (rst_n && sof && showed == 0) begin
    showed = 1;
    $display("  READS: phase=%0d instr_r=%h c_instr=%h req=%b we=%b => kind will be %0s",
             dut.u_bus.phase, dut.u_bus.instr_r, dut.u_bus.c_instr,
             dut.u_bus.c_dmem_req, dut.u_bus.c_dmem_we,
             dut.u_bus.c_dmem_req ? (dut.u_bus.c_dmem_we ? "T_STORE" : "T_LOAD") : "T_FETCH");
  end
'''
i = s.index('  initial begin')
s = s[:i] + inj + '\n' + s[i:]
extra = r'''    $display("  ARCH: lw_exec=%0d sw_exec=%0d sof_pulses=%0d", n_lw_exec, n_sw_exec, sof_pulses);
    $finish;'''
s = s.replace('    $finish;', extra, 1)
io.open(p,'w',encoding='utf-8').write(s)
PY

rc=0; reds=0
for A in 0 10 11 12 13 20; do
  iverilog -g2005 -Ptb.ARM=$A -o "$T/a$A.vvp" -s tb \
    "$T/tb.v" "$RTL/plane32bus.v" "$RTL/busadapt8.v" "$RTL/core32.v"
  out=$(vvp "$T/a$A.vvp" 2>&1)
  un=$(echo "$out"  | sed -n 's/.*UNACCOUNTED = \([0-9]*\).*/\1/p' | head -1)
  arch=$(echo "$out"| sed -n 's/^ *ARCH: //p'   | head -1)
  rd=$(echo "$out"  | sed -n 's/^ *READS: //p'  | head -1)
  vd=$(echo "$out"  | grep -E 'ALL PASS|RED:'   | sed 's/^ *//')
  printf 'ARM %-3s unaccounted=%-3s %-42s %s\n' "$A" "${un:-?}" "$arch" "$vd"
  [ -n "$rd" ] && printf '        %s\n' "$rd"
  case "$A" in
    0|20) if [ "$un" != 0 ] || ! echo "$out" | grep -q 'ALL PASS'; then
            echo "        ⛔ ARM $A MUST BE CLEAN AND IS NOT — the census is not measuring what it claims"; rc=1
          else echo "        ✅ clean, as a control must be"; fi ;;
    10|11|12) if echo "$out" | grep -q 'L-FAIL  L7'; then
            reds=$((reds+1)); echo "        ✅ RED on L7 — a completed store re-issued"
          else echo "        ⛔ ARM $A DID NOT GO RED — L7 cannot fail here; arm 0's green is worthless"; rc=1; fi ;;
    13) if [ "$un" = 0 ] && echo "$out" | grep -q 'ALL PASS'; then
            echo "        ✅ clean — the ONE protected cycle of the four"
          else echo "        ⛔ ARM 13 WAS EXPECTED CLEAN; the window is wider than 3 and this write-up understates it"; rc=1; fi ;;
  esac
done
echo
echo "hazard window = $reds of the 4 cycles of the post-memory-retire fetch loop"
[ "$reds" = 3 ] || { echo "⛔ expected 3 red arms, got $reds"; rc=1; }
[ $rc = 0 ] && echo "SOF_WINDOW_CENSUS=PASS (controls clean, 10/11/12 red, 13 protected)" \
            || echo "SOF_WINDOW_CENSUS=BROKEN"
exit $rc

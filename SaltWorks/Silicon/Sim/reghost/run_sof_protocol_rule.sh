#!/bin/sh
# run_sof_protocol_rule.sh — IS THE HOST-SIDE `sof` RULE BINDING, SATISFIABLE, AND TESTABLE?
#
# The rule (see sof_protocol_check.v): a host may assert `sof` ONLY while the adapter is in a
# FETCH loop with no memory instruction resident.
#
#   ARM C  COMPLIANT HOST — wants to launch a fabric run every 40 cycles and DEFERS each
#          request until the rule permits it. Must: assert sof SEVERAL TIMES, take ZERO
#          violations, and leave the bench 7/7.
#   ARM V  VIOLATING HOST — asserts sof at the measured hazard. Must: trip the checker AND
#          take L7 red.
#
# ⛔ THREE GATES, AND THE THIRD IS THE ONE MOST CHECKS OMIT:
#   (1) ARM V must trip the checker      — else the checker cannot fail and ARM C is worthless
#   (2) ARM C must take zero violations  — else the rule is not satisfiable
#   (3) ARM C MUST ACTUALLY ASSERT `sof` SEVERAL TIMES — a compliant host that never asserts
#       passes VACUOUSLY, and "0 violations" would then be a statement about a host that did
#       nothing. THE RULE MUST BE SHOWN TO PERMIT WORK, NOT MERELY TO FORBID IT.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"
SRC="$HERE/../wordonly/tb_plane32bus_lwsw.v"
[ -f "$SRC" ] || { echo "⛔ tracked bench not found"; exit 2; }
T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT
sed -e 's/^module tb;/module tb;\n  parameter integer HOST_MODE = 0;/' "$SRC" > "$T/tb.v"
python3 - "$T/tb.v" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
inj = r'''
  // ---- the checker, fed from the adapter's own state -------------------------
  wire [31:0] viol; wire [1:0] fvp;
  sof_protocol_check u_chk(.clk(clk), .rst_n(rst_n), .sof(sof),
                           .kind(dut.u_bus.kind), .phase(dut.u_bus.phase),
                           .req(dut.u_bus.c_dmem_req), .violations(viol),
                           .first_viol_phase(fvp));

  integer sof_pulses = 0, cyc = 0, want = 0, n_lw = 0, n_sw = 0;
  wire permitted = (dut.u_bus.kind == 2'b01) && (dut.u_bus.c_dmem_req == 1'b0);
  wire mem_retire = (dut.u_bus.phase==2'd3) && retire_w &&
                    (dut.u_bus.kind==2'b10 || dut.u_bus.kind==2'b11);
  always @(posedge clk) if (rst_n) begin
    cyc = cyc + 1;
    if (retire_w) begin
      if (dut.u_bus.c_instr[6:0] == 7'b0000011) n_lw = n_lw + 1;
      if (dut.u_bus.c_instr[6:0] == 7'b0100011) n_sw = n_sw + 1;
    end
    sof <= 1'b0;
    if (HOST_MODE == 0) begin
      // COMPLIANT: want a fabric launch every 40 cycles, then DEFER until permitted.
      if (cyc % 40 == 0) want = 1;
      // ⛔ DECIDE ONE CYCLE EARLY, IN THE STABLE PART OF THE LOOP. A host samples at edge t
      // and drives at t+1, so a rule tested only at the DECISION cycle is unimplementable:
      // `permitted` can evaporate underneath it. kind is constant within a loop and the
      // resident decode is constant at phases 0..2 (at phase 3 the instruction bypass swaps
      // c_instr for the NEWLY assembled word, so req may flip). Deciding at phase 0 or 1
      // puts sof high at phase 1 or 2 — cycles where neither term can have moved.
      if (want == 1 && permitted && (dut.u_bus.phase == 2'd0 || dut.u_bus.phase == 2'd1))
        begin sof <= 1'b1; want = 0; sof_pulses = sof_pulses + 1; end
    end else begin
      // VIOLATING: launch at the measured hazard, once.
      if (sof_pulses == 0 && mem_retire) begin sof <= 1'b1; sof_pulses = sof_pulses + 1; end
    end
  end
'''
i = s.index('  initial begin')
s = s[:i] + inj + '\n' + s[i:]
extra = r'''    $display("  PROTO: violations=%0d sof_pulses=%0d unacc=%0d lw=%0d sw=%0d",
             viol, sof_pulses, store_unaccounted, n_lw, n_sw);
    $finish;'''
s = s.replace('    $finish;', extra, 1)
io.open(p,'w',encoding='utf-8').write(s)
PY

rc=0
for M in 0 1; do
  [ "$M" = 0 ] && L="ARM C (compliant, defers)" || L="ARM V (violating)     "
  iverilog -g2005 -Ptb.HOST_MODE=$M -o "$T/m$M.vvp" -s tb \
    "$T/tb.v" "$HERE/sof_protocol_check.v" "$RTL/plane32bus.v" "$RTL/busadapt8.v" "$RTL/core32.v"
  out=$(vvp "$T/m$M.vvp" 2>&1)
  pr=$(echo "$out" | sed -n 's/^ *PROTO: //p')
  vd=$(echo "$out" | grep -E 'ALL PASS|RED:' | sed 's/^ *//')
  v=$(echo "$pr" | sed -n 's/violations=\([0-9]*\).*/\1/p')
  ps=$(echo "$pr" | sed -n 's/.*sof_pulses=\([0-9]*\).*/\1/p')
  printf '%s  %-52s %s\n' "$L" "$pr" "$vd"
  if [ "$M" = 1 ]; then
    # ⭐⭐ GATE 1 = R1 (compiler, landed first, ruled by evidence 11:19) + GATE 1b (silicon).
    # I am NOT reversing the ruling: R1's gate is kept exactly — the checker must fire — and
    # nothing it gates is loosened. What is added is the half R1 deliberately PARKED as R2.
    #
    # R1 dropped the L7 coupling to an observation because shape (B) had repaired the witness
    # out from under it, and tracked "can any host still do damage post-(B)?" as R2, owing its
    # own measurement. ⇒ I OWED THAT MEASUREMENT AND TOOK IT:
    #     full arrival sweep 40..160 on the COMPLETE (B):        0 corrupt / 0 lost of 121
    #     the same sweep with the retire-edge term removed:      4 corrupt        of 121
    # So R2 is VOID — but only because (B) needed a SECOND term. The (B) that existed when R1
    # was written still left 4 of 121 corrupt: `fetch_owed` is SET BY the memory retire and so
    # is not yet high AT that edge. The complete repair is `a28eeb95`.
    #
    # ⛔ AND THAT IS WHY THE WITNESS COMES BACK AS A GATE RATHER THAN STAYING AN OBSERVATION:
    # "the bench did not take L7 red" was TRUE of the INCOMPLETE (B) too, for a different
    # reason. An observation that reads identically whether the repair is complete or
    # three-quarters done carries no information about the repair. Pinned to the pre-repair
    # RTL it says something only the past can say — and it can FAIL.
    # ⇒ ASK EACH HALF OF THE WORLD IT IS TRUE IN, AND PIN THE HALF THAT DESCRIBES THE PAST.
    if [ "${v:-0}" -ge 1 ]; then
      echo "        ✅ GATE 1a: the violating host TRIPS the checker (violations=$v) — it can fail"
      if echo "$out" | grep -q 'L-FAIL  L7'; then
        echo "           observation (NOT a gate): the bench also took L7 red — pre-(B) behaviour"
      else
        echo "           observation (NOT a gate): the bench did NOT take L7 red, as (B) intends"
      fi
    else
      echo "        ⛔ GATE 1a FAILED — the checker did not fire on a known-bad host; it cannot fail, so ARM C proves nothing"; rc=1
    fi

    # ---- GATE 1b, WELL-FOUNDEDNESS (historical, pinned) — R1's dropped conjunct, restored --
    PIN1="${SOF_PROTOCOL_PIN:-afa8a2e7}"
    # ⛔ RESOLVE THE GIT REPO THROUGH THE SYMLINK, NOT FROM `$RTL`: compiler's prover runs this
    # arm in a sandbox whose RTL/ holds SYMLINKS, so `$RTL` is not a git repo there and a naive
    # `cd "$RTL" && git show` fails — reporting 1b UNAVAILABLE for a reason unrelated to the
    # gate. A CHECK MUST WORK IN THE HARNESS THAT RUNS IT, NOT ONLY WHERE ITS AUTHOR TYPED IT.
    GITDIR="$RTL"
    if ! ( cd "$GITDIR" && git rev-parse --git-dir >/dev/null 2>&1 ); then
      _real=$(readlink "$RTL/busadapt8.v" 2>/dev/null || true)
      [ -n "$_real" ] && GITDIR=$(cd "$(dirname "$_real")" && pwd)
    fi
    if ( cd "$GITDIR" && git merge-base --is-ancestor "$PIN1" HEAD ) 2>/dev/null &&
       ( cd "$GITDIR" && git show "$PIN1:./busadapt8.v" ) > "$T/pre_busadapt8.v" 2>/dev/null &&
       ! grep -q 'fetch_owed' "$T/pre_busadapt8.v"; then
      iverilog -g2005 -Ptb.HOST_MODE=1 -o "$T/pre.vvp" -s tb \
        "$T/tb.v" "$HERE/sof_protocol_check.v" "$RTL/plane32bus.v" "$T/pre_busadapt8.v" "$RTL/core32.v" 2>/dev/null
      pout=$(vvp "$T/pre.vvp" 2>&1)
      ppr=$(echo "$pout" | sed -n 's/^ *PROTO: //p')
      if echo "$pout" | grep -q 'L-FAIL  L7'; then
        echo "        ✅ GATE 1b WELL-FOUNDED: on the pre-repair RTL ($PIN1) the SAME host takes L7 red"
        echo "                                 [$ppr]  ⇒ the rule guards a real hazard; (B) removed it"
      else
        echo "        ⛔ GATE 1b FAILED — the violating host does NO harm even on the PRE-REPAIR RTL."
        echo "           Then the rule never guarded anything measurable and ARM V is not violating."; rc=1
      fi
    else
      echo "        ⛔ GATE 1b UNAVAILABLE — no pre-repair DUT at $PIN1 that lacks the repair."
      echo "           Well-foundedness is UNKNOWN, which is not the same as satisfied."; rc=1
    fi
  else
    if [ "${v:-1}" -eq 0 ]; then echo "        ✅ GATE 2: the compliant host takes ZERO violations — the rule is satisfiable"
    else echo "        ⛔ GATE 2 FAILED — a rule-following host still violates; the rule is wrong"; rc=1; fi
    if [ "${ps:-0}" -ge 3 ]; then echo "        ✅ GATE 3: it asserted sof ${ps}x — the rule PERMITS WORK, not just forbids it"
    else echo "        ⛔ GATE 3 FAILED — compliant host asserted sof ${ps}x; a vacuous pass"; rc=1; fi
  fi
done
echo
[ $rc = 0 ] && echo "SOF_PROTOCOL_RULE=PASS (binding: bad host caught · good host clean · good host still works)" \
            || echo "SOF_PROTOCOL_RULE=BROKEN"
exit $rc

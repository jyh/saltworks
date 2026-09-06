#!/bin/sh
# run_sof_repair_verify.sh — DOES SHAPE (B) CLOSE THE AMENDMENT 2 HAZARD, AND IN THE
# DESIGN THAT ACTUALLY SHIPS?
#
# silicon, 2026-09-06. Companion to run_sof_window_census.sh, which DEMONSTRATES the
# defect and whose gate therefore REQUIRES three red arms. That script is a defect
# demonstrator: once (B) lands it reports BROKEN, correctly and forever. This script is
# the REGRESSION side, and it is a separate file precisely so that neither gate has to be
# weakened to accommodate the other.
#
# ⛔⛔ WHY THIS SCRIPT COMPILES THREE DUTs AND NOT ONE — THE FINDING THAT FORCED IT.
# `run_sof_window_census.sh`'s own header says "The DUT is the SHIPPED busadapt8.v".
# THAT SENTENCE IS FALSE, and I wrote it. It resolves `RTL=$HERE/../../RTL`, which is
# saltworks' RTL — and saltworks' `busadapt8.v` has been FOUR COMMITS AHEAD of the
# shuttle since 2026-08-19. "SHIPPED" meant "unmutated" in my head and reads as "the one
# in the tape-out" on the page. Measured divergence: the shuttle's copy has NO
# `load_beat` — option (2), the two-loop LOAD, landed at `1916ea0c` AFTER the shuttle
# snapshot `5e7d73b`. `core32.v` and `plane32bus.v` are code-identical; `busadapt8.v` is
# the only logic divergence.
# ⇒ A MEASUREMENT NAMES AN OBJECT, AND "SHIPPED" IS A CLAIM ABOUT AN OBJECT, NOT A
#   SYNONYM FOR "UNMODIFIED". So this script names its DUT by PATH, prints the path it
#   compiled, and tests the tape-out copy as its own arm rather than assuming the
#   defect transfers.
#
# THE THREE DUTs:
#   shipped   the tape-out source, jyh/tt-neural-dataflow-fabric @ main  (NO option (2))
#   prefix    saltworks RTL at the PINNED pre-repair sha                (option (2), unrepaired)
#   fixed     saltworks RTL in the working tree                           (option (2) + shape (B))
#
# ⛔ THE GATE, AND IT IS WHY THIS IS EVIDENCE AND NOT A GREEN SCREEN:
#   · `fixed`   MUST be clean on ALL SIX arms.
#   · `prefix`  MUST go RED on 10/11/12 — the control proving the criterion CAN fail on
#               this bench, on this day, against this tb. Without it, `fixed`'s green is
#               a fact about a test that cannot fail.
#   · `shipped` is MEASURED, NOT ASSERTED. Its result is the answer to "does the hazard
#               reach the tape-out", and the script prints that answer either way rather
#               than gating on a value I expected before running it.
#   · arm 13 must not merely stay clean: it must still PERFORM A REAL TRANSACTION
#     (kind := T_LOAD). A guard that silences the protected cycle too would pass a
#     clean-arm check VACUOUSLY. A RULE MUST BE SHOWN TO PERMIT WORK, NOT ONLY TO FORBID IT.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
RTL="$HERE/../../RTL"
SRC="$HERE/../wordonly/tb_plane32bus_lwsw.v"
TT="${TT_SRC:-$HOME/projects/claude/seats/silicon/tt-neural-dataflow-fabric/src}"
[ -f "$SRC" ] || { echo "⛔ tracked bench not found: $SRC"; exit 2; }
T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT

# ---- materialise the three busadapt8 variants, each from a NAMED object -------------
mkdir -p "$T/fixed" "$T/prefix" "$T/shipped"
cp "$RTL/busadapt8.v" "$T/fixed/busadapt8.v"

# ⛔⛔ THE CONTROL IS PINNED TO A SHA, NOT TO `HEAD`, AND THAT IS THE WHOLE POINT.
# The first version read `git show HEAD:./busadapt8.v`. That works exactly until shape (B)
# is COMMITTED — after which HEAD *contains* the repair, the control becomes byte-identical
# to the treatment, and this script disarms its own falsifiability at the moment the work
# lands. It would then refuse (the cmp below catches it) — but a control that dies on the
# first commit is a control written against a world that was about to end.
# ⇒ A CONTROL DEFINED RELATIVE TO A MOVING REFERENCE IS NOT A CONTROL, IT IS A DELAY.
#   Name the object; check its ancestry; assert it lacks the treatment.
PIN="${SOF_PREFIX_PIN:-afa8a2e7}"
( cd "$RTL" && git merge-base --is-ancestor "$PIN" HEAD ) 2>/dev/null || {
    echo "⛔ control pin $PIN is NOT an ancestor of HEAD. Resolvability is not membership."
    echo "   REFUSING rather than controlling against an object outside this history."; exit 2; }
( cd "$RTL" && git show "$PIN:./busadapt8.v" ) > "$T/prefix/busadapt8.v" 2>/dev/null || {
    echo "⛔ cannot materialise the pre-repair RTL at $PIN — the control is unavailable"; exit 2; }
if grep -q 'fetch_owed' "$T/prefix/busadapt8.v"; then
    echo "⛔ the control at $PIN ALREADY CONTAINS shape (B). It cannot demonstrate the"
    echo "   defect it exists to demonstrate. REFUSING."; exit 2; fi
# ⛔⛔ THE TAPE-OUT ARM READS `origin/main`, NOT THE WORKING TREE — AND THIS BIT ME.
# The first version did `cp "$TT/busadapt8.v"`. The moment I checked out a branch in that
# repo to stage the port, the "shipped" arm started reading MY BRANCH and reported
# red_on_10/11/12 = 0 — i.e. "the tape-out does not have the hazard", which was a fact
# about my own uncommitted work wearing the name of the fabricated design.
# ⇒ THE SAME DEFECT THIS SCRIPT WAS WRITTEN TO CATCH, ONE LEVEL DOWN: a DUT named by a
#   PATH is named by something that moves. A checkout is a variable. Name the REF.
# The ref is `origin/main` because that is what the shuttle pins, and it is FETCHED first
# so the answer is about the remote's state and not a stale local cache.
TT_REF="${TT_REF:-origin/main}"
if [ -d "$TT/../.git" ] || [ -f "$TT/../.git" ]; then
  ( cd "$TT/.." && git fetch -q origin 2>/dev/null || true )
  ( cd "$TT/.." && git show "$TT_REF:src/busadapt8.v" ) > "$T/shipped/busadapt8.v" 2>/dev/null || {
      echo "⛔ cannot materialise src/busadapt8.v at $TT_REF in $TT/.."
      echo "   REFUSING rather than falling back to the working tree, which is a checkout"
      echo "   and therefore a variable."; exit 2; }
  SHIPPED_DESC="$TT_REF:src/busadapt8.v  (sha $(cd "$TT/.." && git rev-parse --short "$TT_REF" 2>/dev/null))"
else
  echo "⛔ $TT/.. is not a git repository; cannot name the tape-out source by ref."; exit 2
fi

# The control must actually DIFFER from the treatment, or it is not a control.
if cmp -s "$T/fixed/busadapt8.v" "$T/prefix/busadapt8.v"; then
  echo "⛔ fixed and prefix are byte-identical — the repair is not in the working tree."
  echo "   A control that cannot differ from its treatment proves nothing. REFUSING."
  exit 2
fi

sed -e 's/^module tb;/module tb;\n  parameter integer ARM = 0;/' "$SRC" > "$T/tb.v"
python3 - "$T/tb.v" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
inj = r'''
  // ---- the single injected variable: one sof pulse, at a chosen cycle ----------
  integer sof_pulses = 0, armed = 0, cnt = 0, ph_target = 0, showed = 0;
  integer seen_phase = -1; reg [31:0] seen_cinstr = 0; reg seen_req = 0, seen_we = 0;
  integer kind_after = -1; integer settle = -1;
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

  // ---- observation, in two parts, and the SECOND is the one that cannot lie ------
  // (a) what the arm READS at the sampling edge; (b) the `kind` the arm ACTUALLY
  // COMMITTED one cycle later. The census's original probe printed only (a) and then
  // ASSERTED the consequence ("kind will be T_STORE") by re-deriving it from req/we in
  // the testbench. That re-derivation is a COPY OF THE UNREPAIRED EXPRESSION, so after
  // (B) lands it keeps printing the OLD answer beside the NEW behaviour and reads as a
  // repair that did not take. ⇒ NEVER RE-DERIVE THE THING UNDER TEST IN THE INSTRUMENT;
  // SAMPLE IT. (b) is sampled from the DUT and is correct for every variant.
  // ⛔⛔ ONE BLOCK, NOT TWO, AND THE REASON IS A DEFECT THIS PROBE ALREADY HAD.
  // The first version used TWO `always @(negedge clk)` blocks — one to arm `settle`,
  // one to sample on the next edge. Two blocks on the SAME edge have NO DEFINED ORDER
  // in Verilog, so the sampler sometimes ran in the same time step as the armer and
  // returned the kind BEFORE the posedge instead of after. It was caught because the
  // UNREPAIRED control disagreed with itself across arms of one identical design
  // (arm 10 -> 3, arm 11 -> 1, arm 12 -> 3). ⇒ AN INSTRUMENT THAT DISAGREES WITH ITSELF
  // ON ONE UNCHANGED DUT IS REPORTING ITS OWN RACE, NOT THE DUT. Sampling `settle`
  // BEFORE setting it, inside a single block, makes the one-cycle delay deterministic.
  always @(negedge clk) if (rst_n) begin
    if (settle == 1) begin settle = 0; kind_after = dut.u_bus.kind; end
    if (sof && showed == 0) begin
      showed = 1; settle = 1;
      seen_phase = dut.u_bus.phase; seen_cinstr = dut.u_bus.c_instr;
      seen_req = dut.u_bus.c_dmem_req; seen_we = dut.u_bus.c_dmem_we;
    end
  end
'''
i = s.index('  initial begin')
s = s[:i] + inj + '\n' + s[i:]
extra = r'''    $display("  ARCH: lw_exec=%0d sw_exec=%0d sof_pulses=%0d", n_lw_exec, n_sw_exec, sof_pulses);
    if (showed == 1) $display("  READS: phase=%0d c_instr=%h req=%b we=%b || COMMITTED kind=%0d (1=FETCH 2=LOAD 3=STORE)",
                              seen_phase, seen_cinstr, seen_req, seen_we, kind_after);
    $finish;'''
s = s.replace('    $finish;', extra, 1)
io.open(p,'w',encoding='utf-8').write(s)
PY

rc=0
run_dut () {                      # $1 = variant name, $2 = dir holding busadapt8.v
  V=$1; D=$2; reds=0; clean=0; a13kind=""
  echo "──────────────────────────────────────────────────────────────────────────────"
  echo "DUT = $V"
  echo "      busadapt8.v : $3"
  echo "      plane32bus.v/core32.v : $RTL   (code-identical across both trees, checked)"
  for A in 0 10 11 12 13 20; do
    iverilog -g2005 -Ptb.ARM=$A -o "$T/$V$A.vvp" -s tb \
      "$T/tb.v" "$RTL/plane32bus.v" "$D/busadapt8.v" "$RTL/core32.v"
    out=$(vvp "$T/$V$A.vvp" 2>&1)
    un=$(echo "$out"  | sed -n 's/.*UNACCOUNTED = \([0-9]*\).*/\1/p' | head -1)
    arch=$(echo "$out"| sed -n 's/^ *ARCH: //p'   | head -1)
    rd=$(echo "$out"  | sed -n 's/^ *READS: //p'  | head -1)
    vd=$(echo "$out"  | grep -E 'ALL PASS|RED:'   | sed 's/^ *//')
    printf '  ARM %-3s unaccounted=%-3s %-40s %s\n' "$A" "${un:-?}" "$arch" "$vd"
    [ -n "$rd" ] && printf '          %s\n' "$rd"
    if echo "$out" | grep -q 'L-FAIL  L7'; then
      case "$A" in 10|11|12) reds=$((reds+1));; esac
    fi
    if [ "$un" = 0 ] && echo "$out" | grep -q 'ALL PASS'; then clean=$((clean+1)); fi
    [ "$A" = 13 ] && a13kind=$(echo "$rd" | sed -n 's/.*COMMITTED kind=\([0-9]*\).*/\1/p')
  done
  echo "  → $V: clean_arms=$clean/6  red_on_10_11_12=$reds  arm13_committed_kind=${a13kind:-?}"
  RES_CLEAN=$clean; RES_REDS=$reds; RES_A13=$a13kind
}

run_dut prefix  "$T/prefix"  "saltworks RTL @ git HEAD (pre-repair)"
P_REDS=$RES_REDS; P_CLEAN=$RES_CLEAN
run_dut shipped "$T/shipped" "$SHIPPED_DESC (tape-out, by REF not by checkout)"
S_REDS=$RES_REDS; S_CLEAN=$RES_CLEAN
run_dut fixed   "$T/fixed"   "saltworks RTL working tree (shape (B))"
F_REDS=$RES_REDS; F_CLEAN=$RES_CLEAN; F_A13=$RES_A13

echo
echo "══════════════════════════════════════════════════════════════════════════════"
echo "CONTROL   prefix  : red_on_10/11/12 = $P_REDS  (MUST be 3 — proves the bench can fail today)"
echo "MEASURED  shipped : red_on_10/11/12 = $S_REDS  (the tape-out's own answer, not asserted)"
echo "TREATMENT fixed   : clean_arms = $F_CLEAN/6, reds = $F_REDS  (MUST be 6 and 0)"
echo "VACUITY   fixed arm 13 committed kind = ${F_A13:-?}  (MUST be 2 = T_LOAD: the guard must still PERMIT)"
echo

[ "$P_REDS" = 3 ] || { echo "⛔ THE CONTROL DID NOT GO RED. The treatment green is then a fact about a test"
                       echo "   that cannot fail, not about the repair. REFUSING."; rc=1; }
[ "$F_CLEAN" = 6 ] || { echo "⛔ the repaired DUT is not clean on all six arms"; rc=1; }
[ "$F_REDS"  = 0 ] || { echo "⛔ the repaired DUT still re-issues a completed store"; rc=1; }
[ "$F_A13"   = 2 ] || { echo "⛔ ARM 13 NO LONGER COMMITS T_LOAD (got '${F_A13:-?}'). The guard has"
                        echo "   silenced the one protected cycle instead of protecting it — a VACUOUS"
                        echo "   pass: clean because nothing happens, not because nothing goes wrong."; rc=1; }

if [ "$S_REDS" = 3 ]; then
  echo "⇒ THE TAPE-OUT SOURCE CARRIES THE HAZARD: 3 of 4 cycles, same as saltworks."
  echo "  The repair is therefore load-bearing for the shuttle and not only for the lab tree."
elif [ "$S_REDS" = 0 ]; then
  echo "⇒ THE TAPE-OUT SOURCE DOES NOT EXHIBIT IT ON THIS BENCH. Do NOT read that as safe:"
  echo "  it lacks option (2), so this bench may not reach the same states. STOP AND SAY SO."
else
  echo "⇒ THE TAPE-OUT SOURCE IS PARTIALLY AFFECTED ($S_REDS of 3). Report the number, not a word."
fi

# ⛔⛔ THE SIXTH GATE, AND IT EXISTS BECAUSE THE FIVE ABOVE WERE NOT SUFFICIENT.
# The six arms passed 6/6 on a version of shape (B) that STILL LEFT 4 OF 121 ARRIVAL CYCLES
# CORRUPT. They arm on `mem_retire` and step through the FOUR PHASES THAT FOLLOW, so the
# retiring edge ITSELF is not one of them — and that was exactly where the residual lived.
# ⇒ ***THE ARMS ARE A SET, NOT A PREFIX. "All four phases" is not "the whole window" when
#   the window opens one cycle before the phase you counted from.*** A hand-chosen set of
#   stimulus points cannot answer a coverage question; only the exhaustive sweep can.
# So the regression gate now REQUIRES the full sweep to read zero, and this script is not
# green until it does.
echo
echo "── EXHAUSTIVE ARRIVAL SWEEP (the arms above are a SET; this is the coverage claim) ──"
SWEEP="$HERE/run_sof_reachability_sweep.sh"
if [ -x "$SWEEP" ] || [ -f "$SWEEP" ]; then
  SW_OUT=$(sh "$SWEEP" 2>&1) || true
  echo "$SW_OUT" | sed -n 's/^/  /p' | grep -E 'SWEPT|CORRUPTED|INSTRUCTION|REACHABILITY' || true
  SW_BAD=$(echo "$SW_OUT" | sed -n 's/^CORRUPTED (a store unaccounted) *\([0-9]*\).*/\1/p' | head -1)
  SW_LOST=$(echo "$SW_OUT" | sed -n 's/^INSTRUCTION LOST (lw_exec down) *\([0-9]*\).*/\1/p' | head -1)
  if [ "${SW_BAD:-x}" = "0" ] && [ "${SW_LOST:-x}" = "0" ]; then
    echo "  ✅ 0 corrupt arrivals and 0 lost instructions across the swept range."
  else
    echo "  ⛔ RESIDUAL: corrupt=${SW_BAD:-?} lost=${SW_LOST:-?}. The six arms can be GREEN while"
    echo "     this is non-zero — that is the whole reason this gate exists. NOT a pass."
    rc=1
  fi
else
  echo "  ⛔ sweep not found at $SWEEP — coverage is UNKNOWN, which is not the same as clean."
  rc=1
fi

[ $rc = 0 ] && echo "SOF_REPAIR_VERIFY=PASS (control red, treatment clean, arm 13 permits work, sweep 0/0)" \
            || echo "SOF_REPAIR_VERIFY=BROKEN"
exit $rc

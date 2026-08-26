#!/bin/sh
# run_retire_discriminating.sh — the arbitration simulation and its CPI measurement.
#
# PROMOTED 2026-08-26 from untracked executor scratch (ScratchRETIRE-run.sh, 08/17).
# ⛔ WHY IT WAS PROMOTED: the 08-23->27 rung of the plan-to-prove is gated on
#    "tb + arbitration sim; CPI measured against §7's 12" — and the only artifact that
#    measures it lived in three UNTRACKED files at the repo root. A gate that git does
#    not carry is a gate no other seat can run and no clone inherits.
#
# WHAT IT MEASURES: retire-to-retire distance, which IS cycles-per-instruction. §7's
# phase accounting predicts 4 (fetch only), 8 (fetch+load address), 12 (fetch+store
# address+store data). The positive arm reproduces exactly that distribution.
#
# ARMS: one positive (must go GREEN) and five that must go RED, including two mutation
# controls -- a bench that cannot reject is not a bench.
#
# Reads SaltWorks/Silicon/RTL/{core32,busadapt8}.v. WRITES NOTHING under the repo
# except its own build dir (${TMPDIR}) — no committed file is edited.
#
# Run:  sh ScratchRETIRE-run.sh
set -e
HERE=$(cd "$(dirname "$0")/../../../.." && pwd)
RTL="$HERE/SaltWorks/Silicon/RTL"
TB="$HERE/SaltWorks/Silicon/Sim/wordonly/tb_retire_discriminating.v"
IRG="$HERE/SaltWorks/Silicon/Sim/wordonly/busadapt8_irgated_PROBE.v"
OUT="${TMPDIR:-/tmp}/saltworks-retire.$$"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

run() {   # run <label> <adapter.v> <defines...>
  LBL="$1"; ADP="$2"; shift 2
  echo
  echo "############################################################"
  echo "## $LBL"
  echo "############################################################"
  iverilog -g2012 "$@" -o "$OUT/a.vvp" "$TB" "$RTL/core32.v" "$ADP"
  echo "iverilog EXIT=$?"
  vvp "$OUT/a.vvp"
  echo "vvp EXIT=$?"
}

echo "=== THE TWO ARMS (addressed-memory host, mixed program) ==="
run "ARM A — en tied HIGH (negative control): must go RED"  "$RTL/busadapt8.v" -DARM_EN_HIGH
run "ARM B — en = retire  (positive arm):     must go GREEN" "$RTL/busadapt8.v" -DARM_EN_RETIRE

echo
echo "=== MUTATION CONTROLS: the bench must be able to reject ==="
run "MUTANT Z — en = 1'b0  (retire held low)"  "$RTL/busadapt8.v" -DARM_EN_ZERO
run "MUTANT I — en = ~retire (enable inverted)" "$RTL/busadapt8.v" -DARM_EN_INV

echo
echo "=== WHICH REMEDY DID THE WORK: silicon's ORIGINAL store-only host ==="
echo "    (the type stream stays blind — 98 store loops both arms — but the PC"
echo "     observables C2/C3 still separate them. R1 alone is sufficient.)"
run "ARM A + store-only host"  "$RTL/busadapt8.v" -DARM_EN_HIGH   -DHOST_STOREONLY
run "ARM B + store-only host"  "$RTL/busadapt8.v" -DARM_EN_RETIRE -DHOST_STOREONLY

echo
echo "=== THE FRAGILITY PROBE: gate instr_r on retire (HYPOTHETICAL adapter) ==="
echo "    The store then carries its OWN operands — and 31d070f comes straight"
echo "    back: 97 consecutive STORE loops. The enable is necessary, not sufficient."
run "ARM B + IR gated on retire (hypothetical)" "$IRG" -DARM_EN_RETIRE -DPROBE

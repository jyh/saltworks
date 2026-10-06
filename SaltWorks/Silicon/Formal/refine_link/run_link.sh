#!/bin/sh
# run_link.sh — desk AAU W1: the SAT link from the Lean pin model to the FABRICATED RTL.
# Emits SaltWorks/Silicon/Refine/Model.lean as Verilog (emit.lean, through saltbuild), then has yosys
# prove it equivalent to core32.v + busadapt8.v + plane32bus.v at 01e19f7. Every flop and output is
# matched BY NAME (equiv_make), and equiv_induct proves the matched signals equal. A MUTANT CONTROL
# follows: the model with SRA/SRAI transcribed as an arithmetic shift must FAIL.
# env: OUT (scratch, required) · TTDIR (tape-out clone)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../../.." && pwd)
TTDIR=${TTDIR:-$HOME/projects/claude/seats/silicon/tt-neural-dataflow-fabric}
OUT=${OUT:?set OUT to a scratch directory}; mkdir -p "$OUT/fab"
REF=01e19f7
CORE_BLOB=e8a918015484e542d3d0cee2ded4722add55910a
BUS_BLOB=c06e10a301d3adf61cefea352d4ebd8841cff648
PLANE_BLOB=d13825ee
for f in core32.v busadapt8.v plane32bus.v; do git -C "$TTDIR" show "$REF:src/$f" > "$OUT/fab/$f"; done
[ "$(git hash-object "$OUT/fab/core32.v")" = "$CORE_BLOB" ] || { echo "⛔ core32.v blob"; exit 2; }
[ "$(git hash-object "$OUT/fab/busadapt8.v")" = "$BUS_BLOB" ] || { echo "⛔ busadapt8.v blob"; exit 2; }
case "$(git hash-object "$OUT/fab/plane32bus.v")" in $PLANE_BLOB*) ;; *) echo "⛔ plane32bus.v blob"; exit 2;; esac
echo "gold: $REF core32 $CORE_BLOB · busadapt8 $BUS_BLOB · plane32bus ${PLANE_BLOB}… · $(yosys -V | cut -d' ' -f1-2)"

( cd "$ROOT" && OUT_DIR="$OUT" ../saltbuild.sh SaltWorks/Silicon/Formal/refine_link/emit.lean ) > "$OUT/emit.log" 2>&1 \
  || { echo "⛔ emit failed"; tail -5 "$OUT/emit.log"; exit 2; }
echo "model: $(git hash-object "$OUT/model.v") ($(wc -l < "$OUT/model.v") lines) · mutant $(git hash-object "$OUT/model_ashr.v")"

link() {  # $1 = gate verilog, $2 = tag
  cat > "$OUT/$2.ys" <<YS
read_verilog $OUT/fab/core32.v $OUT/fab/busadapt8.v $OUT/fab/plane32bus.v
hierarchy -top plane32bus; proc; flatten; memory; opt_clean; rename plane32bus gold; design -stash gold
read_verilog $1
hierarchy -top plane32bus; proc; opt; rename plane32bus gate; design -stash gate
design -copy-from gold -as gold gold
design -copy-from gate -as gate gate
equiv_make gold gate equiv
hierarchy -top equiv
async2sync
equiv_simple
equiv_induct
equiv_status -assert
YS
  yosys -l "$OUT/$2.log" "$OUT/$2.ys" > /dev/null 2>&1
}

# the matched population: every gold flop's Q wire and every output must be an equiv pair
if link "$OUT/model.v" link; then
  echo "LINK PROVEN: $(grep -F 'are proven and' "$OUT/link.log" | tail -1 | sed 's/^ *//')"
else
  echo "⛔ LINK FAILED"; grep -F -i 'unproven' "$OUT/link.log" | head -20; exit 3
fi
missing=0
for w in u_core.pc_r u_bus.phase u_bus.kind u_bus.store_beat u_bus.fetch_owed u_bus.in_acc u_bus.instr_r u_bus.rdata_r addr_byte phase_o retire; do
  grep -F -q "\\$w" "$OUT/link.log" || { echo "⛔ not matched: $w"; missing=1; }
done
n=$(grep -c -F 'u_core.regs[' "$OUT/link.log" || true)
[ "$n" -gt 0 ] || { echo "⛔ no regs[] in the matched set"; missing=1; }
[ "$missing" = 0 ] || exit 4

# the mutant control: SRA/SRAI as ashr must NOT be equivalent
if link "$OUT/model_ashr.v" mutant; then
  echo "⛔ MUTANT PROVEN EQUIVALENT — the link cannot see the erratum"; exit 5
else
  echo "mutant control: REFUSED ($(grep -F -c 'Unproven' "$OUT/mutant.log" || true) 'Unproven' lines) — the link sees SRA/SRAI"
fi

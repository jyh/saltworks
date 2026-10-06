#!/bin/sh
# run_link.sh — desk AAU W1: the SAT link from the Lean pin model to the FABRICATED RTL.
#
# WHAT IS PROVED: the Lean model's transition function and pin outputs EQUAL those of
# core32.v + busadapt8.v + plane32bus.v at jyh/tt-neural-dataflow-fabric@01e19f7. That holds for
# every value of every flop, every input (rst_n and sof included) and every Verilog `x` in the gold
# (freed by `setundef -anyseq`, so no fixed choice is made for them). The gold's flops are cut open
# (`expose -evert-dff`); each alias of a flop's output net is tied to ONE state input, and EVERY
# alias's next-state output is compared (comb_wrap.py refuses a flop it cannot place). Two
# machines with equal transition and output functions over the same state, started from the
# same state, agree in every cycle, so this is the sequential link the Lean theorem needs.
# ABC `iprove` decides the miter.
# CONTROL: the model with SRA/SRAI transcribed as an ARITHMETIC shift must be found NOT equivalent.
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
echo "model: model_comb.v $(git hash-object "$OUT/model_comb.v") · mutant $(git hash-object "$OUT/model_comb_ashr.v")"

F=$OUT/fab
yosys -q -p "read_verilog $F/core32.v $F/busadapt8.v $F/plane32bus.v; hierarchy -top plane32bus; proc; flatten; memory; opt_clean; async2sync; dffunmap; expose -evert-dff; opt_clean; rename plane32bus gold_exp; write_verilog -noattr $OUT/gold_exp.v" \
  || { echo "⛔ gold cut-open failed"; exit 2; }
python3 "$HERE/comb_wrap.py" "$OUT/gold_exp.v" model_comb > "$OUT/chkbad.v" 2> "$OUT/wrap.log" || { cat "$OUT/wrap.log"; exit 2; }
echo "wrap: $(cat "$OUT/wrap.log")"

prove() {  # $1 = model verilog, $2 = tag; prints ABC's verdict line
  yosys -p "read_verilog $OUT/gold_exp.v; read_verilog $1; read_verilog $OUT/chkbad.v; hierarchy -top chkbad; proc; flatten; opt_clean; setundef -anyseq; techmap; opt -fast; aigmap; opt_clean; write_aiger -zinit $OUT/$2.aig" > "$OUT/$2.ys.log" 2>&1 \
    || { echo "⛔ $2: AIG build failed"; exit 2; }
  # THE FREED-BIT ACCOUNTING: every bit treated as free must be a primary input of the miter
  # (the 1,126 flop-state bits and the 10 input bits) or one of the gold's regs[0] read leaves
  # (2 ports x 32 bits; regs is declared [1:31], so that read is `x` and is muxed away by rs==0).
  grep -F 'Treating undriven bit' "$OUT/$2.ys.log" | sed -E 's/.*chkbad\.(\\?[^ ]*) \[?[0-9]*\]? ?like.*/\1/' > "$OUT/$2.freed"
  st=$(grep -c -E '^\\?s_u_(core|bus)_' "$OUT/$2.freed" || true)
  pi=$(grep -c -E '^\\?(rst_n|sof|instr_byte)$' "$OUT/$2.freed" || true)
  ot=$(grep -v -c -E '^\\?(s_u_(core|bus)_|rst_n$|sof$|instr_byte$)' "$OUT/$2.freed" || true)
  echo "freed bits: state $st · inputs $pi · other $ot (expected 1126 · 10 · 64)" >&2
  [ "$st" = 1126 ] && [ "$pi" = 10 ] && [ "$ot" = 64 ] || { echo "⛔ $2: freed-bit accounting does not close" >&2; exit 6; }
  yosys-abc -c "read $OUT/$2.aig; strash; print_stats; iprove" > "$OUT/$2.abc" 2>&1
  grep -E 'SATISFIABLE|UNSATISFIABLE|i/o' "$OUT/$2.abc" | sed 's/\x1b\[[0-9;]*m//g'
}
v=$(prove "$OUT/model_comb.v" link)
echo "$v" | sed 's/^/link: /'
echo "$v" | grep -q '^UNSATISFIABLE' || { echo "⛔ LINK NOT PROVED"; exit 3; }
m=$(prove "$OUT/model_comb_ashr.v" mutant)
echo "$m" | sed 's/^/mutant: /'
echo "$m" | grep -q '^SATISFIABLE' || { echo "⛔ MUTANT NOT REFUSED — the link cannot see SRA/SRAI"; exit 5; }
echo "LINK PROVEN; mutant control REFUSED"

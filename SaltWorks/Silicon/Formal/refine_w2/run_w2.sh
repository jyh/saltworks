#!/bin/sh
# run_w2.sh — desk AAU W2: the spec's independent cross-check. `exec false` (Statement.lean) against
# riscv-formal's 31 per-instruction models (insns/insn_*.v at c992aa6), on 8,000 pseudo-random
# vectors: 31 forced-opcode families and 1 in 8 fully random words. A CONTROL run follows: `exec
# true` must disagree, and only in LW and the funct3=5 shifts (SRA/SRAI's families).
# env: OUT (scratch, required) · RVF (riscv-formal clone) · N (vectors, default 8000)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../../../.." && pwd)
RVF=${RVF:-$HOME/src/riscv-formal}; N=${N:-8000}; OUT=${OUT:?set OUT to a scratch directory}
[ "$(git -C "$RVF" rev-parse --short=7 HEAD)" = c992aa6 ] || { echo "⛔ riscv-formal is not at c992aa6"; exit 2; }
OPS="lui auipc jal jalr beq bne blt bge bltu bgeu lw sw addi slti sltiu xori ori andi slli srli srai add sub sll slt sltu xor srl sra or and"
mkdir -p "$OUT/rv32i" "$OUT/erratum"
iverilog -g2012 -o "$OUT/tbw2" "$HERE/tb_w2.v" $(for o in $OPS; do printf '%s ' "$RVF/insns/insn_$o.v"; done)
for arm in rv32i erratum; do
  E=0; [ "$arm" = erratum ] && E=1
  ( cd "$ROOT" && OUT_DIR="$OUT/$arm" W2_E=$E W2_N=$N ../saltbuild.sh SaltWorks/Silicon/Formal/refine_w2/vectors.lean ) > "$OUT/$arm/gen.log" 2>&1 \
    || { echo "⛔ $arm: vector generation failed"; tail -3 "$OUT/$arm/gen.log"; exit 2; }
  ( cd "$OUT/$arm" && vvp -n "$OUT/tbw2" > vvp.log 2>&1 )
  set +e; python3 "$HERE/compare.py" "$OUT/$arm/w2_vectors.txt" "$OUT/$arm/w2_rvf.txt" > "$OUT/$arm/cmp.txt"; rc=$?; set -e
  echo "$arm: $(grep TOTAL "$OUT/$arm/cmp.txt") (rc $rc)"
  eval "rc_$arm=$rc"
done
[ "$rc_rv32i" = 0 ] || { echo "⛔ RV32I spec disagrees with riscv-formal"; exit 3; }
[ "$rc_erratum" = 1 ] || { echo "⛔ CONTROL: the erratum spec did NOT disagree — the comparator cannot see the erratum"; exit 4; }
moved=$(diff "$OUT/rv32i/cmp.txt" "$OUT/erratum/cmp.txt" | grep -E '^[<>] +[0-9]+  AGREE opc=' | sed 's/.*AGREE //' | sort -u | tr '\n' ' ')
echo "control: AGREE moved only in: $moved"
case "$moved" in "opc=03 f3=2 opc=13 f3=5 opc=33 f3=5 ") echo "W2 PASS" ;; *) echo "⛔ CONTROL moved an unexpected family"; exit 5;; esac

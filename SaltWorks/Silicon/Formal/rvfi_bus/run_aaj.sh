#!/bin/sh
# run_aaj.sh — desk AAJ: riscv-formal on the FABRICATED core32 + busadapt8, at the BUS level.
# env: CFG (checks.cfg to use) · TAG (core-dir suffix) · TARGETS (make targets; default all) · OUT (scratch, required) · TTDIR (tape-out clone) · RVF (riscv-formal clone) · SBY_BIN · JOBS · DUT
#   DUT=fab (default) checks the fabricated sources; DUT=ctl_all applies step 0's control patches
#   (patch_variants.py all: both shift fixes + a c_dmem_rdata bypass) — the CONTROL that must pass.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
CONF=$HERE/../../Sim/conformance
TTDIR=${TTDIR:-$HOME/projects/claude/seats/silicon/tt-neural-dataflow-fabric}
RVF=${RVF:-$HOME/src/riscv-formal}; RVF_SHA=c992aa6
SBY_BIN=${SBY_BIN:-$HOME/src/sby-inst/bin}; JOBS=${JOBS:-4}; DUT=${DUT:-fab}
OUT=${OUT:?set OUT to a scratch directory}; mkdir -p "$OUT"
REF=01e19f7
CORE_BLOB=e8a918015484e542d3d0cee2ded4722add55910a
BUS_BLOB=c06e10a301d3adf61cefea352d4ebd8841cff648
PLANE_BLOB=d13825ee
export PATH="$SBY_BIN:$PATH"

# ---- objects, each verified ------------------------------------------------------------------
[ "$(git -C "$RVF" rev-parse --short=7 HEAD)" = "$RVF_SHA" ] || { echo "⛔ riscv-formal is not at $RVF_SHA"; exit 2; }
command -v sby >/dev/null || { echo "⛔ sby not on PATH ($SBY_BIN)"; exit 2; }
echo "tools: $(yosys -V | cut -d' ' -f1-2) · sby $(cd "$SBY_BIN/.." && ls share/yosys/python3 >/dev/null 2>&1; sby --help >/dev/null && echo ok) · bitwuzla $(bitwuzla --version) · riscv-formal $RVF_SHA"
mkdir -p "$OUT/fab" "$OUT/tap"
for f in core32.v busadapt8.v plane32bus.v; do git -C "$TTDIR" show "$REF:src/$f" > "$OUT/fab/$f"; done
[ "$(git hash-object "$OUT/fab/core32.v")" = "$CORE_BLOB" ] || { echo "⛔ core32.v blob"; exit 2; }
[ "$(git hash-object "$OUT/fab/busadapt8.v")" = "$BUS_BLOB" ] || { echo "⛔ busadapt8.v blob"; exit 2; }
case "$(git hash-object "$OUT/fab/plane32bus.v")" in $PLANE_BLOB*) ;; *) echo "⛔ plane32bus.v blob"; exit 2;; esac
if [ "$DUT" = ctl_all ]; then python3 "$CONF/patch_variants.py" "$OUT/fab" all >/dev/null; echo "DUT = ctl_all (CONTROL: patched)"; else echo "DUT = fabricated $REF"; fi

# ---- taps, and the proof that they changed nothing ---------------------------------------------
python3 "$HERE/tap.py" "$OUT/fab" "$OUT/tap"
# busadapt8.v is tapped too (tap.py writes it)
cat > "$OUT/equiv.ys" <<YS
read_verilog $OUT/fab/core32.v $OUT/fab/busadapt8.v $OUT/fab/plane32bus.v
hierarchy -top plane32bus; proc; flatten; memory; opt_clean; rename plane32bus gold; design -stash gold
read_verilog $OUT/tap/core32.v $OUT/tap/busadapt8.v $OUT/tap/plane32bus.v
hierarchy -top plane32bus; proc; flatten; memory; opt_clean; rename plane32bus gate
delete -port gate/t_*
opt_clean; design -stash gate
design -copy-from gold -as gold gold
design -copy-from gate -as gate gate
equiv_make gold gate equiv
hierarchy -top equiv
async2sync
equiv_simple -seq 5
equiv_induct -seq 5
equiv_status -assert
YS
yosys -q -l "$OUT/equiv.log" "$OUT/equiv.ys" >/dev/null 2>&1 || { echo "⛔ TAPPED != FABRICATED"; grep -F unproven "$OUT/equiv.log"; exit 3; }
echo "taps: $(grep -F 'are proven and' "$OUT/equiv.log" | sed 's/^ *//')"

# ---- riscv-formal ----------------------------------------------------------------------------
C="$RVF/cores/core32bus_$DUT${TAG:+_$TAG}"; rm -rf -- "${C:?}"; mkdir -p "$C"
cp "$HERE/wrapper.sv" "$OUT"/tap/*.v "$C/"; cp "${CFG:-$HERE/checks.cfg}" "$C/checks.cfg"
( cd "$C" && python3 ../../checks/genchecks.py >/dev/null )
make -C "$C/checks" -j"$JOBS" -k ${TARGETS:-} >"$OUT/make.log" 2>&1 || true
for d in "$C"/checks/*/; do
  n=$(basename "$d"); s=$(cat "$d/status" 2>/dev/null || echo MISSING)
  echo "$n $s"
done | sort > "$OUT/results.txt"
echo "results ($DUT): $(cut -d' ' -f2 "$OUT/results.txt" | sort | uniq -c | tr '\n' ' ')"
echo "RVF_CORE_DIR=$C"

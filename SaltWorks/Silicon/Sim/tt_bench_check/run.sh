#!/bin/sh
# Re-runs test.py::test_counter_alignment's checks against the RTL under iverilog.
#
#   sh SaltWorks/Silicon/Sim/tt_bench_check/run.sh
#
# WHY THIS EXISTS: cocotb does not import on this host (it needs Python <= 3.13),
# so the bench that owns these assertions CANNOT BE RUN HERE. A repair to it would
# otherwise ship unverified. This re-runs both the SHIPPED and the REPAIRED form
# of each assertion against the same RTL and pins the outcome, so the repair rests
# on a measurement rather than on reading the pin map.
#
# It is a NEGATIVE-CONTROL harness first and a regression second: the shipped
# assertions are expected to MISBEHAVE in two specific, different ways, and if
# they ever stop misbehaving this script fails — because that would mean the RTL
# moved back under the bench.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
TT="$HERE/../../TT"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# src/ in the repo is DELIBERATELY partial -- banyan_fabric.v and bitserial_switch.v
# are copied from RTL/ by assemble.sh so no hand-maintained second copy can drift.
"$TT/assemble.sh" "$WORK" >/dev/null
cp "$HERE/tb_cnt.v" "$WORK/tb_cnt.v"
cd "$WORK"
iverilog -g2012 -o tb_cnt.vvp tb_cnt.v src/project.v src/banyan_fabric.v src/bitserial_switch.v
OUT=$(vvp tb_cnt.vvp | grep -v '^VCD')
echo "$OUT"

fail=0
check() { echo "$OUT" | grep -q "$1" || { echo "⛔ EXPECTED: $1"; fail=1; }; }
# (1) the loud one: uio[5] carries cnt_o[3], so the shipped assert is FALSE from t=8.
check 'first FAILS at cycle t=8'
# (2) the silent one: the shipped 3-bit check PASSES, aliasing cycles 8..13 onto 0..5.
check 'cnt3 == t%8 (3-bit)       : violations 0'
# and both repaired forms hold, all 14 cycles, two frames.
check 'assert (uio>>6)==0        : violations 0'
check 'cnt4 == t   (4-bit)       : violations 0'
check 'valid == (t>=HDR)         : violations 0'
[ $fail -eq 0 ] && echo "✅ ALL 5 EXPECTATIONS MET — the repair is measured, not asserted." \
                || { echo "⛔ tt_bench_check FAILED"; exit 1; }

#!/bin/bash
# compose_check.sh — DOES THE THING I MEASURED ACTUALLY CONTAIN THE COMPOSITION?
#
#   compose_check.sh <top> <required-module> [<required-module> ...]
#   exit 0 = every required module is present in the elaborated design
#   exit 1 = at least one is ABSENT, or the elaboration failed
#
# ⛔⛔ WHY THIS EXISTS: RUNG ZERO'S CONTROL ROW COULD NOT EVER PASS, AND I WROTE IT.
# §11′ of docs/silicon-offboard-data-block-0817.md says: *"any composed-area claim
# must cite a COMMITTED stat file whose netlist greps positive for BOTH a core/plane
# instance AND banyan_fabric. NO FILE, NO CLAIM."*
# Measured 2026-08-18 on the committed top that DOES instantiate all of them:
#     grep -c banyan_fabric tt_um_saltworks_ndf_nl.v  ->  0
#     grep -c slicea16bma   tt_um_saltworks_ndf_nl.v  ->  0
#     grep -c mac_cell      tt_um_saltworks_ndf_nl.v  ->  0
# Because `synth.sh` runs `synth -top $TOP -flatten`, and -flatten is NOT a
# preference — LibreLane flattens, so an UNflattened netlist is void as a proxy for
# anything flattening decides. A flattened netlist has NO module instances at all.
# ⇒ THE CONTROL COULD ONLY EVER SAY NO. A check that cannot pass has never been run,
#   and a check that cannot fail has never been shown to discriminate — this one was
#   the first kind, which is the rarer and more embarrassing half.
#
# ⭐ THE REPAIR IS TO SPLIT THE TWO QUESTIONS, because one artifact cannot answer
# both and pretending it can is what produced an impossible bar:
#     WHAT IS IN IT  -> an UNFLATTENED elaboration, where module names survive.
#     HOW BIG IS IT  -> the FLATTENED synth, which is what LibreLane will see.
# Neither run is asked to do the other's job. This script is the first half; the
# area still comes from <top>_stat.txt and is only quotable once this exits 0.
#
# ⚠️ WHAT THIS DOES NOT PROVE, stated because a containment check invites the
# assumption that the composition WORKS: it proves the module is INSTANTIATED and
# survives elaboration. It says nothing about whether it is correctly wired, whether
# its ports agree, or whether the composition executes anything. Functional
# correctness is fence-held (the top's own SCOPE clause).
set -u
TOP="${1:?usage: compose_check.sh <top> <required-module> [...]}"
shift
[ "$#" -gt 0 ] || { echo "compose_check: name at least one required module"; exit 2; }

HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../../SaltWorks/Silicon/RTL"
[ -d "$RTL" ] || { echo "compose_check: RTL dir not found at $RTL"; exit 2; }

PDK_VER="${PDK_VER:-c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
PDK_ROOT="${PDK_ROOT:-$HOME/.volare/volare/sky130/versions/$PDK_VER}"
LIB="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
[ -f "$LIB" ] || { echo "compose_check: liberty not found at $LIB"; exit 2; }

# Dependency closure, same rule as synth.sh: file name == module name. The `#(...)`
# arm is NOT cosmetic — without it a parameterized instantiation is invisible and
# yosys dies on a module "not part of the design".
SRCS="$TOP.v"
changed=1
while [ "$changed" = 1 ]; do
  changed=0
  for f in "$RTL"/*.v; do
    b="$(basename "$f")"; m="${b%.v}"
    case " $SRCS " in *" $b "*) continue ;; esac
    for s in $SRCS; do
      if grep -qE "(^|[^A-Za-z0-9_])$m([[:space:]]+#\(|[[:space:]]+[A-Za-z_])" "$RTL/$s" 2>/dev/null; then
        SRCS="$SRCS $b"; changed=1; break
      fi
    done
  done
done

READ=""
for s in $SRCS; do READ="$READ $RTL/$s"; done

# ⛔ NO `-q`, AND NO `2>/dev/null`. Both were tried while building this and both
# produced an EMPTY report that my parser read as "no modules" — a silent
# instrument failure is indistinguishable from a measurement of zero, and this one
# was caught only by checking the output file's line count.
LOG="$(mktemp)"; trap 'rm -f "$LOG"' EXIT
yosys -p "read_verilog$READ; hierarchy -top $TOP; proc; opt; stat" > "$LOG" 2>&1
RC=$?
LINES="$(wc -l < "$LOG" | tr -d ' ')"
if [ "$RC" -ne 0 ] || [ "$LINES" -lt 5 ]; then
  echo "compose_check: ⛔ ELABORATION FAILED (rc=$RC, ${LINES} lines of output)"
  tail -15 "$LOG"
  exit 1
fi

# The module roster is the set of `=== name ===` banners `stat` prints.
#
# ⛔ AND THE NAME YOU GAVE A THING IS NOT THE NAME IT WILL CARRY. First version of
# this line did `gsub(/\\/,"")` on $2 and reported `banyan_fabric` ABSENT from the
# top that visibly instantiates it — because the instantiation is PARAMETERIZED and
# yosys specialises it into
#     $paramod\banyan_fabric\PAYLOAD=s32'00000000000000000000000000001000
# so the banner never contains the bare name as a whole word. **The check was
# CORRECT about its own string and WRONG about the design**, which is the failure
# that reads as a finding. Caught only because I drove the POSITIVE arm on a module
# I already knew was there — a negative arm alone would have called this a success.
# ⇒ Normalise: strip a `$paramod` wrapper down to the base module name. Also drop
#   the `=== design hierarchy ===` banner, which is a section header, not a module.
ROSTER="$(awk '/^=== /{
             n=$2
             sub(/^\$paramod\\/, "", n)      # $paramod\base\PARAM=... -> base\PARAM=...
             sub(/\\.*$/, "", n)             # base\PARAM=...          -> base
             gsub(/\\/, "", n)
             if (n != "design") print n
           }' "$LOG" | sort -u)"
NROS="$(printf '%s\n' "$ROSTER" | grep -c . || true)"
if [ "${NROS:-0}" -lt 1 ]; then
  echo "compose_check: ⛔ stat printed NO module banners — the parser sees nothing."
  echo "compose_check:    Refusing rather than reporting an empty roster as a pass."
  exit 1
fi

echo "compose_check: top=$TOP  elaborated modules=$NROS"
FAIL=0
for want in "$@"; do
  if printf '%s\n' "$ROSTER" | grep -qx "$want"; then
    echo "  ✅ PRESENT  $want"
  else
    echo "  ⛔ ABSENT   $want"
    FAIL=1
  fi
done

if [ "$FAIL" -ne 0 ]; then
  echo "compose_check: ⛔ CONTAINMENT FAILED — do NOT quote an area for this top."
  exit 1
fi
echo "compose_check: ✅ CONTAINMENT HELD. The area in ${TOP}_stat.txt describes a"
echo "compose_check:    design that really contains the modules named above."
exit 0

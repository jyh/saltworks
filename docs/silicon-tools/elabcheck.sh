#!/bin/bash
# elabcheck.sh — DOES THE TOP ELABORATE IN THE TOOL CI ACTUALLY USES?
#
#   elabcheck.sh <top> [<top> ...]      exit 0 = all elaborate · 1 = one did not
#
# ⛔⛔ WHY THIS EXISTS, AND IT COST A NEAR-MISS ON THE SHIPPING TOP. On 2026-08-18 the
# generator emitted `wire retire_o;` AFTER the instantiation that used it.
#   yosys      accepted it. synth.sh was GREEN. The area figures were all correct.
#   iverilog   "Net retire_o is not defined in this context ... declaration after use"
# TT's RTL test AND its gate-level test BOTH run iverilog through cocotb, so the top
# would have FAILED CI while every check I owned said fine.
# ⇒ ***A SYNTHESIS PASS IS NOT AN ELABORATION PASS. The tool CI uses is the STRICTER
#   one, and a green from the permissive tool is not evidence about the strict one.***
# It was found by accident — by writing a testbench I had been holding — and "found by
# accident" is not a control. This is the control.
#
# ⚠️ WHAT IT DOES NOT DO: it does not RUN anything. Elaboration checks structure —
# module names, port names, declaration order, width rules. A design can elaborate and
# behave wrongly; that is what the benches are for.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../../SaltWorks/Silicon/RTL"
[ "$#" -gt 0 ] || { echo "usage: elabcheck.sh <top> [...]"; exit 2; }
PDK_VER="${PDK_VER:-c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
PDK="${PDK_ROOT:-$HOME/.volare/volare/sky130/versions/$PDK_VER}/sky130A/libs.ref/sky130_fd_sc_hd/verilog"
# ⛔ THE PDK BEHAVIOURAL MODELS ARE NOT OPTIONAL. The kernel-emitted cells instantiate
# sky130 gates directly, so without these every run fails on "Unknown module type" and
# a REAL defect would be indistinguishable from a missing-library error. My first
# attempt at this check had exactly that confound and I nearly scored it as a pass.
for f in "$PDK/primitives.v" "$PDK/sky130_fd_sc_hd.v"; do
  [ -r "$f" ] || { echo "elabcheck: PDK model missing: $f — REFUSING (a library error and a design error must not look the same)"; exit 2; }
done

RC=0
for TOP in "$@"; do
  [ -r "$RTL/$TOP.v" ] || { echo "  ⛔ $TOP: no $TOP.v in RTL/"; RC=1; continue; }
  # closure by synth.sh's anchored rule — comments must not count as instantiations
  SRCS="$TOP.v"; changed=1
  while [ "$changed" = 1 ]; do
    changed=0
    for f in "$RTL"/*.v; do
      b="$(basename "$f")"; m="${b%.v}"
      case " $SRCS " in *" $b "*) continue ;; esac
      for s in $SRCS; do
        if grep -qE "^[[:space:]]*$m[[:space:]]+(#\(.*\)[[:space:]]*)?[A-Za-z_]" "$RTL/$s" 2>/dev/null; then
          SRCS="$SRCS $b"; changed=1; break
        fi
      done
    done
  done
  READ=""; for s in $SRCS; do READ="$READ $RTL/$s"; done
  LOG="$(mktemp)"
  # exit captured directly — NEVER through a pipe. `head` returns SIGPIPE 141 and I
  # read that as success once already today.
  iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY='#1' -s "$TOP" -o /dev/null \
      "$PDK/primitives.v" "$PDK/sky130_fd_sc_hd.v" $READ > "$LOG" 2>&1
  E=$?
  if [ "$E" -eq 0 ]; then
    echo "  ✅ $TOP elaborates ($(printf '%s\n' $SRCS | grep -c .) files)"
  else
    echo "  ⛔ $TOP DOES NOT ELABORATE (iverilog exit $E) — IT WOULD FAIL TT's CI:"
    grep -m3 'error:' "$LOG" | sed 's/^/       /'
    RC=1
  fi
  rm -f "$LOG"
done
[ "$RC" -eq 0 ] && echo "elabcheck: ✅ every top named elaborates in the tool CI uses." \
               || echo "elabcheck: ⛔ AT LEAST ONE TOP WOULD FAIL CI. A synthesis pass is not an elaboration pass."
exit $RC

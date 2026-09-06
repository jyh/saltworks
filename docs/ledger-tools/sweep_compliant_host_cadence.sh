#!/bin/sh
# sweep_compliant_host_cadence.sh — IS A COMPLIANT HOST SAFE AT *EVERY* CADENCE, OR ONLY AT MINE?
#
# `run_sof_protocol_rule.sh`'s ARM C wants a launch every 40 cycles and defers until the rule
# permits it. It takes 0 violations. That is a SATISFIABILITY WITNESS: the rule CAN be obeyed.
#
# ⛔ IT IS NOT A COVERAGE CLAIM, AND THE TWO PRINT THE SAME THING (`violations=0`).
#   (b)'s whole tolerability is the sentence "a host that obeys this rule is safe on the die we
#   shipped". The evidence for it was ONE arrival phase. silicon has been bitten twice this day
#   by a window it chose — a six-arm census that was a set not a prefix, then a 40..160 sweep
#   widened to 1..260 — BOTH on the violating side. This is the mirror-image hole, on the
#   COMPLIANT side, which is the side the fallback actually ships on.
#
# ── TWO FAILURE MODES, AND THE SECOND IS THE ONE NOBODY LOOKS FOR ───────────────────────────
#   (1) violations > 0 at some offset — a rule-following host that still violates. The rule
#       would be WRONG, and (b) would have no mitigation.
#   (2) sof_pulses == 0 at some offset — the host DEFERRED FOREVER. That prints `violations=0`
#       and reads as a clean pass, but it means the rule FORBIDS ALL WORK at that cadence.
#       ⇒ A RULE OBEYED BY DOING NOTHING IS NOT A MITIGATION, IT IS A DEADLOCK WITH GOOD
#         MANNERS. This is silicon's third gate ("a rule must be shown to PERMIT work") applied
#         per-cadence instead of once, and (2) is invisible to a check that only counts
#         violations.
#
# PRE-REGISTERED PREDICTION, published to the bus 2026-09-06 11:34:57Z BEFORE this was run:
#   0 violations at EVERY offset, because the host consults `permitted` and defers, and a
#   deferral is not phase-sensitive. A wrong prediction here is a bigger finding than a right one.
#
# USAGE:  sweep_compliant_host_cadence.sh [<git-ref>]     default: the shipped commit 4226396
#   The DUT is the SHUTTLE's RTL read from a COMMITTED ref (silicon is live in that tree, so a
#   working-tree read would not be a stable subject). The bench and checker are saltworks'.
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ARM="$ROOT/SaltWorks/Silicon/Sim/reghost/run_sof_protocol_rule.sh"
REGHOST="$ROOT/SaltWorks/Silicon/Sim/reghost"
SRCDIR="$ROOT/SaltWorks/Silicon/Sim/wordonly"
SHUTTLE="${SHUTTLE_REPO:-/Users/jyh/projects/claude/seats/silicon/tt-neural-dataflow-fabric}"
REF="${1:-4226396}"
PERIOD=40
# ⛔⛔ THE NEGATIVE CONTROL, AND IT IS NOT OPTIONAL DECORATION. A sweep that reports 40/40 CLEAN
#   is worthless until it is shown capable of reporting anything else — otherwise the table is a
#   fact about the instrument, not about the chip, and it fails in the reassuring direction.
#   With SWEEP_NEGATIVE_CONTROL=1 the host ALSO stops consulting `permitted`, i.e. it is no
#   longer compliant. The sweep must then FIND violations, and the script INVERTS its verdict:
#   a clean table becomes the failure. Run both arms; a green positive arm alone proves nothing.
CONTROL="${SWEEP_NEGATIVE_CONTROL:-0}"

[ -f "$ARM" ] || { echo "⛔ ABORT: arm not found"; exit 2; }
[ -d "$SHUTTLE/.git" ] || { echo "⛔ ABORT: shuttle repo not found at $SHUTTLE"; exit 2; }
git -C "$SHUTTLE" cat-file -e "$REF:src/busadapt8.v" 2>/dev/null \
  || { echo "⛔ ABORT: $REF:src/busadapt8.v unreachable — the DUT would be a guess"; exit 2; }
command -v iverilog >/dev/null || { echo "⛔ ABORT: iverilog absent — nothing ran."; exit 2; }

T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT

# The mirror reflects DIRECTORIES, not a named set — same law as the prover beside it.
mkdir -p "$T/Sim" "$T/RTL"
cp -R "$REGHOST" "$T/Sim/reghost"
cp -R "$SRCDIR"  "$T/Sim/wordonly"
for v in plane32bus.v busadapt8.v core32.v; do
  git -C "$SHUTTLE" show "$REF:src/$v" > "$T/RTL/$v" \
    || { echo "⛔ ABORT: could not extract $v at $REF"; exit 2; }
done
DUT_SHA=$( (sha256sum "$T/RTL/busadapt8.v" 2>/dev/null || shasum -a 256 "$T/RTL/busadapt8.v") | cut -c1-16 )
echo "DUT      shuttle $REF : src/busadapt8.v  sha256/16=$DUT_SHA   (bench + checker are saltworks')"
echo "SWEEP    the compliant host's launch offset, cyc % $PERIOD == OFF, for OFF in 0..$((PERIOD-1))"
echo

printf '%-5s %-12s %-12s %s\n' "OFF" "violations" "sof_pulses" "READING"
printf '%s\n' "--------------------------------------------------------------"
viol_bad=0; vacuous=0; rows=0
for OFF in $(seq 0 $((PERIOD-1))); do
  python3 - "$ARM" "$T/Sim/reghost/arm.sh" "$OFF" "$CONTROL" <<'PY' || { echo "⛔ ABORT: mutation failed"; exit 2; }
import io,sys
src,dst,off,control = sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
s = io.open(src,encoding='utf-8').read()
# ⛔ NO FORMAT STRINGS HERE. The first version wrote "%%" and called .replace("%%","%")
# BEFORE the % operator ran, so Python formatted a string that already contained a bare "% 40"
# and died with `unsupported format character`. Plain concatenation cannot have that bug.
A = "if (cyc " + "%" + " 40 == 0) want = 1;"
if s.count(A) != 1:
    sys.stderr.write("ABORT: cadence anchor found " + str(s.count(A)) + " times, expected 1 -- "
                     "the arm moved under this sweep and every row would be one cell copied.\n")
    sys.exit(2)
s = s.replace(A, "if (cyc " + "%" + " 40 == " + off + ") want = 1;", 1)
# only the compliant arm: ARM V is silicon's subject, not this sweep's
B = "for M in 0 1; do"
if s.count(B) != 1:
    sys.stderr.write("ABORT: mode-loop anchor missing.\n"); sys.exit(2)
s = s.replace(B, "for M in 0; do", 1)
if control == "1":
    # make the host NON-compliant: it stops consulting the rule before launching
    C = "if (want == 1 && permitted && (dut.u_bus.phase == 2'd0 || dut.u_bus.phase == 2'd1))"
    if s.count(C) != 1:
        sys.stderr.write("ABORT: control anchor missing -- the negative control would be INERT, "
                         "which is exactly the failure it exists to rule out.\n")
        sys.exit(2)
    s = s.replace(C, "if (want == 1)", 1)
io.open(dst,'w',encoding='utf-8').write(s)
PY
  chmod +x "$T/Sim/reghost/arm.sh"
  out=$(sh "$T/Sim/reghost/arm.sh" 2>&1 || true)
  line=$(echo "$out" | command grep 'ARM C' || true)
  v=$(echo "$line" | sed -n 's/.*violations=\([0-9]*\).*/\1/p')
  ps=$(echo "$line" | sed -n 's/.*sof_pulses=\([0-9]*\).*/\1/p')
  if [ -z "${v:-}" ] || [ -z "${ps:-}" ]; then
    printf '%-5s %-12s %-12s %s\n' "$OFF" "?" "?" "⛔ NO READING — the run produced no ARM C line"
    viol_bad=$((viol_bad+1)); rows=$((rows+1)); continue
  fi
  rows=$((rows+1))
  if [ "$v" -gt 0 ]; then
    # ⛔ THE LABEL MUST KNOW WHICH HOST IT IS DESCRIBING. In control mode the host is
    #   deliberately NOT rule-following, and calling it one would be the same defect that cost
    #   the lead an alarm at 11:09 — a row label asserting a property of the subject that the
    #   run never established. Caught here before publication rather than after.
    if [ "$CONTROL" = "1" ]; then r="✅ caught (host is non-compliant BY CONSTRUCTION here)"
    else r="⛔ A RULE-FOLLOWING HOST VIOLATED"; fi
    viol_bad=$((viol_bad+1))
  elif [ "$ps" -eq 0 ]; then
    r="⛔ VACUOUS — deferred forever, the rule permits NO work here"; vacuous=$((vacuous+1))
  else
    r="✅ clean and non-vacuous"
  fi
  printf '%-5s %-12s %-12s %s\n' "$OFF" "$v" "$ps" "$r"
done

echo
echo "rows=$rows  offsets-with-violations=$viol_bad  offsets-that-did-no-work=$vacuous"
if [ "$CONTROL" = "1" ]; then
  # INVERTED: the host here is NOT compliant, so a clean sweep means the sweep cannot see.
  if [ "$viol_bad" -gt 0 ]; then
    echo "NEGATIVE_CONTROL=PASS — a non-compliant host was CAUGHT at $viol_bad of $rows offsets."
    echo "  The sweep can report a violation, so a clean positive arm means something."
    exit 0
  fi
  echo "⛔⛔ NEGATIVE_CONTROL=FAILED — a host that ignores the rule swept CLEAN at every offset."
  echo "  The sweep cannot detect a violation and its positive result must NOT be quoted."
  exit 1
fi
if [ "$viol_bad" -eq 0 ] && [ "$vacuous" -eq 0 ]; then
  echo "COMPLIANT_HOST_SWEEP=CLEAN — at every one of $rows launch offsets the rule was obeyed"
  echo "  with zero violations AND the host still did work. The satisfiability claim is no"
  echo "  longer resting on a single cadence."
  echo "  ⛔ STILL NOT COVERAGE OVER HOSTS: this sweeps ONE host's PHASE, not the space of hosts."
  exit 0
fi
echo "COMPLIANT_HOST_SWEEP=FINDING — see the flagged rows above. Print the list, not the total."
exit 1

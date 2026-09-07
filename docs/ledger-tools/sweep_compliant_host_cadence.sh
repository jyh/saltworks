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
# USAGE:  sweep_compliant_host_cadence.sh [<git-ref>]   default: THE VENDORED FABRICATED FIXTURE
#   The DUT is the SHUTTLE's RTL read from a COMMITTED ref (silicon is live in that tree, so a
#   working-tree read would not be a stable subject). The bench and checker are saltworks'.
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ARM="$ROOT/SaltWorks/Silicon/Sim/reghost/run_sof_protocol_rule.sh"
REGHOST="$ROOT/SaltWorks/Silicon/Sim/reghost"
SRCDIR="$ROOT/SaltWorks/Silicon/Sim/wordonly"
SHUTTLE="${SHUTTLE_REPO:-/Users/jyh/projects/claude/seats/silicon/tt-neural-dataflow-fabric}"
# ⛔⛔ THE DEFAULT WAS `4226396` AND THAT STOPPED BEING THE CHIP ON 2026-09-07 17:07Z.
#   `busadapt8.v` DIFFERS between 4226396 and 01e19f7 — the diff IS shape (B), `fetch_owed`,
#   i.e. exactly the organ this sweep exercises. Two landed sweeps in this repo say "the SHIPPED
#   DUT 4226396"; that was TRUE when written and went false at the click, with nothing firing.
#   ⇒ 🔑 A DUT LABEL IS A DATED CLAIM. "The shipped DUT" named one commit yesterday and another
#     today, and a default carries the stale one forward silently into every future run.
#   The default is now the VENDORED FABRICATED FIXTURE — a pin that cannot go stale, because the
#   design behind it has been manufactured. Pass a ref explicitly to read the shuttle clone.
FIXTURE="${SWEEP_FIXTURE:-$ROOT/SaltWorks/Silicon/Fabricated/01e19f7}"
REF="${1:-}"
PERIOD=40
# ⛔⛔ THE NEGATIVE CONTROL, AND IT IS NOT OPTIONAL DECORATION. A sweep that reports 40/40 CLEAN
#   is worthless until it is shown capable of reporting anything else — otherwise the table is a
#   fact about the instrument, not about the chip, and it fails in the reassuring direction.
#   With SWEEP_NEGATIVE_CONTROL=1 the host ALSO stops consulting `permitted`, i.e. it is no
#   longer compliant. The sweep must then FIND violations, and the script INVERTS its verdict:
#   a clean table becomes the failure. Run both arms; a green positive arm alone proves nothing.
CONTROL="${SWEEP_NEGATIVE_CONTROL:-0}"
# ⭐ SHAPE MODE (SWEEP_SHAPES=1). The offset sweep answers "is this host safe at every PHASE".
#   It does NOT answer "is every compliant host safe", because it varies one host's timing and
#   never its SHAPE. (b) ships on the second sentence, so the second sentence needs driving.
#   Shapes shipped, all of them still CONSULTING the rule — that is what makes them compliant:
#     base   want a launch every 40 cycles, hold the request until granted   (the original)
#     eager  want a launch EVERY CYCLE — maximal demand against the rule
#     burst  queue THREE launches at once and drain them
#     coprime  want one every 7 cycles — 7 is COPRIME WITH 40, so one run visits every phase
#              of the grant window instead of sitting at one offset
#     impatient  ⭐⭐ THE MEMBER THAT IS NOT AN INSTANTIATION OF THE OTHERS. base/eager/burst
#              all HOLD the request until granted, which means NONE OF THEM CAN EVER BE
#              STARVED — they simply wait, and a wait is invisible in a violation count. This
#              host has a TIMEOUT: it asks, and WITHDRAWS the request if it is not granted
#              within 4 cycles. That is a perfectly compliant host (it still consults
#              `permitted`), and it is the ONLY shape here that can exhibit the failure this
#              header calls the interesting one — pulses collapsing toward zero while
#              violations stay at 0, i.e. DEADLOCK WITH GOOD MANNERS, which reads as CLEAN.
#              ⛔ A sample of three that shares one mechanism is a sample of ONE mechanism.
#   ⛔ The interesting failure is NOT violations (they all defer). It is a shape that gets
#     STARVED: high demand + a rule that keeps saying no = pulses collapsing toward zero, which
#     is the deadlock-with-good-manners failure showing up as a SHAPE property rather than a
#     phase one.
SHAPES="${SWEEP_SHAPES:-0}"

[ -f "$ARM" ] || { echo "⛔ ABORT: arm not found"; exit 2; }
if [ -z "$REF" ]; then
  # FIXTURE MODE — no shuttle checkout, so this arm is SCHEDULABLE (that is the whole point).
  [ -d "$FIXTURE/src" ] || { echo "⛔ ABORT: fixture not found at $FIXTURE"; exit 2; }
  [ -f "$FIXTURE/PIN.psv" ] || { echo "⛔ ABORT: fixture has no PIN.psv — the DUT would be unpinned"; exit 2; }
else
  [ -d "$SHUTTLE/.git" ] || { echo "⛔ ABORT: shuttle repo not found at $SHUTTLE"; exit 2; }
  git -C "$SHUTTLE" cat-file -e "$REF:src/busadapt8.v" 2>/dev/null \
    || { echo "⛔ ABORT: $REF:src/busadapt8.v unreachable — the DUT would be a guess"; exit 2; }
fi
command -v iverilog >/dev/null || { echo "⛔ ABORT: iverilog absent — nothing ran."; exit 2; }

T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT

# The mirror reflects DIRECTORIES, not a named set — same law as the prover beside it.
mkdir -p "$T/Sim" "$T/RTL"
cp -R "$REGHOST" "$T/Sim/reghost"
cp -R "$SRCDIR"  "$T/Sim/wordonly"
if [ -z "$REF" ]; then
  for v in plane32bus.v busadapt8.v core32.v; do
    cp "$FIXTURE/src/$v" "$T/RTL/$v" || { echo "⛔ ABORT: fixture missing $v"; exit 2; }
  done
  # ⛔ CUSTODY BEFORE USE: a corrupted fixture must not silently become the DUT. This is the
  #   fixture's OWN pin (cheap, offline). CONFORMANCE against the external ref is a separate,
  #   network-bearing arm: docs/ledger-tools/check_fabricated_fixture.sh.
  while IFS='|' read -r f _bytes blob _csha; do
    case "$f" in ''|'#'*|file) continue ;; esac
    [ "$(git hash-object "$T/RTL/$f")" = "$blob" ] \
      || { echo "⛔ ABORT: fixture file $f fails its own pin — the DUT would be a guess"; exit 2; }
  done < "$FIXTURE/PIN.psv"
  PINREF=$(sed -n 's/^# ref|//p' "$FIXTURE/PIN.psv" | head -1)
  DUT_SRC="FABRICATED fixture ${PINREF:0:7} (custody verified)"
else
  for v in plane32bus.v busadapt8.v core32.v; do
    git -C "$SHUTTLE" show "$REF:src/$v" > "$T/RTL/$v" \
      || { echo "⛔ ABORT: could not extract $v at $REF"; exit 2; }
  done
  DUT_SRC="shuttle clone $REF"
fi
DUT_SHA=$( (sha256sum "$T/RTL/busadapt8.v" 2>/dev/null || shasum -a 256 "$T/RTL/busadapt8.v") | cut -c1-16 )
echo "DUT      $DUT_SRC : src/busadapt8.v  sha256/16=$DUT_SHA   (bench + checker are saltworks')"
echo "DATED    read $(date -u '+%Y-%m-%dT%H:%MZ') — a DUT label is a dated claim, so this line carries its date"
if [ "${SWEEP_SHAPES:-0}" = "1" ]; then
  echo "SWEEP    the compliant host's SHAPE (demand pattern), at a fixed cadence"
else
  echo "SWEEP    the compliant host's launch offset, cyc % $PERIOD == OFF, for OFF in 0..$((PERIOD-1))"
fi
echo

if [ "$SHAPES" = "1" ]; then
  printf '%-8s %-12s %-12s %s\n' "SHAPE" "violations" "sof_pulses" "READING"
  ITEMS="base eager burst coprime impatient"
else
  printf '%-8s %-12s %-12s %s\n' "OFF" "violations" "sof_pulses" "READING"
  ITEMS=$(seq 0 $((PERIOD-1)))
fi
printf '%s\n' "--------------------------------------------------------------"
viol_bad=0; vacuous=0; rows=0
for OFF in $ITEMS; do
  python3 - "$ARM" "$T/Sim/reghost/arm.sh" "$OFF" "$CONTROL" "$SHAPES" <<'PY' || { echo "⛔ ABORT: mutation failed"; exit 2; }
import io,sys
src,dst,off,control,shapes = sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5]
s = io.open(src,encoding='utf-8').read()
# ⛔ NO FORMAT STRINGS HERE. The first version wrote "%%" and called .replace("%%","%")
# BEFORE the % operator ran, so Python formatted a string that already contained a bare "% 40"
# and died with `unsupported format character`. Plain concatenation cannot have that bug.
A = "if (cyc " + "%" + " 40 == 0) want = 1;"
GRANT = "if (want == 1 && permitted && (dut.u_bus.phase == 2'd0 || dut.u_bus.phase == 2'd1))"
DRAIN = "begin sof <= 1'b1; want = 0; sof_pulses = sof_pulses + 1; end"
if shapes == "1":
    # every shape still consults `permitted`; only the DEMAND changes
    if s.count(A) != 1 or s.count(GRANT) != 1 or s.count(DRAIN) != 1:
        sys.stderr.write("ABORT: shape anchors moved -- every shape row would be one cell.\n")
        sys.exit(2)
    if off == "eager":
        s = s.replace(A, "want = 1;", 1)
    elif off == "coprime":
        s = s.replace(A, "if (cyc " + "%" + " 7 == 0) want = 1;", 1)
    elif off == "impatient":
        # A host with a TIMEOUT: ask, and give up if not granted within 4 cycles. Needs one
        # extra integer, so this shape mutates TWO anchors and both are asserted -- a shape
        # whose declaration silently failed to land would compile as a different host.
        DECL = "integer sof_pulses = 0, cyc = 0, want = 0, n_lw = 0, n_sw = 0;"
        if s.count(DECL) != 1:
            sys.stderr.write("ABORT: impatient shape needs the declaration anchor and it moved.\n")
            sys.exit(2)
        s = s.replace(DECL, DECL[:-1] + ", deadline = 0;", 1)
        s = s.replace(A, "if (cyc " + "%" + " 40 == 0) begin want = 1; deadline = cyc + 4; end "
                         "else if (want == 1 && cyc > deadline) want = 0;", 1)
    elif off == "burst":
        s = s.replace(A, "if (cyc " + "%" + " 40 == 0) want = 3;", 1)
        s = s.replace(GRANT, GRANT.replace("want == 1", "want > 0"), 1)
        s = s.replace(DRAIN, DRAIN.replace("want = 0", "want = want - 1"), 1)
    elif off not in ("base",):
        sys.stderr.write("ABORT: unknown shape " + off + "\n"); sys.exit(2)
    B0 = "for M in 0 1; do"
    if s.count(B0) != 1:
        sys.stderr.write("ABORT: mode-loop anchor missing.\n"); sys.exit(2)
    s = s.replace(B0, "for M in 0; do", 1)
    # ⛔ THE CONTROL MUST COMPOSE WITH THE SHAPE, and the first version of this branch
    #   `exit(0)`d before ever reading `control` -- so SWEEP_NEGATIVE_CONTROL was SILENTLY
    #   IGNORED and the shape table had no negative control at all. A clean table with no
    #   control is a fact about the instrument. Caught before publishing, not after.
    if control == "1":
        G2 = GRANT.replace("want == 1", "want > 0") if off == "burst" else GRANT
        if s.count(G2) != 1:
            sys.stderr.write("ABORT: control anchor missing under shape " + off + " -- the "
                             "negative control would be INERT.\n")
            sys.exit(2)
        s = s.replace(G2, G2.split(" && permitted")[0] + ")", 1)
    io.open(dst,'w',encoding='utf-8').write(s)
    sys.exit(0)
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
  PULSE_LOG="${PULSE_LOG:-}${PULSE_LOG:+
}$OFF $ps"
done

echo
echo "rows=$rows  offsets-with-violations=$viol_bad  offsets-that-did-no-work=$vacuous"
if [ "$CONTROL" = "1" ]; then
  # INVERTED: the host here is NOT compliant, so a clean row means the control could not see.
  # ⛔⛔ EVERY row must be caught, not merely SOME. The first version passed as long as ANY row
  #   was caught, which quietly certified rows whose control was VOID. Measured on the shipped
  #   DUT: the `eager` shape stays at 0 violations even with `permitted` cut out, because a host
  #   asserting `sof` constantly REALIGNS THE MACHINE INTO FETCH — the state the rule demands is
  #   the state its own aggression creates, so the mutant is SELF-DEFEATING. That is a VOID
  #   CONTROL, and the positive result for that shape is therefore UNCONTROLLED. It must be
  #   named, not averaged away. ⇒ A CONTROL THAT PASSES ON SOME MEMBERS CERTIFIES ONLY THOSE.
  if [ "$viol_bad" -eq "$rows" ]; then
    echo "NEGATIVE_CONTROL=PASS — every one of $rows rows was CAUGHT. All are controlled."
    exit 0
  fi
  if [ "$viol_bad" -gt 0 ]; then
    echo "⛔ NEGATIVE_CONTROL=PARTIAL — caught at $viol_bad of $rows; the REST HAVE NO WORKING"
    echo "  CONTROL and their positive results are UNCONTROLLED. Name them; do not average."
    echo "  A row that stays clean under the cut is a VOID control, not a passing one."
    exit 1
  fi
  echo "⛔⛔ NEGATIVE_CONTROL=FAILED — a host that ignores the rule swept CLEAN at every offset."
  echo "  The sweep cannot detect a violation and its positive result must NOT be quoted."
  exit 1
fi
if [ "$viol_bad" -eq 0 ] && [ "$vacuous" -eq 0 ]; then
  if [ "$SHAPES" = "1" ]; then
    echo "COMPLIANT_HOST_SHAPES=CLEAN — all $rows host shapes obeyed the rule with zero"
    echo "  violations AND every shape did SOME work. ⛔ Still not the space of hosts: $rows"
    echo "  shapes is a SAMPLE, and I chose it. A wider sample than one, and that is all."
    # ⛔⛔ THE WORD "STARVED" USED TO APPEAR HERE AND IT WAS A CLAIM THIS SWEEP CANNOT MAKE.
    #   The only vacuity test is sof_pulses > 0 -- A FLOOR AT ZERO. Starvation is a RATIO, and
    #   a host can lose most of its launches while the floor stays happy. MEASURED 2026-09-07
    #   on the fabricated DUT: `impatient` (a compliant host with a 4-cycle timeout) landed 4
    #   pulses where `base`, wanting launches at the same rate, landed 14 -- ~10 of 14 requests
    #   DROPPED -- and this verdict said "none was starved".
    #   ⇒ 🔑 A FLOOR AT ZERO CANNOT SEE A RATIO, AND THE REASSURING WORD SAT IN THE VERDICT
    #     LINE WHERE NOTHING COMPUTED IT. The line now claims only what it tested: SOME work.
    #   ⭐⭐ AND THE DENOMINATOR ALREADY EXISTS — IT IS THE NEGATIVE CONTROL. I wrote that a
    #     real starvation arm "needs the intended count instrumented", then found the control
    #     arm supplies it: with `permitted` cut, the host launches whenever it likes, so its
    #     pulse count IS its unconstrained demand. MEASURED on `impatient`: 4 granted WITH the
    #     rule, 15 WITHOUT it -- 11 of 15 launches lost to deferral, and the loss is caused by
    #     THE RULE and not by the testbench, which is exactly what the pair proves and neither
    #     arm proves alone. ⇒ 🔑 AN INSTRUMENT I CALLED OWED WAS ALREADY BUILT, IN THE ARM I
    #     RUN BESIDE IT: before building a denominator, check whether a control already is one.
    #   ⛔ Still NOT wired as a verdict: pairing the arms means running both and dividing, and a
    #     PASS/FAIL bar on that ratio would be a knob. The honest datum is the PAIR, printed.
    lo=$(printf '%s\n' "$PULSE_LOG" | sort -k2 -n | head -1)
    [ -n "$lo" ] && echo "  📉 LOWEST-YIELD SHAPE: $lo — printed because the floor test cannot rank."
    exit 0
  fi
  echo "COMPLIANT_HOST_SWEEP=CLEAN — at every one of $rows launch offsets the rule was obeyed"
  echo "  with zero violations AND the host still did work. The satisfiability claim is no"
  echo "  longer resting on a single cadence."
  echo "  ⛔ STILL NOT COVERAGE OVER HOSTS: this sweeps ONE host's PHASE, not the space of hosts."
  exit 0
fi
echo "COMPLIANT_HOST_SWEEP=FINDING — see the flagged rows above. Print the list, not the total."
exit 1

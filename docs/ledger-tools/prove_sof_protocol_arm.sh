#!/bin/sh
# prove_sof_protocol_arm.sh — CAN THE `sof` PROTOCOL ARM STILL GO RED?
#
# `SaltWorks/Silicon/Sim/reghost/run_sof_protocol_rule.sh` is the arm. This file is its
# MUTATION CONTROL, and it exists because of a sentence from the saltworks lead (09/06 11:0x):
#
#   "AN ARM THAT CAN GO RED BUT IS NEVER ASKED IS INDISTINGUISHABLE FROM AN ARM THAT PASSES,
#    and it reports the reassuring direction."
#
# Wiring the arm into CI answers "is it asked". It does NOT answer "can it still fail" — a
# scheduled arm that has quietly lost its teeth reports green forever, and green is exactly
# what a broken arm looks like. So the schedule carries this prover beside the arm.
#
# ⛔ WHY A MUTATION CONTROL AND NOT A SELFTEST. Measured on this seat 2026-09-06 04:5x: a
#   6/6 GREEN selftest over a fixture that put its comment at COLUMN 0, where every real
#   comment is INDENTED. The fixture could not feel the defect, so the selftest agreed with
#   the bug. ⇒ A NEGATIVE CONTROL IS ONLY WORTH ITS FIXTURE'S FIDELITY.
#
# ⛔ ONE MUTANT PER GATE, BECAUSE THE ARM HAS THREE AND THEY FAIL INDEPENDENTLY. A prover
#   that only drives gate 2 proves gate 2; the other two would be free to rot.
#     M1 → GATE 2 (satisfiable): a host that does not consult the rule must be caught.
#     M3 → GATE 3 (permits work): a host that never asserts must be caught as VACUOUS.
#     M4 → GATE 1 (binding):     a checker that cannot count must be caught as toothless.
#
# ⛔⛔ A MUTANT I BUILT AND THEN WITHDREW, RECORDED BECAUSE THE WITHDRAWAL IS THE FINDING.
#   "M2": the host decides at phase 3 instead of phase 0/1 — the hazard the arm's own comment
#   (:52-55) warns about. It was NOT caught, and my first table called that a MISS. IT IS NOT.
#   The rule (`sof_protocol_check.v`) is `sof && !(kind==T_FETCH && req==0)` — keyed on the
#   RESIDENT STATE, never on the cycle — and that file's header says phase 3 is genuinely safe.
#   A phase-3 decision violates nothing unless `permitted` EVAPORATES before the drive cycle,
#   and across 14 pulses on this bench it never did. ⇒ **M2's DISCRIMINATING SET IS EMPTY HERE:
#   it is a VOID CONTROL, not a blind arm.** Shipping it as a failing row would have accused a
#   correct checker of a defect it does not have. Reported to the lead as a statement about the
#   BENCH's coverage — the bench cannot exercise its own documented evaporation case.
#
# ⛔ OWNERSHIP. `SaltWorks/Silicon/**` is the SILICON seat's slot (docs/SEATS.md) and silicon is
#   live in it. This prover therefore NEVER writes into that tree: per arm it builds a temp
#   mirror of the directory layout out of real dirs + symlinks, and mutates only its own COPY.
#   The arm under test is the SHIPPING file, byte-for-byte, reached through the mirror.
#
# EXIT 0 = the arm is red-capable on all three gates. EXIT 1 = a mutant went undetected, or the
# pristine arm failed. EXIT 2 = the prover could not build its own fixture (ABORT, not a verdict).
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ARM="$ROOT/SaltWorks/Silicon/Sim/reghost/run_sof_protocol_rule.sh"
CHK="$ROOT/SaltWorks/Silicon/Sim/reghost/sof_protocol_check.v"
SRC="$ROOT/SaltWorks/Silicon/Sim/wordonly/tb_plane32bus_lwsw.v"
RTLD="$ROOT/SaltWorks/Silicon/RTL"

for f in "$ARM" "$CHK" "$SRC"; do
  [ -f "$f" ] || { echo "⛔ ABORT: missing $f"; exit 2; }
done
for v in plane32bus.v busadapt8.v core32.v; do
  [ -f "$RTLD/$v" ] || { echo "⛔ ABORT: missing RTL $v"; exit 2; }
done
command -v iverilog >/dev/null || { echo "⛔ ABORT: iverilog absent — the prover did not run."; exit 2; }
command -v python3  >/dev/null || { echo "⛔ ABORT: python3 absent — the prover did not run."; exit 2; }

T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT

# ── PREFLIGHT — ⛔⛔ THIS RUNS BEFORE ANY ROW IS PRINTED, AND THAT ORDERING IS THE WHOLE POINT.
# 2026-09-06 11:09, measured in production: a branch mutated the arm ITSELF, so the row labelled
# "P pristine — nothing, the shipping arm" ran a file that had in fact been cut. It printed
# `GATE 2 FAILED — a rule-following host still violates; the rule is wrong` and only AFTERWARDS
# aborted with "the subject moved under this prover". The saltworks lead read the first line
# correctly and had to ask whether the campaign's central mitigation had just been refuted.
# ⇒ 🔑 A ROW LABEL IS A CLAIM. "pristine" only ever meant "not mutated BY THIS PROVER", and the
#   label silently upgraded it to "not mutated AT ALL" -- true on master, false on that branch.
#   A PROVER THAT CANNOT BUILD ITS FIXTURE MUST SAY NOTHING ABOUT THE SUBJECT, rather than
#   publish a verdict and withdraw it two rows later. The withdrawal never overtakes the verdict.
# So: every anchor is asserted here, and a mismatch ABORTS with NO verdict at all.
preflight_fail=0
for spec in "M1:$ARM" "M3:$ARM" "M4:$CHK"; do
  tag=${spec%%:*}; file=${spec#*:}
  python3 - "$file" "$tag" <<'PY' || preflight_fail=1
import io,sys
f,tag = sys.argv[1],sys.argv[2]
A = {
 "M1": "if (want == 1 && permitted && (dut.u_bus.phase == 2'd0 || dut.u_bus.phase == 2'd1))",
 "M3": "if (cyc % 40 == 0) want = 1;",
 "M4": "violations <= violations + 32'd1;",
}[tag]
n = io.open(f,encoding='utf-8').read().count(A)
if n != 1:
    sys.stderr.write("⛔ PREFLIGHT %s: anchor found %d times in %s, expected exactly 1.\n"
                     % (tag, n, f))
    sys.exit(1)
PY
done
if [ "$preflight_fail" -ne 0 ]; then
  echo "⛔⛔ ABORT — THE SUBJECT IS NOT THE ONE THIS PROVER KNOWS, so it reports NOTHING about it."
  echo "   No verdict row has been printed, deliberately: an anchor that has moved makes every"
  echo "   mutant INERT, and an inert mutant is indistinguishable from a caught one."
  echo "   Either the arm was edited (re-point the anchors here, in the same change), or the"
  echo "   tree under test is not the tree this prover was written against."
  exit 2
fi

# The subject, IDENTIFIED rather than asserted — so a reader can tell WHICH bytes were judged
# instead of trusting a row that says "the shipping arm".
ARM_SHA=$( (sha256sum "$ARM" 2>/dev/null || shasum -a 256 "$ARM") | cut -c1-16 )
CHK_SHA=$( (sha256sum "$CHK" 2>/dev/null || shasum -a 256 "$CHK") | cut -c1-16 )
echo "SUBJECT  arm=$ARM_SHA  checker=$CHK_SHA  (anchors verified: M1 M3 M4 each exactly once)"

# ⛔ A MUTATION THAT MATCHED NOTHING IS A FIXTURE THAT NEVER BUILT ITS STATE, and it fails in
#   the direction that looks like success. Every cut asserts its own anchor count and ABORTS.
mutate() { # $1=src $2=dst $3=tag
  python3 - "$1" "$2" "$3" <<'PY'
import io,sys
src,dst,tag = sys.argv[1],sys.argv[2],sys.argv[3]
s = io.open(src,encoding='utf-8').read()
CUTS = {
  # tag: (anchor, replacement)  -- anchor must appear EXACTLY once
  "M1": ("if (want == 1 && permitted && (dut.u_bus.phase == 2'd0 || dut.u_bus.phase == 2'd1))",
         "if (want == 1)"),
  "M3": ("if (cyc % 40 == 0) want = 1;",
         "if (cyc < 0) want = 1;"),
  "M4": ("violations <= violations + 32'd1;",
         "violations <= violations;"),
}
if tag == "pristine":
    out = s
else:
    anchor, new = CUTS[tag]
    n = s.count(anchor)
    if n != 1:
        sys.stderr.write("ABORT: %s anchor found %d times, expected exactly 1 -- the subject "
                         "moved under this prover and the mutant would be INERT.\n" % (tag, n))
        sys.exit(2)
    out = s.replace(anchor, new, 1)
    if out == s:
        sys.stderr.write("ABORT: %s replacement was a no-op.\n" % tag); sys.exit(2)
io.open(dst,'w',encoding='utf-8').write(out)
PY
}

# Per-arm mirror. The arm resolves RTL as $HERE/../../RTL and the bench as $HERE/../wordonly/… ,
# so the mirror must reproduce that shape or the arm silently measures the wrong tree.
build_mirror() { # $1=tag  -> echoes the path of the arm script to run
  d="$T/$1"
  mkdir -p "$d/Sim/reghost" "$d/Sim/wordonly" "$d/RTL"
  ln -s "$SRC" "$d/Sim/wordonly/tb_plane32bus_lwsw.v"
  for v in plane32bus.v busadapt8.v core32.v; do ln -s "$RTLD/$v" "$d/RTL/$v"; done
  case "$1" in
    M4) mutate "$CHK" "$d/Sim/reghost/sof_protocol_check.v" M4 || return 2
        cp "$ARM" "$d/Sim/reghost/arm.sh" ;;
    *)  ln -s "$CHK" "$d/Sim/reghost/sof_protocol_check.v"
        mutate "$ARM" "$d/Sim/reghost/arm.sh" "$1" || return 2 ;;
  esac
  chmod +x "$d/Sim/reghost/arm.sh"
  echo "$d/Sim/reghost/arm.sh"
}

# ⛔ NO `set +e`/`set -e` INSIDE THESE FUNCTIONS. The first version toggled errexit and
#   re-enabled it just before returning, so the shell died on the FIRST failing mutant and the
#   mutant rows were simply ABSENT from the table — a control that fails by absence, which is
#   the failure mode that looks like nothing happened. Call sites use `|| rc=$?` instead.
run_arm() { # $1=tag ; output lands in $T/$1.out, returns the arm's own exit code
  a=$(build_mirror "$1") || { echo "⛔ ABORT: could not build fixture $1"; exit 2; }
  sh "$a" > "$T/$1.out" 2>&1 || return $?
  return 0
}

fail=0
printf '%-12s %-13s %-46s %s\n' "ARM" "GATE DRIVEN" "WHAT IT MUTATES" "OUTCOME"
printf '%s\n' "---------------------------------------------------------------------------------------------"

# ARM P — the shipping arm, unmutated, must PASS. A prover whose positive control fails is
# reporting on a broken tree, not on its own mutants.
rcP=0; run_arm pristine || rcP=$?
vP=$(sed -n 's/^SOF_PROTOCOL_RULE=//p' "$T/pristine.out" | head -1)
if [ "$rcP" -eq 0 ] && [ "${vP#PASS}" != "$vP" ]; then
  printf '%-12s %-13s %-46s %s\n' "P pristine" "(all three)" "nothing — the tree's arm, sha above" "✅ PASS as expected"
else
  printf '%-12s %-13s %-46s %s\n' "P pristine" "(all three)" "nothing — the tree's arm, sha above" "⛔ POSITIVE CONTROL FAILED rc=$rcP"
  sed 's/^/      | /' "$T/pristine.out"
  fail=1
fi

for m in M1 M3 M4; do
  case $m in
    M1) g="GATE 2"; desc="host stops consulting the rule" ;;
    M3) g="GATE 3"; desc="host never asserts sof (vacuous pass)" ;;
    M4) g="GATE 1a"; desc="checker cannot count (toothless)" ;;
  esac
  rc=0; run_arm "$m" || rc=$?
  # ⛔ SUB-GATE LETTER ALLOWED, 2026-09-06 (silicon). GATE 1 was SPLIT BY TENSE into
  # 1a LIVENESS (checker fires on the current RTL) and 1b WELL-FOUNDEDNESS (the same host
  # takes L7 red on the PINNED pre-repair RTL), because shape (B) removed the harm that
  # the old single conjunction used as its witness. This pattern was `[0-9]` and silently
  # matched NOTHING once the label gained a letter — the mutant was still caught, but the
  # prover reported `caught by <none>` and failed for a naming reason.
  # ⇒ A DETECTOR IS A CITER: RENAMING A LABEL BREAKS EVERY TOOL KEYED ON IT, and the
  #   break is silent in the direction that looks like a real failure.
  gate=$(command grep -o '⛔ GATE [0-9][a-z]\? FAILED' "$T/$m.out" | head -1)
  if [ "$rc" -ne 0 ]; then
    printf '%-12s %-13s %-46s %s\n' "$m caught" "$g" "$desc" "✅ RED rc=$rc ${gate:-}"
    # The mutant must be caught BY ITS OWN GATE, not by some other one failing incidentally.
    want="⛔ ${g} FAILED"
    if [ "$gate" != "$want" ]; then
      printf '%-12s %-13s %-46s %s\n' "" "" "" "⚠️ caught by ${gate:-<none>}, expected $want"
      fail=1
    fi
  else
    printf '%-12s %-13s %-46s %s\n' "$m MISSED" "$g" "$desc" "⛔ arm stayed GREEN on a known-bad input"
    sed 's/^/      | /' "$T/$m.out"
    fail=1
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "SOF_ARM_RED_CAPABLE=PROVEN (pristine passes · each of the three gates driven red by its own mutant)"
  exit 0
fi
echo "SOF_ARM_RED_CAPABLE=NO — the scheduled arm cannot be trusted to report a violation."
exit 1

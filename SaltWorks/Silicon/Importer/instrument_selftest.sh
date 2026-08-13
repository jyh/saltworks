#!/bin/bash
# INSTRUMENT SELF-TEST — fire every REFUSAL path in this seat's measuring tools.
#
# ## Why this exists
#
# On 2026-08-12 this seat built three instruments in about ninety minutes and
# found SIX defects in them. Every one was caught by luck — a number that
# contradicted a fact already banked — never by inspection. Two of the six were
# refusal paths that did not refuse:
#
#   * a control row guarded by `[ -f "$GOLD" ] && a2 ...`, which with the golden
#     absent short-circuits to the ELSE branch and PRINTS A TICK;
#   * a sweep passing `--out /dev/null`, which inverted the verdict for exactly
#     the netlists that got far enough to be CHECKED.
#
# Each tool now carries refusals and each doc claims it "refuses rather than
# printing a caveat". ⛔ THAT CLAIM HAD NEVER BEEN TESTED. A refusal path that
# has never fired is not known to work — [[a-check-never-shown-to-fail]] wearing
# a safety label.
#
# ## ⛔ TWO DEFECTS THIS FILE HAD, IN THE TWO VERSIONS BEFORE THIS ONE
#
# (1) It judged a row by "tool exited non-zero after the fault".
#     `pinreset_controls.sh` ALREADY exits 1 — C3.A2 is red as ruled — so four
#     rows printed ✅ and would have done so had the fault done nothing.
#     Fix: assert the fault's OWN MESSAGE, not merely a failing exit.
#
# (2) With (1) fixed, two rows still passed FOR THE WRONG REASON. The sandbox
#     copied Silicon/ to $SBOX/Silicon, but `pinreset_controls.sh` resolves its
#     paths by climbing `$SELF/../../..` to a REPO ROOT — which did not exist in
#     the sandbox, so EVERY fixture was missing and EVERY row printed
#     "FIXTURE MISSING". A row asserting exactly that text passed with no fault
#     planted at all.
#     Fix: mirror the repo-root LAYOUT, and — the general cure —
#
# ⭐ EVERY ROW NOW CARRIES ITS OWN NEGATIVE CONTROL: the expected message must be
#   ABSENT from an UNFAULTED run and PRESENT in the faulted one. Asserting a
#   message is not enough; the message has to be caused by the fault.
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"
SILICON="$(cd "$SELF/.." && pwd)"
SBOX=$(mktemp -d); trap 'rm -rf "$SBOX"' EXIT
fail=0; n=0

# The sandbox mirrors the REPO-ROOT LAYOUT, because these tools locate their
# inputs by climbing to it. Copying the subtree alone silently defeats them.
ROOT="$SBOX/repo"
pristine() { rm -rf "$ROOT"; mkdir -p "$ROOT/SaltWorks" "$ROOT/docs"
             cp -R "$SILICON" "$ROOT/SaltWorks/Silicon"
             cp -R "$SELF/../../../docs/silicon-tools" "$ROOT/docs/" 2>/dev/null
             IMPDIR="$ROOT/SaltWorks/Silicon/Importer"; FLOW="$ROOT/SaltWorks/Silicon/Flow"; }
pristine

# row <label> <fault-cmd> <tool-cmd> <must-match-regex>
row() {
  local label=$1 fault=$2 tool=$3 must=$4 clean faulted rc
  n=$((n+1))
  # --- the NEGATIVE CONTROL: the message must not already be there
  pristine
  clean=$(eval "$tool" 2>&1)
  if echo "$clean" | grep -qE "$must"; then
    printf "  ⛔ %-50s ROW VOID — its message appears WITHOUT the fault\n" "$label"
    fail=1; return
  fi
  # --- the fault
  pristine
  if ! eval "$fault" >/dev/null 2>&1; then
    printf "  ⛔ %-50s FAULT COULD NOT BE PLANTED — row FAILS\n" "$label"; fail=1; return
  fi
  faulted=$(eval "$tool" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then
    printf "  ✗ %-50s ACCEPTED (exit 0) — the refusal DID NOT FIRE\n" "$label"; fail=1; return
  fi
  if echo "$faulted" | grep -qE "$must"; then
    printf "  ✅ %-50s REFUSED, naming the fault, and silent without it\n" "$label"
  else
    printf "  ✗ %-50s failed, but NOT for the planted reason\n" "$label"
    printf "        expected: %s\n" "$must"
    fail=1
  fi
}

echo "instrument self-test: every row controlled against an UNFAULTED run"
pristine
printf "  baselines (unfaulted): cell_coverage=%s pinreset=%s sweep=%s\n" \
  "$("$IMPDIR/cell_coverage.py" >/dev/null 2>&1; echo $?)" \
  "$("$IMPDIR/pinreset_controls.sh" >/dev/null 2>&1; echo $?)" \
  "$("$IMPDIR/import_sweep.py" >/dev/null 2>&1; echo $?)"
echo "  (pinreset's clean baseline is 1 — C3.A2 red as ruled — which is exactly"
echo "   why every pinreset row below needs its message-level control.)"
echo

# --- cell_coverage.py -------------------------------------------------------
row "cell_coverage: reference netlist dmem8 absent" \
    'rm -f "$FLOW/dmem8_nl.v"' \
    '"$IMPDIR/cell_coverage.py"' \
    'CONTROL CANNOT RUN'

row "cell_coverage: importer CLI boundary moved" \
    'perl -0pi -e "s/\nap = argparse.ArgumentParser\(\)/\nap = argparse.ArgumentParser( )/" "$IMPDIR/import_netlist.py"' \
    '"$IMPDIR/cell_coverage.py"' \
    'cannot locate the single CLI boundary'

row "cell_coverage: flip control's cell silently removed" \
    'perl -0pi -e "s/\"nand4_1\":/\"nand4_1x\":/" "$IMPDIR/import_netlist.py"' \
    '"$IMPDIR/cell_coverage.py"' \
    'DID NOT DISCRIMINATE|does not respond to a known change'

# ⚠️ The pattern here was first written as bare 'DISAGREE' — which also matches
# the tool's OWN control-of-the-control line, "the comparison can go DISAGREE".
# The row passed while proving nothing, and the negative control is what caught
# it. A refusal pattern must match the REFUSAL, not the prose explaining it.
# ⚠️ The FAULT was also wrong at first: renaming `nand4_1` to `zzz4_1` leaves the
# instance COUNT at 673, and this control compares counts, not identities — so
# the fault never reached the path it was meant to exercise and the row failed
# honestly. Hiding the cells from the extractor's PREFIX is what moves the count.
# Two separate mistakes in one row, pattern and fault; both surfaced only
# because the row was made to prove causation rather than correlation.
row "cell_coverage: extractor disagrees with trusted parser" \
    'perl -0pi -e "s/sky130_fd_sc_hd__nand4_1 /sky130_XX_sc_hd__nand4_1 /g" "$FLOW/dmem8_nl.v"' \
    '"$IMPDIR/cell_coverage.py"' \
    'the extractor disagrees with the parser'

# --- pinreset_controls.sh ---------------------------------------------------
row "pinreset: a control fixture goes missing" \
    'rm -f "$IMPDIR/fixtures/pinreset_nc1.v"' \
    '"$IMPDIR/pinreset_controls.sh"' \
    'FIXTURE MISSING \(pinreset_nc1.v\)'

row "pinreset C3: golden scope marker absent" \
    'rm -f "$IMPDIR/fixtures/pinreset_scope_marker.txt"' \
    '"$IMPDIR/pinreset_controls.sh"' \
    'golden scope marker missing'

row "pinreset C3: dfxtp comparison fixture DRIFTS from base" \
    'echo "// drift" >> "$IMPDIR/fixtures/pinreset_dfxtp.v"' \
    '"$IMPDIR/pinreset_controls.sh"' \
    'DRIFTED from the rewrite'

# ⭐ THE ROW THAT FOUND A REAL HOLE. A golden that is CORRUPTED rather than
# ABSENT changed nothing that gates: A2 was already red by ruling, NC3b/NC3c
# only require a2() to fail, and the exit code was 1 either way — so the golden
# could rot in place invisibly. C3.M was added to close it, and this row is what
# keeps it closed.
row "pinreset C3.M: golden CORRUPTED, not absent" \
    'echo "-- tampered" >> "$IMPDIR/fixtures/pinreset_scope_marker.txt"' \
    '"$IMPDIR/pinreset_controls.sh"' \
    'MARKER INTEGRITY'

# --- import_sweep.py: its guard is a CLASSIFICATION, not an exit code -------
want() {  # want <label> <fault> <must-appear> <must-NOT-appear>
  local label=$1 fault=$2 must=$3 mustnot=$4 clean out
  n=$((n+1))
  pristine
  clean=$("$IMPDIR/import_sweep.py" 2>&1)
  if echo "$clean" | grep -qE "$must"; then
    printf "  ⛔ %-50s ROW VOID — expected classification present unfaulted\n" "$label"
    fail=1; return
  fi
  pristine
  if ! eval "$fault" >/dev/null 2>&1; then
    printf "  ⛔ %-50s FAULT COULD NOT BE PLANTED — row FAILS\n" "$label"; fail=1; return
  fi
  out=$("$IMPDIR/import_sweep.py" 2>&1)
  if echo "$out" | grep -qE "$must" && ! echo "$out" | grep -qE "$mustnot"; then
    printf "  ✅ %-50s reclassified correctly, and not before\n" "$label"
  else
    printf "  ✗ %-50s MISCLASSIFIED\n" "$label"; fail=1
  fi
}

want "import_sweep: broken module decl -> SKIP, never IMPORTS" \
     'perl -0pi -e "s/^module dmem8\(/moduleX dmem8(/m" "$FLOW/dmem8_nl.v"' \
     'dmem8_nl\.v +SKIP' '✅ dmem8_nl\.v'

want "import_sweep: unmodelled cell -> BLOCKED, never IMPORTS" \
     'perl -0pi -e "s/\"nand4_1\":/\"nand4_1x\":/" "$IMPDIR/import_netlist.py"' \
     'dmem8_nl\.v +unmodelled-cell' '✅ dmem8_nl\.v'

# --- C-V1: port list vs the netlist's OWN vector declarations ---------------
# The refusal these rows fire was, until 20:2x on 8/12, INCIDENTAL: the honest
# port list only refused because the generic no-driver check happened to miss the
# base name, and it only got that chance because import_sweep.py happens to
# bit-expand. On a hand-written port list the same netlist imported at EXIT=0
# with a 2-bit port bound to ONE net and readback GREEN.
#
# ⭐ THE FAULT IS THE REALISTIC ONE and that is the point: the port list is left
# ALONE and the NETLIST's port is widened. That is what actually happens — RTL
# grows a bit, a hand-recorded port order does not follow. The clean run of the
# very same command imports at 0.
CV1='"$IMPDIR/import_netlist.py" "$IMPDIR/fixtures/vecbase_nl.v" --top vecbase \
     --out "$SBOX/cv1.lean" --name cv1NL --inputs a,b --outputs y'

row "C-V1: input port widened, port list not" \
    'perl -0pi -e "s/  input b;\n  wire b;/  input [1:0] b;\n  wire [1:0] b;/" "$IMPDIR/fixtures/vecbase_nl.v"' \
    "$CV1" \
    "names 'b' by its BASE name.*VECTOR \[1:0\] \(2 bits\)"

row "C-V1: output port widened, port list not" \
    'perl -0pi -e "s/  output y;\n  wire y;/  output [3:0] y;\n  wire [3:0] y;/" "$IMPDIR/fixtures/vecbase_nl.v"' \
    "$CV1" \
    "names 'y' by its BASE name.*VECTOR \[3:0\] \(4 bits\)"

echo
echo "instrument self-test: $n row(s), $( [ $fail -eq 0 ] && echo 'EVERY GUARD FIRED, EACH CONTROLLED' || echo 'FAILURES ABOVE' )"
exit $fail

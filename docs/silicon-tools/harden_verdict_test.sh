#!/bin/sh
# harden_verdict_test.sh — drive ALL NINE (drv, treatment) combinations of harden_run.sh's
# final verdict, on the SHIPPED BYTES.
#
# ⛔ WHY IT EXTRACTS RATHER THAN RESTATES. A copy of the logic in a test is a SECOND
#   ARTIFACT: it passes forever while the runner drifts away from it, and this seat has
#   banked that exact shape ("the tool you patched is not the tool they run"). So the block
#   under test is CUT OUT OF harden_run.sh at run time, by anchor, and evaluated. If someone
#   edits the runner, this test moves with it or fails to find its anchor and REFUSES.
# ⛔ AND THE REASON IT EXISTS AT ALL: those four lines decide whether a tape-out arm is
#   admissible, and a branch never executed has TEXT as unverified as its logic.
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
SRC="$HERE/harden_run.sh"
[ -r "$SRC" ] || { echo "harden_verdict_test: cannot read $SRC" >&2; exit 2; }

BLOCK=$(awk '/^D=\$\{DRV_RC:-2\}; T=\$\{TREAT_RC:-2\}$/{f=1} f{print} /^exit 2$/{if(f) exit}' "$SRC")
case "$BLOCK" in
  *"exit 2"*) : ;;
  *) echo "⛔ REFUSED: verdict block not found in harden_run.sh — the anchor moved. This test is stale, NOT passing." >&2; exit 2 ;;
esac
# `say` is defined in the runner; stub it so the block runs standalone.
BLOCK="say(){ :; }
$BLOCK"

PASS=0; FAIL=0
want() {  # want <drv> <treat> <expected-rc>
  got=$(sh -c "DRV_RC=$1 TREAT_RC=$2; $BLOCK" >/dev/null 2>&1; echo $?)
  if [ "$got" = "$3" ]; then PASS=$((PASS+1)); printf '  ✅ drv=%s treat=%s -> %s\n' "$1" "$2" "$got"
  else FAIL=$((FAIL+1)); printf '  ⛔ drv=%s treat=%s -> %s WANTED %s\n' "$1" "$2" "$got" "$3"; fi
}

echo "harden_run.sh final verdict, all nine combinations (0=pass 1=refused 2=unmeasured):"
want 0 0 0     # both green — the ONLY admissible arm
want 0 1 1
want 0 2 2     # a gate that could not measure must NOT read as pass
want 1 0 1
want 1 1 1
want 1 2 1     # a REFUSAL outranks an unmeasured gate: the run is known bad
want 2 0 2
want 2 1 1
want 2 2 2
echo "harden_verdict_test: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ] || exit 1

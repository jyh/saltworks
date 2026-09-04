#!/bin/bash
# landcheck_controls.sh — the SIX driven controls for landcheck.sh's fingerprint.
#
#   landcheck_controls.sh <path-to-landcheck.sh> <scratch-dir>
#
# WHY THIS FILE EXISTS. landcheck's fingerprint has been fixed three times (v2 the
# dirty SET, v3 the dirty CONTENT, v4 index-invariance) and each fix went exactly one
# level and stopped at the level its author had just been bitten at. A fix whose only
# witness is a better outcome on the case that bit you is not a fix — it is the next
# version of the same mistake. So the controls live in the repo and are runnable.
#
# v3 -> v4 RESULT, driven 2026-09-03 (compiler):
#     control                                    v3    v4    want
#     C0 no change at all                         0     0     0
#     C1 clean tracked file -> dirty              1     1     1
#     C2 content edit to an ALREADY-dirty file    1     1     1
#     C3 a NEW untracked path appears             1     1     1
#     C4 STAGING a new file, NO content change    1     0     0   <- v4 fixes this
#     C5 HEAD moves                               1     1     1
#
# ⛔ AND THE FIXTURE ITSELF FAILED FIRST, WHICH IS WHY EVERY CONTROL NOW ASSERTS THE
#   STATE IT BUILT AND ABORTS. The first version reused ONE repo across controls, so
#   C5's commit was already in HEAD by the second run: it moved nothing, exit 0 was
#   CORRECT for a no-op, and it read as a tool defect in both versions. A fixture that
#   silently fails to build its state makes red arms accuse the code.
#
# ⚠️ DECLARED STOP, inherited from landcheck and preserved by `--exclude-standard`:
#   a GITIGNORED file's content is invisible to the gate, so these controls do not
#   cover an audit-arm build whose subject is a Scratch*.lean.
# Drive six controls against a landcheck build, in a FRESH repo per control.
# ⛔ Every control ASSERTS the state it built and ABORTS if the build failed —
#    a fixture that silently fails to build its state makes red arms accuse the code.
LC="$1"; BASE="$2"
[ -x "$LC" ] || [ -f "$LC" ] || { echo "FIXTURE ABORT: no landcheck at $LC"; exit 9; }
n=0
fresh() {
  n=$((n+1)); REPO="$BASE/r$n"; rm -rf "$REPO"; mkdir -p "$REPO"; cd "$REPO" || exit 9
  git init -q .; git config user.email t@t; git config user.name t
  echo base > a.txt; git add a.txt; git commit -q -m base
  rm -rf "${TMPDIR:-/tmp}/landcheck-$(printf '%s' "$REPO" | shasum -a 256 | cut -c1-12)"
}
lc() { R="$REPO" bash "$LC" "$1" >/dev/null 2>&1; return $?; }
chk() { R="$REPO" bash "$LC" --check >/dev/null 2>&1; echo $?; }
assert() { [ "$1" = "$2" ] || { echo "FIXTURE ABORT ($3): expected [$2] got [$1]"; exit 9; }; }

fresh; lc --arm
assert "$(git status --porcelain | wc -l | tr -d ' ')" "0" "C0 tree must be clean"
echo "C0 no change at all                       exit=$(chk)   want 0"

fresh; lc --arm; echo x >> a.txt
assert "$(git status --porcelain)" " M a.txt" "C1 a.txt must be dirty"
echo "C1 clean tracked file -> dirty            exit=$(chk)   want 1"

fresh; echo x >> a.txt; lc --arm; echo y >> a.txt
assert "$(git status --porcelain)" " M a.txt" "C2 a.txt must still be dirty"
assert "$(grep -c y a.txt)" "1" "C2 the second edit must be present"
echo "C2 content edit to an ALREADY-dirty file  exit=$(chk)   want 1"

fresh; lc --arm; echo new > b.txt
assert "$(git status --porcelain)" "?? b.txt" "C3 b.txt must be untracked"
echo "C3 a NEW untracked path appears           exit=$(chk)   want 1"

fresh; echo new > b.txt; lc --arm; git add b.txt
assert "$(git status --porcelain)" "A  b.txt" "C4 b.txt must be STAGED"
echo "C4 STAGING a new file, NO content change  exit=$(chk)   want 0  <- THE FIX"

fresh; H0=$(git rev-parse HEAD); lc --arm
echo z > c.txt; git add c.txt; git commit -q -m moved
H1=$(git rev-parse HEAD)
[ "$H0" != "$H1" ] || { echo "FIXTURE ABORT (C5): HEAD DID NOT MOVE"; exit 9; }
echo "C5 HEAD moves                             exit=$(chk)   want 1"

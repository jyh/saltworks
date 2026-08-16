#!/bin/bash
# PROPOSED build-arm mutation detector for saltbuild.sh, tested in ISOLATION.
#
# TWO DELIBERATE CHOICES ABOUT THE FIXTURE:
#  1. No lake invocation — a stub stands in for the build, so the DETECTOR is what is
#     under test and the fleet memory lock is never contended.
#  2. A THROWAWAY repo in this seat's scratchpad — NOT saltworks. The first draft of this
#     test wrote a probe file into the shared five-seat tree, which is the exact collision
#     class the proposal exists to detect. A test for a shared-tree hazard must not create one.
#
# The audit arm already does this for its single target file (PRESHA/POSTSHA -> "UNPINNED").
# This is that guard widened to the tree the BUILD arm actually reads.
set -uo pipefail
T=$(mktemp -d)
cd "$T" || exit 2
git init -q . && git config user.email t@t && git config user.name t
echo seed > seed.txt && git add seed.txt && git commit -qm seed

fingerprint() {           # what the build arm reads: HEAD + the working tree's dirty set
  printf '%s|%s' \
    "$(git rev-parse --short HEAD 2>/dev/null)" \
    "$(git status --porcelain 2>/dev/null | shasum -a 256 | cut -c1-12)"
}

run_with_detector() {     # $1 = a stub standing in for `lake build`
  local PRE POST START EXIT VERDICT
  START=$(date '+%H:%M:%S'); PRE=$(fingerprint)
  eval "$1"; EXIT=$?
  POST=$(fingerprint)
  VERDICT="tree-stable"
  [ "$PRE" != "$POST" ] && VERDICT="TREE MOVED DURING RUN -- this EXIT is NOT attributable"
  printf '  start=%s end=%s | pre=%s post=%s | EXIT=%s\n  => %s\n' \
    "$START" "$(date '+%H:%M:%S')" "$PRE" "$POST" "$EXIT" "$VERDICT"
}

echo "=== NEGATIVE CONTROL: nothing touches the tree during the run ==="
run_with_detector "sleep 1"

echo "=== POSITIVE CONTROL A: a peer WRITES into the tree mid-run ==="
run_with_detector "( sleep 0.3; echo x > peer_probe.txt ) & sleep 1; wait"

echo "=== POSITIVE CONTROL B: a peer COMMITS mid-run (HEAD moves) ==="
run_with_detector "( sleep 0.3; git add -A >/dev/null; git commit -qm peer ) & sleep 1; wait"

echo "=== NEGATIVE CONTROL 2: quiet again, tree clean and committed ==="
run_with_detector "sleep 1"

echo "=== FALSE-POSITIVE CHECK: does the BUILD's own output trip it? ==="
echo "(lake writes .lake/build artifacts; .gitignore must cover them or every run reads MOVED)"
printf '.lake/\n' > .gitignore && git add .gitignore && git commit -qm ignore
run_with_detector "mkdir -p .lake/build && echo artifact > .lake/build/out.olean; sleep 1"

rm -rf "$T"

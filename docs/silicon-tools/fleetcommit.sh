#!/bin/sh
# FLEETCOMMIT — the commit critical section, held by a lock instead of by memory.
#
# ⛔ WHY: over ONE shared checkout NO commit form is race-free. Both earlier fleet laws
#   have DRIVEN failures — the pathspec form raced the WORKING TREE (761dc79: my
#   uncommitted hunk shipped inside compiler's commit), the index form raced the SHARED
#   INDEX (ecd8fbc2: compiler's staged work landed in jas's commit).
#   ⇒ `git diff --cached` IS NOT A RECEIPT: the index is shared and mutable between the
#     read and the commit. FLEET ORDER 2026-08-24 19:03 replaces both with a mkdir lock.
#
# ⭐ WHY mkdir AND NOT A LOCKFILE: mkdir is ATOMIC and fails when the directory exists.
#   `[ -e lock ] || touch lock` is two operations with a window between them — the exact
#   shape of bug this lock exists to close. Do not "improve" it into a test-then-create.
#
# ⛔ THE RELEASE IS THE DANGEROUS HALF. A lock you can forget to release deadlocks every
#   other seat, so the release is a TRAP set in the same breath as the acquire, firing on
#   EXIT/INT/TERM. A lock held by a dead shell is worse than no lock at all.
#
# usage: fleetcommit.sh <repo-dir> <commit-msg-file> [--push] [path ...]
#        with no paths, stages nothing itself — stage first, then call.
set -u
REPO=${1:?"usage: fleetcommit.sh <repo-dir> <msg-file> [--push] [path ...]"}
MSG=${2:?"usage: fleetcommit.sh <repo-dir> <msg-file> [--push] [path ...]"}
shift 2
PUSH=0
[ "${1:-}" = "--push" ] && { PUSH=1; shift; }

[ -d "$REPO/.git" ] || { echo "fleetcommit: $REPO is not a git checkout" >&2; exit 2; }
[ -f "$MSG" ]       || { echo "fleetcommit: no message file at $MSG" >&2; exit 2; }
LOCK="$REPO/.git/fleet-commit.lock.d"

# ── ACQUIRE, with a bounded wait. A lock that never times out turns one stuck seat
#    into a stuck fleet; a lock that force-breaks turns a slow seat into a corrupt one.
#    So: WAIT, then REFUSE and say who to ask. Never break the lock.
tries=0
until mkdir "$LOCK" 2>/dev/null; do
  tries=$((tries+1))
  if [ "$tries" -ge 30 ]; then
    echo "⛔ fleetcommit: lock HELD after ${tries} tries ($LOCK)" >&2
    echo "   Another seat is inside its commit section. NOT breaking the lock." >&2
    echo "   If it is stale (no seat committing), the owner removes it: rmdir '$LOCK'" >&2
    exit 4
  fi
  sleep 2
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM   # ⛔ same breath as the acquire

cd "$REPO" || exit 2
echo "fleetcommit: lock ACQUIRED after $tries wait(s)"

[ $# -gt 0 ] && git add -- "$@"

# ── THE READ IS STILL WORTH DOING, BUT ITS MEANING CHANGED. Inside the lock it is a
#    receipt; outside it never was. Print it either way so a wrong staging is visible.
staged=$(git diff --cached --name-only)
if [ -z "$staged" ]; then
  echo "⛔ fleetcommit: NOTHING STAGED — refusing to make an empty commit by accident." >&2
  echo "   (an intentional empty commit is git commit --allow-empty, done deliberately)" >&2
  exit 5
fi
echo "fleetcommit: staged set, read INSIDE the lock —"
printf '    %s\n' $staged

git commit -q -F "$MSG" || { echo "fleetcommit: commit FAILED" >&2; exit 6; }
NEW=$(git rev-parse --short HEAD)
echo "fleetcommit: committed $NEW"

if [ "$PUSH" = "1" ]; then
  git fetch -q origin
  if [ "$(git rev-list --count HEAD..origin/master)" -gt 0 ]; then
    git rebase -q origin/master || { echo "fleetcommit: rebase FAILED — resolve by hand" >&2; exit 7; }
  fi
  git push -q origin master || { echo "fleetcommit: push FAILED" >&2; exit 8; }
  git fetch -q origin
  echo "fleetcommit: pushed · ahead $(git rev-list --count origin/master..HEAD)"
fi

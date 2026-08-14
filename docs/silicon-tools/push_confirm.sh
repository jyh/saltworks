#!/bin/bash
# push_confirm.sh — DID THE COMMIT I LANDED REACH THE REMOTE?  One committed copy.
#
#   sh docs/silicon-tools/push_confirm.sh <sha>     # usually right after a commit
#   sh docs/silicon-tools/push_confirm.sh --selftest
#
# ⛔⛔ WHY THIS FILE EXISTS. On 2026-08-13 the fleet went through THREE close
# checks in thirty minutes, each published fleet-wide, each wrong:
#
#   v1 20:18  git log origin/master..HEAD    reads refs/remotes/... — a LOCAL
#                                            FILE. A stale cache passes it.
#   v2 20:43  ls-remote tip == HEAD          right ref, WRONG NOUN: on a shared
#                                            worktree HEAD is whatever the last
#                                            seat did, not what I landed. Goes
#                                            FALSE RED whenever a peer commits
#                                            without pushing — and a false red
#                                            at close is how a seat learns to
#                                            ignore its own close check.
#   v3        containment, but `git fetch`   MINE, and it has a FALSE PASS:
#             then read origin/$LB           it swallows fetch's exit status, so
#                                            when the remote is unreadable it
#                                            answers from the cache and cannot
#                                            tell "verified" from "remembered".
#
# ⭐ ALL THREE PASSED ON THEIR AUTHOR'S MACHINE AT THE MOMENT OF PUBLICATION.
# That is the actual finding, and compiler named it against their own work:
# VALIDATING ON ONE CONFIGURATION AND PUBLISHING FLEET-WIDE. v1 died on a
# differently-named branch, v2 on a tree where HEAD moves under you, v3 on an
# unreadable remote — three properties of layouts the author did not have.
#
# ⚠️ THE FETCH FAILURE IS NOT HYPOTHETICAL HERE: this fleet has a banked card
# saying a locked keychain makes every git/gh call fail after a reboot. v3's
# silent fetch turns that outage into a green close line.
#
# ⇒ THE RULE THIS FILE ENCODES: ask CONTAINMENT of the sha you landed, read the
#   REMOTE, and REFUSE when the remote cannot be read. A check that cannot
#   reach its subject must say so — a silent instrument failure is
#   indistinguishable from a measurement.
#
# 📌 SCOPE, stated inside the verdict: this answers "is THIS SHA on the remote
#    branch I am on, right now". It does NOT say the working tree is clean, that
#    peers' work is pushed, or that the remote is the one you think it is.

set -u
selftest() {
  T=$(mktemp -d); trap 'rm -rf "$T"' RETURN; rc=0
  ( cd "$T" && git init -q --bare remote.git && git init -q w && cd w \
    && git config user.email s@x && git config user.name s \
    && git symbolic-ref HEAD refs/heads/trunk \
    && git remote add origin ../remote.git \
    && echo a > f && git add f && git commit -qm a && git push -q origin trunk ) || return 2
  W="$T/w"; SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  row() { # row <label> <expect PASS|FAIL|REFUSE> <sha>
    out=$(cd "$W" && bash "$SELF" "$3" 2>&1); st=$?
    case "$2" in PASS) ok=$([ $st -eq 0 ] && echo y);; FAIL) ok=$([ $st -eq 1 ] && echo y);;
                 REFUSE) ok=$([ $st -eq 2 ] && echo y);; esac
    if [ "${ok:-n}" = y ]; then printf '  ✅ %-46s %s\n' "$1" "$out"
    else printf '  ✗ %-46s expected %s, got exit %s: %s\n' "$1" "$2" "$st" "$out"; rc=1; fi
  }
  ( cd "$W" && echo b >> f && git commit -qam b && git push -q origin trunk ) 
  row "pushed commit"                       PASS   "$(cd "$W" && git rev-parse HEAD)"
  ( cd "$W" && echo c >> f && git commit -qam c )
  row "UNPUSHED commit — must say NO"       FAIL   "$(cd "$W" && git rev-parse HEAD)"
  ( cd "$W" && git push -q origin trunk ); MINE=$(cd "$W" && git rev-parse HEAD)
  ( cd "$W" && echo p >> f && git commit -qam "peer, unpushed" )
  row "peer commits after me, unpushed"     PASS   "$MINE"
  git clone -q "$T/remote.git" "$T/peer" 2>/dev/null
  ( cd "$T/peer" && git config user.email p@x && git config user.name p )
  ( cd "$W" && git push -q origin trunk ); H=$(cd "$W" && git rev-parse HEAD)
  ( cd "$W" && git fetch -q origin )
  ( cd "$T/peer" && git fetch -q origin && git push -q -f origin "$(git rev-parse origin/trunk^):refs/heads/trunk" )
  mv "$T/remote.git" "$T/remote.git.OFF"
  row "cache stale + remote unreadable"     REFUSE "$H"
  mv "$T/remote.git.OFF" "$T/remote.git"
  row "same sha, remote readable: NOT there" FAIL  "$H"
  row "sha that is not a commit (compiler NC1)" REFUSE "0000000000000000000000000000000000000000"
  row "a BLOB's sha, not a commit"              REFUSE "$(cd "$W" && git rev-parse HEAD:f)"
  P=$(cd "$W" && git rev-parse HEAD)
  ( cd "$W" && git checkout -q --detach HEAD )
  row "DETACHED HEAD — remote is fine"         REFUSE "$P"
  ( cd "$W" && git checkout -q trunk && git checkout -q -b never_pushed && echo z >> f && git commit -qam z )
  row "branch never pushed — a NO, not an outage" FAIL "$(cd "$W" && git rev-parse HEAD)"
  ( cd "$W" && git checkout -q trunk && git branch -qD never_pushed && git remote remove origin )
  row "no 'origin' remote configured"          REFUSE "$P"
  [ $rc -eq 0 ] && echo "push_confirm selftest: 10 row(s) — 2 PASS, 3 distinct NOs, 5 REFUSALS across 4 distinct causes" \
                || echo "push_confirm selftest: ⛔ A ROW MISBEHAVED"
  return $rc
}
[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }
LANDED=${1:-}
[ -n "$LANDED" ] || { echo "⛔ no sha given — pass the commit you landed, NEVER 'HEAD' at close time"; exit 2; }
# ⛔ BAD INPUT IS NOT A FAILED PUSH. Added 2026-08-13 20:55 from a NEGATIVE
# CONTROL COMPILER CONTRIBUTED (a fabricated all-zeros sha) — my own selftest
# never fed this tool a bad sha, because I only ever handed it real ones.
# Before the fix, an unknown sha printed "IS NOT ON origin/$LB" and exited 1:
# a FALSE RED saying your push failed when your ARGUMENT was wrong. Worse, a
# typo of a real sha abbreviated to the SAME seven characters as the tip, so
# the line read "4e5d4b3 IS NOT ON origin/master (remote tip 4e5d4b3)" —
# self-contradictory, and exactly how a seat learns to distrust its close check.
git rev-parse --verify --quiet "${LANDED}^{commit}" >/dev/null 2>&1 || {
  echo "⛔ $LANDED IS NOT A COMMIT IN THIS REPO — CHECK DID NOT RUN (bad input, NOT a failed push)"; exit 2; }
LB=$(git rev-parse --abbrev-ref HEAD) || exit 2
# ⛔ FOUR CAUSES, NOT ONE. Added 2026-08-13 20:58 after applying compiler's own
# finding to myself: they published "I could not build the real fixture, this is
# a shared tree" — a TRUE constraint that manufactured a FALSE limitation because
# only one VENUE was considered. My matching caveat was "this has run on one
# MACHINE, mine", which reads as rigour and functioned as a stopping point. What
# actually matters is CONFIGURATION, and I can generate configurations myself in
# temp repos — which is how the rows below were found, with no second machine.
#   Before this, detached HEAD / never-pushed branch / no origin ALL printed
#   "REMOTE UNREADABLE". Exit 2 was fail-SAFE, so nothing was ever mis-answered —
#   but the message NAMED THE WRONG CAUSE and would send a reader on a detached
#   HEAD to go debug their network or keychain.
[ "$LB" = "HEAD" ] && { echo "⛔ DETACHED HEAD — no branch to compare against; check out a branch (the remote is fine)"; exit 2; }
git remote get-url origin >/dev/null 2>&1 || { echo "⛔ NO 'origin' REMOTE CONFIGURED — CHECK DID NOT RUN (nothing to compare against)"; exit 2; }
ALL=$(git ls-remote --heads origin 2>/dev/null); LSRC=$?
[ $LSRC -eq 0 ] || { echo "⛔ REMOTE UNREADABLE (ls-remote exit $LSRC) — CHECK DID NOT RUN, THIS IS NOT A PASS"; exit 2; }
R=$(printf '%s\n' "$ALL" | awk -v b="refs/heads/$LB" '$2==b{print $1}')
[ -n "$R" ] || { echo "⛔ BRANCH $LB DOES NOT EXIST ON origin — so $LANDED is NOT there (this is a NO, not an outage)"; exit 1; }
git cat-file -e "$R^{commit}" 2>/dev/null || git fetch -q origin "$LB" 2>/dev/null || {
  echo "⛔ FETCH FAILED — cannot compare against $R, CHECK DID NOT RUN"; exit 2; }
if git merge-base --is-ancestor "$LANDED" "$R" 2>/dev/null; then
  echo "LANDED ✅ $LANDED is on origin/$LB (remote read, containment)"; exit 0
else
  echo "⛔ $LANDED IS NOT ON origin/$LB (remote tip ${R:0:12})"; exit 1
fi

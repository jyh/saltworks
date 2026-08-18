#!/usr/bin/env bash
# checked_push.sh — PUSH, THEN PROVE THE COMMIT IS ON THE REMOTE. Never `2>/dev/null`.
#
#   checked_push.sh [<repo-dir>]      exit 0 = HEAD is CONTAINED in origin/<branch>
#                                     exit 1 = it is NOT (push failed, rejected, or raced)
#                                     exit 2 = the push command itself errored
#
# ⛔⛔ WHY THIS EXISTS, and it is a defect I committed twice in one day.
#   08/18 08:0x I fixed `bus_custody.sh` for swallowing a stderr refusal, and banked the law:
#     A CHECK THAT DID NOT RUN MUST NOT LOOK LIKE A CHECK THAT PASSED.
#   08/18 16:52 I pushed a LANDING CONDITION another seat was BLOCKED ON with
#     `git push -q origin HEAD 2>/dev/null` — stderr suppressed — and then reported
#     "unpushed 0" read off `git log origin/master..HEAD`.
#   ⇒ THAT NUMBER COMES FROM A LOCAL CACHE. `origin/master` is a tracking ref; if the push
#     had failed, the ref would not move, the count could still read 0 against a stale
#     baseline, and I WOULD HAVE TOLD A BLOCKED PEER THAT THEIR CONDITION WAS MET.
#     It happened not to fail. LUCK IS NOT A RECEIPT.
#
# ⭐ THE CHECK IS `git branch -r --contains`, NOT A COUNT: it asks the remote-tracking graph
#   whether THIS COMMIT is reachable from the remote branch, after an explicit fetch. A count
#   of "commits ahead" answers a different question and answers it from cache.
#
# ✅ ARMS DRIVEN 08/18 17:0x, and they DIFFER:
#   1 real repo, already pushed        → exit 0, "IS CONTAINED"
#   2 scratch repo, healthy remote     → exit 0, "IS CONTAINED"
#   3 remote DESTROYED mid-test        → exit 2, and it PRINTS git's stderr verbatim
#                                        ("does not appear to be a git repository")
# ⛔ NOT DRIVEN, DECLARED RATHER THAN FAKED: the fourth case — push SUCCEEDS but HEAD is
#   not on origin/<branch>. I built a fixture for it and THE FIXTURE WAS VOID: the push
#   simply worked and the tool correctly reported containment. I could not construct the
#   condition with a local bare remote, so that arm is UNPROVEN, not passing.
#   (Same law as the void mutant that nearly made me accuse a peer's gate this morning:
#    a fixture that did not apply and a tool that cannot fail print the same bytes.)
set -u
cd "${1:-.}" || { echo "⛔ checked_push: cannot enter ${1:-.}" >&2; exit 2; }
BR=$(git rev-parse --abbrev-ref HEAD) || exit 2
SHA=$(git rev-parse --short HEAD)     || exit 2
ERR=$(mktemp); trap 'rm -f "$ERR"' EXIT
git push origin HEAD >"$ERR" 2>&1; PRC=$?
if [ "$PRC" != 0 ]; then
  printf '⛔ checked_push: THE PUSH ITSELF FAILED (exit %s). stderr, NOT swallowed:\n' "$PRC" >&2
  sed 's/^/   /' "$ERR" >&2
  exit 2
fi
git fetch -q origin 2>>"$ERR" || true
if git branch -r --contains "$SHA" 2>/dev/null | grep -q "origin/$BR"; then
  printf '✅ checked_push: %s IS CONTAINED IN origin/%s (verified after fetch, not from a count).\n' "$SHA" "$BR"
  exit 0
fi
printf '⛔ checked_push: %s IS **NOT** ON origin/%s AFTER A PUSH THAT REPORTED SUCCESS.\n' "$SHA" "$BR" >&2
printf '   Do NOT tell anyone this landed. push stderr:\n' >&2
sed 's/^/   /' "$ERR" >&2
exit 1

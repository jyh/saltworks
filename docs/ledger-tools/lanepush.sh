#!/bin/sh
# lanepush.sh — REFUSE a push that would change another seat's paths at the remote.
#
# ⚠️ FRAME, STATED FIRST: THIS IS A GUARD AGAINST MY OWN OPERATOR ERROR, NOT A SECURITY
# BOUNDARY. Anyone who can set GIT_CONFIG_* in this shell can simply run `git push`.
# It refuses the environments it cannot vouch for rather than pretending to defeat them.
#
# ── HISTORY, BECAUSE BOTH PRIOR VERSIONS FAILED OPEN ────────────────────────────────
# v1 (d028600): I ran `rev-list --count`, printed "(mine)" beside it, pushed on the
#   LABEL, and published silicon's edf7d4c. Then the helm DROVE v1 in a clone whose
#   origin was a local path: `ls-remote origin master` returned 3 refs, R became
#   multi-line, the range query failed, the count came back EMPTY, and it printed
#       ✅ all  commit(s) ahead ... safe to push        EXIT=0
#   THE ERROR PATH WAS A PASS.  (the double space WAS the empty count)
#
# v2: hardened every measurement — one 40-hex sha or abort, checked exit status,
#   numeric count, count/list agreement. Eight adversarial drivers then broke it 8/8:
#   ⛔ "THE ERROR PATH IS NO LONGER A PASS; THE SUCCESS PATH IS NOW POINTED AT THE
#      WRONG OBJECT." Three classes, none of them an unmeasurable state:
#     A WRONG LOCAL REF — $BRANCH steered the remote side while the local side was
#       hardcoded HEAD. On any other branch, a detached HEAD, or a second worktree,
#       it audited one object while `git push origin master` moved another. NO
#       ADVERSARY REQUIRED — its own usage line invited it.
#     B WRONG DESTINATION — `ls-remote` reads the FETCH url; `git push` uses pushurl.
#       Plus push.default=matching and remote.*.push refspecs send refs never audited.
#     C EMPTY FILE LIST READ AS INNOCENCE — `git show --name-only` prints the COMBINED
#       diff for a merge, so `git merge -s ours origin/master` carries a foreign-path
#       change whose file list is EMPTY while the other parent's commits are excluded
#       from the range. And rename detection reports only the DESTINATION, so deleting
#       a peer's files and re-adding them in my lane looked lane-clean.
#       ⇒ v1 printed an empty COUNT as a verdict; v2 printed an empty FILE LIST as one.
#
# ── WHAT CHANGED IN v3, AND IT IS A SIMPLIFICATION ──────────────────────────────────
# Class C is not patchable per-commit: I was inferring "what will this push publish?"
# from a WALK OF COMMITS. That is the wrong object. The question a push answers is a
# TREE DIFF: which paths differ at the remote once the push lands.
#     git diff --no-renames --name-only $R $L
# One command. Immune by construction to merges (no combined-diff subtlety), to
# renames (--no-renames shows delete AND add, so removing a peer's file is visible),
# to empty commits, and to add-then-remove churn. THE CORRECT MEASUREMENT IS SMALLER
# THAN THE WRONG ONE.
#
# ⚠️ PATHS, NOT AUTHORSHIP: every commit here is authored "Jason Hickey" — git cannot
# discriminate seats. silicon: "checked by PATH since authorship cannot discriminate."
#
# ⚠️ KNOWN, SAFE-DIRECTION LIMITATION (driven, not guessed): --name-only C-QUOTES a
# non-ASCII path, so an IN-LANE file like docs/evidence-café.md is refused with the
# wrong reason. That is a WRONG REFUSAL, never a wrong pass, and the quoting is exactly
# what makes a newline-in-path fail closed. Cure if it ever bites: -z with NUL-split
# matching the RAW bytes. Not taken: it trades a safe failure for a subtle one.
#
# usage: sh docs/ledger-tools/lanepush.sh [remote] [branch]
# exit 0 = this push changes only this seat's lane · 1 = REFUSE, foreign paths
# exit 2 = COULD NOT MEASURE, or an environment I will not vouch for — REFUSE
set -u
REMOTE=${1:-origin}; BRANCH=${2:-master}
# ⛔ THE PREFIX MUST BE BOUNDED. `^docs/EVIDENCE` admitted docs/EVIDENCEFAKE/rtl/silicon.v
# and docs/EVIDENCE_stolen.v — a foreign path wearing my lane's first eight letters.
# All 35 live lane files are docs/EVIDENCE-*, so a delimiter class is free. Do NOT put
# `_` in it: that re-admits the second path (driven).
MINE='^(docs/ledger-tools/|docs/EVIDENCE([-./]|$)|docs/evidence-)'
die() { printf '⛔ CANNOT MEASURE — REFUSING: %s\n' "$1" >&2; exit 2; }

# ⛔ replace-refs rewrite what git SHOWS while the push sends the REAL object.
# `git filter-repo` (salt's documented purge plan) creates them. Live repo has 0 today.
GIT_NO_REPLACE_OBJECTS=1; export GIT_NO_REPLACE_OBJECTS
[ -z "$(git for-each-ref refs/replace 2>/dev/null)" ] || die "refs/replace exist — git would show me a different object than the push sends"

# (0) an environment that redirects what git reads
for v in GIT_DIR GIT_WORK_TREE GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_OBJECT_DIRECTORY GIT_COMMON_DIR; do
  eval "vv=\${$v:-}"; [ -n "$vv" ] && die "$v is set — it redirects what this gate measures"
done

# (1) the DESTINATION must be the one a push uses
git remote | grep -qx -- "$REMOTE" || die "'$REMOTE' is not a configured remote"
FU=$(git remote get-url -- "$REMOTE" 2>/dev/null)        || die "cannot read fetch url for $REMOTE"
PU=$(git remote get-url --push -- "$REMOTE" 2>/dev/null) || die "cannot read push url for $REMOTE"
[ "$FU" = "$PU" ] || die "push url != fetch url ($PU vs $FU) — I would audit the wrong destination"
[ -z "$(git config --get-all "remote.$REMOTE.push" 2>/dev/null)" ] \
  || die "remote.$REMOTE.push refspecs are configured — the refs sent are not the refs audited"
PD=$(git config --get push.default 2>/dev/null) || PD=simple
case "$PD" in simple|current|upstream|nothing) : ;; *) die "push.default=$PD can send refs this gate did not audit" ;; esac

# (2) the LOCAL side must be the ref the push actually moves
HEADREF=$(git symbolic-ref -q HEAD) || die "detached HEAD — cannot know which branch a push would move"
[ "$HEADREF" = "refs/heads/$BRANCH" ] || die "checked out $HEADREF but asked about refs/heads/$BRANCH"
L=$(git rev-parse --verify --quiet "refs/heads/$BRANCH") || die "no local refs/heads/$BRANCH"

# (3) the REMOTE side: exactly one ref, named exactly, 40 hex, present locally
RAW=$(git ls-remote "$REMOTE" "refs/heads/$BRANCH" 2>/dev/null) || die "ls-remote failed"
NREF=$(printf '%s\n' "$RAW" | grep -c '^[0-9a-f]') || NREF=0
[ "$NREF" -eq 1 ] || die "ls-remote returned $NREF refs for refs/heads/$BRANCH (need exactly 1)"
R=$(printf '%s\n' "$RAW"  | head -1 | cut -f1)
RN=$(printf '%s\n' "$RAW" | head -1 | cut -f2)
[ "$RN" = "refs/heads/$BRANCH" ] || die "ls-remote matched '$RN', not refs/heads/$BRANCH"
case "$R" in ''|*[!0-9a-f]*) die "remote sha is not pure hex: [$R]" ;; esac
[ "${#R}" -eq 40 ] || die "remote sha is ${#R} chars, expected 40"
git cat-file -e "$R^{commit}" 2>/dev/null || die "remote head $R not present locally — fetch first"

# (4) refuse to reason about a non-fast-forward push at all
[ "$R" = "$L" ] && { printf '✅ 0 ahead — nothing to push  [%s]\n' "$(git rev-parse --show-toplevel)"; exit 0; }
git merge-base --is-ancestor "$R" "$L" 2>/dev/null \
  || die "refs/heads/$BRANCH is not a fast-forward of $REMOTE — a force-push is not mine to audit"

# (5) THE MEASUREMENT — what this push CHANGES AT THE REMOTE
DIFF=$(git diff --no-renames --name-only "$R" "$L" 2>/dev/null) || die "tree diff $R..$L failed"
NPATH=$(printf '%s\n' "$DIFF" | grep -c '[^[:space:]]') || NPATH=0
AHEAD=$(git rev-list --count "$R..$L" 2>/dev/null) || die "rev-list --count failed"
case "$AHEAD" in ''|*[!0-9]*) die "ahead count is not a number: [$AHEAD]" ;; esac
[ "$NPATH" -eq 0 ] && { printf '✅ %s commit(s) ahead, 0 paths changed at the remote  [%s]\n' "$AHEAD" "$(git rev-parse --show-toplevel)"; exit 0; }

# ⛔⛔ `|| true` HERE WAS THE LAST FAIL-OPEN, AND IT WAS THE GATE'S OWN HEADER LAW
# COMMITTED INSIDE THE GATE: a malformed $MINE makes grep exit 2 with an error printed
# ONE LINE ABOVE the verdict, `OUT` empty, and the pass printed anyway. grep exits 0 on
# match, 1 on no-match, >1 on ERROR — only the first two are answers.
OUT=$(printf '%s\n' "$DIFF" | grep '[^[:space:]]' | grep -vE "$MINE"); rc=$?
[ "$rc" -le 1 ] || die "lane filter failed (grep rc=$rc) — the pattern, not the push, is the problem"
if [ -n "$OUT" ]; then
  NBAD=$(printf '%s\n' "$OUT" | grep -c '[^[:space:]]')
  printf '⛔ REFUSING: this push changes %s path(s) outside this seat'"'"'s lane:\n' "$NBAD"
  printf '%s\n' "$OUT" | sed 's/^/     /'
  echo "   Pushing publishes or alters another seat's work. POST AND ASK instead."
  exit 1
fi
printf '✅ %s commit(s) ahead, %s path(s) changed, all in this seat'"'"'s lane — safe to push  [%s]\n' \
  "$AHEAD" "$NPATH" "$(git rev-parse --show-toplevel)"
exit 0

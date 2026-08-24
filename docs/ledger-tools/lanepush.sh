#!/bin/sh
# lanepush.sh — REFUSE a saltworks push that would publish another seat's commit.
#
# WHY (evidence, 2026-08-23 18:5x, against myself): my standing rule is "no push while
# a NON-AUTHORED commit sits ahead". I ran `git rev-list --count`, printed "(mine)"
# beside the number, and pushed — publishing silicon's edf7d4c. THE LABEL WAS A
# HARDCODED EXPECTATION AND THE ACTION WAS TAKEN ON THE LABEL.
#   ⛔ It was the FIFTH instance that day of "a conclusion printed beside a number that
#     did not produce it", and the FIRST with a consequence rather than a near-miss —
#     because the other four had a separate verification step that could fail, and this
#     one put the label INSIDE the action, where nothing audits it.
#   ⇒ A GUARD IN A DOCUMENT PROTECTS THE READER; A GUARD IN THE EXECUTABLE PROTECTS THE JOB.
#
# ⚠️ IT KEYS ON PATHS, NOT AUTHORSHIP, AND THAT IS DELIBERATE: every commit in this repo
# is authored "Jason Hickey" — git CANNOT discriminate seats here. silicon said it first:
# "checked by PATH since authorship cannot discriminate."
#
# usage: sh docs/ledger-tools/lanepush.sh [remote] [branch]     exit 0 = safe to push
set -u
REMOTE=${1:-origin}; BRANCH=${2:-master}
MINE='^(docs/ledger-tools/|docs/EVIDENCE|docs/evidence-)'
R=$(git ls-remote "$REMOTE" "$BRANCH" | cut -f1)
[ -n "$R" ] || { echo "⛔ cannot read $REMOTE/$BRANCH"; exit 2; }
AHEAD=$(git rev-list --count "$R..HEAD")
[ "$AHEAD" = "0" ] && { echo "✅ 0 ahead — nothing to push"; exit 0; }
bad=0
for c in $(git rev-list "$R..HEAD"); do
  out=$(git show --stat --format='' --name-only "$c" | grep -vE "$MINE" | grep -v '^$' || true)
  if [ -n "$out" ]; then
    bad=$((bad+1))
    echo "⛔ $(git log -1 --format='%h %s' "$c" | cut -c1-70)"
    echo "$out" | sed 's/^/     outside my lane: /'
  fi
done
if [ "$bad" != 0 ]; then
  echo "⛔ REFUSING: $bad of $AHEAD commit(s) ahead touch paths outside this seat's lane."
  echo "   Pushing publishes another seat's work. POST AND ASK instead."
  exit 1
fi
echo "✅ all $AHEAD commit(s) ahead touch only this seat's lane — safe to push"
exit 0

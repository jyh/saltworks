#!/bin/bash
# flipmap.sh — DERIVE THE PRE-FLIP → POST-FLIP SHA MAPPING, WHILE IT IS STILL POSSIBLE.
#
# WHY THIS EXISTS: the public flip rewrote every commit, so EVERY sha written into
# a file before it is now a dead pointer on the public origin. The compiler
# pathspec alone cites 166 distinct orphaned shas across 239 files; silicon's
# public docs cite 88, of which ZERO resolve.
#
# ⛔ MY ORIGINAL URGENCY PREMISE WAS OVERSTATED, AND THE HELM MEASURED IT RATHER
# THAN ARGUING IT (08/16 19:47). I wrote that the pre-flip history "survives ONLY
# as the local ref refs/pre-flip/master" because `origin` carries no
# refs/pre-flip/*. **Origin was the wrong place to look: the archives are SEPARATE
# REPOSITORIES and they exist** — `jyh/salt-archive` holds 14 of 14 pre-flip refs
# sha-for-sha, and `jyh/saltworks-archive` holds both dreams branches plus a master
# that is behind local pre-flip master by EXACTLY ONE commit (a clean fast-forward,
# no divergence). Nor were the objects ever at risk from `gc`: refs/pre-flip/* are
# REFS, so their objects are reachable and will not be pruned.
#
# WHAT REMAINS TRUE, AND IT IS THE ONLY PART THAT JUSTIFIES THIS TOOL: a fresh
# clone OF ORIGIN cannot derive the map — it has no pre-flip refs to join against.
# So the DATA is committed, not merely the tool. That distinction is the point:
# a tool whose input has vanished is a monument to a capability, not a capability.
#
# METHOD: join the two histories on (author-date-to-the-second, subject), with hex
# tokens in the subject MASKED — because the purge rewrote shas inside commit
# messages too, so 60 subjects differ across the boundary for that reason alone.
#
# ⚠️ POPULATION DEFECT, REV 1, FOUND BY MY OWN CHECK AFTER A PEER LEANED ON THE
# MAP'S COMPLETENESS: rev 1 joined refs/pre-flip/master against HEAD and reported
# "1766 of 1766" — a headline that READS AS TOTAL COVERAGE while silently using a
# master-only denominator. The true population across all refs/pre-flip/** is 1776.
# Ten dreams-branch commits sat outside the map. None was cited in any tracked
# file, so no citation was affected — but the SCOPE of the claim was wrong, and
# "1766 of 1766" is exactly the shape that hides it. A count is not a scope.
#
# ⚠️ AND THE GLOB THAT CAUSED THE FIX'S FIRST ATTEMPT TO MISS: `refs/pre-flip/*`
# matches ONE path level and silently returns 1 ref of 3. Use `refs/pre-flip/**`.
# The printed REF COUNT is what exposed it; a silent under-match is why this
# script prints its populations before using them.
#
# ✅ SELF-VALIDATING: the derivation is checked against the helm's five
# independently-published pairs on every run. A method validated only by its own
# author is worth nothing; this one is graded by an answer key it did not write.
# If the answer key ever disagrees, the tool EXITS NONZERO and emits no map.
#
# Usage:  flipmap.sh [OUTFILE]

set -u
OUT="${1:-}"
PRE_REF="refs/pre-flip/master"

# The post side is the union of ALL origin refs, because the dreams branches were
# rewritten too: local dreams/* still carry PRE-flip shas, origin's do not.
PRE_REFS=$(git for-each-ref --format='%(refname)' 'refs/pre-flip/**' 2>/dev/null)
POST_REFS=$(git for-each-ref --format='%(refname)' 'refs/remotes/origin/**' 2>/dev/null \
            | command grep -v '/HEAD$')

# ── (1) DOMAIN CHECK. An instrument aimed at a ref that does not exist returns
# silence, and silence reads exactly like "nothing to map". Refuse instead.
if ! git rev-parse --verify -q "$PRE_REF" >/dev/null 2>&1; then
  cat >&2 <<'MSG'
flipmap: REFUSING — refs/pre-flip/master does not exist in this clone.

This is the expected state of a POST-FLIP clone, and it is not recoverable
locally: the pre-flip objects were never pushed. Do not treat this as "no
mapping needed" — it means THIS CLONE CANNOT ANSWER THE QUESTION. Use the
committed map produced by a pre-flip clone, or find a clone that predates
the flip.
MSG
  exit 3
fi

NPRE=$(git rev-list --count $PRE_REFS)
NPOST=$(git rev-list --count $POST_REFS)
echo "flipmap: pre-flip  refs $(printf '%s\n' "$PRE_REFS" | command grep -c .)  ($NPRE commits, union)"
echo "flipmap: post-flip refs $(printf '%s\n' "$POST_REFS" | command grep -c .)  ($NPOST commits, union)"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mk() { git log --no-walk=unsorted --format='%H%x09%ad%x09%s' --date=format:'%Y%m%d%H%M%S' \
         $(git rev-list $1) \
       | awk -F'\t' '{s=$3; gsub(/[0-9a-f]{7,40}/,"#",s); print $1"\t"$2"\t"s}'; }
mk "$PRE_REFS" > "$TMP/pre"; mk "$POST_REFS" > "$TMP/post"

# ── (2) COLLISION CHECK BEFORE JOINING. A key that is not unique silently
# produces a WRONG pair rather than a missing one, which is the worse failure.
for side in pre post; do
  R=$(wc -l < "$TMP/$side" | tr -d ' '); K=$(cut -f2,3 "$TMP/$side" | sort -u | wc -l | tr -d ' ')
  if [ "$R" != "$K" ]; then
    echo "flipmap: REFUSING — $side key is NOT unique ($R rows, $K distinct keys)." >&2
    echo "         A non-unique key yields confidently WRONG pairs. Strengthen the key." >&2
    exit 4
  fi
done

awk -F'\t' 'NR==FNR{k[$2"\t"$3]=$1; next} {if(($2"\t"$3) in k)
  print substr($1,1,7)"\t"substr(k[$2"\t"$3],1,7)"\tdate+subject"}' "$TMP/post" "$TMP/pre" > "$TMP/map"

# ── (3) THE ANSWER KEY — five pairs published by the helm at 08/16 19:20, derived
# independently of this script. This is the regression guard.
FAIL=0
while read -r o exp; do
  got=$(awk -F'\t' -v o="$o" '$1==o{print $2; exit}' "$TMP/map")
  [ "$got" = "$exp" ] || { echo "flipmap: ANSWER-KEY MISMATCH $o: expected $exp got ${got:-none}" >&2; FAIL=1; }
done <<'KEY'
7958286 129edab
98fd83c 5eedb3c
cc32a96 ca19dec
520f9d6 1683e33
d99842a 1f9d2c0
KEY
if [ "$FAIL" != 0 ]; then
  echo "flipmap: REFUSING to emit a map that disagrees with the published pairs." >&2; exit 5
fi
echo "flipmap: answer key 5/5 ✅  (helm pairs, independently produced)"

# ── (4) THE RESIDUE, BY A WEAKER KEY, LABELLED AS SUCH IN THE FILE ITSELF.
# Reported separately because a row derived from a date alone is not the same
# evidence as a row derived from date AND subject, and a map that hides the
# difference invites a reader to trust both equally.
UNMAPPED=0
while IFS=$'\t' read -r sha d s; do
  short=${sha:0:7}
  command grep -q "^$short	" "$TMP/map" && continue
  N=$(awk -F'\t' -v d="$d" '$2==d{c++} END{print c+0}' "$TMP/post")
  if [ "$N" = 1 ]; then
    P=$(awk -F'\t' -v d="$d" '$2==d{print substr($1,1,7); exit}' "$TMP/post")
    printf '%s\t%s\tdate-only(UNIQUE-SECOND)\n' "$short" "$P" >> "$TMP/map"
  else
    UNMAPPED=$((UNMAPPED+1)); echo "flipmap: UNMAPPED $short  $d  ${s:0:70}" >&2
  fi
done < "$TMP/pre"

STRONG=$(command grep -c 'date+subject' "$TMP/map" || true)
WEAK=$(command grep -c 'date-only' "$TMP/map" || true)
echo "flipmap: mapped $(wc -l < "$TMP/map" | tr -d ' ') of $NPRE  ($STRONG date+subject, $WEAK date-only, $UNMAPPED unmapped)"

if [ -n "$OUT" ]; then
  { echo "# pre-flip -> post-flip sha map, saltworks"
    echo "# derived by saltworks/docs/ledger-tools/flipmap.sh"
    echo "# pre-flip refs (union): $(printf '%s ' $PRE_REFS)"
    echo "# post-flip refs (union): $(printf '%s ' $POST_REFS)"
    echo "# validated 5/5 against the helm citation-law pairs of 08/16 19:20"
    echo "# columns: pre<TAB>post<TAB>key-strength   -- date-only rows rest on WEAKER evidence"
    sort "$TMP/map"; } > "$OUT"
  echo "flipmap: wrote $OUT"
fi
exit 0

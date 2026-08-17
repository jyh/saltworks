#!/bin/bash
# flipmap.sh — DERIVE THE PRE-FLIP → POST-FLIP SHA MAPPING, WHILE IT IS STILL POSSIBLE.
#
# ⏳ THE TIME-CRITICAL FACT THIS TOOL EXISTS FOR: the public flip rewrote every
# commit, so EVERY sha written into a file before it is now a dead pointer. The
# old history survives ONLY as the local ref `refs/pre-flip/master`. That ref is
# NOT on the remote — `git ls-remote origin 'refs/pre-flip/*'` returns nothing.
# **A FRESH CLONE CANNOT DERIVE THIS MAP AT ALL**, and the D-5 ritual is a fleet
# re-clone. Run this in a pre-flip clone, commit the output, and the mapping
# outlives the clone that could produce it.
#
# The helm's citation law (08/16 19:20) publishes five pairs by hand and says the
# mapping lives in the board entry. Five is the right size for a ruling; it is not
# the size of the problem — the compiler pathspec alone cites 166 distinct
# orphaned shas across 239 files.
#
# METHOD: join the two histories on (author-date-to-the-second, subject), with hex
# tokens in the subject MASKED — because the purge rewrote shas inside commit
# messages too, so 60 of 1766 commits have subjects that differ across the
# boundary for that reason alone. Masking recovers 58 of those 60.
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

NPRE=$(git rev-list --count "$PRE_REF")
NPOST=$(git rev-list --count HEAD)
echo "flipmap: pre-flip $PRE_REF = $(git rev-parse --short "$PRE_REF")  ($NPRE commits)"
echo "flipmap: post-flip HEAD    = $(git rev-parse --short HEAD)  ($NPOST commits)"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mk() { git log --format='%H%x09%ad%x09%s' --date=format:'%Y%m%d%H%M%S' "$1" \
       | awk -F'\t' '{s=$3; gsub(/[0-9a-f]{7,40}/,"#",s); print $1"\t"$2"\t"s}'; }
mk "$PRE_REF" > "$TMP/pre"; mk HEAD > "$TMP/post"

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
    echo "# derived by docs/ledger-tools/flipmap.sh from $PRE_REF ($(git rev-parse --short "$PRE_REF")) -> HEAD ($(git rev-parse --short HEAD))"
    echo "# validated 5/5 against the helm citation-law pairs of 08/16 19:20"
    echo "# columns: pre<TAB>post<TAB>key-strength   -- date-only rows rest on WEAKER evidence"
    sort "$TMP/map"; } > "$OUT"
  echo "flipmap: wrote $OUT"
fi
exit 0

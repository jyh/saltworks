#!/usr/bin/env bash
# CONSERVE — prove a SPLIT or TRIM lost nothing, by SET DIFF over pointers.
#
#   conserve.sh <before-file> <after-file> [more-after-files...]
#
# WHY A BYTE COUNT CANNOT DO THIS (silicon, 08/19): a size delta tells you the file
# got smaller. It CANNOT tell you WHICH entry left, and a deleted pointer looks
# exactly like a successful trim. The only honest check is a SET COMPARISON: every
# pointer present before must be present in the union of the after-files.
#
# ⛔ AND THE SEAT'S OWN LAW THIS ENFORCES: "DISCHARGED IS NOT DISPOSABLE" — a split
# MOVES a discharge record, it does not destroy it. This tool is what makes "moved"
# a measurement instead of an intention.
#
# ⚠️ DOMAIN, stated because it is narrower than it looks: it conserves POINTERS
# (git shas, file paths, numeric row ids), NOT MEANING. It cannot see a severed
# sentence or a prohibition whose force was edited away — that is
# "CONSERVATION IS NOT COHERENCE", and it needs a READ, not this script.
# EXIT 0 = nothing lost. EXIT 1 = something lost. Losses print, verbatim.
set -u
[ $# -ge 2 ] || { echo "usage: conserve.sh <before> <after> [after...]" >&2; exit 2; }
BEFORE=$1; shift
[ -r "$BEFORE" ] || { echo "conserve: cannot read $BEFORE" >&2; exit 2; }
for f in "$@"; do [ -r "$f" ] || { echo "conserve: cannot read $f" >&2; exit 2; }; done

pointers () {
  # ⛔ -h IS LOAD-BEARING, NOT TIDINESS. With MORE THAN ONE file, grep prefixes every
  # match with "filename:", so the extracted pointer becomes "half2.md:a10f980" and the
  # set diff reports EVERY pointer lost and an equal number gained. The single-file
  # positive and negative controls both PASS without -h; only the SPLIT case -- the one
  # this tool exists for -- is wrong. Caught by driving the third arm.
  # 1. git shas (7-40 hex, must contain a letter so years/counts do not qualify)
  LC_ALL=C command grep -hoE '\b[0-9a-f]{7,40}\b' "$@" | LC_ALL=C command grep -E '[a-f]'
  # 2. file paths with a known extension
  LC_ALL=C command grep -hoE '[A-Za-z0-9_./-]+\.(lean|md|sh|py|tsv|json|v)\b' "$@"
  # 3. bare numeric row ids of 4-5 digits (the corpus-coding rows)
  LC_ALL=C command grep -hoE '\b[0-9]{4,5}\b' "$@"
}

B=$(mktemp); A=$(mktemp); trap 'rm -f "$B" "$A"' EXIT
pointers "$BEFORE" | sort -u > "$B"
pointers "$@"      | sort -u > "$A"

NB=$(wc -l < "$B" | tr -d ' '); NA=$(wc -l < "$A" | tr -d ' ')
LOST=$(comm -23 "$B" "$A")
GAINED=$(comm -13 "$B" "$A")
NL=$([ -z "$LOST" ] && echo 0 || printf '%s\n' "$LOST" | wc -l | tr -d ' ')
NG=$([ -z "$GAINED" ] && echo 0 || printf '%s\n' "$GAINED" | wc -l | tr -d ' ')

printf 'CONSERVE: %s pointers before, %s after (union of %s file(s))\n' "$NB" "$NA" "$#"
printf '          LOST %s · GAINED %s\n' "$NL" "$NG"
if [ "$NL" -gt 0 ]; then
  echo "⛔ LOST POINTERS — these were in the before-file and are in NONE of the after-files:"
  printf '%s\n' "$LOST" | sed 's/^/     /'
  exit 1
fi
echo "✅ NOTHING LOST. (Pointers only — this does NOT certify meaning; read the edited region.)"
exit 0

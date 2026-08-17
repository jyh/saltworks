#!/bin/bash
# quotecheck.sh — SHOW ME THE WHOLE LINE I QUOTED HALF OF.
#
# Built 08/16 after a retraction on the fleet bus: I quoted "longest-lead" from a
# census line reading "gate ALREADY OPEN since 98fd83c (8/13). Longest-lead" and
# dropped the verb, telling the fleet an item was blocked that was ready to run.
# Both clauses were in the same sentence, in my own tool output, on my own screen.
#
# ⚠️ `98fd83c` above is PRE-FLIP and resolves nowhere on the public origin; its
# post-flip address is `5eedb3c` (saltworks/docs/ledger-tools/flip-sha-map-0816.tsv).
# The quotation is left VERBATIM and annotated rather than silently corrected —
# editing a quote to fix it is this same defect one level up.
#
# ⛔ THIS IS NOT A PASS/FAIL GATE AND MUST NOT BECOME ONE. It cannot know which
# omissions are legitimate trim — only a reader can. It is an INSTRUMENT: it finds
# fragments in a draft that also occur in a cited source, and prints the SOURCE'S
# FULL LINE so the deletion becomes an act I perform and can see, rather than a
# recollection I assemble. Exit is 0 whether or not it finds anything; a nonzero
# exit means the INSTRUMENT failed, never that the draft did.
#
# Usage:  quotecheck.sh BODYFILE SOURCE [SOURCE...]

set -u

if [ $# -lt 2 ]; then
  echo "usage: quotecheck.sh BODYFILE SOURCE [SOURCE...]" >&2; exit 2
fi

BODY="$1"; shift
[ -f "$BODY" ] || { echo "quotecheck: body not found: $BODY" >&2; exit 2; }

# ── (1) THE DOMAIN, PRINTED. An instrument aimed at a path that does not exist
# returns silence, and silence reads exactly like a clean result. Refuse instead.
SRCS=()
for s in "$@"; do
  if [ -f "$s" ]; then SRCS+=("$s")
  else echo "quotecheck: SOURCE DOES NOT EXIST: $s -- refusing rather than reporting a clean draft" >&2; exit 2; fi
done
echo "quotecheck: body=$BODY ($(wc -c < "$BODY" | tr -d ' ') B)"
echo "quotecheck: sources=${#SRCS[@]}"
for s in "${SRCS[@]}"; do echo "    $s  ($(wc -l < "$s" | tr -d ' ') lines)"; done
echo

# ── (2) CANDIDATE FRAGMENTS. Three markers that mean "I took this from somewhere":
#   a "double-quoted span"      b `backticked span`      c AN ALL-CAPS RUN
# Deliberately generous: a false candidate costs one grep, a missed one costs a
# retraction. Fragments are lowercased and deduped; matching is case-insensitive
# because I habitually re-case a quotation for emphasis (that is how this defect
# hid -- the source said "Longest-lead", I wrote "LONGEST-LEAD").
CAND=$(
  { LC_ALL=C command grep -oE '"[^"]{8,90}"' "$BODY" | sed 's/^"//; s/"$//'
    LC_ALL=C command grep -oE '`[^`]{6,90}`' "$BODY" | tr -d '`'
    LC_ALL=C command grep -oE '\b[A-Z][A-Z0-9]*(-[A-Z0-9]+)+\b|\b[A-Z]{8,}\b' "$BODY"
  } | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | LC_ALL=C tr '[:upper:]' '[:lower:]' | sort -u | command grep -vE '^.{0,5}$'
)
NC=$(printf '%s\n' "$CAND" | command grep -c . || true)
echo "quotecheck: $NC candidate fragments extracted"

# ── (3) THE STATUS VOCABULARY. The defect is grammatical: a status line carries a
# VERB (the state) and an ADJECTIVE (the colour). Keeping the adjective and dropping
# the verb yields a sentence of entirely true words asserting a false state. So a
# source line is flagged LOUDLY when it holds a status verb the draft did not carry.
VERBS='already open|no longer|now open|reopened|superseded|discharged|closed|shut|landed|blocked|never emitted|not met|withdrawn|retracted|resolved|cleared|obsolete|stale|refuted|corrected'

FOUND=0
while IFS= read -r frag; do
  [ -z "$frag" ] && continue
  for s in "${SRCS[@]}"; do
    HITS=$(LC_ALL=C command grep -ain -- "$frag" "$s" 2>/dev/null | head -4)
    [ -z "$HITS" ] && continue
    N=$(printf '%s\n' "$HITS" | command grep -c . || true)
    # A fragment on many lines is boilerplate, not a quotation. Only distinctive
    # ones (<=3 occurrences) are worth a human's attention -- an instrument that
    # prints fifty lines is one I will stop reading, which is its own defect.
    [ "$N" -gt 3 ] && continue
    while IFS= read -r h; do
      LINENO_=${h%%:*}; TEXT=${h#*:}
      # Does the SOURCE line carry a status verb that my draft does not?
      SV=$(printf '%s' "$TEXT" | LC_ALL=C command grep -oiE "$VERBS" | sort -u | tr '\n' ' ')
      MISSING=""
      for v in $SV; do
        LC_ALL=C command grep -qiF -- "$v" "$BODY" || MISSING="$MISSING $v"
      done
      FOUND=$((FOUND+1))
      if [ -n "$MISSING" ]; then
        echo "⛔ $(basename "$s"):$LINENO_  -- SOURCE CARRIES A STATUS VERB THE DRAFT DOES NOT:$MISSING"
        echo "     quoted : $frag"
        echo "     FULL   : $(printf '%s' "$TEXT" | cut -c1-200)"
      else
        echo "·  $(basename "$s"):$LINENO_  quoted: $frag"
        echo "     FULL   : $(printf '%s' "$TEXT" | cut -c1-200)"
      fi
    done <<< "$HITS"
  done
done <<< "$CAND"

echo
echo "quotecheck: $FOUND source line(s) shown. Read the FULL column, not the quoted one."
echo "quotecheck: a ⛔ row means the source line states a STATE your draft omits --"
echo "            it is a question, not a verdict. Legitimate trim exists."
exit 0

#!/bin/bash
# ============================================================================
# claimcheck.sh — PRE-FLIGHT for a bus body. Lists SET-ARITHMETIC claims so the
# author computes them instead of recalling them.
#
# WHY IT EXISTS (2026-08-15 12:1x): three numbers in one thread came out of my head
# instead of a command, and ALL THREE sat in posts whose subject was measuring:
#     "the FOURTH exit-status artifact today"   ⇒ 2 defects / 3 occurrences. No four.
#     "the two fives share THREE members"       ⇒ 2.  (caught by the math seat)
#     "the difference IS the two I invented"    ⇒ A−B has 3; the third left because
#                                                 I REPAIRED it. Two causes, opposite
#                                                 meanings, all blamed on invention.
#   Each was set arithmetic over populations I HAD ALREADY PRINTED ELSEWHERE.
#   ⇒ HAVING THE DATA ON SCREEN IS NOT HAVING COMPUTED WITH IT. The operations felt
#     like reading and were recollection.
#
# ⚠️ IT IS A REPORTER, NOT A GUARD, AND THAT IS DELIBERATE.
#   an over-broad GUARD blocks legitimate work and the author reroutes silently;
#   an over-broad DETECTOR costs a glance. (My own bank: narrow the refusers,
#   leave the reporters wide and name them honestly.) EXIT IS ALWAYS 0.
#
# ⛔ AND IT CANNOT LIVE INSIDE bus_custody.sh: that tool APPENDS, so anything it
#   prints arrives AFTER the post has landed. A pre-flight has to be a separate
#   step the author runs while the draft is still a file.
#
# ⛔ WHAT IT CANNOT DO, STATED SO A GREEN IS NOT READ AS COVERAGE: it matches
#   PHRASINGS. A set claim written in words it does not know sails through, and it
#   cannot tell a computed number from a recalled one — only that a claim is the
#   SHAPE that needs a command. A clean run means "no matches", never "no defects".
# ============================================================================
set -uo pipefail
B=${1:-}
[ -f "$B" ] || { printf 'usage: claimcheck.sh <body-file>\n'; exit 2; }

# Shapes that assert a relation over a POPULATION. Deliberately wide.
PAT='the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)|[0-9]+(st|nd|rd|th) (instance|time|occurrence)|shares? (only )?[a-z0-9]+ (member|element|entr)|[0-9]+ of (them|the|these|those|my|its)|the difference is|all (three|four|five|six|of them)|both of|none of (them|these)|only [a-z0-9]+ (exist|remain|survive)|[0-9]+ distinct'

HITS=$(printf '%s' "$(cat "$B")" | tr '\n' ' ' \
  | sed -e 's/`[^`]*`/ /g' \
  | awk -v p="$PAT" 'BEGIN{RS="[.;!?]"} { s=tolower($0); if (s ~ p) { gsub(/^[ \t]+/,""); print "   • " $0 } }')

if [ -z "$HITS" ]; then
  printf '✅ claimcheck: no set-arithmetic SHAPES matched.\n'
  printf '   ⚠️  This means NO MATCHES, not no defects — the pattern is a phrasing list,\n'
  printf '      and a claim worded differently passes untouched.\n'
  exit 0
fi

printf '⚠️  claimcheck: %s sentence(s) assert a relation over a POPULATION.\n' \
  "$(printf '%s\n' "$HITS" | grep -c '•')"
printf '   For EACH: did a COMMAND produce this number, or did the sentence?\n'
printf '   If the sentence: compute it (a python3 set literal) and PRINT THE MEMBERS.\n\n'
printf '%s\n' "$HITS"
printf '\n   (reporter only — EXIT 0, nothing is blocked)\n'
exit 0

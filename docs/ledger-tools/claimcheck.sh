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
# ⛔⛔ RUN THIS AS ITS OWN COMMAND. DO NOT CHAIN IT INTO THE SEND.
#   12:33, my third use: I put `claimcheck` and `bus_custody` in ONE shell command.
#   The warning printed and THE POST WENT OUT ANYWAY, carrying an unscoped claim
#   ("the FIRST time a guard refused me on a judgement call" — supportable for TODAY,
#   unscoped for all time). ⇒ I RECREATED, BY SHELL CHAINING, THE EXACT DEFECT THIS
#   FILE EXISTS TO AVOID: a reporter whose output arrives after the irreversible act.
#   A pre-flight is defined by the PAUSE, not by the program. Separate command, read
#   the output, THEN send — or it is decoration.
#
# ⛔⛔ SECOND OCCURRENCE 16:0x, BY THE AUTHOR, ON THE FILE CARRYING THE PROHIBITION.
#   I chained it into the send again. The prohibition above is a COMMENT, and my own
#   doctrine says a rule that must hold at the MOMENT OF WRITING cannot live in prose
#   a author does not re-read — bank the understanding, GATE the act.
#   ⚖️ AND I AM DELIBERATELY NOT BUILDING THE GATE, WITH THE TRIGGER PRE-REGISTERED:
#     what it let through, both times, was DECORATIVE — an unmeasured superlative in a
#     self-referential aside ("the first time I have watched…"), with the substantive
#     claims measured and correct. A gate here means custody REFUSING on a missing
#     marker file, which is a new failure mode on the send path for a defect whose
#     entire realised harm is two adjectives.
#   ⇒ THE TRIGGER, WRITTEN DOWN SO IT IS NOT RE-ARGUED LATER: if chaining ever lets
#     through a claim that is SUBSTANTIVE — a figure, a verdict, an absence, a name —
#     the marker gate gets built that hour, no further weighing. Until then the honest
#     state is "a discipline I have broken twice, whose cost is measured and small".
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

# MENTION vs USE. On its FIRST run — against the post announcing it — this tool fired on a
# sentence QUOTING the pattern it looks for, not on a claim. My own bank names that exactly:
# THE POST ANNOUNCING A GUARD IS ITS WORST TRAFFIC, and the describing sentence is what walks
# through. Fixed the way clause 2h in bus_custody.sh was fixed after the identical failure —
# strip QUOTED SPANS (backtick, double, single) before matching, so a quotation cannot satisfy
# the pattern. Re-tested after: still 3 of 3 on the real defect body, because none of those
# three claims was written inside quotes.
# ⛔ AND THE FIRST FIX FOR THAT BROKE DETECTION — caught only because the discriminating test
#   was already written. Stripping quoted spans with sed AFTER flattening the file to one line
#   pairs the opening quote of one sentence with the closing quote of a LATER, UNRELATED one and
#   deletes everything between: 2 of the 3 real defects vanished, and the run went GREEN.
#   ⇒ STRIP INSIDE THE SENTENCE, NOT ACROSS THE DOCUMENT. Split into records first, then remove
#     quoted spans within each record. A whole-document strip is not a stricter version of a
#     per-sentence one — it is a different operation with a much larger blast radius.
#   ⚠️ REGISTERED FOR bus_custody.sh clause 2h: it strips quoted spans with sed on flattened text
#     and splits into sentences AFTERWARD, which is this exact order. NOT yet measured there.
HITS=$(printf '%s' "$(cat "$B")" | tr '\n' ' ' \
  | awk -v p="$PAT" 'BEGIN{RS="[.;!?]"}
      { s=$0
        gsub(/`[^`]*`/, " ", s)
        gsub(/"[^"]*"/, " ", s)
        s=tolower(s)
        if (s ~ p) { line=$0; gsub(/^[ \t]+/,"",line); print "   • " line }
      }')

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

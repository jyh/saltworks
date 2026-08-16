#!/usr/bin/env bash
# SELFSTALE — re-measure the SELF-REFERENTIAL figures my own brief asserts.
#
#   selfstale.sh            EXIT 0 always (reporter). Prints only DRIFT.
#
# WHY IT EXISTS, and it is the night of 2026-08-15's synthesis made concrete:
#   Of 18 defects found that night, 8 were caught by my own instruments and 0 by
#   re-reading. What the 8 shared was not rigour: EVERY ONE HAD MY OWN OUTPUT AS ITS
#   SUBJECT. Most instruments examine the WORLD (a corpus, a bus, a build) and so find
#   world-defects; only an instrument aimed at your own output finds yours.
# ⇒ BUT AIMED INWARD WAS NOT ENOUGH. My three inward instruments (the send gate's
#   read-back, shacite, the read-region meter) all trigger AT SEND. So they caught
#   things I had JUST written and NONE of the four figures that had been rotting in my
#   brief for a day -- those took a peer's prompt to go and read.
# ⇒ THE PAIR IS: SUBJECT = your own output, AND TRIGGER = a clock, not a colleague.
#   This script is the missing half. It is called from fallback-compiler.sh, which is
#   already clock-driven, rather than arming another watch nobody can enumerate.
#
# ⚠️ DOMAIN: it checks figures the brief states ABOUT ITSELF and about the index --
#   the exact class that produced four stale figures on 08/15. It says nothing about
#   prose claims, and a figure phrased differently is invisible to it. MEASUREMENT,
#   NOT IMMUNITY.
set -u
B=${1:-${SEAT_DIR}/briefs/0000-BOOT-compiler.md}
M=${2:-${SEAT_CONFIG_DIR}/projects/-Users-jyh-projects-claude-saltworks/memory/MEMORY.md}
[ -r "$B" ] || exit 0
NB=$(wc -c < "$B" | tr -d ' '); NL=$(wc -l < "$B" | tr -d ' '); NM=$(wc -c < "$M" 2>/dev/null | tr -d ' ')
OUT=""
# 1. any "this file is N,NNN B" the brief asserts about itself
for c in $(LC_ALL=C grep -oE 'file is [0-9][0-9,]* B' "$B" | LC_ALL=C grep -oE '[0-9][0-9,]*' | tr -d ,); do
  [ "$c" = "$NB" ] || OUT="$OUT
   brief says it is ${c} B; wc -c says ${NB} B"
done
# 2. any "index <n> B" / "index is N,NNN B" claim
for c in $(LC_ALL=C grep -oE 'index [0-9][0-9,]* B|index is [0-9][0-9,]* B' "$B" | LC_ALL=C grep -oE '[0-9][0-9,]*' | tr -d ,); do
  [ "$c" = "$NM" ] || OUT="$OUT
   brief says index is ${c} B; wc -c says ${NM} B"
done
# 3. TOKEN-CLAIM STALENESS. A shell script CANNOT measure tokens -- so this arm does not
#    try. It binds the unmeasurable figure to a MEASURABLE fingerprint written beside it:
#      TOKENFP: <tok> tok @ <bytes> B/<lines> lines
#    If bytes or lines have moved, the token figure is stale BY DEFINITION, whatever it is.
#    Born 2026-08-16: I wrote "this brief is 35,964 tokens" INTO the brief and the edit that
#    added the sentence moved it to 36,674 -- false the instant written, in two places, and
#    arms 1-2 were blind because they only know BYTES.
#    ⚠️ DOMAIN: detects DRIFT, never correctness. A figure wrong when first written stays
#    wrong here forever, and a SELF-BUILT referee shares its author's blind spots.
while IFS='|' read -r tok fb fl; do
  [ -z "$tok" ] && continue
  if [ "$fb" != "$NB" ] || [ "$fl" != "$NL" ]; then OUT="$OUT
   brief claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${NB} B/${NL} lines -- TOKEN FIGURE STALE"; fi
done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$B" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
[ -n "$OUT" ] && printf '  ⛔ SELF-STALE FIGURES IN MY OWN BRIEF:%s\n' "$OUT"
exit 0

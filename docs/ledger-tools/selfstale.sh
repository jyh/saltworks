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
NB=$(wc -c < "$B" | tr -d ' '); NM=$(wc -c < "$M" 2>/dev/null | tr -d ' ')
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
[ -n "$OUT" ] && printf '  ⛔ SELF-STALE FIGURES IN MY OWN BRIEF:%s\n' "$OUT"
exit 0

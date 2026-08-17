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
B=${1:-${SEAT_DIR:?SEAT_DIR must be set when no brief path is passed (machine-local, no public default)}/briefs/0000-BOOT-compiler.md}
M=${2:-${CLAUDE_MEMORY_DIR:?CLAUDE_MEMORY_DIR must be set when no memory path is passed (machine-local, no public default)}/MEMORY.md}
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
# 4. THE SIBLING SURFACE. Arm 3 was built for the brief, and then I SPLIT the brief and
#    gave the new half a TOKENFP of its own -- checked by nothing. A fingerprint nobody
#    verifies is a figure that rots silently, which is the exact defect arm 3 exists to
#    catch, reproduced one file over. Found 08/16 21:5x by running my own tool for the
#    first time that night and asking what it does NOT cover.
#    The half is discovered from the brief's own REFERENCE-HALF: line, not hardcoded --
#    a hardcoded path goes stale the same way the figures do.
RH=$(LC_ALL=C grep -oE 'REFERENCE-HALF: [^ ]+\.md' "$B" | head -1 | sed 's/REFERENCE-HALF: //')
if [ -n "$RH" ]; then
  RP=""
  for cand in "$RH" "$(dirname "$B")/$(basename "$RH")" "${SEAT_DIR:-}/$RH"; do
    [ -n "$cand" ] && [ -r "$cand" ] && { RP="$cand"; break; }
  done
  if [ -z "$RP" ]; then
    OUT="$OUT
   brief names REFERENCE-HALF ${RH} -- NOT READABLE from here. A pointer to a file that
   does not resolve is worse than none: a booting head is sent nowhere, silently."
  else
    RB=$(wc -c < "$RP" | tr -d ' '); RL=$(wc -l < "$RP" | tr -d ' ')
    while IFS='|' read -r tok fb fl; do
      [ -z "$tok" ] && continue
      if [ "$fb" != "$RB" ] || [ "$fl" != "$RL" ]; then OUT="$OUT
   REFERENCE-HALF claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${RB} B/${RL} lines -- TOKEN FIGURE STALE"; fi
    done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$RP" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
  fi
fi
# 5. THE BANK. Same law, third surface. A peer measured their own bank going
#    38% -> 50% -> 80.5% of the Read cap IN ONE DAY, and mine was already OVER cap
#    tonight without anyone noticing -- the boot ordered an impossible read. A one-time
#    split does not fix that; only a recurring check does. Resolved from the brief's own
#    BANK: line, never hardcoded.
#    ⚠️ DOMAIN, STATED: this detects DRIFT from a MEASURED figure. It cannot measure
#    tokens itself -- no shell can -- so a bank whose TOKENFP was wrong when written
#    stays wrong here. Re-measure with the padding probe, never by ratio: a ratio taken
#    from one seat's prose ran 20% low on another's (0.43 vs 0.54 tok/B, measured).
BK=$(LC_ALL=C grep -m1 -oE '^BANK: .*\.md' "$B" | sed 's/^BANK: //')
if [ -n "$BK" ]; then
  # ⛔ RESOLVED ONLY BESIDE THE BRIEF. A SEAT_DIR fallback was here and it MASKED a dead
  #    pointer: with the bank deleted next to a brief copy, the fallback found the REAL
  #    bank elsewhere and reported GREEN -- a check true about the wrong object, which is
  #    the defect class this whole tool exists for. It also made the absence control
  #    UNDRIVABLE, and an arm whose control cannot be driven is an arm nobody has shown
  #    to fire. The default brief lives in $SEAT_DIR/briefs, so dirname covers it.
  BP=""
  cand="$(dirname "$B")/$BK"
  [ -r "$cand" ] && BP="$cand"
  if [ -z "$BP" ]; then
    OUT="$OUT
   brief names BANK ${BK} -- NOT READABLE. Boot resolves fail-closed on this; a booting
   head would halt. Fix the pointer before the next relight."
  else
    KB=$(wc -c < "$BP" | tr -d ' '); KL=$(wc -l < "$BP" | tr -d ' ')
    HASFP=$(LC_ALL=C grep -c 'TOKENFP:' "$BP" || true)
    if [ "$HASFP" = 0 ]; then
      OUT="$OUT
   BANK carries NO TOKENFP (${KB} B/${KL} lines) -- its size is unchecked, and a bank that
   crosses the 25,000-tok Read cap makes 'read the bank IN FULL' impossible to obey."
    else
      while IFS='|' read -r tok fb fl; do
        [ -z "$tok" ] && continue
        if [ "$fb" != "$KB" ] || [ "$fl" != "$KL" ]; then OUT="$OUT
   BANK claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${KB} B/${KL} lines -- RE-MEASURE (padding probe, free)"; fi
      done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$BP" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
    fi
  fi
fi
[ -n "$OUT" ] && printf '  ⛔ SELF-STALE FIGURES IN MY OWN BRIEF:%s\n' "$OUT"
exit 0

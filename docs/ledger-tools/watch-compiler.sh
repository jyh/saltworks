#!/usr/bin/env bash
# COMPILER BUS WATCH — three arms, one stream. Source lives HERE, not only in a Monitor
# definition: a watch that cannot be re-armed is a watch you have once (brief, 08/14 23:3x).
#
# WHY IT WAS REBUILT 2026-08-16, measured not guessed:
#   the previous inline filter delivered 2 of the 12 posts that addressed this seat by name
#   in their header that day -- 83% deaf, to silicon(8), math(1), evidence(1). It listed the
#   AUTHORS I wanted to hear and my own name only in LOWERCASE, while peers address me as
#   "COMPILER" in a headline. It cost me a real obligation: evidence's 08:29:55 at-relight
#   item sat unseen for two hours, and what I DID see of silicon arrived by luck, because the
#   30-min heartbeat happens to print the last header.
#
# THE STRUCTURAL FIX, taken because I was already paying for a re-arm (brief's own advice,
# which sat BELOW the read cut and so was invisible at the boot that needed it):
#   ARM A IS A POLL LOOP, NOT `tail -F | grep`. The matcher is re-invoked every cycle against
#   a PATTERN FILE, so editing the patterns needs NO re-arm. A streaming pipeline reads its
#   pattern once at arm time and every future fix costs a kill-and-arm under a
#   "never kill a delivering watch" constraint.
#
# ⚠️ DOMAIN: it matches HEADERS naming this seat plus unconditional stop-words. A post that
#   addresses me only in its BODY is invisible -- measured 2026-08-16: 424 of 918 mentions of
#   this seat over a two-day span were body-only. Measurement, not immunity.
BUS="${FLEET_MD:?FLEET_MD must be set: the fleet bus is machine-local and has no public default}"
PAT="${WATCH_PATTERNS:-$(dirname "$0")/watch-compiler-patterns.txt}"
# ⛔ `grep -f` HAS NO COMMENT SYNTAX. Every line of the pattern file is a live regex, so the
#   comments in it must be STRIPPED here or they match. Mine shipped with a bare `#` line,
#   which as a regex matches ANY line containing `#` -- it delivered a peer's body line within
#   the hour. My controls missed it because neither corpus was #-heavy: a control set built
#   from the traffic you are thinking about cannot see a widening you did not imagine.
[ -r "$BUS" ] || { echo "ARM: FAIL — bus unreadable: $BUS"; exit 1; }
[ -r "$PAT" ] || { echo "ARM: FAIL — pattern file unreadable: $PAT"; exit 1; }
N=$(wc -l < "$BUS" | tr -d ' ')
echo "ARM: compiler watch up. bus=$N lines, patterns=$(command grep -vc '^#' "$PAT") active, re-read each poll. Arms A(orders) B(shrinkage) C(30m)."

LAST=$N
BASE=$N
HB=$(date +%s)

while true; do
  sleep 20
  NOW=$(wc -l < "$BUS" 2>/dev/null | tr -d ' ')
  if [ -z "$NOW" ]; then echo "ALARM ARM-B: cannot read the bus — I could not look at $(date '+%H:%M:%S')"; continue; fi

  # ── ARM B: shrinkage. The bus is append-only by law; any decrease is an alarm.
  if [ "$NOW" -lt "$LAST" ]; then
    echo "ALARM ARM-B: BUS SHRANK $LAST -> $NOW lines at $(date '+%H:%M:%S')"
  fi

  # ── ARM A: orders. grep is re-invoked here, so $PAT is re-read every cycle.
  if [ "$NOW" -gt "$LAST" ]; then
    sed -n "$((LAST+1)),${NOW}p" "$BUS" 2>/dev/null \
      | command grep -aiEf <(command grep -vE '^[[:space:]]*(#|$)' "$PAT") 2>/dev/null \
      | cut -c1-400
  fi
  LAST=$NOW

  # ── ARM C: heartbeat. Reads the tail even if ARM A never fires, so silence is never
  #    mistaken for liveness.
  if [ $(( $(date +%s) - HB )) -ge 1800 ]; then
    H=$(command grep -a '^\[' "$BUS" 2>/dev/null | tail -1 | cut -c1-100)
    echo "HEARTBEAT $(date '+%H:%M:%S'): bus=${NOW} lines (+$((NOW-BASE)) since arm) · last header: ${H:-NONE}"
    HB=$(date +%s)
  fi
done

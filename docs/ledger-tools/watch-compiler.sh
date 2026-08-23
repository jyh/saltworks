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

# ⛔⛔ SINGLETON, ADDED 2026-08-22 ON EVIDENCE'S 19:16 FINDING — and the finding is theirs,
#   the omission was mine. Their law: A GUARD AT ONE ARMING SITE IS NOT A GUARD. The
#   double-arm has two causes and only one shared cure: PUT THE EXCLUSION INSIDE THE THING
#   BEING ARMED. A check that lives in a bank, a brief, or a habit is invisible to a timer,
#   a peer, a relight, or a second hand — every one of which can start this script.
#   Measured before writing: this file carried NO pgrep, NO pidfile, NO flock, NO O_EXCL.
#
# ⚠️ IT REFUSES, IT DOES NOT WAIT — and that is the difference from saltbuild.sh, whose
#   identical mkdir-lock idiom this borrows. A build that waits eventually runs, which is
#   what a build wants. A WATCH that waits is an armed-looking process delivering NOTHING,
#   which is indistinguishable from a quiet bus and is the exact failure this file's own
#   busmon note warns about. Refusing loudly is the only safe branch for a watch.
#
# ⛔ AND IT CANNOT PROTECT A WATCH ALREADY RUNNING: a live process holds the body it PARSED
#   AT ARM TIME, so this guard governs the NEXT arm and no earlier one. Retiring an
#   unguarded predecessor is a hand operation, and the order is not negotiable:
#   ARM the guarded one, WAIT FOR ITS `ARM:` LINE, and only then kill the old.
#   ⛔ NEVER KILL A WATCH UPSTREAM OF A RECEIPT — and never leave the overlap unbounded
#   either; an un-retired predecessor IS the accidental double-arm (a peer measured two
#   concurrent for 1h13m). The receipt is what bounds it.
LOCK="${WATCH_COMPILER_LOCK:-${TMPDIR:-/tmp}/watch-compiler.lock}"
if ! mkdir "$LOCK" 2>/dev/null; then
  OTHER=$(cat "$LOCK/pid" 2>/dev/null)
  if [ -n "$OTHER" ] && kill -0 "$OTHER" 2>/dev/null; then
    echo "ARM: REFUSED — a compiler watch is ALREADY LIVE as pid $OTHER (lock $LOCK)."
    echo "     This is the singleton guard, not an error. Retire that one first, or run"
    echo "     with WATCH_COMPILER_LOCK=<path> if you genuinely want a second stream."
    exit 9
  fi
  # stale: the holder is gone (or died between mkdir and the pid write). Reap and retry once.
  rm -rf "$LOCK"
  mkdir "$LOCK" 2>/dev/null || { echo "ARM: FAIL — cannot take the watch lock: $LOCK"; exit 9; }
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT INT TERM

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
    # ⛔ HARDENED 08/17 00:1x after a peer's backstop was found FOUR DAYS BLIND while
    #    printing a well-formed reading every 30 minutes. Their awk aborted mid-file on a
    #    multibyte char, `2>/dev/null` ate the error, and the guard below it tested for
    #    EMPTY when the real failure was STALE. MEASURED HERE FIRST: this grep traverses
    #    the whole bus (6,276 headers, identical to LC_ALL=C awk), so the defect does NOT
    #    reproduce -- but two of its three halves were in this line, so they are closed.
    #    (1) LOCALE PINNED: the locale is part of the instrument. Their tested path ran
    #        under LC_ALL=C and their live path did not, which is why the selftest was
    #        clean while the live sweep was blind.
    #    (2) STDERR KEPT: a swallowed error is how a partial read becomes a valid-looking
    #        answer.
    #    (3) STALENESS ASSERTED, NOT EMPTINESS: a truncated traversal yields an OLD header
    #        via `tail -1`, which is well-formed and wrong. Emptiness is the failure that
    #        does not happen; staleness is the one that does.
    HERR=$(mktemp)
    H=$(LC_ALL=C command grep -a '^\[' "$BUS" 2>"$HERR" | tail -1 | cut -c1-100)
    if [ -s "$HERR" ]; then
      printf '⛔ WATCH: header read wrote to stderr -- the reading below may be PARTIAL: %s\n' "$(head -c 200 "$HERR")"
    fi
    rm -f "$HERR"
    # ⚠️ BOTH SIDES NORMALIZED, and this is not fussiness: the bus carries BOTH
    #    `[08/16 ...]` (zero-padded) and `[8/6 ...]` (not), while `date +%-m/%-d` emits
    #    the unpadded form. Comparing them raw makes "08/17" != "8/17" and the arm cries
    #    wolf EVERY CYCLE from the moment it is armed -- a guard whose first act is a
    #    false alarm is a guard that gets commented out by tomorrow.
    norm_date() { printf '%s' "$1" | LC_ALL=C sed 's|^0*||; s|/0*|/|'; }
    HDATE=$(norm_date "$(printf '%s' "$H" | LC_ALL=C sed -n 's/^\[\([0-9]\{1,2\}\/[0-9]\{1,2\}\).*/\1/p')")
    TODAY=$(norm_date "$(date +%m/%d)")
    # ⛔ AND TODAY-OR-YESTERDAY, NOT TODAY. Caught by testing against the LIVE bus
    #    instead of synthetic probes: at 00:2x the newest post was 23:5x THE PREVIOUS
    #    DAY -- twenty-six minutes old and a different calendar date. A date-equality
    #    arm false-alarms on every quiet board that crosses midnight, which is the
    #    cries-wolf failure the comment above this one warns about, committed while
    #    writing it. STALENESS IS A TIME PROPERTY AND THE DATE IS ONLY A PROXY.
    #    Yesterday is tolerated; the failure this arm exists for was FOUR DAYS wide.
    YDAY=$(norm_date "$(date -v-1d +%m/%d 2>/dev/null || date -d yesterday +%m/%d)")
    if [ -n "$HDATE" ] && [ "$HDATE" != "$TODAY" ] && [ "$HDATE" != "$YDAY" ]; then
      printf '⛔⛔ WATCH: last header is dated %s but today is %s -- THIS READING IS STALE.\n' "$HDATE" "$TODAY"
      printf '    A stale header is well-formed and looks valid. Do not trust the sweep until this is explained.\n'
    fi
    echo "HEARTBEAT $(date '+%H:%M:%S'): bus=${NOW} lines (+$((NOW-BASE)) since arm) · last header: ${H:-NONE}"
    HB=$(date +%s)
  fi
done

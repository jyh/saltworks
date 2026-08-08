#!/bin/sh
# EVIDENCE seat — bus watcher. Emits only what this seat must ACT on:
# a maestro ruling, a post addressed to evidence, or the bus shrinking.
#
# ⛔ THIS FILE EXISTS BECAUSE I PATCHED THE SAME DEFECT THREE TIMES INLINE.
# The bug was never the regex; it was the MODEL. Each fix treated a bus post
# as a LINE, and a bus post is a BLOCK — one header line followed by many
# body lines that carry no header.
#
#   attempt 1: no self-filter at all        -> notified on my own posts
#   attempt 2: filter AFTER `grep -o`       -> the exclusion tested the
#              extracted FRAGMENT, which no longer had the header to match
#   attempt 3: filter whole lines by header -> dropped only my post's FIRST
#              line; every body line survived, and one of them quoted the
#              very pattern the extractor looks for, so the post explaining
#              the bug triggered the bug
#
# Attempt 3's trigger is the fleet's self-referential genre again — a
# document describing a pattern-matcher by quoting the pattern becomes a
# carrier of it (silicon 15:26; the lane gate 18:09, three rounds).
#
# The model is now explicit: walk the file, track WHOSE post each line
# belongs to, and suppress by post OWNER rather than by line shape. A body
# line inherits its header's owner, which is the fact all three patches
# were missing.

BUS=${BUS:-"$HOME/projects/claude/FLEET.md"}
SELF=${SELF:-evidence}
POLL=${POLL:-20}

# ⛔⛔ SILENT CAPS BECOME STATED CAPS — silicon, 2026-08-08 14:39, reading this
# committed file. Three passes ended in `head -3`, so a FOURTH match in one poll
# window was dropped WITH NO TRACE. On the CAPTAIN-RELAY pass that means the
# Captain's own words, silently. The cap itself is defensible -- a notification
# storm is its own failure -- but an UNSTATED cap is not: from the seat's side a
# suppressed order and a quiet bus are the same observation, which is this file's
# founding ambiguity arriving on the OUTPUT side after four fixes on the input
# side.
# 🔑 This seat published "no silent caps: log what was dropped" as a rule and
# then shipped three of them in its own watcher. A rule you wrote is not a rule
# you applied.
cap3() {                    # reads stdin; prints <=3 lines, then NAMES the drop
  _t=$(cat)
  [ -z "$_t" ] && return 0
  _n=$(printf '%s\n' "$_t" | wc -l | tr -d ' ')
  printf '%s\n' "$_t" | head -3
  if [ "$_n" -gt 3 ]; then
    echo "⚠️ $((_n - 3)) MORE ${1:-match(es)} SUPPRESSED by the 3-line cap — read /tmp/ev-peer.txt for the rest"
  fi
  return 0
}

# ⛔⛔ THE BASELINE IS AN ASSERTION, AND ON A RELIGHT IT IS FALSE.
# `wc -l` at arm time silently asserts "everything above this line is already
# handled." True in steady state; FALSE on a boot, by exactly the width of the
# boot -- which is when the backlog of unread orders is at its MAXIMUM.
#
# MEASURED 2026-08-08, the crash relight, on this seat:
#   08:0x  I read the bus tail            -> 15592 lines, last post 02:31
#   08:02  maestro posts HOLD HEAVY WORK  -> lands at line 15594
#   08:0x  this monitor arms, baseline = wc -l  -> the HOLD is BEHIND it, FOREVER
# I did not receive the one order governing the morning. I complied with it only
# because none of my work is in its prohibited classes -- compliance by luck, not
# by obedience, and the two are indistinguishable from inside.
#
# ⇒ PASS BASELINE=<the last line you have ACTUALLY READ>. Falls back to `wc -l`
# for a steady-state re-arm, which is the only case where that is honest.
last=${BASELINE:-$(wc -l < "$BUS" | tr -d ' ')}

while true; do
  n=$(wc -l < "$BUS" | tr -d ' ')
  if [ "$n" -lt "$last" ]; then
    echo "⛔ BUS SHRANK: $n lines, was $last — a clobbering '>' looks exactly like this"
    last=$n
  elif [ "$n" -gt "$last" ]; then
    awk -v start="$last" -v self="$SELF" '
      NR <= start { next }
      # a post header sets the owner for every line until the next header
      # A HEADER MUST FOLLOW A BLANK LINE (2026-08-08 11:4x, the stricter case
      # the maestro published). Pattern alone cannot tell a header you QUOTE from
      # one that IS one: their 11:25 post quoted a header at column 0 and this arm
      # matched it as REAL, spoofing owner-tracking -- which is what the 08:22
      # owner-gate exists to prevent, one level up.
      # MEASURED on the live window: blank-precedence rejects every quoted header
      # and misses ZERO genuine posts, because each real post is appended with a
      # newline-then-bracket header. The blank line is STRUCTURAL, not stylistic.
      # NOTE: NO APOSTROPHES IN THIS COMMENT. It lives inside a single-quoted awk
      # program, so one apostrophe terminates the program -- which is exactly the
      # defect that broke this file twice while the fix was being written.
      prevblank && /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
      }
      /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
      { if (tolower(owner) != tolower(self)) print }
      { prevblank = ($0 == "") }
    ' "$BUS" > /tmp/ev-peer.txt

    # ⛔ SECOND PASS, ADDED 08:1x 8/8 AFTER THE WIDENING FIRED TWICE AND WAS
    # WRONG BOTH TIMES. An order-owned view: only the maestro's own posts.
    # A HALT is an ORDER, and on this bus orders come from the maestro or from
    # a CAPTAIN-RELAY line. Every seat post that merely CONTAINS "HALT" is a
    # seat DESCRIBING ITS OWN FILTER -- which is this file's founding defect
    # (a document naming a pattern becomes a carrier of it) reappearing one
    # variable further out. Owner-gating is the same fix the self-filter
    # already uses; I applied it to "whose post is this" and not to "whose
    # post may issue an order."
    # NOTE the `start` guard: owner must be tracked from line 1 (a body line
    # inherits a header that may predate the new tail), but only NEW lines may
    # be EMITTED. Without it this pass re-reports every historical maestro
    # halt on each fire -- I wrote that bug into the fix for a false-fire.
    awk -v start="$last" '
      # A HEADER MUST FOLLOW A BLANK LINE (2026-08-08 11:4x, the stricter case
      # the maestro published). Pattern alone cannot tell a header you QUOTE from
      # one that IS one: their 11:25 post quoted a header at column 0 and this arm
      # matched it as REAL, spoofing owner-tracking -- which is what the 08:22
      # owner-gate exists to prevent, one level up.
      # MEASURED on the live window: blank-precedence rejects every quoted header
      # and misses ZERO genuine posts, because each real post is appended with a
      # newline-then-bracket header. The blank line is STRUCTURAL, not stylistic.
      # NOTE: NO APOSTROPHES IN THIS COMMENT. It lives inside a single-quoted awk
      # program, so one apostrophe terminates the program -- which is exactly the
      # defect that broke this file twice while the fix was being written.
      prevblank && /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
      }
      /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
      NR <= start { next }
      { if (tolower(owner) == "maestro") print }
      { prevblank = ($0 == "") }
    ' "$BUS" > /tmp/ev-orders.txt

    grep -oE '^\[[0-9]+/[0-9]+ [0-9:]+, maestro[^]]*\]|^- [0-9-]+ [0-9:]+ MAESTRO' \
      /tmp/ev-peer.txt | cut -c1-95
    # ⛔ WIDENED 2026-08-07 21:1x, AND THE OLD PATTERN WAS WRONG IN BOTH DIRECTIONS.
    # It was `-i 'EVIDENCE (—|:)'`, which:
    #   TOO NARROW — the fleet addresses this seat with a COMMA and with "EVIDENCE
    #     SEAT" at least as often as with a dash. MEASURED over the whole bus: 62
    #     addressed-looking lines on 8/7 alone that this filter could not match,
    #     including "EVIDENCE, this one is yours:" (silicon 21:04) and "EVIDENCE,
    #     BEFORE THE 19:15 NIGHTLY:" (compiler 19:05) — the second landed ten
    #     minutes before the nightly it was warning about.
    #   TOO BROAD — `-i` matched this seat's OWN post headers, `[…, evidence — …]`,
    #     and ordinary lowercase prose ("no evidence: the file was empty").
    # Net effect of the fix: 203 matches -> 116, and the two known misses now hit.
    #
    # 🔑 THE REASON IT SURVIVED ALL DAY is the datum compiler posted at 21:0x:
    # AN ARMED-AND-CORRECT MONITOR AND AN ARMED-AND-MIS-SCOPED ONE ARE
    # INDISTINGUISHABLE FROM THE SEAT'S OWN SIDE. This seat verified "is it
    # running?" by PPID chain four times today and never once asked "what exactly
    # will wake me?" — silence from a mis-scoped filter reads as a quiet bus.
    grep -oE "EVIDENCE('S| SEAT)?[[:space:]]*[—:,][^.]{0,70}" /tmp/ev-peer.txt | cap3 "EVIDENCE-addressed"
    # ⛔ ADDED 2026-08-08 08:0x, AT THE CRASH RELIGHT — AND IT WAS MISSING ALL OF 8/7.
    # The WATCH BLOCK item (1) names FOUR classes: own seat + MAESTRO + CAPTAIN +
    # HALT/STOP/STAND DOWN (plus shrinkage, unconditional). This script implemented
    # TWO of them. So on 8/7 this seat answered "is the monitor running?" correctly
    # every time and would NOT have woken on a Captain's order or a fleet halt.
    # That is the 8/7 lesson (watch-filter-watches-orders-not-triggers) committed
    # a second time by the seat that WROTE it: I widened the EVIDENCE pattern at
    # 21:1x for being mis-scoped and never asked what ELSE the block required.
    # A CAPTAIN-RELAY line is the Captain's own words and may sit in ANY seat's
    # post, so it is matched against the peer view.
    grep -oE "CAPTAIN-RELAY:.{0,70}" /tmp/ev-peer.txt | cut -c1-95 | cap3 "CAPTAIN-RELAY"
    # HALT/STAND DOWN only from the ORDER-OWNED view.
    # ⛔ AND I WROTE A NUMBER HERE BEFORE I MEASURED IT. The first version of
    # this comment claimed "27 seat-owned lines and 0 maestro-owned" and called
    # itself "measured before arming". Then I measured:
    #   math 11 · silicon 10 · compiler 5 · evidence 2 · MAESTRO 1  = 29
    # The maestro line is real and is exactly the class worth waking for --
    # 8/7 17:00, ratifying silicon's FIREWALL halt (fdb4474, the Bellcore
    # figure). So the gate is NOT vacuous: it keeps 1 of 29 and drops 28 seat
    # posts that merely LIST their filter classes. Had I shipped the asserted
    # version, the comment would have argued the gate discards nothing while
    # the gate's whole value is the one line it keeps.
    grep -oE "HALT|STAND DOWN|STAND-DOWN|ALL SEATS STOP|FLEET STOP" /tmp/ev-orders.txt \
      | sed 's/^/⛔ MAESTRO ORDER WORD: /' | cap3 "MAESTRO ORDER WORD"
    # ⛔ THE FLEET GATE -- ADDED 2026-08-08 13:5x ON THE MAESTRO RULING THAT CLOSED
    # A GAP THIS SEAT NAMED AGAINST ITSELF AT 13:44. The order-owned view above is
    # gated on the MAESTRO, and a PEER SEAT CAN BIND THE WHOLE FLEET WITHOUT BEING
    # THE HELM: compiler 13:44 opened a red window on the shared tree with
    # do-not-debug instructions, and this watch would have slept through it.
    # I read it by hand and it cost nothing -- compliance by luck, which is the
    # same failure this file already records at the BASELINE comment.
    #
    # ⚠️ AND THE OBVIOUS IMPLEMENTATION IS A CARRIER. The ruling that CREATED this
    # rule necessarily quotes the marker (maestro 13:49: "opens its header body
    # with FLEET -- in caps"), so a bare grep for the marker fires on the
    # announcement of the marker. That is this file's founding defect for the
    # fourth time, and a wider regex cannot fix it.
    #
    # 🔑 THE STRUCTURAL DISCRIMINATOR, MEASURED ON BOTH LIVE SPECIMENS: a post that
    # BINDS opens its body with the marker -- it is the FIRST text after the
    # header bracket. A post that DESCRIBES the rule reaches the marker mid
    # sentence, after other prose. So the gate reads only the first characters
    # after the "]", stripped of emoji and markup, and asks whether the body
    # STARTS there.
    #   compiler 13:44 (binds)     "]  U+1F6A7 **FLEET -- DELIBERATE RED WINDOW"   MATCH
    #   maestro  13:49 (describes) "]  **ALL SEATS -- one-line convention, ..."    no match
    # NOTE: NO APOSTROPHES IN THIS COMMENT -- it sits above a single-quoted awk
    # program, the hazard already recorded twice in this file.
    # ⛔⛔ AND THE FIRST VERSION OF THIS PASS WAS BROKEN, CAUGHT BY TESTING IT
    # AGAINST BOTH LIVE SPECIMENS BEFORE ARMING IT. I opened with
    #   NR <= start { next }
    # which skips the boundary line BEFORE prevblank is assigned, so the header
    # at start+1 never learns that start was blank and the gate matched NOTHING --
    # including the very post it exists to catch. The orders pass twenty lines
    # above carries a comment warning of exactly this, in exactly these words
    # ("owner must be tracked from line 1 ... but only NEW lines may be EMITTED"),
    # and I reproduced it one pass over while reading it. The guard belongs on
    # the EMIT, never on the line walk.
    # ⛔⛔⛔ AND THE SECOND DEFECT, CAUGHT ONLY BY SWEEPING THE WHOLE FILE RATHER
    # THAN THE WINDOW I CARED ABOUT: this pass ABORTS without LC_ALL=C.
    #   awk: towc: multibyte conversion failure ... input record number 127
    # The gsub below forces wide-char conversion of emoji-bearing lines, and one
    # malformed sequence at line 127 kills the whole program -- every fire,
    # forever, BEFORE reaching any post. The peer and orders passes never hit it
    # because neither gsubs over multibyte text.
    # 🔑 AN ARMED GATE THAT ABORTS AT LINE 127 IS INDISTINGUISHABLE FROM A QUIET
    # BUS, which is this file's standing lesson about mis-scoped monitors, now in
    # its most literal form: not the wrong filter, a DEAD one. LC_ALL=C makes awk
    # byte-oriented, which is also exactly the semantics this gate wants -- it
    # strips emoji bytes as non-letters, which is the intent.
    # ⛔⛔⛔⛔ THIRD DEFECT, AND THE ONLY ONE THAT WOULD HAVE SURVIVED REVIEW: the
    # first working version read the marker ONLY on the header line, and was
    # therefore BLIND TO THIS SEATS OWN POSTING FORMAT. Measured by running the
    # gate against my own FLEET post seconds after publishing it -- it saw the
    # header and reported "not FLEET-marked".
    #   compiler / silicon / math  printf ends WITHOUT a newline
    #                              -> "] <emoji> **FLEET -- ..."   marker ON the header
    #   THIS SEAT                  printf ends WITH a newline
    #                              -> marker on the FIRST BODY LINE BELOW it
    # 🔑 I built the gate from the specimens I had, and every specimen I had was
    # another seats format. An instrument tested only on other peoples objects is
    # blind in exactly the place its author cannot see -- the same shape as
    # verifying over a window instead of the full object, one axis over.
    # ⇒ The gate now accepts the marker in EITHER position: on the header line,
    # or on the first non-blank line beneath a header that carries no body text.
    # The DESCRIBES-vs-BINDS discriminator is unchanged and still rejects the
    # ruling that created the marker (maestro 13:49), measured after the fix.
    # ⛔⛔⛔⛔⛔ FOURTH DEFECT, AND IT IS THIS FILES FOUNDING BUG, RECOMMITTED BY ME
    # WHILE READING THE COMMENT THAT DESCRIBES IT. The header of this file opens:
    #   "attempt 1: no self-filter at all -> notified on my own posts"
    # I added the FLEET pass reading "$BUS" DIRECTLY instead of the owner-filtered
    # peer view, so it fired on my own 14:02 post within seconds of arming.
    # 🔑 THE THREE EARLIER PASSES ARE OWNER-GATED BECAUSE THEY WERE BUILT THROUGH
    # THAT PAIN; the new pass was built from the RULING, which says nothing about
    # ownership, so it inherited none of the file s history. A new pass in an old
    # file does not inherit the old passes lessons -- the lessons live in their
    # code, not in the file s air.
    # ⇒ Owner extracted here the same way the peer pass does it, and self-owned
    # posts are skipped before any marker test.
    LC_ALL=C awk -v start="$last" -v self="$SELF" '
      function marked(s,   h) {
        h = substr(s, 1, 40)
        gsub(/[^A-Za-z -]/, "", h)
        sub(/^[ ]*/, "", h)
        return (h ~ /^FLEET[ -]/)
      }
      # ⛔⛔⛔⛔⛔⛔ FIFTH DEFECT — SILICON 14:34, FOUND BY READING MY COMMITTED FILE
      # AND VERIFIED AT MY BYTES BEFORE IT WAS SAID. THE GATE DID THE HARD PART AND
      # THEN THREW THE ANSWER AWAY.
      # Both emits printed the raw HEADER line, and our provenance convention puts a
      # long note INSIDE the header. Measured on compiler 13:44, the live specimen:
      #     header/provenance prefix          123 chars
      #     substr(hdr, 1, 150) therefore     27 chars of the actual ORDER
      # So the highest-stakes class this seat watches for delivered its own
      # boilerplate and about twenty characters of the instruction.
      # 🔑 SILICONS ASYMMETRY, ADOPTED WHOLE: a long routine line is noise, a
      # truncated ORDER is a missed order -- they must not share a width.
      # ⇒ Emit SHORT ATTRIBUTION + LONG BODY, content first. stamp keeps only
      # "[MM/DD HH:MM, owner]" and drops the provenance note.
      # ⚠️ AND THE RESIDUAL, silicons words and they are right: the notification
      # ENVELOPE truncates for display independently of any filter. Content-first
      # helps because the payload starts earlier; it does NOT make an arbitrarily
      # deep marker safe. "Never truncates" would be a false claim.
      prevblank && /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
        hdr = $0; pend = 0
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
        if (tolower(owner) == tolower(self)) { prevblank = 0; next }
        # ⚠️ POSIX awk sub() has NO CAPTURE GROUPS -- my first version used "\\1"
        # and emitted the literal string "\1]" as the attribution, caught by
        # running it on the five live specimens before arming. match()+substr()
        # is the portable form.
        stamp = (match($0, /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z0-9_-]+/) \
                 ? substr($0, RSTART, RLENGTH) "]" : "[?]")
        body = $0
        sub(/^\[[^]]*\][[:space:]]*/, "", body)
        if (NR > start) {
          if (body != "") {
            if (marked(body)) print "🚧 FLEET-BINDING POST " stamp " " substr(body, 1, 400)
          } else pend = 1
        }
        prevblank = 0
        next
      }
      pend && $0 != "" {
        if (marked($0)) print "🚧 FLEET-BINDING POST " stamp " " substr($0, 1, 400)
        pend = 0
      }
      { prevblank = ($0 == "") }
    ' "$BUS"
    last=$n
  fi
  sleep "$POLL"
done

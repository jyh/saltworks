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

last=$(wc -l < "$BUS" | tr -d ' ')

while true; do
  n=$(wc -l < "$BUS" | tr -d ' ')
  if [ "$n" -lt "$last" ]; then
    echo "⛔ BUS SHRANK: $n lines, was $last — a clobbering '>' looks exactly like this"
    last=$n
  elif [ "$n" -gt "$last" ]; then
    awk -v start="$last" -v self="$SELF" '
      NR <= start { next }
      # a post header sets the owner for every line until the next header
      /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
      }
      /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
      { if (tolower(owner) != tolower(self)) print }
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
      /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
      }
      /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
      NR <= start { next }
      { if (tolower(owner) == "maestro") print }
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
    grep -oE "EVIDENCE('S| SEAT)?[[:space:]]*[—:,][^.]{0,70}" /tmp/ev-peer.txt | head -3
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
    grep -oE "CAPTAIN-RELAY:.{0,70}" /tmp/ev-peer.txt | cut -c1-95 | head -3
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
      | head -3 | sed 's/^/⛔ MAESTRO ORDER WORD: /'
    last=$n
  fi
  sleep "$POLL"
done

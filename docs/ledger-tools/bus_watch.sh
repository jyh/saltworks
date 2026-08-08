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
    last=$n
  fi
  sleep "$POLL"
done

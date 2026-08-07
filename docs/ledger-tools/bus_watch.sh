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
    grep -oiE 'EVIDENCE (—|:)[^.]{0,70}' /tmp/ev-peer.txt | head -3
    last=$n
  fi
  sleep "$POLL"
done

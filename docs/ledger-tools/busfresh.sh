#!/usr/bin/env bash
# busfresh.sh — REFUSE a bus post that answers a stale read.
#
# WHY THIS EXISTS (evidence seat, 2026-08-17 07:1x):
#   I read the maestro's 07:14 post, spent two minutes analysing it, and posted
#   at 07:16:21. The maestro WITHDREW that post at 07:15:27 — 54 seconds before
#   my reply landed. My reply's substance survived (the withdrawal enumerated it
#   as retained) but it answered text that no longer stood.
#
#   Every gate on my send path is a CUSTODY check: landed bytes vs my own
#   hdr.txt/body.txt, offset, bracket, sha. Not one of them asks
#       "DID THE WORLD CHANGE BETWEEN MY READ AND MY SEND?"
#   That is a freshness precondition and the bus has never had one.
#
# THE LAW IT ENFORCES: printed-is-not-gated. This does not PRINT the new posts,
# it EXITS NONZERO on them. "If this value were the bad one, what would STOP?"
#   -> the send does, because callers use:   busfresh.sh "$READ_OFF" || exit 1
#
set -u
BUS=${BUS:?BUS must be set: the fleet bus is machine-local and has no public default}
READ_OFF=${1:?usage: busfresh.sh <byte-offset-of-bus-when-you-READ-it>}

NOW_OFF=$(wc -c < "$BUS" | tr -d ' ')

if [ "$NOW_OFF" -lt "$READ_OFF" ]; then
  echo "⛔ BUS SHRANK: read-offset $READ_OFF > current $NOW_OFF — the bus was rewritten, not appended." >&2
  exit 2
fi
if [ "$NOW_OFF" = "$READ_OFF" ]; then
  echo "✅ bus unchanged since your read (offset $READ_OFF) — safe to send."
  exit 0
fi

# Something landed. Show WHO and WHAT, then refuse.
NEW=$(tail -c "+$((READ_OFF+1))" "$BUS" | grep -cE '^\[[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}' || true)
echo "⛔ STALE READ: $((NOW_OFF-READ_OFF)) bytes and $NEW post(s) landed since offset $READ_OFF." >&2
tail -c "+$((READ_OFF+1))" "$BUS" | grep -E '^\[[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}' \
  | cut -c1-150 | sed 's/^/   ⇒ /' >&2
echo "   READ THESE BEFORE SENDING. A withdrawal or a correction may have landed under your draft." >&2
exit 1

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
# ⛔⛔ HASH-NOT-LENGTH — 2026-08-23 14:4x, bank §2 item 1, pre-registered at
# seat bb1ab8b5 BEFORE this code was written.
#   The original compared byte COUNT only. So it answered "did the bus GROW?"
#   while claiming (line 12, above, in its own words) to answer "did the world
#   change between my READ and my SEND?" Those are different questions.
#   DRIVEN, not argued — a scratch bus, an equal-length in-place edit
#   (HOLD HEAVY WORK -> hold heavy work), content sha 79a7a4da -> 30f96567:
#       the gate returned exit 0, "✅ safe to send."
#   ⇒ An in-place edit inside the region I had already read was INVISIBLE, and
#     the failure direction is the bad one: it says SAFE.
#
#   THE FIX IS A DIGEST OF THE READ PREFIX [0, READ_OFF), not of the whole bus:
#   the suffix is what A2 (growth) already covers, and hashing it would make
#   every ordinary append look like tampering.
#
#   ⚠️ AND THE ARM IS OPTIONAL, SO ITS ABSENCE IS DISCLOSED. A caller that
#   passes no digest gets exactly the OLD guarantee and IS TOLD SO. An exclusion
#   is never self-announcing; a miss is. [[an-instrument-must-disclose-its-frame]]
#
#   ⚠️ ORDER MATTERS: the prefix check runs BEFORE the length-equality shortcut,
#   so a bus that was BOTH rewritten AND appended is reported as REWRITTEN (3)
#   rather than as ordinary growth (1). A gate ordering can mask the very arm you
#   built to test. [[a-control-must-traverse-the-pipeline]]
#
# usage: busfresh.sh <READ_OFF> [READ_SHA]     -> gate a send
#        busfresh.sh --mark                    -> print "OFF SHA" for right now
#   ⇒ PREFER --mark. It emits both coordinates from ONE read of the object, so
#     they cannot drift apart; a hand-typed pair can.
#     [[never-type-a-high-entropy-field]]
#
# EXIT: 0 fresh · 1 appended-since · 2 shrank · 3 REWRITTEN IN PLACE · 4 misuse
#
set -u
# ⛔ MISUSE MUST NOT WEAR THE REFUSAL'S EXIT CODE. `${BUS:?}` exits 1 under set -u —
# the SAME code as "stale read" — so a caller running `busfresh.sh "$OFF" || exit 1`
# cannot tell a MISCONFIGURED GATE from a GENUINE REFUSAL. Found 2026-08-23 by my own
# test harness forgetting to export BUS: all three arms returned 1 and I read it as a
# regression. The harness was wrong and the exit code was ambiguous; only one of those
# is mine to keep. Misuse has its own code and this path now uses it.
if [ -z "${BUS:-}" ]; then
  echo "⛔ MISUSE: BUS must be set: the fleet bus is machine-local and has no public default." >&2
  exit 4
fi

prefix_sha() {  # $1 = byte count
  head -c "$1" "$BUS" | shasum -a 256 | cut -d' ' -f1
}

if [ "${1:-}" = "--mark" ]; then
  OFF=$(wc -c < "$BUS" | tr -d ' ')
  echo "$OFF $(prefix_sha "$OFF")"
  exit 0
fi

READ_OFF=${1:?usage: busfresh.sh <byte-offset-of-bus-when-you-READ-it> [read-sha] | busfresh.sh --mark}
READ_SHA=${2:-}

NOW_OFF=$(wc -c < "$BUS" | tr -d ' ')

if [ "$NOW_OFF" -lt "$READ_OFF" ]; then
  echo "⛔ BUS SHRANK: read-offset $READ_OFF > current $NOW_OFF — the bus was rewritten, not appended." >&2
  exit 2
fi

# --- the in-place arm. Runs FIRST, and on every path that has a digest. ---
if [ -n "$READ_SHA" ]; then
  case ${#READ_SHA} in
    16|32|64) : ;;
    *) echo "⛔ MISUSE: read-sha must be 16, 32 or 64 hex chars (got ${#READ_SHA}); a weak digest is a gate that lies." >&2
       exit 4 ;;
  esac
  NOW_SHA=$(prefix_sha "$READ_OFF")
  NOW_CUT=${NOW_SHA:0:${#READ_SHA}}
  if [ "$NOW_CUT" != "$READ_SHA" ]; then
    echo "⛔ BUS REWRITTEN IN PLACE: the first $READ_OFF bytes are NOT the bytes you read." >&2
    echo "     you read: $READ_SHA" >&2
    echo "     now:      $NOW_CUT" >&2
    echo "   Length alone would have called this UNCHANGED. Something under your draft was EDITED," >&2
    echo "   not appended — a withdrawal, a correction, or a repair. RE-READ BEFORE SENDING." >&2
    exit 3
  fi
fi

if [ "$NOW_OFF" = "$READ_OFF" ]; then
  if [ -n "$READ_SHA" ]; then
    echo "✅ bus unchanged since your read (offset $READ_OFF, prefix digest verified) — safe to send."
  else
    echo "✅ bus unchanged since your read (offset $READ_OFF) — safe to send."
    echo "⚠️  LENGTH ONLY: no digest given, so the in-place-edit arm DID NOT RUN. An equal-length" >&2
    echo "   edit under your draft would read exactly like this. Use \`busfresh.sh --mark\` at read" >&2
    echo "   time and pass both values to exercise it." >&2
  fi
  exit 0
fi

# Something landed. Show WHO and WHAT, then refuse.
NEW=$(tail -c "+$((READ_OFF+1))" "$BUS" | grep -cE '^\[[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}' || true)
echo "⛔ STALE READ: $((NOW_OFF-READ_OFF)) bytes and $NEW post(s) landed since offset $READ_OFF." >&2
tail -c "+$((READ_OFF+1))" "$BUS" | grep -E '^\[[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}' \
  | cut -c1-150 | sed 's/^/   ⇒ /' >&2
echo "   READ THESE BEFORE SENDING. A withdrawal or a correction may have landed under your draft." >&2
exit 1

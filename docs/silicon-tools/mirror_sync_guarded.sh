#!/bin/sh
# mirror_sync_guarded.sh — run mirror-sync, then assert the SHARED TREE is clean.
#
# ⛔ WHY THIS EXISTS, 2026-08-27 21:4x. I ran mirror-sync three times in one evening and
#   verified the result AT THE ARTIFACT each time — sha by sha, both sides — and posted
#   "mirror 77/77 verified" three times. Every one of those checks was TRUE. Meanwhile the
#   sync had written into the SHARED seat checkout and left it dirty, and three peers'
#   fleetcommit rebases orphaned on it (evidence 20:31, helm 21:47, bus-sync 21:39).
#
# 🔑 I CHECKED THE PROPERTY I CARED ABOUT — do the bytes match — AND NEVER ASKED THE
#   QUESTION THE REPO CARES ABOUT: is the tree clean for the next hand.
#   ⇒ A VERIFICATION THAT CONFIRMS *MY* INVARIANT CAN LEAVE *YOUR* BLOCKER IN PLACE.
#   The content check could not have caught it: it was true the whole time, and its truth
#   is what made the step feel discharged.
#
# ⚠️ THE STRUCTURAL GAP IT CLOSES: every other instrument this seat runs is pointed at
#   CONTENT and at MY OWN clones. The sync is the only thing I run that writes into a repo
#   I do not own, and it was the only thing with no post-condition.
#
# ⛔ mirror-sync itself is NOT patched — it is a fleet tool and not mine to edit. This
#   wrapper is the seat-side guard; the receipt-says-nothing-about-the-repo observation is
#   reported to its owner instead.
#
# Usage: mirror_sync_guarded.sh <src-memory-dir> <dst-mirror-dir> [seat-repo]

set -u
SRC=${1:?usage: mirror_sync_guarded.sh <src> <dst> [seat-repo]}
DST=${2:?missing dst}
REPO=${3:-${SEAT_DIR:-/Users/jyh/projects/claude/seat}}
SYNC=${MIRROR_SYNC:-$REPO/tools/mirror-sync.sh}

[ -x "$SYNC" ] || { echo "⛔ mirror_sync_guarded: $SYNC not executable"; exit 2; }

bash "$SYNC" "$SRC" "$DST"; rc=$?
if [ "$rc" -ne 0 ]; then
  echo "⛔ mirror_sync_guarded: sync itself EXIT=$rc — not evaluating tree state"
  exit "$rc"
fi

# ── THE POST-CONDITION THE SYNC DOES NOT HAVE ────────────────────────────────
DIRTY=$(git -C "$REPO" status --porcelain 2>/dev/null)
if [ -n "$DIRTY" ]; then
  echo "⛔⛔ mirror_sync_guarded: THE SHARED TREE IS DIRTY AFTER THE SYNC."
  echo "   Every peer fleetcommit rebase will fail on this until it is committed."
  printf '%s\n' "$DIRTY" | sed 's/^/     /'
  echo "   ⇒ commit BY PATH through fleetcommit, or discard by your own hand."
  echo "mirror_sync_guarded EXIT=9"
  exit 9
fi
echo "✅ mirror_sync_guarded: sync clean AND $REPO tree clean — nothing left for a peer to trip on"

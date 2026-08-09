#!/bin/sh
# wrapper_restore_point.sh — is the fleet's ONLY build wrapper still recoverable?
#
# WHY THIS EXISTS (compiler, 2026-08-09, from silicon's stale-owed-list find applied to my own store)
# ----------------------------------------------------------------------------------------------------
# `saltbuild.sh` is the ONLY sanctioned way to run lake or lean, by standing law, for all five
# seats. IT LIVES AT THE PORTFOLIO ROOT, WHICH IS NOT A GIT REPOSITORY, AND IT IS TRACKED
# NOWHERE. Measured 2026-08-09: exactly one copy on disk, links=1, no symlink, no twin.
#
# It is NOT restorable from the versioned corpus. Sharp test — 6 distinctive code lines checked
# against tracked content in salt, saltworks, seat, jas:
#     ✅ in VC   echo $$ > "$LOCK/pid"                        (quoted into discussion docs)
#     ✅ in VC   if [ "$1" = "--cap" ]; then CAP="$2"; ...
#     ❌ nowhere while ! mkdir "$LOCK" 2>/dev/null; do        ← lock ACQUISITION
#     ❌ nowhere trap 'rm -rf "$LOCK"' EXIT INT TERM          ← lock RELEASE
#     ❌ nowhere *)      MODE=build; ... lake build "$@" ;;   ← the build ARM
#     ❌ nowhere else SHA=" sha256=$PRESHA->$POSTSHA UNPINNED"
# Fragments were quoted while being DEBATED; the mechanism never was. Many docs MENTION
# `salt-fleet-build.lock`, `MAXWAIT`, `EXIT=75` — a mention is not a restore path.
#
# THE HAZARD IS NOT "no builds". It is a hasty reconstruction FROM the prose that omits the
# lock: it would build correctly, pass every check, and silently drop the fleet's memory guard.
# Measured peak is 43.08 GB on 64 GiB, so two unlocked seats overcommit — and nothing announces
# it. A wrapper that works and does not lock is worse than a missing wrapper, which announces
# itself immediately.
#
# ⛔ THE DIRECTION IS NOT SYMMETRIC, AND THIS IS THE WHOLE DESIGN.
# Unlike pool_drift.sh (where either side may be the stale one), here THE LIVE FILE IS ALWAYS
# AUTHORITATIVE. On drift the correct act is to REFRESH THE SNAPSHOT. Restoring the snapshot
# over a live wrapper that a seat has legitimately fixed would silently revert a fleet-wide
# ruling — e.g. `CAP=24000`, the Captain 8/9 ruling, which lives ONLY in that file.
# This tool therefore refuses to restore. It only ever reports and refreshes.
#
#   ./wrapper_restore_point.sh          check  (exit 0 same · 1 drift · 2 refuse)
#   ./wrapper_restore_point.sh refresh  adopt the LIVE file as the new snapshot
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
LIVE=/Users/jyh/projects/claude/saltbuild.sh
SNAP="$REPO/docs/ledger-tools/saltbuild.sh.restore-point"

for f in "$LIVE" "$SNAP"; do
  [ -f "$f" ] || { echo "wrapper_restore_point: REFUSING — no file at $f" >&2; exit 2; }
done

lsha=$(shasum -a 256 "$LIVE" 2>/dev/null | cut -d' ' -f1)
ssha=$(shasum -a 256 "$SNAP" 2>/dev/null | cut -d' ' -f1)
[ -n "$lsha" ] && [ -n "$ssha" ] || {
  echo "wrapper_restore_point: REFUSING — shasum produced nothing." >&2; exit 2; }

if [ "${1:-check}" = refresh ]; then
  if [ "$lsha" = "$ssha" ]; then
    echo "wrapper_restore_point: nothing to refresh — already byte-identical."
    exit 0
  fi
  cp -p "$LIVE" "$SNAP" || { echo "wrapper_restore_point: copy FAILED" >&2; exit 2; }
  echo "wrapper_restore_point: snapshot refreshed from the LIVE wrapper."
  echo "  was $ssha"
  echo "  now $lsha"
  echo "  ⚠️  COMMIT IT — an unrefreshed working-tree snapshot protects nothing."
  exit 0
fi

echo "wrapper_restore_point: live=$(echo "$lsha" | cut -c1-12)  snapshot=$(echo "$ssha" | cut -c1-12)"
if [ "$lsha" = "$ssha" ]; then
  echo "wrapper_restore_point: OK — the fleet's build wrapper is recoverable from this repo."
  echo "  (scope: THESE BYTES, today. It does not check that the wrapper is CORRECT.)"
  exit 0
fi
echo "wrapper_restore_point: ⛔ DRIFT — the snapshot is STALE. The live wrapper has changed." >&2
echo "  The live file is authoritative. Someone edited the wrapper without refreshing here," >&2
echo "  so the committed restore point would REVERT their change if ever applied." >&2
echo "  FIX: ./wrapper_restore_point.sh refresh   then commit." >&2
echo "  DO NOT copy the snapshot over the live wrapper. Rulings live in the live file." >&2
exit 1

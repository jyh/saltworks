#!/bin/sh
# bus_integrity.sh — detect an IN-PLACE REWRITE of the append-only fleet bus.
#
# WHY THIS EXISTS (evidence, 2026-08-08 16:1x). Silicon named a hazard that no
# instrument on this bus covers:
#
#   "My monitor's shrinkage alarm catches the file getting SHORTER; an in-place
#    edit that preserves length is invisible to every instrument on this bus."
#
# FLEET.md is in no git repo and has no remote, so a rewrite is BOTH undetectable
# after the fact AND unrecoverable. Every bus citation the fleet has ever written
# -- every "see bus line N", every bank, every freeze anchor -- rests on the file
# being append-only. Nothing was checking that it IS.
#
# THE MECHANISM, and it is the whole idea: FOR AN APPEND-ONLY FILE THE PREFIX IS
# IMMUTABLE. So digest the first N lines, where N is the length last seen. On the
# next run that same prefix must hash identically. Growth is invisible to the
# check (correct -- growth is legal); ANY edit inside the prefix changes it,
# whether or not the length is preserved.
#
#   sh bus_integrity.sh          # check, then re-baseline to current length
#   sh bus_integrity.sh --check  # check only, do not move the baseline
#
# EXIT 0 = intact (or first run) · EXIT 2 = REWRITE DETECTED · EXIT 3 = shrunk
#
# ⚠️ LIMITS, stated here rather than discovered later:
#  * It detects a rewrite ONLY on the next run. It is a tripwire, not a lock, and
#    it cannot recover the lost bytes -- nothing can, absent a snapshot.
#    `bus_snapshot.sh` is the thing that makes recovery possible; this only tells
#    you that you need it.
#  * A rewrite of the prefix that is REVERTED before the next run is invisible.
#  * The baseline file lives beside the seat kit. If IT is lost, the next run is
#    a first run and reports intact -- silently. A first run says so explicitly
#    for exactly that reason.

set -e

BUS=${BUS:-"$HOME/projects/claude/FLEET.md"}
STATE=${STATE:-"${SEAT_DIR}/fleet/bus-integrity.state"}
MODE=${1:-"--advance"}

[ -f "$BUS" ] || { echo "⛔ bus_integrity: no bus at $BUS"; exit 1; }
mkdir -p "$(dirname "$STATE")"

now_lines=$(command wc -l < "$BUS" | tr -d ' ')

if [ ! -f "$STATE" ]; then
  d=$(head -n "$now_lines" "$BUS" | shasum -a 256 | cut -d' ' -f1)
  printf '%s %s\n' "$now_lines" "$d" > "$STATE"
  echo "ℹ️  bus_integrity: FIRST RUN — baseline set at $now_lines lines."
  echo "    Nothing is verified yet; a first run cannot detect anything."
  exit 0
fi

prev_lines=$(cut -d' ' -f1 < "$STATE")
prev_hash=$(cut -d' ' -f2 < "$STATE")

if [ "$now_lines" -lt "$prev_lines" ]; then
  echo "⛔⛔ bus_integrity: BUS SHRANK — $prev_lines → $now_lines lines."
  echo "    A clobbering '>' looks exactly like this. Do NOT append; recover first."
  exit 3
fi

# THE CHECK: re-hash the SAME prefix that was hashed last time.
cur_hash=$(head -n "$prev_lines" "$BUS" | shasum -a 256 | cut -d' ' -f1)

if [ "$cur_hash" != "$prev_hash" ]; then
  echo "⛔⛔ bus_integrity: IN-PLACE REWRITE DETECTED."
  echo "    The first $prev_lines lines changed while the file did not shrink."
  echo "    expected $prev_hash"
  echo "    found    $cur_hash"
  echo "    Every citation into that prefix — banks, freeze anchors, 'see bus"
  echo "    line N' — may now resolve to different bytes than when it was written."
  exit 2
fi

echo "✅ bus_integrity: prefix intact across $prev_lines lines (bus now $now_lines, +$((now_lines - prev_lines)))."

if [ "$MODE" != "--check" ]; then
  d=$(head -n "$now_lines" "$BUS" | shasum -a 256 | cut -d' ' -f1)
  printf '%s %s\n' "$now_lines" "$d" > "$STATE"
fi
exit 0

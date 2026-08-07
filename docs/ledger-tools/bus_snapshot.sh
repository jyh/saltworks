#!/bin/sh
# Snapshot FLEET.md — the bus — because it is the campaign's central record
# and it lives in NO git repository, has NO remote, and has NO history.
#
# Measured 2026-08-06 17:20 by the EVIDENCE seat: `~/projects/claude` is not a
# git repo, neither `salt` nor `saltworks` tracks `../FLEET.md`, and there is
# exactly ONE copy on this machine — 1,145 lines, 474,676 bytes, grown from
# nothing in nineteen hours. Five seats append to it with shell heredocs. One
# `>` where a `>>` was meant destroys the entire record, and unlike every
# other artifact in this campaign there is no previous version to recover.
#
# This is deliberately NOT a policy: where the bus should ultimately live
# (the private `seat` repo is the obvious candidate) is the maestro's ruling.
# This is the cheap insurance that costs nothing while that is decided.
#
#   sh docs/ledger-tools/bus_snapshot.sh          # snapshot + prune to 40
#   KEEP=100 sh docs/ledger-tools/bus_snapshot.sh
#
# It PRINTS WHAT IT READ, per the 16:52 instrument law — the byte count it
# copied, verified on the destination, not the byte count it intended to.

set -e

BUS=${BUS:-"$HOME/projects/claude/FLEET.md"}
DEST=${DEST:-"$HOME/projects/claude/.bus-snapshots"}
KEEP=${KEEP:-40}

if [ ! -f "$BUS" ]; then
  echo "bus_snapshot: FAIL — no bus at $BUS" >&2
  exit 1
fi

src_bytes=$(wc -c < "$BUS" | tr -d ' ')
src_lines=$(wc -l < "$BUS" | tr -d ' ')

# A bus that has SHRUNK since the last snapshot is the exact accident this
# script exists for, so it is reported loudly rather than snapshotted over.
last=$(ls -1 "$DEST"/FLEET-*.md 2>/dev/null | tail -1 || true)
if [ -n "$last" ]; then
  last_bytes=$(wc -c < "$last" | tr -d ' ')
  if [ "$src_bytes" -lt "$last_bytes" ]; then
    echo "bus_snapshot: ⛔ THE BUS HAS SHRUNK — $src_bytes bytes now against"
    echo "              $last_bytes in $(basename "$last")."
    echo "              This is what a clobbering '>' looks like. The snapshot"
    echo "              is still taken (under a .SHRUNK name), and the previous"
    echo "              one is NOT pruned. Investigate before appending."
    stamp=$(TZ=America/Los_Angeles date +%Y%m%d-%H%M%S).SHRUNK
  fi
fi
stamp=${stamp:-$(TZ=America/Los_Angeles date +%Y%m%d-%H%M%S)}

mkdir -p "$DEST"
out="$DEST/FLEET-$stamp.md"
cp -p "$BUS" "$out"

# verify the DESTINATION, not the intent
dst_bytes=$(wc -c < "$out" | tr -d ' ')
if [ "$dst_bytes" != "$src_bytes" ]; then
  echo "bus_snapshot: ⛔ FAIL — copied $dst_bytes bytes, source has $src_bytes" >&2
  exit 1
fi

case "$stamp" in
  *.SHRUNK) ;;
  *) ls -1 "$DEST"/FLEET-*.md 2>/dev/null | grep -v SHRUNK | sed -e :a -e "\$d;N;2,${KEEP}ba" -e 'P;D' \
       | while read -r old; do rm -f "$old"; done ;;
esac

n=$(ls -1 "$DEST"/FLEET-*.md 2>/dev/null | wc -l | tr -d ' ')
# ⛔ NOT "OK" ON THE SHRINK PATH. The first version of this script printed the
# shrink warning and then "bus_snapshot: OK" underneath it — two contradictory
# lines in one report, which is the precise defect this seat catalogued in its
# own fleet-hygiene detector at 09:xx and then committed again here at 17:21.
case "$stamp" in
  *.SHRUNK)
    echo "bus_snapshot: ⛔ SHRUNK — $src_lines lines, $dst_bytes bytes preserved at"
    echo "              $(basename "$out") · $n kept · NOTHING PRUNED. Not a success." ;;
  *)
    echo "bus_snapshot: OK — $src_lines lines, $dst_bytes bytes verified at destination"
    echo "              $(basename "$out") · $n snapshot(s) kept in $DEST" ;;
esac

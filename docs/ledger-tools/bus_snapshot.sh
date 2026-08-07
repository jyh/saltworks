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
#
# ⛔ ORDERED BY MTIME, NOT BY NAME — and that correction is owed to the
# SILICON seat, who adopted this script within 45 minutes and named their
# copies `FLEET-silicon-preappend-<time>.md`. The first version took the
# baseline with `ls -1 | tail -1`, i.e. the last filename ALPHABETICALLY,
# which silently assumed one naming convention. `FLEET-2026…` sorts before
# `FLEET-silicon-…` for every possible timestamp, so the moment a second seat
# joined, "the most recent snapshot" became "whichever seat's prefix sorts
# last" — and the prune below would have deleted the NEWEST dated snapshots
# while keeping older ones. It read correctly today by accident, which is not
# the same as correctly.
last=$(ls -1t "$DEST"/FLEET-*.md 2>/dev/null | head -1 || true)
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
  *) # newest first by MTIME, drop everything past KEEP — naming-agnostic, so
     # any seat may use any prefix (see the note above)
     ls -1t "$DEST"/FLEET-*.md 2>/dev/null | grep -v SHRUNK | tail -n +$((KEEP + 1)) \
       | while read -r old; do rm -f "$old"; done ;;
esac

# --- ARCHIVE: refresh the version-controlled copy in the private seat repo --
# Captain-directed 2026-08-06. Opt-in (ARCHIVE=1) rather than automatic,
# because it commits and pushes into ANOTHER SEAT'S repo and nobody should
# discover that as a side effect of taking a local snapshot.
#
# ⛔ THE LANE CHECK RUNS ON EVERY ARCHIVE, NOT ONCE. The bus is append-only
# and growing — it added 67 KB in the 35 minutes after the first archive — so
# a firewall scan performed once at adoption is the unbreached-cap failure in
# a new costume: it certifies the file that WAS, and the file that IS keeps
# changing. A hit blocks the push rather than warning about it.
#
# 🙈 AND THE GATE IS BLUNT BY DESIGN, WITH ONE CONSEQUENCE EVERY SEAT MUST
# KNOW: **writing ABOUT this check, by spelling out the strings it looks for,
# TRIPS IT.** That is not hypothetical — the bus post announcing this script
# listed the markers to show the scan came back clean, and the scan then
# blocked the archive of that post. It is the third instance of the fleet's
# self-referential defect (*a document that describes a substring-gate by
# quoting the substring becomes a carrier of the failure it documents*) and
# the first to fire in production. **Describe the markers; do not reproduce
# them.** The gate stays blunt on purpose: a firewall check should err toward
# blocking, and the override is LANE_OK=1 — an explicit human call, never a
# default.
#
# ⚠️ BUT "BLUNT" HAS A CEILING, AND COMPILER FOUND IT (18:12): *a gate that
# cries wolf every single time is a false-negative design wearing
# false-positive clothes.* "False positives I can see beat false negatives I
# cannot" holds only while the false positives stay RARE ENOUGH TO LOOK AT.
# At 69-per-run, LANE_OK stops being an explicit human call and becomes the
# thing you type to make the tool go away — converting the override into a
# reflex, which is the exact outcome the design refused. That is why the
# markers are split by kind above rather than uniformly loosened.
#
# 📌 AND ONE RULE FOR THE RECORD, PAID FOR BY THIS EXCHANGE: **when an
# instrument cannot be quoted, publish its LOCATION.** The anti-quoting rule
# meant this gate's pattern was described on the bus and never shown — so a
# peer auditing it (correctly, unprompted, checking their own text first) had
# to RECONSTRUCT it, measured the reconstruction, and reported 69 false
# positives against a gate that has 0. A file-and-line pointer is not a
# substring and would have cost nothing: this is
# `docs/ledger-tools/bus_snapshot.sh`, and the pattern is the line below.
if [ "${ARCHIVE:-0}" = "1" ]; then
  SEAT=${SEAT:-"${SEAT_DIR}"}
  REL=${REL:-"fleet/BUS-triple-campaign.md"}

  if [ ! -d "$SEAT/.git" ]; then
    echo "bus_snapshot: ⛔ ARCHIVE FAILED — no git repo at $SEAT" >&2
    exit 1
  fi

  # SPLIT BY KIND, NOT BY LOOSENESS (compiler's taxonomy, 18:12, adopted in
  # full — `gdm` was the one case still on the wrong side of it):
  #   repo/org names  -> WORD-BOUNDED. Short, substring-prone, and meaningful
  #                      only as whole tokens. Unbounded `loca` matches
  #                      `local` and `allocation`, which are two of the most
  #                      common words in this campaign's vocabulary — 69 hits
  #                      on the live bus, all false. Bounded: 0.
  #   secrecy words   -> SUBSTRING. There the partial match IS the point:
  #                      the longer form built on the marker must still trip.
  # Verified on this grep that `\b` actually binds — an unsupported `\b` would
  # match nothing and fail SILENTLY OPEN, which is the direction that matters.
  hits=$(grep -c -i -E '\bloca\b|\bholl\b|\bgdm\b|google|deepmind|confidential|proprietary' "$BUS" || true)
  if [ "${hits:-0}" -ne 0 ]; then
    echo "bus_snapshot: ⛔ ARCHIVE BLOCKED — the lane scan found $hits employer-lane" >&2
    echo "              marker(s) in the bus. NOT pushed. Read them, and if they are" >&2
    echo "              benign, archive with LANE_OK=1. The local snapshot is taken." >&2
    [ "${LANE_OK:-0}" = "1" ] || exit 1
    echo "bus_snapshot: ⚠️  LANE_OK=1 given — proceeding under an explicit human call."
  fi

  # gh is the authority on visibility; the CLAUDE.md note is not. A public
  # repo here would publish five seats' unreviewed notes in one push.
  vis=$(cd "$SEAT" && gh repo view --json visibility -q .visibility 2>/dev/null || echo UNKNOWN)
  if [ "$vis" != "PRIVATE" ]; then
    echo "bus_snapshot: ⛔ ARCHIVE BLOCKED — $SEAT reports visibility '$vis', not PRIVATE." >&2
    echo "              The bus carries unreviewed seat notes. NOT pushed." >&2
    exit 1
  fi

  cp -p "$BUS" "$SEAT/$REL"
  if ! cmp -s "$BUS" "$SEAT/$REL"; then
    echo "bus_snapshot: ⛔ ARCHIVE FAILED — copy is not byte-identical to the bus" >&2
    exit 1
  fi

  if (cd "$SEAT" && git diff --quiet -- "$REL" && git diff --cached --quiet -- "$REL"); then
    echo "bus_snapshot: archive already current at $REL — nothing to commit"
  else
    (cd "$SEAT" \
      && git add "$REL" \
      && git commit --only "$REL" -q \
           -m "fleet: bus archive refresh — $src_lines lines, $src_bytes bytes" \
      && git push -q origin master) \
      && echo "bus_snapshot: archive pushed — $REL ($vis)" \
      || { echo "bus_snapshot: ⛔ ARCHIVE COMMIT/PUSH FAILED — the local snapshot stands" >&2; exit 1; }
  fi
fi

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

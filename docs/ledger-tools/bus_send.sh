#!/bin/bash
# bus_send.sh -- append a post AND emit the SEND RECORD in the same command.
#
# Born 2026-08-13 from the cold pass on post-integrity-method v1, verdict Q1
# CONFIRMED-FATAL: the spec's population source, "the send path", NAMED NO INSTRUMENT
# THAT EXISTS. The v1 form's four steps emit no send record, so an auditor following
# §3 exactly could not afterwards satisfy §2. Every run claiming compliance used the
# RECEIVE path (the bus) for its numerator and a DIRECTORY for its denominator, both
# forbidden by v1's own clauses. A send list reconstructed afterwards is memory.
#
# THIS FILE IS THE MISSING INSTRUMENT. It is deliberately small: it writes the record
# by THE ACT THAT SENDS, so the population is a fact rather than a reconstruction.
#
#   usage: bus_send.sh <source-file> <bus-file> <sendlog>
#
# The source may contain a literal @@STAMP@@; it is replaced with the stamp this
# command generates, and the SAME stamp is written to the send log. Nothing re-reads
# the stamp from the destination (cold-pass Q3(d): a stamp read back from the bus is
# compared against itself, so header corruption is undetectable by construction).
#
# WHAT IT RECORDS, one line per SEND (never per file):
#   stamp | source path | sha256 of the substituted body | byte offset of the header
#   | line count | destination
# The byte offset is captured BEFORE the append, so the anchor is a recorded fact and
# not a search (cold-pass Q3: v1 defined the region by the SOURCE's length, which begs
# the question -- a dropped-block post is shorter than its source, so the window walks
# past the end and pulls in the next post's bytes, and CORRUPTED is then correct by
# accident).
#
# ⛔ WHAT THIS DOES NOT DO, stated here so the spec cannot overclaim it:
#   * it does not make the append ATOMIC. `>>` on a 12MB shared file with five seats
#     and no lock can still interleave; v1 oversold this and the cold pass caught it.
#     The send log makes interleaving DETECTABLE (offset + length + hash), not absent.
#   * it does not verify anything. Verification reads this log; it is a separate act.
#   * it has never been run against a live corruption. Nothing here has.
set -u

SRC=${1:?source file}; BUS=${2:?bus file}; LOG=${3:?send log}
[ -s "$SRC" ] || { echo "REFUSED: source empty or missing: $SRC" >&2; exit 2; }
[ -f "$BUS" ] || { echo "REFUSED: bus not found: $BUS" >&2; exit 2; }

STAMP=$(date '+%m/%d %H:%M:%S')
SUBST=$(mktemp); trap 'rm -f "$SUBST"' EXIT
sed "s|@@STAMP@@|$STAMP|g" "$SRC" > "$SUBST"

# refuse if the placeholder survived (v1 shipped a literal unsubstituted header once)
if grep -q '@@STAMP@@' "$SUBST"; then
  echo "REFUSED: @@STAMP@@ survived substitution" >&2; exit 3
fi

BODY_SHA=$(shasum -a 256 < "$SUBST" | cut -d' ' -f1)
LINES=$(wc -l < "$SUBST" | tr -d ' ')
OFFSET_BEFORE=$(wc -c < "$BUS" | tr -d ' ')   # anchor, recorded BEFORE the act

{ printf '\n'; cat "$SUBST"; } >> "$BUS" || { echo "REFUSED: append failed" >&2; exit 4; }

# the send record is written by the act that sends -- same command, no second decision
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$STAMP" "$SRC" "$BODY_SHA" "$OFFSET_BEFORE" "$LINES" "$BUS" >> "$LOG" \
  || { echo "WARNING: APPEND LANDED BUT SEND RECORD FAILED -- population now incomplete" >&2; exit 5; }

echo "SENT   stamp=$STAMP lines=$LINES sha=${BODY_SHA:0:12} offset_before=$OFFSET_BEFORE"
echo "LOGGED $LOG"

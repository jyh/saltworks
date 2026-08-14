#!/bin/bash
# BUS APPEND WITH A PUBLISHED, MACHINE-CERTIFIED TRANSPORT RECEIPT
#
# Usage:  bus_append.sh <header-file> <body-file> <claimed-bytes> <claimed-sha16> [<bus>]
#         (phase 1 is bus_receipt.sh, which prints the two claimed values)
#
# ⛔ WHY THIS EXISTS: it replaces a pattern-counting idiom of mine that was
# repaired THREE times and holed FOUR — and every hole leaned the same way,
# TOWARD PASSING:
#   theatre (a control that could not fail) → a typed expected count (one red,
#   a false alarm) → a count derived from the artifact (passed VACUOUSLY when the
#   typed pattern matched nothing) → `exp>0` (SATISFIED BY THE EXACT TYPO IT
#   GUARDS, because this house format states each sentence twice, so an ALL-CAPS
#   pattern matches the header once and leaves the body untested at 2.07%).
# A cold fourth-eyes review killed the fourth patch: the class did not want a
# fifth guard, IT WANTED THE QUERY REMOVED. No pattern is typed here.
#
# THE THREE CLAUSES THIS SATISFIES (idiom law, ratified 08/13 18:22:58):
#  (1) NO TYPED EXPECTATIONS — the expectation is DERIVED from the artifact's
#      bytes. The author DOES author two numbers into the anchor line, and this
#      tool RE-DERIVES them and REFUSES on mismatch, so a published receipt can
#      never be a wish: it is checked against the object it describes.
#  (2) COVERAGE IS DECLARED — 100% of the sent bytes, by cmp, not a handle.
#      The receipt carries TWO labelled halves: TRANSPORT machine-certified ·
#      CONTENT author-read-back. cmp proves what ARRIVED, never what was MEANT.
#  (3) THE RECEIPT IS PUBLISHED — bytes/sha ride the anchor line; the offset is
#      printed at the landing (it is unknowable earlier, and a stale offset is a
#      lie the moment a peer appends).
#
# THE FORM: reference materialised ONCE; hashed BEFORE the send (re-reading the
# source afterwards would make a compose-time mutation derivable and therefore
# invisible); pre-append offset captured so nothing counted can predate the
# append; verdict = size-delta == bytes AND `tail -c N | cmp` == reference. A
# concurrent peer append makes the tail differ → RED, loudly, the safe direction.
set -u
HDR="${1:?usage: bus_append.sh <header> <body> <bytes> <sha16> [<bus>]}"
BODY="${2:?missing body}"
CLAIM_N="${3:?missing claimed bytes}"
CLAIM_SHA="${4:?missing claimed sha16}"
BUS="${5:-${BUS}}"
for f in "$HDR" "$BODY" "$BUS"; do
  [ -f "$f" ] || { echo "bus_append: missing file: $f"; exit 2; }
done
[ -s "$BODY" ] || { echo "bus_append: body is EMPTY — refusing"; exit 2; }

# --- CLAUSE (1): the PUBLISHED receipt is verified against the bytes ----------
ACT_N=$(wc -c < "$BODY" | tr -d ' ')
ACT_SHA=$(shasum -a 256 "$BODY" | cut -c1-16)
if [ "$ACT_N" != "$CLAIM_N" ] || [ "$ACT_SHA" != "$CLAIM_SHA" ]; then
  echo "bus_append: ⛔ THE ANCHOR LINE'S RECEIPT DOES NOT DESCRIBE THIS BODY."
  echo "bus_append:    claimed bytes=$CLAIM_N sha=$CLAIM_SHA"
  echo "bus_append:    actual  bytes=$ACT_N sha=$ACT_SHA"
  echo "bus_append:    the body changed after the receipt was taken — REFUSING."
  exit 1
fi

REF=$(mktemp); trap 'rm -f "$REF"' EXIT
D=$(date '+%m/%d %H:%M:%S')
# Stamp generated here and PREPENDED by concatenation: no substitution stage
# exists, so no human-written character can be eaten or survive as a token.
{ printf '\n[%s, ' "$D"; cat "$HDR"; cat "$BODY"; } > "$REF"

N=$(wc -c < "$REF" | tr -d ' ')
SHA=$(shasum -a 256 "$REF" | cut -c1-16)
OFF=$(wc -c < "$BUS" | tr -d ' ')

cat "$REF" >> "$BUS"
RC=$?
AFT=$(wc -c < "$BUS" | tr -d ' ')
DELTA=$((AFT - OFF))

[ "$RC" -eq 0 ] || { echo "bus_append: ⛔ APPEND FAILED rc=$RC"; exit 1; }
if [ "$DELTA" -ne "$N" ]; then
  echo "bus_append: ⛔ SIZE MISMATCH — sent $N bytes, file grew $DELTA"; exit 1
fi
if tail -c "$N" "$BUS" | cmp -s - "$REF"; then
  echo "bus_append: ✅ TRANSPORT CERTIFIED — 100% of sent bytes, by cmp"
  echo "bus_append:    stamp=$D  sent=$N  offset=$OFF  sha(sent)=$SHA"
  echo "bus_append:    published body receipt VERIFIED: bytes=$ACT_N sha=$ACT_SHA"
  echo "bus_append: ⚠️ CONTENT NOT certified here — author read-back is separate"
  exit 0
else
  echo "bus_append: ⛔ TAIL DIFFERS FROM WHAT WAS SENT — sent=$N offset=$OFF sha=$SHA"
  echo "bus_append:    a concurrent peer append or a mangled write; READ THE BUS"
  exit 1
fi

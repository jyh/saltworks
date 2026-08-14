#!/bin/bash
# BUS APPEND WITH A MACHINE-CERTIFIED TRANSPORT RECEIPT
#
# Usage:  bus_append.sh <body-file> [<bus-file>]
#
# ⛔ WHY THIS EXISTS: it REPLACES a pattern-counting idiom of mine that was
# repaired three times and holed four. The progression, because it is the lesson:
#
#   uses 1-10   grep payload + grep a nonsense control  -> THEATRE. The control
#               was a string I invented; it could not appear, so `control: 0`
#               proved only that grep returns 0 for absent text. And the payload
#               arm passed with NO APPEND AT ALL if the text was already there.
#   use  11     before/after DELTA against a typed expected count -> went RED on
#               its first use, a FALSE alarm: I derived the count from a belief
#               about my post format instead of reading the artifact.
#   use  ~20    delta vs a count read FROM the artifact -> passed VACUOUSLY when
#               the typed pattern matched nothing: exp=0, delta=0, 0==0.
#   the patch   require exp>0 -> A COLD FOURTH-EYES REVIEW KILLED IT: this house
#               format states each key sentence TWICE (ALL CAPS in the bracket
#               header, sentence case in the body), so an ALL-CAPS typed pattern
#               — hole three's exact error — matches the HEADER once. exp=1,
#               guard satisfied, LANDED, and the whole body untested at 2.07%
#               measured coverage. THE PATCH MADE THE SAME MISTAKE UNDETECTABLE.
#
# ⭐ EVERY HOLE LEANED THE SAME WAY — TOWARD PASSING. A check's residual failures
# are not random; they inherit the author's wish. So the class does not want a
# fifth guard: IT WANTS THE QUERY REMOVED. No pattern is typed here at all.
#
# THE FORM (a peer seat runs it controlled; the review named the arms):
#   * REF is materialised ONCE  = stamp line + body, exactly the bytes sent.
#   * REF is hashed BEFORE the send. Re-reading the source afterwards would
#     rebuild the very failure this replaces — a mutation upstream of the hash
#     is derivable and therefore invisible to a derivability check.
#   * the pre-append byte OFFSET is captured, so nothing counted can predate
#     the append: "already present" becomes IMPOSSIBLE, not improbable.
#   * verdict = (size delta == byte count) AND (tail -c N | cmp == REF).
#     Coverage is 100% of what was sent, not a 62-byte handle of a 7 KB post.
#   * a concurrent peer append makes the tail differ -> RED, loudly, which is
#     the SAFE direction: this bus is append-only and shared.
#
# ⚠️ WHAT THIS DOES **NOT** CERTIFY, and the receipt says so in two labelled
# halves rather than one word: it proves TRANSPORT of the bytes I sent. It cannot
# know whether those bytes were RIGHT when composed. CONTENT is an author
# read-back and stays a separate, human verdict. A one-word "LANDED" hid that
# distinction for twenty uses.
set -u
BODY="${1:?usage: bus_append.sh <body-file> [<bus-file>]}"
BUS="${2:-${BUS}}"
[ -f "$BODY" ] || { echo "bus_append: body file missing: $BODY"; exit 2; }
[ -s "$BODY" ] || { echo "bus_append: body file is EMPTY — refusing"; exit 2; }
[ -f "$BUS" ]  || { echo "bus_append: bus missing: $BUS"; exit 2; }

REF=$(mktemp); trap 'rm -f "$REF"' EXIT
D=$(date '+%m/%d %H:%M:%S')
# The stamp is generated here and PREPENDED by concatenation. No substitution
# stage exists, so no human-written character can be eaten or survive as a token.
{ printf '\n[%s, ' "$D"; cat "$BODY"; } > "$REF"

N=$(wc -c < "$REF" | tr -d ' ')
SHA=$(shasum -a 256 "$REF" | cut -c1-16)
OFF=$(wc -c < "$BUS" | tr -d ' ')

cat "$REF" >> "$BUS"
RC=$?

AFT=$(wc -c < "$BUS" | tr -d ' ')
DELTA=$((AFT - OFF))
if [ "$RC" -ne 0 ]; then
  echo "bus_append: ⛔ APPEND FAILED rc=$RC"; exit 1
fi
if [ "$DELTA" -ne "$N" ]; then
  echo "bus_append: ⛔ SIZE MISMATCH — sent $N bytes, file grew $DELTA"; exit 1
fi
if tail -c "$N" "$BUS" | cmp -s - "$REF"; then
  echo "bus_append: ✅ TRANSPORT CERTIFIED  stamp=$D bytes=$N offset=$OFF sha=$SHA"
  echo "bus_append:    coverage 100% of sent bytes · no pattern typed · region anchored"
  echo "bus_append: ⚠️ CONTENT is NOT certified here — author read-back is a separate verdict"
  exit 0
else
  echo "bus_append: ⛔ TAIL DIFFERS FROM WHAT WAS SENT — bytes=$N offset=$OFF sha=$SHA"
  echo "bus_append:    a concurrent peer append or a mangled write; READ THE BUS"
  exit 1
fi

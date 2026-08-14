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
# invisible); pre-append offset captured AND USED AS THE READ ANCHOR, so nothing
# counted can predate the append; verdict = size-delta == bytes AND the region
# [offset, offset+N) compared byte-for-byte against the reference.
# ⚠️ THIS PARAGRAPH ITSELF ROTTED ONCE, WITHIN MINUTES, AND IS CORRECTED HERE:
# it used to describe a `tail -c N` read and call a concurrent peer append "RED,
# the safe direction". That WAS the defect — a peer appending between the write
# and the verification made tail compare THEIR bytes against my reference and go
# red on bytes that were intact. Safe direction, yes; still a check that cries
# wolf, and those teach their reader to wave past the real one.
set -u
HDR="${1:?usage: bus_append.sh <header> <body> <bytes> <sha16> [<bus>]}"
BODY="${2:?missing body}"
CLAIM_N="${3:?missing claimed bytes}"
CLAIM_SHA="${4:?missing claimed sha16}"
BUS="${5:-${BUS}}"

# ⛔⛔ HEADER STATE-TOKEN GATE — added 2026-08-14 00:48, because REMEMBERED
# COMPLIANCE FAILED WITHIN ONE POST. I adopted `SEAT-STATE: silicon=<state>` at
# 00:45 and measured my next four posts: the token reached the HEADER exactly
# ONCE, and only because that post happened to be ABOUT the convention. When I
# stopped discussing it, it vanished from the header immediately.
# ⚠️ AND THE HEADER IS THE ONLY SURFACE THAT MATTERS FOR THIS: a peer's watch
# shows the header in its notification and TRUNCATES the rest, so a token in the
# body is invisible to exactly the reader it exists for. I had put my
# machine-readable state on the one surface I had just proved peers do not read.
# ⇒ SO THIS IS A GATE, NOT A REMINDER. A reminder is what already failed.
#   `printed is not gated` — the check whose exit status nothing consumes.
case "$(head -c 400 "$HDR" 2>/dev/null)" in
  *silicon=LIT*|*silicon=RESTING*|*silicon=DARK*) : ;;
  *) echo "⛔ REFUSED: header carries no silicon=<STATE> token." >&2
     echo "   The header is what a peer's watch SHOWS; the body is what it TRUNCATES." >&2
     echo "   Put silicon=LIT (or =RESTING) in the header text, then re-run." >&2
     exit 3 ;;
esac
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
# ⛔ THE RECEIPT PHRASE IS EMITTED HERE, NOT TYPED INTO THE HEADER. A peer's
# custody gate anchors on the literal `body receipt bytes=` (measured present in
# 12 of 12 brackets) — and until this line it was HAND-TYPED into a printf by me,
# once per post, checked by nothing. This tool re-derived the NUMBERS and refused
# on mismatch, so a wrong figure could not ship; but a typo in the PHRASE shipped
# green, transport certified, while the peer's gate silently stopped seeing me.
# ⇒ A MACHINE DEPENDED ON A STRING A HUMAN RETYPED EVERY TIME, and the guard on
# that line guarded everything except the part the peer relied on. Machine-emitted
# on both ends now. Helm 19:25:52 cleared the fourth touch: the meta-clause fires
# on two failures in ONE direction, and this is a contract created by adoption
# rather than a repair — but the helm granted that, not me.
# ⚠️ The header's trailing newline is STRIPPED and the closing bracket is supplied
# HERE, so the bracket line stays ONE line whatever the header file ends with.
# First version depended on me omitting that newline — i.e. it replaced a
# hand-typed PHRASE with a hand-maintained FILE CONVENTION, which is the same
# defect wearing a different hat.
{ printf '\n[%s, ' "$D"
  printf '%s' "$(cat "$HDR")"
  printf ' body receipt bytes=%s sha256/16=%s]\n' "$ACT_N" "$ACT_SHA"
  cat "$BODY"
  # ⛔ GUARANTEE THE TRAILING TERMINATOR, and note WHOSE problem each newline is:
  #   LEADING  \n  protects ME     — my header lands at column zero whatever the
  #                                  previous poster left behind.
  #   TRAILING \n  protects the NEXT poster — their header lands at column zero
  #                                  whatever I leave behind.
  # I had the first in the tool and the second only BY ACCIDENT: measured on my
  # own six most recent posts, five carried a terminator and ONE DID NOT, because
  # it depends on whether the body heredoc happened to end with a newline.
  # ⚠️ AND THE HAZARD IS INVISIBLE TO ITS CAUSER: a missing terminator is SILENTLY
  # HEALED by the next poster's leading separator, so it only surfaces when
  # someone WITHOUT that defence posts next — and then it looks like THEIR defect.
  # Measured live tonight: two helm posts ended without one, both healed, and the
  # third exposed a peer who took the blame for it first.
  # ⇒ A DEFENSIVE MEASURE IN ONE COMPONENT HIDES A DEFECT IN ANOTHER, so "no
  #   corruption observed" is NOT evidence that terminators are correct.
  tail -c1 "$BODY" | od -c 2>/dev/null | head -1 | grep -q '\\n' || printf '\n'
  } > "$REF"

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
# ⛔ THE READ IS ANCHORED AT THE OFFSET, NOT TAKEN FROM THE TAIL — evidence's NC4
# convicted compiler's tool on this and the same diagnosis is mine: I PUBLISHED
# THE OFFSET AND DID NOT USE IT. `tail -c N` reads the LAST N bytes, so a peer
# appending between my write and my verification makes it compare THEIR bytes
# against my reference: RED on bytes that are perfectly intact. MEASURED, not
# reasoned — with a peer append planted mid-verification, tail says RED and the
# offset-anchored read says GREEN.
# The failure direction was SAFE (false red, never false green), which is exactly
# why it could have survived: a check that cries wolf on a non-defect teaches its
# reader to wave past the real one.
if tail -c "+$((OFF + 1))" "$BUS" | head -c "$N" | cmp -s - "$REF"; then
  echo "bus_append: ✅ TRANSPORT CERTIFIED — 100% of sent bytes, by cmp"
  echo "bus_append:    stamp=$D  sent=$N  offset=$OFF  sha(sent)=$SHA"
  echo "bus_append:    published body receipt VERIFIED: bytes=$ACT_N sha=$ACT_SHA"
  echo "bus_append: ⚠️ CONTENT NOT certified here — author read-back is separate"
  exit 0
else
  echo "bus_append: ⛔ THE REGION AT THE OFFSET DIFFERS FROM WHAT WAS SENT — sent=$N offset=$OFF sha=$SHA"
  echo "bus_append:    a mangled write or an interleaved writer; READ THE BUS"
  exit 1
fi

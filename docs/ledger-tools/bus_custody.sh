#!/usr/bin/env bash
# BUS CUSTODY — the ratified idiom law (ADDENDUM B, kit-revision-0813.md), as a tool.
#
#   bus_custody.sh <body.md> <bracket.txt> [<bus>]
#
# body.md     the rendered markdown body (what the receipt's bytes/sha describe)
# bracket.txt line 1 of the post: ", compiler — …]" with bytes= and sha256/16= AUTHORED BY HAND
#
# WHY A SCRIPT: my own banked law says a hand-typed check beats a built one on LATENCY, not
# on merit — the hand-rolled version wins because it is reachable at the moment of the
# question. A committed tool removes that advantage, which is the only thing that has ever
# stopped me re-deriving a form badly under time pressure.
#
# WHY NO TEMPLATE: injecting the receipt into a placeholder would reintroduce the
# SUBSTITUTION STAGE this fleet retired 2026-08-13 — it ate a payload at 08:38 and left an
# unsubstituted token on the bus at 14:40, both this seat's. The figures are AUTHORED by
# hand and RE-DERIVED here; the tool refuses on mismatch. (Silicon's shape, 18:25.)
set -u
BODY=${1:?body.md}; BRACKET=${2:?bracket.txt}
BUS=${3:-${BUS}}
die() { echo "⛔ $1"; exit "$2"; }

# ---- STRUCTURE, each gate refusing in the expression that computes it --------------------
LC_ALL=C grep -q ']$' <<<"$(head -1 "$BRACKET")"           || die "bracket line does not close with ]" 6
[ $(( $(command grep -c '^```' "$BODY") % 2 )) -eq 0 ]     || die "ODD fence count — would corrupt a global parse" 6
[ "$(LC_ALL=C grep -c '[^[:space:]]' "$BODY")" -ge 3 ]     || die "body under 3 lines — invisible to a peer watch" 6
[ "$(LC_ALL=C grep -c '^\[[0-9]\{1,2\}/[0-9]\{1,2\} [0-9][0-9]:[0-9][0-9]' "$BODY")" -eq 0 ] \
                                                           || die "a header-shaped line at column 0 in the body" 6
[ "$(command grep -o '@@STAMP@@' "$BODY" "$BRACKET" | wc -l | tr -d ' ')" -eq 0 ] \
                                                           || die "TRIPWIRE: the retired substitution token is present" 9

# ---- CLAUSE 3: RE-DERIVE the hand-authored receipt and REFUSE on mismatch ----------------
ACT_B=$(wc -c < "$BODY" | tr -d ' ')
ACT_S=$(shasum -a 256 "$BODY" | cut -c1-16)
PUB_B=$(grep -o 'bytes=[0-9]*'          "$BRACKET" | head -1 | cut -d= -f2)
PUB_S=$(grep -o 'sha256/16=[0-9a-f]*'   "$BRACKET" | head -1 | cut -d= -f2)
[ -n "$PUB_B" ] && [ -n "$PUB_S" ] || die "clause 3: bracket line publishes no bytes=/sha256/16=" 3
[ "$PUB_B" = "$ACT_B" ] || die "PUBLISHED bytes=$PUB_B but body is $ACT_B — a false receipt" 3
[ "$PUB_S" = "$ACT_S" ] || die "PUBLISHED sha=$PUB_S but body is $ACT_S — a false receipt" 3

# ---- CLAUSE 1: expectation DERIVED from bytes. REF materialized ONCE, never re-read ------
STAMP=$(date '+%m/%d %H:%M:%S')
REF=$(mktemp)
{ printf '\n[%s' "$STAMP"; cat "$BRACKET"; printf '\n'; cat "$BODY"; } > "$REF"
N=$(wc -c < "$REF" | tr -d ' '); RSHA=$(shasum -a 256 "$REF" | cut -c1-16)
OFF=$(wc -c < "$BUS" | tr -d ' ')

cat "$REF" >> "$BUS"

AFTER=$(wc -c < "$BUS" | tr -d ' ')
[ $((AFTER-OFF)) -eq "$N" ] || die "SIZE-DELTA $((AFTER-OFF)) != $N" 1
tail -c "$N" "$BUS" | cmp -s - "$REF" || die "CMP MISMATCH at the anchored region" 1
rm -f "$REF"

# ---- CLAUSE 2: coverage declared, two labelled halves ------------------------------------
echo "✅ TRANSPORT machine-certified · coverage 100% of sent bytes"
echo "   bytes=$N  offset-pre-append=$OFF  region-sha256/16=$RSHA  stamp=$STAMP"
echo "   body receipt RE-DERIVED and matched: bytes=$ACT_B sha256/16=$ACT_S"
echo "⚠️ CONTENT author-read-back: the AUTHOR's claim, not this tool's. State it yourself."
echo "⚠️ This tool is SELF-BUILT and UNREVIEWED. Its greens are controlled, not sound."

#!/bin/bash
# BUS RECEIPT — phase 1 of the two-phase publish, for idiom-law clause (3).
#
# Usage:  bus_receipt.sh <body-file>
#
# Prints the BODY's receipt fields so the author can copy them into the bracket
# (anchor) line before sending. Clause (3): "bytes/offset/sha in the anchor line
# — a number nobody else can see cannot be falsified by anybody else."
#
# ⛔ WHY TWO PHASES AND NOT A PLACEHOLDER: injecting the hash into a template
# would reintroduce a SUBSTITUTION STAGE, which this fleet retired today after it
# ate one post's payload and left an unsubstituted token in another. The form law
# is that no human-written character is ever a shell token or a printf format. So
# the hash is COMPUTED here, AUTHORED into the header by hand, and then VERIFIED
# against the bytes by bus_append.sh — which is what stops the published number
# from being just another typed expectation (clause 1).
#
# ⚠️ OFFSET is deliberately NOT printed here: it is only knowable at the append,
# and a pre-computed offset would be stale the moment any peer appends. The
# landing prints it.
set -u
BODY="${1:?usage: bus_receipt.sh <body-file>}"
[ -f "$BODY" ] || { echo "bus_receipt: missing body: $BODY"; exit 2; }
[ -s "$BODY" ] || { echo "bus_receipt: body is EMPTY — refusing"; exit 2; }
N=$(wc -c < "$BODY" | tr -d ' ')
SHA=$(shasum -a 256 "$BODY" | cut -c1-16)
echo "bus_receipt: body bytes=$N sha256/16=$SHA"
echo "bus_receipt: paste into the bracket line, then run:"
echo "bus_receipt:   bus_append.sh <header-file> $BODY $N $SHA"

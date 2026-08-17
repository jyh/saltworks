#!/bin/bash
# table_identical.sh — the joint ownership table must be BYTE-IDENTICAL wherever it lives.
#
# The helm ordered (08/17 12:02) that the temporal ownership table land byte-identical in
# BOTH temporal blocks: "sharing moves the risk to the interface, so the interface is one
# artifact in two places, cmp-verified."
#
# ⛔ CMP-VERIFIED IS THE OPERATIVE WORD. Two copies maintained by hand are two copies that
# will diverge, and the divergence is silent: each seat reads its own and both believe
# they agree. This script makes the identity a READING rather than a promise.
#
# It extracts the region between the BEGIN and END markers from every file given and
# compares them byte for byte. It REFUSES (exit 1) on any divergence, and REFUSES (exit 2)
# if a file carries no region at all -- a missing table and an identical table must not
# look the same, which is this fleet's most-measured failure.
#
# ⚠️ REVISED 12:0x: silicon authored the canonical table concurrently, in the shared tree,
# at docs/temporal-ownership-TABLE-0817.md. THEIR FILE IS THE INTERFACE and it carries no
# markers -- so this script no longer demands markers in the canonical copy. It takes the
# CANONICAL file as arg 1 and compares it against the region embedded in each later file,
# which is the shape the joint artifact actually has: one owner-authored original, and
# copies that must equal it.
#
# Usage:  table_identical.sh CANONICAL EMBEDDING [EMBEDDING...]

set -u
BEGIN='TEMPORAL-OWNERSHIP-TABLE v1 · BEGIN'
END='TEMPORAL-OWNERSHIP-TABLE v1 · END'

[ $# -ge 1 ] || { echo "usage: table_identical.sh FILE [FILE...]" >&2; exit 3; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
CANON="$1"; shift
[ -f "$CANON" ] || { echo "⛔ table_identical: canonical not found: $CANON" >&2; exit 3; }
cp "$CANON" "$TMP/0.region"
printf '  %-58s %6s B  sha256/16=%s   CANONICAL\n' "$CANON" \
  "$(wc -c < "$TMP/0.region" | tr -d ' ')" "$(shasum -a 256 "$TMP/0.region" | cut -c1-16)"
N=1; MISSING=0
for f in "$@"; do
  if [ ! -f "$f" ]; then echo "⛔ table_identical: not a file: $f" >&2; exit 3; fi
  awk -v b="$BEGIN" -v e="$END" '
    index($0,b){inr=1;next} index($0,e){inr=0} inr{print}
  ' "$f" > "$TMP/$N.region"
  if [ ! -s "$TMP/$N.region" ]; then
    echo "⛔ table_identical: NO TABLE REGION in $f" >&2
    echo "   A missing table and an identical table must not look the same." >&2
    MISSING=1
  else
    printf '  %-58s %6s B  sha256/16=%s\n' "$f" \
      "$(wc -c < "$TMP/$N.region" | tr -d ' ')" \
      "$(shasum -a 256 "$TMP/$N.region" | cut -c1-16)"
  fi
  N=$((N+1))
done
[ "$MISSING" = 1 ] && exit 2

FAIL=0
for i in $(seq 1 $((N-1))); do
  if ! cmp -s "$TMP/0.region" "$TMP/$i.region"; then
    echo "⛔ table_identical: REGION DIVERGES between copy 0 and copy $i" >&2
    cmp "$TMP/0.region" "$TMP/$i.region" 2>&1 | head -2 | sed 's/^/   /' >&2
    FAIL=1
  fi
done
[ "$FAIL" = 1 ] && exit 1
echo "✅ table_identical: $N cop$([ "$N" = 1 ] && echo y || echo ies) carry a BYTE-IDENTICAL region."
[ "$N" = 1 ] && echo "   ⚠️ ONE COPY ONLY — identity is trivially true and proves nothing yet."
exit 0

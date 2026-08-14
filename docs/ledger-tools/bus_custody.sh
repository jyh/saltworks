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

# ============================================================================
# --selftest : the fourth-eyes review's ONE CHANGE (2026-08-13).
# Drives every die site it CAN on a scratch bus, DECLARES the ones it cannot,
# and writes an arm-count stamp keyed to THIS script's sha. A normal run refuses
# to certify unless a passing selftest exists FOR THESE BYTES.
# Rationale, from the review: "every failure on this record is an arm that did
# not fire in this run, reported as a clean verdict."
# ============================================================================
SELF="${BASH_SOURCE[0]}"
SELFSHA=$(shasum -a 256 "$SELF" | cut -c1-16)
STAMPF="${TMPDIR:-/tmp}/bus_custody_selftest_${SELFSHA}"

if [ "${1:-}" = "--selftest" ]; then
  T=$(mktemp -d); FIRED=0; TOTAL=0; FAILED=""
  mk() { printf 'a control body line\nsecond line\nthird line\n' > "$T/b.md"; }
  arm() { # name, expected-exit, body, bracket
    TOTAL=$((TOTAL+1)); : > "$T/bus"
    BUS_CUSTODY_SELFTEST_CHILD=1 bash "$SELF" "$3" "$4" "$T/bus" >/dev/null 2>&1; local got=$?
    if [ "$got" -eq "$2" ]; then FIRED=$((FIRED+1)); printf '  %-34s exit=%-3s ✅\n' "$1" "$got"
    else printf '  %-34s exit=%-3s ⛔ expected %s\n' "$1" "$got" "$2"; FAILED="$FAILED $1"; fi
  }
  mk; B=$(wc -c < "$T/b.md" | tr -d ' '); S=$(shasum -a 256 "$T/b.md" | cut -c1-16)
  printf ', c — ok, bytes=%s sha256/16=%s]' "$B" "$S" > "$T/ok.txt"
  echo "SELFTEST — driving every drivable die site (script sha256/16=$SELFSHA)"
  arm "NC0 honest append"            0 "$T/b.md" "$T/ok.txt"
  printf ', c — no closing bracket, bytes=%s sha256/16=%s' "$B" "$S" > "$T/x.txt"
  arm ":24 bracket unterminated"     6 "$T/b.md" "$T/x.txt"
  printf 'body\n```\nunclosed fence\n' > "$T/odd.md"
  arm ":25 odd fence count"          6 "$T/odd.md" "$T/ok.txt"
  printf 'one line only\n' > "$T/thin.md"
  arm ":26 body under 3 lines"       6 "$T/thin.md" "$T/ok.txt"
  printf 'body\nmore\n[08/13 09:09, x — a header at column 0]\n' > "$T/hdr.md"
  arm ":28 header-shaped line"       6 "$T/hdr.md" "$T/ok.txt"
  printf 'body\nmore\nthird @@STAMP@@ token\n' > "$T/tok.md"
  arm ":30 retired-token tripwire"   9 "$T/tok.md" "$T/ok.txt"
  printf ', c — no receipt fields at all]' > "$T/norx.txt"
  arm ":37 clause-3 fields absent"   3 "$T/b.md" "$T/norx.txt"
  printf ', c — lie, bytes=%s sha256/16=%s]' "$((B+9))" "$S" > "$T/badb.txt"
  arm ":38 bytes mistyped"           3 "$T/b.md" "$T/badb.txt"
  printf ', c — lie, bytes=%s sha256/16=deadbeefdeadbeef]' "$B" > "$T/bads.txt"
  arm ":39 sha mistyped"             3 "$T/b.md" "$T/bads.txt"
  echo
  echo "  NOT DRIVABLE IN-PROCESS, declared rather than counted as passing:"
  echo "    :55 bus shorter than OFF+N  — needs the append itself to fail mid-write"
  echo "    :57 CMP MISMATCH at offset  — needs a concurrent writer between :48 and :55;"
  echo "        the fourth-eyes reviewer drove it with a cat shim. NOT self-drivable."
  echo
  if [ -n "$FAILED" ]; then
    echo "⛔ SELFTEST FAILED — arms:$FAILED"; rm -f "$STAMPF"; rm -rf "$T"; exit 1; fi
  printf 'ARMS=%s/%s UNDRIVABLE=2 SHA=%s\n' "$FIRED" "$TOTAL" "$SELFSHA" > "$STAMPF"
  echo "✅ SELFTEST PASSED — ARMS=$FIRED/$TOTAL fired, 2 declared undrivable"
  echo "   stamp written for script sha256/16=$SELFSHA"
  rm -rf "$T"; exit 0
fi

# The selftest drives this script recursively; its children must bypass the gate the
# selftest exists to satisfy, or the gate blocks the only thing that can open it.
# Caught on the selftest's FIRST run — 9/9 arms returned exit 5 (the gate) instead of
# their own codes. A certification gate that refuses its own certifier is a deadlock,
# and it fails in the SAFE direction, which is why it was visible at once.
if [ "${BUS_CUSTODY_SELFTEST_CHILD:-}" != "1" ] && [ ! -f "$STAMPF" ]; then
  echo "⛔ REFUSING: no passing selftest for THESE script bytes (sha256/16=$SELFSHA)."
  echo "   The tool changed since its arms were last shown to fire, or never was."
  echo "   Run:  bash $SELF --selftest"
  exit 5
fi
ARMLINE=$(cat "$STAMPF" 2>/dev/null || echo "ARMS=selftest-child")

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
# SILICON'S CRITERION (19:13, 2026-08-13): "a caveat living only in the source never reaches
# the bus." Run against my own landed work it CONVICTED: 10 posts carried a machine receipt;
# the tool's limits reached the bus in at most 4, and only when I hand-copied them.
# THE ASYMMETRY WAS THE DEFECT — this script emitted the CERTIFYING half (bytes/sha) into the
# post automatically and the LIMITING half to my terminal only, so forgetting always failed
# in the over-claiming direction. The caveat is now part of the SENT REGION.
# It is appended AFTER the body, so the hand-authored body receipt (bytes=$ACT_B/$ACT_S,
# re-derived above) still describes exactly what the author read back — no mutation upstream
# of a published hash. The tool-computed region figures ($N/$RSHA) cover the caveat too.
# The line is EXCLUDED from the hand-authored body receipt (it is appended after the body is
# sha'd), so it must SAY SO — otherwise a reader who re-shas the visible text including this
# line gets a mismatch and concludes the author published a false receipt. A receipt whose
# scope a reader cannot see is a trap I would have set for my own verifiers.
CAVEAT='⚠️ *Transport certified by `bus_custody.sh` — SELF-BUILT and UNREVIEWED: bytes/sha cover the SENT REGION only, never the truth of the content, which is the author'"'"'s read-back. **This line is appended by the tool and is EXCLUDED from the `body receipt` above** — re-derive that sha over the body WITHOUT this line.*'
{ printf '\n[%s' "$STAMP"; cat "$BRACKET"; printf '\n'; cat "$BODY"; printf '%s\n' "$CAVEAT"; } > "$REF"
N=$(wc -c < "$REF" | tr -d ' '); RSHA=$(shasum -a 256 "$REF" | cut -c1-16)
OFF=$(wc -c < "$BUS" | tr -d ' ')

cat "$REF" >> "$BUS"

# NC4 (evidence, 18:29): a TAIL-based gate FALSE-ALARMS when a peer appends between the
# write and the check. This is a five-seat bus; that race is normal traffic, not an edge
# case. The cure is the OFFSET the law already makes us publish — read the region AT the
# anchor, never from the end. I was publishing OFF and not using it.
AFTER=$(wc -c < "$BUS" | tr -d ' ')
[ "$AFTER" -ge $((OFF+N)) ] || die "bus shorter than OFF+N ($AFTER < $((OFF+N))) — the append did not land" 1
dd if="$BUS" bs=1 skip="$OFF" count="$N" status=none 2>/dev/null | cmp -s - "$REF" \
  || die "CMP MISMATCH at offset $OFF (+$N)" 1
[ "$AFTER" -gt $((OFF+N)) ] && echo "   note: bus grew past my region during the check (peer append) — offset anchor unaffected"
rm -f "$REF"

# ---- CLAUSE 2: coverage declared, two labelled halves ------------------------------------
echo "✅ TRANSPORT machine-certified · coverage 100% of sent bytes · $ARMLINE"
echo "   bytes=$N  offset-pre-append=$OFF  region-sha256/16=$RSHA  stamp=$STAMP"
echo "   body receipt RE-DERIVED and matched: bytes=$ACT_B sha256/16=$ACT_S"
echo "⚠️ CONTENT author-read-back: the AUTHOR's claim, not this tool's. State it yourself."
echo "⚠️ This tool is SELF-BUILT and UNREVIEWED. Its greens are controlled, not sound."

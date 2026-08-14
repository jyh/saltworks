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
  # Every fixture carries the ENFORCED phrase `body receipt bytes=…`, because a control that
  # does not traverse the real form tests a pipeline nobody uses.
  printf ', c — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/ok.txt"
  echo "SELFTEST — driving every drivable die site (script sha256/16=$SELFSHA)"
  arm "NC0 honest append"            0 "$T/b.md" "$T/ok.txt"
  printf ', c — SEAT-STATE: compiler=LIT · no closing bracket, body receipt bytes=%s sha256/16=%s' "$B" "$S" > "$T/x.txt"
  arm ":24 bracket unterminated"     6 "$T/b.md" "$T/x.txt"
  printf 'body\n```\nunclosed fence\n' > "$T/odd.md"
  arm ":25 odd fence count"          6 "$T/odd.md" "$T/ok.txt"
  # CLAUSE 2b -- the closed vocabulary. Positive AND negative, both driven.
  for w in LIT RESTING; do
    printf ', c — SEAT-STATE: compiler=%s · ok, body receipt bytes=%s sha256/16=%s]' "$w" "$B" "$S" > "$T/v.txt"
    arm ":2b vocab $w accepted"        0 "$T/b.md" "$T/v.txt"
  done
  # the QUOTED-TOKEN pair: a post may quote a peer's state line, and the gate must
  # adjudicate on the AUTHOR'S token (first), never the quoted one (last).
  printf ', c — SEAT-STATE: compiler=LIT · quoting "SEAT-STATE: compiler=BANANA", body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/q1.txt"
  arm ":2b quoted-bad token ACCEPTED"  0 "$T/b.md" "$T/q1.txt"
  printf ', c — SEAT-STATE: compiler=BANANA · quoting "SEAT-STATE: compiler=LIT", body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/q2.txt"
  arm ":2b quoted-good token REFUSED"  8 "$T/b.md" "$T/q2.txt"
  for w in DARK ACTIVE BANANA; do
    printf ', c — SEAT-STATE: compiler=%s · ok, body receipt bytes=%s sha256/16=%s]' "$w" "$B" "$S" > "$T/v.txt"
    arm ":2b vocab $w REFUSED"         8 "$T/b.md" "$T/v.txt"
  done
  # CLAUSE 2c -- bracket grammar. The REAL malformation is the fixture, per the banked law
  # that a mutant needs a fixture built from a landed defect: this is my 12:26:53 header.
  printf '[08/14 12:26, SEAT-STATE: compiler=LIT — the REAL 12:26:53 malformation, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/nest.txt"
  arm ":2c LANDED nested-timestamp REFUSED" 10 "$T/b.md" "$T/nest.txt"
  printf 'x, c — SEAT-STATE: compiler=LIT · no leading comma, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/nc.txt"
  arm ":2c missing leading comma REFUSED"   10 "$T/b.md" "$T/nc.txt"
  printf ', c — SEAT-STATE: compiler=LIT · a [bracket] mid-line, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/mid.txt"
  arm ":2c mid-line '[' REFUSED"            10 "$T/b.md" "$T/mid.txt"
  printf 'one line only\n' > "$T/thin.md"
  arm ":26 body under 3 lines"       6 "$T/thin.md" "$T/ok.txt"
  printf 'body\nmore\n[08/13 09:09, x — a header at column 0]\n' > "$T/hdr.md"
  arm ":28 header-shaped line"       6 "$T/hdr.md" "$T/ok.txt"
  printf 'body\nmore\nthird @@STAMP@@ token\n' > "$T/tok.md"
  arm ":30 retired-token tripwire"   9 "$T/tok.md" "$T/ok.txt"
  # SEAT-STATE arms. The helm's 04:37 release ORDERED a control that fires in the
  # DISCRIMINATING SET: a refusal driven on a post that is NOT about state. That is the
  # arm below — its bracket is about a build result and carries no token.
  printf ', c — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tok_ok.txt"
  arm ":33 SEAT-STATE present"       0 "$T/b.md" "$T/tok_ok.txt"
  printf ', c — build green on three modules, no state mentioned anywhere, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tok_missing.txt"
  arm ":33 SEAT-STATE absent (NOT-about-state)" 7 "$T/b.md" "$T/tok_missing.txt"
  printf ', c — SEAT-STATE: helm=LIT · wrong seat bound, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tok_wrongseat.txt"
  arm ":33 SEAT-STATE bound to WRONG seat" 7 "$T/b.md" "$T/tok_wrongseat.txt"
  printf ', c — SEAT-STATE: compiler=LIT · no receipt fields at all]' > "$T/norx.txt"
  arm ":37 clause-3 fields absent"   3 "$T/b.md" "$T/norx.txt"
  printf ', c — SEAT-STATE: compiler=LIT · lie, body receipt bytes=%s sha256/16=%s]' "$((B+9))" "$S" > "$T/badb.txt"
  arm ":38 bytes mistyped"           3 "$T/b.md" "$T/badb.txt"
  printf ', c — SEAT-STATE: compiler=LIT · lie, body receipt bytes=%s sha256/16=deadbeefdeadbeef]' "$B" > "$T/bads.txt"
  arm ":39 sha mistyped"             3 "$T/b.md" "$T/bads.txt"
  # The receipt is NOT last on the line -- ". One date in this append.]" follows it in 12 of
  # 12 real brackets. This fixture puts DIGITS in that trailer, which is exactly what my
  # first fix's false justification permitted. Plain `tail -1` binds 777 and refuses; the
  # phrase anchor binds the receipt. Differential measured at landing.
  printf ', c — SEAT-STATE: compiler=LIT · body receipt bytes=%s sha256/16=%s. Prior post was bytes=777. One date.]' "$B" "$S" > "$T/trail.txt"
  arm ":37 digits AFTER the receipt"  0 "$T/b.md" "$T/trail.txt"
  # REGRESSION, from a REAL refusal at 19:16 (not a synthetic mutant): prose discussing
  # "bytes=/sha256/16=" before the receipt shadowed it under `head -1`. Expect PASS now.
  # Differential run both ways at landing: head -1 → exit 3, tail -1 → exit 0.
  printf ', c — SEAT-STATE: compiler=LIT · posts carrying a receipt bytes=/sha256/16= are the subject here, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/shadow.txt"
  arm ":37 prose shadows the receipt" 0 "$T/b.md" "$T/shadow.txt"
  # The fixture above fails only when BOTH the anchor and the digit-requirement are absent,
  # so it cannot attribute the fix. This one isolates the ANCHOR: a prose mention carrying
  # DIGITS defeats the pattern fix, so only tail-anchoring rescues it. Differential measured
  # at landing: head -1 → exit 3 regardless of pattern; tail -1 → exit 0.
  printf ', c — SEAT-STATE: compiler=LIT · quoting an earlier receipt bytes=999 sha256/16=beefbeefbeefbeef before mine, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/shadow2.txt"
  arm ":37 digit-bearing prose (anchor)" 0 "$T/b.md" "$T/shadow2.txt"
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

# SEAT-STATE CONTRACT (fleet, 2026-08-14 00:45-00:48; helm released this arm 04:37 as
# CONTRACT ADOPTION rather than self-revision). Two reader kinds force both properties:
# a TRUNCATING reader needs the state FIRST, a SCRAPING reader needs it BOUND to the seat
# name — a body-grep cannot tell "compiler declaring LIT" from "the helm reporting compiler
# LIT". Measured 08/14: I carried the token 2-for-2 and BOTH posts were ABOUT state, i.e.
# zero traffic in the discriminating set; a peer measured the identical adoption decaying to
# 1-in-4 within minutes. A remembered contract is not a contract.
# ABOVE THE PIVOT deliberately: this question is answerable BEFORE the append, so its green
# is a GUARANTEE and not a report.
LC_ALL=C grep -q 'SEAT-STATE: compiler=[A-Z][A-Z]*' <<<"$(head -1 "$BRACKET")" \
  || die "SEAT-STATE contract: bracket lacks 'SEAT-STATE: compiler=<STATE>' as a self-attributing token.
   The fleet made seat state a POSTED FACT (helm, 08/13 23:45). A header without it is
   unreadable to a scraper and invisible past a truncation cut." 7

# ---- CLAUSE 2b: the VOCABULARY, closed at the helm's 11:25 ruling ------------------------
# Until 11:25 this gate enforced the token's PRESENCE and never its VOCABULARY: driven, it
# accepted compiler=BANANA and compiler=XYZZY as readily as LIT. I reported that measurement
# and the helm closed the set on it (kit 886f618, provisional pending ratification):
#   POSTED vocabulary = {LIT, RESTING}.  New words mint ONLY at a sitting.
#   ACTIVE is a HISTORICAL SYNONYM (ACTIVE = LIT) for two retired instances, NOT a member
#     going forward -- so this gate refuses it. That is my reading of "closes at
#     {LIT, RESTING}", and it is the strict one; correctable at a word.
#   DARK is refused deliberately: the helm ruled DARK is a READER'S VERDICT, never a posted
#     token -- a dark seat by definition is not posting, so it cannot be self-declared.
# FIRST occurrence, not last. The original used sed with a greedy `.*`, which takes the
# LAST token on the line -- so a post QUOTING a peer's state line was adjudicated on the
# QUOTED word, both polarities exploitable (a good post refused, a bad post accepted).
# Found 11:42 by a peer's "an empty result needs a POSITIVE CONTROL" applied to my own
# replay: the replay used a python re-implementation that disagreed with the shell, which
# is the never-implement-from-the-prose defect one level in. The ratified form puts the
# self-attributing token as the FIRST CLAUSE of the anchor, so first-match is the author's.
SEAT_WORD=$(head -1 "$BRACKET" | LC_ALL=C grep -o 'SEAT-STATE: compiler=[A-Z][A-Z]*' | head -1 | sed 's/.*=//')
case "$SEAT_WORD" in
  LIT|RESTING) : ;;
  *) die "SEAT-STATE vocabulary: 'compiler=$SEAT_WORD' is not in the closed set {LIT, RESTING}
   (helm ruling 08/14 11:25, kit 886f618). New words mint ONLY at a sitting. DARK is a
   READER'S verdict and can never be posted; ACTIVE is a retired synonym for LIT." 8 ;;
esac

# ---- CLAUSE 2c: the bracket's OPENING, because 22 green arms shipped a broken header ------
# 08/14 12:26:53 I posted a header math could not attribute: "[08/14 12:26:53[08/14 12:26,
# SEAT-STATE: compiler=LIT — ...". Line 227 emits '[' + STAMP and then cats the bracket, so a
# bracket must OPEN WITH THE COMMA that separates stamp from seat. Mine opened with its own
# '[08/14 12:26,' and produced a NESTED TIMESTAMP: zero well-formed matches on that stamp,
# one nested-bracket match, on the peer's control.
# ⛔ THE LESSON, AND IT IS ABOUT THIS TOOL'S GREENS: the run certified "TRANSPORT
# machine-certified · coverage 100% of sent bytes · ARMS=22/22". Every word was TRUE. The
# tool verifies that the bytes I composed are the bytes that landed -- it had NO ARM ON THE
# GRAMMAR OF WHAT I COMPOSED. A fidelity check cannot see a well-transported malformation,
# and the header form was documented in a COMMENT at the top of this file, i.e. remembered.
# The header is the ONE part a truncating reader always sees, so its grammar is exactly the
# part that must not be remembered. Above the pivot: this PREVENTS, it does not detect.
# exit 10: 6 is the pre-existing unterminated-bracket arm and 9 is the retired-token
# tripwire -- a shared code makes two different defects indistinguishable to a caller.
B1=$(head -1 "$BRACKET")
case "$B1" in
  ,\ *) : ;;
  *) die "bracket grammar: line 1 must OPEN with ', ' (comma-space), because line 227 emits
   '[' + the stamp and then this file. Yours opens: '$(printf '%.28s' "$B1")...'
   A leading '[' yields a NESTED TIMESTAMP that no seat's watch can attribute (math,
   08/14 12:28, measured with a control)." 10 ;;
esac
case "$B1" in
  *\[*) die "bracket grammar: line 1 contains a '[' -- the opening bracket is emitted by this
   tool, never by the bracket file. A second one nests and breaks attribution." 10 ;;
esac

# ---- CLAUSE 3: RE-DERIVE the hand-authored receipt and REFUSE on mismatch ----------------
ACT_B=$(wc -c < "$BODY" | tr -d ' ')
ACT_S=$(shasum -a 256 "$BODY" | cut -c1-16)
# PROSE SHADOWING, found live 19:16 when this gate REFUSED a post of mine: the bracket's own
# prose said "a machine receipt bytes=/sha256/16=" and `head -1` bound PUB_B to that mention,
# which has no digits. It failed SAFE (refused rather than certified).
#
# MY FIRST FIX WORKED FOR A REASON I WROTE DOWN AND WHICH WAS FALSE. I anchored to the LAST
# match and justified it as "the receipt is the last thing on the bracket line by form law".
# It is not: `. One date in this append.]` follows the receipt in 12 of 12 of my brackets.
# The tail anchor survived only because that trailer happens to carry no digit-bearing
# `bytes=` — a property nobody had checked and no rule guarantees. Found by running silicon's
# 19:20 criterion ("my first fix for it was a regression") against my own four-minute-old fix.
#
# SO ANCHOR TO THE THING THAT IS ACTUALLY INVARIANT: the phrase. Measured on the bus, 12 of
# 12 compiler brackets carrying a receipt carry `body receipt bytes=`. This makes the form
# MACHINE-ENFORCED instead of asserted in a comment, which is the difference between a rule
# and a hope — and it no longer depends on ANYTHING about what follows the receipt.
PUB_B=$(grep -o 'body receipt bytes=[0-9][0-9]*'                "$BRACKET" | tail -1 | sed 's/.*=//')
PUB_S=$(grep -o 'body receipt bytes=[0-9][0-9]* sha256/16=[0-9a-f][0-9a-f]*' "$BRACKET" | tail -1 | sed 's/.*=//')
[ -n "$PUB_B" ] && [ -n "$PUB_S" ] || die "clause 3: bracket publishes no receipt in the ENFORCED form.
   Required, verbatim:  body receipt bytes=<digits> sha256/16=<hex>
   A bare 'bytes=…' no longer satisfies this — the phrase IS the anchor, so that prose may
   discuss receipts freely. If you got here with a receipt on the line, it lacks the phrase." 3
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

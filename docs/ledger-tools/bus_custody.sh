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
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/ok.txt"
  echo "SELFTEST — driving every drivable die site (script sha256/16=$SELFSHA)"
  arm "NC0 honest append"            0 "$T/b.md" "$T/ok.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · no closing bracket, body receipt bytes=%s sha256/16=%s' "$B" "$S" > "$T/x.txt"
  arm ":24 bracket unterminated"     6 "$T/b.md" "$T/x.txt"
  printf 'body\n```\nunclosed fence\n' > "$T/odd.md"
  arm ":25 odd fence count"          6 "$T/odd.md" "$T/ok.txt"
  # CLAUSE 2b -- the closed vocabulary. Positive AND negative, both driven.
  for w in LIT RESTING; do
    printf ', compiler — SEAT-STATE: compiler=%s · ok, body receipt bytes=%s sha256/16=%s]' "$w" "$B" "$S" > "$T/v.txt"
    arm ":2b vocab $w accepted"        0 "$T/b.md" "$T/v.txt"
  done
  # the QUOTED-TOKEN pair: a post may quote a peer's state line, and the gate must
  # adjudicate on the AUTHOR'S token (first), never the quoted one (last).
  printf ', compiler — SEAT-STATE: compiler=LIT · quoting "SEAT-STATE: compiler=BANANA", body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/q1.txt"
  arm ":2b quoted-bad token ACCEPTED"  0 "$T/b.md" "$T/q1.txt"
  printf ', compiler — SEAT-STATE: compiler=BANANA · quoting "SEAT-STATE: compiler=LIT", body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/q2.txt"
  arm ":2b quoted-good token REFUSED"  8 "$T/b.md" "$T/q2.txt"
  for w in DARK ACTIVE BANANA; do
    printf ', compiler — SEAT-STATE: compiler=%s · ok, body receipt bytes=%s sha256/16=%s]' "$w" "$B" "$S" > "$T/v.txt"
    arm ":2b vocab $w REFUSED"         8 "$T/b.md" "$T/v.txt"
  done
  # CLAUSE 2c -- bracket grammar. The REAL malformation is the fixture, per the banked law
  # that a mutant needs a fixture built from a landed defect: this is my 12:26:53 header.
  printf '[08/14 12:26, SEAT-STATE: compiler=LIT — the REAL 12:26:53 malformation, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/nest.txt"
  arm ":2c LANDED nested-timestamp REFUSED" 10 "$T/b.md" "$T/nest.txt"
  printf 'x, c — SEAT-STATE: compiler=LIT · no leading comma, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/nc.txt"
  arm ":2c missing leading comma REFUSED"   10 "$T/b.md" "$T/nc.txt"
  # NARROWED 13:25: a TAG bracket must be ACCEPTED -- [BOARD] is the fleet's own marker and
  # my first version refused it. The positive arm is the one that would have caught that.
  printf ', compiler — SEAT-STATE: compiler=LIT · [BOARD] queue at zero, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tag.txt"
  arm ":2c [BOARD] tag ACCEPTED"             0 "$T/b.md" "$T/tag.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · a nested [08/14 09:00 stamp, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/mid.txt"
  arm ":2c mid-line nested TIMESTAMP REFUSED" 10 "$T/b.md" "$T/mid.txt"
  # CLAUSE 2d -- the owner slot. Fixture 1 is the REAL 12:30:56 malformation.
  printf ', SEAT-STATE: compiler=LIT — the REAL 12:30:56 malformation, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/own1.txt"
  arm ":2d LANDED SEAT-STATE-in-slot REFUSED" 10 "$T/b.md" "$T/own1.txt"
  # the DANGEROUS direction: well-formed, wrong seat. This one would NOT fail loud.
  printf ', math — SEAT-STATE: compiler=LIT · well-formed WRONG owner, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/own2.txt"
  arm ":2d well-formed WRONG seat REFUSED"    10 "$T/b.md" "$T/own2.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · canonical, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/own3.txt"
  arm ":2d canonical owner ACCEPTED"           0 "$T/b.md" "$T/own3.txt"
  printf ', compiler=LIT — SEAT-STATE: compiler=LIT · attested variant, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/own4.txt"
  arm ":2d attested seat=STATE ACCEPTED"       0 "$T/b.md" "$T/own4.txt"
  # CLAUSE 2e -- decoy owner. Fixture 1 is my REAL 13:08:06 bracket, abridged.
  printf ', compiler — SEAT-STATE: compiler=LIT · V7 names 3 objects (mine, silicon watch revisions, maestro V7-A..V7-E), body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/dec1.txt"
  arm ":2e LANDED decoy-owner REFUSED"     10 "$T/b.md" "$T/dec1.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · thanks to silicon and math, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/dec2.txt"
  arm ":2e 'and <seat>' form ACCEPTED"      0 "$T/b.md" "$T/dec2.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · silicon'"'"'s zero refuted, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/dec3.txt"
  arm ":2e possessive form ACCEPTED"        0 "$T/b.md" "$T/dec3.txt"
  printf 'one line only\n' > "$T/thin.md"
  arm ":26 body under 3 lines"       6 "$T/thin.md" "$T/ok.txt"
  printf 'body\nmore\n[08/13 09:09, x — a header at column 0]\n' > "$T/hdr.md"
  arm ":28 header-shaped line"       6 "$T/hdr.md" "$T/ok.txt"
  printf 'body\nmore\nthird @@STAMP@@ token\n' > "$T/tok.md"
  arm ":30 retired-token tripwire"   9 "$T/tok.md" "$T/ok.txt"
  # SEAT-STATE arms. The helm's 04:37 release ORDERED a control that fires in the
  # DISCRIMINATING SET: a refusal driven on a post that is NOT about state. That is the
  # arm below — its bracket is about a build result and carries no token.
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tok_ok.txt"
  arm ":33 SEAT-STATE present"       0 "$T/b.md" "$T/tok_ok.txt"
  printf ', compiler — build green on three modules, no state mentioned anywhere, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tok_missing.txt"
  arm ":33 SEAT-STATE absent (NOT-about-state)" 7 "$T/b.md" "$T/tok_missing.txt"
  printf ', compiler — SEAT-STATE: helm=LIT · wrong seat bound, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/tok_wrongseat.txt"
  arm ":33 SEAT-STATE bound to WRONG seat" 7 "$T/b.md" "$T/tok_wrongseat.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · no receipt fields at all]' > "$T/norx.txt"
  arm ":37 clause-3 fields absent"   3 "$T/b.md" "$T/norx.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · lie, body receipt bytes=%s sha256/16=%s]' "$((B+9))" "$S" > "$T/badb.txt"
  arm ":38 bytes mistyped"           3 "$T/b.md" "$T/badb.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · lie, body receipt bytes=%s sha256/16=deadbeefdeadbeef]' "$B" > "$T/bads.txt"
  arm ":39 sha mistyped"             3 "$T/b.md" "$T/bads.txt"
  # The receipt is NOT last on the line -- ". One date in this append.]" follows it in 12 of
  # 12 real brackets. This fixture puts DIGITS in that trailer, which is exactly what my
  # first fix's false justification permitted. Plain `tail -1` binds 777 and refuses; the
  # phrase anchor binds the receipt. Differential measured at landing.
  printf ', compiler — SEAT-STATE: compiler=LIT · body receipt bytes=%s sha256/16=%s. Prior post was bytes=777. One date.]' "$B" "$S" > "$T/trail.txt"
  arm ":37 digits AFTER the receipt"  0 "$T/b.md" "$T/trail.txt"
  # REGRESSION, from a REAL refusal at 19:16 (not a synthetic mutant): prose discussing
  # "bytes=/sha256/16=" before the receipt shadowed it under `head -1`. Expect PASS now.
  # Differential run both ways at landing: head -1 → exit 3, tail -1 → exit 0.
  printf ', compiler — SEAT-STATE: compiler=LIT · posts carrying a receipt bytes=/sha256/16= are the subject here, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/shadow.txt"
  arm ":37 prose shadows the receipt" 0 "$T/b.md" "$T/shadow.txt"
  # The fixture above fails only when BOTH the anchor and the digit-requirement are absent,
  # so it cannot attribute the fix. This one isolates the ANCHOR: a prose mention carrying
  # DIGITS defeats the pattern fix, so only tail-anchoring rescues it. Differential measured
  # at landing: head -1 → exit 3 regardless of pattern; tail -1 → exit 0.
  printf ', compiler — SEAT-STATE: compiler=LIT · quoting an earlier receipt bytes=999 sha256/16=beefbeefbeefbeef before mine, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/shadow2.txt"
  arm ":37 digit-bearing prose (anchor)" 0 "$T/b.md" "$T/shadow2.txt"
  # clause 2h. Fixture built from the REAL LANDED DEFECT: my 23:15:56 correction ended
  # "no other occurrence on the bus" and was false on arrival. Three arms, because the
  # negative alone cannot show the guard is narrow enough to live with.
  printf ', compiler — SEAT-STATE: compiler=LIT · retracted string contained, no other occurrence on the bus, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/abs_nostamp.txt"
  arm ":2h absence claim UNSTAMPED"  12 "$T/b.md" "$T/abs_nostamp.txt"
  printf ', compiler — SEAT-STATE: compiler=LIT · retracted string contained, no other occurrence on the bus as of 23:15 before this append, body receipt bytes=%s sha256/16=%s]' "$B" "$S" > "$T/abs_stamp.txt"
  arm ":2h absence claim STAMPED (positive)" 0 "$T/b.md" "$T/abs_stamp.txt"
  # Body-side arm: ALLTXT concatenates BODY and BRACKET, and a guard that reads only the
  # bracket would pass this while the false sentence ships in the body -- where I put mine.
  printf 'a control body line\nthe string appears once on the bus and nowhere else\nthird line\n' > "$T/abs_body.md"
  BB=$(wc -c < "$T/abs_body.md" | tr -d ' '); BS=$(shasum -a 256 "$T/abs_body.md" | cut -c1-16)
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$BB" "$BS" > "$T/abs_bodyok.txt"
  arm ":2h absence in BODY, clean bracket" 12 "$T/abs_body.md" "$T/abs_bodyok.txt"
  # THE EXPLOIT ARM, and it is not hypothetical: this is my own 23:18:45 post reduced.
  # A stamp exists in the post but in ANOTHER SENTENCE -- there, inside the example
  # illustrating what 2h cannot catch. v1 passed this. Co-located v2 must refuse it.
  printf 'a control body line.\nno other occurrence on the bus.\nan illustration of a useless stamp is as of now nothing anywhere ever.\n' > "$T/abs_far.md"
  FB=$(wc -c < "$T/abs_far.md" | tr -d ' '); FS=$(shasum -a 256 "$T/abs_far.md" | cut -c1-16)
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$FB" "$FS" > "$T/abs_farok.txt"
  arm ":2h stamp in ANOTHER sentence"  12 "$T/abs_far.md" "$T/abs_farok.txt"
  # The phrasings the FLEET actually used tonight, which the original list missed entirely.
  printf 'a control body line.\nthe third orphan is unclaimed.\nthird line here.\n' > "$T/abs_v2.md"
  VB=$(wc -c < "$T/abs_v2.md" | tr -d ' '); VS=$(shasum -a 256 "$T/abs_v2.md" | cut -c1-16)
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$VB" "$VS" > "$T/abs_v2ok.txt"
  arm ":2h 'unclaimed' (evidence's word)" 12 "$T/abs_v2.md" "$T/abs_v2ok.txt"
  printf 'a control body line.\nnothing unnamed as of 00:44 before this append.\nthird line.\n' > "$T/abs_v3.md"
  WB=$(wc -c < "$T/abs_v3.md" | tr -d ' '); WS=$(shasum -a 256 "$T/abs_v3.md" | cut -c1-16)
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$WB" "$WS" > "$T/abs_v3ok.txt"
  arm ":2h 'nothing unnamed' STAMPED"     0 "$T/abs_v3.md" "$T/abs_v3ok.txt"
  # MENTION vs USE, built from the post that this arm refused at 00:5x.
  printf 'a control body line.\nevidence published the word `unclaimed` as an example.\nthird line.\n' > "$T/men.md"
  MB=$(wc -c < "$T/men.md" | tr -d ' '); MS=$(shasum -a 256 "$T/men.md" | cut -c1-16)
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$MB" "$MS" > "$T/menok.txt"
  arm ":2h backticked MENTION exempt"     0 "$T/men.md" "$T/menok.txt"
  printf 'a control body line.\nthe third orphan is unclaimed by anyone.\nthird line.\n' > "$T/use.md"
  UB=$(wc -c < "$T/use.md" | tr -d ' '); US=$(shasum -a 256 "$T/use.md" | cut -c1-16)
  printf ', compiler — SEAT-STATE: compiler=LIT · ok, body receipt bytes=%s sha256/16=%s]' "$UB" "$US" > "$T/useok.txt"
  arm ":2h bare USE still convicts"      12 "$T/use.md" "$T/useok.txt"
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
# ── clause 2g: THE READ-THROUGH MARKER, VERIFIED (added 08/14 22:5x) ──────────────
# Proposed at 22:47 and immediately violated by its own founding instance: I typed
# "read to FLEET.md 100616" from RECOLLECTION, never ran wc -l, and it happened to be
# right. A hand-typed marker that LOOKS like an instrument reading and is an author's
# memory is worse than no marker at all -- so the author states it (no substitution
# stage, per the 08/13 law) and THIS ARM CONVICTS IT.
#   NOT REQUIRED: a bracket without the marker passes untouched. Requiring it would
#   block every other seat and the fleet's own older forms -- the over-broad-guard
#   defect I was refused by at 13:25 and will not re-create.
# ⛔⛔ WHAT THIS ARM DOES *NOT* CATCH, TESTED AND STATED: it refuses only the IMPOSSIBLE
#   (claimed > actual). Replaying my own 22:47 violation through it -- claimed 100616
#   against a bus of 100658 -- IT PASSES, because 100616 is POSSIBLE. Possible is not
#   measured. THE GUARD DOES NOT CATCH THE CASE IT WAS BUILT FOR.
#   math's card holds the stronger rule: NEVER hand-write a machine-read field at all,
#   plausible or placeholder. RATIFIED FLEET-WIDE 08/15 11:23 as law 7 of the twelve.
# ⛔ 2026-08-15 11:3x -- AND THE NEXT TWO SENTENCES OF THIS COMMENT USED TO BE WRONG. They
#   read "the real fix is MACHINE EMISSION ... NOT MINE TO MAKE", and they would have sent
#   my successor to build a MISLABELLER. Struck, with the reasoning, because a landed
#   instruction outlives the author who stopped believing it:
#     (1) THE BLOCKER WAS FALSE. I refused the change because emission "needs a field
#         before the owner slot, which breaks clause 2d". It does not: 2d reads only the
#         token after the FIRST comma (line 393) and 2e refuses only a later ", <seat>".
#         A field appended AFTER the owner slot violates neither -- silicon landed exactly
#         that placement at 11:26:52. I DECLARED A CHANGE OUT OF SCOPE ON A CONSTRAINT I
#         NEVER TESTED, and the test is two seds.
#     (2) AND THE CHANGE IS STILL WRONG, for a better reason than the one I gave.
#         EXACT-MATCH EMISSION WOULD FORCE ME TO OVERCLAIM. Compose at 11:19 having read
#         to 105831, append at 11:37 when the bus is 105980, and a machine-emitted field
#         asserts I read 149 lines I never saw. THE GAP IS THE HONEST PART OF THIS FIELD.
# ⭐ THE DISCRIMINATOR, which law 7 needs and does not yet carry -- WHOSE PROPERTY IS THE
#   FIELD ABOUT? An ARTIFACT-subject field ("bus length", "own posts on the bus", bytes,
#   sha) has an instrument that measures exactly what its name claims: MACHINE-EMIT IT,
#   law 7 applies with full force. An AUTHOR-subject field ("how far I read", "bodies in
#   full") has NO instrument -- wc -l measures ARRIVAL and the name claims COMPREHENSION.
#   Emitting it does not make it true, it makes it PRE-TRUSTED AND FALSE.
#   ⇒ my bracket carries BOTH VERBS for this reason (headlines-only = arrival, machine-
#     checkable; bodies-in-full = an author's claim, never emitted). Banked at 08/14 23:00
#     in an-undefined-unit-is-unfalsifiable and re-derived here from the opposite end.
#   So this arm ships as a PARTIAL BY DESIGN, not by blockage: it convicts the IMPOSSIBLE
#   (an author cannot read past the end) and DISCLOSES the gap, which is the most an
#   instrument can honestly say about a fact whose subject is the reader.
RT=$(printf '%s' "$B1" | sed -n 's/.*read to FLEET\.md \([0-9][0-9]*\).*/\1/p')
if [ -n "$RT" ]; then
  NOW=$(wc -l < "$BUS" | tr -d ' ')
  if [ "$RT" -gt "$NOW" ]; then
    die "read-through marker IMPOSSIBLE: you claim to have read to line $RT but the bus
   is only $NOW lines. You cannot have read past the end -- this is a recalled number,
   not a measured one, which is exactly the defect this arm exists for." 11
  fi
  GAP=$((NOW - RT))
  printf '   read-through: claimed %s, bus %s, GAP %s lines behind at append time\n' "$RT" "$NOW" "$GAP"
  [ "$GAP" -gt 400 ] && printf '   ⚠️  %s lines is a wide gap -- your post may cross a turn you have not seen.\n' "$GAP"
fi

# ── clause 2h: AN ABSENCE CLAIM MUST STAMP ITS MOMENT (added 08/14 23:2x) ─────────
# Founding instance, mine, 23:15:56: a CORRECTION post about over-claiming ended
# "no other occurrence on the bus" -- TRUE when composed, FALSE the instant it landed,
# because the post QUOTES the string it is retracting. Measured after append: 6
# occurrences, and the phrase "no other occurrence on the bus" itself appeared TWICE.
# ⛔ THE REASON THIS NEEDS A GATE AND NOT A CARD: I had already banked this exact law
#   (a-mention-is-not-a-restore-path, "an absence claim SELF-FALSIFIES on publication --
#   stamp the MOMENT"). 108 cards in the bank and the relevant one DID NOT FIRE while I
#   was writing. A bank is a READING artifact; it is not an instrument at WRITE time.
#   So the law moves into the writer, per fix-the-format-fix-the-writer.
# NARROW BY CONSTRUCTION: it fires only on an absence PHRASE whose OWN SENTENCE carries
#   no moment stamp. A stamped claim passes untouched -- "no other occurrence as of
#   23:15", "nowhere else on the bus before this append". Blocking a legitimate stamped
#   absence would be the over-broad-guard defect clause 2g already disclaims.
# ⛔ WHAT IT DOES *NOT* CATCH, TESTED AND STATED: it checks that a stamp is PRESENT and
#   CO-LOCATED, never that it is TRUE. "no other occurrence as of now" passes, and so
#   does a stamp that names the wrong time. It converts an unfalsifiable sentence into a
#   falsifiable one; it does not verify it.
# ⛔ 2026-08-15 00:4x — THIS LIST IS CLOSED, AND A CLOSED LIST IS THE DEFECT IT GUARDS AGAINST.
#   Tonight four seats each withdrew a completeness claim, and every instrument involved failed
#   the same way: a closed set of names/paths/phrases presented as coverage. THIS ARM IS THE SAME
#   SHAPE. evidence published "UNCLAIMED" and silicon "nothing unnamed" — both are absence claims
#   and NEITHER would have tripped the original pattern. Extended below with the phrasings the
#   fleet actually used, which raises the floor and does NOT close the class.
#   ⇒ IT CANNOT ENUMERATE ALL WAYS TO ASSERT AN ABSENCE. A post that says "I found none" in a
#     phrasing nobody used tonight sails through. Stated here so the next author does not read
#     a green as coverage.
ABS='no other occurrence|nowhere else on the bus|only occurrence|appears (only )?once on the bus|no other post|zero other occurrences|the sole occurrence|unclaimed|nothing unnamed|nothing unaccounted|no [a-z]+ orphan exists|none exist|found nothing|nothing else (exists|remains)'
STAMP='as of|before this (append|post)|at composition|prior to this (append|post)|at the moment of|when composed|measured at [0-9][0-9]:[0-9][0-9]'
ALLTXT=$(cat "$BODY" "$BRACKET" 2>/dev/null)
# ⛔ TIGHTENED 23:2x, ONE POST AFTER 2h LANDED, AND THE HOLE WAS EXPLOITED BY MY OWN
#   DISCLOSURE. v1 asked only whether a stamp existed ANYWHERE in the post. The post
#   announcing 2h quoted `"as of now, nothing anywhere, ever"` as an ILLUSTRATION of what
#   2h cannot catch -- and that quotation was the ONLY stamp token in the whole post, so
#   it satisfied v1 and my real absence claims shipped unstamped. Measured, not guessed:
#   grep -Eoi over the sent bytes returned exactly 2 hits, both inside that example.
# ⇒ A GUARD'S OWN STATEMENT OF ITS WEAKNESS WAS THE THING THAT WALKED THROUGH IT.
#   The repair is SCOPE: the stamp must sit in the SAME SENTENCE as the claim it dates.
# ⛔ 2026-08-15 00:5x — MENTION vs USE. The extension above refused the very post announcing
#   it: 10 sentences, every one QUOTING a trigger phrase as an EXAMPLE. A guard that cannot tell
#   `"unclaimed"` (mentioned) from unclaimed (asserted) blocks exactly the traffic that discusses
#   it — the over-broad direction, whose refusals are SILENT because the author reroutes.
#   Fix: strip quoted/backticked spans BEFORE matching. A phrase in `backticks` or "quotes" is a
#   MENTION and is exempt; the same phrase bare is a USE and still convicts.
#   ⛔ LIMIT: an asserted absence that HAPPENS to sit inside quotes is now exempt too. That is a
#     real hole, accepted deliberately — a false negative here costs a missed stamp, while the
#     false positive it replaces costs every post that discusses the rule.
BAD=$(printf '%s' "$ALLTXT" | tr '\n' ' ' \
  | sed -e 's/`[^`]*`/ /g' -e 's/"[^"]*"/ /g' -e "s/'[^']*'/ /g" \
  | awk -v abs="$ABS" -v st="$STAMP" '
  BEGIN{RS="[.;]"} { s=tolower($0); if (s ~ abs && s !~ st) c++ } END{print c+0}')
if [ "${BAD:-0}" -gt 0 ]; then
  die "ABSENCE CLAIM WITHOUT A MOMENT: $BAD sentence(s) assert something does not occur
   and carry no stamp saying WHEN that was true. If the post quotes the string it is
   claiming is absent, the claim is FALSE THE INSTANT IT LANDS -- that is exactly how
   this arm was born (23:15:56, mine, in a correction about over-claiming).
   A stamp ELSEWHERE in the post does NOT count: v1 accepted one and was defeated by
   its own disclaimer quoted as an example. Put 'as of <HH:MM>' or 'before this append'
   IN THE SAME SENTENCE as the claim -- co-location is the whole repair." 12
elif printf '%s' "$ALLTXT" | grep -Eqi "$ABS"; then
  printf '   absence claim: PRESENT and CO-LOCATED with a stamp (2h checks position, never truth)\n'
fi

# NARROWED 13:25: the first version refused ANY '[' and that was over-broad -- it blocked
# `[BOARD]`, the fleet's own marker for a queue-state post (PROGRAM BOARD invariant 2), and
# I found out by being refused while trying to file one. THE HAZARD IS A NESTED TIMESTAMP,
# not a bracket character. A guard that blocks a ratified convention is a defect even when
# every refusal it makes is "safe" -- the cost lands on legitimate traffic and it lands
# silently, because the author reaches for a workaround instead of reporting it.
if printf '%s' "$B1" | LC_ALL=C grep -q '\[[0-9]\{1,2\}/[0-9]\{1,2\}'; then
  die "bracket grammar: line 1 contains a NESTED TIMESTAMP '[<m>/<d>'. The opening bracket
   and stamp are emitted by this tool, never by the bracket file; a second one nests and
   breaks attribution (the real 12:26:53 malformation). Tag brackets like [BOARD] are fine." 10
fi

# ---- CLAUSE 2d: the OWNER SLOT ------------------------------------------------------------
# 12:30:56, five minutes after shipping 2c, I posted ", SEAT-STATE: compiler=LIT — ..." and
# math's watch lost me AGAIN: the owner slot held "SEAT-STATE:" where the grammar wants a bare
# seat name. 2c checked the leading comma and the nested bracket and NOTHING ELSE, because I
# repaired the token that had just hurt instead of enumerating the grammar. That is the
# where-else-does-this-law-apply defect, committed inside the repair for the previous one.
# DERIVED FROM THE CORPUS, NOT FROM MY MEMORY OF IT (5149 headers measured 12:32):
#   owner slot = compiler 1205 · silicon 1178 · math 885 · evidence 795 · maestro 563,
#   plus an attested "seat=STATE" variant (silicon=LIT 39, maestro=LIT 34);
#   separator after the name is the em-dash, 4695 of them.
# ⛔ AND THE SECOND ARM IS THE ONE THAT MATTERS MOST, per math 12:28: "A MALFORMED VALUE FAILS
# LOUD AND A WELL-FORMED WRONG ONE IS UNFINDABLE FOREVER." Both my slips failed loud -- a
# bracket that read ", math —" would not have. So the slot is pinned to THIS seat.
OWNER=$(printf '%s' "$B1" | sed -n 's/^,[[:space:]]*\([^[:space:]—-]*\).*/\1/p')
case "$OWNER" in
  compiler|compiler=*) : ;;
  "") die "bracket grammar: no owner in the slot after ', '. The corpus puts a bare seat name
   there in 4626 of 5149 headers." 10 ;;
  *) die "bracket grammar: owner slot holds '$OWNER'; it must be 'compiler' (optionally
   'compiler=STATE'). Measured on 5149 corpus headers: the slot carries a BARE SEAT NAME.
   Yours would post under another seat's name or under no seat at all -- and a well-formed
   WRONG owner is unfindable forever, where a malformed one merely fails loud." 10 ;;
esac

# ---- CLAUSE 2e: NO DECOY OWNER LATER IN THE LINE -----------------------------------------
# 13:08:06 I posted about a NAMING COLLISION and my own header caused a MISATTRIBUTION. My
# bracket carried ", silicon" and ", maestro" while listing which seats use a token. A peer's
# watch scans the WHOLE line for ", <seat>" and filed my post under the helm -- reported by
# math at 13:10 with both filters compared live.
# THE GRAMMAR IS THE REASON: the owner sits after the FIRST comma (clause 2d). Every LATER
# ", <seat>" is indistinguishable from an owner to a scanner that does not stop at the first.
# I fixed exactly this shape inside clause 2b (greedy sed took the LAST SEAT-STATE token
# instead of the author's) and did not ask where else a last-match could win. Same law,
# same file, second surface -- and the post it broke was ABOUT names.
# ⛔ THE FIX IS FREE AT THE AUTHOR'S END: write "silicon's" or "and silicon", never
# ", silicon". This arm refuses the comma form so the rewording is forced, not remembered.
REST=$(printf '%s' "$B1" | sed 's/^,[[:space:]]*[^[:space:]—-]*//')
DECOY=$(printf '%s' "$REST" | LC_ALL=C grep -o ',[[:space:]]*\(maestro\|math\|silicon\|evidence\|compiler\)' | head -1)
if [ -n "$DECOY" ]; then
  die "bracket grammar: a DECOY OWNER '$DECOY' appears after the owner slot. A watch that
   scans the whole header line cannot tell it from the author, and one filed a post of mine
   under the wrong seat at 13:08:06 (math, 13:10, measured against two filters).
   Rewrite as \"<seat>'s\" or \"and <seat>\" -- the comma is the whole problem." 10
fi

# ---- CLAUSE 2f: "owed 0" IS A CLAIM ABOUT **TWO** ARTIFACTS -- and this one REPORTS ------
# 2026-08-14: I wrote "owed 0" in ~20 posts while my memory MIRROR sat EIGHTEEN FILES behind
# the live bank. Every one was true about the BANK and silent about the MIRROR, which is
# word-for-word what my own card `memory-mirror-is-the-second-noun` (banked 08/11) exists to
# prevent. THE LAW WAS WRITTEN DOWN AND NOT INSTALLED.
# ⭐ THIS IS A DETECTOR, NOT A GUARD, AND THE DISTINCTION IS DELIBERATE: a guard's false
# positive BLOCKS work and the author reroutes silently; a detector's false positive costs a
# GLANCE. The mirror is legitimately behind mid-work, so refusing would be wrong -- it warns
# and always exits 0 on its own account. It also FAILS OPEN if the mirror is absent: a
# detector that breaks the pipeline is a guard wearing the wrong label.
MIRROR="${SEAT_DIR}/memory-seats/compiler"
LIVEBANK="${CLAUDE_MEMORY_DIR:-${SEAT_CONFIG_DIR}/projects/-Users-jyh-projects-claude-saltworks/memory}"
if LC_ALL=C grep -qi 'owed[[:space:]]*[:=]\?[[:space:]]*\(0\|ZERO\|none\)' <<<"$B1" 2>/dev/null; then
  if [ -d "$MIRROR" ] && [ -d "$LIVEBANK" ]; then
    STALE=0
    for lf in "$LIVEBANK"/*.md; do
      [ -e "$lf" ] || continue
      bn=$(basename "$lf")
      cmp -s "$lf" "$MIRROR/$bn" || STALE=$((STALE+1))
    done
    if [ "$STALE" -gt 0 ]; then
      printf '⚠️  MIRROR NOT CURRENT: %d live memory file(s) differ from ${SEAT_DIR}/memory-seats/compiler.
' "$STALE" >&2
      printf '   Your bracket claims "owed 0". That is a claim about TWO artifacts -- the BANK
' >&2
      printf '   and the MIRROR -- and it is currently true of one. (Detector: not blocking.)
' >&2
    fi
  fi
fi

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

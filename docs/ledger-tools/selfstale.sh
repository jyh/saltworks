#!/usr/bin/env bash
# SELFSTALE — re-measure the SELF-REFERENTIAL figures my own brief asserts.
#
#   selfstale.sh            EXIT 0 always (reporter). Prints only DRIFT.
#
# WHY IT EXISTS, and it is the night of 2026-08-15's synthesis made concrete:
#   Of 18 defects found that night, 8 were caught by my own instruments and 0 by
#   re-reading. What the 8 shared was not rigour: EVERY ONE HAD MY OWN OUTPUT AS ITS
#   SUBJECT. Most instruments examine the WORLD (a corpus, a bus, a build) and so find
#   world-defects; only an instrument aimed at your own output finds yours.
# ⇒ BUT AIMED INWARD WAS NOT ENOUGH. My three inward instruments (the send gate's
#   read-back, shacite, the read-region meter) all trigger AT SEND. So they caught
#   things I had JUST written and NONE of the four figures that had been rotting in my
#   brief for a day -- those took a peer's prompt to go and read.
# ⇒ THE PAIR IS: SUBJECT = your own output, AND TRIGGER = a clock, not a colleague.
#   This script is the missing half. It is called from fallback-compiler.sh, which is
#   already clock-driven, rather than arming another watch nobody can enumerate.
#
# ⚠️ DOMAIN: it checks figures the brief states ABOUT ITSELF and about the index --
#   the exact class that produced four stale figures on 08/15. It says nothing about
#   prose claims, and a figure phrased differently is invisible to it. MEASUREMENT,
#   NOT IMMUNITY.
set -u
# ⛔ CALLER COUNT — THIS TOOL CANNOT REPORT THAT NOBODY IS RUNNING IT.
#   On 08/19 this seat went down and selfstale had EXACTLY ONE caller
#   (fallback-compiler.sh, mine). So while I was dark my own self-referential
#   figures were checked BY NOTHING, and the checker's silence was
#   indistinguishable from a clean run. silicon found it and wired its own arm.
#   ⇒ A SHARED INSTRUMENT WITH A SINGLE CALLER IS A SINGLE POINT OF FAILURE THAT
#     THE INSTRUMENT ITSELF IS STRUCTURALLY BLIND TO -- the same shape as a
#     filtered watch being unable to prove its own liveness.
#   ⇒ SO IT IS ANSWERABLE BY RUNNING, NOT BY MEMORY:
#        bash selfstale.sh --callers
#     which greps the kit for live call sites and prints the COUNT and the NAMES.
#     A name list in a comment rots on the next caller added; the grep does not.
if [ "${1:-}" = "--callers" ]; then
  # ⛔ SEARCH THE WHOLE TOOL TREE, NOT MY OWN DIRECTORY. First run of this arm reported
  #   "1 caller" while silicon's REAL caller sat in docs/silicon-tools/ -- a sibling.
  #   The count was TRUE ABOUT THE WRONG POPULATION, and it under-reported, which here is
  #   the alarming direction but under a different layout would read as SAFE.
  #   ⚠️ `command grep` is mandatory: the shim is ugrep and skips .gitignored paths.
  D=$(cd "$(dirname "$0")/.." && pwd)
  HITS=$(LC_ALL=C command grep -rl "selfstale" "$D" 2>/dev/null \
           | command grep -v "/selfstale.sh$" | sort -u)
  N=$([ -z "$HITS" ] && echo 0 || printf '%s\n' "$HITS" | wc -l | tr -d ' ')
  printf 'selfstale CALLERS: %s\n' "$N"
  [ "$N" -gt 0 ] && printf '%s\n' "$HITS" | sed 's|^|  |'
  [ "$N" -le 1 ] && printf '⛔ %s caller. A single caller dies with its owner and this tool CANNOT say so.\n' "$N"
  exit 0
fi
B=${1:-${SEAT_DIR:?SEAT_DIR must be set when no brief path is passed (machine-local, no public default)}/briefs/0000-BOOT-compiler.md}
M=${2:-${CLAUDE_MEMORY_DIR:?CLAUDE_MEMORY_DIR must be set when no memory path is passed (machine-local, no public default)}/MEMORY.md}
[ -r "$B" ] || exit 0
NB=$(wc -c < "$B" | tr -d ' '); NL=$(wc -l < "$B" | tr -d ' '); NM=$(wc -c < "$M" 2>/dev/null | tr -d ' ')
OUT=""
# 1. any "this file is N,NNN B" the brief asserts about itself
for c in $(LC_ALL=C grep -oE 'file is [0-9][0-9,]* B' "$B" | LC_ALL=C grep -oE '[0-9][0-9,]*' | tr -d ,); do
  [ "$c" = "$NB" ] || OUT="$OUT
   brief says it is ${c} B; wc -c says ${NB} B"
done
# 2. any "index <n> B" / "index is N,NNN B" claim
for c in $(LC_ALL=C grep -oE 'index [0-9][0-9,]* B|index is [0-9][0-9,]* B' "$B" | LC_ALL=C grep -oE '[0-9][0-9,]*' | tr -d ,); do
  [ "$c" = "$NM" ] || OUT="$OUT
   brief says index is ${c} B; wc -c says ${NM} B"
done
# 3. TOKEN-CLAIM STALENESS. A shell script CANNOT measure tokens -- so this arm does not
#    try. It binds the unmeasurable figure to a MEASURABLE fingerprint written beside it:
#      TOKENFP: <tok> tok @ <bytes> B/<lines> lines
#    If bytes or lines have moved, the token figure is stale BY DEFINITION, whatever it is.
#    Born 2026-08-16: I wrote "this brief is 35,964 tokens" INTO the brief and the edit that
#    added the sentence moved it to 36,674 -- false the instant written, in two places, and
#    arms 1-2 were blind because they only know BYTES.
#    ⚠️ DOMAIN: detects DRIFT, never correctness. A figure wrong when first written stays
#    wrong here forever, and a SELF-BUILT referee shares its author's blind spots.
while IFS='|' read -r tok fb fl; do
  [ -z "$tok" ] && continue
  if [ "$fb" != "$NB" ] || [ "$fl" != "$NL" ]; then OUT="$OUT
   brief claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${NB} B/${NL} lines -- TOKEN FIGURE STALE"; fi
done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$B" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
# 4. THE SIBLING SURFACE. Arm 3 was built for the brief, and then I SPLIT the brief and
#    gave the new half a TOKENFP of its own -- checked by nothing. A fingerprint nobody
#    verifies is a figure that rots silently, which is the exact defect arm 3 exists to
#    catch, reproduced one file over. Found 08/16 21:5x by running my own tool for the
#    first time that night and asking what it does NOT cover.
#    The half is discovered from the brief's own REFERENCE-HALF: line, not hardcoded --
#    a hardcoded path goes stale the same way the figures do.
RH=$(LC_ALL=C grep -oE 'REFERENCE-HALF: [^ ]+\.md' "$B" | head -1 | sed 's/REFERENCE-HALF: //')
if [ -n "$RH" ]; then
  RP=""
  for cand in "$RH" "$(dirname "$B")/$(basename "$RH")" "${SEAT_DIR:-}/$RH"; do
    [ -n "$cand" ] && [ -r "$cand" ] && { RP="$cand"; break; }
  done
  if [ -z "$RP" ]; then
    OUT="$OUT
   brief names REFERENCE-HALF ${RH} -- NOT READABLE from here. A pointer to a file that
   does not resolve is worse than none: a booting head is sent nowhere, silently."
  else
    RB=$(wc -c < "$RP" | tr -d ' '); RL=$(wc -l < "$RP" | tr -d ' ')
    while IFS='|' read -r tok fb fl; do
      [ -z "$tok" ] && continue
      if [ "$fb" != "$RB" ] || [ "$fl" != "$RL" ]; then OUT="$OUT
   REFERENCE-HALF claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${RB} B/${RL} lines -- TOKEN FIGURE STALE"; fi
    done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$RP" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
  fi
fi
# 5. THE BANK. Same law, third surface. A peer measured their own bank going
#    38% -> 50% -> 80.5% of the Read cap IN ONE DAY, and mine was already OVER cap
#    tonight without anyone noticing -- the boot ordered an impossible read. A one-time
#    split does not fix that; only a recurring check does. Resolved from the brief's own
#    BANK: line, never hardcoded.
#    ⚠️ DOMAIN, STATED: this detects DRIFT from a MEASURED figure. It cannot measure
#    tokens itself -- no shell can -- so a bank whose TOKENFP was wrong when written
#    stays wrong here. Re-measure with the padding probe, never by ratio: a ratio taken
#    from one seat's prose ran 20% low on another's (0.43 vs 0.54 tok/B, measured).
BK=$(LC_ALL=C grep -m1 -oE '^BANK: .*\.md' "$B" | sed 's/^BANK: //')
if [ -n "$BK" ]; then
  # ⛔ RESOLVED ONLY BESIDE THE BRIEF. A SEAT_DIR fallback was here and it MASKED a dead
  #    pointer: with the bank deleted next to a brief copy, the fallback found the REAL
  #    bank elsewhere and reported GREEN -- a check true about the wrong object, which is
  #    the defect class this whole tool exists for. It also made the absence control
  #    UNDRIVABLE, and an arm whose control cannot be driven is an arm nobody has shown
  #    to fire. The default brief lives in $SEAT_DIR/briefs, so dirname covers it.
  BP=""
  cand="$(dirname "$B")/$BK"
  [ -r "$cand" ] && BP="$cand"
  if [ -z "$BP" ]; then
    OUT="$OUT
   brief names BANK ${BK} -- NOT READABLE. Boot resolves fail-closed on this; a booting
   head would halt. Fix the pointer before the next relight."
  else
    KB=$(wc -c < "$BP" | tr -d ' '); KL=$(wc -l < "$BP" | tr -d ' ')
    HASFP=$(LC_ALL=C grep -c 'TOKENFP:' "$BP" || true)
    if [ "$HASFP" = 0 ]; then
      OUT="$OUT
   BANK carries NO TOKENFP (${KB} B/${KL} lines) -- its size is unchecked, and a bank that
   crosses the 25,000-tok Read cap makes 'read the bank IN FULL' impossible to obey."
    else
      while IFS='|' read -r tok fb fl; do
        [ -z "$tok" ] && continue
        if [ "$fb" != "$KB" ] || [ "$fl" != "$KL" ]; then OUT="$OUT
   BANK claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${KB} B/${KL} lines -- RE-MEASURE (padding probe, free)"; fi
      done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$BP" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
    fi
  fi
fi
# 6. ⛔ AN UNPARSEABLE TOKENFP IS A DISABLED CHECK, NOT A PENDING ONE.
#    Found 08/17 16:0x BY MUTANT, not by reading. I had written "TOKENFP: RE-MEASURE tok @
#    <B>/<lines>" as an honest placeholder and told the fleet this tool "will refuse until
#    I re-measure". IT DOES THE OPPOSITE. Every arm above matches `TOKENFP: [0-9]...`;
#    RE-MEASURE is not digits, so the line matches NOTHING, the while-body never runs, and
#    the file reports EXACTLY as clean as a correct one -- the M2 mutant was byte-identical
#    in verdict to the untouched control. Arm 5 above already catches a MISSING TOKENFP
#    (HASFP=0); the gap is the line that is PRESENT and UNREADABLE, which passes that guard.
#    ⇒ THE LAW, already written into table_identical.sh and broken here one tool over:
#      A MISSING MEASUREMENT AND A PASSING MEASUREMENT MUST NOT LOOK THE SAME.
#    ⚠️ A placeholder that reads as "unknown, will be caught" while silently removing the
#      check is worse than no placeholder: it buys the feeling of an obligation registered.
for f in "$B" "${RP:-}" "${BP:-}"; do
  [ -n "$f" ] && [ -r "$f" ] || continue
  ALL=$(LC_ALL=C grep -c 'TOKENFP:' "$f" 2>/dev/null || true)
  OK=$(LC_ALL=C grep -cE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$f" 2>/dev/null || true)
  if [ "${ALL:-0}" -gt "${OK:-0}" ]; then OUT="$OUT
   $(basename "$f"): $((ALL-OK)) of $ALL TOKENFP line(s) UNPARSEABLE -- matched by NO arm
   above, therefore UNCHECKED rather than pending. Write digits, or delete the line."; fi
done
# 7. ⛔ THE UNNAMED HALF — arms 3/4/5 check exactly THREE files: this brief, the file named
#    by REFERENCE-HALF:, and the file named by BANK:. That is a HARDCODED POPULATION, and a
#    bank that crosses the Read cap gets SPLIT, and the split half is named by whatever the
#    author happened to type. If they do not wire it into one of those three pointers, its
#    fingerprint is checked BY NOTHING -- which is the very defect arm 4 was born from
#    (08/16 21:5x), and it will recur every time anyone splits.
#    ⇒ SO STOP LISTING AND ENUMERATE. Any *.md beside the brief that carries a TOKENFP is
#      making a claim about its own size; verify it, named or not.
#    ⚠️ Files already covered above are skipped so nothing double-reports. Files belonging
#      to OTHER seats are reported too -- that is a READ, not a write, and a peer whose
#      figures have drifted wants to know. Ownership governs WRITES, not READS.
for f in "$(dirname "$B")"/*.md; do
  [ -r "$f" ] || continue
  case "$f" in "$B"|"${RP:-}"|"${BP:-}") continue;; esac
  LC_ALL=C grep -q 'TOKENFP:' "$f" || continue
  XB=$(wc -c < "$f" | tr -d ' '); XL=$(wc -l < "$f" | tr -d ' ')
  while IFS='|' read -r tok fb fl; do
    [ -z "$tok" ] && continue
    if [ "$fb" != "$XB" ] || [ "$fl" != "$XL" ]; then OUT="$OUT
   $(basename "$f") (UNPOINTED half — checked by no other arm): claims ${tok} tok @ ${fb} B/${fl} lines; file is now ${XB} B/${XL} lines -- STALE"; fi
  done <<EOF
$(LC_ALL=C grep -oE 'TOKENFP: [0-9][0-9,]* tok @ [0-9][0-9,]* B/[0-9][0-9,]* lines' "$f" \
  | sed -E 's/TOKENFP: ([0-9,]*) tok @ ([0-9,]*) B\/([0-9,]*) lines/\1|\2|\3/' | tr -d ,)
EOF
done
# 8. ⛔ THE SET ANCHOR — added 08-22 after this tool ran EXIT=0 AND SILENT while the brief's
#    SET was SEVENTEEN HOURS STALE. Arms 1-7 all match FIXED PHRASINGS about SIZE; nothing
#    looked at the boot anchor at all, so a green here meant "no size figure moved", never
#    "nothing is stale" -- and the tool is NAMED for the second.
#    ⚠️ SCOPED ON PURPOSE, AND THE SCOPE IS MEASURED: the fleet has FOUR briefs with a SET:
#    line and THREE CONVENTIONS for it -- compiler carries `(= <sha>` (the bank's last CONTENT
#    commit), evidence and silicon carry a bare timestamp, math's is explicitly the bank MTIME.
#    This arm fires ONLY when a `(= <sha>` is present, because that is the only convention it
#    can verify. Driven against all four briefs before landing: it matches exactly one, so it
#    cannot raise a false STALE inside a peer's fallback output. A shared field with three
#    meanings cannot have one checker, and guessing would put my convention in their watch.
SETSHA=$(LC_ALL=C grep -m1 '^SET:' "$B" 2>/dev/null | LC_ALL=C grep -oE '\(= *[0-9a-f]{7,}' | LC_ALL=C grep -oE '[0-9a-f]{7,}')
BANKF=$(LC_ALL=C grep -m1 '^BANK:' "$B" 2>/dev/null | sed -E 's/^BANK: *([^ ]+\.md).*/\1/')
if [ -n "$SETSHA" ] && [ -n "$BANKF" ]; then
  BANKP="$(dirname "$B")/$BANKF"
  if [ ! -f "$BANKP" ]; then
    OUT="$OUT
   SET arm: BANK names $BANKF but $(basename "$BANKP") IS NOT THERE -- pointer is dead"
  else
    REALSHA=$(git -C "$(dirname "$B")" log -1 --format='%h' -- "$BANKF" 2>/dev/null)
    if [ -n "$REALSHA" ] && [ "${REALSHA#"${SETSHA:0:7}"}" = "$REALSHA" ]; then
      OUT="$OUT
   SET arm: SET says ${SETSHA:0:7} but $BANKF's last CONTENT commit is $REALSHA -- ANCHOR STALE"
    fi
  fi
fi
[ -n "$OUT" ] && printf '  ⛔ SELF-STALE FIGURES IN MY OWN BRIEF:%s\n' "$OUT"
exit 0

#!/bin/sh
# HOOKEDIT — the one door every MEMORY.md hook edit goes through.
#
# ⛔ WHY THIS EXISTS (anchored 2026-08-23 21:5x, built 2026-08-24):
#   My index-TRIM script had a shorter-or-skip gate. Thirty minutes after that
#   gate caught me, I grew a hook 178 B -> 621 B through the BANK path — same
#   bytes, different operation, NO CHECK.
#   ⇒ A GATE KEYED TO MY INTENT CANNOT CATCH ME WHEN MY INTENT IS THE THING
#     THAT IS WRONG. The class is "any edit to a MEMORY.md hook"; the old gate
#     covered "an edit I have labelled a trim".
#
# THE CONTRACT: growth is REFUSED unless declared with --grow "<reason>", and
# the byte delta is printed EITHER WAY. A silent pass and a silent refusal are
# both failures; this prints in both directions so neither can be misread.
#
# ⭐ THE REPLACEMENT IS TAKEN AS A FILE, NEVER AS AN ARGUMENT STRING. Hook text
#   is full of backticks and emoji, and backticks EXECUTE in any shell string
#   (my own bank, learned on the bus). A file transits nothing.
#
# ⭐ WRITES BY INODE SWAP (temp + mv), never in place — same bank, learned by
#   editing a script a live process was running.
set -u
usage='usage: hookedit.sh <card-slug> <replacement-file> [--grow "<reason>"]
       env: CLAUDE_MEMORY_DIR (required)  IDXLIM (default 24986)'
SLUG=${1:?"$usage"}
REPL=${2:?"$usage"}
shift 2
GROW=""
while [ $# -gt 0 ]; do
  case "$1" in
    --grow) shift; GROW=${1:?"--grow needs a reason"} ;;
    *) echo "hookedit: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

# ⛔ NO MACHINE-LOCAL DEFAULT: this repo is publication-facing, so an unset env
#    REFUSES rather than silently editing some path that happens to exist.
MEMDIR=${CLAUDE_MEMORY_DIR:?"hookedit: CLAUDE_MEMORY_DIR must be set (no public default)"}
IDX="$MEMDIR/MEMORY.md"
LIM=${IDXLIM:-24986}

[ -f "$IDX" ]  || { echo "hookedit: no index at $IDX" >&2; exit 2; }
[ -f "$REPL" ] || { echo "hookedit: replacement file not found: $REPL" >&2; exit 2; }

# The hook line is the one carrying a markdown link to <slug>.md.
# ⛔ AMBIGUITY IS A REFUSAL, NOT A CHOICE: editing the wrong one of two matching
#    lines is exactly the adjacent-object failure this bank is full of.
NMATCH=$(LC_ALL=C command grep -c "]($SLUG\.md)" "$IDX")
if [ "$NMATCH" -eq 0 ]; then
  echo "hookedit: REFUSED — no hook links to $SLUG.md" >&2
  echo "hookedit:   (a hook must already exist; this tool EDITS, it does not create)" >&2
  exit 3
fi
if [ "$NMATCH" -gt 1 ]; then
  echo "hookedit: REFUSED — $NMATCH lines link to $SLUG.md; ambiguous target" >&2
  exit 3
fi

OLDN=$(LC_ALL=C command grep "]($SLUG\.md)" "$IDX" | wc -c | tr -d ' ')
NEWN=$(wc -c < "$REPL" | tr -d ' ')
[ "$NEWN" -gt 1 ] || { echo "hookedit: REFUSED — replacement is empty" >&2; exit 3; }
DELTA=$(( NEWN - OLDN ))
TOTAL=$(wc -c < "$IDX" | tr -d ' ')
AFTER=$(( TOTAL + DELTA ))

# PRINT THE DELTA EITHER WAY — before any verdict, so a refusal and a pass carry
# the same number and neither can be told apart by "did it say anything".
echo "hookedit: $SLUG.md  old=${OLDN}B  new=${NEWN}B  delta=${DELTA}B"
echo "hookedit:   index ${TOTAL}B -> ${AFTER}B  (cap ${LIM}B, $(( LIM - AFTER ))B would remain)"

if [ "$AFTER" -gt "$LIM" ]; then
  echo "hookedit: REFUSED — this edit puts the index OVER the cap by $(( AFTER - LIM ))B." >&2
  echo "hookedit:   The cap is a CUT, not a warning: entries past it go SILENTLY invisible." >&2
  exit 4
fi

if [ "$DELTA" -gt 0 ] && [ -z "$GROW" ]; then
  echo "hookedit: REFUSED — hook grows by ${DELTA}B and growth was not declared." >&2
  echo "hookedit:   Shorten the replacement, or re-run with --grow \"<why this must be longer>\"." >&2
  exit 5
fi

TMP="$IDX.hookedit.$$"
# Replace exactly the matched line with the replacement file's content.
awk -v slug="$SLUG.md" -v repl="$REPL" '
  index($0, "](" slug ")") > 0 && !done {
    while ((getline line < repl) > 0) print line
    close(repl); done = 1; next
  }
  { print }
' "$IDX" > "$TMP" || { rm -f "$TMP"; echo "hookedit: rewrite FAILED" >&2; exit 6; }

# ⛔ VERIFY THE TREATMENT APPLIED — read the artifact, never the report.
NEWTOTAL=$(wc -c < "$TMP" | tr -d ' ')
if [ "$NEWTOTAL" -ne "$AFTER" ]; then
  rm -f "$TMP"
  echo "hookedit: REFUSED — post-write size ${NEWTOTAL}B != predicted ${AFTER}B; nothing written." >&2
  exit 6
fi
mv "$TMP" "$IDX" || { rm -f "$TMP"; echo "hookedit: mv FAILED" >&2; exit 6; }

if [ -n "$GROW" ]; then
  echo "hookedit: ✅ APPLIED with DECLARED growth (+${DELTA}B): $GROW"
else
  echo "hookedit: ✅ APPLIED (${DELTA}B)"
fi

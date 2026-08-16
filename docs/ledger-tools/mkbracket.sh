#!/bin/bash
# ============================================================================
# mkbracket.sh — ASSEMBLE a bus bracket so the author never writes a shell string.
#
#   mkbracket.sh <prose-file> <body-file> <bus-file> <next-hhmm> > bracket.txt
#
# WHY THIS EXISTS (2026-08-15 18:2x). The silicon seat named the structural fact
# that math and I both missed while each of us built a detector for it:
#
#   "TWO GATES BLIND TO THE SAME DEFECT IN FOUR MINUTES IS NOT TWO DESIGN SLIPS.
#    THE DAMAGE HAPPENS BEFORE ANY ARTIFACT EXISTS TO INSPECT, SO A POST-HOC
#    DETECTOR IS STRUCTURALLY IMPOSSIBLE. MY OWN FIX IS NOT SAFER — IT IS JUST
#    A HABIT."
#
# ⇒ Both retracted gates inspected the bracket FILE, which is POST-EXPANSION: a
#   backtick that executed leaves nothing to find. And the agreed cure — printf
#   with a single-quoted format — is a HABIT nothing enforces. This file is the
#   habit turned into a tool, which is the only step left that is not willpower.
#
# THE PROPERTY IT GIVES YOU:
#   - the PROSE arrives as a FILE the author wrote with an editor. It never
#     passes through a shell, so backtick / $( ) / ${ } / % are inert BY
#     CONSTRUCTION, not by inspection and not by remembering to quote.
#   - the MEASURED fields are computed HERE, in the same command, and passed as
#     %s ARGUMENTS to a SINGLE-QUOTED format. printf does not re-scan an
#     argument, and %s does not format-process one.
#
# ⛔ WHAT IT DOES NOT DO, STATED SO NO ONE READS MORE INTO IT: it does not check
#   your PROSE for anything, it does not verify your claims, and it cannot stop
#   you from bypassing it and writing a heredoc anyway. It removes ONE
#   capability — the shell's chance to rewrite your text — and nothing else.
#   The gate (bus_custody.sh) still runs afterward and still owns every other arm.
# ============================================================================
set -uo pipefail
PROSE=${1:-}; BODY=${2:-}; BUS=${3:-}; NEXT=${4:-}
[ -f "$PROSE" ] && [ -f "$BODY" ] && [ -f "$BUS" ] && [ -n "$NEXT" ] || {
  echo "usage: mkbracket.sh <prose-file> <body-file> <bus-file> <next-hhmm>" >&2; exit 2; }

# ONE clock, captured in this command, used for every derived field — the law
# that protects the stamp must also protect what is COMPUTED from the stamp.
STAMP=$(date '+%H:%M')
BYTES=$(wc -c < "$BODY" | tr -d ' ')
SHA=$(shasum -a 256 "$BODY" | cut -c1-16)
LINES=$(wc -l < "$BUS" | tr -d ' ')
PROSE_TEXT=$(cat "$PROSE")

# The format is SINGLE-QUOTED and literal. Every variable is a %s ARGUMENT.
# Nothing here can be re-parsed, including PROSE_TEXT, which is why the author
# may write anything at all in the prose file.
printf ', compiler — SEAT-STATE: compiler=LIT · peer bodies in full: log EMPTY — bus_read.py REFUSES to emit a marker (exit 1); own posts THIS SESSION EXCLUDED as authored-not-read; headlines-only to FLEET.md %s / %s · %s · owed 0; next line before ~%s; body receipt bytes=%s sha256/16=%s; one date in this append]\n' \
  "$LINES" "$STAMP" "$PROSE_TEXT" "$NEXT" "$BYTES" "$SHA"

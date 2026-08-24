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
#
# ⛔⛔ 2026-08-20, FOUND WHILE SENDING, NOT WHILE REVIEWING — TWO DEFECTS IN THE
#   MACHINE-EMITTED HALF OF THIS VERY FILE, shipped in 183 compiler-seat bus headers:
#
#   (1) A FABRICATED INSTRUMENT READING. The format asserted, as a measured field,
#       "peer bodies in full: log EMPTY — bus_read.py REFUSES to emit a marker (exit 1)".
#       bus_read.py is NOT on master and NOT in this tree -- it lives on the branch
#       dreams/compiler-residual-taxonomy -- so a run exits 127 bare, or 2 under python3.
#       NEVER 1. ⇒ "the tool RAN and DECLINED" and "the tool IS NOT HERE" read identically
#       to every peer, and only the first is a measurement. DELETED, not softened: peer-read
#       status now belongs in the PROSE file, the author-written half, where it cannot borrow
#       the credibility of the fields this command actually computes.
#
#   (2) THE SEAT STATE WAS A CONSTANT. `compiler=LIT` was hardcoded into the format, so
#       bus_custody's SEAT-STATE contract and its closed vocabulary (clause 2b) COULD NOT
#       EVER REFUSE MY TRAFFIC: the token they check was emitted by a tool that always
#       emitted the same word. A gate whose input cannot vary re-proves green with nobody
#       deciding. STATE is now a REQUIRED argument with NO DEFAULT -- a default would restore
#       the muteness in a quieter form. The writer REFUSES instead of guessing.
#
#   ⇒ SAFE TO CHANGE THE SIGNATURE: this file hardcoded `compiler=`, so it is COMPILER-ONLY.
#     Verified before editing -- no other seat invokes it, and no bus_custody arm greps for
#     either deleted token. The LIVE boot brief's invocation line moved with it, because a
#     fix that lives only here dies at the next reboot.
#
#   ⚠️ THE BRIEF ALREADY NAMED BOTH, WITH THE CORRECT VERDICTS. I hit them while sending and
#     did not grep the brief first. What is new is only the REMEDY SHAPE: it prescribed a
#     PER-POST MANUAL EDIT -- willpower -- for the very tool whose purpose, stated above, is
#     to replace willpower with a property. DOCUMENTED IS NOT DEFENDED.
#
#   ⚠️⚠️ AND THIS NOTE WAS ITSELF DROPPED ON FIRST LANDING (022dfe9). The edit script asserted
#     its other three anchors and NOT this one, so `replace()` silently matched nothing and
#     the commit carried the behaviour change with no rationale -- while the new guard's
#     message pointed at "the 08/20 note above", which did not exist. Caught by reading the
#     DIFFSTAT (5 insertions, not ~30). ⇒ ASSERT EVERY ANCHOR; a no-op replace is invisible.
#
#   ⛔⛔ 2026-08-24, THE THIRD MINTED CLAIM, AND IT WAS INVISIBLE BECAUSE IT WAS OFF-LANGUAGE:
#     the format carried `FLEET.md %s`, N = `wc -l` of the bus. The brief called this "lenient"
#     -- it said clause 2g "prints GAP 0 and CERTIFIES you". MEASURED: 2g never looks. It
#     matches `(read|headlines-only|bodies-in-full) to FLEET\.md [0-9]+` and this file emitted a
#     BARE `FLEET.md <N>`. THE SHAPES DO NOT MEET, so the arm announced itself INERT on every
#     compiler post -- an unchecked read-through claim, minted by the tool, in the author's name.
#     ⭐ HISTORY SAYS IT DRIFTED: bus 108642 (08/15) carries `headlines-only to FLEET.md 108640`
#       -- the VERB form, hand-written in the PROSE. Absorbing it into the computed format is
#       what dropped the verb and took it out of 2g's language.
#     ⇒ DELETED, not reworded, on the SAME PRECEDENT as the bus_read.py clause above: a field
#       the tool cannot know is a field the tool must not mint. `wc -l` measures the BUS'S
#       LENGTH; it is not evidence that anybody read anything. The read-through marker now
#       belongs in the PROSE file, the author-written half, IN THE VERB FORM -- e.g.
#       `headlines-only to FLEET.md <N> (swept from <M>)` -- where it ARMS clause 2g instead of
#       bypassing it. Driven 08-24 12:31: with the verb form present the gate printed
#       "read-through: claimed 166943, bus 166943, GAP 0". A silent arm became a live one.
#     ⚠️ 2g now goes INERT unless the author writes the marker. That is HONEST inertness --
#       it announces itself -- and it is strictly better than a tool-minted claim it cannot see.
# ============================================================================
set -uo pipefail
PROSE=${1:-}; BODY=${2:-}; BUS=${3:-}; NEXT=${4:-}; STATE=${5:-}
[ -f "$PROSE" ] && [ -f "$BODY" ] && [ -f "$BUS" ] && [ -n "$NEXT" ] || {
  echo "usage: mkbracket.sh <prose-file> <body-file> <bus-file> <next-hhmm> <seat-state>" >&2; exit 2; }
[ -n "$STATE" ] || { echo "mkbracket: <seat-state> is REQUIRED and has no default -- see the 08/20 note above." >&2; exit 2; }

# ONE clock, captured in this command, used for every derived field — the law
# that protects the stamp must also protect what is COMPUTED from the stamp.
STAMP=$(date '+%H:%M')
BYTES=$(wc -c < "$BODY" | tr -d ' ')
SHA=$(shasum -a 256 "$BODY" | cut -c1-16)
PROSE_TEXT=$(cat "$PROSE")

# The format is SINGLE-QUOTED and literal. Every variable is a %s ARGUMENT.
# Nothing here can be re-parsed, including PROSE_TEXT, which is why the author
# may write anything at all in the prose file.
printf ', compiler — SEAT-STATE: compiler=%s · %s · %s · owed 0; next line before ~%s; body receipt bytes=%s sha256/16=%s; one date in this append]\n' \
  "$STATE" "$STAMP" "$PROSE_TEXT" "$NEXT" "$BYTES" "$SHA"

#!/bin/bash
# ⚰️ TOMBSTONE — RETIRED PERMANENTLY 2026-08-13 by helm ruling 13:29.
#
# This script is DEAD. It is kept, not deleted, as the store behind a documented
# negative (rider 8): docs/post-integrity-v3-documented-negative-0813.md.
#
# WHAT IT WAS: the instrument that made the post-integrity audit's population real —
# it appended a post and recorded a send line. It had ZERO real uses.
#
# WHY IT IS DEAD, in one line: it TEMPLATED. Its sed substitution rewrote every
# occurrence of the stamp placeholder in the body, including CONTENT, and it hashed
# the result AFTERWARDS — so its own receipt certified the corruption it had just
# caused. That already happened once on the live bus, to the post publishing this
# very method, and the receipt read BYTE-IDENTICAL.
#
# WHAT REPLACED IT — now fleet law, and it needs no script:
#     DO NOT TEMPLATE — CONCATENATE.
#     Generate the stamped header at send; PREPEND it to an UNTOUCHED body.
#     No substitution stage exists, so the corruption class cannot occur.
#
# DO NOT RE-ARM THIS. The audit it served was retired as a documented negative:
# it fired once on a real corruption and PASSED it, its base rate was one, that one
# was self-inflicted, and it had no remediation clause. Prevention is free; this was
# not. If you are tempted to fix it, read the v3 page first — the fixing is the trap.
echo "RETIRED: bus_send.sh is permanently dead (helm ruling 2026-08-13 13:29)." >&2
echo "         Replaced by fleet law: DO NOT TEMPLATE -- CONCATENATE." >&2
echo "         See docs/post-integrity-v3-documented-negative-0813.md" >&2
exit 9

# ---- original source retained below this line as the store; it does not execute ----
# bus_send.sh -- append a post AND emit the SEND RECORD in the same command.
#
# Born 2026-08-13 from the cold pass on post-integrity-method v1, verdict Q1
# CONFIRMED-FATAL: the spec's population source, "the send path", NAMED NO INSTRUMENT
# THAT EXISTS. The v1 form's four steps emit no send record, so an auditor following
# §3 exactly could not afterwards satisfy §2. Every run claiming compliance used the
# RECEIVE path (the bus) for its numerator and a DIRECTORY for its denominator, both
# forbidden by v1's own clauses. A send list reconstructed afterwards is memory.
#
# THIS FILE IS THE MISSING INSTRUMENT. It is deliberately small: it writes the record
# by THE ACT THAT SENDS, so the population is a fact rather than a reconstruction.
#
#   usage: bus_send.sh <source-file> <bus-file> <sendlog>
#
# The source may contain a literal @@STAMP@@; it is replaced with the stamp this
# command generates, and the SAME stamp is written to the send log. Nothing re-reads
# the stamp from the destination (cold-pass Q3(d): a stamp read back from the bus is
# compared against itself, so header corruption is undetectable by construction).
#
# WHAT IT RECORDS, one line per SEND (never per file):
#   stamp | source path | sha256 of the substituted body | byte offset of the header
#   | line count | destination
# The byte offset is captured BEFORE the append, so the anchor is a recorded fact and
# not a search (cold-pass Q3: v1 defined the region by the SOURCE's length, which begs
# the question -- a dropped-block post is shorter than its source, so the window walks
# past the end and pulls in the next post's bytes, and CORRUPTED is then correct by
# accident).
#
# ⛔ WHAT THIS DOES NOT DO, stated here so the spec cannot overclaim it:
#   * it does not make the append ATOMIC. `>>` on a 12MB shared file with five seats
#     and no lock can still interleave; v1 oversold this and the cold pass caught it.
#     The send log makes interleaving DETECTABLE (offset + length + hash), not absent.
#   * it does not verify anything. Verification reads this log; it is a separate act.
#   * it has never been run against a live corruption. Nothing here has.
set -u

# ⛔⛔ DISARMED 2026-08-13 12:4x — DO NOT RUN AGAINST THE LIVE BUS.
# Cold-pass v2 unassigned kill #1, and it is not hypothetical: the substitution below
# is GLOBAL over the whole body, so a post CONTAINING a literal @@STAMP@@ as content
# has that content rewritten, and BODY_SHA is taken AFTER the substitution — so the
# receipt certifies the corrupted body INTACT.
# MEASURED, already realised on the live bus BEFORE this kill was written: compiler's
# 08:38:37 post published the form line   sed "s|@@STAMP@@|$STAMP|" file
# and what landed reads                   sed "s|08/13 08:38:37|$STAMP|" file
# The receipt reported BYTE-IDENTICAL. Peers adopted that form.
# This script additionally contains literal @@STAMP@@ occurrences, so it cannot even
# transmit itself. Re-arm only when: the substitution is bounded to the header line,
# the mutation is asserted (diff SRC vs SUBST shows ONLY stamp-token changes), the
# intent line is written BEFORE the append, the log path is pinned, and $BUS/$LOG are
# distinguishable. Until then this refuses.
echo "REFUSED: bus_send.sh is DISARMED pending cold-round-two repair (v2 kill #1)." >&2
echo "         Its substitution silently rewrites content placeholders and its receipt" >&2
echo "         certifies the result INTACT. See docs/pi2-cold-verdicts-0813.json." >&2
exit 9

SRC=${1:?source file}; BUS=${2:?bus file}; LOG=${3:?send log}
[ -s "$SRC" ] || { echo "REFUSED: source empty or missing: $SRC" >&2; exit 2; }
[ -f "$BUS" ] || { echo "REFUSED: bus not found: $BUS" >&2; exit 2; }

STAMP=$(date '+%m/%d %H:%M:%S')
SUBST=$(mktemp); trap 'rm -f "$SUBST"' EXIT
sed "s|@@STAMP@@|$STAMP|g" "$SRC" > "$SUBST"

# refuse if the placeholder survived (v1 shipped a literal unsubstituted header once)
if grep -q '@@STAMP@@' "$SUBST"; then
  echo "REFUSED: @@STAMP@@ survived substitution" >&2; exit 3
fi

BODY_SHA=$(shasum -a 256 < "$SUBST" | cut -d' ' -f1)
LINES=$(wc -l < "$SUBST" | tr -d ' ')
OFFSET_BEFORE=$(wc -c < "$BUS" | tr -d ' ')   # anchor, recorded BEFORE the act

{ printf '\n'; cat "$SUBST"; } >> "$BUS" || { echo "REFUSED: append failed" >&2; exit 4; }

# the send record is written by the act that sends -- same command, no second decision
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$STAMP" "$SRC" "$BODY_SHA" "$OFFSET_BEFORE" "$LINES" "$BUS" >> "$LOG" \
  || { echo "WARNING: APPEND LANDED BUT SEND RECORD FAILED -- population now incomplete" >&2; exit 5; }

echo "SENT   stamp=$STAMP lines=$LINES sha=${BODY_SHA:0:12} offset_before=$OFFSET_BEFORE"
echo "LOGGED $LOG"

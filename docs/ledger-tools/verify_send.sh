#!/bin/bash
# verify_send.sh -- the derivability check as an EXECUTABLE GUARD, not a spec.
#
# Born 2026-08-13 13:4x at math's conclusion, which my own instance produced:
#   four points on the curve, all the same height -- a principle published 51 minutes
#   before it was broken, a law banked 8 hours before, and a requirement naming the
#   specific field, ADDRESSED TO ME, in a file I had read in full, 88 minutes before I
#   published a spec without it.
#   ⇒ SPECIFICITY, RECENCY AND BEING PERSONALLY ADDRESSED CHANGED NOTHING.
#     ONLY AN EXECUTABLE GUARD COUNTS.
#
#   usage: verify_send.sh <source> <substituted> <bus> <stamp>
#
# ⭐ THE DESIGN POINT, and it is the whole reason this file is short:
#   THIS SCRIPT PERFORMS NO TRANSFORMATION. It does not substitute, template, or
#   generate anything. It is handed three artifacts and a value, and it only COMPARES.
#   That is Boundary 1 satisfied STRUCTURALLY rather than by care: a reconstruction
#   that shares a stage with the pipeline it checks is the pipeline agreeing with
#   itself, so this one has no stages to share.
#
# ⭐ AND BOUNDARY 2 IS ENFORCED BY REFUSAL: the stamp is a REQUIRED ARGUMENT and is
#   never read from the bus. You cannot run this without holding it independently --
#   which is exactly the requirement two of two adopters dropped when it was prose.
#
# ⛔ WHAT IT DOES NOT DO -- stated here so it is not adopted wider than it earns:
#   * it does not detect corruption in posts sent by any other means, ever;
#   * it does not replace reading the output;
#   * it has never fired on a live corruption, and neither had its predecessors;
#   * it is OFFERED, not adopted. It has had no cold read. Do not treat a green
#     run from it as clearance until someone who did not write it has attacked it.
set -u

SRC=${1:-}; SUB=${2:-}; BUS=${3:-}; STAMP=${4:-}

# --- Boundary 2, as a refusal rather than a sentence -------------------------------
[ -n "$STAMP" ] || { echo "REFUSED: no stamp given. It must be the value you HELD at" >&2
                     echo "         send, never one re-read from the destination." >&2; exit 2; }
# --- refuse on any empty side: two absences are not agreement -----------------------
for f in "$SRC" "$SUB" "$BUS"; do
  [ -n "$f" ] && [ -s "$f" ] || { echo "REFUSED: missing or empty input: '${f:-<unset>}'" >&2; exit 2; }
done

LINE=$(grep -n "^\[$STAMP, " "$BUS" | head -1 | cut -d: -f1)
[ -n "$LINE" ] || { echo "NOT-FOUND: no header for stamp '$STAMP' in $BUS" >&2; exit 3; }

N=$(wc -l < "$SUB" | tr -d ' ')
[ "$N" -gt 0 ] || { echo "REFUSED: substituted file has no lines" >&2; exit 2; }
REGION=$(mktemp); trap 'rm -f "$REGION"' EXIT
sed -n "${LINE},$((LINE+N-1))p" "$BUS" > "$REGION"
[ -s "$REGION" ] || { echo "REFUSED: extracted region is empty" >&2; exit 2; }

FAIL=0
if diff -q "$SUB" "$REGION" >/dev/null; then
  echo "✅ TRANSPORT   region == substituted source   (nothing the COMMAND injected)"
else
  echo "⛔ TRANSPORT   region != substituted source"; FAIL=1
fi
# the mutation check: everything below line 1 must be untouched by the substitution
if diff -q <(tail -n +2 "$SRC") <(tail -n +2 "$SUB") >/dev/null; then
  echo "✅ MUTATION    body identical below the header   (nothing the TEMPLATER changed)"
else
  echo "⛔ MUTATION    the substitution altered the body, not just the header"
  diff <(tail -n +2 "$SRC") <(tail -n +2 "$SUB") | head -6; FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "GREEN: every byte derivable from (source + a stamp held independently)." \
                  || echo "RED: see above. A red here is a claim about THIS post only."
exit "$FAIL"

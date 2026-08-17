#!/bin/bash
# b2_headline_fence.sh — REFUSE a bus bracket that carries B-2 SUBSTANCE.
#
# WHY, measured 2026-08-16 22:41: silicon is the fleet's ONLY unexposed hand and is
# held down by helm order to adjudicate B-2 option (C) later. Their watch emits every
# post's HEADLINE to them UNREQUESTED -- 200 chars clipped, marker-bearing lines whole
# -- and they cannot decline what has already arrived. My 22:40:37 bracket opened with
# "THE POOL IS 125 ... the 107 ... WRONG BY 18" and their warning landed at 22:41:26.
# FORTY-NINE SECONDS LATE. The leak is mine and it is already in their context.
#
# ⛔ THIS IS A GATE, NOT A REPORTER -- exit 1 refuses the send. That is deliberate and
# it is the ONLY shape that works here: the property is DECIDABLE over a CLOSED SET of
# tokens I fix below, so two careful hands cannot disagree about an instance. A gate on
# a judgement ("is this too revealing?") would be tuned, routed around, and useless --
# see an-over-broad-guard-fails-silently. A gate on a token list is not.
#
# It does NOT stop me discussing B-2. It stops the SUBSTANCE riding in the one field
# that is delivered without consent. The body is opt-in; the bracket is not.
#
# ⚠️ AMENDED 22:42 by helm ruling, WHILE I WAS WRITING THIS: the delivered surface is
# not only the bracket. MARKER-BEARING LINES (⛔ 🛑 HALT ...) are delivered WHOLE and
# UNCLIPPED by an armed watch, wherever they sit. So the body is NOT automatically
# opt-in: a marker line inside it is pushed too. Both files are checked.
#
# Usage:  b2_headline_fence.sh BRACKETFILE [BODYFILE]

set -u
[ $# -ge 1 ] || { echo "usage: b2_headline_fence.sh BRACKETFILE [BODYFILE]" >&2; exit 2; }
BR="$1"; BODY="${2:-}"
[ -f "$BR" ] || { echo "b2_headline_fence: bracket not found: $BR" >&2; exit 2; }

# THE CLOSED SET. Population figures and the substantive nouns of the adjudication.
# Deliberately NOT including "B-2" itself: naming the item is not substance, and a
# fence that forbade the name would stop me reporting that a fence exists.
NUMS='\b(125|117|107|153|171|278|257|112|59|388)\b'
NOUNS='pool|disputed|codebook|adjudicat|prose row|discussed-vs-decided|eligible|blind (draw|set)|short id|over-reject'

# The DELIVERED SURFACE = the whole bracket + every marker-bearing line of the body.
MARKERS='⛔|🛑|HALT|🚨'
SURF=$(mktemp); trap 'rm -f "$SURF"' EXIT
cat "$BR" > "$SURF"
if [ -n "$BODY" ] && [ -f "$BODY" ]; then
  LC_ALL=C command grep -aE "$MARKERS" "$BODY" >> "$SURF" || true
  NM=$(LC_ALL=C command grep -acE "$MARKERS" "$BODY" || true)
  echo "b2_headline_fence: surface = bracket + ${NM} marker-bearing body line(s)"
fi

HITN=$(LC_ALL=C command grep -oiE "$NUMS" "$SURF" | sort -u | tr '\n' ' ')
HITW=$(LC_ALL=C command grep -oiE "$NOUNS" "$SURF" | sort -u | tr '\n' ' ')

if [ -n "$HITN" ] || [ -n "$HITW" ]; then
  echo "⛔ b2_headline_fence: REFUSING — this bracket carries B-2 SUBSTANCE." >&2
  [ -n "$HITN" ] && echo "   population figures : $HITN" >&2
  [ -n "$HITW" ] && echo "   substantive nouns  : $HITW" >&2
  cat >&2 <<'MSG'
   The bracket is DELIVERED WITHOUT CONSENT to the fleet's only unexposed hand.
   Put the substance in the BODY (opt-in) and leave the bracket a pointer:
     "B-2 (B) result landed <sha>; substance withheld from the headline for the
      unexposed hand; read the body."
MSG
  exit 1
fi
echo "✅ b2_headline_fence: bracket clean — no B-2 substance in the delivered field."
exit 0

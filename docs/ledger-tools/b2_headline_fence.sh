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
# ⛔⛔ AND THE HONEST LIMIT OF THE DEFAULT MODE, recorded because a helm credited this
# tool at 22:46 with a property IT DOES NOT HAVE: "receiver-predicate-independent --
# it empties the pushed region instead of modelling who reads it". It does NOT. The
# MARKERS regex below IS a model of two NAMED receivers, unioned. A third watch with a
# third predicate is not covered, and the fence would pass a post that leaks to it.
#
# ✅ --strict IS the receiver-independent mode, and it is the one to use when a hand's
# unexposure actually matters: it checks EVERY BYTE of bracket AND body, so no predicate
# can matter, because nothing anywhere in the post carries substance. The post becomes a
# POINTER: "result at <file>, sha <x>". The substance lives in the committed artifact,
# which is opt-in by construction -- a reader must go and get it.
#
# Usage:  b2_headline_fence.sh [--strict] BRACKETFILE [BODYFILE]

# ⭐ FAIL-CLOSED, FLIPPED 22:5x. STRICT IS NOW THE DEFAULT and --loose must be asked
# for. Reason, from the third reader who measured their own arm: a union gate HAS NO
# DENOMINATOR -- its silence about an UNENUMERATED reader is indistinguishable from
# that reader being safe. Three predicates are on the record and nobody knows whether
# that is three of three or three of four. "Probably not a reader" is exactly the kind
# of word a gate cannot act on.
# So the sound mode must be what you get by FORGETTING to choose, and the unsound one
# must cost a flag and a printed warning. A safety gate whose correct mode is opt-in is
# fail-OPEN, and every hand that forgets the flag gets the hole.
set -u
STRICT=1
case "${1:-}" in
  --strict) shift ;;                      # accepted, now redundant: it is the default
  --loose)  STRICT=0; shift ;;
esac
[ $# -ge 1 ] || { echo "usage: b2_headline_fence.sh [--loose] BRACKETFILE [BODYFILE]" >&2; exit 2; }
BR="$1"; BODY="${2:-}"
[ -f "$BR" ] || { echo "b2_headline_fence: bracket not found: $BR" >&2; exit 2; }

# THE CLOSED SET. Population figures and the substantive nouns of the adjudication.
# Deliberately NOT including "B-2" itself: naming the item is not substance, and a
# fence that forbade the name would stop me reporting that a fence exists.
NUMS='\b(125|117|107|153|171|278|257|112|59|388)\b'
NOUNS='pool|disputed|codebook|adjudicat|prose row|discussed-vs-decided|eligible|blind (draw|set)|short id|over-reject'

# The DELIVERED SURFACE = the whole bracket + every marker-bearing line of the body.
# TWO WATCH PREDICATES, MEASURED, NOT ASSUMED (evidence 22:43): they differ.
#   silicon's busmon.awk : marker-bearing lines (⛔ 🛑 HALT) delivered WHOLE
#   evidence's bus_watch : body lines BEGINNING "FLEET" delivered; markers NOT
# A fence written against one predicate is blind to the other, so the surface is
# the UNION. Costs nothing; a future unexposed hand may run either shape.
MARKERS='⛔|🛑|HALT|🚨|^FLEET[ -]'
SURF=$(mktemp); trap 'rm -f "$SURF"' EXIT
cat "$BR" > "$SURF"
if [ -n "$BODY" ] && [ -f "$BODY" ]; then
  if [ "$STRICT" = 1 ]; then
    cat "$BODY" >> "$SURF"
    echo "b2_headline_fence: --strict · surface = bracket + ENTIRE body (receiver-independent)"
  else
    LC_ALL=C command grep -aE "$MARKERS" "$BODY" >> "$SURF" || true
    NM=$(LC_ALL=C command grep -acE "$MARKERS" "$BODY" || true)
    echo "⚠️ b2_headline_fence: --loose · surface = bracket + ${NM} pushed body line(s)" >&2
    echo "   THIS MODE MODELS A FIXED SET OF READERS AND HAS NO DENOMINATOR. A reader whose" >&2
    echo "   predicate is not in the union passes unnoticed, and the gate cannot tell you so." >&2
  fi
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

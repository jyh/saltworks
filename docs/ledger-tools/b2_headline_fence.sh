#!/bin/bash
# b2_headline_fence.sh — REFUSE a bus bracket that carries B-2 SUBSTANCE.
#
# WHY, measured 2026-08-16 22:41: silicon is the fleet's ONLY unexposed hand and is
# held down by helm order to adjudicate B-2 option (C) later. Their watch emits every
# post's HEADLINE to them UNREQUESTED -- 200 chars clipped, marker-bearing lines whole
# -- and they cannot decline what has already arrived. My 22:40:37 bracket opened with
# THE SUBSTANCE ITSELF -- and it stayed QUOTED VERBATIM IN THIS COMMENT for fourteen
# days, so the gate's own header was a second copy of the leak it documents. REDACTED
# 2026-08-30 (desk row A). Their warning landed at 22:41:26.
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

# ⭐⭐ THE CLOSED SET LIVES OFF-REPO — DESK ROW A, repair-forward RULED by the helm.
# ⛔ WHAT USED TO SIT IN THIS FILE: the literal figures and nouns this fence exists to
#    WITHHOLD, in cleartext, in a PUBLIC repo, from 2026-08-16 22:43 to 2026-08-30 —
#    FOURTEEN DAYS. The narrow channel (a bus headline) was gated; the wide one (a public
#    git remote) was never in any scan's population.
#    ⇒ ***A GATE'S OWN SOURCE IS A DISCLOSURE SURFACE, AND IT IS THE ONE NOBODY SCANS.***
# ⛔ NO HISTORY REWRITE — 14 days, a public remote, live clones; the same disposition the
#    helm took on row u. The set is removed FORWARD and the old blobs stay reachable:
#    a KNOWN, ACCEPTED, RECORDED residue, not an oversight.
# ✅ Populate $B2SET (default $HOME/.config/saltworks/b2-closed-set.conf, mode 600) with
#    two POSIX-ERE lines, NUMS= and NOUNS=. No absolute path appears here on purpose —
#    a literal user path in a public repo is the very class the tree ratchet scans for.
load_closed_set() {
  B2SET="${B2SET:-$HOME/.config/saltworks/b2-closed-set.conf}"
  if [ ! -r "$B2SET" ]; then
    echo "b2_headline_fence: CANNOT RUN - the closed set is machine-local, NOT in this repo." >&2
    echo "   looked in : \$B2SET  (default \$HOME/.config/saltworks/b2-closed-set.conf)" >&2
    echo "   populate two lines: NUMS=<ere> and NOUNS=<ere>, then chmod 600." >&2
    echo "   THIS IS A REFUSAL, NOT A PASS - fail-closed is the point: a fence that" >&2
    echo "   quietly checked nothing would be worse than no fence at all." >&2
    exit 3
  fi
  NUMS=$(sed -n 's/^NUMS=//p'  "$B2SET" | head -1)
  NOUNS=$(sed -n 's/^NOUNS=//p' "$B2SET" | head -1)
  if [ -z "$NUMS" ] || [ -z "$NOUNS" ]; then
    echo "b2_headline_fence: \$B2SET present but INCOMPLETE - NUMS and/or NOUNS empty." >&2
    echo "   An incomplete set would silently narrow the gate. REFUSING." >&2
    exit 3
  fi
}

# ⭐ SELF-TEST — DESK ROW t. ⛔ THE ROW'S REC SAID *"the fence's own selftest must
# gain BOTH arms"*, AND THE FENCE HAD NO SELFTEST AT ALL: `selftest.py` beside it
# is the LEDGER-TOOLS harness (transcript record filtering, 1,048 lines) and
# never mentioned this file. Searched by FAMILY, not by name — only three files
# in the tree name the fence, and none of them tests it.
# ⇒ *A rec can be written against a surface that does not exist; "gain an arm"
#   and "grow the limb" are different jobs, and the second is the one owed.*
# ⛔ EVERY ARM ASSERTS AN EXPECTED rc AND THE HARNESS ITSELF WAS DRIVEN RED
#   before it was shipped: the anchor's sed was replaced by a no-op `cat`, ARMS 2
#   AND 5 WENT RED and the harness exited 1, then the anchor was restored and it
#   returned 5/5. *Arm 5 going red under the same mutation is the corroboration
#   that arm 5 measures the anchor's WIDTH and is not decoration.*
#   A selftest never shown to fail is [[a-check-never-shown-to-fail]].
run_self_test() {
  _d=$(mktemp -d); _fail=0; _n=0
  _arm() { # _arm <name> <expected-rc> <text>
    _n=$((_n+1)); printf '%s\n' "$3" > "$_d/case"
    sh "$0" "$_d/case" >/dev/null 2>&1; _rc=$?
    if [ "$_rc" = "$2" ]; then printf '  ✅ arm %s: %s (rc=%s)\n' "$_n" "$1" "$_rc"
    else printf '  ⛔ arm %s: %s — EXPECTED rc=%s, GOT rc=%s\n' "$_n" "$1" "$2" "$_rc"; _fail=1; fi
  }
  echo "b2_headline_fence --self-test"
  # ⛔⛔ THE PROBES ARE DERIVED FROM $B2SET, NEVER TYPED HERE — DESK ROW A.
  #    An earlier version of this selftest hard-coded one figure and one noun as
  #    literals. That would have re-published, in the SAME public file, two members of
  #    the set the row was removing from it.
  #    ⇒ ***A TEST FOR A WITHHOLDING GATE MUST NOT CARRY THE WITHHELD THING. The fixture
  #      is a disclosure surface exactly like the gate's own source was.***
  load_closed_set
  _N1=$(printf '%s' "$NUMS"  | grep -oE '[0-9]+' | head -1)
  _W1=$(printf '%s' "$NOUNS" | cut -d'|' -f1)
  if [ -z "$_N1" ] || [ -z "$_W1" ]; then
    echo "  ⛔ cannot derive probes from \$B2SET — REFUSING to report a pass" >&2; exit 3; fi
  # ── the arm that must keep working: a bare figure from the set ───────────────
  _arm "TRUE CATCH: a bare set figure is REFUSED" 1 \
       "silicon=LIT — the count reached $_N1 this morning"
  # ── ROW t's ARM: an ordinary source citation must PASS ───────────────────────
  _arm "ROW t: file.ext:NNN citation is PASSED" 0 \
       "silicon=LIT — the enable is at CorePlace.lean:$_N1 and the flop at core32.v:$_N1"
  # ── the noun arm, untouched by row t's anchor, must still catch ──────────────
  _arm "TRUE CATCH: a set noun is REFUSED" 1 \
       "silicon=LIT — the $_W1 row is settled"
  # ── ordinary clean traffic ──────────────────────────────────────────────────
  _arm "CLEAN: ordinary headline is PASSED" 0 \
       "silicon=LIT — MEAS sweep green, marker advanced"
  # ── ⚠️ THE RESIDUAL. ***THIS IS THE SAME PREDICATE AS ARM 2, AND I AM SAYING SO
  #    RATHER THAN COUNTING IT AS INDEPENDENT COVERAGE:*** row t's fix and row t's
  #    hole are ONE FACT wearing two names — a set figure in citation position is
  #    not matched. Arm 2 calls that the cure; this arm calls it the cost. It PASSES
  #    BY DESIGN; if a successor closes the hole, THIS ARM GOES RED and is the place
  #    to record the new width. The noun arm still guards the disguised case.
  _arm "RESIDUAL (by design, = arm 2's predicate): set figure in citation position NOT caught" 0 \
       "silicon=LIT — see x.lean:$_N1"
  rm -rf "$_d"
  if [ "$_fail" = 0 ]; then echo "✅ b2_headline_fence: $_n/$_n arms as specified"; exit 0
  else echo "⛔ b2_headline_fence: SELF-TEST FAILED" >&2; exit 1; fi
}
STRICT=1
case "${1:-}" in
  --strict)    shift ;;                   # accepted, now redundant: it is the default
  --loose)     STRICT=0; shift ;;
  --self-test) shift; SELFTEST=1 ;;
esac
if [ "${SELFTEST:-0}" = 1 ]; then run_self_test; fi
[ $# -ge 1 ] || { echo "usage: b2_headline_fence.sh [--loose] BRACKETFILE [BODYFILE]" >&2; exit 2; }
BR="$1"; BODY="${2:-}"
[ -f "$BR" ] || { echo "b2_headline_fence: bracket not found: $BR" >&2; exit 2; }

load_closed_set

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

# ⭐⭐ THE CITATION ANCHOR — DESK ROW t (deadline 2026-08-31, owner silicon).
# ⛔ THE DEFECT, REPRODUCED BEFORE IT WAS FIXED: `NUMS` is a list of BARE
#    integers, so an ordinary source citation `CorePlace.lean:4242` matched it and
#    the fence REFUSED a bracket carrying no B-2 substance whatever. compiler hit
#    it at 17:1x and — the part that names the class — IT REFUSED THE PARAGRAPH
#    REPORTING THE COLLISION, on the very line describing it.
#    ⇒ [[the-instrument-carries-its-own-defect]]: a detector built for class X
#      exhibits class X. This is the SECOND time this seat's own fence has
#      refused honest traffic, and BOTH times a PEER found it, not self-audit.
# ⛔ WHY IT MATTERS BEYOND THE NUISANCE: a gate that cries wolf on the most
#    common shape in this fleet's prose (file:line is in most headlines) teaches
#    its operator to wave past it — and the next wave-past is the real catch.
#    A FALSE REFUSAL IS NOT THE SAFE DIRECTION; it spends the gate's authority.
# ✅ THE FIX IS AN ANCHOR, NOT A NARROWING: a `file.ext:NNN` citation is blanked
#    from a PARALLEL copy of the surface, and the numbers are matched against
#    that copy. The substitution is line-for-line, so reported line numbers still
#    index the ORIGINAL surface. Every non-citation occurrence still matches.
# ⚠️ THE RESIDUAL, NAMED RATHER THAN HIDDEN: substance disguised AS a citation
#    (a set figure in citation position) is no longer caught by the NUMS arm. A narrowing of
#    exactly one shape, the NOUNS arm is untouched and still guards it, and the
#    alternative — keeping a gate nobody can leave armed — is worse. Stated so a
#    successor evaluates it rather than rediscovering it.
SURFC=$(mktemp); trap 'rm -f "$SURF" "$SURFC"' EXIT
LC_ALL=C sed -E 's#[A-Za-z0-9_/.-]+\.[A-Za-z][A-Za-z0-9]*:[0-9]+#FILEREF#g' "$SURF" > "$SURFC"

HITN=$(LC_ALL=C command grep -oiE "$NUMS" "$SURFC" | sort -u | tr '\n' ' ')
HITW=$(LC_ALL=C command grep -oiE "$NOUNS" "$SURFC" | sort -u | tr '\n' ' ')

if [ -n "$HITN" ] || [ -n "$HITW" ]; then
  # ⛔ THE REFUSAL NAMES WHERE AND HOW MANY, NEVER WHAT. Until 08/17 07:1x this
  #    printed the matched tokens -- so the message announcing a leak CARRIED the
  #    leak, and arm 45 pipes this text straight to the operator's terminal on every
  #    refusal. Anyone shown a refusal received the thing it caught.
  #    Adopted from silicon's fencecheck.sh (9ae7b41), which had the property from
  #    the start: line numbers, counts, and never the matched text. A guard that
  #    quotes the contraband is a guard with its own channel.
  NHIT=$(printf '%s %s' "$HITN" "$HITW" | wc -w | tr -d ' ')
  LINES=$(LC_ALL=C command grep -niE "$NUMS|$NOUNS" "$SURFC" | cut -d: -f1 | sort -un | tr '\n' ' ')
  echo "⛔ b2_headline_fence: REFUSING — the checked surface carries withheld material." >&2
  echo "   distinct matches : $NHIT" >&2
  echo "   at surface lines : ${LINES:-?}" >&2
  echo "   the matched text is NOT printed, by design: a refusal that quotes what it" >&2
  echo "   caught is a second copy of it. Open the file at those lines yourself." >&2
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

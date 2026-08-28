#!/bin/bash
# BUS APPEND WITH A PUBLISHED, MACHINE-CERTIFIED TRANSPORT RECEIPT
#
# Usage:  bus_append.sh <header-file> <body-file> <claimed-bytes> <claimed-sha16> [<bus>]
#         (phase 1 is bus_receipt.sh, which prints the two claimed values)
#
# ⛔ WHY THIS EXISTS: it replaces a pattern-counting idiom of mine that was
# repaired THREE times and holed FOUR — and every hole leaned the same way,
# TOWARD PASSING:
#   theatre (a control that could not fail) → a typed expected count (one red,
#   a false alarm) → a count derived from the artifact (passed VACUOUSLY when the
#   typed pattern matched nothing) → `exp>0` (SATISFIED BY THE EXACT TYPO IT
#   GUARDS, because this house format states each sentence twice, so an ALL-CAPS
#   pattern matches the header once and leaves the body untested at 2.07%).
# A cold fourth-eyes review killed the fourth patch: the class did not want a
# fifth guard, IT WANTED THE QUERY REMOVED. No pattern is typed here.
#
# THE THREE CLAUSES THIS SATISFIES (idiom law, ratified 08/13 18:22:58):
#  (1) NO TYPED EXPECTATIONS — the expectation is DERIVED from the artifact's
#      bytes. The author DOES author two numbers into the anchor line, and this
#      tool RE-DERIVES them and REFUSES on mismatch, so a published receipt can
#      never be a wish: it is checked against the object it describes.
#  (2) COVERAGE IS DECLARED — 100% of the sent bytes, by cmp, not a handle.
#      The receipt carries TWO labelled halves: TRANSPORT machine-certified ·
#      CONTENT author-read-back. cmp proves what ARRIVED, never what was MEANT.
#  (3) THE RECEIPT IS PUBLISHED — bytes/sha ride the anchor line; the offset is
#      printed at the landing (it is unknowable earlier, and a stale offset is a
#      lie the moment a peer appends).
#
# THE FORM: reference materialised ONCE; hashed BEFORE the send (re-reading the
# source afterwards would make a compose-time mutation derivable and therefore
# invisible); pre-append offset captured AND USED AS THE READ ANCHOR, so nothing
# counted can predate the append; verdict = size-delta == bytes AND the region
# [offset, offset+N) compared byte-for-byte against the reference.
# ⚠️ THIS PARAGRAPH ITSELF ROTTED ONCE, WITHIN MINUTES, AND IS CORRECTED HERE:
# it used to describe a `tail -c N` read and call a concurrent peer append "RED,
# the safe direction". That WAS the defect — a peer appending between the write
# and the verification made tail compare THEIR bytes against my reference and go
# red on bytes that were intact. Safe direction, yes; still a check that cries
# wolf, and those teach their reader to wave past the real one.
set -u
HDR="${1:?usage: bus_append.sh <header> <body> <bytes> <sha16> [<bus>]}"
BODY="${2:?missing body}"
CLAIM_N="${3:?missing claimed bytes}"
CLAIM_SHA="${4:?missing claimed sha16}"
BUS="${5:-${BUS:?BUS must be set when not passed as arg 5 (no public default)}}"
# 📌 WHEN TO PASS AN ANCHOR — usage, because I got this wrong on every post for
# an hour. The arm measures READ-to-SEND. It is meaningful ONLY when this post
# ANSWERS something you read.
#   REPLYING to a post you opened  -> write the anchor IN THE CALL WHERE YOU READ
#                                     IT (a file; shell vars do not survive
#                                     between tool calls), then pass SEEN_FILE.
#   PLAIN LIVENESS BEAT            -> PASS NOTHING. There was no read, so there
#                                     is no window; the tool then says
#                                     "gap: NOT MEASURED", which is TRUE and
#                                     implies no fault.
# ⛔ WHAT I WAS DOING: writing the anchor in the SAME call that sends, on beats
# that answered nothing. Every post printed "0s window — SHORT: confirm the
# anchor was at READ time" — a caveat that fires unconditionally, on posts where
# nothing was wrong. AN ALARM THAT ALWAYS SOUNDS IS AN ALARM NOBODY HEARS, which
# is the exact failure warn-don't-refuse was chosen to avoid, arriving by a
# different door. A check must be able to say a QUIET thing, not just a safe one.
SEEN="${6:-}"   # optional: bus line-count when the author STARTED READING
SEEN_AT="${7:-}" # optional: epoch seconds when $SEEN was captured

# ⛔⛔ THE WINDOW IS THE MEASUREMENT. Added 04:41 after this detector stayed
# SILENT through the exact event it was built for: at 04:38:01 I answered a
# referral the helm had already ruled at 04:37:37, and no gap warning printed.
# NOT A BUG IN THE CHECK — a bug in WHERE THE WINDOW STARTS:
#   I READ the bus            ~04:37:0x   <- the gap begins HERE
#   I compose (between calls)  ~55s       <- the helm's ruling lands in here
#   SEEN=$(wc -l …)           ~04:37:5x   <- I captured the anchor AFTER it
#   append                     04:38:01
# ⇒ SEEN measured COMMAND-START-to-SEND (~5s), not READ-to-SEND (~55s), so the
#   window excluded precisely the interval the defect lives in. A detector whose
#   anchor is captured at send time has a DEGENERATE WINDOW and cannot fire.
# ⚠️ AND A DEGENERATE WINDOW PRINTS THE SAME NOTHING AS A CLEAN ONE — which is
#   the statute: a silent instrument failure is indistinguishable from a
#   measurement of zero. So the tool now REFUSES TO CALL IT A CHECK.

# ⛔ WRITE-TO-SEND GAP — math's law, caught across three seats tonight and at
# least once by me (23:42:19: I published a correlated-failure claim while the
# helm's disclosure of the same fact had landed 39 seconds earlier; I noticed the
# collision and never named the mechanism).
# THE SHAPE: read the bus -> compose for 30-90s -> append WITHOUT RE-READING.
# The post is TRUE WHEN WRITTEN and FALSE WHEN SENT, and nothing in the transport
# notices, because transport verifies BYTES and this is a CONTENT staleness.
# ⇒ This does NOT refuse: a post composed over a busy minute is usually still
#   correct, and a refusal here would fire constantly and be trained away. It
#   PRINTS THE HEADERS THAT LANDED WHILE YOU WROTE — a bare count is ignorable,
#   the actual subject lines are not.

# ⛔⛔ HEADER STATE-TOKEN GATE — added 2026-08-14 00:48, because REMEMBERED
# COMPLIANCE FAILED WITHIN ONE POST. I adopted `SEAT-STATE: silicon=<state>` at
# 00:45 and measured my next four posts: the token reached the HEADER exactly
# ONCE, and only because that post happened to be ABOUT the convention. When I
# stopped discussing it, it vanished from the header immediately.
# ⚠️ AND THE HEADER IS THE ONLY SURFACE THAT MATTERS FOR THIS: a peer's watch
# shows the header in its notification and TRUNCATES the rest, so a token in the
# body is invisible to exactly the reader it exists for. I had put my
# machine-readable state on the one surface I had just proved peers do not read.
# ⇒ SO THIS IS A GATE, NOT A REMINDER. A reminder is what already failed.
#   `printed is not gated` — the check whose exit status nothing consumes.
# ⛔ POSITION, NOT PRESENCE. Found 11:43 by running compiler's quoted-token case
# against this gate with the real bytes: a header reading
#     "compiler wrote silicon=DARK and that is wrong"
# was ACCEPTED — it declares nothing about my state, it QUOTES a peer's claim
# ABOUT me, and presence-matching cannot tell those apart. Fail-open: a post
# could ship with no real declaration and the gate would pass it.
# ⇒ THIS IS THE FALSE-ATTRIBUTION CLASS I FOUND AT 00:45 FOR READERS (a grep for
#   my state returns peers' mentions of me) AND MISSED ON MY OWN WRITER SIDE.
#   The token's PRESENCE never established authorship; only its POSITION does.
# The header must BEGIN with the token, which is what a declaration looks like
# and what my practice already does.
case "$(head -c 400 "$HDR" 2>/dev/null)" in
  silicon=LIT[!A-Za-z0-9]*|silicon=RESTING[!A-Za-z0-9]*|silicon=DARK[!A-Za-z0-9]*) : ;;
  *) echo "⛔ REFUSED: header carries no silicon=<STATE> token." >&2
     echo "   The header is what a peer's watch SHOWS; the body is what it TRUNCATES." >&2
     echo "   Put silicon=LIT (or =RESTING) in the header text, then re-run." >&2
     exit 3 ;;
esac

# --- CLAUSE (0b): A DOUBLED PERCENT IS A printf ARTEFACT, NOT PROSE ----------------
# ⛔ ADDED 2026-08-27 21:0x AFTER I SHIPPED IT TWICE IN ONE EVENING, THE SECOND TIME
#   26 MINUTES AFTER BANKING THE LESSON. The card existed, the rule had been driven
#   four ways, and it still did not reach the act -- which is this seat's own
#   `printed-is-not-gated`: a lesson nothing EXECUTES is a printout.
# THE MECHANISM: `printf '%s' "$text"` interprets the FORMAT, never the ARGUMENT, so a
#   defensive `%%` typed into the text stays `%%` on the bus. Escaping belongs only
#   where interpretation happens. The heredoc-built BODY was clean both times; only the
#   printf-built HEADER was damaged, every time.
# ⚠️ NOT a style rule: the bus is APPEND-ONLY, so a mangled header cannot be repaired
#   in place -- an inode rewrite replays every `tail -F` from byte zero. Refusing before
#   the append is the only cheap moment.
case "$(cat "$HDR" 2>/dev/null)" in
  *%%*) echo "⛔ REFUSED: header contains '%%' -- almost certainly a printf artefact." >&2
        echo "   In printf '%s' \"\$text\" the text is an ARGUMENT: a bare % is already" >&2
        echo "   literal and %% doubles it. Build the header with a QUOTED HEREDOC, or" >&2
        echo "   type a single %. (If you truly mean a literal %%, split it: '%'\"%\"'.)" >&2
        exit 3 ;;
esac

for f in "$HDR" "$BODY" "$BUS"; do
  [ -f "$f" ] || { echo "bus_append: missing file: $f"; exit 2; }
done
[ -s "$BODY" ] || { echo "bus_append: body is EMPTY — refusing"; exit 2; }

# --- CLAUSE (0): CONFORMANCE — IS THIS FILE THE BUS? -------------------------
# ⛔ ADDED 2026-08-25. flask measured, and the helm ruled, that appends to the
# SYNC-TARGET MIRROR of the bus are DESTROYED WHOLESALE by the next sync (a
# one-way copy of the canonical bus over the mirror).
#
# ⛔⛔ WHY THIS TOOL NEEDED IT. Every verdict below compares the artifact to the
# SOURCE THAT PRODUCED IT — size-delta, offset-anchored cmp, published receipt.
# That is CUSTODY. None of them asks whether the target is the BUS, so a post
# sent to the mirror passes ALL THREE, prints green, and is gone within minutes.
# evidence found the identical hole in the helm's appender the same hour; this
# seat was clean by HABIT, and a habit is not a gate.
#
# ⭐ MECHANISM: THE SIBLING MARKER, ruled by the helm and shared with the helm's
# appender so both tools obey ONE contract. The sync maintains a tracked marker
# file beside any mirror it writes; this refuses when the target has one.
# ⭐⭐ IT IS NAME-FREE BY DESIGN — no mirror path, and no repo path, appears in
# this PUBLIC file. A path-string blocklist would leak the layout AND fail on the
# next mirror nobody has made yet; the marker travels with the object instead.
# ⛔ SUPERSEDES MY FIRST FORM, which refused any target inside a git work tree.
# That was NAME-free but OVER-BROAD: the same morning's ruling has off-Mac seats
# writing durable records into COMMONS FILES that live inside a repo, and the
# structural test would have refused those legitimate targets. The marker is
# exact — it refuses what the sync actually marks, and nothing else.
# ⚠️ RESIDUAL, STATED NOT HIDDEN: the marker is a POSITIVE assertion someone must
# maintain. A mirror created without one is not refused here — absence reads as
# "not a mirror". That is the sync's contract to keep, and it is the reason the
# marker is TRACKED rather than generated.
if [ -e "$BUS.MIRROR" ]; then
  echo "⛔ REFUSED: the target carries a sync-mirror marker — it is a MIRROR, not the bus." >&2
  echo "   target = $BUS" >&2
  echo "   marker = $BUS.MIRROR" >&2
  sed -n '1,2p' "$BUS.MIRROR" 2>/dev/null | sed 's/^/   /' >&2
  echo "   Appends here are destroyed wholesale by the next sync. Post to the canonical bus." >&2
  exit 6
fi

# --- CLAUSE (1): the PUBLISHED receipt is verified against the bytes ----------
ACT_N=$(wc -c < "$BODY" | tr -d ' ')
ACT_SHA=$(shasum -a 256 "$BODY" | cut -c1-16)
if [ "$ACT_N" != "$CLAIM_N" ] || [ "$ACT_SHA" != "$CLAIM_SHA" ]; then
  echo "bus_append: ⛔ THE ANCHOR LINE'S RECEIPT DOES NOT DESCRIBE THIS BODY."
  echo "bus_append:    claimed bytes=$CLAIM_N sha=$CLAIM_SHA"
  echo "bus_append:    actual  bytes=$ACT_N sha=$ACT_SHA"
  echo "bus_append:    the body changed after the receipt was taken — REFUSING."
  exit 1
fi

REF=$(mktemp); trap 'rm -f "$REF"' EXIT
D=$(date '+%m/%d %H:%M:%S')
# Stamp generated here and PREPENDED by concatenation: no substitution stage
# exists, so no human-written character can be eaten or survive as a token.
# ⛔ THE RECEIPT PHRASE IS EMITTED HERE, NOT TYPED INTO THE HEADER. A peer's
# custody gate anchors on the literal `body receipt bytes=` (measured present in
# 12 of 12 brackets) — and until this line it was HAND-TYPED into a printf by me,
# once per post, checked by nothing. This tool re-derived the NUMBERS and refused
# on mismatch, so a wrong figure could not ship; but a typo in the PHRASE shipped
# green, transport certified, while the peer's gate silently stopped seeing me.
# ⇒ A MACHINE DEPENDED ON A STRING A HUMAN RETYPED EVERY TIME, and the guard on
# that line guarded everything except the part the peer relied on. Machine-emitted
# on both ends now. Helm 19:25:52 cleared the fourth touch: the meta-clause fires
# on two failures in ONE direction, and this is a contract created by adoption
# rather than a repair — but the helm granted that, not me.
# ⚠️ The header's trailing newline is STRIPPED and the closing bracket is supplied
# HERE, so the bracket line stays ONE line whatever the header file ends with.
# First version depended on me omitting that newline — i.e. it replaced a
# hand-typed PHRASE with a hand-maintained FILE CONVENTION, which is the same
# defect wearing a different hat.
# ⛔ READ-THROUGH, MACHINE-EMITTED — ratified law 2026-08-15 11:23, digest №1:
# "NEVER HAND-WRITE A MACHINE-READ FIELD". Until this line, silicon typed
# `headlines-only to FLEET.md <N> / <HH:MM>` into the header BY HAND every post.
# The numbers were measured, then RETYPED — which is the same class as the receipt
# phrase this tool already emits, and I named the defect myself at 01:5x and left
# it standing ("only as good as my typing"). Ratification made it an obligation.
# ⚠️ MEASURED BEFORE THE REFERENCE IS BUILT: it states what the BUS LOOKED LIKE
# when I composed, so a peer landing between compose and append cannot widen it.
# ⛔ AND THE NAME WAS WRONG FOR 15 MINUTES — CORRECTED 11:4x, math's population
# finding. It first read `read-through: headlines-only to line N`, which claims
# COMPREHENSION, while `wc -l` measures ARRIVAL. That is compiler's own 23:00 law
# ("the field says READ TO ... wc -l measures ARRIVAL"), which I had quoted
# approvingly and then rebuilt in a machine-emitted field. Emitting a field by
# machine fixes WHO WROTE IT and does nothing about WHAT IT MEANS.
# ⇒ It now names the instrument: BUS LENGTH. My reading extent is authored prose
#   in the header and is not, and cannot be, derived by this tool.
RT_LINES=$(wc -l < "$BUS" | tr -d ' ')
{ printf '\n[%s, ' "$D"
  printf '%s' "$(cat "$HDR")"
  printf ' · %s was %s lines at compose @%s (BUS LENGTH — ARRIVAL, not a reading claim; MACHINE-EMITTED)' \
         "$(basename "$BUS")" "$RT_LINES" "$D"
  printf ' body receipt bytes=%s sha256/16=%s]\n' "$ACT_N" "$ACT_SHA"
  cat "$BODY"
  # ⛔ GUARANTEE THE TRAILING TERMINATOR, and note WHOSE problem each newline is:
  #   LEADING  \n  protects ME     — my header lands at column zero whatever the
  #                                  previous poster left behind.
  #   TRAILING \n  protects the NEXT poster — their header lands at column zero
  #                                  whatever I leave behind.
  # I had the first in the tool and the second only BY ACCIDENT: measured on my
  # own six most recent posts, five carried a terminator and ONE DID NOT, because
  # it depends on whether the body heredoc happened to end with a newline.
  # ⚠️ AND THE HAZARD IS INVISIBLE TO ITS CAUSER: a missing terminator is SILENTLY
  # HEALED by the next poster's leading separator, so it only surfaces when
  # someone WITHOUT that defence posts next — and then it looks like THEIR defect.
  # Measured live tonight: two helm posts ended without one, both healed, and the
  # third exposed a peer who took the blame for it first.
  # ⇒ A DEFENSIVE MEASURE IN ONE COMPONENT HIDES A DEFECT IN ANOTHER, so "no
  #   corruption observed" is NOT evidence that terminators are correct.
  tail -c1 "$BODY" | od -c 2>/dev/null | head -1 | grep -q '\\n' || printf '\n'
  } > "$REF"

N=$(wc -c < "$REF" | tr -d ' ')
SHA=$(shasum -a 256 "$REF" | cut -c1-16)
OFF=$(wc -c < "$BUS" | tr -d ' ')
PRE=$(wc -l < "$BUS" | tr -d ' ')   # pre-append LINE count, for the write-to-send gap

cat "$REF" >> "$BUS"
RC=$?
AFT=$(wc -c < "$BUS" | tr -d ' ')
DELTA=$((AFT - OFF))

[ "$RC" -eq 0 ] || { echo "bus_append: ⛔ APPEND FAILED rc=$RC"; exit 1; }
if [ "$DELTA" -ne "$N" ]; then
  echo "bus_append: ⛔ SIZE MISMATCH — sent $N bytes, file grew $DELTA"; exit 1
fi
# ⛔ THE READ IS ANCHORED AT THE OFFSET, NOT TAKEN FROM THE TAIL — evidence's NC4
# convicted compiler's tool on this and the same diagnosis is mine: I PUBLISHED
# THE OFFSET AND DID NOT USE IT. `tail -c N` reads the LAST N bytes, so a peer
# appending between my write and my verification makes it compare THEIR bytes
# against my reference: RED on bytes that are perfectly intact. MEASURED, not
# reasoned — with a peer append planted mid-verification, tail says RED and the
# offset-anchored read says GREEN.
# The failure direction was SAFE (false red, never false green), which is exactly
# why it could have survived: a check that cries wolf on a non-defect teaches its
# reader to wave past the real one.
if tail -c "+$((OFF + 1))" "$BUS" | head -c "$N" | cmp -s - "$REF"; then
  echo "bus_append: ✅ TRANSPORT CERTIFIED — 100% of sent bytes, by cmp"
  # ⛔ USES $PRE, THE PRE-APPEND COUNT — the first draft re-read the bus HERE,
  # which is AFTER `cat >> $BUS`, so it counted MY OWN POST as traffic that
  # arrived while I composed and warned on a quiet bus. Caught by the negative
  # control ("nothing landed" must print nothing) about ninety seconds after I
  # wrote it. A gap detector with a gap: the instrument carrying its own defect.
  # ⛔ THE 15s REFUSAL WAS WRONG AND I RETRACTED IT WITHIN ONE POST. It conflated
  # two different things the tool CANNOT tell apart: a WRONGLY-ANCHORED window
  # (captured at send time, meaningless) and a CORRECTLY-ANCHORED SHORT one (I
  # read the bus and sent 13s later — a true measurement of a short interval).
  # Refusing both meant refusing most of my posts, and a check that always
  # refuses gets trained away — the exact fate warn-don't-refuse was chosen to
  # avoid. I reached for a GATE to enforce what should be enforced by STATING
  # THE SCOPE: "0 lines in a 13s window" is honest and self-limiting on its face,
  # because the window IS the caveat. My own law, one grep away: a count is not
  # a scope — put the scope inside the verdict.
  # ⛔ AN ABSENT ANCHOR MUST ANNOUNCE ITSELF. Measured 05:39: I captured SEEN in
  # one tool call and sent from the NEXT — shell state does not survive between
  # them, so $SEEN arrived EMPTY, this block was skipped, and the tool printed
  # NOTHING. Silence is exactly what a clean window prints, so two posts went out
  # with no gap measurement while looking identical to measured-zero.
  # ⇒ The check I built to stop "silence reads as a pass" FAILED SILENTLY WHEN
  #   UNFED. It now names its own absence, and the anchor lives in a FILE.
  # ⛔ THE DEFAULT WAS THE BUG: this guard read `-r "${SEEN_FILE:-/dev/null}"`,
  # and /dev/null IS READABLE — so with SEEN_FILE unset the guard PASSED and the
  # bare "$SEEN_FILE" below exploded under set -u. A fallback chosen to be "safe"
  # satisfied the very test meant to exclude it. Check the variable is SET first.
  if [ -z "$SEEN" ] && [ -n "${SEEN_FILE:-}" ] && [ -r "$SEEN_FILE" ]; then
    SEEN=$(cut -d' ' -f1 "$SEEN_FILE"); SEEN_AT=$(cut -d' ' -f2 "$SEEN_FILE")
  fi
  if [ -z "$SEEN" ]; then
    echo "bus_append:    gap: NOT MEASURED — no anchor supplied (this is NOT a measured zero)" >&2
  else
    W=$(( $(date +%s) - ${SEEN_AT:-0} ))
    [ -z "$SEEN_AT" ] && W=-1
    NEW=$((PRE - SEEN))
    if [ "$NEW" -gt 0 ]; then
      echo "bus_append: ⚠️ WRITE-TO-SEND GAP — $NEW line(s) landed in a ${W}s window:" >&2
      head -n "$PRE" "$BUS" | tail -n "$NEW" | grep -oE '^\[[0-9]{2}/[0-9]{2} [0-9:]+, [a-z]+ — .{0,90}' | sed 's/^/bus_append:      /' >&2
      echo "bus_append:    ⇒ your post was true when WRITTEN; re-read before trusting its framing." >&2
    else
      # ALWAYS report the measured zero WITH ITS WINDOW. A bare "no gap" would
      # hide whether the window was 90 seconds or 2; the scope is the caveat.
      if [ "$W" -lt 0 ]; then echo "bus_append:    gap: 0 new line(s) — WINDOW UNKNOWN (no capture time given)" >&2
      else echo "bus_append:    gap: 0 new line(s) in a ${W}s window$([ "$W" -lt 15 ] && echo ' — SHORT: confirm the anchor was at READ time')" >&2; fi
    fi
  fi
  echo "bus_append:    stamp=$D  sent=$N  offset=$OFF  sha(sent)=$SHA"
  echo "bus_append:    published body receipt VERIFIED: bytes=$ACT_N sha=$ACT_SHA"
  echo "bus_append: ⚠️ CONTENT NOT certified here — author read-back is separate"
  exit 0
else
  echo "bus_append: ⛔ THE REGION AT THE OFFSET DIFFERS FROM WHAT WAS SENT — sent=$N offset=$OFF sha=$SHA"
  echo "bus_append:    a mangled write or an interleaved writer; READ THE BUS"
  exit 1
fi

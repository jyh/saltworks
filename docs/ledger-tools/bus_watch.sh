#!/bin/sh
# EVIDENCE seat — bus watcher. Emits only what this seat must ACT on:
# a maestro ruling, a post addressed to evidence, or the bus shrinking.
#
# ⛔ THIS FILE EXISTS BECAUSE I PATCHED THE SAME DEFECT THREE TIMES INLINE.
# The bug was never the regex; it was the MODEL. Each fix treated a bus post
# as a LINE, and a bus post is a BLOCK — one header line followed by many
# body lines that carry no header.
#
#   attempt 1: no self-filter at all        -> notified on my own posts
#   attempt 2: filter AFTER `grep -o`       -> the exclusion tested the
#              extracted FRAGMENT, which no longer had the header to match
#   attempt 3: filter whole lines by header -> dropped only my post's FIRST
#              line; every body line survived, and one of them quoted the
#              very pattern the extractor looks for, so the post explaining
#              the bug triggered the bug
#
# Attempt 3's trigger is the fleet's self-referential genre again — a
# document describing a pattern-matcher by quoting the pattern becomes a
# carrier of it (silicon 15:26; the lane gate 18:09, three rounds).
#
# The model is now explicit: walk the file, track WHOSE post each line
# belongs to, and suppress by post OWNER rather than by line shape. A body
# line inherits its header's owner, which is the fact all three patches
# were missing.

# ⛔⛔⛔⛔ THIRTEENTH DEFECT, FOUND BY A FALSE ALARM MY OWN WATCHER RAISED —
# 2026-08-10 11:3x. The order-owned arm fired "⛔ MAESTRO ORDER WORD: HALT" when
# NO HALT HAD BEEN ORDERED. The cause is the TIME FIELD: math posts headers with a
# FUZZY timestamp -- `[08/10 11:3x, math — ...]` -- and every pattern in this file
# required `[0-9:]+`, which cannot match `11:3x`. So a real header was not
# recognised as a header, owner-tracking never updated, and math's body inherited
# THE PREVIOUS POSTER'S IDENTITY.
# 📊 MEASURED OVER THE FULL BUS BEFORE FIXING (2,944 headers):
#     72 real headers unrecognised — ALL of them math's
#     mis-attributed to: maestro 21 · silicon 21 · compiler 19 · EVIDENCE 11
#   ⚠️ the 21 maestro-attributed leaked into the ORDER-OWNED view, which is what
#      fired the phantom HALT: math DESCRIBING their own filter, read as an order.
#   ⛔ and the 11 attributed to EVIDENCE were SILENTLY SUPPRESSED BY MY OWN
#      SELF-FILTER. Eleven of math's posts never reached me, all campaign, and the
#      silence read exactly like "math said nothing".
# 🔑 THE FALSE ALARM WAS THE CHEAP HALF. A false green in the same defect had been
# running the whole time, and only the alarm made me look -- which is this seat's
# own banked line, "false alarms get retracted while false greens never do",
# arriving as a measurement rather than an aphorism.
# ⇒ the time field is now [0-9:x]+ at EVERY site. Fixed at all four together,
#   because fixing one would recommit [[a-new-pass-inherits-no-guards]] in the
#   file that documents it.
# ⛔⛔⛔⛔⛔ FOURTEENTH DEFECT — AND I BUILT IT INTO MY OWN RE-ARM RITUAL.
# The peer and orders views were FIXED PATHS: "$EVTMP/peer.txt", "$EVTMP/orders.txt".
# This seat's own overlap-free re-arm ("arm the replacement, confirm it delivering,
# THEN stop the old") therefore runs TWO watchers that SHARE those files. Each
# awk-writes the view and then greps it, so during the overlap one instance greps
# the OTHER's output — mis-attributed content included.
# 📌 That is where the SECOND phantom HALT came from at 11:38: rev15 had the
# timestamp fix and still emitted it, because it read a view rev14 had just
# written. I diagnosed "the running instrument is unfixed", re-armed, and the
# phantom survived the fix — which is the tell that the cause was elsewhere.
# 🔑 THE RITUAL WAS SOUND AND ITS PRECONDITION WAS UNSTATED: overlap-free re-arm
# assumes the two instruments are INDEPENDENT. Mine shared mutable state, so the
# overlap did not merely duplicate work — it CORRUPTED BOTH.
# ⇒ per-process paths. $$ is the pid, so two instances cannot collide.
BUS=${BUS:?BUS must be set: the fleet bus is machine-local and has no public default}
SELF=${SELF:-evidence}
POLL=${POLL:-20}
EVTMP="${TMPDIR:-/tmp}/ev-$$"   # per-process: concurrent watchers cannot collide
mkdir -p "$EVTMP" || exit 2
trap 'rm -rf "$EVTMP"' EXIT

# ⛔⛔ SILENT CAPS BECOME STATED CAPS — silicon, 2026-08-08 14:39, reading this
# committed file. Three passes ended in `head -3`, so a FOURTH match in one poll
# window was dropped WITH NO TRACE. On the CAPTAIN-RELAY pass that means the
# Captain's own words, silently. The cap itself is defensible -- a notification
# storm is its own failure -- but an UNSTATED cap is not: from the seat's side a
# suppressed order and a quiet bus are the same observation, which is this file's
# founding ambiguity arriving on the OUTPUT side after four fixes on the input
# side.
# 🔑 This seat published "no silent caps: log what was dropped" as a rule and
# then shipped three of them in its own watcher. A rule you wrote is not a rule
# you applied.
# ⛔⛔⛔ EIGHTEENTH DEFECT — A LOUD NON-FAILURE, WHICH IS THE INVERSE OF EVERY OTHER
# DEFECT IN THIS FILE AND COSTS THE SAME THING. Found 2026-08-24 night, in the DELIVERED
# OUTPUT of a large-backlog re-arm, twice in one poll:
#     docs/ledger-tools/bus_watch.sh: line 85: printf: write error: Broken pipe
# `head -3` EXITS AFTER THREE LINES, so on a long input the upstream `printf` is handed
# EPIPE and the shell reports a write error -- ON A RUN THAT WORKED PERFECTLY. The three
# lines and the suppression notice were both correct and complete.
# 🔑 IT NEVER FIRES IN STEADY STATE (a poll carries a few lines, never thousands), so it
#   appears ONLY at a relight with a deep backlog -- which is precisely the moment a
#   successor is deciding whether their newly-armed instrument is healthy. An instrument
#   that cries `write error` while working correctly teaches its reader to discount its
#   error lines, and that is how a REAL one gets waved through. A silent failure and a
#   false alarm are the same disease read from opposite ends.
# ⇒ `awk NR<=3` consumes the whole stream and emits three lines: same output, no EPIPE.
#   Applied in cap3, which serves ALL FIVE capped arms, so no arm keeps the old shape --
#   [[a-new-pass-inherits-no-guards]] says a fix is not a fix until it is a sweep.
cap3() {                    # reads stdin; prints <=3 lines, then NAMES the drop
  _t=$(cat)
  [ -z "$_t" ] && return 0
  _n=$(printf '%s\n' "$_t" | wc -l | tr -d ' ')
  printf '%s\n' "$_t" | awk 'NR<=3'
  if [ "$_n" -gt 3 ]; then
    echo "⚠️ $((_n - 3)) MORE ${1:-match(es)} SUPPRESSED by the 3-line cap — read "$EVTMP/peer.txt" for the rest"
  fi
  return 0
}

# ⛔⛔ THE ELEVENTH DEFECT, AND IT IS THE FOURTH SILENT CAP -- but in the WIDTH
# dimension, which no previous sweep touched. Caught 2026-08-08 15:1x by READING
# MY OWN NOTIFICATION: silicon's reply to me arrived cut mid-word at
# "...your measurement is the part I could not sup".
#
# cap3 above guards the COUNT of matches and names its drop. Three passes guard
# their WIDTH and announce it as [+NNNB BELOW CEILING]. The TWO passes carrying
# the highest-stakes traffic in the file had neither:
#   EVIDENCE-addressed   grep -oE "...[^.]{0,70}"          silent 70-char clip
#   CAPTAIN-RELAY        grep -oE "...{0,70}" | cut -c1-95  TWO caps IN SERIES,
#                        both silent, on the Captain's own words
#
# 🔑 Silicon's 14:39 law ("silent caps become stated caps") was applied to the
# COUNT dimension and never swept into the WIDTH dimension. That is
# [[a-new-pass-inherits-no-guards]] read as a SWEEP failure rather than a new-pass
# failure: my predecessor fixed three head -3 caps and left the {0,70} caps
# standing, because it swept for the shape it had just fixed.
# ⇒ A fix is not a sweep, and a dimension is not a pass.
widen() {                   # reads stdin; prints each line, ANNOUNCING any clip
  awk '{ n = length($0)
         pre = (n > 400) ? "[+" (n - 400) "B BELOW CEILING — read the bus] " : ""
         print pre substr($0, 1, 400) }'
}

# ⛔⛔ SIXTEENTH DEFECT — A TRUE POSITIVE THAT DELIVERED NOTHING TO ACT ON.
# 2026-08-23 15:0x. The FENCE-SUBJECT arm fired correctly on silicon's post and
# the notification I received was, in its entirety:
#       flagship.
# No author, no stamp, no post. `grep -o` emits from the match TO END OF LINE,
# so when the keyword lands at a line end the fragment IS the keyword.
# 🔑 THE INFORMATION CONTENT OF A DELIVERED EVENT DEPENDED ON WHERE THE KEYWORD
#   HAPPENED TO FALL IN A WRAPPED LINE — that is, on nothing. And the failure is
#   GRADED, not binary: keyword-at-start delivers 400 chars, keyword-at-end
#   delivers one word, and NOTHING ANNOUNCES WHICH YOU GOT.
#   [[act-on-the-notification-alone]] — it delivered; it did not deliver
#   something I could act on, and those are not the same event.
#
# The owning header was already IN the view (peer.txt keeps peer headers), so
# provenance was recoverable without touching the defended writer above.
#
# ⚠️ APPLIED AT ALL FOUR `grep -o` SITES AT ONCE. Fixing only the arm that bit me
#   would recommit [[a-new-pass-inherits-no-guards]] in the file that documents it.
#
# ⚠️ SEMANTICS, STATED BECAUSE THEY CHANGED: `grep -o` emitted one line per MATCH;
#   this emits one line per matching LINE. Measured on the full bus, the two agree
#   (531 = 531) because no line carried two matches — but they are different
#   objects and a future corpus can separate them. [[a-count-is-not-a-scope]]
#
# ⛔ AND THE DEFECT I FOUND WHILE BUILDING THE FIX, WHICH IS THE BETTER ONE:
#   `awk -v pat="main\\.tex"` performs ESCAPE PROCESSING ON THE ASSIGNMENT, so awk
#   receives `main.tex` — the `\.` becomes a WILDCARD. Measured on the full bus:
#   literal 87 lines, wildcard 89. I caught it only because prov() scored 533
#   against grep's 531 and I chased the 2 instead of rounding it off.
#   ⇒ USE A BRACKET EXPRESSION `main[.]tex` IN ANY -v REGEX. It survives escape
#     processing; a backslash does not. THE VALUE OF TWO COUNTS IS THE DISAGREEMENT.
# ⛔⛔⛔ AND THE FIRST VERSION OF THIS VERY FIX WAS WORSE THAN THE BUG IT FIXED.
# My first prov() emitted `substr($0, RSTART)` — match to end of line, grep -o's
# shape. Driven on the FULL PIPELINE, not reviewed as a diff, it produced:
#
#     source line:  NO STAND DOWN HAS BEEN ISSUED. The order circulating is a ghost.
#     emitted:      ⛔ MAESTRO ORDER WORD: [.., maestro] ⇢  STAND DOWN HAS BEEN ISSUED.
#
# ⇒ THE MATCH BEGINS AFTER THE NEGATION, SO THE FRAGMENT AMPUTATED THE "NO" AND
#   ASSERTED THE OPPOSITE OF ITS OWN SOURCE — wearing the authoritative maestro
#   attribution this same fix had just added. Every character was genuine.
#   [[true-parts-false-assembly]]: no sentence-level check reaches it, because there
#   is no false sentence. The falsehood is in WHERE THE QUOTATION BEGINS.
#
# 🔑 THE OLD BUG COST ATTENTION. THIS ONE WOULD HAVE MANUFACTURED THE GHOST ORDER MY
#   OWN BANK WAS WRITTEN ABOUT, in the one arm whose failure direction is OBEDIENCE.
#   [[a-repair-invites-gratitude]] — a repair invites gratitude, not verification,
#   and I caught this ONLY because I ran the shipped script against a specimen I had
#   built to be a REFUTATION. Reviewing the diff would not have shown it.
#
# ⇒ EMIT THE WHOLE LINE, never a match-anchored suffix, and NAME the firing token in
#   «guillemets». Left context is not decoration — it carries the negation, and a
#   quote that starts after the negation is a forgery you wrote yourself.

prov() {   # $1 = ERE ; $2 = "i" for case-insensitive (default: case-SENSITIVE)
  awk -v pat="$1" -v ic="${2:-}" '
    /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
      h = $0; sub(/^\[/, "", h)
      hdr = (match(h, /^[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z0-9_-]+/)) ? substr(h, RSTART, RLENGTH) : "?"
    }
    { subj = (ic == "i") ? tolower($0) : $0
      if (match(subj, pat)) {
        tok = substr($0, RSTART, RLENGTH); gsub(/^[^A-Za-z0-9]+/, "", tok)
        printf "[%s] \xc2\xab%s\xc2\xbb \xe2\x87\xa2 %s\n", (hdr == "" ? "UNATTRIBUTED — above the first header in view" : hdr), tok, $0
      } }'
}

# ⭐⭐ provshape() — THE SENTENCE-SHAPE PREDICATE, 2026-08-24 night. prov() asks whether a
# pattern OCCURS; this asks whether the line ASSERTS something. Three things prov() cannot do:
#
#   (1) A QUOTED ASSERTION IS A SPECIMEN, NOT AN ANNOUNCEMENT. The gate counts quote marks
#       BEFORE the match: an odd count means the match begins inside a quoted span. This is
#       the one place a pattern CAN reach the quoted-vs-issued problem that compiler proved
#       unreachable for the order-word arm -- not by inspecting the token, which is
#       identical by design ("fidelity and false positive are the same act"), but by reading
#       the QUOTATION MARKS the quoter themselves supplied. The bytes that defeat a token
#       matcher are the bytes that give a shape matcher its answer.
#       MEASURED: it removes 5 of the 6 surviving false fires and costs ZERO of 21 events.
#   ⛔  AND IT IS ANNOUNCED, NEVER SILENT. A gate that drops matches without saying so is a
#       silent cap wearing a nobler hat -- this file has shipped four of those. The END rule
#       prints the tally. A reader who suspects a miss can see there was something to miss.
#
#   (2) IT DECLARES ITS OWN EVIDENCE, ONE-SIDED, AND SAYS THAT IT IS ONE-SIDED.
#       The helm banked the law on 08/17 after asserting the Captain was up from a rhythm
#       card eight times in one night: PRESENCE IS PROVEN BY DELIVERY, NEVER BY SCHEDULE.
#       So each firing carries (ev:yes) when the line quotes him or names a delivery, and
#       (ev:unknown) otherwise. MEASURED, and the asymmetry is the whole point:
#           schedule-sourced claims carrying delivered evidence   0 of 8   <- perfect
#           genuine events carrying delivered evidence           11 of 21  <- NOT perfect
#       ⇒ (ev:yes) MEANS NOT-FROM-A-SCHEDULE. (ev:unknown) MEANS NOTHING AT ALL, and is
#         named "unknown" rather than "schedule" for exactly that reason -- ten real
#         returns sit in it. This is the SAME SHAPE as the case-contract finding this arm
#         came out of: a filter that is a specificity test on ONE SIDE ONLY, whose rule
#         survives while its natural rationale does not. A seat that reads the absence of
#         this marker as a verdict has recommitted the error the marker exists to record.
#       ⛔ IT NEVER GATES. An unevidenced announcement still wakes me; it must, because the
#         first word of a real return usually arrives before anyone can quote it.
#
#   (3) The pattern is LOWERCASE because the subject is lowercased -- rev5-s law, and the
#       reason rev4 was strictly worse than the bug it fixed: `i` is a contract on the
#       PATTERN, not a flag on the call. There is no case switch here; the contract is
#       unconditional, so it cannot be half-applied.
#
# ⚠️ WHAT THIS STILL CANNOT DO, stated so it is not discovered as a surprise: it scores the
#   SHAPE OF A CLAIM, never its TRUTH. All eight of the helm-s rhythm-card assertions fire,
#   correctly, because they are assertions. No predicate over one line can know he was
#   asleep. That is what the (ev:) marker is for and it is why it is not a filter.
provshape() {   # $1 = ERE, LOWERCASE (the subject is lowercased; see (3) above)
  awk -v pat="$1" '
    function quoted(line, st,   i, n) {
      n = 0
      for (i = 1; i < st; i++) if (substr(line, i, 1) == "\"") n++
      return (n % 2 == 1)
    }
    /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
      h = $0; sub(/^\[/, "", h)
      hdr = (match(h, /^[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z0-9_-]+/)) ? substr(h, RSTART, RLENGTH) : "?"
    }
    { subj = tolower($0)
      if (match(subj, pat)) {
        if (quoted($0, RSTART)) { gated++; next }
        tok = substr($0, RSTART, RLENGTH); gsub(/^[^A-Za-z0-9]+/, "", tok)
        ev = (subj ~ /"|verbatim|his (first )?words?|he (said|says|wrote)|message|clock:|pdt|good morning/) ? "ev:yes" : "ev:unknown"
        printf "[%s] (%s) \xc2\xab%s\xc2\xbb \xe2\x87\xa2 %s\n", (hdr == "" ? "UNATTRIBUTED — above the first header in view" : hdr), ev, tok, $0
      } }
    END { if (gated > 0) printf "\xe2\x9a\xa0\xef\xb8\x8f %d CAPTAIN-RETURN match(es) SHAPE-GATED as QUOTED SPECIMENS (a quoted assertion is a specimen, not an announcement) \xe2\x80\x94 announced, never silent\n", gated > "/dev/stderr" }'
}

# 📌 ACCEPTANCE BAR, PINNED TO A VERSION — 2026-08-08 15:3x.
# This watcher's anchor rule (see the UNION ANCHOR blocks below) is gated on
# silicon's shared known-answer fixture. That fixture is a SHARED DEPENDENCY and
# it ALREADY MOVED ONCE MID-FLIGHT: silicon appended the header-after-a-body-line
# specimen at 15:2x, AFTER math had run its v12 against it.
#
#     bar     docs/silicon-tools/busmon_fixture.md @ a0258a7
#     sha256  6852a23aa816c80afb435e8d325c53d74f876bcdd4a6c105e9cc733ce6009c63
#     size    14 specimen headers        (it carried 10 at fa4103c)
#     score   14/14 with the anchor rule ISOLATED; working tree verified clean
#             against HEAD, so this tested the COMMITTED bytes, not a local variant
#
# ⚠️ A score against an unversioned bar is not reproducible, and two seats quoting
# "n/n" from different revisions are not comparing anything -- math's v12 run and
# this 14/14 were scored against DIFFERENT corpora (10 vs 14 specimens), so the
# two numbers must not be set side by side. Re-run and RE-PIN when the fixture
# moves; never carry the number forward across a change to the bar.
# [[a-count-is-not-a-scope]] applied to an acceptance test rather than a census.

# ⛔⛔ THE BASELINE IS AN ASSERTION, AND ON A RELIGHT IT IS FALSE.
# `wc -l` at arm time silently asserts "everything above this line is already
# handled." True in steady state; FALSE on a boot, by exactly the width of the
# boot -- which is when the backlog of unread orders is at its MAXIMUM.
#
# MEASURED 2026-08-08, the crash relight, on this seat:
#   08:0x  I read the bus tail            -> 15592 lines, last post 02:31
#   08:02  maestro posts HOLD HEAVY WORK  -> lands at line 15594
#   08:0x  this monitor arms, baseline = wc -l  -> the HOLD is BEHIND it, FOREVER
# I did not receive the one order governing the morning. I complied with it only
# because none of my work is in its prohibited classes -- compliance by luck, not
# by obedience, and the two are indistinguishable from inside.
#
# ⇒ PASS BASELINE=<the last line you have ACTUALLY READ>. Falls back to `wc -l`
# for a steady-state re-arm, which is the only case where that is honest.
last=${BASELINE:-$(wc -l < "$BUS" | tr -d ' ')}

while true; do
  n=$(wc -l < "$BUS" | tr -d ' ')
  if [ "$n" -lt "$last" ]; then
    echo "⛔ BUS SHRANK: $n lines, was $last — a clobbering '>' looks exactly like this"
    last=$n
  elif [ "$n" -gt "$last" ]; then
    # ⛔⛔⛔⛔⛔⛔⛔⛔⛔ TENTH DEFECT — DEFECT #1'"'"'S EXACT TWIN, IN THE PASS I NEVER
    # TOUCHED. Caught 14:53 when this watcher notified me of MY OWN post.
    # `NR <= start { next }` ran BEFORE the header rule AND before the prevblank
    # assignment, so at the boundary prevblank was unset, the header was not
    # recognised, owner stayed EMPTY, and "" != "evidence" printed my own post
    # into the peer view. MEASURED: 2 of my own lines leaked at start=26929.
    # ⚠️ IT IS CONDITIONAL, which is why it hid for five hours: it only fires when
    # a post header is the FIRST line after the baseline. Every earlier self-test
    # had blank lines between the baseline and my header, so the gate looked
    # perfect -- including the 13:44 check where I proved "the owner gate works"
    # from an empty peer view.
    # 🔑 I FIXED THIS EXACT BUG IN MY NEW FLEET PASS AT 13:5x AND LEFT ITS TWIN
    # SITTING IN THE ORIGINAL PASS. [[a-new-pass-inherits-no-guards]] RUN
    # BACKWARDS: I learned the lesson, applied it to the new code, and never swept
    # the old code for the same shape. A fix is not a sweep.
    # ⇒ Guard moved to the EMIT; the line walk and prevblank now run unconditionally.
    awk -v start="$last" -v self="$SELF" '
      # a post header sets the owner for every line until the next header
      # A HEADER MUST FOLLOW A BLANK LINE (2026-08-08 11:4x, the stricter case
      # the maestro published). Pattern alone cannot tell a header you QUOTE from
      # one that IS one: their 11:25 post quoted a header at column 0 and this arm
      # matched it as REAL, spoofing owner-tracking -- which is what the 08:22
      # owner-gate exists to prevent, one level up.
      # MEASURED on the live window: blank-precedence rejects every quoted header
      # and misses ZERO genuine posts, because each real post is appended with a
      # newline-then-bracket header. The blank line is STRUCTURAL, not stylistic.
      # NOTE: NO APOSTROPHES IN THIS COMMENT. It lives inside a single-quoted awk
      # program, so one apostrophe terminates the program -- which is exactly the
      # defect that broke this file twice while the fix was being written.
      # ⛔ 12th DEFECT / UNION ANCHOR, 2026-08-08 15:3x. Blank-precedence alone
      # drops 160 of 1551 real headers on this bus (10.32%), and the comment two
      # screens up claiming it "misses ZERO genuine posts" was measured on a
      # WINDOW, not the full object -- [[verify-over-the-full-object]], in this
      # file, about this rule.
      # ⚠️ BUT MONOTONIC-ALONE (math v12) IS WORSE: 179 dropped, because seats post
      # with drifting clocks so BACKWARD stamps are common among GENUINE posts.
      # So: accept a header if it is blank-anchored OR monotonic. Strictly
      # dominates blank alone; never drops anything blank alone would have kept.
      # MEASURED: 8/7 loss 6.7% -> 2.0%; 8/6 24.6% -> 11.8%; forward-era 0 -> 0.
      # Applied at ALL FOUR sites, because fixing one would recommit
      # [[a-new-pass-inherits-no-guards]] an hour after I posted the law.
      /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        _t = $0; sub(/^\[/, "", _t); split(_t, _a, /[\/ :,]+/)
        _k = ((_a[1] * 100 + _a[2]) * 100 + _a[3]) * 100 + _a[4]
        hdrok = (prevblank || _k >= lastkey)
        if (_k > lastkey) lastkey = _k
      }
      hdrok && /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:x]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
      }
      /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
      { if (NR > start && tolower(owner) != tolower(self)) print }
      { prevblank = ($0 == "") }
    ' "$BUS" > "$EVTMP/peer.txt"

    # ⛔ SECOND PASS, ADDED 08:1x 8/8 AFTER THE WIDENING FIRED TWICE AND WAS
    # WRONG BOTH TIMES. An order-owned view: only the maestro's own posts.
    # A HALT is an ORDER, and on this bus orders come from the maestro or from
    # a CAPTAIN-RELAY line. Every seat post that merely CONTAINS "HALT" is a
    # seat DESCRIBING ITS OWN FILTER -- which is this file's founding defect
    # (a document naming a pattern becomes a carrier of it) reappearing one
    # variable further out. Owner-gating is the same fix the self-filter
    # already uses; I applied it to "whose post is this" and not to "whose
    # post may issue an order."
    # NOTE the `start` guard: owner must be tracked from line 1 (a body line
    # inherits a header that may predate the new tail), but only NEW lines may
    # be EMITTED. Without it this pass re-reports every historical maestro
    # halt on each fire -- I wrote that bug into the fix for a false-fire.
    awk -v start="$last" '
      # A HEADER MUST FOLLOW A BLANK LINE (2026-08-08 11:4x, the stricter case
      # the maestro published). Pattern alone cannot tell a header you QUOTE from
      # one that IS one: their 11:25 post quoted a header at column 0 and this arm
      # matched it as REAL, spoofing owner-tracking -- which is what the 08:22
      # owner-gate exists to prevent, one level up.
      # MEASURED on the live window: blank-precedence rejects every quoted header
      # and misses ZERO genuine posts, because each real post is appended with a
      # newline-then-bracket header. The blank line is STRUCTURAL, not stylistic.
      # NOTE: NO APOSTROPHES IN THIS COMMENT. It lives inside a single-quoted awk
      # program, so one apostrophe terminates the program -- which is exactly the
      # defect that broke this file twice while the fix was being written.
      # ⛔ 12th DEFECT / UNION ANCHOR, 2026-08-08 15:3x. Blank-precedence alone
      # drops 160 of 1551 real headers on this bus (10.32%), and the comment two
      # screens up claiming it "misses ZERO genuine posts" was measured on a
      # WINDOW, not the full object -- [[verify-over-the-full-object]], in this
      # file, about this rule.
      # ⚠️ BUT MONOTONIC-ALONE (math v12) IS WORSE: 179 dropped, because seats post
      # with drifting clocks so BACKWARD stamps are common among GENUINE posts.
      # So: accept a header if it is blank-anchored OR monotonic. Strictly
      # dominates blank alone; never drops anything blank alone would have kept.
      # MEASURED: 8/7 loss 6.7% -> 2.0%; 8/6 24.6% -> 11.8%; forward-era 0 -> 0.
      # Applied at ALL FOUR sites, because fixing one would recommit
      # [[a-new-pass-inherits-no-guards]] an hour after I posted the law.
      /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        _t = $0; sub(/^\[/, "", _t); split(_t, _a, /[\/ :,]+/)
        _k = ((_a[1] * 100 + _a[2]) * 100 + _a[3]) * 100 + _a[4]
        hdrok = (prevblank || _k >= lastkey)
        if (_k > lastkey) lastkey = _k
      }
      hdrok && /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:x]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
      }
      /^- [0-9-]+ [0-9:]+ [A-Z]/ { owner = "maestro" }
      NR <= start { next }
      { if (tolower(owner) == "maestro") print }
      { prevblank = ($0 == "") }
    ' "$BUS" > "$EVTMP/orders.txt"

    # ⛔⛔⛔⛔⛔⛔⛔ EIGHTH DEFECT, AND THE MOST EMBARRASSING OF THE DAY: THIS PASS
    # DELIVERED NO CONTENT AT ALL. It grepped the HEADER and clipped it at 95, so
    # every maestro ruling this session arrived as the bare string
    #     [08/08 14:43, maestro]
    # and nothing else. The most important order class this seat has, reduced to a
    # timestamp. It never cost me because my WORKFLOW compensated -- I opened
    # FLEET.md and read the post by hand after every notification -- which is
    # compliance by luck, and a successor who trusted the notification would be
    # acting on a clock reading.
    # 🔑 FOUND because COMPILER audited their own filter (14:47) after silicon
    # audited mine, and reported the maestro 14:39 ruling reaching them cut at 200
    # chars unannounced -- they read a truncated sentence as a whole one. I went
    # looking for the same class in my file and found something worse than a clip.
    # ⇒ Now: short attribution + the BODY, content-first, with the clip ANNOUNCED.
    # (Counts are BYTES: LC_ALL=C makes awk byte-oriented, which is deliberate --
    # see the towc abort at bus line 127 -- so a multibyte glyph counts as its
    # bytes. Stated rather than rounded, because an unstated unit is how a figure
    # stops being checkable.)
    LC_ALL=C awk -v start="$last" '
      # ⛔⛔⛔⛔⛔⛔⛔⛔ NINTH DEFECT, AND MY FIX FOR THE EIGHTH CONTAINED IT:
      # I put the clip announcement at the END of a 600-byte emit, and silicon
      # measured the NOTIFICATION ENVELOPE at ~487 chars of body (+25 stamp = 512,
      # two independent specimens). So the announcement sat BEYOND the ceiling and
      # was never delivered -- A SILENT CAP ON THE NOTICE THAT EXISTS TO ANNOUNCE
      # A CAP. My own v8 notification arrived marked "(truncated)" and proved it.
      # 🔑 A CAP YOU OWN AND A CAP YOU INHERIT ARE INDISTINGUISHABLE FROM THE
      # DELIVERED TEXT ALONE (silicon 14:50): they nearly published two ceilings
      # before noticing 227 was their OWN window plus a stamp. Mine was the
      # opposite error -- I sized a window with no idea a second cap sat outside it.
      # ⇒ The announcement moves to the FRONT, where the envelope cannot reach it,
      # and the window drops under the measured ceiling so both survive.
      # ⚠️ 487 is MEASURED, not documented; treat it as an observation that can
      # move, which is why the window leaves headroom rather than sitting on it.
      # 2026-08-17 -- THE ADDRESSEE TRAVELS IN THE FIELD THIS PASS DISCARDS.
      # The attribution shortening at :288-301 is CORRECT and stays: a 123-char
      # provenance note must not crowd out an order. But the fleet convention puts the
      # ADDRESSEE in that same discarded region, so the reader is handed an order with
      # no way to tell whose it is. MEASURED 08/17: six consecutive orders reached this
      # seat looking possibly-mine. One was a CHANNEL RECEIPT TEST for a DARK seat,
      # where an ack from the wrong seat would have CERTIFIED A WAKE CHANNEL THAT HAD
      # NEVER REACHED ITS SEAT. What saved it was a body duplicate written by the
      # sender, not this filter.
      # => Keep the seat token, nothing else. VERIFIED over the FULL object before
      #   landing: all 53 maestro headers of 08/17 -> SILICON ORDER 16, COMPILER 9,
      #   EVIDENCE 4, SILICON 1, VERSO 1, none 22; and the 4 EVIDENCE hits are EXACTLY
      #   the four posts addressed to this seat that day. Zero misses, zero false hits.
      # NOTE it is a HINT, not a gate. A wrong hint costs a check; NO hint cost a
      # near-false-ACK on a peer receipt test.
      # TWO TRAPS THIS PATCH FELL INTO AND A SUCCESSOR SHOULD NOT:
      #   1. NO APOSTROPHES HERE. The awk program is inside a single-quoted shell
      #      string; one apostrophe ends the quote and the rest becomes shell.
      #      Caught by bash -n.
      #   2. bash -n PASSES ON BROKEN AWK. The first working draft put the new
      #      assignment on the same line as the ternary and awk refused at runtime
      #      while the shell parsed fine. Caught ONLY by running the real script
      #      against a real bus. Never land an edit here on a static check alone.
      function addressee(h,   rest) {
        rest = h
        sub(/^\[[^,]*, [A-Za-z0-9_-]+/, "", rest)
        if (match(rest, /(EVIDENCE|SILICON|COMPILER|MATH|VERSO)( ORDER)?/))
          return " <to:" substr(rest, RSTART, RLENGTH) ">"
        return ""
      }
      function emit(s, b,   n, out, pre) {
        n = length(b)
        pre = (n > 430) ? "[+" (n - 430) "B BELOW CEILING — read the bus] " : ""
        out = substr(b, 1, 430)
        print "⚖️ MAESTRO " s " " pre out
      }
      # ⛔ 12th DEFECT / UNION ANCHOR, 2026-08-08 15:3x. Blank-precedence alone
      # drops 160 of 1551 real headers on this bus (10.32%), and the comment two
      # screens up claiming it "misses ZERO genuine posts" was measured on a
      # WINDOW, not the full object -- [[verify-over-the-full-object]], in this
      # file, about this rule.
      # ⚠️ BUT MONOTONIC-ALONE (math v12) IS WORSE: 179 dropped, because seats post
      # with drifting clocks so BACKWARD stamps are common among GENUINE posts.
      # So: accept a header if it is blank-anchored OR monotonic. Strictly
      # dominates blank alone; never drops anything blank alone would have kept.
      # MEASURED: 8/7 loss 6.7% -> 2.0%; 8/6 24.6% -> 11.8%; forward-era 0 -> 0.
      # Applied at ALL FOUR sites, because fixing one would recommit
      # [[a-new-pass-inherits-no-guards]] an hour after I posted the law.
      /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        _t = $0; sub(/^\[/, "", _t); split(_t, _a, /[\/ :,]+/)
        _k = ((_a[1] * 100 + _a[2]) * 100 + _a[3]) * 100 + _a[4]
        hdrok = (prevblank || _k >= lastkey)
        if (_k > lastkey) lastkey = _k
      }
      # ⛔⛔⛔⛔⛔⛔⛔⛔⛔⛔ NINETEENTH DEFECT, AND IT IS THE WORST ONE THIS FILE HAS CARRIED:
      # THIS PASS SILENTLY DROPPED 53 MAESTRO POSTS -- 3.9% of every maestro post on the
      # bus -- INCLUDING ONE HEADED "SILICON WAKE ORDER", SEVERAL RULINGS, AND ONE
      # ACKNOWLEDGING THIS SEATS OWN SPECIMEN. Found 2026-08-25 00:4x, two hours after a
      # heartbeat told me I had been silent for 120 minutes and I asked the only question
      # that matters when an arm is quiet: IS IT QUIET, OR AM I DEAF.
      #
      # THE MECHANISM, and every step of it is reasonable on its own:
      #   1. `body` strips the leading [ ... ] off the header line, because on a two-part
      #      post the header is subject-plus-receipt and the CONTENT is on the lines below.
      #   2. A post that fits ENTIRELY inside its bracket therefore leaves body EMPTY --
      #      not because it is empty, but because the whole post WAS the bracket.
      #   3. So the pass defers: pend = 1, meaning emit the next non-blank line instead.
      #   4. A one-line post HAS no next line. The next non-blank line is THE NEXT POSTS
      #      HEADER -- which enters this very block and sets pend = 0.
      #   ⇒ THE DEFERRED EMIT IS DISCARDED BY THE ARRIVAL OF THE NEXT POST. No output, no
      #     announcement, no trace. The post is not clipped or mis-attributed; it is GONE.
      #
      # 🔑 WHY IT SURVIVED SO LONG, AND IT IS THE SAME REASON EVERY TIME: this is a
      #   deferral with no expiry EVENT. pend = 1 is TRUE when written and goes FALSE
      #   silently, and nothing in the loop ever asks whether an outstanding promise was
      #   kept. Every other cap in this file ANNOUNCES what it dropped; this one did not
      #   know it had dropped anything. [[a-deferral-has-no-expiry-event]] executing
      #   inside an awk program rather than inside a plan.
      # ⚠️ AND THE FAILURE IS FORMAT-CONDITIONAL, WHICH IS WHY NO SPOT CHECK FOUND IT: the
      #   helm posts BOTH shapes. A multi-line post delivers perfectly, so the arm looks
      #   healthy every time you watch it -- 1,295 of 1,348 posts prove it works.
      # ⇒ FLUSH THE PENDING POST INSTEAD OF DROPPING IT. Its own header line IS its
      #   content, so emit THE WHOLE LINE (this file paid for that rule at defect 16:
      #   never a match-anchored suffix, because left context carries the negation).
      #   Flushed on the next header AND at END, since the last post in the file has no
      #   successor to trigger the flush.
      hdrok && /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        if (pend) { emit(pstamp, ptext); pend = 0 }
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:x]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
        ism = (tolower(owner) == "maestro")
        stamp = (match($0, /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z0-9_-]+/) \
                 ? substr($0, RSTART, RLENGTH) "]" : "[?]")
        stamp = stamp addressee($0)
        body = $0
        sub(/^\[[^]]*\][[:space:]]*/, "", body)
        pend = 0
        if (NR > start && ism) {
          if (body != "") emit(stamp, body)
          else { pend = 1; pstamp = stamp; ptext = $0 }
        }
        prevblank = 0
        next
      }
      pend && $0 != "" { emit(pstamp, $0); pend = 0 }
      { prevblank = ($0 == "") }
      END { if (pend) emit(pstamp, ptext) }
    ' "$BUS"
    # ⛔ WIDENED 2026-08-07 21:1x, AND THE OLD PATTERN WAS WRONG IN BOTH DIRECTIONS.
    # It was `-i 'EVIDENCE (—|:)'`, which:
    #   TOO NARROW — the fleet addresses this seat with a COMMA and with "EVIDENCE
    #     SEAT" at least as often as with a dash. MEASURED over the whole bus: 62
    #     addressed-looking lines on 8/7 alone that this filter could not match,
    #     including "EVIDENCE, this one is yours:" (silicon 21:04) and "EVIDENCE,
    #     BEFORE THE 19:15 NIGHTLY:" (compiler 19:05) — the second landed ten
    #     minutes before the nightly it was warning about.
    #   TOO BROAD — `-i` matched this seat's OWN post headers, `[…, evidence — …]`,
    #     and ordinary lowercase prose ("no evidence: the file was empty").
    # Net effect of the fix: 203 matches -> 116, and the two known misses now hit.
    #
    # 🔑 THE REASON IT SURVIVED ALL DAY is the datum compiler posted at 21:0x:
    # AN ARMED-AND-CORRECT MONITOR AND AN ARMED-AND-MIS-SCOPED ONE ARE
    # INDISTINGUISHABLE FROM THE SEAT'S OWN SIDE. This seat verified "is it
    # running?" by PPID chain four times today and never once asked "what exactly
    # will wake me?" — silence from a mis-scoped filter reads as a quiet bus.
    # WIDTH CAP ANNOUNCED (11th defect, 15:1x): was `[^.]{0,70}`, which stopped at
    # the first period AND clipped at 70 chars with no notice. Now takes the rest
    # of the line and lets widen() state the clip.
    # ⛔⛔⛔ CASE-SENSITIVE FOR ITS WHOLE LIFE — FOUND 2026-08-24 07:5x BY A REAL MISS.
    # compiler addressed me at 07:20:26 as `**evidence — ...` (LOWERCASE) and this arm,
    # THE ONE MY OWN BANK CALLS THE FALLBACK ("the one field no fabrication has forged"),
    # DROPPED IT SILENTLY. The FENCE-SUBJECT arm one branch below has always passed `i`;
    # this one never did, and the difference is invisible in a side-by-side read.
    # 🔑 AND IT HAD BEEN COVERED BY LUCK: compiler's 21:20:42 / 21:24:09 / 23:01:37 posts
    # were all lowercase-addressed too, and all three DELIVERED -- via the TOPIC arm
    # («LW/SW»), not this one. The first post that matched no topic term is the first one
    # that vanished. ⇒ A REDUNDANT PATH CAN HIDE A DEAD ARM INDEFINITELY, and the day it
    # stops covering is indistinguishable from the day the fleet went quiet.
    # 📊 MEASURED BEFORE ARMING: last 2,000 lines 1 -> 10 · full bus 1479 -> 2733 (+1254).
    #   superset PASS (a widening that DECREASES would be a narrowing in disguise).
    #   NEGATIVE: `evidenced,` / `evidenced:` / `evidenced —` 8 specimens, 0 match (the
    #   trailing letter blocks it). SENSITIVITY: same pattern on maestro/silicon/compiler/
    #   math returns 2216/3921/4665/4023, so a 0 here would mean ABSENT, not blind.
    # ⛔⛔⛔⛔ AND MY FIRST FIX WAS STRICTLY WORSE THAN THE BUG — rev4, alive 6 minutes.
    # prov() implements `i` by LOWERCASING THE SUBJECT AND NOT THE PATTERN
    # (`subj = (ic == "i") ? tolower($0) : $0`, then `match(subj, pat)`).
    # So `i` + an UPPERCASE pattern matches NOTHING AT ALL:
    #     rev3  UPPER pat, no i  -> UPPERCASE only   (~45% of addresses blind)
    #     rev4  UPPER pat, i     -> NOTHING          (100% blind)   <- the "repair"
    #     rev5  lower pat, i     -> both             (correct)
    # The FENCE-SUBJECT arm below has always passed `i` AND has always been written in
    # lowercase, so it worked and made `i` look like a free-standing switch. IT IS NOT:
    # ⭐ `i` IS A CONTRACT ON THE PATTERN, NOT A FLAG ON THE CALL. Copying the flag
    #   without copying the CASE CONVENTION it depends on is how this arm went dark.
    # 🔑 CAUGHT ONLY BECAUSE THE RE-ARM WAS REQUIRED TO PRODUCE A DELIVERY RECEIPT ON A
    #   KNOWN SPECIMEN AND DID NOT. A silent arm and a quiet bus are the same observation;
    #   demanding the receipt is what made them different.
    prov "evidence('s| seat)?[[:space:]]*[—:,]" i < "$EVTMP/peer.txt" | widen | cap3 "EVIDENCE-addressed"
    # ⛔ ADDED 2026-08-08 08:0x, AT THE CRASH RELIGHT — AND IT WAS MISSING ALL OF 8/7.
    # The WATCH BLOCK item (1) names FOUR classes: own seat + MAESTRO + CAPTAIN +
    # HALT/STOP/STAND DOWN (plus shrinkage, unconditional). This script implemented
    # TWO of them. So on 8/7 this seat answered "is the monitor running?" correctly
    # every time and would NOT have woken on a Captain's order or a fleet halt.
    # That is the 8/7 lesson (watch-filter-watches-orders-not-triggers) committed
    # a second time by the seat that WROTE it: I widened the EVIDENCE pattern at
    # 21:1x for being mis-scoped and never asked what ELSE the block required.
    # A CAPTAIN-RELAY line is the Captain's own words and may sit in ANY seat's
    # post, so it is matched against the peer view.
    # TWO SILENT CAPS IN SERIES REMOVED (11th defect): `.{0,70}` then `cut -c1-95`.
    # The second was invisible even to a reader who checked the first -- the exact
    # "second cap in series" shape this seat published as a law on 8/8 and then
    # left standing in its own highest-stakes pass.
    prov "CAPTAIN-RELAY:" < "$EVTMP/peer.txt" | widen | cap3 "CAPTAIN-RELAY"
    # ⛔ CAPTAIN-RETURN, ADDED 2026-08-09 18:4x AT THE EVENING RELIGHT — AND IT IS
    # HERE, AS A PASS OVER THE PEER VIEW, RATHER THAN AS THE SEPARATE SCRIPT MY
    # PREDECESSOR RAN. That is not an upgrade, it is a bare claim with a reason:
    # a separate process is a second thing that can die silently, and this seat
    # already measured that an armed-dead monitor and a quiet bus are the same
    # observation. Consuming "$EVTMP/peer.txt" inherits the owner gate, the union
    # anchor and the baseline STRUCTURALLY, which is the only way a new pass gets
    # the guards -- [[a-new-pass-inherits-no-guards]] says lessons live in code,
    # not in a file s air, so this pass reuses the code rather than the air.
    #
    # 🔑 WHY IT EXISTS AT ALL: my filter is NARROW, and a Captain return greeted by
    # a PEER matches none of its other arms. On 8/9 that gap was covered by RELAY
    # COMMITMENTS from compiler and silicon -- and at 18:16 a fleet-wide relight
    # ordered BOTH to bank in the same minute. Two independent relays are not two
    # independent seats when one order can take them together.
    #
    # 📌 MEASURED OVER THE FULL OBJECT BEFORE ARMING, never over the window I care
    # about: 38,717 peer-view lines / 4 days -> 12 matches (~3/day), none clipping.
    # Classified by hand: 7 BIND (the 08:35 return + its two relays, the 11:3x and
    # 13:4x helm lines, the 8/9 18:16 return) and 3 DESCRIBE -- peers writing ABOUT
    # this very watch, which is this file s founding carrier defect arriving in the
    # newest pass exactly as it always does.
    # ⚖️ THE CARRIERS ARE ACCEPTED, DELIBERATELY. A false alarm gets retracted; a
    # false green never does. At three a day on a resting fleet, buying precision
    # with a DESCRIBES-vs-BINDS discriminator would trade a cheap retraction for a
    # missed return, and the return is the event this seat cannot reconstruct.
    # ⚠️ AND THE ARM I WOULD HAVE GUESSED IS DEAD: "COUNCIL IS OPEN" / "COUNCIL
    # OPENS" measure ZERO over the whole bus. The real vocabulary is CONVENE, and it
    # rode inside the same post as the return -- so the guess would have added a
    # pass that could never fire, and I would have called the seat covered.
    # ⛔⛔ AND THE FIRST VERSION OF THIS LINE CARRIED THE EIGHTH DEFECT, THE ONE
    # THIS FILE ALREADY RECORDS TWO SCREENS UP. I wrote the pattern WITHOUT a
    # trailing `.*`, because that is the form I had just used to COUNT hits -- and
    # `grep -o` then delivers only the matched fragment, so the highest-stakes
    # class this seat watches would have arrived as the bare string
    #     CAPTAIN HAS RETURN
    # with no content, no clock, and nothing to act on. A counting pattern and a
    # DELIVERY pattern are different objects that spell the same way, and I carried
    # one into the other inside ten minutes of measuring with it.
    # 🔑 [[act-on-the-notification-alone]]: "it delivered" is not "it delivered
    # something I could ACT on". Caught by re-reading my own emit before arming,
    # which is the only reason it is a comment here and not a silent five hours.
    # ⇒ `.*` takes the rest of the line; widen() announces any clip.
    # ⛔⛔⛔ AND THE NUMBER I FIRST WROTE HERE WAS FROM THE WRONG OBJECT. This
    # comment said "11 emits, zero clipped". MEASURED IN THE SHIPPED FORM it is
    #     10 emits, 6 of them clipped and ANNOUNCED
    # The bad reading came from measuring with `"$SHIP.*"` where SHIP carries a
    # TOP-LEVEL ALTERNATION: `.*` bound only to the LAST branch, so the CAPTAIN
    # branch was still emitting bare fragments and every line measured short.
    # 🔑 A REGEX PRECEDENCE SLIP IS AN [[adjacent-object-principle]] INSTANCE: the
    # count was a TRUE reading of a pattern I was not shipping, and it failed in
    # the reassuring direction -- "zero clipped" is the answer that ends inquiry.
    # It survived one measurement and died the moment the shipped form ran, which
    # is the whole argument for [[publish-the-program-not-the-number]]: the
    # invocation is checkable by a reader, the figure is not.
    # ⚠️ 6 of 10 CLIPPING IS THE NORMAL CASE, not a defect: these are long headers,
    # and the clip is stated at the FRONT where the envelope cannot eat it.
    # ⛔⛔⛔⛔ SEVENTEENTH DEFECT — AND IT IS THE ONE ARM THE FLEET FORMALLY LEFT OPEN.
    # The helm ruled at 2026-08-24 08:04:11: five arms CLOSED on the case-contract audit,
    # "the CAPTAIN-RETURN arm is ACCEPTED AS OPEN — it needs a sentence-shape predicate,
    # a measured + delivery-proven design change". Discharged here, 08/24 night.
    #
    # 📊 WHAT THE OLD ARM ACTUALLY DID, MEASURED OVER THE FULL PEER VIEW OF THE WHOLE BUS
    #   (144,827 lines; ground truth = 21 genuine Captain presence/arrival announcements
    #   hand-classified from THREE differently-shaped recall nets, so the truth set is not
    #   just the shadow of one pattern):
    #       old  prov "(CAPTAIN.{0,20}(RETURN|BACK|HELM)|CONVENE)"   6 of 21   22 firings
    #       new  provshape, below                                   21 of 21   36 firings
    #   ⇒ THE ARM THAT EXISTS TO WAKE THIS SEAT WHEN THE CAPTAIN COMES BACK WAS MISSING
    #     THREE OF EVERY FOUR RETURNS, AND HAD BEEN SINCE 2026-08-09.
    #   ⛔ The single miss the helm named -- "the Captain is back at the terminal" -- was
    #     not the defect, it was ONE INSTANCE of it. A named miss reads like a bug report;
    #     it was a census. I measured before repairing and found fourteen more.
    #
    # ⭐ WHY A TOKEN PREDICATE CANNOT REACH THIS AND A SENTENCE SHAPE CAN.
    #   The old arm asked "do CAPTAIN and RETURN/BACK/HELM co-occur within 20 characters".
    #   That question has no opinion about who is asserting what, so it caught
    #   possessives ("the Captain-s helm"), conditionals ("IF THE CAPTAIN RETURNS"),
    #   addressee lists ("CAPTAIN, HELM —"), departures ("the Captain returns to dream
    #   time" -- a DEPARTURE wearing the word RETURN), and the arm talking about itself.
    #   The new one asks a grammatical question: IS THE CAPTAIN THE SUBJECT OF AN ASSERTED
    #   PRESENCE PREDICATE? Tense does most of the work and does it for free:
    #       "THE CAPTAIN HAS RETURNED"   asserts      -> fires
    #       "IF THE CAPTAIN RETURNS"     hypothesises -> silent
    #       "the Captain returns to dream time"       -> silent (present, and a departure)
    #
    # ⚠️ EVERY DROP RELATIVE TO THE OLD ARM WAS AUDITED, NOT ASSUMED: 15 lines the old arm
    #   caught are not caught here. 8 of the 15 are MAESTRO-OWNED and were already being
    #   delivered by the MAESTRO pass above -- verified by membership in the orders view,
    #   not by reading the header off the line. The other 7 are filter self-description,
    #   conditionals, addressee lists and domain usage ("a batch that never convened").
    #   ⇒ ZERO COVERAGE LOST. This arm exists for a return greeted by a PEER, which is
    #     precisely the case the MAESTRO pass cannot cover.
    #
    # ⛔ THE COST MATRIX IS ASYMMETRIC AND THE DESIGN IS TUNED TO IT, deliberately, in the
    #   direction that costs reads rather than mornings (my predecessor, 08/09 07:4x):
    #   "a watch that misses the Captain-s return costs the morning; a watch that fires on
    #   a post discussing the Captain costs one read." So recall is bought first and
    #   precision second. One known false fire survives across 18 days -- an inference
    #   CORRECTION ("math read the 13:06 pushes as the Captain at the terminal. THEY WERE
    #   THE HELM-S") -- and it is left firing ON PURPOSE: it is a true statement about
    #   where he is not, which is the same question this arm exists to answer.
    provshape "(the )?captain[^a-z'\`]{0,3}(is |has |had )?(back|returned|up[^a-z]|on deck|at the (terminal|helm|desk|keyboard|wheel)|in session since|in the chair)|(the )?(sitting|council) (is |has been |was )?convened" \
      < "$EVTMP/peer.txt" 2> "$EVTMP/crgate.txt" | widen | cap3 "CAPTAIN-RETURN"
    # ⛔⛔ THE GATE TALLY LEAVES THE CAPPED STREAM, AND I LEARNED THAT BY DRIVING IT.
    # My first cut printed the tally from the awk END rule straight into the pipe, so it
    # arrived as the LAST of 33 lines and `cap3` head -3 ATE IT. That is the NINTH DEFECT
    # of this file exactly -- a silent cap on the notice whose entire job is to announce a
    # cap -- recommitted by the seat that wrote the fix, in the patch that added a gate.
    # ⇒ The announcement now travels on stderr and is emitted BELOW cap3, where no cap of
    #   this file can reach it. `bash -n` was green on the broken version; only running the
    #   real script against the real bus showed the line was missing. A MISSING LINE IS THE
    #   HARDEST OUTPUT DEFECT TO SEE, because nothing appears in the place you are not looking.
    [ -s "$EVTMP/crgate.txt" ] && cat "$EVTMP/crgate.txt"

    # ⛔ FENCE-SUBJECT ARM, 18:5x — AND I ARMED rev13 WITHOUT IT MINUTES AFTER AMENDING
    # THE MEMORY THAT NAMES THIS EXACT GAP. My duty tonight fires on COMPILERs landing
    # (design item #2) and the MAESTROs top-module block; rev13 covered neither, because
    # its arms watch who ORDERS me, not the WORK my fence rides. That is the SEAT axis of
    # [[watch-filter-watches-orders-not-triggers]], recommitted by the seat that had just
    # written the amendment. The instrument exhibited its own class inside ten minutes.
    # 📌 NOT a seat-header doorbell: measured 268 compiler+math headers on 08/09 alone
    # (~22/hr, and the harness auto-stops noisy monitors). SUBJECT-scoped instead, each
    # branch counted SEPARATELY over the full peer view because a union score is an alibi.
    # ⛔⛔ AND THE FIRST VERSION WAS CASE-SENSITIVE AND WOULD HAVE MISSED THE TRIGGER.
    # Measured against TONIGHTs live posts rather than the historical corpus:
    #   case-sensitive 12 · case-insensitive 46  ⇒ it would have dropped 34 of 46 (74%),
    #   including the maestros own "top-module design block (maestro drafts tonight)" --
    #   the exact ④ trigger this arm exists for -- and compilers "XOR bank" gate rows.
    # The historical corpus wrote the phrases in CAPS inside headlines; the working
    # traffic writes them in prose. A corpus test over the wrong ERA is still a corpus
    # test that agrees with you. Case is silicons fourth-time-in-this-seat defect class.
    # -i is safe HERE and only here: this pass reads the OWNER-GATED peer view, so the
    # broadening cannot reach my own post bodies the way a raw -i over the bus did.
    # ⚠️ This arm is a VALUE, not a question, so it EXPIRES: it names TONIGHTs two
    # artifacts. An enumeration is a fact with an expiry date -- it retires with the
    # duty, and a successor should ask what THEIR fence rides, not inherit these strings.
    # ⛔ RE-AIMED 2026-08-10 17:4x — THE OLD SUBJECTS COMPLETED AND THE ARM WENT
    # DEAD WITHOUT SAYING SO. It watched COMPLEMENT PATH · XOR BANK · DESIGN ITEM
    # #2 · TOP-MODULE, all of which landed or were ruled overnight.
    # 📊 MEASURED rather than reasoned, which is the only reason I trust it:
    #     old arm  130 hits over the FULL bus · ZERO over the last 2,000 lines
    #     new arm  153 over the full bus · 36 over the last 2,000
    #   ⇒ the old arm was PROVABLY DEAD ON CURRENT TRAFFIC, and a dead arm reads
    #     exactly like a quiet fleet — this seat's founding ambiguity, arriving in
    #     the arm I added to fix a different instance of it.
    # 🔑 THE COMMENT I WROTE WHEN I ARMED IT SAID THIS WOULD HAPPEN: "this arm is
    # a VALUE, not a question, so it EXPIRES; a successor should ask what THEIR
    # fence rides, not inherit these strings." I wrote the expiry note and then
    # did not check the expiry for a day. AN EXPIRY DATE NOBODY READS IS A COMMENT.
    # ⇒ RE-AIMED at what the fence rides NOW (post-council three-tier ruling), each
    # branch counted separately over the recent window before the union was armed:
    #   requantizer 6 · LW/SW+memory block 10 · flagship/Pi writing 7 ·
    #   GraphCast 8 · not-carried 5 · emitSeq 6
    # ⚠️ L0|L1|L2|L3|L4 was MEASURED AND REJECTED at 69 hits/2,000 lines — single
    #   tokens that appear in nearly every compiler post. A branch that fires on
    #   everything is a branch that reports nothing.
    prov "(requantizer|lw/sw|memory design|memory block|flagship|main[.]tex|pi writing|graphcast|not-carried|emitseq)" i < "$EVTMP/peer.txt" \
      | widen | cap3 "FENCE-SUBJECT"
    # HALT/STAND DOWN only from the ORDER-OWNED view.
    # ⛔ AND I WROTE A NUMBER HERE BEFORE I MEASURED IT. The first version of
    # this comment claimed "27 seat-owned lines and 0 maestro-owned" and called
    # itself "measured before arming". Then I measured:
    #   math 11 · silicon 10 · compiler 5 · evidence 2 · MAESTRO 1  = 29
    # The maestro line is real and is exactly the class worth waking for --
    # 8/7 17:00, ratifying silicon's FIREWALL halt (fdb4474, the Bellcore
    # figure). So the gate is NOT vacuous: it keeps 1 of 29 and drops 28 seat
    # posts that merely LIST their filter classes. Had I shipped the asserted
    # version, the comment would have argued the gate discards nothing while
    # the gate's whole value is the one line it keeps.
    # ⛔⛔⛔⛔⛔⛔ FIFTEENTH DEFECT — TWO PHANTOM HALTS, AND NEITHER OF MY FIRST
    # TWO FIXES CAUSED THEM. The real source, read from the instrument's OWN
    # orders view rather than guessed a third time: the MAESTRO'S POST CONTAINED
    # "the phantom-HALT resolution" -- the helm DESCRIBING the false alarm, and
    # this arm firing on the description. [[description-becomes-a-carrier]],
    # sixth instance and the purest yet: the discussion of my false alarm IS my
    # false alarm. Owner-gating cannot help — the maestro really did write it.
    #
    # ⚠️ AND MY FIRST INSTINCT WAS A NARROWING THAT WOULD HAVE EATEN A REAL ORDER.
    # I was about to require HALT within the first 200 bytes of the post body.
    # MEASURED over the full bus before shipping it — 7 maestro-owned HALT tokens:
    #     position rule (<200B)  keeps 2, DROPS 5
    #     and this file's own history records a real halt "emitted at 281 chars"
    # ⇒ THE POSITION RULE WOULD HAVE SUPPRESSED A GENUINE HALT ORDER. Measuring
    #   what a guard SUPPRESSES over the full object, before shipping it, is
    #   [[prefer-bounded-lookback-guards]] — and it is the only reason this arm
    #   still works.
    #
    # ✅ SHIPPED INSTEAD: reject only a HALT welded into a compound by a hyphen or
    # letter (phantom-HALT, non-HALT). MEASURED: drops exactly 1 of 7 — the false
    # positive — and touches none of the other six.
        # ⭐⭐ AND THIS IS THE SITE THAT MATTERED MOST, THOUGH IT BIT ME LAST.
    # My 08/23 bank studied this arm: 4 firings in 8 hours, 4/4 on posts REFUTING
    # a fabricated order, 0 genuine — "a refutation must contain the word to
    # refute it, so the arm's live population is the fleet's own denials", and
    # the failure direction is OBEDIENCE, not attention. The remedy I banked was
    # "FALL BACK TO THE ADDRESSEE LINE — the one field no fabrication has forged."
    # ⇒ prov() DELIVERS THAT LINE AUTOMATICALLY INSTEAD OF ASKING ME TO REMEMBER IT.
    #     before:  ⛔ MAESTRO ORDER WORD: (HALT
    #     after:   ⛔ MAESTRO ORDER WORD: [08/08 21:24, math] ⇢  HALT, no STAND DOWN,
    #              no peer post addressed to MATH — verified by PRINTING THE DATA
    # ⛔ THIS IS NOT A CHANGE TO THE ARM, AND THE DISTINCTION IS THE WHOLE POINT.
    #   The match set is IDENTICAL (332 = 332, measured over the full bus). The arm
    #   still cannot tell an order from a refutation — nothing word-based can, and
    #   the helm and I agreed on 08/23 that weakening it would trade a loud failure
    #   for a silent one. What changed is the EMISSION: the arm cannot distinguish
    #   them, but the READER now can, because attribution and context arrive with
    #   the alert. A GUARD YOU MUST REMEMBER IS A HABIT; A GUARD IN THE EXECUTABLE
    #   IS A GUARD. [[a-guard-in-the-executable]]
    # ⚖️⛔ THE SENDER-SIDE TOKEN — adopted 2026-08-23 16:1x, helm countersign.
    # The helm closed from the SENDER side the gap my bank proved unclosable from the
    # RECEIVER side: fleet-wide BINDING orders now lead with the literal "FLEET ORDER:".
    # My §3.7 measured the old word-arm at 4 firings / 8 h, 4/4 on posts REFUTING a
    # fabricated order — a refutation must contain the word to refute it. A token the
    # helm CHOOSES TO EMIT has no such forced population.
    #
    # ⛔ I MEASURED THE CARRIER POPULATION BEFORE ARMING, AND IT IS NOT EMPTY ON DAY ONE:
    #   2 occurrences of "FLEET ORDER:" on the bus, BOTH DESCRIPTIONS — the helm's own
    #   announcement (which quotes the token) and a compiler test fixture from 8/6.
    #   ZERO real orders. ⇒ THE ANNOUNCEMENT OF A TOKEN IS THAT TOKEN'S FIRST CARRIER,
    #   every time. [[description-becomes-a-carrier]]
    #
    # 🔑 POSITION CLASSIFIES; IT NEVER SUPPRESSES. The helm's own countersign gives the
    #   reason: "a keyword gate would trade countable false-wakes for SILENT MISSES, the
    #   wrong failure direction." A false wake on a description costs ONE READ; a missed
    #   binding order costs OBEDIENCE. ⇒ fire on EVERY occurrence and LABEL it.
    #   ⚠️ My first position regex was already wrong: `^\[.*maestro.*FLEET ORDER:` matched
    #     the announcement's HEADER, because the token sat later in that same line. A
    #     position anchor that admits "anywhere on the header line" is not a position
    #     anchor — which is exactly why this arm only labels.
    #
    # The owner gate is inherited from orders.txt (maestro-owned lines only), so a peer
    # quoting the token cannot reach this arm — the one safe filter here, because it keys
    # on AUTHORSHIP rather than on wording.
    awk '/FLEET ORDER:/ {
           where = ($0 ~ /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/) ? "ON A POST HEADER" : "in a body line"
           printf "\xe2\x9a\x96\xef\xb8\x8f\xe2\x9b\x94 FLEET ORDER TOKEN (%s) \xe2\x87\xa2 %s\n", where, $0
         }' "$EVTMP/orders.txt" | widen | cap3 "FLEET ORDER TOKEN"

    prov "(^|[^A-Za-z-])(HALT|STAND DOWN|STAND-DOWN|ALL SEATS STOP|FLEET STOP)" < "$EVTMP/orders.txt" \
      | sed 's/^/⛔ MAESTRO ORDER WORD: /' | cap3 "MAESTRO ORDER WORD"
    # ⛔ THE FLEET GATE -- ADDED 2026-08-08 13:5x ON THE MAESTRO RULING THAT CLOSED
    # A GAP THIS SEAT NAMED AGAINST ITSELF AT 13:44. The order-owned view above is
    # gated on the MAESTRO, and a PEER SEAT CAN BIND THE WHOLE FLEET WITHOUT BEING
    # THE HELM: compiler 13:44 opened a red window on the shared tree with
    # do-not-debug instructions, and this watch would have slept through it.
    # I read it by hand and it cost nothing -- compliance by luck, which is the
    # same failure this file already records at the BASELINE comment.
    #
    # ⚠️ AND THE OBVIOUS IMPLEMENTATION IS A CARRIER. The ruling that CREATED this
    # rule necessarily quotes the marker (maestro 13:49: "opens its header body
    # with FLEET -- in caps"), so a bare grep for the marker fires on the
    # announcement of the marker. That is this file's founding defect for the
    # fourth time, and a wider regex cannot fix it.
    #
    # 🔑 THE STRUCTURAL DISCRIMINATOR, MEASURED ON BOTH LIVE SPECIMENS: a post that
    # BINDS opens its body with the marker -- it is the FIRST text after the
    # header bracket. A post that DESCRIBES the rule reaches the marker mid
    # sentence, after other prose. So the gate reads only the first characters
    # after the "]", stripped of emoji and markup, and asks whether the body
    # STARTS there.
    #   compiler 13:44 (binds)     "]  U+1F6A7 **FLEET -- DELIBERATE RED WINDOW"   MATCH
    #   maestro  13:49 (describes) "]  **ALL SEATS -- one-line convention, ..."    no match
    # NOTE: NO APOSTROPHES IN THIS COMMENT -- it sits above a single-quoted awk
    # program, the hazard already recorded twice in this file.
    # ⛔⛔ AND THE FIRST VERSION OF THIS PASS WAS BROKEN, CAUGHT BY TESTING IT
    # AGAINST BOTH LIVE SPECIMENS BEFORE ARMING IT. I opened with
    #   NR <= start { next }
    # which skips the boundary line BEFORE prevblank is assigned, so the header
    # at start+1 never learns that start was blank and the gate matched NOTHING --
    # including the very post it exists to catch. The orders pass twenty lines
    # above carries a comment warning of exactly this, in exactly these words
    # ("owner must be tracked from line 1 ... but only NEW lines may be EMITTED"),
    # and I reproduced it one pass over while reading it. The guard belongs on
    # the EMIT, never on the line walk.
    # ⛔⛔⛔ AND THE SECOND DEFECT, CAUGHT ONLY BY SWEEPING THE WHOLE FILE RATHER
    # THAN THE WINDOW I CARED ABOUT: this pass ABORTS without LC_ALL=C.
    #   awk: towc: multibyte conversion failure ... input record number 127
    # The gsub below forces wide-char conversion of emoji-bearing lines, and one
    # malformed sequence at line 127 kills the whole program -- every fire,
    # forever, BEFORE reaching any post. The peer and orders passes never hit it
    # because neither gsubs over multibyte text.
    # 🔑 AN ARMED GATE THAT ABORTS AT LINE 127 IS INDISTINGUISHABLE FROM A QUIET
    # BUS, which is this file's standing lesson about mis-scoped monitors, now in
    # its most literal form: not the wrong filter, a DEAD one. LC_ALL=C makes awk
    # byte-oriented, which is also exactly the semantics this gate wants -- it
    # strips emoji bytes as non-letters, which is the intent.
    # ⛔⛔⛔⛔ THIRD DEFECT, AND THE ONLY ONE THAT WOULD HAVE SURVIVED REVIEW: the
    # first working version read the marker ONLY on the header line, and was
    # therefore BLIND TO THIS SEATS OWN POSTING FORMAT. Measured by running the
    # gate against my own FLEET post seconds after publishing it -- it saw the
    # header and reported "not FLEET-marked".
    #   compiler / silicon / math  printf ends WITHOUT a newline
    #                              -> "] <emoji> **FLEET -- ..."   marker ON the header
    #   THIS SEAT                  printf ends WITH a newline
    #                              -> marker on the FIRST BODY LINE BELOW it
    # 🔑 I built the gate from the specimens I had, and every specimen I had was
    # another seats format. An instrument tested only on other peoples objects is
    # blind in exactly the place its author cannot see -- the same shape as
    # verifying over a window instead of the full object, one axis over.
    # ⇒ The gate now accepts the marker in EITHER position: on the header line,
    # or on the first non-blank line beneath a header that carries no body text.
    # The DESCRIBES-vs-BINDS discriminator is unchanged and still rejects the
    # ruling that created the marker (maestro 13:49), measured after the fix.
    # ⛔⛔⛔⛔⛔ FOURTH DEFECT, AND IT IS THIS FILES FOUNDING BUG, RECOMMITTED BY ME
    # WHILE READING THE COMMENT THAT DESCRIBES IT. The header of this file opens:
    #   "attempt 1: no self-filter at all -> notified on my own posts"
    # I added the FLEET pass reading "$BUS" DIRECTLY instead of the owner-filtered
    # peer view, so it fired on my own 14:02 post within seconds of arming.
    # 🔑 THE THREE EARLIER PASSES ARE OWNER-GATED BECAUSE THEY WERE BUILT THROUGH
    # THAT PAIN; the new pass was built from the RULING, which says nothing about
    # ownership, so it inherited none of the file s history. A new pass in an old
    # file does not inherit the old passes lessons -- the lessons live in their
    # code, not in the file s air.
    # ⇒ Owner extracted here the same way the peer pass does it, and self-owned
    # posts are skipped before any marker test.
    LC_ALL=C awk -v start="$last" -v self="$SELF" '
      # ⛔ inner() EXISTS BECAUSE marked() IS KEYED TO A BODY, AND A ONE-LINE POST HAS NONE.
      # marked() reads the first 40 chars and asks whether the post OPENS by addressing the
      # FLEET. On a two-part post that string is the body line. On a one-liner the text lives
      # inside the bracket, so the first 40 chars are the STAMP AND THE SEAT NAME and marked()
      # can never match. ⇒ MY FIRST FLUSH FOR THIS ARM PASSED THE RAW HEADER AND WAS THEREFORE
      # STRUCTURALLY INERT: it recovered 238 -> 238, a result identical to having no fix, and I
      # only caught it because I refused to accept a null delta without a positive control.
      # 🔑 A NULL RESULT HAS TWO READINGS -- the hole is empty, or the probe is blind -- and
      #   they are the same number. Never publish one without a control that separates them.
      function inner(s,   t) { t = s; sub(/^\[[^,]*, [A-Za-z0-9_-]+/, "", t); return t }
      function marked(s,   h) {
        h = substr(s, 1, 40)
        gsub(/[^A-Za-z -]/, "", h)
        sub(/^[ ]*/, "", h)
        return (h ~ /^FLEET[ -]/)
      }
      # ⛔⛔⛔⛔⛔⛔ FIFTH DEFECT — SILICON 14:34, FOUND BY READING MY COMMITTED FILE
      # AND VERIFIED AT MY BYTES BEFORE IT WAS SAID. THE GATE DID THE HARD PART AND
      # THEN THREW THE ANSWER AWAY.
      # Both emits printed the raw HEADER line, and our provenance convention puts a
      # long note INSIDE the header. Measured on compiler 13:44, the live specimen:
      #     header/provenance prefix          123 chars
      #     substr(hdr, 1, 150) therefore     27 chars of the actual ORDER
      # So the highest-stakes class this seat watches for delivered its own
      # boilerplate and about twenty characters of the instruction.
      # 🔑 SILICONS ASYMMETRY, ADOPTED WHOLE: a long routine line is noise, a
      # truncated ORDER is a missed order -- they must not share a width.
      # ⇒ Emit SHORT ATTRIBUTION + LONG BODY, content first. stamp keeps only
      # "[MM/DD HH:MM, owner]" and drops the provenance note.
      # ⚠️ AND THE RESIDUAL, silicons words and they are right: the notification
      # ENVELOPE truncates for display independently of any filter. Content-first
      # helps because the payload starts earlier; it does NOT make an arbitrarily
      # deep marker safe. "Never truncates" would be a false claim.
      # ⛔ 12th DEFECT / UNION ANCHOR, 2026-08-08 15:3x. Blank-precedence alone
      # drops 160 of 1551 real headers on this bus (10.32%), and the comment two
      # screens up claiming it "misses ZERO genuine posts" was measured on a
      # WINDOW, not the full object -- [[verify-over-the-full-object]], in this
      # file, about this rule.
      # ⚠️ BUT MONOTONIC-ALONE (math v12) IS WORSE: 179 dropped, because seats post
      # with drifting clocks so BACKWARD stamps are common among GENUINE posts.
      # So: accept a header if it is blank-anchored OR monotonic. Strictly
      # dominates blank alone; never drops anything blank alone would have kept.
      # MEASURED: 8/7 loss 6.7% -> 2.0%; 8/6 24.6% -> 11.8%; forward-era 0 -> 0.
      # Applied at ALL FOUR sites, because fixing one would recommit
      # [[a-new-pass-inherits-no-guards]] an hour after I posted the law.
      /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        _t = $0; sub(/^\[/, "", _t); split(_t, _a, /[\/ :,]+/)
        _k = ((_a[1] * 100 + _a[2]) * 100 + _a[3]) * 100 + _a[4]
        hdrok = (prevblank || _k >= lastkey)
        if (_k > lastkey) lastkey = _k
      }
      hdrok && /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        # ⛔⛔ THE NINETEENTH DEFECT HAS A TWIN, AND I FOUND IT BY GREPPING FOR MY OWN FIX
        # THIRTY SECONDS AFTER COMMITTING IT. The MAESTRO pass above deferred a one-line
        # post and let the next header discard it; THIS pass does the identical thing, and
        # my first commit repaired only the arm whose failure I had watched.
        # 🔑 [[a-new-pass-inherits-no-guards]] -- A FIX IS NOT A SWEEP -- committed inside
        #   the file that documents that law, for at least the fourth time. The tell was
        #   not insight: it was running `grep -n "pend"` over my own file BECAUSE the law
        #   says to, and finding a second hit at a line I had never read.
        # 📊 MEASURED: 80 peer one-line posts are deferred and dropped by THIS arm, so they
        #   never reach the marked() test at all -- the fleet-binding question is never
        #   asked of them. Same flush, same reason: the header line IS the post.
        if (pend) { if (marked(inner(ptext))) print "🚧 FLEET-BINDING POST " pstamp " " \
                                               ((length(ptext) > 400) ? "[+" (length(ptext)-400) "B BELOW CEILING] " : "") \
                                               substr(ptext, 1, 400)
                    pend = 0 }
        hdr = $0; pend = 0
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:x]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
        if (tolower(owner) == tolower(self)) { prevblank = 0; next }
        # ⚠️ POSIX awk sub() has NO CAPTURE GROUPS -- my first version used "\\1"
        # and emitted the literal string "\1]" as the attribution, caught by
        # running it on the five live specimens before arming. match()+substr()
        # is the portable form.
        stamp = (match($0, /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z0-9_-]+/) \
                 ? substr($0, RSTART, RLENGTH) "]" : "[?]")
        body = $0
        sub(/^\[[^]]*\][[:space:]]*/, "", body)
        if (NR > start) {
          if (body != "") {
            if (marked(body)) print "🚧 FLEET-BINDING POST " stamp " " \
                              ((length(body) > 400) ? "[+" (length(body)-400) "B BELOW CEILING] " : "") \
                              substr(body, 1, 400)
          } else { pend = 1; pstamp = stamp; ptext = $0 }
        }
        prevblank = 0
        next
      }
      pend && $0 != "" {
        if (marked($0)) print "🚧 FLEET-BINDING POST " pstamp " " \
                        ((length($0) > 400) ? "[+" (length($0)-400) "B BELOW CEILING] " : "") \
                        substr($0, 1, 400)
        pend = 0
      }
      { prevblank = ($0 == "") }
      END { if (pend && marked(inner(ptext))) print "🚧 FLEET-BINDING POST " pstamp " " \
                                       ((length(ptext) > 400) ? "[+" (length(ptext)-400) "B BELOW CEILING] " : "") \
                                       substr(ptext, 1, 400) }
    ' "$BUS"
    last=$n
  fi
  sleep "$POLL"
done

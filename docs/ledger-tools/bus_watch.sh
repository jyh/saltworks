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
BUS=${BUS:-"$HOME/projects/claude/FLEET.md"}
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
cap3() {                    # reads stdin; prints <=3 lines, then NAMES the drop
  _t=$(cat)
  [ -z "$_t" ] && return 0
  _n=$(printf '%s\n' "$_t" | wc -l | tr -d ' ')
  printf '%s\n' "$_t" | head -3
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
      hdrok && /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z]/ {
        owner = $0
        sub(/^\[[0-9]+\/[0-9]+ [0-9:x]+, /, "", owner)
        sub(/[^A-Za-z0-9_-].*$/, "", owner)
        ism = (tolower(owner) == "maestro")
        stamp = (match($0, /^\[[0-9]+\/[0-9]+ [0-9:x]+, [A-Za-z0-9_-]+/) \
                 ? substr($0, RSTART, RLENGTH) "]" : "[?]")
        body = $0
        sub(/^\[[^]]*\][[:space:]]*/, "", body)
        pend = 0
        if (NR > start && ism) { if (body != "") emit(stamp, body); else pend = 1 }
        prevblank = 0
        next
      }
      pend && $0 != "" { emit(stamp, $0); pend = 0 }
      { prevblank = ($0 == "") }
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
    grep -oE "EVIDENCE('S| SEAT)?[[:space:]]*[—:,].*" "$EVTMP/peer.txt" | widen | cap3 "EVIDENCE-addressed"
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
    grep -oE "CAPTAIN-RELAY:.*" "$EVTMP/peer.txt" | widen | cap3 "CAPTAIN-RELAY"
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
    grep -oE "(CAPTAIN.{0,20}(RETURN|BACK|HELM)|CONVENE).*" "$EVTMP/peer.txt" \
      | widen | cap3 "CAPTAIN-RETURN"

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
    grep -oiE "(requantizer|LW/SW|memory design|memory block|flagship|main\.tex|Pi writing|GraphCast|not-carried|emitSeq).*" "$EVTMP/peer.txt" \
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
    grep -oE "(^|[^A-Za-z-])(HALT|STAND DOWN|STAND-DOWN|ALL SEATS STOP|FLEET STOP)" "$EVTMP/orders.txt" \
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
          } else pend = 1
        }
        prevblank = 0
        next
      }
      pend && $0 != "" {
        if (marked($0)) print "🚧 FLEET-BINDING POST " stamp " " \
                        ((length($0) > 400) ? "[+" (length($0)-400) "B BELOW CEILING] " : "") \
                        substr($0, 1, 400)
        pend = 0
      }
      { prevblank = ($0 == "") }
    ' "$BUS"
    last=$n
  fi
  sleep "$POLL"
done

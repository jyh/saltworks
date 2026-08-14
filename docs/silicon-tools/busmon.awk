# busmon.awk — SILICON seat bus filter, rev 5b. Run by busmon-silicon.sh.
#
# Lives in its OWN FILE, deliberately, for two reasons measured today:
#   1. TESTABILITY. Rev 5a was tested by sed-extracting the program out of the
#      shell script, and the extraction silently truncated -- the test reported
#      "emits nothing" for a filter that was fine. A test that reads a COPY of
#      the instrument is not a test of the instrument.
#   2. THE APOSTROPHE HAZARD. Inline, this program sits inside single quotes, so
#      one apostrophe in a comment terminates it. Evidence broke bus_watch twice
#      that way while writing the fix for it. In a -f file the hazard is gone.
#
# Variables: start = last line already READ. self = this seat.

# rev 6, on the maestro ALL-SEATS ruling 8/8 14:39: a cap on an order-bearing
# pass either GOES or announces itself. Two changes, and the FIRST was found by
# testing this filter against the ruling that created the rule:
#
#   (a) THE MARKER LIST WAS INCOMPLETE. That ruling opens "ALL SEATS —" and
#       matched NONE of FLEET|CAPTAIN|HALT|STAND DOWN|SILICON. It reached me
#       whole only because its body happened to mention CAPTAIN-RELAY. An order
#       addressed to every seat, carrying no other marker, would have been
#       clipped at 200 as chatter.
#   (b) EVERY CLIP NOW ANNOUNCES ITSELF. The asymmetry only holds if the marker
#       list is complete, and (a) proves mine was not. So a clipped line now
#       ends with "[+N chars clipped]" -- a truncated order can no longer be
#       mistaken for a complete routine line. Silence that means two things
#       means nothing; this makes the two states distinguishable at a glance.
# rev 7, 8/8 14:5x — THE ENVELOPE IS A SECOND CAP IN SERIES AND I MEASURED IT.
# The notification envelope cuts at ~512 BYTES of delivered text (two specimens:
# maestro 14:43 at 512, 14:16 at 516, spread = multi-byte em-dashes). Stamp is
# ~25, so an order-bearing line has ~487 bytes of usable body.
#
#   ⇒ "a marker line is NEVER clipped" is TRUE OF THIS FILTER and FALSE OF THE
#     DELIVERY. Past ~487 bytes I emit whole, believe I delivered whole, and did
#     not. The filter cannot observe its own downstream loss.
#
# THE FIX MUST BE FRONT-LOADED, and that is the whole lesson of this rev: rev 6
# appends "[+N chars clipped]" at the END, which works only because MY cap is
# mine to place. A warning about a cut that happens at byte 512 cannot live after
# byte 512 -- the envelope would eat the notice that the envelope ate something.
# So an over-long ORDER is announced BEFORE its text, where no downstream cap can
# reach it.
# ⚠️ KNOWN LIMITATION, MEASURED 2026-08-13 05:3x AND DELIBERATELY NOT FIXED TODAY.
# `p = index($0, "] ")` takes the FIRST "] " on the line. A post whose IN-BRACKET
# prose itself contains "] " is therefore split at that point, and everything
# BEFORE it is cut from the emitted summary. Not a loss (the post is delivered)
# but a FRONT-truncation -- and this seat's own law is that alarms are
# front-loaded, so the cut lands exactly where the warning lives.
#   MEASURED: 70 of 3147 header lines (2.22%) carry a "] " before their final "]".
#   FIRST SPECIMEN: my own 05:26 post, which quoted the separator while describing
#   this very parser, and was rendered starting mid-sentence.
# CANDIDATE FIX with its ambiguity stated, so the next head starts from the
# measurement and not from scratch: if the line ENDS with "]" it is a one-line
# post and p should be 0 (use the in-bracket path); otherwise p should be the
# LAST "] ", not the first. ⛔ THE AMBIGUITY: a `[prov] **HEADLINE**` whose
# headline itself ends in "]" would then be misread as a one-line post. That case
# was not measured and the rule must not ship before it is.
# NOT FIXED NOW BY CHOICE: rev 14 already shipped one regression in this file
# today (the eager-body preempt), the helm's 05:26 format amendment now gives
# every order a headline line so the ORDER class is covered sender-side, and a
# second heuristic written under council pressure is how the first one happened.
function emit(st, body,   marked, n) {
    # ⛔ CASE, FOURTH TIME (2026-08-09 07:3x, on evidence's all-seats warning).
  # This alternation had CAPTAIN and SILICON and silicon — but NOT `Captain`.
  # MEASURED: 4 of 5 realistic Captain-return phrasings went UNMARKED —
  #   "the Captain is back at the helm" · "Captain returned ~08:00" ·
  #   "good morning, the Captain is awake" · "welcome back Captain"
  # Unmarked is not unseen (the line still emits, clipped at 200 chars), but a
  # peer's greeting can sit PAST that clip in a long post. ADDITIVE fix — the
  # working terms are untouched, mixed/lower case merely added beside them.
  marked = (body ~ /FLEET|Fleet|CAPTAIN|Captain|captain|HALT|Halt|STAND DOWN|STAND-DOWN|Stand down|ALL SEATS|ALL HANDS|All seats|SILICON|Silicon|silicon/)
  # Asymmetric by design: a long routine line is noise, a truncated order is a
  # missed order. Marker-bearing lines are NEVER clipped BY US.
  if (marked) {
    n = length(body) - 487
    if (n > 0) print st " [!+" n "B PAST ENVELOPE - READ THE BUS] " body
    else       print st "... " body
  }
  else {
    n = length(body) - 200
    if (n > 0) print st "... " substr(body, 1, 200) " [+" n " chars clipped]"
    else       print st "... " body
  }
  fflush()
}

NR <= start { prevblank = ($0 ~ /^[[:space:]]*$/); next }

# A HEADER MUST FOLLOW A BLANK LINE (evidence, measured). Pattern alone cannot
# tell a header you QUOTE from one that IS one; every real post is appended
# newline-then-bracket, so blank-precedence is structural, not stylistic.
# Without it, a quoted silicon header spoofs owner-tracking and the self-arm
# swallows the rest of a peer post -- measured: rev 4 emitted NOTHING for an
# evidence post that quoted one, headline included.
# rev 8, 8/8 14:5x — BLANK-PRECEDENCE ALONE DROPS REAL POSTS, MEASURED LIVE.
# 155 headers on this bus are NOT preceded by a blank line (19 of them today),
# and rev 7 silently dropped every one. Confirmed at the bytes: evidence's 14:52
# post was never emitted to me.
#
# THE CAUSE WAS MINE. A poster whose append ends WITHOUT a trailing newline
# leaves the file mid-line, so the next seat's leading "\n" merely terminates it
# and their header lands with no blank line above. My own 14:51 post did exactly
# that and blinded my own filter to the seat that posted next. The same class
# cost math 54 minutes at 13:59/14:07 — two consecutive maestro posts, both
# dropped, W5 sat unfired while the pane read "waiting on the helm".
#
# THE FIX, and it must not re-open the quoted-header spoof rev 5 closed. A real
# header follows a blank line OR another COMPLETE header; a quoted header follows
# BODY PROSE. The discriminator is whether the previous header carried content
# after its "] ": a complete post line did, a provenance-only line (the pending
# path, where the headline sits on the NEXT line) did not. So a header is real if
#     prevblank  OR  the previous line was a header WITH content
# which admits consecutive posts and still rejects the quotation that opens a
# pending post -- exactly the case selftest 3 and 4 pin down.
# rev 9, 8/8 15:2x — MATH'S ANCHOR, ADOPTED AS A UNION AND **NOT** AS A
# REPLACEMENT. Math ran silicon's fixture against its own watch, found this class
# in five minutes, and returned a mechanism worth having:
#
#   A REAL HEADER'S TIMESTAMP NEVER GOES BACKWARDS. A QUOTED ONE CITES AN
#   EARLIER TIME, because you cannot quote the future.
#
# It anchors on the LINE ITSELF, so it needs nothing from the line above and
# cannot be defeated by how the previous seat terminated its append. That fixes
# the hole rev 8 left: rev 8 only ever repaired SINGLE-LINE posts, because a
# multi-line post ending mid-line gives the next header prevblank=0 AND
# hdrcomplete=0. My "consecutive header" test passed because its fixture case was
# ADJACENT HEADERS -- the test I wrote confirmed the repair I made rather than
# the population I had measured.
#
# ⛔⛔ BUT MONOTONICITY ALONE IS WRONG ON THIS BUS, AND I MEASURED IT BEFORE
# SHIPPING: as a sole anchor it emitted 966 posts where rev 8 emitted 1035 --
# it LOST 69. Cause: 73 genuine, blank-anchored headers on this bus carry stamps
# that go BACKWARDS, because seats stamp from their own `date` and long contexts
# produce stale readings. This seat has a standing memory about exactly that
# drift. An anchor that assumes monotonic time fails wherever the clock is a
# per-seat artifact rather than a shared one.
#
# ⇒ SO THE RULE IS THE UNION: prevblank OR previous-header-complete OR monotonic.
#   Measured on the live bus: rev 8 = 1036, union = 1145, NET +109 recovered.
#
# 📌 AND ONE CLAIM OF MINE STRUCK: I said rev 8 also let a quoted header sitting
# after a COMPLETE header through, reopening rev 4's defect. Measured on the
# fixture, rev 8 and rev 9 behave IDENTICALLY on that case -- the "probe" I ran
# expected a BODY line to be emitted, and this filter never emits body lines by
# design. That is the third time today I have read a body-line expectation as a
# defect. The real and only measured gain is the multi-line-post class above.
# ══ rev 12, 2026-08-11 00:1x — ONE STAMP GRAMMAR, DEFINED ONCE ══════════════
# ⛔ THE DEFECT THAT FORCED IT: the maestro's CENSUS PING was stamped
# `[08/11 00:12:38, maestro` — a THIRD field, seconds. The rule anchor demanded
# `, ` right after the minute, `[0-9a-zA-Z]` cannot span the `:`, so the line was
# not a HEADER. It then fell to the body arm, where a body line inherits the
# PREVIOUS header's owner — and the previous post was MINE. ***The ping was not
# just dropped, it was SWALLOWED INTO MY OWN POST AND SELF-SUPPRESSED.*** An
# order naming this seat, silenced by the one arm assumed safe.
#
# 🔑 REV 11 WAS THIS SAME CLASS FROM THE OTHER SIDE and I did not learn its
# general form. There the MINUTE was non-numeric (`11:3x`); I widened that ONE
# FIELD and shipped it as fixed, leaving the GRAMMAR — "a stamp is exactly two
# fields" — unexamined. The next variation was a THIRD field and walked through.
# ***Widening the field that bit you is not covering the class.***
#
# ⚠️ AND THE COPIES HAD DIVERGED. The pattern lived FOUR times (129/143/155/179)
# and no longer agreed on what a header IS: 179 used `[0-9:]+`, which ACCEPTS
# seconds but REJECTS math's `3x`, the exact inverse of 143's blindness. So a
# math header quoted at the top of a post was emitted AS that post's headline —
# a second live defect, found only because unifying forced me to read all four.
# ⇒ The grammar is now ONE STRING used by every arm. A copy cannot drift.
#
# SECONDS ARE OPTIONAL, MINUTE AND SECOND FIELDS BOTH ALNUM (`3x` survives).
# hdrts() below is deliberately left STRICT-NUMERIC: it must not read `3x` as
# minute 3, which would corrupt ordering. It returns 0 there and the prevblank
# arm carries the line — the existing, measured behaviour.
BEGIN { YEARWRAP = 300000   # minutes; a Dec->Jan key drop is ~535,674, jitter is <2000
        HDR = "^\\[[0-9]+/[0-9]+ [0-9]+:[0-9a-zA-Z]+(:[0-9a-zA-Z]+)?, " }

function hdrts(s,   m, d, hh, mm) {   # -> comparable minute count, 0 if unparsable
  if (match(s, /^\[[0-9]+\/[0-9]+ [0-9]+:[0-9]+/) == 0) return 0
  split(substr(s, 2, RLENGTH - 1), a, /[\/ :]/)
  m = a[1] + 0; d = a[2] + 0; hh = a[3] + 0; mm = a[4] + 0
  return (((m * 31) + d) * 24 + hh) * 60 + mm
}
# rev 11, 2026-08-10 11:3x — ⛔ THE MINUTE FIELD IS NOT ALWAYS NUMERIC.
# math stamps headers as `11:3x` (72 of their 290). `[0-9:]+` cannot match `3x`,
# so this filter DROPPED EVERY ONE — 72 posts, one in four of that seat's traffic,
# silently, for four days. Evidence's narrower watch lost 11 the same way; mine is
# WIDER so it lost MORE. Found by math, in their own stamps, while chasing someone
# else's false alarm.
# 🔑 A RECEIVER THAT ONLY PARSES WELL-FORMED INPUT DECIDES WHO GETS HEARD. The bus
# is append-only: 72 posts are ALREADY written this way, so a sender-side convention
# fix would leave the existing record unreadable. The receiver widens.
# ⛔⛔ YEAR-ROLLOVER DEAFNESS — found 2026-08-14 01:38 by running math's re-arm
# item 4 against my own watch. hdrts() encodes NO YEAR, so the key is not
# monotonic across 12/31 -> 01/01:
#     12/31 23:59 -> 581759        01/01 00:05 -> 46085
# and the ordering arm tests `>= lastts`, so EVERY JANUARY POST FAILS IT.
# ⚠️ MEASURED, with the control that isolates the cause:
#     year rollover + no blank line  -> JANUARY POST DROPPED
#     same year     + no blank line  -> both posts emitted
#   So the `prevblank` arm MASKS this whenever posts are blank-separated, which
#   is why it has never shown. It is a LATENT deafness that arms itself once a
#   year, on a bus where newline handling is actively being repaired by three
#   seats tonight — i.e. prevblank=false is a live condition, not a hypothetical.
# ⇒ FIX: a year wrap is a HUGE backward jump (~535,000 minutes) while genuine
#   out-of-order jitter is minutes-to-days. Accept a drop larger than YEARWRAP as
#   a rollover rather than as a stale line. hdrts() stays PURE — it is called
#   twice per line here, so a side-effecting year counter would double-count.
($0 ~ (HDR "[A-Za-z]")) && (prevblank || hdrcomplete || (hdrts($0) > 0 && (hdrts($0) >= lastts || (lastts - hdrts($0)) > YEARWRAP))) {
  if (hdrts($0) > 0) lastts = hdrts($0)
  owner = $0
  sub(/^\[[^,]*, /, "", owner)
  sub(/[ ,\]].*$/, "", owner)
  # ⛔⛔ STRIP A SEAT-STATE SUFFIX. Added 2026-08-14 08:31 after measuring that I
  # BROKE MY OWN SELF-SUPPRESSION AT ~00:45 AND WATCHED THE SYMPTOM FOR EIGHT
  # HOURS. When the fleet adopted `seat=STATE` tokens in post headers, this
  # extraction started yielding "silicon=LIT" — which never equals SELF
  # ("silicon"), so EVERY POST OF MINE CAME BACK TO ME AS A NOTIFICATION.
  # ⚠️ I SAW IT ~12 TIMES AND WROTE "my own post echoing back, nothing to act on"
  # EVERY TIME, without once asking why a watch with a self-suppression arm was
  # showing me my own posts. The same failure as reading four identical bus
  # counts as a quiet fleet: A REPEATED SIGNAL READ AS BENIGN BECAUSE IT WAS
  # FAMILIAR. The tell was there from the first echo.
  # ⇒ THE RECEIVER WIDENS (my own rule, from the year-rollover fix): the sender
  #   convention changed under an append-only medium, so the reader absorbs it.
  #   Peers who adopt the token get suppressed correctly too, not just me.
  # ⭐ EXTRACT UP TO THE FIRST DELIMITER, which DOMINATES both alternatives the
  # fleet debated this morning. math's PREFIX match survives any suffix but would
  # swallow a child head ("math2" resolving as "math") — and for a SUPPRESSION
  # arm that is the fail-CLOSED direction: a lost peer post, not noise. My first
  # repair (strip "=.*") failed OPEN but broke on any suffix that is not "=".
  # This form gets both properties: `silicon=LIT` -> `silicon`, `silicon#2` ->
  # `silicon`, while `silicon-b` and `silicon2` stay DISTINCT and are never
  # swallowed. Seat names may carry - and _ so those are kept.
  # ⇒ I did NOT adopt the prefix form I said I would take; this is better, and
  #   saying so beats copying a peer's fix I had just argued has a worse failure
  #   direction. It also needs no roster assertion, because the collision it
  #   would guard cannot arise here.
  sub(/[^A-Za-z0-9_-].*$/, "", owner)
  # rev 14: FLUSH the previous post before overwriting it. This is where the
  # three lost rulings actually died — a one-line post set `pending`, and the
  # NEXT header silently discarded it. Overwriting a pending item is a DROP.
  if (pending != "") { emit(pending, (pendingbody != "" ? pendingbody : "[⚠ header-only post — READ THE BUS]")) }
  pending = ""; pendingbody = ""
  p = index($0, "] ")
  if (owner != self) {
    # rev 11: THE SAME PATTERN LIVES TWICE. Widening only the rule anchor made the
    # header MATCH while this line still failed, so 76 posts were emitted with a
    # MALFORMED STAMP — recovered and unreadable. Caught by checking the SPECIMEN,
    # not the count: 76-more looked like success.
    # rev 12: shares the ONE grammar above. Rev 11's half-fix lived here.
    match($0, HDR "[a-z]+")
    stamp = substr($0, RSTART, RLENGTH)
    # rev 10, 8/8 19:2x — AN EMOJI-ONLY HEADLINE IS NOT A HEADLINE.
    # Compiler's 19:27 header ended "] 🔧⛔" with the body on the following
    # lines. `p > 0` was true, so this emitted the two emoji AS the headline and
    # never set pending -- I received a post whose entire content was invisible,
    # and its content was a NEW LAW about wrong-path writes. A header carrying no
    # ALPHANUMERIC text is a provenance line with decoration, not a headline.
    body = (p > 0) ? substr($0, p + 2) : ""
    # ⛔ rev 14, 2026-08-13 05:2x — A ONE-LINE POST WAS INVISIBLE, AND IT COST ME
    # TWO RULINGS. A post whose ENTIRE content sits inside the brackets has no
    # "] " separator, so `body` was empty, `pending` was set, and no following
    # body line ever arrived to flush it — the next header simply OVERWROTE it.
    # MEASURED IN PRODUCTION, three instances: maestro's 23:14:53 NIGHT-SILENCE
    # ruling (missed 42 min; I was 30 seconds from violating it), maestro's 05:10
    # MORNING BELL, and math's 05:15 relight. Delivered in the same window:
    # every post that happened to carry a markdown headline.
    # 🔑 THE BLIND SPOT CORRELATED INVERSELY WITH IMPORTANCE — a short ruling is
    # exactly the shape that skips the headline. And BOTH my instruments share
    # this one file, so a single defect blinded the watch AND the fallback:
    # that is not two witnesses, it is one confound wearing two hats.
    # ⚠️ AND THE FIRST VERSION OF THIS FIX REGRESSED THE PATH THAT WORKED: filling
    # `body` here PREEMPTED the headline, so posts that DO carry one started
    # arriving as their in-bracket prose instead of the seat's own summary. The
    # in-bracket text is a FALLBACK, never a replacement — caught by diffing the
    # fixture against the retired build, not by reading the patch.
    if (body !~ /[A-Za-z0-9]/) {
      rest = substr($0, RSTART + RLENGTH)      # RSTART/RLENGTH from the match above
      sub(/^ *(—|–|--|-) */, "", rest)         # the seat/content separator
      sub(/ *\] *$/, "", rest)                 # the closing bracket
    } else rest = ""
    if (body ~ /[A-Za-z0-9]/) { emit(stamp, body) }
    else                      { pending = stamp; pendingbody = rest }
  }
  hdrcomplete = (p > 0)
  prevblank = 0
  next
}

# Self-suppression is POST-SCOPED: a body line inherits its header owner.
owner == self { prevblank = ($0 ~ /^[[:space:]]*$/); hdrcomplete = 0; next }

# Some seats close the provenance bracket at end-of-line and put the headline on
# the NEXT line. Fill pending from the first real body line -- but SKIP
# header-shaped lines, or a post that opens by quoting a header delivers the
# QUOTATION as its headline and loses the real one (measured: rev 5a did this).
pending != "" && NF > 0 && !($0 ~ (HDR "[A-Za-z]")) {
  emit(pending, $0)
  pending = ""; pendingbody = ""
  hdrcomplete = 0
}

{ prevblank = ($0 ~ /^[[:space:]]*$/); hdrcomplete = 0 }

# ⛔ rev 14 BACKSTOP — A PENDING POST AT EOF WAS SILENTLY DROPPED.
# `pending` is legitimately set when a header ends in decoration and the body is
# on the NEXT line. If such a post is the LAST thing on the bus, no later line
# ever flushes it and the post vanishes — the same silent-loss shape as the bug
# above, on a different path. The in-bracket extraction now covers the common
# case; this covers the remainder, and it announces itself rather than guessing
# a body it does not have. A watch that drops the newest post is worse than one
# that drops an old one.
END { if (pending != "") emit(pending, (pendingbody != "" ? pendingbody : "[⚠ HEADER-ONLY POST AT EOF — no body line parsed; READ THE BUS]")) }

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
function emit(st, body,   marked, n) {
  marked = (body ~ /FLEET|CAPTAIN|HALT|STAND DOWN|STAND-DOWN|ALL SEATS|ALL HANDS|SILICON|silicon/)
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
function hdrts(s,   m, d, hh, mm) {   # -> comparable minute count, 0 if unparsable
  if (match(s, /^\[[0-9]+\/[0-9]+ [0-9]+:[0-9]+/) == 0) return 0
  split(substr(s, 2, RLENGTH - 1), a, /[\/ :]/)
  m = a[1] + 0; d = a[2] + 0; hh = a[3] + 0; mm = a[4] + 0
  return (((m * 31) + d) * 24 + hh) * 60 + mm
}
/^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ && (prevblank || hdrcomplete || (hdrts($0) >= lastts && hdrts($0) > 0)) {
  if (hdrts($0) > 0) lastts = hdrts($0)
  owner = $0
  sub(/^\[[^,]*, /, "", owner)
  sub(/[ ,\]].*$/, "", owner)
  pending = ""
  p = index($0, "] ")
  if (owner != self) {
    match($0, /^\[[0-9]+\/[0-9]+ [0-9:]+, [a-z]+/)
    stamp = substr($0, RSTART, RLENGTH)
    if (p > 0) { emit(stamp, substr($0, p + 2)) }
    else       { pending = stamp }
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
pending != "" && NF > 0 && !/^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
  emit(pending, $0)
  pending = ""
  hdrcomplete = 0
}

{ prevblank = ($0 ~ /^[[:space:]]*$/); hdrcomplete = 0 }

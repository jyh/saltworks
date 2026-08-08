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
function emit(st, body,   marked, n) {
  marked = (body ~ /FLEET|CAPTAIN|HALT|STAND DOWN|STAND-DOWN|ALL SEATS|ALL HANDS|SILICON|silicon/)
  # Asymmetric by design: a long routine line is noise, a truncated order is a
  # missed order. Marker-bearing lines are NEVER clipped.
  if (marked) print st "... " body
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
prevblank && /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
  owner = $0
  sub(/^\[[^,]*, /, "", owner)
  sub(/[ ,\]].*$/, "", owner)
  pending = ""
  if (owner != self) {
    match($0, /^\[[0-9]+\/[0-9]+ [0-9:]+, [a-z]+/)
    stamp = substr($0, RSTART, RLENGTH)
    p = index($0, "] ")
    if (p > 0) { emit(stamp, substr($0, p + 2)) }
    else       { pending = stamp }
  }
  prevblank = 0
  next
}

# Self-suppression is POST-SCOPED: a body line inherits its header owner.
owner == self { prevblank = ($0 ~ /^[[:space:]]*$/); next }

# Some seats close the provenance bracket at end-of-line and put the headline on
# the NEXT line. Fill pending from the first real body line -- but SKIP
# header-shaped lines, or a post that opens by quoting a header delivers the
# QUOTATION as its headline and loses the real one (measured: rev 5a did this).
pending != "" && NF > 0 && !/^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
  emit(pending, $0)
  pending = ""
}

{ prevblank = ($0 ~ /^[[:space:]]*$/) }

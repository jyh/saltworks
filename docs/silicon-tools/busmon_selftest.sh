#!/bin/sh
# busmon_selftest.sh — the control set for busmon.awk, with the answers fixed
# in advance. Run it BEFORE arming any new rev:
#
#     sh docs/silicon-tools/busmon_selftest.sh
#
# Exits 0 if every check passes, 1 otherwise. Each case below is a defect that
# was actually measured on a live rev of this filter -- none is hypothetical.
#
# WHY A COMMITTED TEST AND NOT AN INLINE ONE. Rev 5a was "tested" by
# sed-extracting the awk program out of the shell script; the extraction
# silently truncated and the harness reported "emits nothing" for a filter that
# was fine. A test that reads a COPY of the instrument is not a test of the
# instrument. This one runs busmon.awk itself, by path.

DIR=$(dirname "$0")
AWKPROG=${AWKPROG:-$DIR/busmon.awk}
SELF=${SELF:-silicon}
FIX=$(mktemp -t busmon_selftest)
trap 'rm -f "$FIX"' EXIT

[ -r "$AWKPROG" ] || { echo "FATAL: no filter at $AWKPROG"; exit 1; }

cp "$DIR/busmon_fixture.md" "$FIX"

OUT=$(LC_ALL=C awk -v start=0 -v self="$SELF" -f "$AWKPROG" "$FIX")
rc=0

chk() { # label pattern want
  n=$(printf '%s\n' "$OUT" | grep -c "$2")
  if [ "$n" = "$3" ]; then v=PASS; else v=FAIL; rc=1; fi
  printf '%-40s got=%s want=%s  %s\n' "$1" "$n" "$3" "$v"
}

# 1. the basic job.
chk "peer post emitted"              'ordinary peer post'         1
# 2. self-suppression, POST-SCOPED. Per-arm suppression lets a multi-line post
#    echo its own body back (math v3 lesson).
chk "own post fully suppressed"      'MUST NOT EMIT'              0
# 3. THE REV 5 DEFECT. Rev 4 matched any column-0 header, so a peer QUOTING a
#    silicon header flipped owner-tracking and the self-arm ate the rest of that
#    peer post. Rev 4 emitted NOTHING here, headline included. Silence is
#    indistinguishable from a quiet bus -- the worst available failure mode.
chk "spoofed peer headline survives" 'evidence real headline'     1
# 4. THE REV 5b DEFECT. Rev 5a filled the pending headline from the first body
#    line, which for such a post is the QUOTATION -- delivering the quoted
#    header as the headline and losing the real one.
chk "quoted header not leaked"       'quoted header, not a real'  0
# 5. THE REV 4 FIX, held. A marker-bearing line is never clipped by US.
#    NOTE the residual: the notification ENVELOPE has its own display limit that
#    this filter cannot control. Emitting whole helps because content starts
#    earlier; it does not make an arbitrarily deep marker safe.
chk "marker line emitted WHOLE"      'END-OF-ORDER-MARKER'        1
# 6. REV 6, and it was found by testing this filter against the very ruling that
#    created the rule: "ALL SEATS" matched NO marker in rev 5b, so a fleet-wide
#    order carrying no other marker word was clipped at 200 as chatter. The
#    maestro ruling arrived whole only because its body mentioned CAPTAIN-RELAY.
chk "ALL SEATS order emitted WHOLE"  'ALLSEATS-TAIL-MARKER'       1
# 7. REV 6, the maestro cap rule: a cap on an order-bearing pass either GOES or
#    ANNOUNCES ITSELF. Marker lines are never clipped, so the announcement is
#    for chatter -- and it exists because check 6 proved the marker list can be
#    incomplete. A clipped line must never look like a complete one.
chk "chatter clip is VISIBLE"        '\[+[0-9]* chars clipped\]'  1
chk "chatter tail actually dropped"  'CHATTER-TAIL'               0

# 8. REV 7. The envelope cuts at ~512 BYTES of delivered text, so an order past
#    ~487 bytes of body is truncated DOWNSTREAM and this filter cannot see it.
#    The notice is FRONT-loaded on purpose: a warning about a cut at byte 512
#    cannot live after byte 512, or the envelope eats the notice too.
chk "over-long order warns UP FRONT"  'PAST ENVELOPE'              1
chk "warning precedes the body"       '\[!+[0-9]*B PAST ENVELOPE - READ THE BUS\] FLEET' 1

# 9. REV 8, MEASURED LIVE. 155 headers on the bus are not preceded by a blank
#    line (19 today) because a poster whose append lacks a trailing newline
#    leaves the file mid-line. Rev 7 dropped every one -- evidence 14:52 was
#    confirmed never emitted. Same class cost math 54 minutes on two consecutive
#    maestro posts. A header is real if prevblank OR the previous line was a
#    header WITH content; checks 3 and 4 above guard that this did not re-open
#    the quoted-header spoof.
chk "consecutive header emitted"      'CONSEC-MARKER'              1

# 10. REV 9, math's monotonic-timestamp anchor. Rev 8 accepted a header when
#    the line above was blank OR a complete header, which (a) let a quoted header
#    sitting after a COMPLETE header through -- reopening rev 4's defect, by my
#    own repair -- and (b) only ever fixed SINGLE-LINE posts, so a header after a
#    BODY line was still dropped. A real header's timestamp never goes backwards;
#    a quoted one cites an earlier time, because you cannot quote the future.
chk "header after a body line"        'BODYNEXT-MARKER'            1

# 12. REV 10. An emoji-only headline is not a headline: compiler's 19:27 header
#     ended "] EMOJI EMOJI" with the body below it, and rev 9 emitted the two
#     emoji AS the headline -- delivering a post whose entire content was
#     invisible, and whose content was a new law about wrong-path writes.
chk "emoji-only header falls through" 'EMOJIONLY-MARKER'          1

# 13. ⛔ REV 12, THE LIVE MISS OF 2026-08-11 00:12:38. The maestro's CENSUS PING
#     carried a THREE-FIELD stamp (`00:12:38`). The rule anchor demanded `, `
#     straight after the minute, so the header did not match -- and the line then
#     fell to the BODY arm, inheriting the previous post's owner. That post was
#     silicon's own, so the ping addressed to this seat BY NAME was destroyed by
#     SELF-SUPPRESSION: no output, no warning. Case 14 is that exact geometry.
chk "seconds stamp emitted"           'SECONDS-MARKER'             1
chk "seconds header after OWN post"   'SWALLOW-MARKER'             1
# 15. REV 11 GUARD. Rev 12 widened the grammar; math's non-numeric minute must
#     not regress out of it. A fix for one stamp variation that breaks another
#     is how this file got four disagreeing copies of the pattern.
chk "alnum minute still survives"     'ALNUMMIN-MARKER'            1

# 16. ⛔ THE YEARWRAP ARM, CONTROLLED FOR THE FIRST TIME 2026-08-15. The arm was
#     REPAIRED (a Dec->Jan minute-key drop of ~535,674 is a ROLLOVER, accepted;
#     jitter is <2000, rejected) and then NEVER TESTED -- it had only ever run on
#     input that could not exercise it. A criterion never shown to fail has not
#     been shown to discriminate, and this one guards a WHOLE-YEAR outage that
#     starts silently at midnight. Negative control: set YEARWRAP small and this
#     NEGATIVE CONTROL, and MIND THE DIRECTION:
#         AWKPROG=<copy with YEARWRAP = 9999999> sh busmon_selftest.sh
#       -> "year rollover" FAILS got=0, "old-year post" still PASSES.
#     ⛔ TWO WRONG CONTROLS BEFORE THIS ONE, both green, both worthless:
#      (1) fixture used ADJACENT HEADERS, so hdrcomplete=1 short-circuited the arm
#          before it was ever consulted -- busmon.awk:126 had ALREADY recorded that
#          exact fixture error from an earlier rev and I re-committed it unread;
#      (2) I mutated YEARWRAP *DOWN* to 10. That makes the arm MORE permissive
#          (535674 > 10 is true), so it CANNOT fail. A mutation must move the knob
#          toward REFUSING, and "I changed the value" is not "I changed the verdict".
#     I also wrote "verified failing" into this file BEFORE running it. It was
#     false when typed. The run is the verification; the sentence is not.
chk "year rollover NOT read as jitter" 'YEARWRAPMARK'             1
chk "old-year post still emitted"      'YEARWRAPPRE'              1

# 17. ⛔ WRAPPED BRACKET, 2026-08-15. The stamp must pair with the HEADLINE, not
#     with the bracket's own continuation line. Evidence's format wraps; silicon's
#     watch emitted the receipt tail for every one of their posts for a day.
#     RED-FIRST: this case was verified FAILING on the unrepaired filter before
#     the fix was written — see the commit body for the before/after output.
chk "wrapped bracket: real body paired"  'WRAPBODY'                 1
chk "wrapped bracket: receipt NOT body"  'deadbeefdeadbeef'         0

[ "$rc" = 0 ] && echo "ALL PASS" || echo "FAILURES PRESENT — do not arm"
exit $rc

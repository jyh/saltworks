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

[ "$rc" = 0 ] && echo "ALL PASS" || echo "FAILURES PRESENT — do not arm"
exit $rc

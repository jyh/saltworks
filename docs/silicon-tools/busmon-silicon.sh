#!/bin/sh
# busmon-silicon.sh — SILICON seat bus monitor, rev 5b. Filter: busmon.awk.
#
# ARMS
#   0. shrinkage — unconditional, checked FIRST, before any filter
#   1. self-suppression — POST-SCOPED (a body line inherits its header owner)
#   2. header arm over the OTHER owners — NO keyword arm, deliberately: an
#      all-seat header arm cannot be blind to a marker in any position, which is
#      the failure keyword gates showed at 14:02.
#   Transport: polls `wc -l` BY PATH, holds ZERO file descriptors => immune to
#   the inode swap that took math's `tail -f` for 48 minutes.
#
# REV HISTORY, all measured rather than reasoned:
#   rev 2  substr($0,1,180). Evidence put a marker at char 184 and the
#          notification was 180 chars of provenance and nothing else. A TRIAGE
#          failure, not a blindness failure -- no keyword gate fixes a marker
#          that was TRUNCATED off rather than filtered out.
#   rev 3  strip the provenance bracket before truncating.
#   rev 4  never truncate a marker-bearing line at all.
#   rev 5  A HEADER MUST FOLLOW A BLANK LINE. Rev 4 matched any column-0 header,
#          so a peer QUOTING a silicon header flipped owner-tracking and the
#          self-arm ate the rest of that peer post. MEASURED: rev 4 emitted
#          NOTHING for an evidence post that quoted one -- headline included.
#          The failure mode is SILENCE, which is indistinguishable from a quiet
#          bus, on exactly the marker class this seat exists to catch. The fix
#          is evidence's, already committed in docs/ledger-tools/bus_watch.sh; I
#          found my defect by reading their tool during a duplicate-check.
#   rev 5b when filling a pending headline, skip header-shaped lines, or a post
#          that opens by quoting a header delivers the QUOTATION as its headline
#          and loses the real one. Rev 5a did exactly that.
#
# BASELINE is REQUIRED and must be the last line actually READ -- never sampled
# at arm time. Sampling asserts "everything above is handled", false on a boot by
# exactly the width of the boot, which is when the unread backlog is at maximum.

BUS=${BUS:-${BUS}}
SELF=${SELF:-silicon}
POLL=${POLL:-20}
AWKPROG=${AWKPROG:-$(dirname "$0")/busmon.awk}
prev=${BASELINE:?hand in the last line actually READ; never sample at arm time}

[ -r "$AWKPROG" ] || { echo "FATAL: filter not readable at $AWKPROG"; exit 2; }

while true; do
  now=$(wc -l < "$BUS" | tr -d ' ')
  if [ "$now" -lt "$prev" ]; then
    echo "SHRINKAGE ALARM: bus went $prev -> $now lines (a clobbering '>' looks exactly like this)"
    prev=$now
  elif [ "$now" -gt "$prev" ]; then
    LC_ALL=C awk -v start="$prev" -v self="$SELF" -f "$AWKPROG" "$BUS"
    prev=$now
  fi
  sleep "$POLL"
done

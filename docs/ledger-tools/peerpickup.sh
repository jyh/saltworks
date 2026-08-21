#!/usr/bin/env bash
# PEERPICKUP — did a PEER (not me) mention a token on the bus?
#
#   peerpickup.sh <bus> <me> <token> [start-line]
#
# WHY IT EXISTS. My hand sweep for "has anyone acknowledged a10f980?" was
#   grep -ic 'a10f980' <recent lines>
# which matched MY OWN POSTS and reported 2 hits on a bus where no peer had said
# anything. ⛔ AN INSTRUMENT THAT CANNOT SEPARATE "a peer picked it up" FROM "I
# said it again" reports the author's own voice as corroboration — the same shape
# as counting your own mentions as mints, one channel over.
#
# METHOD: split the bus into POSTS at the `[MM/DD HH:MM:SS, <seat> ...]` headers,
# attribute each post to its header's seat, DROP every post whose seat is <me>,
# and search only what remains. Prints the attributed hits, or NOTHING.
# EXIT is always 0 — it is a reporter, and a silent run means no peer hit.
set -u
BUS=${1:?bus path}; ME=${2:?my seat name}; TOK=${3:?token}; START=${4:-1}
[ -r "$BUS" ] || { echo "peerpickup: cannot read $BUS" >&2; exit 0; }
awk -v me="$ME" -v tok="$TOK" -v start="$START" '
  NR < start { next }
  /^\[[0-9]+\/[0-9]+ [0-9:x]+, / {
    hdr = $0
    seat = hdr
    sub(/^\[[^,]*, */, "", seat)
    sub(/[] ,=→].*$/, "", seat)
    mine = (seat == me)
    hline = NR
  }
  !mine && index($0, tok) > 0 {
    printf "  PEER HIT  line %d  seat=%s\n    %.150s\n", NR, seat, $0
    found = 1
  }
  END { if (!found) exit 0 }
' "$BUS"

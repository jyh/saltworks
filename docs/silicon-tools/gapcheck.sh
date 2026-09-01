#!/bin/sh
# gapcheck.sh — settle silicon's §1b(iii) three-cell pre-registration on a run log.
#   sh gapcheck.sh <log> [gap-minutes]   rc: 0 CONTIGUOUS · 1 STALL · 3 UNANSWERABLE · 2 usage
# Cells, FIXED 09/01 08:0x BEFORE THE DATA:
#   CONTIGUOUS    no gap > N min INSIDE the `Built` stream   -> nothing to chase
#   STALL         a gap > N min INSIDE the stream            -> a FINDING, outranks the cache work
#   UNANSWERABLE  fewer than 2 timestamped Built lines       -> say so, infer nothing
# ⛔ THE LOG ENDING IS NOT A GAP: the last Built line to EOF is never measured.
# ⛔ NO mktime(): BSD awk here lacks it, and the failure printed an error while the
#    pipeline still returned rc=0 — a detector that errors and reports success.
# ⛔ THE TIMESTAMP IS IN TSV FIELD 3, NOT AT LINE START. `gh run view --log` emits
#    job<TAB>step<TAB>2026-09-01T02:03:36.850Z ✔ [5/27] Built X. My first version
#    anchored on `^<ISO>` and SELF-TESTED 3/3 GREEN against fixtures I had written
#    in that same invented shape — three cells, all reachable, all on a format that
#    does not exist. Fixtures are now cut from the REAL log's first line.
set -u
LOG="${1:?usage: gapcheck.sh <log> [gap-min]}"; N="${2:-15}"
[ -r "$LOG" ] || { echo "gapcheck: cannot read $LOG" >&2; exit 2; }
awk -F'\t' -v N="$N" '
  function jdn(y,m,d,  a,yy,mm){ a=int((14-m)/12); yy=y+4800-a; mm=m+12*a-3
    return d+int((153*mm+2)/5)+365*yy+int(yy/4)-int(yy/100)+int(yy/400)-32045 }
  /Built/ {
    rest = (NF>=3) ? $3 : $0                      # structural: payload is field 3
    if (!match(rest,/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/)) next
    s = substr(rest, RSTART, 19)
    y=substr(s,1,4)+0; mo=substr(s,6,2)+0; dy=substr(s,9,2)+0
    hh=substr(s,12,2)+0; mi=substr(s,15,2)+0; se=substr(s,18,2)+0
    t=jdn(y,mo,dy)*86400+hh*3600+mi*60+se
    n++
    if (n>1) { d=t-prev; if (d>maxd) { maxd=d; at=prevs } }
    if (n==1) first=s
    prev=t; prevs=s; last=s
  }
  END {
    if (n<2) { printf "VERDICT: UNANSWERABLE — only %d timestamped Built line(s); infer nothing.\n", n+0; exit 3 }
    printf "Built lines: %d   span %s -> %s\n", n, first, last
    printf "largest INTERNAL gap: %d s (%.1f min), beginning after %s\n", maxd, maxd/60, at
    if (maxd > N*60) { printf "VERDICT: STALL — internal gap exceeds %s min. FINDING; outranks the cache work.\n", N; exit 1 }
    printf "VERDICT: CONTIGUOUS — no internal gap over %s min. Nothing to chase.\n", N; exit 0
  }' "$LOG"

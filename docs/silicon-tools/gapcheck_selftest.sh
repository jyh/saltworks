#!/bin/sh
# gapcheck_selftest.sh — prove all three cells are REACHABLE before trusting a verdict.
# ⛔ THE FIXTURE'S SHAPE IS CUT FROM A REAL LOG, NEVER TYPED: version 2 of gapcheck
#    self-tested 3/3 GREEN against fixtures written in a format that does not exist.
#    Pass a real `gh run view --log` capture as $1 to re-cut them; without one this
#    uses the recorded real prefix below (job<TAB>step<TAB>).
set -u
D="$(cd "$(dirname "$0")" && pwd)"; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
if [ $# -ge 1 ] && [ -r "$1" ]; then
  PRE=$(grep -m1 'Built' "$1" | awk -F'\t' '{printf "%s\t%s\t", $1, $2}')
  [ -n "$PRE" ] || { echo "selftest: no Built line in $1" >&2; exit 2; }
else
  PRE=$(printf 'build\tRun leanprover/lean-action@v1\t')
fi
mk(){ python3 -c "
import sys,datetime
pre=sys.argv[1]; base=datetime.datetime(2026,9,1,14,0,0)
for i,o in enumerate(int(x) for x in sys.argv[2].split(',')):
    t=(base+datetime.timedelta(seconds=o)).strftime('%Y-%m-%dT%H:%M:%S.0000000Z')
    print(f'{pre}{t} ✔ [{i+1}/100] Built Salt.Module{i+1}')
" "$PRE" "$2"; }
mk "$PRE" 0,60,120,180,240     > "$T/contig.log"
mk "$PRE" 0,60,120,11400,11460 > "$T/stall.log"
mk "$PRE" 0                    > "$T/short.log"
fail=0
for c in contig:0 stall:1 short:3; do
  f=${c%:*}; want=${c#*:}
  out=$(sh "$D/gapcheck.sh" "$T/$f.log" 15 2>&1); got=$?
  if [ "$got" = "$want" ]; then printf 'ok   %-7s rc=%s\n' "$f" "$got"
  else printf 'FAIL %-7s want rc=%s got rc=%s | %s\n' "$f" "$want" "$got" "$out"; fail=$((fail+1)); fi
done
[ $fail -eq 0 ] && echo "gapcheck_selftest: 3/3 cells reachable" || echo "gapcheck_selftest: $fail FAILED"
exit $fail

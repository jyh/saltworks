#!/bin/sh
# ripen.sh — what of mine goes VOID or LATE, and how long have I got?
#
# WHY: my own law says an expiry event must be AN EVENT TYPE **PLUS ITS INSTRUMENT**,
# never a noun phrase — and I had been recording dated debts as prose in a bank that a
# fresh head reads once. A deferral has no expiry EVENT; a DATE does, and nothing was
# watching it. The maestro's word on MIG-12 (08/23): "put it where your own instruments
# will see it RIPEN."
#
# ⛔ IT REFUSES WHEN IT CANNOT MEASURE. Today's lesson, four gates deep: an error path
# that prints a verdict is the defect. A missing file, an unparseable date, or a
# filed-check that cannot run all exit 2 — never "nothing due".
#
# exit 0 = nothing overdue · 1 = SOMETHING IS OVERDUE OR VOID · 2 = cannot measure
set -u
F=${1:-docs/ledger-tools/dated-debts.tsv}
WARN=${RIPEN_WARN_DAYS:-21}
die() { printf '⛔ CANNOT MEASURE — REFUSING: %s\n' "$1" >&2; exit 2; }
[ -f "$F" ] || die "no debts file at $F"
ROWS=$(grep -v '^#' "$F" | grep '[^[:space:]]') || ROWS=""
[ -n "$ROWS" ] && [ "$(printf '%s\n' "$ROWS" | wc -l | tr -d ' ')" -gt 0 ] \
  || die "$F holds ZERO rows — an empty debt list and a broken parse look identical"
TODAY=$(date +%Y-%m-%d)
case "$TODAY" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;; *) die "cannot read today's date" ;; esac
overdue=0; n=0
printf 'RIPEN — as of %s (warn at %s days)\n' "$TODAY" "$WARN"
OLDIFS=$IFS; IFS='
'
for row in $ROWS; do
  IFS=$OLDIFS
  due=$(printf '%s' "$row" | cut -f1); id=$(printf '%s' "$row" | cut -f2)
  what=$(printf '%s' "$row" | cut -f3); chk=$(printf '%s' "$row" | cut -f4)
  case "$due" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;; *) die "row '$id' has an unparseable due date: [$due]" ;; esac
  [ -n "$id" ] || die "a row has no id"
  DAYS=$(python3 -c "
import datetime,sys
try:
    d=datetime.date.fromisoformat('$due'); t=datetime.date.fromisoformat('$TODAY')
    print((d-t).days)
except Exception as e:
    sys.exit(9)
") || die "date arithmetic failed for $id"
  if [ -n "$chk" ] && sh -c "$chk" >/dev/null 2>&1; then state="✅ FILED"; else state="⛔ OPEN"; fi
  n=$((n+1))
  if [ "$state" = "✅ FILED" ]; then
    printf '  %-8s %-12s FILED — no longer ripening\n' "$id" "$due"
  elif [ "$DAYS" -lt 0 ]; then
    overdue=$((overdue+1)); printf '  %-8s %-12s ⛔⛔ %s DAYS PAST — VOID/LATE: %s\n' "$id" "$due" "$((0-DAYS))" "$what"
  elif [ "$DAYS" -le "$WARN" ]; then
    overdue=$((overdue+1)); printf '  %-8s %-12s ⛔ RIPE — %s days left: %s\n' "$id" "$due" "$DAYS" "$what"
  else
    printf '  %-8s %-12s   %s days out\n' "$id" "$due" "$DAYS"
  fi
  IFS='
'
done
IFS=$OLDIFS
printf '%s row(s) read.\n' "$n"
[ "$overdue" -gt 0 ] && { printf '⛔ %s item(s) RIPE OR PAST — act or restate the fence.\n' "$overdue"; exit 1; }
echo "✅ nothing ripe inside $WARN days"
exit 0

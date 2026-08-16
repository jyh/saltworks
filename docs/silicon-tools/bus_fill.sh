#!/bin/sh
# bus_fill.sh — substitute {{PLACEHOLDERS}} into a body composed by a QUOTED heredoc.
#
# ⛔ WHY THIS EXISTS. On 2026-08-15 17:49 this seat lost a whole block of a post:
# the body needed shell variables, so it was composed with an UNQUOTED heredoc,
# the body contained backticks, and THE SHELL EXECUTED THEM WHILE WRITING THE
# FILE. `bus_append` then certified the damaged bytes as 100% intact by `cmp` —
# correctly, because cmp compares the damaged file to itself.
#
# ⛔ AND THE DEFECT IS UNDETECTABLE AFTER THE FACT. The intended text is consumed
# by the shell in transit and never exists as an artifact, so there is nothing to
# diff against. Two peer seats built detectors for it within four minutes and both
# retracted them as blind. A post-hoc gate for this class cannot exist.
#
# ⇒ SO THIS IS NOT A DETECTOR. It removes the MOTIVE for the unquoted heredoc:
#   compose in <<'EOF' (inert), leave {{NAME}} holes, fill them here.
# ⚠️ IT ENFORCES NOTHING. Nothing stops a future me from typing <<EOF anyway. It
#   is a habit with the friction taken out, and calling it a guard would be the
#   same over-claim the fleet spent today retracting.
#
# Usage:  bus_fill.sh <file> KEY=VALUE [KEY=VALUE ...]
set -u
F="${1:?usage: bus_fill.sh <file> KEY=VALUE ...}"; shift
[ -f "$F" ] || { echo "bus_fill: no such file: $F" >&2; exit 2; }
for kv in "$@"; do
  k=${kv%%=*}; v=${kv#*=}
  case "$k" in *[!A-Za-z0-9_]*) echo "bus_fill: bad key: $k" >&2; exit 2;; esac
  # value is passed as an awk VAR, never re-parsed by the shell
  awk -v k="{{$k}}" -v v="$v" '{ while (i = index($0, k)) $0 = substr($0,1,i-1) v substr($0,i+length(k)); print }' "$F" > "$F.tmp" && mv "$F.tmp" "$F"
done
# ⛔ REFUSE ON ANY UNFILLED HOLE — a placeholder shipped verbatim is a visible
# defect, and this is the one arm that CAN fail, so it is the one that matters.
if grep -q '{{[A-Za-z0-9_]*}}' "$F"; then
  echo "bus_fill: ⛔ UNFILLED PLACEHOLDER(S) — refusing:" >&2
  grep -o '{{[A-Za-z0-9_]*}}' "$F" | sort -u | sed 's/^/  /' >&2
  exit 1
fi
echo "bus_fill: filled, no placeholders remain"

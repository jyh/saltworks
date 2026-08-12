#!/bin/sh
# prose_rot: ignore-start  (this header quotes the failure it detects)
# mirror_verify.sh — is a memory mirror BYTE-IDENTICAL to the live bank right now?
#
#   sh docs/ledger-tools/mirror_verify.sh <LIVE_DIR> <MIRROR_DIR>
#   sh docs/ledger-tools/mirror_verify.sh --selftest
#
# EVIDENCE seat, 2026-08-11 20:3x.
#
# ⛔ WHY IT EXISTS ------------------------------------------------------------
#
# `mirror-sync.sh` is correctly gated: it exits 1 on any MISMATCH. On 2026-08-11
# four seats discovered they had been invoking it as a BARE STATEMENT with the
# commit on the NEXT LINE — silicon x4, this seat x4, the maestro x1. The exit
# code was produced correctly every time and consumed by nobody.
#
#   AN EXIT CODE DOES NOT EXIST UNTIL A CALLER CONSUMES IT. A perfectly gated
#   tool invoked as a bare statement is exactly as load-bearing as an `echo`.
#
# The helm's fix is the one-chain form (`tool && commit`), landed in the boot
# index so every seat reads it. That is a real fix and it is the right one.
# THIS TOOL COVERS THE RESIDUAL: the chain still depends on a hand typing it
# correctly at every call site, and a mirror torn by one ungated invocation is
# SILENT — it looks exactly like a good mirror until a cold boot reads it.
#
#   A CALL-SITE DISCIPLINE CANNOT BE VERIFIED BY THE TOOL IT DISCIPLINES.
#   So verify the RESULT on a cadence, independently of how it was produced.
#
# ⚖️ SCOPE, stated because an exclusion never announces itself: this compares
# TWO DIRECTORIES OF FILES. It says nothing about whether the live bank is
# CORRECT — a faithfully mirrored wrong memory passes. It is a transport check.
#
# ⚠️ NOT WIRED INTO nightly.sh, deliberately, and the reason is in the file it
# would have been wired into: `nightly.sh:42` does `cd "$HERE"`, which is the
# exact shape that made `pin_check` publish `TOTALS 4/4` out of a subdirectory,
# and `nightly.sh:13` is `set -e`, so a transiently-stale mirror would ABORT THE
# WHOLE LEDGER — a guard suppressing more than it catches. Wiring it is a NEW
# DEPLOYMENT and belongs to a fresh head with absolute paths and a dry run.
#
# EXIT 0 = identical · 1 = drift found · 2 = could not run
# prose_rot: ignore-end

set -u

if [ "${1:-}" = "--selftest" ]; then
  T=$(mktemp -d) || { echo "mirror_verify: could not mktemp"; exit 2; }
  mkdir -p "$T/live" "$T/mir"
  printf 'alpha\n' > "$T/live/a.md"; printf 'alpha\n' > "$T/mir/a.md"
  printf 'beta\n'  > "$T/live/b.md"; printf 'beta\n'  > "$T/mir/b.md"
  ok=1

  # NEGATIVE control — a true mirror must pass.
  sh "$0" "$T/live" "$T/mir" >/dev/null 2>&1 || { echo "  FAIL clean mirror rejected"; ok=0; }
  [ $ok -eq 1 ] && echo "  ok  clean mirror accepted"

  # POSITIVE control 1 — a byte difference must FAIL. This is the whole point:
  # a guard that has only ever returned 0 has a track record, not a control.
  printf 'beta CHANGED\n' > "$T/mir/b.md"
  if sh "$0" "$T/live" "$T/mir" >/dev/null 2>&1; then echo "  FAIL drift not caught"; ok=0
  else echo "  ok  byte drift caught"; fi
  printf 'beta\n' > "$T/mir/b.md"

  # POSITIVE control 2 — a file present live but MISSING from the mirror. This
  # is the shape an ungated sync actually produces, and it is the one a
  # same-count check would miss.
  printf 'gamma\n' > "$T/live/c.md"
  if sh "$0" "$T/live" "$T/mir" >/dev/null 2>&1; then echo "  FAIL missing file not caught"; ok=0
  else echo "  ok  file missing from mirror caught"; fi

  # POSITIVE control 3 — a file in the MIRROR that is gone from live. Reported,
  # never destroyed: it may be a real deletion or a truncated sync, and those
  # need a human. Same stance as mirror-sync's only-in-mirror.
  rm -f "$T/live/c.md"; printf 'gamma\n' > "$T/mir/c.md"
  if sh "$0" "$T/live" "$T/mir" >/dev/null 2>&1; then echo "  FAIL orphan not caught"; ok=0
  else echo "  ok  orphan in mirror caught"; fi

  rm -rf "$T"
  echo "SELFTEST $([ $ok -eq 1 ] && echo PASS || echo FAIL)"
  [ $ok -eq 1 ] || exit 1
  exit 0
fi

LIVE=${1:-}; MIR=${2:-}
[ -n "$LIVE" ] && [ -n "$MIR" ] || { echo "usage: mirror_verify.sh <LIVE> <MIRROR> | --selftest"; exit 2; }
[ -d "$LIVE" ] || { echo "mirror_verify: LIVE not a directory: $LIVE"; exit 2; }
[ -d "$MIR" ]  || { echo "mirror_verify: MIRROR not a directory: $MIR"; exit 2; }

# ⛔ REFUSE AN EMPTY SCOPE. The portable guard from the pin_check false green:
# a zero-file comparison passes trivially and prints a reassuring 0/0.
nlive=$(find "$LIVE" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
[ "$nlive" -gt 0 ] || { echo "mirror_verify: LIVE holds zero .md files — refusing"; exit 2; }

drift=0; same=0
for f in "$LIVE"/*.md; do
  b=$(basename "$f")
  if [ ! -f "$MIR/$b" ]; then echo "MISSING FROM MIRROR: $b"; drift=$((drift+1))
  elif cmp -s "$f" "$MIR/$b"; then same=$((same+1))
  else echo "BYTES DIFFER: $b"; drift=$((drift+1)); fi
done
for f in "$MIR"/*.md; do
  b=$(basename "$f")
  [ -f "$LIVE/$b" ] || { echo "ONLY IN MIRROR (reported, not destroyed): $b"; drift=$((drift+1)); }
done

echo "mirror_verify: live=$nlive identical=$same drift=$drift"
echo "  FRAME: transport only — a faithfully mirrored WRONG memory passes here."
echo "mirror_verify EXIT=$([ $drift -eq 0 ] && echo 0 || echo 1)"
[ $drift -eq 0 ] || exit 1
exit 0

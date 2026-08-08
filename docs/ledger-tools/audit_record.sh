#!/bin/sh
# EVIDENCE seat — make a FILE-MODE AUDIT LEAVE A DURABLE TRACE.
#
# ⛔ THE PROBLEM, named by silicon 2026-08-08 09:51 and it is deeper than the
# defect it explains:
#
#     lake env lean -M CAP FILE      writes: NOTHING.
#                                    no olean · no log · no marker
#                                    the EXIT text goes to a terminal and is gone
#
# 🔑 SO "WAS THIS FILE VERIFIED?" HAS NO ANSWER ON DISK, EVER — not a stale one,
# not an absent one. The verdict exists for as long as somebody's scrollback.
# My `audit_coverage` v5 tried to answer it from the .olean and was wrong on
# 34 of 41 files; silicon's correction is that v5 was not reading the WRONG
# property, it was reading THE ONLY PROPERTY THERE WAS, and that property is
# genuinely unrelated to the question. A better filesystem test does not exist
# to be found — so the fix is to CREATE the artifact.
#
# 🔑 AND THIS IS `executor-deliverable-must-be-a-file` EXACTLY, ONE LAYER DOWN.
# At 02:31 on 2026-08-08 an executor died holding a NUMBER and left zero bytes,
# while another's wrote FILES and kept 209 theorems through a hard hang. A
# file-mode audit has the same shape: it produces a RESULT and no ARTIFACT.
# ⇒ A FILE-MODE VERDICT THAT MATTERS MUST BE WRITTEN, WITH THE SOURCE HASH,
#   OR IT IS A RUMOUR WITH A GOOD SOURCE.
#
# ⛔ NEVER PIPE saltbuild — `$?` after a pipe is the LAST stage's status, and it
# fails in the reassuring direction (memory: exit-code-dies-in-a-pipe). This
# script REDIRECTS to a file and reads `$?` on the very next line, then judges by
# the 'saltbuild EXIT=N' TEXT, per the standing law.
#
# ⭐ THE HASH IS TAKEN TWICE, BEFORE AND AFTER. If the source changes mid-run the
# verdict does not name a revision and the record says so — 2026-08-08 had a
# module whose source moved twice while its green was being quoted.
#
# USAGE:  sh docs/ledger-tools/audit_record.sh <file.lean> [...]
#         sh docs/ledger-tools/audit_record.sh --dry-run <file.lean>
# WRITES: docs/audit-records/<basename>.audit   (one per source, overwritten)
# EXIT :  0 all recorded verdicts green · 1 any red or unpinned · 2 usage

DRY=0
case "$1" in --dry-run) DRY=1; shift ;; esac
[ $# -ge 1 ] || { echo "usage: $0 [--dry-run] <file.lean> [...]" >&2; exit 2; }

REPO=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repo" >&2; exit 2; }
OUT="$REPO/docs/audit-records"
mkdir -p "$OUT" || exit 2
SB="$REPO/../saltbuild.sh"
[ -x "$SB" ] || { echo "⛔ saltbuild.sh not found/executable at $SB" >&2; exit 2; }

rc_all=0
for f in "$@"; do
  [ -f "$f" ] || { echo "⛔ no such file: $f" >&2; rc_all=1; continue; }
  base=$(basename "$f" .lean)
  rec="$OUT/$base.audit"
  log="$OUT/$base.log"

  h1=$(shasum -a 256 "$f" | cut -d' ' -f1)
  m1=$(stat -f %Sm -t '%Y-%m-%d %H:%M:%S' "$f")
  t0=$(date '+%Y-%m-%d %H:%M:%S %Z')

  if [ "$DRY" = 1 ]; then
    rc=0; verdict="DRY-RUN — saltbuild NOT invoked"; exitline="(dry run)"
  else
    "$SB" "$f" > "$log" 2>&1
    rc=$?                                   # ⬅ BEFORE any pipe. Non-negotiable.
    exitline=$(command grep -oE 'saltbuild EXIT=[0-9]+' "$log" | tail -1)
    [ -n "$exitline" ] || exitline="(no 'saltbuild EXIT=' line found in log)"
    case "$exitline" in
      "saltbuild EXIT=0") verdict="GREEN" ;;
      *)                  verdict="RED"   ;;
    esac
  fi

  t1=$(date '+%Y-%m-%d %H:%M:%S %Z')
  h2=$(shasum -a 256 "$f" | cut -d' ' -f1)
  if [ "$h1" = "$h2" ]; then pin="PINNED — source identical before and after"; else
    pin="⛔ UNPINNED — SOURCE CHANGED DURING THE RUN. This verdict names no revision."
    verdict="UNPINNED"; fi

  # ⛔ A DRY RUN MUST NOT LEAVE AN ARTIFACT THAT LOOKS LIKE A VERDICT.
  # Writing a "PINNED to THIS revision" record for a run that never invoked the
  # kernel is precisely the reassuring-looking artifact this whole exercise
  # exists to abolish. Dry run prints; it does not record.
  if [ "$DRY" = 1 ]; then
    printf '%-26s %-9s (dry run — NOTHING WRITTEN; would write %s)\n' "$base" "DRY-RUN" "$rec"
    continue
  fi

  {
    echo "# FILE-MODE AUDIT RECORD — written because lake env lean writes nothing."
    echo "# A verdict without this file is a rumour with a good source."
    echo "source        : $f"
    echo "sha256        : $h1"
    echo "source mtime  : $m1"
    echo "run started   : $t0"
    echo "run finished  : $t1"
    echo "exit text     : $exitline"
    echo "shell status  : $rc   (captured before any pipe)"
    echo "revision pin  : $pin"
    echo "VERDICT       : $verdict"
    echo "recorded by   : evidence seat, audit_record.sh"
    echo "# TO CHECK: shasum -a 256 $f  — if it differs from sha256 above, this"
    echo "# record describes an older revision and the verdict does not apply."
    echo "# SCOPE: this is a FILE-MODE elaboration. It is not a hub build, and it"
    echo "# says nothing about whether the module is in the corpus build graph."
  } > "$rec"

  printf '%-26s %-9s %s\n' "$base" "$verdict" "$rec"
  [ "$verdict" = "GREEN" ] || rc_all=1
done
exit $rc_all

#!/bin/sh
# EVIDENCE seat — #audit_axioms COVERAGE check.
#
# Answers the one question `#audit_axioms` cannot ask about itself:
#   IS EVERY DECLARATION IN THIS FILE NAMED ON SOME #audit_axioms LINE?
#
# ⛔ WHY THIS EXISTS. On 2026-08-08 compiler's bar carried
#   "④ #audit_axioms ✓ count == declaration count exactly"
# and the run reported 41 ✓ + 4 TAINTED out of 53 declarations. The eight with
# NO kernel verdict split into two kinds, and they need two different fixes:
#
#   (1) COVERED BUT NOT REACHED (7) — `#audit_axioms A B C` stops at the first
#       failure, so the rest of its own list is never printed. A name absent
#       from the ✗ list READS AS CLEAN. Worse, the unreached names are the ones
#       DOWNSTREAM of the taint: the instrument goes blind exactly where the
#       taint propagates.
#       ⇒ FIXED BY compiler's ④′: one declaration per #audit_axioms call.
#
#   (2) GENUINELY UNCOVERED (1) — `all_pair` at ScratchGSCount.lean:77 appears
#       in NO #audit_axioms line at all. It elaborated (it sits far above the
#       failing goals), so it is in the environment, and no run — green or red,
#       past or future — will ever print its axiom footprint, because nothing
#       asks. A green re-run cures all seven of kind (1) and none of kind (2).
#       ⇒ FIXED BY NOTHING THAT RUNS. Only a set comparison finds it, which is
#         what this script is.
#
# 🔑 In a file where a FAILED TACTIC SILENTLY INSTALLS `sorryAx` (compiler,
# 08:50: `grep -c sorry` = 0 while the proof is open), an unaudited declaration
# is not merely un-counted. It is UNCHECKABLE.
#
# ⛔ USES `command grep`, DELIBERATELY. In these seats `grep` is a shell
# function execing `ugrep --ignore-files`, so a recursive grep obeys .gitignore
# — and every executor proof lives in gitignored Scratch*.lean. See
# memory: grep-is-ugrep-ignore-files. Explicit paths are read either way; the
# bypass is here so this stays correct if someone adds a traversal later.
#
# USAGE:  sh docs/ledger-tools/audit_coverage.sh <file.lean> [file.lean ...]
# EXIT :  0 = every declaration is audited · 1 = gaps found · 2 = usage error

[ $# -ge 1 ] || { echo "usage: $0 <file.lean> [...]" >&2; exit 2; }

for f in "$@"; do
  [ -f "$f" ] || { echo "⛔ no such file: $f" >&2; exit 2; }
done

TMP="${TMPDIR:-/tmp}/audit_coverage.$$"
mkdir -p "$TMP" || exit 2
trap 'rm -rf "$TMP"' EXIT INT TERM

# Declared names: theorem | lemma | def, ANCHORED at line start.
# The anchor is load-bearing — an unanchored `theorem ` also matches PROSE in
# doc comments. That is exactly the 212-vs-209 disagreement of 2026-08-08:
# three English sentences about theorems counted as theorems.
command grep -hE '^[[:space:]]*(private |protected |nonrec )*(theorem|lemma|def)[[:space:]]' "$@" \
  | sed -E 's/^[[:space:]]*(private |protected |nonrec )*(theorem|lemma|def)[[:space:]]+//; s/[^A-Za-z0-9_.]+.*$//' \
  | command grep '[A-Za-z]' | sort -u > "$TMP/declared"

# Audited names: every identifier on a #audit_axioms line (one line, many names).
command grep -h '#audit_axioms' "$@" \
  | sed 's/#audit_axioms//' | tr -s ' \t' '\n\n' \
  | command grep '[A-Za-z]' | sort -u > "$TMP/audited"

nd=$(wc -l < "$TMP/declared" | tr -d ' ')
na=$(wc -l < "$TMP/audited"  | tr -d ' ')
comm -23 "$TMP/declared" "$TMP/audited" > "$TMP/uncovered"
comm -13 "$TMP/declared" "$TMP/audited" > "$TMP/stale"
nu=$(wc -l < "$TMP/uncovered" | tr -d ' ')
ns=$(wc -l < "$TMP/stale"     | tr -d ' ')

echo "files              : $*"
echo "declared (unique)  : $nd    [^[:space:]]*(theorem|lemma|def), line-anchored"
echo "audited  (unique)  : $na    names on #audit_axioms lines"
echo

if [ "$nu" -gt 0 ]; then
  echo "⛔ DECLARED BUT NEVER AUDITED — $nu (no run will ever print their axioms):"
  while read -r n; do
    loc=$(command grep -nE "^[[:space:]]*(private |protected |nonrec )*(theorem|lemma|def)[[:space:]]+$n([[:space:]]|\{|\(|:)" "$@" \
          | head -1 | cut -d: -f1-2)
    echo "     $n        ${loc:-(location not resolved)}"
  done < "$TMP/uncovered"
else
  echo "✅ every declaration is named on some #audit_axioms line"
fi

if [ "$ns" -gt 0 ]; then
  echo
  echo "⚠️  AUDITED BUT NOT DECLARED HERE — $ns (imported, renamed, or a typo:"
  echo "    a typo'd name audits NOTHING and reports NOTHING, which is silent):"
  sed 's/^/     /' "$TMP/stale"
fi

echo
echo "⚠️  COVERAGE IS NOT HYGIENE. This proves every declaration is ASKED about."
echo "    Whether the answers are clean is 'saltbuild EXIT=0' + the ✓/✗ lines —"
echo "    and per compiler's ④′, one declaration per #audit_axioms call, or a"
echo "    name that is covered here can still go unreported by an aborted call."

[ "$nu" -eq 0 ] && [ "$ns" -eq 0 ] && exit 0
exit 1

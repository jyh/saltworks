#!/bin/sh
# EVIDENCE seat — #audit_axioms COVERAGE check.
#
# Answers the one question `#audit_axioms` cannot ask about itself:
#   IS EVERY DECLARATION IN THIS FILE NAMED ON SOME #audit_axioms COMMAND?
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
#       in NO #audit_axioms command at all. It elaborated (it sits far above the
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
# ⛔⛔ DEFECT FOUND BY SILICON 08:5x, ONE HOUR AFTER THIS SHIPPED — AND IT IS THE
# SAME SHAPE AS THE BUG THIS FILE WAS WRITTEN TO CATCH.
#   `#audit_axioms` is VARIADIC (`elab "#audit_axioms" ids:ident+`,
#   SaltWorks/Tactic/AuditAxioms.lean:81) and this corpus WRAPS long name lists
#   onto INDENTED CONTINUATION LINES that carry no `#audit_axioms` token:
#       #audit_axioms SaltWorks.Silicon.monotone_bool_false_prefix
#         SaltWorks.Silicon.card_filter_perm          ← v1 could not see this
#   v1 extracted names only from lines CONTAINING the token, so it counted
#   COMMANDS and reported continued names as UNAUDITED — false positives, in the
#   direction that manufactures alarm. Silicon measured the same error in
#   import-closure.py at 2.3× (10 sites vs 23 declarations).
# ⚠️ AND MY VALIDATION DID NOT CATCH IT: I tested on two HDL Scratch files that
#   happen to use the single-line form only. A negative control drawn from a
#   corpus subset that lacks the breaking feature proves nothing about it —
#   `a-count-is-not-a-scope` pointed at my own test coverage.
#   v2 parses the variadic command properly and is validated on BOTH forms.
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

# ── the variadic-command parser ────────────────────────────────────────────
# Written to a file via a QUOTED heredoc: Lean identifiers carry primes
# (`hσ'r`), which would terminate a single-quoted inline awk program.
#
# A CONTINUATION line is recognised NEGATIVELY — indented, non-empty, and
# containing none of the punctuation that any other Lean syntax would carry.
# A negative test survives unicode identifiers (σ, ₀, «…»); an identifier
# character-class does not, and this corpus is full of them.
# ⛔⛔ v4 — THE THIRD DEFECT, AND THE PUREST INSTANCE OF THE DAY'S RECURRING CLASS.
# v3 matched `#audit_axioms` ANYWHERE on a line. GenSelectCount.lean:577 is PROSE
# INSIDE A `/-! ... -/` DOC COMMENT:
#     `#audit_axioms` aborts the rest of its own argument list at the first failure,
# — compiler's ④′ RATIONALE. v3 parsed that sentence as an invocation and
# reported eleven English words as audited names: the · of · at · its · own ·
# rest · list · first · failure, · argument · aborts. EXIT=1 on a clean file.
# 🔑 A DOCUMENT EXPLAINING A COMMAND BECAME AN INVOCATION OF IT — the same shape
# as bus_watch.sh's founding defect, which I wrote in that file's own header:
# "a document describing a pattern-matcher by quoting the pattern becomes a
# carrier of it." Fifth instance on 2026-08-08, across five different instrument
# kinds. TWO INDEPENDENT GUARDS, because one of these keeps not being enough:
#   (1) STRIP COMMENTS FIRST — audit arguments are code, never comment text.
#       Lean block comments NEST, so the depth counter is required.
#   (2) ANCHOR THE COMMAND — a real invocation starts its line.
cat > "$TMP/parse.awk" <<'AWK'
function emit(s,   n, a, i) {
  n = split(s, a, /[ \t]+/)
  for (i = 1; i <= n; i++) if (a[i] != "") print a[i]
}
# Guard (1): remove --line comments and NESTED /- block -/ comments.
# `depth` is global on purpose: block comments span lines.
function strip(line,   out, i, n, two) {
  out = ""; n = length(line); i = 1
  while (i <= n) {
    two = substr(line, i, 2)
    if (depth == 0 && two == "--") break          # line comment: drop the rest
    if (two == "/-") { depth++; i += 2; continue }
    if (two == "-/") { if (depth > 0) depth--; i += 2; continue }
    if (depth == 0) out = out substr(line, i, 1)
    i++
  }
  return out
}
{
  s = strip($0)
  # Guard (2): the command must START the line (after indentation).
  if (s ~ /^[ \t]*#audit_axioms([ \t]|$)/) {
    line = s
    sub(/^[ \t]*#audit_axioms[ \t]*/, "", line)
    emit(line)
    inAudit = 1
    next
  }
  if (inAudit == 1) {
    # must be indented and have content
    if (s !~ /^[ \t]+[^ \t]/)               { inAudit = 0; next }
    # any of these means it is NOT a bare name list
    if (s ~ /[:(){}\[\],=#⟨⟩→←∀∃λ|]/)       { inAudit = 0; next }
    if (s ~ /^[ \t]*(theorem|lemma|def|end|section|namespace|open|import|instance|example|abbrev|structure|inductive|variable|attribute|macro|elab|notation|set_option|deriving|where|by)([ \t]|$)/) {
      inAudit = 0; next
    }
    emit(s)
    next
  }
}
AWK

# Declared names, SPLIT BY KIND. The anchor is load-bearing — an unanchored
# `theorem ` also matches PROSE in doc comments, which is exactly the 212-vs-209
# disagreement of 2026-08-08: three English sentences counted as theorems.
#
# ⛔⛔ THE SPLIT IS NOT COSMETIC — v2 WITHOUT IT WAS A FALSE-ALARM MACHINE.
# Lumping `def` in with theorems reported **10 DECLARED BUT NEVER AUDITED** on
# SaltWorks/Silicon/Equiv/PartialLoad.lean — and ALL TEN ARE `def`s. That file
# has ZERO unaudited theorems; it is fully covered. A `def` is a definition, not
# a proof obligation: it cannot carry a `sorryAx` from a failed tactic, which is
# the entire hazard this script exists to detect. Auditing defs is a style, not
# a duty, and scoring it as a gap manufactures alarm on a clean file — the
# direction silicon named at 08:5x as the one that gets a real finding dismissed.
# ⇒ THEOREMS/LEMMAS are the ⛔ verdict. Defs are reported separately, as ℹ️.
for kind in thm def; do
  case $kind in
    thm) pat='(theorem|lemma)' ;;
    def) pat='def' ;;
  esac
  command grep -hE "^[[:space:]]*(private |protected |nonrec )*${pat}[[:space:]]" "$@" \
    | sed -E "s/^[[:space:]]*(private |protected |nonrec )*${pat}[[:space:]]+//; s/[^A-Za-z0-9_.]+.*\$//" \
    | command grep '[A-Za-z]' | sed 's/.*\.//' | sort -u > "$TMP/declared.$kind"
done

# Audited names, via the variadic parser. Frequently FULLY QUALIFIED
# (SaltWorks.Silicon.foo) while declarations are bare inside a `namespace`, so
# compare on the last dotted component.
awk -f "$TMP/parse.awk" "$@" | command grep '[A-Za-z]' | sed 's/.*\.//' | sort -u > "$TMP/audited.base"

nt=$(wc -l < "$TMP/declared.thm" | tr -d ' ')
nf=$(wc -l < "$TMP/declared.def" | tr -d ' ')
na=$(wc -l < "$TMP/audited.base" | tr -d ' ')
# anchored for the same reason the parser is: an unanchored count also counts
# the doc comment that EXPLAINS the command (GenSelectCount.lean:577).
ncmd=$(command grep -hc '^[[:space:]]*#audit_axioms' "$@" | awk '{s+=$1} END{print s+0}')
comm -23 "$TMP/declared.thm" "$TMP/audited.base" > "$TMP/uncovered"
comm -23 "$TMP/declared.def" "$TMP/audited.base" > "$TMP/uncovered.def"
cat "$TMP/declared.thm" "$TMP/declared.def" | sort -u > "$TMP/declared.all"
comm -13 "$TMP/declared.all" "$TMP/audited.base" > "$TMP/stale"
nu=$(wc -l < "$TMP/uncovered"     | tr -d ' ')
nud=$(wc -l < "$TMP/uncovered.def" | tr -d ' ')
ns=$(wc -l < "$TMP/stale"          | tr -d ' ')

echo "files              : $*"
echo "theorems/lemmas    : $nt    ^(theorem|lemma), line-anchored  ← the audited duty"
echo "defs               : $nf    ^def                             ← informational only"
echo "audited  (unique)  : $na    names across $ncmd #audit_axioms COMMAND(S)"
echo "                            (commands ≠ declarations: the command is variadic)"
echo

if [ "$nu" -gt 0 ]; then
  echo "⛔ THEOREMS DECLARED BUT NEVER AUDITED — $nu (no run will ever print their axioms):"
  while read -r n; do
    loc=$(command grep -nE "^[[:space:]]*(private |protected |nonrec )*(theorem|lemma)[[:space:]]+$n([[:space:]]|\{|\(|:)" "$@" \
          | head -1 | cut -d: -f1-2)
    echo "     $n        ${loc:-(location not resolved)}"
  done < "$TMP/uncovered"
else
  echo "✅ every THEOREM is named on some #audit_axioms command"
fi

if [ "$nud" -gt 0 ]; then
  echo
  echo "ℹ️  defs not audited — $nud (NORMAL: a def carries no proof obligation,"
  echo "    so this is not a gap. Listed only so the numbers reconcile.)"
  sed 's/^/     /' "$TMP/uncovered.def" | head -12
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

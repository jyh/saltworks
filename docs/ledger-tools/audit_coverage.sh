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

# ⛔⛔ v6 — THE SKEW BLOCK, CORRECTED. v5 PAIRED THE WRONG TWO OBJECTS.
#
# v5 compared SOURCE mtime against the module's .olean and concluded "any EXIT=0
# quoted for this file built an earlier version." Compiler and silicon refuted it
# within three minutes, from saltbuild.sh itself:
#
#   saltbuild.sh:26   *.lean)  lake env lean -M "$CAP" "$@"   ← ELABORATES, writes NO olean
#   saltbuild.sh:27   *)       lake build "$@"                ← the ONLY path that writes one
#
# 🔑 A FILE-MODE AUDIT NEVER WRITES OR READS AN OLEAN. So a stale-or-absent olean
# is the NORMAL state for an audited file and says nothing whatever about whether
# the audit read current bytes. MEASURED: v5's "never built" branch fired on
# 34 of 41 Scratch*.lean — the exact corpus this tool exists to audit — and the
# message was not merely noisy, it was FALSE: those files HAVE been built, in
# file mode, EXIT=0. (My own GenSelectCount passed v5 only because it is a hub
# module that happened to be swept after my edit — luck of sequencing, not a
# property of the check.)
#
# ⭐ THE FIX IS TO PUT THE READING BACK UNDER THE PROPERTY IT ACTUALLY MEASURES.
# The olean's age is not HYGIENE (②). It is REACH (③) — is this module current in
# the corpus build graph. Two different verdicts need two different pairs:
#
#   FILE-MODE AUDIT  (saltbuild.sh X.lean)  →  pair RUN CLOCK  vs SOURCE MTIME
#   MODULE / HUB GREEN (lake build)         →  pair OLEAN MTIME vs SOURCE MTIME
#
# This tool cannot know which verdict a reader will pair it with, and it cannot
# see anyone's run clock. So it PRINTS THE SOURCE MTIME and names both pairs,
# and it asserts nothing about a verdict it did not observe.
for f in "$@"; do
  base=$(basename "$f" .lean)
  smt=$(stat -f %Sm -t '%H:%M:%S' "$f")
  echo "⏱  SOURCE MTIME  $base.lean  $smt"
  # ⭐ A FILE-MODE AUDIT LEAVES NO TRACE (silicon, 09:51) — so the only way to
  # answer "was this verified?" is for someone to have WRITTEN the verdict down.
  # audit_record.sh does that, pinned to a source hash. Read it if it exists.
  arec="$(git rev-parse --show-toplevel 2>/dev/null)/docs/audit-records/$base.audit"
  if [ -f "$arec" ]; then
    rsha=$(command grep -m1 '^sha256' "$arec" | awk '{print $3}')
    rver=$(command grep -m1 '^VERDICT' "$arec" | awk '{print $3}')
    rfin=$(command grep -m1 '^run finished' "$arec" | cut -d: -f2- | sed 's/^ *//')
    csha=$(shasum -a 256 "$f" | cut -d' ' -f1)
    if [ "$rsha" = "$csha" ]; then
      # ⛔ THE MARKER KEYS ON *GREEN*, NOT ON "a record exists". A RED or
      # UNPINNED verdict pinned to the right revision is still not a pass, and
      # a ✅ beside it would manufacture exactly the reassurance this tool spent
      # the morning removing from its own output.
      case "$rver" in
        GREEN) mark="✅" ;;
        *)     mark="⚠️ " ;;
      esac
      echo "   $mark AUDIT RECORD: $rver, pinned to THIS revision ($rfin)"
      echo "      sha $(echo "$csha" | cut -c1-16)… — record and source agree."
      [ "$rver" = "GREEN" ] || echo "      ⇒ a record is not a pass. This verdict is NOT green."
    else
      echo "   ⛔ AUDIT RECORD IS FOR A DIFFERENT REVISION — it describes sha"
      echo "      $(echo "$rsha" | cut -c1-16)…, the file on disk is $(echo "$csha" | cut -c1-16)…"
      echo "      ⇒ that verdict ($rver) DOES NOT APPLY to these bytes. Re-record."
    fi
  else
    echo "   FILE-MODE AUDIT: your 'saltbuild EXIT=N' is current only if THAT RUN"
    echo "   COMPLETED AFTER $smt. No audit record exists, so this tool cannot"
    echo "   answer it — a file-mode audit writes nothing. Use audit_record.sh."
  fi
  ol=$(command find .lake -name "$base.olean" 2>/dev/null | head -1)
  if [ -z "$ol" ] || [ ! -f "$ol" ]; then
    echo "   REACH: no .olean — NOT IN THE CORPUS BUILD GRAPH. Normal for a scratch"
    echo "   file (file-mode audits write none). It means no HUB green covers this."
  else
    ot=$(stat -f %m "$ol"); st=$(stat -f %m "$f")
    if [ "$st" -gt "$ot" ]; then
      echo "   ⛔ REACH: olean $(stat -f %Sm -t '%H:%M:%S' "$ol") is OLDER than source (${st_d:-$(( (st-ot)/60 ))}m)."
      echo "   ⇒ THE HUB GREEN FOR THIS MODULE IS STALE. Says nothing about a file-mode"
      echo "     audit, which never consults it. The next lake build will rebuild it."
    else
      echo "   REACH: olean $(stat -f %Sm -t '%H:%M:%S' "$ol") — current w.r.t. source."
    fi
  fi
done

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
echo "⚠️  THREE DIFFERENT PROPERTIES. A ✅ here is ONLY the first of them, and a"
echo "    declaration can be covered AND clean AND never elaborated by the corpus:"
echo "      1 COVERAGE  every theorem is ASKED about      ← THIS TOOL, and only this"
echo "      2 HYGIENE   the answers are clean             ← saltbuild EXIT=0 + ✓/✗ lines"
echo "                  (per compiler's ④′, one declaration per call — a name"
echo "                   covered here still goes UNREPORTED by an aborted call)"
echo "      3 REACH     the corpus build elaborates this  ← ledger-tools/import-closure.py"
echo "                  module at all"
echo "    ⛔ 2026-08-08 09:2x, silicon: GenSelectCount.lean passes 1 and 2 and FAILS"
echo "       3 — 56 audit sites OUTSIDE the default build, so the corpus green does"
echo "       not see them. 'Audited' is not 'audited WHERE ANYONE WOULD NOTICE'."

[ "$nu" -eq 0 ] && [ "$ns" -eq 0 ] && exit 0
exit 1

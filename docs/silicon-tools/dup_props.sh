#!/bin/sh
# dup_props.sh — find propositions PROVED MORE THAN ONCE under different names.
#
#   sh docs/silicon-tools/dup_props.sh [git-ref] [path-glob]
#   sh docs/silicon-tools/dup_props.sh origin/master 'SaltWorks/HDL/*.lean'
#
# ⚖️ NOT the same class as docs/hdl-tools/dup_decls.py, and both are worth having:
#     dup_decls.py  SAME NAME in two files -> Lean SILENTLY keeps the
#                   first-imported copy, so SaltWorks.lean's line order becomes
#                   semantically load-bearing.  DANGEROUS.
#     this          DIFFERENT names, SAME statement -> nothing breaks today; the
#                   risk is DIVERGENCE, when a re-cut updates one proof and
#                   leaves the other kernel-checked, audited, ticked, and stating
#                   a number that is no longer true.  MILD, and invisible to a
#                   green build exactly like its dangerous cousin.
#
# ⭐ THE PART THAT IS NOT A ONE-LINER — CLASSIFY, NEVER COUNT. Two patterns are
# statement-identical to the disease and are the CURE, so a bare count over-reports:
#     ruled_gate_count := gate_count_three          <- ALIAS: the fix itself
#     ruled_ssa := genSelect_ssa 3 2 (by decide)    <- PARAMETRIC INSTANTIATION,
#                  better than either: it proves the instance BY the general
#                  lemma, demonstrating coverage instead of re-deciding.
# Measured on SaltWorks/HDL 8/8: the raw count says 8, the truth is 6 + 2 cures.
#
# ⚠️ AND CHECK THE ADJACENT-OBJECT TRAP BEFORE BELIEVING A HIT. Two theorems can
# print the same statement about DIFFERENT objects if each file defines its own.
# On this corpus the C/non-C pairs (BatcherNet/BatcherNetC, CompareExchange/
# CompareExchangeC) are exactly where that would bite -- verified there by
# checking each object is defined ONCE and the second file imports it.
#
# Regex, not Lean: it can MISS (never invent). A clean report is evidence, not proof.
#
# ⛔ AND HERE IS A MEASURED MISS RATHER THAN A GENERIC CAVEAT — I know the answer
# on this corpus because I swept it by hand first, and the tool finds SIX of the
# SEVEN:
#     (genSelect 10 4).gates.length - (genSelect 3 2).gates.length = 1154
#     RuledSizing32.lean:38 (by rw)  +  SelectCut32.lean:416 (by omega)
# It is invisible here because BOTH declarations put `:=` or the statement across
# a LINE BREAK, and this pipeline reads one line at a time. A multi-line theorem
# is exactly the shape a long statement takes, so the misses are biased toward
# the BIGGEST propositions -- the opposite of harmless.
# ⇒ Treat a clean run as "no single-line duplicates", which is the honest scope,
#   and hand-check anything whose statement wraps.

REF=${1:-origin/master}
GLOB=${2:-SaltWorks/HDL/*.lean}

# ⛔ AN EMPTY RESULT MUST NOT LOOK LIKE A CLEAN ONE (silicon's law, 17:12; first
# put into code by evidence at 17:13, and this is my own instance of it).
# Before the fix this script printed NOTHING when the corpus was clean -- which is
# byte-identical to what it prints when the glob matches no files, the ref is
# wrong, or the theorem regex has rotted. "Nothing found" is the one output
# that looks the same for every wrong question.
# ⇒ So it now states its POPULATION first, and REFUSES outright if that
#   population is zero. A detector that has scanned nothing has not shown it can
#   detect anything.
FILES=$(git ls-tree -r --name-only "$REF" -- $GLOB 2>/dev/null | wc -l | tr -d ' ')
THMS=$(git grep -h -cE "^theorem " "$REF" -- "$GLOB" 2>/dev/null | awk -F: '{n+=$NF} END{print n+0}')
if [ "${FILES:-0}" -eq 0 ] || [ "${THMS:-0}" -eq 0 ]; then
  echo "⛔ dup_props: REFUSING — scanned $FILES files / $THMS theorems at '$REF' '$GLOB'."
  echo "   A zero population cannot support a clean verdict. Check the ref and the glob."
  exit 2
fi
echo "scanned: $FILES files, $THMS theorems at $REF -- $GLOB"

git grep -h -E "^theorem [A-Za-z_0-9']+ ?:.*:=" "$REF" -- "$GLOB" \
| sed -E "s/^theorem [A-Za-z_0-9']+ ?://; s/:=.*$//; s/^ *//; s/ *$//" \
| grep -vE '^$' | sort | uniq -c | sort -rn | awk '$1>1 {$1=""; sub(/^ /,""); print}' \
| while IFS= read -r prop; do
    [ -z "$prop" ] && continue
    hits=$(git grep -n -F "$prop" "$REF" -- "$GLOB" | sed "s|^$REF:||" | grep -E ':[0-9]+:theorem')
    # ⛔ AN EMPTY `hits` IS IMPOSSIBLE BY CONSTRUCTION — `$prop` was just EXTRACTED
    # from this same ref and glob, so it must be findable in them. Empty therefore
    # means the PIPELINE FAILED, not that the proposition vanished. Without this,
    # a failure here makes `indep` 0 and the `continue` below silently DROPS a real
    # duplicate — under-reporting, which is the direction that cost me three
    # published "residue still 1" verdicts on 8/8.
    # (The pipeline's own status is `grep`'s, so it cannot be tested directly here;
    # this invariant check is the substitute. See meas_scan.sh's third-pass note.)
    if [ -z "$hits" ]; then
      echo "⛔ dup_props: '$prop' was extracted from $REF but cannot be found in it."
      echo "   The lookup pipeline FAILED. Refusing to continue — the count would under-report."
      exit 2
    fi
    # ⭐ ONLY REPORT A PROPOSITION WITH >=2 INDEPENDENT PROOFS. A proposition that
    # has been CURED -- one proof plus aliases -- must drop off the list, or the
    # headline count never falls and a reader concludes the fix did nothing.
    # MEASURED 8/8: after compiler aliased five of six pairs, the old output still
    # listed all six. The classification column was right and the LIST was
    # misleading, which is this file's own count-vs-classify law aimed at itself.
    indep=$(printf '%s\n' "$hits" | grep -c ':= by' || true)
    [ "${indep:-0}" -lt 2 ] && continue
    printf '\n=== %s   [%s independent proofs]\n' "$prop" "$indep"
    printf '%s\n' "$hits" | while IFS= read -r hit; do
        case "$hit" in
          *':= by'*)  kind='INDEPENDENT PROOF' ;;
          *':='*)     kind='alias / instantiation  <- the CURE, do not sweep' ;;
          *)          kind='(proof on next line — classify by hand)' ;;
        esac
        printf '  %-100s  %s\n' "$(echo "$hit" | cut -c1-100)" "$kind"
      done
  done
echo "scan complete (a proposition is listed only with >=2 INDEPENDENT proofs)."

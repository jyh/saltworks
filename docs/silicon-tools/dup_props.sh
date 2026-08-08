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

git grep -h -E "^theorem [A-Za-z_0-9']+ ?:.*:=" "$REF" -- "$GLOB" \
| sed -E "s/^theorem [A-Za-z_0-9']+ ?://; s/:=.*$//; s/^ *//; s/ *$//" \
| grep -vE '^$' | sort | uniq -c | sort -rn | awk '$1>1 {$1=""; sub(/^ /,""); print}' \
| while IFS= read -r prop; do
    [ -z "$prop" ] && continue
    printf '\n=== %s\n' "$prop"
    git grep -n -F "$prop" "$REF" -- "$GLOB" \
    | sed "s|^$REF:||" | grep -E ':[0-9]+:theorem' \
    | while IFS= read -r hit; do
        case "$hit" in
          *':= by'*)  kind='INDEPENDENT PROOF' ;;
          *':='*)     kind='alias / instantiation  <- the CURE, do not sweep' ;;
          *)          kind='(proof on next line — classify by hand)' ;;
        esac
        printf '  %-100s  %s\n' "$(echo "$hit" | cut -c1-100)" "$kind"
      done
  done

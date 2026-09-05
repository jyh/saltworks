#!/bin/sh
# olean_staleness.sh — REFUSE A MEAS VERDICT TAKEN AGAINST A STALE IMPORT CLOSURE.
#
# ⛔⛔ WHY THIS FILE EXISTS — 2026-09-05, AND I WAS ONE POST AWAY FROM ACCUSING A PEER.
# After fast-forwarding to 88e7f64c I ran the PATH form on the two modules MEAS had
# re-triggered on. It came back RED, and the red was SUBSTANTIVE: `decide` proved
# adapterNext_correct's 32-input proposition FALSE, and #audit_axioms caught the
# fallen-through declaration depending on sorryAx. A correctness theorem refuted and
# a sorry in the axiom audit is exactly what a real regression looks like.
#
# IT WAS MY OWN BUILD STATE. `git pull` moves SOURCES; it does not move OLEANS. The
# PATH form elaborates the TARGET fresh and loads its imports FROM CACHE, so the run
# compared a NEWLY REBUILT circuit against a FIVE-DAY-OLD BusFSM.next
# (olean Aug 30 12:16 vs source Sep 4 11:26). The module form then reported
# adapterNext_correct ✓ at 0 axioms, and the PATH form re-run went green.
#
# 🔑 THE LAW, AND IT IS NOT THE ONE THE BRIEF ALREADY CARRIES:
#   ***A STALE OLEAN IS NOT A MISSING OLEAN.***
#   The brief's ⑨ hook says a root red on a MISSING olean is build state, and keys the
#   reader on the `import owed` symptom. A MISSING olean ANNOUNCES ITSELF. A STALE one
#   is silent about its cause and produces a CORRECT-LOOKING REFUTATION OF A TRUE
#   THEOREM. The existing hook keys on the tidy failure; the dangerous one wears the
#   face of a peer's defect.
# ⚠️ AND IT IS MORE CREDIBLE THAN A GREEN WOULD HAVE BEEN: the landing commit SAID it
#   had rebuilt the organ because the spec moved. A stale-dependency red lands exactly
#   where a real regression would land, and the story you already have explains it.
#   ⇒ CARE CANNOT FIX THIS. Only a measurement taken BEFORE the verdict can.
#
# ⛔ meas_build.sh ALREADY PRINTS the scope ("their transitive closure came from cached
#   oleans — NOT re-checked here") and still let the verdict out. [[printed-is-not-gated]]
#   one level up: a CAVEAT nothing consumes is a printout. This file consumes it.
#
# Usage:  olean_staleness.sh <path/to/Module.lean> [more.lean ...]
# Exit:   0 = every project-local module in the closure has an olean at least as new as
#             its source;  3 = STALE (names them);  2 = usage/internal.
# Scope:  project-local modules ONLY — a module is checked when <Mod path>.lean exists in
#         this tree. Package deps (Salt, mathlib) are lake's to age and are NOT checked;
#         that is a REAL limit and it is printed, not implied.
set -u

[ $# -ge 1 ] || { echo "usage: olean_staleness.sh <path/to/Module.lean> [...]" >&2; exit 2; }

ROOT=${OLEAN_ROOT:-.lake/build/lib/lean}

# mod2src  SaltWorks.HDL.BusFSM -> SaltWorks/HDL/BusFSM.lean
mod2src() { echo "$1" | tr '.' '/' | sed 's/$/.lean/'; }
mod2ole() { echo "$ROOT/$(echo "$1" | tr '.' '/').olean"; }
src2mod() { echo "$1" | sed 's/\.lean$//' | tr '/' '.'; }

seen=""
stale=""
missing=""
checked=0

# Transitive walk over project-local imports. Depth is small; a worklist keeps it flat
# and terminates on the `seen` set even if the import graph has a cycle.
work=""
for t in "$@"; do
  [ -f "$t" ] || { echo "⛔ olean_staleness: no such file: $t" >&2; exit 2; }
  work="$work $(src2mod "$t")"
done

while [ -n "$(echo "$work" | tr -d ' ')" ]; do
  next=""
  for m in $work; do
    case " $seen " in *" $m "*) continue ;; esac
    seen="$seen $m"
    src=$(mod2src "$m")
    [ -f "$src" ] || continue          # not project-local: lake's, not ours
    checked=$((checked + 1))
    ole=$(mod2ole "$m")
    if [ ! -f "$ole" ]; then
      missing="$missing $m"
    elif [ "$src" -nt "$ole" ]; then
      stale="$stale $m"
    fi
    # queue this module's own imports
    for im in $(grep -E '^import ' "$src" 2>/dev/null | awk '{print $2}'); do
      next="$next $im"
    done
  done
  work="$next"
done

if [ -n "$stale" ] || [ -n "$missing" ]; then
  echo "⛔ STALE IMPORT CLOSURE — REFUSING TO CERTIFY A PATH-FORM VERDICT."
  echo "   A PATH-form red taken now is NOT evidence about the source. It compares a"
  echo "   freshly elaborated target against oleans older than their own sources."
  [ -n "$stale" ]   && { echo "   SOURCE NEWER THAN ITS OLEAN:"; for m in $stale;   do echo "     - $m"; done; }
  [ -n "$missing" ] && { echo "   OLEAN ABSENT:";                for m in $missing; do echo "     - $m"; done; }
  echo "   ⇒ Run the MODULE form first, then re-run the PATH form:"
  echo "        sh ../saltbuild.sh $(src2mod "$1")"
  echo "   (project-local modules checked: $checked; package deps not checked — lake's)"
  exit 3
fi

echo "✅ import closure current — $checked project-local module(s), none older than source."
echo "   (package deps (Salt, mathlib) NOT checked here — that is this gate's declared limit)"
exit 0

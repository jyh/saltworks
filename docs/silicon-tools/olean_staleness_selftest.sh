#!/bin/sh
# olean_staleness_selftest.sh — drive BOTH arms of the staleness guard on a fixture.
#
# ⭐ THE ARM THAT MATTERS IS THE TRANSITIVE ONE. My real defect was NOT the target's own
#   olean — it was a DEPENDENCY's. A guard that only checked the file named on the command
#   line would have printed a clean bill and let the false verdict out, which is the exact
#   shape of the bug it exists to prevent. So the fixture makes the TARGET current and
#   only the DEPENDENCY stale, and requires the guard to still refuse.
# ⛔ Mtimes are set with `touch -t`, never with sleep: a filesystem's 1-second granularity
#   makes a sleep-based fixture flaky, and a flaky control is worse than none.
set -u
GUARD=$(cd "$(dirname "$0")" && pwd)/olean_staleness.sh
FIX=$(mktemp -d) || exit 2
trap 'rm -rf "$FIX"' EXIT
fails=0

mk() { # mk <clean|stale|missing>
  rm -rf "$FIX/t"; mkdir -p "$FIX/t/Pkg/Sub" "$FIX/t/.lake/build/lib/lean/Pkg/Sub"
  printf '%s\n' 'import Pkg.Sub.Dep' '-- top' > "$FIX/t/Pkg/Top.lean"
  printf '%s\n' '-- dep' > "$FIX/t/Pkg/Sub/Dep.lean"
  : > "$FIX/t/.lake/build/lib/lean/Pkg/Top.olean"
  : > "$FIX/t/.lake/build/lib/lean/Pkg/Sub/Dep.olean"
  # sources OLD, oleans NEW  => clean
  touch -t 202601010000 "$FIX/t/Pkg/Top.lean" "$FIX/t/Pkg/Sub/Dep.lean"
  touch -t 202601020000 "$FIX/t/.lake/build/lib/lean/Pkg/Top.olean" \
                        "$FIX/t/.lake/build/lib/lean/Pkg/Sub/Dep.olean"
  case "$1" in
    stale)   touch -t 202601030000 "$FIX/t/Pkg/Sub/Dep.lean" ;;   # DEP only, not the target
    missing) rm -f "$FIX/t/.lake/build/lib/lean/Pkg/Sub/Dep.olean" ;;
  esac
}

run() { ( cd "$FIX/t" && sh "$GUARD" Pkg/Top.lean 2>&1 ); }
rc()  { ( cd "$FIX/t" && sh "$GUARD" Pkg/Top.lean >/dev/null 2>&1; echo $? ); }

echo "== ARM 1: clean closure -> must PASS (rc 0) =="
mk clean; got=$(rc); out=$(run)
if [ "$got" = "0" ]; then echo "  ✅ rc=0"; else echo "  ⛔ rc=$got (want 0)"; echo "$out"; fails=$((fails+1)); fi
echo "$out" | grep -q 'closure current' || { echo "  ⛔ missing success text"; fails=$((fails+1)); }

echo "== ARM 2: TRANSITIVE stale dep, target itself current -> must REFUSE (rc 3) =="
mk stale; got=$(rc); out=$(run)
if [ "$got" = "3" ]; then echo "  ✅ rc=3"; else echo "  ⛔ rc=$got (want 3)"; echo "$out"; fails=$((fails+1)); fi
echo "$out" | grep -q 'Pkg.Sub.Dep' || { echo "  ⛔ did not NAME the stale dep"; fails=$((fails+1)); }
# ⛔ ANCHOR ON THE LIST-ENTRY FORM, NOT THE BARE NAME. The first version grepped for
#   'Pkg.Top' anywhere in the output and FAILED — the guard's own remediation line
#   ("sh ../saltbuild.sh Pkg.Top") legitimately names the target. THE CONTROL WAS THE
#   DEFECTIVE PART, which is the failure mode that looks exactly like a real finding.
echo "$out" | grep -q '^     - Pkg\.Top$' && { echo "  ⛔ wrongly blamed the target"; fails=$((fails+1)); }

echo "== ARM 3: absent olean -> must REFUSE (rc 3) and say ABSENT, not stale =="
mk missing; got=$(rc); out=$(run)
if [ "$got" = "3" ]; then echo "  ✅ rc=3"; else echo "  ⛔ rc=$got (want 3)"; echo "$out"; fails=$((fails+1)); fi
echo "$out" | grep -q 'OLEAN ABSENT' || { echo "  ⛔ did not distinguish absent from stale"; fails=$((fails+1)); }

echo "== ARM 4: usage refusal on a missing file (the gate can say NO to its own input) =="
got=$( sh "$GUARD" /nonexistent/Nope.lean >/dev/null 2>&1; echo $? )
if [ "$got" = "2" ]; then echo "  ✅ rc=2"; else echo "  ⛔ rc=$got (want 2)"; fails=$((fails+1)); fi

echo "----"
if [ "$fails" = "0" ]; then echo "✅ olean_staleness selftest: ALL ARMS PASS"; exit 0
else echo "⛔ olean_staleness selftest: $fails FAILURE(S)"; exit 1; fi

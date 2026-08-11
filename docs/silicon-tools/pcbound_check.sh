#!/bin/sh
# pcbound_check.sh — PRE-REGISTERED CRITERION, silicon, 2026-08-11 01:2x.
#
#   sh docs/silicon-tools/pcbound_check.sh <file.lean> [theorem-name ...]
#
# ⚠️ WHY THIS EXISTS, and it is compiler's shape, not mine. Answering item 3 of
# my scoping of math's deferred pass, compiler measured that `whileFits`
# discharges the REPRESENTABILITY half of the branch obligations exactly and the
# pc-RANGE half NOT AT ALL — structurally, because the `hp` hypotheses mention
# `q`, the block's POSITION, and `compileS` has no position parameter. That
# absence is the very property that makes the offsets position-independent.
# The pc-range bound is therefore SUPPLIED BY THE CALLER, exactly as at L0/L1.
#
# ⛔ COMPILER NAMED THE FAILURE SHAPE THEY WANT NOBODY'S GREEN TO COVER:
#      "an emitter that silently ASSUMES `hp` instead of taking it as a
#       hypothesis — the shape that would let a 2^30-instruction program
#       compile to a lie."
#   That is NOT mathematics. It is a structural property of a theorem's binder
#   list, which puts it on the MEAS leg. Hence a criterion, published BEFORE the
#   emitter lands so it cannot be fitted to the artifact afterwards.
#
# THE BAR, fixed in advance:
#   For any theorem asserting where a compiled block's branches LAND, or the
#   correctness of emitted code AT A POSITION:
#     PASS  its binder region carries an explicit pc-range/length bound
#           (`< 2 ^ 32`) — i.e. the caller must supply it.
#     FAIL  no such binder, while the statement still ranges over an arbitrary
#           position or program length. The obligation has been ASSUMED.
#
# ⭐ THIS CRITERION HAS BEEN SHOWN TO FAIL. `--selftest` builds a mutant of a
#   real landed theorem with its `hp` binder deleted and requires the detector
#   to flag it. A criterion only ever run on passing input has not been shown to
#   discriminate — precision reads exactly like strength.
#
# Instrument notes, each paid for on 2026-08-11:
#   · theorem names are END-ANCHORED. `^theorem X` also matches `X_of_branchFree`
#     — the restatement-renames law makes every new name CONTAIN the old one.
#   · `\b` is NOT POSIX ERE and matches NOTHING under `grep -E`. Not used here.
#   · the binder region is the text from the theorem head to the FIRST `:= by`,
#     so a bound appearing only in the PROOF does not count as a hypothesis.

set -u
SELF=$(basename "$0")

# Extract the statement (head .. first ':= by' / ':=') of theorem $2 in file $1.
# ⛔ THE QUOTING HERE IS DELIBERATE AND WAS PAID FOR: the end-anchor character
# class must exclude the PRIME, because Lean names may carry it. Writing that
# class inline put a literal ' and " inside a single-quoted shell string holding
# an awk string, and awk died with "extra ]" on EVERY line — the extractor then
# returned NOT FOUND for every theorem, which is the FALSE-CLEAN direction.
# ⭐ THE SELFTEST CAUGHT IT AND REFUSED TO CERTIFY THE GATE (pos=1 neg=1). The
# positive control is what made a dead extractor distinguishable from a clean
# corpus. Build the class from a -v variable; keep quotes out of the program.
stmt() {
  awk -v n="$2" -v q="$(printf '\047')" '
    $0 ~ ("^theorem[ \t]+" n "([^A-Za-z0-9_" q "]|$)") { f=1 }
    f { print }
    f && /:= by[ \t]*$|:=[ \t]*$|:= by / { exit }
  ' "$1"
}

# ⛔ APPLICABILITY, ADDED AFTER THE TOOL FLAGGED `whileBack_msb` — MY OWN SCOPE
# ERROR, caught by running the gate on the landed set before publishing it.
# `whileBack_msb` is PURE ARITHMETIC about the immediate: no position, no `pc`,
# so it does not NEED a pc-range bound and its "FAIL" meant nothing.
# 🔑 A CRITERION THAT CANNOT TELL "DOES NOT NEED IT" FROM "IS MISSING IT" FIRES
# ON EVERY ARITHMETIC LEMMA IN THE FILE — and a gate that cries wolf on a duty
# that runs all day is how a REAL alarm gets ignored. Same reasoning that made
# meas_since.sh report deletions as RETIRED instead of feeding them to the gate.
# IN SCOPE iff the statement mentions a position-bearing object (`pc`/`codeAt`).
check_one() {   # file, name -> 0 pass/skip, 1 fail
  s=$(stmt "$1" "$2")
  if [ -z "$s" ]; then
    printf '  %-34s ⛔ NOT FOUND (name end-anchored; check spelling)\n' "$2"
    return 1
  fi
  # ⛔ REV 2b — THE SCOPE TEST WAS TOO COARSE AND PRODUCED A FALSE POSITIVE ON A
  # PEER'S LANDED THEOREM. `mentions pc` also matched `while_certificates`, a
  # CONCRETE decide-style certificate over six fixed configs whose statement
  # reads `s.pc` — a RECORD FIELD OF A CLOSED RUN, not a position parameter. It
  # has no `q`, quantifies over nothing, and needs no pc-range bound; my gate
  # called it "the bound is ASSUMED".
  # ***I caught it by READING THE THEOREM before publishing it as a finding. Had
  # I trusted the gate I had just built and tested, my first act with it would
  # have been to report a defect in compiler's work that does not exist.***
  # ⚠️ AND REV 2b's FIRST ATTEMPT ("pc as a BINDER, not a mention") WAS THEN TOO
  # NARROW, caught by my own outputs CONTRADICTING each other: it SKIPped
  # `step_exit_taken`, a theorem that CARRIES the pc-range bound. A statement
  # that needs the bound but is ruled out of scope is a contradiction — and that
  # one pins position through a FIELD (`{st : St}` … `hq : st.pc.toNat = 4 * q`),
  # not through a `pc :` binder. Two revisions, opposite errors, same afternoon.
  # ✅ THE DISCRIMINATOR IS SEMANTIC, NOT SYNTACTIC: in scope iff the statement
  # PINS pc TO A SYMBOLIC POSITION (`pc.toNat = 4 * q`) or speaks of `codeAt`.
  #   step_exit_taken     `st.pc.toNat = 4 * q`                    -> IN SCOPE
  #   while_certificates  `s.pc == BitVec.ofNat 32 (4 * img.len)`  -> concrete,
  #                       a closed run with no position variable   -> SKIP
  if ! printf '%s\n' "$s" | grep -qE '(pc\.toNat[ \t]*=[ \t]*4[ \t]*\*|codeAt)'; then
    printf '  %-34s ·  SKIP — no position in the statement, bound N/A\n' "$2"
    return 0
  fi
  if printf '%s\n' "$s" | grep -q '< *2 *\^ *32'; then
    printf '  %-34s ✅ PASS — pc-range bound is a HYPOTHESIS\n' "$2"
    return 0
  fi
  printf '  %-34s ⛔ FAIL — NO pc-range binder; the bound is ASSUMED\n' "$2"
  return 1
}

if [ "${1:-}" = "--selftest" ]; then
  SRC=${2:?usage: $SELF --selftest <file.lean> <theorem-with-hp>}
  NAME=${3:?usage: $SELF --selftest <file.lean> <theorem-with-hp>}
  TMP=$(mktemp -t pcbound); trap 'rm -f "$TMP"' EXIT
  echo "SELFTEST — the criterion must PASS the real theorem and FAIL its mutant."
  echo "POSITIVE CONTROL (real $NAME):"
  check_one "$SRC" "$NAME"; pos=$?
  # MUTANT: delete the pc-range binder line, leaving everything else intact.
  grep -v '< *2 *\^ *32' "$SRC" > "$TMP"
  echo "NEGATIVE CONTROL (same theorem, hp binder deleted):"
  check_one "$TMP" "$NAME"; neg=$?
  echo
  crit=1
  if [ "$pos" = 0 ] && [ "$neg" = 1 ]; then
    echo "✅ CRITERION DISCRIMINATES — passes the real, fails the mutant."; crit=0
  else
    echo "⛔ CRITERION IS VACUOUS (pos=$pos neg=$neg) — DO NOT USE IT AS A GATE."
  fi

  # ⛔ HARNESS ARMS — ADDED REV 2. The rev-1 selftest stopped at the line above
  # and certified a tool with a VACUOUS-PASS PATH: `check_one` was correct and
  # the harness never called it. ***PROVING THE CRITERION DISCRIMINATES SAYS
  # NOTHING ABOUT WHETHER ANYTHING IS EVER FED TO IT.*** These arms invoke "$0"
  # itself — the REAL entry point an operator types, not a copy of its logic.
  echo
  echo "HARNESS CONTROLS — does the gate ever actually examine anything?"
  harn=0
  EMPTY=$(mktemp -t pcbnone); printf 'def f := 1\n-- no theorems here\n' > "$EMPTY"

  # H1 a file with NO theorems must be FATAL, never "ALL PASS".
  o1=$(sh "$0" "$EMPTY" 2>&1); s1=$?
  case "$o1$s1" in
    *ALL\ PASS*|*0) printf '  H1 empty-file    ⛔ FAIL — vacuous pass (exit %s)\n' "$s1"; harn=1 ;;
    *)              printf '  H1 empty-file    ✅ refused, exit %s\n' "$s1" ;;
  esac

  # H2 no names given: the gate must DISCOVER theorems and say how many.
  o2=$(sh "$0" "$SRC" 2>&1); s2=$?
  ex=$(printf '%s\n' "$o2" | sed -n 's/^EXAMINED \([0-9]*\).*/\1/p')
  if [ "${ex:-0}" -gt 0 ]; then printf '  H2 discovery     ✅ examined %s theorem(s) with no names given\n' "$ex"
  else printf '  H2 discovery     ⛔ FAIL — examined ZERO with no names given\n'; harn=1; fi

  # H3 the reported bug: the gate must not certify its own (theorem-free) source.
  o3=$(sh "$0" "$0" 2>&1); s3=$?
  case "$o3" in
    *ALL\ PASS*) printf '  H3 self-certify  ⛔ FAIL — gate passes its own source\n'; harn=1 ;;
    *)           printf '  H3 self-certify  ✅ refused, exit %s\n' "$s3" ;;
  esac
  # H4 THE SCOPE INVARIANT, and it is the arm that caught rev 2b. A theorem that
  # CARRIES the pc-range bound but is classified OUT OF SCOPE is a contradiction:
  # the bound would not be there if the statement had no position. This detects
  # a scope test that has drifted TOO NARROW — the direction that SKIPS exactly
  # the theorems the gate exists for, silently, while printing ALL PASS.
  # ⭐ Rev 2b SKIPped `step_exit_taken`, which carries the bound; I found it by
  # noticing two of my own outputs disagree. This arm makes that automatic.
  o4=$(sh "$0" "$SRC" 2>&1)
  bad=$(printf '%s\n' "$o4" | awk '/SKIP/{print $1}' | while read -r nm; do
          st=$(stmt "$SRC" "$nm")
          printf '%s' "$st" | grep -q '< *2 *\^ *32' && echo "$nm"
        done)
  if [ -z "$bad" ]; then
    printf '  H4 scope-invariant ✅ no bound-carrying theorem was SKIPPED\n'
  else
    printf '  H4 scope-invariant ⛔ FAIL — SKIPPED despite carrying the bound: %s\n' "$bad"
    harn=1
  fi
  rm -f "$EMPTY"

  echo
  if [ "$crit" = 0 ] && [ "$harn" = 0 ]; then
    echo "✅ CRITERION DISCRIMINATES AND THE HARNESS FEEDS IT. Safe to use as a gate."
    exit 0
  fi
  echo "⛔ NOT SAFE AS A GATE (criterion=$crit harness=$harn)."
  exit 1
fi

F=${1:?usage: $SELF <file.lean> [theorem-name ...]}
shift
[ -r "$F" ] || { echo "FATAL: cannot read $F"; exit 2; }

# ⛔⛔ REV 2 — THE VACUOUS-PASS PATH, found by COMPILER running the gate instead
# of thanking me for it, 2026-08-11 01:30. Rev 1 was:
#     for n in "$@"; do check_one "$F" "$n" || rc=1; done
# With NO names, the loop never ran, `rc` stayed 0, and it printed ALL PASS
# having examined ZERO THEOREMS — exit 0. It certified its own source file.
# ***And the usage line ADVERTISED it (`[theorem-name ...]`, brackets = optional),
# so the vacuous invocation was the DOCUMENTED one — and the natural one: "run
# the gate on the file" is what a tired operator types at 2am.***
#
# 🔑 WHY THE rev-1 SELFTEST COULD NOT SEE IT, and this is worth more than the bug:
#   IT EXERCISED `check_one`, WHICH WAS CORRECT. It proved the CRITERION
#   discriminates and said NOTHING about whether the HARNESS ever FEEDS it
#   anything. ***A criterion discriminates perfectly over an empty set.*** Same
#   false-clean direction as the dead extractor one layer out: there the
#   extractor was dead, here it is alive and simply never called.
#
# ⇒ NAMES ARE NOW DISCOVERED FROM THE FILE, not supplied by an operator. Taking
#   compiler's (b) over (a): refusing the empty case still checks only the names
#   somebody REMEMBERED TO TYPE, so a theorem added by a later landing that
#   nobody lists would pass unexamined — absent, not degraded, and absent is
#   silent. Discovery makes the gate cover the FILE.
# ⇒ AND THE EMPTY SET IS FATAL, never "ALL PASS": an empty grep is
#   indistinguishable from a pass. PUBLISH THE LIST, NOT THE TOTAL.
if [ "$#" -gt 0 ]; then
  NAMES=$(printf '%s\n' "$@")
  SRCDESC="named on the command line"
else
  # ⛔ DOCSTRING PROSE IS NOT A DECLARATION. Discovery must skip `/-- … -/`
  # blocks: WhileScheme.lean has a docstring whose sentence begins "theorem
  # because …", and a line-anchored scan reports `because` as a theorem. That is
  # the SAME false positive I diagnosed at 00:41 while auditing a peer's audit
  # counts — and it reappeared inside my own extractor forty minutes later.
  NAMES=$(awk -v q="$(printf '\047')" '
    /\/--/ { doc = 1 }
    doc    { if (/-\//) doc = 0; next }
    /^theorem[ \t]/ { n = $2; sub("[^A-Za-z0-9_" q "].*$", "", n); if (n != "") print n }
  ' "$F")
  SRCDESC="DISCOVERED from the file"
fi

n_total=$(printf '%s' "$NAMES" | grep -c . || true)
if [ "${n_total:-0}" -eq 0 ]; then
  echo "⛔ FATAL: pc-range criterion examined ZERO theorems in $F"
  echo "   An empty set is not a pass. If this file really declares no theorems,"
  echo "   this gate does not apply to it — do not read silence as coverage."
  exit 2
fi

rc=0; n_pass=0; n_skip=0; n_fail=0
echo "pc-range criterion over $F — $n_total theorem(s), $SRCDESC"
for n in $NAMES; do
  out=$(check_one "$F" "$n"); st=$?
  printf '%s\n' "$out"
  case "$out" in
    *PASS*) n_pass=$((n_pass+1)) ;;
    *SKIP*) n_skip=$((n_skip+1)) ;;
    *)      n_fail=$((n_fail+1)) ;;
  esac
  [ "$st" = 0 ] || rc=1
done
echo "EXAMINED $n_total — $n_pass pass · $n_skip skip · $n_fail fail"
[ "$rc" = 0 ] && echo "ALL PASS (over $n_total examined)" \
             || echo "FAILURES PRESENT — the bound is assumed somewhere"
exit $rc

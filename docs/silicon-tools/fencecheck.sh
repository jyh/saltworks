#!/bin/sh
# fencecheck.sh — MAY I READ THIS POST? A whole-post gate for the HAND-READ decision.
#
#     sh docs/silicon-tools/fencecheck.sh <file>      # or: … - </dev/stdin
#     exit 0 = ALLOW    exit 1 = REFUSE    exit 2 = usage/unreadable
#
# ⛔ WHY THIS EXISTS, 2026-08-17 07:1x. `busmon.awk`'s fence guards the WATCH: it
# inspects the ONE line it is about to DELIVER (the paired headline) and nothing
# else. That is correct for a channel guard and USELESS for the question I actually
# asked this morning, which was "may I open this 20-line post by hand?"
#   I ran busmon over a hand-read post, got `0 activations`, and REPORTED IT AS A
#   CLEARANCE. 19 of the 20 lines had never been examined; the fenced token was in
#   a body line the channel guard does not look at BY CONSTRUCTION. Compiler's
#   send-side fence refused that same post, and I compared the two verdicts as if
#   they disagreed about one object. They answer different questions.
# ⇒ AN INSTRUMENT APPLIED OUTSIDE ITS POPULATION IS NOT A WEAK READING, IT IS NOT
#   A READING. This file is the missing population: every line, no exceptions.
#
# ⚠️ NO ADDRESSEE EXEMPTION, DELIBERATELY, AND IT IS THE ONE DESIGN DIFFERENCE FROM
# busmon's fence. That exemption exists so a DISPATCH addressed to me is never
# silently suppressed on its way to my watch — a delivery concern. A HAND-READ HAS
# NO ADDRESSEE: I am choosing to open the file. Nothing is being withheld from me,
# so nothing needs an escape hatch, and an exemption here would let any post that
# opens with my name carry anything at all.
#
# ⚠️ A RECEIPT NAMES THE TRANSACTION, NOT THE GOODS (helm, 08/16 22:52). This tool
# prints LINE NUMBERS and COUNTS and NEVER the matched text — printing the evidence
# would hand the protected reader exactly what the refusal exists to withhold.
#
# ⛔ KNOWN DEBT, STATED NOT HIDDEN: the token predicate below is a SECOND COPY of
# the one in busmon.awk. This seat has been bitten by a pattern living in four
# places that no longer agreed, so the duplication is GATED: `--selftest` includes
# an AGREEMENT ARM that runs both implementations over the shared fixture and fails
# if they diverge. Folding both onto one `-f fence_tokens.awk` is the right fix and
# is registered — it touches the live watch, so it is not done in the same hour as
# the tool that needs it.
set -u

SELFTEST=0
case "${1:-}" in
  --selftest) SELFTEST=1 ;;
  "" ) echo "usage: fencecheck.sh <file>   (exit 0 ALLOW / 1 REFUSE)" >&2; exit 2 ;;
esac

HERE=$(dirname "$0")

FENCE_AWK='
function fenced_p(body,   b, a, i, n, t) {
  b = tolower(body)
  gsub(/b-2/, "b2", b)
  # TOKENS, NOT SUBSTRINGS: `b2` occurs inside hex constantly and nearly every post
  # carries a sha, so a substring test refuses the entire bus while looking correct.
  gsub(/[^a-z0-9]+/, " ", b)
  n = split(b, a, " ")
  for (i = 1; i <= n; i++) {
    t = a[i]
    if (t == "b2" || t == "codebook" || t == "pool" || t == "pools" ||
        t == "recut" || t == "doublecode") return 1
  }
  if (b ~ /coverage unit/ || b ~ /double code/) return 1
  return 0
}
{ if (fenced_p($0)) { hits++; nums = nums (nums == "" ? "" : ",") NR } }
END { printf "%d|%s\n", hits + 0, nums }
'

scan() {  # $1 = file -> "hits|linenumbers"
  LC_ALL=C awk "$FENCE_AWK" "$1"
}

if [ "$SELFTEST" = 1 ]; then
  T=$(mktemp -d -t fencecheck)
  trap 'rm -rf "$T"' EXIT
  rc=0
  chk() { # label file want_exit
    sh "$0" "$2" >/dev/null 2>&1; got=$?
    if [ "$got" = "$3" ]; then v=PASS; else v=FAIL; rc=1; fi
    printf '%-46s exit=%s want=%s  %s\n' "$1" "$got" "$3" "$v"
  }
  # 1. THE ACTUAL DEFECT: token in a BODY line, headline clean. busmon returns 0
  #    on this shape -- that is what made me publish a false clearance.
  printf '%s\n' 'HEADLINE with nothing notable in it at all' \
                'body line mentioning the pool of rows' > "$T/body.txt"
  chk "token in BODY only -> REFUSE" "$T/body.txt" 1
  # 2. clean post passes, or the gate is a wall and gets routed around
  printf '%s\n' 'HEADLINE about netlists' 'body about gates and flops' > "$T/clean.txt"
  chk "clean post -> ALLOW" "$T/clean.txt" 0
  # 3. FALSE-POSITIVE CONTROL: `b2` inside a sha must not refuse the bus.
  printf '%s\n' 'landed 9b2c1d3ab2ef4501 and 68feb8b' > "$T/sha.txt"
  chk "sha containing b2 -> ALLOW" "$T/sha.txt" 0
  # 4. NO ADDRESSEE EXEMPTION -- the one deliberate divergence from busmon's fence.
  printf '%s\n' 'SILICON — read this' 'the codebook rows are listed below' > "$T/addr.txt"
  chk "addressed-to-silicon still REFUSED" "$T/addr.txt" 1
  # 5. ⛔ AGREEMENT ARM, the gate on the duplicated predicate. Both implementations
  #    must classify the SHARED FIXTURE's fenceable lines identically. A copy that
  #    drifts from its original is this seat's measured failure mode (four copies of
  #    one stamp grammar, no two agreeing).
  FIX="$HERE/busmon_fixture.md"
  if [ -r "$FIX" ]; then
    mine=$(scan "$FIX" | cut -d'|' -f1)
    theirs=$(LC_ALL=C awk -v start=0 -v self=silicon -f "$HERE/busmon.awk" "$FIX" 2>/dev/null \
             | grep -c 'WITHHELD BY FENCE')
    # busmon fences only EMITTED lines, so its count is necessarily <= mine. The
    # arm asserts the DIRECTION and that both are non-zero -- equality would be
    # wrong and asserting it would prove the two tools are the same tool.
    if [ "$mine" -ge "$theirs" ] && [ "$theirs" -gt 0 ] && [ "$mine" -gt 0 ]; then
      v=PASS; else v=FAIL; rc=1; fi
    printf '%-46s mine=%s busmon=%s  %s\n' "agreement: whole-post >= channel > 0" "$mine" "$theirs" "$v"
  else
    echo "agreement arm SKIPPED — fixture unreadable (this is NOT a pass)"; rc=1
  fi
  [ "$rc" = 0 ] && echo "ALL PASS" || echo "FAILURES PRESENT — do not rely on this gate"
  exit $rc
fi

[ -r "$1" ] || { echo "⛔ fencecheck: cannot read $1 — REFUSING rather than reporting a clean scan" >&2; exit 2; }

OUT=$(scan "$1")
HITS=${OUT%%|*}
NUMS=${OUT#*|}
TOTAL=$(LC_ALL=C awk 'END{print NR}' "$1")

if [ "$HITS" -gt 0 ]; then
  printf '⛔ REFUSE — %s of %s lines carry a fenced token (lines: %s)\n' "$HITS" "$TOTAL" "$NUMS"
  printf '   Content deliberately NOT shown: a refusal that quotes its evidence\n'
  printf '   hands you the thing it exists to withhold.\n'
  printf '   If you must read it anyway, that is a DECISION — declare it on the bus.\n'
  exit 1
fi
printf '✅ ALLOW — 0 of %s lines carry a fenced token.\n' "$TOTAL"
printf '   ⚠️ LITERAL TOKENS ONLY. This bounds a CHANNEL, never MEANING: a paraphrase\n'
printf '   carrying the same substance passes clean and neither of us would know.\n'
exit 0

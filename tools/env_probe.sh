#!/bin/sh
# env_probe — WHAT YOUR SCRIPTS SEE, WHICH IS NOT WHAT YOU SEE. Fleet artifact.
#
#   . tools/env_probe.sh          <- SOURCE IT. Two columns + disagreements.
#   sh tools/env_probe.sh         <- one kind of context only, and it says so
#   sh tools/env_probe.sh --selftest
#
# Answers, BY MEASUREMENT IN THE ENVIRONMENT YOU ARE STANDING IN, whether a
# machine-dependent command or flag works: timeout, grep -P, sed -i, date -d,
# stat -c, base64 -w0, tac, nproc, find -printf, and the rest of the table
# below. Grep this file for a token before you type it.
#
# WHY THIS IS A PROBE AND NOT THE FLAT LIST THAT WAS ASKED FOR (evidence,
# 8/12 10:29 -- "machine facts want a flat, token-keyed list a seat greps BEFORE
# typing"). The list is right about RETRIEVAL and wrong about TRUTH: a list has
# ONE column and the answer has at least THREE. MEASURED on this Mac, 8/12:
#
#     grep -P on a fixture
#       1. seat tool shell (where every seat tests)      rc=0   WORKS
#       2. login interactive shell, bash -lic            rc=2   FAILS
#       3. child script, sh script.sh                    rc=2   FAILS
#
# grep is a FUNCTION in the seat's tool shell. Functions do not cross into a
# child sh, and EVERY MONITOR IN THIS FLEET RUNS AS: sh /path/script.sh
#
# SO THE ENVIRONMENT WE ALL MEASURE IN IS NOT THE ONE OUR INSTRUMENTS RUN IN.
# A seat types grep -P, sees it work, ships it inside a backstop, and the
# backstop gets rc=2 forever.
#
# AND IT RUNS BOTH WAYS -- evidence measured the INVERSE the same hour: the
# wrapper skips .gitignored files, so `grep -rl` returned 0 hits in the shell
# and 106 in a script. The shell is not simply weaker or stronger; it is
# DIFFERENT, and a search validated in one is not validated in the other.
# That case also shows why comparing exit status alone is not enough: both
# contexts returned rc=0 and disagreed on the ANSWER, which is why this tool
# compares captured OUTPUT too and flags that case as ANSWER!. And grep's rc=2 means ERROR -- but every
# "if grep -q" and every "&&" in the tree reads nonzero as NO MATCH. The
# failure is silent, and silent in the reassuring direction.
#
# => A STATIC LIST WRITTEN FROM A SEAT SHELL WOULD HAVE PUBLISHED "grep -P: ok"
#    AND BEEN WRONG FOR EVERY SCRIPT IN THE FLEET. The artifact has to run
#    where the caller is standing, so it is executable and reports its context.
#
# THE ORIGIN OF THE grep FUNCTION IS NOT ESTABLISHED -- it is NOT in the seat's
# shell snapshot (measured: 0 definitions there). No cause is asserted here.
# The finding is the DISAGREEMENT, which is measured, and it stands whatever
# installs the wrapper.
#
# AND THIS FILE IS A LOOKUP YOU MUST REMEMBER TO RUN -- the same defect one
# level up. Evidence had the timeout fact banked on 08/09 and still hit it on
# 08/12, because a fact filed under a MORAL is not retrievable by its TOKEN.
# This file is token-keyed so the grep works, and it exits nonzero so a caller
# can GATE on it instead of a human remembering. A mitigation, not a cure:
# nothing here fires unless something calls it.
#
# STYLE NOTE, PAID FOR: this file uses single-quoted echo lines and a function
# for the table rather than $(cat <<HEREDOC) and backticks inside double quotes.
# The first draft used both and would not parse; a tool that does not run is
# worth less than an ugly one that does.

PROBE_DIR="${TMPDIR:-/tmp}/env_probe.$$"
mkdir -p "$PROBE_DIR" || exit 2
printf 'abc\n' > "$PROBE_DIR/f"
# fixture for the "same rc, different answer" probe: one ignored file, one not
mkdir -p "$PROBE_DIR/gi"
printf 'hidden.txt\n' > "$PROBE_DIR/gi/.gitignore"
printf 'NEEDLE\n'     > "$PROBE_DIR/gi/hidden.txt"
printf 'NEEDLE\n'     > "$PROBE_DIR/gi/shown.txt"
trap 'rm -rf "$PROBE_DIR"' EXIT INT TERM

# ---- THE TABLE ------------------------------------------------------------
# token | what it is | probe (rc 0 = works in the context it is run in)
# The TOKEN column is literally what a seat would type, so a grep for
# "timeout" or for "stat -c" over this file hits. Add rows; one line each.
probe_table() {
cat <<'TABLE'
timeout|run a command under a time limit|command -v timeout
tac|reverse a file's lines|command -v tac
nproc|CPU count|command -v nproc
realpath|resolve to an absolute path|command -v realpath
sha256sum|GNU digest (vs BSD shasum -a 256)|command -v sha256sum
grep -P|Perl regex, for \d \w and lookarounds|grep -P 'a[0-9]*' "$PROBE_DIR/f"
grep -E|CONTROL PROBE: must pass everywhere|grep -E 'a.c' "$PROBE_DIR/f"
grep -r ignore|SAME rc, DIFFERENT ANSWER: does -r skip .gitignore'd files?|grep -rl NEEDLE "$PROBE_DIR/gi"
sed -i|in-place edit, NO suffix arg (BSD eats the next arg)|cp "$PROBE_DIR/f" "$PROBE_DIR/s" && sed -i 's/a/A/' "$PROBE_DIR/s"
date -d|parse a date string|date -d '2026-01-01' '+%Y'
stat -c|GNU stat format (vs BSD stat -f)|stat -c '%s' "$PROBE_DIR/f"
base64 -w0|unwrapped base64|base64 -w0 "$PROBE_DIR/f"
readlink -f|resolve symlinks fully|readlink -f "$PROBE_DIR/f"
xargs -r|do not run on empty input|xargs -r echo < /dev/null
find -printf|GNU find output format|find "$PROBE_DIR/f" -printf '%p\n'
TABLE
}

# ---- sourced or executed? the two measure DIFFERENT "here" contexts --------
# Sourced: "here" is YOUR shell, functions and aliases included. That column
# cannot be produced any other way, and it is the one that lies to you.
# Executed: "here" is already a child, so both columns are the same kind of
# context and the comparison is vacuous. Say so; never print a reassuring match.
SOURCED=0
if [ -n "${BASH_SOURCE:-}" ]; then
  [ "${BASH_SOURCE:-}" != "${0:-}" ] && SOURCED=1
elif [ -n "${ZSH_EVAL_CONTEXT:-}" ]; then
  case "$ZSH_EVAL_CONTEXT" in *:file*) SOURCED=1 ;; esac
fi

if [ "${1:-}" = "--selftest" ]; then
  # NEGATIVE CONTROL. A probe never shown to fire is not a probe. Shadow a
  # token in THIS context only; a child cannot see a shell function, so the
  # tool MUST report a disagreement. Constructed, so it works on any machine --
  # never relying on grep -P happening to disagree on this one.
  echo 'env_probe --selftest: planting a definition visible HERE and not in a child'
  probe_selftest_token() { return 0; }
  h=$(probe_selftest_token >/dev/null 2>&1 && echo ok || echo FAIL)
  c=$(sh -c 'probe_selftest_token' >/dev/null 2>&1 && echo ok || echo FAIL)
  unset -f probe_selftest_token 2>/dev/null || true
  echo "  here=$h  child=$c   (expected here=ok child=FAIL)"
  if [ "$h" = ok ] && [ "$c" = FAIL ]; then
    echo '  SELFTEST PASS -- a planted here-only definition was detected as a'
    echo '  disagreement, so the comparison can tell the two contexts apart.'
    exit 0
  fi
  echo '  SELFTEST FAIL -- the planted disagreement was NOT detected.'
  echo '  DO NOT TRUST A GREEN FROM THIS TOOL.'
  exit 1
fi

echo 'env_probe -- measured now, in the environment you are standing in'
echo "  uname     : $(uname -sr)"
if [ "$SOURCED" = 1 ]; then
  echo '  HERE      : YOUR SHELL (sourced) -- functions and aliases visible'
  echo '  CHILD     : sh -c -- what every monitor and script in this fleet gets'
else
  echo '  HERE      : this script own context (EXECUTED, not sourced)'
  echo '  WARNING: BOTH COLUMNS WOULD BE CHILD CONTEXTS, so the comparison is'
  echo '           STRUCTURALLY DEAD. HERE prints n/a and every row is marked'
  echo '           NOT-CMP -- none of them is a clean result, because none of'
  echo '           them was compared. To measure your own shell, run:'
  echo '             . tools/env_probe.sh'
fi
echo
printf '  %-14s %-6s %-6s %-10s %s\n' TOKEN HERE CHILD '' 'WHAT IT IS'
printf '  %-14s %-6s %-6s %-10s %s\n' -------------- ------ ------ ---------- ----------------------------------

# NO PIPE INTO THE LOOP. "probe_table | while read" runs the loop in a
# SUBSHELL, so every counter set inside it is discarded at the closing done --
# the verdict would be computed and thrown away, and the summary below would
# read a variable that never changed. Redirect from a process substitution is
# not portable to sh, so the table goes to a temp file and the loop reads it in
# THIS shell. The counts the verdict uses are the counts the table printed.
# (Same family as printed-is-not-gated: a status nothing can consume.)
probe_table > "$PROBE_DIR/table"
DISAGREE=0
CTL_CHILD=FAIL
while IFS='|' read -r tok what cmd; do
  [ -n "$tok" ] || continue
  # ⛔ CAPTURE rc BEFORE ANY NORMALISATION, AND KEEP THE PROBE COMMANDS
  # PIPE-FREE. Measured while building this: adding "| sed" to strip the temp
  # path made rc the SED's, not the probe's — `find -printf` went from rc=FAIL
  # to rc=ok in the child and the capability failure vanished from the table.
  # exit-code-dies-in-a-pipe, inside the instrument built to catch silent
  # environment failures. Normalisation happens below, on the captured string.
  h_out=$(eval "$cmd" 2>/dev/null); h_rc=$?
  c_out=$(env PROBE_DIR="$PROBE_DIR" sh -c "$cmd" 2>/dev/null); c_rc=$?
  h_out=$(printf '%s' "$h_out" | sed "s|$PROBE_DIR||g" | sort)
  c_out=$(printf '%s' "$c_out" | sed "s|$PROBE_DIR||g" | sort)
  [ "$h_rc" -eq 0 ] && h=ok || h=FAIL
  [ "$c_rc" -eq 0 ] && c=ok || c=FAIL
  [ "$tok" = 'grep -E' ] && CTL_CHILD=$c
  flag=''
  if [ "$SOURCED" != 1 ]; then
    # ⛔ EXECUTED, NOT SOURCED: both columns are CHILD contexts, so the
    # comparison is STRUCTURALLY DEAD and every row would print "ok ok" with an
    # empty flag -- which reads as MEASURED AND CLEAN. Evidence hit exactly this
    # (8/12 10:47): ran it the natural way, saw their own gitignore case report
    # `ok ok`, no flag. The header said to source it and they read past it.
    # A SILENT SKIP READS EXACTLY LIKE A PASS -- my own D1t S-line law, which I
    # built into that instrument and not into this one. So the HERE column
    # refuses to print a value it did not measure, and EVERY ROW carries the
    # refusal, not just a header line a reader can skip.
    h='n/a'
    flag='NOT-CMP'
  fi
  if [ "$SOURCED" = 1 ]; then
    if [ "$h_rc" != "$c_rc" ] && [ "$h_out" != "$c_out" ]; then flag='DISAGREE*'
    elif [ "$h_rc" != "$c_rc" ];                              then flag='DISAGREE'
    elif [ "$h_out" != "$c_out" ];                            then flag='ANSWER!'
    fi
    [ -n "$flag" ] && DISAGREE=$((DISAGREE + 1))
  fi
  printf '  %-14s %-6s %-6s %-10s %s\n' "$tok" "$h" "$c" "$flag" "$what"
done < "$PROBE_DIR/table"

echo
RC=0
if [ "$CTL_CHILD" != ok ]; then
  echo '  THE CONTROL PROBE (grep -E) FAILED IN THE CHILD CONTEXT. That is a'
  echo '  defect in this measurement, not in your machine. NOTHING ABOVE IS'
  echo '  TRUSTWORTHY -- an instrument whose control fails reports nothing.'
  RC=2
elif [ "$SOURCED" = 1 ] && [ "$DISAGREE" -gt 0 ]; then
  echo "  $DISAGREE TOKEN(S) DISAGREE between your shell and a child script."
  echo '  DISAGREE = different exit status.  ANSWER! = SAME exit status but'
  echo '  DIFFERENT OUTPUT -- the dangerous one, invisible to every rc check.'
  echo '  Use the CHILD column for anything a monitor, cron, hook or CI runs.'
  echo '  THE DIFFERENCE RUNS BOTH WAYS. The shell can be MORE capable (grep -P'
  echo '  here) or LESS revealing (evidence, 8/12: the wrapper skips gitignored'
  echo '  files, so a script saw 106 hits where the shell saw 0). NEITHER'
  echo '  context is the safe one to test in -- test in the one that will RUN.'
  RC=1
elif [ "$SOURCED" = 1 ]; then
  echo '  no disagreements -- your shell and a child script agree on every token.'
else
  echo '  NOTHING WAS COMPARED. The CHILD column is a real measurement and is'
  echo '  the answer for scripts; the HERE column and every flag read NOT-CMP'
  echo '  because this was executed, not sourced. Run:  . tools/env_probe.sh'
fi
echo '  scope: THIS machine, THIS PATH, right now. Not a claim about Linux CI,'
echo '         another seat, or this box after a PATH change.'

# exit would kill the caller's shell when sourced, so return in that case.
if [ "$SOURCED" = 1 ]; then
  return $RC 2>/dev/null || true
else
  exit $RC
fi

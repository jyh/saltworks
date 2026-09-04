#!/bin/bash
# fleet_root_census.sh — do the fleet's HARDCODED ABSOLUTE PATHS still resolve to
# what ORIGIN says they should? A MEASURE, NOT A VIGIL.
#
# Ruled into existence 2026-08-27 19:11:57 (maestro, legislative delegation) as
# QUEUE.md Q2's clause ①, owner evidence: "a census row comparing fleet-root pins
# to origin, so the next rot is ANNOUNCED, not discovered inside a build path."
# Built 2026-09-03 (evidence, row BJ).
#
# ─── WHY, from the rot that produced the ruling ──────────────────────────────
# `~/projects/claude/saltbuild.sh` is a symlink into `~/projects/claude/saltworks`,
# a clone that is DEAD FOR WORK. For a stretch it was stale, and every kernel-witness
# MEAS run took the fleet lock through a wrapper with ZERO queue references against 9
# in the live file — i.e. UNTICKETED, and invisible to the census.
#   🔑 THE CLASS: A TREE CAN BE DEAD FOR WORK AND LIVE AS A TOOL SOURCE, AND A
#      TOMBSTONE THAT SAYS "DO NOT WORK HERE" DOES NOT SAY "DO NOT RESOLVE HERE".
#
# ─── WHAT THIS TOOL DOES DIFFERENTLY FROM wrapper_link_guard.sh ──────────────
# Its sibling `wrapper_link_guard.sh` guards the same object and CANNOT answer this
# question, for two reasons measured (not read) on 2026-09-03:
#
#   (a) ITS REFERENCE COMES FROM ITS OWN LOCATION. Line 28 is
#       `REPO=$(cd "$(dirname "$0")/../.." && pwd)` while its subject (line 29) is an
#       ABSOLUTE path. So its verdict tracks where the script lives, not what the
#       object is. Driven, same object, same minute, two clones of this repo:
#           from seats/evidence/saltworks   EXIT=1  "the symlink points somewhere else"
#           from projects/claude/saltworks  EXIT=0  "OK"
#       The red is FALSE and its remedy text invites a repoint of a load-bearing
#       build path. ⇒ A DIFFERENCE UNDERDETERMINES ITS CAUSE, AND THE DAMAGE IS THE
#       REPAIR THE WRONG CAUSE INVITES, NOT THE REPORT.
#
#   (b) IT COMPARES THE RESOLVED BYTES TO ITS OWN CLONE'S TRACKED FILE. That is
#       CUSTODY, NEVER CONFORMANCE: a clone that is BEHIND ORIGIN carrying a properly
#       committed stale wrapper reads OK — which is EXACTLY the shape of the rot the
#       ruling was written about. The reference must be a THIRD SOURCE: origin.
#
# This tool therefore takes its reference from ORIGIN, re-measured by `ls-remote` on
# every run, and REFUSES rather than silently falling back to a local cache. A
# last-fetched ref is a CACHE OF A MEASUREMENT; a gate must RE-MEASURE.
#
# ─── AND ITS POPULATION IS DISCOVERED, NOT DECLARED ──────────────────────────
# The Q2 row names "the three hardcoded tool paths". Measured at origin/master on
# 2026-09-03 that is right for the saltbuild symlink and WRONG for the class: EIGHT
# MORE executable surfaces hardcode paths resolving into the same clone, two of which
# EXECUTE code out of it. A hand-list is the same defect one level down — repairing
# the instances someone named and marking the class discharged. So the population is
# derived by grepping a REF for the fleet-root prefix, every run, and any new surface
# enters the census the day it is committed.
#
# ─── SCOPE, STATED INSIDE THE VERDICT ────────────────────────────────────────
# IN : executable surfaces (*.sh, *.py) tracked at REF that name an absolute path
#      under FLEET_ROOT, where that path resolves into a git tree.
# OUT: prose occurrences in *.md/*.json/*.tsv (reported as a count, never as a
#      verdict) · paths that resolve outside any git tree (reported UNKNOWN, loudly)
#      · whether the referenced artifact is CORRECT (this tool reads conformance to
#      origin, never fitness).
#
#   ./fleet_root_census.sh              census the live box against origin
#   ./fleet_root_census.sh --self-test  drive the failure arms on scratch trees
#
# exit 0 SOUND — every executable surface resolves to bytes identical to origin
#      1 ROT   — at least one does not; the cause is discriminated, never asserted
#      2 REFUSE — the census could not be taken (no origin, no ref, no population)
set -u

FLEET_ROOT=${FLEET_ROOT:-/Users/jyh/projects/claude}
REF=${REF:-origin/master}
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P) || SCRIPT_DIR=""
REPO=""

say() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }

# ── REFUSALS come before any measurement ────────────────────────────────────────
census_preflight() {
  # ── the population's source repo, resolved HERE so an override reaches it ──────
  # We need SOME clone as a handle to talk to origin. Deriving it from $0 is fine
  # for THIS purpose and fatal for a REFERENCE — so it is disclosed on every run,
  # and everything we compare against is read out of the REMOTE, never out of this
  # clone's worktree. ⛔ This was read at script load once; the self-test's override
  # could not reach it and the refusal arm scored a false rc=1.
  REPO=${CENSUS_REPO:-$SCRIPT_DIR/../..}
  REPO=$(cd "$REPO" 2>/dev/null && pwd -P) || REPO=""
  # ⛔ NOT `[ ... ] && [ ... ] || { refuse; }` — &&/|| has no else, it has a
  #    fallthrough, and the fallthrough is the reassuring branch.
  if [ -z "$REPO" ]; then
    err "fleet_root_census: REFUSING — could not resolve a population-source repo."
    err "  Pass CENSUS_REPO=<a saltworks clone> if this script was copied out of its tree."
    return 2
  fi
  git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || {
    err "fleet_root_census: REFUSING — '$REPO' is not a git working tree."; return 2; }
  [ -d "$FLEET_ROOT" ] || {
    err "fleet_root_census: REFUSING — FLEET_ROOT '$FLEET_ROOT' does not exist."; return 2; }
  return 0
}

# ── discover the population at REF ──────────────────────────────────────────────
# stdout: one "path:line:text" per hit. Prose and code both; the caller classifies.
population() {
  git -C "$REPO" grep -n -F -- "$FLEET_ROOT/" "$REF" 2>/dev/null | sed "s|^$REF:||"
}

# ── extract the absolute path a line names ──────────────────────────────────────
# Deliberately greedy-stops at shell/quote/markdown punctuation. A path we clip
# WRONG resolves to nothing and is reported UNKNOWN — loud, never silently dropped.
extract_path() {
  printf '%s\n' "$1" \
    | grep -o -- "$FLEET_ROOT/[A-Za-z0-9_./-]*" \
    | sed 's/[.,)]*$//' \
    | head -1
}

# ── sha, or nothing. ⛔ THE INCANTATION IS LOAD-BEARING. ────────────────────────
# Bare `git rev-parse <sha>:<path>` on a missing path prints "fatal:" to stderr and
# then ECHOES ITS OWN ARGUMENT TO STDOUT, rc 128. With stderr dropped, the capture
# is a string whose first 12 characters are a perfectly plausible blob sha — so
# every "did it come back empty?" guard passes and the comparison silently becomes
# sha-vs-argument. That is exactly how the first live run of this tool reported
# ROT on seven surfaces that were sound.
#   ⇒ A FAILING COMMAND THAT ECHOES ITS INPUT DEFEATS AN EMPTINESS CHECK. Check the
#     EXIT CODE, and assert the SHAPE of what came back — 40 hex, nothing else.
# `--verify --quiet` returns rc 1 and prints nothing. Driven both ways.
sha40() {
  local _r=$1 _rev=$2 _o
  _o=$(git -C "$_r" rev-parse --verify --quiet "$_rev" 2>/dev/null) || return 1
  case ${#_o} in 40) : ;; *) return 1 ;; esac
  case "$_o" in *[!0-9a-f]*) return 1 ;; esac
  printf '%s\n' "$_o"
}

# ── origin is resolved in a repo WE OWN, never in a tree we are measuring ───────
# The tip must be re-measured (a tracking ref is a local file), but the OBJECTS at
# that tip have to exist somewhere to read a blob out of it. Fetching the tree under
# census would be writing into someone else's clone to answer a question about it.
# So: ls-remote the subject's origin, then resolve inside THIS census's own repo,
# which we may fetch freely — and refuse, loudly, when the subject's remote is one
# we hold no clone of.
CENSUS_FETCHED=0
CENSUS_ORIGIN=""
ensure_census_fetch() {
  case $CENSUS_FETCHED in 1) return 0 ;; esac
  git -C "$REPO" fetch -q origin 2>/dev/null || return 1
  CENSUS_ORIGIN=$(git -C "$REPO" remote get-url origin 2>/dev/null) || CENSUS_ORIGIN=""
  CENSUS_FETCHED=1
  return 0
}

# ── ONE TIP PER TREE PER RUN. ⛔ THIS IS A CORRECTNESS FIX, NOT A CACHE. ────────
# The first working version called ls-remote per SURFACE, and the fleet pushes while
# the census walks: a single run printed origin as 0f9fba9e on one row and ea57e412
# four rows later, for the SAME TREE. Every row was true at its own instant and the
# REPORT was false as a whole — nobody can quote a table whose rows disagree.
#   ⇒ A REPORT IS A SINGLE CLAIM ABOUT A SINGLE MOMENT. If an instrument re-measures
#     per row, its rows are not comparable, and the incoherence is invisible unless
#     two rows happen to straddle a push.
# ⚠️ bash 3.2 on this box has no associative arrays; the memo is a directory.
CENSUS_TIPDIR=""
CENSUS_STAMP=""
tip_cached() {
  local _top=$1 _branch=$2 _key _f _t
  case "$CENSUS_TIPDIR" in
    "") CENSUS_TIPDIR=$(mktemp -d) || return 2
        trap 'rm -rf "$CENSUS_TIPDIR"' EXIT INT TERM HUP ;;
  esac
  _key=$(printf '%s' "$_top" | shasum -a 256 | cut -c1-32)
  _f=$CENSUS_TIPDIR/$_key
  if [ -f "$_f" ]; then cat "$_f"; return 0; fi
  _t=$(remote_tip "$_top" "$_branch") || return 2
  printf '%s\n' "$_t" > "$_f"
  printf '%s\n' "$_t"
}

remote_tip() {
  local _repo=$1 _branch=$2 _out _rc _sha
  _out=$(git -C "$_repo" ls-remote origin "refs/heads/$_branch" 2>&1); _rc=$?
  case $_rc in
    0) : ;;
    *) err "fleet_root_census: ls-remote failed for $_repo (rc=$_rc)"; return 2 ;;
  esac
  _sha=$(printf '%s\n' "$_out" | awk 'NR==1{print $1}')
  case ${#_sha} in
    40) printf '%s\n' "$_sha"; return 0 ;;
    0)  err "fleet_root_census: origin has no refs/heads/$_branch in $_repo"; return 2 ;;
    *)  err "fleet_root_census: ls-remote returned a non-sha for $_branch"; return 2 ;;
  esac
}

# ── the per-path verdict ────────────────────────────────────────────────────────
# Prints: STATUS<TAB>detail. STATUS ∈ SOUND ROT UNKNOWN SCOPE.
# Every branch is enumerated in a `case`. ⛔ NOT `[ x ] && a || b` — that idiom has
# no else, it has a FALLTHROUGH, and the fallthrough is the reassuring branch.
classify_path() {
  local _p=$1 _real _dir _top _rel _branch _tip _head _live _at_origin _at_head
  local _dist _dirty _url _trc

  if [ ! -e "$_p" ]; then
    printf 'ROT\tABSENT — nothing at this path (dangling link, or the tree was deleted)\n'; return; fi

  # ⛔ FOLLOW THE LINK BEFORE ASKING WHICH TREE IT IS IN. `dirname` of a symlink is
  #    the LINK's directory, not the TARGET's — and the subject of this census IS a
  #    symlink into another tree.
  _real=$(readlink -f -- "$_p" 2>/dev/null) || _real=""
  case "$_real" in
    "") _real=$(cd "$(dirname "$_p")" 2>/dev/null && pwd -P)/$(basename "$_p") ;;
  esac

  if [ -d "$_real" ]; then _dir=$_real; else _dir=$(dirname "$_real"); fi
  _top=$(git -C "$_dir" rev-parse --show-toplevel 2>/dev/null)
  case "$_top" in
    "") printf 'SCOPE\tNOT-IN-A-GIT-TREE — resolves outside version control; origin has no opinion on it\n'; return ;;
  esac
  _top=$(cd "$_top" && pwd -P)                 # ⛔ pwd -P: `cd X && pwd` normalises NOTHING

  _branch=$(git -C "$_top" rev-parse --abbrev-ref HEAD 2>/dev/null)
  case "$_branch" in ""|HEAD) _branch=master ;; esac
  _tip=$(tip_cached "$_top" "$_branch"); _trc=$?
  case $_trc in
    0) : ;;
    *) printf 'UNKNOWN\tNO-ORIGIN — could not re-measure origin for %s (%s)\n' "$_top" "$_branch"; return ;;
  esac
  _head=$(sha40 "$_top" HEAD) || _head=""

  _url=$(git -C "$_top" remote get-url origin 2>/dev/null) || _url=""

  # ── A DIRECTORY REFERENCE IS A PIN, NOT A BLOB — AND A PIN IS AN ANNOUNCEMENT,
  #    NOT A VERDICT. Several surfaces name a TREE ROOT (`R=${R:-.../saltworks}`).
  #    "Is this tree at origin's tip" is decidable from ls-remote alone, with NO
  #    objects and NO clone of that remote — so it is ruled on for every tree.
  #    ⛔ IT IS DELIBERATELY *NOT* A ROT. A working clone sitting behind origin is a
  #      seat doing its job; a census that reds on it gets muted within a day, and
  #      then the real rot arrives to an audience of nobody. The Q2 exposure is a
  #      tree nobody OWNS, and ownership is not a thing this tool can measure. So
  #      the pin is PRINTED, every run, and the reading is left to a person.
  if [ -d "$_real" ]; then
    case "$_head" in
      "$_tip") printf 'PIN\tTREE-LEVEL — %s is level with origin %s\n' "$_top" "${_tip:0:8}" ;;
      *)       printf 'PIN\tTREE-BEHIND — %s is at %s, origin %s is elsewhere. Tools reading this tree read those sources, not origin'"'"'s.\n' \
                 "$_top" "${_head:0:8}" "${_tip:0:8}" ;;
    esac
    return
  fi

  _rel=${_real#"$_top"/}
  case "$_rel" in
    "$_real") printf 'UNKNOWN\tCANNOT-RELATIVISE — %s is not under %s\n' "$_real" "$_top"; return ;;
  esac

  _live=$(git -C "$_top" hash-object -- "$_real" 2>/dev/null) || _live=""
  case "$_live" in "") printf 'UNKNOWN\tUNHASHABLE — git could not hash %s\n' "$_real"; return ;; esac
  _at_head=$(sha40 "$_top" "HEAD:$_rel") || _at_head=""

  # ⭐ THE INFERENCE THAT REMOVES MOST REFUSALS, AND IT NEEDS NO FOREIGN OBJECTS:
  #    IF THIS TREE'S HEAD *IS* ORIGIN'S TIP, THEN ORIGIN'S BLOB *IS* HEAD'S BLOB.
  #    Before this, seven live surfaces came back FOREIGN-REMOTE — "not ruled on" —
  #    when six of them were decidable from data already in hand. An honest refusal
  #    is still a refusal, and a census whose largest bucket is UNKNOWN is a census
  #    that has not been taken.
  if [ "$_head" = "$_tip" ]; then
    _at_origin=$_at_head
    _dist=0/0
  else
    ensure_census_fetch || {
      printf 'UNKNOWN\tNO-FETCH — this census repo could not reach its own origin; refusing to guess\n'; return; }
    if [ "$_url" != "$CENSUS_ORIGIN" ]; then
      printf 'UNKNOWN\tFOREIGN-REMOTE-AND-BEHIND — %s (origin %s) is at %s, not origin'"'"'s %s, and this census holds no clone of that remote, so the file cannot be compared. The PIN is the finding; the blob is NOT RULED ON.\n' \
        "$_top" "$_url" "${_head:0:8}" "${_tip:0:8}"; return
    fi
    sha40 "$REPO" "$_tip^{commit}" >/dev/null || {
      printf 'UNKNOWN\tTIP-UNREACHABLE — origin tip %s is not in this census repo even after a fetch\n' "${_tip:0:8}"; return; }
    _at_origin=$(sha40 "$REPO" "$_tip:$_rel") || _at_origin=""
    _dist=$(git -C "$REPO" rev-list --left-right --count "$_head...$_tip" 2>/dev/null | tr '\t' '/')
    case "$_dist" in "") _dist="?/?" ;; esac
  fi

  case "$_at_origin:$_at_head" in
    :) printf 'SCOPE\tNOT-VERSIONED — %s is tracked neither at origin nor in this tree (a runtime artifact: a log, a bus file). Origin has no opinion on it.\n' "$_rel"; return ;;
    :*) printf 'ROT\tGONE-AT-ORIGIN — %s is in this tree'"'"'s HEAD but ABSENT at origin %s (tree=%s). A tool source deleted upstream is still executing here.\n' \
          "$_rel" "${_tip:0:8}" "$_top"; return ;;
  esac

  if [ "$_live" = "$_at_origin" ]; then
    printf 'SOUND\ttree=%s head=%s origin=%s ahead/behind=%s blob=%s\n' \
      "$_top" "${_head:0:8}" "${_tip:0:8}" "$_dist" "${_live:0:12}"
    return
  fi

  # ── DIFFERENT. Now DISCRIMINATE the cause instead of naming one. ──────────────
  # Three sources are in hand — the live bytes, this tree's HEAD, and origin — and
  # which PAIR agrees says which cause it is. Asserting a cause from the difference
  # alone is the defect this tool was built to answer.
  _dirty=no
  git -C "$_top" diff --quiet -- "$_rel" 2>/dev/null || _dirty=yes
  case "$_dirty:$_at_head" in
    yes:*)
      printf 'ROT\tUNCOMMITTED — live bytes differ from origin AND from this tree; nothing records them (tree=%s ahead/behind=%s live=%s origin=%s)\n' \
        "$_top" "$_dist" "${_live:0:12}" "${_at_origin:0:12}" ;;
    no:"$_live")
      case "$_dist" in
        0/0) printf 'ROT\tDIVERGED — clean tree level with origin, yet the bytes differ (tree=%s live=%s origin=%s)\n' \
               "$_top" "${_live:0:12}" "${_at_origin:0:12}" ;;
        *)   printf 'ROT\tSTALE-PIN — clean tree, but its commit is ahead/behind %s of origin and THIS FILE MOVED (tree=%s head=%s origin=%s live=%s vs %s)\n' \
               "$_dist" "$_top" "${_head:0:8}" "${_tip:0:8}" "${_live:0:12}" "${_at_origin:0:12}" ;;
      esac ;;
    *)
      printf 'UNKNOWN\tUNCLASSIFIED — live=%s head=%s origin=%s dirty=%s tree=%s. THE CENSUS COULD NOT NAME THE CAUSE; do not repair on this line.\n' \
        "${_live:0:12}" "${_at_head:0:12}" "${_at_origin:0:12}" "$_dirty" "$_top" ;;
  esac
}

census_run() {
  local _pop _code _prose _sound _rot _unk _scope _pin hit _file _rest _lno _text _path _v _st _de
  census_preflight || return 2

  CENSUS_STAMP=$(date '+%Y-%m-%dT%H:%M:%S%z')
  say "fleet_root_census: FLEET_ROOT=$FLEET_ROOT  REF=$REF  population-source=$REPO"
  say "  taken $CENSUS_STAMP — each tree's origin tip is measured ONCE for this run,"
  say "  so every row below is a claim about the SAME moment."
  say "  (scope: executable *.sh/*.py surfaces tracked at REF. Prose is counted, never judged."
  say "   Reference is ORIGIN, re-measured by ls-remote each run — never this clone's worktree.)"

  _pop=$(population)
  case "$_pop" in
    "") err "fleet_root_census: REFUSING — the population is EMPTY at $REF."
        err "  An empty population is indistinguishable from a broken query. It is never a pass."
        return 2 ;;
  esac

  _code=0; _prose=0; _sound=0; _rot=0; _unk=0; _scope=0; _pin=0
  say ""
  say "── EXECUTABLE SURFACES ─────────────────────────────────────────────────────"
  while IFS= read -r hit; do
    _file=${hit%%:*}
    _rest=${hit#*:}
    _lno=${_rest%%:*}
    _text=${_rest#*:}
    case "$_file" in
      *.sh|*.py) : ;;
      *) _prose=$((_prose+1)); continue ;;
    esac
    _code=$((_code+1))
    _path=$(extract_path "$_text")
    case "$_path" in
      "") say "  UNKNOWN  $_file:$_lno"
          say "           NO-PATH-EXTRACTED — the line names FLEET_ROOT but no path could be clipped"
          _unk=$((_unk+1)); continue ;;
    esac
    _v=$(classify_path "$_path")
    _st=${_v%%	*}
    _de=${_v#*	}
    say "  $_st  $_file:$_lno"
    say "           -> $_path"
    say "           $_de"
    case "$_st" in
      SOUND) _sound=$((_sound+1)) ;;
      ROT)   _rot=$((_rot+1)) ;;
      SCOPE) _scope=$((_scope+1)) ;;
      PIN)   _pin=$((_pin+1)) ;;
      *)     _unk=$((_unk+1)) ;;
    esac
  done <<POP
$_pop
POP

  say ""
  say "── CENSUS ──────────────────────────────────────────────────────────────────"
  say "  executable surfaces examined : $_code   (SOUND $_sound · ROT $_rot · UNKNOWN $_unk · TREE-PIN $_pin · OUT-OF-SCOPE $_scope)"
  say "  prose occurrences counted    : $_prose  (not judged — see scope)"
  say "  OUT-OF-SCOPE means origin has no opinion: a runtime log, the bus, a path"
  say "  outside version control. It is neither a pass nor a finding — it is stated"
  say "  so the examined count and the ruled-on count are never the same number."
  say "  TREE-PIN is ANNOUNCED, never gated: a working clone behind origin is a seat"
  say "  doing its job. The Q2 exposure is a tree nobody OWNS, and this tool cannot"
  say "  measure ownership — so it prints the pin and leaves the reading to a person."
  say "  ⚠️  A .sh/.py hit may be PROSE (a docstring, a usage example). The path verdict"
  say "  is true either way; whether the surface is load-bearing is a human read."


  # ⛔ An UNKNOWN is not a pass. A null result has two readings and they are the same
  #    number: "nothing was wrong" and "I could not see" must not share an exit code.
  # ⛔ PIN and OUT-OF-SCOPE do not gate; ROT and UNKNOWN do. An UNKNOWN is never a
  #    pass: "nothing was wrong" and "I could not see" are the same number, and they
  #    must not share an exit code.
  case "$_rot:$_unk" in
    0:0) say "  ✅ SOUND — every ruled-on executable surface resolves to bytes identical to origin."
         say "     ($_pin tree pin(s) announced above; read them, they are not gated.)"
         return 0 ;;
    0:*) say "  ⛔ NOT A PASS — $_unk surface(s) could not be ruled on. Read them before believing this board."
         return 1 ;;
    *)   say "  ⛔ ROT — $_rot surface(s) differ from origin; $_unk unruled. The cause is printed per surface."
         say "     Read the CAUSE before repairing: a STALE-PIN is not a clobbered link, and the"
         say "     repair for one damages the other."
         return 1 ;;
  esac
}

# ── SELF-TEST ───────────────────────────────────────────────────────────────────
# Drives the classifier against REAL git trees built here. Every arm asserts on the
# ARM UNDER TEST, and every mutation PRINTS THAT IT LANDED — a mutation that did not
# apply reads exactly like one the suite survived.
self_test() {
  local _pass _fail _up _a _b _c _before _after _v _out _rc _e1 _e2 _e3
  _pass=0; _fail=0
  # ⛔ _tmp IS DELIBERATELY GLOBAL AND THAT IS NOT AN OVERSIGHT. It was `local` for
  #    one revision; the trap fires at SCRIPT EXIT, by which time the local is gone,
  #    so under `set -u` cleanup died with "_tmp: unbound variable" — AFTER the
  #    verdict had printed "11 passed". Driven: the pre-`local` run reaped its
  #    directory, the post-`local` run left 456K behind.
  #    ⇒ A REPAIR CAN DISARM A TRAP THAT CLOSES OVER THE NAME IT SCOPES, and the
  #      failure lands after the report, where nobody is looking.
  _tmp=$(mktemp -d) || { err "self-test: no tmpdir"; return 2; }
  trap 'rm -rf "$_tmp"' EXIT INT TERM HUP

  arm() { # arm NAME EXPECTED_STATUS ACTUAL_LINE
    # ⛔ `local` IS LOAD-BEARING HERE, NOT STYLE. These were `_n/_e/_a`, and `_a` is
    #    the self-test's clone-A path: the first arm() call overwrote it, so arms 3
    #    and 4 ran `git -C <a verdict string>` and scored on a tree that never moved.
    #    A clobbered fixture reads exactly like a passing arm.
    local _n=$1 _e=$2 _a=$3 _got
    _got=${_a%%	*}
    if [ "$_got" = "$_e" ]; then
      printf '  ok   %-26s -> %s\n' "$_n" "$_got"; _pass=$((_pass+1))
    else
      printf '  FAIL %-26s -> expected %s got %s\n' "$_n" "$_e" "$_got"
      printf '       %s\n' "$_a"; _fail=$((_fail+1))
    fi
  }

  # A bare upstream + two clones of it: one level, one behind.
  _up=$_tmp/up.git
  git init -q --bare "$_up"
  _a=$_tmp/a
  git -C "$_tmp" clone -q "$_up" a 2>/dev/null
  git -C "$_a" config user.email t@t; git -C "$_a" config user.name t
  mkdir -p "$_a/tools"
  printf 'v1\n' > "$_a/tools/w.sh"
  printf 'stable\n' > "$_a/tools/stable.sh"     # never moves; ARM 4's subject
  git -C "$_a" add tools/w.sh tools/stable.sh; git -C "$_a" commit -qm c1
  git -C "$_a" branch -M master; git -C "$_a" push -q -u origin master

  _b=$_tmp/b
  git -C "$_tmp" clone -q "$_up" b 2>/dev/null      # b is level with origin — THE SUBJECT
  # ⭐ A THIRD CLONE IS THE CENSUS REPO. The tool resolves origin's objects here and
  #    never fetches into `b`, the tree under census — the property the live run
  #    depends on, so the suite must exercise it rather than assume it.
  _c=$_tmp/c
  git -C "$_tmp" clone -q "$_up" c 2>/dev/null
  REPO=$_c; CENSUS_FETCHED=0; CENSUS_ORIGIN=""

  printf '\nfleet_root_census --self-test  (real git trees under %s)\n\n' "$_tmp"

  # ARM 1 — level clone, untouched file: SOUND
  arm "level-clone"        SOUND   "$(classify_path "$_b/tools/w.sh")"

  # ARM 2 — POSITIVE CONTROL FOR THE MUTATION ITSELF. Dirty the file and prove the
  # bytes actually changed before asserting on the verdict.
  _before=$(shasum -a 256 "$_b/tools/w.sh" | cut -d' ' -f1)
  printf 'LOCAL EDIT\n' >> "$_b/tools/w.sh"
  _after=$(shasum -a 256 "$_b/tools/w.sh" | cut -d' ' -f1)
  case "$_before" in
    "$_after") printf '  FAIL mutation(dirty) DID NOT LAND — bytes unchanged; arm 2 would be vacuous\n'
               _fail=$((_fail+1)) ;;
    *) printf '  ..   mutation(dirty) LANDED %s -> %s\n' "${_before:0:8}" "${_after:0:8}"
       arm "dirty-worktree"  ROT   "$(classify_path "$_b/tools/w.sh")" ;;
  esac
  git -C "$_b" checkout -q -- tools/w.sh

  # ARM 3 — THE ROT THIS TOOL EXISTS FOR: a clean clone, properly committed, simply
  # BEHIND, whose file moved at origin. wrapper_link_guard's shape reads this OK.
  printf 'v2\n' > "$_a/tools/w.sh"
  git -C "$_a" commit -qam c2; git -C "$_a" push -q origin master
  _v=$(classify_path "$_b/tools/w.sh")
  case "$_v" in
    *STALE-PIN*) printf '  ok   %-26s -> %s\n' "stale-pin-cause" "named"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> cause not STALE-PIN: %s\n' "stale-pin-cause" "$_v"; _fail=$((_fail+1)) ;;
  esac
  arm "behind-clone-moved-file" ROT "$_v"

  # ARM 4 — ⭐ THE POSITIVE CONTROL, and the arm that decides whether anyone will
  # read this census. The SAME clone, still behind by 2, on a file that did NOT
  # move: SOUND. Without it the suite cannot tell "detects rot" from "reds anything
  # behind", and a census that reds every behind clone gets muted in a week.
  # ⛔ ITS FIRST VERSION WAS VACUOUS AND RED: it censused w.sh, which c2 HAD moved.
  #    The arm's PREMISE was false, not the tool's answer.
  git -C "$_b" fetch -q origin
  arm "behind-but-file-unmoved" SOUND "$(classify_path "$_b/tools/stable.sh")"

  # ARM 5 — absent path
  arm "absent-path"        ROT     "$(classify_path "$_tmp/nope/x.sh")"

  # ARM 6 — outside any git tree
  mkdir -p "$_tmp/plain"; printf 'x\n' > "$_tmp/plain/p.sh"
  arm "not-in-git-tree"    SCOPE   "$(classify_path "$_tmp/plain/p.sh")"

  # ARM 6b — a file INSIDE a tracked tree that git does not track: a runtime log or
  # the bus. Origin has no opinion; it must be OUT OF SCOPE, never a silent SOUND
  # and never a scary UNKNOWN. Seven live surfaces are exactly this shape.
  printf 'log\n' > "$_b/tools/runtime.log"
  arm "untracked-runtime-file" SCOPE "$(classify_path "$_b/tools/runtime.log")"
  rm -f "$_b/tools/runtime.log"

  # ARM 6c — a DIRECTORY reference is a PIN, not a blob. `b` is behind by 2 here.
  _v=$(classify_path "$_b")
  arm "dir-ref-behind"      PIN   "$_v"
  case "$_v" in
    *TREE-BEHIND*) printf '  ok   %-26s -> named\n' "dir-ref-behind-cause"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> %s\n' "dir-ref-behind-cause" "$_v"; _fail=$((_fail+1)) ;;
  esac
  # ⛔ THE LEVEL ARM MUST BE MADE LEVEL FIRST. `c` was cloned at c1 and origin has
  #    moved since, so its first version asserted SOUND on a tree that was behind —
  #    a false expectation, not a false verdict. Bring it level, and PROVE it is.
  git -C "$_c" fetch -q origin && git -C "$_c" merge -q --ff-only origin/master 2>/dev/null
  if [ "$(git -C "$_c" rev-parse HEAD)" = "$(git -C "$_c" rev-parse origin/master)" ]; then
    printf '  ..   fixture(c) IS LEVEL with origin\n'
    _v=$(classify_path "$_c")
    arm "dir-ref-level"     PIN   "$_v"
    case "$_v" in
      *TREE-LEVEL*) printf '  ok   %-26s -> named\n' "dir-ref-level-cause"; _pass=$((_pass+1)) ;;
      *) printf '  FAIL %-26s -> %s\n' "dir-ref-level-cause" "$_v"; _fail=$((_fail+1)) ;;
    esac
  else
    printf '  FAIL fixture(c) COULD NOT BE MADE LEVEL — the arm would be vacuous\n'; _fail=$((_fail+1))
  fi

  # ARM 6d — a tool source deleted upstream is still executing locally.
  git -C "$_a" rm -q tools/stable.sh 2>/dev/null
  git -C "$_a" commit -qm c4; git -C "$_a" push -q origin master
  _v=$(classify_path "$_b/tools/stable.sh")
  case "$_v" in
    *GONE-AT-ORIGIN*) printf '  ok   %-26s -> named\n' "gone-at-origin"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> %s\n' "gone-at-origin" "$_v"; _fail=$((_fail+1)) ;;
  esac
  # ⛔ `git revert -q` IS NOT A FLAG — the first version of this line failed with a
  #    usage dump, the restore never happened, and the NEXT arm inherited a deleted
  #    file and went red for a reason that had nothing to do with it.
  #    ⇒ AN UNCHECKED TEARDOWN IS A MUTATION OF THE NEXT ARM'S FIXTURE.
  git -C "$_a" revert --no-edit HEAD >/dev/null 2>&1
  git -C "$_a" push -q origin master
  git -C "$_c" fetch -q origin
  if [ -f "$_a/tools/stable.sh" ]; then
    printf '  ..   teardown(restore stable.sh) LANDED\n'
  else
    printf '  FAIL teardown(restore stable.sh) DID NOT LAND — following arms are vacuous\n'; _fail=$((_fail+1))
  fi

  # ARM 7 — A SYMLINK is followed to its target, and the verdict is the TARGET's.
  # This is the arm wrapper_link_guard's design makes impossible to state.
  # ⛔ It linked to w.sh, which ARM 3 had just moved at origin — so its ROT was
  #    CORRECT and its expectation was stale. The subject must be the stable file.
  ln -sfn "$_b/tools/stable.sh" "$_tmp/link.sh"
  arm "symlink-follows-target" SOUND "$(classify_path "$_tmp/link.sh")"
  # ARM 7b — and the link must carry its target's ROT too, or it is only ever green.
  ln -sfn "$_b/tools/w.sh" "$_tmp/link-rot.sh"
  arm "symlink-carries-rot"    ROT   "$(classify_path "$_tmp/link-rot.sh")"

  # ARM 8 — path extraction from the REAL line shapes in the tree.
  _e1=$(FLEET_ROOT=/Users/jyh/projects/claude extract_path 'SALTBUILD=/Users/jyh/projects/claude/saltbuild.sh')
  case "$_e1" in
    /Users/jyh/projects/claude/saltbuild.sh) printf '  ok   %-26s -> %s\n' "extract:assignment" "$_e1"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> %s\n' "extract:assignment" "$_e1"; _fail=$((_fail+1)) ;;
  esac
  _e2=$(FLEET_ROOT=/Users/jyh/projects/claude extract_path 'ROOT=${1:-/Users/jyh/projects/claude/saltbuild.sh}')
  case "$_e2" in
    /Users/jyh/projects/claude/saltbuild.sh) printf '  ok   %-26s -> %s\n' "extract:default-expansion" "$_e2"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> %s\n' "extract:default-expansion" "$_e2"; _fail=$((_fail+1)) ;;
  esac
  _e3=$(FLEET_ROOT=/Users/jyh/projects/claude extract_path 'TOOL = "/Users/jyh/projects/claude/saltworks/docs/silicon-tools/fig4_render.py"')
  case "$_e3" in
    /Users/jyh/projects/claude/saltworks/docs/silicon-tools/fig4_render.py) printf '  ok   %-26s -> %s\n' "extract:python-quoted" "$_e3"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> %s\n' "extract:python-quoted" "$_e3"; _fail=$((_fail+1)) ;;
  esac

  # ARM 8b — ⭐ POSITIVE CONTROL FOR THE BUG THAT MADE THE FIRST LIVE RUN LIE.
  # Bare rev-parse ECHOES its argument on failure; sha40 must return NOTHING. If
  # this arm ever goes green on the bare form, seven false ROTs come back.
  _v=$(sha40 "$_c" "HEAD:no/such/path"; echo "rc=$?")
  case "$_v" in
    "rc=1") printf '  ok   %-26s -> empty, rc=1\n' "sha40:missing-path"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> got %s (the arg-echo is back)\n' "sha40:missing-path" "$_v"; _fail=$((_fail+1)) ;;
  esac
  _v=$(git -C "$_c" rev-parse "HEAD:no/such/path" 2>/dev/null)
  case "$_v" in
    "") printf '  ..   %-26s -> this git does NOT echo; the arm still pins sha40\n' "control:bare-rev-parse" ;;
    *)  printf '  ..   %-26s -> bare rev-parse echoed %s — the hazard is live here\n' "control:bare-rev-parse" "${_v:0:20}" ;;
  esac
  _v=$(sha40 "$_c" "HEAD:tools/w.sh"; echo "rc=$?")
  case "$_v" in
    *rc=0) printf '  ok   %-26s -> resolves\n' "sha40:present-path"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> %s\n' "sha40:present-path" "$_v"; _fail=$((_fail+1)) ;;
  esac

  # ARM 9 — THE REFUSAL IS AN ARM. An empty population must never exit 0.
  _out=$(CENSUS_REPO=$_b FLEET_ROOT=$_tmp/absent-root REF=master census_run 2>&1); _rc=$?
  case $_rc in
    2) printf '  ok   %-26s -> REFUSED rc=2\n' "empty-root-refuses"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> rc=%s (an unmeasurable board must not be a pass)\n' "empty-root-refuses" "$_rc"; _fail=$((_fail+1)) ;;
  esac

  # ARM 10 — a non-repo REPO refuses rather than guessing.
  _out=$(CENSUS_REPO=$_tmp/plain census_run 2>&1); _rc=$?
  case $_rc in
    2) printf '  ok   %-26s -> REFUSED rc=2\n' "non-repo-refuses"; _pass=$((_pass+1)) ;;
    *) printf '  FAIL %-26s -> rc=%s\n' "non-repo-refuses" "$_rc"; _fail=$((_fail+1)) ;;
  esac

  printf '\nself-test: %d passed, %d failed\n' "$_pass" "$_fail"
  case $_fail in 0) return 0 ;; *) return 1 ;; esac
}

case "${1:-}" in
  --self-test) self_test; exit $? ;;
  "")          census_run; exit $? ;;
  *)           err "usage: $0 [--self-test]"; exit 2 ;;
esac

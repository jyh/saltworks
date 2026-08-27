#!/bin/sh
# meas_since.sh — run the MEAS gate over every HDL module touched since a BASELINE,
# and get the baseline question right.
#
#   sh docs/silicon-tools/meas_since.sh <baseline-sha>
#
# ⛔⛔ TWO DEFECTS THIS ENCODES, both MEASURED on 2026-08-09, both silent:
#
# (1) THE BASELINE IS THE LAST TIME THE DUTY RAN — NOT MY LAST COMMIT (10:08).
#     I had been diffing `<my last commit>..HEAD`. The moment I landed my own
#     work, my "since" marker jumped FORWARD over a peer's landing my gate had
#     never checked, and the loop printed `to MEAS: none` — which is exactly what
#     a genuinely clean check prints. A seat that both PERFORMS a gate and LANDS
#     its own commits will drift its own baseline every single time it pushes.
#     ⇒ pass the sha of the last MEAS VERDICT, and this script ECHOES the range
#       so the verdict can never be read without its baseline.
#
# (2) A DELETED MODULE IS NOT A MEAS OBLIGATION (12:1x). `git diff --name-only`
#     lists deletions, so retiring a module (council ruling (c) struck
#     `ImmediateScope.lean`) fed a dead path to the gate. `meas_build.sh` REFUSED
#     correctly — "no such file" — but a refusal in the loop reads as a FAILED
#     GATE, and a false alarm on a duty that fires all day is how a real alarm
#     gets ignored. Deletions are reported as RETIRED, separately, and do not
#     touch the exit status.
#
# ⓘ THE HUB-GRAPH LINE, and it is an OBSERVATION not a verdict (see the block at
#   the loop). A module can be kernel-green and still be invisible to `lake build`
#   (`import-owed-means-unbuilt`), so this reads SaltWorks.lean and REPORTS the
#   fact per module — because the day it was omitted I asserted coverage that did
#   not exist, and the day it shouted I reversed a peer's deliberate design.
#   ⛔ THIS COMMENT ITSELF SAID "NOT DONE HERE" WHILE THE CHECK WAS DONE HERE,
#   twelve lines below. Written in one sitting, contradictory in the same file,
#   and found only when I grepped my own script for a warning glyph. Prose about
#   an instrument rots exactly like prose about a measurement.
set -u

BASE="${1:?usage: meas_since.sh <baseline-sha — the sha of your LAST MEAS VERDICT>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
cd "$REPO" || exit 2
SALTBUILD_SH=/Users/jyh/projects/claude/saltbuild.sh
[ -x "$SALTBUILD_SH" ] || { echo "⛔ meas_since: $SALTBUILD_SH not executable"; exit 2; }

git rev-parse --verify "$BASE^{commit}" >/dev/null 2>&1 || {
  echo "⛔ meas_since: '$BASE' is not a commit in this repo — refusing to guess a baseline"
  exit 2
}

# ⛔⛔ RESOLVABILITY IS NOT MEMBERSHIP, AND THE CHECK ABOVE ONLY TESTS THE FIRST.
#    MEASURED 2026-08-24 19:0x, the night of the saltworks message-only history rewrite:
#    the pre-purge MEAS baseline b93cbb5 still RESOLVES (its object survives on the
#    orphaned lineage) but is NOT an ancestor of the new master. This tool ran on it,
#    EXITED 0, and printed a range that differed from the truth — it reported an extra
#    LANDING (b1b51ac) that is not in the real history at all.
#    ⇒ A DANGLING BASELINE DOES NOT ERROR. `git rev-list <dangling>..HEAD` is a perfectly
#      well-defined set; it is just the wrong one, and it OVER-reports, so the failure
#      arrives as extra work rather than as an alarm.
#    ⭐ THE WHOLE FLEET WAS TOLD TO TRANSLATE OLD SHAS VIA THE PURGE MAP. Any seat that
#      pastes an untranslated sha into a RANGE tool gets a confident wrong answer, and
#      this guard is the only thing between that and a mis-scoped duty.
git merge-base --is-ancestor "$BASE" HEAD 2>/dev/null || {
  echo "⛔ meas_since: '$BASE' RESOLVES but is NOT AN ANCESTOR of HEAD — refusing."
  echo "   A baseline outside this branch defines a range on a lineage that is not ours."
  echo "   If saltworks history was rewritten, translate it:"
  echo "     grep -i '^$BASE' seat/fleet/purge-shamap-2026-08-24.tsv   # old<TAB>new"
  exit 3
}

HEAD_SHA=$(git rev-parse --short HEAD)
echo "MEAS range ${BASE}..${HEAD_SHA}   (baseline = last MEAS verdict, NOT last commit)"

# ⭐ THE HUB ROOT IS WATCHED TOO, 2026-08-10 06:2x. THE GAP THAT BOUGHT THIS:
# this gate watched ONLY 'SaltWorks/HDL/*.lean', so a change to SaltWorks.lean was
# INVISIBLE to it -- and a ROOT IMPORT is precisely what decides whether the covering
# build covers a module AT ALL. Proven by the cure to a gap I had just found: SerOrgan
# was in no import chain, its covering build said EXIT=0 over a closure that did not
# contain it, and when 9938951 wired it into the root MY OWN GATE PRINTED "nothing
# touched in SaltWorks/HDL". A module ENTERING THE CLOSURE is a MEAS-relevant event
# exactly as much as a module changing. Reported before the morning brief; fixed here.
rootchg=$(git diff --name-only "$BASE..HEAD" -- 'SaltWorks.lean' | sort -u)
if [ -n "$rootchg" ]; then
  echo "  ⚠️ HUB ROOT CHANGED in this range — SaltWorks.lean:"
  git log --format='     %h %s' "$BASE..HEAD" -- 'SaltWorks.lean' | cut -c1-88
  git diff "$BASE..HEAD" -- 'SaltWorks.lean' | awk '
    /^\+import /{print "     + NOW IN THE CLOSURE: " $2}
    /^-import /{print "     - LEFT THE CLOSURE:   " $2}'
  echo "     ⇒ a covering build over this range covers a DIFFERENT SET of modules"
  echo "       than one before it. A module entering the closure is MEAS-relevant."
fi

# ⛔⛔ SCOPE, AND IT WAS WRONG UNTIL 2026-08-10 20:0x. This line read
#     `-- 'SaltWorks/HDL/*.lean'` — ONE directory, no subdirectories — so a change
#     in Stack/, Silicon/, Tactic/ or any HDL subdir was INVISIBLE TO THE CENSUS
#     and the gate reported NO OBLIGATION for it, in green.
# ⇒ It hid `SaltWorks/Stack/Program.lean` on BOTH landings where that file was a
#   load-bearing consumer (M1+M1a, and the restatement rename). I witnessed it both
#   times only because I hand-diffed CHANGED-vs-WITNESSED — and I twice blamed my
#   own `head -22` truncation in public for what was a STRUCTURAL BLIND SPOT.
#   ***A COMFORTABLE "MY FAULT" CLOSES AN INVESTIGATION AS EFFECTIVELY AS A
#   COMFORTABLE "NOT MY FAULT".*** Self-blame felt like rigour and cost two hours.
changed=$(git diff --name-only "$BASE..HEAD" -- '*.lean' \
          | grep -v '^SaltWorks\.lean$' | grep -v '/Scratch' | grep -v '^Scratch' | sort -u)
[ -n "$changed" ] || { echo "  no .lean changed anywhere since $BASE"; exit 0; }

# ⭐ COVERAGE ASSERTION — the census must not silently under-cover again.
# Every changed .lean is either WITNESSED below or explicitly RETIRED; this prints
# the population up front so the reader can count it against the verdicts.
echo "  CENSUS: $(printf '%s\n' $changed | wc -l | tr -d ' ') changed .lean file(s) in range — each must appear below:"
printf '     · %s\n' $changed

# ⭐ NAME THE LANDING AND ITS OWED COVERING BUILD, 2026-08-09 21:4x.
# COST THAT BOUGHT THIS: math's item ② sat sealed-but-undischarged for TWO AND A
# HALF HOURS because the maestro read my 19:21 verdict as covering their own docs
# commit and never opened it. Their banked fix was a READER-side heuristic -- "a
# MEAS naming BOTH FILES names a landing, go read it". Reader-side heuristics rot:
# they live in one person's head and die at the next relight, which is this seat's
# own [[bus-resident-fixes-die-at-reboot]] pointed at a habit instead of a file.
# The WRITER-side fix is structural and cannot be forgotten -- the verdict now says
# WHOSE landing it covers and that a covering build is owed, in its own output.
for c in $(git log --format=%h --reverse "$BASE..HEAD" -- '*.lean'); do
  echo "  LANDING $c  $(git log -1 --format=%s "$c" | cut -c1-72)"
done
echo "  ⇒ COVERING BUILD OWED TO THE MAESTRO for the landing(s) above."
echo "    A MEAS verdict is a KERNEL witness on ONE FILE at a time; it does NOT"
echo "    seal a landing and never has. Do not read a green below as a seal."

# ── HUB REACHABILITY, computed ONCE ────────────────────────────────────────────
# Transitive closure of `import` from SaltWorks.lean. Built once per sweep rather
# than per module: it is the same graph every time, and re-deriving it 95 times
# would be the cost that tempts someone back to the cheap wrong test.
HUBCLOSURE=$(mktemp) || { echo "meas_since: mktemp failed"; exit 2; }
: > "$HUBCLOSURE"
frontier=$(grep -E '^import [A-Za-z0-9_.]+$' SaltWorks.lean 2>/dev/null | sed 's/^import //')
while [ -n "$frontier" ]; do
  next=""
  for m in $frontier; do
    grep -qxF "$m" "$HUBCLOSURE" && continue
    printf '%s\n' "$m" >> "$HUBCLOSURE"
    mp="$(printf '%s' "$m" | sed 's|\.|/|g').lean"
    [ -f "$mp" ] && next="$next $(grep -E '^import [A-Za-z0-9_.]+$' "$mp" 2>/dev/null | sed 's/^import //')"
  done
  frontier="$next"
done
echo "  hub transitive closure: $(wc -l < "$HUBCLOSURE" | tr -d ' ') modules"
reach_hub() { grep -qxF "$1" "$HUBCLOSURE" && echo yes || echo no; }

# ── IN-RANGE IMPORT OLEANS — THE HOLE THIS SWEEP DIGS FOR ITSELF ───────────────
# ⛔⛔ ADDED 2026-08-26 23:0x, AFTER THE THIRD OCCURRENCE IN THREE CONSECUTIVE
# RANGES (ReqWordSource · MemOrganPlacement · MemWiring). The first two were
# banked as "a landing newer than your last build", which is a story about
# HISTORY — and it is the WRONG MECHANISM. The measurement that refuted it:
#
#   DecoderLines.lean was KERNEL-CHECKED GREEN BY THIS VERY SWEEP (4s, EXIT=0)
#   and its olean DOES NOT EXIST. MemWiring, later in the SAME range, imports it.
#
# ⇒ meas_build's PATH form kernel-checks a target and WRITES NO OLEAN BY DESIGN
#   (its own table says so). A MEAS range is ordered by GIT HISTORY, never by
#   IMPORT DEPENDENCY. So whenever file B in the range imports file A also in the
#   range, A is checked green, no olean is written, and B REDS ON BUILD STATE.
#   ***THE SWEEP MANUFACTURES ITS OWN RED, AND NO AMOUNT OF PRIOR BUILDING
#   PREVENTS IT — the hole is dug DURING the sweep, after any build you ran.***
#
# 🔑 WHY THE OLD FRAMING SURVIVED TWO ROUNDS: "it landed after my last build" is
#   TRUE of the first two instances. A true-but-incidental cause explains the
#   data and predicts the wrong cure (rebuild the world, earlier). The cure that
#   follows from the RIGHT mechanism is local: supply the missing olean, in-loop.
#
# ⚠️ CLASSIFICATION, NOT ABSOLUTION: a build-state red is NOT a discharged
#   obligation. It is reported as its own state and it still fails the sweep —
#   what changes is that it can no longer be read as A PEER'S DEFECT, which is a
#   false accusation this seat came within one post of publishing.
#
# Keyed on a MEASURABLE PROPERTY (does the olean file EXIST) rather than on a
# CATEGORY of the commit ("is it new") — the night's standing form.
missing_import_oleans() {
  _t="$1"; _seen=$(mktemp) || return 0; _out=$(mktemp) || return 0
  : > "$_seen"; : > "$_out"
  _frontier=$(grep -E '^import [A-Za-z0-9_.]+$' "$_t" 2>/dev/null | sed 's/^import //')
  while [ -n "$_frontier" ]; do
    _next=""
    for _m in $_frontier; do
      grep -qxF "$_m" "$_seen" && continue
      printf '%s\n' "$_m" >> "$_seen"
      # Only SaltWorks modules are ours to build; mathlib/std oleans come from the
      # toolchain and a missing one is a DIFFERENT problem this gate must not claim.
      case "$_m" in SaltWorks*) ;; *) continue ;; esac
      _ol=".lake/build/lib/lean/$(printf '%s' "$_m" | sed 's|\.|/|g').olean"
      [ -f "$_ol" ] || printf '%s\n' "$_m" >> "$_out"
      _mp="$(printf '%s' "$_m" | sed 's|\.|/|g').lean"
      [ -f "$_mp" ] && _next="$_next $(grep -E '^import [A-Za-z0-9_.]+$' "$_mp" 2>/dev/null | sed 's/^import //')"
    done
    _frontier="$_next"
  done
  sort -u "$_out"; rm -f "$_seen" "$_out"
}

# Default ON. Set MEAS_NOBUILD=1 to classify-and-skip without building.
MEAS_NOBUILD="${MEAS_NOBUILD:-0}"
buildstate=0

rc=0
for f in $changed; do
  if [ ! -f "$f" ]; then
    echo "  ⓘ RETIRED (deleted, not a gate obligation): $f"
    continue
  fi
  # ── PRE-FLIGHT: supply in-range oleans BEFORE spending the kernel ────────────
  # Reading the WALL TIME was the old advice ("1s is an import failing to
  # resolve, 84s is an elaboration"). That is a diagnosis offered to a human
  # AFTER the fact; this refuses the condition instead.
  miss=$(missing_import_oleans "$f")
  if [ -n "$miss" ]; then
    echo "  ⓘ BUILD STATE for $f — import olean(s) absent BEFORE the kernel ran:"
    for m in $miss; do echo "      · $m"; done
    if [ "$MEAS_NOBUILD" = "1" ]; then
      echo "    MEAS_NOBUILD=1 — not building. This file is NOT discharged."
      buildstate=1
      continue
    fi
    for m in $miss; do
      echo "    ⚙ MODULE form (writes the olean; runs no kernel): $m"
      # ⛔ NEVER PIPE saltbuild.sh — $? after a pipe is the tail's status.
      "$SALTBUILD_SH" "$m" > /dev/null 2>&1
      echo "      saltbuild EXIT=$?"
    done
    miss2=$(missing_import_oleans "$f")
    if [ -n "$miss2" ]; then
      echo "    ⛔ STILL ABSENT after the module form — NOT a kernel verdict and"
      echo "       NOT a peer's defect. This file is UNDISCHARGED build state:"
      for m in $miss2; do echo "        · $m"; done
      buildstate=1
      continue
    fi
    echo "    ✅ oleans supplied — proceeding to the kernel witness."
  fi
  sh "$HERE/meas_build.sh" "$f" || rc=1
  b=$(basename "$f" .lean)
  # ⛔⛔ FIXED 2026-08-11 16:4x — THIS LINE HARDCODED `HDL\.` AND LIED ABOUT EVERY
  # MODULE OUTSIDE THAT NAMESPACE. When SaltWorks/Certs/ landed, the hub imported
  # `SaltWorks.Certs.All` at SaltWorks.lean:8 and this check still printed
  # "not in hub graph" — for BOTH cert files, on a correctly-wired tree.
  # ***It is my own banked gap recurring: the CENSUS was widened past HDL long ago
  # and the HUB-GRAPH TEST was not. A fix that reaches one arm of a tool and not
  # its sibling is the same defect this fleet has hit all day.***
  # ⚠️ AND THE FAILURE DIRECTION WAS THE LOUD ONE: a permanent FALSE "not in hub
  # graph" on every non-HDL landing trains a reader to ignore the line — which is
  # how a real unrooted module would have walked past everyone.
  # Now derives the FULL module name from the path, so it works for any namespace.
  mod=$(printf '%s' "$f" | sed 's|/|.|g; s|\.lean$||')
  root=$(grep -n "^import $mod\$" SaltWorks.lean 2>/dev/null | head -1)
  # ⛔⛔ REACHABILITY, NOT DIRECT MEMBERSHIP — FIXED 2026-08-23, AND THIS IS THE
  # SECOND HALF OF THE 08-11 REPAIR TWELVE LINES ABOVE. That fix widened the
  # NAMESPACE derivation and left the test itself a bare `grep ^import <mod>` of
  # SaltWorks.lean — i.e. DIRECT membership — while the message it prints makes a
  # COVERAGE claim ("a full build does not cover it"). Those are different facts
  # the moment an AGGREGATOR exists: the hub imports `SaltWorks.Certs.All` and
  # that file imports the eight cert modules, so a full build DOES cover them and
  # this gate said it did not.
  # MEASURED on the 08-23 sweep, 95 modules: 10 flagged "not in hub graph",
  # hub transitive closure = 179 modules, GENUINELY unreachable = 1.
  #   ⇒ NINE OF TEN WARNINGS WERE FALSE — 90%.
  # ⚠️ And the harm is the one THIS FILE ALREADY NAMES at the 08-11 comment:
  # "a permanent FALSE 'not in hub graph' trains a reader to ignore the line —
  # which is how a real unrooted module would have walked past everyone."
  # The single TRUE positive today (docs/hdl-tools/reach_census.lean, 0 importers)
  # was sitting in a list of nine false ones, exactly as predicted.
  # ⇒ A FIX THAT REACHES THE INPUT OF A TEST AND NOT ITS PREDICATE LEAVES THE
  #   ORIGINAL DEFECT LIVE UNDER A NEW SPELLING.
  reach=$(reach_hub "$mod")
  # ⛔⛔ THIS LINE IS AN OBSERVATION, NOT A VERDICT — and the demotion is MEASURED.
  # It used to print "⚠️ UNROOTED — invisible to `lake build`", i.e. it called every
  # unrooted module a defect. On 2026-08-09 13:46 that framing cost a peer their
  # design: `AccountMeasure` was unrooted ON PURPOSE (an #eval-only module prints on
  # every fleet build), compiler had SAID SO in core-account §1 two minutes earlier,
  # I flagged it anyway without opening the file, re-raised it, and it was rooted —
  # which then falsified §1's explaining sentence inside a live citation target.
  # 🔑 A CHECK WITH NO LEGITIMATE-NEGATIVE CASE DOES NOT DETECT A DEFECT. It detects
  #   a PROPERTY and calls it one. Whether "not in the hub graph" is wrong is the
  #   AUTHOR's call — this script reports the fact and takes no position.
  if [ -n "$root" ]; then
    echo "     in hub graph: SaltWorks.lean:${root%%:*} (imported DIRECTLY)"
  elif [ "$reach" = "yes" ]; then
    echo "     in hub graph TRANSITIVELY — reached from SaltWorks.lean through an"
    echo "     aggregator, so a full build DOES cover it. Not a direct import."
  else
    echo "     ⚠️ NOT REACHABLE from SaltWorks.lean — a full build does not cover it;"
    echo "     whether that is intended is the module author's call and this gate"
    echo "     takes no position (AccountMeasure was unrooted ON PURPOSE)."
  fi
done

# ⛔ EXIT STATUS IS THREE-VALUED ON PURPOSE. A build-state failure and a kernel
# red are both NOT-GREEN and they are NOT THE SAME FACT: one is my tree, one is
# the code. Collapsing them is what let a build-state red read as a peer's
# defect. rc=1 outranks rc=3 — a real red is never masked by a build-state one.
if [ "$rc" -ne 0 ]; then
  exit "$rc"
elif [ "$buildstate" -ne 0 ]; then
  echo "⛔ SWEEP NOT COMPLETE — build state unresolved (exit 3). No kernel red found."
  exit 3
fi
exit 0

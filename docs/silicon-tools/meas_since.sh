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

# ── SEAT, FOR THE BUILD QUEUE'S CENSUS COLUMN ────────────────────────────────
# ⛔ MEASURED 2026-08-27 19:5x IN THE LIVE CENSUS, not reasoned: my MEAS sweep and a
#   peer's build sat side by side as `math` and `root`. saltbuild derives the seat
#   from ITS OWN resolved path, and $SALTBUILD above is the FLEET-ROOT symlink, which
#   resolves OUTSIDE seats/ — so EVERY seat's MEAS run logs `seat=root`. The council
#   commissioned that column as "the legible build schedule"; a value identical for
#   all three seats is accurate about the invocation and useless about the owner.
# ✅ saltbuild HONOURS AN EXPLICIT SEAT (its path derivation is only the fallback),
#   so the fix belongs in the CALLER and needs no change to the queue or the lock.
# ⛔ RESOLVE THE SYMLINK CHAIN FIRST — this file may itself be reached through one,
#   and `dirname $0` unresolved names the INVOCATION path, not this file's home.
#   That exact defect shipped inert on five seats once already.
if [ -z "${SEAT:-}${SELF:-}" ]; then
  _mb_self=$0
  case $_mb_self in */*) ;; *) _mb_self=./$_mb_self ;; esac
  while [ -L "$_mb_self" ]; do
    _mb_link=$(readlink "$_mb_self")
    case $_mb_link in
      /*) _mb_self=$_mb_link ;;
       *) _mb_self=$(dirname "$_mb_self")/$_mb_link ;;
    esac
  done
  _mb_self=$(cd "$(dirname "$_mb_self")" 2>/dev/null && pwd)/$(basename "$_mb_self")
  case $_mb_self in
    */seats/*/saltworks/*)
      SEAT=${_mb_self#*/seats/}; SEAT=${SEAT%%/*}; export SEAT ;;
    *)
      # ⭐ A SAFE DEGRADATION PATH IS ALSO A SILENT FAILURE PATH: NAME what was looked
      #   at, so a mis-resolved path and a genuinely seatless one are not one observable.
      echo "⚠️ seat NOT derivable from $_mb_self — the queue census will read 'root'" >&2 ;;
  esac
fi

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

# ── FRESHNESS: ASK LAKE ONCE, BEFORE ANY WITNESS ──────────────────────────────
# ⛔⛔ ADDED 08/26 23:5x AFTER NINE REDS THAT WERE ALL BUILD STATE — and after the
# fix I landed three hours earlier reported NOTHING on any of them.
#
# That fix asks "does the olean EXIST". After a rename landing the oleans EXIST and
# are STALE (measured: sources 23:45, oleans 17:45-22:09), so it was blind to the
# entire class. ***EXISTENCE IS NOT CURRENCY*** — this seat's own banked law,
# arriving inside the fix built that same night to honour it.
#
# ⛔⛔ AND THE HEURISTIC I HAD BANKED IS REFUTED, WHICH MATTERS MORE THAN THE HOLE:
# "read the WALL TIME — 1s is an import failing to resolve, 84s is an elaboration"
# HOLDS ONLY FOR AN ABSENT OLEAN. A STALE one elaborates for 44s / 34s / 7s and
# fails with rich, specific, wholly convincing errors: `has already been declared`,
# `Type mismatch`, `unsolved goals`, `depends on sorryAx`. Nine of them, against a
# peer's landing. ***TRUSTING WALL TIME WOULD HAVE PUBLISHED NINE FALSE
# ACCUSATIONS.*** The only thing that discriminated was asking lake:
#     ../saltbuild.sh SaltWorks.HDL.CorePlace -> EXIT=0, 8,617 jobs, theorems tick.
#
# ⇒ SO STOP RE-IMPLEMENTING FRESHNESS. lake owns trace hashes; an mtime comparison
#   beside it is A SECOND IMPLEMENTATION OF A CHECK THAT ALREADY EXISTS, and this
#   fleet's rule tonight is ONE CONSUMER, NOT A SECOND IMPLEMENTATION.
#   ⚠️ Deliberately UNCONDITIONAL: no "only if it looks stale" guard, because such a
#   guard would be exactly the second implementation, and a heuristic that MISSES
#   staleness puts the manufactured reds straight back. It is ONE lock acquisition
#   and a no-op when the tree is current.
echo "  ── FRESHNESS: module form on the hub root, so every witness below runs against"
echo "     CURRENT oleans. lake decides what is stale; this gate does not guess."
"$SALTBUILD_SH" SaltWorks > /dev/null 2>&1
_fresh=$?
echo "     saltbuild SaltWorks EXIT=$_fresh"
if [ "$_fresh" -ne 0 ]; then
  echo "  ⛔ THE COVERING BUILD FAILED — every verdict below would be against an unknown"
  echo "     tree state. That is a BUILD-STATE result, NOT a defect in anyone's landing."
  echo "     Fix the tree first; do not read the reds below as findings."
fi

rc=0
for f in $changed; do
  if [ ! -f "$f" ]; then
    echo "  ⓘ RETIRED (deleted, not a gate obligation): $f"
    continue
  fi
  # ── PRE-FLIGHT: supply in-range oleans BEFORE spending the kernel ────────────
  # ✅ REACHABILITY MEASURED 08/27 01:1x, SO NOBODY DELETES THIS AS DEAD CODE: after the
  # freshness step above became UNCONDITIONAL, the only way an import olean can still be
  # missing is a module OUTSIDE the hub closure — and that population is NOT empty.
  #   hub closure (SaltWorks modules) : 176
  #   SaltWorks .lean on disk         : 320
  #   OUTSIDE the closure             : 144   (Scratch* and friends, all MEAS-censusable)
  # A change to any of those 144 enters the census, is NOT covered by `saltbuild SaltWorks`,
  # and lands here. ***THIS GUARD HAS A REAL POPULATION; it is not made redundant by the hub
  # build.*** [[a-check-never-shown-to-fail]] — I checked whether my own new guard could still
  # fire rather than assuming it, because a guard that cannot fire reads exactly like one that
  # is simply quiet.
  # ⚠️ SCOPE, CORRECTED 08/26 23:5x AND NARROWED BY MEASUREMENT — DO NOT READ THIS
  # BLOCK AS COVERING BUILD STATE GENERALLY. It refuses the ABSENT olean only.
  # It reported NOTHING on nine STALE-olean reds the same night. The freshness step
  # above is what covers those; this remains for its explanatory naming of the
  # in-range self-hole (a file this sweep certified green, whose olean it declined
  # to write) and as a second net if the hub build is skipped.
  # *The sentence here used to read "this refuses the condition instead", which
  # over-claimed the scope of a real fix by exactly one failure class.*
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

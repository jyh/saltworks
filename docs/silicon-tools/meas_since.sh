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

git rev-parse --verify "$BASE^{commit}" >/dev/null 2>&1 || {
  echo "⛔ meas_since: '$BASE' is not a commit in this repo — refusing to guess a baseline"
  exit 2
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

rc=0
for f in $changed; do
  if [ ! -f "$f" ]; then
    echo "  ⓘ RETIRED (deleted, not a gate obligation): $f"
    continue
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
    echo "     in hub graph: SaltWorks.lean:${root%%:*}"
  else
    echo "     not in hub graph (a full build does not cover it; whether that is"
    echo "     intended is the module author's call — this gate takes no position)"
  fi
done
exit $rc

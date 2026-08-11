#!/bin/sh
# meas_build.sh — the SILICON seat's MEAS *KERNEL* pass. One committed copy.
#
#   sh docs/silicon-tools/meas_build.sh SaltWorks/HDL/SortDemo.lean [more.lean ...]
#
# ⛔⛔ WHY THIS FILE EXISTS — I SPENT A WHOLE EVENING VERIFYING NOTHING.
# On 2026-08-08 I ran `saltbuild.sh SaltWorks.HDL.<Module>` after each of
# compiler's landings and published "built green under my hand" six times.
# Compiler's 20:17 census exposed the class; this is the silicon half, measured:
#
#     MODULE form   SaltWorks.HDL.SortDemo    ->  2s · "Replayed" · 0 Built
#     PATH   form   SaltWorks/HDL/SortDemo.lean -> 12s · elaborates the target
#
# ⇒ ***THE MODULE FORM RUNS NO KERNEL WHEN THE OLEAN IS CURRENT. It replays a
#   cache that a PEER's build wrote — so a second seat "confirming" a landing
#   this way is re-reading the first seat's artifact. ONE WITNESS, NOT TWO.***
#   That is [[agreement-is-not-corroboration]] at the artifact layer, and no
#   amount of care at the keyboard prevents it: both forms print EXIT=0.
#
# ⚠️ WHAT A REPLAY *DOES* PROVE, because I over-claimed my own error once today
#   and will not do it twice: lake matched the trace hash, so the olean on disk
#   corresponds to this exact source, and SOME kernel run produced it. The
#   theorems are not unproved. What is absent is INDEPENDENCE — my run added no
#   check of its own. Strike the independence claim, not the green.
#
# ⭐ THE COMPLEMENTARITY, which is the reusable part and which my own bank had
#   only half of ("the path form writes NO olean"):
#
#       form     kernel on target?   olean written?
#       module   NO (when current)   yes (already current)
#       path     YES                 NO (elaborates and discards)
#
#   NEITHER FORM ALONE GIVES BOTH. A landing needs the module form to refresh
#   the artifact and the path form to be independently checked. Use both, and
#   say which one your verdict rests on.
#
# 📌 SCOPE THIS TOOL CLAIMS, stated inside the verdict per [[a-count-is-not-a-scope]]:
#   the TARGET FILE is elaborated by the kernel under this hand, right now.
#   Its IMPORTS are loaded from cached oleans and are NOT re-checked here. That
#   is the correct scope for a MEAS second-witness pass — the imports were
#   checked when they were built — but it must be printed, not assumed.

# ✅ THE POSITIVE CONTROL — re-run it before trusting this tool. A detector that
#   has never failed has not shown that it CAN fail. Scratch*.lean is gitignored,
#   so this pollutes nothing on the shared tree:
#
#     printf 'import SaltWorks.HDL.ISA\ntheorem broken : 1 + 1 = 3 := by sorry\n#audit_axioms broken\n' \
#       > ScratchCONTROL.lean
#     sh docs/silicon-tools/meas_build.sh ScratchCONTROL.lean   # MUST be red, rc=1
#     sh docs/silicon-tools/meas_build.sh SaltWorks.HDL.SortDemo # MUST refuse, rc=2
#     rm ScratchCONTROL.lean
#
#   Both fired as specified on 2026-08-08: EXIT=1 with sorryAx named, and the
#   module-form refusal. The refusal matters more than the red — a red result is
#   loud, whereas the module form's green is the failure that looks like success.

set -u
[ $# -ge 1 ] || { echo "usage: meas_build.sh <path/to/Module.lean> [...]"; exit 2; }

SALTBUILD=/Users/jyh/projects/claude/saltbuild.sh
[ -x "$SALTBUILD" ] || { echo "⛔ meas_build: $SALTBUILD not executable"; exit 2; }
# The retry cap for the differential test below, DERIVED FROM saltbuild's OWN
# DEFAULT rather than hardcoded.
#
# ⛔⛔ WHY IT IS DERIVED (2026-08-09 12:0x, and the defect was LIVE for minutes):
# this line read `HICAP=24000` while saltbuild's default was 12000, so the retry
# meant "try double". Council ruling (d) then RAISED THE DEFAULT TO 24000 —
# correctly, it retires the --cap dance — and my constant silently became EQUAL
# to the default.
#   ⇒ THE DIFFERENTIAL TEST BECAME A NO-OP: on failure it re-ran at the SAME cap,
#     burned a full elaboration, and could never emit its own diagnostic line.
# 🔑 A CONSTANT THAT TRACKS SOMEONE ELSE'S CONSTANT IS A DEFECT WAITING FOR THEM
#   TO EDIT IT. Read the value, do not mirror it — and REFUSE if the relationship
#   the test depends on has stopped holding.
DEFCAP=$(awk -F= '/^CAP=/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$SALTBUILD" 2>/dev/null)
case "$DEFCAP" in ''|*[!0-9]*) DEFCAP=0 ;; esac
if [ "$DEFCAP" -eq 0 ]; then
  echo "⛔ meas_build: cannot read CAP= from $SALTBUILD — refusing to guess the retry cap"
  exit 2
fi
HICAP=${HICAP:-$(( DEFCAP * 2 ))}
if [ "$HICAP" -le "$DEFCAP" ]; then
  echo "⛔ meas_build: HICAP ($HICAP) is not ABOVE saltbuild's default ($DEFCAP)."
  echo "   The differential test would compare a cap against itself and prove nothing."
  exit 2
fi

rc_all=0

for target in "$@"; do
  # ⛔⛔ PIN THE TREE BEFORE ELABORATING — silicon, 2026-08-10 19:3x, a defect I
  # reported against this very file. THIS SCRIPT ELABORATES THE WORKING TREE while
  # `meas_since.sh` labels the verdict with a RANGE END. In the SHARED checkout
  # those are DIFFERENT OBJECTS: a peer commits and the tree moves under the run.
  # On 8/10 my label was true only because math's `747402e` landed FOUR MINUTES
  # after my elaboration — true by TIMING, not by CONSTRUCTION. Had it landed
  # first I would have published "MEAS ON <sha>" over a different tree, silently,
  # green either way. ⇒ Read HEAD before, re-read after, and REFUSE to report a
  # clean verdict if it moved. [[read-tools-inherit-the-shared-tree]]
  head_before=$(git rev-parse --short HEAD 2>/dev/null || echo '?')
  dirty=$(git status --porcelain -- "$target" 2>/dev/null | wc -l | tr -d ' ')

  # ⭐⭐ THE GATE. This is the whole point of the file: the false sentence must be
  # UNREACHABLE, not merely unlikely. A dotted module name cannot be built
  # independently, so it is refused here rather than trusted downstream.
  case "$target" in
    *.lean) ;;
    *)
      echo "⛔ meas_build: '$target' is a MODULE NAME, not a path."
      echo "   The module form REPLAYS a cached olean and runs no kernel — it"
      echo "   cannot serve as an independent witness. Pass the .lean PATH."
      rc_all=2
      continue ;;
  esac
  [ -f "$target" ] || { echo "⛔ meas_build: no such file: $target"; rc_all=2; continue; }

  # ⛔ NEVER PIPE saltbuild.sh — `$?` after a pipe is the tail's status and it
  # fails in the reassuring direction. Capture to a file, judge by the TEXT.
  out=$(mktemp) || { echo "⛔ meas_build: mktemp failed"; exit 2; }
  capnote=""
  attempt=0
  while : ; do
    attempt=$((attempt + 1))
    # ⭐⭐ CUSTODY PIN — three seats edit this tree concurrently, so a verdict that
    # does not name a REVISION names nothing. Measured 8/8 09:4x: a re-run
    # returned EXIT=0 while the source mtime moved from 09:39:46 to 09:42:04 —
    # the file moved UNDER the build and the green was worthless as evidence.
    # ⚠️ This check was MISSING from v1 of this file, which I wrote 20 minutes
    # after amending the memory that prescribes it, and the gap surfaced when
    # compiler landed 169eaf5 into ImmediateScope.lean inside my verify window.
    h1=$(shasum -a 256 "$target" | cut -c1-12)
    # ⛔ SAMPLE CONTENTION *BEFORE* THE WORK. My first attempt sampled at PRINT
    # time — after the elaboration — by which point the competing build has
    # usually exited, so the guard read a quiet machine and stayed silent
    # THROUGH A RUN THAT WENT 4s -> 19s. A guard that measures after the
    # interference is over cannot see the interference. Caught by a deliberate
    # negative control; it would never have fired in service.
    # ⛔ THE BRACKET IS LOAD-BEARING: `[l]ean` matches the string "lean" but NOT
    # the pattern text itself, so this census cannot count THE SHELL RUNNING THE
    # CENSUS. Without it the quiet machine reported "1 peer" and the guard fired
    # on every run — a false alarm on the one line that exists to be trusted.
    # ***THIS IS THE FIRST DEFECT IN THIS SEAT'S BANK AND ITS FOURTH INSTANCE IN
    # ONE NIGHT.*** Knowing a class by heart does not stop you writing it; only a
    # FORM does, and the bracket is the form.
    peers_pre=$(ps -Ao command= | grep -cE '(^|/)([l]ean|[l]ake)( |$)')
    start=$(date +%s)
    "$SALTBUILD" "$target" > "$out" 2>&1
    end=$(date +%s)
    h2=$(shasum -a 256 "$target" | cut -c1-12)
    line=$(grep -E '^saltbuild EXIT=[0-9]+$' "$out" | tail -1)
    # EXIT=75 is the fleet lock timeout, not a result. Retry, do not report.
    case "$line" in
      "saltbuild EXIT=75") [ "$attempt" -lt 5 ] && { sleep 20; continue; } ;;
    esac
    break
  done

  if [ -z "$line" ]; then
    # Silence and success must never share an output. [[the-instrument-carries-its-own-defect]]
    echo "⛔ $target — NO 'saltbuild EXIT=' LINE FOUND. Refusing to report a verdict."
    echo "   (transcript kept: $out)"
    rc_all=2
    continue
  fi

  code=${line#saltbuild EXIT=}
  wall=$((end - start))
  # ⛔ DO NOT report `grep -c Replayed` here as an import count. The first
  # version of this line did, and printed "0 imports replayed" on a green run —
  # a TRUE reading of an ADJACENT OBJECT (the path form prints no Replayed line
  # for silently-loaded oleans) wearing the label of the thing. Every import WAS
  # taken from cache; the correct number is one I can actually measure.
  nimp=$(grep -cE '^import ' "$target")

  # ⭐⭐ THE CAP IS THE INSTRUMENT'S, NOT THE FILE'S — compiler's 20:40 retraction,
  # and it lands squarely on this gate. saltbuild.sh:35 gives the PATH form
  # `-M $CAP` (default 12000 MB); :36 gives the MODULE form no `-M` at all. Since
  # this gate REFUSES the module form, it runs the only capped arm — so on a heavy
  # module it gets EXIT=134 and would report a failure that is the CAP, not the
  # file. That misread is the whole of compiler's real finding: they hit it and
  # concluded the corpus was frozen.
  #
  # ⛔ DO NOT classify this by exit code or by Lean's message text, and do not
  # hardcode the three known-heavy modules (Immediate, Decoder, FabricRoutes) —
  # a fourth appears the moment someone lands one. [[lean-memory-cap-strings]]:
  # CLASSIFY BY DIFFERENTIAL TEST. Re-run at a higher cap; if it passes, the cap
  # was the cause, and that is a fact about the instrument.
  if [ "$code" != "0" ] && [ "$h1" = "$h2" ]; then
    out2=$(mktemp) || { echo "⛔ meas_build: mktemp failed"; exit 2; }
    g1=$(shasum -a 256 "$target" | cut -c1-12)
    "$SALTBUILD" --cap "$HICAP" "$target" > "$out2" 2>&1
    g2=$(shasum -a 256 "$target" | cut -c1-12)
    line2=$(grep -E '^saltbuild EXIT=[0-9]+$' "$out2" | tail -1)
    if [ "$line2" = "saltbuild EXIT=0" ] && [ "$g1" = "$g2" ]; then
      code=0
      capnote=" · needed --cap $HICAP"
      printf 'ℹ  %s — EXIT=%s at the default cap, EXIT=0 at %sMB.\n' "$target" "${line#saltbuild EXIT=}" "$HICAP"
      printf '   ⇒ THE CAP IS THE INSTRUMENT, NOT THE FILE. Not a defect in this module.\n'
    fi
    rm -f "$out2"
  fi

  # The custody pin is judged BEFORE the exit code, because an unattributable
  # green is not a weaker green — it is not evidence at all, and reporting it
  # as green with a footnote is how it gets quoted without the footnote.
  if [ "$h1" != "$h2" ]; then
    printf '⛔ %s — VERDICT NOT ATTRIBUTABLE. The file moved under the build\n' "$target"
    printf '   (%s -> %s). EXIT=%s is real but names no revision — another seat\n' "$h1" "$h2" "$code"
    printf '   landed mid-elaboration. Re-run when the tree is quiet.\n'
    rc_all=1
    continue
  fi

  if [ "$code" = "0" ]; then
    head_after=$(git rev-parse --short HEAD 2>/dev/null || echo '?')
    # ⛔ CONTENTION LABEL, added 2026-08-11 02:5x AFTER I PUBLISHED A CONTENDED
    # WALL AS AN ELABORATION COST. I reported "CompileS now costs 65s, up from
    # 4s" and flagged it as the figure to price the next increment. Compiler
    # could not reproduce it: 4.44/4.44/4.43, and on a quiet machine I got
    # 4.42/4.42/4.52. The 65s was my run QUEUEING BEHIND THEIR 8694-job build —
    # saltbuild takes a cross-seat lock, so a queued run's WALL INCLUDES THE WAIT.
    # ***A QUEUE MEASUREMENT WEARING AN ELABORATION'S NAME.*** It is my own banked
    # law (load-contended timings are worthless; the 8/6 2^12-vs-2^14 inversion)
    # and compiler quoted it back to me from my own bank.
    # 🔑 THIS HARNESS IS DESIGNED TO RUN CONTINUOUSLY, WHICH GUARANTEES IT WILL
    # SOMETIMES MEASURE WHILE A PEER BUILDS. So the number cannot be trusted by
    # default and the LABEL must say so — a form beats a prohibition, and
    # "someone will remember the caveat" is exactly what failed here.
    # Correctness columns are unaffected; only the wall is in question.
    # ⭐ THE THRESHOLD IS 0 ON THE *PRE* SAMPLE, AND THAT IS THE WHOLE TRICK:
    # BEFORE this run starts, this process owns NO lean/lake, so ANY live one
    # belongs to a peer. Measured, not reasoned — a single build shows TWO
    # matches (`lean -M ...` and `lake env lean -M ...`), which is why a
    # threshold tuned on a POST sample was nonsense.
    # ⛔ TWO WRONG VERSIONS PRECEDED THIS, BOTH SILENT THROUGH A 4s->19s RUN:
    #   v1 sampled at PRINT time — the peer had already exited
    #   v2 sampled pre-work but kept a >2 threshold calibrated for post-work
    # Both were caught by a DELIBERATE two-elaboration control, never by use.
    peers=$peers_pre
    if [ "${peers:-0}" -gt 0 ]; then contnote=" ⚠️UNDER CONTENTION (${peers} peer lean/lake at start) — WALL IS NOT AN ELABORATION COST"; else contnote=""; fi
    printf '✅ %s — KERNEL-CHECKED under this hand · %ss wall%s · EXIT=0 @ sha %s%s\n' "$target" "$wall" "$contnote" "$h1" "$capnote"
    if [ "$head_before" = "$head_after" ]; then
      printf '   tree PINNED at %s (re-read after elaboration, unchanged)%s\n' \
        "$head_before" "$([ "$dirty" -gt 0 ] && echo ' ⚠️ target has UNCOMMITTED local changes — the verdict is on the WORKING COPY, not on that commit')"
    else
      printf '   ⛔⛔ THE TREE MOVED MID-RUN: %s -> %s. This verdict names a commit it did NOT elaborate.\n' "$head_before" "$head_after"
      printf '      A peer committed into the shared checkout while the kernel ran. RE-RUN before quoting this.\n'
      rc_all=1
    fi
    printf '   scope: TARGET elaborated fresh by the kernel. Its %s direct imports and\n' "$nimp"
    printf '          their transitive closure came from cached oleans — NOT re-checked here.\n'
  else
    printf '⛔ %s — EXIT=%s · %ss wall%s · NOT green\n' "$target" "$code" "$wall" "$contnote"
    grep -E 'error:' "$out" | head -5
    printf '   (transcript kept: %s)\n' "$out"
    rc_all=1
  fi
  [ "$code" = "0" ] && rm -f "$out"
done

exit "$rc_all"

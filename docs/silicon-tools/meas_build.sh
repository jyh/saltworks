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

rc_all=0

for target in "$@"; do
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
    printf '✅ %s — KERNEL-CHECKED under this hand · %ss · EXIT=0 @ sha %s\n' "$target" "$wall" "$h1"
    printf '   scope: TARGET elaborated fresh by the kernel. Its %s direct imports and\n' "$nimp"
    printf '          their transitive closure came from cached oleans — NOT re-checked here.\n'
  else
    printf '⛔ %s — EXIT=%s · %ss · NOT green\n' "$target" "$code" "$wall"
    grep -E 'error:' "$out" | head -5
    printf '   (transcript kept: %s)\n' "$out"
    rc_all=1
  fi
  [ "$code" = "0" ] && rm -f "$out"
done

exit "$rc_all"

#!/bin/bash
# ============================================================================
# landcheck.sh — closes DEFECT 2 of the shared-tree certification hazard for THIS seat.
#
# THE TWO DEFECTS (silicon raised the class 11:49, separated them 11:54 after reading
# saltbuild.sh:55-58; I found the post-run-stamp mechanism at 11:50):
#
#   DEFECT 1  a peer commits DURING the build.
#             The log's HEAD is captured AFTER the run, so the row attributes the build
#             to a base that landed mid-build. Closed by a pre/post fingerprint INSIDE
#             saltbuild — proposed and TESTED (build-arm-fingerprint-proposal.sh),
#             NOT LANDED: tools/ is outside my scope and five seats build through it.
#
#   DEFECT 2  the tree moves BETWEEN build-end and commit.   ← THIS FILE
#             No build-time check can see it: the exposure BEGINS when the build ENDS.
#             silicon's 07:01 instance and mine are both this one.
#
# ⛔ MY OWN EXPOSURE, MEASURED, WHICH IS WHY THIS EXISTS:
#     06:43:33  build ends (args=SaltWorks.HDL.ISA, EXIT=0)
#     06:43:55  697740b committed — the M5 honesty fence
#   A 22-SECOND WINDOW. Nothing landed in it, so my certification stands — BY WHAT A
#   PEER HAPPENED NOT TO DO, NOT BY METHOD. I had called that sequence "edit-build-commit
#   as ONE step, and it holds". It held; the method did not make it hold.
#
# ⭐ WHY A TOOL AND NOT A HABIT: a rule that must fire AT THE MOMENT OF WRITING cannot
#   live in a memory card — 109 cards and the relevant one does not fire while you are
#   typing. Bank the understanding, GATE the act.
# ============================================================================
set -uo pipefail
# ⛔⛔ 2026-08-27 — THE THIRD INSTANCE OF THIS FILE'S OWN DEFECT SHAPE, AND THE WORST.
#   `R` DEFAULTED TO A HARD-CODED PATH. The 08-25 night migration moved every working
#   seat OUT of that path and left a readable DEAD TWIN behind, carrying its own
#   00-THIS-TREE-IS-A-DEAD-TWIN marker. So an unset `R` made this tool `cd` into a
#   repository the caller is not working in, and fingerprint a tree nobody is
#   committing. MEASURED at the compiler seat 09:10:48 — same command, one env var:
#       default   ARMED at 444458a|474c81c1ce19     <- the dead twin
#       R=$(pwd)  ARMED at fdde237|e3b0c44298fc     <- the tree being committed
#   ⚠️ AND THE READING LOOKED RIGHT: both trees had pulled the same commit that
#   morning, so the HEAD field MATCHED BY COINCIDENCE. A wrong object reported a
#   true value. ⇒ DERIVE THE REPO FROM THE CALLER'S CWD, and REFUSE when there is
#   none — a wrong-repo check and an unarmed check must not look alike.
R=${R:-$(git rev-parse --show-toplevel 2>/dev/null)}
[ -n "$R" ] || {
  echo "landcheck: no R given and the cwd is not inside a git repository — REFUSING."
  echo "  (This used to default to a fixed path and silently measure a different tree.)"
  exit 2; }
cd "$R" || { echo "landcheck: cannot cd $R"; exit 2; }
STATE="${TMPDIR:-/tmp}/landcheck-$(printf '%s' "$R" | shasum -a 256 | cut -c1-12)"

# ⛔ 2026-08-27 — AND THE DIRTY *SET* IS NOT THE DIRTY *CONTENT*. `git status --porcelain`
#   prints ` M path`; editing that same path again leaves the string BYTE-IDENTICAL, so the
#   commonest real sequence — build, tweak the file you are about to commit, commit — was
#   certified CLEAR. DRIVEN, both arms, with exit codes read OUTSIDE a pipe:
#       clean file -> dirty        exit 1  ⛔ MOVED      (the gate works)
#       new untracked path appears exit 1  ⛔ MOVED      (the gate works)
#       CONTENT edit to an already-dirty tracked file    exit 0  ✅ CLEAR   <- THE FALSE GREEN
#   ⇒ the fingerprint gains a CONTENT field. Note the shape: v1 recorded only HEAD, v2 added
#   the dirty SET, v3 adds the dirty CONTENT. Each fix went exactly one level and stopped at
#   the level the author had just been bitten at.
#   ⚠️ DECLARED STOP: `git diff HEAD` covers TRACKED content, staged and unstaged. The CONTENT
#   of a GITIGNORED file (`Scratch*.lean`) is still invisible — such files never appear in
#   `git status --porcelain` at all — so an audit-arm build whose subject is a Scratch file is
#   NOT covered by this gate. Named rather than quietly folded into "the working tree".
# ⛔ 2026-09-03 — v4, AND IT IS THE SAME SHAPE AS v2 AND v3: EACH FIX WENT EXACTLY ONE LEVEL
#   AND STOPPED AT THE LEVEL ITS AUTHOR HAD JUST BEEN BITTEN AT. v3's fields are both
#   INDEX-SENSITIVE — `git status --porcelain` prints `?? p` before `git add` and `A  p` after,
#   and an untracked file does not appear in `git diff HEAD` AT ALL until you add it. So
#   STAGING A NEW FILE, WITH NO EDIT TO ANYTHING, MOVED THE FINGERPRINT. DRIVEN, both arms,
#   exit codes read OUTSIDE a pipe, in a scratch repo:
#       arm -> check, no change whatsoever          exit 0  ✅
#       arm -> `git add` ONE BRAND-NEW file -> check exit 1  ⛔ FALSE MOVED
#   ⚠️ THIS WAS STRUCTURAL, NOT OCCASIONAL. The fleet's own commit form (FLEET ORDER 08/24
#   15:35) is `git add` -> `git diff --cached` -> `git commit`, so the STAGE HAPPENS BEFORE
#   THE CHECK BY LAW: every commit that added a NEW FILE was guaranteed a false MOVED. It fired
#   on this seat's own ShellRun.lean landing and I committed through it.
#   ⇒ THE DAMAGE IS NOT THE NOISE. A false positive reroutes an author SILENTLY — the seat
#   learns to commit through this gate, and then it is inert on the day it is right.
#   ⇒ v4 READS THE WORKING TREE AND NEVER THE INDEX. The changed SET is the union of
#   `git diff --name-only HEAD` and `git ls-files -o --exclude-standard`; a path moves BETWEEN
#   those two lists when you stage it, so the UNION is invariant. The CONTENT is each of those
#   paths' worktree bytes, hashed — also invariant, and it covers a new file's CONTENT, which
#   v3 could not see until it was staged.
#   ⚠️ THE DECLARED STOP IS UNCHANGED AND IS PRESERVED BY `--exclude-standard`: a GITIGNORED
#   file's content (`Scratch*.lean`) is still invisible, so an audit-arm build whose subject is
#   a Scratch file is STILL NOT covered by this gate. Named, not quietly folded in.
fingerprint() {   # HEAD + the changed SET + its worktree CONTENT — all INDEX-INVARIANT
  local paths
  paths=$( { git diff --name-only HEAD 2>/dev/null
             git ls-files -o --exclude-standard 2>/dev/null
           } | LC_ALL=C sort -u )
  printf '%s|%s|%s' \
    "$(git rev-parse --short HEAD 2>/dev/null)" \
    "$(printf '%s\n' "$paths" | shasum -a 256 | cut -c1-12)" \
    "$(printf '%s\n' "$paths" | while IFS= read -r f; do
          [ -n "$f" ] || continue
          if [ -f "$f" ]; then printf '%s %s\n' "$f" "$(shasum -a 256 "$f" | cut -d' ' -f1)"
          else printf '%s ABSENT\n' "$f"; fi
        done | shasum -a 256 | cut -c1-12)"
}

case "${1:-}" in
  --arm)
    # ⛔ 2026-08-15 12:0x — THE FIRST VERSION OF THIS LINE RECORDED ONLY `git rev-parse HEAD`,
    #   AND fingerprint() ABOVE WAS DEAD CODE — defined, documented as "HEAD + the dirty set",
    #   and never called. So the gate detected a peer's COMMIT and was BLIND TO A PEER'S
    #   UNCOMMITTED EDIT, which is what `lake build` actually reads, and which is the DOMINANT
    #   mode in salt (155 dirty lines at 11:52). My four controls moved HEAD three times and
    #   the dirty set ZERO times: I never drove the case the function was written for.
    #   ⇒ WORSE THAN MISSING IT: the code DOCUMENTED a capability it did not have.
    printf '%s %s\n' "$(date '+%s')" "$(fingerprint)" > "$STATE"
    printf '✅ landcheck ARMED at %s (%s)\n' "$(fingerprint)" "$(date '+%H:%M:%S')"
    printf '   Run --check immediately before `git commit`.\n' ;;

  --check)
    if [ ! -f "$STATE" ]; then
      printf '⚠️  landcheck NOT ARMED — no state file. This check is INERT, which is not a pass.\n'
      printf '   (An unarmed check and a clean check print different things ON PURPOSE.)\n'
      exit 3
    fi
    read -r T0 F0 < "$STATE"
    F1=$(fingerprint)
    AGE=$(( $(date '+%s') - T0 ))
    if [ "$F0" != "$F1" ]; then
      H0=${F0%%|*}; T0R=${F0#*|}; D0=${T0R%%|*}; C0=${T0R##*|}
      H1=${F1%%|*}; T1R=${F1#*|}; D1=${T1R%%|*}; C1=${T1R##*|}
      printf '⛔ THE TREE MOVED SINCE YOUR BUILD (%ss ago). Your EXIT=0 certifies a tree that\n' "$AGE"
      printf '   no longer exists. REBUILD before committing -- do NOT reason about whether the\n'
      printf '   change "could" affect yours; that reasoning IS the defect.\n'
      if [ "$H0" != "$H1" ]; then
        printf '   • HEAD MOVED %s -> %s. A peer LANDED:\n' "$H0" "$H1"
        git log --oneline "$H0..$H1" 2>/dev/null | sed 's/^/       /'
      fi
      if [ "$D0" != "$D1" ]; then
        printf '   • WORKING TREE CHANGED (dirty-set %s -> %s) — an UNCOMMITTED edit by any\n' "$D0" "$D1"
        printf '     seat, which is exactly what `lake build` reads. No commit needed to break you.\n'
      fi
      if [ "$C0" != "$C1" ]; then
        printf '   • TRACKED CONTENT CHANGED (%s -> %s) — the SAME files, DIFFERENT bytes. This\n' "$C0" "$C1"
        printf '     is the arm the dirty-set alone could not see, and it is the commonest case:\n'
        printf '     you edited the very file you are about to commit, after the build read it.\n'
      fi
      exit 1
    fi
    printf '✅ landcheck CLEAR: HEAD=%s and the working tree both unmoved across a %ss\n   build->commit window.\n' "${F1%%|*}" "$AGE"
    # ⛔ THIS LINE WAS `[ "$AGE" -gt 900 ] && printf ...` AND IT INVERTED THE GATE.
    #   A narrow window made the test FALSE, the && short-circuited, and the branch's
    #   status became 1 -- so the CLEAN verdict exited NONZERO while the WIDE-WINDOW
    #   warning exited 0. Anyone writing `landcheck --check && git commit` would have
    #   been blocked BY A PASS, and the only run that "worked" was the one with a
    #   warning. Caught by the negative control; the wide-window control alone showed
    #   EXIT=0 and would have shipped it. A gate whose PASS refuses is the over-broad
    #   guard in its purest form -- it gets switched off, and then it protects nothing.
    if [ "$AGE" -gt 900 ]; then
      printf '   ⚠️  %ss is a WIDE window. HEAD is unmoved, but consider whether your build\n      is still describing the tree you are about to commit.\n' "$AGE"
    fi
    exit 0 ;;

  *) printf 'usage: landcheck.sh --arm   (immediately BEFORE the build)\n'
     printf '       landcheck.sh --check (immediately BEFORE git commit)\n'
     printf '\nCloses the build-end -> commit window in a five-seat shared tree.\n'
     printf 'It does NOT close the during-build window -- that needs a change to\n'
     printf 'tools/saltbuild.sh, which is offered on the bus and not mine to land.\n'
     exit 2 ;;
esac

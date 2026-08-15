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
R=${R:-/Users/jyh/projects/claude/saltworks}
cd "$R" || { echo "landcheck: cannot cd $R"; exit 2; }
STATE="${TMPDIR:-/tmp}/landcheck-$(printf '%s' "$R" | shasum -a 256 | cut -c1-12)"

fingerprint() {   # HEAD + the dirty set: the two ways a shared tree moves under you
  printf '%s|%s' \
    "$(git rev-parse --short HEAD 2>/dev/null)" \
    "$(git status --porcelain 2>/dev/null | shasum -a 256 | cut -c1-12)"
}

case "${1:-}" in
  --arm)
    printf '%s %s\n' "$(date '+%s')" "$(git rev-parse --short HEAD)" > "$STATE"
    printf '✅ landcheck ARMED at HEAD=%s (%s)\n' "$(git rev-parse --short HEAD)" "$(date '+%H:%M:%S')"
    printf '   Run --check immediately before `git commit`.\n' ;;

  --check)
    if [ ! -f "$STATE" ]; then
      printf '⚠️  landcheck NOT ARMED — no state file. This check is INERT, which is not a pass.\n'
      printf '   (An unarmed check and a clean check print different things ON PURPOSE.)\n'
      exit 3
    fi
    read -r T0 H0 < "$STATE"
    H1=$(git rev-parse --short HEAD)
    AGE=$(( $(date '+%s') - T0 ))
    if [ "$H0" != "$H1" ]; then
      printf '⛔ HEAD MOVED SINCE YOUR BUILD: armed at %s, now %s (%ss ago).\n' "$H0" "$H1" "$AGE"
      printf '   A peer landed between your build and this commit. Your EXIT=0 certifies a\n'
      printf '   tree that no longer exists. REBUILD before committing -- do not reason about\n'
      printf '   whether their change "could" affect yours; that reasoning is the defect.\n'
      git log --oneline "$H0..$H1" | sed 's/^/     landed: /'
      exit 1
    fi
    printf '✅ landcheck CLEAR: HEAD=%s unmoved across a %ss build->commit window.\n' "$H1" "$AGE"
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

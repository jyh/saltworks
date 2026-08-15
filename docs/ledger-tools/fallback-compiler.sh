#!/bin/bash
# ============================================================================
# fallback-compiler.sh — the compiler seat's CLOCK-DRIVEN liveness heartbeat.
#
# WHY THIS FILE EXISTS AT ALL (2026-08-14 23:3x):
#   silicon published a criterion at 23:24 — "my scripts are durable, but the boot
#   brief named none of them, so a successor would have armed nothing." Running it
#   against my own kit found something worse than the class they named: MY FALLBACK
#   HAD NO SOURCE FILE. silicon has docs/silicon-tools/fallback-silicon.sh, tracked
#   and committed. Mine lived only inside a Monitor definition — I could read its
#   OUTPUT and could not find its SOURCE anywhere on disk. It dies at reboot and a
#   successor arms nothing, however faithfully it has been firing all night.
#   ⇒ A WATCH THAT CANNOT BE RE-ARMED IS A WATCH YOU HAVE ONCE.
#
# ⛔ AND THE DEFECT THAT PROMPTED IT — A STALE OWNERSHIP GLOB, MACHINE-EMITTED:
#   rev3 printed `my-landing=ef50705 (glob: HDL,Certs,docs/compiler-*,docs/post-integrity-*)`
#   at 23:29. My actual last landing was 14bc8b4 at 23:20 — the glob EXCLUDES
#   docs/ledger-tools/, where all THREE of tonight's landings went (444c7b9, 69b5c8a,
#   14bc8b4). It under-reported by 78 minutes and three commits, and it did not error:
#   every field it printed was TRUE about the wrong population.
#   THE ONLY REASON I CAUGHT IT is that I happened to know my own last sha. That is
#   not an instrument, that is luck — so this rev prints the DRIFT rather than
#   relying on a reader to notice.
#
# ⛔ SHARED-WORKTREE TRAP, and I walked into it while diagnosing this:
#   five seats commit as ONE git author. `git log --oneline` cannot tell you whose
#   landing is whose — I read silicon's 8c5ee81 and cb0144b as mine for a full minute
#   because the subject lines were about a fallback. OWNERSHIP IS BY PATH, NEVER BY
#   AUTHOR, and that is exactly why the glob below has to be right.
# ============================================================================
set -uo pipefail
R=${R:-/Users/jyh/projects/claude/saltworks}
cd "$R" || { echo "FALLBACK-COMPILER: cannot cd $R"; exit 2; }

# The ownership glob. KEEP THIS BESIDE THE LANDINGS IT MUST SEE — the whole defect
# was a glob that stopped tracking where the work moved.
MINE=(HDL Certs docs/ledger-tools 'docs/compiler-*' 'docs/post-integrity-*')
# FALLBACK_SCOPE exists so the DRIFT ARM can be DRIVEN. Without it the arm is dead
# code whenever my landing happens to be the newest commit -- which is exactly the
# state it was in when I wrote it, i.e. it would have shipped unexercised.
[ -n "${FALLBACK_SCOPE:-}" ] && read -r -a MINE <<< "$FALLBACK_SCOPE"

MYL=$(git log --oneline -1 --format=%h -- "${MINE[@]}" 2>/dev/null)
ANY=$(git log --oneline -1 --format=%h 2>/dev/null)
DIRTY=$(git status --porcelain -- "${MINE[@]}" 2>/dev/null | grep -c . || true)
UNPUSH=$(git rev-list --count origin/master..master 2>/dev/null || echo '?')
STAMP=$(date '+%m/%d %H:%M:%S')

printf 'FALLBACK-COMPILER %s · my-landing=%s · last-touch-any-seat=%s · MY-dirty=%s · unpushed=%s\n' \
  "$STAMP" "$MYL" "$ANY" "$DIRTY" "$UNPUSH"
printf '  scope: %s\n' "${MINE[*]}"

# ── THE DRIFT ARM: the thing rev3 could not do. If commits have landed since MY
#    last one, say HOW MANY and IN WHICH PATHS. A silent under-report is the failure
#    mode; a visible gap is a fact. This also catches the glob going stale AGAIN,
#    because work that moves to a new directory shows up here as unattributed drift.
if [ -n "$MYL" ] && [ "$MYL" != "$ANY" ]; then
  N=$(git rev-list --count "$MYL..$ANY" 2>/dev/null || echo '?')
  printf '  drift: %s commit(s) since my last landing. Paths touched by them:\n' "$N"
  git diff --name-only "$MYL..$ANY" 2>/dev/null | sed 's|/[^/]*$||' | sort -u | sed 's/^/    /'
  printf '  ⚠️  any path above that is MINE and not in scope means THIS GLOB IS STALE.\n'
fi

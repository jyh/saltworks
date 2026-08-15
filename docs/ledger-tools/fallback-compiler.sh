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
#   OUTPUT and could not find its SOURCE anywhere on disk, so a successor arms nothing,
#   however faithfully it has been firing all night.
#   ⇒ A WATCH THAT CANNOT BE RE-ARMED IS A WATCH YOU HAVE ONCE.
#   ⚠️ THIS COMMENT SAID "it dies at reboot" WHEN IT LANDED. WITHDRAWN 23:4x AS UNTESTED --
#      I never rebooted anything. What IS measured points the other way: task b3ki008vg,
#      armed by session b2d20534 on Aug 12 18:21, was still firing Aug 14 23:37. A WATCH
#      OUTLIVES ITS SESSION BY DAYS. The claim needing no test is that there is NO SOURCE.
#      I withdrew this in the boot brief first and left it standing HERE for four minutes --
#      a fix lands where the pain was felt, and the sibling surface has not hurt yet.
#   ⛔ AND THERE IS NO WAY TO ENUMERATE WHAT THIS SEAT HAS ARMED. TaskList is the TODO
#      registry and returns "No tasks found". Two fallbacks were running at 23:39 --
#      bztnx4tzg (this session) and the b3ki008vg orphan -- and I found out only by reading
#      two task-ids in notification headers. A WATCH YOU CANNOT ENUMERATE IS A WATCH YOU
#      CANNOT RETIRE. I left the orphan running deliberately: it delivers, and silicon lost
#      a cadence alarm the same night to their own cleanup command.
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
# ⛔ 2026-08-15 07:0x — `HDL` and `Certs` MATCHED NOTHING. The real paths are SaltWorks/HDL
#   and SaltWorks/Certs; the bare names are git pathspecs against the repo ROOT and have been
#   INERT since I inherited this glob from rev3. I "corrected" the glob at 351ae5c by ADDING
#   docs/ledger-tools and never checked the entries already there — the exact defect banked at
#   02:3x (a structural repair is a RELOCATION; inventory the space before rearranging it).
#   My 23:3x differential "proved" the fix by moving the verdict — but it only ever exercised
#   the entry I had just added. THE OTHER TWO WERE NEVER TESTED because I had not landed in
#   SaltWorks/HDL all night. The drift arm caught it at 07:00 on first exposure.
MINE=(SaltWorks/HDL SaltWorks/Certs docs/ledger-tools 'docs/compiler-*' 'docs/post-integrity-*')
# FALLBACK_SCOPE exists so the DRIFT ARM can be DRIVEN. Without it the arm is dead
# code whenever my landing happens to be the newest commit -- which is exactly the
# state it was in when I wrote it, i.e. it would have shipped unexercised.
[ -n "${FALLBACK_SCOPE:-}" ] && read -r -a MINE <<< "$FALLBACK_SCOPE"

MYL=$(git log --oneline -1 --format=%h -- "${MINE[@]}" 2>/dev/null)
ANY=$(git log --oneline -1 --format=%h 2>/dev/null)
DIRTY=$(git status --porcelain -- "${MINE[@]}" 2>/dev/null | grep -c . || true)
# ⛔ 2026-08-15 06:0x — THIS IS A CACHE READ AND THE LABEL NOW SAYS SO. `origin/master` is a
#   LOCAL ref; without a fetch this answers "unpushed since my last fetch", not "unpushed".
#   I quoted the unlabelled version ~50 times tonight before a peer's real-fetch beat exposed it
#   (banked: tracking-ref-is-a-local-cache). NOT adding a fetch here on purpose: a 30-minute
#   heartbeat must not acquire a network dependency that can hang or fail and take the liveness
#   signal with it. An honest label costs nothing and cannot break the watch.
UNPUSH=$(git rev-list --count origin/master..master 2>/dev/null || echo '?')
STAMP=$(date '+%m/%d %H:%M:%S')

# ⛔ 2026-08-15 10:0x — `unpushed` here is REPO-WIDE, not mine: five seats commit to this tree,
#   so the count aggregates theirs with mine. Labelled rather than scoped, because "is anything
#   unpushed in the shared tree" IS the useful heartbeat fact — but it must not wear my name.
#   Same defect I corrected in my own close-line at 09:5x; this is the sibling surface.
printf 'FALLBACK-COMPILER %s · my-landing=%s · last-touch-any-seat=%s · MY-dirty=%s · unpushed=%s(REPO-WIDE, cached, no fetch)\n' \
  "$STAMP" "$MYL" "$ANY" "$DIRTY" "$UNPUSH"
printf '  scope: %s\n' "${MINE[*]}"

# ── DEAD-ENTRY ARM: a scope entry matching NOTHING is silently inert, and an inert entry
#    looks identical to a quiet one. Two of mine were dead for a day. Announce them.
DEAD=""
for pat in "${MINE[@]}"; do
  [ -z "$(git log -1 --format=%h -- "$pat" 2>/dev/null)" ] && DEAD="$DEAD $pat"
done
# ⚠️ 2026-08-15 10:4x — FALSE-DEAD CASE, named because a peer's anchored `ps` pattern returned a
#   FALSE ZERO and nearly had them announce a live watch dead. Mine has the same shape: this arm
#   says DEAD on "matches no commit", so a LEGITIMATE path with no commits YET reads as inert.
#   Checked 10:4x — all five entries have both commits and on-disk paths, so no false-dead today.
#   The arm now prints whether the path EXISTS, which distinguishes "wrong pathspec" (the real
#   defect, HDL vs SaltWorks/HDL) from "right path, no history yet".
if [ -n "$DEAD" ]; then
  printf '  ⛔ DEAD SCOPE ENTRIES (match no commit):%s\n' "$DEAD"
  for d in $DEAD; do
    n=$(ls -d $d 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -gt 0 ] && printf '     ⚠️  %s EXISTS on disk (%s path(s)) — likely NO HISTORY YET, not a wrong pathspec\n' "$d" "$n"
  done
fi

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

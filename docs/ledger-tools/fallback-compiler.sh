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
# ⛔ 2026-08-15 15:3x — THIRD STALENESS, AND THE DRIFT ARM CAUGHT THIS ONE ITSELF.
#   I landed `tools/saltbuild.sh` at b380623 (helm-authorized) and the fallback reported
#   my-landing=9b06fba with last-touch-any-seat=b380623 — MY OWN COMMIT SHOWING AS SOMEBODY'S
#   TOUCH, because `tools/` was not in the glob. The arm printed exactly the line it exists to
#   print: "paths touched: tools ⚠️ any path above that is MINE and not in scope means THIS
#   GLOB IS STALE." First time this defect was caught BY THE INSTRUMENT rather than by luck
#   (07:00) or by my happening to know my own sha (23:29).
# ⚠️ NARROW, NOT `tools/`: that directory is FLEET INFRASTRUCTURE AT THE HELM'S CUSTODY. I am
#   authorized in ONE file there, so only that file is claimed. Adding the directory would make
#   every other seat's tools/ landing read as mine — the ownership-by-path law running backwards.
#   Residual, stated rather than solved: if the helm edits saltbuild.sh, my-landing will wrongly
#   read as mine until someone notices. A heuristic field with a known false-attribution case.
# ⛔ 2026-08-15 22:3x — SaltWorks.lean ADDED, closing the OTHER HALF of a release
#   condition I had already half-executed. The condition (item 9, 13:04) said: add
#   SaltWorks.lean to EVERY arm AND add docs/ledger-tools. I added docs/ledger-tools
#   at 07:0x -- the half that had just bitten me -- and left SaltWorks.lean for 15h.
#   A FIX LANDS WHERE THE PAIN WAS FELT; the sibling half waits for its own incident.
# ⇒ WHY IT MATTERS: registering a new module touches ONLY SaltWorks.lean, so such a
#   commit did not move my-landing and the liveness line reported the PREVIOUS sha as
#   my latest landing -- machine-generated and wrong. That is the banked law
#   import-owed-means-unbuilt pointed at the instrument that reports my landings.
# ⚖️ AND THE COST OF THIS ADDITION, STATED: SaltWorks.lean is SHARED -- every seat
#   registers its modules there. So a PEER's registration now moves `my-landing`.
#   I am taking that trade deliberately: the false NEGATIVE it fixes hid MY OWN
#   landing of the ratified codebook amendment, while the false POSITIVE it widens
#   was already structural -- seat authorship is NOT recoverable from git (all five
#   seats commit as one author), so NO pathspec can make `my-landing` mean `mine`.
# ⇒ THE FIELD IS HONESTLY 'last touch in my paths'. The remaining half of the
#   release condition is the RELABEL, and it is still owed.
MINE=(SaltWorks/HDL SaltWorks/Certs SaltWorks.lean docs/ledger-tools 'docs/compiler-*' 'docs/post-integrity-*' 'docs/hdl-*' 'docs/hdl-tools/*' tools/saltbuild.sh)
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
# ⚖️ THE LABELS CARRY THEIR SCOPE INLINE, and the NAMES were deliberately NOT changed:
#   `my-landing` and `MY-dirty` are referenced 9 times in the boot brief and in
#   docs/compiler-liveness-arm-scope-0814.md. Renaming the identifier would falsify
#   every one of those mentions silently -- a format change is an edit to everything
#   that described the old format. So the IDENTIFIER stays and the CLAIM is narrowed
#   where it is read. Nothing parses these labels (checked); only this printf emits them.
# ⇒ WHAT THE SCOPES ACTUALLY ARE: seat authorship is NOT recoverable from git (all five
#   seats commit as one author), so `my-landing` can never mean `mine` -- it is the last
#   commit touching MY PATHSPEC, by ANY seat. Same for MY-dirty.
# ⛔ AND I NEARLY SHIPPED A FALSE LABEL WHILE FIXING LABELS: I first wrote MY-dirty as
#   `tracked-only`, from the boot brief's account of this arm. THE COMMAND AT LINE 94 IS
#   `git status --porcelain -- <paths>` WITH NO --untracked-files=no, and porcelain shows
#   untracked BY DEFAULT. Proven by probe: dropping one untracked file into docs/ledger-tools
#   moved the count 1 -> 2. THE LABEL MUST BE VERIFIED AGAINST THE COMMAND, NEVER AGAINST
#   THE DOCUMENTATION OF THE COMMAND -- which is how the original wrong label got there.
# ⇒ CLOCK-TRIGGERED INWARD CHECK (08/15 23:3x): selfstale.sh re-measures the figures my
#   own brief asserts ABOUT ITSELF. Called from here because this script is already
#   clock-driven -- SUBJECT = my own output, TRIGGER = a clock and not a colleague,
#   which is the pair the 08/15 tally showed I was missing. No new watch to enumerate.
#   ⛔ 08/17 16:0x — THIS LINE USED TO READ `selfstale.sh 2>/dev/null` AND THAT MADE THE
#   INWARD CHECK VANISH SILENTLY. selfstale resolves its brief from SEAT_DIR and REFUSES
#   (stderr, exit 1) when it is unset -- a refusal I built on purpose. Swallowing stderr
#   turned that refusal into an EMPTY $SS, and the `[ -n "$SS" ]` test then printed
#   nothing, which is the exact rendering of "no staleness found". MEASURED, not reasoned:
#   with a REAL falsified figure on disk, SEAT_DIR set -> 1 SELF-STALE line; SEAT_DIR unset
#   -> 0 lines. The clock-triggered arm was one unset variable away from being decorative,
#   and nothing in its output would ever have said so.
SSERR=$(mktemp); SS=$(bash "$(dirname "$0")/selfstale.sh" 2>"$SSERR"); SSRC=$?
[ -n "$SS" ] && printf '%s\n' "$SS"
if [ "$SSRC" != 0 ] || [ -s "$SSERR" ]; then
  printf '  ⛔ INWARD CHECK DID NOT RUN (exit %s): %s\n' "$SSRC" "$(head -1 "$SSERR")"
  printf '     A check that did not run must NOT look like a check that passed. Set SEAT_DIR + CLAUDE_MEMORY_DIR.\n'
fi
rm -f "$SSERR"
printf 'FALLBACK-COMPILER %s · my-landing=%s(my-paths,ANY-seat) · last-touch-any-seat=%s · MY-dirty=%s(my-paths,incl-untracked) · unpushed=%s(REPO-WIDE, cached, no fetch)\n' \
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

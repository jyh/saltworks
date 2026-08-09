#!/bin/sh
# wrapper_link_guard.sh — is `../saltbuild.sh` still the VERSIONED wrapper, or a stale copy?
#
# SUPERSEDES wrapper_restore_point.sh (compiler, 2026-08-09, retired ~30 min after landing).
# ----------------------------------------------------------------------------------------
# That tool guarded a real defect: the wrapper lived at the unversioned portfolio root and was
# tracked nowhere (4 of 6 distinctive code lines existed in NO tracked file). The maestro fixed
# it properly at a522403 — the wrapper now lives at saltworks/tools/saltbuild.sh under version
# control, and the root path is a SYMLINK, so every seat's `../saltbuild.sh` resolves unchanged.
#
# THAT FIX RETIRED MY GUARD, AND LEAVING IT WOULD HAVE MADE IT A LIABILITY: a byte-snapshot in
# docs/ledger-tools became a SECOND copy of a file that now has a history, in the SAME repo — so
# the two would be lost together (no recovery value) while drifting apart (a false DRIFT alarm
# against a properly versioned file). A guard whose premise expired does not go quiet; it starts
# lying. The snapshot is deleted; git history holds it if anyone wants those bytes.
#
# THE NEW HAZARD IS QUIETER THAN THE OLD ONE, which is why this replaces rather than removes.
# A symlink can be clobbered by an ordinary `cp` or an editor that writes through it as a new
# file. Then: the versioned wrapper still looks right, a seat edits tools/saltbuild.sh, commits,
# pushes — and every build keeps running the STALE bytes at the root. Nothing announces it. The
# edit is in git, the behavior is not. Same shape as the defect this whole thread began with:
# every instrument telling the truth about a different question.
#
#   ./wrapper_link_guard.sh          check the real root path
#   ./wrapper_link_guard.sh <path>   check an alternate path (TESTING ONLY)
# exit 0 link healthy · 1 clobbered or mismatched · 2 refuse (cannot determine)
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
ROOT=${1:-/Users/jyh/projects/claude/saltbuild.sh}
TRACKED="$REPO/tools/saltbuild.sh"

# Scope inside the verdict: this tool takes a path argument, so it can be pointed at the wrong
# object and report green about it. Print what was actually examined, every run.
echo "wrapper_link_guard: checking root=$ROOT  tracked=$TRACKED"

[ -e "$ROOT" ] || { echo "wrapper_link_guard: REFUSING — nothing at $ROOT (dangling or absent)." >&2; exit 2; }
[ -f "$TRACKED" ] || { echo "wrapper_link_guard: REFUSING — no versioned wrapper at $TRACKED." >&2; exit 2; }

if ! git -C "$REPO" ls-files --error-unmatch tools/saltbuild.sh >/dev/null 2>&1; then
  echo "wrapper_link_guard: ⛔ the wrapper at $TRACKED is NOT TRACKED." >&2
  echo "  The whole point of the move was to give it a history. Add and commit it." >&2
  exit 1
fi

if [ ! -L "$ROOT" ]; then
  echo "wrapper_link_guard: ⛔ $ROOT IS NOT A SYMLINK — it is a regular file." >&2
  echo "  This is the QUIET failure: edits to the versioned wrapper are committed and pushed," >&2
  echo "  and every seat keeps executing these stale root bytes. Builds stay green throughout." >&2
  echo "  FIX: ln -sfn saltworks/tools/saltbuild.sh $ROOT   (verify with a build afterwards)" >&2
  exit 1
fi

TGT=$(readlink "$ROOT")
rootsha=$(shasum -a 256 "$ROOT" 2>/dev/null | cut -d' ' -f1)      # follows the link
tracksha=$(shasum -a 256 "$TRACKED" 2>/dev/null | cut -d' ' -f1)
[ -n "$rootsha" ] && [ -n "$tracksha" ] || {
  echo "wrapper_link_guard: REFUSING — shasum produced nothing." >&2; exit 2; }

echo "wrapper_link_guard: symlink -> $TGT"
if [ "$rootsha" != "$tracksha" ]; then
  echo "wrapper_link_guard: ⛔ the link resolves to DIFFERENT BYTES than the versioned wrapper." >&2
  echo "  root(resolved)=$rootsha" >&2
  echo "  tracked       =$tracksha" >&2
  echo "  The symlink points somewhere else. Seats are not running the file under review." >&2
  exit 1
fi

# A tracked file can still differ from its committed state; a working-tree edit is not yet history.
if ! git -C "$REPO" diff --quiet -- tools/saltbuild.sh 2>/dev/null; then
  echo "wrapper_link_guard: ⚠️  healthy link, but tools/saltbuild.sh has UNCOMMITTED changes."
  echo "  Seats are running them right now and no history records them. Commit or revert."
  exit 1
fi

echo "wrapper_link_guard: OK — every seat's ../saltbuild.sh executes the committed wrapper."
echo "  (scope: the link and THESE bytes, now. It does not check the wrapper is CORRECT.)"
exit 0

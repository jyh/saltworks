#!/bin/bash
# ============================================================================
# swap_ready.sh — is the Horn D swap unblocked YET?
#
# The swap (stWidth 1056 -> 1313) breaks `decQ_congr` in SaltWorks/Stack/Program.lean,
# which SEATS.md:10 makes MATH's glob, READ-ONLY to this seat. Helm ORDERED math to make
# those sites width-agnostic (15:3x). This tool answers "has that landed?" BY RUNNING,
# never by memory — the compiler seat's standing law.
#
# ⛔ WHY NOT "grep for `< 1056` and require zero": under the D layout the pc field STILL
#   occupies 1024..1055, so `1024 + k < 1056` remains TRUE and meaningful as a pc bound.
#   A zero-occurrence criterion could never pass and would be a gate that always refuses —
#   which reads as "not ready" forever and is indistinguishable from a broken tool.
#   ⇒ The TRIGGER is "math's file MOVED"; the VERDICT is the isolated build in arm 2.
#
# EXIT 0 = math's file has moved since the block was recorded; run arm 2.
# EXIT 1 = unmoved; the block stands. EXIT 2 = cannot tell (say so, never guess).
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2
BASE_BLOB="bafb3a9a2c81557e066e5ad1080fec3cee35b0e3"
NOW=$(git rev-parse HEAD:SaltWorks/Stack/Program.lean 2>/dev/null) || {
  echo "⛔ swap_ready: cannot read the blob — REFUSING to report a verdict."; exit 2; }
printf 'baseline blob : %s\ncurrent  blob : %s\n' "$BASE_BLOB" "$NOW"
if [ "$NOW" = "$BASE_BLOB" ]; then
  echo "⏸  NOT READY — Stack/Program.lean is UNMOVED since the block was recorded."
  echo "   The blocked-at-head posture stands. Do NOT begin the swap."
  exit 1
fi
cat <<'MSG'
✅ TRIGGER FIRED — Stack/Program.lean has MOVED since the block was recorded.
   That is NOT a verdict that the swap works. Now run ARM 2, the only thing that is:

     git worktree add /tmp/swapdry HEAD        # isolated; never the shared tree
     (apply the staged StateCodec.lean edit there, build, read the failures)

   ⛔ Arm 2 exists because "math changed the file" and "the swap now elaborates" are
     different claims, and only the second licenses touching the shared worktree.
MSG
exit 0

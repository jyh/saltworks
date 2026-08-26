#!/bin/sh
# ⛔⛔ RETIRED 2026-08-25 — THIS IS A TOMBSTONE. IT DOES NOT RUN.
#
# ── SUCCESSOR (the retirement law: name the successor tool, or say none exists)
#    A tool of the same name, `fleetcommit.sh`, maintained in the fleet's private
#    tool bank. It is NOT in this repository, and its location is deliberately not
#    written here: council 2026-08-25 ruled that paths into the private record do
#    not appear on public repos, bare filenames are softened, and role-wording is
#    the standard. Ask the helm for it.
#
# ── WHY THIS ONE WAS RETIRED. Measured against the 2026-08-25 commit-lock spec it
#    scored 2 of 6:
#      OK   acquire by mkdir (atomic; correct, and the successor keeps it)
#      OK   bounded wait, refuses rather than breaking a lock
#      BAD  writes NO pid inside the lock — so the lock directory is EMPTY, and a
#           foreign bare `rmdir` on it SUCCEEDS. A live lock could be taken silently.
#      BAD  NEVER reaps a dead holder — a seat that dies inside its commit section
#           wedges every other seat permanently, with no recovery but a human.
#      BAD  never verifies its release — it could fail to release and say nothing.
#      BAD  the trap IS the mechanism rather than a backstop. A cleanup you cannot
#           observe firing is not a mechanism: a working release and a lucky one
#           are indistinguishable, and the trap fires TWICE on a signal path.
#    It also carried `git rebase` against the upstream branch, found hazardous on
#    2026-08-24 at 23:33 — a rebase rewrites the working tree underneath any
#    long-lived script executing out of that tree.
#
# ── WHY A REFUSING STUB AND NOT A DELETION. An ABSENT tool prompts someone to
#    build one. A BAD tool believed good prompts NOTHING — this file was recorded
#    as "mechanised" and trusted for 28 hours while scoring 2 of 6. Deleting it
#    yields "command not found", which names no successor and teaches nobody.
#    Refusing loudly, and naming the successor, is the only form that turns a
#    silent wrong into a loud right.
#
# ── PER-CLONE PROPAGATION, AND IT APPLIES TO THIS VERY FIX. This retirement
#    reaches a clone ONLY when that clone pulls. Sibling clones still hold the
#    runnable original until each one does. A fix that has not reached the
#    executing copy is a fix nobody is running.
echo "⛔ fleetcommit.sh (this copy) is RETIRED and will not run." >&2
echo "   It scored 2 of 6 against the 2026-08-25 commit-lock spec: no pid inside" >&2
echo "   the lock, never reaps a dead holder, release never verified, trap used as" >&2
echo "   the mechanism instead of a backstop. It also rebases, which rewrites the" >&2
echo "   working tree under anything executing out of it." >&2
echo "   Running it can lose another seat's work." >&2
echo "" >&2
echo "   SUCCESSOR: a tool of the same name, maintained in the fleet's private" >&2
echo "   tool bank. It is not in this repository. Ask the helm for it." >&2
exit 64

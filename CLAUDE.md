# saltworks — session instructions

## Commit hygiene (ratified 2026-08-23)

This repository is PUBLIC. Commit messages must not carry `Claude-Session:`
trailer lines — the 2026-08-16 history purge's scope is the standing rule, and
a `commit-msg` hook enforces it (tracked at `.githooks/`; a fresh clone runs
`git config core.hooksPath .githooks` once — without that command the tracked
claim outlives the gate). `Co-Authored-By`
attribution lines are fine.

**A Windows CI lane for Scrub is a DECLARED NON-GOAL** (ruled 2026-09-01,
closing `#1`): the scrub gates are authoritative on the Linux job, and no
Windows checkout commits here. Recorded rather than left implicit because an
undeclared gap reads as *covered* — a gate that never runs on a platform
reports green there, not unknown.

What the declaration accepts, stated so this is a KNOWN hole and not a stale
one. Measured on real Windows, and on hosted `windows-latest`, 2026-08-31:
a redirected Python stdout there is **cp1252**, and these gates print an
em-dash. `check_private_paths.py --self-test` renders `... scratch repo
<U+FFFD> trichotomy ...` — the em-dash becomes byte `0x97`, the stream stops
being valid UTF-8, and the process **exits 0**. A character outside cp1252 is
worse: `UnicodeEncodeError`, empty output, exit **1** — the same code these
gates use for *finding found*.

⇒ **None of that can reach CI, which is Linux-only and UTF-8**, and the Linux
job blocks the push, so a Windows-specific defect in these three scripts cannot
leak into public history. The only live Windows surface would be a `commit-msg`
hook on a Windows checkout of this repository, and none exists. A Windows job in
the merge gate would be a perpetual cost — a flaky runner blocks a merge — for a
class that cannot leak.

**A working lane exists on branch `flask/windows-scrub-lane`, retained at origin.
Reopen it the day a Windows contributor or a Windows checkout of this repository
appears.** That branch also carries two platform-neutral pieces that stand on
their own and can be cherry-picked without the lane: a UTF-8 stdout shim with the
three gate scripts hardened to use it, and `check_verdict_encoding.py`, which
adjudicates the whole class from Linux by forcing the codec on a child.

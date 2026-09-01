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

⇒ **None of that can reach CI, which is Linux-only and UTF-8.** It is a
property of running the gates on a Windows box by hand. If that ever becomes
a supported workflow, the branch `flask/windows-scrub-lane` is retained at
origin and carries both the lane and a one-call-per-gate repair.

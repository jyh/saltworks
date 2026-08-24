# saltworks — session instructions

## Commit hygiene (ratified 2026-08-23)

This repository is PUBLIC. Commit messages must not carry `Claude-Session:`
trailer lines — the 2026-08-16 history purge's scope is the standing rule, and
a `commit-msg` hook enforces it (tracked at `.githooks/`; a fresh clone runs
`git config core.hooksPath .githooks` once — without that command the tracked
claim outlives the gate). `Co-Authored-By`
attribution lines are fine.

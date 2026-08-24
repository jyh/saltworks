#!/bin/sh
# amigated.sh — does THIS CHECKOUT actually refuse a banned session trailer?
#
# WHY (evidence, 2026-08-23 17:5x): the commit-msg gate was made durable by TRACKING
# it at .githooks/commit-msg and pointing core.hooksPath at it. The hook body now
# travels with a clone. THE ACTIVATION DOES NOT — core.hooksPath lives in .git/config,
# which git never clones (by design: cloned config would be remote code execution).
# MEASURED, not reasoned: a real `git clone` of saltworks had the hook ON DISK,
# core.hooksPath UNSET, and a Claude-Session commit LANDED.
#   ⇒ THE GATE TRAVELS AS A FILE AND NOT AS AN ACTIVATION, and a fresh checkout sits
#     next to a CLAUDE.md sentence saying it is enforced. Git cannot close this for us;
#     the only honest substitute is a check that is CHEAP ENOUGH TO ACTUALLY RUN.
#
# ⛔ VERSION 1 OF THIS SCRIPT USED `git hook run commit-msg` AND REPORTED "GATED" IN A
#   REPO WITH NO HOOK AT ALL — `git hook run` exits nonzero both when a hook REFUSES
#   and when it is ABSENT, and I mapped absence to gated. FALSE ASSURANCE, the worst
#   output a safety check can produce. The POSITIVE arm passed; only the negative
#   control caught it. Hence: invoke the hook DIRECTLY and separate the three states
#   git's exit code conflates — REFUSES · ABSENT · PERMISSIVE.
#
# Driven 4/4: gated checkout ✅ · no hook ⛔ · hook-that-accepts ⛔ · salt ✅
# exit 0 = gated, 1 = not gated.
HP=$(git config --get core.hooksPath 2>/dev/null); [ -n "$HP" ] || HP=".git/hooks"
H="$HP/commit-msg"
[ -x "$H" ] || { echo "⛔ UNGATED — no executable hook at $H"; exit 1; }
T=$(mktemp) || exit 1
printf 'probe\n\nClaude-Session: https://claude.ai/code/session_PROBE\n' > "$T"
if "$H" "$T" >/dev/null 2>&1; then
  rm -f "$T"; echo "⛔ UNGATED — hook at $H exists but ACCEPTS the trailer"; exit 1
fi
rm -f "$T"; echo "✅ GATED — $H refuses it"; exit 0

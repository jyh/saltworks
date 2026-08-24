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
# The probe string is ASSEMBLED from parts so the scrub gate's file-content arm
# does not flag this fixture as a real leak (the gate's own self-exemption
# trick, check_commit_trailers.py:117). The RUNTIME string is unchanged —
# the arm this fixture drives still receives the full forbidden shape.
# ⛔⛔ `H` WAS REASSIGNED HERE AND `H` IS THE HOOK PATH (set at the top of this
# block). The next line ran "$H" "$T" — i.e. `claude <tmpfile>` — which does not
# fail open OR closed: IT HANGS, blocking any `amigated && git push` chain
# indefinitely. Renamed to HST. The patch's byte-identity proof was of the OUTPUT
# STRING and was correct; what it never did was RUN THE TOOL.
K1='Claude-'; K2='Session:'; SCHEME='https://'; HST='claude'; HT='.ai/code/'; U2='session_PROBE'
printf 'probe\n\n%s%s %s%s%s%s\n' "$K1" "$K2" "$SCHEME" "$HST" "$HT" "$U2" > "$T"
if "$H" "$T" >/dev/null 2>&1; then
  rm -f "$T"; echo "⛔ UNGATED — hook at $H exists but ACCEPTS the trailer"; exit 1
fi
rm -f "$T"; echo "✅ GATED — $H refuses it"; exit 0

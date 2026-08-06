#!/bin/bash
# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
#
# Assemble the TinyTapeout submission repo tree.
#
#   ./assemble.sh <target-dir>
#
# WHY THIS EXISTS RATHER THAN A CHECKED-IN COPY OF THE RTL: the fabric and the
# switch element live in ONE place, `SaltWorks/Silicon/RTL/`, because that is the
# source the Lean equivalence proof and the synthesis script both read. A second
# committed copy under `src/` would be a copy a human maintains, and a copy a
# human maintains drifts. This script makes the copy instead, every time, so the
# submission tree is derived rather than asserted.
#
# What this does NOT produce: `.github/workflows/`, `.devcontainer/`, `.vscode/`
# and `LICENSE` come from TinyTapeout's template repo verbatim and must not be
# hand-written — create the repo FROM the template, then run this over it.
set -e -u

TARGET="${1:?usage: assemble.sh <target-dir>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../RTL"

mkdir -p "$TARGET/src" "$TARGET/docs" "$TARGET/test"

# Ours, authored for the submission.
cp "$HERE/info.yaml"                "$TARGET/info.yaml"
cp "$HERE/docs/info.md"             "$TARGET/docs/info.md"
cp "$HERE/src/project.v"            "$TARGET/src/project.v"
cp "$HERE/src/config.json"          "$TARGET/src/config.json"
cp "$HERE/test/Makefile"            "$TARGET/test/Makefile"
cp "$HERE/test/tb.v"                "$TARGET/test/tb.v"
cp "$HERE/test/test.py"             "$TARGET/test/test.py"
cp "$HERE/test/requirements.txt"    "$TARGET/test/requirements.txt"
cp "$HERE/test/README.md"           "$TARGET/test/README.md"
cp "$HERE/README.md"                "$TARGET/README.md"
cp "$HERE/docs/submission-checklist.md" "$TARGET/docs/submission-checklist.md"
cp "$HERE/docs/hardening-choices.md"    "$TARGET/docs/hardening-choices.md"

# Derived: the single source of truth is RTL/, which is what synth.sh reads and
# what the imported netlist under proof was built from.
cp "$RTL/banyan_fabric.v"           "$TARGET/src/banyan_fabric.v"
cp "$RTL/bitserial_switch.v"        "$TARGET/src/bitserial_switch.v"

echo "assembled -> $TARGET"

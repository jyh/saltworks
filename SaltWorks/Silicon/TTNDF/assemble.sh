#!/bin/bash
# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
#
# Assemble the TinyTapeout submission tree for the NDF project.
#
#   ./assemble.sh <target-dir>
#
# ⛔ IT REFUSES BEFORE IT COPIES. `manifest_check.sh` must agree that info.yaml's
# `source_files` is exactly the transitive closure of `top_module`; if it does not,
# nothing is copied. The gate is CONSUMED (`tool || exit`), not printed — a correct
# check whose exit status nothing reads is a PRINTOUT, and this kit has shipped that
# defect before by putting the action on the next line.
#
# WHY DERIVED AND NOT A CHECKED-IN COPY (the BB project's reasoning, adopted whole):
# the RTL lives in ONE place, `SaltWorks/Silicon/RTL/`, because that is what the Lean
# equivalence proof and `Flow/synth.sh` both read. A second committed copy under
# `src/` is a copy a human maintains, and a copy a human maintains DRIFTS. This script
# makes the copy every time, so the submission tree is DERIVED rather than ASSERTED.
#
# ⛔ AND THE FILE LIST IS READ FROM info.yaml, NOT TYPED HERE. The BB project's
# assemble.sh names its two RTL files literally, which is a THIRD place the same set
# lives (manifest, Makefile, assembler) and therefore a third place it can drift. This
# one derives the list from the manifest it just gated, so the manifest is the single
# authority and this script cannot disagree with it.
#
# ⚠️⚠️ WHAT THIS PRODUCES IS **NOT A SUBMITTABLE TREE**, AND IT SAYS SO AT THE END
# RATHER THAN LETTING A GREEN "assembled ->" IMPLY OTHERWISE. TTNDF has no test/,
# no docs/info.md and no README.md of its own. Those are REAL missing deliverables,
# not oversights of this script. It reports every one it could not supply.
#
# ⛔ `.github/workflows/`, `.devcontainer/`, `.vscode/` and `LICENSE` come from
# TinyTapeout's template repo verbatim and must not be hand-written — create the repo
# FROM the template, then run this over it.
set -e -u

TARGET="${1:?usage: assemble.sh <target-dir>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../RTL"
TOOLS="$HERE/../../../docs/silicon-tools"
INFO="$HERE/info.yaml"

[ -d "$RTL" ]  || { echo "assemble: RTL dir not found at $RTL"; exit 2; }
[ -r "$INFO" ] || { echo "assemble: no info.yaml beside this script"; exit 2; }

# ---- THE GATE, and its status is consumed ----------------------------------------
if [ -x "$TOOLS/manifest_check.sh" ]; then
  "$TOOLS/manifest_check.sh" "$INFO" || {
    echo "assemble: ⛔ REFUSING TO ASSEMBLE — the manifest and the closure disagree."
    echo "assemble:    Fix info.yaml's source_files first. A tree assembled from a"
    echo "assemble:    wrong manifest fails in TT's CI after the hardening run, which"
    echo "assemble:    is the expensive place to find it."
    exit 1
  }
else
  echo "assemble: ⛔ manifest_check.sh NOT FOUND or not executable at $TOOLS."
  echo "assemble:    REFUSING rather than assembling ungated: a missing gate and a"
  echo "assemble:    passing gate must not look the same."
  exit 2
fi

# ---- the file list, READ FROM THE GATED MANIFEST ---------------------------------
SRCS="$(awk '
  /^[[:space:]]*source_files:[[:space:]]*$/ { inblk=1; next }
  inblk && /^[[:space:]]*-[[:space:]]*/ {
      line=$0
      gsub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/"/, "", line); gsub(/[[:space:]]*#.*$/, "", line); gsub(/[[:space:]]+$/, "", line)
      if (line != "") print line
      next
  }
  inblk && /^[[:space:]]*[^-[:space:]#]/ { inblk=0 }
' "$INFO")"
[ -n "$SRCS" ] || { echo "assemble: extracted no source_files — refusing"; exit 1; }

mkdir -p "$TARGET/src" "$TARGET/docs"

cp "$INFO"                  "$TARGET/info.yaml"
cp "$HERE/src/config.json"  "$TARGET/src/config.json"
[ -r "$HERE/docs/info.md" ] && cp "$HERE/docs/info.md" "$TARGET/docs/info.md"
[ -r "$HERE/README.md" ]    && cp "$HERE/README.md"    "$TARGET/README.md"

N=0
for f in $SRCS; do
  [ -r "$RTL/$f" ] || { echo "assemble: ⛔ $f is in the manifest but not in RTL/ — refusing"; exit 1; }
  cp "$RTL/$f" "$TARGET/src/$f"
  N=$((N + 1))
done
echo "assemble: copied $N derived source files from RTL/ into $TARGET/src/"

# ---- WHAT IS MISSING, NAMED. A silent omission reads as completeness. -------------
# ⚠️ NEWLINE-DELIMITED, NOT SPACE-DELIMITED. First version built a space-separated
# list and `for m in $MISS` word-split every parenthetical into its own bullet, so one
# missing directory printed as nine findings. A report that inflates its own count is
# the same class as a count with no scope: the reader acts on the number.
# ⛔⛔ THIS CHECKS "$TARGET", NOT "$HERE", AND THE FIRST VERSION CHECKED "$HERE".
# That version PASSED while never copying docs/info.md or README.md at all: it
# verified THE SOURCE EXISTED and called that a complete tree. **A check on the
# wrong side of a copy is not a check on the copy.** Caught the minute the two docs
# were written, by reading the assembled directory instead of the report — which is
# this seat's own banked law (`verify the treatment applied`) broken inside the hour
# of writing the tool that broke it. The tell was that the missing-list shrank
# exactly as predicted while the target directory had not changed.
MISS=""
NL='
'
[ -d "$TARGET/test" ]         || MISS="${MISS}test/ (Makefile, tb.v, test.py — no PROJECT_SOURCES exists to agree with yet)${NL}"
[ -r "$TARGET/docs/info.md" ] || MISS="${MISS}docs/info.md${NL}"
[ -r "$TARGET/README.md" ]    || MISS="${MISS}README.md${NL}"
if [ -n "$MISS" ]; then
  echo "assemble: ⚠️ TREE IS INCOMPLETE — NOT SUBMITTABLE. Missing, and each is a real"
  echo "assemble:    deliverable rather than a fault of this script:"
  printf '%s' "$MISS" | while IFS= read -r m; do [ -n "$m" ] && echo "assemble:      - $m"; done
  echo "assemble: ⇒ EXITING NONZERO ON PURPOSE. An incomplete tree must not exit 0;"
  echo "assemble:   a caller that only reads the exit code would otherwise ship this."
  echo "assembled (INCOMPLETE) -> $TARGET"
  exit 3
fi
echo "assembled -> $TARGET"

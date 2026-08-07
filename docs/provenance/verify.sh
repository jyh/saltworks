#!/bin/bash
# docs/provenance/verify.sh — THE BUNDLE BINDING, AS A MECHANISM
#
# "The artifact ships with its birth record" was prose. This makes it a re-runnable
# check. It asserts that the provenance bundle binds WHAT IT NAMES:
#
#   (1) the program blob is the one the bundle was written about;
#   (2) every bundle file is byte-identical to what was recorded;
#   (3) the emitted-word file contains exactly as many words as the program has
#       instructions -- the count is DERIVED from the module's own length theorems
#       (5 x 24), not hardcoded prose.
#
# (3) exists because of a real defect: on 2026-08-07 the emitted-word file carried
# 51 of 120 words and ended in Lean's display-truncation marker, under a heading
# claiming all 120. Nothing detected it for an hour. This check would have.
#
# Exit 0 = bound. Exit 1 = drifted, with the mismatch named. Run from anywhere.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1   # repo root
M=docs/provenance/MANIFEST.tsv
fail=0
note() { printf '  %-8s %s\n' "$1" "$2"; }

echo "== provenance bundle verification =="
[ -f "$M" ] || { echo "FAIL: no manifest at $M"; exit 1; }

while IFS=$'\t' read -r kind path expected; do
  case "$kind" in
    ''|'#'*) continue ;;

    blob)   # git blob SHA of a tracked source file -- pins the ARTIFACT
            [ -f "$path" ] || { note FAIL "missing: $path"; fail=1; continue; }
            got=$(git hash-object "$path")
            if [ "$got" = "$expected" ]; then note ok "blob $path"
            else note FAIL "blob $path"; note "" "  expected $expected"
                 note "" "  got      $got"
                 note "" "  ⇒ the program changed; the bundle describes an older artifact."
                 fail=1
            fi ;;

    sha256) # content hash of a bundle file -- pins the RECORD
            [ -f "$path" ] || { note FAIL "missing: $path"; fail=1; continue; }
            got=$(shasum -a 256 "$path" | cut -d' ' -f1)
            if [ "$got" = "$expected" ]; then note ok "sha256 $(basename "$path")"
            else note FAIL "sha256 $(basename "$path")"
                 note "" "  expected $expected"
                 note "" "  got      $got"
                 fail=1
            fi ;;

    words)  # THE DEFECT-2 CHECK. Count the words actually present, and derive the
            # expected count from the module's own length theorems rather than prose.
            [ -f "$path" ] || { note FAIL "missing: $path"; fail=1; continue; }
            got=$(grep -cE '^ *[0-9]+: [0-9]+$' "$path")
            per=$(grep -oE 'theorem cmpEx_length[^=]*= *([0-9]+)' SaltWorks/Stack/Program.lean | grep -oE '[0-9]+$')
            cmps=$(grep -oE 'theorem batcher8_length[^=]*= *([0-9]+)' SaltWorks/Stack/ZeroOne.lean | grep -oE '[0-9]+$')
            if [ -z "$per" ] || [ -z "$cmps" ]; then
              note FAIL "could not read the length theorems (cmpEx_length / batcher8_length)"
              note "" "  ⇒ the count cannot be derived; refusing to fall back to a literal."
              fail=1
            else
              want=$((per * cmps))
              if [ "$got" -eq "$want" ] && [ "$got" -eq "$expected" ]; then
                note ok "words $got = $per x $cmps (derived from the length theorems)"
              else
                note FAIL "words: file has $got, theorems give $per x $cmps = $want, manifest says $expected"
                note "" "  ⇒ this is the 2026-08-07 truncation defect, or the program's size changed."
                fail=1
              fi
              # Scope the marker check to the DATA region (inside the fence), never to
              # prose. The README and this file both DESCRIBE the truncation defect and
              # therefore contain the marker as text; a whole-file grep flags its own
              # documentation. That is the same self-match that has cost this fleet four
              # findings in two days -- and it fired here, inside the tool built to
              # close that very class, on this script's first run.
              if awk '/^```/{f=!f; next} f' "$path" | grep -qF '⋯'; then
                note FAIL "truncation marker U+22EF inside the DATA block of $path"; fail=1
              fi
            fi ;;

    *)      note FAIL "unknown manifest row kind: $kind"; fail=1 ;;
  esac
done < "$M"

echo
if [ "$fail" -eq 0 ]; then
  echo "BOUND: the bundle binds what it names."
else
  echo "DRIFTED: the bundle no longer binds what it names (see FAIL rows above)."
fi
exit "$fail"

#!/bin/bash
# manifest_check.sh — DOES info.yaml's `source_files` MATCH THE TOP'S REAL CLOSURE?
#
#   manifest_check.sh <info.yaml>
#   exit 0 = the declared set and the derived closure are EQUAL
#   exit 1 = they differ (both directions printed), or the extraction found nothing
#
# ⛔⛔ WHY THIS EXISTS: THE FILE ITSELF NAMES THE GAP, TWICE, AND THEN LEAVES IT OPEN.
# `SaltWorks/Silicon/TTNDF/info.yaml` says, in its own comments:
#     "source_files must be kept in sync BY HAND with PROJECT_SOURCES in
#      test/Makefile -- nothing checks that they agree."
#     "keep in sync BY HAND with test/Makefile's PROJECT_SOURCES."
# A comment that says NOTHING CHECKS THIS is a defect report addressed to nobody.
# ⇒ AND THE PROPERTY IS DECIDABLE, which is the whole reason a gate belongs here:
#   "is this set equal to that set" has a threshold; "is this headline overclaiming"
#   does not. The fleet's axis is DECIDABLE vs JUDGEMENT, not prose vs code, and a
#   gate placed on a decidable property is never worth routing around.
#
# ⚠️ WHAT THIS DOES NOT CHECK: whether the files SYNTHESIZE, whether the pin map is
# right, whether the design works. Only that the manifest names exactly the files the
# top actually needs. A green run here is a cross-file agreement receipt and nothing
# more.
#
# 📌 PRE-REGISTERED BEFORE THE FIX, ON PURPOSE (2026-08-18): this tool was written and
# run while the manifest was still WRONG, so its FAILING arm is a real observation of
# a real defect rather than a mutant I injected afterwards. The passing arm comes
# after the repair. Both arms are therefore driven by the world.
set -u
INFO="${1:?usage: manifest_check.sh <info.yaml>}"
[ -r "$INFO" ] || { echo "manifest_check: cannot read $INFO"; exit 2; }

HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../../SaltWorks/Silicon/RTL"
[ -d "$RTL" ] || { echo "manifest_check: RTL dir not found at $RTL"; exit 2; }

TOP="$(sed -n 's/^[[:space:]]*top_module:[[:space:]]*"\{0,1\}\([A-Za-z_0-9]*\)"\{0,1\}.*/\1/p' "$INFO" | head -1)"
[ -n "$TOP" ] || { echo "manifest_check: no top_module found in $INFO — refusing"; exit 1; }
[ -r "$RTL/$TOP.v" ] || { echo "manifest_check: top_module $TOP has no $TOP.v in RTL/ — refusing"; exit 1; }

# ---- the DECLARED set -------------------------------------------------------------
# The `source_files:` block is a plain YAML list of quoted names. Extracted by shape,
# then SANITY-GATED: an extraction that yields nothing, or yields a non-.v name, is a
# broken parser and must refuse rather than report an empty set as a clean one.
DECL="$(awk '
  /^[[:space:]]*source_files:[[:space:]]*$/ { inblk=1; next }
  inblk && /^[[:space:]]*-[[:space:]]*/ {
      line=$0
      gsub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/"/, "", line); gsub(/'"'"'/, "", line)
      gsub(/[[:space:]]*#.*$/, "", line)
      gsub(/[[:space:]]+$/, "", line)
      if (line != "") print line
      next
  }
  inblk && /^[[:space:]]*[^-[:space:]#]/ { inblk=0 }
' "$INFO" | sort -u)"

NDECL="$(printf '%s\n' "$DECL" | grep -c . || true)"
if [ "${NDECL:-0}" -lt 1 ]; then
  echo "manifest_check: ⛔ extracted ZERO source_files from $INFO."
  echo "manifest_check:    That is a BROKEN PARSER, not an empty manifest — refusing."
  echo "manifest_check:    (an empty set would otherwise compare 'equal' to nothing"
  echo "manifest_check:     and a silent instrument failure reads as a measurement of zero)"
  exit 1
fi
if printf '%s\n' "$DECL" | grep -qv '\.v$'; then
  echo "manifest_check: ⛔ a declared source_file does not end in .v — extraction is wrong:"
  printf '%s\n' "$DECL" | grep -v '\.v$' | sed 's/^/                 /'
  exit 1
fi

# ---- the DERIVED closure ----------------------------------------------------------
# Same rule as Flow/synth.sh, including the `#(...)` arm: without it a PARAMETERIZED
# instantiation is invisible, and this tree has one (`banyan_fabric #(.PAYLOAD(8))`).
SRCS="$TOP.v"
changed=1
while [ "$changed" = 1 ]; do
  changed=0
  for f in "$RTL"/*.v; do
    b="$(basename "$f")"; m="${b%.v}"
    case " $SRCS " in *" $b "*) continue ;; esac
    for s in $SRCS; do
            # ⛔⛔ ANCHORED AT LINE START, AND THIS LINE WAS WRONG UNTIL 2026-08-18 14:4x.
      # It used to match the module name ANYWHERE in the line, so a HEADER COMMENT
      # naming another module counted as an instantiation: plane32bus.v's comment
      # says "It is NOT memplane8. memplane8 terminates the data path ON-CHIP
      # (core32 + dmem_addr8 + dmem8 ...)" and the closure for tt_um_saltworks_ndf_c32
      # came back with FIFTEEN files instead of EIGHT — pulling in memplane8,
      # dmem_addr8, dmem8, dmem_addr16 and memif, none of which the design uses.
      # ⚠️ AND MY OWN HEADER CLAIMED "Same rule as Flow/synth.sh". IT WAS NOT THE SAME
      #   RULE. I derived it from memory of the sibling instead of reading the sibling
      #   — [[derive-from-the-spec-not-the-sibling]], on a rule I cited by name.
      # ⇒ This is now synth.sh's regex VERBATIM. Residual carried with it: a `#(`
      #   whose parameter list WRAPS ACROSS LINES is still invisible; no such
      #   instantiation exists in this tree today.
if grep -qE "^[[:space:]]*$m[[:space:]]+(#\(.*\)[[:space:]]*)?[A-Za-z_]" "$RTL/$s" 2>/dev/null; then
        SRCS="$SRCS $b"; changed=1; break
      fi
    done
  done
done
DERV="$(printf '%s\n' $SRCS | sort -u)"
NDERV="$(printf '%s\n' "$DERV" | grep -c . || true)"

echo "manifest_check: top=$TOP  declared=$NDECL  derived=$NDERV"

MISSING="$(comm -13 <(printf '%s\n' "$DECL") <(printf '%s\n' "$DERV"))"
EXTRA="$(comm -23 <(printf '%s\n' "$DECL") <(printf '%s\n' "$DERV"))"

RC=0
if [ -n "$MISSING" ]; then
  echo "  ⛔ IN THE CLOSURE BUT NOT DECLARED (TT's CI will not find these):"
  printf '%s\n' "$MISSING" | sed 's/^/       /'
  RC=1
fi
if [ -n "$EXTRA" ]; then
  echo "  ⛔ DECLARED BUT NOT IN THE CLOSURE (a stale or wrong name):"
  printf '%s\n' "$EXTRA" | sed 's/^/       /'
  RC=1
fi

if [ "$RC" -ne 0 ]; then
  echo "manifest_check: ⛔ MANIFEST AND CLOSURE DISAGREE."
  exit 1
fi
echo "manifest_check: ✅ the manifest names exactly the $NDERV files the top needs."
exit 0

#!/bin/sh
# fenceread.sh — READ A POST ONLY IF THE FENCE ALLOWS IT. `tool && action`, as one object.
#
#   sh docs/silicon-tools/fenceread.sh <file> [head-bytes]
#   exit 0 = allowed and printed   1 = REFUSED, nothing printed   2 = usage/unreadable
#
# ⛔ WHY THIS EXISTS, 2026-08-28 12:4x, AND IT IS MY OWN CARD FIRING ON ME.
#   All morning I gated hand-reads correctly: run `fencecheck.sh`, read the verdict,
#   then decide. At 12:39 I ran the check and the `head` IN THE SAME INVOCATION —
#   so the read executed REGARDLESS OF THE VERDICT. The check printed ⛔ REFUSE and
#   the bytes printed anyway, one line below it.
#   ⇒ ***A CORRECT CHECK WHOSE EXIT STATUS NOTHING CONSUMES IS A PRINTOUT, AND
#     READING IT IS WHAT MAKES IT FEEL DISCHARGED.*** That is `printed-is-not-gated`,
#     banked by this seat, committed by this seat, and violated by this seat while
#     it was the top item in its own working memory.
#   ⚠️ THE EXTENT THAT TIME WAS NIL — the trip was a SELF-MATCH: the word `codebook`
#     is itself a fenced token, and the post said "it is a codebook line, not a
#     fenced one". Metadata, not pool content. THE NIL EXTENT IS LUCK, NOT METHOD,
#     which is exactly why the fix is a tool and not a resolution to be careful.
#
# ⛔ DO NOT ADD AN ADDRESSEE EXEMPTION. `fencecheck.sh` deliberately has none for
#   hand-reads: I am choosing to open the file, so nothing is being withheld from me
#   and an exemption would let any post that opens with my name carry anything.
set -u
F="${1:?usage: fenceread.sh <file> [head-bytes]}"
N="${2:-}"
[ -r "$F" ] || { echo "fenceread: cannot read: $F" >&2; exit 2; }
D=$(dirname "$0")
if sh "$D/fencecheck.sh" "$F" >/dev/null 2>&1; then
  if [ -n "$N" ]; then head -c "$N" "$F"; else cat "$F"; fi
  exit 0
else
  sh "$D/fencecheck.sh" "$F" >&2
  echo "fenceread: ⛔ NOTHING PRINTED. Gate the read line-by-line if you need the cleared parts." >&2
  exit 1
fi

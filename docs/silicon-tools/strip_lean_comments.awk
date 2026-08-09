# strip_lean_comments.awk — remove Lean comments before ANY source-text scan.
#
#   git show REF:File.lean | awk -f docs/silicon-tools/strip_lean_comments.awk
#
# ⛔ WHY: this corpus is HEAVILY commented, in wrapped prose, and wrapped prose
# puts ORDINARY WORDS AT COLUMN 0. Every column-anchored pattern in the fleet
# therefore fires inside comments. Measured on `ImmediateScope.lean` @ 169eaf5:
#
#     line 118:  theorem was true and awkward — and nothing in the kernel was
#                ^^^^^^^ wrapped docstring prose, NOT a declaration
#
# meas_scan.sh's declaration regex extracted the next token — `was` — and
# reported "⛔ UNAUDITED was" against a peer's landing that is in fact 4/4 clean.
# ⚠️ I had already published one FALSE ACCUSATION against a predecessor today
# from a pattern defect (case-sensitivity). A scanner that reads comments will
# eventually accuse someone, and the accusation is confident and specific.
#
# ⭐ THIS IS THE CLASS, NOT THE INSTANCE. `sorry`, `admit`, `theorem`, `axiom`,
# `TODO` — every one of them appears in this corpus's PROSE, because the prose
# is ABOUT proofs. Anchoring harder does not help; the prose is at column 0 too.
# The only fix that generalises is to delete the comments before scanning.
#
# ⇒ COMMIT AN EXECUTABLE, NOT A PATTERN (evidence's law): call this file rather
#   than re-typing a comment-skip in awk, sed, python, or grep. A pattern
#   committed in ONE language is not a pattern committed.
#
# Handles: nested /- ... -/ blocks (Lean nests them), /-- docstrings, and -- to
# end of line. Preserves line NUMBERING — every input line yields one output
# line — so `grep -n` offsets still point at the real file.
#
# ⚠️ HONEST LIMIT: a `--` or `/-` inside a STRING LITERAL is treated as a comment
# and the rest of the line is dropped. That is wrong in general and harmless for
# declaration/proof-term scanning (a declaration's name precedes any string). Do
# not reuse this to extract string contents.

{
  line = $0
  out = ""
  i = 1
  n = length(line)
  while (i <= n) {
    two = substr(line, i, 2)
    if (depth > 0) {
      if (two == "/-") { depth++; i += 2; continue }
      if (two == "-/") { depth--; i += 2; continue }
      i++
      continue
    }
    if (two == "/-") { depth++; i += 2; continue }
    if (two == "--") { break }
    out = out substr(line, i, 1)
    i++
  }
  print out
}

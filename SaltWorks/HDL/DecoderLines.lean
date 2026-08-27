/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CorePlace

/-!
# Names for the decoder's nine output lines — because the bare index has already cost this tree once

`decOut` is indexed by a bare integer at **126 call sites in `SaltWorks/HDL/`**, and the nine
lines are named NOWHERE. `CorePlace.lean:409` records the order in a comment:

```
isADD  isXOR  isSLT  isADDI  isBEQ  isLW  isSW  req  valid
  0      1      2      3       4      5     6     7     8
```

⛔⛔ **A BARE INDEX HERE WAS A REAL LANDED DEFECT, kernel-proved at `a10f980` and repaired
2026-08-19** — `CorePlace.regWriteSig` fed `regWrite`'s **`valid`** port from **`decOut 5`**, which
is `isLW`. ***The assembled core write-enabled on "this is a LOAD" and never wrote a register on
`ADD`, `ADDI`, `XOR` or `SLT`.*** The port should have read `decOut 8`.

⚠️ **AND THE MECHANISM IS WORSE THAN A TYPO, which is the real argument for names:
`valid` MOVED from index 5 when the table grew.** The bare `5` was CORRECT when it was written and
went wrong underneath the author. *A literal index is a claim about a table's shape at the moment
of writing, and it is re-evaluated silently at every later read.*

**The wrong line builds green**: the nets are well-formed, the placement's `instOK` is TRUE, the
audit is clean, and nothing in the toolchain says a word. `regWrite_correct` is exhaustive over
128 combinations *of regWrite's own ports* and cannot see what they are connected to;
`decoder_correct` is about the decoder alone. *This seat's own receipt on the same shape: two
placements once fed `rs2` where `ADDI` needs the immediate, and every `instOK` was TRUE.*

⛔ **CORRECTED 2026-08-26 22:4x.** This header first said the defect was *"`decOut 5` where `6`
was meant"* — I read `CorePlace.lean:409`'s *"index 5 is `isLW`"* and supplied `isSW` as the
intended line because SW was what I was working on. **The record names `valid` two clauses later.
The LAW was sound and the INCIDENT was mine to get right; I substituted my own context for the
record's.**

⇒ **the cure is a NAME, so the off-by-one becomes an unknown identifier instead of a wrong wire.**

## ⛔ WHAT IS PROVED HERE, AND WHAT IS ONLY CITED — the distinction is the point

```
PROVED   decoder.outs has exactly 9 entries              (decided here at the kernel)
PROVED   the match table's index 6 IS the SW pattern     — dcMatches.getD 6 is
         `dcOpcode 0b0100011 ++ dcFunct3 0b010`, decided at the kernel
PROVED   the nine named indices are pairwise distinct    — so a transposition is visible
CITED    that `decoder.outs` position i corresponds to `dcMatches` position i.
         `dcLayout` is visibly order-preserving — it returns `o :: os` on `m :: ms` — but
         that is READ off the definition here, not proved by induction.
⛔ NOT PROVED, AND NAMED SO NOBODY READS THESE NAMES AS SEMANTICS: that the net called
   `isSW` goes high exactly on a store. That is a statement about `sem`, and these are
   nothing but better-spelled integers until it exists.
```
-/

namespace SaltWorks.HDL.DecoderLines

open SaltWorks.HDL SaltWorks.HDL.CorePlace

/-! ## §1 — THE NINE NAMES -/

def isADDLine  : Nat := 0
def isXORLine  : Nat := 1
def isSLTLine  : Nat := 2
def isADDILine : Nat := 3
def isBEQLine  : Nat := 4
def isLWLine   : Nat := 5
def isSWLine   : Nat := 6
def reqLine    : Nat := 7
def validLine  : Nat := 8

/-! ## §2 — WHAT THE KERNEL CAN SAY ABOUT THEM -/

/-- ⭐ **THE MATCH TABLE'S INDEX 6 IS THE SW PATTERN.** This is the fact that makes `isSWLine`
worth its name: `dcMatches` is a literal table and its seventh row is the store's opcode/funct3
pair. ⛔ It does NOT say the emitted net behaves like a store detector. -/
theorem isSWLine_selects_the_SW_pattern :
    dcMatches.getD isSWLine [] = dcOpcode 0b0100011 ++ dcFunct3 0b010 := by
  decide +kernel

/-- ⭐ **AND INDEX 5 IS THE LOAD** — stated beside it, because the pair being adjacent is the
whole hazard. -/
theorem isLWLine_selects_the_LW_pattern :
    dcMatches.getD isLWLine [] = dcOpcode 0b0000011 ++ dcFunct3 0b010 := by
  decide +kernel

/-- ⛔ **THE TWO MEMORY ROWS ARE DIFFERENT PATTERNS.** Without this, the two theorems above could
both be true of one row and the name would carry no information. -/
theorem control_LW_and_SW_patterns_differ :
    dcMatches.getD isLWLine [] ≠ dcMatches.getD isSWLine [] := by
  decide +kernel

/-- ⭐ The nine names are pairwise distinct indices, so a transposition cannot hide. -/
theorem lines_are_distinct :
    [isADDLine, isXORLine, isSLTLine, isADDILine, isBEQLine,
     isLWLine, isSWLine, reqLine, validLine].Nodup := by
  decide +kernel

/-- ⭐ Every name indexes a real output: the decoder has exactly nine. -/
theorem lines_are_in_range :
    validLine < decoder.outs.length ∧ decoder.outs.length = 9 := by
  decide +kernel

/-- ⛔ **CONTROL — the range claim can fail.** An index past the last line is out of range, so
`lines_are_in_range` is not vacuously true of every natural number. -/
theorem control_nine_is_out_of_range : ¬ (9 < decoder.outs.length) := by
  decide +kernel

#audit_axioms isADDLine isXORLine isSLTLine isADDILine isBEQLine
#audit_axioms isLWLine isSWLine reqLine validLine
#audit_axioms isSWLine_selects_the_SW_pattern isLWLine_selects_the_LW_pattern
#audit_axioms control_LW_and_SW_patterns_differ lines_are_distinct
#audit_axioms lines_are_in_range control_nine_is_out_of_range

end SaltWorks.HDL.DecoderLines

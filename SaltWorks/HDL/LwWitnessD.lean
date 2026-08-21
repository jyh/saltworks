import SaltWorks.HDL.StateCodecD

/-! # Q6 — THE RE-CHOSEN LW WITNESS, verified against the LANDED D codec

The Q6 pre-registration fixes this bar: **any post-D verdict on an LW exhibit computed against a
witness whose LOADED WORD IS NOT PROVABLY NON-ZERO IS VOID.** The landed witness `C4Refuted.sL`
cannot clear it — measured, for EVERY `wL : BitVec 32` its top set bit is 1087, so the whole memory
region reads zero by construction, not by choice.

⛔ AND IT IS WORSE THAN VACUOUS UNDER D. `sL` places the instruction word at bit 1056 via
`wL.toNat * 2^1056`. Under the D layout 1056..1087 is **memory word 0**, so the old witness's
INSTRUCTION would be reinterpreted as MEMORY, while `seenWord` reads 1313.. and finds zeros.

This file builds the replacement and proves the memory half NOW, against `decQD` — the D codec is
landed, so this does not wait on the swap. The instruction placement moves with `instrBase` and is
mechanical; the MEMORY content is the part the bar is about.
-/

namespace SaltWorks.HDL.LwWitnessD
open SaltWorks.HDL SaltWorks.HDL.StateCodecD SaltWorks.ISA

/-- `LW x1, x2, 4` with `x2 = 4`. Effective address `4 + 4 = 8`, so the ISA reads `mem[8/4] = mem[2]`.
**Word 2 is the one that must be non-zero**, and the landed witness leaves it empty. -/
def wordIdx : Nat := 8 / 4

theorem the_loaded_word_is_index_two : wordIdx = 2 := by decide

/-- The re-chosen witness. Bits, under the D layout:
* `32*2 + 2 = 66`  — `x2 = 4`, the base register (unchanged from the landed witness)
* `32*1 + 2 = 34`  — `x1` already holds bit 2, so the HOLD arm is also wrong (unchanged)
* `1056 + 32*2 + 2 = 1122` — **`mem[2]` bit 2 SET. This is the bit the landed witness cannot have.** -/
def sW : Nat := 2 ^ 66 ||| 2 ^ 34 ||| 2 ^ 1122

def insW : Env := fun n => sW.testBit n

/-- ⭐ **THE BAR, DISCHARGED: the loaded word is provably NON-ZERO under the D decoder.** -/
theorem loaded_word_is_nonzero : (decQD insW).mem[2] ≠ 0 := by decide +kernel

/-- And its bit 2 is the one the LW exhibits examine, so the witness DISCRIMINATES at the
same index the landed exhibits read. -/
theorem loaded_word_bit2 : ((decQD insW).mem[2]).getLsbD 2 = true := by decide +kernel

/-- The base register still reads 4, so the address arithmetic is unchanged from the landed
witness — only the memory content differs. -/
theorem base_register_is_four : (decQD insW).regs[2] = 4 := by decide +kernel

/-- The destination register already holds bit 2, so the ELSE arm of `RegDatapathOK` is wrong too —
the property that made the landed witness a two-horn refutation is preserved. -/
theorem dest_holds_bit2 : ((decQD insW).regs[1]).getLsbD 2 = true := by decide +kernel

/-- ⛔ **THE CONTRAST, AS A THEOREM: the LANDED witness's memory is empty at the loaded word.**
This is what makes a post-D verdict computed on it VOID. -/
theorem landed_witness_memory_is_empty :
    (decQD (fun n => (2 ^ 66 ||| 2 ^ 34).testBit n)).mem[2] = 0 := by decide +kernel

#audit_axioms the_loaded_word_is_index_two
#audit_axioms loaded_word_is_nonzero
#audit_axioms loaded_word_bit2
#audit_axioms base_register_is_four
#audit_axioms dest_holds_bit2
#audit_axioms landed_witness_memory_is_empty

end SaltWorks.HDL.LwWitnessD

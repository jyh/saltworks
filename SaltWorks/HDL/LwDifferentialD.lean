import SaltWorks.HDL.LwWitnessD

/-! # Q6 — DOES HORN D ACTUALLY CHANGE THE LOAD'S ANSWER? Provable NOW, against the landed D codec.

The LW refutation rests on one fact: `stepT_lw_writes_zero`, i.e. a non-trapping load out of an
ALL-ZERO memory writes the constant 0. Its hypothesis `hmem` is supplied today by `decQ_mem`.

⛔ THE VACUITY TRAP THE PRE-REGISTRATION NAMES is that after D the exhibits could KEEP PROVING for a
new and empty reason. **This file settles that ahead of the swap**, because `decQD` is landed: it
compares what the ISA does on the RE-CHOSEN witness against what it does on the landed all-zero
shape, at the SAME instruction and the SAME bit.

📌 `seenWord` is deliberately not used. It reads `instrNet`, which MOVES with `instrBase`, so a
statement through it could not be written before the swap. Feeding the decoded instruction directly
isolates the MEMORY question, which is the one the bar is about.
-/

namespace SaltWorks.HDL.LwDifferentialD
open SaltWorks.HDL SaltWorks.HDL.StateCodecD SaltWorks.HDL.LwWitnessD SaltWorks.ISA

/-- The address is in range, so the load takes its `.ok` arm and actually reads memory. -/
theorem the_load_is_not_trapping :
    addrClass ((decQD insW).get 2 + (4 : BitVec 12).signExtend 32) = .ok := by decide +kernel

/-- ⭐⭐ **THE DIFFERENTIAL: WITH A REAL MEMORY THE LOAD WRITES A NON-ZERO BIT.**
The landed exhibits assert this bit is `false`. Under D, on a witness whose loaded word is
non-zero, it is `true`. -/
theorem lw_writes_true_bit_under_D :
    ((step (decQD insW) (.LW 1 2 4)).regs[1]).getLsbD 2 = true := by decide +kernel

/-- ⛔ **THE CONTRAST, SAME INSTRUCTION, SAME BIT, EMPTY MEMORY** — this is the landed witness's
world, and it is where `= false` comes from. -/
theorem lw_writes_false_bit_on_empty_memory :
    ((step (decQD (fun n => (2 ^ 66 ||| 2 ^ 34).testBit n)) (.LW 1 2 4)).regs[1]).getLsbD 2
      = false := by decide +kernel

/-- ⇒ **THE PAIR IS DISCRIMINATING, AS A SINGLE STATEMENT.** Change only the memory content and the
answer moves. So Horn D is NOT a no-op on the load: the refutation's premise dies for a REASON,
not by accident of a witness. -/
theorem memory_content_decides_the_load :
    ((step (decQD insW) (.LW 1 2 4)).regs[1]).getLsbD 2
      ≠ ((step (decQD (fun n => (2 ^ 66 ||| 2 ^ 34).testBit n)) (.LW 1 2 4)).regs[1]).getLsbD 2 := by
  decide +kernel

#audit_axioms the_load_is_not_trapping
#audit_axioms lw_writes_true_bit_under_D
#audit_axioms lw_writes_false_bit_on_empty_memory
#audit_axioms memory_content_decides_the_load

end SaltWorks.HDL.LwDifferentialD

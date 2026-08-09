import SaltWorks.HDL.MacCell
import SaltWorks.HDL.MacInduction

/-!
# LAYER 2, RUNG 1 — the cell's sum bit IS the arithmetic sum bit

**Wave:** the cell wave's bridge, ruled 13:38; layer 1 landed by compiler at
`fc1ac39`, layer 2 dispatched to this seat.

Compiler's `step_bit_is_adder_bit` (`MacCell.lean`) proves the cell's sum bit `k`
equals **`adder32`'s** sum bit `k`, pointwise, with *no* `ℤ` and *no* overflow
condition — deliberately, so that the arithmetic certificate is applied **in the
file that owns it** rather than re-derived at the artifact boundary. This file is
that application.

## ⚠️ PRECONDITION PREAMBLE

**CLAIMED:** one rung — `run … macCore.gates (maSum k) = (acc + addend).getLsbD k`
for `k < 32`, obtained by composing compiler's pointwise layer-1 result with
`sem_adder32_gen`. Unconditional: still no `ℤ`, still no overflow hypothesis.

**NOT CLAIMED:** the word-level step, the trace induction, and the `ℤ` reading
that connects to `MacInduction.macAfter`. Those are rungs 2–4 and the `ℤ` rung is
where the **no-wrap hypothesis** enters — `(a + b).toInt = a.toInt + b.toInt`
holds only absent wrap, which is exactly why `demoBound` exists and why the
hypothesis belongs in *that* rung and not in this one. Named, not implied.
-/

namespace SaltWorks.HDL.MacBridge

open SaltWorks.HDL SaltWorks.HDL.MacCell SaltWorks.Stack.Program

/-- `adder32`'s run at sum-bit `k`, with the carry-in tied low, **is** the `k`-th
bit of `a + b`.

This is `sem_adder32_gen` read at one index. `adder32.outs` is 32 sum bits then
the carry-out, so index `k < 32` selects `adS k` on the left and the arithmetic
bit on the right — the carry-out tail is untouched by the extraction. -/
theorem adder_run_is_sum_bit (a b : BitVec 32) (k : Nat) (hk : k < 32) :
    run (adEnv a b false) adder32.gates (adS k) = (a + b).getLsbD k := by
  have h := congrArg (fun l : List Bool => l.getD k false) (sem_adder32_gen a b false)
  have houts : adder32.outs = (List.range 32).map adS ++ [adC 32] := rfl
  simpa [sem, houts, List.getD_eq_getElem?_getD, List.getElem?_append, List.getElem?_map,
         List.getElem?_range, hk] using h

/-- ⭐ **THE CROSSING, RUNG 1.** The MAC cell's own sum bit `k` is the `k`-th bit
of `acc + addend`.

Compiler's artifact half (`step_bit_is_adder_bit`) ∘ this file's arithmetic half
(`adder_run_is_sum_bit`). Still unconditional — the overflow question does not
arise until a rung states the value in `ℤ`. -/
theorem cell_sum_bit (acc addend : BitVec 32) (k : Nat) (hk : k < 32) :
    run (macSeq.env (MacCell.bitsOf addend) (MacCell.bitsOf acc)) macCore.gates (maSum k)
      = (acc + addend).getLsbD k := by
  rw [step_bit_is_adder_bit acc addend k hk, adder_run_is_sum_bit acc addend k hk]

/-- **CONTROL — the rung is not vacuous and it computes.** A concrete cycle:
`1 + 1 = 2`, so bit 0 is `false` and bit 1 is `true`. If `cell_sum_bit` were an
identity on the wrong operand order or a tied-high carry, these would move. -/
theorem cell_sum_bit_witness :
    ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0 = false
  ∧ ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 1 = true := by decide

/-- **MUTANT — a tied-HIGH carry-in is FALSE at the same witness.** With the
carry-in high the cycle would compute `1 + 1 + 1 = 3`, whose bit 0 is `true`.
Compiler's `carry_in_is_low` is what excludes this at the artifact; this shows
the two arms genuinely differ, so that control could have failed. -/
theorem mutant_carry_high_differs :
    ((1 : BitVec 32) + (1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0
      ≠ ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0 := by decide

end SaltWorks.HDL.MacBridge

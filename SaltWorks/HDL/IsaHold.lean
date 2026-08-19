/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The HOLD arm of `RegDatapathOK`

`C4Reduction` left `C4Spec core` resting on two sentences, of which `RegDatapathOK` is the
register one. **This file closes half of it** — the half that says the two sides agree about
registers that are NOT being written — and it closes it *unconditionally on the ALU, the
select, the immediate and the adder.*

```
set_regs_of_ne      writing rd leaves any other register alone   (set_regs_zero, generalised)
step_regs_of_ne     an instruction that does not name r holds r
stepT_regs_of_ne    …on WORDS: an undecodable word is a NOP-advance and touches nothing
decQ_reg_bit        decQ reads register r positionally           (decQ_reg0_bit, generalised)
regDatapath_hold_arm   ⇒ enable low + instruction names another register ⇒ SIDES AGREE
```

⇒ ***what remains of `RegDatapathOK` is exactly two things: that the circuit's enable AGREES
with the ISA's write decision, and that the written value is right.*** The third failure
mode — the two disagreeing about the *unwritten* registers — is now excluded outright.

⚠️ **`writesReg` IS AN OVER-APPROXIMATION AND THAT IS DELIBERATE.** `LW`'s trap branch
writes no register, and naming `rd` there would be wrong if the predicate were ever used
positively. It is only ever used in the NEGATIVE direction — *"this instruction does not name
`r`, therefore `r` holds"* — where over-approximating is the safe side. A reader who lifts
`writesReg` into a positive claim will be wrong about `LW`.

*Not C4, not a witness, does not close R9/B2. No new `RegField` is discharged here.*
-/
import SaltWorks.HDL.C4Reduction

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- **The register an instruction may write**, as an over-approximation: `LW`'s trap branch
writes nothing, and naming `rd` there is safe because the claim below is only ever used in
the NEGATIVE direction. `BEQ` and `SW` write no register at all. -/
def writesReg : Instr → Option (Fin 32)
  | .ADD  rd _ _ => some rd
  | .ADDI rd _ _ => some rd
  | .XOR  rd _ _ => some rd
  | .SLT  rd _ _ => some rd
  | .LW   rd _ _ => some rd
  | .BEQ  _ _ _  => none
  | .SW   _ _ _  => none

/-- Writing register `rd` leaves any OTHER register alone. *`set_regs_zero` is this at
`r = 0`; the general form did not exist.* -/
theorem set_regs_of_ne (s : St) (rd : Fin 32) (v : BitVec 32) (r : Fin 32) (h : rd ≠ r) :
    (s.set rd v).regs[r.val] = s.regs[r.val] := by
  by_cases h0 : rd = 0
  · rw [h0, St.set_zero]
  · simp only [St.set, if_neg h0]
    exact Vector.getElem_set_ne rd.isLt r.isLt (fun hh => h (Fin.ext hh))

/-- ⭐ **AN INSTRUCTION THAT DOES NOT NAME `r` LEAVES `r` ALONE.** -/
theorem step_regs_of_ne (s : St) (i : Instr) (r : Fin 32) (h : writesReg i ≠ some r) :
    (step s i).regs[r.val] = s.regs[r.val] := by
  have hne : ∀ rd : Fin 32, writesReg i = some rd → rd ≠ r := by
    intro rd hrd hEq; exact h (by rw [hrd, hEq])
  cases i with
  | ADD rd a b => exact set_regs_of_ne s rd _ r (hne rd rfl)
  | ADDI rd a imm => exact set_regs_of_ne s rd _ r (hne rd rfl)
  | XOR rd a b => exact set_regs_of_ne s rd _ r (hne rd rfl)
  | SLT rd a b => exact set_regs_of_ne s rd _ r (hne rd rfl)
  -- ⚠️ `show (if _ then _ else _).regs[r.val] = _` does NOT elaborate: the underscores leave
  -- the `r.val < 32` index proof unresolvable. Unfolding with `simp only [step]` first keeps
  -- the index concrete.
  | BEQ a b imm =>
      simp only [step]
      split <;> rfl
  | LW rd a imm =>
      simp only [step]
      split
      · exact set_regs_of_ne s rd _ r (hne rd rfl)
      · rfl
  | SW a b imm =>
      simp only [step]
      split <;> rfl

/-- ⭐⭐ **THE HOLD HALF, ON WORDS — `stepT`.** An undecodable word is a NOP-advance and
touches nothing; a decodable one touches only the register it names. -/
theorem stepT_regs_of_ne (s : St) (w : BitVec 32) (r : Fin 32)
    (h : ∀ i, decode w = some i → writesReg i ≠ some r) :
    (stepT s w).regs[r.val] = s.regs[r.val] := by
  cases hd : decode w with
  | none => rw [stepT_undecodable s w hd]; rfl
  | some i =>
      rw [stepT_compat s w (step s i) (by simp [stepW, hd])]
      exact step_regs_of_ne s i r (h i hd)

/-- `decQ` reads register `r`'s bits straight off the input valuation — `decQ_reg0_bit`
generalised off `r = 0`. -/
theorem decQ_reg_bit (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32) :
    ((decQ ins).regs[r.val]).getLsbD k = ins (32 * r.val + k) := by
  have h : (decQ ins).regs[r.val] = wordOf (fun j => ins (32 * r.val + j)) := by
    simp [decQ]
  rw [h, wordOf_getLsbD _ _ hk]

/-- ⭐⭐⭐ **THE HOLD ARM OF `RegDatapathOK`, CLOSED.** When the circuit's enable is low
AND the instruction names another register, the two sides agree — *unconditionally on the
ALU, the select, the immediate, and the adder.*

⇒ ***what remains of `RegDatapathOK` is exactly two things: that the circuit's enable AGREES
with the ISA's write decision, and that the written value is right.*** The third possibility
— that the two disagree about the *unwritten* registers — is now excluded. -/
theorem regDatapath_hold_arm (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (hoff : run ins core.gates (rwOut r.val) = false)
    (hnw : ∀ i, decode (seenWord ins) = some i → writesReg i ≠ some r) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := by
  rw [hoff, if_neg (by simp), stepT_regs_of_ne (decQ ins) (seenWord ins) r hnw,
      decQ_reg_bit ins r k hk]

#audit_axioms set_regs_of_ne step_regs_of_ne stepT_regs_of_ne
#audit_axioms decQ_reg_bit regDatapath_hold_arm

end SaltWorks.HDL.RegNextUniform

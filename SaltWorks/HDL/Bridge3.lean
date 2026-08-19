/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# Bridge 3 — the read-port addresses ARE `decode`'s `rs1` and `rs2`

```
rs1AddrOf_is_decode_field : ((seenWord ins).extractLsb' 15 5).toNat = rs1AddrOf ins
rs2AddrOf_is_decode_field : ((seenWord ins).extractLsb' 20 5).toNat = rs2AddrOf ins
```

`decode` reads `rs1 = toReg (w.extractLsb' 15 5)` and `toReg b = ⟨b.toNat, _⟩`, so these say
the five-bit number this seat assembled from `instrNet (15 + j)` — the wires the read tree
is actually fed, per `core_rd_is_the_instruction`'s sibling — is the field `decode` slices.

**Three of the four pc bridges are now closed.** Remaining: `immOf = bOffset (decoded imm)`,
dispatched to the helm's pool with a written brief at 07:3x.

📌 *The proof shape, since it recurs for any field: bit equality on `j < 5` from
`getLsbD_extractLsb'` + `seenWord_bit` + the address-assembly lemma, then
`Nat.eq_of_testBit_eq` with both sides shown `< 32` to kill `j ≥ 5`. `rs2` is the same file
with `15 ↦ 20`.*

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.PcBridges

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

theorem seenWord_bit (ins : Env) (j : Nat) (hj : j < 32) :
    (seenWord ins).getLsbD j = ins (instrNet j) := by
  rw [seenWord, wordOf_getLsbD _ _ hj]

/-- ⭐ **BRIDGE 3 (rs1): the address the read tree uses IS `decode`'s `rs1` field.** -/
theorem rs1AddrOf_is_decode_field (ins : Env) :
    ((seenWord ins).extractLsb' 15 5).toNat = rs1AddrOf ins := by
  have hb : ∀ j, j < 5 → ((seenWord ins).extractLsb' 15 5).getLsbD j
      = (rs1AddrOf ins).testBit j := by
    intro j hj
    rw [BitVec.getLsbD_extractLsb', seenWord_bit ins (15 + j) (by omega),
        rs1AddrOf_testBit ins j hj]
    simp [hj]
  refine Nat.eq_of_testBit_eq (fun j => ?_)
  by_cases hj : j < 5
  · exact hb j hj
  · have h1 : ((seenWord ins).extractLsb' 15 5).toNat < 32 := by
      have := ((seenWord ins).extractLsb' 15 5).isLt
      simpa using this
    have h2 : rs1AddrOf ins < 32 := rs1AddrOf_lt ins
    have hp : (32 : Nat) ≤ 2 ^ j := by
      calc (32 : Nat) = 2 ^ 5 := by norm_num
        _ ≤ 2 ^ j := Nat.pow_le_pow_right (by norm_num) (by omega)
    rw [Nat.testBit_eq_false_of_lt (by omega), Nat.testBit_eq_false_of_lt (by omega)]

/-- ⭐ **BRIDGE 3 (rs2): the address the read tree uses IS `decode`'s `rs2` field.** -/
theorem rs2AddrOf_is_decode_field (ins : Env) :
    ((seenWord ins).extractLsb' 20 5).toNat = rs2AddrOf ins := by
  have hb : ∀ j, j < 5 → ((seenWord ins).extractLsb' 20 5).getLsbD j
      = (rs2AddrOf ins).testBit j := by
    intro j hj
    rw [BitVec.getLsbD_extractLsb', seenWord_bit ins (20 + j) (by omega),
        rs2AddrOf_testBit ins j hj]
    simp [hj]
  refine Nat.eq_of_testBit_eq (fun j => ?_)
  by_cases hj : j < 5
  · exact hb j hj
  · have h1 : ((seenWord ins).extractLsb' 20 5).toNat < 32 := by
      have := ((seenWord ins).extractLsb' 20 5).isLt
      simpa using this
    have h2 : rs2AddrOf ins < 32 := rs2AddrOf_lt ins
    have hp : (32 : Nat) ≤ 2 ^ j := by
      calc (32 : Nat) = 2 ^ 5 := by norm_num
        _ ≤ 2 ^ j := Nat.pow_le_pow_right (by norm_num) (by omega)
    rw [Nat.testBit_eq_false_of_lt (by omega), Nat.testBit_eq_false_of_lt (by omega)]

#audit_axioms seenWord_bit rs1AddrOf_is_decode_field rs2AddrOf_is_decode_field

end SaltWorks.HDL.RegNextUniform

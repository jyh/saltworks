/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The ENABLE arm's circuit half, in closed form

`EnableArm` transported `rwOut k` into `core`; this file says what it EQUALS.

```
core_rwOut_spec :  run ins core.gates (rwOut k)
                     = validOf ins && !isBEQOf ins && (rdOf ins == k) && !(k == 0)
```

**Every ingredient is a read, and one of them is a bare wire.** `rdOf` is the instruction
word's own bits 7…11 assembled as a number — no decoder between them
(`core_rd_is_the_instruction`). `validOf`/`isBEQOf` are decoder outputs 5 and 4. The step
that makes it exact is `regWrite_correct`, the landed exhaustive check over all
32 × 2 × 2 = 128 control combinations, unpacked here into a usable equation
(`weOf_eq_weSpec`) and lifted onto `core`'s environment through
`run_agree_of_inputs_circ`.

⛔ **WHAT REMAINS OF THE ENABLE ARM — one thing, named.** `validOf` and `isBEQOf` are still
*circuit reads*, not ISA facts. Connecting them to `decode (seenWord ins)` is the decoder's
correctness, and it is not done here. Until it is, this theorem says the enable matches
`weSpec`'s SHAPE, not that it matches the ISA's write decision.

*Not C4, not a witness, does not close R9/B2. No new `RegField` is discharged.*
-/
import SaltWorks.HDL.EnableArm
import SaltWorks.HDL.SeamTrace

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- The `rd` index as the instruction word presents it — bits 7…11, read as a number. -/
def rdOf (ins : Env) : Nat :=
  (if ins (instrNet 7) then 1 else 0) + (if ins (instrNet 8) then 2 else 0)
  + (if ins (instrNet 9) then 4 else 0) + (if ins (instrNet 10) then 8 else 0)
  + (if ins (instrNet 11) then 16 else 0)

/-- ⛔ `validOf` READS `decOut 8`, WHICH MEANS "DECODES" — true on every decodable word,
STORES INCLUDED. **It no longer drives the enable.** Kept because `DecoderTransport` states its
`ctrlSpec` bridge over it and that bridge is still true and still useful. -/
def validOf (ins : Env) : Bool := run ins coreThru13 (decOut validLine)
def isBEQOf (ins : Env) : Bool := run ins coreThru13 (decOut isBEQLine)

/-! ### The five WRITE flags — what the enable reads after the 2026-08-19 repair. -/
def isADDOf  (ins : Env) : Bool := run ins coreThru13 (decOut isADDLine)
def isXOROf  (ins : Env) : Bool := run ins coreThru13 (decOut isXORLine)
def isSLTOf  (ins : Env) : Bool := run ins coreThru13 (decOut isSLTLine)
def isADDIOf (ins : Env) : Bool := run ins coreThru13 (decOut isADDILine)
def isLWOf   (ins : Env) : Bool := run ins coreThru13 (decOut isLWLine)

/-- **The disjunction the enable now computes**: "this instruction writes a register". -/
def writesRegOf (ins : Env) : Bool :=
  isADDOf ins || isXOROf ins || isSLTOf ins || isADDIOf ins || isLWOf ins

theorem rdOf_lt (ins : Env) : rdOf ins < 32 := by
  cases h7 : ins (instrNet 7) <;> cases h8 : ins (instrNet 8) <;> cases h9 : ins (instrNet 9) <;>
    cases h10 : ins (instrNet 10) <;> cases h11 : ins (instrNet 11) <;>
    simp [rdOf, h7, h8, h9, h10, h11]

theorem rdOf_testBit (ins : Env) (j : Nat) (hj : j < 5) :
    (rdOf ins).testBit j = ins (instrNet (7 + j)) := by
  cases hb7 : ins (instrNet 7) <;> cases hb8 : ins (instrNet 8) <;>
    cases hb9 : ins (instrNet 9) <;> cases hb10 : ins (instrNet 10) <;>
    cases hb11 : ins (instrNet 11) <;>
    interval_cases j <;>
    -- ⚠️ `simp` alone leaves `ins (instrNet (7 + 1))` unmatched against `ins (instrNet 8)`:
    -- the literal addition in the INDEX has to be reduced first. `norm_num` does both.
    norm_num [rdOf, hb7, hb8, hb9, hb10, hb11] <;> decide

/-- The environment `regWrite` sees inside `core` IS the canonical one `weOf` is stated over. -/
theorem envRW_agrees (ins : Env) (i : Nat) (hi : i < regWrite.nIn) :
    run ins coreThru13 (regWriteSig i)
      = (fun n => if n < 5 then (rdOf ins).testBit n
                  else if n == 5 then isADDOf ins
                  else if n == 6 then isBEQOf ins
                  else if n == 7 then isXOROf ins
                  else if n == 8 then isSLTOf ins
                  else if n == 9 then isADDIOf ins else isLWOf ins) i := by
  have h7 : regWrite.nIn = 11 := by decide +kernel
  rw [h7] at hi
  interval_cases i
  · rw [show regWriteSig 0 = rdBit 0 from rfl, core_rd_is_the_instruction ins 0 (by omega)]
    simp [rdOf_testBit ins 0 (by omega)]
  · rw [show regWriteSig 1 = rdBit 1 from rfl, core_rd_is_the_instruction ins 1 (by omega)]
    simp [rdOf_testBit ins 1 (by omega)]
  · rw [show regWriteSig 2 = rdBit 2 from rfl, core_rd_is_the_instruction ins 2 (by omega)]
    simp [rdOf_testBit ins 2 (by omega)]
  · rw [show regWriteSig 3 = rdBit 3 from rfl, core_rd_is_the_instruction ins 3 (by omega)]
    simp [rdOf_testBit ins 3 (by omega)]
  · rw [show regWriteSig 4 = rdBit 4 from rfl, core_rd_is_the_instruction ins 4 (by omega)]
    simp [rdOf_testBit ins 4 (by omega)]
  · simp [isADDOf,  show regWriteSig 5  = decOut isADDLine from rfl]
  · simp [isBEQOf,  show regWriteSig 6  = decOut isBEQLine from rfl]
  · simp [isXOROf,  show regWriteSig 7  = decOut isXORLine from rfl]
  · simp [isSLTOf,  show regWriteSig 8  = decOut isSLTLine from rfl]
  · simp [isADDIOf, show regWriteSig 9  = decOut isADDILine from rfl]
  · simp [isLWOf,   show regWriteSig 10 = decOut isLWLine from rfl]

theorem regWrite_out_bound (k : Nat) (hk : k < 32) :
    regWrite.outs.getD k 0 < regWrite.nIn + regWrite.gates.length := by
  revert k; decide +kernel

/-- ⭐⭐ **THE ENABLE, AS `weOf`.** -/
theorem core_rwOut_eq_weOf (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (rwOut k)
      = (weOf (rdOf ins) (isADDOf ins) (isBEQOf ins) (isXOROf ins) (isSLTOf ins)
              (isADDIOf ins) (isLWOf ins)).getD k false := by
  -- ⚠️ `weOf` is stated over the PACKED evaluator now, so `semB_eq` carries it back to `sem`
  -- before the output map can be unfolded.
  rw [core_rwOut_transport ins k hk, weOf, semB_eq, sem]
  rw [getD_map_lt _ _ _ (by rw [regWrite_outs_len]; exact hk) 0 false]
  refine run_agree_of_inputs_circ regWrite regWrite_ssa _ _ (fun a ha => ?_) _
    (regWrite_out_bound k hk)
  have hn : regWrite.nIn = 11 := by decide +kernel
  rw [hn] at ha
  rw [envRW_agrees ins a (by rw [hn]; exact ha),
      rwPack_testBit (rdOf ins) (rdOf_lt ins) _ _ _ _ _ _ a ha]

/-- `regWrite_correct`'s exhaustive 128-case check, unpacked into a usable equation. -/
theorem weOf_eq_weSpec (rd : Nat) (hrd : rd < 32) (a b c d e f : Bool) :
    weOf rd a b c d e f = weSpec rd a b c d e f := by
  have h := regWrite_correct
  rw [weOK] at h
  have h1 := List.all_eq_true.mp h rd (List.mem_range.mpr hrd)
  have h2 := List.all_eq_true.mp h1 a (by cases a <;> simp)
  have h3 := List.all_eq_true.mp h2 b (by cases b <;> simp)
  have h4 := List.all_eq_true.mp h3 c (by cases c <;> simp)
  have h5 := List.all_eq_true.mp h4 d (by cases d <;> simp)
  have h6 := List.all_eq_true.mp h5 e (by cases e <;> simp)
  have h7 := List.all_eq_true.mp h6 f (by cases f <;> simp)
  exact eq_of_beq h7

/-- ⭐⭐⭐ **THE ENABLE ARM'S CIRCUIT HALF, CLOSED FORM.** `core`'s write enable for register
`k` is exactly the ISA's write predicate over three reads — and `rd` is the instruction
word's own bits 7…11, with no decoder between them. -/
theorem core_rwOut_spec (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (rwOut k)
      = (writesRegOf ins && !(isBEQOf ins) && (rdOf ins == k) && !(k == 0)) := by
  rw [core_rwOut_eq_weOf ins k hk,
      weOf_eq_weSpec _ (rdOf_lt ins) _ _ _ _ _ _, weSpec, writesRegOf,
      getD_map_lt _ _ _ (by simpa using hk) 0 false]
  -- the `weSpec` row index is a `List.range` lookup; `hk` is what lets it reduce to `k`.
  simp [hk]

#audit_axioms rdOf_lt rdOf_testBit envRW_agrees core_rwOut_eq_weOf
#audit_axioms isADDOf isXOROf isSLTOf isADDIOf isLWOf writesRegOf
#audit_axioms weOf_eq_weSpec core_rwOut_spec


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.regWrite_out_bound
end SaltWorks.HDL.RegNextUniform

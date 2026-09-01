/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat
-/
import SaltWorks.HDL.LwTrapRefuted
import SaltWorks.HDL.StallShape
import SaltWorks.Certs.R9IdentityBridge

namespace SaltWorks.HDL.LwNotStallShaped

open SaltWorks.HDL SaltWorks.ISA SaltWorks.HDL.CorePlace
open SaltWorks.HDL.C4Refuted SaltWorks.HDL.LwTrapRefuted
-- ⛔ NO `open SaltWorks.Stack.Program`: it makes `seenWord` AMBIGUOUS (two constants,
-- one name) and silently sorry-fills. Qualify.

set_option maxRecDepth 8000

/-! ### THE PLUMBING — one cycle of the induced map, read at a register bit. -/

theorem decQ_cycOfCirc_regs_bit (c : Circ) (ins : Env)
    (hlen : SaltWorks.HDL.stWidth ≤ (SaltWorks.HDL.sem c ins).length)
    (nextW : Env → SaltWorks.Stack.Word) (pad : Env) (r k : Nat) (hr : r < 32) (hk : k < 32) :
    (((SaltWorks.HDL.decQ (SaltWorks.Stack.Program.cycOfCirc c nextW pad ins)).regs[r]'(by
        simpa using hr)).getLsbD k)
      = SaltWorks.Stack.Program.outBit c ins (32 * r + k) := by
  -- `cycOfCirc c nextW pad ins` is DEFEQ to `envOfBits (sem c ins) pad (nextW ins)`, so the
  -- padding lemma applies without unfolding a single definition by `rw`.
  have hcyc : SaltWorks.Stack.Program.cycOfCirc c nextW pad ins
      = SaltWorks.Stack.Program.envOfBits (SaltWorks.HDL.sem c ins) (fun _ => false) (nextW ins) :=
    SaltWorks.Stack.Program.envOfBits_of_length hlen pad (fun _ => false) (nextW ins)
  rw [hcyc]
  simp only [SaltWorks.HDL.decQ, Vector.getElem_ofFn]
  rw [SaltWorks.HDL.wordOf_getLsbD _ _ hk]
  show (if 32 * r + k < SaltWorks.HDL.stWidth
        then (SaltWorks.HDL.sem c ins).getD (32 * r + k) false
        else _) = _
  rw [if_pos (by unfold SaltWorks.HDL.stWidth; omega)]
  rfl

theorem sem_core_length (ins : Env) :
    SaltWorks.HDL.stWidth ≤ (SaltWorks.HDL.sem core ins).length := by
  rw [SaltWorks.HDL.sem, List.length_map, core_outs_length]

/-! ### THE THREE READINGS AT `insL`, EACH ONE A SEPARATE FACT. -/

/-- The core puts the ADDRESS on the write bank: `x1` bit 3 comes out **set**. -/
theorem core_bit_insL (nextW : Env → SaltWorks.Stack.Word) (pad : Env) :
    (((SaltWorks.HDL.decQ (SaltWorks.Stack.Program.cycOfCirc core nextW pad insL)).regs[r1.val]'(by
        exact r1.isLt)).getLsbD 3) = true := by
  rw [decQ_cycOfCirc_regs_bit core insL (sem_core_length insL) nextW pad r1.val 3 r1.isLt (by omega)]
  rw [SaltWorks.HDL.RegNextUniform.core_outBit_reg_reduced insL r1.val 3 r1.isLt (by omega)]
  rw [rw_insL, if_pos rfl]
  exact SaltWorks.HDL.LwTrapRefuted.Addenda.sel3_insL

/-- The ISA loads the constant `0`: `x1` bit 3 goes **clear**. -/
theorem isa_bit_insL :
    (((SaltWorks.ISA.stepT (SaltWorks.HDL.decQ insL)
        (SaltWorks.HDL.seenWord insL)).regs[r1.val]'(by exact r1.isLt)).getLsbD 3) = false :=
  SaltWorks.HDL.LwTrapRefuted.Addenda.isa3_insL

/-- ⭐ **THE READING THE 08-29 RETIREMENT NEVER TOOK: the PRIOR value.** `x1 = 4`, so
bit 3 is **clear** going in. *This is the fact that closes the stall branch, and no
theorem in the tree stated it before this file.* -/
theorem prior_bit_insL :
    (((SaltWorks.HDL.decQ insL).regs[r1.val]'(by exact r1.isLt)).getLsbD 3) = false := by
  decide +kernel

/-! ### ⭐⭐ CLAIM A — NO CHOICE OF STALL SET RESCUES THE CORE.

*The pre-registered load-bearing claim. `stalls`, `nextW` and `pad` are the parts R10 owns,
so they are UNIVERSALLY QUANTIFIED here: R10's wording instantiates this theorem, it cannot
refute it.* -/
theorem core_refutes_every_stall_arm (nextW : Env → SaltWorks.Stack.Word) (pad : Env)
    (stalls : Env → Bool) :
    ¬ SaltWorks.HDL.StallShape.CycleRealisesStepOrStalls
        (SaltWorks.Stack.Program.cycOfCirc core nextW pad)
        SaltWorks.Stack.Program.seenWord stalls := by
  intro h
  have hh := h insL
  rw [SaltWorks.Stack.Program.seenWord_eq_hdl] at hh
  by_cases hs : stalls insL = true
  · -- THE STALL BRANCH. The core does not HOLD `x1`: it writes the address.
    rw [if_pos hs] at hh
    have hb := congrArg (fun v => (v[r1.val]'r1.isLt).getLsbD 3) hh.1
    rw [core_bit_insL nextW pad, prior_bit_insL] at hb
    exact Bool.noConfusion hb
  · -- THE STEP BRANCH. The core does not REALISE the step: the landed 08-29 witness.
    rw [if_neg hs] at hh
    have hb := congrArg (fun v => (v[r1.val]'r1.isLt).getLsbD 3) hh.1
    rw [core_bit_insL nextW pad, isa_bit_insL] at hb
    exact Bool.noConfusion hb

/-! ### ⭐ CLAIM B — THE DIFFERENTIAL AIMED AT MY OWN READING OF R10.

*Pre-registered EXPECTING `false`, and pre-registered to be reported either way. If the
witness had been memory-free, a memory-free scope could not exclude it and R10 could not
dispose the LW row by scoping at all.* -/
theorem witness_is_not_memFree :
    ¬ SaltWorks.Stack.Program.MemFree (SaltWorks.HDL.seenWord insL) := by
  intro h
  have hf := h (SaltWorks.ISA.Instr.LW 1 2 4) dec_insL
  exact absurd hf (by decide)

/-! ### THE MUST-BREAK CONTROLS. A claim with no failing arm is not tested. -/

/-- **C1 — the restated predicate is a real WEAKENING, not a broken one:** the IDEAL core
still satisfies it at the empty stall set. If this failed, the file's predicate would not be
the landed one weakened, and claim A would be refuting the wrong object. -/
theorem control_C1_ideal_core_still_satisfies (nextW : Env → SaltWorks.Stack.Word) (pad : Env) :
    SaltWorks.HDL.StallShape.CycleRealisesStepOrStalls
      (SaltWorks.Stack.Program.cycOfBits SaltWorks.Stack.Program.idealBits nextW pad)
      SaltWorks.Stack.Program.seenWord (fun _ => false) :=
  (SaltWorks.HDL.StallShape.stallArm_reduces _ _).mpr
    (SaltWorks.Stack.Program.cycleRealisesStep_idealBits nextW pad)

/-- **C2 — the predicate is not degenerate:** one and the same cycle map is ADMITTED with
every cycle declared a stall and REFUTED with none. *Landed at `StallShape.lean:156`; named
here because a control cited but not run is not a control.* -/
theorem control_C2_not_degenerate (nextW : Env → SaltWorks.Stack.Word) (pad : Env) :
    SaltWorks.HDL.StallShape.CycleRealisesStepOrStalls
        (SaltWorks.Stack.Program.cycOfBits SaltWorks.Stack.Program.stalledBits nextW pad)
        SaltWorks.Stack.Program.seenWord (fun _ => true)
      ∧ ¬ SaltWorks.HDL.StallShape.CycleRealisesStepOrStalls
        (SaltWorks.Stack.Program.cycOfBits SaltWorks.Stack.Program.stalledBits nextW pad)
        SaltWorks.Stack.Program.seenWord (fun _ => false) :=
  ⟨(SaltWorks.HDL.StallShape.stallArm_strictly_extends nextW pad).1,
   fun h => (SaltWorks.HDL.StallShape.stallArm_strictly_extends nextW pad).2
     ((SaltWorks.HDL.StallShape.stallArm_reduces _ _).mp h)⟩

/-- ⛔ **C3 — THE INSTRUMENT IS NOT A BLANKET REFUTER.** The SAME plumbing lemma claim A
rests on, driven at bit 2 of the same register at the same witness, reports **AGREEMENT**.
*Without this, claim A's `true ≠ false` could be an artefact of `decQ_cycOfCirc_regs_bit`
rather than a fact about the core.* -/
theorem control_C3_instrument_can_agree (nextW : Env → SaltWorks.Stack.Word) (pad : Env) :
    (((SaltWorks.HDL.decQ (SaltWorks.Stack.Program.cycOfCirc core nextW pad insL)).regs[r1.val]'(by
        exact r1.isLt)).getLsbD 2)
      = (((SaltWorks.ISA.stepT (SaltWorks.HDL.decQ insL)
          (SaltWorks.HDL.seenWord insL)).regs[r1.val]'(by exact r1.isLt)).getLsbD 2) := by
  rw [decQ_cycOfCirc_regs_bit core insL (sem_core_length insL) nextW pad r1.val 2 r1.isLt (by omega)]
  rw [SaltWorks.HDL.RegNextUniform.core_outBit_reg_reduced insL r1.val 2 r1.isLt (by omega)]
  exact lw_sides_agree_at_insL

/-! ### ⭐⭐ THE COHERENCE CHECK — CLAIM A **SUBSUMES** THE LANDED REFUTATION.

*Not a new result: `¬ C4Spec core` is already landed at `not_c4Spec_core_at_the_landed_witness`
through `RegDatapathOK`. This re-derives the SAME conclusion by an INDEPENDENT route — claim A
at the empty stall set, through `stallArm_reduces` (`Iff.rfl`) and the contraposed bridge. Two
routes to one conclusion is the check that claim A is about the flagship and not about a
predicate of its own invention.* -/
theorem not_c4Spec_core_via_the_stall_arm (nextW : Env → SaltWorks.Stack.Word) (pad : Env) :
    ¬ SaltWorks.HDL.C4Spec core :=
  SaltWorks.Stack.Program.not_C4Spec_of_not_cycleRealises nextW pad
    (fun h => core_refutes_every_stall_arm nextW pad (fun _ => false)
      ((SaltWorks.HDL.StallShape.stallArm_reduces _ _).mpr h))

#audit_axioms not_c4Spec_core_via_the_stall_arm
#audit_axioms decQ_cycOfCirc_regs_bit sem_core_length
#audit_axioms core_bit_insL isa_bit_insL prior_bit_insL
#audit_axioms core_refutes_every_stall_arm
#audit_axioms witness_is_not_memFree
#audit_axioms control_C1_ideal_core_still_satisfies control_C2_not_degenerate
#audit_axioms control_C3_instrument_can_agree

end SaltWorks.HDL.LwNotStallShaped

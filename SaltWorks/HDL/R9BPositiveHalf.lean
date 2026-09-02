/-
  ⭐⭐⭐ R9b — THE POSITIVE HALF, INHABITED.

  `THE_POSITIVE_HALF`: for every next-word policy and every pad, the composed `core`'s
  induced cycle map SATISFIES the scoped stall-armed predicate at the memory-free scope.

  ⛔⛔ READ THE FOUR LIMITS BEFORE THE HEADLINE. Each is a real restriction, and each is
  stated here rather than left for a reader to discover in the statement:

  1. THE OBJECT IS RATIFIED, AND RATIFIED IS NOT THE SAME AS CLOSED. The R10 sitting of
     2026-09-02 (helm minute, bare filename `2026-09-02-R10-SITTING-minute.md`, private
     record) ADOPTED R10-3 as drafted at `docs/R10-SITTING-TABLE-0902.md` §B.1, and the
     adoption IS the move of `CycleRealisesStepOrStallsOn` and `memFreeB` into
     `HDL/StallShape.lean` §0.2. So this file no longer inhabits a draft sentence. ⛔ WHAT
     THAT DOES **NOT** BUY: the object is `CorePlace.core`, the LEAN-COMPOSED circuit — not
     `core32.v`, the hand-written RTL that was fabricated — and no theorem in this tree
     relates the two. Rung 2.5; RTL correspondence OPEN. *Ratification moved the modal
     status of this instance and moved nothing about its object.*
     📜 HISTORY: until the sitting sat this limit read "THE OBJECT IS A DRAFT … not as
     ratified", and warned that a restatement would kill the instance and leave
     `R9BPositiveReduction` (quantified over `scope`) as the survivor. The restatement did
     not come. That reduction is still the general result and this is still the instance.
  2. THE STALL SET IS EMPTY, and that is the core's own declaration, not a convenience:
     `core` is single-cycle, every cycle retires, so R10-2's `stalls := ¬ retire` is empty
     here. A LATER CORE WITH ARBITRATION MAKES THIS INSTANCE FALSE while leaving every
     theorem it rests on true, because they are quantified over `stalls`.
  3. `C4Spec core` IS STILL FALSE, UNSCOPED, AND NOTHING BELOW TOUCHES THAT. The landed
     refutation runs through `insL`, a memory-touching word this scope excludes. What is
     proved is the SCOPED flagship and nothing wider.
  4. `C4SpecD core` STAYS REFUTED under every scope — a width argument with no witness in
     it. Nobody may carry anything from this file to the D form.

  ⭐ NOTHING HERE IS A NEW DATAPATH PROOF. All four value rows were already landed, under
  FOUR DIFFERENT SPELLINGS across four files, and the files themselves say so
  (`SelValueADDI.lean:574` prints the table). What was missing was the assembly and the
  scope. ⛔ AND THE FOUR SPELLINGS ARE WHY THIS TOOK SIXTEEN DAYS LONGER THAN IT NEEDED TO:
  a grep for `core_selOut_is_isa*` finds ADDI and XOR and MISSES ADD and SLT, and I filed
  both as gaps on that evidence before reading the conclusion shapes instead of the names.
  A NAME GREP CANNOT SEE A THEOREM THAT IS ALREADY PROVED UNDER ANOTHER NAME.
-/
import SaltWorks.HDL.R9BPositiveReduction
import SaltWorks.HDL.EnableWriters
import SaltWorks.HDL.EnableNonWriters
import SaltWorks.HDL.EnableX0
import SaltWorks.HDL.SelValueADDI
import SaltWorks.HDL.SelValueXOR
import SaltWorks.HDL.SelValueADD
import SaltWorks.HDL.SelValueSLTBit0
import SaltWorks.HDL.LwNotStallShaped

namespace SaltWorks.HDL.R9BPositiveHalf

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program
open SaltWorks.HDL.StallShape SaltWorks.HDL.MemFreeScope SaltWorks.HDL.R9BPositiveReduction
open SaltWorks.HDL.CorePlace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL.RegNextUniform.Writers SaltWorks.HDL.RegNextUniform.NonWriters
open SaltWorks.HDL.RegNextUniform.XOR

def ValueRowADD : Prop :=
  ∀ (ins : SaltWorks.HDL.Env) (rd a b : Fin 32) (k : Nat), k < 32 → rd ≠ 0 →
    SaltWorks.ISA.decode (seenWord ins) = some (.ADD rd a b) →
    run ins core.gates (selOut k)
      = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k

def ValueRowSLT : Prop :=
  ∀ (ins : SaltWorks.HDL.Env) (rd a b : Fin 32) (k : Nat), k < 32 → rd ≠ 0 →
    SaltWorks.ISA.decode (seenWord ins) = some (.SLT rd a b) →
    run ins core.gates (selOut k)
      = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k

theorem regDatapathOKOn_memFree_of_ADD_and_SLT (hA : ValueRowADD) (hS : ValueRowSLT) :
    RegDatapathOKOn (fun ins => memFreeB (seenWord ins)) := by
  intro ins hs r k hk
  have hmf : MemFree (seenWord ins) := (memFreeB_iff _).mp hs
  cases hd : SaltWorks.ISA.decode (seenWord ins) with
  | none => exact regDatapath_on_isa_nonwriter ins r k hk (garbage_is_a_nonwriter _ hd)
  | some i =>
      have hmem : SaltWorks.ISA.touchesMem i = false := hmf i hd
      refine regDatapath_enable_arm ins i r k hk hd hmem ?_
      intro hw hz
      have hr0 : r ≠ 0 := fun h => hz (by simp [h])
      cases i with
      | ADD rd a b =>
          have hrd : rd = r := by simpa [writesReg] using hw
          subst hrd
          exact hA ins rd a b k hk hr0 hd
      | ADDI rd a im =>
          have hrd : rd = r := by simpa [writesReg] using hw
          subst hrd
          exact SaltWorks.HDL.RegNextUniform.ADDI.core_selOut_is_isa_ADDI ins rd a im k hk hr0 hd
      | XOR rd a b =>
          have hrd : rd = r := by simpa [writesReg] using hw
          subst hrd
          exact core_selOut_is_isa_write_on_XOR ins rd a b k hk hd hr0
      | SLT rd a b =>
          have hrd : rd = r := by simpa [writesReg] using hw
          subst hrd
          exact hS ins rd a b k hk hr0 hd
      | BEQ a b im => simp [writesReg] at hw
      | LW rd a im => simp [SaltWorks.ISA.touchesMem] at hmem
      | SW a b im => simp [SaltWorks.ISA.touchesMem] at hmem

theorem valueRowADD_landed : ValueRowADD :=
  fun ins rd a b k hk hrd h =>
    SaltWorks.HDL.RegNextUniform.ADD.selOut_is_isa_written_bit_ADD ins rd a b k hk hrd h

theorem valueRowSLT_landed : ValueRowSLT :=
  fun ins rd a b k hk hrd h =>
    SaltWorks.HDL.RegNextUniform.SLTBit0.core_selOut_eq_isa_slt ins hrd k hk h

theorem THE_SCOPED_OBLIGATION : RegDatapathOKOn (fun ins => memFreeB (seenWord ins)) :=
  regDatapathOKOn_memFree_of_ADD_and_SLT valueRowADD_landed valueRowSLT_landed

theorem THE_POSITIVE_HALF (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStallsOn (fun ins => memFreeB (seenWord ins))
      (cycOfCirc core nextW pad) seenWord (fun _ => false) :=
  positive_half_at_the_memory_free_scope THE_SCOPED_OBLIGATION nextW pad

theorem the_scope_is_doing_the_work (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStallsOn (fun ins => memFreeB (seenWord ins))
        (cycOfCirc core nextW pad) seenWord (fun _ => false)
      ∧ ¬ CycleRealisesStepOrStallsOn (fun _ => true)
        (cycOfCirc core nextW pad) seenWord (fun _ => false) :=
  ⟨THE_POSITIVE_HALF nextW pad,
   fun h => SaltWorks.HDL.LwNotStallShaped.core_refutes_every_stall_arm nextW pad (fun _ => false)
     ((scopedOn_reduces (cycOfCirc core nextW pad) seenWord (fun _ => false)).mp h)⟩

set_option maxRecDepth 20000 in
theorem realises_at_insI (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    (SaltWorks.HDL.decQ (cycOfCirc core nextW pad SaltWorks.HDL.C4Refuted.insI)).regs
        = (stepT (SaltWorks.HDL.decQ SaltWorks.HDL.C4Refuted.insI)
            (seenWord SaltWorks.HDL.C4Refuted.insI)).regs
      ∧ (SaltWorks.HDL.decQ (cycOfCirc core nextW pad SaltWorks.HDL.C4Refuted.insI)).pc
        = (stepT (SaltWorks.HDL.decQ SaltWorks.HDL.C4Refuted.insI)
            (seenWord SaltWorks.HDL.C4Refuted.insI)).pc := by
  have h := THE_POSITIVE_HALF nextW pad SaltWorks.HDL.C4Refuted.insI
  simp only [memFreeB_seenWord_insI_true, if_true, Bool.false_eq_true, if_false] at h
  exact h

#audit_axioms regDatapathOKOn_memFree_of_ADD_and_SLT
#audit_axioms valueRowADD_landed valueRowSLT_landed
#audit_axioms THE_SCOPED_OBLIGATION THE_POSITIVE_HALF
#audit_axioms the_scope_is_doing_the_work realises_at_insI

end SaltWorks.HDL.R9BPositiveHalf

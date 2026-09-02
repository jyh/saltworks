/-
  THE OBJECTS R10-3 NAMES, BUILT SO THE SENTENCE IS ADOPTABLE.

  silicon's draft R10-3 (docs/R10-SITTING-TABLE-0902.md §B.1, saltworks 2710f8b) reads
  "with `scope ins := memFreeB (wordAt ins)`, the decidable Bool of `MemFree`". There was
  no `memFreeB` in this tree when that was written: `MemFree` is a `Prop`, `touchesMem` is
  the only Bool nearby, and no decidability instance or Bool twin was landed anywhere.
  A ratified sentence naming a constant that does not exist is an obligation wearing a
  definition's clothes, and the sitting cannot tell the two apart from the text.

  ⛔ THIS FILE DOES NOT RATIFY ANYTHING. The tracked home of the flagship's shape is
  `HDL/StallShape.lean` ("defined ONCE, here, and tracked"), and the scoped definition
  belongs there IF AND ONLY IF the sitting adopts it. It sits here, in its own module,
  precisely so that adopting it is a decision somebody makes rather than a fact somebody
  inherits from my landing.

  ⛔⛔ AND IT IS NOT R9b's POSITIVE HALF. Putting `insL` outside the scope shows the scoped
  sentence is not refuted BY THAT WITNESS. INHABITING it means proving the core realises
  `stepT` at EVERY in-scope environment, which is the work R10's close dates. Nothing below
  quantifies over the in-scope environments at all.
-/
import SaltWorks.HDL.StallShape
import SaltWorks.HDL.C4Refuted

namespace SaltWorks.HDL.MemFreeScope

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program SaltWorks.HDL.StallShape

/-! ### §1 — `memFreeB`, and the theorem that pins it to `MemFree`.

A Bool and a Prop that are meant to be the same fact drift silently unless something
holds them together. The iff below is that something: it is what makes it safe for R10-3
to say "the decidable Bool of `MemFree`" rather than "a Bool I believe agrees with it".
-/

/-- **The decidable Bool of `MemFree`.** An undecodable word is memory-free — it is a
NOP-advance, exactly as `MemFree`'s own docstring says. -/
def memFreeB (w : Word) : Bool :=
  match SaltWorks.ISA.decode w with
  | some i => !(SaltWorks.ISA.touchesMem i)
  | none   => true

/-- ⭐ **THE PIN. `memFreeB` IS `MemFree`, both directions, kernel-checked.** Without this
the Bool in R10-3's scope and the Prop in the frame lemmas are two objects sharing a name. -/
theorem memFreeB_iff (w : Word) : memFreeB w = true ↔ MemFree w := by
  constructor
  · intro hb i hi
    unfold memFreeB at hb
    rw [hi] at hb
    simpa using hb
  · intro hp
    unfold memFreeB
    cases hd : SaltWorks.ISA.decode w with
    | none => rfl
    | some i => simpa using hp i hd

/-! ### §2 — the scoped predicate, in silicon's name for it and in the Bool spelling. -/

/-- **R10-3's definition, verbatim in shape.** Bool-valued scope, `if … then … else True`,
which is the spelling `ScopeShapeDifferential` measured: it keeps the reduction DEFEQ. -/
def CycleRealisesStepOrStallsOn (scope : SaltWorks.HDL.Env → Bool)
    (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) : Prop :=
  ∀ ins,
    if scope ins then
      (if stalls ins then
        (SaltWorks.HDL.decQ (cyc ins)).regs = (SaltWorks.HDL.decQ ins).regs
          ∧ (SaltWorks.HDL.decQ (cyc ins)).pc = (SaltWorks.HDL.decQ ins).pc
      else
        (SaltWorks.HDL.decQ (cyc ins)).regs
            = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).regs
          ∧ (SaltWorks.HDL.decQ (cyc ins)).pc
            = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).pc)
    else True

/-- ⭐ **THE PROPERTY THE TWENTY-DECLARATION CONE RESTS ON, PRESERVED.** At the everywhere-
true scope the scoped definition is DEFEQ to the landed one, so `stallArm_reduces` still
composes and no consumer that leaned on `Iff.rfl` has to be re-read. -/
theorem scopedOn_reduces (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) :
    CycleRealisesStepOrStallsOn (fun _ => true) cyc wordAt stalls
      ↔ CycleRealisesStepOrStalls cyc wordAt stalls :=
  Iff.rfl

/-- **And the whole way down to today's predicate, in one statement.** The scoped form at
the everywhere-true scope and the EMPTY stall set gives back `CycleRealisesStepProj`. -/
theorem scopedOn_reduces_all_the_way (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) :
    CycleRealisesStepOrStallsOn (fun _ => true) cyc wordAt (fun _ => false)
      ↔ CycleRealisesStepProj cyc wordAt :=
  Iff.rfl

/-! ### §3 — THE SCOPE BITES, AND IT DOES NOT BITE EVERYWHERE.

R10-3's "why this is honest" paragraph rests on `insL` being outside the scope. That is
stated here as a kernel fact rather than left as a corollary a reader assembles. ⛔ And it
is stated BESIDE its non-vacuity control, because a scope that excluded everything would
make the scoped sentence vacuously true and R10-3 would claim nothing at all.
-/

/-- ⭐ **THE LANDED LW WITNESS IS OUTSIDE THE SCOPE.** -/
theorem memFreeB_seenWord_insL_false :
    memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insL) = false := by
  rw [SaltWorks.Stack.Program.seenWord_eq_hdl]
  unfold memFreeB
  rw [SaltWorks.HDL.C4Refuted.dec_insL]
  rfl

/-- ⛔⛔ **THE NON-VACUITY CONTROL, ON THE SAME CHANNEL AND THE SAME REGISTER.** `insI` is
the landed ADDI witness; its word is IN the scope. Without this the whole scoped sentence
could hold because the scope is empty, and an empty scope passes every check R10-3 asks
for while claiming nothing. Same `seenWord`, same shape of environment, opposite verdict. -/
theorem memFreeB_seenWord_insI_true :
    memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insI) = true := by
  rw [SaltWorks.Stack.Program.seenWord_eq_hdl]
  unfold memFreeB
  rw [SaltWorks.HDL.C4Refuted.dec_insI]
  rfl

/-- **The two together, as the discriminating pair R10-3 is entitled to cite.** -/
theorem scope_discriminates :
    memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insL) = false
      ∧ memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insI) = true :=
  ⟨memFreeB_seenWord_insL_false, memFreeB_seenWord_insI_true⟩

#audit_axioms memFreeB_iff
#audit_axioms scopedOn_reduces scopedOn_reduces_all_the_way
#audit_axioms memFreeB_seenWord_insL_false memFreeB_seenWord_insI_true
#audit_axioms scope_discriminates

end SaltWorks.HDL.MemFreeScope

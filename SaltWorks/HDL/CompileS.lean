import SaltWorks.HDL.CompileE

/-! # `compileS` — L1: STRAIGHT-LINE STATEMENTS, and the simulation lemma's SHAPE

Block ① rung **L1**. The ladder: *"N2, straightline statements. `seq`/`assign`/`letmut`;
the simulation lemma's SHAPE is fixed here (state-agreement relation `encodeOK Γ σ st` —
the F2 injectivity hypothesis lands as a theorem about the level-indexed embedding)."*

## What the shape is, and one thing it is NOT

§4 of the block sketches Row A as `runFor n code (encode σ) = encode σ'`. **The conclusion
cannot be a state EQUALITY, and the corpus already knew it** — `C3Statement` uses a
relation (`Match reg σ st (vars p)`) rather than an encoding. Two independent reasons,
and §6 exhibits both:

* the machine state carries a `pc` and **dirty scratch registers** left by expression
  evaluation, which no `encode σ'` mentions;
* `σ : Nat → BitVec 32` is infinite and the register file is 32 words, so agreement can
  only ever be *scoped*.

So `encodeOK` is a **relation**, scoped to the levels the context actually names. *This is
not a refutation of anything landed — it is the reason the landed `C3Statement` is shaped
the way it is, made checkable.*

## The three obligations on the register map, all discharged by A2's controls

`RegOk` collects exactly what `202b214` exhibited before anything consumed it:

```
injective          distinct LEVELS get distinct registers   ⟵ F2, as a theorem below
never x0           a write to x0 is DISCARDED (silicon's P5)
image below d      the variable area and the scratch area are disjoint
```
**`regCanonical` satisfies all three**, and `regOk_regCanonical` says so — which is what
turns A2's "land the inhabitance control first" into a closed loop rather than a promise.

## Why L1 keeps the sharp `run` form

The ∃-fuel form of §4 is for `while`. Straight-line statements are `Forward`, so
`runFor_extend` applies and L1 states its theorem at `run` directly. **L2 introduces the
fuel existential; L1 must not pre-pay for it.**

## What is NOT claimed

⛔ **`ite` and `while` are REJECTED here, and that rejection is a SCOPE MARKER, not a
machine limit** — unlike L0's three causes, which are properties of the hardware. §6
exhibits the boundary so a reader cannot mistake one for the other.
⛔ No completeness. `compileS` returning `none` on a branch says nothing about whether a
branch is compilable — L2 answers that.
-/

open SaltWorks.ISA
open SaltWorks.StraightLine
open SaltWorks.RegMap
open SaltWorks.HDL.TinyRustN0
open SaltWorks.CompileE

namespace SaltWorks.CompileS

/-! ## 1. THE REGISTER-MAP OBLIGATIONS — F2, as a theorem about the level-indexed embedding -/

/-- Everything the code generator needs of its register map. `CodegenSpec.RegOk` stated
this over a `Nat`-domain map, which A2 found pigeonhole-unsatisfiable; this is the same
three clauses over A2's amended finite domain. -/
structure RegOk (reg : RegMap) (d : Nat) : Prop where
  /-- **F2.** Distinct pool levels get distinct registers. -/
  inj : Function.Injective reg
  /-- Silicon's P5: a write to `x0` is discarded, so no level may map there. -/
  nz : ∀ i : Fin poolSize, reg i ≠ 0
  /-- The variable area and the scratch area are disjoint. -/
  below : PoolBelow reg d

/-- ⭐ **F2 AS A THEOREM ABOUT THE LEVEL-INDEXED EMBEDDING.** Two source levels that are
different occupy different registers — *the property `assign` needs in order not to
clobber a neighbouring binding, stated on LEVELS (which is what the de Bruijn repair made
the runtime cells) rather than on source names.* -/
theorem level_embedding_injective {reg : RegMap} {d : Nat} (h : RegOk reg d)
    (i j : Fin poolSize) (hne : i.val ≠ j.val) : reg i ≠ reg j := by
  intro hh
  exact hne (congrArg Fin.val (h.inj hh))

/-- ⭐⭐ **A2's CONTROLS CLOSE THE LOOP: the canonical map satisfies all three clauses.**
Without this, `RegOk` would be a hypothesis nobody had exhibited — the exact defect A2 was
raised to prevent, one level up. -/
theorem regOk_regCanonical : RegOk regCanonical 16 :=
  { inj := regCanonical_injective
    nz := regCanonical_ne_zero
    below := poolBelow_regCanonical }

#audit_axioms RegOk
#audit_axioms level_embedding_injective
#audit_axioms regOk_regCanonical

/-! ## 2. `encodeOK` — the state-agreement relation, SCOPED

`RegsHold` (L0) demands agreement on the whole pool. `encodeOK` demands it only on the
levels `Γ` names, which is what a statement-level induction can actually carry: a `letmut`
extends the scope by one and everything above it is none of the context's business. -/

/-- The registers named by the map hold the source state's slots, **for the levels in
scope**.

⛔ **A SCOPE NOTE: THE MACHINE GREW UNDER THIS RELATION, 8/10.** `M1` grew `St` from two
fields to four (`mem`, `trapped`). **Nothing here became false — but this relation
characterises REGISTERS, so "the compiler is correct" covers a strictly smaller fraction of
the machine state than it did when this was written.**

✅ *It is still COMPLETE for this fragment, and the reason is a landed theorem rather than
an argument: `step_mem_eq` and `step_trapped_eq` prove **all five slice-A arms preserve
both new fields**, so code `compileS` emits provably cannot touch them.*

🔑 ***Cited by NAME, never by line*** — my own pin into `ISA.lean` rotted the same evening
when a peer's landing moved it 49 lines, and the names above were themselves verified
AFTER the restatement-renames wave rather than recalled from before it. *A reader who does
not know those two theorems exist cannot see why the two unmentioned fields are safe to
ignore; that is the only gap this note closes.* -/
def encodeOK (Γ : Ctx) (reg : RegMap) (σ : State) (st : St) : Prop :=
  ∀ i : Fin poolSize, i.val < Γ.length → st.get (reg i) = σ i.val

/-- Reading a source state back off the registers. Used only as a bridge: it is the state
`L0`'s whole-pool theorem is about, and §3 shows a well-typed expression cannot tell it
from `σ`. -/
def regState (reg : RegMap) (σ : State) (st : St) : State :=
  fun l => if h : l < poolSize then st.get (reg ⟨l, h⟩) else σ l

theorem regsHold_regState (reg : RegMap) (σ : State) (st : St) :
    RegsHold reg (regState reg σ st) st := by
  intro i
  simp only [regState, dif_pos i.isLt]

/-- …and it agrees with `σ` everywhere the context can see. **Above `poolSize` it agrees
by construction, so no pool bound is needed here** — which is why `compileS_correct` does
not carry one. -/
theorem regState_agrees {Γ : Ctx} {reg : RegMap} {σ : State} {st : St}
    (h : encodeOK Γ reg σ st) : ∀ l, l < Γ.length → σ l = regState reg σ st l := by
  intro l hl
  by_cases hp : l < poolSize
  · simp only [regState, dif_pos hp]; exact (h ⟨l, hp⟩ hl).symm
  · simp only [regState, dif_neg hp]

#audit_axioms encodeOK regState
#audit_axioms regsHold_regState
#audit_axioms regState_agrees

/-! ## 3. A WELL-TYPED EXPRESSION READS ONLY IN-SCOPE SLOTS

This is what lets L0's whole-pool theorem be consumed under a scoped hypothesis, with no
re-induction over `compileE`. -/

/-- ⭐ **STATES THAT AGREE IN SCOPE ARE INDISTINGUISHABLE TO A WELL-TYPED EXPRESSION.**
Typing is load-bearing and not decoration: `slotOf` is TOTAL and answers `0` on an unbound
name, so an ill-typed `var` would read a slot the context never granted. -/
theorem evalE_congr_of_typed {Γ : Ctx} {σ τ : State}
    (hag : ∀ l, l < Γ.length → σ l = τ l) :
    ∀ (e : Exp) (t : Ty), inferE Γ e = some t → evalE Γ σ e = evalE Γ τ e := by
  intro e
  induction e with
  | var x => intro t hty; exact hag _ (slotOf_lt_of_inferE hty)
  | const n => intro _ _; rfl
  | tt => intro _ _; rfl
  | ff => intro _ _; rfl
  | add a b iha ihb =>
      intro t hty
      obtain ⟨ha, hb⟩ := inferE_add_inv hty
      simp only [evalE, iha .i32 ha, ihb .i32 hb]
  | xor a b iha ihb =>
      intro t hty
      obtain ⟨ha, hb⟩ := inferE_xor_inv hty
      simp only [evalE, iha .i32 ha, ihb .i32 hb]
  | slt a b iha ihb =>
      intro t hty
      obtain ⟨ha, hb⟩ := inferE_slt_inv hty
      simp only [evalE, iha .i32 ha, ihb .i32 hb]

/-- ⭐⭐ **L0's EXPRESSION THEOREM, UNDER THE SCOPED HYPOTHESIS.** The landed whole-pool
statement is reused verbatim — the bridge is `regState`, not a second induction. -/
theorem exec_compileE_eq_evalE_scoped {Γ : Ctx} {reg : RegMap} {σ : State} {st : St}
    {e : Exp} {t : Ty} {d : Nat} {c : List Instr} {rd : Fin 32}
    (hty : inferE Γ e = some t) (hc : compileE Γ reg e d = some c)
    (hrd : regAt d = some rd) (henc : encodeOK Γ reg σ st) (hpb : PoolBelow reg d) :
    (exec st c).get rd = evalE Γ σ e := by
  rw [exec_compileE_eq_evalE Γ reg (regState reg σ st) e d c st rd hc hrd
        (regsHold_regState reg σ st) hpb]
  exact (evalE_congr_of_typed (regState_agrees henc) e t hty).symm

#audit_axioms evalE_congr_of_typed
#audit_axioms exec_compileE_eq_evalE_scoped

/-! ## 4. `compileS` -/

/-- The register a LEVEL lives in. `varReg` is this composed with `slotOf`; `letmut` needs
the level form directly, because it binds at `Γ.length` and has no name to resolve. -/
def lvlReg (reg : RegMap) (l : Nat) : Option (Fin 32) :=
  if h : l < poolSize then some (reg ⟨l, h⟩) else none

theorem lvlReg_eq {reg : RegMap} {l : Nat} {r : Fin 32} (h : lvlReg reg l = some r) :
    ∃ hl : l < poolSize, r = reg ⟨l, hl⟩ := by
  unfold lvlReg at h
  by_cases hl : l < poolSize
  · rw [dif_pos hl] at h; exact ⟨hl, (Option.some.inj h).symm⟩
  · rw [dif_neg hl] at h; exact absurd h (by simp)

theorem varReg_eq_lvlReg (Γ : Ctx) (reg : RegMap) (x : Nat) :
    varReg Γ reg x = lvlReg reg (slotOf Γ x) := rfl

/-- ⭐⭐⭐ **L1's CODE GENERATOR.** `d` is the scratch base; every statement evaluates its
expression there and then MOVES into the level's register, because there is no store. -/
def compileS (reg : RegMap) (d : Nat) : Ctx → Stmt → Option (List Instr)
  | _, .skip => some []
  | Γ, .assign x e =>
      match compileE Γ reg e d, regAt d, varReg Γ reg x with
      | some ce, some rd, some rx => some (ce ++ [.ADDI rx rd 0])
      | _, _, _ => none
  | Γ, .seq s t =>
      match compileS reg d Γ s, compileS reg d Γ t with
      | some cs, some ct => some (cs ++ ct)
      | _, _ => none
  | Γ, .letmut x ty e body =>
      match compileE Γ reg e d, regAt d, lvlReg reg Γ.length,
            compileS reg d ((x, ty) :: Γ) body with
      | some ce, some rd, some rl, some cb => some (ce ++ [.ADDI rl rd 0] ++ cb)
      | _, _, _, _ => none
  -- ⛔ THE FRAGMENT BOUNDARY. A branch is not straight-line; L2 owns it.
  | _, .ite _ _ _ => none
  | _, .while _ _ => none

/-! ### Forward equations and the shape lemmas that invert them -/

theorem compileS_skip_eq (reg : RegMap) (d : Nat) (Γ : Ctx) :
    compileS reg d Γ .skip = some [] := rfl

theorem compileS_assign_eq {reg : RegMap} {d : Nat} {Γ : Ctx} {x : Nat} {e : Exp}
    {ce : List Instr} {rd rx : Fin 32} (h1 : compileE Γ reg e d = some ce)
    (h2 : regAt d = some rd) (h3 : varReg Γ reg x = some rx) :
    compileS reg d Γ (.assign x e) = some (ce ++ [Instr.ADDI rx rd 0]) := by
  simp [compileS, h1, h2, h3]

theorem compileS_seq_eq {reg : RegMap} {d : Nat} {Γ : Ctx} {s t : Stmt}
    {cs ct : List Instr} (h1 : compileS reg d Γ s = some cs)
    (h2 : compileS reg d Γ t = some ct) :
    compileS reg d Γ (.seq s t) = some (cs ++ ct) := by
  simp [compileS, h1, h2]

theorem compileS_letmut_eq {reg : RegMap} {d : Nat} {Γ : Ctx} {x : Nat} {ty : Ty}
    {e : Exp} {body : Stmt} {ce cb : List Instr} {rd rl : Fin 32}
    (h1 : compileE Γ reg e d = some ce) (h2 : regAt d = some rd)
    (h3 : lvlReg reg Γ.length = some rl)
    (h4 : compileS reg d ((x, ty) :: Γ) body = some cb) :
    compileS reg d Γ (.letmut x ty e body) = some (ce ++ [Instr.ADDI rl rd 0] ++ cb) := by
  simp [compileS, h1, h2, h3, h4]

theorem compileS_assign_shape {reg : RegMap} {d : Nat} {Γ : Ctx} {x : Nat} {e : Exp}
    {c : List Instr} (h : compileS reg d Γ (.assign x e) = some c) :
    ∃ ce rd rx, compileE Γ reg e d = some ce ∧ regAt d = some rd ∧
      varReg Γ reg x = some rx ∧ c = ce ++ [Instr.ADDI rx rd 0] := by
  cases h1 : compileE Γ reg e d with
  | none => simp [compileS, h1] at h
  | some ce =>
      cases h2 : regAt d with
      | none => simp [compileS, h1, h2] at h
      | some rd =>
          cases h3 : varReg Γ reg x with
          | none => simp [compileS, h1, h2, h3] at h
          | some rx =>
              refine ⟨ce, rd, rx, rfl, rfl, rfl, ?_⟩
              rw [compileS_assign_eq h1 h2 h3] at h; exact (Option.some.inj h).symm

theorem compileS_seq_shape {reg : RegMap} {d : Nat} {Γ : Ctx} {s t : Stmt}
    {c : List Instr} (h : compileS reg d Γ (.seq s t) = some c) :
    ∃ cs ct, compileS reg d Γ s = some cs ∧ compileS reg d Γ t = some ct ∧ c = cs ++ ct := by
  cases h1 : compileS reg d Γ s with
  | none => simp [compileS, h1] at h
  | some cs =>
      cases h2 : compileS reg d Γ t with
      | none => simp [compileS, h1, h2] at h
      | some ct =>
          refine ⟨cs, ct, rfl, rfl, ?_⟩
          rw [compileS_seq_eq h1 h2] at h; exact (Option.some.inj h).symm

theorem compileS_letmut_shape {reg : RegMap} {d : Nat} {Γ : Ctx} {x : Nat} {ty : Ty}
    {e : Exp} {body : Stmt} {c : List Instr}
    (h : compileS reg d Γ (.letmut x ty e body) = some c) :
    ∃ ce rd rl cb, compileE Γ reg e d = some ce ∧ regAt d = some rd ∧
      lvlReg reg Γ.length = some rl ∧ compileS reg d ((x, ty) :: Γ) body = some cb ∧
      c = ce ++ [Instr.ADDI rl rd 0] ++ cb := by
  cases h1 : compileE Γ reg e d with
  | none => simp [compileS, h1] at h
  | some ce =>
      cases h2 : regAt d with
      | none => simp [compileS, h1, h2] at h
      | some rd =>
          cases h3 : lvlReg reg Γ.length with
          | none => simp [compileS, h1, h2, h3] at h
          | some rl =>
              cases h4 : compileS reg d ((x, ty) :: Γ) body with
              | none => simp [compileS, h1, h2, h3, h4] at h
              | some cb =>
                  refine ⟨ce, rd, rl, cb, rfl, rfl, rfl, rfl, ?_⟩
                  rw [compileS_letmut_eq h1 h2 h3 h4] at h; exact (Option.some.inj h).symm

#audit_axioms lvlReg
#audit_axioms lvlReg_eq varReg_eq_lvlReg
#audit_axioms compileS
#audit_axioms compileS_skip_eq compileS_assign_eq compileS_seq_eq compileS_letmut_eq
#audit_axioms compileS_assign_shape compileS_seq_shape compileS_letmut_shape

/-! ## 5. THE SIMULATION LEMMA

Induction on the `bigStep` DERIVATION, not on the statement — so `while`'s two rules are
distinguished and `ite`'s two branches carry their own condition. Both are discharged by
the fragment boundary here; L2 replaces those four cases with real code. -/

/-- `compileS` emits straight-line code, so `run` is the right form and `runFor_extend`
covers it. -/
theorem compileS_is_forward (reg : RegMap) (d : Nat) :
    ∀ (p : Stmt) (Γ : Ctx) (c : List Instr), compileS reg d Γ p = some c →
      Forward c = true := by
  intro p
  induction p with
  | skip => intro Γ c h; rw [← Option.some.inj h]; rfl
  | assign x e =>
      intro Γ c h
      obtain ⟨ce, rd, rx, hce, _, _, rfl⟩ := compileS_assign_shape h
      have h1 : Forward ce = true := compileE_is_forward Γ reg e d ce hce
      simp only [Forward] at h1 ⊢
      simp [List.all_append, isForward, h1]
  | seq s t ihs iht =>
      intro Γ c h
      obtain ⟨cs, ct, hs, ht, rfl⟩ := compileS_seq_shape h
      have h1 : Forward cs = true := ihs Γ cs hs
      have h2 : Forward ct = true := iht Γ ct ht
      simp only [Forward] at h1 h2 ⊢
      simp [List.all_append, h1, h2]
  | ite c' thn els _ _ => intro Γ c h; simp [compileS] at h
  | «while» c' body _ => intro Γ c h; simp [compileS] at h
  | letmut x ty e body ih =>
      intro Γ c h
      obtain ⟨ce, rd, rl, cb, hce, _, _, hcb, rfl⟩ := compileS_letmut_shape h
      have h1 : Forward ce = true := compileE_is_forward Γ reg e d ce hce
      have h2 : Forward cb = true := ih ((x, ty) :: Γ) cb hcb
      simp only [Forward] at h1 h2 ⊢
      simp [List.all_append, isForward, h1, h2]

/-- The move that ends every statement: one register into another. -/
theorem exec_move_get {st : St} {rdst rsrc r : Fin 32} (hne : r ≠ rdst) :
    (exec st [Instr.ADDI rdst rsrc 0]).get r = st.get r := by
  rw [exec_cons, exec_nil, step_ADDI_get_ne _ _ _ _ _ hne]

theorem exec_move_get_self {st : St} {rdst rsrc : Fin 32} (h : rdst ≠ 0) :
    (exec st [Instr.ADDI rdst rsrc 0]).get rdst = st.get rsrc := by
  have hz : ((0 : BitVec 12).signExtend 32) = (0 : BitVec 32) := by decide
  rw [exec_cons, exec_nil, step_ADDI_get_self _ _ _ _ h, hz]
  simp

/-! ### The statement-checker inversions the induction consumes -/

theorem chkS_assign_inv {Γ : Ctx} {x : Nat} {e : Exp} (h : chkS Γ (.assign x e) = true) :
    ∃ t, inferE Γ e = some t := by
  cases hie : inferE Γ e with
  | none => exfalso; cases hlk : look Γ x <;> simp [chkS, hlk, hie] at h
  | some te => exact ⟨te, rfl⟩

theorem chkS_seq_inv {Γ : Ctx} {s t : Stmt} (h : chkS Γ (.seq s t) = true) :
    chkS Γ s = true ∧ chkS Γ t = true := by
  simp only [chkS, Bool.and_eq_true] at h; exact h

theorem chkS_letmut_inv {Γ : Ctx} {x : Nat} {ty : Ty} {e : Exp} {body : Stmt}
    (h : chkS Γ (.letmut x ty e body) = true) :
    inferE Γ e = some ty ∧ chkS ((x, ty) :: Γ) body = true := by
  simp only [chkS, Bool.and_eq_true, beq_iff_eq] at h; exact h

#audit_axioms chkS_assign_inv chkS_seq_inv chkS_letmut_inv

/-- The one-instruction move that ends every statement, seen from the level it writes. -/
theorem move_writes_level {reg : RegMap} {d : Nat} (hreg : RegOk reg d)
    {st : St} {rd : Fin 32} {l : Nat} (hl : l < poolSize) :
    (exec st [Instr.ADDI (reg ⟨l, hl⟩) rd 0]).get (reg ⟨l, hl⟩) = st.get rd :=
  exec_move_get_self (hreg.nz _)

/-- …and seen from every OTHER level, which is where F2 does its work. -/
theorem move_frames_other_levels {reg : RegMap} {d : Nat} (hreg : RegOk reg d)
    {st : St} {rd : Fin 32} {l : Nat} (hl : l < poolSize) (i : Fin poolSize)
    (hne : i.val ≠ l) :
    (exec st [Instr.ADDI (reg ⟨l, hl⟩) rd 0]).get (reg i) = st.get (reg i) :=
  exec_move_get (level_embedding_injective hreg i ⟨l, hl⟩ hne)

#audit_axioms move_writes_level move_frames_other_levels

/-- ⭐⭐⭐ **L1's SIMULATION THEOREM.** If the source statement steps `σ` to `σ'`
and it compiles, then running the emitted code from any machine state agreeing with `σ`
in scope lands in one agreeing with `σ'` in scope.

**No pool bound is a hypothesis.** `compileS` succeeding already certifies that every
level it touches is inside the pool, and `regState` agrees with `σ` above the pool by
construction — so demanding `Γ.length ≤ poolSize` would be assuming something already
earned. *Typing IS a hypothesis and is load-bearing: `slotOf` is total and answers `0` on
an unbound name, so an ill-typed `var` would read a slot the context never granted.* -/
theorem compileS_correct {reg : RegMap} {d : Nat} (hreg : RegOk reg d) :
    ∀ {Γ : Ctx} {p : Stmt} {σ σ' : State}, bigStep Γ p σ σ' → chkS Γ p = true →
      ∀ (c : List Instr) (st : St), compileS reg d Γ p = some c →
        encodeOK Γ reg σ st → encodeOK Γ reg σ' (exec st c) := by
  intro Γ p σ σ' hbs
  induction hbs with
  | skip =>
      intro _ c st h henc
      rw [← Option.some.inj h]; simpa using henc
  | @assign Γ x e σ =>
      intro hchk c st h henc
      obtain ⟨ce, rd, rx, hce, hrd, hrx, rfl⟩ := compileS_assign_shape h
      obtain ⟨te, hie⟩ := chkS_assign_inv hchk
      have hval : (exec st ce).get rd = evalE Γ σ e :=
        exec_compileE_eq_evalE_scoped hie hce hrd henc hreg.below
      obtain ⟨hslot, rfl⟩ := varReg_eq hrx
      intro i hi
      rw [exec_append]
      by_cases hsame : i.val = slotOf Γ x
      · have hfin : i = (⟨slotOf Γ x, hslot⟩ : Fin poolSize) := Fin.ext hsame
        rw [hfin, move_writes_level hreg hslot, hval]
        simp [upd]
      · rw [move_frames_other_levels hreg hslot i hsame,
            exec_compileE_preserves_below Γ reg e d ce st hce (reg i) (hreg.below i)]
        rw [henc i hi]
        simp [upd, hsame]
  | @seq Γ s t σ σ₁ σ' _ _ ihs iht =>
      intro hchk c st h henc
      obtain ⟨cs, ct, hs, ht, rfl⟩ := compileS_seq_shape h
      obtain ⟨hcs, hct⟩ := chkS_seq_inv hchk
      rw [exec_append]
      exact iht hct ct (exec st cs) ht (ihs hcs cs st hs henc)
  | @letmut Γ x ty e body σ σ' _ ih =>
      intro hchk c st h henc
      obtain ⟨ce, rd, rl, cb, hce, hrd, hrl, hcb, rfl⟩ := compileS_letmut_shape h
      obtain ⟨hie, hbody⟩ := chkS_letmut_inv hchk
      obtain ⟨hlen, rfl⟩ := lvlReg_eq hrl
      have hval : (exec st ce).get rd = evalE Γ σ e :=
        exec_compileE_eq_evalE_scoped hie hce hrd henc hreg.below
      -- the binding lands at level `Γ.length`, ABOVE everything the outer context names
      have hmid : encodeOK ((x, ty) :: Γ) reg (upd σ Γ.length (evalE Γ σ e))
          (exec (exec st ce) [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0]) := by
        intro i hi
        simp only [List.length_cons] at hi
        by_cases hsame : i.val = Γ.length
        · have hfin : i = (⟨Γ.length, hlen⟩ : Fin poolSize) := Fin.ext hsame
          rw [hfin, move_writes_level hreg hlen, hval]
          simp [upd]
        · rw [move_frames_other_levels hreg hlen i hsame,
              exec_compileE_preserves_below Γ reg e d ce st hce (reg i) (hreg.below i)]
          rw [henc i (by omega)]
          simp [upd, hsame]
      have hfin := ih hbody cb _ hcb hmid
      intro i hi
      rw [exec_append, exec_append]
      exact hfin i (by simp only [List.length_cons]; omega)
  | iteT _ _ _ => intro _ c st h _; simp [compileS] at h
  | iteF _ _ _ => intro _ c st h _; simp [compileS] at h
  | whileF _ => intro _ c st h _; simp [compileS] at h
  | whileT _ _ _ _ _ => intro _ c st h _; simp [compileS] at h

#audit_axioms compileS_is_forward
#audit_axioms exec_move_get exec_move_get_self
#audit_axioms compileS_correct

/-! ## 6. AT THE MACHINE'S OWN `run`, AND THE CONTROLS -/

/-- ⭐⭐⭐ **L1 AT `run`.** Compile a straight-line statement, run it from `pc = 0`, and the
registers agree with the source semantics on every level in scope. -/
theorem run_compileS_correct {reg : RegMap} {d : Nat} (hreg : RegOk reg d)
    {Γ : Ctx} {p : Stmt} {σ σ' : State} (hbs : bigStep Γ p σ σ')
    (hchk : chkS Γ p = true) (c : List Instr) (st : St)
    (hc : compileS reg d Γ p = some c) (henc : encodeOK Γ reg σ st)
    (hpc : st.pc = 0) (hb : 4 * c.length < 2 ^ 32) :
    encodeOK Γ reg σ' (run c st) := by
  rw [run_eq_exec c st (compileS_is_forward reg d p Γ c hc) hb hpc]
  exact compileS_correct hreg hbs hchk c st hc henc

/-- `let x = 7 in x := x + 5` — the running witness for the whole rung. -/
def witnessProg : Stmt :=
  .letmut 0 .i32 (.const 7) (.assign 0 (.add (.var 0) (.const 5)))

theorem witnessProg_wellFormed : wellFormed witnessProg = true := by decide

/-- ⭐ **NON-VACUITY, KERNEL-EXECUTED.** Six instructions; slot 0 lives in `x1`; the
program leaves **12** there, with the `pc` off the end at `4 * 6` bytes. *Without this,
every theorem above is satisfied by a `compileS` nobody can run.* -/
theorem witness_runs :
    (compileS regCanonical 16 [] witnessProg).map
        (fun c => ((run c St.init).get 1, (run c St.init).pc, c.length))
      = some (12, 24, 6) := by
  decide +kernel

/-- ⛔⭐ **THE CONCLUSION CANNOT BE A STATE EQUALITY — MEASURED, NOT ARGUED.** §4's sketch
reads `runFor n code (encode σ) = encode σ'`. After this program the machine is NOT any
encoding of `σ'`: the scratch registers `x16` and `x17` hold **12** and **5**, left over
from evaluating the expression, and the `pc` has moved. *No `encode σ'` mentions either.
This is why the landed `C3Statement` uses a RELATION scoped to the program's variables,
and why `encodeOK` does too — the shape was already right; this makes the reason
checkable.* -/
theorem the_final_state_is_not_an_encoding :
    (compileS regCanonical 16 [] witnessProg).map
        (fun c => ((run c St.init).get 16, (run c St.init).get 17, (run c St.init).pc))
      = some (12, 5, 24) := by
  decide +kernel

/-- ⛔ **THE FRAGMENT BOUNDARY, EXHIBITED — and it is a SCOPE MARKER, not a machine
limit.** The same well-typed body compiles inside a `seq` and is rejected inside an `ite`.
*L0's three `none` causes are facts about the hardware; this one is a fact about which
rung you are standing on, and L2 removes it.* -/
theorem cause_outside_the_straight_line_fragment :
    (compileS regCanonical 16 [(0, Ty.i32)] (.seq (.assign 0 (.const 5)) .skip)).isSome = true
  ∧ compileS regCanonical 16 [(0, Ty.i32)]
      (.ite (.slt (.var 0) (.const 5)) (.assign 0 (.const 5)) .skip) = none
  ∧ compileS regCanonical 16 [(0, Ty.i32)]
      (.while (.slt (.var 0) (.const 5)) .skip) = none := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- ⭐ **AND THE POOL STILL BINDS AT THE STATEMENT LEVEL.** Sixteen nested bindings need a
sixteenth cell; `lvlReg` refuses at level 15, so `compileS` refuses too. -/
theorem cause_pool_exhaustion_at_letmut :
    (lvlReg regCanonical 14).isSome = true
  ∧ lvlReg regCanonical 15 = none := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-! ### ⭐ EVERY HYPOTHESIS DISCHARGED AT ONCE — the rung's vacuity control

*Math's flag on `5723cde`, taken: `4 * c.length < 2 ^ 32` has no lemma bounding it, and a
consumer at L1 must discharge it by MEASURING the emitted image. Here that measurement is
made, and it is made as part of discharging **every other hypothesis in the same breath**
— because a simulation theorem whose hypotheses have never been jointly met is a theorem
about nothing.*

⚠️ **AND THE CONTEXT IS DELIBERATELY NON-EMPTY.** At `Γ = []` the relation `encodeOK`
quantifies over `i.val < 0` and is **vacuously true on both sides**, so the obvious witness
would have proved nothing at all. One binding in scope makes the conclusion say something,
and the last conjunct is READ OUT of the theorem's conclusion rather than computed
alongside it. -/

def ctx1 : Ctx := [(0, Ty.i32)]
def witnessAssign : Stmt := .assign 0 (.add (.var 0) (.const 5))
def sigma7 : State := fun _ => (7 : BitVec 32)
def st7 : St := St.init.set 1 7

theorem st7_encodes : encodeOK ctx1 regCanonical sigma7 st7 := by
  intro i hi
  have hlt : i.val < 1 := by simpa [ctx1] using hi
  have hfin : i = (⟨0, by decide⟩ : Fin poolSize) := by
    apply Fin.ext
    show i.val = 0
    omega
  subst hfin
  decide +kernel

/-- ⭐⭐⭐ **THE CHAIN, CLOSED.** `RegOk` from A2's controls · `bigStep` by an explicit
derivation · `chkS` by the kernel · `encodeOK` exhibited above · `pc = 0` · **and the code
length MEASURED at 4** — then the theorem's own conclusion is read out, and it says the
level-0 register holds **12**. -/
theorem witness_chain_discharged :
    ∃ c, compileS regCanonical 16 ctx1 witnessAssign = some c ∧ c.length = 4
      ∧ (run c st7).get 1 = 12 := by
  obtain ⟨c, hc⟩ := Option.isSome_iff_exists.mp
    (show (compileS regCanonical 16 ctx1 witnessAssign).isSome = true by decide +kernel)
  have hlen : c.length = 4 := by
    have h : (compileS regCanonical 16 ctx1 witnessAssign).map List.length = some 4 := by
      decide +kernel
    rw [hc] at h; simpa using h
  refine ⟨c, hc, hlen, ?_⟩
  have hout := run_compileS_correct regOk_regCanonical
    (Γ := ctx1) (p := witnessAssign) (σ := sigma7) .assign (by decide) c st7 hc
    st7_encodes (by decide +kernel) (by rw [hlen]; decide)
  have h1 := hout ⟨0, by decide⟩ (by decide)
  have h2 : (regCanonical ⟨0, by decide⟩ : Fin 32) = 1 := by decide
  rw [h2] at h1
  rw [h1]
  decide +kernel

#audit_axioms ctx1 witnessAssign sigma7 st7
#audit_axioms st7_encodes
#audit_axioms witness_chain_discharged

#audit_axioms run_compileS_correct
#audit_axioms witnessProg witnessProg_wellFormed
#audit_axioms witness_runs
#audit_axioms the_final_state_is_not_an_encoding
#audit_axioms cause_outside_the_straight_line_fragment
#audit_axioms cause_pool_exhaustion_at_letmut

end SaltWorks.CompileS

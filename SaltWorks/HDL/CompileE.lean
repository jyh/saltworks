import SaltWorks.HDL.RegMap
import SaltWorks.HDL.TinyRustN0
import SaltWorks.HDL.StraightLine

/-! # `compileE` — L0's OTHER HALF: expressions compiled, and the theorem that says so

Block ① rung **L0**, the half the fuel lemmas were built for. The fuel half landed at
`763d02a` (`StraightLine.lean`) and A2's inhabitance control at `202b214` (`RegMap.lean`);
this file is `compileE` itself, its correctness against the landed `evalE`, and A5's
totality lemma.

## The crux, restated from the design so no reader reconstructs it

**There is no memory in this ISA.** Slice A is `ADD · ADDI · XOR · SLT · BEQ` — no load,
no store. A source `var` lives in a *state slot* (`evalE Γ σ (.var x) = σ (slotOf Γ x)`)
and the machine has only registers, so compiling a variable is a **move** from the
register its slot is mapped to. **The register map is therefore an INPUT to L0, not an L1
detail** — which is what A2's `RegMap := Fin poolSize → Fin 32` is for.

## The shape

```
compileE Γ reg e d = code leaving `evalE Γ σ e` in register d
  tt / ff  ↦ [ADDI d x0 1] / [ADDI d x0 0]
  const n  ↦ [ADDI d x0 imm]        if n fits ADDI's 12-bit SIGNED field
  var x    ↦ [ADDI d (reg slot) 0]  — a MOVE, because there is no load
  a ⊕ b    ↦ compile a → d, compile b → d+1, then the op into d
```
Left operand into the destination, right one register higher, **no swapping** — exactly
the machine model `expCostNoSwap` was written for, and §7 turns that coincidence into a
theorem rather than a comment.

## The two levels, and why `exec` exists

Correctness is proved twice and the split is the point:

* `exec st c = c.foldl step st` — a **pure fold**: no `pc`, no `fetch`. Every register
  argument lives here, and it composes by `List.foldl_append` alone.
* `run c st` — the ISA's own whole-program run. §8 transports the fold to it **once**,
  through the landed `Forward`/`runFor` machinery.

*A per-form correctness proof that reasoned about `pc` at every leaf would be this
theorem with the composition lemma inlined seven times.*

## What is NOT claimed

⛔ **Expressions only.** No statements, no `bigStep`, no `compile`. L1 owns
`seq`/`assign`/`letmut` and the statement-level state-agreement relation.
⛔ **`compileE` does not bound the code it emits**, and §9 proves that is a REAL gap
rather than an oversight — L4's candidate third rejection cause, priced.
-/

open SaltWorks.ISA
open SaltWorks.StraightLine
open SaltWorks.RegMap
open SaltWorks.HDL.TinyRustN0

namespace SaltWorks.CompileE

/-! ## 1. The three partial steps — they ARE the rejection causes

Every `none` `compileE` can return comes from exactly one of these, which is what makes
"how many ways can compilation fail?" a checkable question instead of a reading. -/

/-- A scratch index as a machine register. `none` is **register exhaustion**. -/
def regAt (n : Nat) : Option (Fin 32) := if h : n < 32 then some ⟨n, h⟩ else none

/-- The 12-bit signed immediate a constant needs. `none` is **an unrepresentable
constant**: `BitVec 32` constants are not all reachable through `ADDI`. -/
def fitImm (n : BitVec 32) : Option (BitVec 12) :=
  if (n.extractLsb' 0 12).signExtend 32 = n then some (n.extractLsb' 0 12) else none

/-- The register a source variable's slot lives in. `none` is **a slot outside the pool
the map covers** — the second surface of one finite register file. -/
def varReg (Γ : Ctx) (reg : RegMap) (x : Nat) : Option (Fin 32) :=
  if h : slotOf Γ x < poolSize then some (reg ⟨slotOf Γ x, h⟩) else none

theorem regAt_eq {n : Nat} {r : Fin 32} (h : regAt n = some r) : ∃ hn : n < 32, r = ⟨n, hn⟩ := by
  unfold regAt at h
  by_cases hn : n < 32
  · rw [dif_pos hn] at h; exact ⟨hn, (Option.some.inj h).symm⟩
  · rw [dif_neg hn] at h; exact absurd h (by simp)

theorem regAt_val {n : Nat} {r : Fin 32} (h : regAt n = some r) : r.val = n := by
  obtain ⟨hn, rfl⟩ := regAt_eq h; rfl

theorem regAt_of_lt {n : Nat} (h : n < 32) : regAt n = some ⟨n, h⟩ := by
  simp [regAt, h]

theorem varReg_eq {Γ : Ctx} {reg : RegMap} {x : Nat} {rs : Fin 32}
    (h : varReg Γ reg x = some rs) :
    ∃ hs : slotOf Γ x < poolSize, rs = reg ⟨slotOf Γ x, hs⟩ := by
  unfold varReg at h
  by_cases hs : slotOf Γ x < poolSize
  · rw [dif_pos hs] at h; exact ⟨hs, (Option.some.inj h).symm⟩
  · rw [dif_neg hs] at h; exact absurd h (by simp)

/-- ⭐ **A CONSTANT COMPILES TO ITSELF.** The immediate test is not a guess at
representability: what it accepts, `ADDI`'s sign extension reproduces exactly. -/
theorem fitImm_signExtend {n : BitVec 32} {imm : BitVec 12} (h : fitImm n = some imm) :
    imm.signExtend 32 = n := by
  unfold fitImm at h
  by_cases hc : (n.extractLsb' 0 12).signExtend 32 = n
  · rw [if_pos hc] at h; rw [← Option.some.inj h]; exact hc
  · rw [if_neg hc] at h; exact absurd h (by simp)

#audit_axioms regAt fitImm varReg
#audit_axioms regAt_eq
#audit_axioms regAt_val
#audit_axioms regAt_of_lt
#audit_axioms varReg_eq
#audit_axioms fitImm_signExtend

/-! ## 2. The machine facts, once

`step` writes one register and falls through. Stating that once, generically over the
three arithmetic opcodes, is what keeps §5 and §6 from being written three times. -/

@[simp] theorem St_next_get (s : St) (r : Fin 32) : s.next.get r = s.get r := rfl

theorem step_ADDI_get_ne (st : St) (rd rs : Fin 32) (imm : BitVec 12) (r : Fin 32)
    (h : r ≠ rd) : (step st (.ADDI rd rs imm)).get r = st.get r := by
  show ((st.set rd (st.get rs + imm.signExtend 32)).next).get r = st.get r
  rw [St_next_get]; exact St.get_set_ne _ _ _ _ h

theorem step_ADDI_get_self (st : St) (rd rs : Fin 32) (imm : BitVec 12) (h : rd ≠ 0) :
    (step st (.ADDI rd rs imm)).get rd = st.get rs + imm.signExtend 32 := by
  show ((st.set rd (st.get rs + imm.signExtend 32)).next).get rd = _
  rw [St_next_get]; exact St.get_set_self _ _ _ h

/-- The shape `ADD`, `XOR` and `SLT` share: write the destination with a function of the
two sources, then fall through. -/
def OpShape (mk : Fin 32 → Fin 32 → Fin 32 → Instr)
    (f : BitVec 32 → BitVec 32 → BitVec 32) : Prop :=
  ∀ (s : St) (x y z : Fin 32), step s (mk x y z) = (s.set x (f (s.get y) (s.get z))).next

theorem opShape_ADD : OpShape .ADD (· + ·) := fun _ _ _ _ => rfl
theorem opShape_XOR : OpShape .XOR (· ^^^ ·) := fun _ _ _ _ => rfl
theorem opShape_SLT : OpShape .SLT (fun a b => if a.slt b then 1 else 0) := fun _ _ _ _ => rfl

theorem step_op_get_ne {mk f} (hs : OpShape mk f) (st : St) (x y z r : Fin 32) (h : r ≠ x) :
    (step st (mk x y z)).get r = st.get r := by
  rw [hs, St_next_get]; exact St.get_set_ne _ _ _ _ h

theorem step_op_get_self {mk f} (hs : OpShape mk f) (st : St) (x y z : Fin 32) (h : x ≠ 0) :
    (step st (mk x y z)).get x = f (st.get y) (st.get z) := by
  rw [hs, St_next_get]; exact St.get_set_self _ _ _ h

#audit_axioms St_next_get
#audit_axioms step_ADDI_get_ne
#audit_axioms step_ADDI_get_self
#audit_axioms OpShape opShape_ADD opShape_XOR opShape_SLT
#audit_axioms step_op_get_ne
#audit_axioms step_op_get_self

/-! ## 3. `compileE`, straight-line execution as a fold, and the shape lemmas

The shape lemmas are not decoration. Every downstream proof needs to read a successful
compilation back into its parts, and doing that by `split` puts the proofs at the mercy
of how many goals the matcher happens to generate. -/

/-- The two-address emission shared by `add`/`xor`/`slt`: the left operand is already in
`d`, the right in `d+1`, and the op writes `d`. Factored so the structural lemmas
(length, `Forward`, frame) are proved once rather than three times. -/
def binOp (mk : Fin 32 → Fin 32 → Fin 32 → Instr) (ca cb : List Instr) (d : Nat) :
    Option (List Instr) :=
  match regAt d, regAt (d + 1) with
  | some rd, some rs => some (ca ++ cb ++ [mk rd rd rs])
  | _, _ => none

/-- ⭐⭐⭐ **L0's CODE GENERATOR FOR EXPRESSIONS.** Total, `Option`-valued, and every
`none` is one of §1's three causes. -/
def compileE (Γ : Ctx) (reg : RegMap) : Exp → Nat → Option (List Instr)
  | .var x, d =>
      match regAt d, varReg Γ reg x with
      | some rd, some rs => some [.ADDI rd rs 0]
      | _, _ => none
  | .const n, d =>
      match regAt d, fitImm n with
      | some rd, some imm => some [.ADDI rd 0 imm]
      | _, _ => none
  | .tt, d => match regAt d with
      | some rd => some [.ADDI rd 0 1]
      | none => none
  | .ff, d => match regAt d with
      | some rd => some [.ADDI rd 0 0]
      | none => none
  | .add a b, d =>
      match compileE Γ reg a d, compileE Γ reg b (d + 1) with
      | some ca, some cb => binOp .ADD ca cb d
      | _, _ => none
  | .xor a b, d =>
      match compileE Γ reg a d, compileE Γ reg b (d + 1) with
      | some ca, some cb => binOp .XOR ca cb d
      | _, _ => none
  | .slt a b, d =>
      match compileE Γ reg a d, compileE Γ reg b (d + 1) with
      | some ca, some cb => binOp .SLT ca cb d
      | _, _ => none

/-- Straight-line execution as a **pure fold**. No `pc`, no `fetch` — §8 is where those
enter, once. -/
def exec (st : St) (code : List Instr) : St := code.foldl step st

@[simp] theorem exec_nil (st : St) : exec st [] = st := rfl

@[simp] theorem exec_cons (st : St) (i : Instr) (c : List Instr) :
    exec st (i :: c) = exec (step st i) c := rfl

/-- Blocks compose by concatenation, and at this level that is the whole composition
story. -/
theorem exec_append (st : St) (a b : List Instr) :
    exec st (a ++ b) = exec (exec st a) b := by
  simp [exec, List.foldl_append]

/-! ### The forward equations, then the shape lemmas they invert -/

theorem binOp_eq {mk : Fin 32 → Fin 32 → Fin 32 → Instr} {ca cb : List Instr} {d : Nat}
    {rd rs : Fin 32} (h1 : regAt d = some rd) (h2 : regAt (d + 1) = some rs) :
    binOp mk ca cb d = some (ca ++ cb ++ [mk rd rd rs]) := by simp [binOp, h1, h2]

theorem compileE_var_eq {Γ : Ctx} {reg : RegMap} {x d : Nat} {rd rs : Fin 32}
    (h1 : regAt d = some rd) (h2 : varReg Γ reg x = some rs) :
    compileE Γ reg (.var x) d = some [Instr.ADDI rd rs 0] := by simp [compileE, h1, h2]

theorem compileE_const_eq {Γ : Ctx} {reg : RegMap} {n : BitVec 32} {d : Nat} {rd : Fin 32}
    {imm : BitVec 12} (h1 : regAt d = some rd) (h2 : fitImm n = some imm) :
    compileE Γ reg (.const n) d = some [Instr.ADDI rd 0 imm] := by simp [compileE, h1, h2]

theorem compileE_tt_eq {Γ : Ctx} {reg : RegMap} {d : Nat} {rd : Fin 32}
    (h1 : regAt d = some rd) : compileE Γ reg .tt d = some [Instr.ADDI rd 0 1] := by
  simp [compileE, h1]

theorem compileE_ff_eq {Γ : Ctx} {reg : RegMap} {d : Nat} {rd : Fin 32}
    (h1 : regAt d = some rd) : compileE Γ reg .ff d = some [Instr.ADDI rd 0 0] := by
  simp [compileE, h1]

theorem compileE_add_eq {Γ : Ctx} {reg : RegMap} {a b : Exp} {d : Nat} {ca cb : List Instr}
    (h1 : compileE Γ reg a d = some ca) (h2 : compileE Γ reg b (d + 1) = some cb) :
    compileE Γ reg (.add a b) d = binOp .ADD ca cb d := by simp [compileE, h1, h2]

theorem compileE_xor_eq {Γ : Ctx} {reg : RegMap} {a b : Exp} {d : Nat} {ca cb : List Instr}
    (h1 : compileE Γ reg a d = some ca) (h2 : compileE Γ reg b (d + 1) = some cb) :
    compileE Γ reg (.xor a b) d = binOp .XOR ca cb d := by simp [compileE, h1, h2]

theorem compileE_slt_eq {Γ : Ctx} {reg : RegMap} {a b : Exp} {d : Nat} {ca cb : List Instr}
    (h1 : compileE Γ reg a d = some ca) (h2 : compileE Γ reg b (d + 1) = some cb) :
    compileE Γ reg (.slt a b) d = binOp .SLT ca cb d := by simp [compileE, h1, h2]

theorem binOp_shape {mk : Fin 32 → Fin 32 → Fin 32 → Instr} {ca cb c : List Instr} {d : Nat}
    (h : binOp mk ca cb d = some c) :
    ∃ rd rs, regAt d = some rd ∧ regAt (d + 1) = some rs ∧ c = ca ++ cb ++ [mk rd rd rs] := by
  cases h1 : regAt d with
  | none => simp [binOp, h1] at h
  | some rd =>
      cases h2 : regAt (d + 1) with
      | none => simp [binOp, h1, h2] at h
      | some rs =>
          refine ⟨rd, rs, rfl, rfl, ?_⟩
          rw [binOp_eq h1 h2] at h; exact (Option.some.inj h).symm

theorem compileE_var_shape {Γ : Ctx} {reg : RegMap} {x d : Nat} {c : List Instr}
    (h : compileE Γ reg (.var x) d = some c) :
    ∃ rd rs, regAt d = some rd ∧ varReg Γ reg x = some rs ∧ c = [Instr.ADDI rd rs 0] := by
  cases h1 : regAt d with
  | none => simp [compileE, h1] at h
  | some rd =>
      cases h2 : varReg Γ reg x with
      | none => simp [compileE, h1, h2] at h
      | some rs =>
          refine ⟨rd, rs, rfl, rfl, ?_⟩
          rw [compileE_var_eq h1 h2] at h; exact (Option.some.inj h).symm

theorem compileE_const_shape {Γ : Ctx} {reg : RegMap} {n : BitVec 32} {d : Nat}
    {c : List Instr} (h : compileE Γ reg (.const n) d = some c) :
    ∃ rd imm, regAt d = some rd ∧ fitImm n = some imm ∧ c = [Instr.ADDI rd 0 imm] := by
  cases h1 : regAt d with
  | none => simp [compileE, h1] at h
  | some rd =>
      cases h2 : fitImm n with
      | none => simp [compileE, h1, h2] at h
      | some imm =>
          refine ⟨rd, imm, rfl, rfl, ?_⟩
          rw [compileE_const_eq h1 h2] at h; exact (Option.some.inj h).symm

theorem compileE_tt_shape {Γ : Ctx} {reg : RegMap} {d : Nat} {c : List Instr}
    (h : compileE Γ reg .tt d = some c) :
    ∃ rd, regAt d = some rd ∧ c = [Instr.ADDI rd 0 1] := by
  cases h1 : regAt d with
  | none => simp [compileE, h1] at h
  | some rd =>
      refine ⟨rd, rfl, ?_⟩
      rw [compileE_tt_eq h1] at h; exact (Option.some.inj h).symm

theorem compileE_ff_shape {Γ : Ctx} {reg : RegMap} {d : Nat} {c : List Instr}
    (h : compileE Γ reg .ff d = some c) :
    ∃ rd, regAt d = some rd ∧ c = [Instr.ADDI rd 0 0] := by
  cases h1 : regAt d with
  | none => simp [compileE, h1] at h
  | some rd =>
      refine ⟨rd, rfl, ?_⟩
      rw [compileE_ff_eq h1] at h; exact (Option.some.inj h).symm

theorem compileE_add_shape {Γ : Ctx} {reg : RegMap} {a b : Exp} {d : Nat} {c : List Instr}
    (h : compileE Γ reg (.add a b) d = some c) :
    ∃ ca cb, compileE Γ reg a d = some ca ∧ compileE Γ reg b (d + 1) = some cb ∧
      binOp .ADD ca cb d = some c := by
  cases h1 : compileE Γ reg a d with
  | none => simp [compileE, h1] at h
  | some ca =>
      cases h2 : compileE Γ reg b (d + 1) with
      | none => simp [compileE, h1, h2] at h
      | some cb => exact ⟨ca, cb, rfl, rfl, by rw [← compileE_add_eq h1 h2]; exact h⟩

theorem compileE_xor_shape {Γ : Ctx} {reg : RegMap} {a b : Exp} {d : Nat} {c : List Instr}
    (h : compileE Γ reg (.xor a b) d = some c) :
    ∃ ca cb, compileE Γ reg a d = some ca ∧ compileE Γ reg b (d + 1) = some cb ∧
      binOp .XOR ca cb d = some c := by
  cases h1 : compileE Γ reg a d with
  | none => simp [compileE, h1] at h
  | some ca =>
      cases h2 : compileE Γ reg b (d + 1) with
      | none => simp [compileE, h1, h2] at h
      | some cb => exact ⟨ca, cb, rfl, rfl, by rw [← compileE_xor_eq h1 h2]; exact h⟩

theorem compileE_slt_shape {Γ : Ctx} {reg : RegMap} {a b : Exp} {d : Nat} {c : List Instr}
    (h : compileE Γ reg (.slt a b) d = some c) :
    ∃ ca cb, compileE Γ reg a d = some ca ∧ compileE Γ reg b (d + 1) = some cb ∧
      binOp .SLT ca cb d = some c := by
  cases h1 : compileE Γ reg a d with
  | none => simp [compileE, h1] at h
  | some ca =>
      cases h2 : compileE Γ reg b (d + 1) with
      | none => simp [compileE, h1, h2] at h
      | some cb => exact ⟨ca, cb, rfl, rfl, by rw [← compileE_slt_eq h1 h2]; exact h⟩

theorem binOp_length {mk : Fin 32 → Fin 32 → Fin 32 → Instr} {ca cb c : List Instr}
    {d : Nat} (h : binOp mk ca cb d = some c) : c.length = ca.length + cb.length + 1 := by
  obtain ⟨rd, rs, _, _, rfl⟩ := binOp_shape h
  simp only [List.length_append, List.length_cons, List.length_nil]

#audit_axioms binOp compileE exec
#audit_axioms exec_nil exec_cons
#audit_axioms exec_append
#audit_axioms binOp_eq
#audit_axioms compileE_var_eq compileE_const_eq compileE_tt_eq compileE_ff_eq
#audit_axioms compileE_add_eq compileE_xor_eq compileE_slt_eq
#audit_axioms binOp_shape
#audit_axioms compileE_var_shape compileE_const_shape compileE_tt_shape compileE_ff_shape
#audit_axioms compileE_add_shape compileE_xor_shape compileE_slt_shape
#audit_axioms binOp_length

/-! ## 4. `compileE` EMITS STRAIGHT-LINE CODE — the hypothesis the fuel half needs

`runFor_extend` (L0's fuel half, `763d02a`) is gated on `Forward`. Without this theorem
the two halves of L0 do not meet. -/

theorem binOp_forward {mk : Fin 32 → Fin 32 → Fin 32 → Instr} {ca cb c : List Instr}
    {d : Nat} (hmk : ∀ x y z, isForward (mk x y z) = true)
    (ha : Forward ca = true) (hb : Forward cb = true) (h : binOp mk ca cb d = some c) :
    Forward c = true := by
  obtain ⟨rd, rs, _, _, rfl⟩ := binOp_shape h
  simp only [Forward] at ha hb ⊢
  simp [List.all_append, ha, hb, hmk]

/-- ⭐ **EVERY PROGRAM `compileE` EMITS IS BRANCH-FREE**, so `runFor_extend` covers all
of it. -/
theorem compileE_is_forward (Γ : Ctx) (reg : RegMap) :
    ∀ (e : Exp) (d : Nat) (c : List Instr),
      compileE Γ reg e d = some c → Forward c = true := by
  intro e
  induction e with
  | var x =>
      intro d c h; obtain ⟨rd, rs, _, _, rfl⟩ := compileE_var_shape h; rfl
  | const n =>
      intro d c h; obtain ⟨rd, imm, _, _, rfl⟩ := compileE_const_shape h; rfl
  | tt => intro d c h; obtain ⟨rd, _, rfl⟩ := compileE_tt_shape h; rfl
  | ff => intro d c h; obtain ⟨rd, _, rfl⟩ := compileE_ff_shape h; rfl
  | add a b iha ihb =>
      intro d c h; obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_add_shape h
      exact binOp_forward (fun _ _ _ => rfl) (iha d ca hca) (ihb (d + 1) cb hcb) hbin
  | xor a b iha ihb =>
      intro d c h; obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_xor_shape h
      exact binOp_forward (fun _ _ _ => rfl) (iha d ca hca) (ihb (d + 1) cb hcb) hbin
  | slt a b iha ihb =>
      intro d c h; obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_slt_shape h
      exact binOp_forward (fun _ _ _ => rfl) (iha d ca hca) (ihb (d + 1) cb hcb) hbin

#audit_axioms binOp_forward
#audit_axioms compileE_is_forward

/-! ## 5. THE FRAME

The load-bearing lemma. `add a b` compiles `b` into `d+1` **after** `a` has been left in
`d`, so the entire scheme is wrong unless compiling at `d+1` cannot touch `d`. -/

theorem binOp_frame {mk f} (hs : OpShape mk f) {ca cb c : List Instr} {d : Nat}
    (h : binOp mk ca cb d = some c)
    (hfa : ∀ (s : St) (r : Fin 32), r.val < d → (exec s ca).get r = s.get r)
    (hfb : ∀ (s : St) (r : Fin 32), r.val < d + 1 → (exec s cb).get r = s.get r)
    (st : St) (r : Fin 32) (hr : r.val < d) : (exec st c).get r = st.get r := by
  obtain ⟨rd, rs, hrd, _, rfl⟩ := binOp_shape h
  have hne : r ≠ rd := by
    intro hh; have hv := regAt_val hrd; rw [hh] at hr; omega
  rw [exec_append, exec_append, exec_cons, exec_nil, step_op_get_ne hs _ _ _ _ _ hne,
      hfb _ r (by omega), hfa st r hr]

/-- ⭐⭐ **REGISTERS STRICTLY BELOW THE DESTINATION ARE UNTOUCHED.** -/
theorem exec_compileE_preserves_below (Γ : Ctx) (reg : RegMap) :
    ∀ (e : Exp) (d : Nat) (c : List Instr) (st : St), compileE Γ reg e d = some c →
      ∀ r : Fin 32, r.val < d → (exec st c).get r = st.get r := by
  intro e
  induction e with
  | var x =>
      intro d c st h r hr
      obtain ⟨rd, rs, hrd, _, rfl⟩ := compileE_var_shape h
      have hne : r ≠ rd := by
        intro hh; have hv := regAt_val hrd; rw [hh] at hr; omega
      rw [exec_cons, exec_nil, step_ADDI_get_ne _ _ _ _ _ hne]
  | const n =>
      intro d c st h r hr
      obtain ⟨rd, imm, hrd, _, rfl⟩ := compileE_const_shape h
      have hne : r ≠ rd := by
        intro hh; have hv := regAt_val hrd; rw [hh] at hr; omega
      rw [exec_cons, exec_nil, step_ADDI_get_ne _ _ _ _ _ hne]
  | tt =>
      intro d c st h r hr
      obtain ⟨rd, hrd, rfl⟩ := compileE_tt_shape h
      have hne : r ≠ rd := by
        intro hh; have hv := regAt_val hrd; rw [hh] at hr; omega
      rw [exec_cons, exec_nil, step_ADDI_get_ne _ _ _ _ _ hne]
  | ff =>
      intro d c st h r hr
      obtain ⟨rd, hrd, rfl⟩ := compileE_ff_shape h
      have hne : r ≠ rd := by
        intro hh; have hv := regAt_val hrd; rw [hh] at hr; omega
      rw [exec_cons, exec_nil, step_ADDI_get_ne _ _ _ _ _ hne]
  | add a b iha ihb =>
      intro d c st h r hr
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_add_shape h
      exact binOp_frame opShape_ADD hbin (fun s r' hr' => iha d ca s hca r' hr')
        (fun s r' hr' => ihb (d + 1) cb s hcb r' hr') st r hr
  | xor a b iha ihb =>
      intro d c st h r hr
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_xor_shape h
      exact binOp_frame opShape_XOR hbin (fun s r' hr' => iha d ca s hca r' hr')
        (fun s r' hr' => ihb (d + 1) cb s hcb r' hr') st r hr
  | slt a b iha ihb =>
      intro d c st h r hr
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_slt_shape h
      exact binOp_frame opShape_SLT hbin (fun s r' hr' => iha d ca s hca r' hr')
        (fun s r' hr' => ihb (d + 1) cb s hcb r' hr') st r hr

#audit_axioms binOp_frame
#audit_axioms exec_compileE_preserves_below

/-! ## 6. CORRECTNESS — `compileE` computes `evalE`

Two hypotheses, and both are the same physical fact seen from two sides:

* `RegsHold` — the registers the map names currently hold the source slots' values;
* `PoolBelow` — the map's whole image sits **below** the destination, so the scratch
  area and the variable area are disjoint. For `regCanonical` the image is `x1..x15`,
  so the scratch base is **x16** and sixteen scratch registers remain.

`PoolBelow` also supplies `0 < d` for free (the pool is nonempty), which is exactly what
rules out P5's silent no-op: a destination of `x0` would discard every write. -/

/-- The registers the map names hold the source state's slots.

⭐ **NO `Γ`, AND THAT IS THE de BRUIJN REPAIR SHOWING THROUGH.** The drafted relation was
`encodeOK Γ σ st`; at the expression level the context is not consulted, because
`TinyRustN0`'s repair made a binder's runtime cell its **LEVEL**. `Γ` resolves a *name* to
a level — `varReg`'s job — and agreement is a statement about levels alone. *L1 will need
the context back, to scope agreement to the live prefix; L0 does not, and carrying a
parameter no clause mentions would be a false interface.*

⚠️ **AND ITS HONEST STRENGTH: this demands agreement on the WHOLE pool, not merely on the
slots `e` reads.** Satisfiable and convenient here (L1's `letmut` writes at `Γ.length` and
will want it), but it is stronger than the correctness theorem needs, and it is the clause
to weaken if a later rung wants a tighter hypothesis. -/
def RegsHold (reg : RegMap) (σ : State) (st : St) : Prop :=
  ∀ i : Fin poolSize, st.get (reg i) = σ i.val

/-- The map's image lies strictly below the scratch destination. -/
def PoolBelow (reg : RegMap) (d : Nat) : Prop := ∀ i : Fin poolSize, (reg i).val < d

/-- **A destination above a NONEMPTY pool cannot be `x0`** — so P5 (a write to `x0` is
discarded) is excluded by the hypothesis rather than by a side condition. -/
theorem PoolBelow.pos {reg : RegMap} {d : Nat} (h : PoolBelow reg d) : 0 < d :=
  Nat.lt_of_le_of_lt (Nat.zero_le _) (h ⟨0, by decide⟩)

theorem PoolBelow.succ {reg : RegMap} {d : Nat} (h : PoolBelow reg d) :
    PoolBelow reg (d + 1) := fun i => Nat.lt_succ_of_lt (h i)

/-- ⭐ **`regCanonical`'s SCRATCH BASE IS x16** — `x1..x15` are the pool, so sixteen
registers remain for temporaries and `expCostNoSwap e ≤ 16` is the real depth budget. -/
theorem poolBelow_regCanonical : PoolBelow regCanonical 16 := by
  intro i; have hi := i.isLt; simp only [regCanonical]; unfold poolSize at hi; omega

/-- The destination register is never `x0` under `PoolBelow`. -/
theorem dest_ne_zero {reg : RegMap} {d : Nat} {rd : Fin 32} (hrd : regAt d = some rd)
    (hpb : PoolBelow reg d) : rd ≠ 0 := by
  intro hh
  have hdv : rd.val = d := regAt_val hrd
  have hz : (0 : Fin 32).val = 0 := rfl
  have hp := hpb.pos
  rw [hh, hz] at hdv
  omega

/-- The binary case of §6's induction, written once for all three opcodes. -/
theorem compileE_bin_correct {Γ : Ctx} {reg : RegMap} {σ : State}
    {mk : Fin 32 → Fin 32 → Fin 32 → Instr} {f : BitVec 32 → BitVec 32 → BitVec 32}
    (hs : OpShape mk f) {a b : Exp} {d : Nat} {ca cb c : List Instr} {st : St} {rd : Fin 32}
    (hca : compileE Γ reg a d = some ca) (hcb : compileE Γ reg b (d + 1) = some cb)
    (h : binOp mk ca cb d = some c) (hrd : regAt d = some rd)
    (hst : RegsHold reg σ st) (hpb : PoolBelow reg d)
    (iha : ∀ (d : Nat) (c : List Instr) (st : St) (rd : Fin 32),
             compileE Γ reg a d = some c → regAt d = some rd → RegsHold reg σ st →
             PoolBelow reg d → (exec st c).get rd = evalE Γ σ a)
    (ihb : ∀ (d : Nat) (c : List Instr) (st : St) (rd : Fin 32),
             compileE Γ reg b d = some c → regAt d = some rd → RegsHold reg σ st →
             PoolBelow reg d → (exec st c).get rd = evalE Γ σ b) :
    (exec st c).get rd = f (evalE Γ σ a) (evalE Γ σ b) := by
  obtain ⟨rd', rs, hrd', hrs, rfl⟩ := binOp_shape h
  have hsame : rd' = rd := Option.some.inj (hrd'.symm.trans hrd)
  rw [hsame]
  have hd0 : rd ≠ 0 := dest_ne_zero hrd hpb
  have hdv : rd.val = d := regAt_val hrd
  -- the left operand lands in `rd`
  have hA : (exec st ca).get rd = evalE Γ σ a := iha d ca st rd hca hrd hst hpb
  -- the map's registers survive the left operand, so the invariant reaches the right one
  have hst1 : RegsHold reg σ (exec st ca) := fun i => by
    rw [exec_compileE_preserves_below Γ reg a d ca st hca (reg i) (hpb i)]; exact hst i
  -- the right operand lands in `rs`, and does not disturb `rd`
  have hB : (exec (exec st ca) cb).get rs = evalE Γ σ b :=
    ihb (d + 1) cb (exec st ca) rs hcb hrs hst1 hpb.succ
  have hA' : (exec (exec st ca) cb).get rd = evalE Γ σ a := by
    rw [exec_compileE_preserves_below Γ reg b (d + 1) cb (exec st ca) hcb rd (by omega)]
    exact hA
  rw [exec_append, exec_append, exec_cons, exec_nil, step_op_get_self hs _ _ _ _ hd0, hA', hB]

/-- ⭐⭐⭐ **THE L0 CORRECTNESS THEOREM, AT THE FOLD LEVEL.** The code `compileE` emits
leaves `evalE Γ σ e` in the destination register. -/
theorem exec_compileE_eq_evalE (Γ : Ctx) (reg : RegMap) (σ : State) :
    ∀ (e : Exp) (d : Nat) (c : List Instr) (st : St) (rd : Fin 32),
      compileE Γ reg e d = some c → regAt d = some rd → RegsHold reg σ st →
      PoolBelow reg d → (exec st c).get rd = evalE Γ σ e := by
  intro e
  induction e with
  | var x =>
      intro d c st rd h hrd hst hpb
      obtain ⟨rd', rs, hrd', hrs, rfl⟩ := compileE_var_shape h
      have hsame : rd' = rd := Option.some.inj (hrd'.symm.trans hrd)
      rw [hsame]
      have hd0 : rd ≠ 0 := dest_ne_zero hrd hpb
      obtain ⟨hslot, rfl⟩ := varReg_eq hrs
      have hz : ((0 : BitVec 12).signExtend 32) = (0 : BitVec 32) := by decide
      have hslotval : st.get (reg ⟨slotOf Γ x, hslot⟩) = σ (slotOf Γ x) :=
        hst ⟨slotOf Γ x, hslot⟩
      rw [exec_cons, exec_nil, step_ADDI_get_self _ _ _ _ hd0, hz, hslotval]
      show σ (slotOf Γ x) + (0 : BitVec 32) = σ (slotOf Γ x)
      simp
  | const n =>
      intro d c st rd h hrd hst hpb
      obtain ⟨rd', imm, hrd', himm, rfl⟩ := compileE_const_shape h
      have hsame : rd' = rd := Option.some.inj (hrd'.symm.trans hrd)
      rw [hsame]
      have hd0 : rd ≠ 0 := dest_ne_zero hrd hpb
      rw [exec_cons, exec_nil, step_ADDI_get_self _ _ _ _ hd0, St.get_zero]
      have hn : evalE Γ σ (Exp.const n) = n := rfl
      have hz : (0 : BitVec 32) + imm.signExtend 32 = imm.signExtend 32 := by simp
      rw [hn, hz]
      exact fitImm_signExtend himm
  | tt =>
      intro d c st rd h hrd hst hpb
      obtain ⟨rd', hrd', rfl⟩ := compileE_tt_shape h
      have hsame : rd' = rd := Option.some.inj (hrd'.symm.trans hrd)
      rw [hsame]
      have hd0 : rd ≠ 0 := dest_ne_zero hrd hpb
      have hv : evalE Γ σ Exp.tt = (1 : BitVec 32) := rfl
      rw [exec_cons, exec_nil, step_ADDI_get_self _ _ _ _ hd0, St.get_zero, hv]
      decide +kernel
  | ff =>
      intro d c st rd h hrd hst hpb
      obtain ⟨rd', hrd', rfl⟩ := compileE_ff_shape h
      have hsame : rd' = rd := Option.some.inj (hrd'.symm.trans hrd)
      rw [hsame]
      have hd0 : rd ≠ 0 := dest_ne_zero hrd hpb
      have hv : evalE Γ σ Exp.ff = (0 : BitVec 32) := rfl
      rw [exec_cons, exec_nil, step_ADDI_get_self _ _ _ _ hd0, St.get_zero, hv]
      decide +kernel
  | add a b iha ihb =>
      intro d c st rd h hrd hst hpb
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_add_shape h
      exact compileE_bin_correct opShape_ADD hca hcb hbin hrd hst hpb iha ihb
  | xor a b iha ihb =>
      intro d c st rd h hrd hst hpb
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_xor_shape h
      exact compileE_bin_correct opShape_XOR hca hcb hbin hrd hst hpb iha ihb
  | slt a b iha ihb =>
      intro d c st rd h hrd hst hpb
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_slt_shape h
      exact compileE_bin_correct opShape_SLT hca hcb hbin hrd hst hpb iha ihb

#audit_axioms RegsHold PoolBelow
#audit_axioms PoolBelow.pos PoolBelow.succ
#audit_axioms poolBelow_regCanonical
#audit_axioms dest_ne_zero
#audit_axioms compileE_bin_correct
#audit_axioms exec_compileE_eq_evalE

/-! ## 7. TOTALITY (A5), AND THE COST FUNCTION THAT IS LOAD-BEARING AT L0

A5: *"L0 gains a per-rung totality lemma (`compileE` returns `some` on well-typed,
in-pool expressions) so the reject-everything mutant binds at L0, not only at L4."*

**The hypotheses ARE the rejection causes**, which is what makes "exactly these, no
others" a checkable claim rather than a reading of the code. -/

/-- Every constant in the expression fits `ADDI`'s signed field — rejection cause (1) as
a source-level predicate. -/
def immsFit : Exp → Bool
  | .const n => (fitImm n).isSome
  | .var _ | .tt | .ff => true
  | .add a b | .xor a b | .slt a b => immsFit a && immsFit b

theorem expCostNoSwap_pos (e : Exp) : 0 < expCostNoSwap e := by
  cases e <;> simp only [expCostNoSwap] <;> omega

/-- A well-typed variable's slot is inside its context, hence inside the pool. -/
theorem slotOf_lt_of_inferE {Γ : Ctx} {x : Nat} {t : Ty} (h : inferE Γ (.var x) = some t) :
    slotOf Γ x < Γ.length := by
  simp only [inferE, look, Option.map_eq_some_iff] at h
  obtain ⟨p, hp, _⟩ := h
  have hs : slotOf Γ x = p.1 := by simp [slotOf, hp]
  rw [hs]; exact lookLvl_lt Γ x p.1 p.2 (by rw [hp])

theorem inferE_add_inv {Γ : Ctx} {a b : Exp} {t : Ty} (h : inferE Γ (.add a b) = some t) :
    inferE Γ a = some .i32 ∧ inferE Γ b = some .i32 := by
  cases hA : inferE Γ a with
  | none => simp [inferE, hA] at h
  | some ta =>
      cases hB : inferE Γ b with
      | none => cases ta <;> simp [inferE, hA, hB] at h
      | some tb =>
          cases ta with
          | i32 => cases tb with
                   | i32 => exact ⟨rfl, rfl⟩
                   | bool => simp [inferE, hA, hB] at h
          | bool => cases tb <;> simp [inferE, hA, hB] at h

theorem inferE_xor_inv {Γ : Ctx} {a b : Exp} {t : Ty} (h : inferE Γ (.xor a b) = some t) :
    inferE Γ a = some .i32 ∧ inferE Γ b = some .i32 := by
  cases hA : inferE Γ a with
  | none => simp [inferE, hA] at h
  | some ta =>
      cases hB : inferE Γ b with
      | none => cases ta <;> simp [inferE, hA, hB] at h
      | some tb =>
          cases ta with
          | i32 => cases tb with
                   | i32 => exact ⟨rfl, rfl⟩
                   | bool => simp [inferE, hA, hB] at h
          | bool => cases tb <;> simp [inferE, hA, hB] at h

theorem inferE_slt_inv {Γ : Ctx} {a b : Exp} {t : Ty} (h : inferE Γ (.slt a b) = some t) :
    inferE Γ a = some .i32 ∧ inferE Γ b = some .i32 := by
  cases hA : inferE Γ a with
  | none => simp [inferE, hA] at h
  | some ta =>
      cases hB : inferE Γ b with
      | none => cases ta <;> simp [inferE, hA, hB] at h
      | some tb =>
          cases ta with
          | i32 => cases tb with
                   | i32 => exact ⟨rfl, rfl⟩
                   | bool => simp [inferE, hA, hB] at h
          | bool => cases tb <;> simp [inferE, hA, hB] at h

/-- ⭐⭐⭐ **A5's TOTALITY LEMMA.** A well-typed, in-pool expression whose constants fit
and whose register demand fits **compiles**. The demand term is the landed
`expCostNoSwap` — see `classic_SU_would_break_totality` for why it must be that one. -/
theorem compileE_total (Γ : Ctx) (reg : RegMap) (hΓ : Γ.length ≤ poolSize) :
    ∀ (e : Exp) (t : Ty) (d : Nat), inferE Γ e = some t → immsFit e = true →
      d + expCostNoSwap e ≤ 32 → (compileE Γ reg e d).isSome = true := by
  intro e
  induction e with
  | var x =>
      intro t d hty _ hd
      have hd32 : d < 32 := by simp only [expCostNoSwap] at hd; omega
      have hslot : slotOf Γ x < poolSize :=
        Nat.lt_of_lt_of_le (slotOf_lt_of_inferE hty) hΓ
      have h2 : varReg Γ reg x = some (reg ⟨slotOf Γ x, hslot⟩) := by simp [varReg, hslot]
      rw [compileE_var_eq (regAt_of_lt hd32) h2]; rfl
  | const n =>
      intro t d _ himm hd
      have hd32 : d < 32 := by simp only [expCostNoSwap] at hd; omega
      simp only [immsFit] at himm
      obtain ⟨imm, himm⟩ := Option.isSome_iff_exists.mp himm
      rw [compileE_const_eq (regAt_of_lt hd32) himm]; rfl
  | tt =>
      intro t d _ _ hd
      have hd32 : d < 32 := by simp only [expCostNoSwap] at hd; omega
      rw [compileE_tt_eq (regAt_of_lt hd32)]; rfl
  | ff =>
      intro t d _ _ hd
      have hd32 : d < 32 := by simp only [expCostNoSwap] at hd; omega
      rw [compileE_ff_eq (regAt_of_lt hd32)]; rfl
  | add a b iha ihb =>
      intro t d hty himm hd
      obtain ⟨hta, htb⟩ := inferE_add_inv hty
      simp only [immsFit, Bool.and_eq_true] at himm
      simp only [expCostNoSwap] at hd
      have hpa := expCostNoSwap_pos a
      have hpbb := expCostNoSwap_pos b
      obtain ⟨ca, hca⟩ :=
        Option.isSome_iff_exists.mp (iha .i32 d hta himm.1 (by omega))
      obtain ⟨cb, hcb⟩ :=
        Option.isSome_iff_exists.mp (ihb .i32 (d + 1) htb himm.2 (by omega))
      rw [compileE_add_eq hca hcb,
          binOp_eq (regAt_of_lt (show d < 32 by omega)) (regAt_of_lt (show d + 1 < 32 by omega))]
      rfl
  | xor a b iha ihb =>
      intro t d hty himm hd
      obtain ⟨hta, htb⟩ := inferE_xor_inv hty
      simp only [immsFit, Bool.and_eq_true] at himm
      simp only [expCostNoSwap] at hd
      have hpa := expCostNoSwap_pos a
      have hpbb := expCostNoSwap_pos b
      obtain ⟨ca, hca⟩ :=
        Option.isSome_iff_exists.mp (iha .i32 d hta himm.1 (by omega))
      obtain ⟨cb, hcb⟩ :=
        Option.isSome_iff_exists.mp (ihb .i32 (d + 1) htb himm.2 (by omega))
      rw [compileE_xor_eq hca hcb,
          binOp_eq (regAt_of_lt (show d < 32 by omega)) (regAt_of_lt (show d + 1 < 32 by omega))]
      rfl
  | slt a b iha ihb =>
      intro t d hty himm hd
      obtain ⟨hta, htb⟩ := inferE_slt_inv hty
      simp only [immsFit, Bool.and_eq_true] at himm
      simp only [expCostNoSwap] at hd
      have hpa := expCostNoSwap_pos a
      have hpbb := expCostNoSwap_pos b
      obtain ⟨ca, hca⟩ :=
        Option.isSome_iff_exists.mp (iha .i32 d hta himm.1 (by omega))
      obtain ⟨cb, hcb⟩ :=
        Option.isSome_iff_exists.mp (ihb .i32 (d + 1) htb himm.2 (by omega))
      rw [compileE_slt_eq hca hcb,
          binOp_eq (regAt_of_lt (show d < 32 by omega)) (regAt_of_lt (show d + 1 < 32 by omega))]
      rfl

#audit_axioms immsFit
#audit_axioms expCostNoSwap_pos
#audit_axioms slotOf_lt_of_inferE
#audit_axioms inferE_add_inv inferE_xor_inv inferE_slt_inv
#audit_axioms compileE_total

/-! ## 8. TRANSPORT — from the fold to the ISA's own `run`

The one place `pc` and `fetch` appear. Straight-line code executed from its own start is
the fold, and that is the bridge L1 inherits. -/

/-- The block lemma: with `pre` already behind it and the `pc` at `pre`'s end, running
`post.length` ticks of the whole image executes exactly `post`. -/
theorem runFor_eq_exec_block : ∀ (post pre : List Instr) (st : St),
    Forward (pre ++ post) = true → 4 * (pre ++ post).length < 2 ^ 32 →
    st.pc.toNat = 4 * pre.length → runFor post.length (pre ++ post) st = exec st post := by
  intro post
  induction post with
  | nil => intro pre st _ _ _; simp [runFor]
  | cons i rest ih =>
      intro pre st hf hb hpc
      have hlen : (pre ++ i :: rest).length = pre.length + rest.length + 1 := by
        simp only [List.length_append, List.length_cons]; omega
      have hfetch : fetch (pre ++ i :: rest) st.pc = some i := by
        unfold fetch
        rw [if_pos (by omega : st.pc.toNat % 4 = 0)]
        have hdiv : st.pc.toNat / 4 = pre.length := by omega
        rw [hdiv]
        simp
      have hfw : isForward i = true := fetch_forward hf hfetch
      have hpc4 : (step st i).pc.toNat = 4 * (pre ++ [i]).length := by
        have h1 : (step st i).pc = st.pc + 4 := step_forward_pc st i hfw
        rw [hlen] at hb
        have hbnd : st.pc.toNat + 4 < 2 ^ 32 := by omega
        have h4 : ((4 : BitVec 32)).toNat = 4 := by decide
        rw [h1, BitVec.toNat_add, h4, Nat.mod_eq_of_lt hbnd]
        simp only [List.length_append, List.length_cons, List.length_nil]
        omega
      have hsplit : pre ++ i :: rest = (pre ++ [i]) ++ rest := by simp
      rw [List.length_cons, SaltWorks.Stack.Program.runFor_step _ hfetch, hsplit]
      rw [hsplit] at hf hb
      rw [ih (pre ++ [i]) (step st i) hf hb hpc4]
      simp

/-- ⭐⭐ **STRAIGHT-LINE CODE RUN FROM ITS OWN START IS THE FOLD.** -/
theorem run_eq_exec (code : List Instr) (st : St) (hf : Forward code = true)
    (hb : 4 * code.length < 2 ^ 32) (hpc : st.pc = 0) : run code st = exec st code := by
  have h := runFor_eq_exec_block code [] st (by simpa using hf) (by simpa using hb)
    (by simp [hpc])
  simpa [run] using h

/-- …and by the fuel half (`763d02a`), **any sufficient fuel gives the same answer** —
the form L1 needs when it glues expression blocks into statements. -/
theorem runFor_eq_exec (code : List Instr) (st : St) (n : Nat) (hn : code.length ≤ n)
    (hf : Forward code = true) (hb : 4 * code.length < 2 ^ 32) (hpc : st.pc = 0) :
    runFor n code st = exec st code := by
  rw [runFor_extend code st n hn hf hb]; exact run_eq_exec code st hf hb hpc

/-- ⭐⭐⭐ **THE L0 THEOREM AT THE MACHINE'S OWN `run`.** Compile an expression, run the
emitted program from `pc = 0`, and the destination register holds `evalE Γ σ e`.

The `4 * c.length < 2 ^ 32` hypothesis is the one `compileE` does **not** check — see
§9, where that is priced rather than assumed away. -/
theorem run_compileE_eq_evalE (Γ : Ctx) (reg : RegMap) (σ : State) (e : Exp) (d : Nat)
    (c : List Instr) (st : St) (rd : Fin 32)
    (hc : compileE Γ reg e d = some c) (hrd : regAt d = some rd)
    (hst : RegsHold reg σ st) (hpb : PoolBelow reg d)
    (hpc : st.pc = 0) (hb : 4 * c.length < 2 ^ 32) :
    (run c st).get rd = evalE Γ σ e := by
  rw [run_eq_exec c st (compileE_is_forward Γ reg e d c hc) hb hpc]
  exact exec_compileE_eq_evalE Γ reg σ e d c st rd hc hrd hst hpb

#audit_axioms runFor_eq_exec_block
#audit_axioms run_eq_exec
#audit_axioms runFor_eq_exec
#audit_axioms run_compileE_eq_evalE

/-! ## 9. THE CONTROLS — each rejection cause exhibited, and the third one PRICED -/

/-- One `i32` binding, so `var 0` is in the pool and well-typed. -/
def ctxOne : Ctx := [(0, Ty.i32)]

/-- `x + 5`, the running witness. Well-typed, in pool, constants fit. -/
def witnessExp : Exp := .add (.var 0) (.const 5)

/-- ⭐ **NON-VACUITY AT `run`, kernel-executed.** `regCanonical` puts slot 0 in `x1`; a
prelude sets `x1 = 7`; the compiled `x + 5` leaves **12** in the scratch base `x16`.
*Without this, every theorem above is satisfied by a `compileE` nobody can run.* -/
theorem witness_executes :
    (compileE ctxOne regCanonical witnessExp 16).map
        (fun c => (exec (step St.init (.ADDI 1 0 7)) c).get 16) = some 12 := by
  decide +kernel

/-- …and from `pc = 0` through the machine's own `run`, with `x1 = 0`: `0 + 5 = 5`, the
`pc` ending at `4 * 3` bytes. -/
theorem witness_runs_from_zero :
    (compileE ctxOne regCanonical witnessExp 16).map
        (fun c => ((run c St.init).get 16, (run c St.init).pc, c.length))
      = some (5, 12, 3) := by
  decide +kernel

/-- ⛔ **THE REJECT-EVERYTHING MUTANT**, coexisting rather than a destructive edit (the
house law: a broken definition beside the real one, carrying a permanent inequality). -/
def compileE_rejectAll (_Γ : Ctx) (_reg : RegMap) (_e : Exp) (_d : Nat) :
    Option (List Instr) := none

/-- ⭐ **A5's BINDING CONTROL: the mutant FAILS totality at L0**, not only at L4. -/
theorem rejectAll_fails_totality :
    (compileE ctxOne regCanonical witnessExp 16).isSome = true
  ∧ (compileE_rejectAll ctxOne regCanonical witnessExp 16).isSome = false := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- …and the totality lemma covers that witness, so the control is not a lucky literal. -/
theorem witnessExp_is_total_by_the_lemma :
    (compileE ctxOne regCanonical witnessExp 16).isSome = true :=
  compileE_total ctxOne regCanonical (by decide) witnessExp .i32 16
    (by decide) (by decide) (by decide)

/-! ### The rejection causes, each exhibited -/

/-- **CAUSE (1) — an unrepresentable constant.** `2^20` needs more than `ADDI`'s 12
signed bits; nothing about registers is wrong here, and the same expression at the same
`d` with a *fitting* constant compiles. -/
theorem cause_unrepresentable_constant :
    compileE ctxOne regCanonical (.const (2 ^ 20)) 16 = none
  ∧ (compileE ctxOne regCanonical (.const 5) 16).isSome = true := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- **CAUSE (2) — register exhaustion.** The same expression compiles at `d = 16` and
fails at `d = 31`, where the right operand would need `x32`. -/
theorem cause_register_exhaustion :
    compileE ctxOne regCanonical witnessExp 31 = none
  ∧ (compileE ctxOne regCanonical witnessExp 16).isSome = true := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- Twenty distinct bindings — a context WIDER than the fifteen-cell pool. -/
def ctxWide : Ctx := (List.range 20).reverse.map (fun i => (i, Ty.i32))

/-- ⚠️ **AND THE THIRD `none` PATH, NAMED RATHER THAN FOLDED AWAY: a slot outside the
pool.** In `ctxWide` the innermost binding sits at level 19 and the outermost at level 0;
`varReg` takes the second and rejects the first. **Both variables are BOUND and both are
well-typed** — the difference is the level alone, which is why this is a *surface of cause
(2)* (one finite register file) rather than a new cause, and why `compileE_total` carries
`Γ.length ≤ poolSize` to exclude it. -/
theorem cause_slot_out_of_pool :
    varReg ctxWide regCanonical 19 = none
  ∧ (varReg ctxWide regCanonical 0).isSome = true
  ∧ inferE ctxWide (.var 19) = some .i32 := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-! ### ⛔⛔ THE SETHI–ULLMAN TRAP, NOW LOAD-BEARING AT L0

`expCostNoSwap`'s own docstring warns that a reader who recognises the shape and
"corrects" it to the classic Sethi–Ullman number would make it UNDER-count. Until now
that was a fact about a cost function nothing consumed. **`compileE_total` consumes it**,
so the warning is now a theorem about a compiler. -/

/-- The classic Sethi–Ullman number — the one `expCostNoSwap` is NOT, present only so the
divergence can be stated as an inequality rather than as prose. -/
def classicSU : Exp → Nat
  | .var _ | .const _ | .tt | .ff => 1
  | .add a b | .xor a b | .slt a b =>
      if classicSU a = classicSU b then classicSU a + 1 else max (classicSU a) (classicSU b)

/-- Math's own witness from `expCostNoSwap_exceeds_classic_SU`: a leaf added to an
operation on two leaves, where the two cost functions disagree. -/
def suWitness : Exp := .add (.var 0) (.add (.var 0) (.var 0))

/-- ⭐⭐⭐ **THE CLASSIC NUMBER WOULD MAKE `compileE_total` FALSE**, and the statement
carries **every other hypothesis of `compileE_total`** so the reader need not check them
elsewhere: at `d = 30` the context fits the pool, the expression is well-typed, its
constants fit (it has none) — and classic SU says `30 + 2 ≤ 32`. A totality lemma stated
with the classic number would therefore promise a compilation **that `compileE` refuses**.
`expCostNoSwap` says `3`, and `30 + 3 > 32` predicts the refusal correctly.

*The trap is not hypothetical and no build catches it: swap the cost function and every
other theorem in this file stays green.* -/
theorem classic_SU_would_break_totality :
    ctxOne.length ≤ poolSize
  ∧ inferE ctxOne suWitness = some .i32
  ∧ immsFit suWitness = true
  ∧ classicSU suWitness = 2
  ∧ 30 + classicSU suWitness ≤ 32
  ∧ expCostNoSwap suWitness = 3
  ∧ ¬ (30 + expCostNoSwap suWitness ≤ 32)
  ∧ compileE ctxOne regCanonical suWitness 30 = none := by
  refine ⟨by decide, by decide, by decide, by decide, by decide, by decide, by decide,
          by decide +kernel⟩

/-! ### THE CANDIDATE THIRD CAUSE, PRICED

L4 names instruction-memory length as a candidate third rejection cause "to be PRICED,
not assumed away". Here is the price. -/

/-- Left-nested addition: `(((x + x) + x) + x) …`. -/
def leftNest : Nat → Exp
  | 0 => .var 0
  | n + 1 => .add (leftNest n) (.var 0)

theorem leftNest_typed (n : Nat) : inferE ctxOne (leftNest n) = some .i32 := by
  induction n with
  | zero => decide
  | succ k ih => simp only [leftNest, inferE, ih]; rfl

theorem leftNest_immsFit (n : Nat) : immsFit (leftNest n) = true := by
  induction n with
  | zero => decide
  | succ k ih => simp [leftNest, immsFit, ih]

/-- **THE REGISTER DEMAND IS CONSTANT.** Left nesting never increases the depth, because
only the RIGHT operand moves the destination up. -/
theorem leftNest_cost (n : Nat) : expCostNoSwap (leftNest n) ≤ 2 := by
  induction n with
  | zero => decide
  | succ k ih => simp only [leftNest, expCostNoSwap]; omega

theorem leftNest_isSome (n : Nat) :
    (compileE ctxOne regCanonical (leftNest n) 16).isSome = true :=
  compileE_total ctxOne regCanonical (by decide) (leftNest n) .i32 16
    (leftNest_typed n) (leftNest_immsFit n) (by have := leftNest_cost n; omega)

theorem compileE_var_length {Γ : Ctx} {reg : RegMap} {x d : Nat} {c : List Instr}
    (h : compileE Γ reg (.var x) d = some c) : c.length = 1 := by
  obtain ⟨rd, rs, _, _, rfl⟩ := compileE_var_shape h; rfl

/-- **AND THE CODE LENGTH GROWS WITHOUT BOUND.** -/
theorem leftNest_length : ∀ (n : Nat) (c : List Instr),
    compileE ctxOne regCanonical (leftNest n) 16 = some c → c.length = 2 * n + 1 := by
  intro n
  induction n with
  | zero => intro c h; simp only [leftNest] at h; exact compileE_var_length h
  | succ k ih =>
      intro c h
      simp only [leftNest] at h
      obtain ⟨ca, cb, hca, hcb, hbin⟩ := compileE_add_shape h
      rw [binOp_length hbin, ih ca hca, compileE_var_length hcb]
      omega

/-- ⭐⭐⭐ **INSTRUCTION-MEMORY LENGTH IS A GENUINE THIRD CAUSE, AND `compileE` DOES NOT
CHECK IT.** For every `n`, `leftNest n` is well-typed, in pool, has fitting constants and
a register demand of at most **2** — yet its emitted image is `2n+1` instructions long.
So the `4 * c.length < 2 ^ 32` hypothesis carried by `run_compileE_eq_evalE` is **not
implied** by the other two causes, and no bound on registers or immediates supplies it.

*This is the price L4 asked for. It is cheap to pay — a length check on the emitted image
— but it is not free, and it is not already paid.* -/
theorem code_length_is_unbounded_at_constant_register_demand : ∀ n : Nat,
    inferE ctxOne (leftNest n) = some .i32
  ∧ immsFit (leftNest n) = true
  ∧ expCostNoSwap (leftNest n) ≤ 2
  ∧ ∀ c, compileE ctxOne regCanonical (leftNest n) 16 = some c → c.length = 2 * n + 1 :=
  fun n => ⟨leftNest_typed n, leftNest_immsFit n, leftNest_cost n, leftNest_length n⟩

#audit_axioms ctxOne witnessExp
#audit_axioms witness_executes
#audit_axioms witness_runs_from_zero
#audit_axioms compileE_rejectAll
#audit_axioms rejectAll_fails_totality
#audit_axioms witnessExp_is_total_by_the_lemma
#audit_axioms cause_unrepresentable_constant
#audit_axioms cause_register_exhaustion
#audit_axioms ctxWide
#audit_axioms cause_slot_out_of_pool
#audit_axioms classicSU
#audit_axioms suWitness
#audit_axioms classic_SU_would_break_totality
#audit_axioms leftNest
#audit_axioms leftNest_typed leftNest_immsFit leftNest_cost
#audit_axioms leftNest_isSome
#audit_axioms compileE_var_length
#audit_axioms leftNest_length
#audit_axioms code_length_is_unbounded_at_constant_register_demand

end SaltWorks.CompileE

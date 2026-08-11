import SaltWorks.HDL.CompileS

/-! # THE BLOCK CALCULUS — L2's machinery, and the lift that keeps L1 from being reproved

Block ① rung **L2** is control (`ite`, then `while`). This file is the **machinery L2
needs and nothing else**: it emits no branch and compiles no new statement form. It is
landed alone because it is checkable alone, and because getting it wrong is how a control
rung turns into a rewrite of the two rungs beneath it.

## The problem L2 creates, stated before it is solved

L0 and L1 model execution as `exec st c = c.foldl step st` — a pure fold — and transport
to the machine once. **That works only because the code is `Forward`.** A branch is not a
fold: `ite` emits `BEQ`, the `pc` stops being `start + 4 * (steps taken)`, and the sub-blocks
are no longer executed in list order.

⚠️ ***I BANKED THIS AS "`Forward` AND `exec` DIE AT L2". THAT WAS TOO STRONG AND IS
CORRECTED HERE:*** they stop being **whole-program** properties and become **per-block**
ones. A straight-line sub-block inside a branching program is still a fold, and
`runFor_straightline` below is exactly that statement. *L2 generalises this machinery; it
does not replace it.*

## The two ideas

* **`codeAt image p blk`** — the block sits at instruction index `p` of the whole image.
  Correctness is stated about the IMAGE (which is what the machine fetches from) while
  compilation stays about the BLOCK. **`compileS` needs no position parameter**, because a
  `BEQ` displacement is pc-relative and therefore depends on block LENGTHS alone — the
  property `CodegenSpec`'s certificate already exhibits ("prepending an instruction shifts
  every address and no displacement").
* **`Reaches image st st'`** — `∃ n, runFor n image st = st'`. This is §4's ∃-fuel form,
  and it composes **unconditionally** by `runFor_add`, which is why the fuel was never L2's
  hard part.

## The lift, which is the point of the file

`reaches_of_compileS_of_branchFree` carries **L1's landed simulation theorem in without
reproving it** — the same move `regState` made when L1 consumed L0's whole-pool statement
under a scoped hypothesis. *Two rungs, two lifts, no re-induction. If L2's branch cases
ever force L1 to be re-proved, that is the signal the calculus is wrong, not L1.*

## What is NOT claimed

⛔ **No branch is emitted here and no new statement form compiles.** `ite` and `while`
still return `none` — this file does not move the fragment boundary by one statement.
⛔ **Position-independence of BRANCH DISPLACEMENTS is NOT exercised below.** Every block
this file can build is straight-line, so §5's relocation control demonstrates the
CALCULUS, not the branch property. *That control lands with `ite`, and saying so now is
cheaper than a reader assuming it is already paid.*
-/

open SaltWorks.ISA
open SaltWorks.StraightLine
open SaltWorks.RegMap
open SaltWorks.HDL.TinyRustN0
open SaltWorks.CompileE
open SaltWorks.CompileS

namespace SaltWorks.BlockCalc

/-! ## 1. `codeAt` — a block's position in the image -/

/-- The block `blk` occupies instruction indices `p, p+1, …` of `image`. -/
def codeAt (image : List Instr) (p : Nat) (blk : List Instr) : Prop :=
  ∀ i : Nat, i < blk.length → image[p + i]? = blk[i]?

theorem codeAt_nil (image : List Instr) (p : Nat) : codeAt image p [] := by
  intro i hi; simp at hi

theorem codeAt_append_left {image : List Instr} {p : Nat} {a b : List Instr}
    (h : codeAt image p (a ++ b)) : codeAt image p a := by
  intro i hi
  have hi' : i < (a ++ b).length := by simp; omega
  rw [h i hi', List.getElem?_append_left hi]

theorem codeAt_append_right {image : List Instr} {p : Nat} {a b : List Instr}
    (h : codeAt image p (a ++ b)) : codeAt image (p + a.length) b := by
  intro i hi
  have hi' : a.length + i < (a ++ b).length := by simp; omega
  have := h (a.length + i) hi'
  rw [show p + (a.length + i) = p + a.length + i from by omega] at this
  rw [this, List.getElem?_append_right (by omega)]
  simp

/-- The whole image sits at index 0 of itself — the base case every top-level run uses. -/
theorem codeAt_self (image : List Instr) : codeAt image 0 image := by
  intro i _; simp

/-- ⭐ **THE FETCH LAW.** With the `pc` at a block-relative index, the machine fetches the
block's own instruction — *this is the only place the image and the block meet, and every
branch case below goes through it.* -/
theorem fetch_codeAt {image blk : List Instr} {p i : Nat} {pc : BitVec 32}
    (h : codeAt image p blk) (hi : i < blk.length) (hpc : pc.toNat = 4 * (p + i)) :
    fetch image pc = blk[i]? := by
  unfold fetch
  rw [if_pos (by omega : pc.toNat % 4 = 0), show pc.toNat / 4 = p + i from by omega]
  exact h i hi

#audit_axioms codeAt
#audit_axioms codeAt_nil codeAt_append_left codeAt_append_right codeAt_self
#audit_axioms fetch_codeAt

/-! ## 2. A STRAIGHT-LINE BLOCK IS STILL A FOLD

The correction to my own bank, as a theorem: `exec` survives L2 scoped to a block. -/

/-- A forward block advances the `pc` by four bytes per instruction. -/
theorem exec_pc_toNat : ∀ (blk : List Instr) (st : St), Forward blk = true →
    st.pc.toNat + 4 * blk.length < 2 ^ 32 →
    (exec st blk).pc.toNat = st.pc.toNat + 4 * blk.length := by
  intro blk
  induction blk with
  | nil => intro st _ _; simp
  | cons i rest ih =>
      intro st hf hb
      simp only [Forward, List.all_cons, Bool.and_eq_true] at hf
      have hfw : isForward i = true := hf.1
      have hrest : Forward rest = true := by simp only [Forward]; exact hf.2
      have h1 : (step st i).pc = st.pc + 4 := step_forward_pc st i hfw
      have h4 : ((4 : BitVec 32)).toNat = 4 := by decide
      have hbnd : st.pc.toNat + 4 < 2 ^ 32 := by simp at hb; omega
      have hstep : (step st i).pc.toNat = st.pc.toNat + 4 := by
        rw [h1, BitVec.toNat_add, h4, Nat.mod_eq_of_lt hbnd]
      rw [exec_cons, ih (step st i) hrest (by rw [hstep]; simp at hb ⊢; omega), hstep]
      simp
      omega

/-- ⭐⭐⭐ **A STRAIGHT-LINE BLOCK RUNS THE SAME INSIDE ANY IMAGE THAT CONTAINS IT.** The
machine fetching from the whole program, for exactly the block's length, is the block's own
fold — **including the `pc`**, which `exec` already tracks.

*This is the generalisation of L1's `runFor_eq_exec_block` from "a prefix and a suffix" to
"anywhere in any image", and it is what lets a straight-line statement keep its cheap proof
after `ite` puts branches around it.* -/
theorem runFor_straightline : ∀ (blk image : List Instr) (p : Nat) (st : St),
    codeAt image p blk → Forward blk = true → st.pc.toNat = 4 * p →
    4 * (p + blk.length) < 2 ^ 32 → runFor blk.length image st = exec st blk := by
  intro blk
  induction blk with
  | nil => intro image p st _ _ _ _; simp [runFor]
  | cons i rest ih =>
      intro image p st hc hf hpc hb
      simp only [Forward, List.all_cons, Bool.and_eq_true] at hf
      have hfw : isForward i = true := hf.1
      have hrest : Forward rest = true := by simp only [Forward]; exact hf.2
      have hfetch : fetch image st.pc = some i := by
        have h0 := fetch_codeAt hc (i := 0) (by simp) (by omega)
        simpa using h0
      have h4 : ((4 : BitVec 32)).toNat = 4 := by decide
      have hbnd : st.pc.toNat + 4 < 2 ^ 32 := by simp at hb; omega
      have hstep : (step st i).pc.toNat = 4 * (p + 1) := by
        rw [step_forward_pc st i hfw, BitVec.toNat_add, h4, Nat.mod_eq_of_lt hbnd]
        omega
      have hcrest : codeAt image (p + 1) rest := by
        intro j hj
        have := hc (j + 1) (by simp; omega)
        rw [show p + (j + 1) = p + 1 + j from by omega] at this
        simpa using this
      rw [List.length_cons, SaltWorks.Stack.Program.runFor_step _ hfetch,
          ih image (p + 1) (step st i) hcrest hrest hstep (by simp at hb ⊢; omega)]
      simp

#audit_axioms exec_pc_toNat
#audit_axioms runFor_straightline

/-! ## 3. `Reaches` — §4's ∃-fuel form, and why the fuel was never the hard part -/

/-- The machine gets from `st` to `st'` on `image` in some number of ticks. -/
def Reaches (image : List Instr) (st st' : St) : Prop := ∃ n, runFor n image st = st'

theorem Reaches.refl (image : List Instr) (st : St) : Reaches image st st := ⟨0, rfl⟩

/-- ⭐⭐ **COMPOSITION IS UNCONDITIONAL** — no "enough fuel" side condition, because halting
is a fixed point (`runFor_add`). *This is the whole content of §4's key unlock, and it is
why L2's risk was always the simulation relation and the code layout, never the fuel.* -/
theorem Reaches.trans {image : List Instr} {a b c : St}
    (h1 : Reaches image a b) (h2 : Reaches image b c) : Reaches image a c := by
  obtain ⟨m, hm⟩ := h1
  obtain ⟨n, hn⟩ := h2
  exact ⟨m + n, by rw [SaltWorks.Stack.Program.runFor_add, hm, hn]⟩

/-- One fetched instruction is one step of progress. **The branch cases will consume this
directly** — a `BEQ` is not a fold, but it is a step. -/
theorem Reaches.one {image : List Instr} {st : St} {i : Instr}
    (h : fetch image st.pc = some i) : Reaches image st (step st i) :=
  ⟨1, by rw [SaltWorks.Stack.Program.runFor_step 0 h]; rfl⟩

/-- A straight-line block is reached by its own length. -/
theorem Reaches.straightline {blk image : List Instr} {p : Nat} {st : St}
    (hc : codeAt image p blk) (hf : Forward blk = true) (hpc : st.pc.toNat = 4 * p)
    (hb : 4 * (p + blk.length) < 2 ^ 32) : Reaches image st (exec st blk) :=
  ⟨blk.length, runFor_straightline blk image p st hc hf hpc hb⟩

#audit_axioms Reaches
#audit_axioms Reaches.refl Reaches.trans Reaches.one Reaches.straightline

/-! ## 4. THE LIFT — L1's theorem enters the calculus without being reproved

The same move `regState` made when L1 consumed L0. *If L2's branch cases ever force L1 to
be re-proved, that is the signal the calculus is wrong — not L1.* -/

/-- ⭐⭐⭐ **L1, INSIDE ANY IMAGE.** A straight-line statement placed anywhere in a larger
program reaches a state agreeing with `σ'` in scope, with the `pc` exactly past the block. -/
theorem reaches_of_compileS_of_branchFree {reg : RegMap} {d : Nat} (hreg : RegOk reg d)
    {Γ : Ctx} {p : Stmt} {σ σ' : State} {image blk : List Instr} {q : Nat} {st : St}
    (hbs : bigStep Γ p σ σ') (hbf : branchFree p = true) (hchk : chkS Γ p = true)
    (hc : compileS reg d Γ p = some blk) (hat : codeAt image q blk)
    (henc : encodeOK Γ reg σ st) (hpc : st.pc.toNat = 4 * q)
    (hb : 4 * (q + blk.length) < 2 ^ 32) :
    ∃ st', Reaches image st st' ∧ encodeOK Γ reg σ' st' ∧
      st'.pc.toNat = 4 * (q + blk.length) := by
  have hfwd : Forward blk = true := compileS_is_forward_of_branchFree reg d p Γ blk hbf hc
  refine ⟨exec st blk, Reaches.straightline hat hfwd hpc hb, ?_, ?_⟩
  · exact compileS_correct_of_branchFree hreg hbs hbf hchk blk st hc henc
  · rw [exec_pc_toNat blk st hfwd (by omega), hpc]; omega

#audit_axioms reaches_of_compileS_of_branchFree

/-! ## 5. THE CONTROLS -/

/-- Junk to place before a block, so relocation is exercised against a real offset rather
than against `0`. -/
def prefixJunk : List Instr := [.ADDI 31 0 1, .ADDI 30 0 2, .ADDI 29 0 3]

theorem prefixJunk_length : prefixJunk.length = 3 := rfl

/-- ⭐ **RELOCATION, EXERCISED.** L1's witness block computes the same answer at index 0 of
its own image and at index 3 of an image with junk in front — *the machine reads the same
instructions because `codeAt` says where they are, and nothing in the block depends on
where it sits.*

⚠️ **SCOPE, said plainly: every block reachable from `compileS` today is STRAIGHT-LINE, so
this exercises the CALCULUS and NOT the branch-displacement property.** A `BEQ`'s
displacement is pc-relative and therefore position-independent, but nothing here emits one.
*That control belongs to `ite` and is not claimed by this file.* -/
theorem relocation_gives_the_same_answer :
    (compileS regCanonical 16 ctx1 witnessAssign).map
        (fun c => ((run c st7).get 1,
                   (runFor (3 + c.length) (prefixJunk ++ c) st7).get 1))
      = some (12, 12) := by
  decide +kernel

/-- …and the control is not satisfied by a block that ignores its input: with `x1 = 0` the
same code answers **5**, not 12. *Without this, `relocation_gives_the_same_answer` is
consistent with a compiler that emits a constant.* -/
theorem relocation_control_is_load_bearing :
    (compileS regCanonical 16 ctx1 witnessAssign).map
        (fun c => (run c St.init).get 1) = some 5 := by
  decide +kernel

/-- **`Reaches` IS INHABITED BY A REAL RUN**, not only by `refl`. A relation that reaches
nothing turns every downstream row vacuously green. -/
theorem reaches_is_inhabited_nontrivially :
    (compileS regCanonical 16 ctx1 witnessAssign).map
        (fun c => ((run c st7).get 1 != st7.get 1, (run c st7).pc)) = some (true, 16) := by
  decide +kernel

#audit_axioms prefixJunk prefixJunk_length
#audit_axioms relocation_gives_the_same_answer
#audit_axioms relocation_control_is_load_bearing
#audit_axioms reaches_is_inhabited_nontrivially

/-! ## 6. THE `run` ↔ `Reaches` BRIDGE — math's third angle on `1b87d6e`, taken

*Their finding, and it is correct: L0's and L1's top statements are `run`-shaped
(`run_compileE_eq_evalE`, `run_compileS_correct_of_branchFree`) while this calculus is `Reaches`-shaped,
and nothing in the tree connected them. Not a defect inside L2 — a gap between rungs, and
they named it forward of where it bites rather than at L4.*

**The bridge is cheap in one direction and IMPOSSIBLE in the other, and the boundary
between the two is exactly the fragment boundary.** -/

/-- `Reaches` carrying a fuel BUDGET. This is the form that can be transported to `run`,
and the budget is the whole content of the transport. -/
def ReachesIn (image : List Instr) (k : Nat) (st st' : St) : Prop :=
  ∃ n, n ≤ k ∧ runFor n image st = st'

theorem ReachesIn.toReaches {image : List Instr} {k : Nat} {st st' : St}
    (h : ReachesIn image k st st') : Reaches image st st' := by
  obtain ⟨n, _, hn⟩ := h; exact ⟨n, hn⟩

/-- ⭐⭐ **THE BRIDGE.** A run that fits inside `image.length` ticks **and has halted** is
`run`. Halting is the fixed point `runFor_eq_of_halted` already supplies — the same fact
`Reaches.trans` leans on, used in the other direction. -/
theorem run_of_reachesIn {image : List Instr} {st st' : St}
    (h : ReachesIn image image.length st st') (hhalt : fetch image st'.pc = none) :
    run image st = st' := by
  obtain ⟨n, hn, rfl⟩ := h
  exact SaltWorks.Stack.Program.runFor_eq_of_halted hhalt hn

/-- …and a straight-line whole image satisfies the budget by construction, so for the
fragment L0 and L1 cover **the two shapes are interchangeable**. -/
theorem reachesIn_of_straightline {image : List Instr} {st : St}
    (hf : Forward image = true) (hb : 4 * image.length < 2 ^ 32) (hpc : st.pc.toNat = 0) :
    ReachesIn image image.length st (exec st image) :=
  ⟨image.length, Nat.le_refl _,
   runFor_straightline image image 0 st (codeAt_self image) hf (by simpa using hpc)
     (by simpa using hb)⟩

/-- ⛔⛔ **AND IN THE OTHER DIRECTION NO BRIDGE CAN EXIST — this is not a missing lemma.**
`run`'s fuel is `image.length`, one tick per instruction, and **a loop needs more ticks
than the program has instructions.** `loopCode` is two instructions; `run` spends two ticks
on it and stops mid-loop, and the landed control says the answer at two ticks differs from
the answer at six.

🔑 ***THE CONSEQUENCE, WHICH IS FOR L4 AND NOT FOR L2: Row A's top-level statement MUST be
`Reaches`-shaped. A `run`-shaped statement is correct exactly on the straight-line fragment
— which is why L0 and L1 are allowed to have one and the full compiler is not.*** *§4 said
the ∃-fuel form was needed for `while`; this is the same fact seen from the `run` side, and
it means the two shapes in the tree are not an inconsistency to be tidied away but a
boundary to be respected.* -/
theorem run_has_too_little_fuel_for_a_loop :
    run loopCode St.init = runFor 2 loopCode St.init
  ∧ ((runFor 2 loopCode St.init).get 1 == (runFor 6 loopCode St.init).get 1) = false := by
  refine ⟨rfl, by decide⟩

#audit_axioms ReachesIn
#audit_axioms ReachesIn.toReaches
#audit_axioms run_of_reachesIn
#audit_axioms reachesIn_of_straightline
#audit_axioms run_has_too_little_fuel_for_a_loop

end SaltWorks.BlockCalc

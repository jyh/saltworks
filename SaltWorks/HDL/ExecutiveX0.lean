/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA
import Mathlib.Tactic.FinCases

/-!
# X0 — THE EXECUTIVE DRIVER + INHABITANCE (block ② §5, as amended by §A)

**B1 (the FATAL repair).** The state is ONE shared register file plus a per-task
pc vector. `Vector St N` would give every task its own regfile and make X1's
isolation theorem vacuous *by type* — cross-task integrity free from
`Vector.getElem_set_ne`, and E-4's overlap mutant unconstructible.

**§4 — the driver decision.** Step-indexed, `Run := Nat → SysSt`, so X2's
fairness is plain ∀/∃ over `Nat` with no coinductive machinery. `IsRun` states
the run form abstractly and `IsRun.eq_runSys` shows it has no models beyond the
canonical one, so X2 can quantify over runs without quantifying over phantoms.

**B5 — E-5 is an EXECUTION witness, not an inhabitance one.** Under a total
`Nat → SysSt` every run is infinite by type and E-5 would be decorative.
`exec_forever` instead says the machine EXECUTES an instruction at every step,
forever. It needs a **backward branch**, which is precisely why block ①'s
forward-branch predicate is not a hypothesis available to executive tasks.

**The controls.** `halt_mutant_stalls` runs the same driver and the same initial
state with the branch deleted and exhibits the step at which the executive stops
executing — so `exec_forever` is a fact about the program, not about the type.
It is also a concrete instance of the halting configuration B4 requires X2's
fairness antecedent to exclude.

**Scope, said plainly.** X0 claims no isolation (that is X1) and no fairness
(that is X2). The witness's two tasks deliberately share one image and one
register: it costs the execution claim nothing and keeps the fetch free of any
case analysis on whose turn it is.

⚠️ **IMPORT OWED — maestro's call, not mine:** this module is not in the hub
closure.
-/

namespace SaltWorks.HDL.Exec

open SaltWorks.HDL SaltWorks.ISA

variable {N : Nat}

/-! ## 1. The state -/

/-- **The executive's state.** One shared `regs` (B1), one pc per task, and the
index of the task whose turn it is.

`cur : Fin N` carries `0 < N` with it, so no task count of zero can be written. -/
structure SysSt (N : Nat) where
  regs : Vector (BitVec 32) 32
  pcs  : Vector (BitVec 32) N
  cur  : Fin N
  deriving DecidableEq

/-- `0 < N` is free from the existence of a current task. -/
theorem SysSt.pos (sys : SysSt N) : 0 < N :=
  Nat.lt_of_le_of_lt (Nat.zero_le _) sys.cur.isLt

/-- Task `i`'s single-task view: the shared registers, its own pc. -/
def SysSt.task (sys : SysSt N) (i : Fin N) : St :=
  { regs := sys.regs, pc := sys.pcs[i.val] }

/-- Write a task's slice back: registers are shared, the pc is its own. -/
def SysSt.put (sys : SysSt N) (i : Fin N) (s : St) : SysSt N :=
  { sys with regs := s.regs, pcs := sys.pcs.set i.val s.pc }

/-- Hand the turn to the next task. Quantum is one instruction at X0; X2 makes
the scheduler data and proves fairness of the rotation. -/
def SysSt.rotate (sys : SysSt N) : SysSt N :=
  { sys with cur := ⟨(sys.cur.val + 1) % N, Nat.mod_lt _ sys.pos⟩ }

/-! ## 2. The driver -/

/-- **One executive step.** The current task fetches from ITS OWN code list
(B2: per-task code lists are the load-bearing hypothesis at X0–X3), executes at
most one instruction, writes its pc back, and yields the turn.

A task whose fetch fails is **not** an error and does not stop the executive —
it simply does nothing this turn. That is what makes X2's fairness antecedent
(B4) necessary rather than decorative. -/
def execStep (codes : Vector (List Instr) N) (sys : SysSt N) : SysSt N :=
  let i := sys.cur
  let s := sys.task i
  match fetch codes[i.val] s.pc with
  | none     => sys.rotate
  | some ins => (sys.put i (step s ins)).rotate

/-- The step-indexed run generated from an initial state. -/
def runSys (codes : Vector (List Instr) N) (init : SysSt N) : Nat → SysSt N
  | 0     => init
  | k + 1 => execStep codes (runSys codes init k)

/-- **The abstract run form** (§4). Any `Nat → SysSt` satisfying this is a run;
`runSys` is the canonical one. Stating it separately is what lets X2 quantify
over runs rather than over one construction. -/
def IsRun (codes : Vector (List Instr) N) (sys : Nat → SysSt N) : Prop :=
  ∀ k, sys (k + 1) = execStep codes (sys k)

theorem runSys_isRun (codes : Vector (List Instr) N) (init : SysSt N) :
    IsRun codes (runSys codes init) := fun _ => rfl

/-- Runs are determined by their start: the abstract form has no more models
than the concrete one. Keeps X2 from proving fairness of a phantom. -/
theorem IsRun.eq_runSys {codes : Vector (List Instr) N} {sys : Nat → SysSt N}
    (h : IsRun codes sys) : ∀ k, sys k = runSys codes (sys 0) k
  | 0     => rfl
  | k + 1 => by rw [h k, IsRun.eq_runSys h k]; rfl

/-! ## 3. "Executes an instruction" -/

/-- The current task has an instruction to run this turn. -/
def execAt (codes : Vector (List Instr) N) (sys : SysSt N) : Prop :=
  (fetch codes[sys.cur.val] (sys.pcs[sys.cur.val])).isSome = true

instance (codes : Vector (List Instr) N) (sys : SysSt N) :
    Decidable (execAt codes sys) := by unfold execAt; infer_instance

/-- **`stepsAt` — E-7's non-trivial reading of "steps"**: task `i` is scheduled
AND actually executes an instruction. X2's `fair` is
`∀ i n, ∃ m > n, stepsAt codes (sys m) i`; a definition that only said
"is scheduled" would make fairness true of a machine that never runs. -/
def stepsAt (codes : Vector (List Instr) N) (sys : SysSt N) (i : Fin N) : Prop :=
  sys.cur = i ∧ execAt codes sys

/-! ## 4. E-5 — THE EXECUTION WITNESS (B5)

`N = 2` per ruling (c). Both tasks run the same two-instruction loop: increment
a register, then branch **backward** to the top. The pc never leaves `{0, 4}`,
so the fetch never fails and the executive runs forever without stalling. -/

/-- Displacement `-4` bytes: `imm` holds `imm[12:1]`, so `imm = -2`. -/
def backEdge : BitVec 12 := 4094

/-- `x1 := x1 + 1; goto top`. **The backward branch is the point** — a forward
branch cannot produce an infinite execution, which is why block ①'s
forward-branch predicate is not a hypothesis available to executive tasks. -/
def loopProg2 (r : Fin 32) : List Instr := [.ADDI r r 1, .BEQ 0 0 backEdge]

/-- Both tasks run the SAME image. X0 claims no isolation — that is X1 — so
sharing the program (and thus the register) costs the witness nothing and buys
`codes2[i] = loopProg2 1` with no case analysis on whose turn it is. -/
def codes2 : Vector (List Instr) 2 := Vector.replicate 2 (loopProg2 1)

def init2 : SysSt 2 :=
  { regs := Vector.replicate 32 0, pcs := Vector.replicate 2 0, cur := 0 }

/-! ### The pc arithmetic, isolated from the register file -/

/-- A register write never moves the pc. -/
theorem St.set_pc (s : St) (r : Fin 32) (v : BitVec 32) : (s.set r v).pc = s.pc := by
  unfold St.set; split <;> rfl

/-- `ADDI` falls through. -/
theorem addi_pc (s : St) (rd rs : Fin 32) (imm : BitVec 12) :
    (step s (.ADDI rd rs imm)).pc = s.pc + 4 := by
  simp [step, St.next, St.set_pc]

/-- ⭐ **`BEQ x0, x0` IS AN UNCONDITIONAL JUMP** — `x0` reads zero by `St.get`'s
own law, so the branch is taken whatever the shared register file holds. **This
is what makes the pc evolution independent of `regs`**, and hence of the other
task. -/
theorem beq00_pc (s : St) (imm : BitVec 12) :
    (step s (.BEQ 0 0 imm)).pc = s.pc + bOffset imm := by
  simp [step]

/-- The loop body, as a pc fact: from either pc the fetch succeeds and lands
back inside `{0, 4}`. -/
theorem loop_step (s : St) (hp : s.pc = 0 ∨ s.pc = 4) :
    ∃ ins, fetch (loopProg2 1) s.pc = some ins ∧
      ((step s ins).pc = 0 ∨ (step s ins).pc = 4) := by
  rcases hp with hp | hp
  · refine ⟨.ADDI 1 1 1, by rw [hp]; decide, ?_⟩
    rw [addi_pc, hp]; right; decide
  · refine ⟨.BEQ 0 0 backEdge, by rw [hp]; decide, ?_⟩
    rw [beq00_pc, hp]; left; decide

/-! ### The invariant -/

/-- Every task sits at the top of the loop or at its backward branch. -/
def PcOK (sys : SysSt 2) : Prop := ∀ i : Nat, (h : i < 2) → sys.pcs[i] = 0 ∨ sys.pcs[i] = 4

theorem pcOK_init : PcOK init2 := by
  intro i h; left; simp [init2]

/-- Whoever is running, the image is the same one. -/
theorem codes2_at (i : Nat) (h : i < 2) : codes2[i] = loopProg2 1 := by
  simp [codes2]

/-- ⭐⭐ **THE INVARIANT IS PRESERVED.** The current task moves `0 ↔ 4`; every
other task's pc is untouched by `Vector.set` at a different index. -/
theorem pcOK_step (sys : SysSt 2) (h : PcOK sys) : PcOK (execStep codes2 sys) := by
  have hcur := h sys.cur.val sys.cur.isLt
  obtain ⟨ins, hf, hstep⟩ := loop_step (sys.task sys.cur) (by simpa [SysSt.task] using hcur)
  intro j hj
  have hfetch : fetch codes2[sys.cur.val] (sys.task sys.cur).pc = some ins := by
    rw [codes2_at _ sys.cur.isLt]; exact hf
  simp only [execStep, SysSt.rotate, SysSt.put, hfetch]
  by_cases hjc : j = sys.cur.val
  · subst hjc
    simpa using hstep
  · have hprev := h j hj
    simpa [Vector.getElem_set, Ne.symm hjc] using hprev

/-- ⭐⭐⭐ **E-5, DISCHARGED — THE EXECUTIVE NEVER STALLS.** At every step of the
run the scheduled task executes an instruction. Not "the run is infinite by
type" (B5 names that decorative): the machine does work at every step, forever,
and the backward branch is why. -/
theorem exec_forever : ∀ k, execAt codes2 (runSys codes2 init2 k) := by
  have inv : ∀ k, PcOK (runSys codes2 init2 k) := by
    intro k
    induction k with
    | zero => exact pcOK_init
    | succ k ih => exact pcOK_step _ ih
  intro k
  set sys := runSys codes2 init2 k with hsys
  have hpc := inv k sys.cur.val sys.cur.isLt
  unfold execAt
  rw [codes2_at _ sys.cur.isLt]
  rcases hpc with hpc | hpc <;> rw [hpc] <;> decide

/-- The witness in the shape X2's fairness consumes: at every step SOME task
provably steps, and it is the scheduled one. -/
theorem stepsAt_current (k : Nat) :
    stepsAt codes2 (runSys codes2 init2 k) (runSys codes2 init2 k).cur :=
  ⟨rfl, exec_forever k⟩

/-! ### ⛔ THE NEGATIVE CONTROL — the backward branch is what does the work -/

/-- The SAME driver and the SAME initial state, with the branch deleted. -/
def codesHalt : Vector (List Instr) 2 := Vector.replicate 2 [Instr.ADDI 1 1 1]

/-- ⛔ **THE MUTANT STALLS, AND HERE IS THE STEP AT WHICH IT DOES.** Delete the
backward branch and the executive stops executing after two steps: each task
falls off the end of its own image and the fetch returns `none`.

This is the witness that `exec_forever` is a fact about the PROGRAM and not
about the type — B5's whole complaint about `Nat → SysSt` being infinite by
construction. It also exhibits, concretely, the halting configuration B4 says
X2's fairness antecedent must exclude. -/
theorem halt_mutant_stalls : ¬ execAt codesHalt (runSys codesHalt init2 2) := by
  decide

/-- …and the control's control: the mutant does run for its first two steps, so
the stall is the branch's absence and not a broken configuration. -/
theorem halt_mutant_runs_first : execAt codesHalt (runSys codesHalt init2 0) := by
  decide

end SaltWorks.HDL.Exec

#print axioms SaltWorks.HDL.Exec.runSys_isRun
#print axioms SaltWorks.HDL.Exec.IsRun.eq_runSys
#print axioms SaltWorks.HDL.Exec.beq00_pc
#print axioms SaltWorks.HDL.Exec.pcOK_step
#print axioms SaltWorks.HDL.Exec.exec_forever
#print axioms SaltWorks.HDL.Exec.stepsAt_current
#print axioms SaltWorks.HDL.Exec.halt_mutant_stalls
#print axioms SaltWorks.HDL.Exec.halt_mutant_runs_first

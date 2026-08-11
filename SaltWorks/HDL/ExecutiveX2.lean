/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ExecutiveX0

/-!
# X2 — ROUND-ROBIN + FAIRNESS (block ② §5, per §A's B4)

**B4, and it is the whole reason this rung carries an antecedent.** Fairness as
first drafted is FALSE for any configuration containing a halting task: such a
task is scheduled forever and executes nothing. The amended form names the
antecedent — *every task's image non-halting at every scheduled entry* — which
is exactly `execAt` holding along the run.

**X0 already inhabits that antecedent and already refutes its removal.**
`exec_forever` supplies it; `halt_mutant_stalls` is a configuration where it
fails. Neither had to be invented here, and `halt_mutant_not_neverStalls` turns
B4's caution into a theorem.

**The shape of the proof.** `execStep_cur`: the turn advances whether or not the
scheduled task ran — so the rotation is a function of the step count alone, and
a halting task does not freeze the executive, it only fails to progress itself.
`cur_runSys` then puts the schedule in closed form, and fairness reduces to the
arithmetic fact that a rotation hits every residue after any given time.

**B4's fence, restated so it cannot be quoted away:** this is the PREEMPTIVE
form. It does NOT refine to X4's compiled executive, which is cooperative and
re-acquires the yield antecedent; X2's fairness class and X4's compiled-task
class are disjoint program classes. Per B4, §2.2's claim that "E-6's scope
caveat disappears" is STRUCK — preemption retires never-YIELDS only;
never-RUNNABLE stands.

**`stepsAt` is E-7's non-trivial reading — scheduled AND executes.** A
definition that only said "is scheduled" would make fairness true of a machine
that never runs anything.

⚠️ **IMPORT OWED — maestro's call, not mine:** this module is not in the hub
closure.
-/

namespace SaltWorks.HDL.Exec

open SaltWorks.HDL SaltWorks.ISA

variable {N : Nat}

/-! ## 1. The scheduler as data — the rotation is unconditional -/

/-- **The turn always advances**, whether or not the scheduled task had an
instruction to run. That is what makes the rotation a function of the step
count alone, and it is why a halting task does not freeze the executive — it
only fails to make progress itself. -/
theorem execStep_cur (codes : Vector (List Instr) N) (sys : SysSt N) :
    (execStep codes sys).cur.val = (sys.cur.val + 1) % N := by
  unfold execStep
  split <;> rfl

/-- ⭐ **THE SCHEDULE IN CLOSED FORM.** After `m` steps the turn belongs to
task `cur₀ + m mod N` — no reference to the register file, the images, or
whether anything executed. -/
theorem cur_runSys (codes : Vector (List Instr) N) (init : SysSt N) :
    ∀ m, (runSys codes init m).cur.val = (init.cur.val + m) % N
  | 0 => by
      show init.cur.val = _
      rw [Nat.add_zero, Nat.mod_eq_of_lt init.cur.isLt]
  | m + 1 => by
      show (execStep codes (runSys codes init m)).cur.val = _
      rw [execStep_cur, cur_runSys codes init m, Nat.mod_add_mod]
      congr 1

/-! ## 2. The arithmetic of a rotation: every task's turn comes again -/

/-- Every residue is hit strictly after any given time. This is the whole
content of "round-robin is fair" once the rotation is in closed form. -/
theorem exists_turn (N : Nat) (hN : 0 < N) (c i n : Nat) (hi : i < N) :
    ∃ m, n < m ∧ (c + m) % N = i := by
  refine ⟨n + 1 + ((i + N - (c + n + 1) % N) % N), by omega, ?_⟩
  set a := (c + n + 1) % N with ha_def
  set t := (i + N - a) % N with ht_def
  have ha : a < N := Nat.mod_lt _ hN
  have hrewrite : (c + (n + 1 + t)) % N = (a + t) % N := by
    rw [ha_def, Nat.mod_add_mod]
    congr 1
    omega
  rw [hrewrite]
  rcases Nat.lt_or_ge i a with hlt | hge
  · have h2 : i + N - a < N := by omega
    have ht : t = i + N - a := by rw [ht_def, Nat.mod_eq_of_lt h2]
    rw [ht]
    have h3 : a + (i + N - a) = i + N := by omega
    rw [h3, Nat.add_mod_right, Nat.mod_eq_of_lt hi]
  · have h2 : i + N - a = (i - a) + N := by omega
    have ht : t = i - a := by
      rw [ht_def, h2, Nat.add_mod_right, Nat.mod_eq_of_lt (by omega)]
    rw [ht]
    have h3 : a + (i - a) = i := by omega
    rw [h3, Nat.mod_eq_of_lt hi]

/-! ## 3. Fairness -/

/-- **The antecedent, named (B4).** The executive never stalls: at every step
the scheduled task has an instruction to run. X0's `exec_forever` supplies it;
X0's `halt_mutant_stalls` exhibits a configuration where it fails. -/
def NeverStalls (codes : Vector (List Instr) N) (sys : Nat → SysSt N) : Prop :=
  ∀ m, execAt codes (sys m)

/-- ⭐⭐⭐ **X2 — ROUND-ROBIN IS FAIR.** Under the non-halting antecedent, every
task executes an instruction infinitely often: for every task `i` and every time
`n` there is a strictly later step at which `i` is scheduled AND runs.

`stepsAt` is E-7's non-trivial reading — *scheduled and executes* — so this is
not the empty claim that every task is looked at. -/
theorem fair (codes : Vector (List Instr) N) (init : SysSt N)
    (hns : NeverStalls codes (runSys codes init)) (i : Fin N) (n : Nat) :
    ∃ m, n < m ∧ stepsAt codes (runSys codes init m) i := by
  obtain ⟨m, hgt, hhit⟩ :=
    exists_turn N init.pos init.cur.val i.val n i.isLt
  refine ⟨m, hgt, ?_, hns m⟩
  exact Fin.ext (by rw [cur_runSys codes init m, hhit])

/-- The form the ladder's later rungs quote: fairness for the canonical run of a
configuration that provably never stalls. -/
theorem fair_of_exec_forever (codes : Vector (List Instr) N) (init : SysSt N)
    (h : ∀ m, execAt codes (runSys codes init m)) (i : Fin N) (n : Nat) :
    ∃ m, n < m ∧ stepsAt codes (runSys codes init m) i :=
  fair codes init h i n

/-! ## 4. ⛔ THE CONTROL — the antecedent is load-bearing (B4)

X0's halting mutant is exactly the configuration B4 says fairness must exclude,
so the refutation is available without constructing anything new. -/

/-- ⛔ **THE ANTECEDENT FAILS ON THE HALTING CONFIGURATION**, so `fair` cannot be
applied to it — which is B4's finding, now a theorem rather than a caution. -/
theorem halt_mutant_not_neverStalls :
    ¬ NeverStalls codesHalt (runSys codesHalt init2) := by
  intro h
  exact halt_mutant_stalls (h 2)

/-- ✅ …and it HOLDS on the looping configuration, so `fair` is inhabited. -/
theorem loop_neverStalls : NeverStalls codes2 (runSys codes2 init2) := exec_forever

/-- ⭐ **FAIRNESS, DISCHARGED ON A CONCRETE CONFIGURATION.** Both tasks of the
two-task loop run infinitely often. -/
theorem fair_loop (i : Fin 2) (n : Nat) :
    ∃ m, n < m ∧ stepsAt codes2 (runSys codes2 init2 m) i :=
  fair codes2 init2 loop_neverStalls i n

end SaltWorks.HDL.Exec

#print axioms SaltWorks.HDL.Exec.cur_runSys
#print axioms SaltWorks.HDL.Exec.exists_turn
#print axioms SaltWorks.HDL.Exec.fair
#print axioms SaltWorks.HDL.Exec.halt_mutant_not_neverStalls
#print axioms SaltWorks.HDL.Exec.fair_loop

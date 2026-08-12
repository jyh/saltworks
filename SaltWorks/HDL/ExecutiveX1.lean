/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ExecutiveX0
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Fintype.Basic

/-!
# X1 — WRITE-ISOLATION AGAINST HAND-PARTITIONED PROGRAMS (block ② §5, per §A)

**B6, said before anything is claimed.** Isolation here is WRITE-confinement.
Task `j` may READ task `i`'s registers; read-isolation / confidentiality is NOT
claimed by this rung, and no theorem below should be quoted as if it were.

**B2 — both halves of the finding.** `writesInstr` returns `Option (Fin 32)`,
because B2's correction is literally *"each `Instr` writes AT MOST one
register"*: `none` for `BEQ` (pc only) and for every `rd = 0` form. And
`step_frame` BINDS the instruction to the image (`ins ∈ code`) — with `ins`
free, as first drafted, any instruction at all could be handed to `step` and the
confinement claim would say nothing.

**B3 — E-4 exactly as pre-registered.** `N = 2`, `P_A = {1,2}`, `P_B = {1,3}`
overlapping at register 1, `progA = [ADDI 1 0 5]`, `progB = [ADDI 1 0 9]`,
quantum 1: `e4_overlap_refutes` shows A's register 1 reading **9**. Paired with
the disjoint control, the positive control (`writesWithin` true on each image
against its own partition) and its complement (an image that writes outside is
rejected), so the side condition is not vacuously true.

**B7.** This lands against HAND-PARTITIONED programs. The theorem is about code,
not about who produced it, so the rung is not hostage to an allocator rung.

**x0, named once (§5).** Partitions need not exclude `x0` by fiat: a write to
`x0` is discarded by `St.set`'s own law, so `writesInstr` sends it to `none` and
`x0` never enters a write set. Reads of `x0` are free — `St.get` returns zero
unconditionally.

⚠️ **WHY THIS RUNG EXISTS AT ALL, and it is B1's repair:** the register file is
SHARED. Under `Vector St N` every theorem here would be free from
`Vector.getElem_set_ne` and E-4's mutant would be unconstructible. The mutant is
the proof that the repair worked.

⚠️ **IMPORT OWED — maestro's call, not mine:** this module is not in the hub
closure.
-/

namespace SaltWorks.HDL.Exec

open SaltWorks.HDL SaltWorks.ISA

/-! ## 1. What an instruction writes -/

/-- A register partition. -/
abbrev Partition := Finset (Fin 32)

/-- **The write set of one instruction (B2).** `Option` rather than a set,
because B2's finding is literally "each `Instr` writes AT MOST one register":
`none` for `BEQ` (pc only) and for every `rd = 0` form (the write is discarded
by `St.set`'s own law, which is also why `x0` never enters a partition). -/
def writesInstr : Instr → Option (Fin 32)
  | .ADD  rd _ _ => if rd = 0 then none else some rd
  | .ADDI rd _ _ => if rd = 0 then none else some rd
  | .XOR  rd _ _ => if rd = 0 then none else some rd
  | .SLT  rd _ _ => if rd = 0 then none else some rd
  | .BEQ  _ _ _  => none
  -- ⬥ M2. LW writes `rd` and so KEEPS the x0-discard guard the other writing
  -- arms use; SW writes no register at all, which is the whole shape of a store.
  | .LW   rd _ _ => if rd = 0 then none else some rd
  | .SW   _ _ _  => none

/-- **The compiler-checkable side condition**, decidable by construction. -/
def writesWithin (code : List Instr) (P : Partition) : Bool :=
  code.all fun ins => match writesInstr ins with
    | none    => true
    | some rd => decide (rd ∈ P)

theorem writesWithin_mem {code : List Instr} {P : Partition} (h : writesWithin code P)
    {ins : Instr} (hin : ins ∈ code) {rd : Fin 32} (hw : writesInstr ins = some rd) :
    rd ∈ P := by
  unfold writesWithin at h
  have := List.all_eq_true.mp h ins hin
  rw [hw] at this
  exact of_decide_eq_true this

/-! ## 2. The frame lemma at one instruction -/

/-- A write to a register other than `r` leaves `r`'s value alone. Covers `x0`
in both directions: writing it is discarded, reading it is constant. -/
theorem St.get_set_ne (s : St) (rd r : Fin 32) (v : BitVec 32) (h : r ≠ rd) :
    (s.set rd v).get r = s.get r := by
  by_cases hr : r = 0
  · simp [St.get, hr]
  · by_cases h0 : rd = 0
    · simp [St.get, St.set, h0]
    · have hne : ¬ (rd.val = r.val) := fun he => h (Fin.ext he).symm
      simp [St.get, St.set, hr, h0, Vector.getElem_set, hne]

/-- If `ins` does not write `r`, it cannot move `r`. -/
theorem step_frame_instr (s : St) (ins : Instr) (r : Fin 32)
    (hr : writesInstr ins ≠ some r) : (step s ins).get r = s.get r := by
  cases ins with
  | ADD rd a b =>
      by_cases h0 : rd = 0
      · simp [step, St.set, h0, St.next, St.get]
      · have : r ≠ rd := by
          intro he; exact hr (by simp [writesInstr, h0, he])
        simpa [step, St.next, St.get] using St.get_set_ne s rd r _ this
  | ADDI rd a imm =>
      by_cases h0 : rd = 0
      · simp [step, St.set, h0, St.next, St.get]
      · have : r ≠ rd := by
          intro he; exact hr (by simp [writesInstr, h0, he])
        simpa [step, St.next, St.get] using St.get_set_ne s rd r _ this
  | XOR rd a b =>
      by_cases h0 : rd = 0
      · simp [step, St.set, h0, St.next, St.get]
      · have : r ≠ rd := by
          intro he; exact hr (by simp [writesInstr, h0, he])
        simpa [step, St.next, St.get] using St.get_set_ne s rd r _ this
  | SLT rd a b =>
      by_cases h0 : rd = 0
      · simp [step, St.set, h0, St.next, St.get]
      · have : r ≠ rd := by
          intro he; exact hr (by simp [writesInstr, h0, he])
        simpa [step, St.next, St.get] using St.get_set_ne s rd r _ this
  | BEQ a b imm =>
      simp only [step]
      split <;> rfl
  -- ⬥ M2. The LW arm splits on `addrClass … = .ok`: only that branch writes a
  -- register, and the trap branch touches `trapped`/`pc` — neither of which
  -- `St.get` can see. The `ok` branch is then the same argument as ADD/ADDI.
  | LW rd a imm =>
      simp only [step]
      split_ifs
      · by_cases h0 : rd = 0
        · simp [St.set, h0, St.next, St.get]
        · have : r ≠ rd := by
            intro he; exact hr (by simp [writesInstr, h0, he])
          simpa [St.next, St.get] using St.get_set_ne s rd r _ this
      · rfl
  -- ⬥ M2. SW writes NO register on either branch, so both close by
  -- reflexivity — the store cannot move `r` whatever the address does.
  | SW a b imm =>
      simp only [step]
      split_ifs <;> rfl

/-- ⭐ **`step_frame` (B2's amended form).** The instruction is BOUND to the
image — `ins ∈ code` — which is exactly the clause whose absence made the
original draft false: with `ins` free, ANY instruction could be handed to `step`
and the confinement claim would say nothing. -/
theorem step_frame {code : List Instr} {P : Partition} (h : writesWithin code P)
    {ins : Instr} (hin : ins ∈ code) (s : St) {r : Fin 32} (hr : r ∉ P) :
    (step s ins).get r = s.get r := by
  refine step_frame_instr s ins r (fun hw => hr ?_)
  exact writesWithin_mem h hin hw

/-! ## 3. Lifted to a whole run -/

/-- A fetched instruction is an instruction of the image. -/
theorem fetch_mem {code : List Instr} {pc : BitVec 32} {ins : Instr}
    (h : fetch code pc = some ins) : ins ∈ code := by
  unfold fetch at h
  split at h
  · exact List.mem_of_getElem? h
  · exact absurd h (by simp)

/-- ⭐⭐ **THE FRAME SURVIVES BOUNDED EXECUTION.** -/
theorem runFor_frame {code : List Instr} {P : Partition} (h : writesWithin code P)
    {r : Fin 32} (hr : r ∉ P) : ∀ (n : Nat) (s : St), (runFor n code s).get r = s.get r
  | 0,     s => rfl
  | n + 1, s => by
      show (match fetch code s.pc with
            | none => s
            | some i => runFor n code (step s i)).get r = s.get r
      cases hf : fetch code s.pc with
      | none     => rfl
      | some ins =>
          simp only []
          rw [runFor_frame h hr n (step s ins), step_frame h (fetch_mem hf) s hr]

/-! ## 4. The interleaving — the shared register file (B1) -/

/-- The shared register file, read through `St.get`'s law. Defined on `regs`
directly: the file is SHARED, so this does not depend on whose turn it is. -/
def SysSt.getReg (sys : SysSt N) (r : Fin 32) : BitVec 32 :=
  if r = 0 then 0 else sys.regs[r.val]

theorem SysSt.getReg_task (sys : SysSt N) (i : Fin N) (r : Fin 32) :
    (sys.task i).get r = sys.getReg r := rfl

/-- ⭐⭐⭐ **X1 — ONE EXECUTIVE STEP CANNOT LEAVE THE RUNNING TASK'S PARTITION.**
Whatever the scheduled task does, every register outside the partition its own
image is confined to keeps its value. The register file is SHARED (B1), so this
is a real theorem and not a fact about the type. -/
theorem execStep_frame {N : Nat} (codes : Vector (List Instr) N)
    (P : Partition) (sys : SysSt N)
    (h : writesWithin codes[sys.cur.val] P)
    {r : Fin 32} (hr : r ∉ P) :
    (execStep codes sys).getReg r = sys.getReg r := by
  unfold execStep
  split
  · rfl
  · next ins hf =>
      have hst := step_frame h (fetch_mem hf) (sys.task sys.cur) hr
      simpa [SysSt.getReg, SysSt.rotate, SysSt.put, SysSt.task, St.get] using hst

/-! ## 5. Cross-task isolation, under disjointness -/

/-- ⭐⭐⭐ **THE ISOLATION THEOREM.** If the running task's image is confined to
`Pcur`, and another task's partition `Pother` is disjoint from it, then the step
cannot touch a single register of `Pother`. **Disjointness is the hypothesis
that does the work** — E-4 below deletes it and the conclusion fails. -/
theorem execStep_frame_disjoint {N : Nat} (codes : Vector (List Instr) N)
    (Pcur Pother : Partition) (hdisj : Disjoint Pcur Pother) (sys : SysSt N)
    (h : writesWithin codes[sys.cur.val] Pcur)
    {r : Fin 32} (hr : r ∈ Pother) :
    (execStep codes sys).getReg r = sys.getReg r :=
  execStep_frame codes Pcur sys h (Finset.disjoint_right.mp hdisj hr)

/-! ## 6. ⛔ E-4 — THE PRE-REGISTERED OVERLAP MUTANT (B3, exactly as specified)

`N = 2`, `P_A = {1,2}`, `P_B = {1,3}` — **overlapping at register 1** —
`progA = [ADDI 1 0 5]`, `progB = [ADDI 1 0 9]`, quantum 1. The mutant WRITES the
overlap, which is what makes it a refutation and not a near-miss. -/

def PA : Finset (Fin 32) := {1, 2}
def PB : Finset (Fin 32) := {1, 3}
def PBdisj : Finset (Fin 32) := {3, 4}

def progA : List Instr := [Instr.ADDI 1 0 5]
def progB : List Instr := [Instr.ADDI 1 0 9]
def progBdisj : List Instr := [Instr.ADDI 3 0 9]

def codesE4 : Vector (List Instr) 2 := Vector.ofFn (fun i : Fin 2 => if i = 0 then progA else progB)
def codesOK : Vector (List Instr) 2 := Vector.ofFn (fun i : Fin 2 => if i = 0 then progA else progBdisj)
def initE4 : SysSt 2 :=
  { regs := Vector.replicate 32 0, pcs := Vector.replicate 2 0, cur := 0 }

/-- ✅ **POSITIVE CONTROL (B3): the side condition HOLDS for each image against
its own partition** — so the mutant's failure is the overlap and not a violated
premise. -/
theorem e4_writesWithin_pos :
    writesWithin progA PA = true ∧ writesWithin progB PB = true ∧
      writesWithin progBdisj PBdisj = true := by
  refine ⟨by decide, by decide, by decide⟩

/-- ✅ **…AND ITS COMPLEMENT: the condition is not vacuously true.** An image
that writes outside the partition is rejected. -/
theorem e4_writesWithin_neg : writesWithin progB PBdisj = false := by decide

/-- ⛔⛔ **E-4, DISCHARGED — OVERLAPPING PARTITIONS REFUTE ISOLATION, WITH THE
WITNESS.** Both images are confined to their own partitions, both partitions are
"checked", and task B still destroys task A's register 1: `5` becomes `9`.

This is what makes `execStep_frame_disjoint` non-tautological — by-construction
disjointness would have made the mutant unconstructible, which is precisely the
FATAL that B1 repaired by sharing the register file. -/
theorem e4_overlap_refutes :
    (1 : Fin 32) ∈ PA ∧ (1 : Fin 32) ∈ PB ∧
      (runSys codesE4 initE4 1).getReg 1 = 5 ∧
      (runSys codesE4 initE4 2).getReg 1 = 9 := by
  refine ⟨by decide, by decide, by decide, by decide⟩

/-- ✅ **THE DISJOINT CONTROL, same driver, same steps.** Move task B's write out
of A's partition and A's register survives — so the mutant's `9` is the overlap
talking and not the executive being broken. -/
theorem e4_disjoint_control :
    Disjoint PA PBdisj ∧ (runSys codesOK initE4 2).getReg 1 = 5 := by
  refine ⟨by decide, by decide⟩

end SaltWorks.HDL.Exec

#print axioms SaltWorks.HDL.Exec.step_frame
#print axioms SaltWorks.HDL.Exec.runFor_frame
#print axioms SaltWorks.HDL.Exec.execStep_frame
#print axioms SaltWorks.HDL.Exec.execStep_frame_disjoint
#print axioms SaltWorks.HDL.Exec.e4_overlap_refutes
#print axioms SaltWorks.HDL.Exec.e4_disjoint_control
#print axioms SaltWorks.HDL.Exec.e4_writesWithin_pos
#print axioms SaltWorks.HDL.Exec.e4_writesWithin_neg

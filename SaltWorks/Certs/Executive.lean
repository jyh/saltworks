/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ExecutiveX1

/-!
# COMPREHENSIBILITY CERTIFICATE — the multitasking executive's isolation claims

Campaign: `docs/cert-layer-design-0811.md` (the fifth deliverable).
Landed by the **COMPILER seat**.

| certificate | proved from | in |
| --- | --- | --- |
| `cert_side_condition_meaning` | `writesWithin` / `writesWithin_mem` (an `iff`) | `HDL/ExecutiveX1.lean` |
| `cert_step_frame` | `SaltWorks.HDL.Exec.step_frame` | `HDL/ExecutiveX1.lean` |
| `cert_task_isolation` | `SaltWorks.HDL.Exec.execStep_frame_disjoint` | `HDL/ExecutiveX1.lean` |
| `cert_isolation_needs_disjointness` | `SaltWorks.HDL.Exec.e4_overlap_refutes` | `HDL/ExecutiveX1.lean` |

## ⭐ WHY THIS FILE EXISTS — the second half of a flag raised on the paper's pillars

The evidence seat flagged two of the four pillars named in the **Nature-track manuscript draft** (`${SEAT_DIR}/briefs/2026-08-11-nature-draft-v0.md`, read 2026-08-11; section numbers are DRAFT-RELATIVE and will move) as *"not mine to
measure — their owners should state what those words cover before the sentence
travels"*: **a verified COMPILER** and **a verified EXECUTIVE**. `Certs/Compiler.lean`
answered the first. **This file answers the second, in the same form: not a promise in
a docstring, but the scope written into the statements themselves.**

## WHAT "THE EXECUTIVE IS VERIFIED" IS ALLOWED TO MEAN

```
✅ HONEST  "Each task declares a set of registers. If every instruction in a task's
            program writes only into that task's set — a condition the compiler can
            CHECK, by running a decidable test on the code — then one step of that
            task leaves every register outside the set exactly as it was. If two
            tasks' sets are disjoint, one cannot disturb the other's registers."
⛔ FALSE    "tasks are isolated"
```
**The false reading is what the word "isolation" does on its own**, and the gap is
not small — see the scope limits below. *The register file is genuinely SHARED, which
is what makes the theorem a theorem rather than a fact about the type: nothing in the
data structure prevents task B from writing task A's register. Only the side condition
does.*

## ⚠️ SCOPE LIMITS, and they are the reason this file is worth reading

* **REGISTERS ONLY.** Every statement below is about `getReg`. **Nothing here says
  anything about MEMORY, about the trap flag, or about the program counter.** *`St`
  carries all three. Since `M2` the machine has real load/store instructions, so
  "isolation" in the memory sense is not merely unproved here — it is not addressed.*
* **ONE STEP, and this is the sharpest limit in the list.** `cert_task_isolation` is
  about a single `execStep`. *Lifting to a whole run is a separate landed theorem
  (`runFor_frame`), and it covers a **single task's** bounded execution.*
  ⛔ ***THE COROLLARY, CHECKED RATHER THAN ASSUMED (grep over `Executive*.lean`, all
  frame/isolation theorems enumerated): THE ONLY MULTI-QUANTUM, SYSTEM-LEVEL STATEMENT
  IN THIS CORPUS IS THE REFUTATION.*** `cert_isolation_needs_disjointness` runs the
  system for two steps and shows corruption; **no theorem runs the system for two steps
  and shows safety.** *So "the executive keeps tasks isolated over time" is not a
  weaker version of what is proved here — it is unaddressed, and the only evidence
  spanning quanta points the other way.*
* **THE PARTITIONS ARE GIVEN, NOT DERIVED.** Nothing here computes a task's register
  set or proves one exists — `P` is an input, and `writesWithin` is the check that a
  given program respects a given `P`.
* **NO LIVENESS.** Nothing about scheduling fairness or progress is claimed in this
  file. *(Fairness lives in `ExecutiveX2`, separately.)*
* **DISJOINTNESS IS LOAD-BEARING, AND THAT IS PROVED, NOT ASSERTED** —
  `cert_isolation_needs_disjointness` exhibits two tasks that each satisfy their own
  side condition and still corrupt each other, because their partitions overlap.

## DIRECTION (iron rule 3)

`cert_side_condition_meaning` is an **`iff`**: the machine-checkable `Bool` test and
the plain-English quantifier are proved equivalent, so the translation of the
vocabulary is *kernel-checked rather than asserted*. The remaining three are the
**same proposition** as their landed theorems, closing by `exact`, with the side
condition supplied in its plain form through that `iff`.

## AXIOMS (iron rule 4)

Measured at the landing of this file, from the `#print axioms` block below:

```
cert_side_condition_meaning        [propext, Quot.sound]
cert_step_frame                    [propext, Quot.sound]
cert_task_isolation                [propext, Classical.choice, Quot.sound]
cert_isolation_needs_disjointness  [propext, Quot.sound]
```

No `sorryAx`, no corpus-local axiom; three of the four are stronger than the
campaign's bar.
-/

namespace SaltWorks.Certs

open SaltWorks.HDL SaltWorks.ISA SaltWorks.HDL.Exec

/-! ## 1. THE SIDE CONDITION, IN PLAIN WORDS — and the translation is an `iff` -/

/-- ⭐ **WHAT THE COMPILER-CHECKABLE TEST ACTUALLY SAYS.** `writesWithin code P` is a
decidable `Bool`; this is the sentence it decides:

> *every instruction in the program, if it writes a register at all, writes one that
> belongs to `P`.*

Direction: **`iff`** — so the plain reading and the machine test are the same claim,
in the kernel, rather than in this docstring. *An instruction that writes nothing
(`BEQ`, `SW`, or any write to `x0`, which the hardware discards) is unconstrained,
which is why the inner quantifier is over `writesInstr ins = some rd` rather than over
all registers.* -/
theorem cert_side_condition_meaning (code : List Instr) (P : Partition) :
    writesWithin code P = true ↔
      ∀ ins ∈ code, ∀ rd : Fin 32, writesInstr ins = some rd → rd ∈ P := by
  constructor
  · intro h ins hin rd hw
    exact writesWithin_mem h hin hw
  · intro h
    unfold writesWithin
    refine List.all_eq_true.mpr ?_
    intro ins hin
    cases hw : writesInstr ins with
    | none => rfl
    | some rd => exact decide_eq_true (h ins hin rd hw)

/-! ## 2. THE FRAME — one instruction cannot move a register outside the set -/

/-- ⭐⭐ **A TASK'S INSTRUCTION CANNOT TOUCH A REGISTER OUTSIDE ITS OWN SET.** If every
instruction of `code` writes only into `P`, then running any instruction *of that
program* leaves every register outside `P` holding exactly what it held before.

*`ins ∈ code` is load-bearing and is not bookkeeping: with `ins` free, any instruction
at all could be handed to `step` and the confinement claim would say nothing.*

Direction: **same proposition** as `SaltWorks.HDL.Exec.step_frame`, with the side
condition given in the plain form of §1. -/
theorem cert_step_frame {code : List Instr} {P : Partition}
    (h : ∀ ins ∈ code, ∀ rd : Fin 32, writesInstr ins = some rd → rd ∈ P)
    {ins : Instr} (hin : ins ∈ code) (s : St) {r : Fin 32} (hr : r ∉ P) :
    (step s ins).get r = s.get r :=
  step_frame ((cert_side_condition_meaning code P).mpr h) hin s hr

/-! ## 3. THE ISOLATION CLAIM — and exactly what it covers -/

/-- ⭐⭐⭐ **ONE TASK CANNOT DISTURB ANOTHER TASK'S REGISTERS.** Let the running task's
program write only into `Pcur`, and let another task's set `Pother` be disjoint from
it. Then after one executive step, **every register of `Pother` still holds its old
value** — read through the SHARED register file, which is what makes this a theorem.

⚠️ **This is about REGISTERS. It says nothing about memory, the trap flag, or the
program counter** — see the scope limits in this file's header.

Direction: **same proposition** as `SaltWorks.HDL.Exec.execStep_frame_disjoint`, with
the side condition in plain form. -/
theorem cert_task_isolation {N : Nat} (codes : Vector (List Instr) N)
    (Pcur Pother : Partition) (hdisj : Disjoint Pcur Pother) (sys : SysSt N)
    (h : ∀ ins ∈ codes[sys.cur.val], ∀ rd : Fin 32, writesInstr ins = some rd → rd ∈ Pcur)
    {r : Fin 32} (hr : r ∈ Pother) :
    (execStep codes sys).getReg r = sys.getReg r :=
  execStep_frame_disjoint codes Pcur Pother hdisj sys
    ((cert_side_condition_meaning _ Pcur).mpr h) hr

/-! ## 4. THE HYPOTHESIS IS LOAD-BEARING — a kernel-executed counterexample -/

/-- ⛔⛔ **DELETE DISJOINTNESS AND ISOLATION IS FALSE — with the witness, not with a
warning.** Two tasks, each satisfying its own side condition, whose register sets
**overlap at register 1**. Task A writes `5` there; task B then writes `9` over it.

```
after 1 step   register 1 = 5     (task A's value)
after 2 steps  register 1 = 9     (task B destroyed it)
```

*So `cert_task_isolation` is not a tautology dressed as a theorem: remove the one
hypothesis and the conclusion fails on a program the kernel actually runs.* **A
verified component whose guarantee cannot fail is not telling you anything, and this
is the line that shows this one can.**

Direction: **same proposition** as `SaltWorks.HDL.Exec.e4_overlap_refutes`. -/
theorem cert_isolation_needs_disjointness :
    (1 : Fin 32) ∈ PA ∧ (1 : Fin 32) ∈ PB ∧
      (runSys codesE4 initE4 1).getReg 1 = 5 ∧
      (runSys codesE4 initE4 2).getReg 1 = 9 :=
  e4_overlap_refutes

#audit_axioms cert_side_condition_meaning
#audit_axioms cert_step_frame
#audit_axioms cert_task_isolation
#audit_axioms cert_isolation_needs_disjointness

#print axioms cert_side_condition_meaning
#print axioms cert_step_frame
#print axioms cert_task_isolation
#print axioms cert_isolation_needs_disjointness

end SaltWorks.Certs

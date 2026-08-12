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
measure … their owners should state what those words cover before the sentence
travels"*: **a verified COMPILER** and **a verified EXECUTIVE**. `Certs/Compiler.lean`
answered the first. **This file answers the second, in the same form: not a promise in
a docstring, but the scope written into the statements themselves.**

### ⚠️ PROVENANCE NOTE ON THE QUOTATION ABOVE (2026-08-12) — a repair, not a style edit

**The ellipsis is load-bearing.** *As first landed, this file joined two of the evidence
seat's phrases with an em-dash, which reads as ONE contiguous sentence. It is not: the
source separates them by ~20 words — "compiler's L0–L2 landed tonight and I have not read
their scope;". **Every word quoted is theirs and in order; the CONTIGUITY was mine.***

**SOURCE PIN: the EVIDENCE seat, 2026-08-11 03:45, on `FLEET.md`.** *Seat and stamp, and
the line number is deliberately absent: the bus is append-only and versioned NOWHERE, so a
line cite has nothing to resolve against and rots on every peer's next post. The phrase is
the anchor; a line number would be a hint that decays — math's `anchor_pin_check`
discipline, which binds harder off-paper than on it.*

*Found by running evidence's 10:08 C-amendment — **every quoted string attributed to a
source must resolve in that source, not only the one the certificate is about** — against
this already-sealed tier.*

⛔ ***AND THE FIRST VERSION OF THIS VERY NOTE WAS SPLICED INTO THE MIDDLE OF THE SENTENCE
IT ANNOTATES**, orphaning "`Certs/Compiler.lean` answered the first" to the far side of it.
Repaired 10:27. **A docstring cannot fail a build, so a prose splice is invisible forever
— which is the whole reason the note is worth its own heading instead of an inline aside.***

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
all registers.*

Witness: **EXEMPT** (rule 6, amended 8/12). *An `iff` universally quantified over `code`
and `P` — it carries no witness, so there is no witness to be degenerate. The degenerate
instance (`code = []`) makes both sides true and the biconditional still holds, which is
correctness of the translation, not evidence about it.* -/
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
condition given in the plain form of §1.

Witness: **EXEMPT** (rule 6, amended 8/12). *No witness — universally quantified. Worth
recording WHY the binder is not degenerately satisfiable even so: `hin : ins ∈ code`
forces `code` non-empty, so the vacuous reading (an empty program, about which `h` says
nothing) cannot arise. That guard is stated two paragraphs above as a correctness point;
under the amended rule it is also the non-degeneracy argument.* -/
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
the side condition in plain form.

Witness: ✅ **SATISFIABILITY — WITNESSED. CLOSED 2026-08-12 10:58**, by the `example` block
below, on an assignment proposed by the EVIDENCE seat and typechecked here. *The paragraph that
follows is kept verbatim because it is the argument that made the question worth asking, and the
answer is only meaningful beside it.* ⬥ **The original declaration read: SATISFIABILITY — NOT
WITNESSED, THE QUESTION IS STATED, NOT ANSWERED** (rule 6, amended 8/12). *This binder CONJOINS two hypotheses over shared
objects — `hdisj : Disjoint Pcur Pother` and `h`, the writes-within condition on
`codes[sys.cur.val]` — and **that conjunction is the exact shape that produced the one
vacuous certificate this tier has already caught** (the `ControlFlow` exit/back split,
where two step-level constraints on one `st` were contradictory in ℕ). Both are plainly
satisfiable ALONE. Nothing in this file exhibits a system satisfying BOTH at once:
`cert_isolation_needs_disjointness` below witnesses the OVERLAPPING case, which is the
refutation, not an inhabitant of this theorem's binder. **I believe the binder is
inhabited and I have not proved it, so I am recording the gap rather than asserting the
kind.** Closing it wants a concrete `codes`/`Pcur`/`Pother`/`sys` with the conclusion
evaluated — a satisfiability witness of the same form as `cert_one_whole_program_end_to_end`.
The theorem is sound either way; this is a claim about the DOCSTRING, not the proof.* -/
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

Direction: **same proposition** as `SaltWorks.HDL.Exec.e4_overlap_refutes`.

Witness: **NON-DEGENERACY** (rule 6, amended 8/12). *A concrete refuting system, and its
non-degeneracy is the two VALUES: task A writes `5` and task B writes `9` over it. **Had
both tasks written the same value the trace would be identical and the refutation would
prove nothing** — the counterexample would survive while its content evaporated. `5 ≠ 9`
is what makes the overlap observable, and it is the reason this witness cannot be
weakened into a degenerate one.* -/
theorem cert_isolation_needs_disjointness :
    (1 : Fin 32) ∈ PA ∧ (1 : Fin 32) ∈ PB ∧
      (runSys codesE4 initE4 1).getReg 1 = 5 ∧
      (runSys codesE4 initE4 2).getReg 1 = 9 :=
  e4_overlap_refutes


/-! ## 5. THE SATISFIABILITY WITNESS for `cert_task_isolation` (rule 6, amended 8/12)

⭐ **THE BINDER IS JOINTLY INHABITED, AND NON-DEGENERATELY.** *`cert_task_isolation` conjoins
`Disjoint Pcur Pother` with the writes-within condition over shared objects — the shape that
produced this tier's one vacuous certificate. Both hypotheses are obviously satisfiable ALONE;
nothing exhibited them TOGETHER, so the cert was landed declaring the question open.*

**PROVENANCE, because the two halves were done by different seats:** *the assignment below was
proposed by the **EVIDENCE seat** at 2026-08-12 10:57, who stated plainly that they had not
typechecked it. **This seat typechecked it.** The design judgement was the part the compiler seat
had declined; a peer supplying it is what made the evaluation mechanical.*

⛔ **WHY IT IS NOT THE DEGENERATE WITNESS:** *empty partitions and empty code satisfy this binder
and prove nothing. Here the current task's program is NON-EMPTY and its instruction genuinely
WRITES — `writesInstr (.ADDI 1 0 5) = some 1`, a real register and not `x0`, whose write `St.set`
would discard. The hypotheses below are each discharged by `decide`, not assumed.*

⭐ **AND THE STEP CHANGES A VALUE, WHICH IS A SECOND AND STRONGER CONDITION — evidence's
strengthening at 11:02, taken.** *The witness first landed with `.ADD 1 1 1`, which on a zeroed
register file computes `0 + 0 = 0`: **the write happened and nothing moved.** That inhabits the
binder and exercises nothing. With `.ADDI 1 0 5` the machine actually does something, kernel-measured:*
```
register 1   0  →  5     the current task's own partition — CHANGED
register 2   0  →  0     the other task's partition — the isolation claim, HELD
```
***A witness that writes without changing anything cannot distinguish "isolation holds" from "the
step did nothing", and those are the two readings a reader has to tell apart.*** *Same class as the
day's other findings: the witness was VALID and the claim about its strength was the weak part —
found by the seat that designed it, reading their own proposal harder for exactly that reason.* -/

def witPcur : Partition := {1}
def witPother : Partition := {2}

def witCodes : Vector (List Instr) 2 :=
  Vector.ofFn (fun i : Fin 2 => if i = 0 then [Instr.ADDI 1 0 5] else [])

def witSys : SysSt 2 :=
  { regs := Vector.replicate 32 0, pcs := Vector.replicate 2 0, cur := 0 }

/-- The binder's three hypotheses, each DISCHARGED rather than assumed. -/
example : Disjoint witPcur witPother := by decide
example : ∀ ins ∈ witCodes[witSys.cur.val], ∀ rd : Fin 32,
    writesInstr ins = some rd → rd ∈ witPcur := by decide
example : (2 : Fin 32) ∈ witPother := by decide

/-- ⭐ **THE WITNESS ITSELF** — `cert_task_isolation` instantiated at this assignment, so the
certificate is applied to a system that exists rather than to a binder nobody has inhabited. -/
example : (execStep witCodes witSys).getReg 2 = witSys.getReg 2 :=
  cert_task_isolation witCodes witPcur witPother (by decide) witSys (by decide) (by decide)


#audit_axioms cert_side_condition_meaning
#audit_axioms cert_step_frame
#audit_axioms cert_task_isolation
#audit_axioms cert_isolation_needs_disjointness

#print axioms cert_side_condition_meaning
#print axioms cert_step_frame
#print axioms cert_task_isolation
#print axioms cert_isolation_needs_disjointness

end SaltWorks.Certs

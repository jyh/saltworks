# THE FLAGSHIP'S STATEMENT, AS ADOPTED — R10, 2026-09-02

**This is the flagship's statement text in the docs.** It lands here by the R10 sitting's
execution list (helm minute, bare filename `2026-09-02-R10-SITTING-minute.md`, private
record, @ `bf813512`): *"compiler RELIT: … the R10 text as the flagship's statement in the
docs."* Silicon's half of the same list — the rung-0 date and R10-4's caption — is in
`docs/silicon-offboard-data-block-0817.md` §20 and §20.1, and silicon's own §20 says so:
*"The R10 statement text itself lands in the docs by compiler's hand."*

The sitting read `docs/R10-SITTING-TABLE-0902.md` at origin/master `64580a1a` and adopted
R10-1..R10-4 **as drafted**. That table is the DRAFT and remains silicon's; this file is the
adopted statement, written against the objects that exist in the tree after adoption.

⛔⛔ **THE FENCE, FIRST AND LAST, BECAUSE EVERY SENTENCE BELOW IS QUOTABLE AND THIS ONE IS
THE ONE THAT GETS DROPPED.** The object is `CorePlace.core`, **the Lean-composed circuit**.
It is **not** `core32.v`, the hand-written RTL that was fabricated, and **no theorem in this
tree relates the two**. THE DIE IS NOT PROVED TO SORT. THE MODEL IS.

---

## §1 — THE STATEMENT

### R10-1 · THE BOUND IS IN THE UNIT THE MACHINE HONORS

> The flagship's bound is a bound on **ISA steps realised** — `stepsIn stalls cyc ins n`, the
> number of non-stalled clocks among the first `n` — and never on clocks. Any clock guard
> that appears is DERIVED from the stall declaration and carries its derivation as a theorem
> beside it; no numeral survives whose meaning depends on the retired *cycle = step*
> identity.

**T8 ruled the unit at this sitting: steps realised.** In the tree, as of `bb4cf5d`:

| object | home | what it does |
|---|---|---|
| `stepsIn` | `HDL/StallShape.lean` §0 | the unit itself |
| `stepsIn_empty` | `HDL/StallShape.lean` §0.0a | an empty stall set gives back `n` |
| `guard_reduces` | `HDL/StallShape.lean` §0.0a | **R10-1's "derivation theorem beside it", by name** |
| `stepsIn_le` | `HDL/StallShape.lean` §0.0a | no free steps — a clock realises AT MOST one |
| `cycles_sort_scoped`, `core_sorts` | `HDL/CoreSorts.lean` | bound stated in `stepsIn` |
| `cycles_sort_scoped_clocks`, `core_sorts_clocks` | `HDL/CoreSorts.lean` | the clock forms, DERIVED |

⚠️ **WHAT THE UNIT CHANGE DOES NOT BUY.** At the stall set this core declares — `fun _ =>
false`, R10-2, single-cycle, every cycle retires — `guard_reduces` makes the steps guard
**IFF** the clock guard. So the restatement gains no strength and proves nothing new. What
it buys is that the clock reading is now a CONSEQUENCE of the stall declaration rather than
a claim standing beside it, and that an arbitrating core later changes only the `stalls`
ARGUMENT while the statement shape survives. `stepsIn_le` closes the other direction: the
restatement cannot buy its own bound.

⛔ **THE BOUNDARY THIS SEAT DID NOT CROSS.** The minute names `cycles_sort` and `sorts_of_C4`,
which live in `SaltWorks/Stack/Program.lean` — **math's slot, read-only to this seat per
`docs/SEATS.md`, no live grant** — and, before ownership even arises, `stepsIn` is defined in
`HDL/StallShape.lean`, **which imports `Program.lean`**: a steps-form statement is not
*expressible* there unless `stepsIn` moves into math's file too. The dependency picks the
venue and the venue is this seat's slot. What is restated above is this seat's SCOPED
descendants of those two theorems, which are the statements the flagship actually rests on.
Math's originals are untouched. Raised on the bus 13:16; recommendation on the record that
`stepsIn` should NOT move.

⛔ **THREE OF R10-1's OWN LEMMAS WERE NOT IN THE TREE WHEN IT WAS RATIFIED.**
`stepsIn_empty`, `guard_reduces` and `stepsIn_le` were proved 2026-08-26 into
`HDL/ScratchStallArm.lean`, which is GITIGNORED. They built, they audited clean, and `git`
had never seen a line of them — so the derivation theorem R10-1 names existed on exactly one
disk while the sitting ratified the clause depending on it. Landed at `bb4cf5d`. *Recorded
here rather than in a bank because the next reader of this statement is entitled to know
that its floor was laid four hours after its ceiling.*

### R10-2 · THE PREDICATE IS THE STALL-ARMED ONE, AND THE STALL DECLARATION IS NAMED

> The flagship's cycle predicate is `CycleRealisesStepOrStalls (cycOfCirc core nextW pad)
> seenWord stalls` (`HDL/StallShape.lean`): every clock either realises `stepT` on
> `(regs, pc)`, or is a DECLARED stall that holds `(regs, pc)`. The stall declaration is
> **`stalls := ¬ retire`** — Contract B of `docs/retire-two-contracts-0826.md`, **RATIFIED**,
> the Captain having signed §6.2 at this sitting with §5.3.1 read into the minute.

`stallArm_reduces` recovers today's predicate at the empty stall set by `Iff.rfl`;
`stallArm_strictly_extends` proves the arm is a real weakening and not a rename.

⭐ **THE ONE BIT, SETTLED: THE `retire`/`en` NET IS *OUT* OF THE LAYOUT.** `retire =
f(kind, storeBeat, req)`; `kind` and `storeBeat` are the adapter bits the ratified `Full`
layout already carries (`stWidthAdapter`), and `req` is in `Env`. ⇒ `stalls` is a **function
of the ratified state**, and no `retire`/`en` net enters the layout. The draft position was
OUT and the sitting settled it OUT.

📐 **AND IT WAS A MEASUREMENT, NOT A RULING — recorded because it was carried for a while as
an owed Captain word that had never existed.** This seat measured it off the tree on 09/02:
the ratified `Full` layout carries `stWidthAdapter` and stops, so there is no retire/`en`
net to remove. A debt that is really a measurement gets EXECUTED through the payer's hand if
nobody checks its liveness.

⛔ **WHAT THIS SEAT'S CORE DECLARES, AND WHY EVERY SCOPED RESULT SITS AT AN EMPTY STALL
SET.** `core` is single-cycle: every cycle retires, so `¬ retire` is empty *here*. **An
arbitrating core falsifies the INSTANCES while leaving every theorem under them true** —
they quantify over `stalls`. That parameterisation is load-bearing and was named as
load-bearing before the 08/26 refutation that proved it: the kernel owns what a stall MEANS,
the RTL owns which cycles ARE stalls.

### R10-3 · THE LW ROW'S DISPOSITION — BY SCOPE, ON THE PREDICATE

> The kernel-backed claim is made over exactly the clocks whose presented word cannot touch
> memory, and the exclusion is written INTO the predicate:
> ```
> CycleRealisesStepOrStallsOn (scope) (cyc) (wordAt) (stalls) : Prop :=
>   ∀ ins, if scope ins then (if stalls ins then ⟨holds (regs, pc)⟩
>                                            else ⟨realises stepT on (regs, pc)⟩)
>                       else True
> ```
> with `scope ins := memFreeB (wordAt ins)`, the decidable Bool of `MemFree`.

**RATIFIED IN THE BOOL FORM, AND ADOPTION IS THE MOVE.** As of `95310c0` the definition,
`memFreeB` and the pin all live in `HDL/StallShape.lean` §0.2 — the tracked home of the
flagship's shape — and not in `HDL/MemFreeScope.lean`, which held them out until the sitting
decided. Nothing was copied: **one definition, one home.**

* `memFreeB` + `memFreeB_iff` — the Bool and the Prop are one fact, both directions,
  kernel-checked. Without the pin they are two objects sharing a name.
* `scopedOn_reduces` (`Iff.rfl`) and `scopedOn_reduces_all_the_way` — at the everywhere-true
  scope the scoped definition is DEFEQ to the landed one, so the twenty-declaration cone
  survives. **The Bool spelling is what keeps that defeq**; the Prop spelling loses it, which
  is a kernel measurement (`HDL/ScopeShapeDifferential.lean`, `86f7efd`) and not a taste.
* `memFreeB_seenWord_insL_false` — the landed LW witness is OUTSIDE the scope, which is
  *how* the scope disposes of the LW row.
* `memFreeB_seenWord_insI_true`, `scope_discriminates` — the NON-VACUITY control: something
  is inside. ⛔ **A scope that excluded everything would make the sentence vacuously true
  while passing every check, and would read exactly like a good one.**

⛔ The two controls stay in `HDL/MemFreeScope.lean` and that is a **dependency fact, not a
preference**: they name `HDL.C4Refuted`, which sits downstream of `StallShape`, so moving
them would invert the edge. That module is now the scope's EVIDENCE, not its home, and §0.2
points at it by name.

⭐ **THE SCOPE DOES NOT EXCLUDE THE WORKLOAD, AND THAT IS A THEOREM.** The obvious way for
this trade to be bad is if the machine's own program contained a memory-touching word.
`batcherSort_touches_no_memory` is a `decide` over the whole 120-instruction program and
`batcherSortWords_memFree` carries it to the words. Had it come out the other way, the
scoped flagship would have been **true and useless**, and that would have been the more
important sentence.

⛔ **AND NOT BY SILENCE, AND NOT BY A STALL.** `core_refutes_every_stall_arm`
(`HDL/LwNotStallShaped.lean`, `32f6ecf`): for every stall set, next-word policy and pad, the
core's induced cycle map fails `CycleRealisesStepOrStalls`. **No R10 wording disposes the LW
row by calling a cycle a stall.** The scope is the disposition; the negative half is what
proves no cheaper one exists.

### R10-4 · THE CAPTION

**Adopted verbatim, and it is not restated here.** It lives at
`docs/silicon-offboard-data-block-0817.md` §20.1, silicon's half of the execution list, with
its measurement pointer (`docs/silicon-lwtrap-0902/`; the standalone gate price, not the
08/31 figure). *Pointed at rather than copied: two seats writing one paragraph in the same
window is how a caption acquires two versions, and the index is shared state.*

---

## §2 — THE RUNG, AND THE FIVE LIMITS THAT RIDE WITH IT

**RUNG 2.5 — PROVEN IN LEAN OVER THE COMPOSED MODEL, RESTRICTED; RTL CORRESPONDENCE OPEN.**

The five limits, from the sitting table's B.2 as adopted, **with limit (1) in its
post-adoption reading**:

1. ~~It inhabits R10-3 AS DRAFTED, not as ratified.~~ **AMENDED BY THE ADOPTION ITSELF,
   2026-09-02: R10-3 IS RATIFIED, and the instance stands.** *The draft reading warned that a
   restatement would kill the instance and leave `R9BPositiveReduction` — quantified over
   `scope` — as the survivor. The restatement did not come. That reduction is still the
   general result and this is still the instance.* ⛔ **RATIFIED IS NOT CLOSED**: ratification
   moved the modal status of these results and moved nothing about their object.
   *(`docs/R10-SITTING-TABLE-0902.md` B.2 still carries limit (1) in its pre-sitting wording;
   that table is silicon's and the amendment is routed to its owner, not taken here.)*
2. **The stall set is EMPTY** — the core's own declaration; an arbitrating core falsifies
   the instance.
3. **`C4Spec core` is STILL FALSE, unscoped.** The refutation runs through `insL`, the
   memory-touching word this scope excludes.
4. **`C4SpecD core` is REFUTED under EVERY scope** — a WIDTH argument, no witness in it, and
   R10-3's scope does nothing for the D form. *A reader must not carry "open, not false"
   from the non-D flagship to the D one.*
5. ⛔ **THE OBJECT IS THE LEAN-COMPOSED `CorePlace.core`**, composed in Lean and conformance-
   discharged in `HDL/CoreConformsClosed.lean` — NOT an imported netlist: there is no
   `Imported/Core*.lean` in this tree, while rung 3's occupant carries `-- source: dmem8_nl.v`
   at `SaltWorks/Silicon/Imported/Dmem8.lean:7`. *(The sitting table's B.2 renders this limit
   as "19 organs by `instGates`"; `instGates` is not a constant of the tracked core — it
   appears only in an untracked scratch file — so the limit is stated here against objects a
   reader can open. The limit itself is unchanged.)*

⭐ **THE RUNG WAS CONTESTED DOWN BY THIS SEAT, AND THAT IS PART OF THE RECORD.** The table's
07:4x cut placed the scoped flagship at RUNG 3; this seat contested its own promotion and
silicon withdrew it. Rung 3 means proven AT THE GATES and its occupants are imported
netlists; rung 2 is "proved in RTL, assumed in Lean" and this object is the mirror image. At
3 it would have borrowed `dmem8`'s die-level standing. **An application of a ruling has no
adversary** — silicon applied this seat's own sentence correctly and nobody in that loop was
positioned to ask whether the object was the same KIND as its new neighbours.

`CoreConforms core` is DISCHARGED (`ce36f0e`) — `core.ssa`, `core.wf`, `core.nIn` — so
`emitPipeline'_sem` applies and the netlist **this tree emits from this model** realises the
step at memory-free words. ⛔ **That emitted netlist is not `core32.v` either.** The rung
stays 2.5 at this seat's own word; "over the composed model" is understated, not wrong.

---

## §3 — WHAT R10 DOES NOT CLAIM

* **Nothing about memory realisation** (stage ③'s obligation at the F4 bridge).
* **No bound in clocks** — see R10-1; the clock forms exist only as derived corollaries.
* **Nothing about trap-class loads.** They lie outside `scope` (a trapping LW touches
  memory) and are stated as measured residue of the submitted part, at RUNG 1.
* **Nothing relating the model to the fabricated die.** The RTL correspondence is OPEN and
  is the whole content of the 2.5.

---

## §4 — R9b DATES WITH THIS CLOSE

The sitting table's B.3: *"R9b then dates with this close."* R10 closed 2026-09-02 and
disposed the LW row by scope, which was R9b's stated precondition — and R9b is **whole**: the
negative half landed 08/31 (`32f6ecf`), the positive half 09/02 (`3882c49`) with its
reduction (`1ae3dde`), and the end-to-end theorem above it (`ef91df4`, `core_sorts`).

⛔ **THIS SEAT IS NOT RE-DATING THE RUNG, and that is a pre-registered position, not a
convenience** (`docs/R9B-POSITIVE-PREREGISTRATION.md`, and `docs/R9B-PREREGISTRATION.md`
before it: *"I am NOT re-dating any rung. §14's table is the helm's."*). §14's live table is
in `docs/silicon-offboard-data-block-0817.md` and carries R9b's row. **The condition is met
and the date is 2026-09-02; the table's edit is routed to its owner.** Recorded here so that
the condition's satisfaction does not depend on anyone's memory of a bus line.

---

## §5 — RECEIPTS

| act | sha | Scrub |
|---|---|---|
| R10-3 adopted — the move into `StallShape` §0.2 | `95310c0` | run `33677616101` SUCCESS |
| T8 applied — the bound in `stepsIn`, clock forms derived | `bb4cf5d` | run `33678095604` SUCCESS |

Tree at both: `saltbuild` EXIT=0, 8771 jobs, 0 `sorryAx` tree-wide, 0 errors; audit ticks
4738 then 4743, each delta equal to exactly the declarations added. `landcheck` CLEAR across
each build→commit window. `check_private_paths --tree` 0 NEW residue.

Prior receipts this statement rests on: `86f7efd` (the Bool/Prop kernel differential) ·
`50cbae2` (`memFreeB`, the pin, the controls) · `1ae3dde` (the reduction, quantified over
`scope`) · `3882c49` (the positive half, inhabited) · `ce36f0e` (`CoreConforms core`
discharged) · `ef91df4` (`core_sorts` — `sorts_of_C4` fires) · `32f6ecf` (the negative half).

# WHICH-CYCLE BINDING — design block, compiler's half of the temporal commission

**compiler · 2026-08-17 · AUTHORED, NOT STARTED. Ready for the refuter; the wave does
not run on this block until it is gated.**

Commissioned by the helm 11:42 under the Captain's ruling: *"we aim to finish the proof
before Sept 7… first priority above everything else."* Silicon holds the stall/arbitration
contract and the bus-protocol FSM; **this block covers only the statement-side binding**,
and it deliberately does not choose.

---

## 0 · THE PROBLEM, STATED AS AN EXISTING OBJECT RATHER THAN A WORRY

The kernel's n-step object is `Stack/Program.lean`:

```lean
def runWords (ws : Nat → Word) : Nat → St → St
  | 0,     s => s
  | n + 1, s => stepT (runWords ws n s) (ws n)
```

Its own section note already states the assumption, in the file, today:

> `runWords`: **every cycle steps.** `stepT` is TOTAL. There is no halting word.

⇒ **cycle index `k` and step index `k` are THE SAME NUMBER, by construction.** That
identity is not an accident of notation — it is what makes every seam theorem's `ins`
unambiguous without carrying a cycle argument.

**A stall breaks that identity.** Silicon's §3 is the same finding from the RTL side:
*"the cycle the strobe rises and the instruction that decoded it stop being the same
clock."*

## 0b · ⛔ ROUND 1 SAID "AND NOTHING ELSE". THAT WAS FALSE AT THE BYTES.

*Struck. A stall breaks a SECOND object, and it is the one that matters more:*

```
CycleRealisesStepProj              Program.lean:1484   ∀ ins, …  — NO CYCLE INDEX
  hypothesis of cycles_sort        :2132
  hypothesis of sorts_of_C4        :2352   ⭐ the end-to-end flagship
refuted under a stall, ALREADY KERNEL-LANDED:
  not_cycleRealisesStep_stalledBits :2404  ¬ CycleRealisesStepProj (cycOfBits
                                            stalledBits …), by decide +kernel
  stalledBits                       :2386  "a core whose outputs re-present the
                                            state it was given: THE STALL"
```
🔑 ***SO UNDER A STALLING `cyc` THE FLAGSHIP IS NOT MISINDEXED — ITS HYPOTHESIS IS
REFUTED AND THE THEOREM IS VACUOUS.*** **Options (A)–(D) below are all INDEX machinery,
and none of them repairs an unindexed `∀`-hypothesis.** That is the fatal defect in round
1 and it is structural, not a wording slip: I proposed to fix a numbering problem for an
object that has no numbers in it.

⚠️ **It sits 1,700 lines above the precedent I quoted, in the file I was reading.** I
found `runWords` by grepping for what I expected to find and stopped when I found it.

### NEITHER AGREEMENT MECHANISM TRANSFERS (also round 1's error)
- `runWords_eq_runFor` (:1942) demands, ∀ k<n, that the stream at cycle k be `encode` of
  the instruction fetched at `runFor k`. **A stall cycle violates that by definition.**
- `runWords_get_of_undecodable` (:1958) recovers agreement only where `decode (ws k) =
  none`. **A held instruction word is DECODABLE** — and the corpus's own landed control
  `noisy_tail_overwrites` (:2078) proves re-presenting a decodable word CORRUPTS the
  answer. The one re-agreement mechanism is exactly the one a hold-the-word stall kills.
- **Shape mismatch**: the precedent is agree-on-prefix-then-diverge-FOREVER, one split. A
  stall trace is INTERLEAVED and RESUMES. Gluing stall-free segments needs a per-segment
  CUMULATIVE shift, while `runWords_add` (:1419) shifts by a CONSTANT. ⇒ **(D) CONTAINS
  (C)**, and round 1 priced them as alternatives.
- **A stall has nowhere to live**: `stWidth = 32*32+32` (StateCodec.lean:60) is regs+pc
  ONLY. A bus-phase or in-flight-transaction bit cannot persist across a cycle without
  widening the codec or making `cyc` a composite of clocks — σ again.

⛔ **AND THE FAILURE IS SILENCE, NOT FALSITY** — measured on my own certificate this
morning, twice, from two different causes. `DriveMap w ins` requires `ins 33` and
`(ctrlSpec w)[6]!` to agree; if `ins` is cycle *t* and `w` is held from cycle *t−k*, they
agree only by accident, the hypothesis is unsatisfied, and the theorem stays green while
covering nothing. **A cycle-binding defect will not fail a build.**

## 1 · THE PRECEDENT: THIS FLEET HAS ALREADY SOLVED THIS SHAPE ONCE

`runFor` and `runWords` are two notions of "n steps" that **diverge** — `runFor` halts at
a fixed point, `runWords` steps forever. The resolution in `Program.lean` was NOT to force
one index. It was:

```
runWords_eq_runFor              the agreement, CONDITIONAL, holding exactly as long
                                as the pc keeps naming a program word
runFor_halts_where_runWords_runs_on   the divergence, KERNEL-CHECKED at the boundary
```

⇒ ***Two objects, an explicit conditional agreement, and an explicit witnessed
divergence.***

⛔ **ROUND 2 STRIKES THE CONCLUSION ROUND 1 DREW FROM THIS.** I called it "the strongest
thing about" option (D). **It does not transfer** — §0b gives the three reasons at the
bytes, and the decisive one is that this precedent is *agree-then-diverge-forever* while a
stall trace **resumes**. The precedent is real and it is the wrong precedent. **The true
one is `NeverStalls` (E), which the fleet used for stalls specifically**, and I reached for
the object I had just read instead of the object that matched the problem.

## 2 · THE OPTIONS, EACH PRICED BY THE LIE IT MAKES AVAILABLE

*(pricing convention borrowed from silicon's discharge block, which the helm called the
model — an architecture is chosen by the mistake it lets you make, not by its elegance)*

### (A) NO CHANGE — require the plane to guarantee same-cycle pairing
The statement layer is untouched; silicon's stall logic must hold `w` and `ins` on the
same clock at the seam.
- **cost** zero in my lane, real in silicon's, and it may be unaffordable — a fixed-latency
  offboard link is *made of* cycles where the core waits.
- ⛔ **the lie**: the obligation becomes invisible. It lives in RTL, is discharged by
  nobody in Lean, and every seam theorem reads exactly as it does today. **A reader cannot
  tell a guaranteed pairing from an assumed one**, which is this morning's defect with a
  new cause.

### (B) INDEX THE HYPOTHESIS — `DriveMap w ins k`
Carry a cycle number into the structure and into every seam theorem.
- **cost** touches every existing seam statement; the index must then be *related* to
  something, which is option (C) or (D) arriving anyway.
- ⛔ **the lie**: an index that is never constrained looks like a binding. `DriveMap w ins k`
  with `k` unused is the same proposition as today's, wearing a temporal costume.

### (C) RETIMING FUNCTION — `σ : Cycle → Step`, with a stall predicate
Introduce an explicit map from cycles to steps, plus `stalled : Cycle → Prop`, and state
seam theorems over cycles while the kernel runs over steps.
- **cost** the honest one. It is new machinery and it must be *derived from the contract*,
  not posited — otherwise σ is a wish.
- ⛔ **the lie**: σ is chosen to make the theorems work. **A retiming defined by the prover
  rather than measured from the RTL is unfalsifiable** — cf. the gate that proves
  consistency and not chronology.

### (D) TWO OBJECTS + CONDITIONAL AGREEMENT — the `runFor`/`runWords` precedent
Keep `runWords` untouched as the no-stall object. Add a stalled object. Prove (i) they
agree on stall-free segments, conditionally and explicitly; (ii) they **diverge**, with a
kernel-checked witness at the boundary, exactly as `runFor_halts_where_runWords_runs_on`
does today.
- **cost** RE-PRICED IN ROUND 2: **(C) plus two objects**, plus a re-priced `K ≤ N`
  guard, plus possibly a codec widening. Round 1 priced (C) and (D) as alternatives; the
  cumulative-stall shift makes (D) contain (C). Round 1 leaned on the precedent for this
  price and named zero consumers.
- ⛔ **the lie**: the conditional agreement gets cited without its condition. This is the
  fleet's most-measured failure mode and it has an antidote already built — the condition
  is a hypothesis, so a citation that drops it does not typecheck.
- ⭐ its lie is one the kernel refuses (a dropped condition will not typecheck).
- ⛔ **ROUND 3 WITHDRAWS "(E) does not carry (C) inside it".** *Refuted: a bounded-stall
  predicate must relate cycles to steps to state its bound at all, which is σ. **(E) carries
  (C) too**, and my §2 comparison rested on that line.

### (E) TRACE PREDICATE AS A WHOLE-RUN HYPOTHESIS — **the shape the fleet actually used for stalls**
Not invented here. `NeverStalls` (`HDL/ExecutiveX2.lean:106`) is a per-step trace predicate
carried as a hypothesis of the whole-run theorem, consumed by `fair` (:115-121),
**satisfiable** (`loop_neverStalls`:143) and **discriminating** (`halt_mutant_not_neverStalls`:137).
- **cost** the honest one, and it does not pretend to be free: the predicate must be
  discharged per run, and runs that stall are outside every theorem that assumes it.
- ✅ **it repairs the unindexed `∀`** — a hypothesis, not an index, which is the only
  thing that can constrain `CycleRealisesStepProj`.
- ⛔ **ROUND 3 WITHDRAWS "C2 IS MET".** *It rested on the REFUTING half alone. The pair
  discipline transfers; **the PRECEDENT does not.*** `NeverStalls`' stall is a
  **software-scheduler** stall in another lane, and its satisfying witness
  (`loop_neverStalls`) holds because a loop never runs out of instructions — a reason with
  no analogue here. **The SATISFYING half for a stalling core DOES NOT EXIST**, and
  `cycleRealisesStepProj_cycOf` (:1893) is the surface where it would have to be built.
- ⛔ **AND `NeverStalls` AS LITERALLY WRITTEN IS VACUOUS ON THIS MACHINE**: it is
  `∀ m, execAt …` — "at every step, execute" — while `FETCH YIELDS TO DATA` manufactures
  steps where fetch does not. **A no-stalls hypothesis on a machine whose stalls are
  designed in is an empty antecedent.** What survives is the SHAPE with a **BOUNDED-STALL**
  predicate (silicon's T4 bound), which the machine satisfies by construction.
- ⛔ **the lie**: a whole-run hypothesis that is never shown SATISFIABLE is a vacuity
  generator — precisely today's defect. The antidote is the pair the precedent already
  carries: a satisfiable witness AND a refuting mutant, both landed.

## 5 · WHAT EACH OPTION ACTUALLY TOUCHES — round 3, re-aimed

⛔ **ROUND 2's LEDGER PRICED A CHANGE NO OPTION PROPOSES.** *It enumerated the consumers of
a `runWords` mutation. **Not one of (A)–(E) mutates `runWords`**: (A) changes nothing,
(B) indexes `DriveMap`, (C) puts σ outside the fold, (D) keeps `runWords` untouched by
construction, (E) adds a hypothesis. I priced a change I had not proposed, and then — at
13:47, unprompted — conceded that ledger was *incomplete*, **grading the wrong artifact
against the wrong question.***

✅ **AND TWO OF ITS BREAKAGE MODES WERE OVERSTATED, verified at the source:**
- `runWords_succ` (:1413) is `rfl` **by the shape of the recursion**; it survives any
  word-stream encoding. It does not "die".
- `runWords_add` (:1419) proves by `induction n` + `rw [runWords_succ, ih]` — **it never
  inspects a word.** It stays UNCONDITIONAL.
⇒ ***MY "(D) CONTAINS (C)" RESTED ON A CONSTANT-vs-CUMULATIVE SHIFT ARGUMENT THAT THESE TWO
FACTS DISSOLVE. I do not currently have a replacement reason, and I am not inventing one to
keep the conclusion.***

### 5.1 · THE POPULATION THAT ACTUALLY MATTERS — the `CycleRealisesStepProj` cone

*Round 2 named 4 of these. There are **20**, enumerated mechanically, every one verified
present:*

```
CycleRealisesStepProj · cycleRealisesStepProj_cycOf · cycleRealisesStepProj_of_bits
cycleRealisesStep_of_C4 · cycleRealisesStep_of_C4Spec · cycleRealisesStep_of_fieldwise
cycleRealisesStep_idealBits · c4Spec_of_fieldwise · cycles_realise_steps_of_memFree
cycles_sort · sorts_of_C4 · decQ_cyc_eq_of_memFree · decQ_trapped · DeliversProgram
exists_halting_count · immBCirc_ne_immBshiftedCirc · seenWord_cycOfCirc · seenWord_envWith
not_cycleRealisesStep_id · not_cycleRealisesStep_stalledBits · not_cycleRealisesStep_wordOf
```
📌 **Two of these are the ones round 2 most needed and never named:**
`cycleRealisesStepProj_cycOf` (:1893) is **the SATISFIABILITY witness — the vacuity control
surface**, and the `not_cycleRealisesStep_*` trio are the **landed refuting controls**.

### 5.2 · ⛔ ONE ROW WAS WRONG IN THE DANGEROUS DIRECTION, AND IT WAS MINE

*Round 2's `cycles_realise_steps_of_memFree` (:1683) row said **"the mem-free premise is
what a stall violates."* **False, and false in the direction that invites a green build.**
`MemFree` is a property of the **WORD**. Under the ruled FETCH=4 a pure-ADDI stream is
`MemFree` at **every cycle while stalling 3-in-4.***

⇒ ***MY ROW INVITED "KEEP THE STREAM MEMORY-FREE AND THIS THEOREM SURVIVES" — GREEN AND
WRONG, IN A LEDGER WHOSE ENTIRE PURPOSE WAS TO CATCH EXACTLY THAT.*** *What a stall refutes
there is the `CycleRealisesStepProj` premise, already kernel-refuted at :2404.*

## 6 · THE BOUNDARY WITH SILICON — THE JOINT TABLE, AUTHORED BY SILICON, ADOPTED HERE

*Ordered 12:02. **Silicon authored the canonical artifact concurrently and theirs is the
interface** — their T4 reframe (fairness ⇒ BOUNDED WAIT, a safety property provable by the
same accounting that gave worst-case CPI) is better than the version I was drafting, and I
adopted it whole rather than merging two tables. **The bytes below are theirs, verbatim.**
`docs/ledger-tools/table_identical.sh` cmp's this region against their canonical file and
REFUSES on divergence — byte-identity is a reading here, not a promise.*

<!-- TEMPORAL-OWNERSHIP-TABLE v1 · BEGIN -->
# TEMPORAL OBLIGATION OWNERSHIP — ONE ARTIFACT, ONE PEN, cmp-VERIFIED

**Ordered by the helm 2026-08-17 12:02; custody arbitrated 12:06 after a collision.
Compiler holds the pen on this file; silicon's block embeds its bytes verbatim.**

> ⚠️ **CUSTODY, AND WHY IT IS WRITTEN AT THE TOP.** At 12:04 this file was created by
> compiler and destroyed within the minute: silicon wrote the same name in **lowercase**,
> macOS is case-insensitive/case-preserving, both names resolve to ONE INODE, and the
> second write replaced the first. The surviving name still carries compiler's uppercase
> `TABLE` — the proof of whose file it was. **It was untracked, so git held nothing.**
> ⇒ **ONE PEN (compiler) · COMMITTED ON CREATION · never a lowercase twin.**
> *Reproduced on this filesystem before being written down, not taken on report.*

---

## THE TABLE

| # | obligation | OWNER | CROSS-VERIFIER | ARTIFACT IT LANDS IN | CONTROL THAT WOULD CATCH ITS ABSENCE |
|---|---|---|---|---|---|
| T1 | stall / arbitration **contract** — which cycles are NOT-cycles | **silicon** | compiler | silicon's offboard block | a NOT-cycle the contract does not name, and no gate refuses the trace |
| T2 | which-cycle **statement shape** + the trace predicate | **compiler** | silicon | compiler's block → `Certs/` | a stalling trace under which the hypothesis is **still satisfiable** ⇒ vacuous, green, silent |
| T3 | bus-protocol **FSM proof** | **silicon** | compiler | silicon's offboard block | a trace where the FSM deadlocks mid-transaction and every current check stays green |
| T4 | arbitration **fairness**, restated as **BOUNDED WAIT** | **silicon** | compiler | silicon's offboard block | a fetch waiting longer than the stated phase bound, with no gate that counts |
| T5 | **store-path timing** — `dmem_we` rising vs the beat leaving the pins | **silicon** | compiler | silicon's block + the seam statement | `we` on beat *n*, data on beat *n+k*, and the seam theorem still elaborates |
| T6 | **`ISA.step` / `runWords` extension** | **compiler** | silicon | `Stack/Program.lean` | the extended object and `runWords` agreeing on **every** trace — no distinguishing witness means the extension is cosmetic and no stall entered |
| T7 | the **13 consumers'** re-proof | **compiler** | silicon | `Stack/Program.lean` | any consumer whose statement changed while its proof did not |
| T8 | the **K/N unit re-cut** (UK1) | ⛔ **the Captain, via the helm** | both | routed, not designed here | a guard passing at a fraction of the intended instructions — green and wrong |

## WHY THE THREE ORPHANS LAND ON SILICON — silicon's principle, adopted

**Each is a property of an artifact silicon writes. Ownership follows the ARTIFACT, not
the difficulty.** T3's FSM is RTL; T4's "fetch yields to data" is silicon's own arbitration
rule; T5's ordering is RTL sequencing. *An owner who does not hold the object cannot fix a
failed proof.*

## ⭐ T4 CHANGES SHAPE ON INSPECTION — silicon's finding, and it is the best thing here

*"Fairness" invites a **liveness** proof — "fetch is not starved forever" — and this fleet
has no liveness machinery in silicon.* **But under `FETCH YIELDS TO DATA` a data
transaction is BOUNDED: at most 8 phases.** ⇒ ***Fairness reduces to BOUNDED WAIT, a
SAFETY property provable by the same accounting that produced worst-case CPI. An
obligation nobody could discharge became an arithmetic one.***

⚠️ *And the structural reason starvation cannot arise: a data transaction exists only
because an instruction was already fetched. **There is no source of data traffic
independent of fetch.***

## ⛔ T6's CONTROL WAS A FALSE NEGATIVE, AND THIS TABLE FROZE IT INTO THREE FILES

*Repaired 2026-08-17 14:0x. The original read: "`runWords_succ` still closing by `rfl`
afterwards — if it does, no stall entered."* **`runWords_succ` is `rfl` BY THE SHAPE OF THE
RECURSION** *(`Program.lean:1413-1414`)*; *it survives any word-stream encoding, so it
would have reported "no stall entered" **while a stall had entered**.*

🔑 ***AND THE TELL IS STRUCTURAL, VISIBLE BY READING THE COLUMN DOWN: every other control
names a FAILURE STATE — something green-and-wrong that can occur while the obligation is
undischarged. T6 alone named a PASS CONDITION.*** *A control that describes success cannot
discriminate; it can only agree with you.*

⚠️ **THE INTERFACE ARTIFACT'S FIRST REAL LESSON, AND IT CUTS BOTH WAYS.** *Byte-identity
did exactly what it was built to do and **propagated a defective row to three files at
once**. A shared interface makes agreement cheap and makes a defect in the interface
maximally expensive. **The cmp check proves the copies match; it cannot prove the original
is right** — and nothing in the mechanism ever will.

## THE COLUMN THAT DOES THE WORK IS THE LAST ONE

*Owner and cross-verifier are assignments; **the control is what makes an assignment
checkable.** A row whose control says "review it carefully" is an unowned row with a name
attached.* ⇒ **Every control above names a state in which an artifact would be GREEN while
the obligation went undischarged** — because that is this seam's measured failure mode,
three times today, and not a hypothetical.

## WHAT CROSS-VERIFIER MEANS — a role, not a courtesy

```
the OWNER     writes the artifact, states the obligation, lands the proof
the VERIFIER  must be able to say NO: re-derive from their OWN instruments and
              REFUSE if it does not reproduce
```
⛔ **A cross-verifier who only reads is decoration.** *Each verifier owes at least one
demonstration that their check CAN reject.*

## STANDING CONDITIONS

- **No option is chosen and no wave runs** until this table is in both blocks and both
  revised blocks pass their refuter rounds. *(helm, 12:02)*
- **T8 is routed, not absorbed.** Neither seat designs the K/N re-cut without his word.
- **An obligation discovered later gets an owner BEFORE it gets work.** The orphans existed
  because the boundary was described before it was divided.
- **This file is committed on every edit.** An untracked artifact in a shared tree has no
  custody and no recovery — which is not a lesson from a manual, it is what happened here.
<!-- TEMPORAL-OWNERSHIP-TABLE v1 · END -->

## 3 · PRE-REGISTERED CRITERIA — six, published before any option is chosen

| | criterion |
|---|---|
| **C1** | the chosen shape must make **today's** seam theorems either still-true or **visibly broken** — never silently weaker |
| **C2** | a **negative control**: the same statement over a stalling trace MUST FAIL. `opcode_only_wiring_violates_DriveMap` is the landed model for this — a falsification that is machine-checked, not argued |
| **C3** | the stall predicate must be **derived from silicon's contract**, and the derivation cited by anchor. A predicate I invent is a wish |
| **C4** | **no theorem may be weakened to make it elaborate.** If a statement strains the elaborator, the statement is wrong or the datum is — recorded because straining `maxRecDepth` *pressures* rather than costs |
| **C5** | the agreement theorem must carry its condition **as a hypothesis**, never as prose |
| **C6** | at every rung, `#audit_axioms` clean and the public claim says exactly what IS proven |

## 4 · WHAT I AM NOT DOING, AND WHY

⛔ **I have not chosen.** Options (A) and (C) are only choosable against a stall contract
that does not exist yet, and restating a hypothesis to fit a contract still being designed
is how a statement gets shaped to fit a wish.

⛔ **I have not started.** The commission is design-block-first and the refuter gates the
wave. This block is its target.

⛔ **ROUND 3 — §4 WAS STALE AGAINST §6 IN MY OWN FILE.** *It left option (A) alive after my
own 12:40 measurement had killed it: silicon's `FETCH YIELDS TO DATA` manufactures
not-cycles by design, so a same-cycle guarantee is unavailable. **(A) is ELIMINATED**, and
the questions below are ANSWERED — `dmem_addr8` stays combinational (their §4), so door 1's
premise is untouched and the stall reaches it through the PAIRING only.*

📌 **The questions as originally posed, now answered and kept for the record**: whether there are
cycles where the core presents an input and memory does not advance, and whether
`dmem_addr8` keeps zero state under the address-map split. **(B), (C) and (D) all price
differently depending on the answers, and (A) survives only if the first answer is "no".**

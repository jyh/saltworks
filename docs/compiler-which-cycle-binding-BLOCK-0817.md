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
  stalledBits                       :2389  "a core whose outputs re-present the
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
- ⭐ its lie is one the kernel refuses (a dropped condition will not typecheck) — **but so
  is (E)'s, and (E) does not carry (C) inside it.**

### (E) TRACE PREDICATE AS A WHOLE-RUN HYPOTHESIS — **the shape the fleet actually used for stalls**
Not invented here. `NeverStalls` (`HDL/ExecutiveX2.lean:106`) is a per-step trace predicate
carried as a hypothesis of the whole-run theorem, consumed by `fair` (:115-121),
**satisfiable** (`loop_neverStalls`:143) and **discriminating** (`halt_mutant_not_neverStalls`:137).
- **cost** the honest one, and it does not pretend to be free: the predicate must be
  discharged per run, and runs that stall are outside every theorem that assumes it.
- ✅ **it repairs the unindexed `∀`** — a hypothesis, not an index, which is the only
  thing that can constrain `CycleRealisesStepProj`.
- ✅ **its discriminating control for THIS SEAM IS ALREADY LANDED** at Program.lean:2404.
  C2 is met before the option is chosen.
- ⛔ **the lie**: a whole-run hypothesis that is never shown SATISFIABLE is a vacuity
  generator — precisely today's defect. The antidote is the pair the precedent already
  carries: a satisfiable witness AND a refuting mutant, both landed.

## 5 · CONSUMER LEDGER — the 13 sites a change to `runWords` touches

*(iron rule 1. `grep -F runWords` over the tree returns `Stack/Program.lean` ONLY; every
row below verified present before listing.)*

| site | breakage mode under a stall-aware step object |
|---|---|
| `runWords_succ` :1413 | **`rfl` DIES** — the definitional equation is the change |
| `runWords_add` :1419 | becomes **CONDITIONAL**; constant shift no longer sound |
| `cycles_realise_steps_of_memFree` :1683 | mem-free premise is what a stall violates |
| `runWords_eq_runFor` :1942 | ∀k stream=encode(fetch) — violated by definition |
| `runWords_get_of_undecodable` :1958 | recovers only on undecodable; a held word decodes |
| `FeedsProgram` :1978 | def; first conjunct binds cycle k to `runFor k` |
| `runWords_get_eq_runFor` :1986 | rewrites with `runWords_add` at :1990 |
| `runFor_halts_where_runWords_runs_on` :2003 | divergence witness assumes forever-split |
| `feedsProgram_addi` :2056 · `feedsProgram_addi_runs` :2069 | instances of the above |
| `noisy_tail_overwrites` :2078 | **the landed proof that a re-presented decodable word corrupts** |
| `cycles_sort` :2132 | consumes `CycleRealisesStepProj` |
| `sorts_of_C4` :2352 | ⭐ end-to-end; **vacuous under a stalling cyc** |

⇒ **No stalled-cycle notion enters `runWords` without moving `runWords_succ` off `rfl` and
making `runWords_add` conditional. Visibly, not silently — but not free.**

## 6 · THE BOUNDARY WITH SILICON — one named owner per obligation

*R3's fatal: an unowned obligation falls between two halves. Proposed, not imposed:*

| obligation | proposed owner |
|---|---|
| stall/arbitration **contract** (which cycles are NOT-cycles) | **silicon** |
| bus-protocol **FSM proof** | **UNASSIGNED — must be named before the wave** |
| arbitration **fairness** claim | **UNASSIGNED — must be named before the wave** |
| **store-path timing**: `dmem_we` rising vs the beat data leaves the pins | **UNASSIGNED** |
| which-cycle **statement shape** + the trace predicate | **compiler** |
| the **K/N unit re-cut** (below) | **statement-tier ⇒ the Captain, via the helm** |

⛔ **UK1 — THE UNIT COLLAPSE, ROUTED AND NOT ABSORBED.** `sorts_of_C4` carries a literal
cycle count that is commensurable with retired instructions **only through the identity a
stall destroys**. At a CPI of 4–12 the guard passes at roughly a quarter of the intended
instructions — **green and wrong**. Round 1 never mentioned K, N or the constant. **This is
a statement-tier re-cut and I am not absorbing it into a design block.**

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

📌 **What I need is two lines from the contract, unchanged since 11:29**: whether there are
cycles where the core presents an input and memory does not advance, and whether
`dmem_addr8` keeps zero state under the address-map split. **(B), (C) and (D) all price
differently depending on the answers, and (A) survives only if the first answer is "no".**

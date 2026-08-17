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

**A stall breaks exactly that identity**, and nothing else. Silicon's §3 is the same
finding from the RTL side: *"the cycle the strobe rises and the instruction that decoded
it stop being the same clock."*

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
divergence.*** That is the shape option (D) below proposes to reuse, and its being a
precedent rather than an invention is the strongest thing about it.

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
- **cost** two objects to maintain, and the agreement theorem is the real work.
- ⛔ **the lie**: the conditional agreement gets cited without its condition. This is the
  fleet's most-measured failure mode and it has an antidote already built — the condition
  is a hypothesis, so a citation that drops it does not typecheck.
- ⭐ **it is the only option whose lie the kernel itself refuses.**

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

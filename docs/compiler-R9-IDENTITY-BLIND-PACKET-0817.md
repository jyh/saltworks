# R9 vs THE STALL ARM — BLIND DERIVATION PACKET (round 4, act 0)

**Ordered by the helm 2026-08-17 16:09:02:** *"at least one refuter receives §0000.1's
stall-arm text and R9's object definition (the C4Spec sentence and what a witness for it
is) WITHOUT your conclusion, and derives identity-or-distinctness independently. Agreement
required; disagreement = HOLD and it comes to me. A builder may draft; a builder may not be
the only derivation."*

> ⛔ **THIS FILE CONTAINS NO CONCLUSION OF MINE, AND IT WAS COMMITTED BEFORE ONE EXISTED
> IN ANY ARTIFACT.** *That ordering is checkable in git, not asserted here: this file's
> commit precedes the commit of my adjudication. If you can see my answer anywhere by the
> time you read this, the blind arm has already failed and you should say so instead of
> proceeding.* **Do not read my block, my bank, or the bus after 16:09 until you have
> published your own derivation.**

---

## THE QUESTION, AND ONLY THE QUESTION

**Are the two obligations below ONE obligation under two names, or TWO obligations?**

- If **ONE**: round 4's block says so and dates **one** rung.
- If **TWO**: the block must state **the seam between them** — *what crosses it* — so the
  refuters can check the count.
- Either way the refuter round carries the helm's kill-check: ***"is the obligation count
  right — neither double-counted nor zero-counted?"***

---

## OBJECT A — the stall arm (round 4's own task)

**Today's predicate**, `SaltWorks/Stack/Program.lean:1484`:

```lean
def CycleRealisesStepProj (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) : Prop :=
  ∀ ins, (SaltWorks.HDL.decQ (cyc ins)).regs
           = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).regs
       ∧ (SaltWorks.HDL.decQ (cyc ins)).pc
           = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).pc
```

**The finding that makes round 4 necessary** (derived 08/17 14:15). Two kernel facts, both
in `SaltWorks/HDL/ISA.lean`:

```lean
def stepT (s : St) (w : BitVec 32) : St := (stepW s w).getD s.next   -- :1115
def St.next (s : St) : St := { s with pc := s.pc + 4 }               -- :207
```

so **every** word advances the pc — undecodable ones too, via NOP-advance (see
`stepT_undecodable`, ISA.lean:1128). A cycle that
*holds* `(regs, pc)` therefore cannot satisfy the `.pc` conjunct. ⇒ **no stalling cycle map
satisfies this predicate, for any word policy.** Instances kernel-checked in the tree:
`not_cycleRealisesStep_id` (:1900), `not_cycleRealisesStep_stalledBits` (:2404).

**The obligation:** the predicate gains a **stall arm** — every cycle realises a step **or**
is a declared stall holding `(regs, pc)` — subject to two properties: (a) it **reduces to
today's predicate when the stall set is empty**, so the 20-declaration
`CycleRealisesStepProj` cone survives; (b) `not_cycleRealisesStep_stalledBits` then proves
the stall arm **non-empty**.

---

## OBJECT B — R9, the `C4Spec` witness

**The sentence**, `SaltWorks/HDL/C4.lean:76`:

```lean
def C4Spec (c : Circ) : Prop :=
  ∀ ins : Env, sem c ins = encD (stepT (decQ ins) (seenWord ins))
```

**What a witness for it is:** a concrete `Circ` term `c` (the composed core, built from
`CorePlace.lean` / `C4.lean` / `StateCodec.lean` material) **together with a kernel proof
of `C4Spec c`**. It is a CONSTRUCTION task, not a restatement task.

**Current status in the tree:** `C4Spec` is **consumed everywhere and inhabited nowhere**,
and the build is green — the helm's 15:58:02 ruling names this as *"the green-and-wrong
state"*. The nearest candidate is **refuted**: `not_C4Spec_coreShaped`
(**`SaltWorks/Stack/Program.lean`:2859**), and see also `not_both_coreShaped_C4Spec`
(**`SaltWorks/Stack/Program.lean`:2472**).

> ⛔ **CORRECTED 17:1x, AND THE BLIND ARM FOUND IT — the defect this packet warned about,
> committed by the packet.** *As first written, both were bare `:2859` / `:2472` inside an
> Object B section headed by `SaltWorks/HDL/C4.lean:76` — so **the file attribution came
> from PLACEMENT, and placement said C4.lean, which is 178 lines long.*** The line numbers
> were right; **both declarations live in `Program.lean`.** ⚠️ *Also corrected: the
> `stepT_undecodable` pin (ISA.lean:1128) sits **one line inside** its declaration, whose
> keyword line is 1127.* 🔑 ***I verified 7/7 declaration citations mechanically and still
> shipped two wrong attributions, because what I checked was `name → line` and what a
> reader resolves is `name → FILE:line`. **A bare line number inherits its file from the
> nearest heading, and inheritance is not citation.***

---

## NEUTRAL FACT OF THE TREE — relevance NOT asserted

There is a landed theorem connecting the two names, `Program.lean:2306`:

```lean
theorem cycleRealisesStep_of_C4Spec {c : SaltWorks.HDL.Circ} (h : SaltWorks.HDL.C4Spec c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord :=
  cycleRealisesStepProj_of_bits (f := SaltWorks.HDL.sem c) h nextW pad
```

*It is included because omitting a landed theorem that directly names both objects would
bias the packet toward "distinct" by silence. **I assert nothing about what it implies for
the question** — including whether it survives round 4 unchanged.*

---

## WHAT YOUR DERIVATION MUST ANSWER

1. **ONE or TWO?** State it plainly.
2. If TWO: **name the seam** — what object crosses from one to the other, and in which
   direction.
3. **What would falsify your answer?** Name a fact about the tree that, if true, would
   flip it.
4. **Is the obligation count right** — neither double-counted nor zero-counted?

⚠️ **You are cross-verifying, not reviewing.** Per the ownership table's own clause: *"the
verifier must be able to say NO: re-derive from their OWN instruments and REFUSE if it does
not reproduce."*

📌 **CITATION STATUS, so that "verify anyway" is not a substitute for my having verified.**
*Every declaration name and line number above was checked MECHANICALLY against the tree
before this file was committed — 7/7 declarations matched at the stated line.* ⚠️ **The two
kernel facts under Object A did NOT match my first grep and I had quoted them in prose from
memory; they are now pinned to `ISA.lean:1115` and `ISA.lean:207` and both reproduce
verbatim.** ⇒ **Grep the tree yourself regardless.** *A citation that was true when written
is a measurement with a date on it, and this file is a `git log` older than your reading of
it.*

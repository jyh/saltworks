# CLAIM-SCOPE AUDIT — `docs/lang-design-v1.md` (Tiny-Rust → 5-op)

**Assigned** maestro 19:05: *"EVIDENCE the claim-scope audit."* **Run** 19:2x
against `origin/master`, committed refs only — peers are mid-edit.

⚠️ **CONTEXT THAT SETS THE BAR: the maestro is drafting the story v0 and the
Captain's morning presentation TONIGHT, from these blocks.** *So the question is
not only "is §0 true?" but "what does §0 become when it is quoted?"*

---

## ✅ 1. THE BLOCK'S STATED PRECONDITIONS HOLD — verified, reported as a positive

*The block names its assumed world, which is what makes it auditable at all.*

```
"Slice-A ISA as landed (ADD/ADDI/XOR/SLT/BEQ ...)"   ✅ all five present in
                                                        SaltWorks/Stack/*.lean
"the certified encoder organ"                        ✅ present, Program.lean
"sem_* family in Stack/Program.lean"                 ✅ present and substantial
                                                        (sem_adder32, sem_aluSelect,
                                                         sem_bitAnd32, … )
```

## ⭐ 2. THE CORPUS IS EXEMPLARY ON THE THING I CAME TO CHECK

*I expected the composition claim to be the weak point. It is the opposite: the
corpus already contains, kernel-checked, the precise reason it could be weak.*

```lean
theorem conformance_does_not_determine_semantics :
    sem coreShaped (fun _ => false) ≠ sem coreShapedT (fun _ => false) := by
  decide +kernel
```
> *"passing `CoreConforms` says nothing whatever about what the circuit computes"*

**And `C4` is a structure requiring BOTH fields**, with the docstring *"a `C4Spec`
without `CoreConforms` is the well-typed false theorem this file exists to
prevent."* **`Program.lean` states the residual in its own words:**

> ### ⛔ Non-vacuity, and what cannot be witnessed today
> ***`cycleRealisesStep_of_C4Spec`'s premise is C4, so no `Circ` can witness it
> until `core` exists.***

⇒ ***The design's second factor is CONDITIONAL, the condition is openly recorded,
and the file carries three discriminating controls through the same code path.***
**This is a stronger disclosure than most published work manages.**

## ⛔ 3. THE ONE FINDING — §0 DOES NOT CARRY WHAT THE CORPUS CARRIES, AND §0 IS WHAT TRAVELS

**§0, verbatim:**
> *"A verified compiler: source semantics → 5-op machine semantics, the
> correctness theorem in the kernel, so that 'the program does what the source
> says' composes with **'the core does what the ISA says'** and (later) 'the
> executive schedules what the core runs.'"*

⚠️ **BOTH factors are prospective, and §0 reads present-tense for one of them.**
*Read in place — under a `DRAFT-UNTIL-REFUTED` banner, in a block titled "THE
CLAIM THIS BLOCK BUYS" — it is plainly about what the work will buy. **Lifted into
a story or a presentation, "the correctness theorem in the kernel … composes with
the core does what the ISA says" asserts a composition whose second factor no
circuit can witness today, by the corpus's own sentence.***

🔑 ***This is not an error in the block. It is the headline/body split that has
bitten this fleet all day: the file always carried the boundary and the headline
dropped it.*** *I committed the identical thing at 17:33 and struck it at 17:35.*

### ✅ THE MINIMAL FIX — one clause, no re-design

> *"…composes with 'the core does what the ISA says' **(C4 — stated, controlled,
> and not yet witnessed by any `Circ`; `core` does not exist yet)** and (later)…"*

**Cost: one parenthesis. Benefit: the sentence can be quoted without becoming
false**, which is the only property that matters for text the Captain will read
aloud.

---

# CLAIM-SCOPE AUDIT — `docs/slice-b-design-v1.md` (added 20:0x, same pass)

## ✅ ALL THREE STATED PRECONDITIONS VERIFY

```
"phase 3+3b closed (constants at the ruled pair)"  ✅ 3b landed bb82d5c
"the census at PASS/FAIL/UNREACHED/UNWIRED"        ✅ the census DOES carry the
                                                      fourth category, with a
                                                      positive control run before
                                                      landing (compiler-census.py)
"the −1,154 banked gates are the budget"           ✅ arithmetic reconciles:
                                                      1445 − 291 = 1154 exactly
```

⭐ **AND THE BLOCK IS BETTER GUARDED THAN THE LANGUAGE BLOCK WAS.** *Its
SEQUENCING section names the dependency order explicitly — "B-EXEC's statements
refine against B-ISA's landed spec; its waves after B-ISA closes" — so E2's two
invariants are openly prospective rather than reading as held. **The defect I
found in `lang-design-v1` §0 does not recur here.***

## ⚠️ ONE FINDING — A COMPONENT SAVING IS BEING SPENT AS A SYSTEM BUDGET

**The banner states, as present fact: *"the −1,154 banked gates are the budget."***

```
VERIFIED     the SELECT fell 1445 → 291. The 1,154 is real and exact.
NOT VERIFIED that the CORE fell by 1,154 — which is what "the budget" spends.
```

🔑 ***A component saving becomes a system budget only if nothing else grew.*** *The
corpus carries per-component counts (`bn_gate_count`, `ceC_gate_count`,
`adS_mem_gates`, `bnCBuild_gates_drop`, …) and **no whole-core total**, so nothing
in the tree settles it either way.*

⚖️ **THIS IS A QUESTION FOR SILICON, NOT A CORRECTION.** *Silicon owns CELLS
pricing and ran the C5 re-baseline; it may hold a whole-core figure this seat
cannot see. **I can verify the select delta and I cannot verify the system delta,
and those are different claims wearing one number.*** ⇒ *Cheapest close: one line
from silicon stating whether 1,154 is the net core delta or the select delta.
If it is the select delta, the budget sentence wants "banked at the select" in it.*

📌 *Same class as the survivor denominator I published and had corrected at 16:0x
— a true figure over a narrower object than the sentence spends it on.*

## 📌 4. WHAT I DID NOT AUDIT, so the gap is on the record and not in the verdict

- **The semantics themselves** (IMP big-step shape, wrapping `i32`, the register
  pool rejection rule) — that is math's and compiler's slate, not a scope question.
- **§2's statement PAIR** and §3's decomposition — read only far enough to check
  §0's claim; a full statement-form read is math's assignment.
- **`slice-b-design-v1.md` and `two-weeks-story.md`** — not assigned to me tonight
  beyond supplying the story's numbers, which landed separately (`acca901`).

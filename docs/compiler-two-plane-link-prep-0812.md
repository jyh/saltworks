# TWO-PLANE LINK — PREP, ANALYSIS ONLY

**Author:** compiler seat · **Stamp:** 2026-08-12 evening, night program item (1)
**Scope of this document:** statement SHAPES for a theorem linking the Lean control
plane to `Silicon/RTL/ctrl32.v`. **NO RTL edits. No writes outside `HDL/**` and this
`docs/` file. Nothing landed, nothing proved.**

⚠️ **AUTHORED BY THE HEAD THAT SEALED D2, NOT BY A FRESH ONE** — see §0.

---

## 0 · THE DISCLOSURE THE ORDER'S PREMISE NEEDS

The night order says *"COMPILER relights fresh."* **I am not a relit head.** I am
the same head that landed `fb3842a` and sealed `6e3f325`, continuous since 17:08.
My predecessor made this exact flag under the D2 order and it mattered; the
Phoenix protocol exists because a deep head cannot assess its own degradation
from inside.

**Why I proceeded anyway, and where I stopped:** this item is *analysis-only* —
the lowest-risk category, and the one where D2 context is an asset rather than a
liability. **Nothing here is landed or proved, so nothing here can be wrong in
the tree.** ⇒ *Anything downstream of this that LANDS should be taken by a
genuinely fresh head, and the helm may prefer to discard this and re-run it on
one.*

## 1 · ⛔ THE FINDING THAT DECIDES THE STATEMENT'S SHAPE

**The two planes are NOT the same function, and the divergence is measurable
today.** Both readings are `[read]` at the bytes, not inferred:

```
ctrl32.v:26    wire is_load  = (opcode == 7'b0000011);      ← OPCODE ONLY
ctrl32.v:27    wire is_store = (opcode == 7'b0100011);      ← OPCODE ONLY
ctrl32.v:31-32 assign mem_we = is_store;  assign mem_re = is_load;

HDL/Program.lean   dcLWm w = dcOpIs w 0b0000011 && dcF3Is w 0b010   ← + FUNCT3
                   dcSWm w = dcOpIs w 0b0100011 && dcF3Is w 0b010
HDL/ISA.lean:803   decode's LW arm requires funct3 = 010; otherwise it FALLS
                   THROUGH to `none`.
```

⇒ ***For `lb`, `lh`, `lbu`, `lhu`, `sb`, `sh` — opcode matches, `funct3 ≠ 010` —
`ctrl32` ASSERTS a memory access while the Lean plane reports NOT DECODED
(`valid = false`, `req = false`, `isLW = isSW = false`).***

🔑 **`ctrl32` is WIDTH-AGNOSTIC on memory; the Lean plane is WORD-EXACT.** Neither
is wrong for its purpose — `ctrl32` is an area-study artifact whose own header
says *"NOT a submission"*, and the Lean plane deliberately implements Slice A.
**But it means any equality-shaped link theorem is FALSE, and would be found
false only after someone had built the machinery to state it.**

📌 **And the divergence runs in BOTH directions.** `ctrl32` also decodes `lui`,
`auipc`, `jal`, `jalr` — four classes `ISA.decode` rejects outright. *So the
relationship is not "one refines the other" globally; it is a refinement on a
RESTRICTED DOMAIN, in one direction only.*

## 2 · THE SHAPES THAT CAN BE TRUE

Written as shapes, not as Lean — nothing here is stated against an object that
exists yet (see §3).

**S1 · REFINEMENT ON THE ACCEPTED SET** — the load-bearing one.
> *On every word the Lean plane accepts, the two agree on the memory signals.*
> `∀ w, valid(w) = true → mem_re(w) = isLW(w) ∧ mem_we(w) = isSW(w)`

*The hypothesis is doing all the work: it excludes exactly the sub-word ops of §1
and the four extra classes.* ⚠️ **Whoever states this must check it is not
VACUOUS in the other direction — `valid` is true on 7 classes, so the hypothesis
is satisfiable and the theorem has real content. Instantiate and evaluate it;
that is this seat's standing trigger.**

**S2 · THE AGGREGATE SEAM** — what `dmem_addr8.v` actually consumes.
> `∀ w, valid(w) = true → (mem_re(w) ||| mem_we(w)) = req(w)`

*This is the one that matters for composition: `dmem_addr8.v:80` takes ONE access
strobe, `ctrl32` emits two signals, and the Lean plane already forms and proves
the aggregate (`ctrlSpec_req_realises_touchesMem`). **The theorem says the
aggregate formed in RTL equals the aggregate already certified in Lean** — so a
core assembled from `ctrl32` inherits D2's seam proof instead of needing its own.*

**S3 · THE DIVERGENCE, STATED RATHER THAN DISCOVERED** — and it is not optional.
> `∃ w, mem_re(w) = true ∧ valid(w) = false`   (witness: any `lb`)

🔑 ***S1 and S2 are both CONDITIONAL, and a conditional theorem is silent about
where its hypothesis fails. S3 is what stops a reader concluding the planes agree
everywhere.*** *Without it, the link layer says "they match" and never says "on
one seventh of the load opcodes they do not" — which is exactly the invariant-and-
therefore-mute failure D2 spent the afternoon on.*

**S4 · WHAT MUST NOT BE STATED.** *No theorem should relate `valid` to anything in
`ctrl32`: **`ctrl32` has no validity output at all.** It decodes every word and
falls through to defaults. A link that invented a correspondence there would be
comparing a signal to an absence.*

## 3 · ⛔ THE BLOCKING PRECONDITION, PRICED AS A POSITIVE QUANTITY

**None of S1-S3 is statable today, because `ctrl32.v` is not a Lean object.**

```
Silicon/Equiv/*.lean   the refinement pattern EXISTS (~30 files) — this is the
                       established shape for RTL↔Lean and it is SILICON's lane
ctrl32.v               61 lines · HAND-WRITTEN · no Lean provenance marker
                       NOT currently imported anywhere
```
⇒ ***The dominant cost is not the theorems. It is getting `ctrl32.v` into Lean as
a `Circ` (or a hand-built model) with a fidelity argument.*** *Stated as a
positive quantity rather than as a list of things the proof would not need —
this seat's own banked law after pricing D2 by absences and being wrong by 5×.*

⚠️ **AND THE FIDELITY ARGUMENT IS THE WHOLE RISK, NOT A FORMALITY:** a
hand-written Lean model of `ctrl32` that I author would be *my reading* of the
Verilog, and S1-S3 would then certify my reading against my own plane — the
adjacent-object failure, with both sides supplied by the same hand. **The import
must come through silicon's importer, or the fidelity step must be a separate
kernel-checked artifact.** *That is a dependency on silicon's lane, and this
document does not presume on it.*

## 4 · WHAT THIS DOCUMENT DOES NOT CLAIM

- **Not** that the link is worth building. *It may not be: `ctrl32` is an
  area-study artifact and the certified path to silicon may never route through
  it. That is the helm's call and a design question, not a compiler one.*
- **Not** that `ctrl32.v` should change. **Silicon's lane, untouched.** The §1
  divergence is a fact about two objects with different purposes, not a defect
  report against either.
- **Not** any statement about `core32.v`, which I have not read.
- **Nothing built.** Every claim above is `[read]` at the bytes and marked so.

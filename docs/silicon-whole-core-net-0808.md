# THE OWED ONE-LINE ANSWER: is −1,154 a WHOLE-CORE net?
### 2026-08-08 ~20:5x, SILICON. Owed per `slice-b-design-v1.md:10–14` before
### the banked figure is spent as a system budget. Measured, not reasoned.

## THE ONE LINE

> **NO — and it cannot be made one from this corpus, because THERE IS NO
> WHOLE-CORE OBJECT TO TOTAL. Against the named datapath, measured tonight at
> 3,633 gates, the −1,154 is 32% — and against a realistic two-read-port
> datapath (~6,615) it is 17%, not the ~70% it looks like read select-locally.**

## 1 · WHY IT CANNOT BE MADE ONE — the composition does not exist

**No module in `SaltWorks/HDL/` references both `aluSelect` and `obMux`.**
```
population   108 HDL modules + SaltWorks/Silicon/**, comments stripped first
query 1      obMux  AND  (aluSelect | genSelect | sliceASelect)   ->  0 hits
query 2      readTree  AND  (aluSelect | genSelect)               ->  1 hit
             ScratchCertSweep7.lean — UNTRACKED scratch, and READ: it is a
             certificate sweep (port-count theorems + #audit_axioms lines),
             not an assembly. Excluded on its content, not its filename.
```
*Query 1 widened past the bare name deliberately: a composition could wire
`genSelect 3 2` directly and never say `aluSelect`.* Every object
named `*core` in the corpus is a COMPONENT core — `bnCore` (Batcher network),
`ceCcore` (compare-exchange), `cell88core` (the 1988 cell) — **none is a
processor core.** ⇒ *The question "what does the core total?" has no referent
yet. That is a stronger statement than "the total is unverified," and it is the
honest one: the parts have never been wired together in the kernel.*

## 2 · THE MEASURED INVENTORY — every landed datapath component

```
object       gates   how known        note
readTree     2,982   #eval ONLY       nIn 997 = 31 regs x 32 bits + 5 sel; outs 32
aluSelect      291   THEOREM          post-recut; asSelBits = 2; 96*(2^2-1)+2+1
regWrite       163   #eval ONLY       nIn 7, outs 32 — the write DECODER
pcNext          99   THEOREM
obMux           97   THEOREM          namespace SaltWorks.HDL.OperandB
immBCirc         1   THEOREM
immICirc         0   THEOREM
             ─────
SUM          3,633   ← a SUM OF NAMED PARTS, *not* a verified composition
```
⚠️ **The sum is mine, computed outside the kernel. Nothing proves these parts
compose, and the sum omits the decoder, control, and all glue.** *Quote it as an
inventory, never as a core.*

## 3 · ⭐ THE FINDING THAT MATTERS MOST — the biggest object has no theorem

🔑 ***`readTree` is 2,982 gates — 82% of the entire named inventory, and more
than TWICE the whole pre-cut select (1,445). Its size is an `#eval`. So is
`regWrite`'s. The corpus holds 88 proven gate-count theorems and they cover
everything EXCEPT the two largest objects in it.***

⚠️ **An `#eval` is not a theorem**: it is evaluated by the compiler, carries no
kernel check, and `#audit_axioms` never sees it. *The number is almost certainly
right — it decodes exactly as 31 muxes × 3 gates × 32 bits + 6 decode = 2,982 —
but "almost certainly right" is the category this fleet exists to eliminate.*
✅ **The cheapest high-value row available in this whole area is
`theorem readTree_gate_count : readTree.gates.length = 2982 := by decide +kernel`.**
*One line, and the corpus's dominant object stops being an assertion.*
See [[audit-coverage-is-not-proof-coverage]].

## 4 · TWO CORRECTIONS TO THE BUDGET LANGUAGE, both narrowing it

**(a) IT IS ONE READ PORT.** `nIn 997 = 31 × 32 + 5` is a single `rs` read. An
R-type op needs `rs1` AND `rs2`. A second port is another ~2,982 unless shared,
so the realistic datapath is **~6,615 gates and −1,154 is ~17% of it.**

**(b) STORAGE IS NOT COUNTED ANYWHERE ABOVE.** `Circ` is combinational; the
register file's **1,024 flip-flops** (32 × 32) appear in NO number in this
document, exactly as the BB-switch account's cores excluded their state bits.
*A whole-core figure that omits 1,024 flops is not a whole-core figure.*

## 5 · WHAT THE −1,154 *IS*, stated so it can be spent honestly

✅ **It is REALIZED, not pending** — `asSelBits = 2` is landed in `AluSelect.lean`,
so the core's own select IS 291 today; `aluSelect.gates.length = 291` is a
theorem (`GenSelectCount.lean:569`). *The saving is banked in the artifact, not
merely designed.*
✅ **It is a SELECT-LOCAL delta**, kernel-proven as the difference of two
instantiations (`genSelect 10 4` − `genSelect 3 2`), and correct as such.
⛔ **It is NOT a system budget.** *Spending it as one means claiming the memory
organ is free if it costs under 1,154 gates — but the core it is 32% (or 17%) of
has never been assembled, so "free" has no denominator.*

📌 **RECOMMENDED WORDING for the block, if it wants one sentence:**
*"−1,154 gates at the select (proven), which is 32% of the named datapath
inventory (3,633, measured) — the whole-core figure does not exist and the
register file, at 2,982 gates for one read port plus 1,024 unpriced flops,
dominates whatever it turns out to be."*

## 6 · CARRIED INTO MY OTHER TWO SLICE-B ROWS

**This settles the tile-interaction row before I run it:** tonight's pricing put
the binding constraint on the register file by AREA and then on PINS. **The gate
inventory now agrees from a second, independent direction — 82% of the named
datapath is register-file read path.** *Two instruments, one conclusion, and they
do not share an input: one is yosys cell area, the other is kernel gate counts.*
⇒ **B1's memory organ competes with the register file for the tile, not with the
select.** Alignment mask (B4) and the memory pricing in cells follow separately.

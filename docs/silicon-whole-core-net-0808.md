# THE OWED ONE-LINE ANSWER: is −1,154 a WHOLE-CORE net?
### 2026-08-08 ~20:5x, SILICON. Owed per `slice-b-design-v1.md:10–14` before
### the banked figure is spent as a system budget. Measured, not reasoned.

## ⛔ AMENDED 21:0x — MY INVENTORY MISSED THE WRITE PATH. THE SUM NEARLY DOUBLES.

**`regNext` (`regNextN 32 32`: nIn 1088, outs 1024) is 3,104 gates — the WHOLE
FILE's next-state logic. I inventoried `regWrite` (163) instead, which is ONE
register's write cell and a COMPONENT of `regNext`, not an addition to it.**
*Found because compiler landed `regNext_gate_count` beside the `readTree` row I
asked for; their "sibling" was an object I did not know existed.*
```
                     published 20:5x  amended 21:0x  corrected 21:0x  FINAL 22:0x
named datapath sum       3,633            6,574          6,737          6,898
−1,154 as a fraction       32%             17.6%          17.1%          16.7%
register-file share         82%            92.6%          92.8%          90.6%
```
⛔ **THE 22:0x PASS FIXES A POPULATION ERROR, NOT AN ARITHMETIC ONE: MY CENSUS
EXCLUDED `SaltWorks/Stack/`.** *I searched `HDL/**` and `Silicon/**` and never
looked in `Stack/Program.lean` — a 422 KB file holding 5 more gate-count theorems
and 25/33/54/60 references to `aluSelect`/`genSelect`/`readTree`/`regNext`.
**Surfaced only because compiler's 21:57 retraction said that file was richer
than anyone had been treating it as.***
✅ **THE COMPOSITION CLAIM SURVIVES OVER THE LARGER POPULATION** — `obMux` occurs
**zero** times in `Stack/Program.lean`, so still nothing composes it with
`aluSelect`.
⭐ **AND `pcAdd` (260) REPLACES `pcNext` (99) IN THE SUM, BECAUSE IT CONTAINS IT
— TESTED BEFORE PUBLISHING THIS TIME:**
```lean
def pcAdd : Circ := { gates := ⟨pcAddZero, .const false⟩
    :: (instGates pcNext … ++ instGates adder32 …) }
1 const + 99 (pcNext) + 160 (adder32) = 260  ✓ EXACTLY pcAdd.gates.length
```
🔑 ***THIS IS THE `regWrite`/`regNext` TRAP A SECOND TIME, AND THE DIFFERENCE IS
THAT I RAN COMPILER'S OWN CONTAINMENT TEST BEFORE PUBLISHING RATHER THAN AFTER
BEING REFUTED: does the body reference the other, and do the gates account for
themselves?*** *Both answered yes here — so summing `pcNext` beside `pcAdd` would
have double-counted, exactly as excluding `regWrite` under-counted.*
📌 **NEXT UNCOUNTED OBJECT, for compiler's slot: `adder32` = 160 gates
(`HDL/Adder.lean:97`, nIn 65, outs 33) has NO gate-count theorem anywhere in the
corpus** — the same gap `readTree` and `regNext` had until `0625cc8`.
⛔⛔ **MY AMENDMENT'S PREMISE WAS WRONG AND COMPILER REFUTED IT WITHIN MINUTES
(21:01). `regWrite` IS NOT A COMPONENT OF `regNext`; EXCLUDING IT LOST 163
GATES.** *Verified independently before accepting:*
```
regNext's gates account for THEMSELVES, with nothing left over:
    32 nots (rnWe r is an INPUT NET)  +  32 regs × 32 bits × 3  =  3,104   ✓ exact
ports show the direction:  regNext nIn 1088 = 1024 state + 32 res + 32 WE  (CONSUMES)
                           regWrite outs 32                                (PRODUCES)
`regWrite` appears ZERO times in RegNext.lean's body
```
⇒ ***They compose IN SERIES — `regWrite` → 32 enables → `regNext` — so BOTH are
needed and summing them does not double-count.***
🔑 **MY MECHANISM: I INFERRED "COMPONENT OF" FROM AN `import`. An import is a
dependency of the FILE, not of the DEFINITION** — and the identifier I "found"
was the capitalised MODULE name `RegWrite`, not the term `regWrite`. *Case, for
the third time today.* ⚠️ **AND I HAD THE REFUTING DATUM IN MY OWN TABLE: I wrote
`regWrite … nIn 7, outs 32` and then called it "one register's write cell."
`outs = 32` says 32-WAY DECODER. I read past my own measurement to reach a
relationship I had already assumed.** *Same class as compiler's one-arm `case`
read: a fragment generalised to a whole.*
🔑 ***THE CORRECTION STRENGTHENS EVERY CONCLUSION BELOW AND CHANGES NONE OF
THEM.*** *The register file is 93% of the named datapath, not 82%; −1,154 is a
smaller fraction of the core, not a larger one; and "the memory organ competes
with the register file" is now the overwhelming reading rather than the merely
dominant one.*
⚠️ **AND MY 17% WAS RIGHT FOR THE WRONG REASON** — I got it by DOUBLING the read
port (2 × 2,982). The truth is that the write path was missing mass. *Both
corrections together — two read ports AND `regNext` — give **9,556 gates and
12.1%**.* See [[right-conclusion-wrong-reason]].
📌 **CITERS: `slice-b-design-v1.md` B1 carries `3,633` and `32%`. Replace with
`6,574` and `17.6%`; the register-file share becomes `92.6%`.**

## THE ONE LINE

> **NO — and it cannot be made one from this corpus, because THERE IS NO
> WHOLE-CORE OBJECT TO TOTAL. Against the named datapath, measured tonight at
> 6,737 gates (AMENDED TWICE — see above), the −1,154 is 17.1%, not the ~70% it
> looks like read select-locally. With a second read port (9,719) it is 11.9%.**

📌 **THE FIGURE MOVED TWICE IN TWENTY MINUTES — 3,633 → 6,574 → 6,737 — and the
SENTENCES never moved at all: no whole-core object; the saving is a small
fraction of the core; the register file dominates and is what the memory organ
competes with.** *Both corrections came from a peer, both raised the sum, and
both made the conclusions stronger. A number under active refutation is worth
more than a number nobody checked, and this is what that looks like in flight.*

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
regNext      3,104   THEOREM (0625cc8) regNextN 32 32; nIn 1088 = 1024 state
                                       + 32 res + 32 WE; outs 1024. CONSUMES
                                       the enables — the next-state mux array.
readTree     2,982   THEOREM (0625cc8) nIn 997 = 31 regs x 32 bits + 5 sel; outs 32
regWrite       163   #eval            nIn 7, outs 32 — the 32-WAY WRITE-ENABLE
                                       DECODER. PRODUCES the enables regNext
                                       consumes: they compose IN SERIES, so both
                                       are summed and nothing double-counts.
aluSelect      291   THEOREM          post-recut; asSelBits = 2; 96*(2^2-1)+2+1
pcNext          99   THEOREM
obMux           97   THEOREM          namespace SaltWorks.HDL.OperandB
immBCirc         1   THEOREM
immICirc         0   THEOREM
             ─────
SUM          6,737   ← a SUM OF NAMED PARTS, *not* a verified composition
                       of which the REGISTER FILE is 6,249 = 92.8%
                       (regNext + readTree + regWrite)
```
📌 *`regWrite` is the one figure here still resting on an `#eval` rather than a
theorem — the same gap that `readTree` and `regNext` had until `0625cc8`.*
✅ **Both `#eval`s in the 20:5x version are THEOREMS now** — compiler landed
`readTree_gate_count = 2982` (matching my independent evaluation exactly) and
`regNext_gate_count = 3104` in `0625cc8`. *The recommendation in §3 below is
DISCHARGED; it is kept because the reasoning for it still applies to the next
uncounted object.*
⚠️ **The sum is mine, computed outside the kernel. Nothing proves these parts
compose, and the sum omits the decoder, control, and all glue.** *Quote it as an
inventory, never as a core.*

## 3 · ⭐ THE FINDING THAT MATTERS MOST — the biggest object has no theorem

🔑 ***AS WRITTEN AT 20:5x, AND THE REASONING IS WHY THE CORRECTION ABOVE EXISTS:
`readTree` is 2,982 gates — more than TWICE the whole pre-cut select (1,445) —
and its size was an `#eval`, not a theorem. The corpus held 88 proven gate-count
theorems and they covered everything EXCEPT its largest objects.***
✅ **DISCHARGED within four minutes: compiler landed both counts as
`decide +kernel` theorems (`0625cc8`).** ⚠️ **AND THE LANDING IS WHAT EXPOSED MY
OWN ERROR — the "sibling" they added was `regNext`, the 3,104-gate object I had
never found, which is why the corrected register-file share is 92.6% and not the
82% this section originally claimed for `readTree` alone.** *Asking for a number
to be checked is how I discovered I had measured the wrong object.*

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

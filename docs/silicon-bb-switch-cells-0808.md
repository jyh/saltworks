# §3 — SILICON'S HALF OF THE BB-SWITCH ACCOUNT: THE THREE CELLS IN STANDARD CELLS
### 2026-08-08 ~20:0x, SILICON, council deliverable ① (dispatched 19:19, PRE-AUTH).
### For the maestro to fold into `docs/bb-switch-account.md` §3.
### FIREWALL inherited verbatim: the ISSCC 1990 paper is cited WORDS-ONLY. Every
### number here is measured on OUR objects, by the flow in `Silicon/Flow/synth.sh`,
### against the pinned sky130 PDK `c6d73a35…`.

## 0 · ⛔ READ THIS BEFORE THE TABLE — THE CELL COLUMN IS NOT AN INDEPENDENT MEASUREMENT

**Two of the three objects exist in the tree only as STRUCTURAL netlists — Verilog
that already instantiates sky130 cells, emitted from the `Circ` by the fleet's
`emitS`. `synth.sh`'s own header says why that matters: `read_liberty -lib`
declares those cells as BLACKBOXES, and *abc cannot restructure through a
blackbox, so an already-mapped design comes out as it went in*.**

⇒ ***IN STRUCTURAL MODE THE CELL COUNT EQUALS THE GATE COUNT BY CONSTRUCTION. The
6/34/40 below is COMPILER'S OWN COLUMN wearing different units — it is one number
printed twice, not two methods agreeing.*** ⚠️ **A council reader who sees
"gates 6/34/40" beside "cells 6/34/40" and reads corroboration has read one
witness as two.** *That is [[agreement-is-not-corroboration]] at the level of a
table column, and it is the single thing most likely to be mis-read out of this
section.*

✅ **THE AREA COLUMN IS NOT redundant** — µm² is the real silicon area of the real
mapped cells, and it is NOT proportional to gate count, because gate TYPES differ
in size. That column is silicon's actual contribution.

## 1 · THE THREE CELLS, ALL IN ONE REGIME

```
object              maps to                cells   area µm²   µm²/gate   state
Banyan.element      banyan_element_s.v         6         38       6.3      0
ceCcore             ce_c.v                    34        198       5.8      4*
cell88core          cell88core.v              40        235       5.9      5*
                                                   * state bits live in the SEQUENTIAL
                                                     wrapper, not in these cores
all three: SYNTH_STRUCTURAL=1, sky130_fd_sc_hd, PDK c6d73a35…, one flow, one PDK
```
📌 **The µm²/gate column is flat (5.8–6.3) and that is the honest reading: at this
scale the three cells are built from the same KIND of small gate, so area tracks
gate count almost linearly. The oracle is not cheap per gate — it is cheap because
it has six gates.**

## 2 · ⭐ WHAT OPTIMISATION BUYS, AND IT IS AVAILABLE FOR ONLY ONE ROW

**`Banyan.element` is small enough to write BEHAVIOURALLY and check by inspection
(two `assign` lines, transcribed from `Banyan.lean:56/95`). Through the DEFAULT
flow, where abc may restructure:**
```
                         cells   area µm²
structural (passthrough)     6         38
BEHAVIOURAL (optimised)      2         18     −67 % cells, −53 % area
```
🔑 ***Six kernel gates become TWO standard cells because sky130 carries
`a22o_1` — an AND-AND-OR compound that implements `(s₀∧a) ∨ (s₁∧b)` in one cell.
The library already contains the oracle's exact shape.***
⚠️ **AND THIS IS WHY NO RATIO MAY BE COMPUTED ACROSS THE ROWS: I have an optimised
number for ONE object and passthrough numbers for the other two. `2 vs 34` would
be a 17× claim built from two different flows. The comparable pair is `6 vs 34`
(same regime) and the optimisation datum stands ALONE, as a fact about the oracle
and the library — not as a comparison.**

## 3 · PROVENANCE — what is verified, transcribed, and assumed

```
cell88core.v        EMITTED by `emitS` from the kernel `Circ`. Verified path,
                    not my hand. 40 gates -> 40 instances, ports as declared.
banyan_element_s.v  EMITTED by `emitS` from `element 0 1 2 3 4 5 6`, wrapped as a
                    6-input core. Verified path. ⚠️ THE WRAPPING is mine: nIn=6,
                    outs=[8,11]. If those out-nets are wrong the AREA is wrong.
banyan_element.v    MY HAND, behavioural, two `assign` lines. Checkable by
                    inspection against Banyan.lean:56/95 in ten seconds. NOT the
                    verified path — must not be cited as the verified element.
ce_c.v              pre-existing in the tree; structural; 7 in / 6 out / 34 cells,
                    which matches compiler's `ceCcore` nIn=7=3+4, outs=6, gates=34
                    EXACTLY — that port-and-count agreement is the identification.
```
⛔ **NOT MEASURED HERE: the sequential wrappers.** *The state bits (4 and 5) live
in `ceC`/`cell88`, not in the cores above, so no flop area is counted in any row.
A cell's true silicon cost includes its flops; these numbers are CORES ONLY, and
the account's §1 table is likewise core-scoped.*
⛔ **NOT MEASURED HERE: routing, placement, congestion, or any post-layout effect.**
*These are yosys pre-layout areas from one mapping pass.*

## 4 · CO-TENANCY CONTEXT, since the dispatch asked

**Tonight's tile pricing (`docs/silicon-riscv-layout-pricing-0808.md`) found the
switch fabric at 2,143 µm² — 5 % of a 2×2 at 60 % density — so none of the three
cells above is anywhere near a tile constraint. The constraint is the register
file of whatever core shares the tile, and after the 19:37 zero-cell refutation
the live limit on co-tenancy is PINS (a core needs ≥3 signals; two are free), not
area.** *Nothing in this section changes that, and none of these numbers should be
cited in a tile argument.*

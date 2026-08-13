# CELL COVERAGE CENSUS — what stands between the flow and every netlist in the corpus

### SILICON seat · 2026-08-12 night · self-named board item, taken when the queue
### thinned to zero actionable items (maestro 19:14: *"post [BOARD] if a queue thins"*).
### Tool: `SaltWorks/Silicon/Importer/cell_coverage.py`. Re-runnable, controls not optional.

## 0 · WHY

`nand4_1` was the one cell between the flow and a clean `dmem8` import — and that
was known **only because someone ran the importer and read the refusal.** For the
other 45 netlists the answer was unknown, and *unknown* is the state in which a
cost gets discovered late. This makes it a printed, priced list.

## 1 · THE HEADLINE

```
16 clean  +  29 blocked  +  1 empty  =  46 of 46 netlists
31 distinct unmodelled cells across the corpus
```
**The buckets are asserted to sum to the denominator; the tool refuses to report
if they do not.** The 16 clean netlists are **named** in the output, not merely
counted — *a coverage figure nobody can audit is a claim.*

## 2 · ⚓ THE ONE THAT MATTERS FOR D1a — AND IT CORRECTS AN EASY ASSUMPTION

`nand4_1` opened **`dmem8` only.** The rest of the family is still shut:

| netlist | unmodelled cells | |
|---|---|---|
| `dmem8` | **0** | ✅ clean, EXIT=0, readback green |
| `dmem16` | **5** | `and4_1 and4b_1 nor4_1 nor4b_1 nor4bb_1` |
| `dmem32` | **9** | the above **+** `a2111oi_0 nand4b_1 nand4bb_1 or4_1` |
| `dmem_addr8` | **1** | `nor4_1` ×7 |
| `dmem_addr16` | **1** | `nor4_1` ×7 |

🔑 ***`dmem16`'s set is a strict SUBSET of `dmem32`'s — measured, not eyeballed —
so NINE combinational cells open the entire remaining `dmem` family.*** And all
nine are `logic-MISSING`: **every one is in the routine combinational class the
helm named tonight, not the sensitive sequential one.**

⭐ **The cheapest real step in the whole corpus: `nor4_1` alone opens
`dmem_addr8` AND `dmem_addr16`** — one cell, two netlists, 7 instances each.

## 3 · THE PRICED LIST — AND A DISTINCTION THAT WOULD HAVE BEEN MISQUOTED

⚠️ **"Appears in" is NOT "frees".** A netlist is unblocked only when **all** of
its missing cells are modelled, so one cell frees exactly those netlists where it
is the **sole** blocker. *An earlier draft of this tool printed the appears-in
column under the heading "ranked by netlists freed" — which reads as a delivery
estimate and would have been quoted as one.* Both columns now print:

| cell | appears-in | **frees alone** | instances |
|---|---|---|---|
| `nor4_1` | 21 | **2** | 103 |
| `xnor2_1` | 15 | **2** | 494 |
| `a311oi_1` | 13 | **1** | 84 |
| `o211ai_1` | 13 | 0 | 311 |
| `o221ai_1` | 12 | 0 | 258 |
| `mux4_2` | 11 | 0 | **1509** |
| *…25 more* | | | |

⇒ **Across 31 cells, only 3 unblock any netlist on their own, freeing 5 in
total.** *The corpus is blocked by combinations, not by single cells — which is
exactly the fact a per-cell ranking hides.*

**GREEDY COVER — the honest shape of the remaining cost:**
```
+nor4_1     1 cell  ->  2 freed, 27 blocked      +a41o_1    27 cells ->  3 freed,  8 blocked
+xnor2_1    2 cells ->  2 freed, 25 blocked      +o2111a_1  28 cells ->  2 freed,  6 blocked
+a311oi_1   3 cells ->  1 freed, 24 blocked      +a21bo_1   29 cells ->  3 freed,  3 blocked
+mux4_2     8 cells ->  1 freed, 23 blocked      +o41a_1    30 cells ->  2 freed,  1 blocked
+nand4b_1  13 cells ->  2 freed, 18 blocked      +a2111o_1  31 cells ->  1 freed,  0 blocked
```
📌 ***The curve is BACK-LOADED: 13 cells free 8 netlists, and the last 18 cells
free 21.*** *The corpus does not open gradually — it opens near the end. Any plan
that prices "the first few cells" as representative will be wrong in the
expensive direction.*

## 4 · ⚠️ A NETLIST IN THE CORPUS IS EMPTY

`slicea16t_nl.v` — 12 lines, **zero cells**, a module with ports and no body.

```verilog
module slicea16t(clk, rst_n, instr_bit, instr_shift);
  input clk; input rst_n; input instr_bit; input instr_shift;
endmodule            // ALL FOUR PORTS ARE INPUTS. There are no outputs.
```
Synthesis deleted the entire design because **nothing it computed was
observable** — [[unobservable-state-is-deleted]], the law this seat banked, caught
in the corpus rather than in a new core.

⛔ **It is excluded from BOTH counts, and that is the load-bearing choice:**
*"every cell is modelled" is **vacuously true of zero cells**, so counting it
clean would have inflated coverage with a design that does not exist.*

## 5 · THE CONTROLS — a census nobody controlled is a number, not a measurement

```
extractor vs trusted parser   text scan 673 == importer's own 673 on dmem8   AGREE
control-of-the-control        a deliberately narrowed pattern sees 8, not 673
                              -> the comparison CAN go DISAGREE
FLIP CONTROL                  remove nand4_1 from the resolver and dmem8 must go
                              CLEAN -> {'nand4_1': 17}.  DISCRIMINATES
```
🔑 ***The flip control is the strong one, because its answer was fixed
independently:*** `nand4_1` landed tonight and a separate census measured 17
instances. **The census reproduces both facts, so it is responding to the
resolver and not to itself.** *Controls run first and cannot be skipped; if any
fails the tool refuses to print a census rather than printing one with a caveat.*

## 6 · THE RULE THE TOOL WAS BUILT TO OBEY

It **calls** `expansion_for`, `base_of`, `SEQ_MODELS`, `SEQ_PREFIX` and
`PHYSICAL_PREFIX` from `import_netlist.py`; it does not restate them. *This seat's
predecessor computed "7 missing cells" twice and was wrong twice, because it
compared base names against a key set mixing full names (`nand2_1`) with base
names (`and3`). The resolver's rule is exact-key-then-drive-stripped. **A census
that re-types that rule is testing its own copy.***

⚙️ *Mechanically: `import_netlist.py` is a script whose argparse runs at module
level, so it loads the importer's own bytes truncated at the CLI boundary — and
**refuses** if that boundary is not found exactly once, rather than guessing a cut
point. Restructuring the trusted, byte-compared importer under a `__main__` guard
to serve a census would invert the dependency for no gain.*

## 7 · WHAT THIS IS NOT

* **Not a promise that a listed netlist imports once its cells are modelled.** It
  measures **cell coverage only.** Sequential structure, clock-domain unity, port
  order and readback are separate gates — `dmem8` passed all of them, but that was
  measured by running the importer, not inferred from this table.
* **Not a change to the trusted set.** No cell was added here; `nand4_1` was
  landed separately at `5688ee2` under its own discipline.
* **Not a claim about the fabricated TT artifact**, whose census lives in
  `Cells/CI-cell-census.md` and is a different population (the `_2` drive family).

---

# ADDENDUM — THE NINE CELLS LANDED, AND THE `dmem` FAMILY IS OPEN

### Taken immediately after the census, under the same routine-combinational class
### the helm named at 18:49. **All nine are combinational; none is sequential.**

## A · THE MODELS WERE PRE-REGISTERED, AND CAME OUT 9 FOR 9

`Cells/CI-cell-census.md` forbids generating a model from the Liberty it is
checked against. So the nine derivations were **written down first**, from the
cell names and the bubbling conventions already encoded in `Sky130.lean`
(AND/NAND bubble the FIRST input, per `and3b`; NOR/OR bubble the LAST, per
`nor3b`), **before the vendor file was read** — with the risk named in advance:

> *"Entries 6 and 7 rest on the NOR-bubbles-last convention, which I read from a
> single existing model. If the vendor bubbles a different pin, those two are
> wrong and their theorems will FAIL rather than mislead."*

**The vendor pin lists came back `nor4b(A,B,C,D_N)` and `nor4bb(A,B,C_N,D_N)` —
the convention held, and all nine derivations matched.** *A convention read off
one example is a guess until a second case tests it; this tested seven more.*

```
✓ and4_liberty  ✓ or4_liberty   ✓ nor4_liberty     ✓ and4b_liberty  ✓ nand4b_liberty
✓ nand4bb_liberty  ✓ nor4b_liberty  ✓ nor4bb_liberty  ✓ a2111oi_liberty
all [0 axioms] · saltbuild EXIT=0
```
⚠️ **Two of the nine carry a weak theorem, said plainly:** for `and4` and `or4`
the name and the vendor function are the **same expression**, so those theorems
confirm arity and pin order and little else. The content is in the bubbled and
AOI cells, where the model is a conjunction under a negation and the vendor
states a disjunction of negations.

## B · THE CENSUS MOVED EXACTLY AS IT PREDICTED

```
before   16 clean + 29 blocked + 1 empty
after    20 clean + 25 blocked + 1 empty
```
**The four that flipped are the four the census named** — `dmem16`, `dmem32`,
`dmem_addr8`, `dmem_addr16`. *The census predicted its own effect and was right,
which is a better check on it than any control I could plant.*

## C · ⭐ `dmem16` AND `dmem32` IMPORT CLEAN

```
dmem16   3964 gates ·  512 flops cut · conservation OK · readback 32 vectors ×  544 outputs · EXIT=0
dmem32   8450 gates · 1024 flops cut · conservation OK · readback 32 vectors × 1056 outputs · EXIT=0
```
⇒ **The whole `dmem` memory family now imports** — 8, 16 and 32 — each under the
`rst_n ≡ 1` restriction with the scope marker riding on the datum. **No datum
lands**; the bar and helm condition (4) are unchanged.

## D · 📐 THE OTHER TWO ARE CELL-CLEAN AND BLOCKED ON **MATH's** OPEN CALL

`dmem_addr8` and `dmem_addr16` are cell-clean and still refuse:

```
importer: assign uses a RANGE 'byte_addr[4:2]' -- the grammar models bit-selects
and scalars only. Refusing rather than collapsing the range to one bit.
```
**That is the range-extension grammar — the question already at math's muster,
not a cell problem.** Measured across the corpus:

| | |
|---|---|
| netlists with range assigns | **13**, 31 lines *(independently reproduces the predecessor's count)* |
| cell-clean **and** range-blocked — freed by the grammar call **alone** | **2** (`dmem_addr8`, `dmem_addr16`, **one line each**) |
| range-using netlists that **also** still need cells | 11 |

🔑 ***So the grammar call unblocks exactly two netlists today, each gated by a
single line.*** *That is a scoping datum for math and it cuts against urgency:
the grammar is a correctness question worth answering carefully, not a
bottleneck holding up corpus coverage.*

## E · THE DOC'S OWN CAVEAT WAS EXERCISED WITHIN THE HOUR

§7 said this census measures **cell coverage only**, and that a listed netlist is
not promised to import. **Two of the four it freed then failed to import for a
non-cell reason.** *The caveat was not boilerplate; it was load-bearing, and it
is the reason the four were RUN rather than reported clean from the table.*

---

# ADDENDUM 2 — GROUND TRUTH: the import sweep, and how wrong the proxy was

### `SaltWorks/Silicon/Importer/import_sweep.py`. Cell coverage was a **proxy**;
### this runs the actual importer on all 46 and records what actually gates each one.

## G.1 · THE RESULT

```
17 import  +  28 blocked  +  1 skipped  =  46 of 46
```

**BLOCKERS — ⚠ the FIRST gate hit, not the only one:**

| class | netlists | detail |
|---|---|---|
| `unmodelled-cell` | 13 | `xnor2_1`×5, `mux4_2`×4, `o211ai_1`×2, `a311oi_1`, `a41oi_1` |
| `range-grammar` | 13 | `imm_b[31:12]`×3, `pc_q[31:2]`×2, `pc_plus_4[1:0]`×2, … |
| **concatenation** | 2 | *"RHS has 2 terms (cout, cin) — concatenations are not modelled"* |

## G.2 · ⚠️ A CLASS COUNT IS NOT A DELIVERY COUNT — THE SAME TRAP, ONE LEVEL UP

The importer refuses at the **first** problem it meets, and **the range check runs
before cell expansion.** So a netlist filed under `range-grammar` may *also* be
missing cells, and clearing the grammar would merely advance it to its next
refusal.

```
range-grammar is the FIRST gate for      13 netlists
range-grammar is the ONLY remaining gate  2 netlists   (dmem_addr8, dmem_addr16)
```
🔑 ***Read carelessly, this table says math's grammar call unblocks 13. It
unblocks 2.*** *Same shape as the "appears in is not frees" error in §3, caught
one level up — and the two analyses agree exactly once first-blocker semantics
are accounted for, which is what makes them a cross-check rather than two
guesses.*

## G.3 · HOW WRONG THE PROXY WAS — AND IN WHICH DIRECTION

```
cell-clean (proxy)   20
actually import      17
false POSITIVES       3   adder8s (concatenation) · dmem_addr8 · dmem_addr16 (range)
false NEGATIVES       0   nothing imports that the census called blocked
```
⭐ ***So cell coverage is a strictly NECESSARY, NOT SUFFICIENT condition — it errs
only optimistically, by 15%.*** *That is worth stating precisely, because a proxy
with no false negatives is safe to use as a filter and unsafe to use as a
promise, and the census doc claimed exactly that in §7 before it was measured.*

## G.4 · THE CONTROLS, AND THE OWN-GOAL THAT NEARLY BURIED THIS

**Agreement with facts fixed independently, hours earlier and by hand:**
```
dmem8   1984 gates ·  256 flops      dmem16  3964 ·  512      dmem32  8450 · 1024
```
**identical to the hand-built port lists** — so the sweep's automatic port
derivation is not inventing a different design. And its 13 range-blocked
netlists match the 13 found by an independent text scan.

⛔ **THE FIRST RUN REPORTED `0 import + 45 blocked` — INCLUDING `dmem8`, `dmem16`
AND `dmem32`, WHICH I HAD PROVED CLEAN TWENTY MINUTES EARLIER.**
```
CAUSE   the sweep passed --out /dev/null; readback reads the emitted datum back
        FROM DISK, and /dev/null reads empty
EFFECT  every netlist that got far enough to be CHECKED was recorded as a
        FAILURE -- the sweep was strictest exactly where the importer worked
        hardest, and its verdict was inverted for precisely the good cases
CAUGHT  not by care. By the result contradicting a measurement already banked.
```
*A second instrument tonight that failed in the alarming direction, which remains
the lucky one — and the second whose only catch was a number that could not be
true.* **The fixture that survives is the one whose output can be checked against
something already known.**

## G.5 · ⛔ WHAT "IMPORTS" DOES NOT MEAN

The sweep derives *a* valid port list from each module's own declaration, purely
to drive the importer. **Port ORDER is load-bearing and is not recoverable from
the netlist** — `reimport.sh` records two data whose orders were lost, and
`readback.py` records that swapping two `--outputs` entries permutes the datum
and its reference *identically*, so nothing catches it. ⇒ **A netlist reported
`IMPORTS` has not been shown to yield the datum any downstream proof wants.**
Nothing the sweep produces is written to the tree.

---

# ADDENDUM 3 — BATCH 2: six cells chosen by CROSSING the two instruments

## H.1 · THE TARGETING, WHICH IS THE POINT

The corpus-wide greedy cover in §3 is **back-loaded** — 13 cells free 8 netlists,
the last 18 free 21 — so "model the highest-leverage cells" is bad advice on its
own. **Crossing the census with the sweep changes the answer:** 13 netlists are
blocked *only* by cells (no range assign, no concatenation), and those are the
ones where a cell model buys a **real import** instead of advancing a netlist to
its next refusal.

```
restricted to those 13, the curve FLIPS to front-loaded:
  +xnor2  +mux4  +o211ai  +o221ai  +a311oi  +maj3   =  6 cells -> 8 netlists
```
🔑 ***Same cells, same corpus, opposite prioritisation — because the first
ranking optimised a proxy and the second optimised the outcome.***

## H.2 · PREDICTED BEFORE, MEASURED AFTER

```
PREDICTED (before the work)   17 -> 25 imports
MEASURED  (after)             25 import + 20 blocked + 1 skipped = 46 of 46
                              +8 exactly · regressions: NONE
new: adder8r · batcher_net · cmpex · cmptree · csr32 · csr32b · regfile16 · wbpath
```
*The forecast was written into the targeting, not fitted afterwards.*

## H.3 · THE DERIVATIONS WENT 6 FOR 6 — 15 OF 15 ACROSS BOTH BATCHES

Pre-registered in `docs/silicon-cell-model-prereg-0812-batch2.txt` with **three
risks named in advance**, the sharpest being:

> *"`mux4_2` is the one I am least sure of. The NAME gives no pin names and no
> select ENCODING… It is the only entry here whose SHAPE, not just whose
> polarity, is a guess."*

**The vendor returned `in=(A0,A1,A2,A3,S0,S1)` with binary encoding and `S1` as
the high bit — the guess was right in every particular.** *Which is the useful
result: the sky130 naming convention has now carried 15 derivations across two
independent batches, including one where it had to supply pin names and an
encoding, not just a polarity.*

⚠️ **`maj3` joins `and4` and `or4` as a WEAK theorem** — the standard majority
form and the vendor function are the same expression, so it confirms arity and
pin order and little else. Flagged in the source, not just here.

## H.4 · STATE AFTER BATCH 2

```
cell coverage   28 clean + 17 blocked + 1 empty = 46      (was 20 / 25 / 1)
import sweep    25 import + 20 blocked + 1 skipped = 46   (was 17 / 28 / 1)
proxy gap       3, unchanged and still all optimistic
gates           reimport EXIT=0 4 of 7 ALL REPRODUCE · pinreset EXIT=1 from C3.A2 alone
all 15 models   [0 axioms] · saltbuild EXIT=0
```
⛔ **No datum has landed.** The bar and helm condition (4) are untouched by any
of this; every netlist above was imported to a temporary file and discarded.

---

# ADDENDUM 4 — BATCH 3 CLOSES THE CELLS-ONLY CLASS, AND MY PREDICTION WAS WRONG

## J.1 · THE RESULT, AND THE MISS

Targeting re-run on the **post-batch-2** state rather than reused: 5 netlists
remained blocked only by cells, needing 10 cells, and the curve there is **flat**
(no front-loaded prefix) — so there is no clever subset and the honest move is to
close the class.

```
PREDICTED   25 -> 30 imports          MEASURED   29 import + 16 blocked + 1 skipped
                                                 +4, not +5.  Regressions: NONE
cell coverage 35 clean + 10 blocked + 1 empty · unmodelled-cell blockers: ZERO
```
⚠️ ***The cells-only class IS closed — no netlist is gated on a cell any more —
but one of the five did not import.*** `trap32` advanced to a gate my targeting
did not model.

## J.2 · 🔑 A **THIRD** GRAMMAR CLASS, MISSED BECAUSE I ONLY EXCLUDED TWO

My "blocked only by cells" filter excluded **range assigns** and
**concatenations**. The corpus has a third form:

```verilog
assign trap_pc = mtvec;      // WHOLE-VECTOR alias: no range, no concatenation
```
**5 netlists, 5 lines** — `branch32 · core32 · csr32 · csr32b · trap32`. **It is
not in the range-extension pricing**, which measured range-assign lines and RHS
concatenations. *So the scope already referred to math is short by one form.*

📌 ***The prediction failed for exactly the reason I have been publishing all
night: clearing one gate reveals the next, and a filter can only exclude the
classes its author knows about.*** *I priced the miss at zero and it was one in
five.*

## J.3 · ✅ THE IMPORTER IS **SAFE** ON THIS CLASS — measured, not assumed

A silently-dropped assign is the shape that should worry anyone, so it was
checked rather than argued:

```
4 of 5   the aliased LHS is a DEAD ALIAS — declared, assigned, referenced
         NOWHERE else (verified on branch32 `tgt`, csr32 `csr_wdata`).
         Dropping it changes nothing, and those netlists import.
1 of 5   trap32: `trap_pc` is an OUTPUT, so dropping its only driver leaves it
         undriven — and the importer's driver check REFUSES.
```
⇒ **Either the assign feeds nothing, or the net it feeds is caught as undriven.
No path emits a datum that silently lost the assignment.**

## J.4 · ⚠️ BUT THE DIAGNOSTIC IS WRONG, AND THAT IS A REAL DEFECT

```
range form   "assign uses a RANGE 'byte_addr[4:2]' -- the grammar models
              bit-selects and scalars only. Refusing rather than collapsing..."
              -> names ITSELF, names the CURE
whole-vector "net 'trap_pc[0]' has no driver and is not an input"
              -> names a SYMPTOM, and points at the PORT LIST
```
🔑 ***The refusal is correct and its explanation sends the reader to the wrong
file.*** *I spent the first minute of this investigation checking my own
auto-derived port list, because that is what the message accused.* **An
unmodelled grammar form should refuse by naming itself, exactly as its sibling
already does** — the two forms are one feature apart and a world apart in how
they fail. Registered as a defect of this seat's importer; **not fixed here**,
because the grammar question it belongs to is at math's muster.

## J.5 · STATE

```
25 cell models, ALL [0 axioms] · derivations pre-registered 25 of 25 over 3 batches
import sweep    29 import / 16 blocked / 1 skipped
cell coverage   35 clean / 10 blocked / 1 empty      proxy gap now 6, all optimistic
remaining gates range-grammar 13 · concatenation 2 · whole-vector 1 · CELLS 0
reimport EXIT=0 · pinreset EXIT=1 from C3.A2 alone · selftest EXIT=0
```
⇒ **Every netlist still blocked is blocked on the GRAMMAR, in one of its three
forms. Nothing left in this corpus is a cell problem, and nothing left is mine.**

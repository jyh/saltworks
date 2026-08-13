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

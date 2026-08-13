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

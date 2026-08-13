# FIGURE 4 — THE STRUCTURAL JOIN, AND WHY THE BLACK MASS IS NOT WHAT MY OWN BANK SAID

**Wake order (maestro, at the Captain's word, 2026-08-12 evening):** run the
structural join of the netlist hierarchy, attribute the anonymous majority, and
produce BOTH colorings — function AND provenance — for `fig-die-logic-colored`.
**Scope fence honoured: the join ONLY.** `dfrtp`, the importer range extension,
and re-hardening stay gated post-D2.

## INPUT, WITH PROVENANCE

```
  the SUBMITTED gate-level netlist   tt_um_saltworks_ndf.v
  sha256  3a8577e019d26e0921892c44353b0db74a6dcf76dd43f57879fe8a17ed15a541
  5,935,941 bytes · 230,710 lines · 53,160 sky130 instances · ONE module (flattened)
```
⚠️ *Read from a prior session's scratchpad, not from CI. **The sha is recorded so
the census is reproducible against the CI copy**, which is the durable original.*

## THE CENSUS — reproduces every published figure

```
  TOTAL instances     53,160
    physical/filler   47,438     decap · fill · tap · antenna · PHY_EDGE
    LOGIC              5,722     <- matches the Figure-4 census exactly
  NAMED by hierarchical prefix   1,443
      cell0 383 · cell1 383 · cell2 383      (383/group, as published)
      ser0   98 · ser1   98 · ser2   98      ( 98/group, as published)
  ANONYMOUS                      4,279  = 74.8% of logic   <- THE BLACK MASS
  flops: 902 total · 288 in named groups · 614 anonymous
```

## ⛔ THE FINDING: `cell3` WAS NOT RENAMED. IT WAS TIED OFF AND CORRECTLY DELETED.

**My own bank carried this warning:** *"cell3's name appears ZERO times in the
5.7 MB netlist while its three identical siblings keep theirs — a name join
reaches 288 of 352 (82%) and would paint a KERNEL-EMITTED MAC CELL as HAND RTL."*

**The first half is true. The inference is false, and the measurement is decisive:**
```
  a cell3-shaped island needs   and2_1 x127 · xor2_1 x96 · or2_1 x31 · inv_1 x1
  the anonymous mass contains   and2_1 x  0 · xor2_1 x 0 · or2_1 x 0 · inv_1 x0
  every and2_1 on the die       127x3 (cells) + 33x3 (sers) = 480 = ALL of them
```
**And the RTL says why.** `tt_um_saltworks_ndf.v:265`:
```verilog
  mac_cell_signed_shell cell3 (
    .clk(clk), .clr(clr),
    .en_wsh(1'b0), .en_acc(1'b0),        // BOTH ENABLES TIED LOW
    .i0(1'b0), .i1(1'b0), .i2(1'b0),     // ALL INPUTS TIED LOW
    .o0(acc3[0]), ...
```
🔑 ***EVERY ENABLE AND EVERY INPUT IS HARD-TIED TO ZERO. Its flops can never
change state, so synthesis constant-propagated the entire island away. `cell3`
is a DELIBERATELY DISABLED instance that the flow correctly removed — not a
naming casualty.***

⚖️ **SO THE 82% IS NOT A NAME-JOIN SHORTFALL.**
```
  352 = an RTL-SIDE count (4 shells x 64 + 3 sers x 32)
  288 = the DIE's kernel-emitted flops
  the difference is 64 = exactly one mac cell, which IS NOT IN SILICON
  => on the die, the name join reaches 288 of 288. There is no MAC cell to
     mispaint, because there is no fourth MAC cell.
```
*This is [[adjacent-object-principle]] in my own bank: 352 describes the RTL, 288
describes the die, and the entry compared them as if they described one object.
It is also [[unobservable-state-is-deleted]] — my own law — firing exactly as
written, on the case that produced it.*

## THE TWO COLORINGS — `Flow/fig4_cell_coloring.tsv`, one row per logic cell

**FUNCTION** (what it does)
| color | cells | share |
|---|---:|---:|
| core_combinational | 1,974 | 34.5% |
| clock_tree | 1,418 | 24.8% |
| core_sequential | 614 | 10.7% |
| mac_island_cell0/1/2 | 383 each | 6.7% each |
| core_mux | 262 | 4.6% |
| serializer_ser0/1/2 | 98 each | 1.7% each |
| tie | 11 | 0.2% |

**PROVENANCE** (who wrote it)
| color | cells | share |
|---|---:|---:|
| agent_written | 2,821 | 49.3% |
| kernel_emitted | 1,443 | 25.2% |
| tool_inserted_cts | 1,418 | 24.8% |
| tool_inserted_drive | 40 | 0.7% |

⭐ **THE BLACK MASS RESOLVES INTO THREE THINGS, NOT ONE:** the `slicea16bma core`
(the switch fabric, control and accumulators — local synthesis sizes it at 2,547
cells), the **clock tree** (1,418 cells, definitionally inserted by CTS and
authored by nobody), and drive-strengthening. **A quarter of the die's logic is
clock distribution, and calling it "agent-written" would be as wrong as calling
it kernel-emitted.**

## HOW THE JOIN WAS DONE, AND WHAT IT IS NOT

- **Attribution is by HIERARCHICAL PREFIX, never by leaf instance name** — the
  standing rule from the `cell3` episode. The netlist is flattened to one module;
  the surviving prefixes (`cell0.`, `ser0.`) are the only naming evidence.
- **Provenance uses structure, not names**: CTS cell families and `_4`/`_8`
  drive strengths appear ONLY outside the named groups, so they are separable
  without trusting any identifier.
- ⚠️ **NOT AN IDENTITY CLAIM.** `slicea16bma` at 2,547 cells is a LOCAL synthesis
  reference; the die was built by LibreLane. The residual against the non-clock
  anonymous cells is flow difference, and I am not reporting it as a match.
- ⚠️ **Drive strength is a PARTIAL discriminator only.** 1,352 anonymous cells
  are `_1` drive, so the split is a signature and not a partition. Reported as
  such, and not used to classify anything on its own.
- ⛔ **No placement.** Coordinates live in the GDS/DEF; this join is topological.
  Figure 4's coordinate frame is unaffected and unclaimed by this work.

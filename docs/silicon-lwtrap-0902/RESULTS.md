# Row 5's harness, as FILES — the trap-gate fidelity measurement, rebuilt 2026-09-02 and driven

*silicon. The 08/30–08/31 measurement ("the die does NOT hold `rd` on a trapping address … priced +40 cells /
+160.15 µm² / +0.282%") was made on a SCRATCHPAD harness that died with its session; desk row 5 registered
"commit to saltworks docs" as a side-item and it stayed owed for three days. This directory is the repair:
`run.sh` regenerates every figure below from `SaltWorks/Silicon/RTL/core32.v` and the two files beside it.*

## The measurement, re-derived (`bash docs/silicon-lwtrap-0902/run.sh`, iverilog + yosys/sky130 tt)

**The gate is ONE wire.** `core32_gated.v` differs from `core32.v` in the `reg_we` block only (the runner diffs
them: 8 changed lines, all that block): `ld_trap = is_load_w ∧ (alu_y ≥ 32 ∨ alu_y[1:0] ≠ 0)` — exactly the
kernel's `addrClass` (`HDL/ISA.lean:111`: `outOfRange ↔ byte address ≥ 32`, tested first; else `misaligned ↔
addr % 4 ≠ 0`) — and `reg_we` takes `is_load_w ∧ ¬ld_trap`. **`dmem_req` and `dmem_we` are untouched**, so
`DriveMap` (req = isLW ∨ isSW, we = isSW) stays true by construction; the bench asserts `dmem_req = 1` on
both trapping loads in BOTH arms.

```
                                     core32 (as fabricated)     core32_gated
LW x1,1(x0)   misaligned             WRITES deadbeef            HOLDS 11111111
LW x1,32(x0)  outOfRange, boundary   WRITES cafef00d            HOLDS 22222222
LW x1,64(x0)  outOfRange, far        WRITES cafef00d            HOLDS 33333333
LW x1,28(x0)  aligned in range  ⭐ positive control: WRITES 0badf00d in BOTH arms
SW  x0,1(x0)  store             ⭐ negative control: rd HELD in BOTH arms, dmem_we = 1
dmem_req on the trapping loads       1                          1   (the one-wire property)
MUTATION CONTROL  a gate that fires on EVERY load is REFUSED by the positive control
```
⇒ **Row 5's finding stands, re-derived at this hand: the fabricated core writes `dmem_rdata` to `rd` on a
trapping word load and continues; conforming programs (no trap-class loads) are identical in both arms.**
The 08/31 run used addresses 1 and 64; this one adds the kernel's exact boundary, 32.

## The price — and the 08/31 figure is NOT reproduced, said plainly

```
whole core, this recipe (synth; dfflibmap; abc; stat -liberty, sky130_fd_sc_hd tt):
   core32          4,444 cells   56,778.20 µm²
   core32_gated    4,817 cells   56,290.24 µm²      Δ = +373 cells, −487.97 µm² (−0.859%)
the gate's OWN logic, standalone (trapgate_only.v: comparator + 2-bit test + the AND/OR):
   trapgate_only      11 cells       70.07 µm²      ← the honest upper bound on what the gate ADDS
```
⛔ **The whole-core delta is abc restructuring noise, not the gate's cost**: a one-wire RTL change reshuffles
the whole 4,400-cell netlist, and the area moved DOWN while the cell count moved up by nine times the gate's
size. The 08/31 scratchpad figure (+40 / +160.15 µm² / +0.282%) came from a recipe that died with the
scratchpad and is not reproduced here; **quote the standalone figure (11 cells, 70 µm², 0.12% of the core)
as the gate's price, and the whole-core delta as evidence that a whole-core delta cannot price a 10-cell
change.** (Neither the committed `core32` figure in `core32.v`'s comments — 4,434 cells / 56,462.90 µm² — nor
this recipe's 4,444 / 56,778.20 is the other's recipe; they agree to 0.2% cells and 0.6% area.)

## What this does NOT change
Ruling 7(a) (council 09/01): the caption lands in the R10 statement text, zero hardware cost; (b) the gate
stays available, now priced from committed files. The `ndf-2a` resubmission carries NO RTL change, so the
fabricated part has this behaviour whether or not the gate is ever taken.

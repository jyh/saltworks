# THE CORE AT SCALE — 5,054 cells, and the RTL route does not close

### 2026-08-07, SILICON. The maestro ordered the core assembled from the surveyed
### blocks. **This closes the gap I flagged in my own C3 verdict four hours
### earlier: "the probe design is 49 cells, not 5,000. Boundary survival at CPU
### scale has NOT been measured."** It has now, and the answer is decisive.

## The core

`RTL/core32.v` — RV32I single-cycle, machine mode without CSR/trap (C3's scope):
fetch + PC path, decode + immgen, 31×32 register file, ALU, memory interface,
writeback select. Every inter-block boundary the survey named is `(* keep *)`.

```
5,054 cells · 57,606 um^2 · 1.27 tiles of 2x2
```

⭐ **My 07:36 estimate was 53,011 um^2 / 1.17 tiles — 8 % low, and the tile count
(2) is unchanged.** *An estimate whose error does not move the conclusion.*

## The measurement

| | cones | median | **max** | ≤ 24 |
|---|---|---|---|---|
| untreated | 2,084 | **1024** | 1060 | 47.6 % |
| cut at the survey's named boundaries | 2,331 | 38 | 1003 | 46.7 % |
| **+ the merged aliases** | 2,395 | **12** | **881** | **60.1 %** |

**The composition effect is severe**: untreated, the median whole-core cone is
**1024** — the register file's 992 state bits reach essentially everything.
Cutting at the named boundaries takes the median to **12**. ⛔ **But it does not
close: 22 of 95 flop roots stay over, the worst at 812, and its leaves are
dominated by 713 RAW `regs` bits** — the register read was partially re-derived
past `rf1`/`rf2`.

## 🆕 A NEW FAILURE MODE AT SCALE: boundaries are MERGED AND RENAMED, not just bypassed

At block scale `keep` failed by **bypass** — the net survived and the optimiser
routed around it. At core scale it also fails by **merger**:

```
assign alu_y   = dmem_addr;
assign rf2[7:0] = dmem_wdata[7:0];              <- PARTIAL, 8 bits of 32
assign pc_q    = { imem_addr[31:2], pc_plus_4[1:0] };
```

**The net survives under a DIFFERENT NAME**, so a census that cuts by source name
**silently under-cuts** and reports the untreated figure. ⚠️ **I hit this myself:
my first cut listed `alu_y` and missed it entirely, and I was one step from
reporting "`alu_y` dissolved" when it had merely been renamed.** *That is the
adjacent-object failure again, on a new axis: **name identity after merging**.*

⇒ **A `--cut` regex written against RTL identifiers is not sound at core scale.**
The boundaries must be found in the **netlist**, not assumed from the source.

## What this establishes

1. **The RTL route does not close at CPU scale.** 60.1 % with every named
   boundary cut, 22 flop roots over, worst 812. **Not 99 %, not 90 % — 60 %.**
2. ⇒ **This is exactly the failure option (A) is immune to**, because structural
   emission has no attribute to ignore and no name to merge: the boundary **is a
   cell instance**, and the C3 probe measured 128 of 128 surviving.
3. ⚠️ **What is still NOT measured: structural emission AT THIS SCALE.** The probe
   was 49 cells; this core is 5,054. **I have shown the alternative fails at
   scale; I have not yet shown (A) holds at scale.** *That is the next
   measurement, and it is the one that should gate C5.*

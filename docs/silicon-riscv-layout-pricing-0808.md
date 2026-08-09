# RISC-V SLICE-A LAYOUT PRICING — (a) co-tenant vs (b) own tile
### 2026-08-08 19:0x, SILICON, campaign ① of the night shift. **The tile decision
### is the Captain's; these are the numbers it rests on, with their assumptions
### named so he is deciding on a measurement and not on a summary.**

## 0 · THE HEADLINE, AND IT IS NOT THE QUESTION THAT WAS ASKED

⭐ **CO-TENANCY IS NEARLY FREE. THE REGISTER FILE DECIDES THE TILE.**

*The switch fabric — the thing "co-tenancy" was about — is **2,143 µm²**, which is
**5% of a 2×2 at 60% density**. It is not the constraint and never was. The
constraint is the register file, which is 45,011 µm² at 32 registers and
21,592 µm² at 16 — and that one choice moves the answer across the tile boundary.*

```
                                     area   @100%   @60%    @45%   of a 2x2
(a) Slice-A(rf32) + switch         61,631     82%   136%    181%   ⛔ NO FIT
(a) Slice-A(rf16) + switch         38,212     51%    84%    112%   ✅ fits @60
(b) Slice-A(rf32) alone            59,488     79%   131%    175%   ⛔ NO FIT
(b) Slice-A(rf16) alone            36,069     48%    80%    106%   ✅ fits @60
    switch alone (shipped today)    2,143      3%     5%      6%
2x2 GROSS = 334.88 x 225.76 = 75,603 um2 (EUR 280) · 1x2 = 36,347 um2 (EUR 140)
```

⇒ ***THE QUESTION "(a) OR (b)?" IS DOMINATED BY A QUESTION NOBODY ASKED: 32
REGISTERS OR 16. At 16 registers BOTH options fit a 2×2 and co-tenancy costs 4
percentage points. At 32 registers NEITHER fits, and buying its own tile does not
rescue it.***

## 1 · TWO PREMISES CORRECTED BEFORE ANY NUMBER

⛔ **"the manifest's own stretch-goals headroom — 88% free" is an ADJACENT-OBJECT
reading.** *`tinytapeout-dossier.md:210` verbatim: "a latch-based design has
fitted 512 bits in one tile at **88% utilisation**". That is a THIRD PARTY's
design, 88% USED, 12% left — a capacity data point about what others fitted into
a 1×1, not headroom in our 2×2.* **Our actual occupancy is the 5% above, measured.**

⛔ **There is NO Slice-A core to price.** *`SaltWorks/Silicon/RTL/core32.v` header,
verbatim: "RV32I CORE … **NOT a submission artifact**". No `slice_a` or 5-op
module exists in the RTL or the Flow directory.* **So every figure here is
BOTTOM-UP from measured blocks, and §3 states which direction each error runs.**

## 2 · METHOD, REGISTERED BEFORE COMPUTING (and it earned its keep)

1. **Priced by AREA, not cell count** — tile fit is µm² against a placement
   density, not a cell tally. ⭐ **This choice protected the deliverable: my first
   cell-count extraction was wrong for 14 of 30 modules (`core32` by 3.1×)
   because yosys prints large per-type areas in scientific notation and my
   pattern skipped those rows. The AREA figures come from a different line and
   were verified separately.**
2. **GROSS ≠ USABLE.** Every figure names its density. LibreLane's sanctioned
   `PL_TARGET_DENSITY_PCT` default is 60; 45 is shown as the congestion-safe case.
   *A fit claimed against gross area is the error this document exists to prevent.*
3. **Slice-A ISA, as landed** (`lang-design-v1.md:6`): `ADD ADDI XOR SLT BEQ`,
   **no memory, state = register file only.** Blocks included: fetch/PC ·
   decode+control · regfile · ALU · branch compare. Excluded: `memif` (no loads),
   `csr32` (19,472), `trap32`, `hazard32`, `wbpath` (30,711 — see §3).

## 3 · WHICH WAY EACH ERROR RUNS — stated, not averaged

**OVER-counts the logic (the estimate is HIGH):** every block is from the RV32I
survey. `alu32` is a full ALU where five ops need ADD/XOR/SLT; `ctrl32` decodes
the whole ISA. *A purpose-built 5-op datapath is strictly smaller.*

**UNDER-counts the total (the estimate is LOW):** `wbpath` is excluded entirely
(30,711 µm², 97% sequential — it is the writeback/load path Slice-A does not
need, but SOME writeback mux is required). **No TT harness, I/O ring, or
`tt_um_*` wrapper is counted.** No routing congestion beyond the density factor.
*Post-layout is reliably worse than a yosys area sum.*

⇒ ⚖️ **NET: the rf16 configuration has real margin at 60% and I would defend it;
the rf32 configuration is not marginal, it is over by a third, and no plausible
correction closes a 31% overshoot.** *The two directions do not cancel, and I have
not averaged them into a single false number.*

## 4 · WHAT WOULD MAKE THIS DECIDABLE RATHER THAN ESTIMATED

**Synthesise an actual 5-op core.** *One RTL file, the five ops, a 16-entry and a
32-entry variant, through the same yosys flow that produced every number above.
That converts §3's two-directional uncertainty into one measurement, and it is
hours not days — the blocks already exist and the flow is in the tree.*
📌 **Until then the honest form of this document is: "the switch is not the
constraint; the register file is; at 16 registers it fits and at 32 it does
not" — which is a SHAPE, not a price, and the Captain should be told which he is
holding.**

## 5 · FLOW-PREP (the order's second half) — opened, not closed

- **Top module shape:** the TT wrapper is `tt_um_*` with `ui_in[8]/uo_out[8]/uio[8]`
  (spec §6 pin map, already carrying `cnt[3]→uio_out[5]` Captain-confirmed today).
  A co-tenant core needs its own pin budget carved from the same 24 signals.
- **Pin budget:** the switch currently uses `ui_in[7:0]`, `uo_out[7:0]`,
  `uio_in[0]`, `uio_out[5:1]`, `uio[7:6]` reserved. **Free today: `uio[7:6]` and
  `uio_out[0]` — three pins.** *A 5-op core with an instruction port needs far
  more; the honest reading is that co-tenancy requires either a shared bus with a
  mode bit, or the core is instruction-fed from an on-tile ROM.* **This is the
  first real constraint on option (a) and it is not an area constraint.**
- **What hardening needs from compiler:** the op semantics the 5-op ISA exposes
  (their inventory item ②), and whether one end-to-end core theorem crowns the
  organs — because the flow question "what do we harden" is answered differently
  if the certified object is the whole core rather than the parts.

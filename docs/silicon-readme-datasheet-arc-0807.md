# THE README / DATASHEET ARC — f_max, the heritage line, and the die pair

### 2026-08-07 ~16:5x, SILICON, on the maestro's queue. Every number below is
### read from the flow's own signoff reports or from a PDF in
### `${LOCAL_SEAT}/papers-bellcore-arc/`. **No remembered figures.**
### Source run: `31226766476` (`revision-bb1-composed`, all six jobs green),
### `GDS_logs → runs/wokwi/55-openroad-stapostpnr/`.

---

## 1. STA f_max — the Captain's 17:43 ask, answered at the signoff reports

### 1.1 The readout

Post-PnR signoff STA, `summary.rpt`, all nine corner/group rows. Minimum period
= `CLOCK_PERIOD − setup slack`; the fabric is **bit-serial**, one bit per clock
per link, so **MHz and Mb/s-per-link are the same number**.

| corner | setup slack | min period | **f_max** | **Mb/s / link** |
|---|---|---|---|---|
| `nom_ff_n40C_1v95` (fast) | +6.6838 ns | 13.32 ns | **75.1 MHz** | 75.1 |
| `nom_tt_025C_1v80` (typical) | +3.6293 ns | 16.37 ns | **61.1 MHz** | 61.1 |
| `max_ss_100C_1v60` (**slow — the limit**) | **−3.4554 ns** | 23.46 ns | **42.6 MHz** | 42.6 |

✅ **Hold is clean everywhere: worst +0.1115 ns, `0` violations at every one of
the nine corners.** *Nothing here is a hold risk in either direction.*

📌 **AGAINST WHAT WE PUBLISH:** `info.yaml` declares `clock_hz = 25 MHz`
(40 ns). The slow corner closes at **23.46 ns**, so the shipped part carries
**≈16.5 ns of margin — about 1.7× headroom at the worst corner.**
⇒ ***The 24 setup violations are against the 20 ns hardening constraint, which
is a 50 MHz we never claim. The chip meets its published spec.***

### 1.2 The critical path, and it is NOT a register path

```
Startpoint : rst_n     (input port clocked by clk)
Endpoint   : uo_out[1] (output port clocked by clk)
39 cell stages, of which 30 are inside u_sort
   12 × mux2_4 · 11 × and2_4 · 5 × or2_4 · 2 × inv_1 · 2 × buf_8 · 2 × a32o_2 · …
```
🔑 **`summary.rpt`'s "of which reg to reg" column reads `0` for all 24 setup
violations, and `timing__setup_r2r__ws` is `Infinity`.** ⇒ ***There is no
constrained register-to-register path in this design at all. The critical path
is pure combinational logic from an input pin to an output pin*** — which is not
a surprise once stated, because it is what the frame protocol RULED.

**The budget, decomposed:**
```
input external delay      4.000 ns   ← TT's assumption, not our logic
our combinational logic  15.205 ns   ← 19.205 − 4.000
data arrival             19.205 ns
clock period             20.000 ns
clock uncertainty        −0.250 ns
output external delay    −4.000 ns   ← TT's assumption
data required            15.750 ns
slack                    −3.455 ns   VIOLATED
```
⇒ **8.25 ns of the 20 ns budget is TT's I/O harness, not this design.**

### 1.3 ⛔ THE FINDING: the "combinational between stages" ruling was made for a
### fabric that no longer exists, and BB-1 never re-opened it

`docs/hdl-frame-protocol-v1.md:60-63` rules the fabric combinational, and gives
its rationale verbatim:

> *"the fabric measures **~96 cells** against a ~17,955 µm² tile, so area does
> not force pipelining; **combinational depth is 3 elements (~9 gates)**,
> nowhere near the timing budget"*

| | when the ruling was made | the composed tile today |
|---|---|---|
| cells | ~96 | **816** |
| combinational depth | 3 elements (~9 gates) | **39 cell stages** |
| timing budget | *"nowhere near"* | **misses 20 ns by 3.46 ns at `ss`** |

⇒ ***Both halves of the rationale are now false. BB-1 composed a 24-element
Batcher in front of the banyan and the ruling that made the fabric combinational
was never revisited.*** **The measured 39-stage path is the direct consequence,
and it is the whole of the f_max story.**
📌 *Nothing is broken — the part meets its published 25 MHz with 1.7×. But the
ruling should be re-taken deliberately rather than inherited, and if a future
wave wants the 1990 rates, per-element pipelining is the lever the 1990 chip
already proved.*

---

## 2. THE HERITAGE PARAGRAPH — sourced, ready to paste

**Every figure below is from a PDF on the shelf. Citations are `[tag]` per
`papers-bellcore-arc/BIBLIOGRAPHY.md`.**

> In 1990 Bellcore built this switch in silicon. A CMOS Batcher-and-banyan chip
> set — W. S. Marcus and J. J. Hickey, *ISSCC 1990 Digest*, pp. 32–33
> (DOI `10.1109/ISSCC.1990.110116`), with the journal version in
> *IEEE J. Solid-State Circuits* **25**(6):1426–1432, Dec 1990
> (DOI `10.1109/4.62170`) — was **measured at 170 Mb/s per bit-serial link**,
> against a 155.52 Mb/s SONET STS-3c target, for **5.44 Gb/s aggregate over 32
> channels**. It was **1.2 µm CMOS**, a single 5 V supply, about **1.5 W**, in
> an **84-pin LCC**. The switching elements are US **5,130,976** (Hickey &
> Marcus, filed 1991-02-12, granted 1992-07-14); the network architecture is US
> **4,910,730** (Day & Giacopelli, filed 1988-03-14, granted 1990-03-20).
>
> This chip is the same architecture, 36 years later, on 130 nm open silicon —
> and it is **proved**, not merely tested. What 1990 established by measurement,
> the Lean kernel here establishes by proof: the gate netlist that goes to the
> foundry is the netlist the theorems are about.

⚠️ **THREE CITATION FENCES, and they exist because each was got wrong once:**
1. **Never cite US 4,910,730 for numbers.** It carries **no process node and no
   155 figure** — only a background "100 megabits/sec" goal. It is the
   *architecture* citation only.
2. **The "1 µm at 155 Mbit" memory is two chips merged.** **1.2 µm** is the
   chip set (the 170 Mb/s one); **1 µm** is the *cell processor* — J. J. Hickey
   (solo), "A 50 MIP ATM Cell Processor for B-ISDN," **CICC 1992**, IEEE Xplore
   doc `5727353`: 1 µm, **622 Mbit/s** (STS-12c), 50 MHz. Different chip,
   different paper, different decade-end.
3. ⚠️ **`BIBLIOGRAPHY.md` still carries a `MAY BE TRUNCATED` warning on the
   ISSCC author list. The bus retired that caveat on 8/6 18:37** — the list is
   confirmed **complete** (Marcus & Hickey, ISSCC 1990 Session 2 WPM 2.4) from
   the PDF itself. **The file is stale, not the fact.** *Fix the file before
   anyone re-derives the caveat from it.*

### 2.1 ⭐ THE COMPARISON THAT IS ACTUALLY INTERESTING — and we lose it

|  | 1990 chip set | this chip (2026) |
|---|---|---|
| process | 1.2 µm CMOS | **130 nm** (sky130) |
| per-link rate | **170 Mb/s measured** | 61 Mb/s @ typical, 42.6 @ slow, **25 declared** |
| logic style | full-custom **dynamic**, 65-transistor element | standard-cell static |
| **pipelining** | **one bit-time per element** | **none — combinational end-to-end** |
| **gate depth per clock** | **9** (ISS'90 §3.1) | **39** (measured, §1.2) |

⇒ ***A 1.2 µm chip from 1990 is ~2.8× faster than our 130 nm one at typical, and
~4× faster at the slow corner. The process is not why.*** **The depth ratio is
39/9 ≈ 4.3× and the speed ratio is 2.8–4.0× — the same order.** *They pipelined
every element and paid 9 gate delays per clock; we pipeline not at all and pay
39.*
🎯 **That is the honest headline and it is a better story than a win would be:
we did not make it faster. We made it PROVED — and the measurement shows exactly
what the proof cost and where it could be bought back.**

---

## 3. THE DIE-PLOT PAIR — the honest jumble beside Figure 6

**Left: ISSCC'90 Figure 6** (`isscc90_batcher_banyan_chipset.pdf` p.3), the
Batcher-chip micrograph. The die reads like the block diagram: Input Col →
fabric as **countable cell-column stripes** alternating with wiring channels →
Latch Col → Mux → Output Col, pad ring around. **The architecture is legible.**

**Right: our 2026 render** (`gds_render` artifact, run `31226766476`). Viewed at
the pixels, honestly:
* the logic is a **wedge in the top ~third**, densest at upper-left, tapering
  right; **the remaining ~two-thirds is uniform tap/decap filler**;
* standard-cell **rows** are visible; **architectural columns are not**;
* **you cannot count stages, elements, or the Batcher/banyan boundary.**

### ⛔ THE HONEST NO, AND IT IS DOCUMENTED RATHER THAN EXCUSED

The fences experiment was run on 8/6 and **failed to produce columns**:
* **The DEF route is closed to us.** OpenROAD honours fences via DEF
  `REGIONS`+`GROUPS` `TYPE FENCE` — but a TT submitter cannot inject a DEF,
  because `tt_tool.py`'s `create_user_config()` writes `FP_DEF_TEMPLATE` last
  and it wins.
* **The obstruction route was tried and accepted without complaint** —
  `gds` ✅ `precheck` ✅ `gl_test` ✅ — ***"they just do not produce columns."***
* The sharpest baseline reading: **a reader counts TWO stripes, not three** —
  stage 2 is already its own column (the placer pulled it toward the output
  pins) while stages 0 and 1 are fully interleaved.

📌 **AND THE RENDER ADDS A CAUSE THE 8/6 EXPERIMENT DID NOT NAME: DENSITY.**
`design__instance__utilization = 15.28 %` on a 2×2 tile bought for headroom.
⇒ ***The placer had no reason to organise anything — there was no pressure to.
The 1990 die is legible partly because every column was hand-placed and partly
because the die was FULL. Ours is a sparse wedge in a tile with room to spare.***
*(Read off the rendered image plus the utilization metric — not from placement
coordinates, which I did not measure.)*

### ⛔⛔ HALT ON THE IMAGE — I WENT TO BUILD THE COMPOSITE AND FOUND A FIREWALL
### PROBLEM AT THE FOOTER OF THE PAGE

I rendered ISSCC'90 p.3 at 300 dpi to place it beside our render. **Every page
of all four PDFs carries this line:**

```
Authorized licensed use limited to: GOOGLE.  Downloaded on August 07,2026
at 01:25:02 UTC from IEEE Xplore.  Restrictions apply.
```
*(verified on all four: `isscc90…`, `iss90…`, `cicc92…`, `sunshine91…`)*

⇒ **TWO distinct problems, and only one of them is copyright:**

1. 🔴 **THE LANE.** These files were obtained under a **GOOGLE institutional
   licence** — outside-lane access — and item ③ would put an image from them
   into a **PUBLIC personal-lane repo.** The portfolio firewall
   (JYH-ratified 2026-07-21) is explicit that outside-lane material does not cross
   into personal repos. ***This is the firewall's case exactly, and it is the
   one I would not want discovered after publication.***
2. ⚖️ **THE COPYRIGHT.** Figure 6 is IEEE's to license; *"Restrictions apply"*
   is their own notice. Republishing it needs a right we have not established.

✅ **AND THE MITIGATION IS STRONG, BUT IT IS THE CAPTAIN'S TO INVOKE, NOT
MINE: JYH IS AN AUTHOR OF THIS PAPER.** IEEE's policy permits authors to reuse
their own figures with citation. ⇒ ***The right plausibly exists — through
AUTHORSHIP, not through the Google licence*** — and if it is invoked, the image
should be re-obtained by a personal-lane route (his own copy / IEEE author
reuse), **not** cropped from the file on this disk.

📌 **UNAFFECTED: §2, the numbers and citations.** *Bibliographic facts — DOI,
page numbers, "measured 170 Mb/s" — are not copyrightable, and citing them is
ordinary scholarship.* **The heritage paragraph ships as written.** *Reading
these PDFs to VERIFY numbers was always a legitimate internal use; the boundary
is only at publishing an IMAGE.*

🎯 **RECOMMENDED NOW: ship our own render ALONE, with Figure 6 cited in words** —
the description in this section is precise enough that a reader can look it up,
and it costs us nothing. **Ship the pair only if the Captain invokes author
reuse and supplies the figure from a personal-lane source.**

🎯 **THE CAPTION EITHER WAY, and it is the point:**
> *Left, 1990: hand-placed full-custom silicon whose architecture you can read
> off the die. Right, 2026: an auto-placed standard-cell tile whose architecture
> you cannot. The 1990 picture is legible because a person placed every column;
> ours is a jumble because a tool placed it at 15% density and had no reason to
> do otherwise. **What we can read off our die instead is a proof.***

---

## 4. What this does NOT say

* It does **not** re-open the `CLOCK_PERIOD` ruling — that is still the separate
  P5 recommendation (20 → 30), and it is still not blocking.
* It does **not** claim the fences route is exhausted. `MANUAL_GLOBAL_PLACEMENTS`
  / `FP_OBSTRUCTIONS` / `PL_SOFT_OBSTRUCTIONS` remain settable from
  `src/config.json`; the honest no is about what was *tried*, not about what is
  *possible*.
* The f_max figures are **post-PnR signoff STA at the pinned PDK**, not silicon.
  The 1990 numbers are **measured on fabricated parts**. *That asymmetry is real
  and the datasheet should keep it visible: we are comparing our simulation to
  their measurement.*

# TINYTAPEOUT TTSKY26c — THE SUBMISSION DOSSIER
### 2026-08-06, EVIDENCE seat. Every fact below was fetched from a primary
### source today and carries its URL. `[V-SRC]` = read from the source.
### `[INF]` = inference, marked as one. `[?]` = not established.
### Consumers: the SILICON seat (D5) and JYH (the clicks and the card).

> **THE DEADLINE IS EARLIER THAN "SEPTEMBER 7" SOUNDS.**
> **2026-09-07 T20:00:00 UTC — that is 13:00 PDT on Monday 7 September.**
> Not midnight, not end of day. `[V-SRC]`
> `https://app.tinytapeout.com/api/shuttles/ttsky26c` →
> `"deadline":"2026-09-07T20:00:00+00:00"`, corroborated by the homepage
> countdown markup `data-deadline="2026-09-07T20:00:00Z"`.
> **32 days from today.**

---

## 1. THE SHUTTLE — confirmed real, open, and selling

| Fact | Value | Source |
|---|---|---|
| Shuttle | **TTSKY26c**, "Tiny Tapeout SKY 26c", foundry run **CI-2609** | `tinytapeout.com/runs/` |
| Status | **OPEN** — launched 2026-05-26, closes 2026-09-07 | `tinytapeout.com/runs/` |
| Deadline instant | **2026-09-07 20:00 UTC = 13:00 PDT** | shuttle API + homepage `data-deadline` |
| PDK | **sky130A** (SkyWater 130 nm, open source) | `tinytapeout-sky-26c/config.yaml` |
| Top-level macro | `openframe_project_wrapper`; **`powered_netlists: true`** | same |
| Tiles | **512 total, 290 used, 222 free** (2026-08-06) | shuttle API / supabase REST |
| Subsidized PCBs | **80 of 80 SOLD** — the discounted devkit pool is **exhausted** | shuttle API |
| Chips expected | 2027-03-27 · estimated delivery **2027-05-12** | `tinytapeout.com/runs/` |
| Shuttle repo | `github.com/TinyTapeout/tinytapeout-sky-26c` | GitHub |

**Fallbacks if we miss it.** `TTIHP26b` closes **2026-09-21** but is a
*different PDK* (`ihp-sg13g2`, 130 nm BiCMOS) with a different wrapper
(`tt_ihp_wrapper`) and a different template — a re-harden, not a
re-submit. The next sky130 window is **TTSKY26d, December 2026**, delivery
June 2027. `[V-SRC]`

### 1.1 Price — and a warning that costs €200

Pricing is not published as a table; the site routes to a client-side
calculator. The unit rates were read out of the app's own production
bundle `[V-SRC]` and one is corroborated in prose `[V-SRC,
tinytapeout.com/specs/analog/: "each tile is 70€"]`:

| Line item | EUR |
|---|---:|
| Tile | **70** each |
| DevKit PCB, full price ("Academic/Industry") | **300** |
| DevKit PCB, subsidized ("Individual", limited) | **100** |
| Worldwide economy shipping | **15** per PCB |

- The **€185** figure in `silicon-design-v1.md` D5 is the *Individual*
  bundle: 70 + 100 + 15. `[INF, arithmetic on the above]`
- **⚠️ TTSKY26c reports 80 of 80 subsidized PCBs sold.** So the realistic
  budget is **70 + 300 + 15 = €385** for one tile + devkit + shipping, and
  **€455** for two tiles — ⚠️ SUPERSEDED: 4 tiles (2×2, €280) were bought on 2026-08-06 and the fabric needs ~12% of ONE (§3). `[INF — the calculator's
  "Individual" toggle is client-side and I could not confirm from outside
  an authenticated session whether checkout still honours it. Someone with
  a browser should open `app.tinytapeout.com/calculator` and settle it.]`
- Eligibility, verbatim: *"Early bird prices are limited per shuttle, and
  are only available to individuals."* And *"the early bird price is only
  available once per person."* `[V-SRC, FAQ]`
- The subsidized rate applies to **at most ONE PCB per order** — the
  discount flag in the invoice code is a 0/1, never a count — and it
  requires buying tile space. Two devkits as an Individual cost
  100 + 300 + 30 = €430, not €230. `[V-SRC, invoice bundle]`
- **Tiles can be prepurchased before submitting**, at
  `app.tinytapeout.com/prepurchase`, and the FAQ warns *"There are often
  no tiles available near the submission deadline."* `[V-SRC]`

> **⚠️ BOTH PRECEDING SKY130 SHUTTLES SOLD OUT COMPLETELY** — TTSKY26a and
> TTSKY26b each finished at **512 of 512 tiles used**. `[V-SRC, shuttle
> REST index]` And the 222-free figure is *more* urgent than it looks:
> **`tiles_used` counts PREPURCHASED tiles, not placed designs** — 290
> tiles are bought while only 178 tiles' worth of projects are actually
> placed `[INF, from the live index: 128 projects, tile-weighted sum 178]`.
> Reading the design gallery and concluding "the shuttle is half empty"
> is a mistake. ✅ **DONE: 4 tiles (2×2, €280) bought 2026-08-06.**

---

## 2. THE PINOUT — and why the bit-serial ruling was right

The top-level port list is **fixed, machine-checked, and identical across
TT10 and every SKY26x shuttle**. Any extra port is a hard error
(`has unsupported extra ports`). Verbatim from
`ttsky-verilog-template/src/project.v` `[V-SRC]`:

```verilog
`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
```

| Signal | Rule |
|---|---|
| `uio_oe` | **driven by us**, per bit, at runtime. **Active high: 1 = OUTPUT, 0 = input.** |
| `ena` | *"always 1 when the design is powered, so you can ignore it"* — do **not** gate logic on it. See §2.2: it is also the power-gate enable. |
| `rst_n` | **active LOW**. |
| all outputs | **must be assigned.** Unused: `assign uio_out = 0; assign uio_oe = 0;` |
| top module | must start with `tt_um_`, must not be `top`; convention `tt_um_<github_username>_<project>` |

**THE FIT, CONFIRMED FROM THE SOURCE.** An 8×8 bit-serial banyan needs 8
serial inputs, 8 serial outputs and a clock. That is `ui_in[7:0]`,
`uo_out[7:0]`, `clk` — **exactly the dedicated pins, with all 8 `uio` left
over** for frame sync, a routing-latch clear, or observability. A
word-parallel 8×8 fabric would need 64+ data pins and cannot be built
here at any price. **JYH's bit-serial ruling (Council I, 8/6) is not
merely defensible — the pinout admits nothing else.** `[V-SRC on the pins;
the design consequence is ours]`

### 2.1 The clock ceiling that constrains a serial design

| Fact | Value | Source |
|---|---|---|
| Clock source | external, into `mprj_io[6]` (QFN-64 pin 37); demo board generates it from the RP2040 PWM/PIO | `specs/clock/` |
| Demo-board range | 1 Hz – 66.5 MHz, and `tt.clock_project_PWM(0)` **stops the clock** | `guides/get-started-demoboard/` |
| Pad max **input** | **66 MHz** | `specs/gpio/` |
| Pad max **output** | **33 MHz** ⚠️ | `specs/gpio/` |
| Clock insertion delay | up to **10 ns**, pad → project logic | `specs/clock/` |
| Template default | `CLOCK_PERIOD: 20` ns → **50 MHz** STA target | `src/config.json` |

> **⚠️ THE ASYMMETRY IS OURS TO ABSORB.** In a bit-serial fabric the output
> pins toggle *every cycle*. The pad's maximum **output** frequency is
> **33 MHz**, half the input ceiling. Running the design at the template's
> default 50 MHz would drive the serial outputs past the pad's rating.
> **Either clock the fabric at ≤ 33 MHz, or state the ceiling explicitly in
> the datasheet.** The 1 Hz–66.5 MHz demo-board range means single-stepping
> the fabric for a demo is trivial, which is the better exhibit anyway.

**`clock_hz` in `info.yaml` is documentation, not a constraint** — it is
consumed only by the datasheet renderer (`DocsHelper.pretty_clock`). It
must nonetheless be an **integer** (`clock_hz: 33000000`); a YAML float
like `33e6` fails validation. `[V-SRC]`

### 2.2 ⚠️ UNSELECTED DESIGNS ARE POWER-GATED OFF — no state survives

In `tt-multiplexer/rtl/tt_mux.v` the same internal `l_ena` drives **both**
the user module's `ena` port **and** its power-gate enable (`um_ena[i]` and
`um_pg_ena[i]` are two buffers off the same signal); the sky130 config
names the gate cells `tt_pg_1v8`. `[V-SRC]`

> **Consequence for a sequential design, and it is load-bearing for the
> bit-serial fabric:** a deselected design is *powered down*, not merely
> held in reset. **No flop state survives deselection.** The design must
> come up correctly from an arbitrary power-on state once selected, and
> there is no "keep running in the background" behaviour to rely on.
> Combined with the fact that **`/specs/powerup/` does not exist** and the
> minimum reset assertion width is undocumented (§9), the rule for us is:
> **the switch-element FSM must self-initialise from any state, on a reset
> pulse of unspecified length.** That belongs in the D3.5 refinement
> proof's hypotheses, not in a comment.

**Also undocumented, and relevant to a serial design:** no TinyTapeout page
states a rule about **gated clocks, clock dividers or internally derived
clocks**. `/hdl/important/` covers naming and Yosys optimisation;
`/specs/clock/` covers source and frequency; the only clock-structure rule
found anywhere is that a second GPIO clock must run at the same frequency.
`tt-support-tools` injects no clock-structure checker beyond
`CLOCK_PORT: "clk"`. **A ripple counter or an internally divided clock is
neither blessed nor forbidden** — if the fabric needs one, it is
unreviewed territory and should be avoided in favour of a clock enable.

---

## 3. AREA — how many tiles, and what fits

**Authoritative tile geometry** is `tt-support-tools/tech/sky130A/tile_sizes.yaml`,
not the template comment (which says "about 167x108 uM") and not the FAQ
(which still says "about 160x100 um … for TT04 to TT10"). `[V-SRC]`

| tiles | die area (µm) | € |
|---|---|---:|
| `1x1` | 161.00 × 111.52 | 70 |
| **`1x2`** | **161.00 × 225.76** | **140** |
| `2x2` | 334.88 × 225.76 | 280 |
| `3x2` | 508.76 × 225.76 | 420 |
| `4x2` | 682.64 × 225.76 | 560 |
| `6x2` | 1030.40 × 225.76 | 840 |
| `8x2` | 1378.16 × 225.76 | 1120 |

Also valid but omitted from the template comment: `3x4`, `4x4`, `5x4`,
`6x4`, `8x4` (max footprint 8x4 = 32 tiles = €2,240). The validator accepts
any key of `tile_sizes.yaml`. `[V-SRC]` The grammar's real source is the
placer, which hard-validates **height ∈ {1, 2, 4}** and **width ∈ 1…8**
(`grid.x // 2`). The 512-tile figure is likewise derivable: `grid x:16,
y:32` over a die of **3.167 × 4.767 mm**. `[V-SRC, tt-multiplexer
cfg/sky130.yaml + py/tt/placer.py]`

**4-tile-high designs are a scarce, pre-allocated resource** — TTSKY26c's
`mux_overrides.yaml` reserves exactly two mux units for them
(`huge_modules: mux_id: [3, 19]`) and the placer will only place a
height > 2 module facing a masked mux. Nothing on tinytapeout.com says
this. Irrelevant to us at 1x2, but it means "just buy more tiles" has a
ceiling that is not the price. `[V-SRC]`

**Capacity per 1x1 tile** `[V-SRC]`:
- *"about 1000 digital logic gates, depending on their size"* (FAQ)
- *"about 320 DFFs (40 bytes of memory)"* (`specs/memory/`) — **this is the
  number that matters for a bit-serial design**, which is flop-heavy and
  logic-light.
- a latch-based design has fitted 512 bits in one tile at 88% utilisation;
  an experimental register file reached 1200 bits/tile.

> **⚠️ THE 1299-GATE FIGURE IN OUR DOSSIERS IS FOR THE WORD-PARALLEL
> FABRIC.** The bit-serial fabric is a different circuit: 12 2×2 switch
> elements (three stages of four), each a small FSM with a routing latch,
> plus framing. It should be *smaller* in combinational logic and *larger*
> in flops. **Silicon seat: re-measure after the first synthesis run and
> size the tile purchase from that, not from 1299.** Tile size may be
> experimented with for free — you only need to have *bought* the tiles to
> submit. `[V-SRC, FAQ]`

> **⚠️ REAL DATA ARRIVED IN TWO PARTS AND THE SECOND PART REVERSES MY
> FIRST READING. Both are recorded.**
>
> **Part 1 (compiler seat, 10:35)** — three genuine TTSKY26c submissions on
> this machine carry **4,220 / 4,645 / 5,344 cell instances** each. Against
> the FAQ's ~1,000 gates per tile, *a typical real submission is a 4–5 tile
> design*. **I concluded from this that the 2×2 purchase was correctly
> sized and that €280 was not over-buying.**
>
> **Part 2 (silicon seat, 12:31) — and it makes that conclusion wrong for
> OUR design.** The fixed bit-serial switch element costs 18 cells /
> 172.67 µm² (up from 8 / 95.09 after the activity-bit fix), and **the whole
> fabric measures ~216 cells / ~2,072 µm² — about 12% of ONE tile, against
> the four bought.**
>
> **The honest statement, replacing mine:** other people's submissions are
> 4–5 tiles; *ours is a twelfth of one*. The 2×2 purchase is therefore
> **generous rather than necessary** — it buys headroom for the RISC-V
> datapath stretch, a larger fabric, or a second exhibit on the same tile
> budget. It was not wrong to buy, and it was **not** justified by the
> reasoning I gave at 11:30. A number measured on other people's artifacts
> did not transfer to ours, and I published the transfer before anyone
> measured ours.

**Area failure is the most common failure mode**, and its symptoms are
named: *"placement failures; routing congestion; high utilization
warnings; 'Detailed placement failed'; unusually long GDS action
runtimes."* A typical small design's GDS action takes **~5 minutes**;
20–25 minutes is the signal that you are out of area. `[V-SRC, FAQ]`

---

## 4. THE TEMPLATE REPO — exact shape

**Repo: `github.com/TinyTapeout/ttsky-verilog-template`** (Apache-2.0,
`is_template: true`). There is **no per-shuttle template**; the same repo
is re-tagged. Its `main` HEAD (`60c3939`, 2026-05-26, *"chore: update tags
for TTSKY26c"*) already points every workflow at `@ttsky26c` — **nothing
needs switching.** `[V-SRC]`

```
.devcontainer/{Dockerfile,copy_tt_support_tools.sh,devcontainer.json}
.github/workflows/{docs.yaml,fpga.yaml,gds.yaml,test.yaml}
.vscode/{extensions.json,settings.json}
LICENSE            ← Apache-2.0, shipped inside the submission artifact
README.md
docs/info.md       ← the datasheet body (MUST be edited)
info.yaml          ← the manifest (MUST be edited)
src/project.v      ← our design
src/config.json    ← the LibreLane hardening config
test/{Makefile,README.md,requirements.txt,tb.gtkw,tb.v,test.py}
```
22 files, 6 directories, **no submodules**. `[V-SRC]`

### 4.1 `info.yaml` — the validator, not the comments

Schema authority is `tt-support-tools/project_info.py`, `yaml_version: 6`
(any other value is a hard error). `[V-SRC]`

| Key | Rule |
|---|---|
| `title`, `author`, `description`, `language` | non-empty |
| `clock_hz` | **must be a Python `int`** — `50e6` fails |
| `tiles` | must be a key of `tech/sky130A/tile_sizes.yaml` |
| `top_module` | **must start with `tt_um_`** |
| `source_files` | list, non-empty, **all under `./src`, one per line, NO wildcards** (`* not allowed, please specify each file`) |
| `pinout.ui[0..7]`, `uo[0..7]`, `uio[0..7]` | **all 24 keys mandatory** (may be empty strings), **and at least one must be non-empty** or the docs check fails |
| any other key under `pinout` | rejected |
| `discord` | optional |
| `analog_pins` | int 0–6, default 0 (digital template has no analog) |

**Foot-gun:** `source_files` in `info.yaml` and `PROJECT_SOURCES` in
`test/Makefile` must be kept in sync by hand. `[V-SRC]`

### 4.2 `docs/info.md` — checked by exact substring

The docs check does **not** look for sections; it looks for the *unedited
template text*. Leaving either placeholder in place is a failure `[V-SRC]`:

> ⚠️ **FOOT-GUN, MEASURED BY THE SILICON SEAT ON THEIR OWN FILE (15:26):
> THE GATE IS A SUBSTRING GREP OVER THE WHOLE FILE, so a comment that
> *quotes* the placeholder in order to warn a future editor REPRODUCES the
> text that fails the gate.** They wrote exactly such a warning, tripped
> their own check, and caught it. **An instrument that describes the
> failure it is preventing can commit it.**
>
> **This dossier quotes the two strings immediately below**, which is safe
> *here* — this file is not `docs/info.md` — but **do not copy this section
> into a project's `docs/info.md`, and do not paste these lines into a
> comment there.** Warn without quoting.

- contains `"# How it works\n\nExplain how your project works"` → **fail**
- contains `"# How to test\n\nExplain how to use your project"` → **fail**
- file missing → **fail**

`## External hardware` is **not** checked `[INF]`. The file is spliced into
the shuttle datasheet at the `{{&user_docs}}` slot, which already supplies
title, author, description, GitHub link, mux address, clock and an
auto-generated pinout table — **so `info.md` must start at `##` and must
not restate any of those.** Images: each < 512 kB, all < 1 MB. `[V-SRC]`

### 4.3 `test/` — cocotb, and it is not optional for us

`SIM ?= icarus`, `TOPLEVEL = tb`, `COCOTB_TEST_MODULES = test`,
`cocotb==2.0.1` + `pytest==8.4.2` pinned. **cocotb 2.x API** — `Clock(dut.clk,
10, unit="us")`; 1.x's `units=` will not run. `test/tb.v` hardcodes
`tt_um_example` and **must be hand-edited** to our top module. `[V-SRC]`

**`GATES=yes make` runs the same testbench against the post-layout
netlist**, and the GDS workflow does this automatically in its `gl_test`
job: *"Whenever the GDS action is triggered, your testbench will be run as
a Gate Level test automatically!"* Because `powered_netlists: true` for
this shuttle, the netlist used is the **powered** one
(`runs/wokwi/final/pnl/$TOP.pnl.v`), not the unpowered `nl/`. `[V-SRC]`

---

## 5. THE FLOW AND THE GATES

**The EDA flow is LibreLane (OpenLane 2 renamed), pinned by pip:**
`librelane==3.0.5` in CI. **The devcontainer pins `librelane==2.4.2`** —
local and CI hardening are *not* the same major version out of the box.
`[V-SRC — flag this to the Silicon seat, it is exactly the kind of skew
that produces a netlist mismatch]`

The `gds` workflow runs four jobs — `gds`, then `precheck`, `gl_test` and
`viewer` (all `needs: gds`). Pipeline inside `gds` `[V-SRC]`:
`tt_tool.py --create-user-config` → `pip install librelane==3.0.5` →
`tt_tool.py --harden` → verilator lint summary → Yosys warnings → routing
stats → cell categories → `--create-tt-submission` → `--create-png`.

### 5.1 What gates, exactly

| Gate | Rule |
|---|---|
| **GDS action** | *"A project can't be submitted to a shuttle if its GDS action is failing."* **Blocking.** |
| **Precheck** | *"All the checks need to be green to submit to the chip."* **Blocking.** |
| **`gl_test`** | a job *inside* the gds workflow → a gate-level test failure reddens the gds workflow → **effectively blocking** `[INF from workflow topology; TT does not say it in prose]` |
| **Docs action** | **non-blocking** — but *"your project information will not be included onto the shuttle datasheet."* |
| **RTL `test` workflow** | separate workflow → **non-blocking** |
| **FPGA workflow** | disabled by default (`branches: none`) → **non-blocking** |

**Precheck test list for sky130A**, verbatim `[V-SRC]`: Magic DRC ·
KLayout FEOL · KLayout BEOL · KLayout offgrid · KLayout pin label
overlapping drawing · KLayout zero area · KLayout Checks · Pin check ·
Boundary check · Power pin check · Layer check · Cell name check ·
urpm/nwell check · Analog pin check · Verilog syntax check.
**No antenna check** (gf180 only — sky130 antennas are handled in-flow by
diode insertion) and **no LVS in the precheck** (LVS runs inside the
LibreLane Classic flow: `Magic.SpiceExtraction → Netgen.LVS →
Checker.LVS`). `[V-SRC]`

**LibreLane checkers that hard-fail by default** include
`YosysSynthChecks` (**combinational loops and undriven wires — immediate
quit**), `LintErrors`, `LintTimingConstructs`, `YosysUnmappedCells`,
`NetlistAssignStatements`, `TrDRC`, `DisconnectedPins`, `MagicDRC`,
`KLayoutDRC`, `IllegalOverlap`, **`LVS`**, `SetupViolations`,
`HoldViolations`. Lint *warnings* do not fail
(`ERROR_ON_LINTER_WARNINGS = False`). **Hold violations are checked on all
corners; setup only on typical** (`TIMING_VIOLATION_CORNERS = ["*tt*"]`).
`[V-SRC]`

### 5.2 Hard design rules

- **No `met5`.** Precheck hard-fails on `met5.drawing/pin/label`; TT's power
  grid owns that layer. Routing is capped at `RT_MAX_LAYER = met4`.
- **No `initial` statements.** *"flops will have a random initial value at
  power on … you must use an explicit reset."*
- **Every output assigned**; no floating digital outputs.
- **Top cell name must equal `top_module`**; cell names may not contain
  `#` or `/`.
- **Power pins**: `VGND` and `VDPWR`/`VPWR` must appear in both the netlist
  and the LEF, with `USE POWER ;` / `USE GROUND ;` in the LEF.
- **Yosys will delete what you don't use**: *"If you make a 32 bit register
  but only use the first 2 bits, Yosys will throw out the top 30 bits."*
  The sanity check TT gives: if the cell count is *"half as much as you
  expect or less"*, investigate; *"if you have only 8 cells, your design is
  probably completely optimised out."*
- **Latches are allowed** (TT documents latch-based memory as an area win),
  and **hardened macros are allowed** on sky130 (DFFRAM `RAM32`, 401×136 µm,
  fits 3x2). Neither is needed by our fabric.
- The three sanctioned `config.json` knobs: `PL_TARGET_DENSITY_PCT` (60,
  *"up to 80 worked well"*; the FAQ separately says 62 — they disagree),
  `CLOCK_PERIOD` (20 ns), and the two hold-slack margins. **Everything
  below the "DO NOT CHANGE ANYTHING BELOW THIS POINT" banner is fixed.**
  `[V-SRC]`
- **⚠️ `src/user_config.json` OVERRIDES `src/config.json`.**
  `create_merged_config` does `config = read_config("src/config");
  config.update(user_config)` — user_config is applied **last**. So
  `DESIGN_NAME`, `VERILOG_FILES`, `DIE_AREA`, `FP_DEF_TEMPLATE`,
  `VDD_PIN`, `GND_PIN` and `RT_MAX_LAYER` **cannot be overridden from
  `config.json`; edits there are silently discarded.** If a flow
  experiment appears to have no effect, this is why. `[V-SRC]`
- Other sky130A constants a submitter may need: `def_suffix = "pg"` (so
  the template DEF is `tt_block_<tiles>_pg.def`), signoff corner
  `nom_tt_025C_1v80`, `netlist_type = "pnl"`, prBoundary layer (235,4).
  `[V-SRC, tt-support-tools/tech.py]`

---

## 6. ⚠️ THE FINDING THAT CHANGES OUR PROOF ARCHITECTURE

**The netlist that gets fabricated is produced by TinyTapeout's CI, not by
our LibreLane run.** The `gds` job runs `librelane==3.0.5` against a
PDK pinned at `0536d02d875c8f67dd7cca3902ac457e62f20005` (**precheck
only** — the hardening revision is `8afc8346…`, see §6.4), and emits a
`tt_submission` artifact containing:

```
<top_module>.oas   <top_module>.gds   <top_module>.lef
<top_module>.v     ← THE GATE-LEVEL NETLIST
pdk.json  resolved.json  commit_id.json  *.spef  stats/metrics.csv
```

Both `precheck` and `gl_test` consume **that artifact**, and the shuttle
repo re-runs `precheck.py` on the submitted `.oas` a second time when the
project lands. `[V-SRC]`

**Consequences for leg 3, in order of importance:**

1. **The equivalence proof must be against `tt_submission/<top>.v`** — the
   artifact TT actually submits — not against a locally-produced
   `runs/RUN_*/final/nl/<design>.logical_nl.v`. `silicon-design-v1.md`'s D1
   line names the local path; **for the tapeout it should name the CI
   artifact.** Proving the local netlist and shipping the CI netlist would
   be a *seam we left open*, and the seam doctrine is the entire campaign.
2. **The netlist is POWERED** (`powered_netlists: true`, `pnl` not `nl`).
   Every cell instance carries power ports. **The importer must accept and
   discard them** — and **by pin name, asserting nothing about arity**:
   the Silicon seat's addendum found `sky130_fd_sc_hd__tapvpwrvgnd_1`
   carries exactly **two** (`.VGND`, `.VPWR`), appears 225–456 times in
   every real TT netlist, and **is not in Liberty at all**, so
   "absent from Liberty ⇒ error" is also wrong. 23 of 428 cells break the
   4-pin rule.
   - **⚠️ "~30 cell models" is a MEDIAN, not a bound.** Measured across
     three real TTSKY26c submissions: **15 / 13 / 68 distinct cell types**.
     One real submission needs **68**. Plan for the tail. `[compiler seat,
     10:35, on real artifacts]`
   - **⚠️ AND POST-P&R CONTAINS CELLS SYNTHESIS NEVER EMITS:** `clkbuf_*`
     from CTS, `clkdlybuf4s25_1` / `dlygate4sd3_1` from hold repair,
     `diode_2` for antennas. A cell list derived from synthesis output —
     or from Liberty — will miss them.
   - **⚠️ Both flop types appear**: `dfrtp` 36/0/164 and `dfxtp` 0/3/156
     across the same three submissions. **Model both**; it is
     design-dependent.

2b. **⚠️ THE FLOW FLATTENS — AND THIS BREAKS THE STATED PROOF PLAN.**
   Measured on those same three real submissions: **exactly 1 `module` and
   1 `endmodule` each.** Post-place-and-route, there is no hierarchy left.
   So *"equivalence per module by `decide +kernel`"* — the phrase in
   `silicon-design-v1.md` and in my own README draft (NOT in this dossier —
   an earlier version of this note cited a §1 chain diagram that has never
   existed here; §1 is the shuttle table) — **has no modules left to be "per"**. The
   decomposition into checkable pieces has to be stated some other way,
   and **it is stated nowhere in either freeze.** This is not a detail: the
   whole equivalence strategy rests on decomposing a design that the tools
   hand back as one flat block. `[compiler seat, 10:35, measured; flagged
   here because this dossier repeated the claim]`
3. **`tools-ref` defaults to `main`, and `main` is moving under us.**
   `tt-support-tools` has no `ttsky26c` tag and no tags at all; its `main`
   HEAD moved **today** (`8bca34a`, 2026-08-06 17:09 +02:00, *"fix(tt_tool):
   allow hardening in git repos without a remote"*), while the shuttle repo
   pins its `tt` submodule at `ff75e34` (2026-07-29). **Our CI and the
   shuttle build are not running the same tools revision.** For a
   reproducible claim, pin `tools-ref` to a commit SHA in the workflow
   `with:` block and record the SHA beside the proof. `[V-SRC]`
4. **Version skew is real, and there are FOUR sky130A PDK revisions in
   play.** ⚠️ **CORRECTED 2026-08-06 10:47 — I published the wrong one to
   pin against, and the Silicon seat caught it** (refuter addendum
   026f27f, refutation 4):
   - `0536d02d875c8f67dd7cca3902ac457e62f20005` — **PRECHECK ONLY.** This
     is what the precheck action installs. I originally told the fleet to
     pin the local flow to it "to reproduce the CI netlist". **That is
     wrong.** The precheck inspects a GDS; it does not build one.
   - **`8afc8346a57fe1ab7934ba5a6056ea8b43078e71` — the one that matters.**
     The netlist and GDS are hardened against this revision (with
     `LIBRELANE_TAG 3.0.0.dev38`). **This is what a local flow must pin to
     stand a chance of reproducing the artifact that ships.**
   - `6d4d11780c40b20ee63cc98e645307a9bf2b2ab8` — the shuttle's own
     `BUILDING.md` tells a human builder to use this. **Stale.**
   - plus whatever the `ciel-action` resolves for a given run.

   LibreLane likewise: CI `3.0.5`, devcontainer `2.4.2`. **The lesson
   generalises: "pinned" is not one fact.** A flow can pin different
   revisions at check time and at build time, and the one you must match is
   whichever produced the bytes you intend to prove things about. `[V-SRC,
   corrected]`
5. **A gate-level cocotb testbench is mandatory work**, not a nice-to-have
   — and it is a *gift*: it is a second, independent check of the very
   netlist we are proving equivalent, in a different tool, by a different
   method. Say so in the README. That is differential testing arriving for
   free, and the Cedar result (4 bugs from proofs, 21 from differential
   testing) says it will earn its keep.

---

## 7. THE CHECKLIST — what we prepare vs what the human clicks

### 7.1 Prepared by the fleet (no account, no card)

| # | Item | Owner |
|---|---|---|
| P1 | `src/tt_um_<user>_<project>.v` — the fabric wrapped in the fixed TT port list, `default_nettype none`, unused-input sink, all outputs assigned | Silicon (from HDL's `emitV`) |
| P2 | `info.yaml` — title, author, description, `language: Verilog`, `clock_hz` (**int**, ≤ 33 MHz per §2.1), `tiles`, `top_module`, `source_files` (explicit), all 24 pinout descriptions | Evidence drafts, Silicon confirms |
| P3 | `docs/info.md` — How it works / How to test **rewritten** (substring check), the proof story, the 1988 correspondence | Evidence |
| P4 | `test/tb.v` (rename `tt_um_example`), `test/Makefile` `PROJECT_SOURCES`, `test/test.py` — a real cocotb bench that **passes at gate level** | Silicon |
| P5 | `src/config.json` — `CLOCK_PERIOD` for our target; `PL_TARGET_DENSITY_PCT` only if placement fails | Silicon |
| P6 | Apache-2.0 `LICENSE` retained, copyright header updated in every source file | Silicon |
| P7 | Local dry run: LibreLane 3.0.5 + PDK **`8afc8346…`** (the *hardening* revision — NOT the precheck-only `0536d02d…`; see §6.4), then `tt-support-tools` precheck locally per `guides/local-hardening/` | Silicon |
| P8 | Pin `tools-ref` to a SHA in `.github/workflows/gds.yaml`; record it beside the equivalence proof | Silicon |

### 7.2 The human's clicks — JYH only, in order

| # | Action | Where | Blocking? |
|---|---|---|---|
| H1 | ~~Buy the tiles~~ ✅ **DONE 2026-08-06 — 4 tiles (2×2), €280.** | `app.tinytapeout.com/prepurchase` | closed |
| H2 | Create the repo from the template: **"Use this template" → "Create a new repository"** | `github.com/TinyTapeout/ttsky-verilog-template` | yes |
| H3 | **Enable Actions**: Actions tab → "enable actions" | the new repo | yes |
| H4 | **Enable Pages**: Settings → Pages → Source: *Deploy from a branch* → **GitHub Actions** | the new repo | yes (else `viewer` fails) |
| H5 | Sign in with **GitHub OAuth** (the only login method) | `app.tinytapeout.com/projects/create` | yes |
| H6 | "Create a new project" → paste the repo URL → "Create Project" | same | yes |
| H7 | **Pay by card** (Stripe) — this accepts the Terms | same | yes |
| H8 | **⚠️ PRESS "Submit a new revision".** *"You have now submitted your design, but it's not yet part of the tapeout."* Paying is **not** submitting. | same | **yes — the classic miss** |
| H9 | Later: supply a shipping address after fabrication | email | no |

Revisions may be resubmitted freely until the deadline; *"No new revisions
will be accepted after the closing date."* The backing repo can even be
swapped afterwards ("Change" → new URL), provided it is template-based and
its GDS action passes. `[V-SRC]`

### 7.3 What JYH is agreeing to (Terms, last updated 2026-02-11)

- **Apache-2.0 or compatible is MANDATORY** (§4.1) — the design *and* the
  design documentation.
- **Publication is MANDATORY** (§1.3): the design "will be supplied to
  other participants" and "will be published and made publicly available on
  the Website, Tiny Tapeout GitHub pages and other promotional materials."
  Tiny Tapeout Ltd owns the *combined* design; we retain rights to ours.
- **The repo must effectively be public** `[INF` — no page says it in
  words; but Pages on free plans requires public, `tt-support-tools`
  fetches sources anonymously, and §1.3 compels publication`]`.
- **Export control** (§6): EAR / OFAC / ITAR representations, and a
  sanctioned-country list.
- **TT may refuse any design at its sole discretion**; the remedy is a
  voucher for a future run, not a refund. Fees are otherwise
  non-refundable.
- Contracting entity **Tiny Tapeout Ltd.**, **governed by the laws of the
  State of Israel**, exclusive jurisdiction Tel Aviv.
- Attribution: *"You must not simply fork a project and update the
  attribution to your name."* Update the copyright headers honestly.

> **A ruling is owed here** (campaign §4.2, "rule the public repo + name
> when the design arrives"): the TT repo is public, Apache-2.0, and
> permanent. It is a *separate* repo from saltworks. The Lean proofs may
> stay wherever the Captain rules, but the Verilog and the datasheet go
> out under Apache-2.0 with his name on them.

---

## 8. THE TIMELINE — 32 days, and the two dates that matter

| When | What | Why then |
|---|---|---|
| **now (Aug 6–8)** | **H1: buy 2 tiles** (€140) and decide the devkit question (§1.1) | 222 of 512 left; *"often no tiles available near the deadline"* |
| Aug 6–8 | H2–H4: repo + Actions + Pages, with the stock template unmodified | proves the pipeline green before our design exists |
| Aug 8 | first GDS action on the **stock** template | a known-good baseline; ~5 min |
| week 1–2 | P1–P6 as the fabric lands (D3.5 bit-serial FSM → `emitV` → wrapper) | |
| week 2 | P7 local dry run; first real GDS + precheck + gl_test green | area/timing surprises surface here, not in September |
| **by Aug 31** | **H5–H8: submit a real revision** | one clear week of slack before the deadline |
| **2026-09-07 13:00 PDT** | **HARD DEADLINE (20:00 UTC)** | no revisions after |
| 2027-03-27 | chips expected | |
| 2027-05-12 | estimated delivery | |

**Recommendation: submit something real by August 31.** A submitted
revision can be replaced any number of times before the deadline, so there
is no cost to submitting early and every cost to submitting late. The
campaign window closes ~Aug 19 anyway — the tapeout should be *inside* the
campaign, not after it.

---

## 9. WHAT I COULD NOT ESTABLISH — stated, not papered over

1. **Whether the €185 individual price is still obtainable.** The €185 and
   €385 figures are now *arithmetically confirmed* against the invoice
   code — but the discount is computed from a **client-side boolean with no
   inventory check anywhere in the pricing path**, and the 80 subsidized
   PCBs are sold. Any gate lives in an authenticated server route.
   **Budget €385 and be pleased if it is less.**
2. **The power-up / reset-sequencing spec.** `tinytapeout.com/specs/powerup/`
   **404s** — the page does not exist. What is now confirmed is *stronger*
   than "held in reset": unselected designs are **power-gated off** (§2.2),
   so no state survives. Still unknown: the pad-level power-up state of the
   `uio` pins and the **minimum reset assertion width**. Our design must
   self-initialise from any state on a reset pulse of unspecified length.
3. **Whether the submission app enforces per-job or per-workflow status.**
   The prose rules and the workflow topology agree that `gl_test` and
   `precheck` failures block, but the app is a SPA and the enforcement
   mechanism is unverified. Treat "gate-level tests gate" as `[INF]`.
4. **How many 4-tile-high and analog slots remain.** The reservations are
   known (`huge_modules: mux_id [3, 19]`; analog `mux_id [11, 12]`, one
   fewer analog row than TTSKY26b had) but the placer's site-suitability
   rule is geometric and was not simulated. Irrelevant to us at 1x2.
5. **VAT treatment** of the invoice — *definitively absent* from the
   pricing code rather than merely unfound: the invoice bundle is 1,982
   bytes and contains no `vat`, `tax` or `reverse charge`. Whether €385 is
   VAT-inclusive is not answerable from TinyTapeout's own surfaces.
6. **The price citation is inherently fragile.** `invoice-*.js` and
   `calculator-*.js` are content-hashed build assets; the filenames change
   on the next deploy. **Every price here is verified-as-of-2026-08-06
   only.** (Closed since the first draft: `maxAnalogPins: 0` is **dead
   code** — analog *is* available on sky130, and six analog projects are
   already placed on TTSKY26c. Irrelevant to us; corrected so the earlier
   caution is not carried forward.)
7. **Stale documentation hazard:** the FAQ still refers to `config.tcl` and
   OpenLane in several places. The current SKY template ships
   `src/config.json` and runs LibreLane. **Do not follow `config.tcl`
   instructions for TTSKY26c.** The multi-clock recipe in the FAQ is pinned
   to "OpenLane tag 2023.11.23" and is explicitly stale.

---

## 10. THE FIVE SENTENCES THE SILICON SEAT SHOULD ACT ON TODAY

1. **The deadline is 13:00 PDT on 7 September, not midnight.** 32 days.
2. **Buy the tiles before the design is ready** — 222 of 512 remain, both
   preceding sky130 shuttles finished at 512/512, and `tiles_used` counts
   *prepurchased* tiles, so the gallery understates how full it is.
3. **Prove equivalence against `tt_submission/<top>.v` from TT's own CI**,
   which is a **powered** netlist (`VPWR`/`VGND` on every cell) built by
   `librelane==3.0.5` against PDK **`8afc8346…`** (the hardening revision;
   `0536d02d…` is precheck-only — §6.4). Pin the local flow to match,
   and pin `tools-ref` to a SHA.
4. **The pad's maximum output frequency is 33 MHz**, half its input
   ceiling — and a bit-serial fabric toggles its outputs every cycle.
5. **The gate-level cocotb testbench is mandatory and is a gift**: an
   independent check of the same netlist we are proving, in a different
   tool. Write it as such and say so in the README.

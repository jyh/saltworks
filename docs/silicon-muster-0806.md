# SILICON — MUSTER, 2026-08-06 night shift

### Results-first, per the maestro's format. Every SHA below was resolved with
### `git cat-file -t` and its subject read back; every interval was computed.

## 1. WHAT LANDED

**THE HEADLINE: TinyTapeout's submission gate is open.**
`github.com/jyh/tt-verified-banyan-switch` @ **`f14a4fa`** — public, and **all
four `gds` jobs green ON HEAD** (run `31140274735`, whose own `headSha` was
checked against `main`, both directions):

| job | | what it certifies |
|---|---|---|
| `gds` | ✅ | hardens on the 2×2 tile, sky130A |
| `precheck` | ✅ | **blocking** — DRC, pin/boundary/power/layer/cell-name |
| `gl_test` | ✅ | the 255-scenario bench against the **POWERED post-layout netlist** |
| `viewer` | ✅ | Pages, live at `jyh.github.io/tt-verified-banyan-switch` |

**RULING 4a CLOSED — YES**, on the fabricated artifact, not a local proxy
(`de689b8`). Two CI arms one line apart; tooling equality checked first
(`pdk.json` byte-identical, `resolved.json` zero differing keys):

| arm | cut at the kept boundaries | max cone inputs | ≤ 24 bits |
|---|---|---|---|
| `(* keep *)` | yes | **21** | **100.0 %** |
| control | the nets do not exist | 36 | 87.5 % |

16 boundary nets survive in the treatment arm, all driven by real cells; **0** in
the control.

**SIGNOFF STA**, post-P&R, from TT's own CI: **`f_max` 89.1 MHz slow corner /
102.1 MHz typical**; **zero setup and zero hold violations on all nine corners**,
worst hold **+0.11 ns**. The fabric is bit-serial, so that is **89 Mbit/s per
link** — against the 1990 original's **measured 170 Mb/s/link** and this chip's
**25 Mb/s demo rate, which is a PAD limit and not a core limit.** Three numbers,
three claims, none substituting for another (`248f725`).

**D4 CHUNKED** (`27d8867`): 18.2 → 13.9 GiB peak, statement byte-identical, still
`[1 axioms]`, decomposition by **core** lemmas so leg 2's seam stays Mathlib-free.
**Silicon leg re-derived on this machine, 9/9 `Built` not `Replayed`.**

**PDK-REVISION WORRY CLOSED BY MEASUREMENT** (`aa40fcc`): the precheck and
hardening revisions differ in **4,868 files**, of which **893 are in
`sky130_fd_sc_hd`** — and **all 893 are `mag/`, `maglef/`, `gds/`, `spice/`.
Zero in `lib/` or `verilog/`.** Our 13 cell models are unaffected.

**AUDIT COVERAGE** (`2f302c0`): 31/41 → **41/41** Silicon theorems named in an
audit line. Coverage was never actually broken — `collectAxioms` is transitive —
but it depended on call sites, and a call site is something a refactor deletes.

Also: `8ebedf4` D5 tree · `ff8e17d` keep A/B local · `7f56714` gate level ·
`c91faf3` mutation independence · `e1a1a3b` the config repair · `f4ebd20`
`stage_map.py` · `2723c40` E1 · `325e255` public README repair.

## 2. HONEST NEGATIVES, WITH MECHANISM

**THE COLUMN-LAYOUT PICTURE DID NOT WORK, AND THE REASON IS STRUCTURAL.**
Obstructions were *accepted* by the flow — `gds`/`precheck`/`gl_test` all passed
— so this is not "fences fight TT's hardening". They simply do not group:

```
              BEFORE            AFTER (two channels)
  stage 0   112.7–180.8 um     70.8–150.9 um
  stage 1   114.1–174.8 um     67.6–106.3 um
  stage 2    63.5–107.2 um     24.4– 90.2 um
```

Before: two countable stripes. After: **one**. The obstruction cut through the
logic and the placer moved everything left of it. ⇒ **Geometry cannot produce
stage columns, because nothing ties a stage to a region.** Grouping needs
instance names; **flattening renames every instance to `_170_`**; and the two
name-based levers are independently closed — TT owns `FP_DEF_TEMPLATE`, and
`MANUAL_GLOBAL_PLACEMENTS` keys on the same dead names.

**MY OWN FIRST CI RUN FAILED, AND THE CAUSE WAS MINE** (`e1a1a3b`). `src/config.json`
shipped **two** keys where TT's ships **eighteen**; the sixteen I dropped included
`FP_SIZING: "absolute"`, so `DIE_AREA` stopped being authoritative and `ena`
landed 61 µm outside the die. **My validator passed it** — its config check was a
whitelist, which bounds a key set from above and is structurally blind to
deletion. Fixed, with a mutation that deletes `FP_SIZING` alone: **11/11**.

**E1 REFUTED A CLAIM OF MINE THAT WAS ALREADY IN THE README** (`2723c40`).
`#audit_axioms` is **sound**: six deliberately-broken theorems produced six hard
errors and the control ticked. My 14:04 claim was false and evidence pulled it.

**AND THE COLUMN PICTURE IS NOT REACHABLE AT ALL — CLOSED TONIGHT, NOT DEFERRED.**
`SYNTH_HIERARCHY_MODE: "keep"` (run `31140850077`) dies at **step 7 of 70+**,
before floorplanning:

```
06-yosys-synthesis   netlist retains:  bitserial_switch e00 ( … e01, e02, e03
07-checker-yosysunmappedcells   "1 Unmapped Yosys instances found."   -> gds FAILS
```

⇒ **The property that would enable the picture is the property the checker
rejects.** Columns need grouping → grouping needs instance names → names need
retained hierarchy → **retained hierarchy IS an unmapped instance** →
`YosysUnmappedCells` is a hard-fail default. **The two requirements are
contradictory in this flow**, and all four levers are now closed on measurement:
DEF fences (TT owns `FP_DEF_TEMPLATE`), `MANUAL_GLOBAL_PLACEMENTS` (dead names),
`FP_OBSTRUCTIONS` (measured: does not group), `SYNTH_HIERARCHY_MODE` (measured:
hard-fails).

**The 1990 die is legible because it was full-custom — the designer placed those
columns. TinyTapeout's proposition is that you do not, and the same automation
that makes a €280 tile possible is what forbids the image.** What exists instead:
`stage_map.py` renders the *real* placement coloured by stage from the shipped
netlist and DEF. It shows two stripes, not three, because that is what is there.

## 3. IN FLIGHT AT MUSTER — NOTHING. AND THE NEXT WORK IS PRICED.

**Nothing of mine is in flight.** `main` is green on HEAD, every branch
experiment is concluded and recorded, no run is pending.

**THE LEG'S REAL REMAINING WORK, measured tonight rather than estimated.** The
seam doctrine says the equivalence proof must target **TT's CI netlist**, not our
local one — and until tonight that netlist did not exist. It does now. Pointing
the importer at it:

```
importer: no expansion for cell 'inv_2' (instance _170_)
```

Census of the fabricated artifact: **36 distinct cell types (32 logic, 4
physical) against our 13 trusted models — overlap ZERO.** Split by *function*
rather than by name, that zero is misleading and the real shape is:

| | count | instances |
|---|---|---|
| same function, different **drive strength** (`and2_2`, `dfxtp_2`, `nand2_2`) | 3 | 67 / 327 |
| **genuinely new functions** | 27 | 260 / 327 |

Our models are the `_1` family; the CI flow chose `_2` drives almost throughout.
⇒ **the trusted set must grow 13 → ~40**: 3 aliases, 27 new one-line functions,
each owing a `decide +kernel` liberty-agreement theorem like the existing
thirteen.

**This quantifies the evidence seat's 12:44 finding on our own artifact: the
trusted model set grows with FLATTENING, not with design size.** The design did
not grow — 327 logic cells — but the flow at TT's constraints reached for three
times as many distinct cell types as our local run.

⚠️ Two of the new cells deserve care rather than a one-liner: **`dlygate4sd3`**
(24) and **`clkdlybuf4s25`** (18) are hold-fixing delay cells whose *logic* is
identity but whose *presence* is a timing artifact; **`conb_1`** (12) is a tie
cell. A trivial model for a delay buffer is trivially right, and that should be
stated rather than assumed.

⇒ **Price of closing the seam: ~30 cell models + liberty theorems, then the
import, then per-cone equivalence — which ruling 4a made possible tonight by
putting every cone at ≤ 21 inputs.**

### …AND THEN EXECUTED, WITH TWO RESULTS THE PRICING DID NOT PREDICT (`cad38dc`)

**`Cells/Sky130.lean`: 13 → 44 liberty theorems covering 43 cells, all
`decide +kernel`, all audited.** ⚠️ *This line said **42** until 21:2x and 42 is
not a count of anything here — the file has **44** theorems over **43** cells,
because the tie cell `conb` owes **two** (one per output, `HI` and `LO`).
Self-caught while answering the maestro's status check by re-deriving the number
instead of quoting my own commit message. Same two-output cell that broke
`outputs_of` this afternoon; it has now broken a count as well.* `import_netlist.py`: +21 expansions, each simulated over its full truth
table against the vendor Liberty before landing, plus multi-output support and
`conb_1`.** Full build **8602 jobs, `EXIT=0`, 0 warnings**.

**1. THE NON-CIRCULAR RULE PAID, MEASURABLY — 2 of 27 hand-derivations were
WRONG.** Derived from the naming convention by contexts forbidden to read the
Liberty, then adjudicated against it: `nor3b` and `or3b` bubble their **LAST**
input (`C_N`) while `and*b`/`nand*b` bubble the **FIRST** (`A_N`). Five one way,
two the other; nothing in the name says which. **Liberty-generated models would
have agreed 27/27, every theorem green, and taught nothing.**

**2. A GAP IN THE EXISTING CHAIN, now closed.** The importer expanded **22**
cells; only **13** had a Lean model. Nine expansions were asserted by a Python
dict and checked by nothing — **four load-bearing, 94 instances across the
netlists D3/D3.5/D4 are proved against.** All four simulated against the Liberty
tonight: **all correct — a GAP, not a DEFECT** — and now proved, so the
importer's own docstring is true for the first time.

**3. THE REMAINING BLOCKER IS NOT CELLS.** With every cell expanding, the importer
stops at `net 'fabric.e20.sel0' has no driver and is not an input` — a **flop
output**. It is **combinational-only**: the comparator it was built for has 0
flops, the fabricated netlist has **52**. The fix is the flop treatment the cone
census already describes (Q-pins as cone leaves, D-pins as roots — D3.5's and
D4's own decomposition, one level up). **Design work, not another table row.**

### …AND THEN THE NIGHT SHIFT, 20:30–22:00 — SIX LANDINGS, AND THREE OF THEM ARE KILL-CHECKS

**THE CAPTAIN'S FLOP TREATMENT** (`cc401c9`). Q-pins as leaves, D-pins as roots,
paired by position. **The fabricated netlist imports for the first time**: 52
flops cut, 70 inputs (18 design + 52 state), 76 outputs, 524 gates.
`Fabric.lean` is **in the hub's import closure**, not merely on disk.
⚠️ **Soundness checked, not assumed**: the obvious test — do all flops share a
CLK net? — is **wrong** here (after CTS they sit on **eight**), so each clock is
traced through the buffer tree to a common **(root, parity)**.

**THE KEEP-ARM FOLLOW-THROUGH** (`f5b6e83`). `--cut` at the surviving
`(* keep *)` boundaries ⇒ **every cone in the netlist TT will fabricate is now
≤ 21 bits, 100 % inside the kernel ceiling**, as a Lean datum that builds.
`uo_out` falls 36 → 21, next-state 22 → 7. Agrees exactly with `cones.py --cut`.

**C0 SEAM CENSUS, SILICON HALF** (`d618178`) — **two findings on C4, the
council's headline.** `compile` has **zero declarations in the tree**; and
`sem (emitN (compile core)) = step` **does not typecheck** (`sem` takes a `Circ`,
`emitN` returns a `Silicon.Netlist`) — **run with a control, not argued.** The
landed `emitN_sem` supplies the correct shape, which proves something *stronger*.
✅ Adopted by the maestro into freeze **v0.1**.

**R3 — THE REGFILE: DOES NOT PASS** (`7e9f6a3`). 1056 cones, **max 36, 93.9 %**,
the failure **entirely in the read ports** and uniform (all 64 at exactly 36).
Cycle induction **does** elaborate at 992-bit state — and is *free*, because
`iterate_congr` inducts on the input list, not the state.
⛔ **And finding this exposed a SOUNDNESS BUG in `cones.py` that had already told
me R3 PASSED** (`max 6, 100 %`): escaped vector nets became phantom constants.
**I caught it only because it contradicted a prediction written to disk first.**

**R2 — THE ALU CONE: HALF RIGHT** (`28db1e5`). The slice obligation is **landed
and proved** (`slice_ok`, 3 inputs, 8 cases). But the **synthesised** netlist has
no slices: cutting at all 33 kept carry nets moved the max only **65 → 62**,
because abc re-derived every carry as lookahead. 🎯 **`(* keep *)` preserves the
NET, not the DEPENDENCY** — and this does **not** retract ruling 4a, re-measured.

**THE READBACK CHECK** (`7090b9f`) — the one the docstring claimed for weeks.
Now real, and **not a mirror**: it takes cell functions, output pins, flop
identification and next-state from the **vendor Liberty**, so corrupting `EXPAND`
or `SEQ_MODELS` makes it fail (measured). ⭐ The vendor **independently confirmed**
the hand-derived `edfxtp` model: `next_state = (D&DE) | (IQ&!DE)`.

## 4. COST

Roughly **20 CI runs** across five branches (~4 min each, zero shuttle cost);
**one local LibreLane image pull still unfinished and now redundant** — TT's CI
answered the STA question the pull was started for. **Twelve defects of my own
found today; seven were caught by another seat's instrument or by a tool refusing
me, five by me.** That ratio is the honest headline of my day.

**Night shift adds four more of mine**, and the pattern held: a false `--check`
claim in a docstring, `.index()` aliasing primary inputs, **"42 liberty theorems"
that is not a count of anything (44 over 43 cells)**, and the `cones.py` phantom
constant. **Three of the four were caught by an instrument or a prediction rather
than by care** — and the fourth, the count, only because I re-derived a number
instead of quoting my own commit message.

⚠️ **THE ONE TO CARRY INTO THE COUNCIL:** `cones.py` reported a **clean pass** on
the regfile. It did not warn, it did not degrade — **it printed a confident wrong
number on the exact shape the CPU road is made of.** Without a pre-registered
prediction on disk, *"max 6, 100 %"* would have gone on the bus as R3 passing.

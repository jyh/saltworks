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

## 3. IN FLIGHT AT MUSTER

**Nothing of mine is in flight.** `main` is green on HEAD, every branch
experiment is concluded and recorded, and no run is pending.

## 4. COST

Roughly **20 CI runs** across five branches (~4 min each, zero shuttle cost);
**one local LibreLane image pull still unfinished and now redundant** — TT's CI
answered the STA question the pull was started for. **Twelve defects of my own
found today; seven were caught by another seat's instrument or by a tool refusing
me, five by me.** That ratio is the honest headline of my day.

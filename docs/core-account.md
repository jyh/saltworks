# THE RISC-V CORE — THE ACCOUNT

### Commissioned by the Captain 2026-08-09 13:2x ("let's do it!") in the
### `bb-switch-account.md` pattern: compiler's kernel half beside
### silicon's priced half, one joint reading, one citation target.
### STATUS: SKELETON (maestro) — seats fill their halves at their seams.
### THE DISCIPLINE (the BB account's, inherited): every count is
### MEASURED from the artifact (#eval, synthesis report, signoff log) —
### never transcribed from a plan or a memory; every number NAMES ITS
### INSTRUMENT and its window; a one-witness column is struck, not
### defended. The [[the-order-invariant]] and the r/k/K letter
### convention (QUEUE 13:0x) bind all prose.
### GATE: the §1 row table's FINAL numbers await assembly rows 15–16
### (instance work, in flight) — the account states a COMPLETE
### assembly or marks itself interim.

**What this document is for:** (1) the deferred TT submission's fact
sheet — ruling #7's "complete, verified, ready for tapeout" made
checkable; (2) the NDF's control-plane reference (design package §3
cites HERE); (3) the writeup's hardware chapter seed.

---

## 1. THE KERNEL HALF — compiler's slot

### ✅ STATUS: **FILLED** (compiler, 2026-08-09 13:3x). Window: **`5f1abb7`**.

**INSTRUMENT for every figure in §1.1–§1.2 — KERNEL-GUARDED, not
print-guarded.** `SaltWorks/HDL/AccountMeasure.lean`, tracked, **rooted**
(`SaltWorks.lean:92`), and stating its readings as **theorems**. Re-runnable by
anyone as `../saltbuild.sh SaltWorks/HDL/AccountMeasure.lean`, and now also
covered by any full build. **An organ that changes dimension breaks the build
instead of changing a number nobody re-ran.**

```
v0  Scratch* name       gitignored  ⇒ an instrument no third party could run
v1  tracked, unrooted   not built   ⇒ a CorePlace change could break it silently
v2  tracked, rooted, THEOREMS       ⇒ guarded by the build; zero print noise
```

*The figures were DERIVED by the v1 `#eval` harness and are now PINNED by the v2
theorems, so two readings stand behind them.*

⚠️ **THIS PARAGRAPH HAS GONE STALE THREE TIMES IN THIRTY MINUTES, and the
sequence is worth more than the paragraph:** it claimed not-rooted-on-purpose
(true at the §4 seal, false seven minutes later when the maestro's sweep rooted
the module — evidence's post-seal-drift catch at 13:49); then it claimed the
conversion was *planned* with print noise *accepted until it lands* (true when
written, false at `4264e3b` when it landed). **A sentence describing a live
object needs a window as much as a number does** — each version was correct when
written and none said when.
*(Evidence's §4 finding 1: v1 was named `Scratch*`, which `.gitignore:2`
excludes — so §1 named an instrument no third party could run. Naming a tool
answers "which tool" and not "can another party reproduce it".)*
**Nothing here is transcribed from `CoreOffsets`' literals, from the assembly
plan, or from a memory** — the harness reads `c.gates.length`, `c.nIn`,
`c.outs.length` and the `instNext` chain off the artifacts themselves.

**DENOMINATOR — what §1 refuses to count, stated up front:**

- **Gates are `Circ` gates, pre-synthesis.** Not cells, not area. §2 is the
  independent axis and the two must not be added.
- **`readTree` and `adder32` are ONE `Circ` each, placed TWICE.** The netlist
  duplicates their gates (`instGates` maps every gate into the host); the
  *source* does not. So "16 rows" is **13 distinct organs in 16 placements**.
- **The tie-cell row is a host preamble, not an organ.** It is counted in the
  net span and excluded from "organs only".
- **No `core` object exists and no semantics is claimed here.** §1 is a
  *placement* account. See §1.4.

**WITNESSES:** the dimensions carry **two independent readings** — this harness
(derived chain) and `CoreOffsets.lean`'s independently-landed `row_*` theorems
(literal table, kernel-checked by `decide +kernel`). They reconcile exactly:
`11461 = 11459 + 2` (§1.2). Columns marked **⚠️1W** are single-witness (mine
alone) and are struck if §4 wants them struck.

### 1.1 The organ inventory (sixteen rows)

| row | organ | gates | nIn | outs | offset | `sem_*` certificate | `instOK` theorem |
|---|---|---|---|---|---|---|---|
| 0 | tie cells | 2 | 0 | 2 | 1088 | *(none — two `const` gates)* | `tieCells_instOK` |
| 1 | `decoder` | 102 | 32 | 6 | 1090 | `sem_decoder`, `sem_decoder_eq_ctrlSpec` | `decoder_instOK` |
| 2 | `immBCirc` | 1 | 32 | 32 | 1192 | `sem_immBCirc`, `sem_immBCirc_of_decode` | `immB_instOK` |
| 3 | `readTree`.rs1 | 2982 | 997 | 32 | 1193 | `sem_readTree`, `sem_readTree_uncond` | `readTree_rs1_instOK` |
| 4 | `readTree`.rs2 | 2982 | 997 | 32 | 4175 | *(same `Circ`, same certificates)* | `readTree_rs2_instOK` |
| 5 | `bitXor32` | 32 | 64 | 32 | 7157 | `sem_bitXor32` | `bitXor32_instOK` |
| 6 | `bitNot32` | 32 | 32 | 32 | 7189 | `sem_bitNot32` | `bitNot32_instOK` |
| 7 | `obMux` | 97 | 65 | 32 | 7221 | `sem_obMux`, `sem_operandBMux` | `ob_instOK` |
| 8 | `adder32`.add | 160 | 65 | 33 | 7318 | `sem_adder32` (all 2⁶⁴ pairs) | `add_instOK` |
| 9 | `adder32`.sub | 160 | 65 | 33 | 7478 | *(same `Circ`, same certificate)* | `sub_instOK` |
| 10 | `sltCirc` | 5 | 3 | 32 | 7638 | `sem_sltCirc` | `slt_instOK` |
| 11 | `sliceASelect` | 291 | 98 | 32 | 7643 | `sem_sliceASelect`, `sem_genSelect` | `sel_instOK` |
| 12 | `ruledEnc` | **0** | 3 | 2 | 7934 | ⚠️ **none** — see §1.4 | `enc_instOK` |
| 13 | `regWrite` | 163 | 7 | 32 | 7934 | `regWrite_correct` | `regWrite_instOK` |
| 14 | `pcAdd` *(math's)* | 260 | 129 | 32 | 8097 | `sem_pcAdd` | `pcAdd_instOK` |
| 15 | `regNext` | 3104 | 1088 | 1024 | 8357 | `sem_regNext`, `sem_regNext_drive` | `regNext_instOK` |

⚠️ **ROWS 12 AND 13 SHARE OFFSET 7934, AND THAT IS LEGITIMATE ONLY BECAUSE ROW
12 HAS ZERO GATES.** `ruledEnc` is a pure re-wiring of the decoder's class
lines, so `instNext ruledEnc off = off` for every `off`
(`enc_row_does_not_advance`, stated ∀-offset). **Two rows sharing an offset when
the earlier one has gates is a defect, not a feature** — it occurred in this
file and is described in §1.4.

#### Port maps

`instOK` certifies that a wire is *computed in time*. It never certifies that it
is the *right wire*. So the two organs whose ports are not a uniform shift carry
an explicit map:

| organ | port range | source that must drive it |
|---|---|---|
| `pcAdd` | 0…31 | state `pc` bits — core input `1024+k` |
| `pcAdd` | 32…63 | `readTree.rs1` **value** (row 3) |
| `pcAdd` | 64…95 | `readTree.rs2` **value** (row 4) |
| `pcAdd` | 96…127 | `immBCirc` B-offset (row 2) |
| `pcAdd` | 128 | `decoder` output 4 = `isBEQ` |
| `regNext` | 0…31 | `we[r]` ← `regWrite` outputs (row 13) |
| `regNext` | 32…63 | `res[k]` ← `sliceASelect` outputs (row 11) |
| `regNext` | 64…1087 | `cur[r][k]` ← core input `32r+k` (the shift `i-64`) |

*Source: `pcAddPortMap` in `CorePlace.lean`, printed by the harness — it is data
in the file, not prose, and `pcAddSig_follows_the_port_map` proves the σ is that
table read back. `pcAddPortMap_is_total` proves it covers `nIn` with no gap and
no overlap: a gap in the map is where a wrong wire hides.*

### 1.2 Totals and state

| quantity | value | instrument |
|---|---|---|
| rows | 16 | harness `#eval` |
| gates, organs only | **10371** | harness; reconciles with `CoreOffsets.total_reconciles` |
| gates, including tie cells | **10373** | harness |
| state bits (`stWidth`) | 1056 | `StateCodec.stWidth` |
| — register file | 1024 | 32 × 32 |
| — pc | 32 | `stWidth − 1024` |
| instruction word base (`instrBase`) | 1056 | `StateCodec` |
| core input width (`coreInWidth`) | 1088 | `stWidth + 32` |
| first gate net | 1088 | `offTie` |
| last net | 11460 | harness |
| **total nets** | **11461** | harness |

**THE CROSS-CHECK — two instruments, and it is the reason §1's numbers are
two-witness:**

```
CorePlace derived chain end            = 11461     (instNext regNext offRegNext)
CoreOffsets chain_last (literal table) = 11459     (landed earlier, decide +kernel)
tie cells CoreOffsets does not model   =     2
expected: 11459 + 2                    = 11461     RECONCILES = true
coverage: offTie + placedGateTotal     = 11461     matches = true
```

*`chain_accounts_for_every_placed_organ` states the coverage identity as a
theorem, proved structurally so no offset is ever forced to a numeral.*

### 1.3 The theorem inventory

**The composition machinery.** `instOK c σ off` = `c.ssa ∧ c.wf ∧ ∀ i < c.nIn,
σ i < off`. Sixteen certificates, one per row, all discharged at `5f1abb7`.
`instOK_mono` lifts a certificate up the chain when an organ's inputs all lie
below an earlier offset (used for rows 1–4 and for `regWrite`).

**The invariant no per-organ certificate can express** —
`chain_accounts_for_every_placed_organ`, plus the pairwise
`immB_and_regWrite_do_not_overlap`. `instOK` constrains ONE instance against ITS
OWN inputs and cannot see another instance at all.

**Wiring controls, all run and audited** — each excludes a mutant that places
cleanly and computes the wrong machine:

| control | the mutant it excludes |
|---|---|
| `wrong_wire_mutant_fails_at_addi` | `ADDI` receiving `rs2` instead of the immediate |
| `addSig_b_bank_is_obMux_not_rs2` | the adder's b-bank bypassing the operand-B mux |
| `subSig_b_bank_is_unchanged` | "consistently" re-routing `sub` — which would break `SLT` |
| `obMux_precedes_the_adder` | the mux placed after its consumer |
| `pcAdd_compares_values_not_indices` | `BEQ` comparing register *numbers* |
| `isBEQ_agrees_with_regWrite` | `valid`/`isBEQ` swapped across two consumers |
| `cur_bank_is_row_major_not_transposed` | the register file read column-wise |
| `we_and_res_banks_are_not_swapped` | write-enables and result bits exchanged |
| `regWrite_is_NOT_placeable_at_off0` | a placement ordered before its producer |
| `subtraction_is_a_plus_not_b_plus_one` | `a + ~b` (off by one on every subtraction) |

**And a second family — DISJOINTNESS controls, which are cross-instance and so
cannot be derived from any `instOK`.** *This family was completed by silicon's
hand-read of the repair: my first draft of §1.3 listed the wiring controls and
missed three of these, which is exactly the incompleteness a second witness is
for.*

| control | the collision it excludes |
|---|---|
| `immB_and_regWrite_do_not_overlap` | two organs' gates sharing net 1192 (**the repaired defect**) |
| `operand_banks_are_disjoint` | the XOR reading one register twice |
| `select_banks_are_disjoint` | the select's three result banks overlapping pairwise |
| `tie_nets_are_distinct` | the two host constants collapsing to one net |
| `slt_operand_signs_are_distinct` | `SLT` comparing a sign bit against itself |
| `we_and_res_banks_are_not_swapped` | `regNext`'s two organ banks exchanged |
| `rd_bits_are_in_the_instruction` | `rd` read from the state instead of the instruction word |

⇒ **THE GENERAL LAW, and it is the one obligation neither half of this account
could generate on its own: a per-instance predicate cannot be strengthened into
a cross-instance one. The pair property must be ASSERTED.** *`instOK`
constrains one instance against its own inputs; two placements sharing a net is
invisible to every one of the sixteen.*

**Axiom audit.** 41 `#audit_axioms` calls, **one declaration per call** — a
multi-name call aborts its own list at the first failure and everything after
reads as clean. **41/41 ticks, 0 failures, maximum `[3 axioms]` = the whitelist
(`propext`, `Classical.choice`, `Quot.sound`).**
*Instrument: build ticks at `5f1abb7`, counted as `grep -c '^✓'` — anchored
positionally, because the token count includes this file's own prose ABOUT the
instrument. **Both figures stamped, because they move:***

| measurement | `#audit_axioms` | `^#audit_axioms` | ticks |
|---|---|---|---|
| at `52d11f3` (when the lesson was found) | 38 | 36 | 36 |
| at `5f1abb7` (this section's window) | **43** | **41** | **41** |

*(Evidence's §4 finding 2: the unstamped `38/36` pair sat in the one sentence a
sceptic tests first, and the file had grown between the measurement and the fill
— so a reader checking the justification found `43/41` and could not tell whether
the lesson or the file had moved. **The lesson survives exactly; the figures did
not.** The gap is the five audit calls the `regWrite` repair added.)*

### 1.4 What §1 does NOT claim — and one defect it found

**`instOK` certifies `ssa`, `wf`, and inputs-computed-in-time. Nothing else.**
There is **no `core` object and no semantics** in this account. The composition
theorem is the next object, and it is where "the right wire" gets *proved*
rather than asserted by a port map.

**Row 12 (`ruledEnc`) has no `sem_*` certificate.** It is a zero-gate
re-wiring, so there is no gate behaviour to certify; what stands in its place is
`encoder_select_seam_closed`, which proves its outputs ARE the nets row 11 wired
into the select. **Stated rather than left blank.**

⛔ **A DEFECT THIS ACCOUNT'S OWN DISCIPLINE FOUND, ten minutes after the
commission.** At `52d11f3` this section would have reported "16 of 16 complete".
The cross-check above disagreed by 161:

```
regWrite was placed at off1 = 1192 — the offset immBCirc already occupied
immBCirc out-nets [1192] · regWrite out-nets [1192, 1193, …] · OVERLAP [1192]
regWrite's 163 gates appeared in NO downstream offset
161 = 163 (regWrite) − 2 (tie cells)
```

**Sixteen `instOK` certificates were all true over a netlist that could not
compose.** Root cause: a docstring concluded `regWrite` was *"placeable from
`off1` onward"* — a lower **bound** — and the placement collapsed that
half-open interval to its left endpoint. **A bound is not a position.** Repaired
at `5f1abb7` by restoring `CoreOffsets`' already-ruled row 13, and the coverage
invariant now makes the class unlandable. *The harness reproduces the defect at
the old offset, so it carries its own positive control: it could have failed.*

## 2. THE PRICED HALF — silicon's slot

**Every number below is MEASURED from a signoff artifact or a synthesis report,
with its instrument and window named. Where a figure was published and later
refuted, it is STRUCK IN PLACE rather than quietly replaced — three of this
document's inputs were withdrawn by their own author on 2026-08-09 and the
strikes are part of the account.**

### 2.1 The 3×2 signoff facts

**Instrument:** LibreLane 3.0.5 (`ghcr.io/librelane/librelane:3.0.5`), sky130A PDK
pinned `c6d73a35f524070e85faff4a6a9eef49553ebc2b`, `FP_SIZING: absolute` at the
true `3x2` tile die. **Window:** run `RUN_2026-08-09_15-50-58` (container UTC),
artifact `SaltWorks/Silicon/Flow/layout-metrics/slicea16bma_3x2_metrics.json`.
Reproduced by the invocation banked in `docs/silicon-3x2-realdie-0809.md`.

| fact | measured | key |
|---|---|---|
| die / core area | 114,858 / 101,535 µm² | `design__die__area`, `design__core__area` |
| stdcell area | **45,337.2 µm²** | `design__instance__area__stdcell` |
| utilization | **44.65 %** | `design__instance__utilization` |
| sequential cells | 552 (11,741.3 µm²) | `…count__class:sequential_cell` |
| timing-repair buffering | 9,860.7 µm² | `…class:timing_repair_buffer` |
| routed wirelength | 172,703 | `route__wirelength` |
| **DRC** (route · magic) | **0 · 0** | `route__drc_errors`, `magic__drc_error__count` |
| **LVS** (all 7 counters) | **0** | `design__lvs_error__count` et al. |
| **antenna** nets / pins | **0 / 0** | `antenna__violating__nets` |
| **setup / hold WNS** | **0 / 0** | met at **all nine corners** |

**SETUP WORST-SLACK, ALL NINE CORNERS, on a 40 ns clock — the margin, not just the
verdict:**

```
max_ss_100C_1v60  +14.8193   ← the limit
nom_ss_100C_1v60  +15.4942       min_ss_100C_1v60  +16.2249
max_tt_025C_1v80  +26.2885       nom_tt_025C_1v80  +26.4763
min_tt_025C_1v80  +26.7291       max_ff_n40C_1v95  +28.2524
nom_ff_n40C_1v95  +28.3811       min_ff_n40C_1v95  +28.5548
HOLD: 0 at all nine.
```
⇒ **worst path = 40 − 14.8193 = 25.18 ns**, i.e. the part closes at **~39.7 MHz**
against a declared 25 MHz. **37 % of the clock period is margin at the slow corner.**

#### ⛔ THE DRV POSTURE — stated as an OPEN failure, not a footnote

```
max-slew violations   2,019 @ ss_100C_1v60   ·   854 @ tt_025C_1v80
max-cap violations       51 @ ss             ·   max-fanout 39
```
**This FAILS the bar I pre-registered at 08:46 before the run ("slew 0 at typical"),
and I score it a FAIL rather than a partial because that is what the bar says.**
DRV does not gate TT submission (§2.3), and it does not affect DRC/LVS/timing —
but the account states it as open.

> ⛔⛔ **STRUCK — MY OWN EXPLANATION FOR IT WAS REFUTED BY MY OWN FOLLOW-UP RUN
> (`9a30d9f`).** I published that the slew regression was WIRE-LENGTH driven,
> citing `route__wirelength` +8.2 % as "a second instrument agreeing". A
> margins-only control run (one variable: the core inset) then cut wirelength
> **3.1 %** while slew ROSE **4.7 %**, with setup slack **2.8 ns WORSE on SHORTER
> wires**. The kill condition was pre-registered before that run, which is the only
> reason it settled in nine minutes.
> 🔑 **Total wirelength is an AGGREGATE; slew violations are PER-NET. An aggregate
> that tracks a per-instance phenomenon in one comparison is not its cause.**
> **NO replacement mechanism is named here** — three runs with die size and
> utilization confounded is exactly the evidence base that produced the error.

### 2.2 Area by organ — **and the two axes DO meet, exactly, where the emitter runs**

**Instrument:** yosys via `SaltWorks/Silicon/Flow/synth.sh`, same pinned PDK,
`stat -liberty` chip area. **Window:** committed `*_stat.txt` reports.

> ⛔ **STRUCK BEFORE PUBLICATION (13:2x) — MY FIRST DRAFT OF THIS SECTION CLAIMED
> "the correspondence to §1's kernel organs is NOT established in the corpus."
> THAT WAS FALSE, and math's pre-registered check #1 ("absence by CONTENT, across
> BOTH repos, never from a note") is what caught it: I had grepped `docs/` only.
> The object was in `SaltWorks/HDL/EmitS.lean`.** *Recorded rather than silently
> fixed, because the check earned its place by firing before the file was cast.*

**THE CORRESPONDENCE IS EXACT WHERE `emitS` RUNS — one sky130 cell per kernel gate:**

| organ | §1 kernel gates | cell instances in the `.v` | area | µm²/cell |
|---|---:|---:|---:|---:|
| `readTree` → `RTL/readtree.v` | 2,982 | **2,981** | 18,636.62 µm² | 6.252 |

✅ **THE ONE-GATE DIFFERENCE IS EXPLAINED (compiler, 14:25) AND THE EMITTER IS
EXACT — THE COMMITTED FILE IS THE STALE OBJECT.**
```
emitS readTree, RUN AT HEAD:   kernel gates 2,982  ·  cell instances 2,982  EXACT
                               of which conb (tie) lines: 1
committed RTL/readtree.v:      2,981 sky130 lines  ·  .HI( lines 0  ·  conb 0
⇒ the missing cell is THE TIE CELL, which `emitCell` emits today
  (`EmitS.lean:137-145`, a `conb_1`). The FILE predates that emitter.
```
*My earlier guess — "a `.const` gate emitting as a tie rather than a cell" — was
the right ORGAN and the wrong DIRECTION: the tie is emitted AS a cell now, and the
committed artifact simply lacks it. **And the obvious alternative was REFUTED by
measurement before mine was preferred: `readTree`'s tie net is LIVE (32 gates read
it) and `opt readTree` removes nothing, so "dead gate elided by `opt`" is dead.***
📌 **MY 2,981 WAS NEVER WRONG — it is a TRUE COUNT OF THE FILE, and evidence's
independent 2,981 confirms the file. The file is stale; the count is not.** *Two
correct measurements of two different objects, which is this account's own
recurring lesson in miniature.*

⛔ **AND A MODULE THAT IS *NOT* EMITTER OUTPUT, WHICH IS WHY A SINGLE µm²/gate
FACTOR WOULD BE WRONG:**

| module | cell instances | area | µm²/cell | kind |
|---|---:|---:|---:|---|
| `RTL/readtree.v` | 2,981 | 18,636.62 | 6.252 | **`emitS` output** — gate-for-gate |
| `RTL/adder32.v` | **0** | 1,361.31 | 8.508 | **behavioural RTL** — yosys maps it |

🔑 ***THE TWO ARE DIFFERENT KINDS OF ARTIFACT AND MUST NOT SHARE A COLUMN.
`readtree.v` is synthesis-as-PASSTHROUGH: the kernel chose every cell, and yosys
only places them. `adder32.v` contains ZERO `sky130_fd_sc_hd__` instances — yosys
chose its cells, optimised across them, and the 8.508 µm²/cell reflects ITS
choices, not the kernel's.***
⇒ **So §1's gate count converts to area EXACTLY for emitted organs and NOT AT ALL
for behavioural ones. Anyone multiplying §1's 10,371 gates by a single µm²/gate
figure is inventing a number this account does not contain** — the corpus holds
both kinds and the account must say which is which per row.

📌 **A SECOND RATIO THAT IS ALSO NOT CONSTANT — synthesis → post-layout:**
```
core family (slicea16b, slicea16bma)   1.56x and 1.53x   => "use 1.55x" [scoped]
banyan_fabric (bit-serial, 48.6% seq)  2,143.31 -> 4,031.37 = 1.881x
```
*The 1.55x rule in `silicon-bytewide-feed-pricing-0808.md:150` carries the clause
"for this cell family and this flow", and the clause is load-bearing: applying it
across families would have understated the fabric by 17.6%.*

**WHAT §2.2 DOES NOT CLAIM:** areas for the other fourteen kernel organs (no
committed `*_stat.txt` exists for them); that `readtree.v` and `readTree` have
identical PORT interfaces (they do not — see the one-gate note); or any µm²/gate
figure for the assembly as a whole.

### 2.3 The pin protocol

**18 of 24 signals, fabricated-grade** (TT supplies `clk`/`rst` OUTSIDE the 24):

```
8  addr   multiplexed memory bus   ·   8  data   ·   2  phase strobe
= 18. Remaining 6 = 3 packet ports (edge-in · edge-out · spare/debug).
```
**The core is `slicea16bma`: byte-wide instruction feed, 32-bit multiplexed
addresses, 4-phase sequencer (`phase_o[1:0]`), served by an RP2040 exactly as the
harness already does.** The RP2040 counterpart is **outside the verified surface** —
it is a harness, and no theorem covers it.

⭐ **A property the architecture bought unasked: the 32-bit PC is architecturally
REAL.** Earlier variants had unobservable PC bits **silently deleted by synthesis**
(17 of 32 flops in `slicea16b`; `slicea16t` collapsed to 0 cells entirely). The
byte-wide fetch makes them observable; `slicea16bma` keeps 31. *Compare expected
against measured flop count on every new core — a shortfall is state you thought you
had.*

#### ⛔ THE `CLOCK_PERIOD` RULE — a trap that ships looking clean

```
info.yaml  clock_hz 25000000  = 40 ns      src/config.json  CLOCK_PERIOD  20
```
**These are INDEPENDENT fields and they disagreed.** At `CLOCK_PERIOD 20` the BB
design carried **24 setup violations, WNS −3.455 ns** at `ss_100C_1v60`; at the
declared 40 ns it has ~16.5 ns of margin.
🔑 ***TT's blocking checks do NOT gate on multi-corner setup timing — `precheck`
goes GREEN either way, so a silently violating design SHIPS LOOKING CLEAN.*** TT's
own config comment sanctions the fix verbatim: *"CLOCK_PERIOD — Increase this in
case you are getting setup time violations."*
✅ **RULE: the submission config's `CLOCK_PERIOD` must equal `1e9 / clock_hz`, and
the two files are reconciled in the same commit.** *Landed for the BB switch
2026-08-09 12:5x; verified at the payload (40 ns ⇔ 25.0 MHz), not at the commit
message.*

## 3. THE JOINT READING — maestro, 2026-08-09 13:4x (both halves in)

**Two objects exist and this section states their exact relation.**

**The kernel object** (§1's subject): the sixteen-row composed netlist
— every organ individually certified (`sem_*`, ∀-env), every placement
`instOK`-certified with its source-port map as data, the chain
coverage-invariant guarded (`5f1abb7` — added when sixteen true
certificates were found standing over a netlist that could not
compose), tie cells at row 0. **What is certified TODAY: the organs,
the wiring, and the composition's well-formedness. What is OWED and
says so: the single-cycle refinement (assembled gates, clocked once,
= `stepT`) — W5-asm's summit theorem, not yet stated over the
completed chain.** Until it lands, the kernel object is a fully
placed, fully port-mapped composition whose *end-to-end* semantics
carries an owed-marker, not a sha.

**The silicon object** (§2's subject): `slicea16bma` — hand-maintained
RTL, hardened and signed off on the real 3×2 die. **The relation
between the two objects TODAY is construction-discipline, not
theorem: the RTL is a *twin* of the kernel organs, kept faithful by
the same hands that measured both — no kernel statement mentions it.**

**What changes the relation:** the `emitS` path. The W5-asm prize —
emit the composed kernel core as the tapeout RTL — would *replace*
the twin with the object itself; the twin-faithfulness question then
dissolves rather than being answered (there is nothing left to be
faithful *to* except yosys and the PDK, named trust steps). The NDF
cell wave (QUEUE, ruled 13:38) applies this law from birth: `macSeq`
is built in the kernel first and emitted, never twinned.

**The one-sentence summary this account authorizes:** *a processor
whose every organ and every wire is kernel-certified, whose composed
end-to-end semantics is one named theorem away, and whose fabbed twin
is scheduled for replacement by the verified object itself.* Any
stronger sentence over-claims; any weaker one undersells measured
work.

## 4. THE FENCES — evidence's pass

> ### ✅ STATUS: **PASS — WITH TWO NOTED ITEMS, NEITHER TOUCHING A HEADLINE NUMBER**
> **Run 2026-08-09 13:4x by the evidence seat, against the criteria in §4.1–4.3
> published at 13:2x BEFORE either half was written.** *Window: `core-account.md`
> at the §3 landing; §1 window `5f1abb7`, §2 window `RUN_2026-08-09_15-50-58`.*
>
> **The account IS a citation target as of this verdict, with the two items
> below carried openly and the refinement's OWED-MARKER intact.**
>
> ### ✅ **BOTH ITEMS CLOSED 13:4x — FIXED BY COMPILER, RE-VERIFIED BY THIS SEAT AT HEAD**
> ```
> ITEM 1  AccountMeasure.lean — tracked=1, NOT ignored, Scratch name gone.
>         Re-runnable by anyone: ../saltbuild.sh SaltWorks/HDL/AccountMeasure.lean
> ITEM 2  §1.3's stale 38/36 parenthetical REMOVED; headline 41/41 unchanged
>         and still correct (ground truth at HEAD: ^-anchored = 41, token = 43)
> ⚠️ AND THE SAME STALE PAIR WAS FOUND IN §4.2 — THIS SECTION'S OWN TEXT — and
>    is now stamped `as of 52d11f3`. The fence carried the defect it raised.
> ```

### 4.0 The verdict, and what it is a verdict ABOUT

*The criteria were published before the halves were filled, so this pass is a
CHECK against a standing bar and not an opinion formed after seeing the work.*

```
INSTRUMENT   §1 names #eval over the real Circ artifacts · §2 names LibreLane
             3.0.5 + pinned sky130A + a run id + yosys stat -liberty      ✅
WINDOW       §1 `5f1abb7` · §2 RUN_2026-08-09_15-50-58 · §3 dated           ✅
DENOMINATOR  §1 states what it refuses to count UP FRONT (gates≠cells, 13
             distinct organs in 16 placements, tie row excluded, no `core`
             object); §2 separates emitS output from behavioural RTL and
             refuses a single µm²/gate factor                              ✅
WITNESSES    §1 reconciles TWO instruments (11461 = 11459 + 2) and marks its
             single-witness columns ⚠️1W itself                            ✅
```

### 4.1′ ITEM 1 — §1's instrument is NAMED but NOT REPRODUCIBLE

```
[MEASURED] SaltWorks/HDL/ScratchAccountMeasure.lean
           exists: yes · git-tracked: 0 · ignored by .gitignore:2 `Scratch*.lean`
```
**Not a strike.** *Naming the tool satisfies "which instrument"; it does not
satisfy "another party can re-run it", and no one off this machine can.*
⇒ **§1 survives on its OTHER witness: `CoreOffsets.lean`'s `row_*` literal table
is tracked and `decide +kernel`-checked, and the two reconcile exactly.** The
harness is the *derivation*; the tracked theorems are the *evidence*. **Fix is
one line: track the harness under a non-`Scratch*` name, or state explicitly
that `CoreOffsets` is the reproducible instrument.**

### 4.2′ ITEM 2 — a STALE PAIR inside the sentence that justifies an instrument

```
§1.3 states  "grep -c '#audit_axioms' returns 38 against 36 real calls"
MEASURED NOW  same file:  #audit_axioms = 43  ·  ^#audit_axioms = 41
```
**The headline is correct and unaffected: 41 calls, 41/41 ticks, `^`-anchoring
is the right instrument.** *But the evidence offered FOR that choice is dated and
unlabelled — a sceptic who checks the justification finds 43/41 and cannot tell
whether the lesson moved or the file did.* **The lesson survives exactly (two
extras, both prose about the instrument); the figures do not.**
⇒ **Fix: stamp them (`38/36 as of 52d11f3`) or refresh to 43/41.** *This fence's
own F4 in `EVIDENCE-neural-claim-fence-0809.md` carries exactly that stamp, added
after the same class bit this seat at 10:36.*

### 4.3′ ONE GLOSS ON §3's AUTHORIZED SENTENCE

*"every organ and every wire is kernel-certified"* is **defensible and needs
§1.4's gloss to stay so**: row 12 (`ruledEnc`) has **no `sem_*` certificate** —
it is a zero-gate rewiring whose stand-in is `encoder_select_seam_closed`. *So
every organ carries A kernel-checked theorem, but not all of the same kind.* §1.4
discloses this plainly; **the sentence must not travel without that disclosure**,
because "kernel-certified" will be read as "has a semantic certificate".

### 4.4′ WHAT I VERIFIED CLEAN — reported because a pass listing only faults is not a pass

```
§2 artifacts    metrics json · realdie doc · synth.sh — ALL TRACKED
                44 *_stat.txt reports tracked (the §2.2 window)
§2 emitS claim  readtree.v TRACKED; I counted sky130 cell instances
                INDEPENDENTLY as a third party: 2,981 — matches silicon exactly
⇒ the one-gate gap (2,982 kernel gates vs 2,981 cells) is REAL, reproduced from
  the artifact by a seat that did not write either half, and correctly left OPEN
  with its candidate cause labelled a GUESS.
```
📌 ***That is the pass earning its keep in the positive direction: silicon's most
uncomfortable number is the one an outside reading confirms.***

### 4.5′ THE CITATION RULE, now active

**This account may be cited.** *Two conditions travel with it: (1) the
single-cycle refinement carries an OWED-MARKER, not a sha — any citation
implying end-to-end semantics is stronger than the account; (2) §3's authorized
sentence is the ceiling. **Any stronger sentence over-claims; any weaker one
undersells measured work** — and that is §3's own wording, which this pass
endorses unchanged.*

<!-- criteria as published 13:2x, before either half was filled: -->

> **The pass runs LAST, by commission — it needs §1 and §2 filled. But the BAR
> is published NOW, before either half is written, for one reason: a criterion
> published after the work is a rationalisation, and a criterion published
> before it is a standard the filler can simply MEET.** *If this section does its
> job, its own verdict is boring.*

### 4.1 What each number must carry — the four-part test

A figure passes if it answers all four. Any figure missing one is **struck, not
defended** (the skeleton's own discipline, inherited from the BB account).

```
INSTRUMENT   which tool produced it?  (#eval · synthesis report · signoff log ·
             build tick count · shasum).  "I counted" is not an instrument.
WINDOW       over WHAT, at WHAT MOMENT?  A commit sha, a run, a date. A number
             whose scope a reader must guess is unciteable.
DENOMINATOR  what was EXCLUDED?  A miss is visible; an exclusion is not. State
             what the count refused to count.
WITNESSES    how many independent readings, BY WHOM?  A one-witness column is
             struck. Two readings by the same author are ONE claim.
```

#### ⭐ AMENDMENT (compiler, 13:5x) — **THE BAR EXTENDS TO PROSE ABOUT LIVE OBJECTS**

*Published as a test for FIGURES. Compiler demonstrated it applies to SENTENCES,
by watching one paragraph go stale three times in thirty minutes:*

```
① "not rooted on purpose"          true at the §4 seal · FALSE 7 min later
② "conversion planned, noise
   accepted until it lands"        true when written · FALSE at 4264e3b
③ the current version              true at 4264e3b — AND IT SAYS SO
```
🔑 ***A SENTENCE DESCRIBING A LIVE OBJECT NEEDS A WINDOW AS MUCH AS A NUMBER
DOES. Every version was correct when written and none of them said WHEN.***
⇒ **So the WINDOW column binds prose too, and the sequence is kept rather than
overwritten — the three states are one defect receding a layer at a time, and
that history is worth more than the paragraph.**

### 4.2 The three failure modes this pass exists to catch

*Named in advance so nobody has to be surprised by the verdict:*

1. **A TOKEN COUNT WHERE A COMMAND COUNT IS MEANT.** *Live example from this
   fleet, **`CorePlace.lean` AS OF `52d11f3`, 2026-08-09 13:2x**: token grep = 38,
   `^`-anchored = 36, build ticks = 36 — the two extras being prose ABOUT the
   instrument.* **In a document that describes its own instruments, grepping the
   instrument's name hits the description. Anchor positionally.**
   > ⛔ **AND THIS EXAMPLE ROTTED WHILE THE PASS THAT CITES IT WAS BEING WRITTEN —
   > the same file measures 43 / 41 by 13:4x.** *Stamped rather than refreshed,
   > because the figures are an ILLUSTRATION of a defect at a moment, not a live
   > count of anything. **§4.2′ raised exactly this against §1.3 and this section
   > carried it unstamped at the same time**: the fence exhibited the class it
   > was written to catch, which is why the stamp is here and not an apology.*
2. **A STATUS WORD USED AS A MEASUREMENT.** *`landed`, `covered`, `green`,
   `done`. These assert facts about our own work — the class no outside reader
   can check and every inside reader assumes someone else verified.* **A status
   word is a CITATION: it carries a sha or an owed-marker, or it is struck.**
3. **A GREEN OVER THE WRONG SCOPE.** *`EXIT=0` never asked the question
   `#audit_axioms` asks; a module absent from the build graph builds green by
   not being built.* **State what the green covered, not that it was green.**

### 4.3 What this pass will NOT do

- **It will not re-derive the numbers.** *That is compiler's and silicon's work
  and re-doing it would produce a second author's agreement, which is worth
  less than one measured claim with its instrument named.*
- **It will not widen a regex to hunt claim-words.** *Measured last night: that
  hunt returns the documentation of the hazard, 399 hits, overwhelmingly prose.*
- **It will not strike a number for being UNSOURCED-PENDING.** *"I cannot find
  the source" and "there is no source" are different findings, and only the
  second justifies a strike. A correct record was deleted on that confusion this
  morning; the prescription is marking, never deletion.*

### 4.4 The gate on citation

**Until this section carries a dated PASS verdict, `core-account.md` is not a
citation target.** *The skeleton says the account "states a COMPLETE assembly or
marks itself interim" — so does this fence: an interim account may be cited
WITH its interim marker, and never without it.*

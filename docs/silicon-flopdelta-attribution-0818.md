# The +10 flops in `plane32bus`, attributed — `memory_map` after `memory_dff`

**Executor measurement, 08/18, on silicon's brief. Repo tip at dispatch `30e89be`.**

`plane32bus` synthesised as a composed module reports **1,127** sequential cells.
Its parts synthesised separately report **1,024** (`core32`) + **93** (`busadapt8`)
= **1,117**. This file attributes the **+10**.

## THE ANSWER IN ONE PARAGRAPH

The +10 is **two 5-bit registers** — `2 x $dff_5` — emitted by **`memory_map`**
(pass 19 of `synth`) for the two read ports of `core32.regs [1:31]`. They exist
only because three passes earlier **`memory_dff`** (a sub-pass of `memory -nomap`,
pass 16) *absorbed the read-address flop into the memory read port*, making the
port clocked. It can only do that after **flattening**, because only then are
`busadapt8.instr_r` and `core32.regs` in the same module: `rs1 = instr[19:15]`
and `rs2 = instr[24:20]` become visibly flop outputs. `instr_r` itself is **not
removed** — the decoder consumes its other 22 bits — so the absorption
**duplicates** 5+5 address bits instead of moving them. Flattening is the
enabling condition; `memory_map` is the pass where the count moves.

Both of silicon's named hypotheses are **DEAD**. The mechanism is register
duplication, but of `instr_r`'s *address slices* by the *memory mapper* — not of
the enable network by `abc`.

## THE PREDICATE

⛔ The brief's corrected predicate is **still incomplete**. Do not inherit it.

The brief supplied `sky130_fd_sc_hd__(e?s?df|dl)`. Tested against the pinned
liberty, that misses **6 of 63** sequential cell types, because `e?s?df` accepts
`e` *before* `s` and sky130 spells the scan-enable flops `sedf…`:

```
sky130_fd_sc_hd__sedfxbp_1   sky130_fd_sc_hd__sedfxtp_1   sky130_fd_sc_hd__sedfxtp_4
sky130_fd_sc_hd__sedfxbp_2   sky130_fd_sc_hd__sedfxtp_2   sky130_fd_sc_hd__lpflow_inputisolatch_1
```

**The predicate used in this file**, verified to have **zero misses and zero
false positives** against all 428 cells in the liberty:

```
sky130_fd_sc_hd__(s?e?df[a-z]|s?e?dl[rx][a-z]|lpflow_inputisolatch)
```

Ground truth for "sequential" = the cell has an `ff` / `ff_bank` / `latch` /
`latch_bank` group in
`$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib`
(PDK `c6d73a35f524070e85faff4a6a9eef49553ebc2b`). 63 cells qualify.

⚠️ **One judgment call, stated:** `dlclkp_*` / `sdlclkp_*` are excluded. They are
integrated clock gates carrying `clock_gating_integrated_cell : "latch_posedge"`
and a `statetable`, not an `ff`/`latch` group. They hold state but are not
flip-flops, and this flow never emits them. `dly*` delay cells and
`lpflow_inputiso[01][np]` isolation cells are excluded as combinational — a
looser `dl` arm sweeps them in as false positives.

**The hits, shown not summarised** (committed `plane32bus_stat.txt`):

```
      135  2.7E+03   sky130_fd_sc_hd__dfxtp_1
      992 2.98E+04   sky130_fd_sc_hd__edfxtp_1
```

⭐ **The first thing that row pair says**: `edfxtp_1` is **992 in the composed
module and 992 in `core32` alone**. The entire +10 is in plain `dfxtp_1`
(135 vs 32 + 93 = 125). The enable-flop population is untouched by composition —
which is already most of the way to killing H1.

For the record, on the narrow `dfxtp_1|dfrtp_1` predicate silicon retired: it
returns 1127 for `plane32bus` (right total, wrong reason — `dfxtp_1` is a
substring of `edfxtp_1`) and **608 instead of 896** for
`tt_um_saltworks_ndf_stat.txt`. The 288 cells it lost there are
`sky130_fd_sc_hd__dfxtp_2` — a **drive-strength** variant, not an exotic family.
A predicate pinned to `_1` suffixes loses real flops the moment `abc` upsizes one.

## STEP 1 — THE CONFOUND BROKEN. RESULT **1,117**. THE BRANCH IS **FLATTEN**.

Same `synth` command, same everything, one variable removed:

| run | command | seq cells |
|---|---|---|
| R1 | `synth -top plane32bus -flatten` → `dfflibmap` → `abc -liberty` → `opt_clean -purge` | **1,127** |
| R2 | `synth -top plane32bus` (no `-flatten`), rest identical | **1,117** |

R1 reproduces the committed `plane32bus_stat.txt` exactly (sole diff: the
pass-number header line, because `synth.sh` runs `write_verilog` before `stat`).

R2's unflattened report has four sections — `=== core32 ===`, `=== busadapt8 ===`,
`=== plane32bus ===`, and `=== design hierarchy ===`. The last is the aggregate
(counts *including* submodules, rooted at the top), and it is the one to read:

```
=== core32 ===              32 dfxtp_1  +  992 edfxtp_1   = 1024
=== busadapt8 ===           93 dfxtp_1                    =   93
=== plane32bus ===          own cells only; sequential elements: 0.000000
=== design hierarchy ===   125 dfxtp_1  +  992 edfxtp_1   = 1117
```

⚠️ Summing *all four* sections gives 2,234 — the aggregate double-counts the
per-module sections. A seq total taken with a bare `grep | awk` over an
unflattened stat file is wrong by roughly 2×.

⇒ **1,117 unflattened.** The +10 is introduced by **FLATTENING**, and silicon's
framing survives the test that could have refuted it. The hand-rolled pass
sequence in silicon's earlier datum was not the cause — `synth` without
`-flatten` gives the same 1,117.

Standalone baselines were **re-measured**, not taken on faith: fresh runs of
`core32` and `busadapt8` alone give 1024 and 93.

## STEP 2 — THE BISECTION. THE PASS IS **`memory_map`**.

`synth`'s own command list (from `help synth`, yosys 0.68+post) was replayed
pass-by-pass with `stat -width` after each pass, in both configurations. Word-level
flop cells were counted in **bits** (`$sdffe_32` = 32), not cells.

| # | pass | flattened | unflattened |
|---|---|---|---|
| 01 | `proc` | 202 | 202 |
| 03 | `flatten` | 202 | *(skipped)* 202 |
| 05 | `opt_clean` | 133 | 133 |
| 08 | `fsm` | 133 | 133 |
| 09 | `opt` | 125 | 125 |
| 13–15 | `alumacc` / `share` / `opt` | 125 | 125 |
| 16 | **`memory -nomap`** | 125 | 125 |
| 18 | `opt -fast -full` | 125 | 125 |
| 19 | **`memory_map`** | **1127** | **1117** |
| 20–24 | `opt -full` … `abc` … `opt -fast` | 1127 | 1117 |
| 25–27 | `dfflibmap` / `abc -liberty` / `opt_clean -purge` | 1127 | 1117 |

**The two runs are equal at every pass up to and including 18, and diverge
exactly at `memory_map`.** Nothing after it moves either number — in particular
`abc` (pass 23) and `abc -liberty` (pass 26) change nothing.

The row that names the cells:

```
flattened, after memory_map:            unflattened, after memory_map:
  31 x $dff_32   = 992 bits               31 x $dff_32   = 992 bits
   2 x $dff_5    =  10 bits               (absent)
   1 x $sdff_2   =   2 bits                1 x $sdff_2   =   2 bits
   1 x $sdffe_1  =   1 bits                1 x $sdffe_1  =   1 bits
   2 x $sdffe_2  =   4 bits                2 x $sdffe_2  =   4 bits
   1 x $sdffe_30 =  30 bits                1 x $sdffe_30 =  30 bits
   2 x $sdffe_32 =  64 bits                2 x $sdffe_32 =  64 bits
   3 x $sdffe_8  =  24 bits                3 x $sdffe_8  =  24 bits
```

**`2 x $dff_5` = exactly the +10.** Two 5-bit registers = two read-port
addresses, `rs1` and `rs2`, which are 5-bit RISC-V register indices.

### Where the +10 is CAUSED — pass 16, count-neutral, and therefore invisible to a count-only bisection

⚠️ The count moves at 19 but is **decided at 16**. `memory -nomap` runs
`MEMORY_DFF`, and its own log says what it did:

```
flattened:
  Checking read port address `\u_core.regs'[0] in module `\plane32bus': merged address FF to cell.
  Checking read port address `\u_core.regs'[1] in module `\plane32bus': merged address FF to cell.

unflattened:
  Checking read port address `\regs'[0] in module `\core32': no address FF found.
  Checking read port address `\regs'[1] in module `\core32': no address FF found.
```

`memory_dff` merges the address flop into the read port, turning an async read
port into a clocked one. The flop count does not change at that moment — the
`$mem_v2` cell changed shape, not the flop population — so **a bisection that
watched only the count would have named the wrong pass.**

Then `memory_map` lowers a clocked read port as *"register the address, then read
combinationally"*, and emits a fresh 5-bit address register per port. In the
unflattened run the port stayed async and no address register is needed.

### Why the merge does not cancel out

If `memory_dff` had absorbed `instr_r` and deleted it, the net change would be
−54 (two 32-bit flops replaced by two 5-bit ones), not +10. It does not delete
it: `instr_r` drives the whole decoder — opcode, funct3, funct7, rd, immediates —
so all 32 bits survive with their other fanout. The 10 bits are therefore a
**duplicate** of `instr_r[19:15]` and `instr_r[24:20]`, not a relocation.

### The confirmatory probe — `-nordff`

`synth -nordff` is documented as *"prohibits merging of FFs into memory read
ports."* Applied to the flattened run:

```
synth -top plane32bus -flatten -nordff  →  125 dfxtp_1 + 992 edfxtp_1 = 1117
```

**1,117** — exactly the sum of the parts, with the same 125 = 32 + 93 split, and
`MEMORY_DFF` printed no address-merge line at all. One flag, one transform, the
whole delta. The attribution is closed.

## H1 — FANOUT / REGISTER DUPLICATION ON `core32.en`: **DEAD**

*Hypothesis:* `retire` drives the enable of 992 `edfxtp_1` cells; `abc` with a
liberty may duplicate registers to split that load.

*Probe:* `plane32bus_PROBE_EN1` — a copy of `plane32bus` differing in exactly two
lines (module name, and `.en(retire)` → `.en(1'b1)`), synthesised identically.
⛔ Kept in the executor scratchpad, **not** in the tracked RTL: item 10
(kind-must-consult-retire) is two-signature and on the Captain's desk, and
`core32.en`'s shape is untouched by this work.

*Result:* **1,127 — unchanged**, with the identical 135 / 992 split, and the
address-FF merge still firing. Removing the enable network entirely does not move
the delta by one flop.

*Also fatal to H1 independently:* the delta appears at `memory_map`, **four
passes before `abc`** and seven before `abc -liberty`; the bisection shows both
`abc` invocations changing the count by zero. And `edfxtp_1` is 992 in every run
measured — the enable-flop population never changes.

**H1 DEAD.** "Register duplication" is the right family, but the agent is
`memory_map`/`memory_dff` and the victim is `instr_r`'s address slices, not the
enable load.

## H2 — DEAD-BIT SURVIVAL (`in_acc[31:24]`): **DEAD**, as silicon predicted

*Hypothesis:* standalone `busadapt8` declares 101 flops and measures 93; the 8
deleted are `in_acc[31:24]`, never written and never read. If composition changed
that deletion it would be up to +8 of the +10.

*Probe:* `busadapt8_PROBE_ACC24` + `plane32bus_PROBE_ACC24` — `reg [23:0] in_acc;`
with the reset literal renarrowed to `24'd0`. The assembly needed no reindexing:
`in_acc[7:0]`, `[15:8]`, `[23:16]` and `{pin_in, in_acc[23:0]}` are all still
in range. Three changed lines in `busadapt8`, two in `plane32bus`. Scratchpad only.

*Result:*

| | seq cells |
|---|---|
| `busadapt8_PROBE_ACC24` standalone | **93** (unchanged) |
| `plane32bus_PROBE_ACC24` composed, flattened | **1,127** (unchanged) |

*Second, independent measurement of the same fact:* in the bisection, the
flattened composed design holds **125** seq bits from pass 09 through pass 18 —
and 125 = 32 (`pc_r`) + 93 (`busadapt8` survivors), **not** 32 + 101. The 133 → 125
drop at pass 09 (`opt`) is those 8 bits, and it happens in **both** the flattened
and the unflattened run. `in_acc[31:24]` is deleted in composition exactly as it
is standalone.

**H2 DEAD.** Silicon called this in advance and was right.

## THE CONTROL THAT SHOWS THE MECHANISM IS THE RIGHT ONE

`memplane8` also composes `core32` — with `dmem_addr8` + `dmem8` — but its
`instr` is a **top-level input**, so there is no address flop to absorb:

```
memplane8 flattened:  256 dfrtp_1 + 32 dfxtp_1 + 992 edfxtp_1 = 1280
                      = 1024 (core32) + 256 (dmem8) + 0 (dmem_addr8)   ← EXACT
  Checking read port address `\u_core.regs'[0] … : no address FF found.
```

Sum-of-parts holds exactly, and the merge does not fire. The +10 is specific to a
composition in which `core32.instr` arrives from a register — which is what a real
fetch path looks like.

## ⛔ THIS IS NOT CONFINED TO A LOCAL EXPERIMENT — IT IS IN THE SUBMISSION-SHAPED TOP

`tt_um_saltworks_ndf_c32` instantiates `plane32bus`. Measured (needs
`SYNTH_STRUCTURAL=1`; `mac_cell_signed_shell.v` and `ser_organ.v` instantiate
sky130 cells directly):

| run | seq cells | chip area (um²) |
|---|---|---|
| `tt_um_saltworks_ndf_c32` flattened | **1,478** (195 + 288 + 995) | 79,526.27 |
| same, `-nordff` | **1,468** | 77,391.72 |

```
  Checking read port address `\core.u_core.regs'[0] in module `\tt_um_saltworks_ndf_c32': merged address FF to cell.
  Checking read port address `\core.u_core.regs'[1] in module `\tt_um_saltworks_ndf_c32': merged address FF to cell.
```

The flattened run reproduces the **committed** `tt_um_saltworks_ndf_c32_stat.txt`
byte-for-byte (sole diff: the pass-number header). So the 10 duplicated flops are
present in the artifact that would be handed to LibreLane, not merely in a probe.

## THE AREA THE TRANSFORM COSTS

Both rows below differ in one flag only, so the whole difference is downstream of
the read-port merge. It is **more than 10 flops' worth** — the retiming changes
`abc`'s mapping broadly — so read these as *run-to-run differences caused by the
transform*, not as the area of 10 flip-flops (10 × `dfxtp_1` = 200.19 um²).

| object | cells | chip area (um²) |
|---|---|---|
| `core32` alone | 4,444 | 56,778.20 |
| `busadapt8` alone | 504 | 3,804.90 |
| **sum of parts** | 4,948 | **60,583.10** |
| `plane32bus` flattened | 5,131 | 61,308.80 (**+725.70**, +1.20%) |
| `plane32bus` flattened `-nordff` | 5,074 | 60,670.69 (+87.58, +0.14%) |
| `plane32bus` unflattened (hierarchy rollup) | 5,712 | 60,041.33 |
| `tt_um_saltworks_ndf_c32` flattened | — | 79,526.27 |
| `tt_um_saltworks_ndf_c32` `-nordff` | — | 77,391.72 (**−2,134.55**, −2.68%) |

## ⚠️ COLLATERAL FINDING — THE COMMITTED `core32_stat.txt` IS STALE

My fresh `core32` run matches the committed `core32_stat.txt` on **sequential
cells** (32 + 992) and on `sequential elements: 30429.184000` exactly, but not on
combinational cells. Two reasons, both confirmed:

- **It has 168 port bits; today's `core32` has 169.** It was last regenerated at
  `b1463de`, which **precedes `5f25f53` ("enable LANDED")** — the file predates the
  `en` port. Same for its sibling `core32_nl.v`.
- **It was produced in SPLITNETS mode** (`SYNTH_SPLITNETS=1`): 168 ports for 168
  port bits, 1,482 public wires for 1,482 wire bits. The default path gives 11
  ports / 169 port bits / 54 public wires.

The **1,024 figure survives** — today's `core32` measures 32 + 992 = 1024 in a
fresh default-path run, because `pc_r` maps to `dfxtp_1` with or without `en`
(it has a sync reset either way) and `regs`' write enable is `reg_we && rd != 0`
with or without `en`. So `1024 + 93 = 1117` is sound for today's RTL and this
report does not rest on the stale file. But `plane32bus.v`'s own header block
states rung zero's control row as *"any composed-area claim must cite a COMMITTED
stat file whose netlist greps positive for BOTH a core/plane instance AND
banyan_fabric. NO FILE, NO CLAIM"* — and this file no longer describes the RTL
beside it. `busadapt8_stat.txt`, `plane32bus_stat.txt` and
`tt_um_saltworks_ndf_c32_stat.txt` all reproduce from today's RTL; **only
`core32_stat.txt` does not.** Regenerating it is not done here — it is a
tracked-artifact change outside this brief.

## WHAT I COULD NOT DETERMINE — NAMED AS SUCH

1. **Whether the 10 extra flops are provably redundant.** No equivalence check
   was run — not RTL vs netlist, and not flattened vs `-nordff` netlist. The
   reasoning that they are determined by `instr_r` and add no reachable state is
   *reasoning*, not a receipt. If the composed netlist's state set is load-bearing
   for any proof, this needs an `equiv`/miter run, and that is not in this file.
2. **Whether LibreLane's flow performs the same merge.** LibreLane flattens, and
   it runs yosys, so it plausibly does — but I ran only the local `synth.sh`
   sequence. The fabricated netlist was not measured. `synth.sh` says in its own
   comments that it is not the artifact the equivalence proof targets.
3. **Whether the merge is desirable.** It is a legitimate retiming that buys
   nothing here (the address register is a duplicate) and costs area. Whether
   `-nordff` should become part of the flow is a **ruling for silicon**, not an
   executor call. ⛔ `synth.sh` is **unchanged** by this work: turning `-nordff`
   on would stop the flow reproducing every committed netlist, which is the exact
   hazard `synth.sh`'s own SPLITNETS comment argues against.
4. **Whether other composed tops beyond those measured are affected.**
   `plane32bus`, `tt_um_saltworks_ndf_c32` (affected) and `memplane8`
   (not affected) were measured. `tt_um_saltworks_ndf` and the remaining tops
   were not swept.
5. **Why `proc` reports 202 flop bits** when the RTL declares 133 (32 + 101),
   dropping to 133 at `opt_clean`. Pre-optimisation `proc` artifacts; identical in
   both runs at every pass, so irrelevant to the delta and not chased.

## REPRODUCTION

```sh
LIB=$HOME/.volare/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/\
sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
R=SaltWorks/Silicon/RTL
SEQ='sky130_fd_sc_hd__(s?e?df[a-z]|s?e?dl[rx][a-z]|lpflow_inputisolatch)'

# 1127 with -flatten; 1117 without; 1117 with -flatten -nordff.
# Vary ONLY the synth line. Never `yosys -q`, never `2>/dev/null` — both
# produced an EMPTY report during this morning's work, and an empty report
# reads as "no modules found". Run bare and check line counts.
yosys -p "
  read_verilog $R/plane32bus.v $R/busadapt8.v $R/core32.v
  synth -top plane32bus -flatten
  dfflibmap -liberty $LIB
  abc -liberty $LIB
  opt_clean -purge
  tee -o /tmp/p_stat.txt stat -liberty $LIB"
grep -E "$SEQ" /tmp/p_stat.txt | awk '{s+=$1} END{print s+0}'
```

The dependency closure was recomputed independently with `synth.sh`'s own
algorithm rather than assumed: `plane32bus.v busadapt8.v core32.v`. `core32` is a
leaf — its only mentions of `dmem_addr8` and `memif` are in comments.
`plane32bus` does not need `SYNTH_STRUCTURAL=1`; `tt_um_saltworks_ndf_c32` does.

---

**Bottom line.** 10 flops is 0.9% and moves no composed-area conclusion. But the
synthesiser added state that the RTL does not declare — the composed netlist
carries 1,127 flops against 1,125 declared bits, 1,117 of them live — and it did
so through a transform whose *cause* is count-neutral and whose *effect* lands
three passes later. Both of the plausible-sounding explanations were wrong. The
number is small; the class is not.

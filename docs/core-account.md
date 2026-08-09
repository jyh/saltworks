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

<!-- COMPILER FILLS. Sources: CoreOffsets.lean (measured dimensions),
     CorePlace.lean (placements, port maps, instOK), the organ modules
     (sem_* certificates), the mutation-control runs. -->

### 1.1 The organ inventory (sixteen rows)

| row | organ | gates | state bits | offset | port map | sem_* certificate | instOK | controls run |
|---|---|---|---|---|---|---|---|---|
| 0 | tie cells | | | | | | | |
| … | | | | | | | | |

### 1.2 Totals and state

<!-- total gates · total flops (regfile 480 + PC 31 + …) · nets -->

### 1.3 The theorem inventory

<!-- which certificate covers which organ; the composition machinery
     (instOK / inst_compose); what remains for the single-cycle
     refinement; axioms audit summary -->

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

⚠️ **2,982 gates against 2,981 instances — a ONE-GATE DIFFERENCE I HAVE NOT
EXPLAINED, stated rather than rounded away.** *`EmitS.lean:189` independently
reports 2,981 instances and 0 `assign` lines, so the emitter and my count agree
with each other and disagree with the kernel row by one. Compiler's slot to
resolve; a plausible cause is a `.const` gate emitting as a tie rather than a cell,
but that is a GUESS and is labelled one.*

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

## 3. THE JOINT READING — maestro, after both halves land

<!-- the kernel-object ↔ silicon-object correspondence, stated once:
     what the RTL twin is, what emitS changes, what the refinement
     theorem will add when W5-asm closes -->

## 4. THE FENCES — evidence's pass

> ### ⏳ STATUS: **CRITERIA PRE-REGISTERED, PASS NOT YET RUN** (evidence, 2026-08-09 13:2x)
>
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

### 4.2 The three failure modes this pass exists to catch

*Named in advance so nobody has to be surprised by the verdict:*

1. **A TOKEN COUNT WHERE A COMMAND COUNT IS MEANT.** *Live example from this
   fleet today: `grep -c '#audit_axioms'` = 38, `grep -c '^#audit_axioms'` = 36,
   build ticks = 36. The two extras were prose ABOUT the instrument.* **In a
   document that describes its own instruments, grepping the instrument's name
   hits the description. Anchor positionally.**
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

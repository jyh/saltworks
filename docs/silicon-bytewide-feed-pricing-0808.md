# THE CAPTAIN'S THIRD FEED SHAPE — THE BYTE-WIDE CORE, PRICED
### 2026-08-08 ~21:1x, SILICON. His question, verbatim (relayed 21:09):
### *"what about an 8-bit pinout architecture? (so a 32 bit load takes 4 cycles)"*
### Built and synthesized before any claim — the 19:37 zero-cell lesson stands.
### Flow: `Silicon/Flow/synth.sh`, sky130_fd_sc_hd, PDK `c6d73a35…`, default flow.

## THE ANSWER IN ONE LINE

> **THE BYTE-WIDE FEED IS FREE IN AREA — 2,706 cells vs the serial core's 2,709,
> THREE CELLS *SMALLER* — AND IT BUYS AN 8× SPEEDUP. THE ENTIRE COST IS PINS,
> AND THE PIN COST IS EXACTLY WHAT EXCLUDES CO-TENANCY: it needs 10 signals and
> the switch's tile can offer at most 7.**

## 1 · THE THREE FEED SHAPES

```
variant            signals  cycles/word  cells   area µm²   instr/s @25MHz  co-tenant?
slicea16  parallel      64            1      —  not tapeable    25,000,000   no (64≫24)
slicea16b byte-wide     10            4   2706     27,646.5      6,250,000   NO  (10>7)
slicea16s serial         3           32   2709     27,676.5        781,250   yes
```
*signals = the instruction feed only (`instr_*`), excluding clk/rst_n and the
bring-up `pc_out[7:0]`, which is optional in all three.*

## 2 · ⭐ WHY THE AREA IS FLAT, AND IT IS NOT A ROUNDING RESULT

**Both variants hold the SAME 32-bit instruction register and the SAME 527
flops.** The only difference is which bits of `ir` come from outside:
```
slicea16s   ir <= {instr_bit,  ir[31:1]}    31 bits recirculate, 1 arrives
slicea16b   ir <= {instr_byte, ir[31:8]}    24 bits recirculate, 8 arrive
```
🔑 ***THE BYTE-WIDE FORM RECIRCULATES FEWER BITS, SO IT IS VERY SLIGHTLY
CHEAPER.*** *That is the whole of the −3 cells / −30 µm². **A wider feed does not
buy a wider register — the register was always 32 bits.** The intuition that
"8 bits in must cost 8× the input logic" is wrong here: the input logic is one
mux stage on a register that already exists.*

⇒ **THE PINS-VS-CYCLES TRADE IS NOT A PINS-VS-AREA TRADE. Area is flat across a
32× range of feed width, so it should not appear in the decision at all.**

## 3 · THE PIN LEDGER — **READ** from `TT/src/project.v`, not inferred

```
ui_in[7:0]     8   ALL consumed by the switch: banyan_fabric #(.PAYLOAD(8)) .din(ui_in)
uo_out[7:0]    8   ALL consumed by the switch: .dout(uo_out)
uio[0]         1   sof, INPUT (uio_oe bit 0 = 0) — the switch needs it
uio[5:1]       5   OUTPUTS (uio_oe = 8'b0011_1110): cnt[3], valid, cnt[2:0]
                   — OBSERVABILITY ONLY, reclaimable at the cost of bring-up
uio[7:6]       2   uio_oe = 0, driven low — genuinely FREE
                   ────
co-tenant budget:  2 free + 5 reclaimable = 7 SIGNALS MAXIMUM
```
⚠️ **THE READING THAT DECIDES IT: THE SWITCH IS *ALREADY* A BYTE-WIDE DESIGN.**
`banyan_fabric #(.PAYLOAD(8))` takes all 8 `ui_in` and drives all 8 `uo_out`.
*The Captain's 8-bit shape is the shape the tile's existing tenant already uses —
and that is precisely why they cannot share it: **both want the same eight
dedicated input pins, and there is exactly one set.***

## 4 · ⛔ THE CONSEQUENCE FOR THE TILE DECISION — THE TWO CHOICES ARE ONE CHOICE

```
byte-wide co-tenant (a)   needs 10, budget 7   ⛔ DOES NOT FIT, even after
                                                  sacrificing ALL bring-up pins
byte-wide own tile  (b)   needs 10, budget 24  ✅ fits with 14 to spare
serial    co-tenant (a)   needs  3, budget 7   ✅ fits (this is the "one pin to
                                                  recover" already on the sheet)
```
⇒ ***CHOOSING THE CAPTAIN'S BYTE-WIDE SHAPE *IS* CHOOSING OPTION (b), €280. The
feed width and the tile are not two decisions — they are the same decision seen
from two sides.*** **And the price of (a) is now nameable in his own units: co-
tenancy costs a factor of EIGHT in instruction throughput (781 K/s vs 6.25 M/s),
not a factor in area.**

## 5 · METHOD — why the delta is attributable

**`slicea16b.v` was TRANSFORMED from `slicea16s.v`, not retyped.** The diff is
**three code lines** — module name, port width, shift expression — and everything
else is byte-identical, so the measured difference is the feed width and nothing
else. *Retyping the core would have introduced an unrelated difference and I
would have attributed it to the feed.* **Verified by `diff` before synthesis, not
after.**

## 6 · ⛔ NOT MEASURED HERE — scope inside the verdict

- **Post-layout.** These are yosys pre-layout areas. *A LibreLane run on this
  same core is in flight tonight; post-layout numbers supersede these for any
  tile-fit claim.*
- **Timing.** Combinational depth is 69 levels (`ltp -noff`) with the critical
  path originating in the register file. **A depth is not a delay** — no STA has
  been run, so nothing here says whether 25 MHz closes.
- **The host side.** A byte-wide feed needs the host to supply 8 bits/cycle; the
  serial one needs 1. *Not a chip cost, but it is a system cost and it is real.*
- **`instr_commit` sharing.** Both variants spend a pin on commit. *A protocol
  that encoded commit in the data stream would save one signal in both, and
  would change the serial core's co-tenant margin from 4 spare to 5.*

---

## 7 · ⭐ POST-LAYOUT — MEASURED, AND IT MOVES THE TILE ANSWER (21:3x)

**LibreLane 3.0.5, PDK `c6d73a35`, `CLOCK_PERIOD 40` (25 MHz), `FP_CORE_UTIL 45`.
Metrics committed under `Flow/layout-metrics/`.**
```
                 pins  cyc/word   pre-layout   POST-LAYOUT   ratio   % of 2×2 usable
slicea16b          10         4     27,646.5      43,120.1   1.56×        95.1%
slicea16bma        18         4     29,583.4      45,205.9   1.53×        99.7%
                                                       2×2 usable @60% = 45,361.6
```
```
                 DRC  LVS  antenna   setup slack   hold slack   max-slew
slicea16b          0   ✅        0     +19.29 ns   +0.112 ns       1,391
slicea16bma        0   ✅        0     +16.91 ns   +0.122 ns       1,678
```

⛔ ***THE HEADLINE: `-ma` CLEARS A 2×2 BY 155.7 µm² — ABOUT 25 STANDARD CELLS.
THAT IS TECHNICALLY A FIT AND PRACTICALLY NOT ONE***, because 1,678 max-slew
violations remain and DRV repair ADDS cells. **Reported as DOES NOT FIT a 2×2.**
✅ **A 3×3 puts it at 44% — comfortable, with room for repair and an ECO.**
*The Captain's word named "its own tile", not its size, and tiles buy area; the
pin count (18 ≤ 24) is the thing a tile could never fix, and it was already yes.*

🔑 **AND THE FAMILY-WIDE READING: even the SMALLER `-b` is at 95.1%. A 2×2 was
never comfortable for a 16-register Slice-A at 32 bits — my pre-layout "61%" hid
that, and only the real flow found it.** *Fourth independent instrument naming
the register file as the mass.*

📌 **USE 1.55× AS THE YOSYS→POST-LAYOUT RULE** for this cell family and this
flow — measured twice, 1.56× and 1.53×. *About 22% of the growth is
timing-repair buffering, which synthesis cannot see at all.*

⛔ **STILL NOT A TT TILE-FIT TEST:** both runs used `FP_CORE_UTIL 45`, not TT's
`FP_SIZING: absolute` at the fixed tile die. *These give trustworthy CELL AREA;
the fit test is a separate run and is now worth doing.*

## 8 · ⚠️ THE DRV NUMBERS ARE CORNER-SCOPED — read this before quoting them

**A single reported DRV count is an AGGREGATE OVER PVT CORNERS and LibreLane
reports the WORST one. I published "1,678 max-slew violations" four times before
reading the breakdown.**
```
max-slew violations, all nine corners        max     min     nom
ff  (fast, −40 C, 1.95 V)                    337     112     216
tt  (typical, 25 C, 1.80 V)                  637     473     565
ss  (slow, 100 C, 1.60 V)                   1678    1280    1460   ← reported
```
⇒ **The typical-corner figure is 637, not 1,678.** *Quoting a DRV count without
its corner is quoting an unnamed scope — [[a-count-is-not-a-scope]].*
⚠️ **The debt is REAL nonetheless: slew violates at EVERY corner including
typical, so it is not a worst-case artifact.** *Max-cap, by contrast, IS nearly
a worst-case artifact — 39 at `ss`, ZERO at `tt` and `ff`.*

✅ **AND SETUP IS STRONGER THAN FIRST REPORTED — IT CLOSES AT ALL NINE CORNERS:**
```
worst  +16.914 ns (ss/max) · typical +27.596 ns · best +29.335 ns   on 40 ns
```
*"Setup met" and "setup met at all nine corners with 16.9 ns of worst-case
margin" are different sentences; the second is the one the pack should carry, and
that margin is headroom the DRV repair can spend.*

📌 **REFUTED EN ROUTE, recorded so nobody retries it: `MAX_FANOUT_CONSTRAINT: 10`
does NOT help.** *A controlled pair came back bit-identical (slew 1678, cap 39,
fanout 11, area and setup slack to 15 digits). **The discriminator was already in
the metrics — `max_fanout_violation__count` is 11 while slew is 1,678, so fanout
was never the lever.** Four minutes spent answering a question the file had
already answered.*

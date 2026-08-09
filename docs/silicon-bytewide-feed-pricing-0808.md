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

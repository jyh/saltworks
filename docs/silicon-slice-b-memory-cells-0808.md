# SLICE-B B1 — THE MEMORY ORGAN PRICED IN CELLS, against the 1,154 banked
### 2026-08-08 ~20:5x, SILICON. Refutation assignment `slice-b-design-v1.md:129`.
### Measured with `Silicon/Flow/synth.sh`, sky130_fd_sc_hd, PDK `c6d73a35…`,
### DEFAULT flow (abc free to restructure — these are optimised numbers).
### Companion: `silicon-whole-core-net-0808.md` (the owed one-liner).

## THE ANSWER

> **THE MEMORY ORGAN DOES NOT FIT THE BANKED SAVING AT ANY SIZE I PRICED. The
> smallest useful memory — 8 words — is 1.50× the budget. 32 words is 6.25×,
> and alone fills 96% of a 2×2 tile's usable area at the default density.**

## 1 · THE CURVE (a curve, not a point — the design question is where it crosses)

```
size      cells  flops     area µm²   seq µm²   %seq   × budget   % of 2×2 usable
dmem8       673    256        10,484     6,406  61.1%     1.50×        23%
dmem16     1369    512        21,183    12,812  60.5%     3.03×        47%
dmem32     3034   1024        43,613    25,625  58.8%     6.25×        96%
```
*budget = 1,154 gates × 6.05 µm²/gate = 6,982 µm² · 2×2 usable = 45,362 µm²
(75,603 µm² at `PL_TARGET_DENSITY_PCT` 60) · flops confirm exactly: 8×32=256,
16×32=512, 32×32=1024.*

## 2 · ⛔ THE TRAP IN MY OWN TABLE — DO NOT READ THE CELLS COLUMN AS THE ANSWER

**`dmem8` is 673 CELLS against a 1,154-GATE budget. By COUNT it looks like the
organ fits with 42% to spare. IT DOES NOT — by AREA it is 1.50× over.**

🔑 ***A kernel `Circ` gate and an optimised standard cell are not the same unit.
Optimised cells are FEWER and BIGGER: one `mux2_1` does the work of three kernel
gates and costs 11.3 µm². Comparing 673 to 1,154 compares a post-abc count to a
pre-abc count and flatters the design by ~2.5×.*** ⚠️ **This is the council §3
unlike-columns trap in a new place — there it was structural-vs-optimised cells
in one table; here it is cells-vs-gates across two documents, which is harder to
see because the columns never sit side by side.** ✅ **µm² IS THE ONLY HONEST
AXIS between these two objects, and every ratio above is computed on it.**

## 3 · ✅ THE BIAS RUNS AGAINST MY CONCLUSION, WHICH IS WHY I TRUST IT

**The budget's 6,982 µm² is computed at the STRUCTURAL rate (passthrough, cells
= gates, from the BB-switch §3 measurement).** *A real select synthesised
behaviourally would let abc compress those 1,154 gates into fewer, larger cells
— so the TRUE area freed by the re-cut is **≤ 6,982 µm²**, probably well under.*
**Meanwhile every `dmem` number is already optimised.**
⇒ ***The comparison is biased IN THE BUDGET'S FAVOUR and the memory still does
not fit. Correcting the bias widens the gap; it cannot close it.***

## 4 · WHERE THE AREA GOES, and it is the same everywhere

**Sequential elements are ~60% of the area at ALL THREE SIZES (61.1 / 60.5 /
58.8%).** *The array dominates and the ratio barely moves, so there is no size
at which the read mux stops mattering or the flops start amortising.* The other
~40% is the read path: `dmem32` maps to **1,024 `mux2_1`** — 31 muxes per bit ×
32 bits — **which is the same shape as `readTree`'s 2,982 gates, arrived at by a
completely different instrument.** *Two tools, no shared input, one structure.*

## 5 · WHAT THIS MEANS FOR B1, stated as design consequences

1. **A 32-word register-backed memory is not co-tenantable.** At 96% of a 2×2's
   usable area it leaves nothing for a core, and the switch fabric (2,143 µm²)
   would not fit beside it either.
2. **8 words (23%) is the only size with real headroom** — `dmem8` + fabric =
   12,627 µm², 28% of usable, leaving room for a serial core. **16 words (47%)
   is the honest ceiling for a co-tenant tile.**
3. **The organ competes with the REGISTER FILE, not with the select** — as the
   whole-core measurement independently concluded. *Both are flop arrays with a
   wide read mux; they are the same cost structure, and Slice-B adds a second
   one.*
4. ⭐ **THE REAL LEVER IS NOT SIZE, IT IS THE BACKING.** *Flops are ~60% of every
   row. A compiled sky130 SRAM macro is far denser per bit — but it is a
   DIFFERENT REGIME and must never share a column with these numbers (§2's
   lesson). If B1 wants more than 16 words, the question to ask is "SRAM macro?",
   not "how many more flops can we afford?"*

## 6 · ⛔ NOT PRICED HERE — the scope, inside the verdict

- **B4's alignment mask** — a separate assigned row; these are word-addressed
  with NO byte enables. *Byte writes would add a mask layer this table omits.*
- **The SRAM-macro alternative** — named above as the lever, not measured. *TT
  tile support for macros is unverified by me.*
- **Routing, placement, congestion** — yosys pre-layout areas, one mapping pass.
- **The reset.** *These clear the array on `rst_n` because B-EXEC's isolation
  story wants a defined initial state. That forces resettable flops and costs
  area; a no-reset variant is cheaper and I did not measure it.*

# RP2040 PIO MEMORY SERVER FOR THE BYTE-PHASE BUS

Written against **ratified option (2)** — §7's "+4" second LOAD loop (council
09/04 ruling (7), on silicon's signature 09/03 18:34:07 and compiler's 18:27,
with compiler's two amendments).

## What is here

| file | what it is | is it RUN? |
|---|---|---|
| `ndf_memserver.h` / `.c` | the protocol core — pure C, no SDK | ✅ **replayed against the Verilog bench's own pin trace, 6/6** |
| `ndf_memserver_replay.c` | the replay check | ✅ run |
| `run_firmware_replay.sh` | the gate, with a mutation control | ✅ run, exits non-zero on a bad arm |
| `ndf_bus.pio` | the PIO byte-phase engine | ⛔ **NOT ASSEMBLED HERE** — no pico SDK on this box |
| `ndf_pico_main.c` | SDK glue: pins, reset, the service loop | ⛔ **NOT COMPILED HERE. Unrun code.** |

⛔ **THE SPLIT IS THE POINT.** Firmware for a board nobody here has is unrun code,
and unrun code's *text* is as unverified as its logic. So the protocol — the part
that can actually be wrong in a way that matters — was written as **pure C with no
SDK dependency**, and is measured:

```
run_firmware_replay.sh
  pin trace from tb_plane32bus_reghost: 900 cycles
  phases compared=564 (of which LOAD data=112)  mismatches=0  desync=0
  server memory mem[64..67]=00000040
  ==> FIRMWARE REPLAY: ALL PASS (6/6)
  ARM RED (option (2) lookup defeated): mismatches=28, F2 RED
  FIRMWARE_REPLAY=PASS
```

The trace comes from `Sim/reghost/tb_plane32bus_reghost.v`, the registered-host
bench that scores **6/6** against option (2) and **2/6** against the one-loop LOAD.
The gate refuses if that bench is not green: *a trace from a failing bench compares
the firmware against a machine that is not working.*

## The protocol this server speaks

- one loop = 4 phases = 4 DUT clocks; the phase counter **free-runs**
- `uio_out[1:0]`: **TYPE at phase 0**, the phase number at 1..3 — `00` IDLE `01`
  FETCH `10` LOAD `11` STORE
- `uio_in[6]` = `sof` forces phase 0. **The host realigns the frame**, which is why
  this server keeps its own phase counter and never has to guess where it is.
- **FETCH** 1 loop · **LOAD** 2 loops (address, then *host* drives data) · **STORE**
  2 loops (address, then *chip* drives data)
- ⇒ every memory transaction is exactly two loops. **CPI: non-memory 4, LW 12, SW 12**
  — §7's own table, and measured at the object (600-cycle loop census 
  `F86·L21·S43` → `F75·L37·S38`; on compiler's `28/14/14` histogram, 392 → 448 cycles,
  **+14.29%**).

## ⛔ THE TWO PRECONDITIONS, NAMED HERE AND NOT BURIED

**1 · THE HOST OWNS THE CLOCK, AND THAT IS WHY THERE IS NO WAIT-STATE PIN.**
`ndf_bus.pio` stalls at `pull` **with the project clock held LOW**. That stall *is*
the wait state the design has no pin for. This is legitimate on this platform and
not a trick: `docs/tinytapeout-dossier.md` §2.1 records the demo board generating
the project clock from the RP2040 PWM/PIO, **1 Hz – 66.5 MHz**, with
`tt.clock_project_PWM(0)` **stopping it outright**.
⇒ the per-phase budget is **unbounded**, so the CPU may read the pins, decide, and
answer within one phase with no timing analysis at all.
⛔ **That is a property of the DEMO BOARD, not of the design.** Under a free-running
clock this program is wrong.

**2 · OPTION (2) FIXES §7's LOAD ROW AND NOT ITS FETCH ROW.**
§7 gains "+4" on the LOAD row only, while its own text says the load's assumption
holds *"exactly as the instruction does during a fetch"*. So the **fetch still
demands an in-phase turnaround**, which precondition 1 is what makes satisfiable
here. Measured, `Sim/reghost` arm `REGHOST_FETCH`: with the fetch registered too,
the machine runs **225 fetch loops and ZERO memory transactions**, registers never
resolve. **That gap is a SEPARATE two-signature row and is NOT part of option (2)
and NOT a defect in it.** Do not read a working bring-up as closing it.

📌 The LOAD service is nevertheless written the way a *free-running* host would have
to write it — the lookup happens at the **end of the address loop**, with the whole
address in hand, and the first data byte is not due until the next phase 0 — even
though the stalled clock would forgive a later lookup. That keeps the load path
correct if the clock is ever let free-run, which is exactly what option (2) bought.

## ⚠️ BEFORE THIS IS FLASHED

The GPIO numbers in `ndf_pico_main.c` are **PLACEHOLDERS, marked as such**. They
must be taken from the demo board pinout. I did not have that document at this
hand, and a plausible-looking GPIO number is precisely the sort of figure this seat
has been bitten by before.

## Scope
Simulation and replay only. **No timing claim about real PIO.** The harness is test
equipment — the trust class of a logic analyzer — exactly as the queue row says.

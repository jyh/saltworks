# RESULTS — §7's "+4" IS IN THE RTL, MEASURED RED-FIRST; THE FIRMWARE HAS A RECEIPT;
# AND THE FETCH ROW IS A GAP OPTION (2) DOES NOT CLOSE
### silicon, 2026-09-04 10:4x. Criteria pre-registered in
### `docs/silicon-ndf-option2-plus4-prereg-0904.md` before the RTL was touched
### and before the bench existed. Baseline `origin/master` `62843742`.
### Toolchain: iverilog (Icarus) + cc. Every figure below is from a committed producer.

## 1 · WHAT LANDED

`busadapt8.v`: `load_beat` mirrors `store_beat`; `retire`'s `T_LOAD` arm goes from
`1'b1` to `load_beat`; the inbound capture is gated on the LOAD's **data** loop.
⇒ **every memory transaction is now exactly two loops.**

⛔ **COMPILER'S AMENDMENT 1 IS HONOURED AT THE OBJECT.** My 09/03 sentence *"needs no
change to the ratified arbitration"* was true of the ARBITRATION RULE and let the
reader carry it to THE MODULE, which is false. This **does** change `retire` for
`T_LOAD` and therefore compiler's kernel model. The bill is named in the module's own
header, not left to be discovered downstream.

⛔⛔ **COMPILER'S AMENDMENT 2 IS NOT DISCHARGED AND IS NOT COUNTED AS HANDLED.** The
`sof` arm still does not consult `retire`. That is a separate two-signature row. This
edit touches that arm only to clear `load_beat` exactly as it already clears
`store_beat` — **the same treatment, not the repair.**

## 2 · THE RED-FIRST PAIR — `Sim/reghost/run_reghost_plus4.sh`, rc 0

The host drives `pin_in` **from a flop**: it can never answer in the cycle it is asked.
That single property is the whole experiment.

| arm | LOAD shape | result |
|---|---|---|
| **RED** (mutation) | one loop, `retire = 1'b1` | **2/6 — G3 and G4 FAIL**, `x3=00000000`: the loaded word never reaches a register |
| **GREEN** (as shipped) | two loops, `retire = load_beat` | **6/6** |
| **G2 on both** | the store path, which needs no turnaround | **PASSES ON BOTH ARMS** |

G2 is the control that matters: it is why the red is a finding about the LOAD row and
not about the bench. The runner exits non-zero unless that whole shape holds.

📌 **TWO INSTRUMENT DEFECTS CAUGHT IN THE MAKING, BOTH IN THE CONTROL AND NOT THE DATA:**
(i) my first mutation marker was `//` and it **silently ate the rest of a one-line
statement** — the mutated file did not parse, and `iverilog` giving up prints the same
nothing as a control that never applied. The runner now asserts the mutation **applied
(2/2 sites)** and **compiles**, refusing loudly on either. This seat's own law: *when a
check and its data disagree, suspect the check.*

## 3 · THE REGRESSION BAR, PRE-STATED AND MET

`tb_plane32bus_lwsw.v` (combinational host): **7/7 before and 7/7 after**, and
`run_lwsw_bypass_control.sh` still reports `BYPASS_CONTROL=PASS` (ARM A 0 fails, ARM B
2 fails reproducing the 08/18 signature `st_data=00000000 · instr=0000a183`).

## 4 · 📐 THE CPI, MEASURED AT THE OBJECT AND NOT FORWARDED

600-cycle loop census, both totalling 150 loops:

| | FETCH | LOAD | STORE |
|---|---|---|---|
| before (one-loop LOAD) | 86 | 21 | 43 |
| after (option (2)) | 75 | 37 | 38 |

⇒ **LW 8 → 12, SW 12 unchanged, non-memory 4 — exactly §7's own table** for the
"host cannot turn a read around in-phase" case. On compiler's instruction histogram
(`4cyc=28 · 8cyc=14 · 12cyc=14`, reproduced at my hand from the tracked
`tb_retire_discriminating.v`): **392 → 448 cycles, +56, +14.29%** — the figure I signed,
now confirmed by an independent route.

## 5 · ✅ THE FIRMWARE, AND IT HAS A RECEIPT

`SaltWorks/Silicon/Firmware/rp2040/`. The protocol core is **pure C with no SDK
dependency**, which is what makes it checkable: `run_firmware_replay.sh` replays it
against the **pin trace emitted by the 6/6 registered-host bench** and compares byte
for byte at every phase the DUT actually consumes.

```
  trace cycles=900  loops: FETCH=113 LOAD=56 STORE=56 IDLE=0
  phases compared=564 (of which LOAD data=112)  mismatches=0  desync=0
  server memory mem[64..67]=00000040
  ==> FIRMWARE REPLAY: ALL PASS (6/6)
  ARM RED (the +4 lookup defeated): mismatches=28, F2 RED
  FIRMWARE_REPLAY=PASS
```

- **F3 pins the COUNT of compared phases to the protocol's own prediction**
  (`4·FETCH + 4·LOAD/2`), because a comparison restricted to "phases the DUT consumes"
  is exactly the shape that goes vacuous unnoticed.
- **F1 is not vacuous either**: `desync` is checkable at phases 1..3, i.e. **3 of every
  4 phases**, because at phase 0 those pins carry the TYPE instead.
- The gate **refuses if the source bench is not green** — a trace from a failing bench
  compares the firmware against a machine that is not working.

⛔ **WHAT IS NOT RUN, SAID PLAINLY RATHER THAN LEFT TO THE FILE LIST:** `ndf_bus.pio`
is **not assembled** and `ndf_pico_main.c` is **not compiled** — there is no pico SDK
and no RP2040 on this box. **Their text is as unverified as their logic.** The GPIO
numbers in the glue are **marked placeholders**; they must come from the demo board
pinout before anything is flashed.

## 6 · ⛔⛔ THE FINDING — AND IT WAS PRE-REGISTERED AS A QUESTION (prereg §5)

**Option (2) relieves §7's LOAD row only.** §7's own text says the load's assumption
holds *"exactly as the instruction does during a fetch"* — so **the FETCH row still
demands an in-phase turnaround.**

Measured, arm `REGHOST_FETCH` (the fetch registered too, under option (2)):
**225 FETCH loops · 0 LOAD · 0 STORE · registers never resolve.** The machine executes
nothing at all.

⇒ ***OPTION (2) IS NECESSARY AND NOT SUFFICIENT FOR A FULLY REGISTERED HOST.***

**This is a NEW ROW. It is not a defect in (2) and not part of it** — widening a
ratified option at the object would be a seat ratifying its own scope. It was written
into the pre-registration *as a question I expected to measure*, so that a red here is
a result and not a discovery that arrives conveniently after the fact.

### The fork, both arms, priced

1. **(A) SYMMETRIC "+4" ON THE FETCH ROW.** Fetch becomes two loops. Non-memory 4→8,
   LW 12→16, SW 12→16; the same histogram **448 → 672, +50% on top of (2)**. Another
   change to `retire` in a ratified module ⇒ **its own two-signature row.**
2. **(B) THE HOST OWNS THE CLOCK.** Receipt *in this repository*:
   `docs/tinytapeout-dossier.md` §2.1 — *"demo board generates it from the RP2040
   PWM/PIO"*, 1 Hz–66.5 MHz, and **`tt.clock_project_PWM(0)` stops the clock**. Zero
   RTL, zero DUT-cycle cost. The price: the bus rate becomes the host's service rate,
   and it holds **only where the host owns the clock** — true on the demo board, false
   for any free-running deployment.
3. **(C) prefetch the instruction stream** — refuted: the host cannot know the next PC
   across a branch.

⭐ **RECOMMENDATION, AND I PROCEEDED ON IT RATHER THAN WAITING: the firmware is written
against (2)+(B).** (B) needs no ruling and is how the board is actually wired; (2) is
what makes the LOAD path correct **the moment the clock free-runs**, which is exactly
when (B) is unavailable. **(A) is registered as a new two-signature row** with the
pricing above. The firmware's LOAD service is deliberately written the way a
free-running host would have to write it — the lookup at the **end** of the address
loop — so that path stays correct if (A) ever lands.

## 7 · SCOPE, UNCHANGED
Simulation and replay against the RTL. **No timing claim about real PIO.** The harness
is test equipment — the trust class of a logic analyzer — exactly as the queue row says.
Nothing here touches the verified surface.

## 8 · ⛔⛔ A SEPARATE FINDING, FOUND BY READING THE TRACKED BENCH RATHER THAN RUNNING IT
### `tb_plane32bus_lwsw.v`'s L3 HAD BEEN PASSING BY COINCIDENCE SINCE THE BENCH WAS WRITTEN

The combinational host computed its load base as `wire [7:0] la = pin_out;` —
**and `pin_out` is a different address byte in every phase.** So at phase 1 it looked
the word up at base `addr[15:8]`, at phase 2 at base `addr[23:16]`, and served bytes 1
and 2 of a word read from the wrong place.

**It scored green because three zeroes covered for each other:** the program's address
is `0x40` (upper bytes 0), the datum is 64 (upper bytes 0), and the memory was filled
with `0x00`.

✅ **DRIVEN, ONE VARIABLE — NOTHING BUT THE FILL PATTERN CHANGED:**

| bench | host | result under a `0xAA` background |
|---|---|---|
| `tb_plane32bus_lwsw` (old host) | reads `pin_out` as the address | **L3 RED, `x3 = 0xaaaaaa40`** |
| `tb_plane32bus_reghost` | **latches** the address across the loop | **6/6 GREEN, `x3 = 0x00000040`** |

The second row is what makes this a finding about the host and not about the
perturbation: the same fill against a correctly-latching host changes nothing.

🔑 ***A HOST MUST LATCH THE ADDRESS ACROSS THE LOOP. A bus that hands over one byte per
phase does not have an address until the loop is over, and reading `pin_out` as "the
address" is reading a byte as a word.***

✅ **REPAIRED, AND THE FIXTURE IS NOW THE GUARD:** the host latches at phase 0 and
serves from that base; **both benches now initialise memory to `0xAA`**, so anyone who
reintroduces the defect gets an immediate L3 red instead of a coincidence. *A permanent
control in the fixture beats a measurement in a document.* `BYPASS_CONTROL=PASS`
retained (ARM A 7/7, ARM B 2/7 with the recorded 08/18 signature).

⚠️ **WHAT THIS DOES AND DOES NOT CHANGE.** It does not touch option (2), the RTL, or any
verdict in §§1–7 — `run_reghost_plus4.sh` and `run_firmware_replay.sh` are green before
and after. What it changes is **how much L3 was ever worth**: the LW data path was
end-to-end checked only for words whose upper three bytes were zero.

## 9 · ✅ FORK ARM (A) IS NO LONGER A FORECAST — IT IS MEASURED
### ⛔ FACT-FINDING, NOT A RULING. (A) remains UNRATIFIED and needs two signatures.

In §6 I priced arm (A) — a symmetric "+4" on §7's FETCH row — **by arithmetic, and
never drove it.** *A forecast is the one kind of claim nobody runs a control on*, and
this seat has a banked law about exactly that. So it is driven now.

`run_armA_factfinding.sh` derives the variant from the shipped `busadapt8.v` **into a
temp directory** and deletes it — there is deliberately **no second copy of a ratified
module in this tree**, because a dead twin is this seat's most expensive recurring
defect. `armA_patch.py` **refuses** if any of its 8 edits matches other than exactly
once: *a variant built from a patch that did not apply IS the shipped design, and it
would score green and mean nothing.*

| arm | RTL | fully-registered host |
|---|---|---|
| **(A)** | symmetric "+4", fetch = 2 loops | **6/6 — `x3=00000040`, store correct, 100 retires, 0 couple violations** |
| **control** | **shipped** (option (2); fetch still in-phase) | **4/6 RED — `mem[64..67]=00000000`, `x3=00000000`: no store ever completes** |

⇒ ***ARM (A) CLOSES THE FETCH-ROW GAP. MEASURED, WITH A CONTROL THAT GOES RED UNDER
THE IDENTICAL HOST.***

### The price, and which half of it is measured

**MEASURED from the loop census** (1,200 cycles = 300 loops; `F200 · L50 · S50`, and
`fetch_loops == 2 × retires` exactly): **non-memory 8 · LW 16 · SW 16 cycles**, against
option (2)'s 4 · 12 · 12.

**ARITHMETIC on compiler's measured `28/14/14` histogram** — the same status as the 448
figure I signed, and named as such rather than presented as a second measurement:

```
  pre-(2)      28·4 + 14·8  + 14·12 = 392
  option (2)   28·4 + 14·12 + 14·12 = 448      +14.29%
  arm (A)      28·8 + 14·16 + 14·16 = 672      +50.0% on (2), +71.4% on pre-(2)
```

⇒ **the +50% I forecast in §6 is confirmed — and it was confirmed by driving the loop
shape, not by re-doing the arithmetic that produced it.**

### ⛔ A CRITERION DEFECT CAUGHT IN THE MAKING, RECORDED BECAUSE IT IS THE HOUSE FAMILY
My first G7 was `maxfrun == 2` — "a FETCH owns exactly two consecutive loops". **It
went RED at 6, and the design was innocent:** `maxfrun` is the longest run of fetch
loops *across instruction boundaries*, and this program has three non-memory fetches in
a row (`nop`, `addi`, then `sw`'s own fetch), so **6 is the correct reading**. The
criterion could not pass. Repaired to the per-instruction form, `fetch_loops ==
2*retires`, which is what the sentence actually meant. *A check that cannot pass is
this file's own §2 lesson arriving from the other side.*

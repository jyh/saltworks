# PRE-REGISTRATION — §7's "+4" SECOND LOAD LOOP (RATIFIED OPTION (2))
### silicon, 2026-09-04 10:3x. Written BEFORE the RTL is touched and BEFORE the
### bench exists, per this seat's `pre-register-the-criterion`.
### Authority: council 09/04 ruling (7) — *"FF RATIFIED — NDF option (2) on the
### double signature; silicon writes the PIO firmware"* — on silicon's signature
### 09/03 18:34:07 and compiler's 18:27, with compiler's two amendments.
### Baseline at this hand: `origin/master` `62843742`; the tracked control
### `run_lwsw_bypass_control.sh` reproduces ARM A 7/7 · ARM B RED 2/7.

## 1 · WHAT (2) CHANGES, STATED AS AN RTL DELTA BEFORE IT IS WRITTEN

`busadapt8.v` today gives a `T_LOAD` **one** loop: `retire = loop_end && 1'b1`.
Option (2) gives it **two**, mirroring the store's `store_beat`:

| | loop 1 | loop 2 | retires at |
|---|---|---|---|
| FETCH | PC bytes out, instr bytes in | — | end of loop 1 |
| LOAD **(changed)** | EA bytes out | **read data bytes in** | **end of loop 2** |
| STORE | EA bytes out | wdata bytes out | end of loop 2 |

⇒ **every memory transaction becomes exactly two loops.** §7's own CPI table is the
price and it is already written there: **LW 8 → 12**, SW 12 unchanged, non-memory 4.

⛔ **COMPILER'S AMENDMENT 1, HONOURED AS I ACCEPTED IT.** My 09/03 sentence *"needs
no change to the ratified arbitration"* was true of the ARBITRATION RULE (fetch
yields to data) and let the reader carry it to THE MODULE, which is false: this
**does** change `busadapt8`'s `retire` for `T_LOAD`, and therefore compiler's kernel
model. *Cheap and bounded is not free.* The delta is named here, in advance, as a
change to a ratified module made under a double signature and a council ruling.

⛔ **COMPILER'S AMENDMENT 2 IS NOT DISCHARGED HERE AND MUST NOT BE COUNTED AS
HANDLED.** The `sof` arm's failure to consult `retire` is a SEPARATE two-signature
row. This work touches the `sof` arm only to clear the new `load_beat` exactly as
that arm already clears `store_beat` — the same treatment, not the repair.

## 2 · PRE-REGISTERED CRITERIA — the tracked bench (regression, must not move)

`Sim/wordonly/tb_plane32bus_lwsw.v` L1–L7 stay green under (2), unchanged, with its
combinational host. **BAR: 7/7 before and 7/7 after, and `run_lwsw_bypass_control.sh`
still reports `BYPASS_CONTROL=PASS`.** A regression here refutes (2)'s implementation,
not the ruling.
📌 Expected and NOT a failure: `LOAD` loop count DOUBLES. It is a count, not a criterion.

## 3 · PRE-REGISTERED CRITERIA — the NEW registered-host bench

`Sim/reghost/tb_plane32bus_reghost.v`. The host drives `pin_in` from a **flop**: it
can never answer in the cycle it is asked. That is the whole quantity under test.

| | criterion |
|---|---|
| **G1** | a LOAD and a STORE both appear on the TYPE pins |
| **G2** | the SW writes the right word to the right address (needs no turnaround — a control that must pass on BOTH arms) |
| **G3** | **the LW's word REACHES A REGISTER through a REGISTERED host** — the quantity (2) exists to fix |
| **G4** | a LOAD owns exactly TWO consecutive loops (the "+4" is actually present) |
| **G5** | no PC advance without a retire |
| **G6** | `store_unaccounted == 0` — L7's count criterion, carried over verbatim |

## 4 · ⛔ THE RED-FIRST ARM, AND THE BAR IS PRE-STATED

**ARM RED = the shipped one-loop LOAD. ARM GREEN = (2).** Same bench, same host.

- **ARM RED must FAIL G3 and G4.** If ARM RED goes green, the bench does not
  discriminate and ARM GREEN's green means nothing — the runner **exits non-zero**.
- **ARM GREEN must pass 6/6.**
- **G2 must pass on BOTH arms.** A control that fails everywhere is measuring the
  harness, not the design.

## 5 · ⛔ DECLARED SCOPE — WHAT THIS BENCH DOES *NOT* MAKE REGISTERED, AND WHY IT IS SAID HERE FIRST

**The FETCH path is served combinationally in this bench, deliberately, and (2) does
not change it.** §7's table gains "+4" on the **LOAD row only**, while §7's own text
says the load's assumption is *"exactly as the instruction does during a fetch"*.
⇒ **The same in-phase turnaround the LOAD row is being relieved of is still demanded
of the FETCH row.** I am registering that in advance as a question I expect to
measure, with its own arm (`REGHOST_FETCH`), so that a red there is a **pre-stated
result and not a discovery that arrives conveniently after the fact.**
**Whatever it measures, it is a NEW row and not part of (2).** (2) is what was ratified;
widening it at the object would be a seat ratifying its own scope.

## 6 · SCOPE, UNCHANGED FROM 09/03
Simulation against the RTL. No timing claim about real PIO. The harness is test
equipment — the trust class of a logic analyzer — exactly as the queue row says.

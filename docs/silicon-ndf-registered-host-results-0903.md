# RESULTS — THE NDF BENCH HARNESS IS BLOCKED ON A DESIGN QUESTION, NOT ON FIRMWARE
### silicon, 2026-09-03 18:1x. Criteria pre-registered in
### `docs/silicon-ndf-registered-host-prereg-0903.md` before the bench existed.
### Tree: saltworks `347451b0`. Bench: `SaltWorks/Silicon/Sim/reghost/tb_sof_at_retire.v`.
### Toolchain: iverilog (Icarus). Baseline control: the tracked
### `run_lwsw_bypass_control.sh` reproduces ARM A 6/6 green · ARM B RED 2/6 with the
### recorded 08/18 defect signature, so the environment is sound.

## 1 · THE ROW IS MIS-PRICED, AND THAT IS THE HEADLINE

`docs/QUEUE.md` §NDF registers the **NDF BENCH HARNESS** as *"scheduled September
work, small … ~100 lines PIO+C"*, owner to be assigned at the harness seam. I took it
at 18:0x. ⛔ **IT IS NOT A FIRMWARE TASK. IT IS BLOCKED ON §7's OPEN QUESTION.**

The RP2040 memory-server side is a **registered host**: PIO samples a pin on one clock
edge and can drive a response only on a later one. The bus assumes the opposite, and
both the RTL and the spec say so:

- `tb_plane32bus_lwsw.v`, its own scope block: *"A COMBINATIONAL (async-SRAM-like) host
  reads pin_out and drives pin_in in the same delta cycle … SO A GREEN HERE … SAYS
  NOTHING ABOUT A REGISTERED HOST."*
- §7 of `docs/silicon-offboard-data-block-0817.md`: *"If the host cannot turn a read
  around in-phase, every LOAD row below gains 4"*, and *"no wait-state / not-ready
  signalling is specified here … there is no pin for one under (d). **That is the next
  hard question.**"*
- ⛔ **AND THE "+4" IS NOT IMPLEMENTED.** `busadapt8.v`: a `T_LOAD` has
  `retire = loop_end && 1'b1` — one loop, unconditionally. A registered host has no
  sanctioned way to be late.

## 2 · THE HYPOTHESIS I TESTED, AND IT IS REFUTED

**Hypothesis:** `sof` is already the missing stall pin. Held high it pins `phase` at 0,
so `loop_end` is false, `retire` is 0, `core32.en` is 0 and the core freezes, while
`pin_out` holds address byte 0 — and phase 0 is exactly where `addr[7:0]` appears.

⛔ **REFUTED, TWICE OVER, AND THE FIRST REFUTATION IS A TIMING FACT I HAD TO TRACE
RATHER THAN READ.** A stall asserted *in reaction to seeing phase 0* arrives a cycle
late: `sof` is a flop, so by the time it is high the phase counter has already left 0.
The trace shows the frame bouncing `0 → 1 → 0` and the transaction restarting forever,
with the core never executing a single instruction. ⇒ **the stall must be asserted at
phase 3, before the host knows whether it needs one.** It is not demand-driven.

⛔ **THE SECOND REFUTATION IS STRUCTURAL AND IT IS THE REAL ONE.** The `sof` arm of the
arbitration does not consult `retire`, while the ratified shape-A `loop_end` arm does:

```verilog
else if (sof) begin
    store_beat <= 1'b0;
    kind <= c_dmem_req ? (c_dmem_we ? T_STORE : T_LOAD) : T_FETCH;   // no `retire`
end
else if (loop_end) begin
    if (retire) begin kind <= T_FETCH; store_beat <= 1'b0; end
```

`c_dmem_req` is a pure decode of the instruction still in `instr_r` and **cannot fall
until a new instruction is fetched** — the exact property the 08/18 ruling identified.
So `sof` at a retiring edge re-derives a transaction that has already completed.

## 3 · MEASURED, ONE VARIABLE, ON THE TRACKED COMBINATIONAL HOST

The probe is injected into a copy of the tracked bench; the host is unchanged. Only the
`sof` pulse varies.

| arm | `sof` pulse | retires | LOAD loops | STORE loops | bench verdict |
|---|---|---|---|---|---|
| 0 | none (control) | 85 | 21 | 43 | ALL PASS 6/6 |
| 1 | one cycle at a **retiring** phase-3 edge | 85 | **20** | **45** | **ALL PASS 6/6** |
| 2 | one cycle at a **non-retiring** phase-3 edge | 85 | 21 | **44** | **RED — L5 FAILED** |

- **Arm 1 injects an entire extra STORE transaction** (+2 loops: address and data) and
  displaces a LOAD (−1), with `retires` unchanged. The re-issue is real.
- **Arm 2** gives one store **three** loops (`store_beat` cleared mid-transaction),
  which `L5` catches.

⇒ **BOTH POSITIONS ARE DAMAGING. `sof` IS NOT A USABLE FRAME-ALIGNED WAIT STATE.**

## 4 · ⛔ AND ARM 1 IS INVISIBLE TO THE TRACKED BENCH — A CRITERION GAP

Arm 1 duplicates a memory transaction and scores **6/6 green**. Two reasons, and both
are about the criteria rather than the design:

- `L2` checks the SW wrote the right word to the right address. **The store is
  idempotent** — same address, same datum — so a second execution is undetectable.
- `L5` requires *"a store owns exactly TWO consecutive loops"*. **A duplicated store is
  shape-legal**: each store still owns exactly two loops. `L5` constrains a store's
  SHAPE and says nothing about HOW MANY stores the program performs.

⇒ 🔑 ***A SHAPE CRITERION CANNOT SEE A COUNT DEFECT, AND AN IDEMPOTENT WRITE HIDES ITS
OWN DUPLICATION.*** The `regs3` field that first exposed it is PRINTED by the bench and
CHECKED BY NOTHING. I found this by reading a column the bench does not gate on.

## 5 · WHAT I AM NOT CLAIMING

- **This is NOT "busadapt8 is broken in service."** `sof`'s specified use is a
  host-driven **realign**, and the tracked bench pulses it only at phase 0, where it is
  inert. Arms 1 and 2 use it in positions it was never specified for. What is live is a
  **latent asymmetry** — the ratified shape-A repair reached the `loop_end` arm and not
  the `sof` arm — which becomes a defect the moment anyone repurposes `sof`.
- **I did NOT write the RP2040 PIO firmware.** Writing it against an unanswered protocol
  would produce code nobody can trust.
- **I am not ratifying a fix.** Making the `sof` arm consult `retire` mirrors shape A and
  is a one-line change to a ratified module — which is the standing two-signature shape
  (cf. item 10, `kind`-must-consult-`retire`). **Recommended, not made.**

## 6 · WHAT THE SEAM ACTUALLY NEEDS — three options, priced

1. **Mirror shape A into the `sof` arm** (one line) and re-price `sof` as a phase-0 wait
   state. Cheapest, but it is an RTL change to a ratified module and it does NOT fix the
   assert-a-cycle-early problem: the stall stays pre-scheduled, not demand-driven.
2. **Implement §7's "+4" second LOAD loop** in `busadapt8`. Honest and demand-free — the
   host always gets a whole loop to answer — at a measured cost of LW CPI 8 → 12.
3. **Require an in-phase host.** Not the RP2040 as a PIO memory server. Would need an
   external async SRAM or a CPLD in front, i.e. more board, not more firmware.

⇒ **RECOMMENDATION: (2).** It is the only one that makes a registered host FIRST-CLASS
rather than tolerated, the CPI cost is already written into §7's own table, and it needs
no change to the ratified arbitration. **Not mine to rule — this is a protocol decision
and it wants the Captain's hand or a two-signature seam with compiler.**

⚠️ **SCOPE.** All of this is simulation against the RTL. Nothing here is a timing claim
about real PIO, and nothing here touches the verified surface — the harness is test
equipment, the same trust class as a logic analyzer, exactly as the queue row says.

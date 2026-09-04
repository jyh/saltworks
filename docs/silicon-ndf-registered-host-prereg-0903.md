# PRE-REGISTRATION — CAN A REGISTERED HOST SERVE THE BYTE-PHASE BUS?
### silicon, 2026-09-03 18:0x, written BEFORE the bench exists and before any run.
### Tree at pre-registration: saltworks `347451b0`. Toolchain: iverilog (Icarus), macOS.

## Why this, and not the firmware the queue row asks for

`docs/QUEUE.md` §NDF registers the **NDF BENCH HARNESS** as *"scheduled September
work, small; OUTSIDE the verified surface … ~100 lines PIO+C"*, owner to be assigned
at the harness seam (compiler or silicon). I took it at 18:0x.

⛔ **IT IS NOT SMALL, AND IT IS NOT A FIRMWARE PROBLEM. THE ROW IS MIS-CLASSIFIED.**
The RP2040 memory-server side is a **registered host**: PIO samples a pin on a clock
edge and can drive a response only on a later one. The bus it must serve assumes the
opposite, and both the RTL and the spec say so in terms:

- `SaltWorks/Silicon/Sim/wordonly/tb_plane32bus_lwsw.v`, its own scope block:
  *"A COMBINATIONAL (async-SRAM-like) host reads pin_out and drives pin_in in the same
  delta cycle … SO A GREEN HERE … SAYS NOTHING ABOUT A REGISTERED HOST. A host that
  cannot turn a read around in-phase needs §7's '+4' second loop, which this bench
  does NOT model and which remains the open question §7 named."*
- `docs/silicon-offboard-data-block-0817.md` §7: *"THE LOAD ROW ASSUMES READ DATA
  RETURNS ON `ui` DURING THE ADDRESS PHASES … That is an assumption about THE HOST,
  not about this design … If the host cannot turn a read around in-phase, every LOAD
  row below gains 4."* And, kept explicit: *"no wait-state / not-ready signalling is
  specified here … A host slower than the phase counter needs a stall input, and there
  is no pin for one under (d). **That is the next hard question.**"*

⛔ **AND THE "+4" IS NOT IMPLEMENTED.** `busadapt8.v`: `retire = loop_end && ((kind ==
T_FETCH) ? ~c_dmem_req : (kind == T_LOAD) ? 1'b1 : …)`. A `T_LOAD` retires at
`loop_end` **unconditionally** — one loop, no second one. So a registered host has no
sanctioned way to be late.

## The candidate answer, derived at the object rather than proposed from the spec

`sof` already does it. Reading `busadapt8.v`: `phase <= 2'd0` whenever `sof`, and the
08/18 repair made `sof` reframe the **transaction** as well as the counter (`kind` is
re-derived in the `sof` branch). With `sof` held high:

- `phase` is pinned at 0, so `loop_end` is false, so `retire` is 0, so `core32.en` is
  0 and **the core is frozen** — it cannot advance past the transaction it is in.
- `out_word` is stable (`instr_r` only updates on a phase-3 edge, which never comes),
  so `pin_out` holds **address byte 0** for as long as the host likes.
- `in_acc[7:0] <= pin_in` re-latches every cycle at phase 0, so the **last** value the
  host drives before releasing `sof` is the one that counts.

⇒ ***`sof` IS ALREADY A PHASE-0 WAIT STATE, AND PHASE 0 IS EXACTLY WHERE `addr[7:0]`
APPEARS.*** For a 256-byte host memory — which is what the tracked bench already uses
(`hmem[la]`, indexed by `addr[7:0]` alone) — a registered host can stretch phase 0,
look up at leisure, then serve bytes 0..3. **§7's "there is no pin for a stall" may be
answered by a pin that already exists.** No new pin, no "+4", no RTL change.

⚠️ **THIS IS A HYPOTHESIS AND MAY BE FALSE.** It is a design claim about a ratified
module and I am not ratifying anything: I am testing it and reporting.

## PRE-REGISTERED CRITERIA — published before the bench is written

| # | criterion | bar |
|---|---|---|
| R1 | a LOAD loop appears on the TYPE pins with the `sof` stretch active during its phase 0 | ≥ 1 |
| R2 | the LW's loaded word REACHES A REGISTER, end to end | exact word |
| R3 | the host is REGISTERED: it never drives `pin_in` in the same cycle it samples `pin_out` | 0 violations, checked, not asserted |
| R4 | the SW writes the RIGHT WORD to the RIGHT ADDRESS in host memory | exact |
| R5 | measured CPI for the LW under the stretch | REPORTED, not predicted |
| R6 | **CONTROL — with the stretch DISABLED and the host still registered, the bench MUST go RED** | R2 or R4 fails |

⛔ **R6 IS THE LOAD-BEARING ROW.** A bench that only passes proves nothing: this seat
has published a green from a check that could not fail before. If R6 goes GREEN the
whole run is void and the stretch is not what made it work.

⚠️ **SCOPE, STATED IN ADVANCE.** A green here measures the PROTOCOL under a registered
host in simulation. It is **not** RP2040 firmware, **not** a timing claim about real
PIO, and **not** a ratification of `sof`-as-wait-state — that is a design decision and
it is not a seat's to make alone. Nothing here touches the verified surface.

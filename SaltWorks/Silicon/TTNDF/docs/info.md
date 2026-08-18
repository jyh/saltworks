<!--
⚠️ SPLICED UNDER A HEADING THE DATASHEET SUPPLIES. Starts at `##`, never `#` —
`validate.py:check_docs` fails the file otherwise, and the title/author/description
come from info.yaml above this slot.

⛔ ONE PARAGRAPH HERE IS NOT TOP-AGNOSTIC AND IS MARKED IN PLACE: "The processor
beside it". Which top ships is the Captain's ladder call. Everything else describes
the fabric/neuron complex, which both candidate tops carry unchanged.
-->

## How it works

This is a **bit-serial neural dataflow fabric**: signed multiply-accumulate cells
sitting on a self-routing banyan switch, with a small processor beside them sharing
the same 24 pins.

**The fabric.** An 8-port banyan network moves one bit per cycle. Ports are frozen
by the D6 pin map: **0–3** are the MAC cells, **4** is edge-in, **5** is edge-out,
**6** is a CPU-stub and **7** is spare. A packet is self-routing — its header names
the destination and the switch elements read it as it passes, so nothing central
schedules the traffic.

**The frame.** Time is divided into 14-cycle frames. Cycles 0–5 carry the header as
three `ACT`/address pairs, most-significant bit first; cycles 6–13 carry the
payload. `sof` (on `uio_in[6]`) realigns every counter in the design to frame zero,
so a host that loses sync recovers by pulsing one pin.

**The computation.** A 22-frame timetable drives a **2-2-1 schedule**: three cells
compute two hidden units and one output. Cells 0–2 carry the demo; cell 3 is
clocked but idle, present so the array is uniform. Each cell accumulates a signed
product bit-serially, with the sign handled on the final cycle of the frame. Three
serialiser organs read the accumulators back out onto the fabric.

**The processor beside it.** *(⛔ This is the one paragraph the ladder call touches.)*
The current top carries a **16-bit byte-phase core**: it drives an address byte per
cycle on `uo_out`, takes an instruction byte back on `ui_in`, and reports where it
is in the 4-phase loop on `uio_out[1:0]`. A 32-bit variant of this socket exists and
is measured but is not what this manifest declares.

**What is proved and what is not — stated precisely, because the distinction is the
point of the project.** Each MAC cell is *generated from a Lean model proved correct
in the Lean kernel*, and the generated netlist is then *proved equivalent to its
arithmetic specification over all inputs by SAT*. The signed accumulation is proved
for the drive schedule the design specifies. **The sequencer that produces that
schedule, the pin wrapper, and the fabric glue are hand-written RTL and are not part
of either proof.** A layout of this composition measures area, timing, DRC, LVS and
antenna — it is not a functional demo and not a proof of the whole.

## How to test

**Reset, then frame.** Hold `rst_n` low, release it, then pulse `sof` on
`uio_in[6]`. Every counter in the design returns to frame zero on that pulse — the
sequencer, the fabric and the core's phase counter all read the same net, so they
cannot disagree about where a frame begins.

**Drive an edge.** Present serial data on `uio_in[2]` (`edge_in_dat`) with
`uio_in[3]` as its valid. Results emerge on `uio_out[4]` (`edge_out_dat`) with
`uio_out[7]` (`valid`) marking the cycles that carry them.

**Watch the core.** `uio_out[1:0]` reports the byte-phase; `uo_out` carries the
address byte for that phase. Feeding instruction bytes back on `ui_in` in phase
order walks the core through its loop.

**Clock.** The design is specified at a 55 ns period (18,181,818 Hz). That figure
and `clock_hz` in the manifest are separate fields in separate files and nothing in
either tool checks that they agree — they are kept equal by hand and by review.

⛔ **THERE IS NO COCOTB BENCH IN THIS PROJECT YET, AND THIS SECTION DOES NOT PRETEND
OTHERWISE.** The bench is genuinely blocked rather than merely unwritten: a
testbench binds `PROJECT_SOURCES`, which must agree with `source_files`, which
follows `top_module` — and which top ships is not yet ruled. A bench written against
the wrong top is wasted twice. The manifest's own source list is machine-checked
against the RTL closure by `docs/silicon-tools/manifest_check.sh`, and
`assemble.sh` refuses to build a submission tree while `test/` is missing.

## Known limitation — one result per frame, and it is a design decision not a bug

The serialiser organs have **no shift-enable**: they shift on every load-low cycle.
A 32-bit emission spread across four frames would therefore lose 24 bits into the
header windows. This artifact emits **one int8 frame per result** instead. Full-width
emission needs either a shift-enable port on the serialiser (about +32 selects) or
per-frame reloads; it is priced and owed, and it does not move the area, timing,
DRC, LVS or antenna numbers a layout of this composition produces.

## External hardware

None. The design needs no external hardware: drive the pins directly, or from a
microcontroller if you want to stream frames faster than by hand.

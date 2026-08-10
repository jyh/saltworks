## How it works

A **neural dataflow fabric**: four bit-serial multiply-accumulate
(MAC) cells attached to the leaf ports of a self-routing 8×8 banyan
switch, with a small RISC-V core (5-instruction subset) alongside on
its own multiplexed memory bus. Weights, biases, and activations are
**traffic, not storage** — every value arrives as a 14-cycle packet
(6-cycle self-routing header + 8-bit payload), and a central
sequencer drives the cells on a fixed, compile-time schedule. There
are no handshakes anywhere: one clock, one frame counter aligned by
`sof`, and a deterministic timetable.

Each MAC cell computes `b + Σ Wᵢ·xᵢ` for signed 8-bit values on a
32-bit datapath: the weight is loaded serially through the same wire
that later streams the input (a duration-controlled load window),
each streamed input bit meets the weight shifted to its position
(shift-and-add), and the final bit of a signed value is processed as
a subtract cycle through an XOR complement bank. A ReLU
(compare-vs-zero at the signed order) and a serializer return each
result to the fabric as a packet.

**Verification, stated exactly:** each cell's combinational core is
generated from a model written in Lean 4 and proved correct in the
Lean kernel (accumulation, the signed subtract cycle, state layout,
and composition seams are theorems; the drive schedule the design
specifies is the schedule the theorems quantify over). The emitted
gate netlist is then proved equivalent to its arithmetic
specification over all inputs by SAT. These are two different
checkers: the kernel proves the model, SAT proves the netlist, and
the generator connecting them is structural — one cell per model
gate for the MAC core, and a documented 3-gates-to-1-mux peephole
in the serializer. Synthesis does not preserve the cell count — it
drops unobservable gates and adds buffers — but it was proved to
preserve the function, by SAT, against the emitted netlist. The
sequencer, the pin wrapper, and the switch fabric are hand-written
RTL and are outside both proofs; the banyan's routing behaviour is
checked in the kernel against a Lean model of the fabric for
prefix-concentrated destination-monotone traffic; the demo's own
routing rounds are not yet in that certified set.

## How to test

The chip is driven by the demo board's RP2040 as a synchronous tape:
because the design is deterministic (no interrupts, no arbitration,
fixed 4-cycle instruction loop on the core, fixed frame timetable on
the fabric), the entire stimulus — weight packets, input packets,
and the core's instruction byte stream — is generated offline and
replayed cycle-accurately.

1. Hold `rst_n` low, then release; pulse `sof` (uio[6]) to align
   the frame counter.
2. Feed weight/bias/input packets on the edge-in port (uio[2]
   data, uio[3] valid), one 14-cycle frame per 8-bit value,
   MSB-first address header, LSB-first payload.
3. Results emerge on the edge-out port (uio[4] data, uio[5]
   valid) as packets; `valid` (uio[7]) marks each frame's payload
   window (cycles 6–13), and its rising edge uniquely identifies
   cycle 6 for phase recovery.
4. The core fetches its instruction stream over ui_in (byte per
   phase, low byte first) with its program counter presented on
   uo_out (byte per phase) and the phase strobe on uio[1:0] —
   the standard TT ROM-emulator pattern, byte k served on phase
   (k+3) mod 4.

A reference 2-neuron-plus-output network (a 2-2-1 MLP) runs in 22
frames ≈ 308 cycles ≈ 17 µs at the 18.18 MHz design clock.

## External hardware

None beyond the TinyTapeout demo board: the on-board RP2040 serves
as both the core's memory server and the fabric's packet source and
sink (PIO state machines; the chip-side protocol is fixed and
documented above). A logic analyzer on the PMOD pins is convenient
for observing packet traffic but not required.

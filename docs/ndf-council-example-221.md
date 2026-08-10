# THE COUNCIL ARGUMENT — a 2-2-1 network, frame by frame

**Maestro (Fable), 2026-08-09 ~20:1x, at the Captain's request ("we
got to the heart of it — prepare the argument for the council").
Companion to ndf-top-module-design-v1.md (v1.1, refuted); consumes
its D4(f)/D4(h)/D6 mechanics. Constants: CLOCK_PERIOD 55 ns
(18.2 MHz), frame = 14 cycles (6 header + 8 payload, P=8), fabric
ports 0-3 = cells, 4 = edge-in, 5 = edge-out. All values int8 on the
32-bit datapath (ruling #8).**

## THE CLAIM, in one sentence

A neural network on verified silicon where synchrony is COMPILE-TIME
ARITHMETIC: no handshakes, no arbiters, no credits, no schedulers in
silicon — one clock, one sof-aligned frame counter, and a timetable
the compiler emits and the kernel can check round by round.

## THE NETWORK (the smallest one that exercises everything)

```
x0 ──┬─→ [neuron 0: b0, W00, W01] ──h0──┐
     │                                   ├─→ [neuron 2: b2, W20, W21] ──y─→ edge-out
x1 ──┴─→ [neuron 1: b1, W10, W11] ──h1──┘
```
- neuron 0, 1 on cells 0, 1 (layer 1); neuron 2 on cell 2 (layer 2)
- h = ReLU(b + W·x + W'·x') per neuron; y is the external output
- Exercises: external fan-out (x0 → two cells), cell-to-cell traffic
  (h0, h1 → cell 2), external output, per-neuron bias, a depth-2 DAG.

## THE MECHANISMS IT RIDES (each with its authority)

| mechanism | authority |
|---|---|
| bias = a weight spent against one x=1 cycle; zero constant gates in silicon | scCore_has_no_constant_gates + the §E bias ruling |
| serial MAC: stream bit t meets W<<<t; sign strobe at frame cycle 13 subtracts the MSB's negative weight | cellSeq_runTrace_state · sc_sign_cycle_subtracts |
| acc persists across inputs; weight reloads per input (full-width, self-cleaning — no reset wire exists or is needed) | the per-input-shape ruling + weight_state_moves_so_reload_is_required |
| the SHELL: en_wsh + en_acc + acc CLEAR (freeze = parked state is valid; clear = the only reset) | v1.1 D4(f), V9 (kernel model owed, compiler) |
| combinational fabric: payload bit in at cycle t is OUT at cycle t; the 2r=6 header is routing tax, not skew | banyan_fabric.v ("no pipeline latency") |
| one frame per int8 value; the shell sign-extends weights locally (8 bits sent, never 32) | v1.1 D4(h) |
| inter-layer h is int8 BY COMPILE-TIME RANGE GUARANTEE (the compiler-checked-per-network family; ReLU gives h≥0, the weight choice bounds it) — NO requant organ, per ruling #8 | noOverflowFrom discipline, extended one conjunct |
| multicast = repetition in the PoC (x0 sent once per destination); multicast rounds are a schedule optimization, not silicon | §5's "natural multicast by rounds" read honestly |

## THE TIMETABLE — every frame, every event

Sub-frame events in brackets ride sequencer-local cycles while the
fabric serves other traffic; a loaded weight's 24-cycle local sign
extension occupies the two frames after its load frame (the cell is
frozen to the fabric meanwhile). CLEAR: one global strobe, frame 0
cycle 0.

```
F0   b0  → cell 0            [CLEAR all accs @ F0c0]
F1   b1  → cell 1
F2   b2  → cell 2            [cell 0 bias cycle x=1 @ F2c11 → acc0 = b0]
F3   W00 → cell 0            [cell 1 bias cycle → acc1 = b1]
F4   W10 → cell 1            [cell 2 bias cycle → acc2 = b2]
F5   W20 → cell 2            (cell 2 then FREEZES holding W20 — parking is valid
                              only because of the shell freeze; found building
                              this very table)
F6   x0  → cell 0   STREAM: 8 payload cycles, sign@c13 → acc0 += W00·x0
F7   x0  → cell 1   (multicast by repetition)          → acc1 += W10·x0
F8   W01 → cell 0
F9   W11 → cell 1
F10  (extensions completing; fabric idle or compressible)
F11  x1  → cell 0                                      → acc0 COMPLETE
F12  x1  → cell 1   [cell 0 ACTIVATE: CE(acc0,0) signed → SER latches h0]
F13  h0: cell 0 → cell 2     [cell 1 ACTIVATE → h1]    → acc2 += W20·h0
F14  W21 → cell 2
F15  (cell 2 extension)
F16  (cell 2 extension completes @ F16c10)
F17  h1: cell 1 → cell 2                               → acc2 COMPLETE
F18  [cell 2 ACTIVATE → y]  y → edge-out, frame 1 of 4
F19  y → edge-out, frame 2 of 4     (edge results go FULL 32-bit for
F20  y → edge-out, frame 3 of 4      bench visibility; cell-to-cell
F21  y → edge-out, frame 4 of 4      h went as ONE int8 frame)
```

**22 frames × 14 cycles = 308 cycles ≈ 17 µs at 18.2 MHz.** The
simple form runs ONE fabric source per frame; the fabric supports
concurrent disjoint routes, so the compressed timetable (overlap
h0's transfer with edge traffic, pack the idle frames) lands near
~14-16 frames — compression is a compiler optimization, not a
correctness question.

## WHY THE COUNCIL SHOULD BELIEVE IT

1. **Every frame is a routing pattern the kernel can check.** The
   whole demo uses SIX distinct single-source routes (edge→cell
   0/1/2, cell0→cell2, cell1→cell2, cell2→edge). Under V10
   (per-round fixtures) each is one `decide +kernel` fixture on the
   netlist model — small, enumerable, honest. No appeal to a theorem
   family whose hypotheses we don't meet (the refuter pass killed
   exactly that sentence in v1).
2. **Dependencies are frame ordering, nothing else.** h0 cannot
   arrive at cell 2 before F13 because the timetable doesn't emit it
   earlier — and the timetable is data the compiler emits and the
   bench replays. The DAG's topological order IS the schedule.
3. **The example found real defects while being built** — the wsh
   freeze (a parked weight decays 2^gap without it) joined the sign
   cycle and the acc-clear as the third capability-class defect,
   all now priced in the shell. The method is working: constructing
   the concrete timetable is itself a verification instrument.
4. **What it costs:** ~17 µs per inference unoptimized; the shell
   (2 enables + clear + sign-hold mux, per cell) as the one new
   silicon class, kernel model owed (V9); the compiler's per-network
   range guarantee as the one new proof obligation class.

## WHAT THE SITTING MUST STILL RULE (exercised by this example)

- D10.6 — the pin amendment (sof rides uio[6] in this timetable).
- V9 — the shell's kernel model (two enables + clear), owner
  compiler.
- V10 — the six fixtures above as the demo's certificate set.
- The inter-layer int8 range guarantee as a named compiler
  obligation (new conjunct beside noOverflowFrom).

🧂⚓

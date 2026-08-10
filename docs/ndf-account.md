# THE NDF ACCOUNT — the KERNEL half

**Compiler's half of the account, on the `bb-switch-account` pattern (Captain-commissioned).
Silicon's PRICED half is the companion; math refutes both; evidence fences both.**

⚖️ **EVERY COUNT IN THIS DOCUMENT IS `#eval`'d FROM THE KERNEL OBJECT ITSELF**, not quoted from a
post. The invocation is `docs/hdl-tools/` + the organ's own module; re-run it rather than trusting
this table — *publish the invocation, not the number* is this fleet's own law and this file obeys it.

---

## 1. THE ORGANS — measured, not recalled

| organ | kernel object | gates | `nIn` | state | `outs` | const gates |
|---|---|---|---|---|---|---|
| weight shift | `wshiftSeq` / `wsCore` | **33** | 34 | 32 | 64 | **0** |
| accumulator | `macSeq` / `macCore` | **160** | 65 | 32 | 96 | **0** |
| the SIGNED cell | `scellSeq` / `scCore` | **225** | 67 | 64 | 96 | **0** |
| SER / activation | `serSeq` / `serCore` | **131** | 65 | 32 | 33 | **0** |
| the SHELL (V9) | `shSeq` / `shCore` | **452** | 70 | 64 | 96 | **0** |

*`scCore` = the two organs composed + a 32-wide XOR bank (`33 + 160 + 32 = 225`). `shCore` =
`scCore` INSTANCED + 3 inverters + 96 weight-select gates + 128 accumulator select-and-clear gates
(`225 + 227 = 452`).*

⭐ **ZERO CONSTANT GATES IN EVERY ORGAN.** *Ruling (b)+A's property, held through three
compositions: each tie became an admitted port instead of a `conb` cell.*

## 2. THE THEOREM CHAIN — organ by organ, bottom to top

```
adder            sem_adder32_gen            ALL 2^64 operand pairs, every carry-in
                                            (not decided — proved; 2^64 is not a kernel computation)
accumulator      step_bit_is_adder_bit      one cycle's sum bit IS adder32's, for EVERY carry-in
weight organ     wshift_addend_bit          the AND row is x ∧ (W<<<t)
                 wshift_next_bit_zero/succ  the shift, and the vacated LSB = load ∧ x
                 wshift_runTrace_state      after t cycles the register holds W<<<t
the SEAM         sc_seam_is_the_xor_of_the_and_row
                                            macCore's addend port IS a XOR of the AND row
                                            with the sign — the COMPLEMENT PATH EXISTS
composition      sc_sum_bit · sc_wsh_next   one cycle of the CELL is one cycle of each organ,
                                            re-proved on the three-segment netlist
signed step      sc_sign_cycle_subtracts    sign=1 ⇒ acc − andWord x w, per bit, on the netlist
                 sc_accumulate_cycle_unchanged
                                            sign=0 ⇒ acc + andWord x w — the compatibility control
THE TRACE        scellSeq_computes_signed_mac   (math's) m accumulation cycles then ONE sign cycle
                                            ⇒ b + Σ addendTrace − signOperand, on scellSeq
```

⭐ **THE NEURON IS SEMANTICALLY WHOLE AT THE KERNEL MODEL — accumulation AND sign — on the composed
signed artifact.** *The bias `b` enters as the INITIAL accumulator state, which is why the hardware
clear (§4) binds in silicon and not in the kernel: the refinement is stated `∀ st₀`.*

## 3. ⚠️ THE BOUNDARY — math's line, verbatim, and it governs every sentence above

> ***every whole-neuron sentence carries WHEN DRIVEN (driver = the sequencer, V9/R6)***

**The theorems in §2 say what the cell computes GIVEN a trace of inputs. They do not say anything
supplies that trace.** On the composed die the supplier is the 2-2-1 sequencer — 3 `always` blocks
and 4 registers of HAND RTL, inside the D2(b) exemption list. So:

```
PROVED            the datapath, at the kernel model, over the trace it is given
NOT PROVED        that the schedule driving it is the schedule the theorems assume
WHO SUPPLIES IT   the sequencer — hand RTL, no theorem near it, V9's subject
```
🔑 *Evidence's phrasing is the one to carry because it does not sound like a schedule item: **the
composed die adds precisely the component their F5 walk found had NO SUPPLIER, and it is added
unverified.** That is a fine engineering choice and a terrible sentence to leave unscoped.*

## 4. WHAT THE SILICON HAS THAT THE KERNEL MODEL DOES NOT

Three capabilities were killed by composing the organs — one root cause, found by three instruments:

```
the SIGN CYCLE   a cycle that does SOMETHING ELSE   compiler's kernel refutation, 8/9 17:45  → FIXED
the ACC CLEAR    a cycle that RESETS                a refuter on the top-module block, 19:40 → V9
the WSH FREEZE   a cycle that DOES NOT HAPPEN       the Captain's own 2-2-1 timetable, 20:08 → V9
```
🔑 ***`runTrace` is "one input → one step, ALWAYS". It has no stall, no reset, no alternate
operation.*** *A schedule feature that is not one-input-one-step sits outside the model BY
CONSTRUCTION — invisible to every theorem over the `Seq`.*

⚠️ **NARROWED 8/10 13:5x, and the narrowing is load-bearing in the CHEAP direction: "…and therefore
a SHELL obligation" WAS TOO STRONG. It is a shell obligation only when the feature is not an
admitted INPUT of the `Seq`.** *The three rows above are shell obligations because the cell's clear
and freeze are not inputs. **The SORTER's reset IS one** — `bnCRst = 0` is a design input of
`batcherNetC`, so its per-frame pulse rides the trace and is inside the model. `emitSeq batcherNetC`
therefore needs NO shell, which is the answer the 8/10 night-council's ① asked for and which silicon
confirmed from the router side (no stall in the composed schedule).* ⇒ **Ask whether the feature is
an INPUT before pricing a shell for it; the blanket form would have bought the sorter a shell it
does not need.**

## 5. THE V-TABLE — honest status, including what is in flight

| | subject | status |
|---|---|---|
| V7 | `emitSeq` acceptance: flops==nState · cells==gates+nState · conb==const-count · assigns==outs | **MET** on the emitted artifacts (L1 64/289/0/96 · L2 64/386/0/96 · SER 32/99/0/33) ⚠️ these are COUNTS; the property half (every flop `D` driven exactly once, `Q` nets distinct) is the complement and both are run by `netlist_check.sh` |
| V9 | the shell's kernel model | **HALF LANDED** (`28accfa`): shape proved (452 gates · 0 const · `instOK` · the clear reaches EXACTLY the acc bank) and the LOGIC proved at the Boolean level (select · holds · clear dominates · transparent when driven). ⛔ **The RUN-LEVEL refinement is OWED — and MECHANICAL.** ⚠️ *This row previously named a missing non-flat generalisation of `run_of_flat_gates` as the obstacle. **THAT OBSTACLE CLAIM WAS FALSE, and I struck it on the bus at 10:4x without amending here for three hours** — `run_snoc` and `run_snoc_frame` landed in `Compose.lean` (`81cd8f4`) and the peel needs no new theory.* Scope re-tested 12:43 and UNCHANGED: ~200 peels, because `shGates` is BIT-MAJOR (`[hWa j, hWb j, hWd j]` per bit) so no flat-layer shortcut exists without reordering `shCore` and breaking its landed shape theorems |
| V10 | per-round `decide +kernel` schedule fixtures | ⛔ **OWED**, not started |
| F3 | chip-level "down to silicon" | **STANDS** — clears only at the run on THIS top module |
| F5 | the composed cell's signed claim | (a)(b)(d) **MET** on the emitted netlist · (c) discharged at math's hand · **STILL BINDS** — and the reason is §3, not a defect |

## 6. WHAT THIS ACCOUNT DOES NOT CLAIM

- **Not** that the fabric is verified. The cells and the SER organ are kernel-emitted; the pin
  wrapper, the sequencer, the CPU and the fabric are hand RTL by ruling (D2(b)).
- **Not** that `emitS` is trusted. It produces a `String` and is untrusted by construction; what
  structural emission buys is that the netlist coming BACK should correspond one-to-one.
- **Not** a tile-fit signoff. Silicon's clause governs: good for area/timing/DRC/LVS/antenna;
  the die matches 6x2 because it was set there.
- **Not** a complete cell. `batcher_c` is emitted and committed and **UNWIRED**. ⚠️ *And it is the CORE, not the design: 624 cells with ZERO flops, 105 in = 9 design + 96 state, 104 out = 8 data + 96 next-state. The clocked object is `emitSeq batcherNetC` — 720 cells, 96 flops (`8be6d48`); quoting 624 as "the sorter" understates it by the whole state file.* the
  SER has no shift-enable, so the edge emission is ONE int8 frame per result, not 32 bits.

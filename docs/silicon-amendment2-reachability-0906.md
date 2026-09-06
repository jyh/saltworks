# IS A SPURIOUS `sof` REACHABLE IN THE SHIPPED CONFIGURATION?

**silicon, 2026-09-06 06:2x.** Routed by evidence 06:15:52 as the missing factor in
`severity = consequence × reachability`. `4d155b79` measured the consequence. This measures the
other factor. **FACT-FINDING, NOT A RULING** — the re-submission call is the Captain's.

## ✅ ANSWER: REACHABLE IN NORMAL OPERATION. NO HOST ERROR, NO INJECTION, NO GLITCH REQUIRED.

`sof` is not generated on-chip and nothing on-chip can suppress it. In the submitted top
`tt_um_saltworks_ndf_c32.v` it is a **bare external input pin, wired straight through**:

```
tt_um_saltworks_ndf_c32.v:28    wire sof = uio_in[6];
                        :53-54  plane32bus core ( .sof(sof), ... )   <- the CPU's bus adapter
                        :63     <fabric>        ( .sof(sof), ... )   <- the OTHER consumer
                        :78     if (!rst_n || sof) begin cyc <= 0; frm <= 0; end
```

There is no gate, no qualifier and no tie-off between the pad and busadapt8's arbitration.

## ⛔⛔ AND THE REASON IT IS REACHABLE IS STRUCTURAL, NOT ACCIDENTAL: ONE WIRE, TWO CLOCKS

`sof` is **shared between the bus adapter and the neural fabric**, and the fabric is the consumer
the pin was allocated for. The fabric's sequencer is **22 frames × 14 cycles**, and `sof` is what
resets it to frame 0 — i.e. **`sof` is how the host STARTS A FABRIC RUN.** That is not a fault
condition. It is the pin's job.

The bus adapter's loop is **4 cycles**. The two framings have no common schedule and no handshake:
a host asserting `sof` to launch a 308-cycle fabric computation lands at whatever cycle the CPU
happens to occupy. ⇒ ***A HOST DOING THE ONE THING THIS PIN EXISTS FOR CORRUPTS THE CPU WHENEVER
THE ARRIVAL FALLS IN THE WINDOW.***

Decision 2 in `busadapt8.v` says the two consumers "cannot disagree about frame start because they
read the same net". That is TRUE about **where phase 0 is** and does not extend to **when a realign
is harmless** — which is the property that actually matters here, and which nothing checks.

## 📊 THE PRICE, MEASURED BY SWEEP (`Sim/reghost/run_sof_reachability_sweep.sh`)

One compile, one `sof` pulse per run, arrival cycle swept across steady state:

```
BASELINE (no pulse)                   lw_exec=18  sw_exec=19
arrival cycles swept                  121   (cycles 40..160)
corrupted (a store unaccounted)        16
instruction lost (lw_exec fell)        12
                                      ----
REACHABILITY                          13.2% of arrival cycles corrupt
```

⚠️ **THAT PERCENTAGE IS PROGRAM-MIX DEPENDENT AND MUST NOT BE QUOTED AS A CONSTANT.** The hazard
window is three cycles per COMPLETED MEMORY INSTRUCTION, so the rate scales with memory density.
This bench's loop is `addi · sw · lw · nop`, i.e. 50% memory — a fair mid-range mix, not a worst
case. A memory-heavy inner loop is worse; a compute-heavy one is better. **What is NOT mix
dependent is that the rate is not zero and requires nothing unusual of the host.**

## 🔑 THE FACT THAT BEARS MOST ON THE RULING, AND IT IS NOT MINE TO WEIGH

The submitted top states its own scope in its header, and it excludes exactly this class:

> *"a layout of this composition measures area / timing / DRC / LVS / antenna. It is NOT a
> functional demo and NOT a tile-fit signoff. **Functional correctness is fence-held.**"*

⇒ The defect is **functional**, and the submitted artifact makes **no functional claim**. Whether
that makes a re-submission unnecessary is a judgement about what project 5500 is FOR, and that is
the Captain's call, not a seat's and not a lead's. I record it because a ruling made without it
would be pricing a claim the artifact never made — and because it cuts toward *ship unchanged*,
which is the direction I would rather have someone else weigh than quietly assume.

⛔ **WHAT I AM NOT SAYING:** that the defect is harmless. It destroys an instruction, silently,
with no architectural signal. If anything downstream ever treats `_c32` as a functional core, this
is a stop-ship. The scope clause narrows what was PROMISED; it does not narrow what the silicon DOES.

## ⛔ THE TWO CHEAP MITIGATIONS, NEITHER LANDED, NEITHER MINE ALONE

Recorded so the Captain has options that are not "re-submit or accept":

1. **A HOST-SIDE PROTOCOL RULE, ZERO RTL:** the host must not assert `sof` while a memory
   transaction is outstanding — i.e. only at a fabric boundary it already controls. This costs no
   silicon and needs no re-submission. It is a documented constraint on firmware, and firmware is
   not in the shuttle. **This is the cheapest correct answer if the ruling is to ship unchanged.**
2. **THE RTL REPAIR** (shape B in `silicon-amendment2-signature-0906.md`) — correct by
   construction, but it is a re-submission, on a 30-hour clock, of an already-ingested project.

⇒ Option 1 makes the hazard unreachable **without touching the shuttle**, which is why the
reachability question was worth taking before the repair question.

## RECEIPTS
- `SaltWorks/Silicon/Sim/reghost/run_sof_reachability_sweep.sh` — one compile, 121 runs.
- Structural claims are line-cited to `tt_um_saltworks_ndf_c32.v` at `:28`, `:53-54`, `:63`, `:78`.
- Consequence half: `docs/silicon-amendment2-signature-0906.md`, saltworks `4d155b79`.

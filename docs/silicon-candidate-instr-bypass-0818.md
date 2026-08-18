# CANDIDATE REPAIR — THE TRANSACTION/INSTRUCTION BOUNDARY. A PROPOSAL FOR TWO SIGNATURES, NOT A LANDING.

**silicon, 2026-08-18 16:4x. The patch is inline and the receipts are below. It is
deliberately NOT in `SaltWorks/Silicon/RTL/` — a boundary change to the SHIPPING top
is not mine to land by keystroke, and shape A is the precedent: I build it, drive it,
report it, and ratification is a separate act.**

⛔ **AND IT IS A DOC RATHER THAN A `.v` ON PURPOSE.** *A variant `.v` in the tree can
be synthesized by accident and read as an alternative design; a patch in a document
cannot. This also survives the session, which a scratchpad copy does not — that is
this seat's own banked defect (a scratch prototype died once and had to be
reconstructed in a hurry).*

## THE DEFECT, restated in one paragraph

The arbitration at a fetch loop's phase-3 edge reads `c_dmem_req` / `c_dmem_we`,
which core32 decodes from `instr` — and at that instant `instr_r` still holds the
PREVIOUS instruction. So the transaction that follows fetch-of-N serves N−1 while the
core already sees N. **Measured** by `Sim/wordonly/tb_plane32bus_lwsw.v`: at a store
commit, `dmem_addr=0x40` and `dmem_wdata=0x00000000` with `instr_r=0000a183` (the
`lw`, whose `rs2` is `x0`) and `regs[1]=0x40`. The store ADDRESS looked correct only
by coincidence — both instructions use `x1` as base.

## THE PATCH

```verilog
// in busadapt8.v, replacing:  assign c_instr = instr_r;
assign c_instr = (kind == T_FETCH && phase == 2'd3)
                   ? {pin_in, in_acc[23:0]}
                   : instr_r;
```

**The idea in one line: expose the word BEING ASSEMBLED for the single cycle in which
the decision is taken, so the decode the arbitration reads belongs to the instruction
the fetch just brought in.** No new state; `instr_r` still commits at the same edge
and drives every other cycle.

## RECEIPTS — against criteria PRE-REGISTERED BEFORE THIS PATCH EXISTED

*That ordering is the whole reason this is evidence: L1–L6 were published on the bus
at 15:00 with three of them RED, and the two that were red are the two the repair had
to turn.*

```
tb_plane32bus_lwsw          BASE            CANDIDATE
  L1 load+store on pins     PASS            PASS
  L2 SW wrote right word     FAIL            PASS   <- mem[64..67] = 00000040
  L3 LW word reached a reg   FAIL            PASS   <- x3 = 00000040
  L4 no advance w/o retire   PASS            PASS
  L5 store owns TWO loops    PASS            PASS   <- §7 preserved
  L6 fetch stride 4          PASS            PASS
                            4/6             ALL PASS (6/6)
```
✅ **AND THE SUITE IS NOT DEAD: `-DMUT_BREAK_COUPLE` still turns L4 RED on the
candidate**, so the criteria still discriminate after the repair.

### Regression — nothing else moved

```
tb_busadapt8      (adapter pin-protocol invariants)   BASE ALL PASS · CAND ALL PASS
tb_memory_inert                                       BASE ALL PASS · CAND ALL PASS
the enable arms (executor harness, run from a SCRATCH COPY so the peer's untracked
original was never edited):
  ARM A  en=1'b1        negative control   RED 5/6   (unchanged — still discriminates)
  ARM B  en=retire      positive           ALL PASS 6/6   (PRESERVED)
  MUTANT Z  en=1'b0                        RED 5/6
  MUTANT I  en=~retire                     RED 5/6
  ARM A / ARM B + store-only host          RED 4/6 · RED 1/6  (both unchanged)
```

## ⛔ WHAT I HAVE **NOT** MEASURED, AND ONE OF THEM IS THE REAL COST

1. **TIMING. This adds a combinational path** `pin_in → c_instr → core32's decode →
   dmem_req/we → kind's next-state`. That is long, it is new, and it lands on the
   deciding edge. **UNMEASURED — and it is exactly what a layout run prices.** A
   functional 6/6 says nothing about whether it closes at 55 ns.
2. **AREA.** Not measured, because synthesizing it would mean writing over committed
   `Flow/` artifacts for a design that is not ratified.
3. ⚠️ **AND IT CHANGES `retire`'s TIMING SEMANTICS TOO, WHICH 6/6 COULD HIDE.** At a
   fetch's phase 3, `retire` is now computed from the NEW instruction rather than the
   old one — so a non-memory instruction retires at the end of ITS OWN fetch.
   **That is arguably the correct semantics, and it is still a semantic change beyond
   "fix the lag".** I am naming it rather than letting a green suite imply the patch
   is a pure bugfix.

## WHAT THIS DOES NOT TOUCH

- **Shape A stands.** It decides which loop follows which and does that correctly;
  this patch changes WHICH INSTRUCTION'S DECODE that decision reads.
- **`en = retire` is still a MARKED VALIDATION ARTIFACT.** Nothing here ratifies it.
- **Criterion (c) stays open**, and compiler's 15:13 line is the reason to expect no
  help from that side: *"decQ covers regs and pc only, so a wrong-operand store
  satisfies ObservesRetire; my structural result does not cover the data path."*
- **The fit work stands** — area unaffected by anything in this document, 34.27% at
  `ab54ce7`.

## THE ASK

Two signatures, as item 10 got. If it is ratified I land the one-line change, re-synth
the adapter and the two composed tops, re-run every arm, and re-quote the area
through `areacite.sh` so the figure carries its new sha. **If it is refused, the
defect stands recorded and the shipping top's own SCOPE clause already fences
functional correctness — nothing about the fit measurement changes either way.**

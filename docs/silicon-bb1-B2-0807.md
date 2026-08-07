# BB-1 · B2 — the network's PROOF half: the artifact exists, its meaning needs option (A)

### 2026-08-07, SILICON. The maestro's dispatch: lift `ce_elem`'s refinement
### across `batcher_net`'s 24 instances, D4 composition discipline, against
### math's `batcher8_banyan_selfrouting` form.

## What landed

**The 24-element bitonic network imports.** `batcher_net` (the landed `batcher8`
realised as 24 `ce_elem`) through the pinned flow and the importer's flop
treatment:

```
447 cells · 48 flops · 65 primary inputs (17 design + 48 state) · 64 outputs
1,186 gates emitted · readback agrees with vendor Liberty on 32 vectors
```

**Nine cell models were owed and are now proved.** The network reached for
`a221o`, `a22o`, `nor2b`, `o21bai`, `o31a`, `o31ai`, `o41ai`, `or3`, `or4b` (and
`a2bb2oi` before them). ⭐ **Each was derived BY HAND from the naming convention
before the Liberty was read — 10 of 10 agreed.** *(The rule's previous run was 25
of 27; this one was clean.)* `Cells/Sky130.lean` now carries **52 audit ticks**.

## ⛔ THE PROOF HALF DOES NOT CLOSE ON THE RTL ROUTE, AND THE MEASUREMENT IS EXACT

**2⁶⁵ is not a decidable enumeration** — the network has 65 primary inputs, so
the whole-network obligation cannot be discharged directly. That is precisely
what the D4 composition discipline is for: **cut at the 24 element boundaries and
each obligation becomes the element's 128 cases, which `ce_step_eq` already
proves.**

| | cones | median | **max** | ≤ 24 |
|---|---|---|---|---|
| untreated | 64 | 46 | 55 | 37.5 % |
| **all 96 element boundaries `(* keep *)`, all 96 SURVIVING** | 144 | 27 | **90** | **50.0 %** |

⚠️ **The boundaries survive and the cones do not shrink.** 96 of 96 nets are in
the netlist; cutting there still leaves a **90-input** cone against an element
obligation that should be **7** (5 inputs + 2 state). **The optimiser routed
around them** — the same failure measured in six blocks this morning, now at
network scale, in the artifact BB-1 actually needs.

*(The first attempt cut at boundaries that did not exist at all: `synth -flatten`
had dissolved them, and **the guard I added at 09:0x fired on my own work** —
`--cut matched no DRIVEN net`, refusing to print an untreated census as treated.)*

## ⇒ B2's proof half is blocked on option (A), and that is a RESULT, not a delay

The element theorem is **proved and ready to compose** — `ce_step_eq`,
`ce_stable`, `ce_rejects_idle_sorts_low` (`7b2cab4`). What is missing is a
network whose **element boundaries are cells rather than attributes**. The C3
probe already measured that route: **128 of 128 boundaries survive structurally,
5,266-cell monolith at 100 %.**

⇒ **B2 = emit `batcher_net` structurally (compiler's half, the same emitter C3
validated), then the 24 obligations are 24 instances of a theorem already in the
kernel.** *No new proof technique is required; the blocker is emission, and it is
the one the campaign has already decided.*

## Against math's statement form

`batcher8_banyan_selfrouting` (`4f63118`) discharges `StrictMonoOn` entirely and
leaves the caller owing **injectivity + bound**. ⇒ **B2's hardware conclusion must
supply exactly those two** about `runNet batcher8`'s realisation — which is what
the composed 24-element refinement will give, once emitted structurally.

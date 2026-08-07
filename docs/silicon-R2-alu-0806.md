# R2 — THE ALU CONE. THE CLAIMED ANSWER IS HALF RIGHT, AND THE MEASUREMENT SAYS WHICH HALF.

### 2026-08-06 night, SILICON. Campaign freeze `a69fee0`, kill-check R2:
### *"32-bit add/sub cones exceed the per-cone law by construction. The claimed
### answer — bit-slice with per-slice carry obligations (the fabric's own
### pattern) — must be **DEMONSTRATED** on one slice before C3 freezes, not
### asserted."*

Measured on a synthetic 32-bit add/sub (`RTL/adder32.v`, ripple, carry chain
`(* keep *)`) through the pinned flow. ⚠️ Cannot reach the tape-out:
`TT/assemble.sh` copies two NAMED files, never `RTL/*.v`.

## ✅ HALF ONE — THE SLICE OBLIGATION IS REAL, AND IT IS NOW LANDED

`SaltWorks/Silicon/Equiv/AdderSlice.lean`:

```
✓ SaltWorks.Silicon.slice_ok [1 axioms]        8607 jobs, saltbuild EXIT=0
```

One full-adder slice has **3 inputs** ⇒ **8 cases**, discharged by `decide
+kernel` — no `native_decide`, no `bv_decide`. Against a specification written
independently of the netlist (the carry stated as the majority function). **R2's
"demonstrate on one slice" is satisfied, and the demonstration is in the hub's
import closure rather than in a scratch file.**

## ⛔ HALF TWO — BUT THE SYNTHESISED NETLIST DOES NOT DECOMPOSE INTO SLICES

R2's premise is confirmed — the monolithic cones are hopeless:

| arm | cones | med | **max** | ≤ 24 |
|---|---|---|---|---|
| monolithic | 33 | 35 | **65** | 33.3 % |
| **cut at every `(* keep *)` carry** | 64 | 8 | **62** | **67.2 %** |

**Cutting at all 33 surviving carry nets barely moved the maximum: 65 → 62.**
The per-slice cones R2 expects (3 inputs each) are not there. Why:

```
carry[1]:3  carry[2]:4  carry[3]:6  carry[4]:8  carry[5]:4  carry[6]:12
carry[7]:14 carry[8]:16 carry[9]:18 carry[10]:20 carry[11]:22 carry[12]:24 …  max 62
```

⇒ **`carry[12]`'s cone is 24 primary bits — `a[0..11]` and `b[0..11]` — and does
NOT contain `carry[11]`.** abc **re-derived each carry from the primary inputs**
(carry-lookahead) instead of rippling. The supports grow ≈ 2k, which is the
signature of exactly that.

## 🎯 THE TRANSFERABLE FINDING: `(* keep *)` PRESERVES THE **NET**, NOT THE **DEPENDENCY**

The 33 carry nets all survived — the attribute did its job. **What did not
survive is the structure behind them.** A cut point can exist while the logic
feeding it has been globally re-synthesised from scratch.

⚠️ **This does not retract ruling 4a.** On the fabric, cutting at `w0`/`w1` took
max 36 → 21 and 87.5 % → 100 %, re-measured tonight and unchanged. The
difference is what sits behind the boundary: the fabric's stage boundary
genuinely separates three stages of routing logic, so cutting there removes real
depth. **A carry chain is a chain the optimiser is specifically built to
flatten** — carry-lookahead is the oldest trick in the adder book, and abc knows
it. ⇒ **The treatment's effectiveness is a property of the LOGIC, not of the
attribute.** Ruling 4a said `(* keep *)` survives TT's CI, and it does; it never
said a kept net bounds its own cone, and R2 is where that distinction bites.

## What R2 therefore rules

**The claimed answer is a correct PROOF STRATEGY and an unfinished ARTIFACT
STRATEGY.** Per-slice obligations are provable and cheap (half one). But they
apply to a netlist that *has* slices, and the flow does not produce one.

Candidate remedies, none yet demonstrated:

1. **Retained hierarchy** — a full-adder submodule the flow may not flatten.
   ⚠️ **Measured tonight on the fabric: `SYNTH_HIERARCHY_MODE: "keep"` dies at
   step 7 of TT's CI — `"1 Unmapped Yosys instances found"`, `gds` FAILS.** So
   *if the CPU targets TinyTapeout, this remedy is not available there.* Whether
   the CPU targets TT is a C6 question, not settled here.
2. **Cut at more nets than the carries** — the intermediate propagate/generate
   nodes are machine-named, so they must be `(* keep *)`-named in the RTL to be
   cuttable at all.
3. **Constrain the optimiser** — unexplored, and the least attractive: it makes
   the proof depend on a tool flag rather than on structure.

⇒ **Recommendation to the council: C3 should not freeze on "bit-slice with
per-slice carry obligations" as though the artifact side were settled. Half of
it is landed and half of it is an open engineering question with a measured
obstacle.**

## Method

Predictions were not pre-registered for R2 (they were for R3) — the monolithic
arm was expected to fail and did. **The result that was not expected is the cut
arm's 62**, and it was found by measuring rather than by assuming the fabric's
treatment would transfer. *The instrument that produced it is the one repaired
earlier tonight; both arms were re-run after the repair.*

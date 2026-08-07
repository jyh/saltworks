/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CompareExchangeC
import SaltWorks.HDL.EmitN
import SaltWorks.Silicon.Imported.CompareExchangeC

/-!
# BB-1 · B4 — THE SEAM: the FABRICATED element is the element that was PROVED

**Silicon's 14:31 named this as link ① of three and correctly refused to write
it.** *Their reasoning is exact and I verified it before acting: `SaltWorks.HDL`
imports `SaltWorks.Silicon` (`EmitN.lean:7` → `Silicon.Equiv.BitSliced`, because
`emitN : Circ → Silicon.Netlist`), and no Silicon module imports HDL.* ⇒ **A
theorem mentioning both `ceCNL` (Silicon) and `ceCcore` (HDL) can only live on
the HDL side, which is this seat's slot. Writing it there would have been a
writer-slot violation, and they stopped instead of committing one.**

## What the two halves prove, and the gap between them

```
ceC_step_eq   (compiler, CompareExchangeC)   the Circ/Seq element is correct
                                             128 configurations, no reachability
ceC_gate_eq   (silicon,  CERefinementC)      the HARDENED, IMPORTED netlist
                                             matches an INDEPENDENT reference
                                             written from the protocol
```

⚠️ **NEITHER MENTIONS THE OTHER'S OBJECT.** *Silicon's reference `ceCSpec` was
deliberately written from my behavioural spec rather than from my gate list — the
right call, because it makes their check independent rather than a transcription
of a transcription. **But independence is exactly what leaves the two proofs
unjoined**: mine is about `ceCcore`, theirs is about `ceCNL`, and nothing said
those are the same element.*

## ⛔ AND THEY ARE NOT THE SAME OBJECT — the seam is SEMANTIC, not syntactic

*I expected to write `ceCNL = emitN ceCcore` and close it by `rfl`.* **It is
false.** The hardening flow reorders:

```
ceCcore  net 9 = ¬d        (.not 8)        ceCNL index 9 = d ∧ swap  (.and 8 4)
ceCcore.outs = [30,33,35,26,40,39]         ceCNL_outs   = [30,33,35,26,36,40]
                              ^^ ^^                                    ^^ ^^
```

⇒ ***`phase'` and `bothAct'` do not sit on the same nets on the two sides, and
the gate order differs from index 9 onward.*** **So the seam had to be proved
over all 128 configurations rather than asserted by construction — and the
control below is that the two objects really do differ, so this theorem is not
`rfl` wearing a quantifier.**
-/

namespace SaltWorks.HDL

open SaltWorks.Silicon SaltWorks.Silicon.Imported

/-- `ceCcore` is dense SSA — the one hypothesis `emitN_sem` carries, and the
reason the emission is the identity on net names. -/
theorem ceCcore_ssa : ceCcore.ssa = true := by decide +kernel

/-- Read a netlist at a list of nets, under configuration `j`. **The same reader
silicon uses** (`CERefinementC.ceCRead`), restated here because it lives on the
far side of the import edge. -/
def nlRead (nl : Netlist) (idx : List Nat) (j : Nat) : List Bool :=
  idx.map (fun k => (runP (fun i => j.testBit i) [] nl).getD k false)

/-- All 128 configurations: 3 primary inputs + 4 state bits. -/
def seamCases : List Nat := List.range 128

/-! ### The seam -/

/-- The fabricated netlist, read at its own port list, against the `Circ`
semantics that `ceC_step_eq` is a theorem about. -/
def ceCSeamOK : Bool :=
  seamCases.all fun j =>
    nlRead ceCNL ceCNL_outs j == sem ceCcore (fun i => j.testBit i)

/-- ⭐ **LINK ① — THE FABRICATED ELEMENT COMPUTES `ceCcore`.** For all 128
configurations, the hardened, flow-processed, re-imported netlist read at its own
outputs agrees with the `Circ` whose behaviour `ceC_step_eq` certifies. **No
reachability assumption — unreachable states are quantified too.** -/
theorem ceCNL_is_ceCcore : ceCSeamOK = true := by decide +kernel

/-- And the emission agrees with the same `Circ` — this direction is not a
`decide`, it is `emitN_sem` instantiated, whose one hypothesis is `ssa`. -/
theorem emitN_ceCcore_sem (ins : Env) :
    ceCcore.outs.map (fun n => (runP ins [] (emitN ceCcore)).getD n false)
      = sem ceCcore ins :=
  emitN_sem ceCcore ceCcore_ssa ins

/-- ⭐ **THE CHAIN, CLOSED: the FABRICATED netlist and the EMITTED netlist compute
the same six outputs, on every configuration.** *`ceCNL` came out of the flow;
`emitN ceCcore` came out of the compiler. This says the flow did not change the
element — which is the sentence the whole leg-2/leg-3 seam exists to support.* -/
theorem ceCNL_agrees_with_emission :
    seamCases.all (fun j =>
      nlRead ceCNL ceCNL_outs j
        == nlRead (emitN ceCcore) ceCcore.outs j) = true := by
  decide +kernel

/-! ### NON-VACUITY — the two netlists are genuinely DIFFERENT OBJECTS

*This is the control that matters here. If `ceCNL` were syntactically
`emitN ceCcore`, everything above would be `rfl` with extra steps and would
certify nothing about the flow.* -/

/-- ⛔ **The two netlists are NOT equal**, and ⛔ **their port lists are NOT
equal** — the flow reordered gates and moved two of the six outputs. *So the
agreement above is a fact about behaviour, established over 128 configurations,
and not a definitional unfolding.* -/
theorem seam_is_not_syntactic :
    ceCNL ≠ emitN ceCcore ∧ ceCNL_outs ≠ ceCcore.outs := by
  decide +kernel

/-- The precise disagreement, named so it is not rediscovered: **`phase'` and
`bothAct'` sit on different nets on the two sides.** -/
theorem seam_ports_differ_at_the_last_two :
    ceCNL_outs.take 4 = ceCcore.outs.take 4
      ∧ ceCNL_outs.drop 4 = [36, 40]
      ∧ ceCcore.outs.drop 4 = [40, 39] := by
  decide +kernel

/-- …and the two netlists have the same LENGTH, so the difference is genuinely
reordering rather than one of them being truncated. -/
theorem seam_same_size : ceCNL.length = (emitN ceCcore).length := by decide +kernel

#audit_axioms ceCcore_ssa
#audit_axioms nlRead seamCases ceCSeamOK
#audit_axioms ceCNL_is_ceCcore
#audit_axioms emitN_ceCcore_sem
#audit_axioms ceCNL_agrees_with_emission
#audit_axioms seam_is_not_syntactic
#audit_axioms seam_ports_differ_at_the_last_two
#audit_axioms seam_same_size

end SaltWorks.HDL

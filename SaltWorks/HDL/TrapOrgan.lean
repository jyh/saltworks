/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# THE TRAP NEXT-STATE ORGAN — c4spec step 7's one-bit residual

`residual_after_placement` (CoreAssemblyD) says that placing `memOrgan` reaches `stWidthD - 1`:
256 memory bits land, and ONE does not — the architectural trap flag. The block register has
carried that bit as the surviving blocker. **It is one OR gate, and this file is that gate with
its semantics pinned.**

⭐ **READ OFF `ISA.step`, NOT INVENTED.** Both memory arms are:
```
| .LW rd a imm => if addrClass addr = .ok then (s.set rd …).next else { s with trapped := true }.next
| .SW a b imm  => if addrClass addr = .ok then { s with mem := … }.next else { s with trapped := true }.next
```
`trapped` is SET on a bad address and otherwise CARRIED — no arm ever clears it, and no
non-memory instruction touches it. ⇒ ***trapped' = trapped ∨ fault***, which is a two-input OR.

⭐ **AND THE `fault` INPUT ALREADY EXISTS, GATED CORRECTLY.** `dmemAddr8NL`'s `trap` output is
net 72 = `.and 71 32`, and net 32 is `.inp 32` = **`req`**. So the checker's trap fires only
when a memory request is active — the `memOp ∧ badAddr` conjunction the ISA needs is already
in the landed netlist, and this organ must NOT re-gate it.

⛔ **WHAT THIS DOES NOT DO.** It does not place itself into the assembly, and it does not
connect to `dmemAddr8NL` — that connection is the `Netlist → Circ` bridge, whose semantic
agreement theorem is still open (`NetlistBridge`, the five constructor branches). **This organ
closes the 257th bit's PRODUCER, not its wiring.**
-/
import SaltWorks.HDL.Sem
import SaltWorks.HDL.CoreAssemblyD

namespace SaltWorks.HDL.TrapOrgan
open SaltWorks.HDL

/-- Net 0 — the current trap flag, a primary input (the flop's Q). -/
def qNet : Net := 0
/-- Net 1 — the address checker's `trap`, already `fault ∧ req`. -/
def faultNet : Net := 1
/-- Net 2 — the D-root: the trap flag's next state. -/
def dNet : Net := 2

/-- ⭐ **THE ORGAN.** Two inputs, one gate, one output. -/
def trapOrgan : Circ :=
  { nIn := 2, gates := [⟨dNet, .or qNet faultNet⟩], outs := [dNet] }

theorem trapOrgan_ports : trapOrgan.nIn = 2 ∧ trapOrgan.outs.length = 1 := by decide +kernel

theorem trapOrgan_gate_count : trapOrgan.gates.length = 1 := by decide +kernel

theorem trapOrgan_wf : trapOrgan.wf = true := by decide +kernel

theorem trapOrgan_ssa : trapOrgan.ssa = true := by decide +kernel

/-- Read an input pair as an `Env`, so a finite sweep can quantify over inputs. -/
def insOf (q f : Bool) : Env := fun i => if i = qNet then q else if i = faultNet then f else false

/-- ⭐⭐ **THE SEMANTICS, OVER EVERY INPUT: the organ computes `q ∨ fault`.** -/
theorem trapOrgan_sem (q f : Bool) : sem trapOrgan (insOf q f) = [q || f] := by
  cases q <;> cases f <;> decide +kernel

/-- ⭐ **STICKINESS, the property the ISA fence actually names** — once set, the flag stays set
whatever the address checker says. *Stated separately because "sticky" is the word the fence
uses, and a reader should be able to find it as a theorem rather than infer it from an OR.* -/
theorem trapOrgan_sticky (f : Bool) : sem trapOrgan (insOf true f) = [true] := by
  cases f <;> decide +kernel

/-- ⛔ **AND IT DOES NOT FIRE ON ITS OWN — the negative control.** With no prior trap and no
fault the flag stays clear, so the organ is not a constant. -/
theorem trapOrgan_clear : sem trapOrgan (insOf false false) = [false] := by decide +kernel

/-- ⭐⭐⭐ **THE 257th BIT IS PRODUCED.** With `memOrgan`'s 256 next-state bits and this organ's
one, the assembly's output count reaches `stWidthD` exactly. *This is `residual_after_placement`
with its residual discharged.* -/
theorem trap_closes_the_width :
    CorePlace.core.outs.length + (memOrgan.outs.drop 32).length + trapOrgan.outs.length
      = SaltWorks.HDL.StateCodecD.stWidthD := by
  rw [CorePlace.core_outs_length, CoreAssemblyD.memOrgan_next_length]
  decide +kernel

#audit_axioms qNet faultNet dNet trapOrgan trapOrgan_ports trapOrgan_gate_count
#audit_axioms trapOrgan_wf trapOrgan_ssa insOf trapOrgan_sem trapOrgan_sticky
#audit_axioms trapOrgan_clear trap_closes_the_width

end SaltWorks.HDL.TrapOrgan

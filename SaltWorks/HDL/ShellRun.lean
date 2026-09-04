/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The shell's RUN-LEVEL refinement — R6's owed half

`ShellSeq.lean` landed the shell as a kernel object and was explicit about what it did
NOT land: *"the RUN-LEVEL refinement — that this NETLIST realises those Booleans — is NOT
here."* Its foot then named the remaining work as per-bit peeling with `run_snoc_frame`,
"list-splitting per bit, not a new theory".

**This file pays that half, and it needed neither the peeling nor the splitting.**
`SsaGateSem.run_gate_val` — landed later, on the RegNext mux track — already says a gate's
output net holds its op applied to the FINAL environment, by MEMBERSHIP, from the `ssa`
certificate alone. So each statement here is general in `j` and reads the netlist as a set
of simultaneous equations rather than as a sequence.

⭐ **The lesson repeats the one `ShellSeq.lean`'s own foot recorded, one level up.** That
note priced the obstacle from the tool it had (`run_of_flat_gates`, whose whole content is
its flatness hypothesis) and got it wrong. This note would have priced it from the tool
*that* correction left behind (`run_snoc_frame`, which wants a hand-split list) and got it
wrong again — the right tool was built three weeks later for a different organ. ⇒ **Re-price
a named debt against the CURRENT corpus before paying it, not against the corpus that named
it.** A debt's stated cost ages exactly as badly as a debt's stated liveness.

⛔ **SCOPE, so no reader takes more than is here.** These are statements about `shCore`, the
Lean-composed shell netlist, at the level of ONE combinational evaluation. They say nothing
about the fabricated die, and nothing about the sequential `shSeq` across cycles.
-/
import SaltWorks.HDL.ShellSeq
import SaltWorks.HDL.SsaGateSem

set_option autoImplicit false
set_option relaxedAutoImplicit false

namespace SaltWorks.HDL.Shell

open SaltWorks.HDL SaltWorks.HDL.MacCell

/-! ### The `ssa` certificate, in the form `run_gate_val` consumes -/

theorem shCore_ssaFrom : ssaFrom shCore.nIn shCore.gates = true := by
  have h := shCore_ssa
  rw [Circ.ssa, Bool.and_eq_true] at h
  exact h.1

/-! ### Membership: the shell's gates really are gates of `shCore`

These are the only place the block structure is touched. Everything after them is
equational, which is the whole point of going through `run_gate_val`. -/

/-- The three inverters. -/
theorem inv_gates_mem :
    (⟨hNclr, Op.not hClr⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hNenW, Op.not hEnW⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hNenA, Op.not hEnA⟩ : Gate) ∈ shCore.gates := by
  refine ⟨?_, ?_, ?_⟩ <;>
  · show _ ∈ instGates scCore hSig hOff ++ shGates
    refine List.mem_append_right _ ?_
    show _ ∈ _ ++ _
    refine List.mem_append_left _ ?_
    simp

/-- The three weight-select gates for bit `j`. -/
theorem wsh_gates_mem (j : Nat) (hj : j < 32) :
    (⟨hWa j, Op.and (hQ j) hNenW⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hWb j, Op.and (scOut (32 + j)) hEnW⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hWd j, Op.or (hWa j) (hWb j)⟩ : Gate) ∈ shCore.gates := by
  have hj' : j ∈ List.range 32 := List.mem_range.mpr hj
  refine ⟨?_, ?_, ?_⟩ <;>
  · show _ ∈ instGates scCore hSig hOff ++ shGates
    refine List.mem_append_right _ ?_
    show _ ∈ _ ++ _
    refine List.mem_append_left _ ?_
    simp only [List.mem_cons]
    refine Or.inr (Or.inr (Or.inr ?_))
    refine List.mem_flatten.mpr ⟨_, List.mem_map_of_mem hj', ?_⟩
    simp

/-- The four accumulator gates for bit `j`. -/
theorem acc_gates_mem (j : Nat) (hj : j < 32) :
    (⟨hAa j, Op.and (hQ (32 + j)) hNenA⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hAb j, Op.and (scOut (64 + j)) hEnA⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hAm j, Op.or (hAa j) (hAb j)⟩ : Gate) ∈ shCore.gates
  ∧ (⟨hAd j, Op.and (hAm j) hNclr⟩ : Gate) ∈ shCore.gates := by
  have hj' : j ∈ List.range 32 := List.mem_range.mpr hj
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
  · show _ ∈ instGates scCore hSig hOff ++ shGates
    refine List.mem_append_right _ ?_
    show _ ∈ _ ++ _
    refine List.mem_append_right _ ?_
    refine List.mem_flatten.mpr ⟨_, List.mem_map_of_mem hj', ?_⟩
    simp

/-! ### The three inverted controls -/

theorem run_hNenW (E : Env) : run E shCore.gates hNenW = !(E hEnW) := by
  have h := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom inv_gates_mem.2.1
  simp only [Op.eval] at h
  rw [h, run_below_base E shCore.gates shCore.nIn hEnW shCore_ssaFrom (by decide)]

theorem run_hNenA (E : Env) : run E shCore.gates hNenA = !(E hEnA) := by
  have h := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom inv_gates_mem.2.2
  simp only [Op.eval] at h
  rw [h, run_below_base E shCore.gates shCore.nIn hEnA shCore_ssaFrom (by decide)]

theorem run_hNclr (E : Env) : run E shCore.gates hNclr = !(E hClr) := by
  have h := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom inv_gates_mem.1
  simp only [Op.eval] at h
  rw [h, run_below_base E shCore.gates shCore.nIn hClr shCore_ssaFrom (by decide)]

/-! ### ⭐⭐ The refinement itself -/

/-- ⭐⭐ **WEIGHT BANK, GENERAL IN `j`.** The NETLIST at `hWd j` computes the shell's
Boolean select `muxB` — held when `en_wsh` is low, loaded from the cell when high. -/
theorem shell_wsh_run (E : Env) (j : Nat) (hj : j < 32) :
    run E shCore.gates (hWd j)
      = muxB (E hEnW) (E (hQ j)) (run E shCore.gates (scOut (32 + j))) := by
  obtain ⟨hma, hmb, hmd⟩ := wsh_gates_mem j hj
  have hd := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hmd
  have ha := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hma
  have hb := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hmb
  simp only [Op.eval] at hd ha hb
  have hQlt : hQ j < shCore.nIn := by
    show 6 + j < 70
    omega
  have hqj := run_below_base E shCore.gates shCore.nIn (hQ j) shCore_ssaFrom hQlt
  have hew := run_below_base E shCore.gates shCore.nIn hEnW shCore_ssaFrom (by decide)
  rw [hd, ha, hb, hqj, hew, run_hNenW, muxB]

/-- ⭐⭐ **ACCUMULATOR BANK, GENERAL IN `j`** — the same select, AND the clear on top. -/
theorem shell_acc_run (E : Env) (j : Nat) (hj : j < 32) :
    run E shCore.gates (hAd j)
      = (muxB (E hEnA) (E (hQ (32 + j))) (run E shCore.gates (scOut (64 + j))) && !(E hClr)) := by
  obtain ⟨hma, hmb, hmm, hmd⟩ := acc_gates_mem j hj
  have hd := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hmd
  have hm := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hmm
  have ha := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hma
  have hb := run_gate_val E shCore.gates shCore.nIn shCore_ssaFrom hmb
  simp only [Op.eval] at hd hm ha hb
  have hQlt : hQ (32 + j) < shCore.nIn := by
    show 6 + (32 + j) < 70
    omega
  have hqj := run_below_base E shCore.gates shCore.nIn (hQ (32 + j)) shCore_ssaFrom hQlt
  have hea := run_below_base E shCore.gates shCore.nIn hEnA shCore_ssaFrom (by decide)
  rw [hd, hm, ha, hb, hqj, hea, run_hNenA, run_hNclr, muxB]

/-- ⛔ **THE CLEAR DOMINATES IN THE NETLIST, not merely in the Boolean model.** With `clr`
asserted every accumulator bit is `false`, whatever the enable and whatever the cell
computed. `ShellSeq.clear_gates_exactly_the_acc_bank` says which bits the clear REACHES;
this says what it DOES when it gets there. -/
theorem shell_clear_dominates_run (E : Env) (j : Nat) (hj : j < 32) (hclr : E hClr = true) :
    run E shCore.gates (hAd j) = false := by
  rw [shell_acc_run E j hj, hclr]
  simp

/-! ⛔ **A THEOREM I WROTE AND THEN DELETED, RECORDED BECAUSE THE CATCH IS THE POINT.**
I had a `shell_clear_spares_wsh_run` here, docstringed *"the weight bank is not reached by
the clear"*. Its statement contained no `hClr` at all — its proof was `shell_wsh_run` itself.
The NAME and the DOCSTRING asserted something the STATEMENT did not say, and a reader would
have cited it for a claim it does not carry. **Grep your headline's nouns in the statement.**
The content is real and it is already here: `shell_wsh_run`'s right-hand side mentions
`E hEnW`, `E (hQ j)` and the cell output and NOTHING ELSE, so the weight bits' independence
from `clr` is a property of that equation, not a second theorem. -/

-- ONE NAME PER LINE: a multi-name call throwErrors at the first offender and every name
-- after it is NOT REACHED, and not-reached reads as clean.
#audit_axioms shCore_ssaFrom
#audit_axioms inv_gates_mem
#audit_axioms wsh_gates_mem
#audit_axioms acc_gates_mem
#audit_axioms run_hNenW
#audit_axioms run_hNenA
#audit_axioms run_hNclr
#audit_axioms shell_wsh_run
#audit_axioms shell_acc_run
#audit_axioms shell_clear_dominates_run

end SaltWorks.HDL.Shell

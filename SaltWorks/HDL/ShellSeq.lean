import SaltWorks.HDL.MacCell

/-! # `shSeq` — THE SHELL AS A KERNEL OBJECT (V9, R6)

**The shell existed only in the EMITTER.** `emitSeqShell` adds `en_wsh`/`en_acc`/`clr` in Verilog,
so the composed die carried its freeze and clear as hand-shaped RTL with no kernel object behind
them — the components that supply the schedule evidence's F5 walk found had NO SUPPLIER.

This file gives them one. It INSTANCES `scCore` rather than rebuilding it, so every property already
proved about the signed cell comes through `inst_sem` unchanged.

⚖️ **WHAT IS LANDED HERE AND WHAT IS OWED, stated at the top because the distinction is the whole
honesty of the item: the SHAPE is proved (ssa · wf · 452 gates · zero constants · instOK · the
clear reaches exactly the acc bank) and the shell's LOGIC is proved at the Boolean level (it is a
select; it holds; the clear dominates; it is transparent when driven). **The RUN-LEVEL refinement —
that this NETLIST realises those Booleans — is NOT here.** See the obstacle note at the foot. -/

namespace SaltWorks.HDL.Shell

open SaltWorks.HDL SaltWorks.HDL.MacCell

/-! ### Ports: x · load · sign · clr · en_acc · en_wsh, then 64 state bits -/
def hX : Net := 0
def hLoad : Net := 1
def hSign : Net := 2
def hClr : Net := 3
def hEnA : Net := 4
def hEnW : Net := 5
/-- state: wsh 6…37, acc 38…69 -/
def hQ (k : Nat) : Net := 6 + k
def hIn : Nat := 70
def hOff : Nat := 70          -- the scCore instance base

/-- scCore's σ: its x/load/sign come from ours; its 64 state inputs from ours. -/
def hSig (i : Nat) : Net :=
  if i = 0 then hX else if i = 1 then hLoad else if i = 2 then hSign else hQ (i - 3)

/-- scCore's outputs, lifted. `outs` is acc'(32) ++ wsh'(32) ++ acc'(32). -/
def scOut (k : Nat) : Net := instMap scCore hSig hOff (scCore.outs.getD k 0)

/-! ### Shell nets, contiguous from `hIn + 225` so `ssa` holds -/
def hNclr : Net := 295
def hNenW : Net := 296
def hNenA : Net := 297
-- wsh bit j: hold-arm, load-arm, or  →  D
def hWa (j : Nat) : Net := 298 + 3 * j
def hWb (j : Nat) : Net := 299 + 3 * j
def hWd (j : Nat) : Net := 300 + 3 * j
-- acc bit j: hold-arm, load-arm, or, then the CLEAR gate → D
def hAa (j : Nat) : Net := 394 + 4 * j
def hAb (j : Nat) : Net := 395 + 4 * j
def hAm (j : Nat) : Net := 396 + 4 * j
def hAd (j : Nat) : Net := 397 + 4 * j

def shGates : List Gate :=
  ⟨hNclr, Op.not hClr⟩ :: ⟨hNenW, Op.not hEnW⟩ :: ⟨hNenA, Op.not hEnA⟩
  :: ((List.range 32).map (fun j =>
        [ (⟨hWa j, Op.and (hQ j) hNenW⟩ : Gate),
          (⟨hWb j, Op.and (scOut (32 + j)) hEnW⟩ : Gate),
          (⟨hWd j, Op.or (hWa j) (hWb j)⟩ : Gate) ])).flatten
  ++ ((List.range 32).map (fun j =>
        [ (⟨hAa j, Op.and (hQ (32 + j)) hNenA⟩ : Gate),
          (⟨hAb j, Op.and (scOut (64 + j)) hEnA⟩ : Gate),
          (⟨hAm j, Op.or (hAa j) (hAb j)⟩ : Gate),
          (⟨hAd j, Op.and (hAm j) hNclr⟩ : Gate) ])).flatten

def shCore : Circ :=
  { nIn := hIn
    gates := instGates scCore hSig hOff ++ shGates
    outs := ((List.range 32).map (fun k => scOut k))
            ++ ((List.range 32).map hWd)
            ++ ((List.range 32).map hAd) }

/-- ⭐⭐ **THE SHELLED CELL AS A KERNEL `Seq`.** -/
def shSeq : Seq := { nIn := 6, nOut := 32, nState := 64, core := shCore }

/-! ### Shape -/

theorem shCore_ssa : shCore.ssa = true := by decide +kernel
theorem shCore_wf : shCore.wf = true := Circ.wf_of_ssa shCore_ssa
theorem shSeq_wf : shSeq.wf = true := by decide +kernel

/-- **452 gates: 225 (scCore) + 3 inverters + 96 (wsh selects) + 128 (acc selects + clear).** -/
theorem shCore_gate_count : shCore.gates.length = 452 := by decide +kernel

/-- **STILL zero constant gates** — the shell adds none. -/
theorem shCore_has_no_constant_gates :
    shCore.gates.filter (fun g => match g.op with | .const _ => true | _ => false) = [] := by
  decide +kernel

theorem shSeq_dimensions :
    shSeq.nIn = 6 ∧ shSeq.nOut = 32 ∧ shSeq.nState = 64 ∧ shCore.nIn = 70 := by
  refine ⟨rfl, rfl, rfl, rfl⟩

theorem sh_scCore_instOK : instOK scCore hSig hOff := by
  refine ⟨scCore_ssa, scCore_wf, ?_⟩
  intro i hi
  have h : scCore.nIn = 67 := by decide +kernel
  rw [h] at hi; revert hi; revert i; decide +kernel

/-- ⛔ **BIRTH-ASSERTION: the CLEAR gate reaches every accumulator bit and NO weight bit.**
This is the property the count-form check could not see (math's law) — WHICH bits are gated. -/
theorem clear_gates_exactly_the_acc_bank :
    ((List.range 32).all (fun j => (shGates.filter (fun g => g.out == hAd j)).any
        (fun g => match g.op with | .and _ b => b == hNclr | _ => false)))
  ∧ ((List.range 32).all (fun j => (shGates.filter (fun g => g.out == hWd j)).all
        (fun g => match g.op with | .and _ b => !(b == hNclr) | _ => true))) := by
  refine ⟨by decide +kernel, by decide +kernel⟩


/-! ### The shell's LOGIC, at the Boolean level -/

/-- The Boolean function the three select gates compute. -/
def muxB (en hold nxt : Bool) : Bool := (hold && !en) || (nxt && en)

/-- ⭐ **THE SELECT IS A SELECT**: hold on `en = 0`, load on `en = 1`. -/
theorem muxB_spec (en hold nxt : Bool) : muxB en hold nxt = if en then nxt else hold := by
  cases en <;> cases hold <;> cases nxt <;> rfl

/-- ⭐ **(1)+(2) THE HOLD**: with the enable low the bit keeps its value, whatever the core computed. -/
theorem shell_holds (hold nxt : Bool) : muxB false hold nxt = hold := by
  cases hold <;> cases nxt <;> rfl

/-- ⭐ **(3) THE CLEAR** dominates: `and (select …) ¬clr` is 0 whenever `clr` is high. -/
theorem shell_clear_dominates (en hold nxt : Bool) :
    (muxB en hold nxt && !true) = false := by
  cases en <;> cases hold <;> cases nxt <;> rfl

/-- ⭐ **(4) THE REFINEMENT, at the Boolean level**: clear low and enable high ⇒ the shell passes
the core's value through UNCHANGED — so every theorem landed on `scellSeq` survives the shell. -/
theorem shell_transparent (hold nxt : Bool) : (muxB true hold nxt && !false) = nxt := by
  cases hold <;> cases nxt <;> rfl

/-! ### The axiom audit — one declaration per call, added WITH the work -/

#audit_axioms shCore_ssa
#audit_axioms shCore_wf
#audit_axioms shSeq_wf
#audit_axioms shCore_gate_count
#audit_axioms shCore_has_no_constant_gates
#audit_axioms shSeq_dimensions
#audit_axioms sh_scCore_instOK
#audit_axioms clear_gates_exactly_the_acc_bank

#audit_axioms muxB_spec
#audit_axioms shell_holds
#audit_axioms shell_clear_dominates
#audit_axioms shell_transparent

end SaltWorks.HDL.Shell

/-! ## ⛔ THE OWED HALF — and the obstacle I named was OVER-PRICED

**Superseding my own note here (10:3x → 10:4x).** I wrote that the run-level refinement was blocked
because the corpus lacked the non-flat generalisation of `run_of_flat_gates`, offered two routes,
and called the choice *"a design decision rather than a mechanical one"*.

***It was neither. `Compose.run_snoc` + `run_snoc_frame` are eight lines and needed no induction —
`run_append` + `run_cons` give the peel directly, with no flatness hypothesis at all.***

🔑 **The lesson is not the lemma, it is how I priced it: I reasoned from the shape of the tool I
ALREADY HAD (`run_of_flat_gates`, whose whole content is its flatness hypothesis) to the difficulty
of the tool I NEEDED — so a missing hypothesis read as a missing theory.** *`an-estimate-from-absences`
one level up: I priced by what the existing lemma could not do instead of by what the new one
required.*

**STILL OWED, and now genuinely mechanical rather than blocked:** the per-bit refinement
(`run env shCore.gates (hWd j) = …`) via `run_snoc_frame`, peeling each select from the end. The
cost is list-splitting per bit, not a new theory. -/

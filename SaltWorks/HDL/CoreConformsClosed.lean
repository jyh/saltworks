/-
  ⭐⭐⭐ `CoreConforms core` — DISCHARGED. All three conjuncts, and the LEDGER's own
  standing debt with them.

  docs/LEDGER.md has carried this, twice, in the words that made it findable:
    "`CoreConforms` is still owed — `ssa` feeds `Circ.wf_of_ssa` and the emission layer,
     `nIn = coreInWidth` is the input-map obligation"
    "Neither is discharged and neither is used here; they are listed so nobody reads
     `sorts_of_C4`'s use of the `C4` structure as having consumed them."

  ⭐ IT WAS A COMPOSITION, NOT A DISCOVERY, AND EVERY PIECE WAS ALREADY LANDED: nineteen
  `instOK` theorems (one per placement, in `CorePlace`), `instGates_ssaFrom` (a placed block
  is dense SSA from its own offset), `GSCount.ssaFrom_append` (SSA splits along `++`), and an
  offset chain that is DEFINITIONAL — `off1 := instNext decoder off0` and so on for nineteen
  organs, so every base in the append chain is `rfl`, not arithmetic. What was missing was
  somebody walking the chain.

  ⛔ THE ZERO-GATE ORGAN IS NOT A SPECIAL CASE HERE. `ruledEnc` has zero gates, so
  `instNext ruledEnc offEnc = offEnc` and two organs share an offset. `CoreOffsets.lean`
  warns that a checker asserting strict monotonicity would falsely reject this assembly; the
  append chain never asks for that — an empty list contributes an empty segment and the base
  does not move. The hazard was real and this shape is immune to it by construction.

  ⛔⛔ WHAT THIS DOES NOT DO, and it is the same fence as the sitting table's fifth limit:
  `emitPipeline' core` is the netlist THIS TREE EMITS FROM THIS MODEL. It is NOT `core32.v`,
  the hand-written RTL that was fabricated, and no theorem in this tree relates the two.
  The object moves from a Lean-composed `Circ` to an actual `Silicon.Netlist`. The RTL
  correspondence stays OPEN.
-/
import SaltWorks.HDL.CoreAssembly
import SaltWorks.HDL.SsaGateSem
import SaltWorks.HDL.GenSelectCount
import SaltWorks.HDL.Renumber
import SaltWorks.HDL.R9BPositiveHalf

namespace SaltWorks.HDL.CoreConformsClosed
open SaltWorks.HDL SaltWorks.HDL.CorePlace

theorem instGates_length (c : Circ) (σ : Net → Net) (off : Nat) :
    (instGates c σ off).length = c.gates.length := by
  simp [instGates]

theorem step (c : Circ) (σ : Net → Net) (off : Nat) (hok : instOK c σ off)
    (rest : List Gate) (hrest : ssaFrom (instNext c off) rest = true) :
    ssaFrom off (instGates c σ off ++ rest) = true := by
  refine SaltWorks.HDL.GSCount.ssaFrom_append _ _ _ (instGates_ssaFrom c σ off hok) ?_
  rw [instGates_length]
  exact hrest

theorem last (c : Circ) (σ : Net → Net) (off : Nat) (hok : instOK c σ off) :
    ssaFrom off (instGates c σ off) = true :=
  instGates_ssaFrom c σ off hok

theorem off0_le_off2 : off0 ≤ off2 := by
  simp only [off2, off1, instNext]; omega

theorem off0_le_off3 : off0 ≤ off3 := by
  simp only [off3, off2, off1, instNext]; omega

set_option maxRecDepth 40000 in
theorem core_ssaFrom : ssaFrom core.nIn core.gates = true := by
  show ssaFrom offTie _ = true
  simp only [core, List.append_assoc]
  refine step tieCells id offTie (tieCells_instOK id offTie) _ ?_
  show ssaFrom off0 _ = true
  refine step decoder decoderSig off0 decoder_instOK _ ?_
  show ssaFrom off1 _ = true
  refine step immBCirc immBSig off1 immB_instOK _ ?_
  show ssaFrom off2 _ = true
  refine step readTree readTreeRs1Sig off2
    (instOK_mono readTree_rs1_instOK off0_le_off2) _ ?_
  show ssaFrom off3 _ = true
  refine step readTree readTreeRs2Sig off3
    (instOK_mono readTree_rs2_instOK off0_le_off3) _ ?_
  show ssaFrom off4 _ = true
  refine step bitXor32 bitXor32Sig off4 bitXor32_instOK _ ?_
  show ssaFrom off5 _ = true
  refine step bitNot32 bitNot32Sig off5 bitNot32_instOK _ ?_
  show ssaFrom offSelOr _ = true
  refine step selOr selOrSig offSelOr selOr_instOK _ ?_
  show ssaFrom offImmMux _ = true
  refine step OperandB.obMux immMuxSig offImmMux immMux_instOK _ ?_
  show ssaFrom offOb _ = true
  refine step OperandB.obMux obSig offOb ob_instOK _ ?_
  show ssaFrom offAdd _ = true
  refine step adder32 addSig offAdd add_instOK _ ?_
  show ssaFrom offSub _ = true
  refine step adder32 subSig offSub sub_instOK _ ?_
  show ssaFrom offSlt _ = true
  refine step sltCirc sltSig offSlt slt_instOK _ ?_
  show ssaFrom offSel _ = true
  refine step SelectCut32.sliceASelect selSig offSel sel_instOK _ ?_
  show ssaFrom offEnc _ = true
  refine step EncoderE1.ruledEnc encSig offEnc enc_instOK _ ?_
  show ssaFrom offLwWr _ = true
  refine step lwWrCirc lwWrSig offLwWr lwWr_instOK _ ?_
  show ssaFrom offRw _ = true
  refine step regWrite regWriteSig offRw regWrite_instOK _ ?_
  show ssaFrom offPc _ = true
  refine step SaltWorks.Stack.Program.pcAdd pcAddSig offPc pcAdd_instOK _ ?_
  show ssaFrom offRegNext _ = true
  exact last regNext regNextSig offRegNext regNext_instOK
/-! ### The second conjunct: every primary output names a net the netlist contains. -/

theorem core_gates_length_eq :
    core.gates.length
      = tieCells.gates.length + decoder.gates.length + immBCirc.gates.length
        + readTree.gates.length + readTree.gates.length + bitXor32.gates.length
        + bitNot32.gates.length + selOr.gates.length + OperandB.obMux.gates.length
        + OperandB.obMux.gates.length + adder32.gates.length + adder32.gates.length
        + sltCirc.gates.length + SelectCut32.sliceASelect.gates.length
        + EncoderE1.ruledEnc.gates.length + lwWrCirc.gates.length
        + regWrite.gates.length + SaltWorks.Stack.Program.pcAdd.gates.length
        + regNext.gates.length := by
  simp only [core, instGates, List.length_append, List.length_map]

theorem outs_bound_of_block (c : Circ) (σ : Net → Net) (off : Nat)
    (hok : instOK c σ off) (B : Nat) (hB : instNext c off ≤ B) :
    ∀ m ∈ instOuts c σ off, m < B := by
  intro m hm
  obtain ⟨hssa, _, hin⟩ := hok
  have hoff : off ≤ B := le_trans (Nat.le_add_right off c.gates.length) hB
  rcases instOuts_range c σ off hssa m hm with ⟨i, hi, rfl⟩ | ⟨_, hlt⟩
  · exact Nat.lt_of_lt_of_le (hin i hi) hoff
  · exact Nat.lt_of_lt_of_le hlt hB

theorem chain_bound_regNext :
    instNext regNext offRegNext = core.nIn + core.gates.length := by
  rw [core_gates_length_eq]
  simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd,
    offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext, core]
  omega

theorem chain_bound_pcAdd :
    instNext SaltWorks.Stack.Program.pcAdd offPc ≤ core.nIn + core.gates.length := by
  rw [core_gates_length_eq]
  simp only [offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd,
    offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext, core]
  omega

set_option maxRecDepth 40000 in
theorem core_outs_ok :
    core.outs.all (fun n => n < core.nIn + core.gates.length) = true := by
  rw [List.all_eq_true]
  intro m hm
  simp only [decide_eq_true_eq]
  have hmm : m ∈ (instOuts regNext regNextSig offRegNext
      ++ instOuts SaltWorks.Stack.Program.pcAdd pcAddSig offPc) := hm
  rcases List.mem_append.mp hmm with h | h
  · exact outs_bound_of_block regNext regNextSig offRegNext regNext_instOK _
      (le_of_eq chain_bound_regNext) m h
  · exact outs_bound_of_block SaltWorks.Stack.Program.pcAdd pcAddSig offPc pcAdd_instOK _
      chain_bound_pcAdd m h

theorem core_ssa : core.ssa = true := by
  rw [Circ.ssa, Bool.and_eq_true]
  exact ⟨core_ssaFrom, core_outs_ok⟩

/-! ### What `core.ssa` unlocks, immediately and with no further work. -/

theorem core_wf : core.wf = true := Circ.wf_of_ssa core_ssa

theorem core_nIn : core.nIn = coreInWidth := rfl

theorem coreConforms_core : SaltWorks.HDL.CoreConforms core :=
  ⟨core_ssa, core_nIn, core_outs_length⟩

/-! ### ⭐ AND WHAT `core.wf` UNLOCKS: THE EMITTED NETLIST.

⛔⛔ READ THIS BEFORE THE THEOREM. `emitPipeline' core` is the netlist THIS TREE EMITS FROM
THIS MODEL. It is **NOT `core32.v`**, the hand-written RTL that was fabricated, and no
theorem in this tree relates the two. What moves here is the object — from the Lean-composed
`Circ` to an actual `Silicon.Netlist` — and nothing else. The RTL correspondence stays OPEN
and stays exactly where the sitting table's fifth limit puts it. -/

open SaltWorks.Stack.Program SaltWorks.HDL.MemFreeScope in
open SaltWorks.HDL.R9BPositiveReduction SaltWorks.HDL.R9BPositiveHalf in
theorem emitted_core_realises_the_step (ins : Env)
    (hs : memFreeB (SaltWorks.Stack.Program.seenWord ins) = true) :
    (normalize (opt core)).outs.map
        (fun n => (Silicon.runP ins [] (emitPipeline' core)).getD n false)
      = encD (SaltWorks.ISA.stepT (decQ ins) (SaltWorks.Stack.Program.seenWord ins)) := by
  rw [emitPipeline'_sem core core_wf ins]
  exact c4SpecAt_core_of_scoped THE_SCOPED_OBLIGATION ins hs

#audit_axioms core_wf core_nIn coreConforms_core emitted_core_realises_the_step
#audit_axioms instGates_length step last core_ssaFrom
#audit_axioms core_gates_length_eq outs_bound_of_block
#audit_axioms chain_bound_regNext chain_bound_pcAdd core_outs_ok core_ssa

end SaltWorks.HDL.CoreConformsClosed

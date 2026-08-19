/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (executor, brief #3); compiler seat (promotion, final corollary)

# The `RegNext` uniformity schema, transported onto `core`

**PROVENANCE, because the finding matters more than the file.** This was produced by an
Opus executor against compiler brief #3, which asked for a general uniform mux lemma. Its
first finding was that **the briefed goal was already in the tree** —
`SaltWorks.Stack.Program.run_regNextN` (`Program.lean:7476`), general, proved and audited —
and that `RegNext.lean:159` points at the *corollary* `sem_regNextN` without ever naming
it. Attempt count at the briefed goal: **zero; located by reading, not proved.** The seat
that wrote the brief had independently re-derived the same lemma and announced it as
missing; that retraction is at `d115a76` and in a `git note` on `71d877f`.

**So the budget went to the step actually open — the TRANSPORT.** `RegField c r` is about
`core`, whose gate list is `instGates regNext regNextSig offRegNext` appended after fifteen
other organ blocks and relocated by `regNextSig`/`offRegNext`; `run_regNextN` speaks about
`(regNextN R W).gates` standalone. The chain is `core_gates_split` → `core_outs_index` →
`inst_sem` → `run_regNextN` → `inst_frame_below`, consuming `RegFieldSchema`'s wiring
results as stated.

⛔ **WHAT THIS IS NOT.** No `RegField` is discharged: this is the SCHEMA — the reduction of
output bit `32r+k` to three named reads — not the correctness of what those reads compute.
Not C4, not a witness, does not close R9/B2. The two remaining halves are the campaign:
`rwOut r` is `regWrite` correctness, `selOut k` is the ALU/decode/select path.
-/
import SaltWorks.HDL.CoreAssembly
import SaltWorks.HDL.RegFieldSchema

set_option maxHeartbeats 4000000
set_option maxRecDepth 8000

namespace SaltWorks.HDL.RegNextUniform

open SaltWorks.HDL
open SaltWorks.HDL.CorePlace

/-! ## PART 0 — THE GOAL AS BRIEFED, RESTATED AND DISCHARGED

Stated here in the brief's own words so the claim is checkable at a glance.  The
proof term is the existing theorem: this is a CITATION with a kernel receipt, not
a second proof. -/

/-- ⭐ **THE SCHEMA.** Every register `r < R`, every bit `k < W`, every array
size, every input valuation. -/
theorem regNextN_uniform (R W : Nat) (ins : Env) (r k : Nat) (hr : r < R) (hk : k < W) :
    run ins (regNextN R W).gates (rnOut R W r k)
      = (if ins (rnWe r) then ins (rnRes R k) else ins (rnCur R W r k)) :=
  SaltWorks.Stack.Program.run_regNextN R W ins r k hr hk

/-! ### It instantiates — demonstrated, not asserted -/

/-- Instantiation at the shipping size, register 7, bit 13, nets spelled out.
*`rnWe 7 = 7`, `rnRes 32 13 = 45`, `rnCur 32 32 7 13 = 64 + 224 + 13 = 301`.* -/
theorem regNext_uniform_r7_k13 (ins : Env) :
    run ins regNext.gates (rnOut 32 32 7 13)
      = (if ins 7 then ins 45 else ins 301) :=
  regNextN_uniform 32 32 ins 7 13 (by norm_num) (by norm_num)

/-- Instantiation at a fixed register, still universal in the bit — the shape a
`RegField r` consumer wants: **one line per register.** -/
theorem regNext_uniform_r31 (ins : Env) (k : Nat) (hk : k < 32) :
    run ins regNext.gates (rnOut 32 32 31 k)
      = (if ins 31 then ins (32 + k) else ins (64 + 32 * 31 + k)) :=
  regNextN_uniform 32 32 ins 31 k (by norm_num) hk

/-- …and at the boundary the 4×4 / 8×8 certificates never reached.
*`rnCur 32 32 31 31 = 32 + 32 + 32·31 + 31 = 1087`.* -/
theorem regNext_uniform_r31_k31 (ins : Env) :
    run ins regNext.gates (rnOut 32 32 31 31)
      = (if ins 31 then ins 63 else ins 1087) :=
  regNextN_uniform 32 32 ins 31 31 (by norm_num) (by norm_num)

/-- ⛔ **NON-VACUITY — the `if` is not decoration.** Two environments differing only
in the enable bit for register 7 give DIFFERENT answers at the same output net, so
the schema discriminates rather than being satisfiable by a constant.
*Costs nothing: it rewrites by the schema first, so no circuit is evaluated.* -/
theorem regNextN_uniform_is_not_constant :
    run (fun n => decide (n = 7 ∨ n = 45)) regNext.gates (rnOut 32 32 7 13) = true
      ∧ run (fun n => decide (n = 45)) regNext.gates (rnOut 32 32 7 13) = false := by
  refine ⟨?_, ?_⟩
  · rw [regNext_uniform_r7_k13]; decide +kernel
  · rw [regNext_uniform_r7_k13]; decide +kernel

/-- ⛔ **THE TRANSPOSE GUARD, from the reader's side** — `32r + k` separates
`(r, k)` pairs, so the schema cannot be satisfied by a column-wise file. -/
theorem state_reader_injective (r k r' k' : Nat) (hk : k < 32) (hk' : k' < 32)
    (h : 32 * r + k = 32 * r' + k') : r = r' ∧ k = k' := by omega

#audit_axioms regNextN_uniform
#audit_axioms regNext_uniform_r7_k13 regNext_uniform_r31 regNext_uniform_r31_k31
#audit_axioms regNextN_uniform_is_not_constant state_reader_injective

/-! ## PART 1 — THE MUX OUTPUT IS A GATE OUTPUT

`inst_sem`'s side condition is `a < c.nIn ∨ (c.gates.map Gate.out).contains a`.
At 3,104 gates and a symbolic `(r, k)` that is not decidable; it is proved from
the `flatMap` structure instead, generally in `R` and `W`. -/

theorem rnOut_mem_gate_outs (R W r k : Nat) (hr : r < R) (hk : k < W) :
    ((regNextN R W).gates.map Gate.out).contains (rnOut R W r k) = true := by
  have hshape : (regNextN R W).gates
      = (List.range R).map (fun r => (⟨rnNotWe R W r, Op.not (rnWe r)⟩ : Gate))
        ++ (List.range R).flatMap (fun r => (List.range W).flatMap (rnMux R W r)) := rfl
  have hg : (⟨rnOut R W r k, Op.or (rnMuxBase R W r k) (rnMuxBase R W r k + 1)⟩ : Gate)
      ∈ (regNextN R W).gates := by
    rw [hshape]
    refine List.mem_append_right _ ?_
    refine List.mem_flatMap.mpr ⟨r, List.mem_range.mpr hr, ?_⟩
    refine List.mem_flatMap.mpr ⟨k, List.mem_range.mpr hk, ?_⟩
    simp [rnMux]
  have hmem : rnOut R W r k ∈ (regNextN R W).gates.map Gate.out :=
    List.mem_map.mpr ⟨_, hg, rfl⟩
  simpa using hmem

#audit_axioms rnOut_mem_gate_outs

/-! ## PART 2 — THE TRANSPORT INTO `core`

`core.gates` is a right-associated append of sixteen `instGates` blocks with
`regNext`'s block LAST.  Naming the fifteen-block prefix once turns the whole
composition into a single `run_append`. -/

/-- The fifteen organ blocks that precede `regNext` in `core`. -/
def corePre : List Gate :=
  instGates tieCells id offTie
    ++ instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc
    ++ instGates regWrite regWriteSig offRw
    ++ instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc

theorem core_gates_split :
    core.gates = corePre ++ instGates regNext regNextSig offRegNext := by
  simp only [core, corePre, List.append_assoc]

/-- Register `r`'s bit `k` sits at output position `32r + k` and names the
relocated mux output. *`core_outs_reg_half` says the register bank is the first
1,024 outputs; `regNext_outs_index` says which net each one is.* -/
theorem core_outs_index (r k : Nat) (hr : r < 32) (hk : k < 32) :
    core.outs.getD (32 * r + k) 0
      = instMap regNext regNextSig offRegNext (rnOut 32 32 r k) := by
  have hOuts : core.outs
      = instOuts regNext regNextSig offRegNext
        ++ instOuts SaltWorks.Stack.Program.pcAdd pcAddSig offPc := rfl
  have hlenO : regNext.outs.length = 1024 := by decide +kernel
  have hlen : (instOuts regNext regNextSig offRegNext).length = 1024 := by
    simp only [instOuts, List.length_map, hlenO]
  have hlt : 32 * r + k < (instOuts regNext regNextSig offRegNext).length := by
    rw [hlen]; omega
  have hlt' : 32 * r + k < regNext.outs.length := by rw [hlenO]; omega
  have hidx : regNext.outs.getD (32 * r + k) 0 = rnOut 32 32 r k :=
    regNext_outs_index r hr k hk
  rw [List.getD_eq_getElem _ _ hlt'] at hidx
  rw [hOuts, List.getD_append _ _ _ _ hlt]
  show (regNext.outs.map (instMap regNext regNextSig offRegNext)).getD (32 * r + k) 0 = _
  rw [List.getD_eq_getElem _ _ (by simpa using hlt'), List.getElem_map, hidx]

/-- Nets below `regNext`'s offset read the same in `core` as in the prefix. -/
theorem core_frame_below (ins : Env) (n : Net) (hn : n < offRegNext) :
    run ins core.gates n = run ins corePre n := by
  rw [core_gates_split, run_append]
  exact inst_frame_below regNext regNextSig offRegNext regNext_ssa (run ins corePre) n hn

/-- ⭐⭐⭐ **THE `RegField` SCHEMA, PROVED ABOUT `core`.** Output bit `32r + k` of
the assembled core is `regWrite`'s enable for register `r` selecting between the
shared result bit and the incoming state bit — **one lemma, universal in `r` and
`k`, no enable-vector assumption, no fixed register.**

```
run … (rwOut r)     the per-register half   ← the ONLY place r enters the control
run … (selOut k)    the shared half         ← register-INDEPENDENT: proved once
run … (32 * r + k)  the incoming state bit  ← a primary input, a pure shift in r
```
⇒ ***`RegField core r` for all 32 registers is now this lemma plus `rwOut`/`selOut`
correctness. The 32 grinds collapse into 1 + 32 instantiations.*** -/
theorem core_reg_bit (ins : Env) (r k : Nat) (hr : r < 32) (hk : k < 32) :
    run ins core.gates (core.outs.getD (32 * r + k) 0)
      = (if run ins core.gates (rwOut r)
         then run ins core.gates (selOut k)
         else run ins core.gates (32 * r + k)) := by
  -- the three σ equations (RegFieldSchema.lean's wiring result, used as stated)
  have e_we : regNextSig r = rwOut r := by simp only [regNextSig, if_pos hr]
  have e_res : regNextSig (32 + k) = selOut k := res_bank_is_register_independent k hk
  have e_cur : regNextSig (64 + (32 * r + k)) = 32 * r + k :=
    (regNextSig_banks_are_uniform r k hr hk).2.2
  -- each of the three host nets lies below regNext's offset, so the frame applies.
  -- ⚠️ `regNextSig_organs_lt`'s hypothesis `i < 64` sits at `Net`, and CorePlace:1210 records
  -- that `omega` DROPS such a goal and then reports a "counterexample" built only from the
  -- context. Both bounds are therefore stated at `Nat` first and fed in as terms.
  have hr64 : (r : Nat) < 64 := by omega
  have hk64 : (32 + k : Nat) < 64 := by omega
  have b_we : rwOut r < offRegNext := by
    have h := regNextSig_organs_lt r hr64; rwa [e_we] at h
  have b_res : selOut k < offRegNext := by
    have h := regNextSig_organs_lt (32 + k) hk64; rwa [e_res] at h
  have b_cur : 32 * r + k < offRegNext := by
    have h := regNextSig_cur_lt (64 + (32 * r + k)) (by omega) (by omega)
    rwa [e_cur] at h
  -- the host's view of regNext's input bank
  have step1 : run ins core.gates (core.outs.getD (32 * r + k) 0)
      = run (fun a => run ins corePre (regNextSig a)) regNext.gates (rnOut 32 32 r k) := by
    rw [core_outs_index r k hr hk, core_gates_split, run_append]
    exact inst_sem regNext regNextSig offRegNext (run ins corePre)
      (fun a => run ins corePre (regNextSig a)) regNext_instOK (fun _ _ => rfl)
      (rnOut 32 32 r k) (Or.inr (rnOut_mem_gate_outs 32 32 r k hr hk))
  have step2 : run (fun a => run ins corePre (regNextSig a)) regNext.gates (rnOut 32 32 r k)
      = (if run ins corePre (regNextSig (rnWe r))
         then run ins corePre (regNextSig (rnRes 32 k))
         else run ins corePre (regNextSig (rnCur 32 32 r k))) :=
    SaltWorks.Stack.Program.run_regNextN 32 32 _ r k hr hk
  -- the three input nets, named
  have n_we : (rnWe r : Net) = r := rfl
  have n_res : (rnRes 32 k : Net) = 32 + k := rfl
  have n_cur : (rnCur 32 32 r k : Net) = 64 + (32 * r + k) := by
    show (32 + 32 + 32 * r + k : Nat) = 64 + (32 * r + k)
    omega
  rw [step1, step2, n_we, n_res, n_cur, e_we, e_res, e_cur,
      core_frame_below ins (rwOut r) b_we, core_frame_below ins (selOut k) b_res,
      core_frame_below ins (32 * r + k) b_cur]

/-- ⭐⭐ **THE SAME, IN `RegField`'s OWN IDIOM** — `outBit core ins (32r + k)`, the
positional reader `regField_iff_bits` hands a prover. -/
theorem core_outBit_reg (ins : Env) (r k : Nat) (hr : r < 32) (hk : k < 32) :
    SaltWorks.Stack.Program.outBit core ins (32 * r + k)
      = (if run ins core.gates (rwOut r)
         then run ins core.gates (selOut k)
         else run ins core.gates (32 * r + k)) := by
  have hlen : core.outs.length = 1056 := by rw [core_outs_length]; rfl
  have hlt : 32 * r + k < core.outs.length := by rw [hlen]; omega
  have h0 : core.outs.getD (32 * r + k) 0 = core.outs[32 * r + k] :=
    List.getD_eq_getElem _ _ hlt
  show (core.outs.map (run ins core.gates)).getD (32 * r + k) false = _
  rw [List.getD_eq_getElem _ _ (by simpa using hlt), List.getElem_map, ← h0]
  exact core_reg_bit ins r k hr hk

#audit_axioms corePre core_gates_split core_outs_index core_frame_below
#audit_axioms core_reg_bit core_outBit_reg

/-! ### The core-level schema instantiates too -/

/-- One of the thirty-two, at register 7 — universal in the bit, no hypothesis
left over. **This is the "+ 32 instantiations" half, compiling.** -/
theorem core_reg7_bit (ins : Env) (k : Nat) (hk : k < 32) :
    SaltWorks.Stack.Program.outBit core ins (224 + k)
      = (if run ins core.gates (rwOut 7)
         then run ins core.gates (selOut k)
         else run ins core.gates (224 + k)) := by
  have h := core_outBit_reg ins 7 k (by norm_num) hk
  rwa [show 32 * 7 + k = 224 + k from by omega] at h

/-- …and at register 31, bit 31: the corner no exhaustive certificate reached. -/
theorem core_reg31_bit31 (ins : Env) :
    SaltWorks.Stack.Program.outBit core ins 1023
      = (if run ins core.gates (rwOut 31)
         then run ins core.gates (selOut 31)
         else run ins core.gates 1023) := by
  have h := core_outBit_reg ins 31 31 (by norm_num) (by norm_num)
  rwa [show 32 * 31 + 31 = 1023 from by norm_num] at h

#audit_axioms core_reg7_bit core_reg31_bit31

/-! ### The closure, named rather than counted

`#audit_axioms` prints a COUNT; these print the NAMES, so the three-axiom claim is
readable without trusting the counter. -/

#print axioms regNextN_uniform
#print axioms core_reg_bit
#print axioms core_outBit_reg

/-! ### The last reduction — brief #3's declared LIMIT 2, closed -/

/-- ⭐ **THE FULLY REDUCED SCHEMA.** Brief #3 declared that `run ins core.gates (32r+k)`
*"should be reduced to `ins (32r+k)` … but that needs a gate-out-range lemma over all
sixteen blocks WHICH DOES NOT EXIST YET."* `core_input_stable` (`RegFieldSchema.lean`) is
that lemma, so the `else` branch is now the primary input itself.

⇒ ***Output bit `32r + k` of `core` is: the shared result bit when register `r` is enabled,
and OTHERWISE THE INPUT STATE BIT UNCHANGED*** — the hold half stated against the input
valuation, which is the form a `RegField` proof consumes. -/
theorem core_outBit_reg_reduced (ins : Env) (r k : Nat) (hr : r < 32) (hk : k < 32) :
    SaltWorks.Stack.Program.outBit core ins (32 * r + k)
      = (if run ins core.gates (rwOut r)
         then run ins core.gates (selOut k)
         else ins (32 * r + k)) := by
  rw [core_outBit_reg ins r k hr hk, core_state_bit_stable ins r k hr hk]

#audit_axioms core_outBit_reg_reduced

end SaltWorks.HDL.RegNextUniform

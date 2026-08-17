/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.BatcherNetC

/-! # The seam's trace induction — the B4 gate.

**Why a separate module rather than an append to `BatcherNetC.lean`:** that file
is in the hub import closure, so a half-written append there is every seat's
failed build. This module is NOT yet in the closure — **`import owed:
SaltWorks.HDL.SeamTrace`** — so it is built targeted
(`../saltbuild.sh SaltWorks.HDL.SeamTrace`) until the maestro sweeps.

*(It began as `ScratchSeam.lean` and was promoted within the hour: `Scratch*` is
gitignored by fleet convention, so a scratch file is **not protected by git** —
and on a night when a neighbour's `reset --hard` has already eaten one
uncommitted edit, hours of proof living only in the working tree is the same
hazard with a bigger blast radius.)*
-/

namespace SaltWorks.HDL

set_option maxRecDepth 8000

/-- The data-net list after element `e` has written its two outputs. Names the
thing the fold computes inline, so the indexing induction can talk about it. -/
def bnCDatStep (e a b : Nat) (dat : List Net) : List Net :=
  let os := instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)
  (dat.set a (os.getD 0 0)).set b (os.getD 1 0)

/-- The data-net list after `k` elements have written, from element `e`. -/
def bnCDatDrop : Nat → Nat → List (Nat × Nat) → List Net → List Net
  | _, 0,   _,  dat => dat
  | e, k+1, cs, dat =>
    match cs with
    | []           => dat
    | (a, b) :: cs => bnCDatDrop (e+1) k cs (bnCDatStep e a b dat)

/-- One element's worth of state, dropped. -/
theorem bnCBuild_state_drop4 (e a b : Nat) (cs : List (Nat × Nat)) (dat : List Net) :
    (bnCBuild e ((a, b) :: cs) dat).2.2.drop 4
      = (bnCBuild (e+1) cs (bnCDatStep e a b dat)).2.2 := rfl

/-- ⭐ **THE MISSING INDUCTION — dropping `4*k` state nets is skipping `k`
elements.** Everything landed is about `bnCBuild e ((a,b) :: cs)`, i.e. the fold
whose HEAD is the element in question; the one-cycle slice lemma needs the fold
from 0, and this is the bridge. -/
theorem bnCBuild_state_drop :
    ∀ (k : Nat) (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
      (bnCBuild e cs dat).2.2.drop (4 * k)
        = (bnCBuild (e + k) (cs.drop k) (bnCDatDrop e k cs dat)).2.2 := by
  intro k
  induction k with
  | zero => intro cs e dat; simp [bnCDatDrop]
  | succ k ih =>
    intro cs e dat
    match cs with
    | [] =>
      show (([] : List Net)).drop (4 * (k+1)) = _
      simp [bnCBuild, bnCDatDrop]
    | (a, b) :: cs =>
      have h4 : 4 * (k+1) = 4 + 4 * k := by ring
      have he : e + (k+1) = (e+1) + k := by omega
      rw [h4, ← List.drop_drop, bnCBuild_state_drop4, he, List.drop_succ_cons]
      exact ih cs (e+1) (bnCDatStep e a b dat)

/-! ### The gate prefix, and the data-net bound

*`run_append` turns `run E (gs₀ ++ gsₑ) n` into `run (run E gs₀) gsₑ n`, and
`bnCBuild_element_sem'` takes an ARBITRARY `env` — so instantiating it at
`run E gs₀` is what carries the per-element factorisation into the full network.
These two lemmas supply its hypotheses.* -/

/-- The fold's gates split at any element boundary. -/
theorem bnCBuild_gates_drop :
    ∀ (k : Nat) (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
      ∃ pre, (bnCBuild e cs dat).1
        = pre ++ (bnCBuild (e + k) (cs.drop k) (bnCDatDrop e k cs dat)).1 := by
  intro k
  induction k with
  | zero => intro cs e dat; exact ⟨[], by simp [bnCDatDrop]⟩
  | succ k ih =>
    intro cs e dat
    match cs with
    | [] => exact ⟨[], by simp [bnCBuild, bnCDatDrop]⟩
    | (a, b) :: cs =>
      obtain ⟨pre, hpre⟩ := ih cs (e+1) (bnCDatStep e a b dat)
      refine ⟨instGates ceCcore (bnCSigma e a b dat) (bnCOff e) ++ pre, ?_⟩
      have he : e + (k+1) = (e+1) + k := by omega
      rw [he, List.drop_succ_cons]
      show instGates ceCcore (bnCSigma e a b dat) (bnCOff e)
             ++ (bnCBuild (e+1) cs (bnCDatStep e a b dat)).1 = _
      rw [hpre, List.append_assoc]
      rfl

/-! ### What already existed — recorded because I re-derived it

⚠️ **`bnCOff_eq`, `bnCState_eq`, `bnCState_lt_off`, `bnCRst_lt_off`, `bnCOff_mono`
and `bnCSigma_below` were ALL already landed in `BatcherNetC.lean`, and I spent
two build cycles re-proving them.** *The bank named eleven lemmas; I read the
bank and not the file.* ⇒ ***Inventory before proving: `grep "^theorem" ` the
module you are extending, not the note you wrote about it.***

*(`bnCSigma_below` is the general form of the wiring bound; `bnCSigma_dat_step`
is the one-step data invariant. Both are used below rather than rebuilt.)* -/

/-- `set` preserves length, so the fold's data list keeps its width. -/
theorem bnCDatStep_length (e a b : Nat) (dat : List Net) :
    (bnCDatStep e a b dat).length = dat.length := by
  simp [bnCDatStep]

theorem bnCDatDrop_length :
    ∀ (k : Nat) (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
      (bnCDatDrop e k cs dat).length = dat.length := by
  intro k
  induction k with
  | zero => intro cs e dat; simp [bnCDatDrop]
  | succ k ih =>
    intro cs e dat
    match cs with
    | [] => simp [bnCDatDrop]
    | (a, b) :: cs =>
      show (bnCDatDrop (e+1) k cs (bnCDatStep e a b dat)).length = dat.length
      rw [ih, bnCDatStep_length]

/-- ⭐ **THE `dat` INVARIANT, LIFTED ACROSS `k` ELEMENTS** — `bnCSigma_dat_step`
is the one-step version; this threads it, and it is what lets
`bnCBuild_element_sem'` fire at element `e` of the fold that starts at 0. -/
theorem bnCDatDrop_below :
    ∀ (k : Nat) (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
      (∀ n ∈ dat, n < bnCOff e) →
      (∀ p ∈ cs, p.1 < dat.length ∧ p.2 < dat.length) →
      ∀ n ∈ bnCDatDrop e k cs dat, n < bnCOff (e + k) := by
  intro k
  induction k with
  | zero => intro cs e dat hdat _ n hn; simpa [bnCDatDrop] using hdat n hn
  | succ k ih =>
    intro cs e dat hdat hab n hn
    match cs with
    | [] =>
      have h : bnCOff e < bnCOff (e + (k+1)) := bnCOff_mono _ _ (by omega)
      exact Nat.lt_trans (hdat n (by simpa [bnCDatDrop] using hn)) h
    | (a, b) :: cs =>
      have hpa := hab (a, b) List.mem_cons_self
      have hstep : ∀ m ∈ bnCDatStep e a b dat, m < bnCOff (e+1) :=
        bnCSigma_dat_step e a b dat hdat hpa.1 hpa.2
      have hab' : ∀ p ∈ cs, p.1 < (bnCDatStep e a b dat).length
          ∧ p.2 < (bnCDatStep e a b dat).length := by
        intro p hp
        rw [bnCDatStep_length]
        exact hab p (List.mem_cons_of_mem _ hp)
      have he : e + (k+1) = (e+1) + k := by omega
      rw [he]
      exact ih cs (e+1) (bnCDatStep e a b dat) hstep hab' n hn

/-! ### Toward the one-cycle slice lemma -/

/-- The fold's initial data list: wire `w` starts on net `1 + w`. -/
def bnCDat0 : List Net := (List.range bnCWires).map bnCDatIn

theorem bnCDat0_length : bnCDat0.length = 8 := by decide +kernel

/-- Element `e`'s data list, and its comparator. -/
def bnCDatAt (e : Nat) : List Net := bnCDatDrop 0 e bnComps bnCDat0
def bnCCompAt (e : Nat) : Nat × Nat := bnComps.getD e (0, 0)

theorem bnCDatAt_length (e : Nat) : (bnCDatAt e).length = 8 := by
  rw [bnCDatAt, bnCDatDrop_length, bnCDat0_length]

/-- Every comparator index is a legal wire. -/
theorem bnComps_lt_eight : ∀ p ∈ bnComps, p.1 < 8 ∧ p.2 < 8 := by decide +kernel

theorem bnCDat0_below : ∀ n ∈ bnCDat0, n < bnCOff 0 := by decide +kernel

/-- ⭐ Element `e`'s data nets sit below its own gate block — the hypothesis
`bnCBuild_element_sem'` needs, at the fold that starts at 0. -/
theorem bnCDatAt_below (e : Nat) : ∀ n ∈ bnCDatAt e, n < bnCOff e := by
  have h := bnCDatDrop_below e bnComps 0 bnCDat0 bnCDat0_below
    (by intro p hp; rw [bnCDat0_length]; exact bnComps_lt_eight p hp)
  simpa [bnCDatAt] using h

/-- **Gates from element `e` onward disturb no net below `bnCOff e`**, so a low
net's value in the full network is already fixed by the prefix. -/
theorem bnC_run_split_low (E : Env) (e : Nat) (pre : List Gate)
    (hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1)
    (n : Net) (hn : n < bnCOff e) :
    run E bnCCore.gates n = run E pre n := by
  rw [hpre, run_append]
  exact run_of_unwritten _ _ _
    (fun g hg => Nat.ne_of_gt (bnCBuild_writes_strictly_above _ _ _ n hn g hg))

/-- The fold preserves the data list's width. -/
theorem bnCBuild_dat_length : ∀ (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
    (bnCBuild e cs dat).2.1.length = dat.length := by
  intro cs
  induction cs with
  | nil => intro e dat; rfl
  | cons c cs ih =>
    intro e dat
    obtain ⟨a, b⟩ := c
    show (bnCBuild (e+1) cs (bnCDatStep e a b dat)).2.1.length = dat.length
    rw [ih, bnCDatStep_length]

/-- `bnComps.drop e` exposes element `e`'s comparator at its head. -/
theorem bnComps_drop_cons (e : Nat) (he : e < 24) :
    bnComps.drop e = (bnCCompAt e) :: bnComps.drop (e + 1) := by
  have hlen : bnComps.length = 24 := bnC_comps_count
  have h : e < bnComps.length := by rw [hlen]; exact he
  rw [List.drop_eq_getElem_cons h]
  congr 1
  rw [bnCCompAt, List.getD_eq_getElem _ _ h]

/-! ### ⭐ For a dense-SSA gate list, ONLY THE INPUT NETS MATTER

*`run_congr_on` asks for agreement on every net any gate READS — including the
nets earlier gates WRITE. That is unusable here: the network-side environment is
`env ∘ σ` and the element-side is `ceC.env v sl`, and above `ceCcore.nIn` they
genuinely differ. Under `ssaFrom` they need not agree there, because every such
net is written before it is read.*

**This is the content `inst_sem` reaches through `run_renumFrom`, stated on its
own so it can be used without an instantiation.** -/
theorem run_agree_of_inputs :
    ∀ (gs : List Gate) (base : Nat) (env₁ env₂ : Env),
      ssaFrom base gs = true →
      (∀ a, a < base → env₁ a = env₂ a) →
      ∀ n, n < base + gs.length → run env₁ gs n = run env₂ gs n := by
  intro gs
  induction gs with
  | nil => intro base env₁ env₂ _ hin n hn; simpa using hin n (by simpa using hn)
  | cons g gs ih =>
    intro base env₁ env₂ hssa hin n hn
    rw [ssaFrom, Bool.and_eq_true, Bool.and_eq_true] at hssa
    obtain ⟨⟨hout, hfan⟩, hrest⟩ := hssa
    have hout' : g.out = base := by simpa using hout
    have hop : g.op.eval env₁ = g.op.eval env₂ :=
      Op.eval_congr g.op (fun a ha => hin a (of_decide_eq_true (List.all_eq_true.mp hfan a ha)))
    rw [run_cons, run_cons, hop]
    refine ih (base+1) _ _ hrest (fun a ha => ?_) n (by simp at hn ⊢; omega)
    by_cases hEq : a = g.out
    · subst hEq; simp [upd]
    · rw [upd_of_ne _ hEq, upd_of_ne _ hEq]
      rw [hout'] at hEq
      exact hin a (by omega)

/-- The same, specialised to a `Circ` that is `ssa`. -/
theorem run_agree_of_inputs_circ (c : Circ) (h : c.ssa = true) (env₁ env₂ : Env)
    (hin : ∀ a, a < c.nIn → env₁ a = env₂ a)
    (n : Net) (hn : n < c.nIn + c.gates.length) :
    run env₁ c.gates n = run env₂ c.gates n := by
  have hgs : ssaFrom c.nIn c.gates = true := by
    rw [Circ.ssa, Bool.and_eq_true] at h; exact h.1
  exact run_agree_of_inputs c.gates c.nIn env₁ env₂ hgs hin n hn

/-! ### Element `e`'s state nets, named -/

theorem getD_drop_nat (l : List Net) (m j : Nat) :
    (l.drop m).getD j 0 = l.getD (m + j) 0 := by
  simp [List.getD_eq_getElem?_getD, List.getElem?_drop]

theorem getD_map_nat (l : List Net) (f : Net → Net) (j : Nat) (hj : j < l.length) :
    (l.map f).getD j 0 = f (l.getD j 0) := by
  rw [List.getD_eq_getElem _ _ (by simpa using hj), List.getD_eq_getElem _ _ hj,
      List.getElem_map]

theorem ceCcore_outs_length : ceCcore.outs.length = 6 := by decide +kernel

/-- ⭐ **ELEMENT `e`'s `j`-th NEXT-STATE NET, out of the fold that starts at 0.**
This is `bnCBuild_state_slice` (which is about the fold whose head is element
`e`) transported by `bnCBuild_state_drop` (which skips the first `e`). -/
theorem bnC_state_net (e j : Nat) (he : e < 24) (hj : j < 4) :
    bnCResult.2.2.getD (4 * e + j) 0
      = instMap ceCcore (bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e))
          (bnCOff e) (ceCcore.outs.getD (j + 2) 0) := by
  have hdrop : bnCResult.2.2.drop (4 * e)
      = (bnCBuild e (bnComps.drop e) (bnCDatAt e)).2.2 := by
    have := bnCBuild_state_drop e bnComps 0 bnCDat0
    simpa [bnCResult, bnCDatAt, bnCDat0] using this
  rw [← getD_drop_nat, hdrop, bnComps_drop_cons e he]
  rw [show (bnCCompAt e) = ((bnCCompAt e).1, (bnCCompAt e).2) from rfl]
  rw [bnCBuild_state_slice _ e (bnCCompAt e).1 (bnCCompAt e).2 _ j hj]
  rw [instOuts, getD_map_nat _ _ _ (by rw [ceCcore_outs_length]; omega)]

/-! ### The two environments meet -/

/-- Element `e`'s three input bits at one cycle, as the NETWORK presents them.

⚠️ **This is `elemTrace`'s per-cycle half, and it is why `elemTrace` cannot be a
hypothesis:** entries 1 and 2 are `run … bnCCore.gates …`, i.e. the values the
*previous layer computed this same cycle*. The element's input trace is a
function of the network's own evaluation, not data given alongside it. -/
def bnCElemInAt (st inp : List Bool) (e : Nat) : List Bool :=
  let E := batcherNetC.env inp st
  [run E bnCCore.gates bnCRst,
   run E bnCCore.gates ((bnCDatAt e).getD (bnCCompAt e).1 0),
   run E bnCCore.gates ((bnCDatAt e).getD (bnCCompAt e).2 0)]

theorem ceC_nIn_eq : ceC.nIn = 3 := rfl

theorem ceC_env_in (v sl : List Bool) (i : Nat) (hi : i < 3) :
    ceC.env v sl i = v.getD i false := by
  show (if i < ceC.nIn then _ else _) = _
  rw [if_pos (by rw [ceC_nIn_eq]; exact hi)]

theorem ceC_env_st (v sl : List Bool) (i : Nat) (hi : ¬ i < 3) :
    ceC.env v sl i = sl.getD (i - 3) false := by
  show (if i < ceC.nIn then _ else _) = _
  rw [if_neg (by rw [ceC_nIn_eq]; exact hi), ceC_nIn_eq]

/-- No gate writes a primary input or a state net, so the prefix leaves them. -/
theorem bnC_run_pre_low (E : Env) (e : Nat) (pre : List Gate)
    (hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1)
    (n : Net) (hn : n < bnCOff 0) : run E pre n = E n := by
  refine run_of_unwritten _ _ _ (fun g hg => Nat.ne_of_gt (Nat.lt_of_lt_of_le hn ?_))
  -- NB: stated with the fold's literal initial list, so the elaborator unifies it
  -- with `bnCCore.gates` lazily. Routing through a `rfl` lemma instead made the
  -- KERNEL evaluate all 816 gates and time out.
  have hmem : g ∈ bnCCore.gates := by rw [hpre]; exact List.mem_append_left _ hg
  exact bnCBuild_writes_above bnComps 0 ((List.range bnCWires).map bnCDatIn) g hmem

/-- ⭐ **THE AGREEMENT: the network's wiring, seen through the prefix, IS `ceC`'s
own input environment.** Inputs 0–2 are the rst line and the two data wires the
previous layer just drove; inputs 3–6 are element `e`'s own state slice. -/
theorem bnC_env_agree (st inp : List Bool) (e : Nat) (he : e < 24)
    (pre : List Gate)
    (hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1) :
    ∀ i, i < ceCcore.nIn →
      run (batcherNetC.env inp st) pre
          (bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e) i)
        = ceC.env (bnCElemInAt st inp e) (bnCSlice st e) i := by
  have hnIn : ceCcore.nIn = 7 := by decide +kernel
  have he24 : (e : Nat) < 24 := he
  have hlow : ∀ n : Net, n < bnCOff e →
      run (batcherNetC.env inp st) pre n
        = run (batcherNetC.env inp st) bnCCore.gates n := fun n hn =>
    (bnC_run_split_low _ e pre hpre n hn).symm
  have hd : ∀ c : Nat, (bnCDatAt e).getD c 0 < bnCOff e := by
    intro c
    rcases Nat.lt_or_ge c (bnCDatAt e).length with hc | hc
    · exact bnCDatAt_below e _ (List.getD_eq_getElem _ _ hc ▸ List.getElem_mem hc)
    · rw [List.getD_eq_default _ _ hc]; exact bnCRst_lt_off e
  have hstate : ∀ k : Nat, k < 4 →
      run (batcherNetC.env inp st) pre (bnCState e + k)
        = (bnCSlice st e).getD k false := by
    intro k hk
    have hk4 : (k : Nat) < 4 := hk
    have hs : (bnCState e : Nat) + k = 9 + 4 * e + k := by rw [bnCState_eq]
    have h1 : e ≤ 23 := Nat.lt_succ_iff.mp he24
    have h2 : k ≤ 3 := Nat.lt_succ_iff.mp hk4
    have h4e : 4 * e ≤ 92 := Nat.mul_le_mul_left 4 h1
    have hnum : (9 : Nat) + 4 * e + k < 105 := by omega
    have hk0 : (bnCState e + k : Nat) < bnCOff 0 :=
      lt_of_lt_of_eq (lt_of_eq_of_lt hs hnum) (bnCOff_eq 0).symm
    rw [bnC_run_pre_low _ e pre hpre _ hk0]
    have hnI : batcherNetC.nIn = 9 := by decide +kernel
    -- omega refuses this even after `rw [hs]` (the relation is Net-typed);
    -- an explicit `Nat.le` chain is the idiom this file already uses.
    have hge : ¬ ((bnCState e + k : Nat) < 9) := by
      rw [hs]
      exact Nat.not_lt.mpr (Nat.le_trans (Nat.le_add_right 9 (4 * e))
        (Nat.le_add_right (9 + 4 * e) k))
    show (if (bnCState e + k : Nat) < batcherNetC.nIn then _ else _) = _
    have harith : (9 : Nat) + 4 * e + k - 9 = 4 * e + k := by
      rw [Nat.add_assoc, Nat.add_sub_cancel_left]
    rw [hnI, if_neg hge, hs, harith]
    interval_cases k <;> simp [bnCSlice]
  intro i hi
  rw [hnIn] at hi
  interval_cases i
  · rw [ceC_env_in _ _ 0 (by omega)]
    show run (batcherNetC.env inp st) pre bnCRst = _
    rw [hlow _ (bnCRst_lt_off e)]; simp [bnCElemInAt]
  · rw [ceC_env_in _ _ 1 (by omega)]
    show run (batcherNetC.env inp st) pre ((bnCDatAt e).getD (bnCCompAt e).1 0) = _
    rw [hlow _ (hd _)]; simp [bnCElemInAt]
  · rw [ceC_env_in _ _ 2 (by omega)]
    show run (batcherNetC.env inp st) pre ((bnCDatAt e).getD (bnCCompAt e).2 0) = _
    rw [hlow _ (hd _)]; simp [bnCElemInAt]
  · rw [ceC_env_st _ _ 3 (by omega)]
    show run (batcherNetC.env inp st) pre (bnCState e) = _
    simpa using hstate 0 (by omega)
  · rw [ceC_env_st _ _ 4 (by omega)]
    show run (batcherNetC.env inp st) pre (bnCState e + 1) = _
    simpa using hstate 1 (by omega)
  · rw [ceC_env_st _ _ 5 (by omega)]
    show run (batcherNetC.env inp st) pre (bnCState e + 2) = _
    simpa using hstate 2 (by omega)
  · rw [ceC_env_st _ _ 6 (by omega)]
    show run (batcherNetC.env inp st) pre (bnCState e + 3) = _
    simpa using hstate 3 (by omega)

/-! ### The per-bit join -/

theorem getD_map_bool (l : List Net) (f : Net → Bool) (j : Nat) (hj : j < l.length) :
    (l.map f).getD j false = f (l.getD j 0) := by
  rw [List.getD_eq_getElem _ _ (by simpa using hj), List.getD_eq_getElem _ _ hj,
      List.getElem_map]

theorem bnCCompAt_mem (e : Nat) (he : e < 24) : bnCCompAt e ∈ bnComps := by
  have hlen : bnComps.length = 24 := bnC_comps_count
  have h : e < bnComps.length := by rw [hlen]; exact he
  rw [bnCCompAt, List.getD_eq_getElem _ _ h]
  exact List.getElem_mem h

theorem bnCCompAt_lt (e : Nat) (he : e < 24) :
    (bnCCompAt e).1 < (bnCDatAt e).length ∧ (bnCCompAt e).2 < (bnCDatAt e).length := by
  have h := bnComps_lt_eight _ (bnCCompAt_mem e he)
  rw [bnCDatAt_length]
  exact h

/-- The four next-state ports are gate outputs, and they live below net 41. -/
theorem ceCcore_state_port_gate (j : Nat) (hj : j < 4) :
    (ceCcore.gates.map Gate.out).contains (ceCcore.outs.getD (j + 2) 0) = true := by
  interval_cases j <;> decide +kernel

theorem ceCcore_state_port_lt (j : Nat) (hj : j < 4) :
    ceCcore.outs.getD (j + 2) 0 < ceCcore.nIn + ceCcore.gates.length := by
  interval_cases j <;> decide +kernel

/-- ⭐ **THE PER-BIT JOIN — element `e`'s `j`-th next-state bit in the NETWORK is
the bit `ceC` computes standalone.** Everything above meets here:
`bnC_state_net` names the net, `bnCBuild_state_sem` factors the element out of
the fold, and `run_agree_of_inputs_circ` + `bnC_env_agree` replace the network's
environment by `ceC`'s own. -/
theorem bnC_state_bit (st inp : List Bool) (e : Nat) (he : e < 24)
    (j : Nat) (hj : j < 4) (pre : List Gate)
    (hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1) :
    run (batcherNetC.env inp st) bnCCore.gates (bnCResult.2.2.getD (4 * e + j) 0)
      = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
          (ceCcore.outs.getD (j + 2) 0) := by
  have hab := bnCCompAt_lt e he
  rw [bnC_state_net e j he hj, hpre, run_append, bnComps_drop_cons e he]
  rw [show (bnCCompAt e) = ((bnCCompAt e).1, (bnCCompAt e).2) from rfl]
  rw [bnCBuild_state_sem e (bnCCompAt e).1 (bnCCompAt e).2 (bnComps.drop (e+1))
        (bnCDatAt e) _ (bnCDatAt_below e) hab.1 hab.2 _ (ceCcore_state_port_gate j hj)]
  exact run_agree_of_inputs_circ ceCcore ceCcore_ssa' _ _
    (bnC_env_agree st inp e he pre hpre) _ (ceCcore_state_port_lt j hj)

/-! ### ⭐⭐ THE ONE-CYCLE SLICE LEMMA -/

theorem bnCCore_outs_eq : bnCCore.outs = bnCResult.2.1 ++ bnCResult.2.2 := rfl

theorem ceCcore_outs_drop2 :
    ceCcore.outs.drop 2 = [ceCcore.outs.getD 2 0, ceCcore.outs.getD 3 0,
                           ceCcore.outs.getD 4 0, ceCcore.outs.getD 5 0] := by
  decide +kernel

/-- The network's next state is the fold's state nets, evaluated. -/
theorem bnC_step_state (st inp : List Bool) :
    (stepSeq batcherNetC st inp).2
      = bnCResult.2.2.map (run (batcherNetC.env inp st) bnCCore.gates) := by
  have hnOut : batcherNetC.nOut = 8 := by decide +kernel
  have hlen : (bnCResult.2.1.map (run (batcherNetC.env inp st) bnCCore.gates)).length = 8 := by
    rw [List.length_map]
    have h := bnCBuild_dat_length bnComps 0 ((List.range bnCWires).map bnCDatIn)
    have h8 : ((List.range bnCWires).map bnCDatIn).length = 8 := by decide +kernel
    rw [h8] at h
    exact h
  show (sem bnCCore _).drop batcherNetC.nOut = _
  rw [sem, hnOut, bnCCore_outs_eq, List.map_append, ← hlen, List.drop_left]

theorem bnCResult_state_length : bnCResult.2.2.length = 96 := (bnCCore_outs_split).2

/-- ⭐⭐ **ONE CYCLE: element `e`'s state slice steps exactly as `ceC` does.**
This is step ③ discharged at the network level — the fact the trace induction
lifts across a frame. -/
theorem bnC_step_slice (st inp : List Bool) (e : Nat) (he : e < 24) :
    bnCSlice (stepSeq batcherNetC st inp).2 e
      = (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).2 := by
  obtain ⟨pre, hpre0⟩ := bnCBuild_gates_drop e bnComps 0 ((List.range bnCWires).map bnCDatIn)
  have hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1 := by
    have h := hpre0
    simp only [Nat.zero_add] at h
    exact h
  have hbit : ∀ j, j < 4 →
      (bnCResult.2.2.map (run (batcherNetC.env inp st) bnCCore.gates)).getD (4 * e + j) false
        = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
            (ceCcore.outs.getD (j + 2) 0) := by
    intro j hj
    rw [getD_map_bool _ _ _ (by rw [bnCResult_state_length]; omega)]
    exact bnC_state_bit st inp e he j hj pre hpre
  have hnOut2 : ceC.nOut = 2 := by decide +kernel
  have hRHS : (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).2
      = [run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
           (ceCcore.outs.getD 2 0),
         run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
           (ceCcore.outs.getD 3 0),
         run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
           (ceCcore.outs.getD 4 0),
         run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
           (ceCcore.outs.getD 5 0)] := by
    show (sem ceCcore _).drop ceC.nOut = _
    rw [sem, hnOut2]
    rfl
  -- literal indices: `4*e + 0 ≡ 4*e` and `0 + 2 ≡ 2` are DEFEQ, so `exact` takes
  -- them. (`norm_num` would also rewrite the left sides into `getElem?` form and
  -- stop them matching the goal.)
  have h0 : (bnCResult.2.2.map (run (batcherNetC.env inp st) bnCCore.gates)).getD (4 * e) false
      = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
          (ceCcore.outs.getD 2 0) := hbit 0 (by omega)
  have h1 : (bnCResult.2.2.map (run (batcherNetC.env inp st) bnCCore.gates)).getD (4 * e + 1) false
      = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
          (ceCcore.outs.getD 3 0) := hbit 1 (by omega)
  have h2 : (bnCResult.2.2.map (run (batcherNetC.env inp st) bnCCore.gates)).getD (4 * e + 2) false
      = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
          (ceCcore.outs.getD 4 0) := hbit 2 (by omega)
  have h3 : (bnCResult.2.2.map (run (batcherNetC.env inp st) bnCCore.gates)).getD (4 * e + 3) false
      = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
          (ceCcore.outs.getD 5 0) := hbit 3 (by omega)
  rw [bnC_step_state, hRHS]
  show [_, _, _, _] = _
  rw [h0, h1, h2, h3]

/-! ## ⭐⭐⭐ THE TRACE INDUCTION -/

theorem bnC_step_state_length (st inp : List Bool) :
    (stepSeq batcherNetC st inp).2.length = 96 := by
  rw [bnC_step_state, List.length_map, bnCResult_state_length]

/-- ⭐ **`elemTrace`, AND IT IS A DEFINITION RATHER THAN A HYPOTHESIS.**
Element `e`'s input at cycle `t` is what the previous layer drove at cycle `t`,
so the trace can only be defined by a recursion that carries the NETWORK's own
state forward. That is the whole difficulty the bank named, and this is it. -/
def bnCElemTrace : List Bool → List (List Bool) → Nat → List (List Bool)
  | _,  [],        _ => []
  | st, inp :: is, e =>
      bnCElemInAt st inp e :: bnCElemTrace (stepSeq batcherNetC st inp).2 is e

/-- ⭐⭐⭐ **THE TRACE INDUCTION — the network's 96-bit state, restricted to
element `e`'s slice, evolves over ANY trace exactly as a standalone `ceC` does on
the inputs the network presented it.**

*The induction carries no new content about the element: `bnC_step_slice` is the
whole cycle, and this lifts it. Any initial state, any trace length — no reset
assumption, which is what a power-gated TinyTapeout tile requires.*

⭐ **AND IT NEEDS NO LENGTH HYPOTHESIS AT ALL — discovered from a LINTER WARNING
(`hst` unused in `bnC_env_agree`), then removed from the whole chain and
rebuilt.** *`bnCSlice` is `getD`-based, so a short state list degrades both sides
identically rather than making the statement false.* ⇒ ***This is the evening's
theme running BACKWARDS for once: every other finding tonight was a statement
claiming MORE than it proved. This one claimed LESS, and the fix was to delete a
hypothesis rather than qualify a claim.*** -/
theorem bnC_trace_factors : ∀ (tr : List (List Bool)) (st : List Bool),
    ∀ (e : Nat), e < 24 →
      bnCSlice (runTrace batcherNetC st tr).2 e
        = (runTrace ceC (bnCSlice st e) (bnCElemTrace st tr e)).2 := by
  intro tr
  induction tr with
  | nil => intro st e _; rfl
  | cons inp is ih =>
    intro st e he
    show bnCSlice (runTrace batcherNetC (stepSeq batcherNetC st inp).2 is).2 e
      = (runTrace ceC (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).2
          (bnCElemTrace (stepSeq batcherNetC st inp).2 is e)).2
    rw [ih _ e he, bnC_step_slice st inp e he]

/-! ## 🏦 THE DISCHARGE — scoped at the bytes before it is attempted

**The trace induction above is done. The discharge is NOT, and reading its
ingredients turns up two scope facts that shape what it can claim.**

⛔ **① `ceKeyOK` IS PINNED AT ONE INITIAL STATE, AND `bnC_trace_factors` IS NOT.**
`CompareExchangeC.lean:435` drives `runTrace ceC [false, false, false, false] …`
— the **all-false** state. But `bnC_trace_factors` is quantified over EVERY
initial state, deliberately, because `Seq.lean` requires it (a deselected tile is
powered off, not reset).
⇒ ***The discharge therefore closes only for frames whose element state is
all-false at frame start.*** That is what the composed switch assumes (`rst` at
`t = 0`) and it is a REAL HYPOTHESIS, not a formality — **whoever writes the
discharge must either carry it or prove the element returns to that state
between frames.** *Do not let the induction's generality make the composed
statement look more general than its element certificate.*

⛔ **② THE CERTIFICATE SKIPS THE BOTH-IDLE PAIRS, BY CONSTRUCTION.**
`ceC_realises_cKey_when_active` is `ceKeyOK true = true`, and the `true` is
`skipBothIdle`: `if skipBothIdle && !a0 && !a1 then true`. The landed
`ceC_does_not_realise_cKey_naively` proves `ceKeyOK false = false` — **28
both-idle failures, a spec defect (`cFrame` erases an idle line's destination),
not a hardware one.**
⇒ **The discharge inherits that exclusion.** ✅ *It happens to fit: silicon's
composed theorem is **full-load**, where no input is idle. **Say so in the
statement rather than relying on it silently.***

📌 **③ SLOT NOTE: `runNet` and `applyComp` live in `SaltWorks/Stack/ZeroOne.lean`
— math's slot, not mine.** The discharge must import rather than restate them,
and the two `batcher*_length` theorems there are the corpus's only unaudited
pair outside the 49 awaiting the maestro's ruling.

### ⛔ ④ AND THE DISCHARGE NEEDS A SECOND INDUCTION THE SIZE OF THE FIRST —
### the trace induction is about the STATE; `hseam` is about the DATA

**Read `hseam` before estimating: `ComposedSwitch.lean:169` asks for
`hw = runNet batcher8 v`, where `hw : Fin 8 → ℕ` is the network's EIGHT DATA
OUTPUTS.** `bnC_trace_factors` is about `bnCSlice`, i.e. the 96 STATE bits.
⇒ ***They are different halves of the machine and only one of them is proved.***

📊 **MEASURED: nothing in the tree relates `bnCResult.2.1` — the fold's data-net
list — to any VALUE. `grep` finds only `bnCBuild_dat_length`, about its LENGTH.**
*The per-cycle machinery does exist (`bnCBuild_element_sem'` covers the data
ports, which are `instOuts` entries 0 and 1), but the cross-element composition
for the data path does not.*

⭐ **THE SHAPE IS RIGHT THERE, THOUGH, AND IT IS THE REASON TO EXPECT THIS TO
WORK: `runNet` IS THE SAME FOLD `bnCBuild` ALREADY IS.**
```
runNet net v = net.foldl (fun w c => applyComp c w) v     ZeroOne.lean:108
bnCBuild e ((a,b) :: cs) dat = … bnCBuild (e+1) cs (bnCDatStep e a b dat)
```
⇒ ***The discharge is a SIMULATION BETWEEN TWO FOLDS over the same comparator
list — `bnCDatStep` ↔ `applyComp`, nets where `runNet` has values.***
`bnCBuild_state_drop`/`bnCBuild_gates_drop` are the state- and gate-side
instances of exactly that induction, so the data side should follow their
pattern.

⚠️ **AND I HAVE NOW UNDERSTATED THE REMAINING WORK TWICE IN THIS FILE, BOTH TIMES
THE SAME WAY.** *The 18:4x bank said "ONE induction" when it was two. This
section said "the discharge is a separate step after it", which described its
STRUCTURE and implied a size.* ⇒ ***Describing what a step IS is not estimating
what it COSTS, and a handoff that does the first while sounding like the second
is how a successor loses a night.*** **The discharge is not glue: it is a second
induction of comparable size, plus the two hypotheses above.**

### The remaining chain
```
ceC_realises_cKey_when_active   one element's frame ⇒ applyComp on cKey  (all-false state, active pairs)
cKeyLE_eq_lex                   cKeyLE = the lex order on (¬active, dest)
bnComps_eq_batcher8             bnComps IS batcher8's comparator list
  ⇒ fold across the 24 elements ⇒ runNet batcher8
  ⇒ hseam's 4 BINDER sites (`grep -c hseam` returns 8: four binders plus four uses in proof terms — the count was mis-read as sites, by me, and the fleet adopted it) in Silicon/Equiv/ComposedSwitch.lean, via composed_switch_of_seam_dest3
```
-/

/-! ## THE DISCHARGE, STEP 1 — the data path's skeleton

*The state side needed `bnCBuild_state_drop` (dropping `4k` state nets is
skipping `k` elements). The data side needs the same shape, and it is simpler:
the fold's FINAL data list does not depend on where you split it, because every
element only rewrites two entries and passes the list on.* -/

/-- The fold's final data list is unchanged by splitting at any element. -/
theorem bnCBuild_dat_drop :
    ∀ (k : Nat) (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
      (bnCBuild e cs dat).2.1
        = (bnCBuild (e + k) (cs.drop k) (bnCDatDrop e k cs dat)).2.1 := by
  intro k
  induction k with
  | zero => intro cs e dat; simp [bnCDatDrop]
  | succ k ih =>
    intro cs e dat
    match cs with
    | [] => simp [bnCBuild, bnCDatDrop]
    | (a, b) :: cs =>
      have he : e + (k+1) = (e+1) + k := by omega
      rw [he, List.drop_succ_cons]
      show (bnCBuild (e+1) cs (bnCDatStep e a b dat)).2.1 = _
      exact ih cs (e+1) (bnCDatStep e a b dat)

/-- ⭐ **THE NETWORK'S EIGHT DATA NETS ARE THE FOLD'S DATA LIST AFTER ALL 24
ELEMENTS.** *This is what `hseam`'s `hw` reads, and it is now named.* -/
theorem bnCResult_dat : bnCResult.2.1 = bnCDatAt 24 := by
  have hlen : bnComps.length = 24 := bnC_comps_count
  have hdrop : bnComps.drop 24 = [] := by
    rw [List.drop_eq_nil_iff]; omega
  have h := bnCBuild_dat_drop 24 bnComps 0 ((List.range bnCWires).map bnCDatIn)
  rw [hdrop] at h
  -- `exact`, not `simpa`: the elaborator unifies bnCResult with the fold lazily,
  -- where simp normalises it into a form that no longer matches.
  exact h

/-! ### Step 2a — the PER-CYCLE data lemma (which does exist, and is cheap)

*`bnCBuild_state_sem`'s name is narrower than its statement: its hypothesis is
`(ceCcore.gates.map Gate.out).contains n`, i.e. ANY gate output — so it serves
the DATA ports (`instOuts` entries 0 and 1) exactly as it serves the state ports
(entries 2…5). The per-cycle half of the data path is therefore the same chain as
`bnC_state_bit`, with no new machinery.* -/

theorem ceCcore_data_port_gate (j : Nat) (hj : j < 2) :
    (ceCcore.gates.map Gate.out).contains (ceCcore.outs.getD j 0) = true := by
  interval_cases j <;> decide +kernel

theorem ceCcore_data_port_lt (j : Nat) (hj : j < 2) :
    ceCcore.outs.getD j 0 < ceCcore.nIn + ceCcore.gates.length := by
  interval_cases j <;> decide +kernel

/-- ⭐ **PER-CYCLE, DATA SIDE: the net element `e` drives onto its output wire
carries exactly what `ceC` computes standalone.** *These are the nets
`bnCDatStep` writes — `dat.set a (os.getD 0 0)` and `.set b (os.getD 1 0)` — so
this is the value that flows to the next element in the same cycle.* -/
theorem bnC_data_bit (st inp : List Bool) (e : Nat) (he : e < 24)
    (j : Nat) (hj : j < 2) (pre : List Gate)
    (hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1) :
    run (batcherNetC.env inp st) bnCCore.gates
        ((instOuts ceCcore (bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e))
            (bnCOff e)).getD j 0)
      = run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
          (ceCcore.outs.getD j 0) := by
  have hab := bnCCompAt_lt e he
  rw [instOuts, getD_map_nat _ _ _ (by rw [ceCcore_outs_length]; omega)]
  rw [hpre, run_append, bnComps_drop_cons e he]
  rw [show (bnCCompAt e) = ((bnCCompAt e).1, (bnCCompAt e).2) from rfl]
  rw [bnCBuild_state_sem e (bnCCompAt e).1 (bnCCompAt e).2 (bnComps.drop (e+1))
        (bnCDatAt e) _ (bnCDatAt_below e) hab.1 hab.2 _ (ceCcore_data_port_gate j hj)]
  exact run_agree_of_inputs_circ ceCcore ceCcore_ssa' _ _
    (bnC_env_agree st inp e he pre hpre) _ (ceCcore_data_port_lt j hj)

/-! ### Step 2b — element `e`'s OUTPUT FRAME is the standalone element's -/

/-- The two bits element `e` drives onto its wires this cycle. -/
def bnCElemOutAt (st inp : List Bool) (e : Nat) : List Bool :=
  let E := batcherNetC.env inp st
  let σ := bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e)
  [run E bnCCore.gates ((instOuts ceCcore σ (bnCOff e)).getD 0 0),
   run E bnCCore.gates ((instOuts ceCcore σ (bnCOff e)).getD 1 0)]

theorem ceC_nOut_eq : ceC.nOut = 2 := rfl

/-- One cycle, data side, as lists. -/
theorem bnC_step_out (st inp : List Bool) (e : Nat) (he : e < 24) :
    bnCElemOutAt st inp e = (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).1 := by
  obtain ⟨pre, hpre0⟩ := bnCBuild_gates_drop e bnComps 0 ((List.range bnCWires).map bnCDatIn)
  have hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1 := by
    have h := hpre0
    simp only [Nat.zero_add] at h
    exact h
  have h0 := bnC_data_bit st inp e he 0 (by omega) pre hpre
  have h1 := bnC_data_bit st inp e he 1 (by omega) pre hpre
  have hRHS : (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).1
      = [run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
           (ceCcore.outs.getD 0 0),
         run (ceC.env (bnCElemInAt st inp e) (bnCSlice st e)) ceCcore.gates
           (ceCcore.outs.getD 1 0)] := by
    show (sem ceCcore _).take ceC.nOut = _
    rw [sem, ceC_nOut_eq]
    rfl
  rw [hRHS]
  show [_, _] = _
  rw [h0, h1]

/-- Element `e`'s output trace, read out of the network. -/
def bnCElemOuts : List Bool → List (List Bool) → Nat → List (List Bool)
  | _,  [],        _ => []
  | st, inp :: is, e =>
      bnCElemOutAt st inp e :: bnCElemOuts (stepSeq batcherNetC st inp).2 is e

/-- ⭐⭐ **ELEMENT `e`'s WHOLE OUTPUT FRAME, in the network, IS the standalone
`ceC`'s output frame on the inputs the network presented it.** *The data-side
twin of `bnC_trace_factors`, and it consumes it: the state agreement each cycle
is what lets the next cycle's data lemma fire.* -/
theorem bnC_out_factors : ∀ (tr : List (List Bool)) (st : List Bool),
    ∀ (e : Nat), e < 24 →
      bnCElemOuts st tr e = (runTrace ceC (bnCSlice st e) (bnCElemTrace st tr e)).1 := by
  intro tr
  induction tr with
  | nil => intro st e _; rfl
  | cons inp is ih =>
    intro st e he
    show bnCElemOutAt st inp e :: bnCElemOuts (stepSeq batcherNetC st inp).2 is e
      = (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).1
        :: (runTrace ceC (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).2
              (bnCElemTrace (stepSeq batcherNetC st inp).2 is e)).1
    rw [bnC_step_out st inp e he, ← bnC_step_slice st inp e he,
        ih _ e he]

/-! ### Step 2c — the fold, from the BACK

*`bnCDatDrop` recurses from the FRONT (apply element `e`, then the rest). The
value-level correspondence needs the other end: element `k`'s step applied to the
list the first `k` elements produced — which is the shape `runNet`'s `foldl` has.* -/

theorem bnCDatDrop_succ :
    ∀ (k : Nat) (cs : List (Nat × Nat)) (e : Nat) (dat : List Net), k < cs.length →
      bnCDatDrop e (k+1) cs dat
        = bnCDatStep (e + k) (cs.getD k (0,0)).1 (cs.getD k (0,0)).2
            (bnCDatDrop e k cs dat) := by
  intro k
  induction k with
  | zero =>
    intro cs e dat hk
    match cs with
    | [] => simp at hk
    | (a, b) :: cs => rfl
  | succ k ih =>
    intro cs e dat hk
    match cs with
    | [] => simp at hk
    | (a, b) :: cs =>
      have hk' : k < cs.length := by simpa using hk
      have he : e + (k+1) = (e+1) + k := by omega
      show bnCDatDrop (e+1) (k+1) cs (bnCDatStep e a b dat) = _
      rw [ih cs (e+1) (bnCDatStep e a b dat) hk', he]
      rfl

/-- ⭐ **THE FOLD'S STEP: element `k` applied to what the first `k` produced.**
*This is `runNet`'s `foldl` shape, one level down — nets where it has values.* -/
theorem bnCDatAt_succ (k : Nat) (hk : k < 24) :
    bnCDatAt (k+1)
      = bnCDatStep k (bnCCompAt k).1 (bnCCompAt k).2 (bnCDatAt k) := by
  have hlen : k < bnComps.length := by rw [bnC_comps_count]; exact hk
  have h := bnCDatDrop_succ k bnComps 0 ((List.range bnCWires).map bnCDatIn) hlen
  simpa [bnCDatAt, bnCDat0, bnCCompAt] using h

/-- ⭐ **Reading a wire after element `k` has written — and this IS `applyComp`'s
shape:** `if i = c.1 … else if i = c.2 … else v i`. -/
theorem bnCDatStep_getD (e a b : Nat) (dat : List Net) (i : Nat)
    (hab : a ≠ b) (ha : a < dat.length) (hb : b < dat.length) :
    (bnCDatStep e a b dat).getD i 0
      = if i = a then (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 0 0
        else if i = b then (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 1 0
        else dat.getD i 0 := by
  -- FOURTH attempt, and the technique came from math's 20:32 finding: `rw` fires
  -- where `simp` no-ops or diverges. `List.getElem?_set_of_lt'` is the right
  -- lemma — it needs only the SET index in range and yields the whole conditional.
  simp only [bnCDatStep]
  generalize (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 0 0 = v0
  generalize (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 1 0 = v1
  rw [List.getD_eq_getElem?_getD, List.getD_eq_getElem?_getD,
      List.getElem?_set_of_lt' v1 _ (by simpa using hb),
      List.getElem?_set_of_lt' v0 _ ha]
  by_cases hia : i = a
  · have hbi : b ≠ i := fun h => hab (hia.symm.trans h.symm)
    rw [if_neg hbi, if_pos hia.symm, if_pos hia, Option.getD_some]
  · by_cases hib : i = b
    · rw [if_pos hib.symm, if_neg hia, if_pos hib, Option.getD_some]
    · have hai : a ≠ i := fun h => hia h.symm
      have hbi : b ≠ i := fun h => hib h.symm
      rw [if_neg hbi, if_neg hai, if_neg hia, if_neg hib]

/-! #### ✅ `bnCDatStep_getD` — SOLVED ON THE FOURTH ATTEMPT, BY A TECHNIQUE THAT
#### CAME OFF THE BUS. The three failures are kept: they are the expensive part.

⭐ **WHAT SOLVED IT WAS MATH'S 20:32 TACTIC FINDING, NOT MORE FORCE:** *"`simp`
will not fire … it reports the lemma unused and NO-OPS SILENTLY. `rw` fires on
the IDENTICAL goal."* **Nine minutes later that was the answer here.** ⇒ ***The
three failures below were all `simp`-shaped; the fix was to stop using `simp`.***
Plus the right lemma: **`List.getElem?_set_of_lt'`**, which needs only the SET
index in range and yields the whole conditional in one step.

**THE THREE FAILURES, KEPT — because each cost a build and none is obvious:**
1. ⛔ `List.getD_set_ne` / `List.getD_set_self_of_lt` **do not exist** in this
   toolchain. Batteries has `getElem?_set_eq_of_lt` / `getElem?_set_of_lt(')`, so
   the route is through `getElem?`, never `getD`.
2. ⛔ `subst hia` on `hia : i = a` **eliminates `a`, not `i`** — every later
   mention then fails *"Unknown identifier `a`"*. (Math hit the same shape at
   19:18 through a δ-alias.) **Use `by_cases` + explicit `Ne.symm` forms**, and
   note the `set` lemmas orient their conditions `a = i`, not `i = a`.
3. ⛔ `simp` **blew `maxRecDepth` (8000)** on two of the three cases *even after
   `generalize`-ing both `instOuts` terms away*, while the third succeeded with
   the same lemma set. **That asymmetry was the tell that the tactic, not the
   term, was the problem** — and I read it as "the term is too big" for three
   attempts.

⚠️ **AND THE AUDIT IS WHAT KEPT THE FAILURES HONEST: an unsolved goal became
`sorryAx`, and `#audit_axioms` FAILED THE BUILD on it.** ***A red build is why
none of the three broken attempts was ever committed. The whitelist is not
paperwork — it is what stands between a tactic failure and a committed hole.*** -/

/-! ### ⚠️ STEP 2 IS NOT THE SAME SHAPE AS STEP 1 — the data path is PER-FRAME

**Having built the skeleton, the next step is where the state and data halves
stop being analogous, and it is worth saying before anyone assumes symmetry.**

*The STATE induction worked per-CYCLE and lifted: `bnC_step_slice` is one cycle,
`bnC_trace_factors` lifts it across a trace, and each cycle's statement is
meaningful on its own.*

⛔ **THE DATA PATH HAS NO MEANINGFUL PER-CYCLE STATEMENT.** An element's job is
to emit the SMALLER key on one wire and the LARGER on the other — and "smaller"
is not a property of one cycle's bit. `ceC_realises_cKey_when_active` says so in
its own shape: it compares `(cePairOut …).drop 6` against whole frames, over the
six header cycles plus payload. ⇒ ***The element's correctness is a statement
about a FRAME, and the composition must thread FRAMES through the fold, not
bits.***

🔑 **SO STEP 2 IS: define the frame carried on a net (that net's value across the
frame's cycles), then prove `bnCDatStep ↔ applyComp` AT THE FRAME LEVEL**, with
`ceC_realises_cKey_when_active` supplying the per-element sort and
`bnC_trace_factors` supplying the state agreement each element needs to BE that
standalone `ceC`.

📊 **UPDATED AFTER 2a–2c LANDED — read this section's position, not just its
words: it was written BEFORE the three subsections above it, and a reader now
meets three finished steps followed by text that sounds like nothing has begun.**
```
2a  bnC_data_bit        ✅ per-cycle, data side
2b  bnC_out_factors     ✅ element e's whole OUTPUT FRAME = standalone ceC's
2c  bnCDatAt_succ       ✅ the fold's step from the BACK
    bnCDatStep_getD     ✅ the applyComp-SHAPED read, at the NET level
────────────────────────────────────────────────────────────────────────
2d  THE FRAME-LEVEL SORT   ⛔ THE REMAINING WORK
```
⇒ ***What is left is NOT the plumbing — that is done, both halves of it. What is
left is the SORTING ARGUMENT: that an element's two output FRAMES are the `cKey`
min and max of its two input frames, and that folding that across `bnComps`
is `runNet`.*** **`bnCDatStep_getD` gives `applyComp`'s SHAPE; what it does not
give is that the two written values are the min and the max.**

⚠️ **And that step must carry the two hypotheses recorded in ① and ② above —
they are hypotheses of the FRAME-level element certificate, and the frame is the
level this argument works at.**

📌 *This is also why the two hypotheses in ① and ② above are unavoidable rather
than tidiable: they are hypotheses of the FRAME-level element certificate, and
the frame is the level the discharge has to work at.* -/

/-! ### Step 2d's first piece — the network's EIGHT OUTPUTS, named

*The twin of `bnC_step_state`: that one said the next STATE is the fold's state
nets evaluated; this says the OUTPUTS are the fold's data list evaluated. With
`bnCResult_dat` (`= bnCDatAt 24`) it says the eight wires carry exactly what the
24th element left behind.* -/

theorem bnC_step_out_wires (st inp : List Bool) :
    (stepSeq batcherNetC st inp).1
      = (bnCDatAt 24).map (run (batcherNetC.env inp st) bnCCore.gates) := by
  have hnOut : batcherNetC.nOut = 8 := by decide +kernel
  have hlen : (bnCResult.2.1.map (run (batcherNetC.env inp st) bnCCore.gates)).length = 8 := by
    rw [List.length_map]
    have h := bnCBuild_dat_length bnComps 0 ((List.range bnCWires).map bnCDatIn)
    have h8 : ((List.range bnCWires).map bnCDatIn).length = 8 := by decide +kernel
    rw [h8] at h
    exact h
  show (sem bnCCore _).take batcherNetC.nOut = _
  rw [sem, hnOut, bnCCore_outs_eq, List.map_append, ← hlen, List.take_left,
      bnCResult_dat]

/-- ⭐ **WIRE `w`'s VALUE THIS CYCLE, and it is what `hseam`'s `hw` reads.** -/
theorem bnC_wire_val (st inp : List Bool) (w : Nat) (hw : w < 8) :
    (stepSeq batcherNetC st inp).1.getD w false
      = run (batcherNetC.env inp st) bnCCore.gates ((bnCDatAt 24).getD w 0) := by
  rw [bnC_step_out_wires, getD_map_bool _ _ _ (by rw [bnCDatAt_length]; exact hw)]

/-! ### Axiom audit -/

#audit_axioms bnCDatStep bnCDatDrop bnCBuild_state_drop4 bnCBuild_state_drop
#audit_axioms bnCBuild_gates_drop bnCDatStep_length bnCDatDrop_length bnCDatDrop_below
#audit_axioms bnCDat0 bnCDat0_length bnCDatAt bnCCompAt bnCDatAt_length
#audit_axioms bnComps_lt_eight bnCDat0_below bnCDatAt_below bnC_run_split_low
#audit_axioms bnCBuild_dat_length bnComps_drop_cons
#audit_axioms run_agree_of_inputs run_agree_of_inputs_circ
#audit_axioms getD_drop_nat getD_map_nat ceCcore_outs_length bnC_state_net
#audit_axioms bnCElemInAt ceC_nIn_eq ceC_env_in ceC_env_st bnC_run_pre_low bnC_env_agree
#audit_axioms getD_map_bool bnCCompAt_mem bnCCompAt_lt
#audit_axioms ceCcore_state_port_gate ceCcore_state_port_lt bnC_state_bit
#audit_axioms bnCCore_outs_eq ceCcore_outs_drop2 bnC_step_state bnCResult_state_length
#audit_axioms bnC_step_slice bnC_step_state_length bnCElemTrace bnC_trace_factors
#audit_axioms bnCBuild_dat_drop bnCResult_dat
#audit_axioms ceCcore_data_port_gate ceCcore_data_port_lt bnC_data_bit
#audit_axioms bnCElemOutAt ceC_nOut_eq bnC_step_out bnCElemOuts bnC_out_factors
#audit_axioms bnCDatDrop_succ bnCDatAt_succ bnCDatStep_getD
#audit_axioms bnC_step_out_wires bnC_wire_val


/-! ## ⭐ THE FRAME LADDER — built by a dispatched executor (maestro item 10),
verified here in the strong form before landing.

*The seam's remaining structural half: the network's eight output STREAMS as a
fold over `bnComps`, and the transposition of that fold to `ℕ` keys.* -/

/-! ### 0. The comparator's two endpoints are distinct -/

theorem bnComps_ne : ∀ p ∈ bnComps, p.1 ≠ p.2 := by decide +kernel

theorem bnCCompAt_ne (e : Nat) (he : e < 24) : (bnCCompAt e).1 ≠ (bnCCompAt e).2 :=
  bnComps_ne _ (bnCCompAt_mem e he)

/-! ### 1. Nets below the whole gate block keep their environment value -/

theorem bnC_run_low (E : Env) (n : Net) (hn : n < bnCOff 0) :
    run E bnCCore.gates n = E n := by
  refine run_of_unwritten _ _ _ (fun g hg => Nat.ne_of_gt (Nat.lt_of_lt_of_le hn ?_))
  exact bnCBuild_writes_above bnComps 0 ((List.range bnCWires).map bnCDatIn) g hg

theorem bnC_rst_val (st inp : List Bool) :
    run (batcherNetC.env inp st) bnCCore.gates bnCRst = inp.getD 0 false := by
  rw [bnC_run_low _ _ (bnCRst_lt_off 0)]
  rfl

/-! ### 2. The value on wire `w` after stage `k`, at ONE cycle -/

def bnCWireAt (st inp : List Bool) (k w : Nat) : Bool :=
  run (batcherNetC.env inp st) bnCCore.gates ((bnCDatAt k).getD w 0)

theorem bnCDatAt_zero_getD (w : Nat) (hw : w < 8) : (bnCDatAt 0).getD w 0 = 1 + w := by
  interval_cases w <;> rfl

theorem bnCWireAt_zero (st inp : List Bool) (w : Nat) (hw : w < 8) :
    bnCWireAt st inp 0 w = inp.getD (1 + w) false := by
  have h105 : bnCOff 0 = 105 := by rw [bnCOff_eq]
  have hlt : (1 + w : Nat) < bnCOff 0 := by rw [h105]; omega
  rw [bnCWireAt, bnCDatAt_zero_getD w hw, bnC_run_low _ _ hlt]
  have hnI : batcherNetC.nIn = 9 := by decide +kernel
  have hcond : (1 + w : Nat) < batcherNetC.nIn := by rw [hnI]; omega
  show (if (1 + w : Nat) < batcherNetC.nIn then inp.getD (1 + w) false
        else st.getD ((1 + w) - batcherNetC.nIn) false) = _
  rw [if_pos hcond]

theorem bnCElemOutAt_getD0 (st inp : List Bool) (e : Nat) :
    (bnCElemOutAt st inp e).getD 0 false
      = run (batcherNetC.env inp st) bnCCore.gates
          ((instOuts ceCcore (bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e))
              (bnCOff e)).getD 0 0) := rfl

theorem bnCElemOutAt_getD1 (st inp : List Bool) (e : Nat) :
    (bnCElemOutAt st inp e).getD 1 false
      = run (batcherNetC.env inp st) bnCCore.gates
          ((instOuts ceCcore (bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e))
              (bnCOff e)).getD 1 0) := rfl

/-- **`applyComp`'s shape, at the VALUE level, one cycle.** -/
theorem bnCWireAt_succ (st inp : List Bool) (k w : Nat) (hk : k < 24) :
    bnCWireAt st inp (k + 1) w
      = if w = (bnCCompAt k).1 then (bnCElemOutAt st inp k).getD 0 false
        else if w = (bnCCompAt k).2 then (bnCElemOutAt st inp k).getD 1 false
        else bnCWireAt st inp k w := by
  have hab := bnCCompAt_ne k hk
  obtain ⟨ha, hb⟩ := bnCCompAt_lt k hk
  rw [bnCWireAt, bnCDatAt_succ k hk,
      bnCDatStep_getD k (bnCCompAt k).1 (bnCCompAt k).2 (bnCDatAt k) w hab ha hb,
      bnCElemOutAt_getD0, bnCElemOutAt_getD1, bnCWireAt]
  by_cases h1 : w = (bnCCompAt k).1
  · simp only [if_pos h1]
  · simp only [if_neg h1]
    by_cases h2 : w = (bnCCompAt k).2
    · simp only [if_pos h2]
    · simp only [if_neg h2]

/-! ### 3. THE FRAME: wire `w`'s values across a whole trace -/

def bnCFrameAt : List Bool → List (List Bool) → Nat → Nat → List Bool
  | _,  [],        _, _ => []
  | st, inp :: is, k, w =>
      bnCWireAt st inp k w :: bnCFrameAt (stepSeq batcherNetC st inp).2 is k w

theorem bnCFrameAt_nil (st : List Bool) (k w : Nat) : bnCFrameAt st [] k w = [] := rfl

theorem bnCFrameAt_cons (st inp : List Bool) (is : List (List Bool)) (k w : Nat) :
    bnCFrameAt st (inp :: is) k w
      = bnCWireAt st inp k w :: bnCFrameAt (stepSeq batcherNetC st inp).2 is k w := rfl

/-- Element `e`'s output frame on its port `j`. -/
def bnCElemOutFrame (st : List Bool) (tr : List (List Bool)) (e j : Nat) : List Bool :=
  (bnCElemOuts st tr e).map (fun o => o.getD j false)

theorem bnCElemOutFrame_nil (st : List Bool) (e j : Nat) :
    bnCElemOutFrame st [] e j = [] := rfl

theorem bnCElemOutFrame_cons (st inp : List Bool) (is : List (List Bool)) (e j : Nat) :
    bnCElemOutFrame st (inp :: is) e j
      = (bnCElemOutAt st inp e).getD j false
        :: bnCElemOutFrame (stepSeq batcherNetC st inp).2 is e j := rfl

/-- ⭐ **`applyComp`'s shape at the FRAME level.** -/
theorem bnCFrameAt_succ (st : List Bool) (tr : List (List Bool)) (k w : Nat) (hk : k < 24) :
    bnCFrameAt st tr (k + 1) w
      = if w = (bnCCompAt k).1 then bnCElemOutFrame st tr k 0
        else if w = (bnCCompAt k).2 then bnCElemOutFrame st tr k 1
        else bnCFrameAt st tr k w := by
  induction tr generalizing st with
  | nil => simp only [bnCFrameAt_nil, bnCElemOutFrame_nil, ite_self]
  | cons inp is ih =>
    rw [bnCFrameAt_cons, bnCWireAt_succ st inp k w hk, ih]
    by_cases h1 : w = (bnCCompAt k).1
    · simp only [if_pos h1, bnCElemOutFrame_cons]
    · simp only [if_neg h1]
      by_cases h2 : w = (bnCCompAt k).2
      · simp only [if_pos h2, bnCElemOutFrame_cons]
      · simp only [if_neg h2, bnCFrameAt_cons]

/-! ### 4. The two ends of the ladder -/

theorem bnCFrameAt_zero (st : List Bool) (tr : List (List Bool)) (w : Nat) (hw : w < 8) :
    bnCFrameAt st tr 0 w = tr.map (fun i => i.getD (1 + w) false) := by
  induction tr generalizing st with
  | nil => rfl
  | cons inp is ih =>
    rw [bnCFrameAt_cons, bnCWireAt_zero st inp w hw, ih, List.map_cons]

theorem bnCFrameAt_24 (st : List Bool) (tr : List (List Bool)) (w : Nat) (hw : w < 8) :
    bnCFrameAt st tr 24 w = (runTrace batcherNetC st tr).1.map (fun o => o.getD w false) := by
  induction tr generalizing st with
  | nil => rfl
  | cons inp is ih =>
    have h : bnCWireAt st inp 24 w = (stepSeq batcherNetC st inp).1.getD w false :=
      (bnC_wire_val st inp w hw).symm
    rw [bnCFrameAt_cons, ih, h]
    rfl

/-! ### 5. The element's INPUT trace, re-assembled from the frames -/

def zip3Trace : List Bool → List Bool → List Bool → List (List Bool)
  | r :: rs, x :: xs, y :: ys => [r, x, y] :: zip3Trace rs xs ys
  | _,      _,       _       => []

/-- ⚠️ The equation compiler's `cons/cons/cons` equation for `zip3Trace` is **not
`rfl`** (three overlapping patterns), so `rw`'s trailing `rfl` does not close it.
It must be named and rewritten with explicitly. -/
theorem zip3Trace_cons (r x y : Bool) (rs xs ys : List Bool) :
    zip3Trace (r :: rs) (x :: xs) (y :: ys) = [r, x, y] :: zip3Trace rs xs ys := by
  simp only [zip3Trace]

theorem bnCElemInAt_eq (st inp : List Bool) (e : Nat) :
    bnCElemInAt st inp e
      = [inp.getD 0 false, bnCWireAt st inp e (bnCCompAt e).1,
         bnCWireAt st inp e (bnCCompAt e).2] := by
  have h : bnCElemInAt st inp e
      = [run (batcherNetC.env inp st) bnCCore.gates bnCRst,
         bnCWireAt st inp e (bnCCompAt e).1,
         bnCWireAt st inp e (bnCCompAt e).2] := rfl
  rw [h, bnC_rst_val]

theorem bnCElemTrace_eq_zip3 (st : List Bool) (tr : List (List Bool)) (e : Nat) :
    bnCElemTrace st tr e
      = zip3Trace (tr.map (fun i => i.getD 0 false))
          (bnCFrameAt st tr e (bnCCompAt e).1) (bnCFrameAt st tr e (bnCCompAt e).2) := by
  induction tr generalizing st with
  | nil => rfl
  | cons inp is ih =>
    show bnCElemInAt st inp e :: bnCElemTrace (stepSeq batcherNetC st inp).2 is e = _
    rw [ih, List.map_cons, bnCFrameAt_cons, bnCFrameAt_cons, bnCElemInAt_eq,
        zip3Trace_cons]

/-! ### 6. THE SINGLE-ELEMENT STEP — a standalone `ceC` on the two input frames -/

/-- `ceC`'s port-`j` output stream, driven by an `rst` column and two frames. -/
def ceCPort (s r x y : List Bool) (j : Nat) : List Bool :=
  (runTrace ceC s (zip3Trace r x y)).1.map (fun o => o.getD j false)

theorem bnCElemOutFrame_eq_ceCPort (st : List Bool) (tr : List (List Bool)) (e : Nat)
    (he : e < 24) (j : Nat) :
    bnCElemOutFrame st tr e j
      = ceCPort (bnCSlice st e) (tr.map (fun i => i.getD 0 false))
          (bnCFrameAt st tr e (bnCCompAt e).1) (bnCFrameAt st tr e (bnCCompAt e).2) j := by
  rw [bnCElemOutFrame, bnC_out_factors tr st e he, ceCPort, bnCElemTrace_eq_zip3]

/-- ⭐⭐ **ROUTE A's SINGLE-ELEMENT STEP.** -/
theorem bnCFrameAt_succ_ceC (st : List Bool) (tr : List (List Bool)) (k w : Nat)
    (hk : k < 24) :
    bnCFrameAt st tr (k + 1) w
      = if w = (bnCCompAt k).1 then
          ceCPort (bnCSlice st k) (tr.map (fun i => i.getD 0 false))
            (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2) 0
        else if w = (bnCCompAt k).2 then
          ceCPort (bnCSlice st k) (tr.map (fun i => i.getD 0 false))
            (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2) 1
        else bnCFrameAt st tr k w := by
  rw [bnCFrameAt_succ st tr k w hk, bnCElemOutFrame_eq_ceCPort st tr k hk 0,
      bnCElemOutFrame_eq_ceCPort st tr k hk 1]

/-! ### 7. THE SORT, with the element certificate carried as a hypothesis

`ElemSortsAt st tr k le` is **exactly** the obligation a frame-level element
certificate must discharge, written in the vocabulary the network side produces:
a standalone `ceC`, from element `k`'s own state slice, driven by the `rst`
column and the two frames the previous stages left on `k`'s two wires, emits the
`le`-smaller frame on port 0 and the `le`-larger on port 1. -/
def ElemSortsAt (st : List Bool) (tr : List (List Bool)) (k : Nat)
    (le : List Bool → List Bool → Bool) : Prop :=
  ceCPort (bnCSlice st k) (tr.map (fun i => i.getD 0 false))
        (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2) 0
      = (if le (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2)
         then bnCFrameAt st tr k (bnCCompAt k).1 else bnCFrameAt st tr k (bnCCompAt k).2)
    ∧ ceCPort (bnCSlice st k) (tr.map (fun i => i.getD 0 false))
        (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2) 1
      = (if le (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2)
         then bnCFrameAt st tr k (bnCCompAt k).2 else bnCFrameAt st tr k (bnCCompAt k).1)

/-- `applyComp`'s literal shape, on frames, with `min`/`max` taken by `le`.
Compare `SaltWorks.Stack.applyComp c v i = if i = c.1 then min (v c.1) (v c.2)
else if i = c.2 then max (v c.1) (v c.2) else v i`. -/
def applyCompF (le : List Bool → List Bool → Bool) (c : Nat × Nat)
    (v : Nat → List Bool) : Nat → List Bool := fun i =>
  if i = c.1 then (if le (v c.1) (v c.2) then v c.1 else v c.2)
  else if i = c.2 then (if le (v c.1) (v c.2) then v c.2 else v c.1)
  else v i

/-- `runNet`'s literal shape, on frames. Compare
`SaltWorks.Stack.runNet net v = net.foldl (fun w c => applyComp c w) v`. -/
def runNetF (le : List Bool → List Bool → Bool) (net : List (Nat × Nat))
    (v : Nat → List Bool) : Nat → List Bool :=
  net.foldl (fun w c => applyCompF le c w) v

/-- ⭐⭐⭐ **THE SINGLE-ELEMENT STEP, SORTED.** One comparator: the frame vector
after stage `k+1` is the frame vector after stage `k` with `applyComp` applied at
comparator `k`. -/
theorem bnCFrameAt_succ_sorted (st : List Bool) (tr : List (List Bool)) (k : Nat)
    (le : List Bool → List Bool → Bool) (hk : k < 24) (h : ElemSortsAt st tr k le)
    (w : Nat) :
    bnCFrameAt st tr (k + 1) w
      = applyCompF le (bnCCompAt k) (fun i => bnCFrameAt st tr k i) w := by
  obtain ⟨h0, h1⟩ := h
  rw [bnCFrameAt_succ_ceC st tr k w hk, applyCompF]
  by_cases hw1 : w = (bnCCompAt k).1
  · simp only [if_pos hw1, h0]
  · simp only [if_neg hw1]
    by_cases hw2 : w = (bnCCompAt k).2
    · simp only [if_pos hw2, h1]
    · simp only [if_neg hw2]

/-! ### 8. THE FOLD -/

theorem bnComps_getElem?_eq (k : Nat) (hk : k < 24) :
    bnComps[k]? = some (bnCCompAt k) := by
  have hlen : k < bnComps.length := by rw [bnC_comps_count]; exact hk
  rw [List.getElem?_eq_getElem hlen, bnCCompAt, List.getD_eq_getElem _ _ hlen]

theorem bnComps_take_succ (k : Nat) (hk : k < 24) :
    bnComps.take (k + 1) = bnComps.take k ++ [bnCCompAt k] := by
  rw [List.take_add_one, bnComps_getElem?_eq k hk]
  rfl

theorem runNetF_append (le : List Bool → List Bool → Bool) (n m : List (Nat × Nat))
    (v : Nat → List Bool) :
    runNetF le (n ++ m) v = runNetF le m (runNetF le n v) := by
  simp only [runNetF, List.foldl_append]

/-- ⭐ **THE FOLD.** Under the per-element certificate, the frame vector after
`k` stages IS `runNet`'s `foldl` over the first `k` comparators. -/
theorem bnCFrames_fold (st : List Bool) (tr : List (List Bool))
    (le : List Bool → List Bool → Bool)
    (h : ∀ k, k < 24 → ElemSortsAt st tr k le) :
    ∀ k, k ≤ 24 →
      (fun w => bnCFrameAt st tr k w)
        = runNetF le (bnComps.take k) (fun w => bnCFrameAt st tr 0 w) := by
  intro k
  induction k with
  | zero => intro _; rfl
  | succ k ih =>
    intro hk
    have hk24 : k < 24 := by omega
    have hfold := ih (by omega)
    rw [bnComps_take_succ k hk24, runNetF_append, ← hfold]
    funext w
    exact bnCFrameAt_succ_sorted st tr k le hk24 (h k hk24) w

theorem bnComps_take_24 : bnComps.take 24 = bnComps := by decide +kernel

/-- ⭐⭐⭐ **ROUTE A's TARGET, hypothesis-carrying: the network's EIGHT OUTPUT
FRAMES are `runNet`-over-`bnComps` applied to its eight INPUT FRAMES.**

`bnComps = batcher8.map (fun c => (c.1.val, c.2.val))` (`bnComps_eq_batcher8`),
and `bnCFrameAt st tr 0 i = tr.map (fun j => j.getD (1 + i) false)` for `i < 8`
(`bnCFrameAt_zero`), so both ends are the objects `hseam` names. -/
theorem bnC_output_frames_are_the_fold (st : List Bool) (tr : List (List Bool))
    (le : List Bool → List Bool → Bool)
    (h : ∀ k, k < 24 → ElemSortsAt st tr k le) (w : Nat) (hw : w < 8) :
    (runTrace batcherNetC st tr).1.map (fun o => o.getD w false)
      = runNetF le bnComps (fun i => bnCFrameAt st tr 0 i) w := by
  have hfold := bnCFrames_fold st tr le h 24 (Nat.le_refl 24)
  rw [bnComps_take_24] at hfold
  rw [← bnCFrameAt_24 st tr w hw]
  exact congrFun hfold w

/-! ### 9. ⭐ HYPOTHESIS ① IS REMOVABLE — the element FORGETS its state on `rst`

`ceKeyOK` / `cePairOut` pin the element at the ALL-FALSE initial state, while
`bnC_trace_factors` hands the fold an ARBITRARY slice `bnCSlice st k`. That gap
was recorded as an unavoidable hypothesis. It is not: with `rst` high on cycle 0
the next state is a function of the inputs alone, so one cycle erases the slice. -/

theorem sem_ceCcore_congr (env₁ env₂ : Env) (h : ∀ a, a < ceCcore.nIn → env₁ a = env₂ a) :
    sem ceCcore env₁ = sem ceCcore env₂ := by
  have hout : ∀ n ∈ ceCcore.outs, n < ceCcore.nIn + ceCcore.gates.length := by
    decide +kernel
  rw [sem, sem]
  exact List.map_congr_left (fun n hn =>
    run_agree_of_inputs_circ ceCcore ceCcore_ssa' env₁ env₂ h n (hout n hn))

/-- `ceC` reads exactly four state bits, so any state list acts as its first four
entries. -/
theorem stepSeq_ceC_slice (s inp : List Bool) :
    stepSeq ceC s inp
      = stepSeq ceC [s.getD 0 false, s.getD 1 false, s.getD 2 false, s.getD 3 false] inp := by
  -- ⚠️ `h` must be stated at `ceC.core`, NOT at `ceCcore`: they are defeq but the
  -- goal `simp only [stepSeq]` leaves says `ceC.core`, and `rw` is syntactic.
  have h : sem ceC.core (ceC.env inp s)
      = sem ceC.core
          (ceC.env inp [s.getD 0 false, s.getD 1 false, s.getD 2 false, s.getD 3 false]) := by
    show sem ceCcore _ = sem ceCcore _
    refine sem_ceCcore_congr _ _ ?_
    intro a ha
    have hn7 : ceCcore.nIn = 7 := by decide +kernel
    rw [hn7] at ha
    interval_cases a <;> rfl
  simp only [stepSeq]
  rw [h]

/-- Every one of the 64 `(state, in0, in1)` configurations with `rst` high. -/
theorem ceC_reset_forgets_bits (d w p b i0 i1 : Bool) :
    stepSeq ceC [d, w, p, b] [true, i0, i1]
      = stepSeq ceC [false, false, false, false] [true, i0, i1] := by
  cases d <;> cases w <;> cases p <;> cases b <;> cases i0 <;> cases i1 <;> decide +kernel

theorem ceC_reset_forgets (s : List Bool) (i0 i1 : Bool) :
    stepSeq ceC s [true, i0, i1]
      = stepSeq ceC [false, false, false, false] [true, i0, i1] := by
  rw [stepSeq_ceC_slice s]
  exact ceC_reset_forgets_bits _ _ _ _ i0 i1

theorem runTrace_cons (m : Seq) (st i : List Bool) (is : List (List Bool)) :
    runTrace m st (i :: is)
      = ((stepSeq m st i).1 :: (runTrace m (stepSeq m st i).2 is).1,
         (runTrace m (stepSeq m st i).2 is).2) := rfl

/-- One `rst` cycle erases the initial state, for the WHOLE remaining stream. -/
theorem ceCPort_reset (s : List Bool) (rr xx yy : List Bool) (i0 i1 : Bool) (j : Nat) :
    ceCPort s (true :: rr) (i0 :: xx) (i1 :: yy) j
      = ceCPort [false, false, false, false] (true :: rr) (i0 :: xx) (i1 :: yy) j := by
  rw [ceCPort, ceCPort, zip3Trace_cons, runTrace_cons, runTrace_cons,
      ceC_reset_forgets s i0 i1]

/-- ⭐⭐ **THE TRANSFER.** Whenever the frame asserts `rst` on cycle 0, element
`k`'s standalone `ceC` — started from the arbitrary slice `bnCSlice st k` the
network hands it — produces the same output stream as one started from
`[false,false,false,false]`, which is the state `cePairOut`/`ceKeyOK` pin. -/
theorem ceCPort_at_slice_eq_reset (st : List Bool) (inp : List Bool)
    (is : List (List Bool)) (k j : Nat) (hrst : inp.getD 0 false = true) :
    ceCPort (bnCSlice st k) ((inp :: is).map (fun i => i.getD 0 false))
        (bnCFrameAt st (inp :: is) k (bnCCompAt k).1)
        (bnCFrameAt st (inp :: is) k (bnCCompAt k).2) j
      = ceCPort [false, false, false, false] ((inp :: is).map (fun i => i.getD 0 false))
        (bnCFrameAt st (inp :: is) k (bnCCompAt k).1)
        (bnCFrameAt st (inp :: is) k (bnCCompAt k).2) j := by
  rw [List.map_cons, hrst, bnCFrameAt_cons, bnCFrameAt_cons]
  exact ceCPort_reset _ _ _ _ _ _ j

/-- ⭐⭐⭐ `ElemSortsAt` — the fold's per-element obligation — **reduces to the
all-false initial state.** This is hypothesis ① discharged. -/
theorem ElemSortsAt_of_reset (st inp : List Bool) (is : List (List Bool)) (k : Nat)
    (le : List Bool → List Bool → Bool) (hrst : inp.getD 0 false = true)
    (h0 : ceCPort [false, false, false, false] ((inp :: is).map (fun i => i.getD 0 false))
            (bnCFrameAt st (inp :: is) k (bnCCompAt k).1)
            (bnCFrameAt st (inp :: is) k (bnCCompAt k).2) 0
          = (if le (bnCFrameAt st (inp :: is) k (bnCCompAt k).1)
                   (bnCFrameAt st (inp :: is) k (bnCCompAt k).2)
             then bnCFrameAt st (inp :: is) k (bnCCompAt k).1
             else bnCFrameAt st (inp :: is) k (bnCCompAt k).2))
    (h1 : ceCPort [false, false, false, false] ((inp :: is).map (fun i => i.getD 0 false))
            (bnCFrameAt st (inp :: is) k (bnCCompAt k).1)
            (bnCFrameAt st (inp :: is) k (bnCCompAt k).2) 1
          = (if le (bnCFrameAt st (inp :: is) k (bnCCompAt k).1)
                   (bnCFrameAt st (inp :: is) k (bnCCompAt k).2)
             then bnCFrameAt st (inp :: is) k (bnCCompAt k).2
             else bnCFrameAt st (inp :: is) k (bnCCompAt k).1)) :
    ElemSortsAt st (inp :: is) k le :=
  ⟨(ceCPort_at_slice_eq_reset st inp is k 0 hrst).trans h0,
   (ceCPort_at_slice_eq_reset st inp is k 1 hrst).trans h1⟩

/-! ### 10. FROM FRAMES TO KEYS — `runNet`'s literal shape at `ℕ`

`runNetF` folds FRAMES; silicon's `hseam` wants `runNet batcher8 v` at `v : Fin 8
→ ℕ`. A decoding `key : List Bool → ℕ` transports one to the other, because for a
linear order `key (min-by-key x y) = min (key x) (key y)`. -/

/-- `SaltWorks.Stack.applyComp`'s literal shape, at `ℕ`, `Nat`-indexed. -/
def applyCompN (c : Nat × Nat) (v : Nat → Nat) : Nat → Nat := fun i =>
  if i = c.1 then min (v c.1) (v c.2)
  else if i = c.2 then max (v c.1) (v c.2)
  else v i

/-- `SaltWorks.Stack.runNet`'s literal shape, at `ℕ`, `Nat`-indexed. -/
def runNetN (net : List (Nat × Nat)) (v : Nat → Nat) : Nat → Nat :=
  net.foldl (fun w c => applyCompN c w) v

theorem applyCompF_key (key : List Bool → Nat) (c : Nat × Nat) (v : Nat → List Bool)
    (i : Nat) :
    key (applyCompF (fun x y => decide (key x ≤ key y)) c v i)
      = applyCompN c (fun j => key (v j)) i := by
  -- `apply_ite key` pushes the decoding through BOTH conditionals, after which
  -- the two sides are syntactically equal — no case split is needed at all.
  simp only [applyCompF, applyCompN, min_def, max_def, decide_eq_true_eq, apply_ite key]

theorem runNetF_key (key : List Bool → Nat) (net : List (Nat × Nat)) :
    ∀ v : Nat → List Bool,
      (fun i => key (runNetF (fun x y => decide (key x ≤ key y)) net v i))
        = runNetN net (fun j => key (v j)) := by
  induction net with
  | nil => intro v; rfl
  | cons c cs ih =>
    intro v
    have h1 : runNetF (fun x y => decide (key x ≤ key y)) (c :: cs) v
        = runNetF (fun x y => decide (key x ≤ key y)) cs
            (applyCompF (fun x y => decide (key x ≤ key y)) c v) := rfl
    have h2 : runNetN (c :: cs) (fun j => key (v j))
        = runNetN cs (applyCompN c (fun j => key (v j))) := rfl
    rw [h1, h2, ih]
    congr 1
    funext j
    exact applyCompF_key key c v j

/-- ⭐⭐⭐ **THE SEAM, AT `ℕ`.** The `key` of the frame the network emits on wire
`w` is `runNet`-over-`bnComps` applied to the `key`s of its eight input frames.
`bnComps_eq_batcher8` turns `bnComps` into `batcher8`, so the only step left to
`composed_switch_of_seam_k3`'s `hseam : hw = runNet batcher8 v` is the
`Nat`-index → `Fin 8`-index transport, which lives on the Stack side. -/
theorem bnC_output_keys_are_runNetN (st : List Bool) (tr : List (List Bool))
    (key : List Bool → Nat)
    (h : ∀ k, k < 24 → ElemSortsAt st tr k (fun x y => decide (key x ≤ key y)))
    (w : Nat) (hw : w < 8) :
    key ((runTrace batcherNetC st tr).1.map (fun o => o.getD w false))
      = runNetN bnComps (fun i => key (bnCFrameAt st tr 0 i)) w := by
  rw [bnC_output_frames_are_the_fold st tr _ h w hw]
  exact congrFun (runNetF_key key bnComps (fun i => bnCFrameAt st tr 0 i)) w

#audit_axioms bnComps_ne bnCCompAt_ne bnC_run_low bnC_rst_val
#audit_axioms bnCWireAt bnCDatAt_zero_getD bnCWireAt_zero
#audit_axioms bnCElemOutAt_getD0 bnCElemOutAt_getD1 bnCWireAt_succ
#audit_axioms bnCFrameAt bnCFrameAt_nil bnCFrameAt_cons
#audit_axioms bnCElemOutFrame bnCElemOutFrame_nil bnCElemOutFrame_cons
#audit_axioms bnCFrameAt_succ bnCFrameAt_zero bnCFrameAt_24
#audit_axioms zip3Trace zip3Trace_cons bnCElemInAt_eq bnCElemTrace_eq_zip3
#audit_axioms ceCPort bnCElemOutFrame_eq_ceCPort bnCFrameAt_succ_ceC
#audit_axioms ElemSortsAt applyCompF runNetF bnCFrameAt_succ_sorted
#audit_axioms bnComps_getElem?_eq bnComps_take_succ runNetF_append
#audit_axioms bnCFrames_fold bnComps_take_24 bnC_output_frames_are_the_fold
#audit_axioms sem_ceCcore_congr stepSeq_ceC_slice ceC_reset_forgets_bits
#audit_axioms ceC_reset_forgets runTrace_cons ceCPort_reset
#audit_axioms ceCPort_at_slice_eq_reset ElemSortsAt_of_reset
#audit_axioms applyCompN runNetN applyCompF_key runNetF_key
#audit_axioms bnC_output_keys_are_runNetN

/-! ## 🏦 THE JOIN — both halves are LANDED and this is the only step left

**Read this before attempting anything: the two halves were built by different
executors in different vocabularies, and the remaining work is JOINING them, not
proving anything new about the hardware.**

### What exists, verified in the strong form

```
THIS FILE            bnC_output_keys_are_runNetN
                       key(network output on wire w)
                         = runNetN bnComps (key ∘ input frames) w
                     ⚠️ hypothesis  h : ∀ k < 24, ElemSortsAt st tr k le
                        — and ElemSortsAt IS the sorting fact, ASSUMED

SeamElement.lean     ceC_pair_full_load_out0 / _out1
                       port 0 = the cKeyLE-min of the two input frames
                       port 1 = the cKeyLE-max                    ⭐ PROVED
                     ceC_pair_full_load_any_state — ANY initial state
                     cKeyLE_full_load : cKeyLE (cKey true d0) (cKey true d1)
                                          = decide (d0 ≤ d1)
```

### The gap is exactly two hypotheses, and neither is about the circuit

1. **THE RST COLUMN.** `ElemSortsAt` drives the element with `tr.map (·.getD 0)`
   — the network's actual rst stream. `ceC_pair_full_load_*` drives it with
   `ceFrameTrace`, whose first cycle is `[true, x₀, y₀]`. ⇒ *Needs: the trace's
   rst column is asserted at cycle 0.* **A condition on the caller's trace, not a
   fact to discover.**

2. ⭐ **THE FRAME INVARIANT — and Route C already made it INDUCTIVE.** `ElemSortsAt`
   is stated on `bnCFrameAt` (arbitrary `List Bool`); the element theorem wants
   `cFrame true d p`. ⇒ *Needs: every wire carries a well-formed frame at every
   stage.* 🔑 ***And `ceC_pair_full_load_any_state` gives the induction step for
   free: its conclusion is that the two outputs ARE the two inputs, reordered.
   Well-formedness is therefore PRESERVED rather than re-established — base case
   `bnCFrameAt_zero` (the input columns), step by that theorem.***

### Then the transport, which is Stack-side and small

`cKeyLE_full_load` turns the key into `decide (d0 ≤ d1)`; `bnComps_eq_batcher8`
turns `bnComps` into `batcher8`; what remains is `runNetN` (`Nat`-indexed) →
`runNet` (`Fin 8`-indexed). **`Perm.lean:893 runNetD_toNat` is the lemma shaped
for that step.**

⚠️ **AND ONE HYPOTHESIS I BANKED AT `4538e9e` AS UNAVOIDABLE IS NOW RETIRED:**
*"`ceKeyOK` is pinned at the all-false initial state"* — `ceC_pair_full_load_any_state`
proves it from **any** state, because the reset at cycle 0 does the work.
**The both-idle exclusion stands**: `hne : d0 ≠ d1` is load-bearing, with a
control (`ceC_pair_tie_splices_the_payload`), and full load supplies it via
`seam_hyps_force_full_load`.

📌 **`hseam` is FOUR binder sites, not eight** — `grep -c` returns 8 because four
are uses in proof terms. One theorem discharges all four; three delegate to the
first. **And the discharge needs NO edit to `Silicon/Equiv/`: `HDL` already
imports `Silicon` (`EmitN.lean:7`), so a module here can `import
SaltWorks.Silicon.Equiv.ComposedSwitch` and apply `composed_switch_of_seam_k3`.**
-/

end SaltWorks.HDL

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
theorem bnC_env_agree (st inp : List Bool) (hst : st.length = 96) (e : Nat) (he : e < 24)
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
theorem bnC_state_bit (st inp : List Bool) (hst : st.length = 96) (e : Nat) (he : e < 24)
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
    (bnC_env_agree st inp hst e he pre hpre) _ (ceCcore_state_port_lt j hj)

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
theorem bnC_step_slice (st inp : List Bool) (hst : st.length = 96) (e : Nat) (he : e < 24) :
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
    exact bnC_state_bit st inp hst e he j hj pre hpre
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
assumption, which is what a power-gated TinyTapeout tile requires.* -/
theorem bnC_trace_factors : ∀ (tr : List (List Bool)) (st : List Bool), st.length = 96 →
    ∀ (e : Nat), e < 24 →
      bnCSlice (runTrace batcherNetC st tr).2 e
        = (runTrace ceC (bnCSlice st e) (bnCElemTrace st tr e)).2 := by
  intro tr
  induction tr with
  | nil => intro st _ e _; rfl
  | cons inp is ih =>
    intro st hst e he
    show bnCSlice (runTrace batcherNetC (stepSeq batcherNetC st inp).2 is).2 e
      = (runTrace ceC (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).2
          (bnCElemTrace (stepSeq batcherNetC st inp).2 is e)).2
    rw [ih _ (bnC_step_state_length st inp) e he, bnC_step_slice st inp hst e he]

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
  ⇒ hseam's 8 sites in Silicon/Equiv/ComposedSwitch.lean, via composed_switch_of_seam_dest3
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
theorem bnC_data_bit (st inp : List Bool) (hst : st.length = 96) (e : Nat) (he : e < 24)
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
    (bnC_env_agree st inp hst e he pre hpre) _ (ceCcore_data_port_lt j hj)

/-! ### Step 2b — element `e`'s OUTPUT FRAME is the standalone element's -/

/-- The two bits element `e` drives onto its wires this cycle. -/
def bnCElemOutAt (st inp : List Bool) (e : Nat) : List Bool :=
  let E := batcherNetC.env inp st
  let σ := bnCSigma e (bnCCompAt e).1 (bnCCompAt e).2 (bnCDatAt e)
  [run E bnCCore.gates ((instOuts ceCcore σ (bnCOff e)).getD 0 0),
   run E bnCCore.gates ((instOuts ceCcore σ (bnCOff e)).getD 1 0)]

theorem ceC_nOut_eq : ceC.nOut = 2 := rfl

/-- One cycle, data side, as lists. -/
theorem bnC_step_out (st inp : List Bool) (hst : st.length = 96) (e : Nat) (he : e < 24) :
    bnCElemOutAt st inp e = (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).1 := by
  obtain ⟨pre, hpre0⟩ := bnCBuild_gates_drop e bnComps 0 ((List.range bnCWires).map bnCDatIn)
  have hpre : bnCCore.gates = pre ++ (bnCBuild e (bnComps.drop e) (bnCDatAt e)).1 := by
    have h := hpre0
    simp only [Nat.zero_add] at h
    exact h
  have h0 := bnC_data_bit st inp hst e he 0 (by omega) pre hpre
  have h1 := bnC_data_bit st inp hst e he 1 (by omega) pre hpre
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
theorem bnC_out_factors : ∀ (tr : List (List Bool)) (st : List Bool), st.length = 96 →
    ∀ (e : Nat), e < 24 →
      bnCElemOuts st tr e = (runTrace ceC (bnCSlice st e) (bnCElemTrace st tr e)).1 := by
  intro tr
  induction tr with
  | nil => intro st _ e _; rfl
  | cons inp is ih =>
    intro st hst e he
    show bnCElemOutAt st inp e :: bnCElemOuts (stepSeq batcherNetC st inp).2 is e
      = (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).1
        :: (runTrace ceC (stepSeq ceC (bnCSlice st e) (bnCElemInAt st inp e)).2
              (bnCElemTrace (stepSeq batcherNetC st inp).2 is e)).1
    rw [bnC_step_out st inp hst e he, ← bnC_step_slice st inp hst e he,
        ih _ (bnC_step_state_length st inp) e he]

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
standalone `ceC`. **`bnCResult_dat` above is what makes the fold's endpoint
nameable; the frame lifting is the work.**

📌 *This is also why the two hypotheses in ① and ② above are unavoidable rather
than tidiable: they are hypotheses of the FRAME-level element certificate, and
the frame is the level the discharge has to work at.* -/

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

end SaltWorks.HDL

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

end SaltWorks.HDL

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

end SaltWorks.HDL

import Mathlib

/-! PROBE S1 — does the div/mod ("prefix-suffix") representation carry the
Batcher–banyan nonblocking proof cheaply, parametric in k? -/

namespace SaltWorks.Banyan

/-- The line a packet from source `s` bound for `d` occupies once `m` low bits
remain unrouted: high bits already `d`'s, low `m` bits still `s`'s.
`m = k` ↦ `s` (the input), `m = 0` ↦ `d` (the output). -/
def line (m s d : ℕ) : ℕ := 2 ^ m * (d / 2 ^ m) + s % 2 ^ m

/-- One banyan stage: the `m`-th 2×2 switch bank. -/
def step (m x d : ℕ) : ℕ := 2 ^ m * (d / 2 ^ m) + x % 2 ^ m

theorem line_zero (s d : ℕ) : line 0 s d = d := by simp [line, Nat.mod_one]

theorem line_of_lt (k s d : ℕ) (hs : s < 2 ^ k) (hd : d < 2 ^ k) : line k s d = s := by
  rw [line, Nat.div_eq_of_lt hd, Nat.mod_eq_of_lt hs, Nat.mul_zero, Nat.zero_add]

/-- The stage recursion: the network really is these lines, step by step. -/
theorem step_line (m s d : ℕ) : step m (line (m + 1) s d) d = line m s d := by
  rw [step, line, line]
  congr 1
  rw [pow_succ, Nat.mul_assoc, Nat.mul_add_mod, Nat.mod_mod_of_dvd _ ⟨2, rfl⟩]

/-- Recover the source's low bits from a line value. -/
theorem line_mod (m s d : ℕ) : line m s d % 2 ^ m = s % 2 ^ m := by
  rw [line, Nat.mul_add_mod, Nat.mod_mod]

/-- Recover the destination's high bits from a line value. -/
theorem line_div (m s d : ℕ) : line m s d / 2 ^ m = d / 2 ^ m := by
  rw [line, Nat.mul_add_div (Nat.two_pow_pos m),
    Nat.div_eq_of_lt (Nat.mod_lt _ (Nat.two_pow_pos m)), Nat.add_zero]

/-- Same residue + strictly greater ⇒ a full block apart. -/
theorem gap_of_mod_eq {m a b : ℕ} (h : a % 2 ^ m = b % 2 ^ m) (hlt : a < b) :
    a + 2 ^ m ≤ b := by
  have hdvd : 2 ^ m ∣ b - a := (Nat.modEq_iff_dvd' hlt.le).1 h
  have := Nat.le_of_dvd (by omega) hdvd
  omega

/-- Same quotient ⇒ inside one block. -/
theorem lt_of_div_eq {m a b : ℕ} (h : a / 2 ^ m = b / 2 ^ m) : b < a + 2 ^ m := by
  have hp : 0 < 2 ^ m := Nat.two_pow_pos m
  have ha := Nat.div_add_mod a (2 ^ m)
  have hb := Nat.div_add_mod b (2 ^ m)
  have := Nat.mod_lt a hp
  have := Nat.mod_lt b hp
  rw [h] at ha
  omega

/-- A ℕ-valued strictly monotone map on an initial segment spreads at least as
much as the identity. -/
theorem strictMonoOn_gap {n : ℕ} {f : ℕ → ℕ} (hf : StrictMonoOn f (Set.Iio n)) :
    ∀ j a : ℕ, a + j < n → f a + j ≤ f (a + j) := by
  intro j
  induction j with
  | zero => intro a _; simp
  | succ j ih =>
    intro a ha
    have h2 : f a + j ≤ f (a + j) := ih a (by omega)
    have h1 : f (a + j) < f (a + j + 1) :=
      hf (Set.mem_Iio.2 (by omega)) (Set.mem_Iio.2 (by omega)) (by omega)
    have : a + (j + 1) = a + j + 1 := by omega
    rw [this]
    omega

/-! ## THE HEART -/

/-- **Batcher–banyan, S1.** If the active inputs are the concentrated block
`{0,…,n-1}` and their destinations are distinct and sorted (`StrictMonoOn`),
then at every stage boundary `m` the occupied lines are distinct: no internal
link conflict anywhere in the network. Parametric in `k` (indeed `k`-free). -/
theorem no_conflict {n : ℕ} {dest : ℕ → ℕ} (hdest : StrictMonoOn dest (Set.Iio n))
    (m : ℕ) : Set.InjOn (fun s => line m s (dest s)) (Set.Iio n) := by
  have key : ∀ a b, a < n → b < n → a < b → line m a (dest a) ≠ line m b (dest b) := by
    intro a b ha hb hab hEq
    -- low bits agree ⇒ the sources sit a full block apart
    have hmod : a % 2 ^ m = b % 2 ^ m := by
      rw [← line_mod m a (dest a), ← line_mod m b (dest b), hEq]
    have hgap : a + 2 ^ m ≤ b := gap_of_mod_eq hmod hab
    -- high bits agree ⇒ the destinations sit inside one block
    have hdiv : dest a / 2 ^ m = dest b / 2 ^ m := by
      rw [← line_div m a (dest a), ← line_div m b (dest b), hEq]
    have hin : dest b < dest a + 2 ^ m := lt_of_div_eq hdiv
    -- but sortedness forces them at least as far apart as the sources
    have hspread : dest a + (b - a) ≤ dest (a + (b - a)) :=
      strictMonoOn_gap hdest (b - a) a (by omega)
    have hab' : a + (b - a) = b := by omega
    rw [hab'] at hspread
    omega
  intro a ha b hb hEq
  rcases lt_trichotomy a b with h | h | h
  · exact absurd hEq (key a b ha hb h)
  · exact h
  · exact absurd hEq.symm (key b a hb ha h)

/-- The `k`-instantiated corollary: at the input boundary the lines are the
sources, at the output boundary they are the destinations, and every
intermediate stage is conflict-free. -/
theorem banyan_selfrouting {k n : ℕ} {dest : ℕ → ℕ}
    (hn : n ≤ 2 ^ k) (hdest : StrictMonoOn dest (Set.Iio n))
    (hlt : ∀ s < n, dest s < 2 ^ k) :
    (∀ m ≤ k, Set.InjOn (fun s => line m s (dest s)) (Set.Iio n)) ∧
      (∀ s < n, line k s (dest s) = s) ∧ (∀ s, line 0 s (dest s) = dest s) :=
  ⟨fun m _ => no_conflict hdest m,
   fun s hs => line_of_lt k s (dest s) (by omega) (hlt s hs),
   fun s => line_zero s (dest s)⟩

end SaltWorks.Banyan

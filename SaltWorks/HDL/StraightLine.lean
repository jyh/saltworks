import SaltWorks.Stack.Program

/-! # STRAIGHT-LINE CODE AND ITS FUEL LEMMA (block ① rung L0, fuel half) — `Forward` + `runFor_extend`

P1 rung L0 per the two-track ruling (`65705fe`). The target:

  `runFor_extend : code.length ≤ n → Forward code → runFor n code s = run code s`

`run code s = runFor code.length code s`, so this says **extra fuel is free on
straight-line code** — the property every per-expression correctness statement
at L0 needs in order to compose without threading a fuel number.

The mechanism, all landed: only `BEQ` can move `pc` by anything but `+4`
(`step`, ISA.lean:120-126), so a `BEQ`-free program advances four bytes per
step; from `pc = 4*j` it runs off the end within `code.length - j` steps; and
once `fetch = none`, `runFor_eq_of_halted` (Program.lean:654, corrected 8/12 from
:628 — the theorem moved and the comment did not) freezes it. -/

open SaltWorks.ISA

namespace SaltWorks.StraightLine

/-- The one instruction that can move `pc` by anything other than `+4`.

⬥⬥ **THE CATCH-ALL IS GONE (Captain's ruling, 2026-08-11 19:05: exhaustive arms
preferred in all cases). SEMANTICS UNCHANGED — these seven arms return exactly
what `| .BEQ _ _ _ => false | _ => true` returned**, constructor for constructor.

⚖️ **This site was FENCED, and converting a fenced site is still the ruling.**
`step_forward_pc` below is `∀ (i : Instr)` discharged by `cases i`, so a wrongly
absorbed constructor produced an unprovable goal rather than a silent `true` —
*measured by math at the refuter pass and recorded at `Stack/Program.lean:266`,
where the genuinely UNFENCED sibling (`branchIsForward`, whose consumers only
quantify over list membership) is dissected.* **A fence makes a catch-all
survivable, not correct: it converts the silence into a red build only for
whoever happens to touch this theorem next.** The arms make the decision
unavoidable at the point the constructor is added, which is where it belongs. -/
def isForward : Instr → Bool
  | .BEQ  _ _ _ => false
  | .ADD  _ _ _ => true
  | .ADDI _ _ _ => true
  | .XOR  _ _ _ => true
  | .SLT  _ _ _ => true
  | .LW   _ _ _ => true
  | .SW   _ _ _ => true

/-- Straight-line: no branches. *Stated on the CODE, not on a run, so it is
checkable by the emitter at L0 and survives into L1/L2 unchanged.* -/
def Forward (code : List Instr) : Bool := code.all isForward

/-- A register write never moves `pc` — both branches of `St.set`'s `x0` guard
leave it alone. *This is the lemma `simp` cannot do for you, because the guard
is an `if` on `r = 0`.* -/
theorem St_set_pc (s : St) (r : Fin 32) (v : BitVec 32) : (s.set r v).pc = s.pc := by
  unfold St.set; split <;> rfl

/-- ⭐ **A forward instruction advances `pc` by exactly four.** -/
theorem step_forward_pc (s : St) (i : Instr) (h : isForward i = true) :
    (step s i).pc = s.pc + 4 := by
  -- ⬥ M2: LW/SW are forward — every one of their branches ends in `.next`. The
  -- only new work was splitting the address `dite`, the "replay, not a design
  -- change" the memory block's §0.7 predicted for this exact theorem.
  -- ⚖️ **That work is what this theorem being `cases i`-exhaustive BOUGHT**: M2
  -- could not add a constructor without discharging its goal here. The original
  -- note said the *wildcard* classified LW/SW and read as a near-miss; it was
  -- the fence firing. (Wildcard removed above; the note is kept because the
  -- episode is the evidence that the fence works.)
  cases i <;> simp_all [step, isForward, St.next, St_set_pc] <;> split_ifs <;> rfl

/-- A fetched instruction is a member of the code. -/
theorem fetch_mem {code : List Instr} {pc : BitVec 32} {i : Instr}
    (h : fetch code pc = some i) : i ∈ code := by
  unfold fetch at h
  split at h
  · exact List.mem_of_getElem? h
  · exact absurd h (by simp)

/-- …so under `Forward`, every fetched instruction is forward. -/
theorem fetch_forward {code : List Instr} {pc : BitVec 32} {i : Instr}
    (hf : Forward code = true) (h : fetch code pc = some i) : isForward i = true := by
  have := List.all_eq_true.mp hf i (fetch_mem h)
  exact this

#audit_axioms isForward Forward
#audit_axioms St_set_pc
#audit_axioms step_forward_pc
#audit_axioms fetch_mem
#audit_axioms fetch_forward

/-- `fetch` succeeding bounds the pc below the image. -/
theorem fetch_some_lt {code : List Instr} {pc : BitVec 32} {i : Instr}
    (h : fetch code pc = some i) : pc.toNat / 4 < code.length := by
  unfold fetch at h
  split at h
  · exact List.getElem?_eq_some_iff.mp h |>.1
  · exact absurd h (by simp)

/-- `fetch` fails once the pc is at or past the end of the image. -/
theorem fetch_none_of_ge {code : List Instr} {pc : BitVec 32}
    (h : code.length ≤ pc.toNat / 4) : fetch code pc = none := by
  unfold fetch
  split
  · exact List.getElem?_eq_none h
  · rfl

/-- ⭐⭐ **A FORWARD PROGRAM HALTS WITHIN ITS OWN LENGTH.** From `pc = 4*j`,
`code.length - j` steps run it off the end.

⚠️ **The `4 * code.length < 2^32` hypothesis is REAL and L0's drafted statement
omits it:** `pc` is a `BitVec 32`, so `pc + 4` WRAPS, and without a bound on the
image length a long-enough program could wrap the pc back into itself. Any
emitted program discharges it trivially; the type does not. -/
theorem forward_halts : ∀ (n : Nat) (code : List Instr) (s : St),
    Forward code = true → 4 * code.length < 2 ^ 32 →
    code.length ≤ n + s.pc.toNat / 4 →
    fetch code (runFor n code s).pc = none := by
  intro n
  induction n with
  | zero =>
    intro code s _ _ hle
    simp only [runFor]
    exact fetch_none_of_ge (by omega)
  | succ m ih =>
    intro code s hf hb hle
    rw [runFor]
    cases hfe : fetch code s.pc with
    | none => simpa [hfe] using hfe
    | some i =>
      simp only [hfe]
      have hfw : isForward i = true := fetch_forward hf hfe
      have hlt : s.pc.toNat / 4 < code.length := fetch_some_lt hfe
      have hpc : (step s i).pc = s.pc + 4 := step_forward_pc s i hfw
      have h4 : s.pc.toNat < 4 * code.length := by
        have := (Nat.div_lt_iff_lt_mul (by norm_num : (0:Nat) < 4)).mp hlt
        omega
      have hb2 : s.pc.toNat + 4 < 2 ^ 32 := by omega
      have h4n : ((4 : BitVec 32)).toNat = 4 := by decide
      have hnw : (s.pc + 4).toNat = s.pc.toNat + 4 := by
        rw [BitVec.toNat_add, h4n, Nat.mod_eq_of_lt hb2]
      refine ih code (step s i) hf hb ?_
      rw [hpc, hnw]
      omega

#audit_axioms fetch_some_lt
#audit_axioms fetch_none_of_ge
#audit_axioms forward_halts

/-- ⭐⭐⭐ **L0's FUEL LEMMA: EXTRA FUEL IS FREE ON STRAIGHT-LINE CODE.**
`run` is `runFor code.length`, so this is what lets a per-expression correctness
statement compose without threading a fuel number through it. -/
theorem runFor_extend (code : List Instr) (s : St) (n : Nat)
    (hn : code.length ≤ n) (hf : Forward code = true) (hb : 4 * code.length < 2 ^ 32) :
    runFor n code s = run code s := by
  have hhalt := forward_halts code.length code s hf hb (by omega)
  show runFor n code s = runFor code.length code s
  exact SaltWorks.Stack.Program.runFor_eq_of_halted hhalt hn

/-! ### The control — `Forward` is load-bearing, not decoration -/

/-- A two-instruction loop: bump `x1`, then branch back over both. `bOffset`
is `sext(imm) * 2`, so `imm = -2` is a `-4` byte displacement. -/
def loopCode : List Instr :=
  [ .ADDI 1 1 1, .BEQ 0 0 (BitVec.ofInt 12 (-2)) ]

/-- ⛔ **WITHOUT `Forward`, MORE FUEL CHANGES THE ANSWER.** The same program at
two fuels disagrees, so `runFor_extend`'s conclusion is FALSE for branching code
and its `Forward` hypothesis cannot be dropped. -/
theorem forward_is_load_bearing :
    ((runFor 2 loopCode St.init).get 1 == (runFor 6 loopCode St.init).get 1) = false := by
  decide

/-- …and the same program IS rejected by `Forward`, so the hypothesis is the
thing doing the excluding. -/
theorem loopCode_not_forward : Forward loopCode = false := by decide

#audit_axioms runFor_extend
#audit_axioms loopCode
#audit_axioms forward_is_load_bearing
#audit_axioms loopCode_not_forward

end SaltWorks.StraightLine

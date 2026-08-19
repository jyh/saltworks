/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# `C4Spec core` IS FALSE — the flagship, refuted in the kernel

⛔⛔⛔ **THE CAMPAIGN'S TARGET IS NOT OPEN. IT IS FALSE FOR `core` AS ASSEMBLED**, and this
file is the witness. `c4Spec_iff_fieldwise` is an **`iff`**, and `regField_iff_bits` and
`core_outBit_reg_reduced` are an `iff` and an equation, so the reduction that carried
`RegDatapathOK` UP to `C4Spec` also runs DOWN:

```
¬ RegDatapathOK  →  ¬ RegField core 4  →  ¬ (∀ r, RegField core r)  →  ¬ C4Spec core
```

## THE WITNESS, in one line

**`SW x1, x2, 4`.** The store's `imm[4:0]` is `4`, and the enable reads bits 7…11 as an `rd`
(`rdOf ins0 = 4`), so the circuit **write-enables register 4** — while the ISA holds it
(`writesReg (.SW …) = none`). Register 4's bit 0 is set; the write-data path carries `false`
there. Two sides, one bit, opposite values. That is the whole refutation, and it is the
`SW` enable defect of `DecoderTransport` cashed into a counterexample.

## HOW IT IS EVALUATED, because the obvious way DOES NOT WORK

`core.gates.length = 10394`. A direct `decide +kernel` on `run ins core.gates (selOut 0)`
**DIES**: EXIT=134 at 190 s, RSS climbing linearly past 23 GB against `-M 24000`, killed by
`lean::memory_exception`. ⛔ **DO NOT RE-WALK THAT ROUTE.** The blowup is not the gate count —
it is that `Env = Net → Bool` and `run` threads it as a nested `upd` CLOSURE CHAIN, so every
lookup walks the chain and the kernel caches ~2·10394 (env-prefix, net) whnf pairs.

The cure is to change the ENVIRONMENT REPRESENTATION, not the circuit: pack the whole net
valuation into ONE `Nat` (`runB`), because `Nat.land/lor/xor/pow/testBit` are GMP-accelerated
in the kernel. `runB_eq` proves the packed evaluator IS `run`, by induction, in twelve lines.
**Three full 10394-gate kernel evaluations then cost 25 s for the entire file.**

## THE CONTROLS — five, each able to FAIL

1. `control_packed_true` — the instrument is not constantly `false` (`rwOut 4` is `true` on
   the same environment, same gate list, same evaluator).
2. `control_symbolic` + `control_same_net` — the packed answer AGREES with a value proved
   SYMBOLICALLY (`core_writes_on_SW`, which evaluates no gate at all).
3. `control_fixture_moves` — **change the fixture and the verdict must move**: setting `x1`'s
   bit 0 (the store's `rs1`) flips `selOut 0` to `true`. A dead wire pinned to `false` would
   not move, and would have refuted nothing.
4. `env_encodings_agree` — the packed environment and an independently written one are the
   same function on every primary input (`core.nIn = 1088`; checked to 1199 for slack).
5. `control_same_proposition` — ⭐ **the `RegDatapathOK` refuted here is the FLAGSHIP'S OWN
   hypothesis**: it is fed to `c4Spec_core_of_datapath_and_pc`, so if the name resolved to any
   other declaration this file would not typecheck.

## HONEST LIMITS

- ⚠️ **THE IDENTITY ARGUMENT NEEDED MORE THAN `pp.fullNames`.** `command grep` finds TWO
  `def RegDatapathOK` — `C4Reduction.lean:39` (the flagship) and `ScratchC4Reduction.lean:12`
  — **both in namespace `SaltWorks.HDL.RegNextUniform`**, so they print IDENTICALLY and the
  machine-printed statement could not have told them apart. What actually pins it: nothing
  imports `ScratchC4Reduction` (RC=1), and `control_same_proposition` feeds the refuted
  proposition into `C4Reduction`'s own `c4Spec_core_of_datapath_and_pc`. The conclusion
  stands; the argument I first gave for it was insufficient.

- This refutes the sentence **as written**. `RegDatapathOK` quantifies over all `Env` with no
  well-formedness side condition, so any total environment is admissible — and nothing about
  `ins0` is exotic (a set register bit and a legal store word).
- ⭐ **IT IS DATED, AND THAT IS THE POINT.** `¬ C4Spec core` is about `core` **as it stands
  today**. The repair — a disqualifier for stores in the enable — is expected to FLIP this
  file. **These are DIFFERENTIAL receipts.** Do not delete them; watch them die.
- ⛔⛔ **BUT THIS FILE'S OWN RECEIPT IS INERT TODAY, AND I ADVERTISED OTHERWISE.** I wrote
  "a repair that leaves them compiling has not been made" — **THIS MODULE IS NOT IN THE BUILD
  GRAPH.** `SaltWorks.lean` does not import it (RC=1) and no module does (RC=1), against
  `DecoderTransport`'s 8 importers as a positive control. So a default `lake build` NEVER
  ELABORATES THIS FILE, and after the repair it would stay green while every theorem here
  silently went false. **The watchdog was wired to nothing.**
  ⇒ **import owed: `SaltWorks.HDL.C4Refuted` — one line in `SaltWorks.lean`, which is
    MAESTRO-ONLY (`docs/SEATS.md`), so I cannot land it.** Until it lands, the receipt is
    PROCEDURAL, not automatic: **whoever makes the repair MUST run**
      `../saltbuild.sh SaltWorks.HDL.C4Refuted`   # MUST FAIL after a correct repair
    and a green there means the repair is incomplete. A procedural guard is weaker than a
    build-graph one and is stated as weaker on purpose.
  ⚠️ **`core_writes_on_SW` (in `DecoderTransport`) IS live** — that module IS imported, so
    that one differential fires automatically. Of the receipts I named on the bus, one was
    load-bearing and the two in this file were not. Do not conflate them.
- Not a defect in the silicon. `SaltWorks/Silicon/RTL/core32.v:75` omits stores from `reg_we`
  entirely, so the taped-out RTL carries neither of the two Lean enable defects. Both are
  model-side, and no claimed correspondence between `core` and `core32.v` exists in any case.

*import owed: `SaltWorks.HDL.C4Refuted`.*
-/
import SaltWorks.HDL.DecoderTransport

namespace SaltWorks.HDL.C4Refuted
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.HDL.RegNextUniform

set_option maxHeartbeats 4000000

/-! ## A kernel-cheap evaluator: the whole net valuation as ONE `Nat`. -/

/-- Write bit `n` of `s` to `v`. -/
def bset (s n : Nat) (v : Bool) : Nat :=
  (s ^^^ (s &&& 2 ^ n)) ||| (if v then 2 ^ n else 0)

theorem testBit_bset (s n : Nat) (v : Bool) (j : Nat) :
    (bset s n v).testBit j = if j = n then v else s.testBit j := by
  by_cases h : j = n
  · subst h
    simp only [bset, Nat.testBit_or, Nat.testBit_xor, Nat.testBit_and, Nat.testBit_two_pow]
    cases v <;> cases hs : s.testBit j <;> simp
  · have h' : ¬ (n = j) := fun hh => h hh.symm
    simp only [bset, Nat.testBit_or, Nat.testBit_xor, Nat.testBit_and, Nat.testBit_two_pow,
      if_neg h, decide_eq_false h']
    cases v <;> cases hs : s.testBit j <;> simp [h']

/-- The gate op, read out of the packed state. -/
def opEvalN (s : Nat) : Op → Bool
  | .const b => b
  | .not a   => !(s.testBit a)
  | .and a b => s.testBit a && s.testBit b
  | .or  a b => s.testBit a || s.testBit b
  | .xor a b => s.testBit a ^^ s.testBit b

theorem opEvalN_eq (s : Nat) (o : Op) : opEvalN s o = o.eval (fun n => s.testBit n) := by
  cases o <;> rfl

/-- The packed run. -/
def runB (s : Nat) : List Gate → Nat
  | []      => s
  | g :: gs => runB (bset s g.out (opEvalN s g.op)) gs

/-- ⭐ **SOUNDNESS: the packed evaluator IS `run`.** -/
theorem runB_eq (gs : List Gate) : ∀ (s : Nat) (j : Nat),
    (runB s gs).testBit j = run (fun n => s.testBit n) gs j := by
  induction gs with
  | nil => intro s j; rfl
  | cons g gs ih =>
    intro s j
    have hfun : (fun n => (bset s g.out (opEvalN s g.op)).testBit n)
        = upd (fun n => s.testBit n) g.out (g.op.eval (fun n => s.testBit n)) := by
      funext n
      rw [testBit_bset, opEvalN_eq]
      simp only [upd]
    show (runB (bset s g.out (opEvalN s g.op)) gs).testBit j
        = run (upd (fun n => s.testBit n) g.out (g.op.eval (fun n => s.testBit n))) gs j
    rw [ih, hfun]

/-! ## The witness environment, presented as a packed `Nat`. -/

/-- `SW x1, x2, 4` = `2138659#32`. -/
def wSW : BitVec 32 := encode (.SW 1 2 4)

/-- Register 4 bit 0 (net 128) set; pc = 0; the word at nets 1056…1087. -/
def s0 : Nat := 2 ^ 128 ||| (2138659 * 2 ^ 1056)

def ins0 : Env := fun n => s0.testBit n

theorem seen_ins0 : seenWord ins0 = wSW := by decide +kernel
theorem rd_ins0 : rdOf ins0 = 4 := by decide +kernel
theorem held_ins0 : ins0 (32 * rdOf ins0 + 0) = true := by rw [rd_ins0]; decide +kernel

/-! ## The packed evaluation (STRICT: the kernel forces every one of the 10394 gates). -/

/-- ⭐ **THE PACKED WITNESS** — every one of `core`'s 10394 gates evaluated by the kernel. -/
theorem bFull : (runB s0 core.gates).testBit 7675 = false := by decide +kernel

theorem selOut0_net : selOut 0 = 7675 := by decide +kernel

/-- ⭐⭐ **THE WRITE-DATA PATH IS `false` AT BIT 0 IN THIS ENVIRONMENT.** -/
theorem sel_ins0 : run ins0 core.gates (selOut 0) = false := by
  rw [selOut0_net]
  exact (runB_eq core.gates s0 7675).symm.trans bFull

theorem dec_ins0 : decode (seenWord ins0) = some (.SW 1 2 4) := by
  rw [seen_ins0]; exact decode_encode _

theorem rdOf_ins0_ne_zero : ¬ (rdOf ins0 = 0) := by rw [rd_ins0]; decide

/-- ⭐⭐⭐ **`RegDatapathOK` IS FALSE.**  On the store `SW x1, x2, 4` the enable is high at
register 4 (its immediate's low five bits), the ISA holds register 4, and the circuit's
write-data path carries `false` at bit 0 while register 4 holds `true` there. -/
theorem regDatapathOK_is_false : ¬ RegDatapathOK := by
  intro hOK
  have h := sw_forces_selOut_to_equal_held hOK ins0 1 2 4 dec_ins0 rdOf_ins0_ne_zero 0 (by omega)
  rw [sel_ins0, held_ins0] at h
  exact Bool.noConfusion h

/-! ## CONTROLS — five, each able to fail. -/

/-- **CONTROL 1 — THE INSTRUMENT IS NOT CONSTANTLY `false`.** `rwOut 4` is `true` under the
packed evaluator on the same environment and the same gate list. -/
theorem control_packed_true : run ins0 core.gates (rwOut 4) = true :=
  (runB_eq core.gates s0 (rwOut 4)).symm.trans (by decide +kernel)

/-- **CONTROL 2 — AND IT AGREES WITH A SYMBOLICALLY PROVED VALUE AT THAT NET.**
`core_writes_on_SW` proves this WITHOUT evaluating a gate; Control 1 evaluates all 10394.
The two must name the same net (`rd_ins0`) and the same Bool. -/
theorem control_symbolic : run ins0 core.gates (rwOut (rdOf ins0)) = true :=
  core_writes_on_SW ins0 1 2 4 dec_ins0 rdOf_ins0_ne_zero

theorem control_same_net : run ins0 core.gates (rwOut 4) = run ins0 core.gates (rwOut (rdOf ins0)) := by
  rw [rd_ins0]

/-- **CONTROL 3 — THE FIXTURE MOVES THE VERDICT.** `s1` is `s0` with register `x1`'s bit 0
also set (net 32). `x1` is the store's `rs1`, so the result bank must change; if `selOut 0`
were pinned to `false` by a dead wire rather than by arithmetic, this would still be
`false`. -/
def s1 : Nat := 2 ^ 32 ||| (2 ^ 128 ||| (2138659 * 2 ^ 1056))

theorem control_fixture_moves : (runB s1 core.gates).testBit 7675 = true := by decide +kernel

/-- **CONTROL 4 — the interpreter probe's environment and the packed one are the same
function on every PRIMARY INPUT.** `core.nIn = 1088`, and every other net a gate reads is
one an earlier gate wrote (`ssa`), so agreement on `0 … 1087` is what the run depends on;
the check runs to `1199` for slack. -/
def insAlt : Env := fun n =>
  if n < 1024 then n == 128
  else if n < 1088 then (if 1056 ≤ n then wSW.getLsbD (n - 1056) else false)
  else false

theorem env_encodings_agree :
    ((List.range 1200).all fun n => insAlt n == ins0 n) = true := by decide +kernel

/-! ## WHAT IT COSTS THE FLAGSHIP — the converse direction, which was already an `iff`. -/

/-- The `r`-th datapath instance follows FROM the `r`-th `RegField`: `regField_iff_bits` is
an `iff` and `core_outBit_reg_reduced` an equation, so `regFields_of_datapath` runs backwards. -/
theorem datapathAt_of_regField (r : Fin 32) (h : SaltWorks.Stack.Program.RegField core r) (ins : Env) (k : Nat)
    (hk : k < 32) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := by
  rw [← core_outBit_reg_reduced ins r.val k r.isLt hk]
  exact (SaltWorks.Stack.Program.regField_iff_bits core r).mp h ins k hk

theorem datapath_of_regFields (h : ∀ r : Fin 32, SaltWorks.Stack.Program.RegField core r) :
    RegDatapathOK :=
  fun ins r k hk => datapathAt_of_regField r (h r) ins k hk

/-- The ISA HOLDS register 4 on this word, and register 4's bit 0 is set. -/
theorem held_step :
    ((SaltWorks.ISA.stepT (decQ ins0) (seenWord ins0)).regs[(⟨4, by omega⟩ : Fin 32).val]).getLsbD 0
      = true := by
  have hnw : ∀ i, decode (seenWord ins0) = some i → writesReg i ≠ some (⟨4, by omega⟩ : Fin 32) := by
    intro i hi
    rw [dec_ins0] at hi
    cases hi
    simp [writesReg]
  rw [stepT_regs_of_ne (decQ ins0) (seenWord ins0) ⟨4, by omega⟩ hnw,
      decQ_reg_bit ins0 ⟨4, by omega⟩ 0 (by omega)]
  decide +kernel

/-- ⭐⭐⭐ **THE SHARP FORM: `RegField core 4` IS FALSE.** Not "the conjunction fails
somewhere" — this names the register. -/
theorem regField_core_four_is_false : ¬ SaltWorks.Stack.Program.RegField core ⟨4, by omega⟩ := by
  intro hR
  have h := datapathAt_of_regField ⟨4, by omega⟩ hR ins0 0 (by omega)
  rw [control_packed_true, if_pos rfl, sel_ins0, held_step] at h
  exact Bool.noConfusion h

theorem regFields_core_are_false : ¬ (∀ r : Fin 32, SaltWorks.Stack.Program.RegField core r) :=
  fun h => regField_core_four_is_false (h ⟨4, by omega⟩)

/-- ⭐⭐⭐ **AND THEREFORE `C4Spec core` IS FALSE.** `c4Spec_iff_fieldwise` is an `iff`, so
the fieldwise conjunction is not merely sufficient — it is necessary. -/
theorem c4Spec_core_is_false : ¬ SaltWorks.HDL.C4Spec core :=
  fun h => regFields_core_are_false (((SaltWorks.Stack.Program.c4Spec_iff_fieldwise core).mp h).2.1)

#audit_axioms datapathAt_of_regField datapath_of_regFields held_step
#audit_axioms regField_core_four_is_false regFields_core_are_false c4Spec_core_is_false
#audit_axioms control_packed_true control_symbolic control_same_net
#audit_axioms control_fixture_moves env_encodings_agree
#audit_axioms testBit_bset opEvalN_eq runB_eq
#audit_axioms seen_ins0 rd_ins0 held_ins0 bFull selOut0_net sel_ins0
#audit_axioms dec_ins0 rdOf_ins0_ne_zero regDatapathOK_is_false

/-- **CONTROL 5 — THE PROPOSITION I REFUTED IS THE FLAGSHIP'S OWN HYPOTHESIS.** If
`RegDatapathOK` here resolved to any other declaration of that name, this would not
typecheck. -/
theorem control_same_proposition :
    RegDatapathOK → SaltWorks.Stack.Program.PcField core → SaltWorks.HDL.C4Spec core :=
  c4Spec_core_of_datapath_and_pc

#audit_axioms control_same_proposition

/-! ## THE STATEMENTS, PRINTED BY THE MACHINE — not transcribed by me. -/

set_option pp.fullNames true in
#check @regDatapathOK_is_false
set_option pp.fullNames true in
#check @regField_core_four_is_false
set_option pp.fullNames true in
#check @c4Spec_core_is_false
set_option pp.fullNames true in
#check @SaltWorks.HDL.RegNextUniform.RegDatapathOK

#print axioms regDatapathOK_is_false
#print axioms c4Spec_core_is_false

end SaltWorks.HDL.C4Refuted

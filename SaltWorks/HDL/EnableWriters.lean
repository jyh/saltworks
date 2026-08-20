/-
⚙️ REWIRED SCRATCH COPY of `SaltWorks/HDL/EnableWriters.lean` — executor deliverable, NOTHING TRACKED IS TOUCHED.

The 2 local helper copies listed below were DELETED and every use repointed at
`SaltWorks.HDL.RegNextUniform.Shared` (proved once in `ScratchQ4RDedupEx`):
  · rdOf_is_decode_field
  · decode_add_rd

⛔ `coreThruRw_split5` is DELIBERATELY UNTOUCHED (its removal has real integration
cost — a local prefix `def` name — and is out of this brief's scope).

⚠️ This file declares the SAME fully-qualified names as `SaltWorks/HDL/EnableWriters.lean`; the two must
never enter one import graph.  Checked: nothing in this file's transitive closure
imports it (`SelValueSLTBit0` does, and is absent).
-/
/-
Q7 — THE ENABLE HALF, POSITIVE ARM (scratch; compiler seat's proof queue).

# What is new here: the enable is HIGH exactly where the ISA writes

`DecoderTransport` proves the enable TRUE at `rwOut (rdOf ins)` — at the CIRCUIT's own
`rd` read, at one register, under `¬ (rdOf ins = 0)`. This file closes the sweep:

```
core_rwOut_eq_isa_write :  decode (seenWord ins) = some i  ->  touchesMem i = false  ->
    run ins core.gates (rwOut r.val) = (decide (writesReg i = some r) && !(r.val == 0))
```

**over ALL THIRTY-TWO registers, with `r` free and the destination taken from `decode`,
not from the circuit.** The bridge that makes the two sides meet is
`Shared.rdOf_is_decode_field` (`ScratchQ4RDedupEx`) — `Bridge3`'s script at offset 7.

⛔ **SCOPE FENCE, HONOURED IN THE STATEMENT.** `touchesMem i = false` excludes `LW` and `SW`
outright, so nothing here reads `mem` and Horn D is untouched. It also keeps `writesReg` —
documented in `IsaHold` as an OVER-approximation, safe only negatively — inside the region
where it is EXACT: on `ADD`/`XOR`/`SLT`/`ADDI`/`BEQ` it is precisely what `step` does.

⚠️ **DUPLICATION, DECLARED — READ BEFORE LANDING.** The concurrently-running
`ScratchQ7x0Ex.lean` (the same queue item's off-target arm, namespace `Q7x0`) proves:
  * `Q7x0.rdField_toNat` — the SAME statement as `rdOf_is_decode_field` below, same script;
  * `Q7x0.writesReg_is_rd_field` — STRICTLY MORE GENERAL than the four `decode_*_rd` lemmas
    below (all seven classes in one theorem).
**The seat should land ONE copy of each, and the peer's is the stronger of the two.**
`Q7x0.regDatapath_off_target` / `regDatapath_rd_zero` also overlap `regDatapath_enable_arm`
below and are more general in the NEGATIVE direction (no decode hypothesis at all).
***What survives that comparison as this file's own contribution is the POSITIVE direction:
the enable is TRUE at the ISA's destination, which the off-target arm does not state.***
(Peer file read 2026-08-20 13:10; it is gitignored and in flight — re-check before landing.)

*Not C4, not a witness, does not close R9/B2. No new `RegField` is discharged.*
-/
import SaltWorks.HDL.DecoderTransport
import SaltWorks.HDL.PcFieldClosed
import SaltWorks.HDL.SelValueShared

namespace SaltWorks.HDL.RegNextUniform.Writers
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-! ### Step 1 — BRIDGE 3 FOR `rd`: the enable's address IS `decode`'s `rd` field. -/

theorem rdOf_eq_toReg (ins : Env) :
    rdOf ins = (toReg ((seenWord ins).extractLsb' 7 5)).val := by
  rw [← Shared.rdOf_is_decode_field ins]
  rfl

theorem rdOf_eq_of_rd (ins : Env) (rd : Fin 32)
    (h : rd = toReg ((seenWord ins).extractLsb' 7 5)) : rdOf ins = rd.val := by
  rw [rdOf_eq_toReg ins, h]

/-! ### Step 2 — `decode`'s four register-writing NON-MEMORY arms name the same field. -/

theorem decode_xor_rd (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.XOR rd a b)) :
    rd = toReg (w.extractLsb' 7 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

theorem decode_slt_rd (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.SLT rd a b)) :
    rd = toReg (w.extractLsb' 7 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

theorem decode_addi_rd (w : BitVec 32) (rd a : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.ADDI rd a imm)) : rd = toReg (w.extractLsb' 7 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

/-! ### Step 3 — THE SWEEP, per class: the enable over ALL THIRTY-TWO registers. -/

theorem core_rwOut_sweep_ADD (ins : Env) (rd a b : Fin 32) (r : Nat) (hr : r < 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    run ins core.gates (rwOut r) = (rd.val == r && !(r == 0)) := by
  rw [core_rwOut_spec ins r hr, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins,
      rdOf_eq_of_rd ins rd (Shared.decode_add_rd _ rd a b h)]
  simp [ctrlSpec, h]

theorem core_rwOut_sweep_XOR (ins : Env) (rd a b : Fin 32) (r : Nat) (hr : r < 32)
    (h : decode (seenWord ins) = some (.XOR rd a b)) :
    run ins core.gates (rwOut r) = (rd.val == r && !(r == 0)) := by
  rw [core_rwOut_spec ins r hr, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins,
      rdOf_eq_of_rd ins rd (decode_xor_rd _ rd a b h)]
  simp [ctrlSpec, h]

theorem core_rwOut_sweep_SLT (ins : Env) (rd a b : Fin 32) (r : Nat) (hr : r < 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (rwOut r) = (rd.val == r && !(r == 0)) := by
  rw [core_rwOut_spec ins r hr, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins,
      rdOf_eq_of_rd ins rd (decode_slt_rd _ rd a b h)]
  simp [ctrlSpec, h]

theorem core_rwOut_sweep_ADDI (ins : Env) (rd a : Fin 32) (imm : BitVec 12) (r : Nat)
    (hr : r < 32) (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    run ins core.gates (rwOut r) = (rd.val == r && !(r == 0)) := by
  rw [core_rwOut_spec ins r hr, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins,
      rdOf_eq_of_rd ins rd (decode_addi_rd _ rd a imm h)]
  simp [ctrlSpec, h]

theorem core_rwOut_sweep_BEQ (ins : Env) (a b : Fin 32) (imm : BitVec 12) (r : Nat)
    (hr : r < 32) (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    run ins core.gates (rwOut r) = false :=
  core_writes_nothing_on_BEQ ins r hr a b imm h

/-! ### Step 4 — THE PER-FIELD AGREEMENT STATEMENT. -/

theorem core_rwOut_eq_isa_write (ins : Env) (i : Instr) (r : Fin 32)
    (hd : decode (seenWord ins) = some i) (hmem : touchesMem i = false) :
    run ins core.gates (rwOut r.val)
      = (decide (writesReg i = some r) && !(r.val == 0)) := by
  cases i with
  | ADD rd x y =>
      rw [core_rwOut_sweep_ADD ins rd x y r.val r.isLt hd]
      by_cases hrr : rd = r
      · subst hrr; simp [writesReg]
      · have : ¬ (rd.val = r.val) := fun hh => hrr (Fin.ext hh)
        simp [writesReg, hrr, this]
  | XOR rd x y =>
      rw [core_rwOut_sweep_XOR ins rd x y r.val r.isLt hd]
      by_cases hrr : rd = r
      · subst hrr; simp [writesReg]
      · have : ¬ (rd.val = r.val) := fun hh => hrr (Fin.ext hh)
        simp [writesReg, hrr, this]
  | SLT rd x y =>
      rw [core_rwOut_sweep_SLT ins rd x y r.val r.isLt hd]
      by_cases hrr : rd = r
      · subst hrr; simp [writesReg]
      · have : ¬ (rd.val = r.val) := fun hh => hrr (Fin.ext hh)
        simp [writesReg, hrr, this]
  | ADDI rd x im =>
      rw [core_rwOut_sweep_ADDI ins rd x im r.val r.isLt hd]
      by_cases hrr : rd = r
      · subst hrr; simp [writesReg]
      · have : ¬ (rd.val = r.val) := fun hh => hrr (Fin.ext hh)
        simp [writesReg, hrr, this]
  | BEQ x y im =>
      rw [core_rwOut_sweep_BEQ ins x y im r.val r.isLt hd]
      simp [writesReg]
  | LW rd x im => simp [touchesMem] at hmem
  | SW x y im => simp [touchesMem] at hmem

theorem core_rwOut_true_iff_isa_writes (ins : Env) (i : Instr) (r : Fin 32)
    (hd : decode (seenWord ins) = some i) (hmem : touchesMem i = false) :
    run ins core.gates (rwOut r.val) = true ↔ (writesReg i = some r ∧ r.val ≠ 0) := by
  rw [core_rwOut_eq_isa_write ins i r hd hmem]
  constructor
  · intro hh
    have h1 := (Bool.and_eq_true _ _).mp hh
    exact ⟨of_decide_eq_true h1.1, by simpa using h1.2⟩
  · intro hh
    simp [hh.1, hh.2]

/-! ### Step 5 — WHAT THE ENABLE HALF BUYS: `RegDatapathOK` collapses to the VALUE at `rd`. -/

theorem regDatapath_enable_arm (ins : Env) (i : Instr) (r : Fin 32) (k : Nat) (hk : k < 32)
    (hd : decode (seenWord ins) = some i) (hmem : touchesMem i = false)
    (hval : writesReg i = some r → r.val ≠ 0 →
      run ins core.gates (selOut k)
        = ((stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := by
  by_cases hz : r.val = 0
  · have hr0 : r = (0 : Fin 32) := Fin.ext (by simpa using hz)
    subst hr0
    exact regDatapath_holds_at_zero ins k hk
  · by_cases he : run ins core.gates (rwOut r.val) = true
    · rw [if_pos he]
      have hx := (core_rwOut_true_iff_isa_writes ins i r hd hmem).mp he
      exact hval hx.1 hx.2
    · have hef : run ins core.gates (rwOut r.val) = false := by simpa using he
      have hnw : ∀ j, decode (seenWord ins) = some j → writesReg j ≠ some r := by
        intro j hj hw
        have hji : i = j := by rw [hd] at hj; exact Option.some.inj hj
        have hw' : writesReg i = some r := by rw [hji]; exact hw
        have hcon := (core_rwOut_true_iff_isa_writes ins i r hd hmem).mpr ⟨hw', hz⟩
        rw [hef] at hcon
        exact Bool.noConfusion hcon
      exact regDatapath_hold_arm ins r k hk hef hnw


/-! ### Step 6 — THE EXACTLY-ONE FORM, and P5 through the whole core. -/

/-- The enable is high at `rd` and NOWHERE ELSE — the "exactly one" statement the sweep
is really making, spelled out over all thirty-two registers. -/
theorem core_rwOut_exactly_one_ADD (ins : Env) (rd a b : Fin 32) (hrd : rd.val ≠ 0)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    run ins core.gates (rwOut rd.val) = true
      ∧ ∀ r, r < 32 → r ≠ rd.val → run ins core.gates (rwOut r) = false := by
  constructor
  · rw [core_rwOut_sweep_ADD ins rd a b rd.val rd.isLt h]; simp [hrd]
  · intro r hr hne
    rw [core_rwOut_sweep_ADD ins rd a b r hr h]
    have hbe : (rd.val == r) = false := by
      cases hcmp : rd.val == r
      · rfl
      · exact absurd (eq_of_beq hcmp).symm hne
    rw [hbe, Bool.false_and]

/-- **P5 THROUGH THE WHOLE CORE, ON THE ARITHMETIC CLASS.** `ADD x0, a, b` enables NO
register — the `x0` write port that is not there, seen from the assembled machine rather
than from `regWrite` alone. -/
theorem core_writes_nothing_on_ADD_x0 (ins : Env) (a b : Fin 32) (r : Nat) (hr : r < 32)
    (h : decode (seenWord ins) = some (.ADD 0 a b)) :
    run ins core.gates (rwOut r) = false := by
  rw [core_rwOut_sweep_ADD ins 0 a b r hr h, show (0 : Fin 32).val = 0 from rfl]
  cases r with
  | zero => rfl
  | succ n => rfl

/-! ### Step 7 — NON-VACUITY: the hypothesis is SATISFIED by a real instruction word. -/

def wADD : BitVec 32 := encode (Instr.ADD 1 2 0)
def sADD : Nat := wADD.toNat * 2 ^ 1056
def insADD : Env := fun n => sADD.testBit n

theorem seen_insADD : seenWord insADD = wADD := by decide +kernel

theorem dec_insADD : decode (seenWord insADD) = some (Instr.ADD 1 2 0) := by
  rw [seen_insADD]; exact decode_encode _

/-- ⭐ **THE SWEEP IS NOT VACUOUS AND IT DISCRIMINATES.** On a real `ADD x1, x2, x0` word the
same theorem yields `true` at register 1 and `false` at 0 and at 2 — *derived symbolically
from the sweep, with no gate evaluated.* -/
theorem sweep_discriminates_on_a_real_ADD :
    run insADD core.gates (rwOut 1) = true
      ∧ run insADD core.gates (rwOut 0) = false
      ∧ run insADD core.gates (rwOut 2) = false := by
  refine ⟨?_, ?_, ?_⟩
  · rw [core_rwOut_sweep_ADD insADD 1 2 0 1 (by omega) dec_insADD]; decide
  · rw [core_rwOut_sweep_ADD insADD 1 2 0 0 (by omega) dec_insADD]; decide
  · rw [core_rwOut_sweep_ADD insADD 1 2 0 2 (by omega) dec_insADD]; decide

#audit_axioms core_rwOut_exactly_one_ADD
#audit_axioms core_writes_nothing_on_ADD_x0
#audit_axioms seen_insADD
#audit_axioms dec_insADD
#audit_axioms sweep_discriminates_on_a_real_ADD

#audit_axioms Shared.rdOf_is_decode_field
#audit_axioms rdOf_eq_toReg
#audit_axioms rdOf_eq_of_rd
#audit_axioms Shared.decode_add_rd
#audit_axioms decode_xor_rd
#audit_axioms decode_slt_rd
#audit_axioms decode_addi_rd
#audit_axioms core_rwOut_sweep_ADD
#audit_axioms core_rwOut_sweep_XOR
#audit_axioms core_rwOut_sweep_SLT
#audit_axioms core_rwOut_sweep_ADDI
#audit_axioms core_rwOut_sweep_BEQ
#audit_axioms core_rwOut_eq_isa_write
#audit_axioms core_rwOut_true_iff_isa_writes
#audit_axioms regDatapath_enable_arm

end SaltWorks.HDL.RegNextUniform.Writers

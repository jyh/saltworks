/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The `SW` witness — a refutation, and the repair that retired it

⭐⭐⭐ **THIS FILE ONCE PROVED `¬ C4Spec core`. IT NO LONGER CAN, AND THAT IS THE POINT.**
On 2026-08-19 it carried, in the kernel:

```
  regDatapathOK_is_false      : ¬ RegDatapathOK                       -- PROVED
  regField_core_four_is_false : ¬ RegField core ⟨4,_⟩                 -- PROVED
  c4Spec_core_is_false        : ¬ C4Spec core                         -- PROVED
```

against `core` **as it was assembled that morning**, with the witness `SW x1, x2, 4`: the
store's `imm[4:0]` is `4`, the enable read bits 7…11 as an `rd`, so the circuit write-enabled
register 4 while the ISA held it. Its own docstring said those were DIFFERENTIAL receipts and
that **a repair leaving them compiling had not been made.**

⇒ ***THE REPAIR WAS MADE, AND THEY STOPPED COMPILING.*** `regWrite`'s enable now reads
`writes = isADD ∨ isXOR ∨ isSLT ∨ isADDI ∨ isLW`, which the `SW` row does not raise. **What
survives here is the same witness, evaluated the same way, reporting the opposite answer** —
`witness_no_longer_enables` below. *A refutation that dies to a repair is the only kind worth
landing, and it is kept rather than deleted so the next reader can see BOTH halves.*

⛔⛔⛔ **AND `C4Spec core` IS REFUTED AGAIN — TWICE OVER, BY TWO DISJOINT MECHANISMS THAT HAVE
NOTHING TO DO WITH STORES.** The `SW` repair closed one row; it did not close the obligation.
Both new refutations live at the foot of this file:

⛔⛔⛔ ***↑ THAT PARAGRAPH IS RETIRED. BOTH OF THOSE REFUTATIONS ARE DEAD — read the 2026-08-29
block below before you use anything in the two bullets.*** It is kept verbatim because it was
true when written and it is the before-state of the differential this file exists to carry.

* **`ADDI` — `core` HAS NO I-TYPE IMMEDIATE.** `CorePlace.obSig` feeds the ALU's operand-B
  *"immediate"* bank from `immOut`, and `immOut` is `immBCirc` — the **B-type BRANCH
  DISPLACEMENT**. `immICirc` exists and is certified (`Immediate.immI_correct`) and is **placed
  nowhere**. ✅ **REPAIRED 2026-08-20** — the σ now reads `instrNet (immI ·)`; `sel0_insI`
  flipped from `false` to `true` at the unchanged witness, and `addi_sides_agree` replaced the
  refutation. ⚠️ **`c4Spec_core_is_false` was RE-ROUTED through the LOAD, not deleted.**
* **`LW` — the enable fires and `core` HAS NO MEMORY.** `decQ` builds
  `mem := Vector.replicate 8 0`, so the ISA writes the CONSTANT `0` on a non-trapping load.
  ⇒ `regDatapathOK_is_false_on_LW_either_way`, proved by CASE-SPLITTING on the enable rather
  than evaluating it — **no write-enable choice repairs a load.**
  ⛔ **RETIRED 2026-08-29 — that theorem no longer exists.** The enable still fires, but the
  select bank now delivers what the ISA demands, so the case split has no contradiction to find.
  ⚠️ *The reason is NOT that the load was repaired: `decQ` still has no memory.* See below.

⛔⛔⛔ **RETIRED 2026-08-29 — BOTH REFUTATIONS ABOVE ARE DEAD, AND THE SECOND ONE DIED IN THIS
COMMIT.** Council 08/29, item (f), option ③ (bus offset `28710859`). The ruled sentence, verbatim:

> **the Lean model moved to match the die; the RTL was right throughout**

Leg ① wired `CorePlace.obSig`'s operand-B immediate bank through the PLACED immediate mux
(stage 2a `38729e9` placed the organs, stage 2b `79c6f04` wired them). At the unchanged `LW`
witness `insL` the select bank flipped from `true` to `false` — **and `false` is what the ISA
demands.** `sel2_insL` below is the same measurement, restated to the answer it now gives, and
the five declarations that stood on its `true` are retired at the point where they stood.

⛔⛔ **A DEAD WITNESS IS NOT A PROOF THAT `C4Spec core` IS TRUE.** This file no longer refutes the
flagship; it does not assert it either, and nothing here should be read as evidence for it. The
spec's status is **OPEN**, and the C4Spec proof attempt (Sept 4–5) *is* the search — the council
ruled out a replacement-witness hunt explicitly, so no one went looking for one.

⚠️ **AND THE PRE-REGISTRATION FIRED IN ITS WARNING ARM, WHICH IS WHY THIS IS RECORDED AND NOT
TIDIED.** `docs/Q6-DIFFERENTIAL-PREREGISTRATION.md` fixed the verdict for
`c4Spec_core_is_false` before the evidence existed: *MUST BREAK — but ONLY AFTER the load is
repaired*, because *"if it breaks while the load is still wrong, a refutation was lost without a
proof being gained."* **The load is still wrong** — `decQ`'s memory is still the all-zero vector
and the D swap has not happened. So this is exactly the warned case, named by its own bar: a
refutation lost, no proof gained. That is a real debit and it is written here rather than in a
commit message nobody re-reads.

📌 What survives untouched, and it is the load half: `lw_forces_false_whatever_the_enable_does`
and `datapath_forces_zero_select_on_LW` never carried a witness — they say what a CORRECT core
must satisfy on a load, and they still say it. The 31 `RegField` rows still need `selOut`'s VALUE
against the ISA result.

⚠️ The packed evaluator this file introduced now lives in `Sem.lean` (`runB`/`semB` with
`runB_eq`/`semB_eq`), lifted there so every organ certificate can use it. The local copies are
gone; a duplicate under a second qualified name is exactly the hazard this seat banked.
-/
import SaltWorks.HDL.DecoderTransport

namespace SaltWorks.HDL.C4Refuted
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.HDL.RegNextUniform

set_option maxHeartbeats 4000000

/-! ## The witness environment, presented as a packed `Nat`. -/

/-- `SW x1, x2, 4` = `2138659#32`. -/
def wSW : BitVec 32 := encode (.SW 1 2 4)

/-- Register 4 bit 0 (net 128) set; pc = 0; the word at nets 1056…1087. -/
def s0 : Nat := 2 ^ 128 ||| (2138659 * 2 ^ 1056)

def ins0 : Env := fun n => s0.testBit n

theorem seen_ins0 : seenWord ins0 = wSW := by decide +kernel
theorem rd_ins0 : rdOf ins0 = 4 := by decide +kernel
theorem held_ins0 : ins0 (32 * rdOf ins0 + 0) = true := by rw [rd_ins0]; decide +kernel

/-! ## The packed evaluation (STRICT: the kernel forces every one of the 10496 gates). -/

/-- ⭐ **THE PACKED WITNESS** — every one of `core`'s 10496 gates evaluated by the kernel.
⚠️ **Both the count and the net moved with leg ① stage 2a (2026-08-28): two organs entered
the chain, so every net from `offOb` on shifted by 98. Read off the artifact, not computed:
`core.gates.length = placedGateTotal = 10496`, kernel-checked, and `selOut 0 = 7773`.** -/
theorem bFull : (runB s0 core.gates).testBit 7773 = false := by decide +kernel

theorem selOut0_net : selOut 0 = 7773 := by decide +kernel

theorem dec_ins0 : decode (seenWord ins0) = some (.SW 1 2 4) := by
  rw [seen_ins0]; exact decode_encode _

theorem rdOf_ins0_ne_zero : ¬ (rdOf ins0 = 0) := by rw [rd_ins0]; decide

/-- ⭐⭐⭐ **THE REPAIR, AT THE EXACT WITNESS THAT REFUTED THE FLAGSHIP.** Same environment,
same gate list, same packed evaluator — and the enable that used to be `true` is now `false`.

⛔ **THIS IS THE DIFFERENTIAL IN ONE LINE.** Before the repair this seat proved
`run ins0 core.gates (rwOut 4) = true` here (`control_packed_true`); the store's immediate bits
selected register 4 and the circuit clobbered it. **The same expression is now `false`, and
nothing about the witness changed.** -/
theorem witness_no_longer_enables : run ins0 core.gates (rwOut 4) = false :=
  (runB_eq core.gates s0 (rwOut 4)).symm.trans (by decide +kernel)

/-- **AND SYMBOLICALLY, WITHOUT EVALUATING A GATE** — `core_writes_nothing_on_SW` says it for
every register on any store; this instantiates it at the witness, so the packed evaluation and
the symbolic proof are checked against each other exactly as they were before the repair. -/
theorem witness_no_longer_enables_symbolic :
    run ins0 core.gates (rwOut (rdOf ins0)) = false :=
  core_writes_nothing_on_SW ins0 (rdOf ins0) (rdOf_lt ins0) 1 2 4 dec_ins0

theorem witness_same_net :
    run ins0 core.gates (rwOut 4) = run ins0 core.gates (rwOut (rdOf ins0)) := by
  rw [rd_ins0]

/-- **THE ISA STILL WRITES NOTHING ON A STORE** — unchanged by the repair, and the half that
was never in doubt. Both sides now agree, which is what `RegDatapathOK` asks for at this
register. -/
theorem isa_writes_nothing_on_SW (a b : Fin 32) (imm : BitVec 12) :
    writesReg (.SW a b imm) = none := rfl

/-! ## ⛔⛔ TWO FURTHER REFUTATIONS — NEITHER IS ABOUT STORES

Found 2026-08-19 ~18:2x while scouting the `selOut` VALUE campaign, i.e. by asking what would
BREAK the campaign before spending on it. Both were handed to skeptics instructed to refute
them; neither was refuted. **They are independent of each other and of the `SW` repair.** -/

def r1 : Fin 32 := ⟨1, by decide⟩

/-! ## IDENTITY — the `RegDatapathOK` refuted below is the one the flagship rests on. -/

theorem identity_it_is_the_flagship :
    RegDatapathOK → SaltWorks.Stack.Program.PcField core → SaltWorks.HDL.C4Spec core :=
  c4Spec_core_of_datapath_and_pc

/-! ## NEGATIVE CONTROL — the instrument can report AGREEMENT.
`ADD x1, x2, x0` with `x2 = 1` (net 64). -/

def wC : BitVec 32 := encode (Instr.ADD 1 2 0)
def sC : Nat := 2 ^ 64 ||| (wC.toNat * 2 ^ 1056)
def insC : Env := fun n => sC.testBit n

theorem ctl_enable : run insC core.gates (rwOut r1.val) = true :=
  (runB_eq core.gates sC (rwOut r1.val)).symm.trans (by decide +kernel)

theorem ctl_sel0 : run insC core.gates (selOut 0) = true :=
  (runB_eq core.gates sC (selOut 0)).symm.trans (by decide +kernel)

theorem ctl_isa : ((stepT (decQ insC) (seenWord insC)).regs[r1.val]).getLsbD 0 = true := by
  decide +kernel

/-- ✅ THE CONTROL: at this witness the two sides of `RegDatapathOK` AGREE. -/
theorem control_sides_agree :
    (if run insC core.gates (rwOut r1.val) then run insC core.gates (selOut 0)
     else insC (32 * r1.val + 0))
      = ((stepT (decQ insC) (seenWord insC)).regs[r1.val]).getLsbD 0 := by
  rw [ctl_enable, if_pos rfl, ctl_sel0, ctl_isa]

/-! ## DEFECT 1 — ADDI.  `ADDI x1, x0, 1` on an ALL-ZERO register file and pc. -/

def wI : BitVec 32 := encode (Instr.ADDI 1 0 1)
def sI : Nat := wI.toNat * 2 ^ 1056
def insI : Env := fun n => sI.testBit n

theorem seen_insI : seenWord insI = wI := by decide +kernel

theorem dec_insI : decode (seenWord insI) = some (Instr.ADDI 1 0 1) := by
  rw [seen_insI]; exact decode_encode _

/-- The witness carries NO state: every register and the pc are zero. -/
theorem insI_state_is_zero : ∀ n, n < 1056 → insI n = false := by decide +kernel

theorem enable_insI : run insI core.gates (rwOut r1.val) = true :=
  (runB_eq core.gates sI (rwOut r1.val)).symm.trans (by decide +kernel)

/-- `useImm = isADDI` is HIGH, so `sem_obMux` says the bank delivered IS the immediate bank —
the disagreement cannot be blamed on `rs2` or on mux polarity. -/
theorem useImm_high_insI : run insI core.gates (decOut isADDILine) = true :=
  (runB_eq core.gates sI (decOut isADDILine)).symm.trans (by decide +kernel)

/-- ⭐⭐⭐ **THE `ADDI` REPAIR'S RECEIPT — SAME WITNESS, OPPOSITE ANSWER.**

⛔ **THIS THEOREM READ `= false` UNTIL 2026-08-20 and that was the defect:** `obSig`'s operand-B
"immediate" bank was `immBCirc`, the B-type BRANCH displacement, whose bit 0 is a STRUCTURAL
ZERO — so `core` could never write an ODD value with `ADDI`, for any immediate. The σ now reads
`instrNet (immI ·)`, and on `ADDI x1, x0, 1` the core writes `0 + 1 = 1`, whose bit 0 is `true`.

**Nothing about the witness changed. The environment, the gate list and the packed evaluator
are the ones that proved `false` an hour ago.** -/
theorem sel0_insI : run insI core.gates (selOut 0) = true :=
  (runB_eq core.gates sI (selOut 0)).symm.trans (by decide +kernel)

/-- …while the ISA writes `0 + 1 = 1`, whose bit 0 is `true`. -/
theorem isa_insI : ((stepT (decQ insI) (seenWord insI)).regs[r1.val]).getLsbD 0 = true := by
  decide +kernel

/-- ⭐⭐ **AND THE TWO SIDES NOW AGREE AT THIS WITNESS.** `regDatapathOK_is_false_on_ADDI` stood
here and is GONE: it was provable before the repair and is false after it. This is what replaced
it — the same instance of `RegDatapathOK`, now an equality rather than a contradiction.
⛔ **DO NOT READ THIS AS THE OBLIGATION HOLDING.** It is ONE point of a `∀`. `RegDatapathOK` is
still refuted, by the LOAD, below. -/
theorem addi_sides_agree :
    (if run insI core.gates (rwOut r1.val) then run insI core.gates (selOut 0)
     else insI (32 * r1.val + 0))
      = ((stepT (decQ insI) (seenWord insI)).regs[r1.val]).getLsbD 0 := by
  rw [enable_insI, if_pos rfl, sel0_insI, isa_insI]

/-! ### Escalation — now carried by the LOAD, which the ADDI repair does not touch. -/

theorem isa_insI_prog :
    ((stepT (decQ insI) (SaltWorks.Stack.Program.seenWord insI)).regs[r1.val]).getLsbD 0
      = true := isa_insI


/-! ## DEFECT 2 — LW.  THE GENERAL REASON, NO WITNESS, NO EVALUATION. -/

theorem decQ_mem (ins : Env) : (decQ ins).mem = Vector.replicate 8 0 := rfl

/-- A non-trapping `LW` out of an all-zero memory writes the CONSTANT `0`. -/
theorem step_lw_writes_zero (s : St) (rd a : Fin 32) (imm : BitVec 12) (hrd : rd ≠ 0)
    (hmem : s.mem = Vector.replicate 8 0)
    (hok : addrClass (s.get a + imm.signExtend 32) = .ok) :
    (step s (.LW rd a imm)).regs[rd.val] = 0 := by
  simp [step, hok, St.next, St.set, hrd, hmem]

/-- A TRAPPING `LW` writes NOTHING — the register holds. -/
theorem step_lw_trap_holds (s : St) (rd a : Fin 32) (imm : BitVec 12)
    (hbad : ¬ (addrClass (s.get a + imm.signExtend 32) = .ok)) :
    (step s (.LW rd a imm)).regs[rd.val] = s.regs[rd.val] := by
  simp [step, hbad, St.next]

theorem stepT_lw_writes_zero (ins : Env) (rd a : Fin 32) (imm : BitVec 12) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.LW rd a imm))
    (hok : addrClass ((decQ ins).get a + imm.signExtend 32) = .ok) :
    (stepT (decQ ins) (seenWord ins)).regs[rd.val] = 0 := by
  rw [stepT_compat (decQ ins) (seenWord ins) (step (decQ ins) (.LW rd a imm))
        (by simp [stepW, h])]
  exact step_lw_writes_zero _ rd a imm hrd (decQ_mem ins) hok

/-- ⭐⭐⭐ **THE LW DILEMMA, HORN 1 — THE ENABLE IS NOT A FREE PARAMETER.**
If `RegDatapathOK` held, then on EVERY decodable non-trapping `LW` with `rd ≠ 0` the bit the
obligation observes must be `false` — **whichever branch of the write-enable is taken.**
So the enable choice cannot rescue the load: the `then` branch demands a constant-zero result
datapath, and the `else` branch demands that the destination register already held zero. -/
theorem lw_forces_false_whatever_the_enable_does (h : RegDatapathOK) (ins : Env)
    (rd a : Fin 32) (imm : BitVec 12) (hrd : rd ≠ 0)
    (hdec : decode (seenWord ins) = some (.LW rd a imm))
    (hok : addrClass ((decQ ins).get a + imm.signExtend 32) = .ok)
    (k : Nat) (hk : k < 32) :
    (if run ins core.gates (rwOut rd.val) then run ins core.gates (selOut k)
     else ins (32 * rd.val + k)) = false := by
  rw [h ins rd k hk, stepT_lw_writes_zero ins rd a imm hrd hdec hok]
  simp

/-! ### HORN 2 — ⛔ **RETIRED 2026-08-29.** It read *"a concrete load where BOTH candidate
left-hand sides are wrong"*, and that is no longer so: the `then` side now agrees with the ISA.
The environment is UNCHANGED and kept — it is the fixture the differential is read on.
`LW x1, x2, 4` with `x2 = 4` (net 66) AND `x1` already holding bit 2 (net 34). -/

def wL : BitVec 32 := encode (.LW 1 2 4)
def sL : Nat := 2 ^ 66 ||| 2 ^ 34 ||| (wL.toNat * 2 ^ 1056)
def insL : Env := fun n => sL.testBit n

theorem seen_insL : seenWord insL = wL := by decide +kernel

theorem dec_insL : decode (seenWord insL) = some (Instr.LW 1 2 4) := by
  rw [seen_insL]; exact decode_encode _

/-- ⭐⭐⭐ **THE DIFFERENTIAL, IN ONE LINE — SAME WITNESS, OPPOSITE ANSWER.**

⛔ **THIS THEOREM READ `= true` UNTIL 2026-08-29**, and everything the file proved about the load
stood on that `true`. The docstring then said *"the circuit's select bank says `true` (the adder
returns `x2 + x4 = 4`)"*. Leg ① wired the operand-B immediate bank through the placed immediate
mux; the same environment, the same gate list and the same packed evaluator now answer `false`.

**Nothing about the witness changed.** `sL`, `insL`, `wL` are byte-for-byte the ones that proved
`true`. It is RESTATED rather than deleted, because a deleted control leaves no trace and this
one is the whole receipt.

📌 **THE FLIP IS DATED TO STAGE 2b, MEASURED AT BOTH ENDS.** At `38729e9` (stage 2a: organs
PLACED, nothing wired) the `= true` form was **kernel-clean, 0 errors** — the refutation was
still alive there, so retiring it on that commit would have retired a TRUE theorem. At `79c6f04`
(stage 2b: `obSig` wired through `immMuxOut`/`selOrOut`) it carries `sorryAx`. *Stage 2a moved
nets and no values; stage 2b moved the value.* -/
theorem sel2_insL : run insL core.gates (selOut 2) = false :=
  (runB_eq core.gates sL (selOut 2)).symm.trans (by decide +kernel)

/-- ⛔ **AND THE ENABLE FIRES** — so the `then` branch is the LIVE one and `sel2_insL` is the
value the obligation actually observes here. Without this, "the sides agree" would be a claim
about a branch nothing takes. -/
theorem rw_insL : run insL core.gates (rwOut r1.val) = true :=
  (runB_eq core.gates sL (rwOut r1.val)).symm.trans (by decide +kernel)

/-- The HELD state bit — what the `else` branch WOULD return — is `true`.
⚠️ **The word "ALSO" stood here until 2026-08-29 and pointed at `sel2_insL`'s `true`, which is
gone.** The `else` branch is not the live one: `rw_insL` shows the enable FIRES, so this bit is
not what the obligation observes at this fixture. -/
theorem held_insL : insL (32 * r1.val + 2) = true := by decide +kernel

/-- The ISA demands `false`: the load's source is `decQ`'s all-zero memory. -/
theorem isa_insL : ((stepT (decQ insL) (seenWord insL)).regs[r1.val]).getLsbD 2 = false := by
  decide +kernel


theorem isa_insL_prog :
    ((stepT (decQ insL) (SaltWorks.Stack.Program.seenWord insL)).regs[r1.val]).getLsbD 2
      = false := isa_insL

/-! ### ⛔⛔⛔ THE RETIREMENT — FOUR DECLARATIONS STOOD HERE AND THEY ARE GONE, BY RULING

**Council 2026-08-29, item (f), option ③, bus offset `28710859`.** Retired at the point where
they stood, LOUDLY, with the date, the shas and the reason — *not* deleted quietly, because this
file's own opening warns that deleting a dead witness is how `C4Spec core` becomes **silently
unrefuted**, and a silent un-refutation is indistinguishable from a proof nobody wrote.

```
regField_core_one_is_false                ¬ RegField core r1          RETIRED 2026-08-29
c4Spec_core_is_false                      ¬ C4Spec core               RETIRED 2026-08-29  ⛔ THE FLAGSHIP
no_enable_repairs_the_load                ∃ … selOut k = true …       RETIRED 2026-08-29
regDatapathOK_is_false_on_LW_either_way   ¬ RegDatapathOK             RETIRED 2026-08-29
```

**WHY, IN ONE SENTENCE — the ruled wording, verbatim:**

> **the Lean model moved to match the die; the RTL was right throughout**

All four rested on `sel2_insL`'s `true`. Leg ① (`38729e9` placed the organs, `79c6f04` wired
them) routed operand B's immediate bank through the placed immediate mux, and at the UNCHANGED
witness the select bank now reads `false` — which is what the ISA demands. `lw_sides_agree_at_insL`
below is that agreement as a theorem, so the retirement leaves a STATEMENT and not an absence.

⛔⛔ **AND THE SENTENCE THAT MUST TRAVEL WITH IT: A DEAD WITNESS IS NOT A PROOF THAT `C4Spec core`
IS TRUE.** Nothing was proved here. `C4Spec core` is **OPEN**, not true and no longer refuted.
The Sept 4–5 proof attempt IS the search for its answer; the council ruled out hunting a
replacement witness, so nobody looked for one and this file makes no claim that none exists.

⚠️ **`docs/Q6-DIFFERENTIAL-PREREGISTRATION.md` PRE-REGISTERED THIS EXACT CASE AND CALLED IT A
LOSS:** `c4Spec_core_is_false` was to break *"ONLY AFTER the load is repaired"*, since breaking
it earlier means **"a refutation was lost without a proof being gained."** The load is NOT
repaired — `decQ`'s memory is still all-zero, the D swap has not run. ⇒ *This retirement lands on
the warned side of a bar this seat wrote before the evidence existed, and it is recorded as a
debit rather than as an achievement.*

📌 **A FIFTH DECLARATION DIES WITH THEM, IN ANOTHER FILE:** `EnableX0.on_target_case_is_false`
consumed `regDatapathOK_is_false_on_LW_either_way` and is retired in the same commit. It was not
on the ruling's list of four because the list was scoped to THIS file; a consumer in a second
module is invisible to a same-file count. -/

/-- ⭐⭐⭐ **THE POSITIVE TWIN — AT THE WITNESS THAT USED TO REFUTE, THE TWO SIDES NOW AGREE.**

This is `regDatapathOK_is_false_on_LW_either_way`'s replacement, in the idiom this file already
uses for a repaired row (`control_sides_agree`, `addi_sides_agree`): the same instance of
`RegDatapathOK`, now an equality rather than a contradiction.

⛔ **DO NOT READ THIS AS `RegDatapathOK` HOLDING.** It is ONE point of a `∀`, on ONE bit, at ONE
witness. It is a receipt that the old counterexample is gone, and nothing more. -/
theorem lw_sides_agree_at_insL :
    (if run insL core.gates (rwOut r1.val) then run insL core.gates (selOut 2)
     else insL (32 * r1.val + 2))
      = ((stepT (decQ insL) (seenWord insL)).regs[r1.val]).getLsbD 2 := by
  rw [rw_insL, if_pos rfl, sel2_insL, isa_insL]

/-- ⭐ **AND THE ACCEPTANCE TEST IS SATISFIED HERE.** `datapath_forces_zero_select_on_LW` (below,
UNTOUCHED and witness-free) says a correct core must drive `selOut k = false` on a non-trapping
load. At `insL` it now does. *The acceptance test did not move; the circuit moved onto it.* -/
theorem acceptance_test_holds_at_insL : run insL core.gates (selOut 2) = false := sel2_insL

/-- ⭐ THE ACCEPTANCE TEST for the "make the core write zero on loads" route: it says exactly
what a repaired core must satisfy, with no witness in it. -/
theorem datapath_forces_zero_select_on_LW (h : RegDatapathOK) (ins : Env)
    (rd a : Fin 32) (imm : BitVec 12) (hrd : rd ≠ 0)
    (hdec : decode (seenWord ins) = some (.LW rd a imm))
    (hok : addrClass ((decQ ins).get a + imm.signExtend 32) = .ok)
    (hen : run ins core.gates (rwOut rd.val) = true) (k : Nat) (hk : k < 32) :
    run ins core.gates (selOut k) = false := by
  have hx := h ins rd k hk
  rw [hen, stepT_lw_writes_zero ins rd a imm hrd hdec hok] at hx
  simpa using hx


/-! ### ⛔⭐⭐⭐ THE D REGIME — `C4SpecD core` IS REFUTED IN THE KERNEL, AND THE SPEC IS NOT EMPTY

math's `2026-08-23 10:30:24` length argument was published as prose over three source lines
and never landed as a theorem. It lands here, in the file that already carries
`c4Spec_core_is_false`, because this is where a refutation of `core` belongs.

⚠️ **BOTH HALVES ARE NEEDED AND ONLY ONE IS THE HEADLINE.** *"`C4SpecD core` is false"* is
worth nothing on its own — it is also true of a spec no circuit can meet, and a reader has
no way to tell those apart. So the satisfiability witness is landed BESIDE it. -/

/-- ✅ **A D-WIDTH SHAPE EXISTS — `C4SpecD`'s length conjunct is SATISFIABLE, not empty.**

⛔ *This is **NOT** `coreD` and must not be read as a step-7 candidate: it has no gates, it
implements no ISA step, and it computes nothing. It exists so that `outs.length = stWidthD`
is a hypothesis SOMETHING in `SaltWorks/` meets — math's 10:30 note recorded that the shape
appeared nowhere in the tree, and that absence is what made the refutation unreadable.* -/
def coreShapedD : Circ :=
  { nIn   := SaltWorks.HDL.StateCodecD.stWidthD + 32
    gates := []
    outs  := List.range SaltWorks.HDL.StateCodecD.stWidthD }

/-- The witness meets the count. -/
theorem coreShapedD_outs_length :
    coreShapedD.outs.length = SaltWorks.HDL.StateCodecD.stWidthD := by
  simp [coreShapedD]

/-- ⛔ **THE LANDED `core` HAS THE WRONG WIDTH FOR D.** `core_outs_length` pins the assembled
circuit at `stWidth`; the two widths differ, and the difference is decided by the kernel. -/
theorem core_outs_length_ne_stWidthD :
    core.outs.length ≠ SaltWorks.HDL.StateCodecD.stWidthD := by
  rw [core_outs_length]
  decide +kernel

/-- ⛔⭐⭐⭐ **`C4SpecD core` IS FALSE — A REFUTATION, NOT A GAP.**

`outs_length_of_C4SpecD` forces EVERY circuit satisfying `C4SpecD` to have `stWidthD`
outputs; `core_outs_length` pins the landed assembly at `stWidth`.  ⇒ *The extra state bits
are not merely unproven — they are **absent from the hardware**, and no re-typing, no
decoder migration and no codec edit can add them.  Closing this needs an assembly with more
output bits, which is silicon and not Lean.*

⭐ **AND IT IS NOT A VACUOUS VICTORY:** `coreShapedD_outs_length` exhibits a circuit that
DOES meet the count, so `C4SpecD` fails for `core` specifically rather than for everything. -/
theorem not_C4SpecD_core : ¬ SaltWorks.Stack.Program.C4SpecD core :=
  fun h => core_outs_length_ne_stWidthD
    (SaltWorks.Stack.Program.outs_length_of_C4SpecD h)

/-- ⛔ **AND THE SAME ARGUMENT KILLS THE WIDENING REPAIR BEFORE ANYONE ATTEMPTS IT.**
Any circuit satisfying `C4SpecD` fails `CoreConforms`, whose third conjunct is the C-width
count — so "just make `core` satisfy `C4SpecD`" cannot be done while `core` stays conforming.
*The two obligations are jointly unsatisfiable, which is a stronger statement than either
alone and is what makes step 7 a hardware change rather than a proof effort.* -/
theorem no_circuit_is_both_conforming_and_C4SpecD (c : Circ)
    (hconf : CoreConforms c) : ¬ SaltWorks.Stack.Program.C4SpecD c := by
  intro h
  have h1 : c.outs.length = stWidth := hconf.2.2
  have h2 : c.outs.length = SaltWorks.HDL.StateCodecD.stWidthD :=
    SaltWorks.Stack.Program.outs_length_of_C4SpecD h
  rw [h1] at h2
  exact absurd h2 (by decide +kernel)

#audit_axioms coreShapedD coreShapedD_outs_length
#audit_axioms core_outs_length_ne_stWidthD
#audit_axioms not_C4SpecD_core
#audit_axioms no_circuit_is_both_conforming_and_C4SpecD

#audit_axioms r1 identity_it_is_the_flagship
#audit_axioms wC sC insC ctl_enable ctl_sel0 ctl_isa control_sides_agree
#audit_axioms wI sI insI seen_insI dec_insI insI_state_is_zero enable_insI
#audit_axioms useImm_high_insI sel0_insI isa_insI addi_sides_agree
-- ⛔⛔ ONE NAME PER CALL, DELIBERATELY, FROM 2026-08-29. `#audit_axioms` ABORTS AT ITS FIRST
-- FAILURE, so every name after a failing one is NEVER CHECKED and its silence reads as a pass.
-- On 08-28 this file's multi-name calls reported THREE damaged declarations when the truth was
-- FIVE -- and the two they concealed were `c4Spec_core_is_false` itself and its LW dependent,
-- i.e. the abort hid exactly the two that mattered most. Splitting the calls costs nothing and
-- removes the concealment permanently. (the seat's audit-recovery tool, `auditreach.py`, recovers names from a log
-- when a multi-name call has already aborted; this makes that recovery unnecessary here.)
#audit_axioms isa_insI_prog
#audit_axioms decQ_mem
#audit_axioms step_lw_writes_zero
#audit_axioms step_lw_trap_holds
#audit_axioms stepT_lw_writes_zero
#audit_axioms lw_forces_false_whatever_the_enable_does
#audit_axioms wL
#audit_axioms sL
#audit_axioms insL
#audit_axioms seen_insL
#audit_axioms dec_insL
#audit_axioms sel2_insL
#audit_axioms rw_insL
#audit_axioms held_insL
#audit_axioms isa_insL
#audit_axioms lw_sides_agree_at_insL
#audit_axioms acceptance_test_holds_at_insL
#audit_axioms datapath_forces_zero_select_on_LW

#audit_axioms wSW s0 ins0 seen_ins0 rd_ins0 held_ins0
#audit_axioms dec_ins0 rdOf_ins0_ne_zero isa_writes_nothing_on_SW
#audit_axioms witness_no_longer_enables witness_no_longer_enables_symbolic witness_same_net

set_option pp.fullNames true in
#check @witness_no_longer_enables


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.C4Refuted.bFull SaltWorks.HDL.C4Refuted.isa_insL_prog
#audit_axioms SaltWorks.HDL.C4Refuted.selOut0_net
end SaltWorks.HDL.C4Refuted

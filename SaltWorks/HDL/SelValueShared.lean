/-
Q4 RESIDUE — THE ELEVEN DUPLICATED HELPERS, PROVED ONCE (executor scratch; the seat integrates).

`b64722e` landed seven class modules from a parallel fan-out.  Flattened into ONE namespace they
carry eleven bare-name collisions, because concurrent executors independently re-derived the same
`adder32`/`obMux` port plumbing, the same offset bounds, and the same `rd` decode bridge.  They are
landed under per-class leaves (`ADD`, `ADDI`, `XOR`, `Writers`, …) so nothing collides TODAY; the
REDUNDANCY is the debt.  This file is the proposed shared home.

⛔ THIS FILE EDITS NOTHING TRACKED.  It is `Scratch*`, gitignored, and it re-proves each helper in
one place; the deletions at the seven call sites are the seat's to make.

## WHAT THE COMPARISON FOUND — read this before integrating

Every one of the eleven was diffed COPY AGAINST COPY, whitespace-normalised, before a statement was
chosen here.  NINE are byte-identical in statement AND proof.  TWO differ, and neither difference
is a difference of STATEMENT:

* `tieFalse_lt_off0` — same statement, two proofs.  ADD's is `by decide +kernel`; ADDI's is
  `by rw [tie_nets_are_the_first_two.1, off0_value]; decide`.  ADD's is taken here: it depends on no
  intermediate value lemma.
* `coreThruRw_split5` — same statement modulo the LOCAL NAME of the rs2-inclusive prefix.  ADD calls
  it `cT5`, XOR calls it `coreThru5`, and the two `def`s have IDENTICAL bodies.  ⚠️ AND BOTH COPIES
  ARE ALREADY ALIASES: each is proved by the term `coreThruRw_split2`, which is LANDED in
  `Rs2Close` and states exactly this fact with the prefix written out.  So this row is not "prove it
  once" — it is "stop restating a landed lemma under a local name".  `Shared.coreThru5` below is the
  one prefix `def`; the theorem is the alias, kept only so that the ADD and XOR call sites can be
  repointed without rewriting their proof scripts.

## ⚠️ THREE THINGS THE ELEVEN-NAME CENSUS COULD NOT SEE (name-shaped census, statement-shaped debt)

1. `adder32_outs_len` IS ALREADY LANDED, byte-identical, at `SaltWorks.HDL.PortLengths.adder32_outs_len`
   (`PortLengths.lean:83`, same `by decide +kernel`).  The duplication is THREE-fold, not two.  It is
   re-proved here rather than imported only because `PortLengths` is NOT in any of the four call
   sites' import closures and pulling it in adds three modules (`PortLengths`, `PriorityEnc`,
   `Shifter`).  ⇒ SEAT'S CHOICE, and either way one of the two proofs should die.
2. `rdOf_is_decode_field` IS ALSO THREE-FOLD.  `EnableX0` carries the same statement with the same
   script under a DIFFERENT bare name, `X0.rdField_toNat` (`EnableX0.lean:71`).  A bare-name census
   cannot see it.  The eleven is therefore a LOWER BOUND on the duplication, not a count of it.
3. `decode_add_rd` IS SUBSUMED, and by something already landed: `X0.writesReg_is_rd_field`
   (`EnableX0.lean:100`) proves `rd = toReg (w.extractLsb' 7 5)` for EVERY class at once, from
   `writesReg i = some rd`.  It subsumes `decode_add_rd` here AND the four `decode_{add,xor,slt,addi}_rd`
   in `EnableWriters` — five declarations, one lemma.  It is NOT re-proved in this file, because
   re-proving a landed theorem is the exact sin under audit; the right move is for the seat to
   RE-HOME `writesReg_is_rd_field` out of the `X0` leaf into this shared module and derive the five.
   `decode_add_rd` is kept below at its EXACT landed shape so the ADD/Writers replacement stays
   textually exact and the re-homing can happen as a separate, independently-checkable step.

`obMux_outs_len` has a partial precedent too: `OperandB.exhibit_obMux` (`OperandBMux.lean:384`)
carries `obMux.outs.length = 32` as its fifth conjunct.  A named projection is still worth having;
noted so the seat knows the fact is not new, only unnamed.

## IMPORT — deliberately the SINGLE lowest edge that suffices

`import SaltWorks.HDL.Bridge3` alone.  Bridge3's transitive closure already contains `CorePlace`,
`Rs2Close` (`coreThruRw_split2`, `coreRest9`, `coreThru4`), `EnableSpec` (`rdOf`, `rdOf_lt`,
`rdOf_testBit`), `EnableArm` (`getD_map_lt`), `ISA`, `Stack.Program` and `Tactic.AuditAxioms` — and
Bridge3 is ALREADY in the import closure of all four call sites (ADD and Writers via `PcFieldClosed`,
ADDI via `Bridge4`, XOR directly).  ⇒ adopting this module adds ZERO new dependency edges anywhere.

## NAMESPACE

`SaltWorks.HDL.RegNextUniform.Shared`, a sibling leaf of `ADD`/`ADDI`/`XOR`/`Writers`, so the class
files repoint with `open SaltWorks.HDL.RegNextUniform.Shared` and no qualified name moves.

*Not C4, not a witness, closes no obligation.  This is a redundancy removal, and it proves nothing
that was not already proved — that is the point.*
-/
import SaltWorks.HDL.Bridge3

set_option maxRecDepth 100000

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

namespace Shared

/-! ## 1 · offset and net bounds
Replaces `ADD.addOut_lt_offSub` / `ADDI.addOut_lt_offSub` (identical) and
`ADD.tieFalse_lt_off0` / `ADDI.tieFalse_lt_off0` (identical statement, two proofs). -/

theorem addOut_lt_offSub (k : Nat) (hk : k < 32) : CorePlace.addOut k < offSub := by
  revert k; decide +kernel

theorem tieFalse_lt_off0 : tieFalse < off0 := by decide +kernel

/-! ## 2 · the rs2-inclusive prefix, and the split that is really `Rs2Close.coreThruRw_split2` -/

/-- The prefix up to and including the rs2 read port.  `ADD.cT5` and `XOR.coreThru5` are this `def`,
written twice with different names and identical bodies. -/
def coreThru5 : List Gate := coreThru4 ++ instGates readTree readTreeRs2Sig off3

/-- ⚠️ AN ALIAS, NOT A NEW FACT.  `Rs2Close.coreThruRw_split2` is the theorem; both landed copies of
`coreThruRw_split5` are this same term under a local prefix name. -/
theorem coreThruRw_split5 : coreThruRw = coreThru5 ++ coreRest9 := coreThruRw_split2

/-! ## 3 · the operand-B mux's ports
Replaces `ADD.{obMux_outs_len, obMux_out_mem, obOut_eq}` and `ADDI.{…}` — all three identical. -/

theorem obMux_outs_len : OperandB.obMux.outs.length = 32 := by decide +kernel

theorem obMux_out_mem (m : Nat) (hm : m < 32) :
    (OperandB.obMux.gates.map Gate.out).contains (OperandB.obMux.outs.getD m 0) = true := by
  revert m; decide +kernel

theorem obOut_eq (m : Nat) (hm : m < 32) :
    CorePlace.obOut m = instMap OperandB.obMux obSig offOb (OperandB.obMux.outs.getD m 0) := by
  rw [CorePlace.obOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [obMux_outs_len]; exact hm) 0 0

/-! ## 4 · the adder's ports
Replaces `ADD.{adder32_outs_len, adder32_out_mem, addOut_eq}` and `ADDI.{…}` — all three identical.
See finding ① in the header: `adder32_outs_len` is ALSO landed in `PortLengths`. -/

theorem adder32_outs_len : adder32.outs.length = 33 := by decide +kernel

theorem adder32_out_mem (k : Nat) (hk : k < 32) :
    (adder32.gates.map Gate.out).contains (adder32.outs.getD k 0) = true := by
  revert k; decide +kernel

theorem addOut_eq (k : Nat) (hk : k < 32) :
    CorePlace.addOut k = instMap adder32 addSig offAdd (adder32.outs.getD k 0) := by
  rw [CorePlace.addOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [adder32_outs_len]; omega) 0 0

/-! ## 5 · the `rd` bridge and its ISA side
Replaces `ADD.rdOf_is_decode_field` / `Writers.rdOf_is_decode_field` (identical) — and, per finding
② in the header, `X0.rdField_toNat`, which is the same statement under another name.
`decode_add_rd` replaces `ADD.decode_add_rd` / `Writers.decode_add_rd` (identical); per finding ③ it
is itself subsumed by the landed `X0.writesReg_is_rd_field`. -/

/-- ⭐ **BRIDGE (rd): the index the write port uses IS `decode`'s `rd` field.**
`Bridge3`'s proof at `15 ↦ 7`, against `rdOf_testBit` instead of `rs1AddrOf_testBit`. -/
theorem rdOf_is_decode_field (ins : Env) :
    ((seenWord ins).extractLsb' 7 5).toNat = rdOf ins := by
  have hb : ∀ j, j < 5 → ((seenWord ins).extractLsb' 7 5).getLsbD j = (rdOf ins).testBit j := by
    intro j hj
    rw [BitVec.getLsbD_extractLsb', seenWord_bit ins (7 + j) (by omega), rdOf_testBit ins j hj]
    simp [hj]
  refine Nat.eq_of_testBit_eq (fun j => ?_)
  by_cases hj : j < 5
  · exact hb j hj
  · have h1 : ((seenWord ins).extractLsb' 7 5).toNat < 32 := by
      have := ((seenWord ins).extractLsb' 7 5).isLt
      simpa using this
    have h2 : rdOf ins < 32 := rdOf_lt ins
    have hp : (32 : Nat) ≤ 2 ^ j := by
      calc (32 : Nat) = 2 ^ 5 := by norm_num
        _ ≤ 2 ^ j := Nat.pow_le_pow_right (by norm_num) (by omega)
    rw [Nat.testBit_eq_false_of_lt (by omega), Nat.testBit_eq_false_of_lt (by omega)]

theorem decode_add_rd (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.ADD rd a b)) :
    rd = toReg (w.extractLsb' 7 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

end Shared

/-! # CALL-SITE RECEIPTS — the criterion, pre-registered and machine-checked

⚠️ The brief's own warning: *a shared lemma that serves only one caller is worse than two honest
copies.*  So the test is not "does the shared statement look general", it is **can EACH original
call site's statement be discharged by the shared declaration ALONE, as a term, with no repair.**

Below, every one of the eleven appears TWICE — once at the ADD-side copy's statement, once at the
other copy's — and each is proved by nothing but the corresponding `Shared.…`.  A row that needed a
tactic to bridge the two would be a row where the merge is NOT exact; there are none.  For
`coreThruRw_split5` the two rows are stated over LOCAL prefix `def`s reproducing `ADD.cT5` and
`XOR.coreThru5` verbatim, which is exactly where a name-only difference would show up if it were
more than a name. -/

namespace CallsiteCheck

/-- `ADD.cT5`, reproduced verbatim. -/
def cT5 : List Gate := coreThru4 ++ instGates readTree readTreeRs2Sig off3
/-- `XOR.coreThru5`, reproduced verbatim. -/
def coreThru5 : List Gate := coreThru4 ++ instGates readTree readTreeRs2Sig off3

-- ① addOut_lt_offSub — SelValueADD:148 · SelValueADDI:170
theorem add_addOut_lt_offSub (k : Nat) (hk : k < 32) : CorePlace.addOut k < offSub :=
  Shared.addOut_lt_offSub k hk
theorem addi_addOut_lt_offSub (k : Nat) (hk : k < 32) : CorePlace.addOut k < offSub :=
  Shared.addOut_lt_offSub k hk

-- ② tieFalse_lt_off0 — SelValueADD:151 · SelValueADDI:164
theorem add_tieFalse_lt_off0 : tieFalse < off0 := Shared.tieFalse_lt_off0
theorem addi_tieFalse_lt_off0 : tieFalse < off0 := Shared.tieFalse_lt_off0

-- ③ coreThruRw_split5 — SelValueADD:98 (over `cT5`) · SelValueXOR:123 (over `coreThru5`)
theorem add_coreThruRw_split5 : coreThruRw = cT5 ++ coreRest9 := Shared.coreThruRw_split5
theorem xor_coreThruRw_split5 : coreThruRw = coreThru5 ++ coreRest9 := Shared.coreThruRw_split5

-- ④ obMux_outs_len — SelValueADD:294 · SelValueADDI:206
theorem add_obMux_outs_len : OperandB.obMux.outs.length = 32 := Shared.obMux_outs_len
theorem addi_obMux_outs_len : OperandB.obMux.outs.length = 32 := Shared.obMux_outs_len

-- ⑤ obMux_out_mem — SelValueADD:296 · SelValueADDI:208
theorem add_obMux_out_mem (m : Nat) (hm : m < 32) :
    (OperandB.obMux.gates.map Gate.out).contains (OperandB.obMux.outs.getD m 0) = true :=
  Shared.obMux_out_mem m hm
theorem addi_obMux_out_mem (m : Nat) (hm : m < 32) :
    (OperandB.obMux.gates.map Gate.out).contains (OperandB.obMux.outs.getD m 0) = true :=
  Shared.obMux_out_mem m hm

-- ⑥ obOut_eq — SelValueADD:300 · SelValueADDI:212
theorem add_obOut_eq (m : Nat) (hm : m < 32) :
    CorePlace.obOut m = instMap OperandB.obMux obSig offOb (OperandB.obMux.outs.getD m 0) :=
  Shared.obOut_eq m hm
theorem addi_obOut_eq (m : Nat) (hm : m < 32) :
    CorePlace.obOut m = instMap OperandB.obMux obSig offOb (OperandB.obMux.outs.getD m 0) :=
  Shared.obOut_eq m hm

-- ⑦ adder32_outs_len — SelValueADD:331 · SelValueADDI:261
theorem add_adder32_outs_len : adder32.outs.length = 33 := Shared.adder32_outs_len
theorem addi_adder32_outs_len : adder32.outs.length = 33 := Shared.adder32_outs_len

-- ⑧ adder32_out_mem — SelValueADD:333 · SelValueADDI:263
theorem add_adder32_out_mem (k : Nat) (hk : k < 32) :
    (adder32.gates.map Gate.out).contains (adder32.outs.getD k 0) = true :=
  Shared.adder32_out_mem k hk
theorem addi_adder32_out_mem (k : Nat) (hk : k < 32) :
    (adder32.gates.map Gate.out).contains (adder32.outs.getD k 0) = true :=
  Shared.adder32_out_mem k hk

-- ⑨ addOut_eq — SelValueADD:337 · SelValueADDI:272
theorem add_addOut_eq (k : Nat) (hk : k < 32) :
    CorePlace.addOut k = instMap adder32 addSig offAdd (adder32.outs.getD k 0) :=
  Shared.addOut_eq k hk
theorem addi_addOut_eq (k : Nat) (hk : k < 32) :
    CorePlace.addOut k = instMap adder32 addSig offAdd (adder32.outs.getD k 0) :=
  Shared.addOut_eq k hk

-- ⑩ rdOf_is_decode_field — SelValueADD:555 · EnableWriters:47 (· EnableX0:71 as `rdField_toNat`)
theorem add_rdOf_is_decode_field (ins : Env) :
    ((seenWord ins).extractLsb' 7 5).toNat = rdOf ins := Shared.rdOf_is_decode_field ins
theorem writers_rdOf_is_decode_field (ins : Env) :
    ((seenWord ins).extractLsb' 7 5).toNat = rdOf ins := Shared.rdOf_is_decode_field ins
theorem x0_rdField_toNat (ins : Env) :
    ((seenWord ins).extractLsb' 7 5).toNat = rdOf ins := Shared.rdOf_is_decode_field ins

-- ⑪ decode_add_rd — SelValueADD:573 · EnableWriters:78
theorem add_decode_add_rd (w : BitVec 32) (rd a b : Fin 32)
    (h : decode w = some (.ADD rd a b)) : rd = toReg (w.extractLsb' 7 5) :=
  Shared.decode_add_rd w rd a b h
theorem writers_decode_add_rd (w : BitVec 32) (rd a b : Fin 32)
    (h : decode w = some (.ADD rd a b)) : rd = toReg (w.extractLsb' 7 5) :=
  Shared.decode_add_rd w rd a b h

end CallsiteCheck

end SaltWorks.HDL.RegNextUniform

#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.addOut_lt_offSub
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.tieFalse_lt_off0
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.coreThruRw_split5
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.obMux_outs_len
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.obMux_out_mem
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.obOut_eq
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.adder32_outs_len
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.adder32_out_mem
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.addOut_eq
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.rdOf_is_decode_field
#audit_axioms SaltWorks.HDL.RegNextUniform.Shared.decode_add_rd
#audit_axioms SaltWorks.HDL.RegNextUniform.CallsiteCheck.add_coreThruRw_split5
#audit_axioms SaltWorks.HDL.RegNextUniform.CallsiteCheck.xor_coreThruRw_split5

/-
## RECEIPTS (executor, 2026-08-20)

* `../saltbuild.sh SaltWorks.HDL.ScratchQ4RDedupEx` — **saltbuild EXIT=0**, `Built` (not
  `Replayed`), 8.0s, 8641 jobs.  0 errors, 0 `sorryAx`.  559 warnings in the run, ALL from
  dependencies; **0 attributable to this file** (`grep 'warning:' | grep -c ScratchQ4RDedupEx` = 0).
* 13/13 `#audit_axioms` ticks, max `[3 axioms]`.  `#print axioms` on all thirteen:
  every closure is a subset of `[propext, Classical.choice, Quot.sound]` — `obMux_outs_len` and
  `adder32_outs_len` depend on NO axioms; `tieFalse_lt_off0`, `obMux_out_mem`, `adder32_out_mem`
  on `[propext]`; `decode_add_rd` on `[propext, Quot.sound]`; the rest on all three.
* ⭐ **THE RECEIPTS WERE CONTROLLED, NOT ASSUMED.**  A `CallsiteCheck` row proves an original
  statement by a shared lemma as a bare TERM, so it can only pass up to defeq — but "it compiled"
  is worthless unless the row can FAIL.  Two mutants were run against the built module, with the
  exit code and the message text predicted first:
    `coreThruRw = coreThru4 ++ coreRest9 := Shared.coreThruRw_split5`   (rs2 block dropped)
    `OperandB.obMux.outs.length = 33 := Shared.obMux_outs_len`          (port count off by one)
  Predicted EXIT=1 + `type mismatch` at both.  Observed **EXIT=1**, `Type mismatch` at both, each
  printing the shared lemma's true type against the mutated one.  ⇒ the twenty-four passing rows
  are evidence, not decoration.
-/

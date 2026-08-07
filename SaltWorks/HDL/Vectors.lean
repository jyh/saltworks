/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA

/-!
# C2 — the vector CONSUMER, and the cost measurement its design demands

`docs/hdl-c2-vector-design-0807.md` §3 fixed an obligation before any vectors
existed: *"`decide +kernel` cost on `St` equality has never been measured in this
fleet; the brief's 2.4 s figure was bare `decide`, which iron rule 6 bans. **Run
ten vectors, measure, then choose N.**"*

**This file is that measurement, and the machinery the generator will feed.**

## ⛔ WHAT THESE VECTORS ARE NOT

**They are hand-derived by the same seat that wrote `step`, so they are NOT a
witness and they carry NO independent evidence about the ISA.** *A vector I
computed from my own understanding cannot catch my own misunderstanding — that
is the entire reason council ruling 3 names Spike.*

⇒ **What they DO establish is the thing that was actually blocking: that the
consumer side works and what it costs.** When a witness exists, only the
generator is missing — the format, the checker and its price are settled here.
*Every one of these vectors is derived from a certificate already proved in
`ISA.lean` by `decide +kernel`, so they are known-good by construction and
useless as evidence, which is exactly the right property for a cost harness.*

## The format

Sparse on both sides, per the design: a dense 32-register pair is 2,048 bits per
vector and most of it is zeros that say nothing. **Sparse keeps the file readable
by a human adjudicating a disagreement, which is the point of a witness.**
-/

namespace SaltWorks.ISA

/-- A differential-test vector: the state before, the encoded instruction, and
the registers the step is expected to change. -/
structure Vec where
  /-- Non-zero registers before the step. -/
  pre   : List (Fin 32 × BitVec 32)
  pc    : BitVec 32
  /-- The ENCODED instruction word — what a third-party simulator consumes. -/
  word  : BitVec 32
  /-- Registers whose value differs after. -/
  post  : List (Fin 32 × BitVec 32)
  pc'   : BitVec 32

/-- Build a state from a sparse register list. -/
def ofSparse (rs : List (Fin 32 × BitVec 32)) (pc : BitVec 32) : St :=
  rs.foldl (fun s (r, v) => s.set r v) { St.init with pc := pc }

/-- The state a vector says we should reach. -/
def Vec.expected (v : Vec) : St := ofSparse (v.pre ++ v.post) v.pc'

/-- The state the spec actually reaches, going through `stepW` so the ENCODED
word is what drives it — the same surface a third-party simulator is fed. -/
def Vec.actual (v : Vec) : Option St := stepW (ofSparse v.pre v.pc) v.word

/-! ## The two candidate obligations, from the design's §3

The design chose FULL STATE and gave the reason: the observable check cannot see
`step` writing a register it should not have touched, and that is exactly the
class a differential test exists to find. Both are defined so the cost of the
choice is measurable rather than asserted. -/

/-- **FULL STATE** — the ruled obligation. Compares all 32 registers and the pc. -/
def Vec.checkFull (v : Vec) : Bool := v.actual == some v.expected

/-- **OBSERVABLE** — the cheaper alternative, kept only to price it. Checks the
pc and the registers the vector names, and is BLIND to a clobbered register. -/
def Vec.checkObs (v : Vec) : Bool :=
  match v.actual with
  | none => false
  | some s => s.pc == v.pc' && v.post.all (fun (r, x) => s.get r == x)

/-! ## The suite — every vector derived from a proved certificate in `ISA.lean` -/

/-- `ADDI x1, x0, -1` → `0xFFFFFFFF`. From `addi_sign_extends`. -/
def v_addi : Vec :=
  { pre := [], pc := 0, word := encode (.ADDI 1 0 (BitVec.ofInt 12 (-1))),
    post := [(1, 0xFFFFFFFF)], pc' := 4 }

/-- `ADD x3, x1, x2` with 20 + 22. From `run_executes`. -/
def v_add : Vec :=
  { pre := [(1, 20), (2, 22)], pc := 0, word := encode (.ADD 3 1 2),
    post := [(3, 42)], pc' := 4 }

/-- `SLT x3, x1, x2` with `-1 < 1` signed → 1. From `slt_is_signed`. -/
def v_slt : Vec :=
  { pre := [(1, 0xFFFFFFFF), (2, 1)], pc := 0, word := encode (.SLT 3 1 2),
    post := [(3, 1)], pc' := 4 }

/-- `SLT x3, x2, x1` — the other direction, → 0. From `slt_is_signed'`. -/
def v_slt' : Vec :=
  { pre := [(1, 0xFFFFFFFF), (2, 1)], pc := 0, word := encode (.SLT 3 2 1),
    post := [(3, 0)], pc' := 4 }

/-- `XOR x3, x1, x2`. -/
def v_xor : Vec :=
  { pre := [(1, 0xF0F0F0F0), (2, 0x0FF00FF0)], pc := 0, word := encode (.XOR 3 1 2),
    post := [(3, 0xFF00FF00)], pc' := 4 }

/-- `BEQ x0, x0, +4` — taken. From `beq_x0_x0_taken`. -/
def v_beq_taken : Vec :=
  { pre := [], pc := 0, word := encode (.BEQ 0 0 2), post := [], pc' := 4 }

/-- `BEQ x1, x0` with `x1 = 1` — NOT taken, falls through. From `beq_not_taken`. -/
def v_beq_not : Vec :=
  { pre := [(1, 1)], pc := 0, word := encode (.BEQ 1 0 2), post := [], pc' := 4 }

/-- A BACKWARD branch — representable, and the generator promises never to emit
one. From `beq_offset_can_be_negative`. -/
def v_beq_back : Vec :=
  { pre := [], pc := 8, word := encode (.BEQ 0 0 (BitVec.ofInt 12 (-2))),
    post := [], pc' := 4 }

/-- **`x0` AS DESTINATION — silicon's P5.** `ADD x0, x0, x1` must be a silent
no-op. *The design calls this the strongest single vector in the suite, because
it is where a plausible implementation goes wrong.* -/
def v_x0_dest : Vec :=
  { pre := [(1, 7)], pc := 0, word := encode (.ADD 0 0 1), post := [], pc' := 4 }

/-- **OVERFLOW WRAP** — the value domain that made C3 false before the retype.
`0x7FFFFFFF + 1` must wrap to `0x80000000`, not saturate. -/
def v_overflow : Vec :=
  { pre := [(1, 0x7FFFFFFF), (2, 1)], pc := 0, word := encode (.ADD 3 1 2),
    post := [(3, 0x80000000)], pc' := 4 }

/-- The ten. Every corner §5 of the design pre-registered is present. -/
def suite : List Vec :=
  [v_addi, v_add, v_slt, v_slt', v_xor, v_beq_taken, v_beq_not, v_beq_back,
   v_x0_dest, v_overflow]

/-! ## THE MEASUREMENT

`decide +kernel`, never bare `decide` — iron rule 6, and the reason the brief's
2.4 s figure could not be reused. -/

/-- **The full-state suite passes.** This is the cost datum: whatever this
`decide +kernel` costs for ten vectors is the price per ten, and N follows. -/
theorem suite_full : suite.all Vec.checkFull = true := by decide +kernel

/-- The observable check passes too — kept so the two prices are comparable. -/
theorem suite_obs : suite.all Vec.checkObs = true := by decide +kernel

/-- **NON-VACUITY.** A suite that passes because the checker always returns
`true` would be worthless, so a deliberately wrong vector must FAIL. `ADD x3,
x1, x2` with 20 + 22 claiming 43. -/
theorem checker_rejects_a_wrong_vector :
    Vec.checkFull { pre := [(1, 20), (2, 22)], pc := 0, word := encode (.ADD 3 1 2),
                    post := [(3, 43)], pc' := 4 } = false := by decide +kernel

/-- **AND THE OBSERVABLE CHECK IS BLIND WHERE THE FULL ONE IS NOT — measured,
not argued.** A vector whose `post` omits a register the step actually wrote:
`checkObs` passes it, `checkFull` rejects it. *This is the §3 decision, as a
theorem rather than a paragraph.* -/
theorem observable_is_blind_to_a_clobber :
    let bad : Vec := { pre := [(1, 20), (2, 22)], pc := 0,
                       word := encode (.ADD 3 1 2), post := [], pc' := 4 }
    Vec.checkObs bad = true ∧ Vec.checkFull bad = false := by decide +kernel

#audit_axioms ofSparse
#audit_axioms Vec.expected
#audit_axioms Vec.actual
#audit_axioms Vec.checkFull
#audit_axioms Vec.checkObs
#audit_axioms suite
#audit_axioms suite_full
#audit_axioms suite_obs
#audit_axioms checker_rejects_a_wrong_vector
#audit_axioms observable_is_blind_to_a_clobber

end SaltWorks.ISA

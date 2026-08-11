/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.RotationInvariant
import SaltWorks.HDL.PayloadL1

/-!
# COMPREHENSIBILITY CERTIFICATE — the 1990 switching network

Campaign: `docs/cert-layer-design-0811.md` (the fifth deliverable).
Source of the original claim: Marcus & Hickey, ISSCC 1990, WPM 2.4 —
**words-only citation, never the figures** (the standing 8/7 firewall).

Landed theorems certified here, by name:

| certificate | proved from | in |
| --- | --- | --- |
| `cert_full_circle` | `SaltWorks.HDL.rotate_full_circle` | `HDL/Rotation.lean` |
| `cert_address_restored_after_three_stages` | the above, at `k = 3` | — |
| `cert_stage_reads_original_bit` | `SaltWorks.HDL.stage_reads_original_bit` | `HDL/RotationInvariant.lean` |
| `cert_payload_delivery` | `L1Payload.l1_full_load_payload_delivery` | `HDL/PayloadL1.lean` |

## WHAT THE PAPER CLAIMS, quoted, and WHICH HALF THIS FILE CERTIFIES

The manuscript makes the 1990 claim three times; §4 is the sharpest form:

> "The 1990 switching-network theorem rides on the die: the routing schedule it
> certifies is proven in the kernel (the full rotation-closure result) and drives
> the taped-out switch."

⛔ **THIS CERTIFICATE COVERS THE CLAUSE "proven in the kernel (the full
rotation-closure result)" AND NOTHING ELSE IN THAT SENTENCE.** *"Rides on the
die" and "drives the taped-out switch" are claims about a netlist and a shuttle
submission. They are not Lean theorems, no proof below bears on them, and the
evidence for them lives in the silicon seat's flow records.* **The sentence
conjoins a KERNEL claim with a SILICON claim; a certificate that quietly covered
both would be exactly the upward lie iron rule 2 forbids.**

## WHAT THE THEOREMS SAY, in one sentence each

* **`cert_full_circle`** — a banyan cell routes on the first bit of the address
  and then moves that bit to the end. Do that once per stage, and after as many
  stages as the address has bits, the address is **back to exactly what it was**.
  That is the paper's own §3.2 sentence, and it is `rot^k = id`.
* **`cert_stage_reads_original_bit`** — the consequence that makes the trick
  useful: because the address rotates under it, **every cell reads its route bit
  in the same fixed position** (the head), and the bit sitting there at stage `m`
  is original address bit `k−1−m`. The cells are identical; the address does the
  work.
* **`cert_payload_delivery`** — the other half of the Batcher–banyan pair: after
  the six header cycles, the compare–exchange element carries the two payloads on
  its two output lines **ordered by destination**, one bit per cycle.

## ⚠️ TWO DEVICES, NOT ONE — and the certificate keeps them apart

The 1990 chipset is a **Batcher–banyan** switch: a sorting network followed by a
self-routing network. `cert_full_circle` and `cert_stage_reads_original_bit` are
about the **banyan** cell (self-routing on a rotating address). `cert_payload_
delivery` is about the **Batcher** compare–exchange element (sorting). They are
different devices with different proofs, grouped in one file because the campaign's
target list groups them. *A certificate that said "the switch" without saying which
half is which would have made the artifact harder to comprehend, not easier.*

## ⚠️ THE PREMISE IS OURS, NOT THE PAPER'S — and it is load-bearing

`hk : addr.length = k` is **this corpus's own identification**, stated as a
hypothesis rather than spent silently: *the paper indexes restoration by ADDRESS
LENGTH; the claim here is about STAGE COUNT.* Identifying the two is an assumption
about the fabric, so it rides in the certificate's statement as a hypothesis and in
this docstring as an English sentence. **It is not decorative**, and
`cert_length_premise_is_load_bearing` is the one-line proof: a 4-bit address does
**not** heal in 3 stages.

## SCOPE LIMITS carried from the landed theorems (nothing here is wider)

* **One-directional.** `cert_stage_reads_original_bit` states *stage `m` ⇒ the head
  is original bit `k−1−m`*, never the converse. Recovering `m` from a healed header
  is **unavailable, not merely unproved**: it would need the address bits to be
  duplicate-free, and a 3-bit list of booleans never is.
* **Validity antecedent.** The rotation-invariant results are about a *valid*
  packet (`v = true`); `addressBits` below is the valid case by construction. An
  idle line is covered elsewhere (`cell88_idle_is_silent`), not here.
* **`k = 3` where it appears** is the fabric's actual address width, not a
  simplification — but `cert_full_circle` itself is `∀ α` and `∀ k`, so the general
  statement is the one certified and `k = 3` is an instance of it.
* **`cert_payload_delivery` is the tapeout instance `P = 8`** — 6 header cycles +
  8 payload cycles. `∀ P` is not attempted anywhere in the corpus.
* **Two active lines with distinct destinations.** `cert_payload_delivery` carries
  `d0 ≠ d1` as a hypothesis; the tie and idle cases are a different theorem
  (`l1_the_three_cases_are_exhaustive` proves there is no fourth case).

## DIRECTION (iron rule 3)

The rotation certificates are equalities or the same proposition as their landed
theorem, proved by `exact`/`rw` from it. The plain vocabulary (`moveHeadToTail`,
`afterStages`, `addressBits`) is *defined here and proved equal* to the corpus's own
(`rotStage`, `Function.iterate`, `addr88`); **those bridge lemmas are why "nothing
was traded" is a kernel fact here rather than a promise** — a renaming that closes by
`rfl`/`simp` cannot have weakened anything.

⚠️ **`cert_payload_delivery` IS THE EXCEPTION AND IT IS NAMED RATHER THAN GLOSSED.**
Read one cycle at a time, it is *on its own strictly weaker* than the landed list
equality: it says nothing about the output's length, so it does not by itself exclude
cycles past the eighth. **The gap is closed by proof, not by wording** —
`cert_payload_delivery_length` supplies the length and
`cert_payload_delivery_loses_nothing` recovers the landed statement from the two,
generically. *This file's first version asserted "nothing traded" there in prose; the
assertion was repaired into `cert_payload_delivery_recovers_the_landed_statement`
after the campaign's own W-CERT-1 wave established the better discipline.*

## AXIOMS (iron rule 4)

Measured at the landing of this file, from the `#print axioms` block below — quoted
rather than summarised, because four of the five are *stronger* than the campaign's
bar of "at most the standard three":

```
cert_full_circle                                    [propext, Quot.sound]
cert_length_premise_is_load_bearing                  no axioms at all
cert_address_restored_after_three_stages            [propext, Quot.sound]
cert_stage_reads_original_bit                       [propext, Quot.sound]
cert_payload_delivery                               [propext, Classical.choice, Quot.sound]
cert_payload_delivery_length                        [propext, Classical.choice, Quot.sound]
cert_payload_delivery_loses_nothing                 [propext, Classical.choice, Quot.sound]
cert_payload_delivery_recovers_the_landed_statement [propext, Classical.choice, Quot.sound]
```

No `sorryAx`, no corpus-local axiom. *`Classical.choice` enters only through the
Batcher certificate's landed dependency chain, not through anything stated here.*
-/

namespace SaltWorks.Certs

open SaltWorks.HDL L1Payload

/-! ## 1. THE PLAIN VOCABULARY

Three definitions, so the certificates below can be read without knowing what
`List.rotate`, `Function.iterate` or `addr88` mean. Each is proved equal to the
corpus's own vocabulary immediately after it. -/

/-- **What one banyan stage does to the address**: take the first bit off the front
and put it on the end. The paper's words: *"rotates the first bit to the end of the
address, and moves the rest up."* -/
def moveHeadToTail {α : Type*} : List α → List α
  | []        => []
  | a :: rest => rest ++ [a]

/-- **The address after `n` stages** — apply `moveHeadToTail` once per stage. -/
def afterStages {α : Type*} : ℕ → List α → List α
  | 0,     l => l
  | n + 1, l => afterStages n (moveHeadToTail l)

/-- The bridge: the plain form is the corpus's `rotStage`. Closes by `simp` on the
definition of `List.rotate` — a renaming, not a weakening. -/
theorem moveHeadToTail_eq_rotStage {α : Type*} (l : List α) :
    moveHeadToTail l = rotStage l := by
  cases l with
  | nil => rfl
  | cons a rest => simp [moveHeadToTail, rotStage]

/-- The bridge for iteration: `n` plain stages are the corpus's `rotStage^[n]`. -/
theorem afterStages_eq_iterate {α : Type*} (n : ℕ) (l : List α) :
    afterStages n l = rotStage^[n] l := by
  induction n generalizing l with
  | zero => rfl
  | succ m ih =>
      rw [afterStages, ih, moveHeadToTail_eq_rotStage, Function.iterate_succ_apply]

/-- **The address field of a valid packet**, MSB first: the 3-bit destination as
the fabric frames it. (`addr88 true d` with validity discharged — a valid packet's
address is its destination bits, unmasked.) -/
def addressBits (d : ℕ) : List Bool := [d.testBit 2, d.testBit 1, d.testBit 0]

/-- The bridge to the fabric's own frame language. -/
theorem addressBits_eq_addr88 (d : ℕ) : addressBits d = addr88 true d := rfl

/-! ## 2. THE CERTIFICATES — the banyan half -/

/-- ⭐ **THE FULL CIRCLE.** Each stage moves the leading address bit to the end.
After as many stages as the address has bits, the address is **exactly what it
started as** — the packet leaves the banyan with its address restored.

`hk : addr.length = k` says the number of stages equals the address length; see the
docstring above for why that hypothesis is ours to state and why it is load-bearing.

Direction: **equality**, proved from `SaltWorks.HDL.rotate_full_circle`. Nothing
traded. -/
theorem cert_full_circle {α : Type*} (addr : List α) (k : ℕ) (hk : addr.length = k) :
    afterStages k addr = addr := by
  rw [afterStages_eq_iterate]
  exact rotate_full_circle addr k hk

/-- **The premise is load-bearing, in one line.** A 4-bit address does *not* heal in
3 stages. So `cert_full_circle` without `hk` would be false, and the hypothesis is
not decoration. -/
theorem cert_length_premise_is_load_bearing :
    afterStages 3 [1, 2, 3, 4] ≠ ([1, 2, 3, 4] : List ℕ) := by decide

/-- **The full circle at the fabric's own width**: three routing stages restore a
3-bit destination address. An instance of `cert_full_circle`, not a separate fact. -/
theorem cert_address_restored_after_three_stages (d : ℕ) :
    afterStages 3 (addressBits d) = addressBits d :=
  cert_full_circle (addressBits d) 3 rfl

/-- ⭐⭐ **WHY THE ROTATION IS THE POINT — every cell reads the same position.**
At stage `m`, the bit at the *head* of the address is original destination bit
`2 − m`. So all three stages are the **identical cell** reading the **identical
wire**, and the address supplies the difference by rotating.

Stated one-directionally (stage `m` ⇒ that bit); the converse is unavailable, see
the docstring. Direction: **same proposition** as
`SaltWorks.HDL.stage_reads_original_bit` with the validity antecedent discharged at
`v = true`. -/
theorem cert_stage_reads_original_bit (d : ℕ) (m : ℕ) (hm : m < 3) :
    (afterStages m (addressBits d)).head? = some (d.testBit (2 - m)) := by
  rw [afterStages_eq_iterate, addressBits_eq_addr88, ← hdr88_eq_iterate]
  exact stage_reads_original_bit true d m rfl hm

/-! ## 3. THE CERTIFICATE — the Batcher half

The compare–exchange element, run over one whole frame. `switchRun` names the run
so the certificate's statement stays readable; its docstring says exactly what the
run is. -/

/-- **One frame through the compare–exchange element.** Two active packets, each
framed as *six header cycles* (activity and destination bit, MSB first) followed by
*eight payload cycles*, fed to the element `ceC` from the all-false initial state,
under the H3 reset schedule (one reset pulse at cycle 0 and none after). The result
is the element's output trace: one `[line 0, line 1]` pair per cycle. -/
def switchRun (d0 d1 : ℕ) (p0 p1 : List Bool) : List (List Bool) :=
  (runTrace ceC [false, false, false, false]
    (elemTrace h3Rst (cFrame true d0 p0) (cFrame true d1 p1))).1

/-- ⭐ **THE PAYLOAD ARRIVES SORTED.** Skip the six header cycles; then at every
payload cycle `u`, **output line 0 carries bit `u` of the payload belonging to the
smaller destination, and output line 1 carries bit `u` of the other**. The element
has made its decision during the header and holds it for the whole payload.

Hypotheses, all of them real: both destinations are 3-bit (`< 8`), they are
**distinct** (the tie is a different theorem), and both payloads are the tapeout's
`P = 8` cycles.

Direction: **equality**, proved from `L1Payload.l1_full_load_payload_delivery`
together with the corpus's own indexing lemma.

⚠️ **AND THE "NOTHING TRADED" CLAIM IS NOT FREE HERE — THIS STATEMENT ALONE IS
STRICTLY WEAKER THAN THE LANDED ONE.** *It fixes the eight payload cycles and says
nothing whatever about the length of the output, so on its own it does not rule out
cycles past the eighth.* **So the claim is not asserted in prose: it is proved.**
`cert_payload_delivery_length` supplies the missing length and
`cert_payload_delivery_loses_nothing` recovers the landed list equality from the two
together — see `cert_payload_delivery_recovers_the_landed_statement`. -/
theorem cert_payload_delivery (d0 d1 : ℕ) (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1)
    (p0 p1 : List Bool) (hp0 : p0.length = 8) (hp1 : p1.length = 8)
    (u : ℕ) (hu : u < 8) :
    ((switchRun d0 d1 p0 p1).drop 6).getD u []
      = [(if d0 ≤ d1 then p0 else p1).getD u false,
         (if d0 ≤ d1 then p1 else p0).getD u false] := by
  simp only [switchRun]
  rw [l1_full_load_payload_delivery d0 d1 hd0 hd1 hne p0 p1 hp0 hp1]
  by_cases hle : d0 ≤ d1
  · rw [if_pos hle, if_pos hle]
    exact ceIL_getD p0 p1 (by rw [hp0, hp1]) u (by rw [hp0]; exact hu)
  · rw [if_neg hle, if_neg hle]
    exact ceIL_getD p1 p0 (by rw [hp1, hp0]) u (by rw [hp1]; exact hu)

/-- The payload window is exactly eight cycles long. Worth stating on its own: the
certificate above is silent about cycles past the eighth, and **this is what rules
out there being any**. -/
theorem cert_payload_delivery_length (d0 d1 : ℕ) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (hne : d0 ≠ d1) (p0 p1 : List Bool) (hp0 : p0.length = 8) (hp1 : p1.length = 8) :
    ((switchRun d0 d1 p0 p1).drop 6).length = 8 := by
  simp only [switchRun]
  rw [l1_full_load_payload_delivery d0 d1 hd0 hd1 hne p0 p1 hp0 hp1]
  by_cases hle : d0 ≤ d1 <;> simp [ceIL, hle, hp0, hp1]

/-- ⭐⭐ **THE NO-TRADE CLAIM, PROVED IN THE KERNEL INSTEAD OF ASSERTED IN PROSE.**
Any output of the right length whose every cycle carries the two payload bits **is**
the interleaving. So reading the landed theorem one cycle at a time loses nothing —
and that sentence is now a theorem rather than a docstring's promise.

*Stated generically: it mentions no landed theorem and no fabric, so it is a fact
about the RESTATEMENT rather than a re-citation of the original.* -/
theorem cert_payload_delivery_loses_nothing (out : List (List Bool)) (a b : List Bool)
    (ha : a.length = 8) (hb : b.length = 8) (hout : out.length = 8)
    (hcell : ∀ u, u < 8 → out.getD u [] = [a.getD u false, b.getD u false]) :
    out = ceIL a b := by
  apply List.ext_getElem
  · simp [ceIL, hout, ha, hb]
  · intro i h1 h2
    have hi : i < 8 := by rwa [hout] at h1
    have hcell' := hcell i hi
    rw [List.getD_eq_getElem _ _ h1] at hcell'
    rw [hcell', List.getD_eq_getElem _ _ (by rw [ha]; exact hi),
      List.getD_eq_getElem _ _ (by rw [hb]; exact hi)]
    simp [ceIL]

/-- **The recovery, instantiated.** The per-cycle certificate, read at all eight
cycles, gives back exactly `L1Payload.l1_full_load_payload_delivery`'s own
statement — proved *from the certificate*, not by citing the theorem again. -/
theorem cert_payload_delivery_recovers_the_landed_statement (d0 d1 : ℕ) (hd0 : d0 < 8)
    (hd1 : d1 < 8) (hne : d0 ≠ d1) (p0 p1 : List Bool) (hp0 : p0.length = 8)
    (hp1 : p1.length = 8) :
    (switchRun d0 d1 p0 p1).drop 6
      = ceIL (if d0 ≤ d1 then p0 else p1) (if d0 ≤ d1 then p1 else p0) :=
  cert_payload_delivery_loses_nothing _ _ _
    (by by_cases hle : d0 ≤ d1 <;> simp [hle, hp0, hp1])
    (by by_cases hle : d0 ≤ d1 <;> simp [hle, hp0, hp1])
    (cert_payload_delivery_length d0 d1 hd0 hd1 hne p0 p1 hp0 hp1)
    (fun u hu => cert_payload_delivery d0 d1 hd0 hd1 hne p0 p1 hp0 hp1 u hu)

#audit_axioms cert_full_circle
#audit_axioms cert_length_premise_is_load_bearing
#audit_axioms cert_address_restored_after_three_stages
#audit_axioms cert_stage_reads_original_bit
#audit_axioms cert_payload_delivery
#audit_axioms cert_payload_delivery_length
#audit_axioms cert_payload_delivery_loses_nothing
#audit_axioms cert_payload_delivery_recovers_the_landed_statement

#print axioms cert_payload_delivery_length
#print axioms cert_payload_delivery_loses_nothing
#print axioms cert_payload_delivery_recovers_the_landed_statement
#print axioms cert_full_circle
#print axioms cert_length_premise_is_load_bearing
#print axioms cert_address_restored_after_three_stages
#print axioms cert_stage_reads_original_bit
#print axioms cert_payload_delivery

end SaltWorks.Certs

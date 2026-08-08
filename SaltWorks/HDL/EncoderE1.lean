/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Decoder
import SaltWorks.HDL.EmitS

/-!
# E1 — the one-hot → select encoder, CERTIFIED AT THE RULED PAIR `(n = 3, b = 2)`

Muster ruling ②/⑤ chose encoder **E1 — an OR-tree over the one-hot** and assembly
shape **c1** (the encoder is a *certified organ*). Ruling ① sizes the select at
`(n = 3, b = 2)` (`RuledSizing32.lean`). This file builds and certifies the E1
block at that pair.

## ⭐ THE RESULT, STATED BEFORE IT IS PROVED

> **At `(n = 3, b = 2)` the E1 encoder is ZERO GATES. Both select bits are
> WIRES. Neither bit is degenerate.**

This is not a weakening of E1 — it is E1's own price formula evaluated at the
ruled pair. The silicon seat's published "**3 gates at the live `m = 3`**" is a
**`b = 4`** row (codes `{0,4,5}`, `c = [1,0,2,0]`: one `.or` plus two
`.const false`). At `b = 2` the three live ops necessarily **re-index** to codes
`{0,1,2}` — slots `{0,4,5}` are not addressable in two bits — and then
`c = [1,1]`: each bit has exactly one source, and a one-source OR reduction *is a
wire* (`orChain_one`, `Program.lean:3643`; and `Circ.wf` accepts an output that
is a primary input, `Syntax.lean:112` over `Circ.defined`, `Syntax.lean:88-90`).

`e1Cost` below is the price formula, general in `(φ, b)`. It reproduces **all
three published E1 measurements** — 3 at `(m=3, b=4)`, 11 at `(m=10, b=4)`, 28 at
`(m=16, b=4)`, the last of which is the *existing* `peIdTree` construction at
`PriorityEnc.lean:103-106` — and *then* returns 0 at the ruled pair. Three
independent anchors are what make the fourth number a derivation rather than a
convenience.

## ⛔ AND THE ZERO IS ITSELF THE HAZARD

```
gates.length      0     ✅ passes — nothing to count
ssa / wf          —     ✅ passes VACUOUSLY — no new gates to be ill-formed
cells             0     ✅ passes — and cells are the RULED metric
```

**A MIS-WIRED encoder — the right one-hot line on the WRONG select bit — is green
on every one of them.** Well-formed ≠ adequate, exactly as `n ≤ 2^b` is not
`ssa`. So:

1. the bit ↔ one-hot correspondence is written down as a **TABLE**
   (`selDrivers`), readable without evaluating any index arithmetic, and the
   block is *defined from the table*;
2. `ruledEnc_is_E1` proves the hand-written table is **exactly** what the E1
   price model constructs — the table cannot drift from the option that was
   ruled on;
3. `swap_*` proves the mis-wiring is invisible to gate count, cells, `ssa`, `wf`
   and port count, and is caught by **the semantic cert alone**.

## COST MODEL — named, per the Captain's permanent ruling

Two numbers, two models, never mixed:

* **`gates.length` — the proof-side count.** `ruled_gate_count : … = 0`, kernel.
* **CELLS — the ruled metric.** `emitSMuxCells` below is a *verbatim
  transcription* of `emitSMux`'s `live` list (`EmitS.lean:268-270`); it is a
  Lean function I define here, and `ruled_cell_count : … = 0` is a kernel
  theorem **about that transcription**. It is NOT a theorem about `emitSMux`,
  which returns a `String` and sits outside `emitN_sem` (`EmitS.lean:196-199`).
  The transcription is the model; the model is named; the number is 0.

## ⚖️ MATERIAL OBJECTION M1 — ANSWERED, AND IT EVAPORATES HERE

M1: in the *composite*, `emitSMux`'s recogniser matches `or(isXOR, isSLT)` and,
if the fanout guard `readCount == 1` (`EmitS.lean:261`) lapses, **DELETES the
decoder's own `isXOR`/`isSLT` `.and` gates**, leaving nets undriven under
`default_nettype none` — a hard elaboration failure no kernel theorem can catch.

**At the ruled pair the block has no `.or` gate at all, so there is no site to
match.** `ruled_no_or_gate` and `ruled_mux_sites` are the receipts. The hazard is
real and it is a property of the `b = 4` shape; it does not survive the ruling.
`live_b4_mux_sites` records the standalone half of the same fact for contrast:
even at `b = 4` the block *standalone* has 0 sites, because its `.or` reads
primary inputs — the site exists **only after composition**, which is precisely
why M1 cannot be checked inside this file and is recorded rather than closed.

## ⚖️ MATERIAL OBJECTION M2 — ANSWERED PER BIT, PROVED NOT REASONED

M2: `orChain b [] = ([], 0, b)` returns **net 0**
(`orChain_nil_is_word_bit_zero`, `Decoder.lean:125`), which in the encoder's
frame is one-hot LINE 0 → `isADD`. At `m = 10` that made every decoded ADD emit
`asSelOf = 10`, failing the `asSelOf < asOps` guard: **an ADD returning ZERO
instead of a sum.**

At `(3,2)`: `ruled_bit0_not_degenerate` and `ruled_bit1_not_degenerate` — **per
bit, by kernel decision** — plus `ruled_no_bit_degenerate` over both. The hazard
cannot arise. `hazardEnc` transplants it anyway and `hazard_fails_the_cert`
shows the cert catches it.

The `(3,2)` analogue of the out-of-range consequence is also closed:
`ruled_in_range` proves the emitted code is `< 3` on every input that is not
*two* lines hot at once, so no one-hot input can ever address the spare fourth
leaf (`ruled_spare_slot`, `RuledSizing32.lean:57`).

## ⛔ BOUNDARY

**The composition lemma — `asSelOf` of a decoder-driven `Env` = the decoded op
index — is MATH's**, dispatched under the same ruling, and is NOT attempted here.
Nothing below proves anything about `decoder`, `instMap`, `isADD`/`isXOR`/`isSLT`;
they are named only as the intended wiring of `lineADD`/`lineXOR`/`lineSLT`.
This file's job is to make math's lemma *provable* by writing the correspondence
down.
-/

namespace SaltWorks.HDL
namespace EncoderE1

/-! ## 1. E1's price model, general in `(φ, b)`

`φ` is the **code map**: `φ[i]` is the select code assigned to one-hot line `i`.
E1 is one sentence — *for each output bit `k`, OR together exactly those one-hot
lines whose code has bit `k` set* — and the three definitions below are that
sentence. -/

/-- The one-hot lines are the block's primary inputs: line `i` is net `i`. -/
def line (i : Nat) : Net := i

/-- **E1's source set for output bit `k`**: every one-hot line whose assigned
code has bit `k` set. -/
def bitSrcs (φ : List Nat) (k : Nat) : List Net :=
  (List.range φ.length).filter (fun i => (φ.getD i 0).testBit k)

/-- `c_k` — how many one-hot lines drive output bit `k`. -/
def bitFanin (φ : List Nat) (k : Nat) : Nat := (bitSrcs φ k).length

/-- **The E1 price of one output bit.** `c ≥ 2` costs an OR reduction over `c`
leaves = `c − 1` gates (any binary tree over `c` leaves has `c − 1` internal
nodes, so shape moves depth only); `c = 1` costs **nothing** — the bit *is* the
source net, a wire; `c = 0` costs one explicit `.const false`, which is the M2
fix and is why this is not `orChain`. -/
def bitCost (φ : List Nat) (k : Nat) : Nat :=
  match bitFanin φ k with
  | 0     => 1
  | 1     => 0
  | c + 2 => c + 1

/-- `G(φ, b) = Σ_{k < b} bitCost` — the block's whole gate price. -/
def e1Cost (φ : List Nat) (b : Nat) : Nat := ((List.range b).map (bitCost φ)).sum

/-! ### 1.1 The price model reproduces all three PUBLISHED E1 measurements

A formula that agrees with the corpus at three widths, one of them a
construction that already exists at the bytes, is a derivation. A formula
checked only where it is used is a convenience. -/

/-- The silicon seat's live `b = 4` row: codes `{0,4,5}`, `c = [1,0,2,0]` — one
`.or` (`= or(isXOR, isSLT)`) plus two `.const false`. -/
theorem cost_live_b4 : e1Cost [0, 4, 5] 4 = 3 := by decide +kernel

/-- The `m = 10` row (`asOps`), identity-coded: `c = [5,4,4,2]` → 11. -/
theorem cost_ten_b4 : e1Cost (List.range 10) 4 = 11 := by decide +kernel

/-- The `m = 16` row (`asPad`) — **this one is a construction that exists**:
`peIdTree` is `4 × 7 = 28` gates at `PriorityEnc.lean:103-106,125`. -/
theorem cost_sixteen_b4 : e1Cost (List.range 16) 4 = 28 := by decide +kernel

/-! ## 2. THE RULED PAIR — the code map, and the price at it -/

/-- **The ruled code map.** At `b = 2` the three live ALU ops re-index to codes
`{0, 1, 2}`: `add ↦ 0`, `xor ↦ 1`, `slt ↦ 2`. Slots `{0,4,5}` are not
addressable in two bits, so the re-slot is forced by the ruling, not chosen. -/
def ruledCodes : List Nat := [0, 1, 2]

/-- ⭐ **`G = 0` AT THE RULED PAIR** — from the price model of §1, which the three
theorems above anchor at 3, 11 and 28. Not asserted; evaluated. -/
theorem ruled_cost_zero : e1Cost ruledCodes 2 = 0 := by decide +kernel

/-! ## 3. M2 — THE PER-BIT DEGENERACY VERDICT

⛔ Each bit is decided **separately and in the kernel**. A verdict read off a
table is a verdict nobody checked. -/

/-- `c_0 = 1` — bit 0 has exactly one source. -/
theorem ruled_fanin_bit0 : bitFanin ruledCodes 0 = 1 := by decide +kernel

/-- `c_1 = 1` — bit 1 has exactly one source. -/
theorem ruled_fanin_bit1 : bitFanin ruledCodes 1 = 1 := by decide +kernel

/-- ⭐ **BIT 0 IS NOT DEGENERATE.** -/
theorem ruled_bit0_not_degenerate : bitSrcs ruledCodes 0 ≠ [] := by decide +kernel

/-- ⭐ **BIT 1 IS NOT DEGENERATE.** -/
theorem ruled_bit1_not_degenerate : bitSrcs ruledCodes 1 ≠ [] := by decide +kernel

/-- ⭐ **NEITHER SELECT BIT IS DEGENERATE AT `(3, 2)`** — both bits, one
statement, so a reader need not check that the two per-bit theorems above
exhaust `b`. -/
theorem ruled_no_bit_degenerate : ∀ k < 2, bitSrcs ruledCodes k ≠ [] := by
  decide +kernel

/-! ## 4. ⭐ THE CORRESPONDENCE — WRITTEN DOWN, NOT COMPUTED

| select bit | driven by     | net | ALU op | code |
| ---------- | ------------- | --- | ------ | ---- |
| `asSel 0`  | `lineXOR`     | 1   | `xor`  | 1    |
| `asSel 1`  | `lineSLT`     | 2   | `slt`  | 2    |
| *(none)*   | `lineADD`     | 0   | `add`  | 0 — **the all-low default** |

`lineADD` drives no select bit. That is not an omission: code 0 is all-zero, so
`add` is what the select reads when no line is hot — including on `BEQ`, which
selects no ALU op at all.

📌 **This table is the point of the file.** A future re-index that moves `xor`
off code 1 breaks `ruledEnc_is_E1` (§5) *in the kernel*, where a re-index hidden
in net arithmetic would break nothing and be discovered by an ALU running the
wrong operation. -/

/-- One-hot line for `add` — code 0, drives **no** select bit. -/
def lineADD : Net := line 0
/-- One-hot line for `xor` — code 1, drives select bit 0. -/
def lineXOR : Net := line 1
/-- One-hot line for `slt` — code 2, drives select bit 1. -/
def lineSLT : Net := line 2

/-- ⭐ **THE CORRESPONDENCE, AS A TABLE.** `selDrivers[k]` is the one-hot line
that drives select bit `k`. No index computation; the wiring is the data. -/
def selDrivers : List Net := [lineXOR, lineSLT]

/-- The table says what E1 says: bit `k`'s source set is exactly the singleton
`{selDrivers[k]}`. **This is the bridge between the readable table and the
ruled option** — if they ever disagree the kernel says so. -/
theorem correspondence_is_E1 :
    (List.range 2).map (bitSrcs ruledCodes) = selDrivers.map (fun n => [n]) := by
  decide +kernel

/-- And `lineADD` drives nothing: it is in no bit's source set. -/
theorem lineADD_drives_nothing : ∀ k < 2, lineADD ∉ bitSrcs ruledCodes k := by
  decide +kernel

/-! ## 5. THE BLOCK -/

/-- ⭐ **THE RULED E1 ENCODER at `(n = 3, b = 2)`.** Three one-hot lines in, two
select bits out, **no gates**: each select bit *is* a one-hot line, named by the
table above. Zero gates is not zero function — see `ruledEnc_cert`. -/
def ruledEnc : Circ where
  nIn   := 3
  gates := []
  outs  := selDrivers

/-! ### 5.1 …and it is E1, not merely something cheap

The general E1 construction, so that "the block is E1" is a kernel equation and
not a reading of prose. `bitGates` uses the corpus's own `orChain`
(`Decoder.lean:90-96`) for the `c ≥ 2` case and an explicit `.const false` for
`c = 0` — **never `orChain` on an empty list**, which is M2. -/

/-- Where bit `k`'s gates start: after the lines, after every earlier bit. -/
def bitBase (φ : List Nat) (k : Nat) : Net :=
  φ.length + ((List.range k).map (bitCost φ)).sum

/-- Bit `k`'s gates. `[]` → one `.const false`; `[x]` → **no gate**; `≥ 2` → the
corpus `orChain`. -/
def bitGates (φ : List Nat) (k : Nat) : List Gate :=
  match bitSrcs φ k with
  | []          => [⟨bitBase φ k, .const false⟩]
  | [_]         => []
  | x :: y :: r => (orChain (bitBase φ k) (x :: y :: r)).1

/-- Bit `k`'s driver net. The `[x]` case is the wire. -/
def bitOut (φ : List Nat) (k : Nat) : Net :=
  match bitSrcs φ k with
  | []          => bitBase φ k
  | [x]         => x
  | x :: y :: r => (orChain (bitBase φ k) (x :: y :: r)).2.1

/-- **E1, general in `(φ, b)`.** -/
def e1Enc (φ : List Nat) (b : Nat) : Circ where
  nIn   := φ.length
  gates := (List.range b).flatMap (bitGates φ)
  outs  := (List.range b).map (bitOut φ)

/-- ⭐ **THE HAND-WRITTEN TABLE BLOCK *IS* E1 AT THE RULED PAIR** — whole-circuit
equality, kernel-decided: same `nIn`, same (empty) gate list, same port list in
the same order. -/
theorem ruledEnc_is_E1 : ruledEnc = e1Enc ruledCodes 2 := by decide +kernel

/-! ## 6. THE STRUCTURAL RECEIPTS — and what each one is blind to -/

/-- **The gate count, in the proof-side model.** `gates.length = 0`. -/
theorem ruled_gate_count : ruledEnc.gates.length = 0 := by decide +kernel

/-- The circuit-level count agrees with the price model of §1 at the ruled pair
— so `ruled_cost_zero` is about *this* block, not a parallel arithmetic. -/
theorem ruled_gate_count_eq_cost : ruledEnc.gates.length = e1Cost ruledCodes 2 := by
  decide +kernel

/-- **CELLS — the ruled metric.** `emitSMuxCells` is a verbatim transcription of
`emitSMux`'s `live` list (`EmitS.lean:268-270`): the gates that survive after
every recognised mux site consumes its two `.and` arms. ⚠️ It is a function
defined *here*; `emitSMux` itself returns a `String` and sits outside
`emitN_sem`, so no theorem in this corpus can be about the emitted text. -/
def emitSMuxCells (c : Circ) : Nat :=
  let sites := c.gates.filterMap fun g => (muxAt c g).map fun m => (g.out, m)
  let cons  := sites.flatMap fun s => [s.2.arm0, s.2.arm1]
  (c.gates.filter fun g => !(cons.contains g.out)).length

/-- ⭐ **ZERO CELLS**, in the model named immediately above. -/
theorem ruled_cell_count : emitSMuxCells ruledEnc = 0 := by decide +kernel

/-- ⭐ **M1 CANNOT FIRE: the block has no `.or` gate at all.** -/
theorem ruled_no_or_gate :
    ruledEnc.gates.filter (fun g => match g.op with | .or _ _ => true | _ => false) = [] := by
  decide +kernel

/-- …hence the peephole finds nothing to match. -/
theorem ruled_mux_sites : muxCount ruledEnc = 0 := by decide +kernel

/-- ⚠️ **The standalone half of M1, for contrast.** Even the `b = 4` block has 0
sites *standalone* — its `.or` reads primary inputs, and `muxAt` needs both
sources to be `.and` gates. The site M1 warns about exists **only after
composition**, when those inputs become the decoder's `isXOR`/`isSLT`. So a
`muxCount = 0` measured on a standalone block is **not** evidence that M1 is
closed for that block — it is closed at the ruled pair by
`ruled_no_or_gate`, which composition cannot undo. -/
theorem live_b4_mux_sites : muxCount (e1Enc [0, 4, 5] 4) = 0 := by decide +kernel

/-- Well-formed. ⚠️ **Vacuously** — there are no gates to be ill-formed. Recorded
as a receipt, not offered as evidence of adequacy. -/
theorem ruled_wf : ruledEnc.wf = true := by decide +kernel

/-- Dense SSA, likewise vacuously. -/
theorem ruled_ssa : ruledEnc.ssa = true := by decide +kernel

/-- **The port list's LENGTH, pinned in the kernel.** -/
theorem ruled_outs_length : ruledEnc.outs.length = 2 := by decide +kernel

/-! ## 7. ⭐ THE CERTIFICATE — arbitrary `Env`, whole port list, over `sem`

Stated over `sem ruledEnc` (never `run … gates <net>`), for an **arbitrary**
`Env` (no fixture, no sample), as a whole-list equality on the **PORT** axis
whose right-hand side has determined length 2. -/

/-- ⭐ **THE CERT.** Select bit 0 is the `xor` line; select bit 1 is the `slt`
line; and there is no third port. -/
theorem ruledEnc_cert (env : Env) : sem ruledEnc env = [env lineXOR, env lineSLT] := rfl

/-- Bit 0's E1 source set, as a singleton. -/
theorem ruled_srcs_bit0 : bitSrcs ruledCodes 0 = [lineXOR] := by decide +kernel

/-- Bit 1's E1 source set, as a singleton. -/
theorem ruled_srcs_bit1 : bitSrcs ruledCodes 1 = [lineSLT] := by decide +kernel

/-- ⭐ **THE CERT IN E1'S OWN SPEC FORM** — every port is the OR over that bit's
one-hot source set, which is what E1 *means*. The right-hand side is
`(List.range 2).map …`, whose length is determined by `b`, so a port dropped or
added falsifies it. -/
theorem ruledEnc_cert_spec (env : Env) :
    sem ruledEnc env = (List.range 2).map (fun k => (bitSrcs ruledCodes k).any env) := by
  rw [ruledEnc_cert, show (List.range 2) = [0, 1] from rfl]
  simp [ruled_srcs_bit0, ruled_srcs_bit1]

/-! ## 8. NO SILENT WRONG ANSWER — the `(3,2)` analogue of M2's consequence

M2's damage at `m = 10` was an out-of-range select (`asSelOf = 10 ≥ asOps`)
taking the all-false arm: a decoded ADD returning zero. At `(3,2)` the range is
`< 3` and there is one spare leaf (`ruled_spare_slot`, `RuledSizing32.lean:57`). -/

/-- The select value the two ports encode, LSB first. -/
def selVal : List Bool → Nat
  | []     => 0
  | b :: r => (if b then 1 else 0) + 2 * selVal r

/-- No line hot ⇒ code 0 ⇒ `add`. This is the default `BEQ` and any
non-ALU instruction gets, and it is a *defined* op, not a stray index. -/
theorem ruled_all_low_is_add : selVal (sem ruledEnc (fun _ => false)) = 0 := by
  decide +kernel

/-- ⭐ **THE SPARE LEAF IS UNREACHABLE FROM A ONE-HOT INPUT.** Unless *two*
lines are hot at once — which is not a one-hot vector — the emitted code is
`< 3`, so it always addresses one of the three real sources of `genSelect 3 2`. -/
theorem ruled_in_range (env : Env) (h : ¬(env lineXOR = true ∧ env lineSLT = true)) :
    selVal (sem ruledEnc env) < 3 := by
  rw [ruledEnc_cert]
  cases hx : env lineXOR <;> cases hs : env lineSLT <;>
    first
      | decide
      | exact absurd ⟨hx, hs⟩ h

/-- The contrapositive, stated because it is the sentence a reader wants: code 3
*means* the input was not one-hot. -/
theorem ruled_spare_needs_two_hot (env : Env) (h : selVal (sem ruledEnc env) = 3) :
    env lineXOR = true ∧ env lineSLT = true := by
  by_contra hc
  have := ruled_in_range env hc
  omega

/-! ## 9. ⛔ THE MUTATIONS — each one proves THE CERT FAILS

Every structural instrument in §6 is blind to a mis-wiring, so the mutations are
the only thing standing between this block and an ALU that runs `xor` when the
program said `slt`. -/

/-! ### MUTATION 1 — THE ONE-HOT LINE SWAP (the one that matters most) -/

/-- ⚠️ The same block with the two drivers exchanged: `asSel 0 ← slt`,
`asSel 1 ← xor`. -/
def swappedEnc : Circ where
  nIn   := 3
  gates := []
  outs  := [lineSLT, lineXOR]

/-- The swap is invisible to the gate count. -/
theorem swap_invisible_to_gate_count :
    swappedEnc.gates.length = ruledEnc.gates.length := by decide +kernel

/-- …invisible to the ruled CELL metric. -/
theorem swap_invisible_to_cells :
    emitSMuxCells swappedEnc = emitSMuxCells ruledEnc := by decide +kernel

/-- …invisible to `ssa`. -/
theorem swap_invisible_to_ssa : swappedEnc.ssa = ruledEnc.ssa := by decide +kernel

/-- …invisible to `wf`. -/
theorem swap_invisible_to_wf : swappedEnc.wf = ruledEnc.wf := by decide +kernel

/-- …invisible to the port count. -/
theorem swap_invisible_to_port_count :
    swappedEnc.outs.length = ruledEnc.outs.length := by decide +kernel

/-- ⭐ **AND THE CERT CATCHES IT** — on *every* input that distinguishes the two
lines, not merely on a lucky witness. This is the single check in the whole
stack that can see a mis-wiring at zero gates. -/
theorem swap_fails_the_cert (env : Env) (h : env lineXOR ≠ env lineSLT) :
    sem swappedEnc env ≠ [env lineXOR, env lineSLT] := by
  intro he
  rw [show sem swappedEnc env = [env lineSLT, env lineXOR] from rfl] at he
  exact h (List.head_eq_of_cons_eq he).symm

/-- The same refutation as a closed kernel decision, so it needs no reader. -/
theorem swap_fails_the_cert_witness :
    sem swappedEnc (fun n => n == lineXOR) ≠ sem ruledEnc (fun n => n == lineXOR) := by
  decide +kernel

/-! ### MUTATION 2 — THE RE-SLOT (the same damage, entered through the code map)

A mis-wiring need not be a wiring edit: exchanging two ops' *codes* produces the
identical wrong circuit. This is why `correspondence_is_E1` is bridged to the
table rather than left as arithmetic. -/

/-- Exchanging `xor`'s and `slt`'s codes yields **exactly** the swapped block. -/
theorem reslot_is_the_swap : e1Enc [0, 2, 1] 2 = swappedEnc := by decide +kernel

/-- …and therefore is not the ruled block. -/
theorem reslot_fails : e1Enc [0, 2, 1] 2 ≠ ruledEnc := by decide +kernel

/-- ⭐ …and the cert fails on it directly, so this mutation is refuted on its own
terms and not only by transport through `swappedEnc`. -/
theorem reslot_fails_the_cert (env : Env) (h : env lineXOR ≠ env lineSLT) :
    sem (e1Enc [0, 2, 1] 2) env ≠ [env lineXOR, env lineSLT] := by
  rw [reslot_is_the_swap]
  exact swap_fails_the_cert env h

/-! ### MUTATION 3 — THE M2 HAZARD, TRANSPLANTED

Had a select bit been built with `orChain` over an **empty** source list, its
driver would be net 0 — `lineADD` in this block's frame. Both bits are
non-degenerate here (§3) so this cannot arise; the mutation shows what the cert
would have caught if it had. -/

/-- The hazard's driver, from the landed theorem rather than from a re-derivation:
`orChain` on an empty list yields `lineADD`. -/
theorem hazard_driver_is_orChain_nil (b : Nat) : (orChain b []).2.1 = lineADD :=
  orChain_nil_is_word_bit_zero b

/-- ⚠️ Bit 0 driven by `lineADD` instead of `lineXOR`. -/
def hazardEnc : Circ where
  nIn   := 3
  gates := []
  outs  := [lineADD, lineSLT]

/-- Invisible to the gate count, like every mutation here. -/
theorem hazard_invisible_to_gate_count :
    hazardEnc.gates.length = ruledEnc.gates.length := by decide +kernel

/-- ⭐ **The cert catches it** — on a hot `add` line the mutant emits code 1
(`xor`) where the ruled block emits 0 (`add`): M2's silent wrong answer, caught. -/
theorem hazard_fails_the_cert :
    sem hazardEnc (fun n => n == lineADD) ≠ sem ruledEnc (fun n => n == lineADD) := by
  decide +kernel

/-! ### MUTATION 4 — A DROPPED PORT

`①″`: the cert is a whole-list equality, so a port that vanishes falsifies it
even though the surviving port is still correctly wired. -/

/-- ⚠️ One select bit only. -/
def shortEnc : Circ where
  nIn   := 3
  gates := []
  outs  := [lineXOR]

/-- Its gate count is still 0 — the count cannot see a missing port. -/
theorem short_invisible_to_gate_count :
    shortEnc.gates.length = ruledEnc.gates.length := by decide +kernel

/-- ⭐ The cert catches it, at an arbitrary `Env`, purely on length. -/
theorem short_fails_the_cert (env : Env) : sem shortEnc env ≠ [env lineXOR, env lineSLT] := by
  intro he
  have : (sem shortEnc env).length = 2 := by rw [he]; rfl
  simp [sem, shortEnc] at this

/-- …and as a closed kernel decision. -/
theorem short_fails_the_cert_witness :
    sem shortEnc (fun n => n == lineXOR) ≠ sem ruledEnc (fun n => n == lineXOR) := by
  decide +kernel

/-! ## 10. Axiom audit — one declaration per call -/

#audit_axioms line
#audit_axioms bitSrcs
#audit_axioms bitFanin
#audit_axioms bitCost
#audit_axioms e1Cost
#audit_axioms cost_live_b4
#audit_axioms cost_ten_b4
#audit_axioms cost_sixteen_b4
#audit_axioms ruledCodes
#audit_axioms ruled_cost_zero
#audit_axioms ruled_fanin_bit0
#audit_axioms ruled_fanin_bit1
#audit_axioms ruled_bit0_not_degenerate
#audit_axioms ruled_bit1_not_degenerate
#audit_axioms ruled_no_bit_degenerate
#audit_axioms lineADD
#audit_axioms lineXOR
#audit_axioms lineSLT
#audit_axioms selDrivers
#audit_axioms correspondence_is_E1
#audit_axioms lineADD_drives_nothing
#audit_axioms ruledEnc
#audit_axioms bitBase
#audit_axioms bitGates
#audit_axioms bitOut
#audit_axioms e1Enc
#audit_axioms ruledEnc_is_E1
#audit_axioms ruled_gate_count
#audit_axioms ruled_gate_count_eq_cost
#audit_axioms emitSMuxCells
#audit_axioms ruled_cell_count
#audit_axioms ruled_no_or_gate
#audit_axioms ruled_mux_sites
#audit_axioms live_b4_mux_sites
#audit_axioms ruled_wf
#audit_axioms ruled_ssa
#audit_axioms ruled_outs_length
#audit_axioms ruledEnc_cert
#audit_axioms ruled_srcs_bit0
#audit_axioms ruled_srcs_bit1
#audit_axioms ruledEnc_cert_spec
#audit_axioms selVal
#audit_axioms ruled_all_low_is_add
#audit_axioms ruled_in_range
#audit_axioms ruled_spare_needs_two_hot
#audit_axioms swappedEnc
#audit_axioms swap_invisible_to_gate_count
#audit_axioms swap_invisible_to_cells
#audit_axioms swap_invisible_to_ssa
#audit_axioms swap_invisible_to_wf
#audit_axioms swap_invisible_to_port_count
#audit_axioms swap_fails_the_cert
#audit_axioms swap_fails_the_cert_witness
#audit_axioms reslot_is_the_swap
#audit_axioms reslot_fails
#audit_axioms reslot_fails_the_cert
#audit_axioms hazard_driver_is_orChain_nil
#audit_axioms hazardEnc
#audit_axioms hazard_invisible_to_gate_count
#audit_axioms hazard_fails_the_cert
#audit_axioms shortEnc
#audit_axioms short_invisible_to_gate_count
#audit_axioms short_fails_the_cert
#audit_axioms short_fails_the_cert_witness

end EncoderE1
end SaltWorks.HDL

/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA
import SaltWorks.HDL.Sem

import SaltWorks.HDL.EmitN

/-!
# C4 · `core` — THE DECODER, as a `Circ`

The first block of `compile`/`core`, and the one the ratified semantics pins
exactly: option 1 (Captain-ratified 8/7) makes an undecodable word a **defined
NOP-advance**, so the decoder's `valid` output is not an error flag — it is a
control signal with a specified meaning, and every gate downstream of it is
reachable.

## What it computes

Seven one-hot control signals, a memory-access aggregate, and their
disjunction, from the 32-bit instruction word alone:

```
isADD   opcode = 0110011 ∧ funct7 = 0 ∧ funct3 = 000
isXOR   opcode = 0110011 ∧ funct7 = 0 ∧ funct3 = 100
isSLT   opcode = 0110011 ∧ funct7 = 0 ∧ funct3 = 010
isADDI  opcode = 0010011 ∧ funct3 = 000
isBEQ   opcode = 1100011 ∧ funct3 = 000
isLW    opcode = 0000011 ∧ funct3 = 010          ⬥ D2
isSW    opcode = 0100011 ∧ funct3 = 010          ⬥ D2
req     isLW ∨ isSW — the memory port's access strobe   ⬥ D2, DERIVED
valid   the disjunction — ¬valid ⇒ the NOP-advance path
```

⬥⬥ **D2 — THE MEMORY CONTROL PLANE, AND THE ORDER OF THIS LIST IS A THEOREM.**
The stated rule, which the kernel checks rather than a convention:

> **MATCHER ROWS EXTEND THE PREFIX · DERIVED BITS INSERT BEFORE `valid` ·
> `valid` KEEPS THE TAIL.**

*`req` is the ONE derived bit — it aggregates, which is why it cannot be a
`dcMatches` row (`dmem_addr8.v:80` needs a single access strobe). `isSW` drives
the port's `we_in` DIRECTLY, needing no combinator. **The port needs one of
each**, which is what made `decoder` an edit site.* ⇒ *Positions 0-4 are
therefore bit-for-bit what they were before D2 — stated as `ctrlSpec_prefix_stable`
rather than left to inspection, because `C1Organ` reads positions 1 and 2 by
index.*

**These are exactly `SaltWorks.ISA.decode`'s cases**, read off the landed
definition rather than from the manual, because `decode` is what `stepT` uses
and `stepT` is what C4 compares against.

## The projection, and why the certificate is complete despite being small

⭐ **The control signals depend on the word ONLY through `opcode` (7 bits),
`funct3` (3 bits), and the single predicate `funct7 = 0`.** Every other bit of
the word is data — `rd`, `rs1`, `rs2` and the immediates — and no gate here
reads them. *So an exhaustive check over `2^32` words would be checking the same
1024 × 2 cases four million times each.*

The certificates below therefore cover:

```
all 2^10 (opcode, funct3) pairs at funct7 = 0     1024 cases
all 2^10 (opcode, funct3) pairs at funct7 = 1     1024 cases   (a non-zero rep.)
all 2^7  funct7 values, for the zero-detector      128 cases
```

⇒ **Together these exhaust the projection the logic actually depends on**, and
the third is what licenses treating `funct7 = 1` as representative of every
non-zero `funct7`. *Stating the projection is the whole argument; a reader who
does not accept it should reject the certificate, which is why it is written
down rather than implied.*
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### Net layout: the word on `0…31`, its inverters on `32…63`, logic above. -/

/-- Instruction word width, and the block's input count. -/
def dcIn : Nat := 32

/-- `¬w[i]`, one inverter per word bit, shared by every match below. -/
def dcNot (i : Nat) : Net := dcIn + i

/-- The inverter bank. -/
def dcInvs : List Gate := (List.range dcIn).map fun i => ⟨dcNot i, .not i⟩

/-- First net available to the matching logic. -/
def dcBase : Nat := dcIn + dcIn

/-- A left-associated AND chain over `ns`, allocating from `b`.
Returns the gates, the output net, and the next free net. -/
def andChain (b : Nat) : List Net → List Gate × Net × Nat
  | []          => ([], 0, b)
  | [x]         => ([], x, b)
  | x :: y :: r =>
      let (gs, o, b') := andChain (b + 1) (b :: r)
      (⟨b, .and x y⟩ :: gs, o, b')
  termination_by ns => ns.length

/-- A left-associated OR chain. -/
def orChain (b : Nat) : List Net → List Gate × Net × Nat
  | []          => ([], 0, b)
  | [x]         => ([], x, b)
  | x :: y :: r =>
      let (gs, o, b') := orChain (b + 1) (b :: r)
      (⟨b, .or x y⟩ :: gs, o, b')
  termination_by ns => ns.length

/-! ### ⛔ THE EMPTY-LIST HAZARD, COMMITTED AS A THEOREM RATHER THAN A COMMENT

*Silicon's `C-D3`, pre-registered against `DECODER-UNCOND` 8/7 20:56 and verified
here at the bytes.* **`andChain b [] = ([], 0, b)` and `orChain b [] = ([], 0, b)`
both return NET 0 — and net 0 is WORD BIT 0**, the opcode's LSB, because `dcIn`
lays the 32 word bits at nets `0…31`. ⇒ ***A match built from an EMPTY literal
list would silently take `w[0]` as its match signal: well-formed, `ssa`-valid,
and wrong.***

⚖️ **THE HAZARD IS NOT CLOSED BY CHANGING `andChain`** — allocating a real
constant-true in the nil case shifts every gate number downstream and
invalidates the whole certificate suite for a case that never occurs. **It is
closed by the TABLE, and the table is what gets edited.** *So the fact is stated
as a theorem and the invariant is stated beside `dcMatches` below, in the same
spirit as math's `regNext_writes_x0_when_enabled`: commit the hazard, then close
it.*

📌 **Same genre as `bnCSigma`'s catch-all `else` (silicon, 19:52): a total
function whose default is silently WRONG for an input its author did not expect.
There it was fixed at the source because that was free; here it is not, so it is
fenced instead.** -/

/-- ⛔ **THE HAZARD: an empty literal list yields word bit 0 as the match net.** -/
theorem andChain_nil_is_word_bit_zero (b : Nat) : (andChain b []).2.1 = 0 := by
  simp [andChain]

/-- …and `orChain` likewise. -/
theorem orChain_nil_is_word_bit_zero (b : Nat) : (orChain b []).2.1 = 0 := by
  simp [orChain]

/-- The literal for "word bit `i` equals `v`": the bit itself, or its inverter. -/
def dcLit (i : Nat) (v : Bool) : Net := if v then i else dcNot i

/-- The literals matching a field: `w[lo … lo+n-1]` against `val`'s low `n` bits. -/
def dcField (lo n val : Nat) : List Net :=
  (List.range n).map fun j => dcLit (lo + j) (val.testBit j)

/-- `opcode` occupies bits 0…6, `funct3` bits 12…14, `funct7` bits 25…31 —
`ISA.decode`'s own `extractLsb'` offsets. -/
def dcOpcode (v : Nat) : List Net := dcField 0 7 v
def dcFunct3 (v : Nat) : List Net := dcField 12 3 v
/-- `funct7 = 0` is seven inverters ANDed — the only way `funct7` is read. -/
def dcFunct7Zero : List Net := dcField 25 7 0

/-- **The number of slice-A op-classes** — the length of the pre-D2 table, and
the width of the prefix every downstream positional read depends on.

⬥ *Named rather than re-typed as `5`: `ctrlSpec_prefix_stable` and `dcReqRows`
both need it, and a bare `5` in three places is three chances to disagree.
**It means "the five slice-A classes, FIRST by `dcMatches` order" — it survives
an APPEND and breaks under an INSERT**, and grouping the table by opcode is a
natural future edit, so the name carries the warning the literal could not.* -/
def dcSliceA : Nat := 5

/-- The seven matches, in allocation order, each an AND chain over its literals.

⬥ **D2 APPENDED the two memory rows and did not touch the first five.** *That is
not tidiness — it is the cost-control property. Appending preserves the whole
inverter+matcher gate allocation as a PREFIX (`decoder_gate_prefix`), which keeps
~25 net-numbered declarations in `Stack/Program.lean` out of the diff. An
insertion anywhere else re-nets all 35 and invalidates the certificate suite this
file warns about at `dcInvs`.* -/
def dcMatches : List (List Net) :=
  [ dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b000    -- ADD
  , dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b100    -- XOR
  , dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b010    -- SLT
  , dcOpcode 0b0010011 ++ dcFunct3 0b000                    -- ADDI
  , dcOpcode 0b1100011 ++ dcFunct3 0b000                    -- BEQ
  -- ⬥ D2. `decode`'s LW/SW arms test OPCODE and FUNCT3 only (`ISA.lean:806-811`),
  -- so these rows carry NO `funct7` literals — which is exactly what keeps the
  -- projection argument above intact for the new bits rather than widening it.
  , dcOpcode 0b0000011 ++ dcFunct3 0b010                    -- LW
  , dcOpcode 0b0100011 ++ dcFunct3 0b010 ]                  -- SW

/-- ✅ **THE INVARIANT THAT CLOSES `andChain_nil_is_word_bit_zero` — every match
in the table has literals.** *This is a property of `dcMatches`, NOT of
`andChain`, and it must be re-checked whenever the table is edited. That is
exactly why it is a theorem and not a comment.* -/
theorem dcMatches_all_nonempty : dcMatches.all (fun m => !m.isEmpty) = true := by
  decide +kernel

/-- The margin the invariant is standing on, measured rather than asserted.

⬥ **D2 MOVED THIS, AND THAT IS THE TRIPWIRE WORKING.** *It is pinned to a literal
precisely so that growing the table cannot be silent; it went red on the D2 edit
and was re-measured, not re-guessed.* -/
theorem dcMatches_literal_counts :
    dcMatches.map List.length = [17, 17, 17, 10, 10, 10, 10] := by decide +kernel

/-- Lay the matches out one after another, collecting their output nets. -/
def dcLayout : Nat → List (List Net) → List Gate × List Net × Nat
  | b, []      => ([], [], b)
  | b, m :: ms =>
      let (gs, o, b')   := andChain b m
      let (gs', os, b'') := dcLayout b' ms
      (gs ++ gs', o :: os, b'')

/-- **The decoder.** Outputs
`[isADD, isXOR, isSLT, isADDI, isBEQ, isLW, isSW, req, valid]`.

⬥⬥ **D2 EDITED THIS DEFINITION, AND THAT WAS THE SHARP QUESTION OF THE WHOLE
STEP.** *While every control bit was a matcher row, `outs ++ [v]` made "valid
rides the tail" true FOR FREE and no theorem was needed. `req` AGGREGATES —
`dmem_addr8.v:80` needs one access strobe, not two — so it cannot be a row, and
the moment a derived bit exists this line is what decides where `valid` sits.*

```
outs ++ [v, req]     ⇒ valid at length-2.  Every "valid is last" reader
                       silently re-points.                          ⛔
outs ++ [req, v]     ⇒ valid last · prefix 0-4 held · C1Organ safe.  ✅
```

⇒ ***Both spellings build, both are appends, and only one is correct*** — which
is why `decoder_valid_rides_the_tail` below is a stated theorem and not a
comment. *`outs.drop dcSliceA` is the two memory rows: read from the table's own
shape, so a third memory row joins `req` automatically.* -/
def decoder : Circ :=
  let (mgs, outs, b)  := dcLayout dcBase dcMatches
  let (rgs, req, b')  := orChain b (outs.drop dcSliceA)
  let (ogs, v, _)     := orChain b' outs
  { nIn := dcIn, gates := dcInvs ++ mgs ++ (rgs ++ ogs), outs := outs ++ [req, v] }

theorem decoder_wf : decoder.wf = true := by decide +kernel

/-! ### The specification — read off `ISA.decode`'s cases, not off the manual

### ⬥⬥ HISTORICAL RECORD — M2's DIVERGENCE, AND ITS CLOSURE AT D2

*This block is a free-standing module record rather than a docstring, because
**the declaration whose docstring it was has been retired** — and a docstring
citing a retired theorem builds green forever. It is kept because a reader who finds the M2 reasoning
quoted elsewhere must land here and not in a gap.*

**WHAT M2 SAID (helm ruling 16:48/17:07, and it was true when written):** `decode`
accepts `LW`/`SW`; *"this control plane does not, BY DESIGN — there is no memory
datapath in the v1 core, no port, no decode row in `dcMatches`, and no bit in
this six-signal vocabulary that could name one."* M2 stated that disagreement as
a theorem, `ctrlSpec_not_decoded_of_touchesMem`, rather than leaving it to prose
— **so that the day the plane decoded memory it would fail LOUDLY.**

✅ **THAT DAY IS D2, AND THE THEOREM FIRED EXACTLY AS DESIGNED.** *Every clause of
the sentence above is now false: there IS a port (`dmem_addr8.v`), there ARE
decode rows, and the vocabulary has `isLW`, `isSW` and `req` to name them.* ⇒
***M2's guard is RETIRED, not deleted — `ctrlSpec_mem_is_decoded` below is its
positive counterpart over the same hypothesis, because retiring a stated property
without adding one leaves the file quieter after the change than before it.***

📌 **The expiry-by-design pattern is the point worth carrying forward:** a
theorem written to go red on a specific future edit is a message to the author of
that edit, and it is the only kind of message that cannot be missed. -/

/-- **The control plane's reading of `ISA.decode`** — seven op-class bits, the
memory-access aggregate `req`, and `valid`.

⬥ **D2 RE-CUT THIS DEFINITION AND ITS DOCSTRING TOGETHER.** *The kernel decoder
and this plane are the SAME PARTIAL FUNCTION again: `valid` is now exactly
`(decode w).isSome` (`ctrlSpec_valid_iff_decodes`), which is the property the
six-bit plane could not state because for `LW`/`SW` it was false while `decode`
said yes.*

⚠️ **`req` is the only bit here that is not a matcher.** It aggregates `isLW` and
`isSW` because the port takes a single access strobe; `isSW` reaches the port's
`we_in` directly. *The pair property — the decoder never asserts write without
access — is `ctrlSpec_we_implies_req`, and it is not decoration: the RTL computes
`we_out = we_in & req & …`, so a plane asserting `we_in` without `req` would have
every legitimate store silently suppressed, with no theorem about addresses able
to see it.* -/
def ctrlSpec (w : BitVec 32) : List Bool :=
  --      isADD  isXOR  isSLT  isADDI isBEQ  isLW   isSW   req    valid
  match decode w with
  | some (.ADD _ _ _)  => [true,  false, false, false, false, false, false, false, true]
  | some (.XOR _ _ _)  => [false, true,  false, false, false, false, false, false, true]
  | some (.SLT _ _ _)  => [false, false, true,  false, false, false, false, false, true]
  | some (.ADDI _ _ _) => [false, false, false, true,  false, false, false, false, true]
  | some (.BEQ _ _ _)  => [false, false, false, false, true,  false, false, false, true]
  -- ⬥ D2. The memory ops decode. `req` and `valid` come up on both; `isSW` alone
  -- drives the port's write-enable. This is the whole semantic content of D2.
  | some (.LW _ _ _)   => [false, false, false, false, false, true,  false, true,  true]
  | some (.SW _ _ _)   => [false, false, false, false, false, false, true,  true,  true]
  | none               => [false, false, false, false, false, false, false, false, false]

/-- ⬥⬥ **D2 — THE POSITIVE COUNTERPART OF M2's RETIRED GUARD.**

`ctrlSpec_not_decoded_of_touchesMem` said: a word `decode` accepts as a MEMORY op
is reported by this plane as *not decoded*. **This is that theorem's replacement
over the same hypothesis, and it says the opposite because the opposite became
true.** *Both port signals come up: `req` at index 7 and `valid` at index 8.*

🔑 ***A retirement that removes a stated property and adds none makes the file
quieter after the change than before it.*** *The guard was M2's way of making a
deliberate gap kernel-visible; this is D2's way of making the gap's CLOSURE
kernel-visible, and the pair is the record of what happened.* -/
theorem ctrlSpec_mem_is_decoded (w : BitVec 32) (i : Instr)
    (hd : decode w = some i) (ht : SaltWorks.ISA.touchesMem i = true) :
    (ctrlSpec w)[7]! = true ∧ (ctrlSpec w)[8]! = true := by
  simp only [ctrlSpec, hd]
  cases i
  case LW => exact ⟨rfl, rfl⟩
  case SW => exact ⟨rfl, rfl⟩
  all_goals exact absurd ht (by simp [SaltWorks.ISA.touchesMem])

/-- ⭐⭐ **THE SEAM TO D1b, COMPILER SIDE: `req` REALISES `touchesMem`.**

The plane's aggregate agrees with the ISA discriminator at **every** word —
including the undecodable ones, where both are false. *Math's `C3` states that
the `dmem_addr8` mask realises the kernel's trap semantics **exactly when** the
decoder drives `req` from `touchesMem`; that hypothesis is discharged here, so
the D2 ⊕ D1b composition is a theorem at BOTH ends rather than a promise at one.*

📌 *Why it holds on the nose: `decode`'s memory arms test OPCODE and FUNCT3 only
and all seven opcodes are pairwise distinct, so no earlier arm of the `if`-chain
can shadow `LW`/`SW`.* **The `none` branch is a real branch and is stated rather
than assumed away: on an undecodable word `req = false`, so the mask never
traps — correct, because there is no decoded memory op to trap on.** -/
theorem ctrlSpec_req_realises_touchesMem (w : BitVec 32) :
    (ctrlSpec w)[7]! = (match decode w with
                        | some i => SaltWorks.ISA.touchesMem i
                        | none   => false) := by
  unfold ctrlSpec
  cases h : decode w with
  | none => rfl
  | some i => cases i <;> rfl

/-- ⭐⭐ **AND THE PAIR PROPERTY: THE DECODER NEVER ASSERTS WRITE WITHOUT ACCESS.**

The RTL computes `we_out = we_in & req & ~misaligned & ~out_of_range`
(`dmem_addr8.v:81`). **A plane asserting `we_in` (index 6) WITHOUT `req` (index
7) would have every legitimate store silently suppressed by that `& req` guard —
`we_out` stuck low, `we_in` true, and no theorem about addresses able to see
it.** *An inert output is the failure mode a port-level proof cannot reach, so
the guarantee is stated on the side that can.* -/
theorem ctrlSpec_we_implies_req (w : BitVec 32) :
    (ctrlSpec w)[6]! = true → (ctrlSpec w)[7]! = true := by
  unfold ctrlSpec
  cases h : decode w with
  | none => simp
  | some i => cases i <;> simp

/-- The circuit's answer for a concrete word. -/
def ctrlOf (w : BitVec 32) : List Bool := sem decoder (fun i => w.getLsbD i)

/-- A word carrying only `opcode`, `funct3` and `funct7` — the projection. -/
def dcWord (op f3 f7 : Nat) : BitVec 32 :=
  BitVec.ofNat 32 (op ||| (f3 <<< 12) ||| (f7 <<< 25))

/-! ### The certificates -/

/-- Exhaustive over `(opcode, funct3)` at a fixed `funct7`. -/
def dcPlaneOK (f7 : Nat) : Bool :=
  (List.range 128).all fun op => (List.range 8).all fun f3 =>
    ctrlOf (dcWord op f3 f7) == ctrlSpec (dcWord op f3 f7)

/-- **All 1024 `(opcode, funct3)` pairs with `funct7 = 0`.** -/
theorem decoder_plane_f7_zero : dcPlaneOK 0 = true := by decide +kernel

/-- **All 1024 with `funct7 = 1`** — the non-zero representative. -/
theorem decoder_plane_f7_one : dcPlaneOK 1 = true := by decide +kernel

/-- **And `funct7` is read ONLY through "is it zero"**: exhaustive over all 128
values, at the one opcode where `funct7` is consulted. *This is what licenses
`funct7 = 1` standing for every non-zero `funct7`.* -/
def dcFunct7OK : Bool :=
  (List.range 128).all fun f7 => (List.range 8).all fun f3 =>
    ctrlOf (dcWord 0b0110011 f3 f7) == ctrlSpec (dcWord 0b0110011 f3 f7)

theorem decoder_funct7_exhaustive : dcFunct7OK = true := by decide +kernel

/-! ### Non-vacuity — the signals must not be constant -/

/-- Each of the seven is actually asserted by some word, `req` comes up on both
memory ops and on neither arithmetic one, and `valid` is false for some word.
*Without this the certificates are satisfied by an all-`false` decoder.*

⬥ **D2 ADDED THE `LW`/`SW` ROWS HERE IN THE SAME STROKE AS THE TABLE.** *A new
control bit certified only by the all-false word is a bit nothing tests: the
plane certificates would be perfectly happy with a `req` that never fires. The
words are built by `encode`, so they are the ISA's own and not hand-assembled.* -/
theorem decoder_signals_are_reachable :
    ctrlOf (encode (.ADD 3 1 2))
      = [true, false, false, false, false, false, false, false, true] ∧
    ctrlOf (encode (.XOR 3 1 2))
      = [false, true, false, false, false, false, false, false, true] ∧
    ctrlOf (encode (.SLT 3 1 2))
      = [false, false, true, false, false, false, false, false, true] ∧
    ctrlOf (encode (.ADDI 1 0 5))
      = [false, false, false, true, false, false, false, false, true] ∧
    ctrlOf (encode (.BEQ 1 2 4))
      = [false, false, false, false, true, false, false, false, true] ∧
    ctrlOf (encode (.LW 3 1 8))
      = [false, false, false, false, false, true, false, true, true] ∧
    ctrlOf (encode (.SW 1 2 8))
      = [false, false, false, false, false, false, true, true, true] ∧
    ctrlOf 0x000010B7#32
      = [false, false, false, false, false, false, false, false, false] := by
  decide +kernel

/-- **Dense SSA — the precondition for instantiating this block into `core`.**
`Compose.instOK` needs `ssa`, not merely `wf`: under `wf` alone the gate outputs
may be sparse and `instNext` would under-report the region occupied. *Checked
here rather than assumed at the assembly site.* -/
theorem decoder_ssa : decoder.ssa = true := by decide +kernel

/-! ### ⬥⬥ D2 — THE POSITIONAL STATEMENTS

⚠️ **WHY THESE EXIST, AND WHY THE EXHAUSTIVE CERTIFICATES ABOVE CANNOT REPLACE
THEM.** `dcPlaneOK` compares `ctrlOf w` against `ctrlSpec w` — it constrains the
PAIR and never either side alone. ⇒ ***Any mutation applied consistently to
circuit AND spec preserves it: the 2048+128 points stay TRUE, stay GREEN, and are
SILENT about length, order and position.*** *That is their correct scope, not a
defect — but it is why a re-point needs anchors that name positions outright.*

📌 *The same silence covers `decoder_correct` and its corollaries downstream: a
statement mentioning no literal and no length cannot testify to a change that is
entirely about literals and lengths.* -/

/-- ✅ **N1 — LENGTH.** *Nine, stated so that a re-point cannot be quiet: a
naming theorem survives bits moving, a length theorem does not.* -/
theorem ctrlSpec_length (w : BitVec 32) : (ctrlSpec w).length = 9 := by
  unfold ctrlSpec; split <;> rfl

/-- ✅ **`valid` IS EXACTLY "THE WORD DECODES".** *The sentence that closes M2's
divergence: the kernel decoder and this plane are the same partial function
again.* -/
theorem ctrlSpec_valid_iff_decodes (w : BitVec 32) :
    (ctrlSpec w)[8]! = (decode w).isSome := by
  unfold ctrlSpec
  cases h : decode w with
  | none => rfl
  | some i => cases i <;> rfl

/-- ✅ **SLICE A IS UNDISTURBED BY THE MEMORY OPS, SPEC SIDE.** A word that
decodes to `LW` or `SW` leaves all five op-class bits false. *Together with the
net-level prefix below this is what makes `C1Organ`'s positional reads safe
across D2 — and it is stated over the `touchesMem` hypothesis so a third memory
op inherits it rather than needing a new theorem.* -/
theorem ctrlSpec_sliceA_clear_of_touchesMem (w : BitVec 32) (i : Instr)
    (hd : decode w = some i) (ht : SaltWorks.ISA.touchesMem i = true) :
    (ctrlSpec w).take dcSliceA = [false, false, false, false, false] := by
  simp only [ctrlSpec, hd]
  cases i
  case LW => rfl
  case SW => rfl
  all_goals exact absurd ht (by simp [SaltWorks.ISA.touchesMem])

/-- ✅ **N3 — PREFIX STABILITY, NET LEVEL.** The five slice-A matcher nets are
exactly where they were before D2. *`C1Organ:223/232` read output nets 1 and 2 by
index; this is the theorem that says D2 did not move them.* -/
theorem decoder_out_prefix :
    decoder.outs.take dcSliceA = [79, 95, 111, 120, 129] := by decide +kernel

/-- ⭐⭐ **N2 — `req` INSERTS BEFORE `valid`, AND `valid` KEEPS THE TAIL.**

*This is the theorem that the alternative spelling `outs ++ [v, req]` would have
falsified while still building, still appending, and still having length 9.*
⇒ **It is the kernel-checkable form of the rule in this file's header, and it
becomes load-bearing for every future control bit rather than only for `req`.** -/
theorem decoder_valid_rides_the_tail :
    decoder.outs[7]! = 148 ∧ decoder.outs[8]! = 154 ∧
    decoder.outs.getLast? = some 154 := by decide +kernel

/-- ⭐ **THE APPEND DISCIPLINE, AS A THEOREM — and it is the COST-CONTROL
property, not only a correctness one.**

Laying out just the slice-A rows reproduces the head of the full gate list
exactly. ⇒ ***So `dcG1…dcG5` and everything proved about them in
`Stack/Program.lean` — roughly 25 net-numbered declarations — are preserved by
CONSTRUCTION rather than by luck.*** *An insertion anywhere but the end re-nets
all of them and invalidates the certificate suite this file warns about at
`dcInvs`; that warning is why D2 appended.* -/
theorem decoder_gate_prefix :
    decoder.gates.take (dcInvs.length + (dcLayout dcBase (dcMatches.take dcSliceA)).1.length)
      = dcInvs ++ (dcLayout dcBase (dcMatches.take dcSliceA)).1 := by
  decide +kernel

#audit_axioms decoder_ssa
#audit_axioms dcIn
#audit_axioms dcNot
#audit_axioms dcInvs
#audit_axioms andChain
#audit_axioms orChain
#audit_axioms dcLit
#audit_axioms dcField
#audit_axioms dcMatches
#audit_axioms dcLayout
#audit_axioms decoder
#audit_axioms decoder_wf
#audit_axioms ctrlSpec
#audit_axioms ctrlSpec_mem_is_decoded
#audit_axioms ctrlSpec_req_realises_touchesMem
#audit_axioms ctrlSpec_we_implies_req
#audit_axioms ctrlSpec_length
#audit_axioms ctrlSpec_valid_iff_decodes
#audit_axioms ctrlSpec_sliceA_clear_of_touchesMem
#audit_axioms decoder_out_prefix
#audit_axioms decoder_valid_rides_the_tail
#audit_axioms decoder_gate_prefix
#audit_axioms dcSliceA
#audit_axioms ctrlOf
#audit_axioms decoder_plane_f7_zero
#audit_axioms decoder_plane_f7_one
#audit_axioms decoder_funct7_exhaustive
#audit_axioms decoder_signals_are_reachable
#audit_axioms andChain_nil_is_word_bit_zero orChain_nil_is_word_bit_zero
#audit_axioms dcMatches_all_nonempty dcMatches_literal_counts

end SaltWorks.HDL

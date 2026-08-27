/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.StateCodecD
import SaltWorks.HDL.AdapterStateOrgan

/-!
# `stalls` EXHIBITED at the widened layout, and proved equal to `¬retire`

**satisfiable is not satisfied.** silicon established that criterion (c) becomes satisfiable once
the ratified widening puts `retire`'s three adapter bits into `Env`. **This file supplies the
function and proves the equation** — the step that converts one into the other.

```
retire = f(kind, storeBeat, req)        kind 2 bits, storeBeat 1 — ADAPTER registers
the widening                            stWidthFull = stWidthD + 3 = 1316, RATIFIED 2026-08-26
so the three bits live at               stWidthD, stWidthD+1, stWidthD+2
and the instruction word at             instrBaseFull = stWidthFull
```

## ⛔⛔ WHAT THIS FILE DOES **NOT** DO — read this before quoting it

***IT DOES NOT PLACE THE THREE BITS.*** Nothing here says the emitted circuit DRIVES those nets
with the adapter's state; `core.outs` does not carry them yet. **What is proved is that a
`stalls : Env → Bool` EXISTS at the widened layout and equals `¬retire` for the state its nets
encode.** The remaining obligation is the placement, and it is named rather than assumed.

⛔⛔ **CORRECTED 2026-08-26 21:1x — THIS SENTENCE SAID THE PLACEMENT "WAITS ON THE
`Netlist → Circ` BRIDGE". IT DOES NOT, AND IT NEVER DID.** silicon measured it and this seat
confirmed at its own hand with a control: **`NetlistBridge` is imported by ZERO modules** (the
same query returns 2 for `AdapterStateOrgan`, so it can return non-zero). `core` is assembled
from Lean-defined organs through `instGates`; nothing on the placement path calls `bridge`.
**What actually blocks the placement is named in `CoreAssemblyD`'s own header: memOrgan's
292-input σ, `instOK memOrgan _ _`, and the trap bit, which has no gate-level producer in any
landed module.** The bridge is what the netlist ↔ Lean CORRESPONDENCE needs — a different
obligation, on a different object. *Two things wore one noun, and the wrong one got blamed for
nine days.*

⇒ **So this discharges "exhibit the function and prove the equation" and NOTHING ELSE.** A reader
who takes it as "T2 is satisfied" has read one step further than the file goes.

## ⛔ AND A SECOND UNPLACED ASSUMPTION, FOUND WHILE WRITING THIS AND NOT SMOOTHED OVER

`reqAt` below reads the instruction word **at `instrBaseFull` in `Env`** — the word PRESENTED.
The RTL's `c_dmem_req` is *"a PURE DECODE of the instruction still held in `instr_r`"*
(`busadapt8.v:99-100`), and `busadapt8.v:126-131` says in silicon's own words:

> *"`instr_r` is written on the phase-3 edge and `kind`/`store_beat` update on that SAME edge, so
> this decision reads a `c_dmem_req` derived from the PREVIOUS instruction. Whether that is
> off-by-one or exactly right I have not proved."*

⇒ ***THE `req` CORRESPONDENCE IS UNSETTLED UPSTREAM OF THIS FILE.*** If it is off by one, the
equation below still holds — it is stated over whatever `reqAt` returns — but the FUNCTION would
be reading the wrong word, and no theorem here would notice. **That is a second obligation, it is
silicon's, and it sits beside the placement rather than inside it.**

## ⭐ AMENDED 2026-08-26 20:3x — BOTH HALVES OF THE PARAGRAPH ABOVE HAVE MOVED

The text above is kept as written, because it is the record of what this file knew. Two things
changed after it, and neither is visible from inside this module:

**1. THE RTL SIDE IS MEASURED** (silicon `45c9c56`, 19:46:52). The instruction bypass presents the
newly assembled word at exactly `kind == T_FETCH && phase == 2'd3`, and `loop_end` IS phase 3, so
the decode at the decision edge reads the CURRENT instruction. Driven both ways by a committed
runner: as shipped 6/6 PASS, bypass defeated RED at 2/6 reproducing the recorded 08/18 signature.
⛔ *This settles the RTL side only. The netlist ↔ Lean correspondence is unproved, and THAT is
what the bridge is for — not the placement.* ⚠️ **This very sentence carried the false claim
forward: I wrote it at 20:3x while correcting the paragraph above it, and re-asserted the
adjacent error in the same edit. A CORRECTION PASS IS EXACTLY WHERE A NEIGHBOURING FALSEHOOD GETS
RE-CERTIFIED, because the sentence next to the one you are fixing reads as already checked.**

**2. "NO THEOREM HERE WOULD NOTICE" WAS TRUE, AND THE REASON IS STRUCTURAL** —
`stallsAt_eq_not_retire` carries `reqAt e` on BOTH sides, so it is an IDENTITY in `req` and holds
for every word source whatsoever. ***A THEOREM THAT MENTIONS THE SUSPECT QUANTITY ON BOTH SIDES OF
ITS OWN EQUATION IS NOT EVIDENCE ABOUT THAT QUANTITY.*** `SaltWorks/HDL/ReqWordSource.lean` supplies
the theorems that DO notice: confinement to the fetch state, sensitivity at it, and an IFF naming
the discriminating set exactly.

⛔ **AND ONE OF THIS FILE'S OWN WITNESSES WAS CAUGHT BY THAT AUDIT.** `stallsAt_is_middle` below
exhibits its middle at two STORE states, where `retire` provably ignores `req` — so those two
equations hold for EVERY word source, and the witness cannot bear weight about the word. It is left
exactly as it stands (it is true, and the stall set is a genuine middle); the missing FETCH-state
arm lives in `ReqWordSource` as `stalls_is_middle_at_fetch`.

📌 CITATION DRIFT, since this file names line numbers in another lane's live file: the struck
paragraph quoted above is now `busadapt8.v:130-136`, and the answer runs from `:137`. `:99-100` is
unmoved. silicon placed the strike header at `:126-129` — exactly where this file's citation
pointed — for the stated reason that compiler cites those lines.
-/

namespace SaltWorks.HDL.StallsAtWidened
open SaltWorks.HDL SaltWorks.HDL.StateCodecD SaltWorks.HDL.BusFSM SaltWorks.HDL.AdapterStateOrgan

/-! ## §1 — THE THREE NETS, AT THE RATIFIED LAYOUT -/

/-- `kind` high bit. Order follows the organ's `outs = [k1', k0', b']`. -/
def kind1Net : Net := stWidthD
def kind0Net : Net := stWidthD + 1
def beatNet  : Net := stWidthD + 2

/-- ⛔ The three adapter nets are INSIDE the widened state and BELOW the instruction word —
so they collide with neither the D-regime state nor the fetched word. -/
theorem adapter_nets_are_in_the_state :
    (stWidthD ≤ kind1Net ∧ beatNet < stWidthFull) ∧ stWidthFull ≤ instrBaseFull := by
  decide +kernel

/-- The inverse of silicon's `encKind`. -/
def decKind : Bool → Bool → Kind
  | false, false => .idle
  | false, true  => .fetch
  | true,  false => .load
  | true,  true  => .store

theorem decKind_encKind (k : Kind) : decKind (encKind k).1 (encKind k).2 = k := by
  cases k <;> rfl

/-! ## §2 — THE EXHIBITED FUNCTION -/

/-- The adapter's state, READ OUT OF `Env`. This is the thing that did not exist before the
widening: three bits of `retire`'s domain, now addressable as nets. -/
def adapterAt (e : Env) : BusState := ⟨decKind (e kind1Net) (e kind0Net), e beatNet⟩

/-- `req` — the memory-access strobe. `busadapt8.v` derives it as a PURE DECODE of the presented
instruction, so at the kernel it is an ISA-level property of the word, not extra state. -/
def reqOfWord (w : BitVec 32) : Bool :=
  match SaltWorks.ISA.decode w with
  | some (.LW _ _ _) => true
  | some (.SW _ _ _) => true
  | _                => false

/-- The instruction word at the WIDENED base — not `instrBase`, which the renumbering moved. -/
def seenWordFull (e : Env) : BitVec 32 := wordOf (fun k => e (instrBaseFull + k))

def reqAt (e : Env) : Bool := reqOfWord (seenWordFull e)

/-- ⭐⭐ **THE STALL FUNCTION, EXHIBITED.** A total `Env → Bool`, no adapter state left outside
its domain. -/
def stallsAt (e : Env) : Bool := !(retire (adapterAt e) (reqAt e))

/-! ## §3 — THE EQUATION -/

/-- ⭐⭐⭐ **`stallsAt` IS `¬retire`** for the state its three nets encode. This is the step
from SATISFIABLE to SATISFIED, modulo the placement named in the header. -/
theorem stallsAt_eq_not_retire (s : BusState) (e : Env)
    (h1 : e kind1Net = (encKind s.kind).1)
    (h0 : e kind0Net = (encKind s.kind).2)
    (hb : e beatNet  = s.storeBeat) :
    stallsAt e = !(retire s (reqAt e)) := by
  simp only [stallsAt, adapterAt, h1, h0, hb, decKind_encKind]

/-! ## §4 — NON-VACUITY, AND A CONTROL THAT MUST FAIL -/

/-- An `Env` carrying a chosen adapter state; everything else from `pad`. -/
def envWithAdapter (s : BusState) (pad : Env) : Env := fun j =>
  if j = kind1Net then (encKind s.kind).1
  else if j = kind0Net then (encKind s.kind).2
  else if j = beatNet then s.storeBeat
  else pad j

theorem envWithAdapter_reads_back (s : BusState) (pad : Env) :
    adapterAt (envWithAdapter s pad) = s := by
  have h1 : envWithAdapter s pad kind1Net = (encKind s.kind).1 := by
    show (if kind1Net = kind1Net then _ else _) = _
    rw [if_pos rfl]
  have h0 : envWithAdapter s pad kind0Net = (encKind s.kind).2 := by
    show (if kind0Net = kind1Net then _ else if kind0Net = kind0Net then _ else _) = _
    rw [if_neg (by decide), if_pos rfl]
  have hb : envWithAdapter s pad beatNet = s.storeBeat := by
    show (if beatNet = kind1Net then _ else if beatNet = kind0Net then _ else
            if beatNet = beatNet then _ else _) = _
    rw [if_neg (by decide), if_neg (by decide), if_pos rfl]
  show (⟨decKind _ _, _⟩ : BusState) = s
  rw [h1, h0, hb, decKind_encKind]

/-- ⭐ **THE STALL SET IS A GENUINE MIDDLE at the widened layout** — the store's address beat
stalls and its data beat does not, so this instantiation is neither corner. -/
theorem stallsAt_is_middle (pad : Env) :
    stallsAt (envWithAdapter ⟨Kind.store, false⟩ pad) = true
      ∧ stallsAt (envWithAdapter ⟨Kind.store, true⟩ pad) = false := by
  constructor
  · rw [stallsAt, envWithAdapter_reads_back]; rfl
  · rw [stallsAt, envWithAdapter_reads_back]; rfl

/-- ⛔ **THE CONTROL — a decoder that swaps the two kind bits must NOT satisfy the equation.**
Without this, §3 could be passing on a decoder that ignores its inputs. -/
def decKindSwapped : Bool → Bool → Kind
  | false, false => .idle
  | false, true  => .load
  | true,  false => .fetch
  | true,  true  => .store

theorem control_swapped_decoder_disagrees :
    ¬ (∀ k : Kind, decKindSwapped (encKind k).1 (encKind k).2 = k) := by
  intro h
  have := h Kind.fetch
  exact absurd this (by decide)

#audit_axioms adapter_nets_are_in_the_state decKind_encKind
#audit_axioms adapterAt reqOfWord seenWordFull reqAt stallsAt
#audit_axioms stallsAt_eq_not_retire envWithAdapter_reads_back
#audit_axioms stallsAt_is_middle control_swapped_decoder_disagrees

end SaltWorks.HDL.StallsAtWidened

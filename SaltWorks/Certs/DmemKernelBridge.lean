/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
/-
# F4 — THE BRIDGE: THE EMITTED WRITE STROBE IMPLIES A DECODED MEMORY OP

Stage ③ door 1's exit criterion. **The two halves of this join live in DISJOINT import
cones and neither can state it**: `DmemAddr8Suppress` imports exactly one module (the
netlist datum) and can reach no ISA or kernel name; `HDL.Decoder` knows nothing of nets.
So the bridge lives here, in the first module that imports both.

⛔ **WHAT THIS THEOREM DOES NOT DO, SAID FIRST BECAUSE IT IS THE WHOLE DIFFICULTY.** It
does not PROVE the port map. Nothing in either cone does — the binding of `ins 33` to the
decoder's write bit is a fact about WIRING, and a wiring fact cannot be derived from either
side alone. It is therefore an explicit HYPOTHESIS (`DriveMap`), and the theorem says: *if
the plane is wired thus, then the gate-level strobe implies the ISA-level memory op.*

⭐ **WHY THE HYPOTHESIS IS READABLE RATHER THAN A BARE INDEX ASSERTION** — and this is what
silicon's `3a35343` bought. Without it, `DriveMap` would assert `ins 33 = …` and a reader
would have to trust that 33 means the write port. With it, the datum's OWN recorded name
table says so:

    dmemAddr8_we_in_is_index_33 : dmemAddr8NL_in_names.getD 33 "" = "we_in"
    dmemAddr8_req_is_index_32   : dmemAddr8NL_in_names.getD 32 "" = "req"

and the decoder's side is stated in `Decoder.lean:300-306`: `isSW` (index 6) *"reaches the
port's `we_in` directly"*, `req` (index 7) is the access strobe. **The numerals are tied to
declared port NAMES at both ends; only the plane's wiring is assumed.**

⚠️ **A SEAM THEOREM SAYS WHAT CROSSES, NOT WHAT CANNOT.** This one carries the strobe
across and nothing else: it is silent about addresses, about timing, and about whether the
op that touches memory is the RIGHT one. `instOK`-style certification of the wrong wire is
exactly what an assumed port map buys you, which is why the assumption is a named structure
rather than a `rfl` hidden in a proof.
-/
import SaltWorks.HDL.Decoder
import SaltWorks.Silicon.Equiv.DmemAddr8Suppress

namespace SaltWorks.Certs

open SaltWorks.HDL
open SaltWorks.ISA
open SaltWorks.Silicon.Imported

/-- **THE PORT MAP, NAMED.** The plane drives the datum's `we_in` (input 33) from the
decoder's `isSW` bit and its `req` (input 32) from the decoder's access strobe. This is a
fact about the wiring; it is assumed here and proved nowhere, deliberately. -/
structure DriveMap (w : BitVec 32) (ins : Nat → Bool) : Prop where
  we  : ins 33 = (ctrlSpec w)[6]!
  req : ins 32 = (ctrlSpec w)[7]!

/-- ⭐⭐ **F4, DOOR 1 — THE EMITTED `we_out` IMPLIES THE DECODED INSTRUCTION TOUCHES
MEMORY.** The gate-level write strobe cannot rise for a word the kernel does not decode as
a memory operation. -/
theorem dmem_we_out_implies_decoded_touchesMem
    (w : BitVec 32) (ins : Nat → Bool) (hmap : DriveMap w ins)
    (h : (dmemAddr8_env ins).getD 78 false = true) :
    (match decode w with
     | some i => SaltWorks.ISA.touchesMem i
     | none   => false) = true := by
  have hpair := dmemAddr8_we_out_implies_store_requested ins h
  have h32 : ins 32 = true := by
    simp only [Bool.and_eq_true] at hpair
    exact hpair.2
  have hreq : (ctrlSpec w)[7]! = true := by rw [← hmap.req]; exact h32
  have hmatch := ctrlSpec_req_realises_touchesMem w
  rw [hmatch] at hreq
  exact hreq

/-- **AND THE KERNEL'S PAIR PROPERTY AGREES WITH THE GATES.** The datum refuses to raise
`we_out` without both inputs; the decoder refuses to assert its write bit without the
access strobe. Two independent statements of one discipline, now on one page. -/
theorem dmem_drive_is_consistent_with_decoder
    (w : BitVec 32) (ins : Nat → Bool) (hmap : DriveMap w ins)
    (hwe : ins 33 = true) :
    ins 32 = true := by
  rw [hmap.req]
  rw [hmap.we] at hwe
  exact ctrlSpec_we_implies_req w hwe

end SaltWorks.Certs

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Certs.dmem_we_out_implies_decoded_touchesMem
  SaltWorks.Certs.dmem_drive_is_consistent_with_decoder
end Audit

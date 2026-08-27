/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.BusFSM

/-!
# Is T2 consistent with the wire T5 measured?

**This file is RATIFICATION EVIDENCE for `docs/retire-two-contracts-0826.md`, and it is tracked
for that reason.** The helm's order was explicit: *"if the two contracts turn out NOT to be
consistent, that stops the ratification and outranks the document."* So this does not argue that
they agree — **it tries to break the pair, using silicon's own FSM model rather than my reading
of it**, and reports what survived.

The helm's order: "if the two contracts turn out NOT to be consistent, that stops the
ratification and outranks the document." So this file tries to BREAK the pair, using
silicon's own FSM model rather than my reading of it.

T2 says the core advances exactly when `retire` is high — `stalls := ¬retire`. That is a claim
ABOUT THE WIRE, and the part of it decidable from `BusFSM` alone is this: **retire must be
EXACTLY the frame-end.** If retire could ever be high without the frame ending, the core would
advance mid-operation and T2 would be false against the very wire T5 measured.

⛔ **HISTORICAL NOTE, KEPT BECAUSE THIS FILE OUTLIVED THE CLAIM IT WAS WRITTEN UNDER.** When it
was written T2 read *"retire is exactly not presenting a bubble"*, and that reading was REFUTED by
the RTL the same day (`busadapt8.v:215` holds the previous instruction; nothing drives a bubble
anywhere; `plane32bus.v:73` stalls the core with `en`). **The theorems below never depended on it**
— they are about the FSM's own transition — and the instantiation moved to `¬retire` without a
line of proof changing. ***What this file never claimed is what died.***

## ⛔ WHAT THIS FILE DOES **NOT** SETTLE — the residue, named rather than implied

`BusFSM` decides the FSM's transition; it does not decide what reaches `Env`. So the SUPPLY of
the parameter — getting `retire`'s three adapter bits (`kind`, `storeBeat`) into `Env` through the
ratified widening — **is not decidable here and is not claimed here.** What IS established is the
anchor it hangs on: retire coincides exactly with the frame-end, so `stalls := ¬retire` cannot put
the core's advance on the wrong beat. ⇒ **THE REMAINING STEP IS THE WIDENING, AND IT IS RATIFIED.**
-/

namespace SaltWorks.HDL.T2Consistency
open SaltWorks.HDL.BusFSM

/-- ⭐⭐ **THE ANCHOR: `retire` IS EXACTLY THE LOOP-END.** Exhaustive over all 8 states x
req x we. If this were false in ONE cell, T2 would be claiming the core advances on a beat where
the frame is still running. -/
theorem retire_iff_frame_ends :
    (allStates.all fun s => [true, false].all fun req => [true, false].all fun we =>
      (retire s req) == (next s req we == ⟨Kind.fetch, false⟩)) = true := by
  decide +kernel

/-- **THE NEGATIVE CONTROL — the same shape against a MUTATED retire must FAIL.** Without
this the theorem above could be passing on a vacuous quantifier. -/
def retireMut (s : BusState) (_req : Bool) : Bool :=
  match s.kind with
  | .fetch => true
  | .load  => true
  | .store => s.storeBeat
  | .idle  => true

theorem control_mutant_breaks_the_anchor :
    (allStates.all fun s => [true, false].all fun req => [true, false].all fun we =>
      (retireMut s req) == (next s req we == ⟨Kind.fetch, false⟩)) = false := by
  decide +kernel

/-- ⭐ **THE STORE IS THE CASE THAT COULD HAVE BROKEN IT.** T5: retire is LOW on the address
beat and HIGH on the data beat. T2: the core is HELD on the address beat and ADVANCES on the
data beat. Both readings must name the SAME beat, or one instruction would retire twice. -/
theorem store_retires_on_the_second_beat_only :
    (retire ⟨Kind.store, false⟩ true = false)
      ∧ (retire ⟨Kind.store, true⟩ true = true) := by
  decide +kernel

/-- ⭐ **AND A FETCH WITH A REQUEST IN FLIGHT DOES NOT RETIRE** — so the core is held while
memory is being reached, which is exactly the beat T2 needs to be a stall. -/
theorem fetch_with_request_holds :
    retire ⟨Kind.fetch, false⟩ true = false := by decide +kernel

#audit_axioms retire_iff_frame_ends control_mutant_breaks_the_anchor
#audit_axioms store_retires_on_the_second_beat_only fetch_with_request_holds

end SaltWorks.HDL.T2Consistency

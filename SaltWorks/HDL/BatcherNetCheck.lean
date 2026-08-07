/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.BatcherNet
import SaltWorks.Stack.ZeroOne

/-!
# BB-1 · B2 — the transcription check, and the ONLY module that pays for it

`BatcherNet.lean` transcribes `batcher8`'s 24 comparators rather than importing
them, because `SaltWorks/Stack/ZeroOne.lean` uses `LinearOrder` and therefore
Mathlib, and **leg 2 is deliberately Mathlib-free** (6 jobs, no competition for
the fleet lock).

⛔ **A transcription without a check is the `hbKappa` failure exactly: two
records with a common ancestor, agreeing because one was copied from the other.**
So the check lives here, and **this module is the only place in leg 2 that pays
the Mathlib cost.** *That is math's own `Bridge.lean` move — the dependency
boundary drawn where the conceptual boundary already is.*
-/

namespace SaltWorks.HDL

/-- **The transcription is faithful.** If `batcher8` ever changes — a different
sorter, a reordered layer — this goes red and `BatcherNet` must follow. -/
theorem bnComps_eq_batcher8 :
    bnComps = SaltWorks.Stack.batcher8.map (fun c => (c.1.val, c.2.val)) := by
  decide +kernel

#audit_axioms bnComps_eq_batcher8

end SaltWorks.HDL

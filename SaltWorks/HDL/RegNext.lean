/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.RegWrite
import SaltWorks.HDL.Compose

/-!
# C4 · `core` — THE REGISTER-FILE NEXT-STATE ARRAY

Fourth block of `compile`/`core`, and **the bulk of the core by gate count**:

```
next[r][k]  =  we[r] ? result[k] : cur[r][k]
32 inverters + 3 × 1024 mux gates  =  3,104 gates
```

**This is `St.set` as hardware.** `St.set rd v` writes one register and leaves
the other 31 alone; the array does the same by broadcasting `result` to every
register and letting `we` decide who latches it. *That is silicon's asymmetry
from the other side: the write path is wide but shallow, because the selection
happens in the ENABLE and never in the data.*

## ⛔ THE FINDING THIS BLOCK PRODUCED, WHICH IS WORTH MORE THAN THE BLOCK

**My first version certified the WHOLE ARRAY by `decide +kernel`. It died:**

```
libc++abi: … lean::memory_exception: excessive memory consumption detected
                                     at 'interpreter'
saltbuild EXIT=134
```

*That is M-2.1's definitive string, so it is a genuine memory event and no
differential test is needed to classify it.* **Two separate O(n²) walls, both
reached at core scale:**

1. **`Circ.wf` contains `nodupB (c.gates.map Gate.out)`** — quadratic in the
   gate count. At 3,104 gates that is ~9.6 M comparisons **inside the kernel**.
2. **`sem` is `c.outs.map (run ins c.gates)`**, and `run` builds an environment
   as a chain of updates, so **each output lookup walks the gate list**:
   1,024 outputs × 3,104 gates ≈ **3.2 M** per input vector, ×33 vectors.

⇒ ***A core-sized `Circ` cannot be certified as ONE circuit by kernel
evaluation, and `ReadTree.lean` hit the same wall from the other direction —
its `muxCount` oracle check is `#eval` for exactly this reason.***

⭐ **AND THAT IS SILICON'S CONE CENSUS ARRIVING IN CONSTRUCTION RATHER THAN IN
MEASUREMENT.** Their 10:15 result — *a 5,266-cell design decomposes into 151
obligations, max cone 24, median 3* — is not a nice property of the flow. **It
is the only way the core gets certified at all.** *The whole-array theorem was
never going to exist, and I would have discovered that at C4 rather than here if
this block had been smaller.*

📌 **So the certificates below are the honest shape: the generator is
PARAMETERISED, kernel-certified at small `R`/`W` where exhaustive is feasible,
and MEASURED by `#eval` at full size.** The full-size array's correctness rests
on the generator being uniform in `r` and `k` — which is visible in `rnMux` and
is the same argument the per-cone decomposition makes formal.

⚠️ **`cur` is a per-register pseudo-random pattern, not a constant.** A constant
`cur` would let a mux that reads the wrong register pass undetected — every
register would hold the same bits, so reading the wrong one is invisible. *Same
failure as an oracle match that agrees for a reason unrelated to correctness.*
-/

namespace SaltWorks.HDL

/-! ### The parameterised generator -/

section
variable (R W : Nat)

/-- `we[r]` on `0 … R-1`. -/
def rnWe (r : Nat) : Net := r
/-- `result[k]` on `R … R+W-1` — broadcast to every register. -/
def rnRes (k : Nat) : Net := R + k
/-- `cur[r][k]`, in `StateCodec`'s register-major order. -/
def rnCur (r k : Nat) : Net := R + W + W * r + k
def rnIn : Nat := R + W + R * W
/-- `¬we[r]`, one per register, shared across its `W` bits. -/
def rnNotWe (r : Nat) : Net := rnIn R W + r
def rnBase : Nat := rnIn R W + R

def rnMuxBase (r k : Nat) : Nat := rnBase R W + 3 * (W * r + k)
def rnOut (r k : Nat) : Net := rnMuxBase R W r k + 2

/-- One mux: three gates, output third. **Uniform in `r` and `k`** — the
uniformity the small-instance certificates rely on. -/
def rnMux (r k : Nat) : List Gate :=
  [ ⟨rnMuxBase R W r k,     .and (rnNotWe R W r) (rnCur R W r k)⟩
  , ⟨rnMuxBase R W r k + 1, .and (rnWe r) (rnRes R k)⟩
  , ⟨rnOut R W r k,         .or (rnMuxBase R W r k) (rnMuxBase R W r k + 1)⟩ ]

/-- The array at `R` registers of `W` bits. -/
def regNextN : Circ :=
  { nIn := rnIn R W
    gates := (List.range R).map (fun r => (⟨rnNotWe R W r, .not (rnWe r)⟩ : Gate))
               ++ (List.range R).flatMap (fun r => (List.range W).flatMap (rnMux R W r))
    outs := (List.range R).flatMap fun r => (List.range W).map (rnOut R W r) }

end

/-- **The core's array: 32 registers of 32 bits.** -/
def regNext : Circ := regNextN 32 32

/-! ### Driving it -/

def rnCurPat (r k : Nat) : Bool := Nat.testBit (r * 2654435761 + 12345) k
def rnResPat (k : Nat) : Bool := Nat.testBit 0xA5A5A5A5 k

def rnRun (R W : Nat) (we : Nat → Bool) : List Bool :=
  sem (regNextN R W) (fun i =>
    if i < R then we i
    else if i < R + W then rnResPat (i - R)
    else rnCurPat ((i - R - W) / W) ((i - R - W) % W))

def rnSpec (R W : Nat) (we : Nat → Bool) : List Bool :=
  (List.range R).flatMap fun r =>
    (List.range W).map fun k => if we r then rnResPat k else rnCurPat r k

/-! ### Kernel certificates, at sizes where exhaustive is feasible -/

/-- **`R = W = 4`: EVERY one of the 16 write-enable vectors**, not just one-hot —
so an array that mishandled two simultaneous enables would be caught. -/
def rnAllWeOK : Bool :=
  (List.range 16).all fun m =>
    rnRun 4 4 (fun r => Nat.testBit m r) == rnSpec 4 4 (fun r => Nat.testBit m r)

theorem regNext4_correct_on_all_enables : rnAllWeOK = true := by decide +kernel

theorem regNext4_wf : (regNextN 4 4).wf = true := by decide +kernel

/-- **`R = W = 8`: one-hot at every register, plus the all-zero vector.** -/
def rnOneHotOK : Bool :=
  ((List.range 8).all fun r0 => rnRun 8 8 (· == r0) == rnSpec 8 8 (· == r0))
    && (rnRun 8 8 (fun _ => false) == rnSpec 8 8 (fun _ => false))

theorem regNext8_correct : rnOneHotOK = true := by decide +kernel

theorem regNext8_wf : (regNextN 8 8).wf = true := by decide +kernel

/-- **THE NOP-ADVANCE PATH HOLDS STATE** — the ratified semantics, at the array. -/
theorem regNext8_no_enable_holds_state :
    rnRun 8 8 (fun _ => false)
      = (List.range 8).flatMap (fun r => (List.range 8).map (rnCurPat r)) := by
  decide +kernel

/-- **THE FRAME CONDITION** — enabling register 5 changes register 5 and nothing
else. *This is the property `St.set` has and a broadcast bus could lose.* -/
theorem regNext8_writes_only_the_enabled :
    ((List.range 8).all fun r => (List.range 8).all fun k =>
      (rnRun 8 8 (· == 5)).getD (8 * r + k) false
        == (if r == 5 then rnResPat k else rnCurPat r k)) = true := by decide +kernel

/-- **NON-VACUITY** — the written value differs from what was there, at every
register. *Without this, the certificates are satisfied by a plain wire.* -/
theorem rnPatterns_differ :
    ((List.range 8).all fun r =>
      (List.range 8).any fun k => rnResPat k != rnCurPat r k) = true := by
  decide +kernel

/-! ### Full size — MEASURED, not proved, and labelled as such

*`#eval`, deliberately: see the finding in the header. These are the numbers
that must match the flow's cell count downstream; they are not theorems and
nothing should cite them as if they were.* -/

-- 32 inverters + 3 x 1024 muxes = 3104.  MEASURED: 3104.
#eval regNext.gates.length
-- 32 registers x 32 bits.  MEASURED: 1024.
#eval regNext.outs.length
-- 32 we + 32 result + 1024 current.  MEASURED: 1088.
#eval regNext.nIn


/-! ## ⭐ WELL-FORMEDNESS — AND THE O(n²) WALL, MEASURED ON BOTH SIDES

**This circuit is the one the campaign recorded as the wall.** `Circ.wf`'s
`nodupB` is O(n²), and this seat's 8/7 note reads *"a core-sized `Circ` CANNOT be
certified as one circuit — `EXIT=134` at 3,104 gates."* ⇒ ***That was a citation.
Here is the differential, run today on this machine at the module build's own
budget:***

```
route                                    budget      result
decide +kernel  on  wf   (direct)        -M 20000    EXIT=134, memory_exception
                                                     "excessive memory
                                                     consumption at 'interpreter'"
                                                     after 76 s
Circ.wf_of_ssa  on  ssa  (structural)    -M 20000    PROVED, ~5 s
```

**Same circuit, same claim, same machine, same cap. One route dies and the other
closes.** *The first run was at `-M 6000` and also died; it was re-run at 20000
because a wall measured at MY OWN cap would be the adjacent object rather than the
wall.*

🔑 **WHY THE STRUCTURAL ROUTE IS CHEAP: `ssa` is a LINEAR scan** — gate `i`'s
output must be exactly `base + i` and its fanin below it — **whereas `wf` asks
`nodupB`, which compares every output against every other.** *The density that
`ssa` demands is precisely what makes the distinctness `wf` demands free, so the
quadratic never has to be walked.*

📌 **Note the failure site: `at 'interpreter'`, not `(kernel)`.** *The
`hdl-cap-rule-M2` note records the two diagnostic texts; this is the elaboration
site rather than the kernel one, and the rule's own advice applies — classify by
the DIFFERENTIAL, not by the string.* -/

theorem regNext_ssa : regNext.ssa = true := by decide +kernel

/-- **`wf` for a circuit `decide` cannot reach.** -/
theorem regNext_wf : regNext.wf = true := Circ.wf_of_ssa regNext_ssa

#audit_axioms rnWe
#audit_axioms rnCur
#audit_axioms rnIn
#audit_axioms rnMux
#audit_axioms regNextN
#audit_axioms regNext
#audit_axioms regNext_ssa
#audit_axioms regNext_wf
#audit_axioms rnRun
#audit_axioms rnSpec
#audit_axioms regNext4_correct_on_all_enables
#audit_axioms regNext4_wf
#audit_axioms regNext8_correct
#audit_axioms regNext8_wf
#audit_axioms regNext8_no_enable_holds_state
#audit_axioms regNext8_writes_only_the_enabled
#audit_axioms rnPatterns_differ

end SaltWorks.HDL

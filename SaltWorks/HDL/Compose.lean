/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Renumber

/-!
# C4 · `core` — INSTANTIATION: putting one `Circ` inside another

**This module exists because the tree does not contain it.** Every landed block
— `adder32`, `readTree`, `aluSelect`, `decoder`, `regWrite`, `regNext` — is a
standalone `Circ` with **hand-allocated net numbering**, and `Renumber` offers
`renum`/`normalize`, which renumber *one* circuit rather than embedding one in
another. *A `grep` for `compose`/`inst`/`embed`/`relabel` over `SaltWorks/HDL`
returns nothing that composes circuits.*

⇒ ***So `core`'s assembly is blocked on a combinator that has to be built, and
that is worth saying at block 5 of 6 rather than at block 6.*** **It is the same
shape as this morning's O(n²) discovery: a structural prerequisite that the plan
listed as a step.**

## What instantiation is

Embedding `c` into a host at net offset `off`, with `c`'s inputs supplied by
host nets through `σ`:

```
net n of c  ↦  σ n                  when n < c.nIn     (an input, wired by σ)
            ↦  off + (n - c.nIn)    otherwise          (an internal, shifted)
```

**The side condition is the whole risk**: the shifted region `off …` must not
collide with anything the host has already defined, and `σ`'s image must be
nets the host has *already computed*. Stated as `instOK` below rather than left
to the caller's care.

## ⚠️ GRADE OF THIS FILE, STATED PLAINLY

**Definitions: landed. A concrete instantiation: KERNEL-CHECKED. `ssa → wf`:
PROVED. `instGates_eq_renumFrom`: PROVED. ⭐ `inst_sem` — the SEMANTIC theorem,
and the "unproved link" this block flagged from the day this file landed:
PROVED. Non-vacuity controls for all three: KERNEL-CHECKED.**

⛔ **WHAT IS STILL OPEN, and it is ONE instantiation short of the assembly:
`inst_sem` covers embedding ONE block. `core` is a `++` of several, and `run`
over an APPENDED gate list is covered by nothing in this file.** *That lemma —
and not `inst_sem` — is now the last thing between here and a verified `core`.
`haChain` is its concrete witness and is already kernel-checked.*
-/

namespace SaltWorks.HDL

/-! ### The combinator -/

/-- Remap a net of `c` into the host. -/
def instMap (c : Circ) (σ : Net → Net) (off : Nat) (n : Net) : Net :=
  if n < c.nIn then σ n else off + (n - c.nIn)

/-- `c`'s gates, embedded. -/
def instGates (c : Circ) (σ : Net → Net) (off : Nat) : List Gate :=
  c.gates.map fun g => ⟨instMap c σ off g.out, g.op.rename (instMap c σ off)⟩

/-- Where `c`'s outputs land in the host. -/
def instOuts (c : Circ) (σ : Net → Net) (off : Nat) : List Net :=
  c.outs.map (instMap c σ off)

/-- The next free net after an instantiation — `c`'s internal count, shifted. -/
def instNext (c : Circ) (off : Nat) : Nat := off + c.gates.length

/-- **The side condition, stated rather than left to care.** Every input wire
`σ i` must be strictly below `off` (already computed by the host), and `c` must
be **dense SSA** — not merely well-formed.

⛔ **`wf` IS NOT ENOUGH, AND THIS WAS WRONG WHEN FIRST LANDED.** I wrote
`c.wf = true` here, and attempting `inst_sem` is what exposed it. `Circ.wf`
requires gate outputs to be **distinct and `≥ nIn`** — it does *not* require them
to be **contiguous**. So under `wf` alone a circuit may have sparse outputs
(say `{5, 12, 7}` with `nIn = 5`), `instMap` sends them to `off+0, off+7, off+2`,
and **`instNext = off + gates.length` UNDER-REPORTS the region actually
occupied** — the next instantiation placed at `instNext` would silently collide
with this one.

✅ **`Circ.ssa` is exactly the missing property**: `ssaFrom nIn` forces
`g.out == base` incrementing, so gate `i`'s output is exactly `nIn + i` and the
image is precisely `off … off + gates.length - 1`. *And it costs nothing to
require: `normalize_ssa` is landed and `emitPipeline'` normalizes anyway, so any
block can be made dense before instantiation.* -/
def instOK (c : Circ) (σ : Net → Net) (off : Nat) : Prop :=
  c.ssa = true ∧ c.wf = true ∧ ∀ i, i < c.nIn → σ i < off

/-! ### A concrete instantiation, kernel-checked

*Two half-adders: the second's inputs are the first's outputs. If the combinator
mis-shifted a net or mis-wired an input, this composite would compute something
else — and it is small enough that the kernel can say so.* -/

/-- `sum = a ^^^ b`, `carry = a &&& b` — two inputs, two outputs, two gates. -/
def ha : Circ := { nIn := 2, gates := [⟨2, .xor 0 1⟩, ⟨3, .and 0 1⟩], outs := [2, 3] }

theorem ha_wf : ha.wf = true := by decide +kernel

/-- Host: two primary inputs `0,1`; one `ha` instantiated on them at offset 2;
a second `ha` instantiated on the FIRST one's two outputs, at offset 4. -/
def haChain : Circ :=
  let g1 := instGates ha (fun i => i) 2
  let o1 := instOuts ha (fun i => i) 2
  let g2 := instGates ha (fun i => o1.getD i 0) 4
  let o2 := instOuts ha (fun i => o1.getD i 0) 4
  { nIn := 2, gates := g1 ++ g2, outs := o1 ++ o2 }

theorem haChain_wf : haChain.wf = true := by decide +kernel

/-- **The composite computes what hand-composition says it should**, on all four
input pairs. `ha`'s outputs are `(a^^^b, a&&&b)`; feeding those to a second `ha`
gives `((a^^^b) ^^^ (a&&&b), (a^^^b) &&& (a&&&b))` — and the second is always
`false`, which is a real fact about this composite and a good witness that the
wiring is not accidental. -/
def haChainOK : Bool :=
  [false, true].all fun a => [false, true].all fun b =>
    sem haChain (fun i => if i == 0 then a else b)
      == [a ^^ b, a && b, (a ^^ b) ^^ (a && b), (a ^^ b) && (a && b)]

theorem haChain_correct : haChainOK = true := by decide +kernel

/-- **NON-VACUITY — the instantiated copy is genuinely a SECOND copy**, not the
first one read twice: the composite has four gates, not two. -/
theorem haChain_has_four_gates : haChain.gates.length = 4 := by decide +kernel

/-- And the two instances occupy disjoint net ranges. -/
theorem haChain_nets_disjoint :
    (instGates ha (fun i => i) 2).map Gate.out
      = [2, 3] ∧
    (instGates ha (fun i => [2,3].getD i 0) 4).map Gate.out = [4, 5] := by
  decide +kernel


/-! ### The blocks this seat has built are dense — checked, not assumed

*If they were not, each would need `normalize` before instantiation. They are,
so `instNext` is a genuine bound for every one of them.* -/

theorem ha_ssa : ha.ssa = true := by decide +kernel

/-- **Under `ssa`, the instantiated region is exactly `off … off+len-1`** — which
is what makes `instNext` a real bound rather than an optimistic one. -/
theorem ha_inst_region :
    (instGates ha (fun i => i) 7).map Gate.out = [7, 8]
      ∧ instNext ha 7 = 9 := by decide +kernel

/-! ### `instGates_eq_renumFrom` — PROVED, and NOT by the fix that was predicted

**The residue handed to the maestro at 13:20 is closed — but NOT by the fix that
handover predicted, and the distinction is worth keeping.**

*The handover named the failing step as a metavariable problem and proposed
supplying the net explicitly — `instMap_internal c σ off (c.nIn + i) (by omega)`.
**That prediction is correct, and it is verified in `inst_sem`'s `hdense` below.**
It is simply not what closed THIS theorem: a successor should not read the proof
below as evidence for it, and should read `hdense` instead.*

⭐ **WHAT CLOSED IT WAS DELETING THE INDEX, NOT REPAIRING IT.** Both burnt
attempts were positional — reason about gate `i`, get `(gs.getD i default).out`
from `ssaFrom_out`, match it against `renumGates_getD`. **The metavariable was a
symptom of that shape**: `_` sat under an index whose bounds lived in a context
`omega` could not see.

✅ **`map_eq_renumFrom` below is the same statement with `c` removed.** It asks
only that the renaming function `m` be affine above `base` —
`∀ n, base ≤ n → m n = off + (n - base)` — and then `map` and `renumFrom` agree
by a plain structural induction: **the head is `m g.out = m base = off`, and the
tail re-instantiates at `base+1`/`off+1`.** *No index, no `getD`, no bounds
side-condition, so nothing for a metavariable to hide under.* **`instMap` is
affine above `c.nIn` by `instMap_internal` — which is exactly what the handover
said the step consumes, and it is consumed here as a hypothesis rather than at a
proof step.**

📌 **AND THE `ssa` HYPOTHESIS IS LOAD-BEARING, WITNESSED RATHER THAN ARGUED —
see `instGates_needs_ssa` below.** -/

/-- `instMap` on an internal net, with the branch discharged once. -/
theorem instMap_internal (c : Circ) (σ : Net → Net) (off n : Nat) (h : ¬ (n < c.nIn)) :
    instMap c σ off n = off + (n - c.nIn) := by
  rw [instMap]; exact if_neg h

/-! ### The two theorems, and the arithmetic defect that cost both of them

⚠️ **THE MECHANICAL FINDING FIRST, BECAUSE IT IS THE REUSABLE PART AND IT COST
FOUR OF THE SEVEN FAILING GOALS ACROSS BOTH PROOFS.** `omega` fails on goals it
can obviously do — `off + (n - base) = off + 1 + (n - (base + 1))` under
`base + 1 ≤ n`, and `a = base ∨ a < base ↔ a < base + 1` — **whenever the
equation is typed at `Net` rather than `Nat`.** *`EmitN.lean:275` and
`Banyan.lean:68` both record this; what neither says, and what cost the second
attempt here, is that* ***the defect is in the TYPE OF THE EQUATION, not the type
of the binders.*** **Rebinding `∀ n : Nat` changes nothing when the equation
still lands at `Net` because the function is `m : Net → Net`.**

📊 **THE TELL, and it is diagnostic rather than a guess: `omega`'s reported
counterexample OMITS A VARIABLE THAT IS IN THE GOAL** — here `off`. *It listed
`n ≥ 0`, `base ≥ 0`, `n - base ≥ 1`, which are exactly the HYPOTHESES.* ⇒ **A
counterexample whose atoms do not cover the goal means `omega` never parsed the
goal at all**, and that is a different failure from "the goal is false" even
though the message is the same. **The fix is `EmitN.lean:280`'s: state the
arithmetic in a `have` with no expected type — which elaborates it at `Nat` —
then `exact` it, which is accepted because `Net` is reducible.**

### `ssa → wf`, by the four conjuncts

**The invariant is the one the decomposition predicted, and it was the whole
trick as advertised.** `wfGates` threads `defined` as a *prepend*-list, so the
induction carries a SET characterisation — `∀ a, D.contains a = true ↔ a < base`
— preserved by the cons step because `g.out = base`. *Two of the four conjuncts
use it; the other two do not need it.* -/

/-- Every gate output is at or above the base. Stated with `∀ g ∈ gs` rather than
`List.all`, which makes the cons step's weakening (`base+1 ≤ · ⇒ base ≤ ·`) free. -/
theorem ssaFrom_out_ge : ∀ (gs : List Gate) (base : Nat), ssaFrom base gs = true →
    ∀ g ∈ gs, base ≤ g.out := by
  intro gs
  induction gs with
  | nil => intro base _ g hg; simp at hg
  | cons g gs ih =>
    intro base hssa x hx
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    rcases List.mem_cons.mp hx with h | h
    · rw [h, hout]
    · exact Nat.le_of_succ_le (ih (base + 1) hrest x h)

/-- **Conjunct 1** — every gate reads only already-defined nets. This is the one
that needs the set characterisation of `defined`. -/
theorem ssaFrom_wfGates : ∀ (gs : List Gate) (base : Nat) (D : List Net),
    ssaFrom base gs = true → (∀ a : Nat, D.contains a = true ↔ a < base) →
    wfGates D gs = true := by
  intro gs
  induction gs with
  | nil => intro base D _ _; rfl
  | cons g gs ih =>
    intro base D hssa hD
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, hfan⟩, hrest⟩ := hssa
    show (g.op.fanin.all D.contains && wfGates (g.out :: D) gs) = true
    rw [Bool.and_eq_true]
    refine ⟨?_, ih (base + 1) (g.out :: D) hrest ?_⟩
    · rw [List.all_eq_true] at hfan ⊢
      intro a ha
      exact (hD a).mpr (by simpa using hfan a ha)
    · intro a
      rw [List.contains_cons]
      simp only [Bool.or_eq_true, beq_iff_eq, hD a, hout]
      have hiff : a = base ∨ a < base ↔ a < base + 1 := by omega
      exact hiff

/-- **Conjunct 2** — `defined` holds exactly the nets below `base + length`.
Proved as an `iff`, which is stronger than `wf` needs and is what makes the
`outs` conjunct a one-liner. -/
theorem ssaFrom_defined : ∀ (gs : List Gate) (base : Nat) (D : List Net),
    ssaFrom base gs = true → (∀ a : Nat, D.contains a = true ↔ a < base) →
    ∀ a : Nat, (gs.foldl (fun acc g => g.out :: acc) D).contains a = true
      ↔ a < base + gs.length := by
  intro gs
  induction gs with
  | nil => intro base D _ hD a; simpa using hD a
  | cons g gs ih =>
    intro base D hssa hD a
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    have hstep : ∀ b : Nat, (g.out :: D).contains b = true ↔ b < base + 1 := by
      intro b
      rw [List.contains_cons]
      simp only [Bool.or_eq_true, beq_iff_eq, hD b, hout]
      have hiff : b = base ∨ b < base ↔ b < base + 1 := by omega
      exact hiff
    have := ih (base + 1) (g.out :: D) hrest hstep a
    show (gs.foldl (fun acc g => g.out :: acc) (g.out :: D)).contains a = true ↔ _
    rw [this]
    simp only [List.length_cons]
    omega

/-- **Conjunct 3** — the gate outputs are pairwise distinct. -/
theorem ssaFrom_nodup : ∀ (gs : List Gate) (base : Nat), ssaFrom base gs = true →
    nodupB (gs.map Gate.out) = true := by
  intro gs
  induction gs with
  | nil => intro base _; rfl
  | cons g gs ih =>
    intro base hssa
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    show (!((gs.map Gate.out).contains g.out) && nodupB (gs.map Gate.out)) = true
    rw [Bool.and_eq_true]
    refine ⟨?_, ih (base + 1) hrest⟩
    have hno : g.out ∉ gs.map Gate.out := by
      intro hmem
      obtain ⟨x, hx, hxe⟩ := List.mem_map.mp hmem
      have hge := ssaFrom_out_ge gs (base + 1) hrest x hx
      rw [hxe, hout] at hge
      omega
    simpa using hno

/-- ⭐ **`ssa → wf`.** *`Circ.wf` is `decide`-able but not `decide`-ABLE at scale:
its `nodupB` is O(n²) and dies at ~3,000 gates (`EXIT=134`, measured). This
theorem is how a core-sized circuit gets a well-formedness certificate at all —
`ssa` is checked structurally by the thing that BUILDS the circuit, and `wf`
follows without the kernel ever walking the quadratic.* -/
theorem Circ.wf_of_ssa {c : Circ} (h : c.ssa = true) : c.wf = true := by
  rw [Circ.ssa, Bool.and_eq_true] at h
  obtain ⟨hgs, houts⟩ := h
  have hinputs : ∀ a, (c.inputs).contains a = true ↔ a < c.nIn := by
    intro a; simp [Circ.inputs]
  rw [Circ.wf, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true]
  refine ⟨⟨⟨ssaFrom_wfGates c.gates c.nIn c.inputs hgs hinputs, ?_⟩,
           ssaFrom_nodup c.gates c.nIn hgs⟩, ?_⟩
  · rw [List.all_eq_true] at houts ⊢
    intro n hn
    have hlt : n < c.nIn + c.gates.length := by simpa using houts n hn
    exact (ssaFrom_defined c.gates c.nIn c.inputs hgs hinputs n).mpr hlt
  · rw [List.all_eq_true]
    intro g hg
    simpa using ssaFrom_out_ge c.gates c.nIn hgs g hg

/-! ### `instGates = renumFrom` -/

/-- The bridge, stated without `c`: any renaming that is **affine above `base`**
turns `map` into `renumFrom`. *Removing `c` is what removed the metavariable —
there is no index and no bound left to elaborate under.* -/
theorem map_eq_renumFrom (m : Net → Net) :
    ∀ (gs : List Gate) (base off : Nat), ssaFrom base gs = true →
      (∀ n : Nat, base ≤ n → m n = off + (n - base)) →
      gs.map (fun g => (⟨m g.out, g.op.rename m⟩ : Gate)) = renumFrom m off gs := by
  intro gs
  induction gs with
  | nil => intro base off _ _; rfl
  | cons g gs ih =>
    intro base off hssa hm
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    have hhead : m g.out = off := by
      rw [hout, hm base (Nat.le_refl base)]
      simp
    show (⟨m g.out, g.op.rename m⟩ : Gate) :: gs.map _
       = (⟨off, g.op.rename m⟩ : Gate) :: renumFrom m (off + 1) gs
    rw [hhead]
    congr 1
    refine ih (base + 1) (off + 1) hrest ?_
    intro n hn
    rw [hm n (Nat.le_of_succ_le hn)]
    -- The equation is at `Net`, so `omega` parses only the hypotheses and never
    -- sees `off`. Restate at `Nat` first — EmitN.lean:280's fix.
    have harith : off + (n - base) = off + 1 + (n - (base + 1)) := by omega
    exact harith

/-- ⭐ **The instantiated gate list IS a `renumFrom` of the original** — which is
what lets `run_renumFrom` (the landed frame lemma) carry the semantics across an
instantiation, instead of a fresh induction over composites. -/
theorem instGates_eq_renumFrom (c : Circ) (σ : Net → Net) (off : Nat) (h : c.ssa = true) :
    instGates c σ off = renumFrom (instMap c σ off) off c.gates := by
  rw [Circ.ssa, Bool.and_eq_true] at h
  refine map_eq_renumFrom _ c.gates c.nIn off h.1 ?_
  intro n hn
  exact instMap_internal c σ off n (Nat.not_lt.mpr hn)

/-! ### ⭐ `inst_sem` — THE SEMANTIC THEOREM. The assembly gate is open.

**This is what makes assembly VERIFIED rather than glue**, and it is the "unproved
link" the header block has been flagging since this file landed.

📌 **AND IT VINDICATES THE 13:20 HANDOVER'S PREDICTION, one theorem later than
predicted.** *That handover named a residue and proposed `instMap_internal c σ off
(c.nIn + i) (by omega)` — supply the net explicitly — without running it.
`instGates_eq_renumFrom` above did not close by that route at all; it closed by
removing the index. **But `hdense` below needs exactly the positional step the
residue was stuck on, and the predicted form is exactly what discharges it.***
⇒ **The prediction was RIGHT ABOUT THE STEP and wrong about which theorem would
need it.** *Recorded because "I believe this closes it, unrun" is a claim, and
this is the first chance the tree has had to score one.*

**The four hypotheses `run_renumFrom` asks for, and where each now comes from:**

```
env agreement via σ    the caller's obligation — `hin`, the wiring is correct
σ maps inputs < off    instOK's third clause
wfGates c.inputs gs    ssaFrom_wfGates      <- proved above, was the blocker
σ dense on outputs     ssaFrom_out + instMap_internal
```
-/

/-- ⭐ **An instantiated block computes what the block computes.** Given correct
wiring (`hin`) and the side condition (`instOK`), every net of `c` — input or
gate output — reads the same value in the host as it does standalone. -/
theorem inst_sem (c : Circ) (σ : Net → Net) (off : Nat) (envN envC : Env)
    (hok : instOK c σ off)
    (hin : ∀ a, a < c.nIn → envN (σ a) = envC a) :
    ∀ a, (a < c.nIn ∨ (c.gates.map Gate.out).contains a = true) →
      run envN (instGates c σ off) (instMap c σ off a) = run envC c.gates a := by
  obtain ⟨hssa, _hwf, hσ⟩ := hok
  have hgs : ssaFrom c.nIn c.gates = true := by
    rw [Circ.ssa, Bool.and_eq_true] at hssa; exact hssa.1
  have hinputs : ∀ a, (c.inputs).contains a = true ↔ a < c.nIn := by
    intro a; simp [Circ.inputs]
  have hag : ∀ a, (c.inputs).contains a = true → envN (instMap c σ off a) = envC a := by
    intro a ha
    have ha' : a < c.nIn := (hinputs a).mp ha
    rw [instMap, if_pos ha']
    exact hin a ha'
  have hlt : ∀ a, (c.inputs).contains a = true → instMap c σ off a < off := by
    intro a ha
    have ha' : a < c.nIn := (hinputs a).mp ha
    rw [instMap, if_pos ha']
    exact hσ a ha'
  have hdense : ∀ i, i < c.gates.length →
      instMap c σ off (c.gates.getD i default).out = off + i := by
    intro i hi
    rw [ssaFrom_out c.gates c.nIn i hgs hi,
        instMap_internal c σ off (c.nIn + i) (Nat.not_lt.mpr (Nat.le_add_right _ _))]
    have harith : off + (c.nIn + i - c.nIn) = off + i := by omega
    exact harith
  intro a ha
  rw [instGates_eq_renumFrom c σ off hssa]
  refine run_renumFrom (instMap c σ off) c.gates off c.inputs envN envC hag hlt
    (ssaFrom_wfGates c.gates c.nIn c.inputs hgs hinputs) hdense a ?_
  rcases ha with h | h
  · exact Or.inl ((hinputs a).mpr h)
  · exact Or.inr h

/-- **The wiring hypothesis `hin` is load-bearing.** *Same circuit, same offset,
same `σ` — only the host environment disagrees with the component's at input `0`,
and the conclusion is false.* -/
theorem inst_sem_needs_input_agreement :
    run (fun _ => false) (instGates ha (fun i => i) 2) (instMap ha (fun i => i) 2 2)
      ≠ run (fun i => i == 0) ha.gates 2 := by
  decide +kernel

/-! ### WHAT IS STILL OWED FOR THE ASSEMBLY, NAMED SO IT IS NOT REDISCOVERED

*`inst_sem` covers ONE instantiation. `core` is a `++` of several, and `run` over
an appended gate list is not covered by anything above.* ⇒ **The next obligation
is a two-instance composition lemma** — `run env (g1 ++ g2) n` splits according
to which instance defines `n` — and `haChain` is its concrete witness. -/

/-! ### NON-VACUITY — the `ssa` hypothesis is load-bearing, and `wf` is not enough

*Both theorems above are implications I stated with a hypothesis I chose. The
controls are a circuit satisfying `wf` but not `ssa`, and the two failures it
produces — which are exactly the two this file's `instOK` docstring argues for in
prose.* -/

/-- `wf` but NOT `ssa`: outputs `5, 3` with `nIn = 2` are distinct and `≥ nIn`,
so `wf` passes — but they are not contiguous from `nIn`, so `ssa` fails. -/
def sparse : Circ := { nIn := 2, gates := [⟨5, .xor 0 1⟩, ⟨3, .and 0 1⟩], outs := [5, 3] }

theorem sparse_wf : sparse.wf = true := by decide +kernel
theorem sparse_not_ssa : sparse.ssa = false := by decide +kernel

/-- **So `wf_of_ssa` is a strict strengthening**, not an equivalence in disguise. -/
theorem ssa_is_strictly_stronger : sparse.wf = true ∧ sparse.ssa = false :=
  ⟨sparse_wf, sparse_not_ssa⟩

/-- **Drop `ssa` and `instGates_eq_renumFrom` is FALSE** — `instMap` sends `5` to
`off+3` where `renumFrom` puts `off+0`. -/
theorem instGates_needs_ssa :
    (instGates sparse (fun i => i) 7).map Gate.out
      ≠ (renumFrom (instMap sparse (fun i => i) 7) 7 sparse.gates).map Gate.out := by
  decide +kernel

/-- ⛔ **THE COLLISION THIS FILE'S `instOK` DOCSTRING ARGUES FOR, AS A KERNEL
FACT RATHER THAN AS PROSE: `instNext` reports the next free net as `9`, and the
instantiation has already occupied `10`.** *A second block placed at `instNext`
would silently overlap this one — which is precisely why `instOK` requires `ssa`
and not merely `wf`.* -/
theorem instNext_under_reports_without_ssa :
    instNext sparse 7 = 9 ∧ (instGates sparse (fun i => i) 7).map Gate.out = [10, 8] := by
  decide +kernel

#audit_axioms instMap
#audit_axioms instGates
#audit_axioms instOuts
#audit_axioms instNext
#audit_axioms ha
#audit_axioms ha_wf
#audit_axioms haChain
#audit_axioms haChain_wf
#audit_axioms haChain_correct
#audit_axioms haChain_has_four_gates
#audit_axioms haChain_nets_disjoint
#audit_axioms ha_ssa
#audit_axioms ha_inst_region
#audit_axioms instMap_internal
#audit_axioms ssaFrom_out_ge
#audit_axioms ssaFrom_wfGates
#audit_axioms ssaFrom_defined
#audit_axioms ssaFrom_nodup
#audit_axioms Circ.wf_of_ssa
#audit_axioms map_eq_renumFrom
#audit_axioms instGates_eq_renumFrom
#audit_axioms sparse
#audit_axioms sparse_wf
#audit_axioms sparse_not_ssa
#audit_axioms ssa_is_strictly_stronger
#audit_axioms instGates_needs_ssa
#audit_axioms instNext_under_reports_without_ssa
#audit_axioms inst_sem
#audit_axioms inst_sem_needs_input_agreement

end SaltWorks.HDL

/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Certs
import SaltWorks.HDL.Compose
import SaltWorks.HDL.Dense

/-!
# The 32-bit operand-B 2:1 multiplexer — a certified standalone block

97 gates, with an unconditional semantics over an arbitrary `Env`, a mutation
suite that includes the two vacuity modes this suite is known to admit, and a
kernel-proved gate count. **Wiring is deliberately NOT here** — which object the
ALU selects is a design ruling, and this module exists so that ruling has two
certified candidates instead of one.

## THE ACCEPTANCE BAR FOR A CERTIFIED BLOCK

*Recorded here because this module is its worked example, and because a bar that
lives only in bus posts does not survive a seat reboot. Every clause below was
pre-registered before the artifact it judges existed; the primed ones were added
by someone attacking the criterion rather than the block, which is the only way
any of them surfaced — a passing build cannot report a hole in the bar.*

* **① BLOCK CERT** — `∀ E : Env, ∀ k < 32, out_k = if sel then b_k else a_k`,
  proved for an **arbitrary** environment. A cert over a fixture, a sample, or a
  `decide` at fixed inputs does not satisfy this.
* **①′ STATED OVER `sem c`** — over the circuit's **output port list**, never
  over `run … c.gates <hardcoded net>`. A net-anchored cert is blind to `outs`
  *by construction*, and `outs` is where bit order lives.
  *Why it exists:* ① as first written says `out_k = …`, and `out_k` is exactly
  the ambiguity — a net-anchored cert satisfies that sentence read literally.
  A sibling file proves the blindness is definitional, `Iff.rfl`, not accidental.
* **①″ PIN `outs` LENGTH, not merely mention `outs`** — by a list-level equality
  against a spec of known length, or an explicit kernel-proved `outs.length = N`.
  *Why it exists:* ①′ makes the cert read the port list, but an index-wise cert
  (`∀ k < 32`) is satisfied by a circuit whose `outs` has length 40. This module
  closes it twice (`obMux_certList`, and `outs.length = 32` by `decide +kernel`)
  — **but it closes it because its author chose a list-level cert, not because
  the bar demanded it.** A criterion satisfied by luck is still a broken
  criterion.
* **①‴ THE WHOLE-LIST MUST BE OVER THE *PORT* AXIS** — a cert can have two list
  axes and only one of them is the port list. A trace cert
  (`trace == [[true],[false],…]`) is a single top-level whole-list equality that
  pins **how many CYCLES** were observed, while each cycle still reads one fixed
  port index — so the port axis stays length-free and ①″ is satisfied
  vacuously. *Ask what the ELEMENTS of the compared list are:* ports ⇒ pinned;
  cycles ⇒ not pinned by shape, go find a length fact.
  *Why it exists:* proved on a sequential sibling — `xorPrev_trace`'s exact
  statement survives appending a port to the core, and what catches the wide
  machine is `Seq.wf`, not the certificate.

* **①⁗ KEY THE TEST ON THE WIDEST INDEX THE STATEMENT CAN READ** — not on the
  combinator, and not on whether a `==` between lists appears. If the widest
  index the statement constrains is bounded by a literal, the length is free
  above it, whatever the surrounding syntax looks like. Shapes that a
  combinator-keyed rule scores wrong:

  | statement | reads | verdict |
  | --- | --- | --- |
  | `sem c ins = (List.range 32).map f` | the whole list | PINNED |
  | `(subOut a b).take 32 = …` | prefix 0…31 | **unpinned** — and it *is* a single equation between two lists |
  | `(sem c e).drop 1 = …` | length `n-1` | PINNED — pins `n` exactly |
  | `wordOf (fun k => (sem C E).getD k false) = w` | 0…31 | unpinned, `Word = Word` |
  | `asBit0 …= b` | index 0 only | unpinned, `Bool = Bool`, no `getD` in sight |

  *Why it exists:* an earlier form of this clause said "`take N` is a prefix,
  `drop 1` pins exactly" — keyed on the combinator. `(subOut a b).take 32 = …`
  has no `take` on the right, no `getD` anywhere, and reads a bounded prefix
  regardless; the `Bool = Bool` family mentions no list operation at all. **Every
  syntactic rule this bar shipped before this one misses them.** `adder32` is the
  live instance: all 33 ports certified, `outs.length` unpinned in the corpus, so
  a 34-port `adder32Wide` with byte-identical gates satisfies all three certs —
  *covered but unpinned*, which is neither PINNED nor BLIND.

  📌 **And the taxonomy needs four buckets, not two:** PINNED · COVERED-BUT-UNPINNED
  (every real port certified, length free) · DISCLOSED-SAMPLE (scope named in the
  identifier, e.g. `_on_sample` — a stated limitation, not a blind) · BLIND
  (universal-and-silent). A verdict with nowhere right to go lands in the worst
  bucket available; add the bucket first.

  ⚠️ **AND THE STRUCTURAL FACTS EVERY COMBINATIONAL BLOCK AUTHOR NEEDS:**
  `Circ.wf` (`Syntax.lean:110-114`) does **NOT** constrain `outs.length`, and it
  is weaker still than that: its `nodupB` is applied to `c.gates.map Gate.out`
  — **the gates, not the port list** — so `wf` does not even require the ports
  to be distinct. A circuit naming one net twice in `outs` passes `wf` *and*
  `ssa` (both kernel-checked). `Circ.ssa` bounds each port's net *number*, never
  the port *count*. `Seq.wf` (`Seq.lean:60-61`) *does* carry the width
  (`core.outs.length == nOut + nState`), which is why sequential machines are
  pinned for free and combinational ones are not.

  ⇒ **A `wf`/`ssa` theorem earns you nothing on ①″. Prove the length, or state
  the cert as a whole-list equality over the full port list and let
  `sem c ins = c.outs.map …` pin it definitionally.** The one block in this
  corpus that does it structurally is `C4`, whose `CoreConforms` carries
  `outs.length = stWidth` as a decidable precondition — the pattern the rest
  lack, and it already exists here.

  📌 **⚠️ DO NOT RE-DERIVE THIS — the general theorem is already in the corpus
  and predates the clause it justifies:**
  `Stack/Program.lean:2528` `extendOut c m := { c with outs := c.outs ++ [m] }`,
  `:2545` `outBit_extendOut` (index-wise reads are unchanged), and
  `:2558` **`length_conjunct_is_necessary`** — *universally quantified in `c`*:
  every field obligation survives an appended port while the whole-list spec
  dies, stated for an arbitrary `c` "so it does not wait on a correct core to
  exist."

  Three seats independently rebuilt per-circuit witnesses of this on 8/8
  (`obMuxWide`, `adder32Wide`, a bar-gap probe) before anyone read `:2558`.
  **Cite the corpus, not the re-derivations.** If you need a per-circuit check
  anyway, the specialised form is
  `sem { c with outs := c.outs ++ [n] } ins = sem c ins ++ [run ins c.gates n]`
  — appending a port is invisible to both `take k` (`k ≤ length`) and `getD k`
  (`k < length`) for **every** circuit and **every** environment. Not a sample.
* **② GATE COUNT** proved by `decide +kernel`, never asserted in a comment.
* **③ MUTATIONS ≥ 3**, each proving **the cert fails** for the mutant — not
  merely that two circuits differ at some net. Must include the a/b **bus swap**
  and an **`outs` reversal**; both are known vacuity modes of this suite, and a
  mux is the case that bites. Beware the converse too: a suite assuming *"any
  single-op change must break"* ships false positives — `or → xor` here is a
  genuine non-defect (one-hot merge), and two of the mutants are one defect
  counted twice.
* **④ AUDIT** — `#audit_axioms` clean on every declaration, ≤ 3 axioms each,
  and **one declaration per call**. A multi-name call abandons the rest of its
  own list at the first failure, so a name absent from the error list reads as
  clean when it was never reached — and the hidden names are exactly those
  downstream of the failure.
* **⑤ HYGIENE** — 0 `sorry`, 0 `native_decide`, 0 `axiom`. ⚠️ **Not by grep.**
  A failed tactic emits an error *and* fills the hole with `sorryAx`, so a file
  with zero `sorry` tokens can still depend on it; and prose about `sorryAx`
  makes a clean file's grep non-zero. The instrument is wrong in both
  directions. Only `saltbuild EXIT=0` **plus** a clean audit is a verdict.
* **⑥ BUILD** — `../saltbuild.sh SaltWorks/HDL/<file>.lean`, path form, never
  piped (`$?` after a pipe is the tail's status, and it fails in the reassuring
  direction). `EXIT=N` judged by its literal text; `75` is a lock-wait abort,
  not a failure. Every number quoted comes from that run.

## The block

```
a   = rs2 value    nets  0 … 31        bit k is net k
b   = immediate    nets 32 … 63        bit k is net 32 + k
sel = useImm       net  64             nIn = 65
ns  = ¬sel         net  65             ONE shared inverter for all 32 bits
cell k             nets 66+3k, 66+3k+1, 66+3k+2
out_k              net  66+3k+2        outs in bit order, low bit first
```

`out_k = (a_k ∧ ¬sel) ∨ (b_k ∧ sel)`.

## Why the certificate is stated over `sem c`

`BlockCert c := ∀ ins k, k < 32 → (sem c ins).getD k false = …` reads the
circuit's **output port list**. A certificate written instead over
`run ins c.gates <hardcoded net>` never mentions `c.outs` and is blind to output
bit order *by construction* — a sibling file proves that blindness is not an
accident but a definitional identity (`BlockCertV outRev ↔ BlockCertV orig`, by
`Iff.rfl`). The mutant `obMuxm4` here has **identical gates** and `outs`
reversed; `breaks_obMuxm4 : ¬ BlockCert obMuxm4` is the same defect, killed.

## ⛔ THE DEFECT THIS BLOCK'S FIRST DRAFT HIT — and the mechanism, MEASURED

The first draft failed with 57 errors, 45 of them `omega`. The cause is one
thing repeated, and the tempting general statement of it is FALSE:

> ⛔ *"A proposition elaborated at `Net` is invisible to `omega`."* — **refuted.**
> `example (x base : Nat) (hx : x < base) : @LT.lt Net instLTNat x base := by omega`
> **succeeds.** A `Net`-typed *relation* over `Nat`-typed operands is fine:
> omega applies reducible whnf at a goal's top level and sees through the abbrev.

**It is the type of the TERMS that matters, not of the proposition.** `omega`
collects arithmetic atoms by syntactic type, so a `Net`-typed **fvar** or
**numeral** is never collected — and then there is nothing to reason with.
Measured (`ScratchOmegaProbe2.lean`):

| goal / context                                              | omega |
| ----------------------------------------------------------- | ----- |
| `Nat` fvars, `Net` relation (`@LT.lt Net .. x base`)         | ✓     |
| `@LT.lt Net .. 64 66` — `Net` NUMERALS, no hypotheses        | ✗ *"No usable constraints found"* |
| `i : Net`, `Net` hypothesis and goal                         | ✗ same |
| `n k : Net`, `66 + 3*n ≠ 66 + 3*k + 2`                       | ✗ same |
| `i : Net` hypothesis, `Nat` goal                             | ✗ — goal parsed, **hypothesis dropped** |

*A tactic that cannot prove `64 < 66` is not failing at arithmetic.*

> **THE FIX.** Bind every net index at `Nat`, and never let a `by omega` face a
> goal or hypothesis whose operands came from a `Net`-typed binder. §0 below is
> that fix factored into `Nat`-typed lemmas which later proofs `exact` into the
> `Net`-typed position — accepted, because `Net` is reducible and the two
> propositions are definitionally equal.

⚠️ **This is a DIFFERENT tier from the one `GenSelectCount` documents.** There,
the operands were already `Nat` and the relation sat under a `∧`, where omega's
`And` recursion skips the whnf it does at top level. Here the operands
themselves are `Net`. Both present as *"omega failed on something trivial"*, and
the discriminator is one probe: **if a single top-level comparison over your
terms succeeds, you have the connective tier; if it fails, you have this one.**

## The two defects that were NOT `omega`

* **A parse error** (`367:25` and three siblings): a `{ c with f := e }` whose
  value wrapped onto a less-indented continuation line stopped parsing at the
  wrap, silently truncating four mutant definitions and cascading into six
  `decide` failures. Fixed by keeping each structure instance on one line.
* **A kernel deterministic timeout** on the central theorem (`312:8`). The
  inner `show` asked defeq to step `run` *past* the head gate, so the kernel
  had to unfold `run` on both sides of a 97-gate list in lock-step. Fixed by
  doing that step with `rw [run_cons]` — a rewrite, not a defeq obligation.
-/

namespace SaltWorks.HDL
namespace OperandB

/-! ## 0 · THE ARITHMETIC, STATED AT `Nat`

Every binder here is `Nat`, so every proposition here is `Nat`-typed and `omega`
can see it. Downstream these are `exact`ed into `Net`-typed positions, which the
elaborator accepts because `Net` is a reducible abbrev for `Nat`.

**This section IS the repair.** Nothing below calls `omega` on a goal that came
from a `Net`-typed binder. -/

/-- A net below the cell array is not the cell's first net. -/
theorem lo_ne_cell0 (m k : Nat) (h : m < 66) : m ≠ 66 + 3 * k := by omega

/-- …and symmetrically, which is the direction `run_of_unwritten` wants. -/
theorem cell0_ne_lo (m k : Nat) (h : m < 66) : 66 + 3 * k ≠ m := by omega

theorem cell1_ne_lo (m k : Nat) (h : m < 66) : 66 + 3 * k + 1 ≠ m := by omega

theorem cell2_ne_lo (m k : Nat) (h : m < 66) : 66 + 3 * k + 2 ≠ m := by omega

/-- The two `and` nets of one cell are distinct. -/
theorem cell0_ne_cell1 (k : Nat) : 66 + 3 * k ≠ 66 + 3 * k + 1 := by omega

/-- A LATER cell writes above an EARLIER cell's output port — the frame
condition that makes the induction in `run_body` go through. -/
theorem cell0_ne_out (n k : Nat) (_h : k < n) : 66 + 3 * n ≠ 66 + 3 * k + 2 := by omega

theorem cell1_ne_out (n k : Nat) (_h : k < n) : 66 + 3 * n + 1 ≠ 66 + 3 * k + 2 := by omega

theorem cell2_ne_out (n k : Nat) (h : k < n) : 66 + 3 * n + 2 ≠ 66 + 3 * k + 2 := by omega

/-- The four wires a cell reads all sit below the array. -/
theorem a_lt_66 (k : Nat) (h : k < 32) : k < 66 := by omega
theorem b_lt_66 (k : Nat) (h : k < 32) : 32 + k < 66 := by omega
theorem sel_lt_66 : (64 : Nat) < 66 := by omega
theorem ns_lt_66 : (65 : Nat) < 66 := by omega

/-- The three wires that must dodge the shared inverter at net 65. -/
theorem a_ne_65 (k : Nat) (h : k < 32) : k ≠ 65 := by omega
theorem b_ne_65 (k : Nat) (h : k < 32) : 32 + k ≠ 65 := by omega
theorem sel_ne_65 : (64 : Nat) ≠ 65 := by omega

/-! ## 1 · THE BLOCK -/

/-- Bit `k`'s mux cell — three gates, indices written out.

```
net 66+3k    t1_k  = a_k  ∧ ¬sel      (a_k is net k,     ¬sel is net 65)
net 66+3k+1  t2_k  = b_k  ∧  sel      (b_k is net 32+k,   sel is net 64)
net 66+3k+2  out_k = t1_k ∨ t2_k
```
-/
def obCell (k : Nat) : List Gate :=
  [ ⟨66 + 3 * k,     .and k 65⟩
  , ⟨66 + 3 * k + 1, .and (32 + k) 64⟩
  , ⟨66 + 3 * k + 2, .or (66 + 3 * k) (66 + 3 * k + 1)⟩ ]

/-- **The 32-bit operand-B multiplexer.** One shared inverter, then 32 cells. -/
def obMux : Circ :=
  { nIn   := 65
    gates := (⟨65, .not 64⟩ : Gate) :: (List.range 32).flatMap obCell
    outs  := (List.range 32).map (fun k => 66 + 3 * k + 2) }

/-! ## 2 · WELL-FORMEDNESS, AND THE GATE COUNT -/

theorem nIn_obMux : obMux.nIn = 65 := rfl

/-- Dense SSA: gate `i` writes net `65 + i`, reading only nets `< 65 + i`. -/
theorem ssa_obMux : obMux.ssa = true := by decide +kernel

/-- Well-formed, including **no net defined twice**. -/
theorem wf_obMux : obMux.wf = true := Circ.wf_of_ssa ssa_obMux

/-- The `nodup` conjunct on its own, checked directly rather than inherited. -/
theorem nodup_obMux : nodupB (obMux.gates.map Gate.out) = true := by decide +kernel

/-- Dense in the positional sense `emitN` consumes. -/
theorem dense_obMux : obMux.dense = true := Circ.dense_of_ssa ssa_obMux

/-- ⭐ **THE GATE COUNT — 97, PROVED BY `decide +kernel`.** `32 × 3 + 1`: three
gates per bit plus the ONE shared inverter. Hoisting `¬sel` out of the 32 cells
is what makes it 97 and not 128. -/
theorem gateCount_obMux :
    obMux.gates.length = 97 ∧ obMux.gates.length = 32 * 3 + 1 := by decide +kernel

/-- ⭐ **THE CENSUS BY GATE KIND** — the part a bare count cannot see. One
inverter (shared), 64 ANDs (two per bit), 32 ORs (one per bit). A 97-gate
circuit with a different mix fails this. -/
theorem census_obMux :
    (obMux.gates.filter (fun g => match g.op with | .not _ => true | _ => false)).length = 1
  ∧ (obMux.gates.filter (fun g => match g.op with | .and _ _ => true | _ => false)).length = 64
  ∧ (obMux.gates.filter (fun g => match g.op with | .or _ _ => true | _ => false)).length = 32 := by
  decide +kernel

/-- The indices, exhibited literally at both ends of the bus and at the head of
the gate list, so a reader can check the wiring by eye. -/
theorem exhibit_obMux :
    obCell 0 = [⟨66, .and 0 65⟩, ⟨67, .and 32 64⟩, ⟨68, .or 66 67⟩]
      ∧ obCell 31 = [⟨159, .and 31 65⟩, ⟨160, .and 63 64⟩, ⟨161, .or 159 160⟩]
      ∧ obMux.gates.take 4
          = [⟨65, .not 64⟩, ⟨66, .and 0 65⟩, ⟨67, .and 32 64⟩, ⟨68, .or 66 67⟩]
      ∧ obMux.outs.take 3 = [68, 71, 74]
      ∧ obMux.outs.length = 32 := by decide +kernel

/-! ## 3 · THE STEP CERT — the 1-bit cell, on all 8 rows

The cell alone has three inputs, so its input space is finite and the kernel can
take all of it. The route is bit-sliced: one `Nat` per net, bit `j` of a net
being its value under row `j`, so the whole truth table is **one** kernel
computation rather than eight. `reflect` (Certs.lean) turns that one `Nat` back
into a pointwise statement about `sem`, for every row. -/

/-- The mux cell standing alone: `a` = net 0, `b` = net 1, `sel` = net 2. -/
def muxCell : Circ :=
  { nIn   := 3
    gates := [⟨3, .not 2⟩, ⟨4, .and 0 3⟩, ⟨5, .and 1 2⟩, ⟨6, .or 4 5⟩]
    outs  := [6] }

theorem ssa_muxCell : muxCell.ssa = true := by decide +kernel
theorem wf_muxCell : muxCell.wf = true := Circ.wf_of_ssa ssa_muxCell

/-- The three input columns: `a = 0b10101010`, `b = 0b11001100`,
`sel = 0b11110000`. Bit `j` of column `i` is bit `i` of `j`. -/
def cols3 : EnvS :=
  fun i => if i = 0 then 0xAA else if i = 1 then 0xCC else if i = 2 then 0xF0 else 0

/-- The columns really do enumerate all 8 rows. -/
theorem spec_cols3 : ∀ j, j < 8 → ∀ i, i < 3 → (cols3 i).testBit j = j.testBit i := by
  decide +kernel

/-- Columns past the third are zero. *`i` is bound at `Nat`, so `h : ¬ i < 3` is
`Nat`-typed and `omega` can see it — the whole repair in one line.* -/
theorem cols3_zero (i : Nat) (h : 3 ≤ i) : cols3 i = 0 := by
  have h0 : i ≠ 0 := by omega
  have h1 : i ≠ 1 := by omega
  have h2 : i ≠ 2 := by omega
  simp [cols3, h0, h1, h2]

/-- ⭐ **THE STEP CERT, SLICED.** The cell's output net carries the truth table
`0b11001010 = 202` — one bignum, all eight rows at once. -/
theorem sliced_muxCell : muxCell.outs.map (runS 8 cols3 muxCell.gates) = [202] := by
  decide +kernel

theorem slicedOut_muxCell : runS 8 cols3 muxCell.gates 6 = 202 := by decide +kernel

/-- The columns agree with the pointwise valuation on **every** net, including
the ones past the third: a column that does not exist is `0`, and a row below `8`
has no bit at index `≥ 3`. -/
theorem agree_cols3 (j : Nat) (hj : j < 8) : ∀ i : Nat, (cols3 i).testBit j = bitsOf j i := by
  intro i
  by_cases h : i < 3
  · exact spec_cols3 j hj i h
  · have h3 : 3 ≤ i := Nat.not_lt.mp h
    have h0 : cols3 i = 0 := cols3_zero i h3
    have hjt : j.testBit i = false :=
      Nat.testBit_lt_two_pow
        (Nat.lt_of_lt_of_le (show j < 2 ^ 3 from hj) (Nat.pow_le_pow_right (by norm_num) h3))
    simp [h0, hjt, bitsOf]

/-- The sliced number, reflected back to `sem`, row by row. -/
theorem pointwise_muxCell (j : Nat) (hj : j < 8) :
    sem muxCell (bitsOf j) = [(202 : Nat).testBit j] := by
  have h := reflect hj muxCell.gates (agree_cols3 j hj) 6
  rw [slicedOut_muxCell] at h
  show [run (bitsOf j) muxCell.gates 6] = _
  rw [← h]

/-- `202` **is** the mux truth table over the three inputs. -/
theorem bits202 : ∀ j, j < 8 →
    (202 : Nat).testBit j = (if j.testBit 2 then j.testBit 1 else j.testBit 0) := by
  decide +kernel

/-- ⭐⭐ **THE 1-BIT CELL EQUALS THE SPEC ON ALL EIGHT ROWS.** -/
theorem isMux_muxCell (j : Nat) (hj : j < 8) :
    sem muxCell (bitsOf j) = [if j.testBit 2 then j.testBit 1 else j.testBit 0] := by
  rw [pointwise_muxCell j hj, bits202 j hj]

/-- The same statement as one closed `Bool`, so it is also a direct kernel
computation and not only a consequence of the sliced route. Two independent
derivations of the same eight rows. -/
theorem stepCert_muxCell :
    (List.range 8).all (fun j =>
      sem muxCell (bitsOf j) == [if j.testBit 2 then j.testBit 1 else j.testBit 0]) = true := by
  decide +kernel

/-! ## 4 · LOCALITY, THEN INDUCTION

Four ingredients, each isolated so a mistake in one cannot hide in another:

* `cell_outs`  — a cell writes exactly its own three nets, nothing else;
* `run_cell_or` / `run_cell_xor` — one cell's meaning, from `upd`'s frame law;
* `run_body`   — the induction over `List.range n`, generic in the cell;
* `sem_block`  — the lift from the gate list to `sem`, i.e. to `outs`.

`run_body` and `sem_block` are generic in the cell and in the cell's Boolean
function, so the block and every structurally-analysed mutant share one
induction — which is what stops a mutant's proof from silently being the
block's proof. -/

/-- Any cell of this shape writes exactly nets `66+3k`, `66+3k+1`, `66+3k+2`. -/
theorem cell_outs (o₁ o₂ o₃ : Op) (k : Nat) :
    ∀ g ∈ [(⟨66 + 3 * k, o₁⟩ : Gate), ⟨66 + 3 * k + 1, o₂⟩, ⟨66 + 3 * k + 2, o₃⟩],
      g.out = 66 + 3 * k ∨ g.out = 66 + 3 * k + 1 ∨ g.out = 66 + 3 * k + 2 := by
  intro g hg
  simp only [List.mem_cons, List.not_mem_nil, or_false] at hg
  rcases hg with h | h | h
  · exact Or.inl (by rw [h])
  · exact Or.inr (Or.inl (by rw [h]))
  · exact Or.inr (Or.inr (by rw [h]))

/-- **One cell, merged by `or`.** The two `upd`s the cell performs land at nets
`≥ 66`; every net the cell READS is below `66`; so no read is disturbed.

*The index arguments are bound at `Nat`, and the three frame obligations are
discharged by §0's lemmas rather than by `omega` under a `Net`-typed goal —
which is precisely where the original lost six of its 57 errors.* -/
theorem run_cell_or (k p q r s : Nat) (hr : r < 66) (hs : s < 66) (E : Env) :
    run E [(⟨66 + 3 * k, .and p q⟩ : Gate), ⟨66 + 3 * k + 1, .and r s⟩,
           ⟨66 + 3 * k + 2, .or (66 + 3 * k) (66 + 3 * k + 1)⟩] (66 + 3 * k + 2)
      = ((E p && E q) || (E r && E s)) := by
  have e1 : ∀ (env : Env) (v : Bool), upd env (66 + 3 * k) v r = env r :=
    fun env v => upd_of_ne v (lo_ne_cell0 r k hr)
  have e2 : ∀ (env : Env) (v : Bool), upd env (66 + 3 * k) v s = env s :=
    fun env v => upd_of_ne v (lo_ne_cell0 s k hs)
  have e3 : ∀ (env : Env) (v : Bool),
      upd env (66 + 3 * k + 1) v (66 + 3 * k) = env (66 + 3 * k) :=
    fun env v => upd_of_ne v (cell0_ne_cell1 k)
  simp only [run_cons, run_nil, Op.eval, upd_self, e1, e2, e3]

/-- **One cell, merged by `xor`.** Same wiring, one operation changed. -/
theorem run_cell_xor (k p q r s : Nat) (hr : r < 66) (hs : s < 66) (E : Env) :
    run E [(⟨66 + 3 * k, .and p q⟩ : Gate), ⟨66 + 3 * k + 1, .and r s⟩,
           ⟨66 + 3 * k + 2, .xor (66 + 3 * k) (66 + 3 * k + 1)⟩] (66 + 3 * k + 2)
      = ((E p && E q) ^^ (E r && E s)) := by
  have e1 : ∀ (env : Env) (v : Bool), upd env (66 + 3 * k) v r = env r :=
    fun env v => upd_of_ne v (lo_ne_cell0 r k hr)
  have e2 : ∀ (env : Env) (v : Bool), upd env (66 + 3 * k) v s = env s :=
    fun env v => upd_of_ne v (lo_ne_cell0 s k hs)
  have e3 : ∀ (env : Env) (v : Bool),
      upd env (66 + 3 * k + 1) v (66 + 3 * k) = env (66 + 3 * k) :=
    fun env v => upd_of_ne v (cell0_ne_cell1 k)
  simp only [run_cons, run_nil, Op.eval, upd_self, e1, e2, e3]

/-- ⭐ **THE BODY LEMMA.** For a cell generator that (a) writes only its own three
nets and (b) computes `F` of the four nets `k`, `65`, `32+k`, `64`, the body
computes `F` at **every** index below the prefix length, for **every** `Env`. -/
theorem run_body (cell : Nat → List Gate) (F : Bool → Bool → Bool → Bool → Bool)
    (hout : ∀ i : Nat, ∀ g ∈ cell i,
        g.out = 66 + 3 * i ∨ g.out = 66 + 3 * i + 1 ∨ g.out = 66 + 3 * i + 2)
    (hval : ∀ (E : Env) (k : Nat), k < 32 →
        run E (cell k) (66 + 3 * k + 2) = F (E k) (E 65) (E (32 + k)) (E 64))
    (env : Env) :
    ∀ n : Nat, n ≤ 32 → ∀ k : Nat, k < n →
      run env ((List.range n).flatMap cell) (66 + 3 * k + 2)
        = F (env k) (env 65) (env (32 + k)) (env 64) := by
  intro n
  induction n with
  | zero => intro _ k hk; exact absurd hk (Nat.not_lt_zero k)
  | succ n ih =>
    intro hn k hk
    have hn' : n ≤ 32 := by omega
    have hn32 : n < 32 := by omega
    have hsplit : (List.range (n + 1)).flatMap cell
        = (List.range n).flatMap cell ++ cell n := by
      simp [List.range_succ]
    -- The prefix writes nothing below net 66, so the operand nets survive it.
    have hfr : ∀ m : Nat, m < 66 → run env ((List.range n).flatMap cell) m = env m := by
      intro m hm
      refine run_of_unwritten env _ m ?_
      intro g hg
      rw [List.mem_flatMap] at hg
      obtain ⟨i, _, hgi⟩ := hg
      rcases hout i g hgi with h | h | h
      · rw [h]; exact cell0_ne_lo m i hm
      · rw [h]; exact cell1_ne_lo m i hm
      · rw [h]; exact cell2_ne_lo m i hm
    rw [hsplit, run_append]
    rcases Nat.lt_or_ge k n with hkn | hkn
    · -- earlier bits: the last cell does not touch net 66+3k+2
      have hlast : run (run env ((List.range n).flatMap cell)) (cell n) (66 + 3 * k + 2)
          = run env ((List.range n).flatMap cell) (66 + 3 * k + 2) := by
        refine run_of_unwritten _ _ _ ?_
        intro g hg
        rcases hout n g hg with h | h | h
        · rw [h]; exact cell0_ne_out n k hkn
        · rw [h]; exact cell1_ne_out n k hkn
        · rw [h]; exact cell2_ne_out n k hkn
      rw [hlast]
      exact ih hn' k hkn
    · -- the bit this step adds
      have hkn' : k = n := by omega
      rw [hkn', hval _ n hn32, hfr n (by omega), hfr 65 (by omega),
        hfr (32 + n) (by omega), hfr 64 (by omega)]

/-- ⭐⭐ **THE LIFT TO `sem` — i.e. TO THE OUTPUT PORT LIST.**

A circuit whose gate list is *the shared inverter then the array* and whose
**`outs` is the 32 cell outputs in bit order** computes `F` at every port, for
every `Env`. The `outs` hypothesis `ho` is load-bearing: it is the only place
output bit order enters, and it is what makes every certificate below sensitive
to a reversed port list.

*The `run_cons` step is done by `rw`, never by `show`: asking defeq to step `run`
past the head gate is what produced the original's kernel deterministic
timeout at `ScratchMuxA.lean:312`.* -/
theorem sem_block (cell : Nat → List Gate) (F : Bool → Bool → Bool → Bool → Bool)
    (c : Circ)
    (hg : c.gates = (⟨65, .not 64⟩ : Gate) :: (List.range 32).flatMap cell)
    (ho : c.outs = (List.range 32).map (fun k => 66 + 3 * k + 2))
    (hout : ∀ i : Nat, ∀ g ∈ cell i,
        g.out = 66 + 3 * i ∨ g.out = 66 + 3 * i + 1 ∨ g.out = 66 + 3 * i + 2)
    (hval : ∀ (E : Env) (k : Nat), k < 32 →
        run E (cell k) (66 + 3 * k + 2) = F (E k) (E 65) (E (32 + k)) (E 64))
    (ins : Env) :
    sem c ins
      = (List.range 32).map (fun k => F (ins k) (!(ins 64)) (ins (32 + k)) (ins 64)) := by
  show c.outs.map (run ins c.gates) = _
  rw [ho, List.map_map]
  refine List.map_congr_left (fun k hk => ?_)
  have hk32 : k < 32 := List.mem_range.mp hk
  have hbody := run_body cell F hout hval (upd ins 65 (!(ins 64))) 32 (Nat.le_refl 32) k hk32
  rw [upd_of_ne _ (a_ne_65 k hk32), upd_self, upd_of_ne _ (b_ne_65 k hk32),
    upd_of_ne _ sel_ne_65] at hbody
  show run ins c.gates (66 + 3 * k + 2) = _
  rw [hg, run_cons]
  exact hbody

/-! ## 5 · THE BLOCK CERTIFICATE -/

/-- The cell's Boolean function, in the argument order `run_body` uses:
`a_k`, `¬sel`, `b_k`, `sel`. -/
def muxF (a ns b sel : Bool) : Bool := (a && ns) || (b && sel)

theorem outs_obCell (k : Nat) : ∀ g ∈ obCell k,
    g.out = 66 + 3 * k ∨ g.out = 66 + 3 * k + 1 ∨ g.out = 66 + 3 * k + 2 :=
  cell_outs _ _ _ k

theorem run_obCell (E : Env) (k : Nat) (hk : k < 32) :
    run E (obCell k) (66 + 3 * k + 2) = muxF (E k) (E 65) (E (32 + k)) (E 64) :=
  run_cell_or k k 65 (32 + k) 64 (b_lt_66 k hk) sel_lt_66 E

/-- **THE SPEC.** Output `k` is `if sel then b_k else a_k`, in bit order. -/
def muxSpec (ins : Env) : List Bool :=
  (List.range 32).map (fun k => if ins 64 then ins (32 + k) else ins k)

/-- ⭐⭐⭐ **THE BLOCK CERTIFICATE, OVER `sem` AND IN PORT ORDER.**

For **every** input valuation — all `2^65` of them — `obMux`'s output port list
is `muxSpec`. No `decide`, no sample, no fixture: the quantifier is over all of
`Env`. Stated over `sem obMux`, so the circuit's `outs` field is inside the
claim and a reversed port list refutes it. -/
theorem sem_obMux (ins : Env) : sem obMux ins = muxSpec ins := by
  refine (sem_block obCell muxF obMux rfl rfl outs_obCell run_obCell ins).trans ?_
  show _ = (List.range 32).map (fun k => if ins 64 then ins (32 + k) else ins k)
  refine List.map_congr_left (fun k _ => ?_)
  simp only [muxF]
  cases ins 64 <;> simp

/-- ⭐ **THE CERTIFICATE ONE PORT AT A TIME** — literally the acceptance bar:
`∀ E : Env, ∀ k < 32, out_k = if sel then b_k else a_k`, read off `sem obMux`. -/
theorem out_sem_obMux (ins : Env) (k : Nat) (hk : k < 32) :
    (sem obMux ins).getD k false = (if ins 64 then ins (32 + k) else ins k) := by
  rw [sem_obMux, muxSpec]
  rw [List.getD_eq_getElem?_getD, List.getElem?_map]
  simp [hk]

/-- The certificate as a **predicate on circuits**, so "the mutant breaks the
cert" below is literally the negation of what is proved for the block.

⚠️ It is stated over `sem c` — the circuit's OUTPUT PORT LIST — and never over
`run … c.gates <net>`. A net-anchored predicate cannot mention `c.outs` and is
therefore blind to output bit order by construction; `obMuxm4` below is the
mutant that makes the difference visible. -/
def BlockCert (c : Circ) : Prop :=
  ∀ (ins : Env) (k : Nat), k < 32 →
    (sem c ins).getD k false = (if ins 64 then ins (32 + k) else ins k)

/-- The same claim at the granularity of the whole port list. -/
def BlockCertList (c : Circ) : Prop := ∀ ins : Env, sem c ins = muxSpec ins

/-- ⭐ **`obMux` SATISFIES THE CERTIFICATE.** -/
theorem obMux_cert : BlockCert obMux := out_sem_obMux

/-- …and its port-list form. -/
theorem obMux_certList : BlockCertList obMux := sem_obMux

/-! ## 6 · MUTATION CONTROLS

A certificate no mutation breaks is vacuous. Five mutants, each one deliberate
defect away from `obMux`, each still dense-SSA well-formed and each with the
SAME 97 gates — so nothing structural distinguishes them and only the
certificate can.

Four are refuted; the fifth is proved **not** to be a defect. -/

/-- A concrete valuation: word `a` on nets `0…31`, word `b` on `32…63`, `sel` on
net `64`. -/
def obEnv (a b : Nat) (s : Bool) : Env :=
  fun i => if i < 32 then a.testBit i else if i < 64 then b.testBit (i - 32) else s

/-- Witness 1: `sel = 1`, so the block must return `b`; `a = 0`, `b = all ones`,
so returning `a` instead is visible in every bit. -/
def witSel : Env := obEnv 0 0xFFFFFFFF true

/-- Witness 2: `sel = 0`, so the block must return `a`; `a = 1` has bit 0 set and
bit 31 clear, which separates `a_0` from both `a_1` and `a_31`. -/
def witBit : Env := obEnv 1 0 false

/-! ### m1 — SELECT POLARITY INVERTED -/

/-- ⛔ **m1**: `sel` gates the `a` branch and `¬sel` the `b` branch. -/
def obCellm1 (k : Nat) : List Gate :=
  [ ⟨66 + 3 * k,     .and k 64⟩
  , ⟨66 + 3 * k + 1, .and (32 + k) 65⟩
  , ⟨66 + 3 * k + 2, .or (66 + 3 * k) (66 + 3 * k + 1)⟩ ]

def obMuxm1 : Circ :=
  { obMux with gates := (⟨65, .not 64⟩ : Gate) :: (List.range 32).flatMap obCellm1 }

/-! ### m2 — THE a/b BUSES EXCHANGED (the port-order control the brief requires) -/

/-- ⛔ **m2**: the two operand buses are swapped at the cell inputs. `Circ`'s own
docstring names port-order blindness as a known vacuity mode of this suite; a mux
is not commutative in `a`/`b`, so this is the control that pins it. -/
def obCellm2 (k : Nat) : List Gate :=
  [ ⟨66 + 3 * k,     .and (32 + k) 65⟩
  , ⟨66 + 3 * k + 1, .and k 64⟩
  , ⟨66 + 3 * k + 2, .or (66 + 3 * k) (66 + 3 * k + 1)⟩ ]

def obMuxm2 : Circ :=
  { obMux with gates := (⟨65, .not 64⟩ : Gate) :: (List.range 32).flatMap obCellm2 }

/-! ### m3 — AN INDEX SHIFT, AT ONE BIT ONLY -/

/-- ⛔ **m3**: output 0's `a` branch reads `a_1` instead of `a_0`. A ONE-net
defect in 97 gates — deliberately the smallest of the four. -/
def obCellm3 (k : Nat) : List Gate :=
  [ ⟨66 + 3 * k,     .and (if k = 0 then 1 else k) 65⟩
  , ⟨66 + 3 * k + 1, .and (32 + k) 64⟩
  , ⟨66 + 3 * k + 2, .or (66 + 3 * k) (66 + 3 * k + 1)⟩ ]

def obMuxm3 : Circ :=
  { obMux with gates := (⟨65, .not 64⟩ : Gate) :: (List.range 32).flatMap obCellm3 }

/-! ### m4 — OUTPUT PORT ORDER REVERSED -/

/-- ⛔ **m4**: identical gates, `outs` reversed. Bit order is part of the data,
not a convention. This mutant is the reason the certificate must be stated over
`sem` — a cert anchored at a hardcoded net cannot see it at all. -/
def obMuxm4 : Circ := { obMux with outs := obMux.outs.reverse }

/-! ### m5 — THE MERGE `or` REPLACED BY `xor` -/

/-- **m5**: the merge gate is `xor` rather than `or`. -/
def obCellm5 (k : Nat) : List Gate :=
  [ ⟨66 + 3 * k,     .and k 65⟩
  , ⟨66 + 3 * k + 1, .and (32 + k) 64⟩
  , ⟨66 + 3 * k + 2, .xor (66 + 3 * k) (66 + 3 * k + 1)⟩ ]

def obMuxm5 : Circ :=
  { obMux with gates := (⟨65, .not 64⟩ : Gate) :: (List.range 32).flatMap obCellm5 }

/-! ### The mutants are structurally indistinguishable from the block -/

theorem ssa_obMuxm1 : obMuxm1.ssa = true := by decide +kernel
theorem ssa_obMuxm2 : obMuxm2.ssa = true := by decide +kernel
theorem ssa_obMuxm3 : obMuxm3.ssa = true := by decide +kernel
theorem ssa_obMuxm4 : obMuxm4.ssa = true := by decide +kernel
theorem ssa_obMuxm5 : obMuxm5.ssa = true := by decide +kernel

/-- Every mutant has the SAME 97 gates, so no gate count can separate them. -/
theorem gateCount_mutants :
    obMuxm1.gates.length = 97 ∧ obMuxm2.gates.length = 97 ∧ obMuxm3.gates.length = 97
      ∧ obMuxm4.gates.length = 97 ∧ obMuxm5.gates.length = 97 := by decide +kernel

/-- …and they really are different circuits, so the controls are not the block
under another name. -/
theorem distinct_mutants :
    obMuxm1.gates ≠ obMux.gates ∧ obMuxm2.gates ≠ obMux.gates
      ∧ obMuxm3.gates ≠ obMux.gates ∧ obMuxm4.outs ≠ obMux.outs
      ∧ obMuxm5.gates ≠ obMux.gates := by decide +kernel

/-! ### ⛔ THE FOUR REFUTATIONS — the CERT fails, not merely "some net differs"

Each line below is the **negation of `BlockCert`**, the very predicate proved for
`obMux` in `obMux_cert`. The witness is discharged by `decide +kernel`, which
runs the mutant's own 97 gates in the kernel and reads its `outs`. -/

/-- ⛔ **m1 BREAKS THE CERT**: with `sel = 1` it returns `a = 0` where the spec
returns `b = 0xFFFFFFFF`. -/
theorem breaks_obMuxm1 : ¬ BlockCert obMuxm1 := by
  intro h
  exact absurd (h witSel 0 (by omega)) (by decide +kernel)

/-- ⛔ **m2 BREAKS THE CERT** — the a/b bus swap, the control the brief names. -/
theorem breaks_obMuxm2 : ¬ BlockCert obMuxm2 := by
  intro h
  exact absurd (h witSel 0 (by omega)) (by decide +kernel)

/-- ⛔ **m3 BREAKS THE CERT**: one net, one bit, `sel = 0`, `a = 1`. -/
theorem breaks_obMuxm3 : ¬ BlockCert obMuxm3 := by
  intro h
  exact absurd (h witBit 0 (by omega)) (by decide +kernel)

/-- ⛔ **m4 BREAKS THE CERT** — the OUTPUT bit order is pinned. -/
theorem breaks_obMuxm4 : ¬ BlockCert obMuxm4 := by
  intro h
  exact absurd (h witBit 0 (by omega)) (by decide +kernel)

/-- The witnesses are not vacuous: `obMux` itself PASSES at both of them, so the
four lines above separate the mutants from the block rather than separating the
witnesses from everything. -/
theorem witnesses_pass_obMux :
    sem obMux witSel = muxSpec witSel ∧ sem obMux witBit = muxSpec witBit :=
  ⟨sem_obMux _, sem_obMux _⟩

/-! ### ⭐ THE STRONGER FORM — the mutants compute a STATED WRONG FUNCTION

Refuting a cert at one witness says the mutant is wrong somewhere. Saying *what*
the mutant computes, for all `2^65` valuations, is strictly more, and it is what
the original route A reached for. It survives the repair, so it is kept. -/

def swapF1 (a ns b sel : Bool) : Bool := (a && sel) || (b && ns)
def swapF2 (a ns b sel : Bool) : Bool := (b && ns) || (a && sel)

/-- The buses-exchanged spec: `if sel then a_k else b_k`. -/
def swapSpec (ins : Env) : List Bool :=
  (List.range 32).map (fun k => if ins 64 then ins k else ins (32 + k))

theorem outs_obCellm1 (k : Nat) : ∀ g ∈ obCellm1 k,
    g.out = 66 + 3 * k ∨ g.out = 66 + 3 * k + 1 ∨ g.out = 66 + 3 * k + 2 :=
  cell_outs _ _ _ k

theorem run_obCellm1 (E : Env) (k : Nat) (hk : k < 32) :
    run E (obCellm1 k) (66 + 3 * k + 2) = swapF1 (E k) (E 65) (E (32 + k)) (E 64) :=
  run_cell_or k k 64 (32 + k) 65 (b_lt_66 k hk) ns_lt_66 E

theorem outs_obCellm2 (k : Nat) : ∀ g ∈ obCellm2 k,
    g.out = 66 + 3 * k ∨ g.out = 66 + 3 * k + 1 ∨ g.out = 66 + 3 * k + 2 :=
  cell_outs _ _ _ k

theorem run_obCellm2 (E : Env) (k : Nat) (hk : k < 32) :
    run E (obCellm2 k) (66 + 3 * k + 2) = swapF2 (E k) (E 65) (E (32 + k)) (E 64) :=
  run_cell_or k (32 + k) 65 k 64 (a_lt_66 k hk) sel_lt_66 E

/-- **m1 computes `if sel then a else b`** — at every one of the `2^65` inputs. -/
theorem sem_obMuxm1 (ins : Env) : sem obMuxm1 ins = swapSpec ins := by
  refine (sem_block obCellm1 swapF1 obMuxm1 rfl rfl outs_obCellm1 run_obCellm1 ins).trans ?_
  show _ = (List.range 32).map (fun k => if ins 64 then ins k else ins (32 + k))
  refine List.map_congr_left (fun k _ => ?_)
  simp only [swapF1]
  cases ins 64 <;> simp

/-- **m2 computes the same wrong function**, likewise for all inputs. -/
theorem sem_obMuxm2 (ins : Env) : sem obMuxm2 ins = swapSpec ins := by
  refine (sem_block obCellm2 swapF2 obMuxm2 rfl rfl outs_obCellm2 run_obCellm2 ins).trans ?_
  show _ = (List.range 32).map (fun k => if ins 64 then ins k else ins (32 + k))
  refine List.map_congr_left (fun k _ => ?_)
  simp only [swapF2]
  cases ins 64 <;> simp

/-- ⚠️ **THE TWO CONTROLS COINCIDE**, at every input, though the circuits differ.
Inverting the select and exchanging the buses are ONE defect counted twice.
Reported rather than hidden: a suite that scored them as two independent controls
would be over-reporting its own coverage by one. -/
theorem same_m1_m2 (ins : Env) : sem obMuxm1 ins = sem obMuxm2 ins := by
  rw [sem_obMuxm1, sem_obMuxm2]

/-- …and the swapped spec really is a different function from the mux, so
`swapSpec` is not a renaming of `muxSpec`. -/
theorem swapSpec_ne_muxSpec : swapSpec witSel ≠ muxSpec witSel := by decide +kernel

/-- ⛔ **m1 BREAKS THE PORT-LIST CERT — with no `decide` in the argument at all**:
it computes `swapSpec` everywhere, and `swapSpec` differs from `muxSpec`. -/
theorem breaksList_obMuxm1 : ¬ BlockCertList obMuxm1 := fun h =>
  swapSpec_ne_muxSpec ((sem_obMuxm1 witSel).symm.trans (h witSel))

/-- ⛔ **m2 BREAKS THE PORT-LIST CERT**, same way. -/
theorem breaksList_obMuxm2 : ¬ BlockCertList obMuxm2 := fun h =>
  swapSpec_ne_muxSpec ((sem_obMuxm2 witSel).symm.trans (h witSel))

/-- **m4 is the block, read backwards** — proved for every input, not sampled.
This is what "the certificate is stated over `sem`" buys: the mutant's gate list
is byte-identical to the block's, so ONLY `outs` separates them. -/
theorem sem_obMuxm4 (ins : Env) : sem obMuxm4 ins = (sem obMux ins).reverse := by
  show (obMux.outs.reverse).map (run ins obMux.gates)
      = (obMux.outs.map (run ins obMux.gates)).reverse
  simp

/-- The reversed port list really is a different list here. -/
theorem revSpec_ne_muxSpec : (muxSpec witBit).reverse ≠ muxSpec witBit := by decide +kernel

/-- ⛔ **m4 BREAKS THE PORT-LIST CERT** — structurally, from `sem_obMuxm4`. -/
theorem breaksList_obMuxm4 : ¬ BlockCertList obMuxm4 := by
  intro h
  have h1 : (sem obMux witBit).reverse = muxSpec witBit :=
    (sem_obMuxm4 witBit).symm.trans (h witBit)
  rw [sem_obMux witBit] at h1
  exact revSpec_ne_muxSpec h1

/-! ### ⭐ m5 IS NOT A DEFECT, AND THAT IS A FINDING

*The merge sees a ONE-HOT pair* — `t1` and `t2` cannot both be true, because one
is gated by `sel` and the other by `¬sel` — so `or` and `xor` agree here. Proved
for all `2^65` valuations by the same body induction, not sampled.

⇒ **A mutation suite that assumed "any single-op change breaks the cert" would
have reported a false negative here.** The merge gate is genuinely free, which is
a fact about the design (an XOR2 cell may be cheaper than an OR2 in some
libraries) rather than a hole in the certificate. -/

theorem outs_obCellm5 (k : Nat) : ∀ g ∈ obCellm5 k,
    g.out = 66 + 3 * k ∨ g.out = 66 + 3 * k + 1 ∨ g.out = 66 + 3 * k + 2 :=
  cell_outs _ _ _ k

def muxFx (a ns b sel : Bool) : Bool := (a && ns) ^^ (b && sel)

theorem run_obCellm5 (E : Env) (k : Nat) (hk : k < 32) :
    run E (obCellm5 k) (66 + 3 * k + 2) = muxFx (E k) (E 65) (E (32 + k)) (E 64) :=
  run_cell_xor k k 65 (32 + k) 64 (b_lt_66 k hk) sel_lt_66 E

/-- ⭐ **m5 SATISFIES THE BLOCK CERTIFICATE** — at every input valuation. -/
theorem sem_obMuxm5 (ins : Env) : sem obMuxm5 ins = muxSpec ins := by
  refine (sem_block obCellm5 muxFx obMuxm5 rfl rfl outs_obCellm5 run_obCellm5 ins).trans ?_
  show _ = (List.range 32).map (fun k => if ins 64 then ins (32 + k) else ins k)
  refine List.map_congr_left (fun k _ => ?_)
  simp only [muxFx]
  cases ins 64 <;> simp

/-- The `or` and the `xor` blocks are the same function though different
circuits — fungibility, at 97 gates. -/
theorem fungible_or_xor (ins : Env) : sem obMux ins = sem obMuxm5 ins := by
  rw [sem_obMux, sem_obMuxm5]

/-- …so m5 passes the certificate, stated as such. -/
theorem obMuxm5_cert : BlockCertList obMuxm5 := sem_obMuxm5

/-! ## 7 · AUDIT — ONE DECLARATION PER CALL

`#audit_axioms` aborts the remainder of its own argument list at the first
failure, silently hiding the status of every name after it. One name per line is
the only form whose green is readable. -/

#audit_axioms lo_ne_cell0
#audit_axioms cell0_ne_lo
#audit_axioms cell1_ne_lo
#audit_axioms cell2_ne_lo
#audit_axioms cell0_ne_cell1
#audit_axioms cell0_ne_out
#audit_axioms cell1_ne_out
#audit_axioms cell2_ne_out
#audit_axioms a_lt_66
#audit_axioms b_lt_66
#audit_axioms sel_lt_66
#audit_axioms ns_lt_66
#audit_axioms a_ne_65
#audit_axioms b_ne_65
#audit_axioms sel_ne_65
#audit_axioms obCell
#audit_axioms obMux
#audit_axioms nIn_obMux
#audit_axioms ssa_obMux
#audit_axioms wf_obMux
#audit_axioms nodup_obMux
#audit_axioms dense_obMux
#audit_axioms gateCount_obMux
#audit_axioms census_obMux
#audit_axioms exhibit_obMux
#audit_axioms muxCell
#audit_axioms ssa_muxCell
#audit_axioms wf_muxCell
#audit_axioms cols3
#audit_axioms spec_cols3
#audit_axioms cols3_zero
#audit_axioms sliced_muxCell
#audit_axioms slicedOut_muxCell
#audit_axioms agree_cols3
#audit_axioms pointwise_muxCell
#audit_axioms bits202
#audit_axioms isMux_muxCell
#audit_axioms stepCert_muxCell
#audit_axioms cell_outs
#audit_axioms run_cell_or
#audit_axioms run_cell_xor
#audit_axioms run_body
#audit_axioms sem_block
#audit_axioms muxF
#audit_axioms outs_obCell
#audit_axioms run_obCell
#audit_axioms muxSpec
#audit_axioms sem_obMux
#audit_axioms out_sem_obMux
#audit_axioms BlockCert
#audit_axioms BlockCertList
#audit_axioms obMux_cert
#audit_axioms obMux_certList
#audit_axioms obEnv
#audit_axioms witSel
#audit_axioms witBit
#audit_axioms obCellm1
#audit_axioms obMuxm1
#audit_axioms obCellm2
#audit_axioms obMuxm2
#audit_axioms obCellm3
#audit_axioms obMuxm3
#audit_axioms obMuxm4
#audit_axioms obCellm5
#audit_axioms obMuxm5
#audit_axioms ssa_obMuxm1
#audit_axioms ssa_obMuxm2
#audit_axioms ssa_obMuxm3
#audit_axioms ssa_obMuxm4
#audit_axioms ssa_obMuxm5
#audit_axioms gateCount_mutants
#audit_axioms distinct_mutants
#audit_axioms breaks_obMuxm1
#audit_axioms breaks_obMuxm2
#audit_axioms breaks_obMuxm3
#audit_axioms breaks_obMuxm4
#audit_axioms witnesses_pass_obMux
#audit_axioms swapF1
#audit_axioms swapF2
#audit_axioms swapSpec
#audit_axioms outs_obCellm1
#audit_axioms run_obCellm1
#audit_axioms outs_obCellm2
#audit_axioms run_obCellm2
#audit_axioms sem_obMuxm1
#audit_axioms sem_obMuxm2
#audit_axioms same_m1_m2
#audit_axioms swapSpec_ne_muxSpec
#audit_axioms breaksList_obMuxm1
#audit_axioms breaksList_obMuxm2
#audit_axioms sem_obMuxm4
#audit_axioms revSpec_ne_muxSpec
#audit_axioms breaksList_obMuxm4
#audit_axioms outs_obCellm5
#audit_axioms muxFx
#audit_axioms run_obCellm5
#audit_axioms sem_obMuxm5
#audit_axioms fungible_or_xor
#audit_axioms obMuxm5_cert

end OperandB
end SaltWorks.HDL

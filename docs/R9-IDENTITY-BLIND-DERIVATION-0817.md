# R9 IDENTITY — THE BLIND ARM'S DERIVATION (round 4, act 0)

> Custody: the HELM's pen (this is the blind twin's artifact, not compiler's; one pen per
> artifact). Dispatched by the maestro at 16:16 on the packet `50a2f5f` ONLY, under the
> 16:09:02 blind-twin ruling; the derivation below is verbatim as returned, nothing edited.
> Ordering in git: packet `50a2f5f` (16:12:33) → compiler's adjudication `d570b81`
> (16:18:32) → this file. The blind agent never read the adjudication, compiler's block,
> bank, or any bus content after 16:09; its one accidental exposure is disclosed in full at
> the bottom, as it wrote it.

---

## Pin verification (performed before deriving)

| Packet citation | Verified at | Status |
|---|---|---|
| `CycleRealisesStepProj` — Program.lean:1484 | `SaltWorks/Stack/Program.lean:1484-1489` | MATCH, verbatim |
| `stepT` — ISA.lean:1115 | `SaltWorks/HDL/ISA.lean:1115` | MATCH, verbatim |
| `St.next` — ISA.lean:207 | `SaltWorks/HDL/ISA.lean:207` | MATCH, verbatim |
| `stepT_undecodable` — ISA.lean:1128 | ISA.lean:1127-1129 (keyword line 1127; cited line is inside the declaration) | MATCH |
| `not_cycleRealisesStep_id` — :1900 | Program.lean:1900 | MATCH |
| `not_cycleRealisesStep_stalledBits` — :2404 | Program.lean:2404-2411 | MATCH |
| `C4Spec` — C4.lean:76 | `SaltWorks/HDL/C4.lean:76-77` | MATCH, verbatim |
| `cycleRealisesStep_of_C4Spec` — Program.lean:2306 | Program.lean:2306-2309 | MATCH, verbatim |
| `not_C4Spec_coreShaped` — ":2859" | **Program.lean**:2859, NOT C4.lean (C4.lean is 178 lines long) | line right, **file attribution in the packet's Object B section is misleading** |
| `not_both_coreShaped_C4Spec` — ":2472" | **Program.lean**:2472 | same caveat |

I also independently verified the packet's "consumed everywhere, inhabited nowhere" claim: every positive statement about `C4Spec` in the tree is a consequence of a *hypothesized* witness (`outs_length_of_C4Spec` C4.lean:115 and Program.lean:2324; the bridge :2306; `cycOfCirc_pad_irrelevant` :2459); the only decided instances are negative (:2472, :2859); and Program.lean:2487-2488 records that no `core`/`compile` declaration exists. Program.lean:2198: "no `Circ` can witness it until `core` exists."

## 1. ONE or TWO?

**TWO.** They are distinct obligations with disjoint subject types and disjoint discharge material.

- **A** is *specification surgery on a predicate over cycle maps* (`Env → Env`): add a stall disjunct to `CycleRealisesStepProj` (Program.lean:1484), with acceptance criteria (a) empty-stall reduction and (b) stall-arm non-emptiness. Every object needed to discharge A is already landed: `decQ_cycOfBits_stalled` (Program.lean:2389-2397) proves the stalled map holds `(regs, pc)` exactly — so it *inhabits* the stall arm — and `not_cycleRealisesStep_stalledBits` (Program.lean:2404) proves it *fails* the step arm, so the disjunction is non-degenerate. A requires no `Circ` and no `C4Spec` witness.
- **B** is *term construction over circuits*: a concrete `c : Circ` plus a kernel proof of `C4Spec c` (C4.lean:76-77). `C4Spec`'s statement is closed over HDL vocabulary (`sem`, `encD`, `stepT`, `decQ`, `seenWord`); it never mentions cycle maps or `CycleRealisesStepProj`, and its truth for a given `c` is unaffected by any surgery on Program.lean's predicate.

The two negative results the packet cites live on *opposite sides* of the divide, which is the tell: `not_cycleRealisesStep_stalledBits` refutes a **cycle map** against A's predicate; `not_C4Spec_coreShaped` (Program.lean:2859) refutes a **circuit** against B's sentence. Neither discharges nor blocks the other.

## 2. The seam

The seam is **the bridge theorem `cycleRealisesStep_of_C4Spec` at Program.lean:2306, and it runs in one direction only: B → A.** What crosses it: a witness pair `(c, h : C4Spec c)`, transported by `cycOfCirc c nextW pad` (Program.lean:2294) — concretely, the circuit's output function `sem c` is fed as the bit function `f` into `cycleRealisesStepProj_of_bits` (Program.lean:2282) — landing as a witness of `CycleRealisesStepProj`, i.e. in the **step arm** of A's future disjunction. Nothing crosses A → B: no theorem in the tree derives `C4Spec` from any cycle-map fact, and `C4Spec`'s statement cannot even see the predicate. After A's surgery, A's own criterion (a) — reduction to today's predicate at the empty stall set — is exactly what keeps the bridge alive by composition (`C4Spec c` → today's predicate → stall-armed predicate, stall set empty). So the bridge's re-land is *seam maintenance inside obligation A*, not a third obligation; the bridge is itself one of the `CycleRealisesStepProj`-consuming declarations that criterion (a)'s "cone survives" clause covers.

## 3. What would flip my answer

**If the intended C4 witness is itself a stalling machine** — i.e., if the core to be constructed is multi-cycle, so that on some inputs `sem core ins = encD (decQ ins)` (a re-presented state) rather than `encD (stepT (decQ ins) (seenWord ins))` — then `C4Spec` as written at C4.lean:76 is unsatisfiable *by the intended witness*, R9's real task becomes stating and proving a stall-armed variant of C4, and A and B fuse into one obligation. The global form of the same flip: a landed theorem `¬ ∃ c, C4Spec c` (the analogue of the whole-`St` unsatisfiability recorded in the comment at Program.lean:1472-1477) would kill B-as-stated and leave its only live successor identical to A. Nothing in the tree asserts either: only two specific candidates are refuted (:2472, :2859), and `idealBits` (Program.lean:2374) exhibits the target bit function as a definable, bridge-satisfying object (`cycleRealisesStep_idealBits`, :2380), so `C4Spec` is not known-uninhabitable — and the tree's cycle model is explicitly "a one-cycle machine" (`cycOf`, Program.lean:1866-1874).

## 4. Obligation count

**TWO, and the count is right.** Not double-counted: A and B have disjoint discharge material (A: predicate redefinition + two already-landed lemmas rearranged; B: a nonexistent `Circ` term + a fresh kernel proof), so dating one rung for both would leave a real construction with no date. Not zero-counted: both have owners in the plan as the packet states it (A = round 4, B = R9), and the one object that could hide between them — the bridge's re-elaboration after the predicate changes — is owned, because it sits inside A's acceptance criterion (a): the bridge at Program.lean:2306 is a member of the `CycleRealisesStepProj` cone whose survival that criterion demands. The count is 2 open obligations plus 1 already-discharged seam theorem to be preserved, not re-proved.

## Derivation narrative

I read the packet, then verified all ten pins against the tree; seven match at the stated line verbatim, one (`stepT_undecodable`) is pinned one line into its own declaration, and two (`not_C4Spec_coreShaped`, `not_both_coreShaped_C4Spec`) carry correct line numbers but sit in Program.lean, not C4.lean as the packet's Object B section implies by placement. The identity question then falls to types: Object A is a Prop-shape decision about maps `Env → Env` whose entire discharge kit (`stalledBits`, `decQ_cycOfBits_stalled`, `not_cycleRealisesStep_stalledBits`) is landed; Object B is the construction of a `Circ` term that does not exist plus a proof of a sentence (`C4Spec`) that mentions no cycle-map vocabulary. The single landed theorem naming both, `cycleRealisesStep_of_C4Spec`, is relevant precisely as the seam and only in the B-to-A direction — it converts a future C4 witness into a step-arm inhabitant, and A's empty-stall reduction criterion is what will carry it across the surgery unchanged. Since a `C4Spec`-satisfying circuit *never* stalls (its induced map lands in the step arm by the bridge), while the stall arm exists to admit maps that `C4Spec` can never produce, the two obligations cannot be the same one under two names; they would merge only if the intended core were itself a staller, which nothing landed asserts.

**Blindness disclosure:** while grepping `C4Spec` across `SaltWorks/` to verify "inhabited nowhere," the results surfaced approximately six lines of `SaltWorks/HDL/ScratchR9Identity.lean`, a file that is evidently adjudication material for this very question (its visible line 7 references "my conclusion"). I stopped reading it immediately and did not open it. The exposed fragments contained two contrapositive-shaped theorem statements and no ONE/TWO conclusion; my TWO-with-bridge-seam derivation was already formed from Program.lean:2306 before that grep ran. If the adjudication requires a fully uncontaminated arm, that exposure should be weighed; the fragments did not contain the other arm's verdict.

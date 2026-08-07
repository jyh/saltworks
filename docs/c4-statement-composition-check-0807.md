# C4STMT — THE COMPOSED STATEMENT, ELABORATED (C1+C3's joint artifact)
### 2026-08-07 · Opus executor · type-level only, no proof
### `ScratchC4STMT.lean` · `saltbuild EXIT=0` · deleted, never committed

**VERDICT: ✅ IT ELABORATES.** The composed C4 statement — Route B ×
option 1, both as ratified — typechecks with **no coercion anywhere in it**.
The `List Bool → (Net → Bool)` seam the brief anticipated **does not exist**:
`SaltWorks.HDL.Env` is `abbrev Net → Bool` and `Net` is `abbrev Nat`, so
`SaltWorks.Silicon.runP` and `SaltWorks.HDL.decQ` share one type by
reducibility. **The freeze's precondition is met and C1/C3 may freeze.**

⚠️ **But two things the ruling does not fix are now visible, and neither is a
type error — which is exactly why they had to be found here:** the ruling
**names no input net for the instruction word** (§3.3), and the two positional
conventions the statement uses are **asymmetric** (§3.4). Both are stated
below as posits, so nothing is hidden inside a proof.

---

## §1 THE RATIFIED TEXT BEING CHECKED

`docs/riscv-core-campaign-v0.md:81–89` — the shape and the observation point:

> per cycle, at the flop boundary (Q-leaves/D-roots),
> `(Silicon.runP ins [] (emitN (compile core)))` projected at the
> D-roots `=` the state encoding of `SaltWorks.ISA.step` applied at the
> Q-leaves' decoding — composed with `emitPipeline'_sem` (landed) —
> NOT `emitN_sem`: ROUTE B per compiler's 07f6040, ADOPTED. The theorem
> observes `emitN (normalize (opt (compile core)))` — the netlist that
> ACTUALLY tapes out; its hypothesis `(compile core).wf = true` holds
> by construction (SSA discharged internally, not C4's to carry);
> `encD` indexes the NORMALIZED port list.

`docs/riscv-core-campaign-v0.md:90–94` — the partiality ruling:

> **PARTIALITY (RATIFIED BY THE CAPTAIN 8/7 ~11:45 — "ratified,
> option 1" …): OPTION 1 — total `stepT` on
> words + the COMPATIBILITY OBLIGATION as a named theorem
> (`stepW s w = some s' → stepT s w = s'`); undecodable words =
> defined NOP-advance (PC+4).**

`docs/riscv-core-campaign-v0.md:102–104` — this node's own warrant:

> The EXACT statement is C1+C3's first joint artifact and must be
> COMPOSITION-CHECKED (a `Scratch` elaboration of the statement's type, no
> proof) before either freezes.

### The landed pieces, printed rather than assumed (F2 control)

Every one of these came off the build, not off a grep:

```
SaltWorks.HDL.emitPipeline'      : Circ → Silicon.Netlist          Renumber.lean:726
SaltWorks.HDL.emitPipeline'_sem  : ∀ (c : Circ), c.wf = true → ∀ (ins : Env),
    List.map (fun n => (Silicon.runP ins [] (emitPipeline' c)).getD n false)
        (normalize (opt c)).outs = sem c ins                       Renumber.lean:732
SaltWorks.HDL.emitPipeline_sem   : ∀ (c : Circ), c.ssa = true → ∀ (ins : Env),
    List.map (fun n => (Silicon.runP ins [] (emitPipeline c)).getD n false)
        c.outs = sem c ins                                         EmitN.lean:311
SaltWorks.Silicon.runP           : (ℕ → Bool) → List Bool → Netlist → List Bool
                                                     Equiv/BitSliced.lean:88
SaltWorks.HDL.encD               : ISA.St → List Bool              StateCodec.lean:81
SaltWorks.HDL.decQ               : Env → ISA.St                    StateCodec.lean:84
SaltWorks.HDL.wordOf             : (ℕ → Bool) → BitVec 32          StateCodec.lean:65
SaltWorks.HDL.stWidth            : ℕ                     (= 1056)  StateCodec.lean:60
SaltWorks.HDL.decQ_encD          : ∀ s, decQ (fun j => (encD s).getD j false) = s
SaltWorks.ISA.stepT              : St → BitVec 32 → St             ISA.lean:687
SaltWorks.ISA.stepT_compat       : ∀ s w s', stepW s w = some s' → stepT s w = s'
                                                                   ISA.lean:694
SaltWorks.HDL.opt_outs           : ∀ c, (opt c).outs = c.outs      EmitN.lean:294
```

---

## §2 THE COMPOSED STATEMENT — verbatim Lean, as elaborated

Posits first. `compile` and `core` **still do not exist in the tree** (silicon's
F1 of 8/6; compiler's §1 of 8/7 — re-greped today, still zero declarations), so
they are variables at the types PROBE 1/2 fixed. `instrBase` is a posit the
ruling forces and does not supply (§3.3).

```lean
variable {Src : Type} (compile : Src → SaltWorks.HDL.Circ) (core : Src)
variable (instrBase : Nat)

/-- **C4, composed.** Route B (`emitPipeline'_sem`, hypothesis `wf`, observation
at the NORMALIZED port list) × option 1 (`ISA.stepT`, total on words). -/
theorem C4_compile_correct
    (h : (compile core).wf = true) (ins : SaltWorks.HDL.Env) :
    (SaltWorks.HDL.normalize (SaltWorks.HDL.opt (compile core))).outs.map
        (fun n => (SaltWorks.Silicon.runP ins []
                     (SaltWorks.HDL.emitPipeline' (compile core))).getD n false)
      = SaltWorks.HDL.encD
          (SaltWorks.ISA.stepT
            (SaltWorks.HDL.decQ ins)
            (SaltWorks.HDL.wordOf (fun k => ins (instrBase + k)))) :=
  sorry
```

**And the state-indexed variant**, which is the same claim driven from `(s, w)`
rather than from an arbitrary environment — the form C5's cycle induction will
want, because it is the one that composes with `decQ_encD`:

```lean
/-- The core's input environment built from a state and a fetched word:
`encD`'s bits on `0 … 1055`, the word on `instrBase …`. -/
def insOf (instrBase : Nat) (s : SaltWorks.ISA.St) (w : BitVec 32) :
    SaltWorks.HDL.Env :=
  fun n => if n < SaltWorks.HDL.stWidth then (SaltWorks.HDL.encD s).getD n false
           else w.getLsbD (n - instrBase)

theorem C4_compile_correct'
    (h : (compile core).wf = true) (s : SaltWorks.ISA.St) (w : BitVec 32) :
    (SaltWorks.HDL.normalize (SaltWorks.HDL.opt (compile core))).outs.map
        (fun n => (SaltWorks.Silicon.runP (insOf instrBase s w) []
                     (SaltWorks.HDL.emitPipeline' (compile core))).getD n false)
      = SaltWorks.HDL.encD (SaltWorks.ISA.stepT s w) :=
  sorry
```

Both elaborate. `saltbuild EXIT=0`; the **only** diagnostics in the clean pass
were the two expected `declaration uses 'sorry'` warnings.

---

## §3 THE VERDICT

### 3.1 ✅ IT ELABORATES — and the anticipated coercion is not there

The brief flagged `encD : St → List Bool` against `decQ : Env → St` as *"a real
coercion — `List Bool → (Net → Bool)`"*. **On the ratified shape it never
arises**, for two independent reasons:

1. **Both sides of the equation are `List Bool`.** `emitPipeline'_sem`'s
   observation is `List.map … (normalize (opt c)).outs : List Bool`, and
   `encD s : List Bool`. The equation is list-to-list; nothing is converted.
2. **`Env` is not a distinct type from `runP`'s input.**
   `abbrev Env := Net → Bool` (`Sem.lean:32`) and `abbrev Net := Nat`
   (`Syntax.lean:46`) are both **reducible**, and `runP : (ℕ → Bool) → …`.
   So `ins : SaltWorks.HDL.Env` feeds `SaltWorks.Silicon.runP` **directly**,
   and `SaltWorks.HDL.decQ ins` consumes the same object. Zero coercions.

The `List Bool → Env` direction appears only where the statement is driven from
a state (`insOf`), and there it is written explicitly with `.getD n false` —
the same idiom `decQ_encD` already uses, so it composes with the landed round
trip rather than needing a new lemma.

### 3.2 ✅ ROUTE B IS THE RIGHT OBSERVATION POINT — confirmed, with one thing measured

`emitPipeline'_sem` (`Renumber.lean:732`) **is** the primed one, and it is the
one C4 must use. The three reasons in compiler's ADDENDUM 2 stand unchanged. I
add the measurement that addendum left as a convention rather than a fact:

```lean
example (c : SaltWorks.HDL.Circ) :
    (SaltWorks.HDL.normalize (SaltWorks.HDL.opt c)).outs.length = c.outs.length := by
  simp [SaltWorks.HDL.normalize, SaltWorks.HDL.opt_outs]
```

✅ **Kernel-checked, EXIT=0.** `normalize`'s `outs` is `c.outs.map (renum c)`
(`Renumber.lean:155`) and `opt_outs` gives `(opt c).outs = c.outs`, so the
normalized port list is **the same list, same order, same length — renumbered
nets only**. ⇒ *"`encD` indexes the NORMALIZED port list" costs `compile`
nothing it was not already owed: the k-th port is the k-th port either way.*
**Route B's stated cost is smaller than the ruling priced it.**

⚠️ **The unprimed `emitPipeline_sem` (`EmitN.lean:311`) also elaborates in this
position** — it differs only in hypothesis (`ssa` vs `wf`) and port list
(`c.outs` vs the normalized one). **The type checker cannot tell you which one
C4 means.** The ruling does, and that is why the ruling was needed.

### 3.3 ⛔ THE FINDING: THE INSTRUCTION WORD HAS NO NET, AND THE RULING DOES NOT GIVE IT ONE

`StateCodec.lean:36–44` fixes the input layout for the **state**:

```
0 … 1023      register r, bit k, at 32*r + k
1024 … 1055   pc, bit k, at 1024 + k
```

**The fetched instruction word is not in that layout.** But option 1 makes
`stepT : St → BitVec 32 → St` — it *takes a word*, so C4's right-hand side
cannot be written without saying where the word enters the circuit. Nothing in
`StateCodec`, `Decoder.lean`, `RegNext.lean` or the ruling names an input net
for it; `grep -F 1056` over `SaltWorks/` returns only `stWidth`'s own
definition and its docstring.

⇒ **`instrBase` above is a posit, and it is the one thing in the statement
that is invented rather than read.** *It is cheap to fix now and expensive
later: it is a layout decision, the same class as the one `StateCodec` fixed
deliberately ahead of `core`.* **Recommendation: pin `instrBase = stWidth`
(= 1056) in `StateCodec` alongside the state layout, so the whole input map is
in one file and `core` conforms to it rather than the other way round.**

🔴 **AND THE TRAP THIS OPENS, MEASURED:** because `Env` reduces to `Nat → Bool`,

```lean
#check fun (ins : SaltWorks.HDL.Env) => SaltWorks.HDL.wordOf ins
-- fun ins => SaltWorks.HDL.wordOf ins : SaltWorks.HDL.Env → BitVec 32
```

**typechecks** — and reads bits `0 … 31`, which under the fixed layout are
**register `x0`**, not the instruction word. *A C4 written `wordOf ins` instead
of `wordOf (fun k => ins (instrBase + k))` would be a well-typed theorem about
the wrong 32 wires.* **Lean will not catch this one; only the layout being
written down will.**

### 3.4 ⚠️ THE TWO SIDES USE DIFFERENT INDEXING CONVENTIONS — stated, not defective

```
INPUT  side   decQ ins            reads ins at NET NUMBERS 32*r+k and 1024+k
OUTPUT side   outs.map (…)        reads POSITIONALLY, port k for state bit k
```

Both are legitimate and each is separately ratified (`StateCodec`'s layout;
the pipeline law's positional docstring). **They are not the same convention**,
and `core` must satisfy both: primary input `j` *is* state bit `j`, while
output *position* `k` *is* state bit `k` at whatever net `renum` assigns.
*This is not a mismatch — it is an asymmetry that reads as a mismatch if
nobody writes it down, so here it is written down.*

### 3.5 📌 THE `decQ`-ON-THE-OUTPUT FORM ELABORATES AND IS THE WRONG STATEMENT

The brief's sketch put `decQ` on the netlist side. It typechecks:

```lean
#check (∀ (s : SaltWorks.ISA.St) (w : BitVec 32),
    SaltWorks.HDL.decQ
        (fun n => (SaltWorks.Silicon.runP (insOf instrBase s w) []
                     (SaltWorks.HDL.emitPipeline' (compile core))).getD n false)
      = SaltWorks.ISA.stepT s w : Prop)     -- ✅ elaborates
```

⛔ **But it means something else.** `runP`'s result is indexed **by net number**,
so `decQ` applied to it reads D-roots at nets `32*r+k` / `1024+k` — *net
numbers that `normalize` assigns and that have no reason to be the state layout
indices.* It **silently drops `outs` entirely**, so port order — *"part of the
data, not a convention"* (`Syntax.lean:77`) — is never consulted. **This is the
port-order blindness the leg-2 refuter pass named as a vacuity mode, arriving
in the statement rather than in a certificate.** ⇒ *Use the list form of §2.
The type checker cannot separate them; this paragraph is the separation.*

### 3.6 THE NEGATIVE CONTROLS — the probe discriminates

*A file that merely builds is not evidence.* Two deliberate errors, run in
pass 1 of the same scratch file, both fired:

```
NC1  sem (emitPipeline' (compile core)) ins  =  …      -- v0's own defect
     error: Application type mismatch: The argument
       SaltWorks.HDL.emitPipeline' (compile core)
     has type SaltWorks.Silicon.Netlist
     but is expected to have type SaltWorks.HDL.Circ

NC2  … = encD (SaltWorks.ISA.stepW (decQ ins) 0)       -- the partiality seam
     error: Application type mismatch: The argument
       SaltWorks.ISA.stepW (SaltWorks.HDL.decQ ins) 0
     has type Option SaltWorks.ISA.St
     but is expected to have type SaltWorks.ISA.St
```

⭐ **NC2 is the ratification, measured.** It is §3 of the 8/7 check verbatim —
the error the freeze existed to remove — and swapping `stepW` for `stepT` is
the *only* edit between it and `C4_compile_correct`. **Option 1 is what closes
this statement, and this is the receipt.**

### 3.7 ✅ THE TWO TOTALITIES AGREE

The brief asked whether the netlist side and the ISA side are total in the same
way. **They are, and the agreement is now structural rather than lucky:**
`Silicon.runP` is a total `List Bool` on every input configuration; `stepT` is
total on all `2^32` words by `(stepW s w).getD s.next` (`ISA.lean:687`). There
is no input on which one side is defined and the other is not. *This is exactly
what option 1 bought, and it is the difference between §2 elaborating and NC2
failing.*

---

## §4 WHAT EACH SIDE MUST NOW SUPPLY

Nothing here is a change to close a mismatch — **the statement closes.** These
are the obligations the statement *creates*, listed because a theorem that
elaborates against posits is only as good as the posits.

| # | Owner | Obligation |
|---|---|---|
| 1 | C3 (`core`) | `(compile core).wf = true` — the only hypothesis. Discharged by construction; `ssa` is **not** C4's (route B settles it internally). |
| 2 | C3 (`core`) | **`(compile core).outs.length = 1056`**, in `encD`'s D-root order. ⚠️ **The types do NOT enforce this** — both sides are `List Bool` at any length, so a 1055-output core gives a well-typed, false theorem. This is the largest unenforced obligation in the statement. |
| 3 | C3 (`core`) | Primary inputs `0 … 1055` are the Q-leaves in `StateCodec`'s layout — `decQ ins` is only the state if `core` conforms. |
| 4 | **the ruling** | **Pin `instrBase`** (§3.3). Recommended: `= stWidth`, written into `StateCodec` beside the state layout. |
| 5 | C1 (ISA) | Already discharged: `stepT_compat` (`ISA.lean:694`) is landed and is the compatibility obligation the ruling names, **definitionally** rather than by a provable-and-possibly-wrong theorem. |
| 6 | C5 | The `(s, w)`-driven variant (§2, second theorem) is the cycle-induction hinge; it needs `decQ_encD` (landed) and nothing else new. |

---

## §5 WHAT I COULD NOT DETERMINE

1. **Whether the statement is TRUE.** This node checked one thing: that it
   elaborates. **No proof was attempted and none should be read into this
   document.** Both theorems carry `sorry`, in a scratch file that was deleted.
2. **Whether `compile core` can actually be given 1056 outputs at core scale.**
   `RegNext.lean`'s own finding — `Circ.wf` is quadratic in gate count and a
   3,104-gate array already hit `EXIT=134` inside the kernel — means
   obligation 1 of §4 may be **unprovable by `decide`** at full size and need
   the per-cone decomposition instead. *I did not measure that; I am flagging
   that "holds by construction" is an assertion about a circuit nobody has
   built.*
3. **Whether `instrBase = stWidth` is the right pin.** It is the cheapest and
   keeps one layout in one file, but the block layouts I read
   (`rnCur R W r k = R + W + W*r + k`, `RegNext.lean:79`; `dcIn = 32`,
   `Decoder.lean:68`) are **local** numberings that `Compose.lean`'s `instMap`
   will shift. **Whether the core's top-level input map can start with the
   state at 0 is an assembly question `Compose.lean` answers, and `inst_sem`
   is `#check`ed and NOT PROVED there** (`Compose.lean:38–43`, that file's own
   stated grade). *So the input map is posited on top of a combinator whose
   semantics theorem is itself outstanding.*
4. **Whether memory belongs in the statement.** The campaign's C1 names *"32×32
   regfile, PC, memory interface"*, `stWidth` covers **regfile + PC only**, and
   `docs/s0-r2-memory-census-0807.md:528` already anticipates
   `stWidth` becoming `1056 + 8N`. **A later memory extension changes `encD`,
   hence changes this statement.** I did not check what it would cost.
5. **The `ScenarioComplete.lean` import gap** (leg 3's earlier finding) was not
   re-checked; nothing in C4's composition touches it.

---

### Method note

`ScratchC4STMT.lean`, run through `/Users/jyh/projects/claude/saltbuild.sh`,
three passes: pass 1 with the negative controls (`EXIT=1`, both fired, plus the
two `sorry` warnings), pass 2 clean (`EXIT=0`), pass 3 with §3.2's length lemma
and §3.3's `wordOf` trap (`EXIT=0`). **The file was deleted and never
committed.** No `.lean` file in the tree was modified by this node.

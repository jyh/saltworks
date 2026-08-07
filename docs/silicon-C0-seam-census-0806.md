# C0 — THE SEAM CENSUS, SILICON HALF

### 2026-08-06 night, SILICON. Against campaign freeze `a69fee0`.
### Every identifier below was **grep-verified at the tree** and is cited
### `file:line`. Nothing here is quoted from a freeze, a bus line, or memory.

C0's law, in the freeze's own words: *"the far side must EXIST before a freeze
about it means anything."* This is the silicon half — every interface my
importer/equivalence chain **exposes**, and every interface it **consumes** from
the CPU road, with both sides named.

## The seams, both sides Lean-named

| # | seam | producer | consumer | type carried | status |
|---|---|---|---|---|---|
| **S1** | circuit → netlist | `SaltWorks.HDL.emitN` `EmitN.lean:90` | `SaltWorks.Silicon.Netlist` `BitSliced.lean:74` | `Circ → Silicon.Netlist` | ✅ |
| **S2** | netlist *meaning* | `SaltWorks.HDL.emitN_sem` `EmitN.lean:241` | `SaltWorks.Silicon.runP` `BitSliced.lean:88` | bridge theorem | ✅ |
| **S3** | flow → netlist | `Importer/import_netlist.py` (untrusted) | `SaltWorks.Silicon.Netlist` | **same type as S1** | ✅ |
| **S4** | flop boundary | importer: `_ndesign_in` `_ndesign_out` `_nstate` | *(C3/C5 — does not exist yet)* | `Nat` | ⚠️ |
| **S5** | chosen cut | importer: `_ncut` | *(C3/C5 — does not exist yet)* | `Nat` | ⚠️ |
| **S6** | cell semantics | `SaltWorks.Silicon.Cells.Sky130.*` + 44 `*_liberty` | importer `EXPAND` | `Bool` functions | ✅ |
| **S7** | one-cycle obligation | `switch_step_eq` `SwitchRefinement.lean:133` | the pattern C5 copies | — | ✅ |
| **S8** | many-cycle lift | `SaltWorks.Silicon.iterate_congr` `SwitchRefinement.lean:169` | C5 | `∀ {σ ι ω}` | ✅ |
| **S9** | ISA meaning | `SaltWorks.ISA.step` `ISA.lean:120` | C4 | `St → Instr → St` | ✅ |
| **S10** | **compile** | ⛔ **ABSENT** | **C4's headline** | — | ⛔ |

## ✅ THE LOAD-BEARING GOOD NEWS, because a census that reports only faults is the instrument this campaign warns about

**S1 ≡ S3 — the emitted netlist and the imported netlist are THE SAME LEAN
TYPE.** `emitN : Circ → Silicon.Netlist` (`EmitN.lean:90`) and the importer emits
`def fabricNL : SaltWorks.Silicon.Netlist`. So per-cone equivalence compares like
with like; **no adapter, no coercion, no third representation.** This is the
single most important fact in the census and it is already true.

**S8 is CPU-reusable AS IT STANDS, and I checked rather than assumed.**
`iterate_congr {σ ι ω : Type} (f g : σ → ι → σ × ω)` is **fully polymorphic** —
nothing about it is banyan-shaped. *"Two machines whose one-cycle behaviour
agrees on every state and input agree on every finite run."* A CPU instantiates
`σ := St`, `ι := Instr`, `ω :=` outputs and gets the whole sequential argument
for free. **The cycle-induction brick the freeze claims is real and generic.**

**S2 already reads the netlist the right way.** `emitN_sem` is stated as
`c.outs.map (fun n => (Silicon.runP ins [] (emitN c)).getD n false) = sem c ins`
— i.e. the netlist side goes through `Silicon.runP`. That matters for F2 below.

## ⛔ F1 — `compile` DOES NOT EXIST, AND C4'S HEADLINE NAMES IT

C4 is the council's headline: **`sem (emitN (compile core)) = step`.**

```
declarations whose name contains "compile", whole tree:  0
```

This is my R1 finding on the codegen freeze, one level up: **the same census, the
same cost — one grep now, a week later.** Not a kill of C4; a statement that C4
is a **goal**, not a theorem about landed objects, and the freeze should say so.

## ⛔ F2 — C4'S HEADLINE IS NOT TYPE-CORRECT AGAINST THE LANDED SIGNATURES

Read at the tree:

```
SaltWorks.HDL.sem   (c : Circ) (ins : Env) : List Bool      Sem.lean:72
SaltWorks.HDL.emitN (c : Circ) : Silicon.Netlist            EmitN.lean:90
```

`sem` consumes a **`Circ`**. `emitN` produces a **`Silicon.Netlist`**
(`= List Gate`, `BitSliced.lean:74`). ⇒ **`sem (emitN X)` cannot elaborate**;
there is no coercion between them, and none should be added.

⚠️ **RUN, NOT ARGUED — a Scratch probe with a control, per this campaign's own
standard.** Reading two signatures and concluding "that won't typecheck" is an
argument; Lean is the adjudicator:

```lean
#check fun (c : Circ) (ins : Env) => sem c ins        -- CONTROL
#check fun (c : Circ) (ins : Env) => sem (emitN c) ins -- THE PROBE
```

```
fun c ins => sem c ins : Circ → Env → List Bool          <-- control elaborates
ScratchF2.lean:8:41: error: Application type mismatch: The argument
  emitN c
has type
  Silicon.Netlist
but is expected to have type
  Circ
in the application
  sem (emitN c)
saltbuild EXIT=1
```

**The control is what makes the probe evidence**: it rules out "the file simply
does not build". F2 is a measurement.

**The intended shape is already landed and is `emitN_sem`'s** (S2): the netlist
side is read through `Silicon.runP`, not through `sem`. So C4 restated against
objects that exist:

```
(compile core).outs.map (fun n => (Silicon.runP ins [] (emitN (compile core))).getD n false)
  = ⟨the observation of SaltWorks.ISA.step⟩
```

⚠️ **This is not pedantry about notation.** `sem (emitN …)` reads as *"the
circuit's meaning equals the ISA's"*, which is C4's actual claim; the landed
composition proves something slightly different and **stronger** — that the
**netlist**, not the circuit, carries the meaning. The headline should be stated
in the form that will actually be proved, because **the form that will be proved
is the better claim** and nobody should discover the gap at C4.

## ⚠️ F3 — THREE CHAIN IDENTIFIERS ARE AMBIGUOUS AT THE TREE, AND THE FREEZE NAMES THEM BARE

| bare name | the two declarations | interchangeable? |
|---|---|---|
| `step` | `SaltWorks.ISA.step` `ISA.lean:120` · `SaltWorks.Banyan.step` `SelfRouting.lean:14` | **no** — the second is ℕ routing arithmetic |
| `run` | `SaltWorks.ISA.run` `ISA.lean:153` · `SaltWorks.HDL.run` `Sem.lean:61` | **no** — instruction list vs gate list |
| `runS` | `SaltWorks.HDL.runS` `Certs.lean:102` · `SaltWorks.Silicon.runS` `BitSliced.lean:108` | **no — different arities**: `(W, env)` vs `(W, cols, env)` |

The intended one is obvious to a reader **tonight**. The `runS` pair is the
dangerous one: same name, same first argument, **different signatures**, and the
bit-sliced certificate machinery is exactly where a CPU-scale proof will live.
⇒ **C0 should carry the fully-qualified name at every seam, and this table is
that.**

## ⚠️ F4 — S4/S5's CONSUMERS DO NOT EXIST, WHICH IS EXPECTED AND IS STILL THE POINT

The flop-treatment interface landed tonight (`cc401c9`, `f5b6e83`) exposes
`_ndesign_in`, `_ndesign_out`, `_nstate`, `_ncut` on every imported datum. **No
Lean consumer reads them yet** — C3 is unbuilt. That is not a fault; naming an
interface before its consumer exists is what C0 is *for*. Recorded so that when
C3 lands, the state-vector convention is **read off this file rather than
re-invented**: state input `ndesign_in + i` pairs with output `ndesign_out + i`,
same flop, ordered by `Q` net name.

## What the CPU road must supply, to close the silicon half

1. **`compile`** — any definition at all (F1).
2. **C4's statement in `emitN_sem`'s shape** (F2), which also settles which
   `run`/`step` (F3).
3. **The regfile cone census** — campaign **R3**, 1024 state bits. ⚠️ Note for
   the council: **R3 cannot be measured on a real artifact tonight, because no
   CPU netlist exists.** It needs a *synthetic* 32×32 regfile through the flow.
   Sequencing it after C0 is the freeze's own order.

## Method note

Every row was produced by grepping for top-level declarations and reading the
signature at the cited line — **not** by trusting the freeze's brick list. The
freeze's list was right about 6 of 7 bricks; the seventh (`compile`) is F1, and
F2 was invisible to a name-only check because **both names exist and only their
composition fails.** *An existence census is necessary and not sufficient; the
types have to be read too.*

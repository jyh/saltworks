# The densifying renumber — scope, obligations, and the two decisions

**Seat:** compiler (compiler-acct), leg 2. **Status: NOT STARTED.** This is a scoping
note so the item is startable rather than merely named. Nothing here is proved
and nothing here is in the build.

## Why it exists

`Dense.lean` found that `opt` does not preserve density: dead-net elimination
filters gates out, so survivors keep their old NAMES while their POSITIONS
shift. `EmitN.lean` answered that by CHECKING (`emitPipeline`: optimize, test
`ssa`, fall back when broken). That is sound and it is shipping.

What it does not do is let us emit the *optimized* circuit when `opt` breaks
density — and that is the case that matters, because `opt` is exactly what keeps
the emitted netlist and the synthesized netlist talking about the same circuit
(`Opt.lean`, "Yosys deletes what a design does not use").

## What it is NOT, and why the cheap routes are closed

* **Not validatable per-circuit.** The obvious move is the one this leg has used
  three times — check the property instead of proving it. It fails here: the
  property is `sem (normalize c) = sem c`, a statement over ALL input
  valuations. `Certs.eq_of_slicedOuts_eq` can discharge such a statement in one
  sliced comparison, but only over `2^W` configurations with `W ≤ 2^24`
  (measured, `Certs.lean`). **The tapeout candidate has 56 inputs.** So the
  bit-sliced escape that made T3 and T5 affordable is unavailable, and there is
  no per-instance route.
* **Not avoidable by emitting differently.** Silicon's `Netlist` carries no
  output list; net identity IS position (`BitSliced.lean:73`). Any emission that
  reorders gates must rename, and any rename must be proved.

⇒ **The general theorem is genuinely required.** That is the honest reason this
is unwritten, not effort.

## The construction

```
σ : Net → Net        inputs fix themselves; gate i's out ↦ nIn + i
normalize c = { nIn := c.nIn
                gates := c.gates.mapIdx (fun i g => ⟨c.nIn + i, g.op.rename σ⟩)
                outs  := c.outs.map σ }
```

## The obligations, in dependency order

1. **`σ` is injective on defined nets.** From `nodupB (gates.map Gate.out)` and
   `∀ g ∈ gates, nIn ≤ g.out` — both already conjuncts of `Circ.wf`.
2. **The frame lemma.** `run envN (gs.map (rename σ)) (σ n) = run envC gs n`,
   given `∀ n, envN (σ n) = envC n` on defined nets. Induction over `gs`,
   generalizing both environments — the same shape as `runP_ssaFrom`, but
   carrying injectivity, which is what makes it the expensive one: the
   `upd`/`upd_of_ne` step needs `σ m ≠ σ g.out → m ≠ g.out`, i.e. injectivity at
   every gate rather than once.
3. **`normalize` preserves meaning.** `sem (normalize c) = sem c` — but note the
   port list is renamed, so the honest statement compares `outs.map σ` against
   `outs`, and the two `sem`s agree POSITIONALLY, not net-for-net. State it as
   the output LIST equality, per the refuter pass's ruling that whole-environment
   comparison is satisfiable only for identical circuits.
4. **`normalize` establishes `ssa`.** Should be near-free by construction: gate
   `i` names `nIn + i` definitionally, and fanin-ordering is inherited from `wf`
   through `σ` being monotone on defined nets — CHECK THAT, it is the step most
   likely to be false as stated.
5. **The pipeline law.** `emitPipeline` becomes: optimize, normalize, emit —
   with the `ssa` check retained as a belt-and-braces validator that should now
   never fire. Keep the fallback; a check that never fires costs nothing and the
   day this file is edited it is the only thing standing.

## The two decisions the next seat has to make first

* **Is `σ` a function or a table?** A function (`indexOf` into the out-list) is
  O(g) per lookup, so `normalize` is O(g²) — the exact append-extension trap the
  refuter pass measured and banned. A precomputed `Array` is O(g) but puts a
  data structure inside the proof. **Recommendation: function first for the
  theorem, table second for the cost, with the theorem stated against an
  abstract `σ` + its specification so the swap is free.**
* **Where does `normalize` sit relative to `wf`?** It needs `wf` (obligation 1),
  but `opt_sem` is deliberately UNCONDITIONAL (`Opt.lean`). Adding a `wf`
  hypothesis to the pipeline would be the first conditional theorem in the leg.
  **Recommendation: keep it conditional and say so loudly — `Circ.wf` is a
  `Bool`, so every concrete circuit discharges it by `decide +kernel`, and the
  unconditional-`opt_sem` property is not lost, only not extended.**

## Estimate

~80–120 lines, one hard induction (obligation 2), and one statement that needs
care rather than cleverness (obligation 3). Bigger than an evening; not
research-tier. The risk is obligation 4 being false as written, which would cost
a redesign of `σ` rather than of the theorem.

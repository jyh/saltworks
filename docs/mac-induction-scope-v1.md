# THE BIT-SERIAL MAC INDUCTION — SCOPE (math, ruling #7 probe, 2026-08-09)

Probe as dispatched: *"scope the MAC induction (statement form, fuel/cycle
indexing, the sign-cycle subtraction); confirm the delivery theorem
instantiates per-permutation as assumed; signed-order discipline applied."*

This is a **scoping** document. It states the shapes and the obligations; it
proves nothing and claims nothing landed.

---

## A. THE DELIVERY THEOREM — **CONFIRMED per-permutation**, with three
##    instantiation obligations that are NOT free

`bnC_payload_delivered` (`SaltWorks/HDL/PayloadL4.lean:149`) takes the routing
map as a **free parameter**:

```
(d : Fin 8 → Nat) (hd : ∀ i, d i < 8) (hdi : Function.Injective d)
```

An injective `d` into `< 8` is a permutation of the eight wires, so **each
round's matching instantiates the theorem directly.** The design package's
"per-permutation instance" assumption is correct.

**A1 — PADDING.** The demo is `k = 4` cells on an **8**-wire fabric. A round's
matching (e.g. `(0 1)(2 3)`) is a permutation of *four* things; `hdi` demands a
bijection on **all eight wires**. ⇒ *The schedule must extend every matching to
a total permutation of `Fin 8`* — identity on the unused wires is the obvious
choice and it is an obligation on the layer-compiler's emitter, not a given.

**A2 — THE FRAMING HYPOTHESES ARE PER-ROUND WORK.** `hrst0`, `hrst`, `hrstT`
(reset discipline), `hL` (equal payload lengths), `hin` (every input column IS a
well-formed `cFrame`) must be re-established **each round** by the phase
sequencer. Equal lengths are free here (2 dims × 8 bits, uniform); the reset
discipline is EXEC's obligation and should be named in its row.

**A3 — ROW 1 OF §4's TABLE CONFLATES TWO CLAIMS.** As written it reads *"each
round delivers exactly the multiset `{h_u : u ∈ N(v)}` to cell `v`"*. That is:

```
(i)  the fabric delivers per permutation           <- LANDED (this theorem)
(ii) the 3 matchings UNION to the edge set          <- NOT STATED ANYWHERE
```

(ii) is a finite combinatorial fact about the compiled schedule — `decide`-able
for a 4-node graph — but the multiset claim is **false without it**, and no
fabric theorem can supply it. It belongs in the layer-compiler's rows.

---

## B. THE MAC INDUCTION — STATEMENT FORM

### B1. Genre: cycle-indexed invariant over `runTrace`, lifted by `runTrace_append`

`Seq.runTrace` (`Seq.lean:78`) folds a trace of input words into
`(outputs, final state)`. `runTrace_append` (`Seq.lean:89`) is the corpus's own
named lifting lemma — its docstring calls it *"what turns per-cycle obligations
into a statement about a whole frame"*. **That is exactly this induction's
route**; no new machinery is needed and no fuel parameter should be introduced
(the trace length IS the cycle index).

### B2. State the ACCUMULATOR INVARIANT, not the final output

The inductive statement must expose the accumulator after `t` cycles, or the
induction carries no hypothesis:

```
acc_after t  =  b  +  Σ_{j ∈ Finset.range t}  W * x_j * 2^j        (t ≤ n-1)
```

with `acc_after t` read out of the state component of
`runTrace cell st (take t stream)`. The final-output theorem is then a corollary
at `t = n`, not the thing proved by induction.

### B3. **THE SIGN CYCLE IS A SEPARATE LEMMA — do not fold it into the recursion**

For a two's-complement multiplier `x = -x_{n-1}·2^{n-1} + Σ_{j<n-1} x_j·2^j`,
the final partial product is **subtracted**. Folding that into the recursive step
makes the induction non-uniform (the step differs at one index) and costs a case
split inside every subsequent lemma. Two statements instead:

```
mac_partial   : ∀ t ≤ n-1, acc_after t = b + Σ_{j ∈ range t} W * x_j * 2^j
mac_sign_cycle:            acc_after n = acc_after (n-1) - W * x_{n-1} * 2^(n-1)
mac_correct   : (corollary) acc_after n = b + W * x.toInt
```

One uniform induction, one composition step. **This is the whole reason the
genre is "one new proof" rather than three.**

### B4. Work in `ℤ` through `BitVec.toInt` — the SAME interpretation as the
###     activation row

The corpus already fixes the signed reading: `wle`/`wlt` are defined through
`BitVec.toInt` (`Stack/Spec.lean:30`), and `wordSignedOrder`
(`Stack/Perm.lean:321`) is the `LinearOrder Word` at that order, **passed
explicitly per the `runNetW` pattern and never promoted to an `instance`**
(`Perm.lean:309`). The MAC theorem must be stated over the same `toInt` reading,
or **rows 2 and 3 will not compose** — the accumulator would carry one notion of
"value" and ReLU another.

### B5. ⛔ THE OVERFLOW OBLIGATION — the finding of this probe

Fixed-width serial accumulation can **wrap**. Two possible statements:

```
(a) modulo 2^w   — always true, and USELESS HERE: a wrapped accumulator has a
                   FLIPPED SIGN BIT, so the activation clips the wrong side and
                   the layer equation is FALSE exactly at the overflowing inputs.
(b) no-overflow hypothesis — honest, and the statement then needs the bound
                   EXHIBITED, per the F1 discipline (a hypothesis nobody can
                   satisfy proves a vacuous theorem).
```

⇒ **Recommend (b)**, with the bound computed from the demo's own ranges — 8-bit
features, 4 nodes, max degree 3, one `W_self` + up to 3 `W_msg` terms + `b` —
and a **witness by `decide`**: a concrete GNN input where the bound holds, plus
its exact accumulator value.

### B6. **THE COMPOSITION POINT, and the reason B5 is not a detail**

> **The MAC's no-overflow hypothesis is what makes the activation's signed `max`
> meaningful.** Rows 2 and 3 of §4 do not compose without it.

This is the same shape as the 10:31 activation finding one level down: there, an
unspecified *order* silently made ReLU the identity; here, an unstated *range*
condition silently makes the sign bit — and therefore ReLU's decision — wrong.
Both are cases of **a certified component whose numeric precondition lives
outside the certificate.**

---

## C. WHAT THIS PROBE DOES NOT CLAIM

No Lean written, nothing built, nothing landed. Item A is read off a landed
theorem's binder list; item B is a proposed shape. **The bound in B5 is not
computed here** — it is named as owed, with its inputs identified.

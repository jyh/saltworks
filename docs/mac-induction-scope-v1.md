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

---

## D. AMENDED BY COUNCIL RULING #8 (2026-08-09 11:36) — THE WIDTH IS CLOSED

**Ruled:** values are **int8 fixpoint on the landed 32-bit datapath**,
sign-extended at ingress; the activation compares at 32 with `wordSignedOrder`
passed explicitly; **no 8-bit order variants, ever, for the PoC**; no
requantization organ in the minimal demo.

**Consequences for this document, stated so a reader does not act on the
superseded text:**

**D1 — §B5's fork is RESOLVED to (b), and the hypothesis is now DISCHARGEABLE
rather than assumed.** With int8 operands on a 32-bit accumulator:

```
int8 signed                   |W|, |h| ≤ 128
one term = 2-dim dot product  |W·h| ≤ 2 · 128 · 128        =    32,768
W_self + 3·W_msg (deg ≤ 3)    4 terms                      =   131,072
+ bias b                                                   ≤   131,200
                                        2^31 = 2,147,483,648
                              ⇒ margin ≈ 16,000×, holds by `decide`
```
The no-overflow condition becomes a **bound lemma with an exhibited witness**,
which is what §B6 required for rows 2 and 3 to compose.

**D2 — §A's narrowing/fourth-row finding does NOT apply to the minimal demo.**
There is no width transition under the ruling, so no `narrow : Word → BitVec 8`
row is owed here. *It returns for the 8-bit-native v2/production variant, where
the fixed-shift bound is `s ≥ 11` (s = 10 overflows by 1.125 units at the
maximal activation).* Kept because that variant is a named reference row.

**D3 — NEW ROW OWED: INGRESS SIGN-EXTENSION.** "int8 on a 32-bit datapath,
sign-extended at ingress" is a semantic operation with a correctness condition:

```
(w : BitVec 8).signExtend 32 |>.toInt  =  w.toInt
```
⚠️ **`zeroExtend` would typecheck, cost the same gates, and silently map every
negative weight to a large positive one** — the third appearance today of *a
certified pipeline whose numeric meaning turns on an unstated convention*
(after the activation's order and the accumulator's range). It is one lemma and
it should be named rather than assumed, precisely because the wrong call is
invisible at every other layer.

## E. AMENDED AGAIN (11:37) — BIAS STREAMS, SO THE CYCLE INDEX GAINS AN OFFSET

**Ruled:** the bias is **not a parallel preload**; it *streams as the first
addend*, one cycle, zero gates.

⚠️ **§B2's invariant assumed a PRELOAD and is wrong as written under this
mechanism.** With `b` arriving as the first addend the accumulator starts at `0`,
not at `b`, and every subsequent index shifts by one:

```
WRONG (preload form, §B2)   acc_after t       = b + Σ_{j ∈ range t} W·x_j·2^j
RIGHT (streamed form)       acc_after 0       = 0
                            acc_after 1       = b
                            acc_after (1 + t) = b + Σ_{j ∈ range t} W·x_j·2^j
                            acc_after (1 + n) = ... - W·x_{n-1}·2^(n-1)   (sign cycle)
```

**Three consequences, all of them statement-level:**

1. **The induction is over `t` with the base case at cycle 1, not cycle 0.** The
   `+1` must live in the statement, not be quietly absorbed by `take t` — the
   trace length is the cycle index (§B1), so an off-by-one here is an off-by-one
   in the theorem, not in a comment.
2. **The total is `n + 1` cycles per MAC, not `n`.** Anything downstream that
   counts bit-times (the §4 "few hundred bit-times per layer pass") is computed
   from the *streamed* count.
3. **The sign cycle sits at index `1 + n`**, so `mac_sign_cycle` (§B3) composes
   onto `acc_after (1 + (n-1))`, not `acc_after (n-1)`.

📌 *This is the maestro's own 11:37 law arriving at the statement layer: **every
width or value transition gets written down.** A preload and a streamed first
addend compute the same number and index it differently — **and the index is what
the induction is about.***

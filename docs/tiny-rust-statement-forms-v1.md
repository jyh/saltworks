# TINY-RUST — THE STATEMENT FORMS, a PROPOSAL (math, 8/8 night)
### Status: PROPOSAL FOR THE HELM. Written under the 20:00 ruling
### ("DRAFT IT"), which inverted the load: math's abundant account
### spends on generation, the hub's budgeted 40 spends on RULING.
### SCOPE, exactly as bounded: the typing-judgment shape · the T1
### substitution · the completeness row's form · F7's three exits
### COSTED WITH NO PICK.
### ⛔ NOT IN SCOPE, and deliberately absent: design decisions,
### concrete syntax, and the FEEL of the morning presentation.
### Those are the helm's, and the last is the part only the helm
### can write.
### SOURCE: `docs/lang-design-v1.md` §1/§2 + math's slate F1–F9
### (bus 19:12, 19:13) and T1–T4 (bus 19:20).

---

## 0. THE ONE-PARAGRAPH SUMMARY, FOR A TIRED READER

The v1 correctness theorem as drafted is **satisfied by a compiler that rejects every
program**. Everything below exists to fix that, and the Captain's type-system ask turns out to
be the instrument that does it: **a typing judgment is a `wellFormed` predicate that cannot be
circular**, because it never mentions the compiler. Adopt the judgment as the hypothesis, add
one completeness row, and the vacuity closes. The remaining open decision is **F7 — Rust's
overflow semantics are not the machine's** — and that one is costed here, not picked.

---

## 1. THE TYPING JUDGMENT — SHAPE

Two judgments, expression and statement, with the statement form **threading the context**:

```
Γ ⊢ e : τ           expressions
Γ ⊢ s ⊣ Γ'          statements: s is well-typed in Γ and leaves Γ'
```

**Why the statement judgment must thread (`⊣ Γ'`) rather than merely hold (`Γ ⊢ s ok`):**
`let` extends the context and a block's end contracts it. Threading is what makes *"how many
bindings are live at once"* a **computable function of the derivation** rather than a separate
analysis — and that number is the register-pool bound. A non-threading judgment forces the pool
analysis to be a second pass, which is precisely where an unwritten lemma (F4's c2) would move
back in.

**Context representation.** Proposed: an association list `Γ : List (Name × Ty)` with shadowing
by most-recent lookup. *Rationale: decidable lookup, structural recursion, and `Γ.length` is the
live-binding count directly.* ⚠️ *A `Finset`/`Std.HashMap` representation buys nothing in v1 and
costs decidability plumbing.*

**v1's type universe is `{ i32 }`** per the block. See §5(T2) — that is not a free choice, it has
a consequence that must be stated in the same breath.

---

## 2. T1 — THE JUDGMENT **IS** `wellFormed` (this is the load-bearing proposal)

**Replace the ad-hoc `wellFormed p` with the judgment.** It satisfies every property F4 demanded,
by construction rather than by assertion:

| F4 demanded | the judgment gives it |
|---|---|
| independent of `compile` | it is a syntactic relation; `compile` does not occur in it |
| decidable | that is what a type checker *is* |
| carries types (F8) | `τ` is in the judgment |
| carries scope | the threading of §1 |

⇒ **PROPOSED TOP-LEVEL FORM:**

```lean
theorem compile_correct
    {p : Prog} {Γ : Ctx} {code : List Instr}
    (hty   : Γ ⊢ p ⊣ Γ')                 -- T1: the judgment as the well-formedness
    (hpool : liveMax p ≤ poolSize)        -- the resource bound, SEPARATE — see below
    (hc    : compile p = some code) :
    ∀ s s', bigStep p s s' →
      machRun code (encode s) = encode s'                       -- F5: functional, not relational
      ∧ ∀ r, r ∉ allocated p → (machRun code (encode s)).reg r = (encode s).reg r   -- F3
```

**⚖️ ONE SUB-DECISION I AM FLAGGING RATHER THAN TAKING: should `hpool` live INSIDE the judgment?**
```
SEPARATE (as drafted)   the judgment stays a pure TYPE system; the pool bound is a
                        RESOURCE bound. Keeps the rejection path characterisable as
                        exactly two causes (ill-typed | too many live bindings), which
                        is what makes §3's completeness row honest.
INSIDE                  one hypothesis instead of two, and "well-typed" then means
                        "compilable". ⚠️ But it welds a MACHINE parameter (poolSize)
                        into the SOURCE language's type system, so the same program is
                        ill-typed on a smaller core. That is a real cost and it is the
                        helm's call, not mine.
```

---

## 3. THE COMPLETENESS ROW (F1) — THE ROW THAT KILLS THE VACUITY

**Correctness alone is satisfied by `compile := fun _ => none`.** The pairing row:

```lean
theorem compile_total
    {p : Prog} {Γ Γ' : Ctx}
    (hty : Γ ⊢ p ⊣ Γ') (hpool : liveMax p ≤ poolSize) :
    ∃ code, compile p = some code
```

***"Well-typed, pool-fitting programs compile."*** That sentence is the entire reason a type
system earns its place in a *compiler* correctness statement rather than only in the language.

**AND THE TWO DEGENERATE CONTROLS, pre-registered here so they are written before the draft
hardens (F6, T2):**
```lean
example : ∃ p Γ Γ' s s', (Γ ⊢ p ⊣ Γ') ∧ bigStep p s s'     -- the relation is INHABITED
example : ¬ (∅ ⊢ ⟦ x = y + 1 ⟧ ⊣ _)                        -- the judgment REJECTS something
```
⚠️ **The second is the one v1 can barely satisfy, and §5 says why in plain terms.**

---

## 4. THE SUPPORTING ROWS (F2, F3, F5)

```lean
theorem encode_injective : Function.Injective encode            -- F2
```
**F2 is not bookkeeping.** Without it a collapsing `encode` makes the conclusion satisfiable by a
machine that does nothing. *(Precedent, same shape, landed today: `bnC_payload_delivered`'s
`hdi : Function.Injective d` — the theorem is FALSE at a two-line witness without it.)*

**F3** rides in the conclusion above as the frame condition. *(Precedent: ③'s ∀-w clause, which
was flagged as the risk and proved to be the asset that made the induction trivial.)*

**F5** — `machRun` proposed as a **function**, conclusion by `=`. The core is deterministic
hardware; a reachability relation would assert only that *some* run lands right. ⚠️ If `machRun`
must stay relational for framework reasons, then **machine determinism becomes its own row** and
the interface law applies (a later re-shape is a breaking change).

---

## 5. THE TWO THINGS THAT MUST BE SAID OUT LOUD

**(T2) With one type, the judgment cannot fail on a type mismatch.** The only thing it can reject
is an unbound variable. ⇒ ***In v1 the "type system" is, honestly, a SCOPE CHECKER in judgment
clothing.*** That is the right thing to build early and the right shape to build it in — **but the
block must say it, or the phrase travels further than the artifact.** *(The fleet corrected that
exact defect three times on 8/8.)*

**(T3) The promoted unsigned-`<` lowering has no trigger in an `i32`-only v1.** `<` on `i32` *is*
`SLT`. Either `u32` enters v1's type universe (and F8's type-direction becomes real work), or the
lowering is **dead in v1** and should be marked *"awaiting the second type"*. **Silence ships a
proved lemma nothing calls, in a campaign whose story counts theorems.**

---

## 6. ⛔ F7 — THE THREE EXITS, COSTED. **NO PICK. THIS IS THE HELM'S OR THE CAPTAIN'S.**

**The fact:** Rust **panics** on arithmetic overflow in debug and **wraps** in release; wrapping is
opt-in and explicit (`wrapping_add`). **The 5-op machine always wraps.** If `bigStep` inherits
Rust's default while `machRun` wraps, `compile_correct` is **FALSE at the first overflowing add** —
and false in the source-is-right direction, which is the one nobody tests.

| exit | what it says | proof cost | statement cost | what it forecloses |
|---|---|---|---|---|
| **A — source WRAPS by definition** | Tiny-Rust *is* release-semantics Rust | **lowest.** `bigStep`'s add is `BitVec` add; the machine matches definitionally | none — no extra hypothesis anywhere | says Tiny-Rust ≠ debug Rust. A user who reasons from `cargo run` gets a different answer |
| **B — overflow excluded by well-formedness** | only provably-non-overflowing programs are legal | **highest.** `wellFormed` must carry a RANGE ANALYSIS, and its soundness is a real theorem | one more hypothesis, and it is the heavy one | ⚠️ **this is a SECOND c2** (F4's shape one level up): a "side condition" that is an unwritten lemma. It also rejects programs Rust accepts |
| **C — quantify over non-panicking runs** | the theorem speaks only where the source does not panic | **low.** `bigStep` gets a panic outcome; the theorem takes the non-panic case | one antecedent, and it is honest and visible | nothing — but the theorem is silent on exactly the programs a user most wants checked |

📌 **THE ONLY THING I WILL ASSERT HERE: silence picks (B) by accident**, because an unexamined
`wellFormed` is where a range analysis hides. **(A) and (C) are both defensible and are two
different products; (B) is the one that must be chosen deliberately if at all.**

⚠️ **AND THE TYPE SYSTEM DOES NOT DECIDE THIS (T4).** `i32 + i32 : i32` type-checks and still
overflows. *A type system is exactly the kind of addition that feels like it settled the
arithmetic questions; this one does not touch them.*

---

## 7. WHAT I DID NOT DECIDE, LISTED SO THE OMISSIONS ARE VISIBLE

- **F7's exit** — §6, costed, unpicked.
- **`hpool` inside vs beside the judgment** — §2, both costed.
- **Whether `u32` enters v1** — §5(T3), stated as a fork.
- **Concrete syntax, keywords, the feel** — the helm's, entirely absent here.
- **Whether the offset/BEQ lemma shape belongs in this file** — it is §3 of the design block
  (N3), and it is compiler's slate, not mine.

---

## 8. REFUTATION INVITED — the same courtesy the block extended to me

**COMPILER:** does `machRun` exist in the functional form §4 proposes, or does the core semantics
force the relational one? **EVIDENCE:** does §0's summary outrun §2's statement? **SILICON:**
nothing hardware-side here. **HELM:** §2's sub-decision and §6's exit are yours.

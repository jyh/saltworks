# TINY-RUST — the language, presented (for the Captain's morning)
### Maestro-drafted 8/8 night, on the v1.1 block (math's six findings
### already folded — what you see is the post-refutation design).
### The campaign: A VERIFIED COMPILER FROM TINY-RUST TO 5-OP.
### v1.2: math's F7-F9 folded — three decisions the NAME forces,
### each chosen by name below, none by silence.

## 1. THE FEEL — three programs you can read cold

**Compare-exchange (the ISA's own idiom).** No SUB and no temp
needed — the XOR-swap is native to Slice A:

```rust
fn main() {
    let mut a = 7;
    let mut b = 3;
    if b < a {          // one SLT + one BEQ
        a = a ^ b;      // the classic three-XOR swap:
        b = a ^ b;      // after these, a and b have traded —
        a = a ^ b;      // no scratch register, pure Slice-A ops
    }
}                       // post: a ≤ b
```

**A loop, with a typed condition.** Subtraction-by-constant is sugar
for ADDI with a negative immediate — exactly what the hardware does;
the `0 < n` is a `bool`, as Rust demands, and SLT hands us its 0/1
representation for free:

```rust
fn main() {
    let mut n = 10;
    let mut sum = 0;
    while 0 < n {
        sum = sum + n;
        n = n - 1;      // sugar: n + (-1), one ADDI
    }
}                       // post: sum = 55
```

**A helper function** — tail-expression return, Rust-style, compiled
by verified inlining:

```rust
fn max(a: i32, b: i32) -> i32 {
    let mut m = a;
    if m < b { m = b; }
    m                       // tail expression = the return value
}

fn main() {
    let mut hi = max(7, 3);
    hi = max(hi, 12);       // hi = 12; two call sites, both inlined,
}                           // one theorem covering the transformation
```

**The sort — the story's centerpiece.** v1 has registers, not arrays,
so we sort four named values through Batcher's 4-input network — the
SAME comparator specification the silicon sorter is proved against
(compiler is unifying the two specs tonight). `cex!` is frontend
sugar that expands to the if-block above:

```rust
fn main() {
    let mut x0 = 9;
    let mut x1 = 3;
    let mut x2 = 7;
    let mut x3 = 1;
    cex!(x0, x1);  cex!(x2, x3);   // Batcher: two column-1 exchanges
    cex!(x0, x2);  cex!(x1, x3);   // column 2
    cex!(x1, x2);                  // the merge exchange
}   // post: x0 ≤ x1 ≤ x2 ≤ x3 — the same network as the tile
```

Reserved for the executive (v2): `yield;` — a first-class statement
compiled to the JAL convention (the harvest from the ML-effects
road: the executive as the thing yields return to).

**Three decisions the name "Rust" forces, chosen out loud (v1):**
1. **Arithmetic WRAPS.** Tiny-Rust is release-semantics Rust: `+` is
   two's-complement wrapping, exactly the machine's — no panics, no
   hidden range analysis. (The alternatives either hide a lemma in
   wellFormed or defer a panic case; we take the honest cheap one.)
2. **One type in v1: `i32`, signed.** So `<` IS the machine's SLT,
   natively — no lowering needed at the source level. `u32` and the
   unsigned-compare lowering stay in the backend for the comparator
   spec (which compares unsigned bit-strings) and reach the SOURCE
   in v2, typed.
3. **Ownership is VACUOUS in v1 and says so**: registers only, no
   heap, no references — nothing to own, nothing to borrow. The
   borrow-checker you may be imagining does not exist yet; it
   arrives with Slice B's memory, as a theorem (§6).

## 2. ABSTRACT SYNTAX (what the theorem is about)

```
τ ::= i32 | bool                        (Ty — v2 reserves u32, &τ, &mut τ)

e ::= x | n | true | false              (Expr)
    | e + e | e ^ e | e < e
    | f(e₁, …, eₙ)                      — function call

s ::= skip                              (Stmt)
    | let mut x : τ = e                 — binds x for the enclosing block;
    | x = e                               scope end = liveness end = the
    | s ; s                               judgment's register budget
    | if e { s } else { s }
    | while e { s }

d ::= fn f(x₁:τ₁, …, xₙ:τₙ) -> τ { s; e }   (Decl — the tail expression
                                             is the return value, as Rust)
p ::= d* fn main() { s }                (Prog)
```

**Multiple functions, no JAL — the staged trick:** Slice A has no
jump-and-link and no stack, so v1 functions are compiled by VERIFIED
INLINING — parameters become let-bindings, the call site becomes the
body, and the theorem "inlining preserves the big-step semantics" is
its own kernel node. The judgment demands the call graph be a DAG
(decidable — recursion is REJECTED in v1, and that rejection is a
pre-registered control alongside the type ones). When Slice B lands
JAL/JALR and memory, calls become real frames and recursion arrives
— the SOURCE programs don't change, only the compiler's strategy
does. One honest boundary: a two-output helper like `cex` cannot be
a function yet (no tuples, no `&mut` until v2) — `cex!` stays sugar,
and becomes a real `fn(&mut i32, &mut i32)` the day references land.
The parser (Rust-familiar surface, `let mut`, sugar like `n - 1` and
`cex!`) is a TRUSTED frontend; every theorem lives from this AST down
to machine code — CompCert's own posture, stated plainly.

## 3. THE TYPE SYSTEM (the Captain's ask — judgment-structured from
## birth)

Two types in v1, and the second is the machine's own gift:

```
τ ::= i32 | bool          (v2 reserves: u32, &τ, &mut τ)

                                       ─────────────────── (var)
─────────────── (lit, n in range)      Γ, x:τ, Δ ⊢ x : τ
Γ ⊢ n : i32

Γ ⊢ e₁ : i32   Γ ⊢ e₂ : i32           Γ ⊢ e₁ : i32   Γ ⊢ e₂ : i32
─────────────────────────── (+,^)     ─────────────────────────── (<)
Γ ⊢ e₁ + e₂ : i32                     Γ ⊢ e₁ < e₂ : bool

Γ ⊢ x : τ    Γ ⊢ e : τ                Γ ⊢ e : bool   Γ ⊢ s ok
────────────────────── (assign)       ─────────────────────── (while)
Γ ⊢ x = e ok                          Γ ⊢ while e { s } ok

Γ ⊢ e : τ    Γ, x:τ ⊢ ss ok
──────────────────────────── (let — binds over its continuation;
Γ ⊢ (let mut x:τ = e); ss ok         the block's end ends the scope)
```

Statements are typed as SEQUENCES with a single context on the left
— no output contexts, no nonstandard turnstiles: `let` extends Γ for
exactly the rest of its block, which is also where the liveness
budget reads straight off the syntax. The var rule reads its binding
from the context's shape (the Captain's house notation — Γ, x:τ, Δ —
no dictionary lookup), and ASSIGN IS SYMMETRIC: both sides typed as
expressions through the same rules. The lhs is a variable in v1 only
because the grammar says so — typing it through (var) is the form
that generalizes to the v2 PLACE judgment (`*p = e`) with the rule's
shape unchanged. The symmetry is the lvalue story, arriving early.

**Function signatures live in Δ, not in τ** (the Captain's
double-check, answered): calls are by name only — no first-class
functions — so the judgment carries a signature context
Δ(f) = (τ₁,…,τₙ) → τ used solely by the call rule

```
Δ(f) = (τ₁,…,τₙ) → τ    Γ ⊢ eᵢ : τᵢ  (each i)
─────────────────────────────────────────── (call)
Γ ⊢ f(e₁,…,eₙ) : τ
```

and the arrow NEVER enters τ: no variable holds a function, no
expression has arrow type, which is exactly what makes inlining
COMPLETE (every call target is statically known) and the DAG check
well-defined. If first-class functions ever arrive, the arrow moves
from Δ into τ — and the hardware for it is already named: JALR is
the indirect-call instruction, waiting in Slice B. Named, not
promised.

Rust-faithful, so: conditions are `bool`, not truthy integers — and
here the machine cooperates beautifully, because SLT already
produces exactly 0 or 1. The representation invariant (bool values
are 0/1 in their register) is the type system's one runtime theorem:
**preservation** — every big-step preserves state typing — is what
makes BEQ-on-a-bool sound, and it is a real, small kernel row, not
ceremony. No implicit coercions (Rust has none; neither do we).

THE JUDGMENT **IS** THE HYPOTHESIS (math's T1 — the ask pays for
itself): there is no separate `wellFormed` — `Γ ⊢ p ok` carries
typing, scope, the live-binding budget (≤ pool; block scoping makes
liveness syntactic), and literal ranges, as ONE syntactic decidable
relation that never mentions the compiler. F4's circularity is
discharged BY CONSTRUCTION, and the completeness row takes its
natural form: **well-typed programs compile** — the whole point of a
type system, and the row that kills the reject-everything vacuity.
TWO controls pre-registered at birth (T2): a program the judgment
ACCEPTS and one it REJECTS (`while 1 { … }` — 1 is i32, not bool),
both by decide — a judgment that can refuse nothing proves nothing,
and bool is what gives v1 its teeth. What the types did NOT fix
(T4): overflow — `i32 + i32 : i32` checks and still wraps; that
choice was made in the SEMANTICS, by name (wrapping, release-Rust).
In v2
the same judgment grows u32 (type-directed comparison lands F8's
lowering at the source) and references — where the borrow rules
enter AS TYPING RULES, which is how ownership becomes a theorem.

## 4. OPERATIONAL SEMANTICS (big-step, three rules shown)

```
────────────────── skip        σ ⊢ e ⇓ v
σ ⊢ skip ⇓ σ                  ─────────────────── assign
                               σ ⊢ (x = e) ⇓ σ[x↦v]

σ ⊢ e ⇓ v   v ≠ 0   σ ⊢ s ⇓ σ'   σ' ⊢ while e {s} ⇓ σ''
──────────────────────────────────────────────────────── while-true
σ ⊢ while e {s} ⇓ σ''
```
A relation, not a function — divergence is representable and v1's
theorem honestly quantifies over terminating runs. Nonemptiness of
the relation itself is a pre-registered kernel control (a concrete
program shown to step, by decide), so no row can go vacuously green.

## 5. THE THEOREM PAIR (v1.1 — the post-refutation form)

**Row A (correctness).** For well-formed p, if `compile p = some
code`, then for every source run σ ⇓ σ′: `machRun code (encode σ) =
encode σ′`, AND every register outside p's pool is untouched — a
function equality against the certified core semantics (the machine
is deterministic; a mere reachability claim would under-specify it),
with `encode` injective as a stated hypothesis.

**Row B (completeness).** Every well-formed program compiles:
`∀ p, wellFormed p → ∃ code, compile p = some code` — without this
row, Row A is satisfied by a compiler that rejects everything.

Together: *the program does what the source says* — composable with
*the core does what the ISA says* (landed) and, later, *the
executive schedules what the core runs* (Slice B).

## 6. THE v2 HORIZON (named, not promised)

Memory and arrays arrive with Slice B's LW/SW — and with them,
tiny-Rust's OWNERSHIP rules stop being syntax: the borrow discipline
becomes the proved isolation frame the verified executive consumes.
"A tiny Rust whose ownership is a theorem" is the arc's star
sentence, and it is two campaigns away, not one.

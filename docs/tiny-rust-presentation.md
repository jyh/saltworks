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
e ::= x | n | e + e | e ^ e | e < e            (Expr)
s ::= skip | x = e | s; s                      (Stmt)
    | if e { s } else { s }
    | while e { s }
p ::= fn main() { s }                          (Prog)
```
The parser (Rust-familiar surface, `let mut`, sugar like `n - 1` and
`cex!`) is a TRUSTED frontend; every theorem lives from this AST down
to machine code — CompCert's own posture, stated plainly.

## 3. THE TYPE SYSTEM (the Captain's ask — judgment-structured from
## birth)

Two types in v1, and the second is the machine's own gift:

```
τ ::= i32 | bool          (v2 reserves: u32, &τ, &mut τ)

Γ ⊢ n : i32   (literal in range)      Γ ⊢ x : Γ(x)
Γ ⊢ e₁ : i32   Γ ⊢ e₂ : i32           Γ ⊢ e₁ : i32   Γ ⊢ e₂ : i32
─────────────────────────── (+,^)     ─────────────────────────── (<)
Γ ⊢ e₁ + e₂ : i32                     Γ ⊢ e₁ < e₂ : bool

Γ(x) = τ   Γ ⊢ e : τ                  Γ ⊢ e : bool   Γ ⊢ s ⊣ Γ
──────────────────── (assign)         ──────────────────────── (while)
Γ ⊢ x = e ⊣ Γ                         Γ ⊢ while e { s } ⊣ Γ
```

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

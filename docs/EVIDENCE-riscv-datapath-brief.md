# RISC-V DATAPATH — the week-2 scoping brief (SLICE A)
### 2026-08-06, EVIDENCE seat. Distilled from
### `salt/docs/exploration/core-scope-scout-dossier-0805.md` (the
### BitVec/circuit-reasoning dossier, `[V-ME]`-tagged measurements) plus
### `saltworks/docs/silicon-design-v1.md` D6 and Council I §10.
### STATUS: a brief, not a freeze. The Silicon seat owns D6 and rules it.

---

## 0. A NAMING NOTE, FIRST — read this before the rest

**"Slice-A" appears nowhere in the core-scope dossier.** I searched every
exploration doc: the string is absent. So this brief states what it takes the
term to mean and invites a one-line correction:

> **SLICE A** = the D6 object in `silicon-design-v1.md` — *"ALU + regfile +
> 3–5 instr single-cycle, hand-written Lean spec; `bv_decide` only as dev
> accelerant"* — scoped to the **smallest instruction set that still closes
> the tower** (Council I's week-2 stretch: mini-language → RV32I codegen with
> a simulation proof).

If the Captain meant something else by Slice-A, everything below is still the
measured scoping envelope; only the instruction list moves.

**Two naming rules that are already ruled and are not negotiable:**

1. **Never say "core".** Say *datapath*, or *RV32I subset*.
   (`silicon-design-v1.md` D6.)
2. **Name the instructions, every time.** Campaign fence §6: *"Verified
   subsets are subsets: a RISC-V slice is not a CPU, and we will say which
   instructions."*

---

## 1. THE CENTRAL SCOPING FACT — and the architecture it forces

A 32-bit datapath cannot be certified by exhaustive checking. The dossier
measured the ceiling on this machine, on salt's exact toolchain `[V-ME]`:

| Goal | Tactic | Axioms | Wall |
|---|---|---|---|
| `∀ x y : BitVec 8` (2¹⁶ cases) | `decide +kernel` | clean | **12 s** |
| `∀ x y : BitVec 10` (2²⁰) | `decide +kernel` | clean | **8 m 19 s** |
| `∀ x y : BitVec 12` (2²⁴) | `decide +kernel` | — | **killed at >10 min** |
| 65,536-case BitVec-8 identity | `decide` | `[propext, Quot.sound]` | 35 s |
| 2,048-case `Vector`-backed regfile read-over-write | `decide` | `[propext, Quot.sound]` | **2.4 s** |

> *"Kernel `decide` is comfortable to ~10⁵ BitVec operations (seconds),
> painful at ~10⁶ (minutes), and dead by ~10⁷. Exhaustive kernel checking
> covers a **16-bit input space** and no more."*

One 32-bit ALU operation has a 2⁶⁴ input space. It is 2⁴⁸ times past the
wall. **No amount of patience closes this gap**, and `bv_decide` — which
could close some of it — is banned from shipped proofs because it emits
`<thm>._native.bv_decide.ax_*` (JYH ruling, 8/6).

### The architecture this forces — and it is a better story than brute force

> **Prove width-generically. Certify exhaustively at a small width. Ship at
> 32.**

- Define every datapath component **polymorphic in width `w`**:
  `alu : Op → BitVec w → BitVec w → BitVec w`.
- Prove `alu_correct : ∀ w, ∀ op a b, sem (aluCirc w) [a,b] = alu op a b`
  **structurally** — by induction and the `Init/Data/BitVec/Bitblast.lean`
  family (`adc_spec`, `add_eq_adc`, `getLsbD_add`, `msb_add`,
  `ult_eq_not_carry`, `sle_eq_carry`, `shiftLeft_eq_shiftLeftRec`, …
  ~165 theorems, all in core, all axiom-clean).
- Instantiate the same theorem at `w = 32` for the shipped design: free.
- Instantiate at `w = 8` and **exhaustively certify all 2¹⁶ input pairs by
  `decide +kernel` in ~12 s** — the "test that is proved" (leg 2's T3), now
  a *witness that the structural proof and the executable model agree*, not
  the proof itself.

This is exactly the discipline Amendment 1 already praised in the equivalence
route: *we could have used the fast bitblaster and didn't, because it
introduces an axiom.* Say the same sentence here: **we could have proved the
32-bit ALU by SAT and didn't; we proved it structurally, and the exhaustive
run at width 8 is the receipt.**

**Do not attempt a multiplier.** Measured `[V-ME]`: `bv_decide` on 12-bit
multiplier commutativity **times out at a 120 s budget** (138 s wall), and
*"raising the timeout will not rescue 32/64-bit"* — the cliff is CaDiCaL on
multiplier circuits and it is exponential. The M extension is out of Slice A,
out of Slice B, and out of the fortnight. (Council I's systolic stretch wants
a multiplier proved **structurally, by induction, not enumeration** — that is
a different, deliberate stone, and `mulRec`/`mul_eq_mulRec`/`blastMul` in core
are its handholds.)

---

## 2. SLICE A — the recommended object

### 2.1 State

```lean
structure St where
  regs : Vector (BitVec 32) 32     -- x0 is present and MUST read as 0
  pc   : BitVec 32
```

**`Vector`, not a function, not a HashMap.** Measured `[V-ME]`: `Vector` is
*"BEST for kernel `decide`"* (2,048-case regfile check in 2.4 s, axioms
`[propext, Quot.sound]`) and **fails under `bv_decide`** (`(r.set 0 v)[0] = v`
is abstracted as an opaque atom — no `getElem`/`Vector.set` support). Since
`bv_decide` is banned from shipped proofs, the trade-off is decided for us and
it lands on the side we want. `Std.HashMap` is unusable in both.

Regfile *laws* (read-over-write same/different index) come from the core
`Vector` lemmas, proved once, structurally — not from the 2,048-case
enumeration. The enumeration is a certificate, not the proof.

### 2.2 The five instructions, and why exactly these

| Instr | What it buys | The trap it exposes |
|---|---|---|
| `ADD`  | register–register arithmetic; the adder | none — this is the easy one, and it is the calibration |
| `ADDI` | the immediate path | **12-bit immediate SIGN-EXTENSION** — the single most common formalisation bug |
| `XOR`  | bitwise; the cheap exhaustive certificate | none; it is the fast credibility exhibit |
| `SLT`  | signed comparison | **signed vs unsigned** — this is literally the instruction the sp1-lean audit found *vacuously true* |
| `BEQ`  | control transfer; PC semantics | **PC + sext(imm) vs PC + 4**, and the branch-offset encoding |

**Why this set and not another.** It is the smallest set that closes Council
I's tower: a mini-language code generator needs (i) a way to make constants
(`ADDI` from `x0`), (ii) arithmetic (`ADD`), (iii) a comparison (`SLT`), (iv)
a conditional branch (`BEQ`), and (v) one bitwise op to make the ALU a real
ALU rather than an adder (`XOR`). With those five you can compile
straight-line integer arithmetic and `if`/`while` over 12-bit-immediate
constants. Nothing smaller compiles a language; nothing larger is needed to
say the tower closed.

**Stated exclusions, to be repeated in public every time:** no loads, no
stores, no `LUI`/`AUIPC`, no jumps (`JAL`/`JALR`), no shifts, no `M`
extension, no CSRs, no traps, no interrupts, no privilege modes, no memory
model at all. **Slice A is a register-to-register machine with a program
counter.** If it is called anything but "a five-instruction RV32I datapath",
the claim is being overstated.

**No memory is a feature, not a gap.** It removes the entire memory-model
problem from week 2. When memory does arrive, the dossier's measured answer
is: `BitVec addrWidth → BitVec dataWidth` as a plain function, LNSym's
`mem_separate'` disjointness pushed into `Nat` linear arithmetic and
discharged by `omega` (axiom-clean) — *not* an SMT array theory, which
`bv_decide` does not have.

### 2.3 The spec

**Hand-write it. ~100–150 lines. Do not import a generated model.**

`sail-riscv-lean` exists and is impressive — 175,877 lines, 4,779
definitions, 0 errors, typechecks in Lean, pushed 2026-08-04 `[V-SRC]`. Three
reasons it is not our spec:

1. **Its own README says the generated Lean is "neither executable nor
   polished in any way."**
2. **It has no license file.** For a repo whose selling point is that a
   skeptic can build and check it, an unlicensed 176k-line dependency is a
   non-starter.
3. It would make the spec — *the one artifact whose language matters, because
   it is the one a human must read* (Council I, the five-artifact loop) —
   unreadable. A 150-line spec a referee reads in ten minutes is the
   deliverable. A 176k-line import is the opposite of the deliverable.

Cite it as prior art; write our own. Same verdict for `lean-mlir`'s `RISCV64`
dialect (RV64I+M+B as SSA, real, in-tree): it pins
**`leanprover/lean4:nightly-2025-12-01`** against salt's `v4.32.0-rc1`, ships
9,449 `.lean` files, and needs `maxHeartbeats 1000000000000000000` just to
`deriving DecidableEq` on its `Op` type. Harvest the *idea* — "put time in
the type, `Stream (BitVec w)`, not a state monad" — and nothing else.

### 2.4 The equivalence obligation

```
      hand-written spec  step : St → BitVec 32 → St        (150 ln, readable)
                ↕  T-EQUIV: proved structurally, ∀ width
      the datapath as leg 2's `Circ`                       (the HDL seat's T4 shape)
                ↓  emitV  [UNTRUSTED]
      Verilog → LibreLane → GDSII + logical_nl.v
                ↓  the importer  [TRUSTED, ≤300 ln]
      Lean netlist  →  per-module `decide +kernel` equivalence
                ↓
      #audit_axioms → THREE AXIOMS END TO END
```

Slice A adds exactly one new link to the chain leg 3 is already building: the
spec↕Circ step. Everything downstream is the fabric's machinery, reused.

---

## 3. THE KILL-CHECKS — from the sp1-lean audit

The strongest public evidence that statement auditing is not optional is the
**Ethereum Foundation zkEVM audit of `succinctlabs/sp1-lean`, 2026-05-20**
(https://zkevm.ethereum.foundation/blog/sp1-fv). It announced **62 opcodes**;
the audit found **51 with complete correct proofs** — an 18% haircut on a
"verified" claim, found by reading the statements. Specifically:

- **`SLTI` was VACUOUSLY TRUE** — contradictory hypotheses from a copy-paste error.
- **`LH`, `LHU`, `LW`, `LWU` were proved against *byte-load* semantics** — the
  wrong specification, proved correctly.
- **`LUI`, `AUIPC`, `LD` had no theorems at all.**
- All load theorems depended on unfinished sign-extension lemmas; **5
  completeness proofs were deferred skeletons; 4 explicit axioms**.
- Several findings surfaced by an **LLM-assisted audit**.
- To its credit, sp1-lean *did* find a real bug: **`JALR` must compute
  `(rs1 + imm) & ~1`**; SP1 omitted the LSB clear. Patched in v6.1.0.

Each of those failure modes becomes a kill-check the Silicon seat's refuter
pass must run **before** any statement is announced.

### K1 — VACUITY. Every theorem's hypotheses must be shown inhabited.

The `SLTI` failure is not exotic: two hypotheses that cannot both hold make
the theorem true and worthless. **Rule:** every datapath theorem with
hypotheses ships beside an `example` that instantiates them with concrete
values and discharges them by `decide`. If the hypotheses are unsatisfiable,
that `example` fails to compile and the build goes red. *No hypothesis set
without a witness.*

### K2 — WRONG SPECIFICATION. Prove against the right semantics.

The load theorems were correct proofs of the wrong statement. A proof
assistant cannot catch this; only a second source can. **Rule, in three
parts:**
- (a) the spec is ≤150 readable lines and is **reviewed line-by-line against
  the RISC-V ISA manual**, with the manual section number in a comment on
  every instruction case;
- (b) **differential testing against an independent executable model** —
  Cedar's verification-guided development found **4 bugs via proofs and 21
  more via differential/property-based testing** (arXiv 2407.01688). Proofs
  alone found the *fewer* bugs. Run our `step` against a third-party RV32I
  simulator on random programs;
- (c) the pre-registered trap list for this slice, checked explicitly:
  **`x0` writes discarded**; **`ADDI` immediate sign-extended, not
  zero-extended**; **`SLT` signed, `SLTU` unsigned** (we ship only `SLT` —
  say so); **branch target `pc + sext(imm)`, fall-through `pc + 4`**; **branch
  immediate's implicit low zero bit**.

### K3 — MISSING THEOREMS. The claim table must be generated, not written.

`LUI`, `AUIPC` and `LD` were counted in "62 opcodes" while having no theorems
at all. That is a bookkeeping failure, and bookkeeping failures are exactly
what a build-time assertion prevents. **Rule:** the instruction list lives in
*one* place in the source, and a build-failing metaprogram — call it
`#audit_coverage`, modelled on `Salt/Tactic/AuditAxioms.lean`'s 127 lines —
checks that every instruction in that list has a named theorem and that every
such theorem is `#audit_axioms`-clean. **A README that says "5 instructions"
must be generated from the artifact.** If an instruction is dropped, the build
goes red before the claim is made.

### K4 — DEFERRED SKELETONS AND AXIOMS. Already covered; keep it that way.

sp1-lean shipped 5 skeleton proofs and 4 explicit axioms. Our iron rules
already forbid this (no `sorry`, no `native_decide`, no new axioms,
`#audit_axioms` on every theorem, `decide +kernel` never bare `decide`). The
addition for week 2: **`bv_decide` may be used as a dev accelerant and must
not survive into a shipped proof.** Grep the diff at wave exit; a
`bv_decide` in a shipped file is a wave failure, not a nit. Where
`bv_normalize` alone closes a goal, no solver runs and no axiom appears —
**write it as `bv_normalize`**, so the distinction is visible in the source.

### K5 — THE POINT IS TO FIND OUR OWN BUGS.

sp1-lean's real contribution was the `JALR` LSB bug. Pre-register what we
expect to find here, so that finding it is a *result* and not finding it is a
*question*: immediate sign-extension, `x0`-write suppression, branch-offset
encoding, signed comparison, and (when shifts arrive) `rs2[4:0]` shift-amount
masking. Record hits and misses in `docs/LEDGER.md` either way.

---

## 4. THE TOOLCHAIN TRAPS — measured, and each one costs a day if missed

| Trap | The fact | What to do |
|---|---|---|
| **`bv_decide` emits an axiom** | `[propext, Classical.choice, Quot.sound, <thm>._native.bv_decide.ax_*]`; `bv_check` does **not** escape it (same `nativeEqTrue` path); there is no kernel mode | dev only; re-prove clean before commit |
| **`decide_cbv` (v4.29)** | axiom-clean `[propext, Quot.sound]`, and it reduces well-founded recursion that kernel `decide` structurally cannot | the fallback for closed evaluations; **it does not enter binders**, so a `∀ x y : BitVec 8` goal must be reshaped as a closed `(List.range 65536).all (…) = true` |
| **Kernel depth, not work** | kernel recursion limit = `maxRecDepth × 16` = 8,192; Lucas–Lehmer does 4,400 nested unfoldings on 4,400-bit numbers "nearly instantly" but dies by depth at 9,689 | keep folds shallow; raise `maxRecDepth` and `--tstack` deliberately |
| **No BitVec in the kernel** | `reduce_nat` accelerates exactly 15 `Nat` primitives; `BitVec`/`Fin`/`UInt*`/`Array` are accelerated only *indirectly* via `Nat`; `Array α` **is** `List α` in the logical model | the "use Array for speed" folklore is **wrong** for kernel `decide` |
| **PR #14270, still open** | under the module system, `deriving DecidableEq` emits a non-`@[expose]` `decEq`, so `decide`/`rfl` **stall across a module boundary** — *"there is no user-side workaround"* | put the datapath's `Decidable` instances and the goals that use them in the **same module**, or write instances by hand with `decidable_of_iff`/`inferInstanceAs` |
| **Never build `Decidable` with tactics** | reduction gets stuck on `Eq.rec`; the canonical anecdote (lean4 #2552) has the *same* 729-case goal succeed with a `match`-written instance and time out with a `cases`-written one | explicit `match` only |
| **The Lean hardware lane is thin** | LNSym frozen since 2024-12; Sparkle is single-author and uses `native_decide`; the strongest nearby result (Kôika ALU, ITP semantics, arXiv 2605.04933) **went to Rocq, not Lean** | expect to build, not to import — and note that this thinness is itself part of the claim |

---

## 5. THE WEEK-2 PLAN — five days, each independently shippable

| Day | Deliverable | Exit test |
|---|---|---|
| **W2.1** | the spec: `St`, `decode`, `step` for the five instructions, ≤150 ln, ISA-manual section in a comment per case | it elaborates; K1 witnesses compile; a hand-traced 6-instruction program matches by `decide` |
| **W2.2** | the width-generic ALU + its structural correctness theorem; `w = 8` exhaustive certificate (~12 s) and `w = 32` instantiation | `#audit_axioms` clean; the 2¹⁶ certificate runs in a *slow* CI target, not the default one |
| **W2.3** | the regfile (`Vector`), `x0`-suppression theorem, PC update; the datapath assembled as leg 2's `Circ`; **T-EQUIV** `sem circ = step` | `#audit_axioms` clean; `#audit_coverage` green |
| **W2.4** | differential testing against an independent RV32I simulator on random programs (K2b); the trap list checked one by one (K2c) | a documented hit/miss table in `docs/LEDGER.md` |
| **W2.5** | through leg 3's chain: emit → LibreLane → netlist → import → per-module `decide +kernel` equivalence | GDSII produced; equivalence kernel-checked; three axioms end to end |

### ⛔ BUILD ETIQUETTE — MANDATORY, AND IT BITES HARDEST HERE

**EVERY Lean invocation goes through
`/Users/jyh/projects/claude/saltbuild.sh`** — builds *and* audit runs.
Never bare `lake`, never bare `lean`.

```
saltbuild.sh                            # full build, this repo
saltbuild.sh SaltWorks.Silicon.YourMod  # targeted build — prefer this while iterating
saltbuild.sh ScratchSILICON.lean        # replaces `lake env lean ScratchSILICON.lean`
```

It takes a cross-seat lock (one heavy invocation at a time, stale-reaped)
and caps `LEAN_NUM_THREADS=6`. **Judge its printed `saltbuild EXIT=N`, not
a pipe.** Full builds only at wave exit. **Killed builds resume
incrementally**, so a lock wait costs nothing. **Put this rule in every
executor and subagent brief you write.** (FLEET.md, maestro, 8/6 08:38 and
the extension after the second OOM: five seats × default `-j18` exhausted
64 GB + 8 GB swap; single elaborations on salt's heavy files reach 6–9 GB.)

This applies with particular force to W2.2: a 2¹⁶ exhaustive
`decide +kernel` certificate is a **12-second single-threaded kernel
reduction that holds memory the whole time**, and W2.5's netlist
equivalence is another. Both belong in a **slow target that is not built by
default**, and both must go through the wrapper. A certificate suite that
OOMs the fleet is not a credibility exhibit.

### ⚠️ AND PRICE THESE BY SEARCH SPACE AND MEMORY — NOT BY WALL TIME

**Added 2026-08-06 after the fleet's fourth resource incident, whose
mechanism the compiler seat named exactly** (FLEET.md 10:05):

> *An exhaustive `decide +kernel` has **no memory bound in principle**. The
> kernel materialises the reduction it is checking, so cost scales with the
> **search space**, not with the source file.*

The measured consequence, and it is the whole reason this section exists:
**a probe whose Lean source is under 60 lines reached 30.67 GB RSS** — with
the fleet lock held and every rule obeyed. Nothing in the source, the
lakefile, or a code review would have flagged it.

So when this brief says "instantiate at `w = 8` and certify all 2¹⁶ input
pairs in ~12 s", read that as a statement about a **16-bit search space on
a small circuit**, and never generalise it:

| Input bits | Status | Note |
|---|---|---|
| 16 (`w = 8` ALU pair) | ✅ ~12 s, measured | the certificate this brief prescribes |
| 20 | ⚠️ ~8 min | bad CI citizen; slow target only |
| 24 | ⛔ dead | measured, killed at >10 min |
| ~44 (a monolithic 8×8 serial fabric) | ⛔ **≈ 2 TB** | the Silicon seat's byte law: sliced cost ≈ #nets × 2^(n−3) bytes |

**The rule for anyone extending this brief: before adding an exhaustive
certificate, write down its input-bit count and multiply. Then run it
through `saltbuild.sh` and nothing else.** The compiler seat's own
self-cap is the model — no probe above 2¹² without posting to the bus
first, one probe file at a time, `fleet_hygiene.py --brief` before each
run.

**This property is exactly what makes T3 valuable and what makes it
dangerous**, and both halves belong in the README when the certificate
suite ships.

It applies to the **`#audit_axioms` and `#audit_coverage` runs of K1/K3
too** — those are Lean elaborations like any other, and running them
outside the wrapper is exactly the "just one quick check" that took the
fleet down twice today.

**The 3-attempt budget and A/B/C classification apply as everywhere else.**
If W2.2's structural ALU proof exceeds three attempts, the honest fallback is
narrower: prove the ALU at `w = 8` exhaustively, ship *that* as the verified
artifact, and state plainly that the 32-bit instance is unproved. A smaller
true claim beats a larger one with a hole in it — that is the entire lesson of
the sp1-lean audit.

---

## 6. WHAT WOULD MAKE ME ABANDON SLICE A

Stated now, before the data, so the call is not made under sunk cost:

1. **The structural ALU proof does not converge in three attempts** and the
   `w = 8`-only fallback is judged too small to be worth the week → then the
   week-2 stretch reverts to the fungibility exhibit and the certificate
   checker, both of which are already ruled and both of which are safer.
2. **The seam with leg 2 is not agreed by W2.1.** The datapath is a *consumer*
   of the HDL seat's `Circ`, including the new sequential extension. If that
   interface is still moving on day 1 of week 2, Slice A is not startable and
   should not be started.
3. **Leg 3's floor is not yet home.** D1–D4 (LibreLane, importer, comparator,
   fabric) outrank this entirely. Slice A is a *stretch*
   (`silicon-design-v1.md` D6 says so). The fabric is the promise; the
   datapath is the bonus. If the two compete for the same hours, the fabric
   wins and this brief waits.

---

## 7. THE SENTENCES TO SAY IN PUBLIC

- *"A five-instruction RV32I datapath — ADD, ADDI, XOR, SLT, BEQ — with a
  150-line hand-written specification, proved equivalent to its gate-level
  implementation width-generically, exhaustively certified at width 8, and
  checked against its post-place-and-route netlist inside the kernel. Three
  axioms end to end."*
- *"It is not a CPU. It has no memory, no loads, no stores, no jumps, no
  multiplier, no privilege modes. We say which five instructions because the
  last team that didn't announced 62 opcodes and had 51."*
- *"We could have proved the 32-bit ALU with a SAT solver. We didn't, because
  the tactic that does it adds an axiom to the theorem. We proved it
  structurally instead, and the exhaustive run at width 8 is the receipt."*

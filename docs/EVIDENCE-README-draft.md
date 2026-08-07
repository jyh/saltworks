# DRAFT — the public README skeleton
### 2026-08-06, EVIDENCE seat. **This is a draft for ratification, not the
### README.** Installing it at the repo root is the maestro's or the
### Captain's act, not mine. Everything in `⟨ANGLE BRACKETS⟩` is a slot
### that is NOT YET TRUE and must be filled from a landed artifact or
### deleted before anything ships.
###
### Sources: salt `docs/exploration/triple-campaign-0805.md` §§9–12,
### `saltworks/docs/{silicon,hdl}-design-v1.md`, `docs/tinytapeout-dossier.md`,
### `docs/EVIDENCE-ledger-latest.md`.

---

<!-- ======================= README STARTS HERE ======================= -->

# ⟨REPO NAME — Captain's ruling owed⟩

⟨**HEADLINE — DO NOT SHIP AS WRITTEN. One of these four clauses is true
today.** The intended claim is: *"A packet-switch fabric, proved in Lean 4,
compiled to Verilog by a verified compiler, hardened to real silicon
geometry by tools we do not trust — and then checked, inside the kernel,
against the netlist those tools actually produced."* **Status: the theorem
is landed; the verified compiler is partly landed (`opt_sem`, the
certificate suite, the fungibility exhibit); there is NO Verilog emitter
yet — `emitV` occurs once in the tree, in a comment; and nothing has been
hardened or checked end to end.** Rewrite it clause by clause against
landed artifacts at publication time, or ship a smaller true sentence.⟩

Every proof in this repo depends on exactly three axioms — `propext`,
`Classical.choice`, `Quot.sound` — and the build fails if that changes.

> ⚠️ **And that sentence is weaker than it sounds, so we say what it does
> not cover.** An axiom audit is a statement about *proofs*. It is
> **invariant under every failure mode that actually threatens this
> chain**: import the wrong netlist file, mis-parse a port, mis-model a
> cell, and the audit still prints three axioms. What rules those out is
> not the axiom count — it is the importer's mutation tests, the
> gate-level testbench eating byte-for-byte the same file, and the named
> provenance of the artifact we checked. **"Three axioms end to end" is a
> true statement about the proofs and a false one about the chain**, and
> anyone quoting it without this paragraph is overclaiming on our behalf.
> *(Silicon seat, refuter addendum 026f27f, honesty finding 1.)*
>
> ⚠️ **One reading hazard, which is about the reader and not the tool.**
> Lean prints info messages emitted *before* an error, so
> `#audit_axioms A B` where `A` elaborates and `B` then fails prints
> **`✓ A [0 axioms]` followed by an error** — and an eye scanning for
> ticks can find one beside a failed build. **Never quote an audit line
> without the build result beside it.**
>
> ⛔ **A STRONGER CLAIM STOOD HERE FOR TWO HOURS AND IT WAS FALSE — we
> leave the retraction in place rather than the sentence.** This section
> led, from 14:30 to 16:24 on 2026-08-06, with *"the audit cannot see a
> theorem that does not exist — it printed `✓ [0 axioms]` for two
> theorems that never elaborated."* **It does not.** The silicon seat
> re-tested their own landed finding against six deliberately-broken
> theorems and a control: every break produced either
> `error: Unknown constant …` (elaboration aborted, so the name never
> entered the environment) or `depends on non-whitelisted axiom(s):
> sorryAx` (elaboration recovered, so the declaration carries the axiom).
> **Not one tick for a broken theorem, and there is no third state.**
>
> The retraction is kept because *how* the error travelled is the useful
> part: **it replaced a true narrow claim with a false total one, and the
> false one was the more quotable** — which is why it moved from a bus
> post into this README in twenty-six minutes, unchallenged, by a seat
> (this one) whose entire job is to challenge exactly that. It rhymed
> with four true findings from the same afternoon. **A claim whose stated
> mechanism cannot happen has not been established, however plausible its
> conclusion.** *(silicon, `docs/silicon-auditaxioms-e1-0806.md`,
> `2723c40`; landed here by evidence at `e3ea8f1` and pulled at
> `--` on the same day.)*

> **The fences, stated before the claims** — they are in §6, and we would
> rather you read them first than discover them later.

---

## 1. What this is

A single chain, closed at every seam:

```
    the theorem            banyan_selfrouting, parametric in k     [Lean 4, LANDED]
        │                  any n distinct destinations, presented
        │                  sorted, route without conflict
        ▼
    the circuit            the fabric as a term of a deep-embedded
        │                  circuit DSL, with a semantics            [LANDED 26353d2]
        │                  ── stated at the STAGE BOUNDARIES, because a
        │                     `sem`-only theorem cannot see internal
        │                     link occupancy — which is the whole
        │                     content of the no-conflict hypothesis
        ▼
    the Verilog            emitted by a printer we DO NOT TRUST     [LANDED 74035a9]
        │                  ── no `emitV_sem`, deliberately: the round trip
        │                     compares through a PORT CORRESPONDENCE, so a
        │                     misconception SHARED by printer and importer
        │                     would pass. The top-level contract is pinned
        │                     to TT's validator — an authority outside this
        │                     repo — precisely to break that circularity.
        │
        ▼
    the layout             LibreLane + sky130 → GDSII          ⟨D4: RTL landed
        │                  synthesis and place-and-route are         002abc1 — 259
        │                  OUTSIDE the trusted base, by              cells, 2,108 µm²;
        │                  construction                              GDSII pending⟩
        ▼
    the netlist            imported back into Lean, ≤300 lines of
        │                  trusted importer + the cell models         ⟨leg 3 D2⟩
        │                  (15/13/68 distinct types across three real
        │                   submissions — budget the TAIL, not the median)
        ▼
    the check              per-COMBINATIONAL-CONE equivalence, by   [LANDED 2e24205]
                           bit-sliced `decide +kernel`              [+ D3.5 0f4c6d7]
                           bit-sliced `decide +kernel`
                           ── the kernel re-does every step
```

**The contribution is the last two arrows.** Verified synthesis is a
different claim, and a harder one to believe; we do not make it. We let
unverified industrial tools do the hard geometric work, and then we
*check their output* against the proved design, in the kernel, per run.

---

## 2. The 1988 correspondence — why this design and not another

The original is public and citable:

- **US Patent 4,910,730** — a high-speed packet switch in CMOS VLSI.
- the companion IEEE conference paper.

The detail that matters: **it was two chips.** A Batcher sorter and a
banyan router, fabricated separately, with a pinout chosen so the fabric
could stack in three dimensions.

**That two-chip partition is our proof partition, recovered 38 years
later:**

| 1988 silicon | 2026 proof |
|---|---|
| Chip 1 — the Batcher sorter | the **sorted-datum hypothesis**, discharged by `Finset.orderEmbOfFin` |
| Chip 2 — the banyan router | `banyan_selfrouting`, **proved**, parametric in *k* |
| the interface between them | the interface the theorem assumes |

**If we tape out, we tape out chip 2 — the proved half.** The proof's
shape is not an arbitrary scoping decision. It is the original silicon's
own modularity.

⟨A second correspondence, and this one we did not plan — **BUT IT IS NOT
YET VERIFIED AGAINST THE LANDED PROOF AND MUST NOT SHIP UNTIL IT IS.** The
claim: the proof uses a **descending stage index**, so the router consumes
destination bit *m* at the stage with *m* bits still unrouted and the
**first** stage reads the **most significant** bit — exactly the 1988 frame
format, address at the front, MSB first, because the packet arrives as a
bit stream. The serial wire order and the proof's induction order would
then agree by construction, neither chosen to match the other.
**Status (Silicon seat, addendum 026f27f, refutation 5): the confirmation
that was reported was performed against `ProbeFacade.line` — a duplicate
constant in a duplicate namespace — not against `SaltWorks.Banyan.line`.
As a statement about the landed proof it does not yet typecheck.** The
mathematics is untouched by this; the *claim about our artifact* is
unproven. Delete this paragraph or verify it against the real constant
before publication.⟩

The pin economy is the same argument too. In 1988 the pinout was chosen so
the fabric could stack; in 2026 the tile gives us 8 dedicated inputs and 8
dedicated outputs, and a word-parallel 8×8 fabric would need 64+ data pins
and cannot be built at any price. **Bit-serial is not nostalgia. It is
what the pins allow, in both decades.**

---

## 3. The price exhibit

> **In 1988, fabricating this design cost roughly $150,000** (VLSI
> Technology Inc; **the author's recollection**, order of magnitude).
> **In 2026 it cost €280** — and this time it shipped with a
> machine-checked proof.

Nominal ratio ≈ **500×**. Adjusted for inflation (~2.7× CPI 1988→2026, so
roughly $400K in today's money) ≈ **1,300×**.

The recollection is stated **as a recollection** and the ratio needs no
precision to land. What is exact is the 2026 side: **4 tiles (2×2) on the
TinyTapeout TTSKY26c shuttle, €280, purchased 2026-08-06**, sky130A,
submission deadline 2026-09-07 13:00 PDT.

⟨PENDING: this section says *fabricating*. Until the design is submitted
AND accepted, the honest verb is *"cost €280 to buy access to"*. Payment
is not submission — the "Submit a new revision" click is a separate,
later act. Do not upgrade the verb before the artifact exists.⟩

---

## 4. The seam doctrine — why certificates, not trust

The old answer to "is this compiler output correct?" was translation
validation (Pnueli, 1998) and proof-carrying code (Necula–Lee). Both were
sound, and both failed on the same thing: **the human cost of producing
the proofs.**

**Agents just paid that bill.** Per-instance certification is now the
native verification mode of automated development — not because the theory
changed, but because the price of a proof did.

This repo exhibits the spectrum at three altitudes:

1. **AMORTIZED** — the optimizer. Prove it once; every run of it is
   covered. **And it landed as a *validated* optimizer, not a
   proved-correct one:** `opt` checks the property its liveness analysis
   needs and falls back to the identity when the check fails, so
   `opt_sem : sem (opt c) = sem c` holds for **every** circuit — no
   well-formedness hypothesis, and no assumption that the analysis is
   right. **A bug in the analysis costs optimization, never correctness.**
   That is translation validation applied *inside* the compiler, one level
   above where we apply it to the untrusted layout tools — **the doctrine
   is not only for the untrusted tools at the bottom.** ⟨leg 2 T1,
   `0aad951`⟩
2. **PER-INSTANCE** — the netlist equivalence. LibreLane is never trusted;
   every run it does is checked. **This is no longer a promise:** the
   comparator's real post-synthesis netlist — 36 sky130 cells over 12
   types, 127 primitives, *including two `lpflow` power-isolation cells
   abc pressed into service as ordinary logic* — was proved equivalent to
   a deliberately differently-structured 109-gate reference **on all
   65,536 input configurations, in the kernel** (`2e24205`). And the
   sequential element followed: **every state and every input, lifted to
   arbitrary run length by induction** (`0f4c6d7`).

   **Both carry a mutation control** — change one gate and the certificate
   *fails* — because a certificate without one can be vacuous and still
   audit clean.
3. **THE FIVE-ARTIFACT LOOP** — spec, implementation, proof, certificates,
   and the emitted artifact. The implementation language is fungible; **the
   spec is the only artifact whose language matters, because it is the one
   a human must read** — and the certificate suite is how they read it.

⟨PENDING, the fungibility exhibit: one router spec, ≥3 deliberately
different implementations, each proved equivalent to the same spec. The
line it earns: *the certificate outlives every implementation.*⟩

**The tower.** The claim is **depth, not breadth**: every seam closed from
program to gates, with a kernel at each junction. CompCert is breadth on
one seam, done far better than we do it; nobody has depth on all of them.
We say "miniature" first — and then: **name the seam you distrust, and we
will show you its certificate.**

### The doctrine's own epistemology — name the narrower question

A certificate answers *"is **this artifact** correct?"*, not *"is the
**tool** correct?"*. That substitution is deliberate and it is the whole
idea. But the same substitution happens **by accident**, constantly, with
every other instrument — and on the first day of building this we caught
ourselves doing it twice:

| Instrument | What it actually answers | What it gets read as |
|---|---|---|
| `#audit_axioms` | do these **proofs** rest on only three axioms? | is the **chain** correct? |
| a memory cap that was never breached | did **this run** exceed it? | does the cap **bind**? |
| a per-instance certificate | is **this artifact** correct? | is the **tool** correct? |
| **a net-name grep over the synthesised netlist** | did this **identifier** survive the flow? | did the **structure** survive? |

**The last row is not hypothetical, and it nearly cost us a wrong ruling on
the chip we are taping out.** We mark the design's stage boundaries so that
synthesis keeps them as real nets — that is what makes the fabricated
netlist certifiable cone by cone rather than as one 36-input blob. To check
whether the foundry flow honours it, the obvious test is to grep the
returned netlist for the boundary net's name.

**On the real artifact that name is absent — from the treated *and* the
untreated build.** The flow splits vectors into per-bit nets, so the parent
declaration disappears in both. The grep therefore reports *"the attribute
was stripped"* with complete confidence, and it is **wrong**: measured by
what actually matters — the number of inputs feeding each combinational
cone — the boundaries are entirely intact, and they take the shipped
netlist from **87.5% to 100%** of cones inside the size ceiling our proofs
require.

Two readouts, both reasonable, pointing in opposite directions; the
misleading one is the one you reach for first. **What saved it was writing
the readout down before the data existed** — the experiment was
pre-registered with the cone census, not the name, as its primary measure,
hours before either build ran. We do the same thing with the ledger in §7,
for the same reason.

⇒ **Two rules we hold ourselves to, beyond naming the narrower question:**

1. **Fix the readout before you can see the answer.** A measure chosen
   after the data is a measure chosen by the data.
2. **When an instrument cannot be quoted, publish its location.** One of
   our own checks scans text for forbidden strings, so any document
   describing it by *quoting* those strings trips it — which means the
   check can never be explained in prose, and an unexplainable check is an
   unauditable one. A file-and-line pointer is not a string, and costs
   nothing.

Three controls we adopted in one morning looked like protection and were
not equal: one was a **measured no-op**, one was **deployed and
unverified**, one was **real but bounded the wrong thing**. An instrument
that cannot distinguish *untested* from *working* would have rated all
three green.

**So the rule we hold ourselves to, and the one we would ask of anyone
reading this repo: name the narrower question out loud, rather than retire
the instrument.** Every tool in `docs/ledger-tools/` reports what it did
*not* check. The axiom audit says what an axiom audit cannot see. The
ledger prints the records it threw away. That is not modesty — it is the
only way a stack of narrow instruments adds up to a claim you can trust.

*(Arrived at by the fleet operating, not by anyone theorising: math seat,
2026-08-06.)*

---

## 5. The axiom posture

```
#audit_axioms Salt.…    -- a build-time ASSERTION, not a report
```

- The whitelist is exactly `[propext, Classical.choice, Quot.sound]`.
- `#audit_axioms` runs `Lean.collectAxioms` at elaboration and **fails the
  build** if any transitive dependency falls outside it.
- **No `sorry`. No `native_decide`. No home-rolled axioms.**
- **No `bv_decide` in any shipped proof.** Measured on our exact
  toolchain: a solver-reaching `bv_decide` call adds
  `<thm>._native.bv_decide.ax_*` to the theorem's axiom set, and
  `bv_check` does not escape it — there is no kernel mode. We could have
  used the fast bitblaster. We didn't, because it would have voided this
  section. Where `bv_normalize` closes a goal alone, no solver runs and no
  axiom appears; we write those as `bv_normalize`, so the distinction is
  visible in the source.

**The cost of that discipline, stated plainly — and the unit is INPUTS, not
gates.** A bit-sliced certificate costs 2^inputs bits per net, so gate count
is nearly free and **input count is the wall**: `Nat.pow` is
kernel-accelerated only to exponent `1<<<24`, which puts a hard ceiling at
**24 input bits**.

**So the decomposition is not per-module — it is per COMBINATIONAL CONE.**
Post-place-and-route there are no modules left: a real submission is one
flat block (measured on three). A flat sequential netlist instead
decomposes at the **flop boundary** — every flop D-pin and every primary
output roots a cone bounded by flop Q-pins, primary inputs and tie cells —
and that decomposition survives whether or not hierarchy does.

**Measured, over 1,626 cones in nine real submissions: 86.8% fall under the
24-input ceiling.** For this design it is not close — every cone in the
bit-serial switch element has **at most six inputs**, and the fabric is
twelve copies of it. The ~13% tail is real, and we state it rather than
discover it later: the worst cone we found was 226 inputs, in someone
else's register-file ECC.

---

## 6. The fences

Stated first everywhere we speak, and repeated here:

1. **No kernel decides physics, biology, or whether a design is worth
   building.** The chain covers spec → artifact. That boundary is what
   makes the rest trustworthy.
2. **Verified subsets are subsets.** ⟨If the RISC-V datapath ships: it is
   a five-instruction RV32I datapath — ADD, ADDI, XOR, SLT, BEQ — with no
   memory, no loads, no stores, no jumps, no multiplier, no privilege
   modes. We name the five every time. The last team that didn't announced
   62 opcodes and had 51.⟩
3. **The layout tools stay unverified.** We do not trust them; we check
   their output. That is a *different and weaker* claim than "verified
   synthesis", and we will not let it be read as the stronger one.
4. **Silicon is a stretch until it isn't.** ⟨Today: tiles purchased,
   deadline 2026-09-07. Nothing has been submitted, nothing has been
   fabricated. Promise the chain, never the silicon.⟩
5. **The proof is of the routing, not of the whole switch.** The sorter is
   a hypothesis we discharge from mathlib, not a circuit we built.
6. **THE CHIP CANNOT EXHIBIT ITS OWN THEOREM'S HYPOTHESIS.** The theorem
   assumes destinations that are **sorted and concentrated**. The Batcher
   sorter that would produce them is built **neither in Lean nor in
   silicon**. So the taped-out part routes correctly **only if something
   off-chip pre-sorts the inputs.** That is precisely the 1988 two-chip
   partition and it was always the plan — but it needs saying in one plain
   sentence, unprompted, because a reader will otherwise assume the chip
   is self-contained.
7. **What is proved is narrower than "a switch works".** Stated exactly:
   an arithmetic function on ℕ is injective under stated hypotheses. **There
   is no network, no switch, no packet and no time in the statement.** The
   bridge from that theorem to a circuit is the `Circ` semantics and the
   netlist equivalence — those are the interesting steps, and they are
   separate claims that must each carry their own evidence.
   *(Fences 6 and 7 are the Silicon seat's honesty finding 2, addendum
   026f27f. They are in the README because a fence a reader has to
   discover is not a fence.)*

---

## 7. The ledger — who was awake

Every artifact here carries a timestamp, and so does every human word that
directed it. The tooling is in `docs/ledger-tools/` and it is committed,
runnable, and self-tested (`selftest.py`, 67 checks).

**The unit is the human-silence window** — the stretch between the last
moment a human touched any seat and the next. Not "night hours": the
night-hours framing is weaker, and a skeptic with `git log` would break it
in thirty seconds.

**The filter is disclosed with every number.** A `"type": "user"` record in
an agent transcript is *not* necessarily a human: agent-completion
notices, `/loop` timer ticks, cron pings, peer-seat messages and
context-compaction summaries are all injected with `role: "user"`.
Counting them made it look as though 98.5% of commits landed within 30
minutes of a human message; filtering moved the ≥1 h figure from **0.3% to
21.5%**. Two of those classes — loop ticks and cron pings — fire
*precisely when the human is away*, and the cron pings carry the human's
own words verbatim, so no string filter can catch them. We classify by the
records' own provenance fields and we print what we threw away.

**We publish the attended days too.** The measurement was pre-registered
before the data existed. ⟨Day 1 of the campaign: 13 commits, **zero**
inside any ≥1 h silence window — it was the most supervised day the
project will ever have. A ledger that only appeared on the good days would
be worth nothing.⟩

Also reported, and separately: **tokens** (input / output / cache created /
cache read, cache never folded into a headline) and **the human's time**
in four pre-registered categories — DIRECTING, REVIEWING, UNBLOCKING,
WATCHING — where the dependency claim is the first three only, by the
counterfactual test *would the artifact exist without this touch?*
WATCHING is reported as its own line, proudly.

⟨PENDING: fill the headline table from `docs/EVIDENCE-ledger-latest.md` at
publication time. Do not hand-copy numbers; they go stale in under a
week.⟩

---

## 8. Build it yourself

```sh
⟨PENDING — the one-command build. The deliverable is
 "a public repo that builds end to end with one command."
 Fill this in from the landed lakefile + flow scripts, and
 make sure a stranger can run it on a clean machine.⟩
```

⟨PENDING: pin and state the toolchain, the mathlib rev, the LibreLane
version and the sky130A PDK hash. For the tapeout path these must match
what TinyTapeout's CI uses — `librelane==3.0.5` and PDK
`0536d02d875c8f67dd7cca3902ac457e62f20005` — because **the netlist that
gets fabricated is built by their CI, not by our local run**, and the
equivalence proof must target the artifact that actually ships.⟩

---

## 9. Prior art, and what we owe it

- **CompCert** — the shape of a verified compiler, and the standard we are
  measured against on the one seam it covers.
- **`bv_decide` / the verified bitblaster** (Böving et al., OOPSLA'25) — we
  decline to use it *because* we measured what it adds, not because it is
  unsound.
- **The Ethereum Foundation's audit of `sp1-lean`** (2026-05-20) — 62
  announced opcodes, 51 with complete correct proofs; one theorem
  *vacuously true* from contradictory hypotheses; four proved against the
  wrong specification. **This is the best public evidence anywhere that
  statement auditing is not optional**, and it is why our claim tables are
  generated from the artifact rather than written by hand.
- **Cedar's verification-guided development** (arXiv 2407.01688) — 4 bugs
  found by proofs, **21 more by differential testing**. Proofs alone found
  fewer. We run both.
- **LNSym**, **lean-mlir / the CIRCT dialects**, **Kôika** — the Lean and
  Rocq hardware lines we read, borrowed ideas from, and did not import.

---

## 10. Honest status

⟨A dated table, regenerated not hand-maintained: what has landed, what is
in flight, what is a stretch, and what we tried and could not do. The
"could not do" column is not optional — it is the reason the other three
are believable.⟩

---

## License

⟨Captain's ruling owed. Note: anything submitted to TinyTapeout is
**contractually required** to be Apache-2.0-compatible and **publicly
published** — that is not our choice to make, and it is also exactly the
demo.⟩

<!-- ======================== README ENDS HERE ======================== -->

---

## Notes for the ratifier (not part of the README)

1. **Every `⟨…⟩` is a live overclaim risk.** They are written as slots
   precisely so that shipping with one unfilled is visibly wrong rather
   than quietly false.
2. **The verb in §3 is load-bearing.** "Fabricating cost €280" is not true
   today and will not be true until a design is submitted *and* accepted.
   Today's true sentence is "€280 bought access to a shuttle".
3. **Do not import salt's numbers without their caveats.** The leg-1
   do-not-quote list applies here too: never "13 waves", never the
   night-hours framing, never "259/259" without its date and scope, never
   a percentage of the corpus described as axiom-audited.
4. **§7's ledger numbers must be generated at publication time.** The
   corpus grew 21% in the five days before the last harvest; anything
   hand-copied is stale within a week.
5. **§2's patent claims are the Captain's own prior art.** He is the named
   inventor; the README should say so plainly rather than implying an
   arm's-length citation.

# CAMPAIGN SCOREBOARD
### The running status of the triple. Maintained by the EVIDENCE seat;
### refreshed at least daily and at every close-of-board.
### **Last refreshed: 2026-08-06 10:12 PDT** (day 1). Seat-status lines age in
### MINUTES, not days — see rule 2.

**T0: 2026-08-05 22:02 PDT. Campaign window: ~Aug 19.
Silicon deadline: 2026-09-07 13:00 PDT (32 days).**

Rules for this file:

1. A line moves to **LANDED** only when an artifact is committed and named
   here **by path or commit**. Anything else is ⟨IN FLIGHT⟩ or ⟨NOT
   STARTED⟩. No line is upgraded on the strength of a plan.
2. ⚠️ **EVERY NON-LANDED LINE IS A SNAPSHOT, AND SNAPSHOTS AGE IN MINUTES.**
   The math seat measured this on 2026-08-06: its N7-prep dossier marked two
   WEIL-TRIO rows `[IN FLIGHT]` and they had **already landed** — *"my
   snapshot aged in about twenty minutes… worth remembering before any seat
   quotes another seat's status."* This scoreboard quotes other seats'
   status **by construction**, so it inherits that failure mode and it must
   not read as authoritative about work it does not own.
   **Therefore: a ⟨…⟩ line is only ever "as reported by ⟨seat⟩ at ⟨time⟩",
   and a stale one always errs against the seat whose work it describes.**
   When in doubt, believe the seat, not this file.
3. **LANDED rows are the trustworthy half** — they cite a commit, and a
   commit does not go stale. ⟨TODO, evidence seat: generate the LANDED
   table from `git log` rather than maintaining it by hand, so the
   mechanically-knowable half stops depending on my attention.⟩

---

## THE ONE CLAIM

> The same method, the same fleet, the same referee discipline — three
> domains, one fortnight, with the ledger showing when each artifact landed
> and who was awake.

---

## THE THREE LEGS

### Leg 1 — MATHEMATICS (harvest, do not rebuild)

| Item | Status | Where |
|---|---|---|
| The evidence package | **LANDED** | salt `docs/exploration/leg1-evidence-0805.md` (740 ln) |
| 652,312 Lean lines · 1,130 files · 19,564 declarations · 1,940 commits · 30 days | **MEASURED** | ibid. §1 |
| Zero `sorry` / `native_decide` / home-rolled axioms, verified in tactic position | **MEASURED** | ibid. §3 |
| 166 `#audit_axioms` assertions naming 6,302 distinct declarations | **MEASURED** | ibid. §3 |
| 73 registry rows, lint-green | **MEASURED** | ibid. §2 |
| Two papers: witness 20pp/172 citations, flagship 17pp/152 | **MEASURED** | ibid. §6 |
| The fulcrum road kept running through the fortnight | ⟨IN FLIGHT — math, as of 10:09⟩ | Lean paused until 20:00 per the 09:22 order; read-only queue cleared |
| N7-PREP dossier (three read-only scouts, zero Lean) | **LANDED** | salt `docs/exploration/n7-prep-dossier-0806.md` (1019c0e) |
| The W3 refutation delivered to the WEIL-TRIO seat via `flags.md` | **LANDED** | salt `docs/blueprints/flags.md` (a7fa34e) |
| CHAR-TRIO / WEIL-TRIO campaigns (second salt seat) | ⟨IN FLIGHT — third-hand, ages fast; **believe that seat, not this row**⟩ | W4Q reported landed at `flags.md:20887`; **W3 reported LANDED** (maestro, 10:11) as `norm_kloosterman_estermann`, sharp `2^{v₂/2}` fold verified, road collapse **honestly gated on W4-a**; W5 firing |
| **A cross-seat delivery loop that closed** | **LANDED** | math's W3 refutation (10:02) → evidence flags the recipient has never posted (10:05) → math re-delivers via `flags.md` `a7fa34e`, a channel that seat *writes* to (10:09) → W3 lands with the dependency gated (10:11). **The finding arrived and changed the artifact.** |

### Leg 2 — CODE: the verified circuit compiler (seat: compiler)

| Deliverable | Status |
|---|---|
| Design freeze v1 + seat's own refuter pass | **LANDED** — `docs/hdl-design-v1.md` (+ 2 addenda) |
| Syntax + Sem | **LANDED** — `ad313e3` |
| T1 `opt_sem` — the optimizer | **LANDED** — `0aad951`, and as a **VALIDATED** optimizer: `opt` checks the property its liveness analysis needs and falls back to the identity when the check fails, so `opt_sem` holds for **every** circuit with no wf hypothesis and no assumption the analysis is right. **A bug in the analysis costs optimization, never correctness.** |
| T3 the executable-certificate suite | **LANDED** — `2a27c12` |
| T5 the fungibility exhibit | **LANDED** — `2a27c12`, and **checkable rather than asserted**: three XOR implementations at 1, 4 and 5 gates, with `fungible_distinct` proving the counts (so three renamings cannot pass as three implementations), `fungible_is_xor` pinning the result to the stated truth table rather than to mere agreement, and **`mutation_detected` proving that swapping the xor for an or BREAKS the certificate** |
| T2 `emitN_sem` — the netlist normal form | ⛔ **BLOCKED** on the writer-slot ruling (see open ruling 5) |
| T4 `banyan_circ` — the fabric as a `Circ` | ⟨NEXT — and the refuter pass found T4 **cannot be stated against the declared `sem`**; it gets an occupancy statement at stage *m* instead⟩ |
| Sequential extension for the bit-serial switch element | ⟨IN FLIGHT — and now gated on Silicon's frame-format decision, see the defects list⟩ |
| **The leg is MATHLIB-FREE** | **MEASURED** — a full `SaltWorks.HDL.*` build is **6 jobs, ~1.5 s**, against 8,581 jobs for a Mathlib-importing module. After three OOM kills that is a resource property, not a nicety: this seat's iteration no longer competes for the fleet lock. |

### Leg 3 — VLSI: the silicon chain (seat: silicon)

| Deliverable | Status |
|---|---|
| `banyan_selfrouting`, parametric in *k*, 3 axioms | **LANDED** — `SaltWorks/Banyan/SelfRouting.lean` |
| Design freeze v1 + ADDENDUM 1 (bit-serial, JYH-ruled) | **LANDED** — `docs/silicon-design-v1.md` |
| The seat's own refuter pass, seven lanes | **LANDED** — `docs/silicon-refuter-0806.md` (3e41d10) |
| D1 — real sky130 synthesis, reproducible, versions pinned | **LANDED** — 62b1b25 (Nix half stated as blocked) |
| D2a — 13 sky130 cell models, kernel-cross-checked against the vendor Liberty | **LANDED** — 0baa9fd, `SaltWorks/Silicon/Cells/Sky130.lean` |
| D2b — the netlist importer + mutation tests | ⟨IN FLIGHT⟩ |
| D3 — comparator end-to-end equivalence, kernel-checked | ⟨NOT STARTED⟩ |
| D3.5 — the bit-serial switch-element FSM refines `line` | ⟨NOT STARTED⟩ |
| D4 — the fabric: per-module equivalence + GDSII | ⟨NOT STARTED⟩ |
| D5 — TinyTapeout TTSKY26c submission | **TILES BOUGHT** (see below); nothing submitted |
| D6 — the RISC-V datapath (stretch) | brief **LANDED** — `docs/EVIDENCE-riscv-datapath-brief.md` |

---

## THE PRICE EXHIBIT

> **In 1988, fabricating this design cost roughly $150,000** (VLSI
> Technology Inc; **the author's recollection**, order of magnitude).
> **In 2026 it cost €280.** And this time it ships with a machine-checked
> proof.

- Nominal ratio ≈ **500×**; inflation-adjusted (~2.7× CPI 1988→2026, so
  ~$400K real) ≈ **1,300×**.
- The 2026 side is exact: **4 tiles (2×2) on TinyTapeout TTSKY26c, €280,
  purchased 2026-08-06.** sky130A, foundry run CI-2609.
- ⚠️ **Payment is not submission.** The "Submit a new revision" click is a
  separate, later act. Until a design is submitted *and* accepted, the
  honest verb is **"€280 bought access to a shuttle"**, not "fabricating
  cost €280". See `docs/tinytapeout-dossier.md` §7.2.

---

## THE TAPEOUT CLOCK

| Date | Event |
|---|---|
| **2026-09-07 13:00 PDT** | **HARD DEADLINE** (20:00 UTC) — no revisions after |
| by 2026-08-31 | target: a real revision submitted, one week of slack |
| 2027-03-27 | chips expected |
| 2027-05-12 | estimated delivery |

Shuttle capacity when last measured (2026-08-06): 222 of 512 tiles free —
and both preceding sky130 shuttles closed at 512/512.

---

## THE LEDGER — who was awake

Tooling: `docs/ledger-tools/` (committed, self-tested — 67 checks).
Design frozen before the data existed:
`docs/measurement-preregistration.md` + ADDENDUM 1.

| Dated artifact | What it holds |
|---|---|
| `docs/EVIDENCE-ledger-2026-08-06.md` | day 1 — silence windows, per-day, longest run, the filter disclosure |
| `docs/EVIDENCE-ledger-latest.md` | the most recent run, same content |
| `docs/EVIDENCE-tokens-2026-08-06.md` | day 1 — tokens by project × tier × wave, cache separate |
| `docs/EVIDENCE-human-time-tags.tsv` | the four-category tags (maestro-assigned, JYH spot-audited) |

**Day 1, measured (T0 → 2026-08-06 09:50):**

| Quantity | Value |
|---|---:|
| Commits, saltworks | 13 |
| API requests (deduplicated) | 2,752 |
| Output tokens | **869,114** |
| Cache created / read | 18,941,186 / 344,638,099 |
| JYH engaged time (pre-registered floor) | **2 h 04 m** — 5 DIRECTING, 1 WATCHING |
| Commits inside a ≥1 h human-silence window | **0** |

**The zero is not a failure to report — it is the report.** Day 1 was
Council I, five seat launches, a bit-serial ruling, a tile purchase and
three OOM kills: the most supervised day this campaign will ever have. The
measurement was pre-registered before any data existed, and the attended
days are published at the same resolution as the unattended ones. That is
the only reason a long-silence exhibit will be worth anything when it
arrives.

---

## FLEET RESOURCE LESSONS — day 1, evidence-grade

Four incidents, all on one 64 GB machine, all cheap in work (lake resumes
incrementally) and all worth publishing. They are the operational half of
the unattended story, not blemishes on it.

1. **OOM #1** — 5 seats × default parallelism; single elaborations
   measured at 6–9 GB. *Fix:* `saltbuild.sh`, a fleet-wide lock + thread
   cap.
2. **OOM #2** — 49 bare `lean` processes, swap at 37 GB: the lock covered
   `lake build` but not `lake env lean` audit runs, and in-flight
   subagents carried pre-rule briefs. *Lesson:* **locks must cover every
   door, not just the front one — and a rule change must reach the agents
   dispatched before it existed.**
3. **Kill #3** — enforcement escalation; one seat discovered it had been
   an offender without knowing, because a rejected dispatch had already
   launched. *Lesson:* **the working tree and the git index are cross-seat
   resources with no lock** — commit explicit pathspecs only, never
   `git add -A`. (Ruled fleet-wide by the maestro at 10:11, after a bare
   commit at 10:08 swept a neighbour's staged files; this seat had already
   adopted it at 09:35 and disclosed its own earlier violation.)

   - ⛔ **THE SECOND HALF, measured live at 12:12 and it is the bigger
     half: THE LOCK SERIALISES BUILDS, NOT PROCESSES.** One *fully
     compliant* `saltbuild.sh` invocation ran **five concurrent `lean`
     children totalling 17.8 GB** (11.2 + 4.5 simultaneously), with the
     lock held and every rule obeyed. Per-build parallelism is a
     **multiplier** on top of the single-elaboration cost. **Even a
     perfectly binding `-M 12000` would permit 5 × 12 GB** — so the `-M`
     question is *narrower than the exposure*.
   - **The knobs, measured by the math seat (11:04), read-only:**
     `lake build -j1` **does not exist** on this toolchain (Lake
     5.0.0-src+b4812ae — no `-j`, no `--jobs`, no parallelism flag
     anywhere); a `LEAN_NUM_PROCS`-style throttle **does not exist either**
     (`strings` over the lake binary yields exactly one `LEAN_*`/`LAKE_*`
     name, `LEAN_RECURSION_COUNT`). `LEAN_NUM_THREADS` is consumed by the
     `lean` *child*, which is precisely why it caps that child's task pool
     and not how many children lake spawns.
   - ⚠️ **A CORRECTION I OWE:** I called the 09:01 claim *"this lake has no
     `-j`"* suspect. **It is correct** — math measured it. What I actually
     measured false was the *second half* of that sentence, *"the task pool
     IS the job pool"*. **Two claims in one sentence, and I impugned the
     true one.** Both halves are separated here deliberately.
   - ✅ **THE ONLY PROCESS-COUNT CONTROL THAT EXISTS IS TARGET SHAPE.**
     Lake's concurrency comes from *independent modules in the requested
     closure*, so a targeted build whose dependencies are already built
     spawns essentially one `lean`. **"Prefer targeted builds while
     iterating; full builds only at wave exit" was right for a better
     reason than anyone knew — it is not etiquette, it is the only knob.**

**A fifth lesson, and it bit THREE separate times before noon** — so it is
structural, not carelessness:

5. **A snapshot of another seat's live tree ages in minutes.** Measured
   instances, all 2026-08-06: math's N7-prep dossier marked two WEIL-TRIO
   rows `[IN FLIGHT]` that had already landed; three line citations in the
   same dossier were off by 3, a file called untracked was tracked, and a
   declaration count was 6 against an actual 13; and this scoreboard
   inherits the identical hazard by construction (rule 2). *Fix:* **cite
   commits, not tree state.** A commit hash does not age. Anything read
   live from another seat's checkout must carry the time it was read and
   an instruction to believe that seat over the copy.
4. **The runaway (averted)** — a single *correctly wrapped* elaboration
   reached **30.7 GB RSS** with the lock held and every rule obeyed
   (evidence, 09:49; gone by 10:04, RAM recovered; it was the last probe
   of the compiler seat's refuter panel, which completed 13 agents with 0
   errors). *Lesson, and it is new:* **serialization is not a memory
   bound.** The wrapper guarantees one heavy invocation at a time; it does
   not bound what that one costs. The cap has to be on the process, not
   only on the queue.
   - **The mechanism, named by the compiler seat (10:05):** *"an
     exhaustive `decide +kernel` has **no memory bound in principle**. The
     kernel materialises the reduction it is checking, so cost scales with
     the **search space**, not with the source file."* **The probe's Lean
     source was under 60 lines.** Nothing in the source, the lakefile, or
     a code review would have flagged it — which is precisely why a
     process cap is needed and why reviewer vigilance is not a substitute.
   - **It is the same property that makes the certificate suite (leg 2's
     T3) valuable and that makes it dangerous**, and both halves belong in
     the README when T3 ships.
   - *Response, unprompted, from the seat that caused it:* a published
     self-cap (no probe above 2¹² without posting first; one probe file at
     a time; `fleet_hygiene.py --brief` before each run) **and** a real fix
     — bit-slicing the evaluation removes the need for these sweeps. That
     is the right shape: a measurement, a bound, and a design change, not
     an apology.
   - ⚠️ **And the obvious fix is a no-op here.** I proposed `ulimit -v`;
     the math seat **measured** it and it does not work on Darwin:
     `ulimit -v`/`-m` either refuse (`cannot modify limit: Invalid
     argument`) or are silently unenforced — a child allocated 800 MB
     under a nominal 500 MB cap. `RLIMIT_AS` is not enforced and
     `RLIMIT_RSS` has been a no-op on macOS for years. **It would have
     passed review and changed nothing, and we would have taken kill #5
     believing we were protected.**
   - ✅ **What should work is Lean's own cap**, enforced inside Lean where
     Darwin's rlimit gap is irrelevant: `lean -M <MB>` (and `-T` for
     allocations per task), documented in this toolchain's own `--help`.
     Two separate edits: the **audit** path is a one-word change in the
     wrapper (`lake env lean -M 12000 "$@"`); the **build** path is not
     reachable from the wrapper at all, because lake spawns `lean` per
     module and does not forward stray args — it needs `moreLeanArgs` /
     `leanOptions` in the lakefile, which is a repo edit and therefore the
     maestro's or Captain's call.
   - 🔑 **AND A BETTER ANSWER THAN THE GUARDRAIL** (compiler seat, 11:50):
     the two certificate routes have **different shapes, not different
     speeds.** Pointwise `decide +kernel` has **no memory bound at all** —
     it materialises the reduction, which is how a 60-line probe reached
     30 GB. **Bit-sliced is bounded by construction**: `Nat.pow` is
     kernel-accelerated only to exponent `1 <<< 24`, so a sliced
     certificate of width `W = 2ⁿ` needs the mask `2^W − 1` and **n = 24
     input bits is a HARD KERNEL CEILING** — at which a single net is 2 MB,
     so total memory is ~**2 MB × #nets** (200 nets ≈ 400 MB). *That is why
     the measured "24 input bits, 60 gates, seconds" datum hit exactly 24
     and not 25.* **A fleet that certifies bit-sliced never generates the
     workload that needs the guardrail.** The `-M` question stays open;
     this removes the need for the answer rather than supplying it.
   - ⚠️ **ENFORCEMENT IS UNVERIFIED.** Nobody has test-fired `-M` yet
     (math is under the no-Lean order until 20:00 and correctly declined
     to break it for an experiment). One run settles it: build a known-heavy
     file through the wrapper with `-M 4000` and confirm it dies with a
     Lean memory error instead of climbing. **Do not write the cap into
     the wrapper as "fixed" until that run exists.**

---

## THE DAY-1 PRINCIPLE — every instrument answers a narrower question than the one you asked

Stated by the math seat at 10:41, and it unifies everything below:

> **`#audit_axioms` cannot tell a correct proof from a vacuous statement.
> An unbreached cap cannot tell a working bound from an untested one.**
> Both are instruments that answer a *narrower* question than the one you
> wanted answered — and in both cases the fix is to **name the narrower
> question out loud**, not to retire the instrument.

Three independent instances, all measured on day 1, all by different seats
from different directions:

| Instrument | The question it *actually* answers | The question people read it as answering |
|---|---|---|
| `#audit_axioms` | do these **proofs** rest on only three axioms? | is this **chain** correct? *(wrong file imported, port mis-parsed, cell mis-modelled — all still print three axioms)* |
| an unbreached memory cap | did **this run** exceed the cap? | does the cap **bind**? *(three controls were adopted today that looked like protection: `ulimit` — measured no-op; `-M` — deployed, unverified; the lock — real, but bounds the **queue**, not the **process**)* |
| a per-instance certificate | is **this artifact** correct? | is the **tool** correct? *(this one is the seam doctrine itself, and it is the only one of the three we designed on purpose)* |
| **`banyan_selfrouting`** | are the **active** destinations conflict-free? *(`no_conflict` is `Set.InjOn` over `Set.Iio n` — it constrains active lines only)* | **does the circuit behave correctly at every port?** ⛔ **It does not, and this gap produced a real bug — see below.** |
| **the circuit DSL's declared `sem`** | what appears at the **primary outputs**? | **does the fabric route?** ⛔ The freeze asked for *"`banyan_circ` + proof its `sem` realizes line-routing"* and **that is unstateable**: `sem` exposes only stage boundary m = 0, where `line 0 s d = d` holds for every source and destination **with no hypotheses at all**. A `sem`-only theorem cannot see internal link occupancy — **which is the entire content of `no_conflict`.** *(compiler seat, 13:10)* |

---

## DEFECTS FOUND BY THE DISCIPLINE — the running list

A campaign that claims a method should publish what the method caught. Day 1:

| Found | What | By whom, how |
|---|---|---|
| **A live routing bug in committed RTL** | `SaltWorks/Silicon/RTL/bitserial_switch.v:25-26`. Both-active cases route correctly — but at an **idle port**, `sel0 = 0` makes `out0` take `in0` unconditionally, so **an active packet on `in1` bound for `out0` is silently DROPPED**. One-sided (out0 prefers in0, out1 prefers in1). | compiler seat, 10:52, **by enumerating the element rather than reading it** |
| — why the proof did not catch it | **`banyan_selfrouting`'s `no_conflict` hypothesis constrains only the ACTIVE lines.** Idle ports are outside what the theorem says anything about — and "sources concentrated" is exactly what *makes* idle ports possible at interior stages. The theorem is true; the artifact is wrong; nothing was violated. | the day-1 principle, in its sharpest form |
| — the fix is a **frame-format decision, not a logic patch** | The element cannot distinguish "idle" from "destination bit 0" because **nothing in the frame says so**. The classical answer, implied by the 1988 framing, is a **leading activity bit** with routing gated on it. It had to be decided **before D3.5's refinement statement is written.** | Silicon's to make |
| — ✅ **RULED, 11:13** | **The serial frame leads with an ACTIVITY BIT, routing gated on it** — the 1988 practice, and the only way the element distinguishes idle from destination-bit-0. **And the refinement statement carries the no-conflict hypothesis VISIBLY.** JYH may override; until then it governs. | maestro |
| — ✅ **FIXED AND VERIFIED, 12:31** | `19df872`. Verified **the way it was found** — by enumeration over every legal configuration under the no-conflict hypothesis: **FIXED = 0 mismatches, OLD = 28**, and the originally reported case reproduces exactly. The frame now leads with the activity bit, so an idle input claims nothing and an unclaimed output drives 0 — **idleness propagates downstream as a zero activity bit, which is what makes the fix compositional rather than local.** Cost: 8 cells/95.09 µm² → 18 cells/172.67 µm². | silicon |
| — **the loop, closed end to end in 100 minutes** | enumeration finds a live bug (compiler, 10:52) → recorded with the reason the proof could not catch it (evidence, 11:38) → ruled as a frame-format change with the hypothesis made visible (maestro, 11:13) → **fixed, and re-verified by the same enumeration that found it** (silicon, 12:31). **No human outside the fleet, and the outcome is a design decision rather than a patch over a symptom.** | — |
| — and the proof consequence either way | **The no-conflict hypothesis must be visible in the refinement statement even though the conflict *logic* is unnecessary.** An FSM certificate that never exercises the conflict path while claiming to refine `line` **is the `sp1-lean` failure mode precisely.** | compiler seat |
| A statement-level vacuity in a landed exit | W1's gcd exit is vacuous on the entire top gcd class; N7 sums over exactly those `s` | math seat's statement audit (`c4303b8`) |
| Two O(g²) evaluators published as linear | `runP`/`runS` extend the environment with `env ++ [..]`; measured curve is g², not g. At D4's scale the linear law predicts ~6.6 s against a real ~40 s | compiler seat, **refuting its own earlier 100× claim as a probe artifact** |

**Every one of these was found by a seat attacking work — its own or a
peer's — under a discipline that requires the attack before the build.
None was found by a kernel, and none would have changed an axiom count.**

### READING THE SOURCE — what it corrected, in both directions

⚠️ **This section was titled "errata found in the literature" and that was a
flattering half-truth.** Reading Heath-Brown 1983 at the bytes has now
**corrected the paper twice and corrected US once** — and the math seat
said so unprompted at 11:33, which is the only reason the third row is
here. A section that recorded only the errors we found in someone else's
work would be exactly the distortion this file keeps catching elsewhere.

**Their framing, and it is the right one:** *"reading the source has now
corrected the paper twice and corrected us once, which is a better argument
for reading sources than any of the three findings individually."*

**Running tally, math seat, 11:44: the source has corrected HB TWICE and
corrected US TWICE.**

**The two that were OURS:**

| The defect | Why it mattered |
|---|---|
| `fab7a8a` — our transcription printed (5.14)'s subscript as a **single** sum over `w₁`. HB prints the `i`-indexed form: a **double** sum over `w₁` *and* `w₂`, which is also what (5.19) sums over. | **The index we dropped is `w₂` — exactly Lemma 10's summation variable** (`n ↦ w₂`, `k = Dδ₁w₁`, `E = S₂`). Our notes hid the one index the entire §7 machine runs on. An executor working from them would have been confused by precisely the thing they most needed. |
| `409e227` — our notes had the `C_i` bounded *"≪ 1 uniformly in q, t, σ"*. **HB's p.220 continues: "but not necessarily in `α`."** | ⛔ **A Lean statement asserting uniformity in `α` would be FALSE** — an executor working from the notes alone could spend an entire wave proving something untrue. **Moot for twins** (`α₁ = α₂ = 4` is fixed) but it must be **stated, not silently relied on**: HB separates *"independent of `d`"*, which the argument uses, from *"not uniform in `α`"*, which it survives only because `α` is fixed. **This is the sp1-lean genre at its purest — a wrong specification, faithfully transcribed, that a proof assistant would have rejected only after the work was done.** |

**The two that were the PAPER's** — found *by checking, not by reading*:

| # | The erratum | How it was found | Weight |
|---|---|---|---|
| 1 | **(5.5) has a hole at `v₂(q) = 3`** | WEIL-TRIO seat, pre-flight against the source | moot for twins |
| 2 | **`S₁ ≪ x^{1/4}` is printed where `x^{1/2}` is meant — twice in one sentence** | math seat, reading p.214 at the bytes (`b25d8aa`, 2026-08-06) | ⛔ **directly on the twin-prime critical path** — (5.19) is what §6 consumes |

**What makes #2 worth publishing rather than filing:**

- **The paper refutes its own sentence one line later.** HB's next display
  substitutes into `(S₁S₂ + S₁² + x + xS₁/S₂)·S₁^{ε−1/4}` and prints
  `(x^{3/8}S₂ + x^{7/8} + xS₁^{−1/4} + x^{11/8}S₂^{−1})x^ε`. Solving each
  substituted term for the θ it presupposes gives **θ = 1/2 three times**,
  and **none is consistent with 1/4**.
- **As printed, the typo emptied the regime** — it forces
  `S₁S₂ ≪ x^{3/4}` against a required `≫ x^{15/16}` — **which is exactly
  what made it look as though *our transcription* was defective.** A
  formalisation that trusted the paper would have hunted for a bug in
  itself, indefinitely, and found nothing.
- **The proviso turns out not to be needed at all.** With both at
  `x^{1/2}` the regime is non-empty, and term by term in exact rationals
  only one of four constraints binds. So `S₂ ≪ x^{1/4}` is not merely
  mistyped — **it is superfluous.**
- **And the record was reconciled without blame:** the WEIL-TRIO seat's
  §D6 had the mathematics right but described it as a defect in *our*
  transcription. Both records were corrected in place.

⟨README: this is among the strongest arguments the campaign can make, and
it costs nothing to state plainly — **provided all three rows go in
together.** *"Formalising a paper found two errors in the paper, and one in
our own transcription of it."* The third clause is what makes the first two
credible; without it the claim reads as scoring points off Heath-Brown,
which is neither true nor the interesting result. Not because the authors
were careless — because a proof assistant cannot skim, and neither can a
seat told to check rather than read. **The method caught the paper and it
caught us, by the same act.**⟩

**Remaining owed from this block:** item 3 of the original three,
`(log Kk)³ → (log 2k)³` (a bounded conversion worth ≤ 2.39), still owed by
N7; and ADDENDUM A's open check on (7.8)'s log exponent (above).

**And the finding changed behaviour, which is the part that matters.**
Within an hour the math seat re-read §7 *at the source* rather than at the
notes, giving the reason explicitly: *"my §7 map was built from a
transcription, and hours later that same transcription's §5 turned out to
sit on two errata in one printed sentence."* **One erratum discovered ⇒
everything derived from the same transcription gets re-read.** Result
(`c470f52`): (7.1)–(7.7) verify clean, and §7 cites exactly **one** external
result *at the paper itself* — confirming the dossier's headline at the
source rather than at the notes.

⚠️ **AND ONE OPEN ITEM THAT MUST NOT BE LOST**, recorded here because it
has a gate rather than an owner: the notes give (7.8) with `(log 2k)³`
while the printed (7.8) appears to carry the **first power**, the cube
arriving only in the p.223 combination. The math seat is explicitly **not**
calling it a finding — the page image is not sharp enough — and the
difference is safe in our direction. But the freeze rules that Lean
statements carry `d(k)³(log 2k)³` **literally**, so **the exponent must be
confirmed against a clean copy BEFORE it is frozen into a statement.**
*An unresolved reading that is safe today becomes a wrong theorem the
moment it is written down.*

**An instrument that cannot distinguish UNTESTED from WORKING would have
rated all three green.** That is why every tool in `docs/ledger-tools/`
reports what it did *not* check, and why the fleet-hygiene detector says
"not yet proof the cap binds — only proof this run has not tested it"
rather than a green tick.

### ⚠️ AND THE PRINCIPLE CUTS BOTH WAYS — a correction to this record

The rule is **name the narrower question**, not **distrust the
instrument**. A record that lists only what a tool *cannot* do is itself a
narrower question presented as the whole one — which is the very failure
this section exists to name. So, on the same day:

**`#audit_axioms` earned its keep, measurably.** On leg 2's T1 commit a
first attempt left an incomplete step, and the build-failing assertion
**caught `sorryAx` in `run_filter` and `opt_sem`** rather than shipping a
green-looking file *(compiler seat, 11:50)*. It is **necessary and not
sufficient** — and it is **fully sufficient for the failure it targets**,
which is precisely why it belongs in the stack rather than in the bin.

The honest formulation, sharpened by the math seat (10:58) and the one to
publish:

> **Sufficient for its own failure mode, and structurally blind to the
> adjacent one.**

`#audit_axioms` caught `sorryAx` before a green-looking file shipped —
**the instrument working perfectly at the thing it targets**, the
incompleteness of a proof. That is *precisely why* it is silent on the
adjacent class: W1's statement-level vacuity, two O(g²) evaluators
published as linear, a routing bug at a port the hypothesis never
constrained. The error is never the instrument. It is the substitution.

⟨README: this is the strongest thing the campaign produced on day 1 and it
was not planned. It belongs in §4 beside the seam doctrine, because it is
the seam doctrine's own epistemology — *name the narrower question* — and
because it arrived by the fleet operating rather than by anyone
theorising.⟩

---

## CONVERGENT FINDING — the fleet found the same missing instrument three times

On 2026-08-06, within about one hour and without coordinating, three seats
arrived at the same conclusion from three different directions:

| Seat | Route | The finding |
|---|---|---|
| **evidence** (08:55, `bed5ed9`) | distilling the EF's `sp1-lean` audit into the Slice-A kill-checks K1–K3 | 62 announced opcodes, 51 real: one theorem *vacuously true*, four proved against the wrong specification, three with no theorem at all. **The claim table must be generated from the artifact, never hand-written.** |
| **silicon** (10:47, `026f27f`) | attacking its own design freeze | **"Three axioms end to end" is invariant under every failure mode that threatens the chain** — wrong file imported, port mis-parsed, cell mis-modelled all still print three axioms. |
| **math** (10:12) | tasked to audit the WEIL-TRIO exits | a statement-audit delta doc, explicitly *"the instrument an axiom audit cannot be"* — vacuity lens, junk-value edges, and the range where each bound is actually non-trivial. |

**The shared conclusion: an axiom audit certifies the proof, not the
statement, and the failure modes that actually threaten a verification
campaign live in the statement.** `#audit_axioms` is necessary and it is
not sufficient. What closes the gap is the second instrument — statement
auditing, generated coverage tables, vacuity witnesses, and differential
testing against an independent model.

This is worth publishing precisely *because* nobody planned it. Three
seats, three domains, one instrument missing from all three — and the
campaign's own discipline surfaced it on day 1 rather than in a postmortem.

### And then the instrument was RUN, the same morning — this is the part that makes it evidence

Math's WEIL-TRIO statement audit (`c4303b8`,
salt `docs/exploration/weil-trio-audit-0806.md`, 10:26) is the first
execution of it. **Verdict: no 🔴, no 🟠 — the landed W1, W4Q and W3 exits
deliver what the freeze promised**, and the two riders that matter are met
at the bytes (no `IsUnit` on any exit-interface statement; the gcd factor
never absorbed). *Clean, reported as loudly as red would have been.*

**And it still found three classes of defect that an axiom audit cannot
see, because none of them changes an axiom count:**

| Grade | Finding | Why `#audit_axioms` is blind to it |
|---|---|---|
| ⛔ | The W1 gcd exit is **vacuous on the entire top gcd class** — at `j = e` the bound `2p^e` is strictly *worse* than trivial for every p and e. Intrinsic to Estermann's shape, but N7 sums over exactly those `s`, so **N7 owes an explicit `j = e` case split falling back to the trivial bound.** | A vacuous-but-true theorem has a perfectly clean axiom set. This is the `sp1-lean` `SLTI` failure mode, found by the same lens, in our own corpus. |
| 🟡 | A module **docstring** states a hypothesis in a form that provably *cannot elaborate*; an executor reading the consuming file's header first — the natural move — would build an object that does not typecheck against the exit. | Docstrings carry no axioms. This one has a direct route to a wasted wave. |
| 🟡 | `HasTwoFormGcdBound q f` is **content-free at q = 0** (true for every f) and undocumented. | A degenerate instance is still a proof. |

Plus a distinction worth adopting fleet-wide: one finding was graded 🟡
rather than 🟠 **because the design freeze had asked for the weaker
disjunction — "the weakness is in the freeze, the delivery is faithful."**
Grading a defect against *who owns it* keeps an audit from punishing a seat
for obeying its brief.

**So the claim is no longer "we think statement auditing matters." It is:
we built the instrument, ran it once, and it immediately returned a
vacuity, a wasted-wave hazard and a degenerate predicate — none of which
would have moved an axiom count by one.**

⟨README: this belongs beside the `sp1-lean` citation in §9, and it is a
stronger argument than the citation alone, because it is ours and it is
dated.⟩

---

## OPEN RULINGS OWED

| # | Question | Owner |
|---|---|---|
| 1 | The public repo's **name** and its Apache-2.0 / public status (contractually mandatory for TinyTapeout) | JYH |
| 2 | The README verb in the price exhibit — "bought access to" until submitted *and* accepted | JYH |
| 3 | ⛔ **ESCALATED — the `lean -M 12000` cap is ALREADY LIVE on the wrapper's `*.lean` audit branch and is STILL UNVERIFIED.** Math's 10:35 concern is specific and serious: `-M` is enforced *inside Lean*, which is why it survives Darwin's rlimit gap — but a `decide +kernel` runaway lives in **kernel `whnf`**, which may not sit on the allocation path Lean's counter checks. If so, the cap is a **second no-op adopted on top of the first**, and the fleet is protected only in belief. **THE TEST IS NOW SAFE — math redesigned it at 10:58 after the compiler seat rightly refused the first version.** *"You do not need a big probe. You need a small cap."* The binding question is a **yes/no about a mechanism** — does Lean's `-M` counter observe kernel `whnf` allocation? — and mechanisms do not care about scale. So: a **~300 MB `decide +kernel` probe against a `-M 100` cap**, seconds to run, killable instantly, **~1% of the risk of the original**. (a) dies with a Lean maximum-memory error → the cap is real, ruling closes; (b) sails past → `-M 12000` is **cosmetic for `decide`-shaped work**. A pass at 100 MB is evidence, not proof, that it binds at 12 GB — but **(b) would be conclusive in the direction we are exposed to.** Math runs it at 20:00 when their Lean pause lifts, ahead of TS-1, unless compiler takes it first. | math or compiler to test, maestro to rule |
| 5 | ⛔ **The shared netlist type has NO writer slot** — `SEATS.md` gives HDL to compiler and Silicon to jason, so the type **both legs must import may be created by neither**, and both seats have been filling the vacuum privately. **This is now the single thing gating leg 2's EmitN.** Compiler's request: a third slot (`SaltWorks/NF/**`), owned by one seat with the other read-only, and they recommend it live with **Silicon** since that copy is already landed and proved and needs only the output-list repair — *"I would rather import theirs than compete with it."* | maestro |
| 4b | ⛔ **"Equivalence per module" has no modules** — post-P&R netlists are one flat module (measured, three real submissions). **First answer, offered by silicon at 12:31 for refutation rather than adoption: decompose by COMBINATIONAL CONE, not by module.** A flat sequential netlist partitions at the flop boundary — every flop D-pin and every primary output roots a cone of pure combinational logic; those cones are certified and composed structurally. It is available whether or not hierarchy survives, and *"it is why my reflection theorem quantifies over a `List Gate` rather than over a module — it never needed the boundary."* ⚠️ **What is missing is the measured cone-size distribution for a real 4–5k-instance netlist, which decides whether this is a plan or a hope.** That measurement is next in silicon's queue, ahead of the importer. | silicon to measure |
| 6 | **Hub imports owed** — `SaltWorks.lean` imports only `SaltWorks.Banyan.SelfRouting`, so **the entire landed Silicon leg (5 files, ~750 lines, the reflection theorem and every `#audit_axioms` block in it) is outside the default build.** The green build currently compiles one file. Owed: `Silicon.Equiv.BitSliced`, `Silicon.Equiv.Columns`, `Silicon.Cells.Sky130`, `Tactic.AuditAxioms`, `Banyan.Facade`. | maestro (hub is MAESTRO ONLY per `SEATS.md`) |
| 3b | Whether the 09:22 no-Lean-until-20:00 order binds **only** the math seat or **all** heavy salt elaborations — salt has TWO live seats, and the second (CHAR-TRIO / WEIL-TRIO) is still elaborating `Salt/HB/*` files of the same weight class | maestro |
| 4 | Install `docs/EVIDENCE-README-draft.md` at the repo root, once its `⟨slots⟩` are filled | maestro / JYH |

---

## DO NOT QUOTE

Inherited from the leg-1 harvest and binding on everything published here:
never "13 waves" (it is 11, or 15 counting the morning); never the
night-hours framing (the unit is the silence window); never "259/259"
without its 2026-07-21 date and "content modules" scope; never a
percentage of the corpus described as axiom-audited (quote the 6,302 named
declarations and the 166 assertions); never the git author field as
evidence of authorship. Full list: salt
`docs/exploration/leg1-evidence-0805.md` §9.

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
| T1 `opt_sem` — the verified optimizer | ⟨IN FLIGHT⟩ |
| T2 `emitN_sem` — the netlist normal form | ⟨NOT STARTED⟩ |
| T3 the executable-certificate suite | ⟨NOT STARTED⟩ |
| T4 `banyan_circ` — the fabric as a `Circ` | ⟨NOT STARTED⟩ |
| T5 the fungibility exhibit (one spec, ≥3 implementations) | ⟨NOT STARTED⟩ |
| Sequential extension for the bit-serial switch element | ⟨IN FLIGHT — seam with Silicon to be agreed first⟩ |

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
   - ⚠️ **ENFORCEMENT IS UNVERIFIED.** Nobody has test-fired `-M` yet
     (math is under the no-Lean order until 20:00 and correctly declined
     to break it for an experiment). One run settles it: build a known-heavy
     file through the wrapper with `-M 4000` and confirm it dies with a
     Lean memory error instead of climbing. **Do not write the cap into
     the wrapper as "fixed" until that run exists.**

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
| 3 | Whether `saltbuild.sh` gets a per-process memory ceiling — via `lean -M`, **not** `ulimit` (see lesson 4), and only after one run verifies `-M` actually bites | maestro |
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

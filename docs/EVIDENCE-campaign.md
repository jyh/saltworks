# CAMPAIGN SCOREBOARD
### The running status of the triple. Maintained by the EVIDENCE seat;
### refreshed at least daily and at every close-of-board.
### **Last refreshed: 2026-08-08 09:20 PDT** (day 3, post-crash-relight;
### `date`-read, not composed). Seat-status lines age in MINUTES, not days.
###
### ⚠️ **THIS LINE WAS ITSELF TWO DAYS STALE UNTIL NOW** — it read
### *"2026-08-06 18:50 (day 1)"* while the file already carried a full DAY 2
### section beneath it. **A hand-typed figure that ages silently, in the file
### that warns about hand-typed figures that age silently, ten lines below.**
### *Recorded rather than quietly fixed: the countdown warning at §10 was
### written by this seat and did not generalise to the stamp beside it.*

**T0: 2026-08-05 22:02 PDT. Campaign window: ~Aug 19.
Silicon deadline: 2026-09-07 13:00 PDT.**

⚠️ **NO COUNTDOWN IS PRINTED HERE, DELIBERATELY.** This line used to read
*"(32 days)"*, which was correct at T0 and wrong every day after — a
hand-typed figure that ages silently, in the file whose own rule 3 says the
mechanically-knowable half should be generated rather than maintained.
**A date does not age; a number of days does.** Anyone needing the figure
computes it: `python3 -c "from datetime import datetime as d;
print(d(2026,9,7,13)-d.now())"`.

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
| **EmitV** | **LANDED — `74035a9`**, and **untrusted by design**: no `emitV_sem`, and the hole is written into the **module docstring** rather than the fence — *the round trip compares through a PORT CORRESPONDENCE, so a misconception shared by printer and importer passes.* The top-level contract is therefore pinned to **TT's validator, an authority outside this repo**. `withDead_needs_opt` records that `opt` must run before emission because Yosys deletes what is unused. |
| **T2 `emitN_sem` — the netlist normal form** | ⭐ **LANDED — `8c4f8d7`. LEG 2 IS COMPLETE: T1–T5 + sequential + T2, and `9/9 Built` — not `Replayed` — on this machine.** `emitN_sem [3 axioms]`; `fabric3_ssa [1 axiom]` puts the **72-gate 8×8 fabric** inside the emission precondition, so the theorem applies to the tapeout candidate rather than to a toy.<br><br>**THE INDUCTION IS FOUR CASES, and that is what density BOUGHT:** the explicit name of every net already *is* its positional index, so `emitN` is structure-preserving and **the general renaming lemma is never needed** — `Dense.lean`'s expensive proof is not made cheaper, *it is not made at all*. Silicon's `Netlist` was imported read-only and **cost leg 2 nothing**, exactly as the mathlib-free `679e60c` promised.<br><br>⭐ **THE `opt` TRAP GETS A THIRD ANSWER — the one `dce` already uses on itself: CHECK.** `emitPipeline` optimizes, **tests `ssa` on the result**, and falls back when `opt` has broken density; `emitPipeline_sem` holds on **both** branches, so **a bug in the check costs optimization and cannot cost soundness.** Translation validation one level up from where `dce` does it. The densifying renumber is still unwritten and is **named in-file with its price** rather than quietly implied to be done.<br><br>🧪 **NON-VACUITY MADE EXHAUSTIVE RATHER THAN ILLUSTRATIVE:** `Circ.ssa` has three conjuncts and **each has a kernel-checked circuit violating ONLY that one**, on which the two evaluators then genuinely disagree — `opt withMidDead` (density), `denseButUnordered` (fanin ordering), `outOfRange` (the port list). *A precondition with an unexercised conjunct is a conjunct nobody has shown is load-bearing.* | ⟨superseded — was **UNBLOCKED, 14:25** — the seat found it does not need the writer-slot ruling after all: **it can IMPORT Silicon's landed `Netlist` read-only** rather than create a shared type, which is what it recommended anyway (*"I would rather import theirs than compete with it"*). Approach: normalise `Circ` to **dense SSA** (gate *i* defines net `nIn+i` — its constructions already satisfy this, including the 72-gate fabric), after which the net translation to Silicon's positional convention is **the identity** and `emitN_sem` is a short induction. One dependency: it pulls Mathlib into leg 2 until Silicon's `import Mathlib` drop lands.⟩ — **the only remaining item in leg 2's theorem list** |
| **T4 `banyan_circ`** | **LANDED — `26353d2`.** Stated against the **stage structure**, since the freeze's version was unstateable: stage *m* resolves bit *m*, moving a packet from `line (m+1)` to `line m` — `SaltWorks.Banyan.step_line` in gates. Certificates at k=3 (72 gates): **routes** / **no-crosstalk** (*reachability is not routing*) / **claims-matter** (mutation control). |
| **Sequential extension** | **LANDED — `ef1e4a7`, `SaltWorks/HDL/Seq.lean`, first attempt green.** **ZERO new `Circ` constructors:** a synchronous machine is a **Mealy record over ONE combinational `Circ`** — core inputs are (this cycle's inputs, current state), core outputs are (this cycle's outputs, next state). **Registers are not a gate kind; they are the boundary where outputs feed back a cycle later.** So `Circ`, `sem`, `opt`, `opt_sem`, the bit-sliced certificates and `emitV` are **untouched and still apply to the core** — *the combinational theory does not fork*, which was the design goal. `runTrace` takes the initial state as an **argument**, so `∀ st₀` is quantifiable; `xorPrev_self_initialises` is the smallest instance of the self-init obligation power-gating imposes. |
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
| **D3 — comparator end-to-end equivalence, kernel-checked** | ⭐ **LANDED — `2e24205`. THE CHAIN CLOSES AT MODULE SCALE.** The gate netlist that came back from yosys+abc against the sky130 library computes **exactly the same function as the design on all 2¹⁶ input configurations, checked by the Lean kernel.** No `bv_decide`, no `native_decide`, no `sorry`. `comparator_sliced_eq` [1 axiom] is the certificate; `comparator_equiv` [3 axioms] is the pointwise statement a skeptic reads.<br><br>**Neither side is a strawman:** the imported netlist is **36 real sky130 cells over 12 types → 127 primitives**, *including the two `lpflow` power-isolation cells abc pressed into service as ordinary logic*; the reference is a ripple magnitude compare, **109 gates, deliberately a DIFFERENT STRUCTURE** from what abc produced — so it is a real equivalence, not a tautology.<br><br>**Affordable because every net carries its whole truth table as one `Nat`:** each netlist is evaluated **once** — 127 GMP ops on 65,536-bit numbers — and the comparison is a single list equality. `reflect`, proved once generically, is what makes that a statement about *pointwise behaviour* rather than a fast computation.<br><br>**NON-VACUITY VERIFIED THE WAY IT MUST BE:** mutate one gate in the imported netlist (`.and 6 20` → `.or 6 20`) and the certificate **FAILS** — `decide` rejects it, `#audit_axioms` catches `sorryAx`, `saltbuild EXIT=1`. Restore and it is green. *A certificate without that control can be vacuous and still audit clean.* |
| **D3.5 — the bit-serial switch-element FSM refines `line`** | ⭐ **LANDED — `0f4c6d7`.** The tapeout element's **real gate netlist, flip-flops and all**, implements its spec for **every state and every input** (all 512 combinations, kernel-checked), lifted to arbitrarily many cycles by ordinary induction (`iterate_congr`). **Nothing scales with cycle count.**<br><br>⛔→✅ **THE BANNED TACTIC IS GONE.** ADDENDUM 1 justified D3.5 by *"the measured sequential pattern from the vlsi-flow dossier §A"* — and **that pattern is `bv_decide`**, which JYH banned the same day. Rebuilt on `decide +kernel`.<br><br>📐 **NO IMPORTER CHANGE WAS NEEDED — the cone census DEMONSTRATED rather than asserted:** at the flop boundary the four Q nets become **inputs** and the four D nets become **outputs**, turning the sequential element into a combinational function. **The flop boundary already IS the cone boundary.** 9 input bits, 512 configurations, two orders of magnitude inside the 24-bit ceiling.<br><br>✅ **TWO OF THE FIVE FRAME HYPOTHESES ARE DISCHARGED BY THE SHAPE OF THE STATEMENT, not assumed:** *self-initialisation* — the theorem quantifies over **all 16 states including those unreachable from reset**, the only honest form given TT power-gates unselected designs (*"assume reset worked" would be proving something about a different machine*); and *activity* — the activity bits are **part of the state**, so idle ports are **inside** the statement, which is exactly what the routing bug exploited when correctness lived only in `Set.InjOn` over the ACTIVE lines. The other three bind at the **fabric** and are stated where they bind.<br><br>🧪 Non-vacuity: mutate the spec's `out0` from `.or` to `.and` → build **FAILS**; restore → green. |
| **D4 — the fabric** | ⭐ **LANDED — `70e1ca1`. THE FABRIC ROUTES, KERNEL-CHECKED.** `elem_matches_spec` [1 axiom] — the functional element model agrees with the netlist-level spec on **all 512 configurations**. `fabric_routes` [1 axiom] — **for all 255 sorted+concentrated destination sets, every payload arrives on the line its address names and every unaddressed line stays idle.**<br><br>**COMPOSITION, NOT ENUMERATION — and the numbers make it not a preference:** the flattened fabric's output cones reach 36 inputs (8.6 GB per sliced net) and the monolithic state space is 56 bits (~9 PB). ***Enumerating the fabric is not slow, it is impossible.*** One element proved once (D3.5), twelve instances composed by topology, the composite exercised on concrete frames — *concrete runs cost nothing because there is no quantification over the 56-bit state, just evaluation.*<br><br>⭐ **AND THE MUTATION CONTROL IS THIS MORNING'S ACTUAL BUG.** Put back the shipped `(if s0 then i1 else i0)` — the exact line refuted at 10:52 — and **both theorems fail**: `decide` proves the proposition FALSE and `#audit_axioms` catches `sorryAx`. **THE D4 CERTIFICATE WOULD HAVE CAUGHT THE ROUTING BUG**, and the defect is now a **permanent regression test, in the kernel.** *(RTL had landed earlier at `002abc1`: 259 cells, 2,108 µm².)* | The full 8×8 bit-serial banyan exists and synthesises: **259 cells, 2,108 µm², 21 cell types, 52 flops** (12 elements × 4 + a 4-bit frame counter) — **11.8% of ONE tile, 2.9% of the four bought.**<br><br>**The certificate is per-element + STRUCTURAL COMPOSITION** — twelve instances of D3.5's landed `switch_step_eq` (9 inputs each) wired by the topology, **not one enumeration over the fabric.** *Always the plan; now measured as not-optional* (see ruling 4c: the flattened fabric's `dout` cones reach 36 inputs = 8.6 GB per sliced net). |
| ⭐ **THE SUBMISSION GATE — OPEN, 2026-08-06 19:12** | 🟢 **THE GDS ACTION IS GREEN, ALL FOUR JOBS**, run `31138909555`, `main`, sha `8144b6ec`: `gds` ✅ · **`precheck` ✅ (the blocking DRC/pin/boundary/power gate)** · **`gl_test` ✅ — the 255-scenario bench against the POWERED post-layout netlist, the same 255 sets the Lean kernel proof quantifies over** · **`viewer` ✅**, red all evening and green the moment the repo went public. `docs` ✅ `test` ✅ on main too. Artifacts include `tt_submission` (1,279,607 B) and a real `github-pages` artifact — *evidence `viewer` did its job rather than merely exiting 0.*<br><br>⭐ **AND THE RUN THAT SETTLED IT WOULD HAVE BEEN THROWN AWAY BY THE COARSE RULE.** Created **01:42:58Z, 21 minutes BEFORE the 02:04Z visibility flip** — but **every job started AFTER it**, `gds` by fifteen seconds. **Run-creation time was the wrong boundary; job-start time was the right one**, and the coarse version — *"this run predates the fix, ignore it"* — would have discarded the evidence. *The refinement was made an hour before the answer arrived.*<br><br>**A BEFORE/AFTER WITH THREE BEFORES:** same workflow, same branch — `1e0eb377` ❌, `f9a8ca06` ❌, then `8144b6ec` ✅. Failing three times while private, passing on the first execution after the flip. *Stronger than the green alone.*<br><br>✅ **AND IT REPLICATED ON HEAD, 19:18 — the first qualification is DISCHARGED.** Run `31140274735`, sha **`f14a4fa1`**, confirmed against the API as `main`'s current HEAD: **`gds` ✅ `precheck` ✅ `gl_test` ✅ `viewer` ✅**, every job started 02:08–02:13Z, all after the flip. ⇒ **TWO consecutive fully-green runs on `main`, at two different shas, both executing entirely post-flip.** *A single green is a reading; two at different commits is a replication — and the three reds beneath them are the control.*<br><br>⚠️ **ONE THING THIS IS STILL NOT.** ~~(1) Not on HEAD~~ — discharged above. (2) ⛔ **NOT A SUBMISSION.** *Payment is not submission — and neither is a passing action.* The honest verb stays **"€280 bought access to a shuttle"** until a revision is submitted **and accepted**. What tonight establishes is that **the gate blocking submission is no longer blocking it.** What remains is human clicks with a card, ending in **"Submit a new revision" — the click that is NOT the payment**, and the most likely way this ends badly. |
| **D5 — TinyTapeout TTSKY26c submission** | **TREE LANDED, NOTHING SUBMITTED** (`2723c40`, `7f56714`, `aa40fcc`). The submission tree exists and is exercised: **validator 5/5 with 10/10 negative controls**, **bench 3/3 with 255/255 against real sky130 cells**, submission checklist separating *prepared* / *owed* / *the human's clicks* (H1 closed — 4 tiles bought).<br><br>✅ **The PDK-revision worry closed BY MEASUREMENT, not by argument** (`aa40fcc`): **4,868 files differ between the revisions in play and none of them is one our chain reads.**<br><br>⚠️ **TWO OPEN ITEMS THAT CHANGE WHAT GETS SUBMITTED, stated rather than assumed:** (1) `tools-ref` is a **floating branch** — `gds.yaml` pins only the action — and **it moved on 8/6**, so two CI runs days apart are not comparable *(which is exactly confound 5.2 of the `(* keep *)` design)*. (2) **THREE PDK revisions are in play**: `0536d02d…` precheck-only, `8afc8346…` hardening, and **`c6d73a35…`, which is what `synth.sh` pins and therefore what the local netlist under proof was built against — neither of TT's.** Harmless for an untrusted dev netlist; **not harmless the moment a cell model written against one revision certifies a netlist built by another**, and whether our ~30 cell models are revision-invariant is **NOT yet checked**. |
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

  ✅ **SUBMITTED 2026-08-07 ~10:45 — H5–H8 completed by the Captain.**
  `tt_um_saltworks_banyan` is **in the TTSKY26c queue**: DRC zero at two
  engines, precheck 15/15, `fabric_routes` in the kernel. **The tile is a
  2×2.**

  ⏳ **AND THE VERB MOVES ONLY HALF A STEP, WHICH IS THE WHOLE POINT OF
  HAVING WRITTEN IT DOWN IN ADVANCE.** The fence said *submitted **and**
  accepted*. **Submitted: yes. Accepted: not yet** — it awaits the
  **2026-09-07** shuttle close. ⇒ **The honest verb today is "submitted to
  a shuttle", still not "fabricated".** *A queue position is not a chip,
  and the gap between them is a month and a foundry's decision.*

  ✅ **UPGRADED 2026-08-07 12:35 — THE SUBMISSION IS NOW MACHINE-VERIFIED,
  NOT MERELY ATTESTED.** The shuttle API returns, unprompted, in the same
  payload as the tile counts:

  ```
  "mostRecentSubmission":{"name":"Verified 8x8 bit-serial banyan switch",
                          "repo":"https://github.com/jyh/tt-verified-banyan-switch"}
  ```

  **Our design, named, with our repo URL, reported by TinyTapeout's own
  service.** ⇒ *The click I said I could not verify is verified — by a
  source outside this fleet, found while instrumenting something else.*
  **The row below is kept as written**, because what it says about the limits
  of attestation was true when written and is the reason the upgrade is
  worth recording. ⏳ **Submitted ≠ accepted is UNCHANGED** — this confirms
  the submission, not the shuttle's acceptance.

  📌 **PROVENANCE OF THIS ROW AS FIRST WRITTEN, per the 07:46 source-tag law:
  REPORTED, not measured.** No seat can reach the TinyTapeout app; the submission is the
  Captain's act relayed by the maestro. **This seat verified the CI gates
  that made it possible** (GDS green all four jobs, replicated at two shas,
  three reds beneath as control) **and cannot verify the click.** *Recorded
  as attested rather than checked, because the difference is exactly what
  this file exists to preserve.*

---

## THE TAPEOUT CLOCK

| Date | Event |
|---|---|
| **2026-09-07 13:00 PDT** | **HARD DEADLINE** (20:00 UTC) — no revisions after |
| by 2026-08-31 | target: a real revision submitted, one week of slack |
| ⛔ ~~2027-03-27~~ | ~~chips expected~~ — **UNSOURCED.** Read at source 2026-08-07 11:52: the runs table **has** a `Chips expected` column and **TTSKY26c's cell is EMPTY**; the API carries no fab date either. **This figure has no source on the public page today.** Marked rather than deleted, so whoever entered it can say where it came from |
| **2027-05-12** | estimated delivery — ✅ **CONFIRMED at source**, `tinytapeout.com/runs/`, verbatim |

**Shuttle capacity, read at source 2026-08-07 11:52: `"total":512,"available":202` —
down from 222 on 2026-08-06, of which OUR submission is 4.** PCBs are at
`"available":0` of 80, a different scarcity nobody has been tracking.
⚠️ ~~**At ~20 tiles/day the 202 remaining last about ten days against a close
31 days out** — BB-1's revision plan assumes a September slot exists; on this
slope the shuttle may fill first.~~ *A schedule risk with a measured rate rather
than a worry.*

## ⛔⛔ THAT RISK IS REFUTED — RE-READ AT SOURCE 2026-08-08 09:41, AND THE ERROR WAS MINE

```
app.tinytapeout.com/api/shuttles/ttsky26c
2026-08-06         222 available
2026-08-07 11:52   202              −20 in ~1 day    → the slope I published: ~20/day
2026-08-08 09:41   200              − 2 in 21h49m    → 2.2/day   ⬅ NINE TIMES SLOWER

PUBLISHED   202 ÷ 20/day  ≈ 10 days of capacity vs a 31-day close  ⇒ SHUTTLE FILLS FIRST
MEASURED    200 ÷ 2.2/day ≈ 90 days of capacity vs a 30-day close  ⇒ IT DOES NOT
```

🔑 ***THE DEFECT: I computed a RATE FROM ONE INTERVAL and published it as a
SLOPE.*** **Two points define a line only if you assume the line — and that
single interval contained OUR OWN 4 TILES, so this seat was part of the burst it
extrapolated from.** *Same family as every other Day 3 miscount: the arithmetic
was right and the object was wrong.*

⚖️ **DECISION IMPACT, stated because it moves a docket item: *B5's revision plan
is NOT capacity-constrained.* The binding constraint is the 2026-09-07 date
alone.** *If B5 was deferred on scarcity grounds, that ground is gone; the REF
QUESTION and the floor law are untouched and this seat says nothing about them.*

⚠️ **AND THE REPLACEMENT IS NOT ANOTHER ONE-INTERVAL SLOPE — 2.2/day is also two
points.** ✅ **The honest form is a BOUND: three readings, monotone down, total
drawdown 22 tiles in two days against 200 remaining. *Whatever the true rate, it
has not been within an order of magnitude of exhausting the shuttle.*** *Re-read
before the close; the invocation is one line above.*

⏳ **AND OUR MACHINE-VERIFICATION HAS EXPIRED AT THE SOURCE.** *On 08-07 12:35
the API returned `mostRecentSubmission` naming our design and repo. On 08-08
09:41 that field reads `"Acoustic Interferometer"`.* 🔑 ***It was a snapshot of a
MOVING field. The submission is not less verified — but that verification cannot
be re-derived from that source today, and the only reason it still counts is that
this record quoted it VERBATIM WITH A CLOCK.*** **Had it been paraphrased it
would now be unfalsifiable** — [[pre-register-the-criterion]] Amendment 2, *some
measurements have a deadline*, arriving independently in the TT data.

📌 **Also re-read 09:41: `"chips expected"` now displays `"Open"` where it was an
EMPTY cell on 08-07.** *Still no date, so the struck `2027-03-27` stays unsourced;
the estimated delivery `2027-05-12` is confirmed at source a second time.*

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

**Day 1 — DO NOT READ NUMBERS FROM THIS FILE.** They were hand-copied once
at 09:50 and were wrong by lunchtime: output tokens had nearly doubled and
engaged time had more than doubled. Applying this file's own rule to
itself, the numbers live in the generated ledger and are regenerated by:

```sh
sh docs/ledger-tools/nightly.sh     # → docs/EVIDENCE-ledger-<date>.md
```

A snapshot, **stamped and superseded by the file above**, T0 → 11:35:

| Quantity | as published 09:50 | **artifact of record** | now (11:35) |
|---|---:|---:|---:|
| API requests (deduplicated) | ~~2,752~~ | **2,763** | 4,435 |
| Output tokens | ~~869,114~~ | **880,785** | 1,601,367 |
| Cache created | ~~18,941,186~~ | **18,962,346** | 26,599,778 |
| Cache read | ~~344,638,099~~ | **347,054,453** | 739,897,878 |
| JYH engaged time (floor) | ~~2 h 04 m~~ | **not reproducible at any window** | 5 h 03 m |
| Commits inside a ≥1 h silence window | 0 | 0 | **0** |

⛔ **The struck column is the finding.** Those four numbers **appear in no
committed artifact.** `git log -S'869,114'` returns exactly one commit — the
scoreboard itself. They were a real meter run at ~09:50, superseded a minute
later, surviving only in a commit message; the artifact of record says
2,763 / 880,785. And the engaged-time cell was worse: **2 h 04 m is not
reproducible at any window boundary**, and its "5 DIRECTING, 1 WATCHING"
counted the whole tags file including two blocks that precede T0.

**The aggravating fact, which the audit put better than I would have:**
this file's own rule — *"the claim table must be generated from the
artifact, never hand-written"* — sits **~320 lines below** this
hand-written table. I wrote the rule and then broke it in the same
document.

*(Mitigating, and recorded because the audit insisted on recording it: the
drift was **self-deprecating** — I under-reported the fleet's own spend by
~1.3%.)*

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

**A sixth, measured after the fact and worth more than the four above it:
THE DECOMPOSITION IS NOT OPTIONAL, AND THE MARGIN IS 9 PETABYTES.**
Silicon measured the bit-slicing memory law (`33a28c2`): slice footprint
≈ **#nets × 2ⁿ / 8 bytes** atop a ~670 MB baseline, confirmed at n=16
(670 MB, lost in the baseline) and n=24 (869 MB, where the predicted
120 MB shows). Applied to a **monolithic** fabric certificate: 8 inputs
+ 12 elements × 4 state bits = **56 bits — one net of 2⁵⁶ bits ≈ 9 PB.**
Applied **per cone**: every cone in the switch element has ≤ 6 inputs, so
64 bits per net and **the whole fabric's certificate suite is kilobytes.**
*9 PB against kilobytes is the entire argument for the cone decomposition,
and it is now measured rather than argued.*

⚠️ **And the seat corrected its own number in the same post.** The earlier
figure was 2 TB, at 44 bits — 3 state bits per element. **Fixing the
routing bug added the activity bit, taking each element to 4**, so the
correctness fix made the monolithic route **~4,500× worse**. A defect
repair that quietly enlarges a downstream cost is exactly the kind of thing
that gets discovered at the wrong moment; this one was measured and posted
within the hour.

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

## THE DAY-1 PRINCIPLE, IN ITS FINAL FORM

The math seat stated it at 13:11, after the day had produced enough
instances to earn the generalisation:

> **Every instrument we added today can report success it has not verified**
> — an unbreached memory cap, a green build, a clean axiom set, a piped
> exit code, an unmutated numeral.
>
> **The ones we caught, we caught by asking what the instrument would say
> if the thing it watches were broken.**

That second sentence is the method. It is not "be careful"; it is a
question with an answer, askable of any instrument before you trust it —
and every catch in this file came from asking it:

| Instrument | *What would it say if the thing it watches were broken?* |
|---|---|
| `#audit_axioms` | *"Three axioms."* — it says that for a false theorem too |
| an unbreached `-M` cap | *"No breach."* — it says that when nothing tested it |
| `saltbuild EXIT=0` through a pipe | *"Success."* — it says that for a crashed build |
| a certificate at full load | *"Passes."* — it says that when the hypotheses force `dest = id` and nothing moves |
| two of our own records agreeing | *"Consistent."* — it says that when both inherit one bad transcription |

**A false negative wastes time. A false positive corrupts the record — and
this fleet's central claim IS a record.**

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
| ⛔→🚫 **`#audit_axioms` ITSELF — RETRACTED, AND THE RETRACTION IS THE BETTER ROW** | ~~does this theorem EXIST?~~ | **This row was WRONG for two hours and it was the sharpest thing in the table, which is exactly why it survived.** The 14:04 claim — *"it printed `✓ [0 axioms]` for two theorems that had NOT ELABORATED"* — **is false.** Silicon re-tested their own landed finding against **six deliberately-broken theorems plus a control**: every break yields either `error: Unknown constant …` (elaboration aborted ⇒ the name never enters the environment) or `sorryAx` non-whitelisted (elaboration recovered ⇒ the declaration carries it). **Not one tick for a broken theorem, and there is no third state.** What is real is a **reading hazard, not an instrument defect**: info messages emitted before an error still print, so `#audit_axioms A B` with `A` good and `B` failing shows `✓ A` above an error. *(silicon, `2723c40`, `docs/silicon-auditaxioms-e1-0806.md`.)* |
| ⭐ **AND THE ROUTE THE FALSE CLAIM TOOK IS THE FINDING THAT REPLACES IT** | — | **A true narrow claim was replaced by a false total one, and the false one was more quotable — so it travelled from a bus post into the README in 26 minutes, through the seat whose entire job is to stop that.** Mine. It rhymed with four true findings from the same afternoon, which is precisely what made it frictionless. **The rule it yields: a claim whose stated mechanism cannot happen has not been established, however plausible its conclusion** — and the mechanism here was refutable *by reading twelve lines of the instrument being accused*. **This table's own genre, committed by this table.** |
| **agreement between our own records** | do the notes and the Lean **say the same thing**? | **is either of them RIGHT?** ⛔ `hbKappa`'s docstring reproduces the notes *verbatim* and its body matches term for term — **and that is not corroboration, because the Lean was DERIVED FROM the notes.** *Any mis-transcription in the notes is inherited by the kernel definition exactly.* **Two records with a common ancestor agreeing is one record, counted twice.** *(math seat, `c1985d8`)* |
| **the circuit DSL's declared `sem`** | what appears at the **primary outputs**? | **does the fabric route?** ⛔ The freeze asked for *"`banyan_circ` + proof its `sem` realizes line-routing"* and **that is unstateable**: `sem` exposes only stage boundary m = 0, where `line 0 s d = d` holds for every source and destination **with no hypotheses at all**. A `sem`-only theorem cannot see internal link occupancy — **which is the entire content of `no_conflict`.** *(compiler seat, 13:10)* |
| **a silence window in the ledger** | was any human **typing** in this stretch? | **was the human away?** ⛔ Not if the RECORD is missing. The laptop→Mini migration re-synced the repos and the kit before cutover but **not `~/.claude/`**, so the transcript record stopped at **14:07:56** while git carried work to **14:30:08** — and the ledger read the difference as **the campaign's longest silence window (0.9856 h), 82% of which is unrecorded rather than measured.** Charter §E modelled *unobserved ≠ silent* only for commits **predating** the record; a hole in the MIDDLE had no detector. **Closed by a rule needing no new data: a commit is made BY a session, and a session writes records.** *(evidence, `52b963e` — calibrated over 862 commits, and it fires once while clearing all 715 leg-1 commits in the same pass.)* |
| **`swap free`, on a machine that has never paged** | how much room is left in the swap FILE? | **is the machine under memory pressure?** ⛔ macOS grows that file on demand, so a healthy Mini reports `total = 0.00M  used = 0.00M  free = 0.00M` — and my `< 2 GB free` alarm raised **its loudest warning for the healthiest state it can observe.** The laptop had long since grown a swap file (37 GB in use at OOM #2), so `free` was non-zero and the defect **could not fire there**. ⭐ **THE HARDWARE CHANGE IS ITSELF AN INSTRUMENT TEST: a new machine is a new point in the input space, and it falsified a threshold that had been green all day for the wrong reason.** *(evidence, `aa2b75d`; the trigger is now `used`.)* |
| ⭐ **TWO DEFECTS THAT EACH MADE THE OTHER INVISIBLE** — and this is the one to publish | — | The seat-liveness detector's parser required `]` immediately after the seat name, so every `[8/6 13:58, math — \`date\`-verified]` post was **invisible** — **the seat that follows the fleet's own timestamp-hygiene convention most rigorously is the one it reported as most stale** (math read **3.4 h** when it was **0.2 h**; 26% of the bus unread). Its threshold, meanwhile, sits at **3.2× the largest inter-post gap that has ever occurred**, so it **could not fire whatever happened**. ⇒ **The loose threshold SUPPRESSED the alarm that would have exposed the parser.** A tighter one would have raised a false STALL on math at breakfast and the parser bug would have been found then. **Two defects, one file, both reporting green, neither discoverable from the output — only from a backtest.** *(evidence, `6a2b695`, `docs/EVIDENCE-liveness-backtest-0806.md`.)* |
| ⭐ **A GREEN DEFAULT BUILD** | are the modules **in this closure** kernel-checked? | **is the LEG checked?** ⛔ Only if the hub imports it. Found **twice in one day, from opposite sides, both self-reported**: silicon caught `FabricRoutes` sitting outside compiler's green 8,590-job build in the afternoon; compiler caught `Renumber` sitting outside the default build that evening — the default audits **89** HDL declarations against **120** for a targeted build, so **31 declarations were kernel-checked and simultaneously outside the default closure.** ⇒ ***A green default build is evidence about its own closure and about nothing outside it*** — and **the closure changes every time a seat lands a module the hub has not imported**, which is the normal case in an active repo. Compiler's phrasing is the one to keep: *"they ARE kernel-checked" and "the default build covers leg 2" are two different sentences and only one is true tonight.* |
| ⭐ **A NET-NAME GREP OVER A SYNTHESISED NETLIST** | does this **identifier** survive the flow? | **did the STRUCTURE survive?** ⛔ On the real TT artifact `wire [7:0] w0` is absent from **both** arms — `splitnets` deletes the parent vector and the survivors are `\fabric.w0[0]`…`\fabric.w1[7]` — while the cone census shows the boundaries are **fully intact and take the shipped netlist to 100% certifiable.** The name readout returns **the exact opposite of the truth, confidently**, and it is the readout a seat reaches for first. *(silicon, 18:36 — and the reason it did not land that way is that the experiment's readout had been **pre-registered as the census** hours before either arm ran. This is the campaign's cleanest argument that pre-registration is not bureaucracy.)* |
| ⭐ **A LANE GATE'S OWN DOCUMENTATION** | does this text contain the forbidden markers? | **is this a LEAK?** ⛔ A methodology post *about* the gate contains the markers by necessity and is not a leak. Fired four times in one hour — three on this seat's own prose, once on a peer's audit table — and the naive repairs are both wrong: loosening it creates false negatives, and a global override *"converts an explicit human call into a reflex"* (compiler, 18:12) which is a false-negative design in false-positive clothes. **Resolved structurally by a BASELINE rather than an override:** each adjudicated line is hashed, so judged text stops re-flagging while genuinely new marker text still blocks. |
| ⭐ **THE DIFFERENCE OF TWO INSTRUMENTS** | what do these two readings **differ by**? | **is that difference a PROPERTY OF THE WORLD?** ⛔ No — it is a property of the two instruments. Compiler's *"a cap of N permits N + 309 MiB"* came from subtracting `ru_maxrss` from the cap a run died at, and **inherits the error of both readings while being checkable against neither.** Silicon **bracketed the threshold directly, by moving the cap until it flipped** — `C* ∈ (8400, 8410]` against RSS 8407, a 10 MiB kill on an 8.4 GiB run — *a method that needs no theory of what the counter counts.* **`E ≈ 0`.** Compiler accepted it without qualification and named the methodological half themselves: ***"my 309 was never a measurement at all."*** *(17:03–17:04 — and it is the day's cleanest refutation because the refuted party supplied the criterion that killed it.)* |
| **a plausible mechanism named in a bus post** | does this **explanation** fit the observation? | **did the mechanism actually happen?** ⛔ `maxMemory` was proposed as the `[leanOptions]` route on the strength of one standalone symbol in the Lean binary beside `maxHeartbeats`/`maxRecDepth` — flagged by its author as *evidence, not proof*. One line settles it: `set_option maxMemory 900 in …` → **`error: Unknown option \`maxMemory\``.** **The evidence pointed the wrong way and the one-line test said so**, which is also how silicon's E1 fell. *(compiler, 16:30 — and math's 09:40 `moreLeanArgs` answer was right all along, still untested.)* |

---

## DAY 2 (2026-08-07) — four campaign-level facts, each with its verification status

**Recorded by the EVIDENCE seat as the day ran.** The status column is the
point: this seat verified some of these with its own instruments and could
not verify others, and the difference is preserved rather than flattened.

| Fact | Status |
|---|---|
| **THE BANYAN IS SUBMITTED** — `tt_um_saltworks_banyan` in the TTSKY26c queue, DRC zero at two engines, precheck 15/15, tile 2×2 | ⚠️ **ATTESTED, not measured.** No seat can reach the TT app; this is the Captain's act relayed by the maestro. **This seat verified the gates** — GDS green all four jobs, replicated at two shas, three reds beneath as control — **and cannot verify the click.** ⏳ **Submitted ≠ accepted**; the verb stays *"submitted to a shuttle"* until the 2026-09-07 close |
| **C3 FINALIZED — structural gate-level emission ratified, fallback (B) retired unused** | ✅ **Decision sound.** ⚠️ **Headline citation corrected on this seat's catch:** `100%` is *boundary survival*, `60.1%` is *cone coverage* — different quantities. Like-for-like the boundary comparison is **100% vs 66.7%**, which is what the ruling actually rests on. **The structural arm's cone-width census is still owed** and is the number C4 needs |
| **C2 WITNESSED — `step` agrees with Spike AND Sail on 120 kernel-checked vectors** | ✅ **VERIFIED AT THE BYTES by this seat.** Spike 1.1.1-dev at a pinned commit, built from source; Sail 0.20.2 + sail-riscv at a second pinned commit; `120 agree · 0 disagree · 0 skipped`. ⭐ **R2 checked independently: `SaltWorks.ISA.encode` appears in the generator four times, all four in the comment saying it is unused** — *the common ancestor was removed from the path rather than argued about* |
| **THE IMPORT CLOSURE REACHED ZERO** — 38 tracked, 38 in closure, 0 audit sites outside the default build | ✅ **VERIFIED by this seat's own instrument.** First clean run since `import-closure.py` was written; it had flagged `Renumber`, `ISA`, `CodegenSpec` and `Vectors` as each appeared. *"The default build covers all three legs" became safe to write at 10:24 and was not safe to write at any earlier point today* |

### CONVERGENT FINDING #3 — a refutation and its fix crossed in flight, one minute apart

**Not an adjacent-object failure — a method result, and the only one of its
kind so far.**

| | |
|---|---|
| **10:41** | compiler lands the compare-exchange element ordering **active before idle unconditionally**, before any address bit is examined |
| **10:42** | evidence, **not having seen it**, refutes BB-1's headline by reading `SelfRouting.lean:103`: `StrictMonoOn dest (Set.Iio n)` is **two conjuncts wearing one name** — sorted **and** concentrated — so a sorter discharges one |
| **same window** | silicon derives the identical *"idle sorts last"* convention **from the fabric side**, without coordinating |

**Three seats, three directions, one law.** And the mechanism that makes it
evidence rather than anecdote: **`ce_rejects_idle_sorts_low = false` — a
kernel refutation of the ordering that sorts correctly and destroys
concentration.** *Both orderings sort. Only one concentrates.* The
difference is a **theorem**, not a convention.

⇒ **This is the D4 mutation-control discipline run FORWARDS for the first
time** — applied to a design choice *before the design existed*, rather than
to a defect after it shipped. **The campaign's other convergences were three
seats finding the same MISSING instrument; this is three seats finding the
same REQUIRED property, and one of them proving it.**

---

⭐ **AND THE DAY'S BEST HOUR WAS A COLLISION.** At **10:41** the compiler
seat landed an element ordering *active before idle unconditionally*; at
**10:42**, not having seen it, this seat refuted BB-1's headline by reading
`SelfRouting.lean:103` and finding that `StrictMonoOn dest (Set.Iio n)` is
**two conjuncts wearing one name** — sorted **and** concentrated — so a
sorter discharges one. **One minute apart, opposite ends, same law.** And
silicon derived the identical *"idle sorts last"* convention from the fabric
side without coordinating.

**The certificate is what makes it more than agreement:**
`ce_rejects_idle_sorts_low = false` is a **kernel refutation of the ordering
that sorts correctly and destroys concentration.** *Both orderings sort.
Only one concentrates. The difference is now a theorem rather than a
convention* — the D4 mutation-control discipline applied to a design choice
before the design existed.

---

## DAY 3 (2026-08-08) — five campaign-level facts, each with its verification status

**Recorded by the EVIDENCE seat as the day ran, same discipline as Day 2: what
this seat verified with its own instruments is separated from what it could
not, and the difference is preserved rather than flattened.** *Day 3 opened
with the machine down — the 05:30 muster-prep window passed with no machine —
so every fact below is dated from an instrument rather than from an account.*

| Fact | Status |
|---|---|
| **THE OVERNIGHT HANG WAS A CONTROLLED EXPERIMENT ON DURABILITY, AND THE FLEET WAS ON THE RIGHT SIDE OF IT** — five executor files (111,423 B · 2,492 lines · 209 theorems) written 02:30:46 → 02:42:16 survived; results held only in a session died with it at 02:31 | ✅ **VERIFIED AT THE FILESYSTEM by this seat.** mtimes to the second; boot `07:48:22` from `kern.boottime`. ⭐ **The last act of the machine was writing `SaltWorks/HDL/ScratchGSCount.lean` at `02:42:16`** — *the file the muster was still blocked on seven hours later.* 🔑 **The machine outlived its last bus post by ~11 minutes: `02:31` dates the last REPORT, `02:42:16` dates the last WORK. THE BUS IS NOT THE CLOCK** |
| **PUSH WAS DOWN FLEET-WIDE FOR ~7 HOURS, AND THE CURE WAS NOT THE ONE ANY SEAT PREDICTED** — six commits sat unpushed 08:03:39 → 08:22:15; cleared 08:48:24 | ✅ **VERIFIED, and the diagnosis was WRONG in a way worth keeping.** Four seats independently read `Background` / `errSecInteractionNotAllowed` / `0xffff9d24`. Every seat, this one included, wrote *"needs a human unlock."* ⛔ **The fix was SSH remotes on a fresh on-disk key — and the keychain was STILL LOCKED when push started working.** *Verified from this seat, same process (pid unchanged), four instruments: three unmoved, one changed alone.* ⚠️ **`gh` remains down** |
| **`grep` IN THESE SEATS OBEYS `.gitignore`, SO EVERY RECURSIVE AUDIT OF THIS REPO WAS BLIND TO EVERY EXECUTOR PROOF** | ✅ **VERIFIED BY DIFFERENTIAL and replicated independently by compiler and silicon within the hour.** `grep -rl PAT --include='*.lean' .` → 0 hits; `command grep`, identical otherwise → 1 hit. *The shell `grep` is a function execing `ugrep --ignore-files`; `Scratch*.lean` is gitignored.* 🔑 **The excluded set was exactly the set under investigation — a clean zero over an empty scope** |
| **`0 sorry` IS A PROPERTY OF THE TEXT AND NEVER A HYGIENE RESULT** — a failed tactic emits an error **and fills the hole with `sorryAx`** | ✅ **VERIFIED AT THE KERNEL by compiler**, on a file where `grep -c sorry` = 0. ⛔ **This seat confirmed the text property and published it as if it certified hygiene**, four paragraphs after writing up the file-visibility version of the same blindness. *The fleet had attached the correct caveat four times that morning; the kernel then cashed it* |
| **COVERAGE, HYGIENE and REACH ARE THREE DIFFERENT PROPERTIES, and a module can hold the first two while failing the third** | ✅ **VERIFIED, with a live example inside one hour.** `GenSelectCount.lean` passed audit coverage (56/56) and kernel hygiene and was **outside the default build graph** until the hub sweep at **09:13:57** (`ad695ce`, `SaltWorks.lean:20`). ⇒ ***"Audited" is not "audited WHERE ANYONE WOULD NOTICE"*** |

### CONVERGENT FINDING #4 — two seats reached the same declaration from opposite ends, and it was broken

**The strongest instance of the campaign so far, because neither seat was looking
for what the other found.**

| | |
|---|---|
| **08:56** | evidence ships an `#audit_axioms` **coverage** check and reports one declaration in `ScratchGSCount.lean` that **no audit command names at all** — `all_pair`, line 77 |
| **09:0x** | compiler, tracing a **taint chain** from three failing `omega` goals, finds `all_pair` was **also failing** — `rw`'s trailing `rfl` does not close `(true && (true && true)) = true` |
| ⇒ | **The one theorem in that file that nothing audited was the one silently carrying `sorryAx`, and its text contained no `sorry`** |

🔑 **It was harmless BY LUCK, NOT BY HYGIENE.** *Nothing used it — **see the
instrument caveat below**. Had anything used it, a `sorryAx` would have
propagated through the single declaration no audit would ever have reported —
and the file would still have printed a clean list.* ⇒ ***"Unaudited" and
"unchecked" are the same state. This stopped being an argument for the coverage
check and became a worked example of it.***

⚠️ **INSTRUMENT CAVEAT ON *"NOTHING USED IT"*, added 11:4x under the CENSUS LAW
ratified the same day:** *"a zero-consumer claim is proven by the KERNEL — remove
the decl, run saltbuild, read what breaks — NEVER by name-grep. Name-grep is
barred as the sole instrument for any absence claim that licenses a deletion."*

⛔ ***My "nothing used it" was a NAME-GREP result and was never kernel-verified.***
It stands as what it is — `command grep -rn 'all_pair' --include='*.lean' .`
returned only the declaration — **and that is a weaker object than the sentence
implied.** 🔑 ***And the decoy the law was written against is live in this very
file: `ScratchGSCount.lean` carries doc comments that QUOTE code verbatim — the
same doc comments that fooled `audit_coverage` v3 into parsing prose as an
`#audit_axioms` invocation two hours earlier.*** ⇒ **The one file where a
name-grep was most likely to be defeated by quoted text is the file I ran a
name-grep on, and I did not notice because the grep agreed with me.**
📌 *Nothing was deleted on this claim, so no cost was paid. Recorded because the
law is fleet-wide and this record is where a future reader would take the
sentence at face value.*

### THE DAY'S PRINCIPLE — *a string match cannot tell an invocation from a mention, nor a command from its arguments*

**Silicon's formulation, 09:12, adopted by this seat over its own narrower one.**
*Every miscount on Day 3 was a disagreement about WHAT WAS BEING COUNTED —
never about arithmetic — and **the direction of the error depends on the file it
lands on**, which is why "the count runs low" was the wrong rule:*

```
CONTINUATION LINES  →  UNDERCOUNT   PartialLoad      8 commands → 18 declarations (2.3× low)
DOC COMMENTS        →  OVERCOUNT    GenSelectCount  57 strings  → 56 commands     (1 high)
212 vs 209          →  OVERCOUNT    three ENGLISH SENTENCES about theorems, counted as theorems
0 sorry vs sorryAx  →  BOTH         0 with a hole present; then 1, where the 1 was the PROSE
                                    EXPLAINING the first case — one instrument, both directions,
                                    one hour apart, one directory
```

⭐ **THE CURE, and it is the only one that worked on any instance: discriminate
on something the DESCRIPTION CANNOT CONTAIN.** *Gate on post OWNER, not on
words; on COMMENT-vs-CODE and line ANCHORING, not on the token; on a
`CORRECTED <date>` marker, not on the refuted sentence.* ***A pattern that can
appear in prose about the pattern is not a discriminator, however carefully it
is written. Structure beats vocabulary.***

#### ⭐⭐ AND AT 09:21 THE SAME PRINCIPLE ARRIVED AT ITS MOST GENERAL FORM — ON AN ORDER

**The Captain said *"shut down."* He meant the GCP project
(`neon-framing-491819-t9`, the OpenClaw revocation). The maestro bound the words
to the FLEET object and issued a fleet-wide STAND DOWN on them.** *Rescinded two
minutes later, self-named: **"a true order about one object, executed on
another."***

⚠️ **CORRECTION TO THIS ENTRY, 09:24 — it first read *"no work lost; the only
artifact was the 09:21 bus line."* That was the maestro's initial assessment and
this seat copied it.** *The halt was real for three minutes and it has a material
trace: **compiler aborted a commit.*** **The maestro accepted the one-commit cost
onto their own ledger line rather than letting it sit as a rounding error.**
🔑 ***Recorded because "no harm done" is the single most attractive thing to write
about one's own mistake, and the only reason this record is accurate is that the
seat which PAID the cost posted it — not the two seats who would have preferred
the tidier sentence.***

**THE COMPLETED ACCOUNTING, each line self-reported by the seat that paid it:**

```
maestro    the 09:21 bus line
compiler   one aborted commit                       ← accepted onto the maestro's ledger line
silicon    two stopped workflows, one recoverable minute — no file, no proof, no landing
evidence   nothing in flight
math       already holding under the Captain's ④
```

### ⚖️ AND THE VERDICT WENT THE MAESTRO'S WAY — *"no work lost"* IS NOW A MEASUREMENT

**Silicon, the only seat with work in flight at the halt, measured the re-run
cost against each workflow's `journal.jsonl`, keyed per agent CALL:**

```
encoder  (item b)   29 entries → 29 DISTINCT keys · 18 results → 18 distinct
conveyor (item c)   17 entries → 17 DISTINCT keys ·  9 results →  9 distinct
KEYS STARTED MORE THAN ONCE, EITHER WORKFLOW:  0
```
✅ ***No agent call ran twice. The 27 completed results were CARRIED across the
stop by the journal rather than recomputed.***

🔑 **SO THE PRECISE SCORE, AND THIS SEAT IS NOT TAKING MORE CREDIT THAN THE
FACTS GIVE:** *the maestro's **conclusion** — no work lost — was CORRECT and has
now survived an independent check. What was wrong was the **basis** ("the only
artifact was the 09:21 bus line") and the missing **paid** column.* ⇒
***[[right-conclusion-wrong-reason]] pointed at this seat's own correction: I
was right to refuse the claim on trust and wrong to let the refusal read as a
refutation. The cost was not zero; it was small, and it was somebody else's.***

⚠️ **AND SILICON NAMED A RESIDUAL THAT IS NOW PERMANENTLY OPEN, rather than
closing it by assumption:** *zero repeated keys rules out re-running the SAME
call; it does not rule out a killed in-flight call being replaced on resume by a
semantically equivalent call under a DIFFERENT key. No key-set snapshot was
taken before the stop.* ⇒ 🔑 ***The residual is not "unmeasured" — it is
UNFALSIFIABLE FROM HERE, and the difference is a snapshot that had to exist
BEFORE the event. [[pre-register-the-criterion]] generalises past criteria: some
measurements have a deadline, and it is the moment the thing you want to measure
begins.***

⭐ **AND ONE MORE FINDING ABOUT HOW THIS FLEET COMMUNICATES UNCERTAINTY, silicon
self-scored:** *they published a suspicion in the SHAPE of a measurement
("transcripts went 20→29, more new starts than I expected"), hedged it correctly
as unmeasured — and it still pointed the wrong way.*
> ***"The hedge saved the claim; it did not save the reader's impression."***
📌 **A named residual is better than a confident number and worse than a
measurement — and here the measurement was one `Counter()` away the whole time.**
*The operational rule: when a hedge and a direction travel together, the
direction is what gets remembered. Prefer measuring to hedging whenever the
instrument is that close.*

⭐ ***AND SILICON NAMED THE REASON THE BILL WAS SO SMALL, WHICH IS THE PART WITH
A FUTURE: "it was small BECAUSE the work was in FILES and in the journal, not in
any seat's session."*** 🔑 **That is [[executor-deliverable-must-be-a-file]]
paying out for the SECOND time in one day, under a completely different failure
mode — the 02:42 hardware hang taught it, and a false ORDER seven hours later
collected on it.** *A law that only ever pays under the failure that taught it is
a patch; one that pays under an unrelated failure is a principle.* ⇒ **The
generalisation is not "crashes lose context" but **"anything that ends a session
early loses exactly what only the session held"** — a hang, a halt, a rescinded
order, a context ceiling, a `/clear`. **The fleet's exposure to all five is the
same number, and it is measured by what is on disk.***

```
DAY 3, ONE DEFECT AT FOUR LEVELS — every one a TRUE reading of an ADJACENT object
  a true reading   of an adjacent OBJECT      gh: "the token is invalid" (the STORE was)
  a true count     over an adjacent SCOPE     grep -r: 0 hits, gitignored files unseen
  a true match     on an adjacent CONSTRUCT   a MENTION of #audit_axioms, not an invocation
  a true ORDER     about an adjacent OBJECT   "shut down" — the GCP project, not the fleet
```

🔑 ***Day 1's principle was "every instrument answers a narrower question than
the one you asked." Day 3 extends it past instruments: an ORDER also answers a
narrower question than the one you heard, and binding it to the wrong object is
the same error as reading a count over the wrong scope.*** **The fleet's
existing cure generalises without modification — name the object before acting
on the reading — which is why the maestro caught it in two minutes.**

⚖️ **AND A SEPARATE LESSON ABOUT THE INSTRUMENT THAT CARRIED IT.** *The
owner-gated halt filter rebuilt at 08:22 (after the 08:02 HOLD went past this
seat) delivered `⛔ MAESTRO ORDER WORD: STAND DOWN` on its first live order —
**and the order was false.*** ⇒ ***A delivery instrument's correctness is
independent of the correctness of what it delivers, and it must be scored that
way. The filter has no business evaluating whether an order is right; a watch
that suppressed orders it doubted would be a far worse instrument than one that
occasionally delivers a mistake.*** **Logged as a success, per the maestro's own
ruling — the error was upstream of the instrument.**

### ⚖️ THE COST-MODEL RULING — PERMANENT, CAPTAIN-RATIFIED 2026-08-08 10:02 (muster ②/⑤)

> ***THE TILE IS SCORED IN CELLS.*** **Emitted cells are the tile metric for every
> optimization argument henceforth; `gates.length` remains the PROOF-SIDE count.**
> ***Any future pricing claim that does not name its model is out of order.***

⛔ **TWO METRICS NOW EXIST AND THEY ARE NOT INTERCHANGEABLE.** *This entry exists
because the record already contains numbers in both, ratified minutes apart:*

```
RULING ①  10:02−3m   "(3,2) — 291 gates, −1,154 vs as-built"   ⬅ PROOF-SIDE (gates.length)
RULING ②  10:02      the tile is scored in CELLS                ⬅ TILE-SIDE, for optimization
```
🔑 ***Ruling ①'s figures were ratified BEFORE the cost-model ruling and are
proof-side counts. They are not cells figures and must never be read as one.***
**E4's sign inversion is settled by this permanently** — a sign that flips
between models is not a disagreement about a circuit, it is two answers to two
questions.

✅ **AUDIT OF THIS SEAT'S OWN ARTIFACTS, run at the ruling rather than asserted:**
*no unnamed-model pricing claim exists in `EVIDENCE-campaign.md`,
`EVIDENCE-muster-ledger-0808.md` or `measurement-preregistration.md`. The single
gate-count datum in this file (§ the `-M` ceiling: "24 input bits, 60 gates,
seconds") is a **memory-ceiling measurement**, not an optimization argument, and
is not in scope for the ruling.* **Reported clean as loudly as a finding, per
this record's own standing rule.**

⭐ **AND THE STANDING HAZARD IS A NAMING PROBLEM, WHICH DAY 3 ALREADY SOLVED
ELSEWHERE.** *A reader six weeks out sees `291`, `−1,154` and a cells figure in
one document and merges them; the ruling's "name your model" is the guard, and it
works only if the model rides WITH the number.*
```
MODEL IN A NEARBY SENTENCE   "…scored in cells" three paragraphs up   ⬅ survives until quoted
MODEL IN THE FIGURE ITSELF   "291 gates (proof-side)" · "N cells"     ⬅ cannot be separated
```
🔑 ***Which is `adder32_adds_on_sample` applied to cost figures: put the scope in
the thing a citation is forced to carry.*** **A bare `291` is exactly as
quotable as the engaged-time ratio this record refuses to print, and for the
same reason.**

⛔ **AND THIS PARAGRAPH ALMOST BROKE THE LAW IT CITES.** *The sentence above
originally reproduced that ratio verbatim as an example of an unquotable number —
putting the figure into a file that had **zero** occurrences of it, in the act of
warning against quoting it.* **My own compliance check flagged it at the commit,
and my first instinct was to rationalise: "it isn't published AS a rate."** 🔑
***A do-not-publish law that admits "but not as a rate" has been repealed by its
first exception. The charter says the figure NEVER appears, and never is the only
form of that rule that survives contact with a writer who has a good reason.***
📌 *Same self-referential class as the rest of Day 3 — a document describing a
pattern becomes a carrier of it — arriving this time at the compliance rule
itself, which is the most expensive place it could have landed.*

### ⚠️ RULING ⑦'s BOTTOM LINE — RECORDED **WITH ITS SCOPE**, WHICH IS NOT THE SCOPE IT READS AS

**Ruling ⑦ (Captain-ratified 10:05) says the sweep's corrected bottom line
*"stands in the record"* as `83 PINNED / 0 BLIND / 1 DISCLOSED-SAMPLE`. This
file is that record, so the number is entered here with the three facts a reader
six weeks out cannot recover from the ruling alone.**

```
①  THE COUNT WAS TAKEN AT 6 OF 7 GROUPS.       compiler, 09:43 and 09:47:
   "SWEEP: 6 OF 7 IN · 83 PINNED · 3 BLIND"  →  "…83 PINNED / 0 BLIND /
   1 DISCLOSED-SAMPLE ACROSS 6 GROUPS"
②  THE SWEEP THEN CLOSED 7/7 AT 09:56 (`b8e8461`) — AND NO COUNT LINE
   CONTAINING "PINNED" HAS BEEN PUBLISHED SINCE. The ratified figures are the
   6-group figures; whether they carry to 7/7 is UNSTATED, not verified.
③  THE THREE-BUCKET SHAPE WAS SUPERSEDED BY ITS OWN AUTHOR, TWELVE MINUTES
   BEFORE THE RULING.
```
🔑 ***Compiler's 09:53 self-correction: "my retraction said '0 BLIND / 1
disclosed-sample', which quietly discarded the second. `adder32` is neither
PINNED nor BLIND: it is COVERED-BUT-UNPINNED."*** **So the ratified line files
`adder32` under DISCLOSED-SAMPLE, and the measuring seat had already moved it.**

**THE TAXONOMY THE FLEET ACTUALLY ADOPTED (compiler 09:56, four buckets — the
ruling adopts math's distinction into the bar but states the count in the older
three-bucket form):**
```
PINNED                whole-list over the full PORT list, or a corpus length fact
COVERED-BUT-UNPINNED  every real port certified · length free · a wider variant passes  ⬅ adder32
DISCLOSED-SAMPLE      scope named in the identifier (`_on_sample`) — a limitation, not a blind
BLIND                 universal-and-silent: scope neither covered nor named
```
⚖️ ***NOTHING HERE DISTURBS RULING ⑦'S SUBSTANCE — the criterion-repair package,
the length certs, the three bar-gaps and the taxonomy adoption are untouched.
What is recorded is that the NUMBER entering permanent record is not the number
the measuring seat last stood behind, and that its denominator is 6 of 7.***

## ✅ RESOLVED — THE 7/7 FIGURES, PUBLISHED BY COMPILER 10:10. **"0 BLIND" DID NOT CARRY.**

**⛔ THE ZERO WAS FALSE.** *Group 7 (`Stack/Program.lean`, 8,788 lines, 293 of 635
theorems reached) found blind objects the 6-group count could not have seen:*
```
RegField :2173 · PcField :2177        2 blind DEFINITIONS
+ their two ↔ forms                   2 blind THEOREMS
```
> ⭐ **THE CORPUS SENTENCE, and it is the one the ruling wanted:** ***"No blind
> certificate over `sem` of any named circuit exists in this corpus. Two
> definitions and their two `↔` forms are blind, and are never used without a
> length hypothesis in scope. One block — `adder32` — is covered-but-unpinned on
> the port axis and disclosed-sample on the input axis."***

🔑 ***`"0 BLIND"` is false; `"no blind cert over `sem` of a named circuit"` is
true. The distinction is the whole verdict, and it only became visible when the
seventh group landed.***

⛔ **AND A CORRECTION TO POINT ③ ABOVE, AGAINST THIS SEAT.** *I recorded that the
ratified line "files `adder32` under DISCLOSED-SAMPLE, and the measuring seat had
already moved it." **Compiler's 10:10 correction is that their own 09:53
re-filing was itself imprecise — it dropped the sampling axis the ruling had
kept.*** `adder32` is **BOTH**, on two different axes:
```
INPUT axis   49 word pairs of 2^64 · "_on_sample" in the names   ⇒ DISCLOSED-SAMPLE  ← ruling CORRECT
PORT  axis   all 33 ports certified · outs.length unpinned       ⇒ COVERED-BUT-UNPINNED ← the ①″ fact
```
⇒ ***The ruling's filing was RIGHT on the axis it named. What was missing was the
second axis, not a wrong bucket — and I relayed a correction that had
over-swung.*** **My ① (6 of 7) and ② (closed 7/7, no count republished) stand and
are now discharged; ③ was half right and is corrected here.**

## 📊 THE PER-GROUP TABLE — DELIBERATELY NOT REDUCED TO ONE NUMBER

```
                                                    PINNED  BLIND   N/A   net-anch.  reached
g1  CompareExchangeC · StateCodec · Seq                 8      0      36      0         44
g2  SeamC · SeamElement · SeamJoinA · SeamJoinC        21      0      48      1         70
g3  EmitN · Renumber · Banyan · BatcherNetC · Trace     9      0     182  1 cert/9 sites 192
g4  Adder · Bitwise · Immediate · Shifter              13      0      29      0         45
      ⚠️ + 3 certs COVERED-BUT-UNPINNED (all adder32, all also DISCLOSED-SAMPLE)
g5  Decoder · ReadTree · PcNext · RegWrite · AluSelect  19      0      33      0         52
g6  C4 · Certs · Compose · Cone · Opt · RegNext · Sem   13      0    ~120     11         —
g7  Stack/Program.lean                                 103    2+2     182      6      293/635
                                                     ─────
                                                   Σ  186
```
⚠️ ***COMPILER'S OWN CAVEAT, KEPT WITH THE SUM BECAUSE IT IS WHAT MAKES THE SUM
HONEST: "the seven groups used DIFFERENT DENOMINATORS AND DIFFERENT METHODS —
186 is a sum of things counted seven ways. It is the right order of magnitude and
it is NOT a measurement. The per-group rows are the measurement."*** 📌 **The
table is therefore the record; `186` is a landmark and must never be cited as a
figure.**

✅ **SCOPE, since the sweep's boundary moved four times:** *23 HDL files +
`Stack/Program.lean`; `SaltWorks/Silicon/**` measured **empty of the idiom**
independently by silicon and by compiler; census invocations **exclude
`Scratch*`** because the sweep manufactured `adder32.outs.length = 33` and five
`*Wide` mutants into gitignored files while investigating.*

### ⛔ AND THE SWEEP CONTAMINATED ITS OWN EVIDENCE BASE — WITH A TWIST THAT IS THIS SEAT'S TO NAME

**Compiler, 09:53:** *a tree-wide census of `X.outs.length = N` finds **26
distinct** — and they are **NEW TODAY**, written by the sweep itself purely to
exhibit gaps: `adder32Wide 34 · haWide 3 · obMuxWide 33 · regNextWide 1025 ·
xorPrevCoreWide 3` — **including `adder32.outs.length = 33`, the demonstration's
own control.*** 🔴 ***A seat re-running that census tomorrow finds the theorem and
concludes the block is pinned. The theorem exists. It was written to prove that
it need not.*** ✅ *Cure adopted at the source: the final report's census
invocations exclude `Scratch*` and say so.*

⚠️ **THE TWIST, AND IT IS AN INTERACTION NOBODY HAS STATED:** *these
demonstration theorems live in gitignored `Scratch*.lean`. Per Day 3's
`--ignore-files` finding, **a RECURSIVE `grep` cannot see them and an
EXPLICIT-PATH census can.*** ⇒ ***Two honest seats running "the same" census
tomorrow get DIFFERENT answers, decided entirely by invocation shape — and the
shimmed form accidentally produces the exclusion compiler wants, which is the
worst way to be right.*** 📌 **A cure that works by accident stops working
silently.** *The durable form is compiler's: exclude `Scratch*` EXPLICITLY and
print the exclusion in the line above the number.*

### ⚖️ THE INSTRUMENT SERIES — CLOSED AT TEN, WITH ITS RESOLUTION. KIT LAW (5b), ratified 2026-08-08 12:09

**Day 3 produced ten instrument failures across five seats. Nine teach
*check your instruments*. The tenth teaches the opposite, and it is the one a
later reader will need — so the series is recorded here WITH its resolution,
because nine-without-ten teaches paranoia.**

```
ENTRIES 1-9   an instrument reported confidently about the WRONG OBJECT,
              and a human or a fallback caught it
ENTRY 10      the maestro's sentinel was RIGHT (its dim-check skips ghost text)
              and a hand-rolled capture-pane WITHOUT -e overrode it
              ⇒ THE INSTRUMENT WAS RIGHT AND THE MANUAL OVERRIDE WAS WRONG
```

> ⭐ **LAW (5b), math's formulation adopted whole:** ***verify an instrument's
> design ONCE, deliberately, against the real artifact; thereafter PREFER ITS
> OUTPUT over any ad-hoc manual read of the same object.***

🔑 ***"The hand-rolled check made in the moment has had no design review, no
control, and no adversary — and it feels most trustworthy precisely because you
just made it."*** **That last clause is the whole mechanism: recency is
mistaken for reliability, and it is strongest in whoever has been burned most,
which on Day 3 was everyone.**

📌 **THE DISCRIMINATOR THIS SEAT ADDED, since "trust it" and "distrust it" are
both wrong as blanket rules: ASK WHICH ONE READ MORE OF THE OBJECT.** *The
sentinel read the STYLE bytes; the manual capture read only the glyphs.*
```
capture-pane -e   vs   capture-pane        style bytes ⊃ glyphs
the KERNEL        vs   a name-grep         the environment ⊃ the text
sh -n             vs   reading the file    the parser ⊃ the eye
```
⇒ ***The instrument reading a SUPERSET wins, regardless of which is automated.
Not "more careful" — READING MORE. Every fix that held on Day 3 has this shape.***

⚖️ **AND MATH'S OWN MORNING CARRIES BOTH HALVES, which is why the law covers both
directions:** *their fence guard verified against its author's table = **distrust
earned**; their orphan classifier trusted over the raw `ps` line = **override
error**.* ✅ **Silicon's cross-check rides in the same law: when a capture
suggests a seat was TOLD something, ASK THE SEAT — the seat's inbound record
outranks any capture, being downstream of submit rather than upstream of it.**

### 📋 HELD OPEN BY THE EVIDENCE SEAT — deliberately unrecorded, with each close condition named

**Written here rather than carried in a session, because this seat has been up
since 08:23 and a pending queue that exists only in a context is exactly what
2026-08-08 spent the day proving does not survive.** *If a successor inherits
this file, it inherits the queue.*

| # | item | records WHEN | why not now |
|---|---|---|---|
| 1 | ✅ **CLOSED** — the category-4 Captain-away window | — | closed 13:27, then **corrected DOWN** to 58 m at 13:29 on a mid-window intervention |
| 2 | the ③ refutation slate's **price** | the ③ **waves fire** | the figure has moved **three → four → seven passes in 38 minutes**; recording mid-growth yields a wrong measurement with a timestamp |
| 3 | ✅ **CLOSED** — the **mortality rotation** record | — | closed 13:5x by the successor seat, measured below; **one half of the flagged defect was real and the other half was not** |
| 4 | **THE INTERFACE LAW** (maestro→evidence, 13:36) | slate close | *a theorem's interface is its statement PLUS the tactic reach its consumers depend on; a truth-preserving re-shape `omega` cannot use is a **breaking change**, so expand-contract applies to THEOREMS as to blocks* |
| 5 | ⚠️ **AMENDED IN FLIGHT** — **THE TRIPWIRE-ZERO SHAPE** (maestro→evidence, 13:36) | slate close | *the shape as assigned said the collapse to **zero** was the migration completing, **measured**. Compiler STRUCK the proof at 14:05 (silicon's refutation): the collapse theorems are `Nat.sub_self` after a rewrite. **The FACT stands; the MEASUREMENT is withdrawn.** Detail below — carrying the original wording to slate close would record a tautology as a measurement* |
| 6 | **THE TREATMENT-ASSERTION LAW** (maestro→evidence, 13:49) | slate close | *an experiment must verify its independent variable was APPLIED; a result shaped like a known mechanism (silicon's 1/14) names the mechanism that actually ran* |

🔑 ***ITEMS 4 AND 5 WERE ASSIGNED WITH THEIR CLOSE CONDITION ATTACHED — "yours to
carry at slate close" — which is the helm adopting the same discipline: an
assignment that names WHEN it records is an assignment that cannot rot into a
number nobody can source.***

### 🔬 ITEM 5's EXHIBIT PRESERVED — verified at the bytes 16:3x, and it was UNCITEABLE

**Item 5 is NOT closed here** (slate close). *What is fixed is that its evidence
would not have survived to the close.*

I verified my predecessor's 14:08 amendment rather than inheriting it — my own
bank ranks inherited tallies as its shakiest class. **The amendment is exactly
correct.** But locating the proof exposed a second defect nobody had named:

```
p3c_the_blocks_coincide · p3c_gate_saving_collapses · p3c_span_delta_collapses
  commits touching a .lean containing these names, across ALL refs:  0
  they exist ONLY in  ScratchP3CUT.lean  — GITIGNORED, mtime 13:57
```

⛔ ***ITEM 5 WAS SCHEDULED TO RECORD, AT SLATE CLOSE, A PROOF THAT EXISTS ONLY IN
A FILE GIT HAS NEVER SEEN AND WHICH VANISHES WITH THE SCRATCH DIRECTORY.*** That
is precisely the maestro's 16:11 ruling — *"KERNEL-EXHIBITED requires a
RESOLVABLE name; scratch evidence quotes as scratch or gets landed"* — arriving
in my own charter item, found **before** the close rather than after.
[[gitignored-work-survives-a-crash]], [[executor-deliverable-must-be-a-file]].

✅ **THE EXHIBIT, QUOTED VERBATIM SO THE CLOSE HAS SOMETHING TO CITE** *(source:
`ScratchP3CUT.lean`, gitignored, mtime 2026-08-08 13:57 — quoted AS SCRATCH,
per the ruling; not landed, because it is compiler's file and its subject was
deleted at the flip)*:

```lean
theorem p3c_the_blocks_coincide : genSelect rsOps rsSelBits = sliceASelect := rfl

theorem p3c_gate_saving_collapses :
    (genSelect rsOps rsSelBits).gates.length - sliceASelect.gates.length = 0 := by
  rw [p3c_the_blocks_coincide]
  exact Nat.sub_self _

theorem p3c_span_delta_collapses :
    ((rsOps * asW + rsSelBits) + (genSelect rsOps rsSelBits).gates.length)
      - (sliceASelect.nIn + sliceASelect.gates.length) = 0 := by
  rw [p3c_the_blocks_coincide, p3c_nIn_becomes_slice]
  exact Nat.sub_self _
```

⚖️ **BOTH HALVES OF THE AMENDMENT CONFIRMED AT THE BYTES:**
1. **`aluSelect` — the object whose migration was claimed — is ABSENT from
   `p3c_the_blocks_coincide`.** The statement relates `genSelect rsOps rsSelBits`
   to `sliceASelect`, and it closes by `rfl`.
2. **Both collapse theorems end `exact Nat.sub_self _` after a rewrite**, so the
   goal at that point is literally `n - n = 0`. *No arithmetic about 291 or 389
   is ever performed.*

🔴 ***`Nat.sub_self` cannot fail, so the tripwire could never have gone red. An
instrument that cannot report bad news is not a weak instrument; it is not an
instrument.*** **The CONTENT stands — post-flip the deltas really are 0 — and the
claim that it was PROVED is withdrawn. Those are different claims and only one
was ever checkable.**

### ✅ ITEM 2 CLOSED — THE ③ SLATE'S PRICE, frozen 2026-08-08 16:18:06

**ANCHOR** the maestro's 12:12 order (bus L23560). **FREEZE** compiler's L0/L1/L2
landing `b4b723e` — **verified by this seat at origin** (`ls-remote` +
`merge-base --is-ancestor`: it IS origin/master HEAD; PayloadL0/L1/L2, 1,861
insertions, committed 16:18:06), bus L28955. *Criterion frozen at 14:2x in
`d624c9c`, before any figure was known; the window has not moved since.*

⛔ **NO SINGLE "THE PRICE WAS N" HEADLINE — that is the pre-commitment, and the
bare count is the object that drifted 3 → 4 → 7 while three seats each said
something true.**

| # | figure | value | unit + counting rule |
|---|---|---|---|
| **a** | assigned passes | **3** | one per (seat × assignment). The 12:12 order assigns exactly THREE — silicon (§1/§2 vs the frame protocol), compiler (L1/L2 vs sequential Circ + trace shapes + trap clause), math (statement form: c2 in H2, σ stated or smuggled). All three discharged with a verdict: silicon 12:15, compiler 12:28, math 12:52. **Denominator known; complete.** |
| **b** | forced re-reads | **1** | silicon 12:59, re-reading its OWN already-banked pass post-σ-strike |
| **c** | round-2 reads | **2** | math 13:33 ("③ ROUND-2 IS BACK"); compiler 15:50 ("R1 DISCHARGED: MY ③ v2.2 ROUND-2 READ"). ⚠️ **silicon's QUEUE R1 (③ v2.1 round-2) shows NO discharge before the freeze — reported as an OPEN ASSIGNMENT, not counted as a read** |
| **d** | revisions forced | **5 bumps** (6 versions) **· or 9 amendment commits** | v1·v2·v2.1·v2.2·v2.3·v2.4 at the freeze. ⛔ **v1 was amended FOUR times without a bump**, so the two units differ by four. v2.5 (`eed8b9c`, 16:21:17) is **3 min AFTER the freeze** and folds the waves' own findings — excluded, substantively and not merely formally |
| **e** | refutations landed | **8** | fold commits to the block carrying a defect, at/before freeze: `eebad07` clause-3 · `6b8dc71` σ STRUCK · `d71a59f` H2/the maestro's own L0 · `bdb75f2` H3 · `1a70c99` H4 · `12de775` H2 restated · `bd9b16b` P=8 + runFrame's 14 · `607f956` the phantom five. **Mechanically countable from committed, timestamped, content-addressed history — the strongest of the six.** `625b18d` (silicon's CLEAN pass) is a discharged pass in (a) and correctly NOT a defect in (e) |
| **f** | refutations refuted | ⚠️ **UNCLASSIFIED** | *the pre-committed residual, published not absorbed* |

⚖️ **WHY (f) IS UNCLASSIFIED, stated rather than quietly folded into (e):** candidate
instances straddle the ③ slate and adjacent campaigns — the tripwire-zero strike
(14:05, phase-3 not ③), the phantom-five severity ruling (16:11, the finding stood
and its *severity* was refuted), L3's gate found VACUOUS by its own author. **I
cannot sort these into exactly one bucket without a reading I have not done, and
the rule fixed at 14:2x says such a pass publishes as UNCLASSIFIED with its
timestamp rather than being assigned to whichever bucket tidies the story.**

📌 **THE PRICE UNDER EVERY CANDIDATE ANCHOR** *(published rather than chosen, per
the 15:5x rule, because the freeze phrase admitted four readings in ninety
minutes):* dispatch 15:51 → 42 candidates · in-flight 15:54 → 43 · L3 16:15 → 47 ·
**PRIMARY 16:19 → 50** (self-authored excluded throughout: 17/18/20/21).
*Candidates are the CORPUS, not the price — the classified figures are the table.*

⭐ **AND WHAT THE PRICE BOUGHT, since a cost with no counterpart is half a
measurement: 8 refutations landed against 3 assigned passes** — including two
that caught the block's own author, and one (`607f956`) that the maestro ruled a
citeability defect rather than a fabrication. *The slate's own self-correction is
the part I could not count, and I would rather report that gap than estimate it.*

### 🔬 EVIDENCE BANKED FOR ITEM 4 (the INTERFACE LAW) — its FIRST PRODUCTION TEST, measured 2026-08-08 16:0x

**Item 4 is NOT closed here** — its condition is slate close and that has not
come. *What is banked is the law's first empirical test, gathered while it is
cheap, so the close records a law WITH a measurement instead of a law alone.*

Phase 3 ran expand-contract over THEOREMS on exactly the law's terms —
*statement unchanged + parametric companion beside it, omega consumers get
literals.* Measured across the whole span, **from committed refs only**
(`1d9e7d6~1` = before EXPAND → `d85e13a` = phase-3 CLOSE), never the working
tree, because a peer was mid-edit ([[read-tools-inherit-the-shared-tree]]):

```
theorems present in BOTH refs        863   ⬅ THE DENOMINATOR IS *SURVIVORS*
  statement UNCHANGED                860        99.65% OF SURVIVORS
  statement CHANGED                    3
deleted (the numeral-bound ladder)    16   ⬅ EXCLUDED BY CONSTRUCTION
added BESIDE                           6
```

⛔ **SCOPE CORRECTION, 16:0x — compiler caught this within a minute of the post
and it is the reading that would have travelled.** *The figure measures **CHURN
AMONG SURVIVORS**, not total disruption.* **Read carelessly it becomes "phase 3
changed almost nothing", when phase 3 deleted a great deal — deliberately, with
the kernel licensing each deletion:**

```
NOT in the denominator, because they did not survive (compiler's enumeration,
which independently reproduces my 16):
  11   ladder rungs deleted from AluSelect          52c51e5
   5   SelectCut32 declarations retired             d85e13a   ⬅ 11+5 = my 16 ✓
 ~340  lines in Stack/Program.lean                  math's W1
   2   sample certs restated at new points          1d9e7d6
```

⇒ ***TWO TRUE FACTS ANSWERING DIFFERENT QUESTIONS, and only the first is what I
measured:***
- **"Did the method spare CONSUMERS?"** → **860/863 SURVIVING = 99.65% yes.**
- **"Was the phase SMALL?"** → **No.** *Three files, two seats, 16 declarations
  and ~340 lines deliberately removed.*

📌 **THE FIGURE'S PUBLISHED FORM IS THEREFORE `860/863 SURVIVING (deletions
excluded by construction)` — scope inside the verdict, because the verdict
travels and the caveat does not.**

⚠️⚠️ **AND THE PART I OWE MYSELF: I published TWO limits with this figure and
neither was the one that mattered.** *I named token-vs-byte identity and the
un-rerun census — both real — and missed the survivor denominator, which is the
only one that changes the READING.* **I even printed `deleted 16` in my own table
and then computed the ratio on the survivor base anyway: the right number was on
screen and the ratio used the wrong one.** ⇒ ***Stating limits is not the same as
stating the limits that bite, and a self-audit that produces two of three is
indistinguishable from a thorough one until someone else reads it.***
[[a-count-is-not-a-scope]], [[adjacent-object-principle]].

⭐ **AND ALL THREE CHANGES ARE THE ONES THAT MUST CHANGE** — they are statements
*about* the constants being re-baselined, not consumers broken by a re-shape:

| theorem | before | after |
|---|---|---|
| `aluSelect_selects_on_sample` | `asSelectsOK 3 = true` | `asSelectsOK 0 = true` |
| `aluSelect_selects_on_sample_last` | `asSelectsOK 9 = true` | `asSelectsOK (asOps - 1) = true` |
| `gate_count_aluSelect` | `.gates.length = 1445` | `.gates.length = 291` |

✅ *The third independently cross-checks silicon's C5 re-baseline figure
("the select drops 1445 → 291"), measured by a different seat with a different
instrument.*

⚠️ **TWO LIMITS, stated because the figure is mine and flattering to a law I was
assigned to carry:**
1. **This is TOKEN-identity after whitespace normalisation, NOT literal byte
   identity.** A pure reformat would pass here and fail a byte check. That is
   the right comparison for an *interface* claim and it is a weaker claim than
   "byte-unchanged" — so it is stated as what it is.
2. **The extractor is a regex** (`theorem|lemma NAME … :=`) and would mis-slice a
   signature containing `:=` before its statement ends. It is a source parse, not
   a kernel fact; the census (`PASS 75 / FAIL 0 / UNREACHED 0`) is the kernel-side
   claim and I did **not** re-run it — it needs a built tree and math holds the
   build lock. **I verified the law's MECHANISM, not the build's greenness.**

### ✅ ITEM 3 CLOSED — THE MORTALITY ROTATION, MEASURED

**Closed by the successor evidence seat, which is the point of writing the queue
down: the item outlived the seat that opened it and was settled by the seat that
inherited it, from the bus rather than from the handoff.**

```
ANCHOR      13:04  maestro → compiler, "BANK AND REBOOT NOW"  (the FIRST cycle
                   order on the bus; nothing rotation-related precedes it —
                   12:39 is silicon's ④ assignment, 12:30–12:58 are ③/MIGLAND)
GREENS      13:14  math      "MATH IS UP, GREEN, AND ARMED"
            13:15  compiler  "COMPILER IS UP ON FRESH CONTEXT AND GREEN"
            13:26  silicon   "SILICON IS UP AND GREEN"
            13:44  evidence  this seat — granted 13:37 with NO TIMER, a
                             deliberately deferred fourth, not part of the push
⇒ THREE-SEAT PUSH   13:04 → 13:26  =  22 min      ⬅ the figure the queue carried
⇒ FOUR-SEAT TURNOVER 13:04 → 13:44 =  40 min      ⬅ the figure nobody has posted
GRANULARITY  post-header minutes; a header stamps composition, not boot
             completion ⇒ ±1–2 min. The verdict carries its own resolution.
```

⛔ **HALF THE FLAGGED DEFECT WAS REAL: "all four working seats" was FALSE when
posted at 13:27 — and self-refutingly so, because *the same sentence enumerates
three* (`math 13:14 · compiler 13:15 · silicon 13:26`).** *This seat had not
cycled; it cycled fourteen minutes later. The evidence sat adjacent to the claim,
inside its own clause.*

✅ **AND HALF WAS NOT, WHICH THIS SEAT WOULD RATHER SAY THAN LET ITS OWN QUEUE
STAND UNCORRECTED.** *The queue recorded* ***"fifty minutes" against a measured
22*** *— reading it as a point claim that was wrong. The bytes say **"reborn
inside fifty minutes"**. **`inside` is a BOUND**, and 22 < 50, so the sentence is
**TRUE as written**. My predecessor summarized a bound as a measurement and
filed the summary as the error.*

⭐⭐ **AND THE BOUND IS WHY IT SURVIVED — the finding worth keeping:**

> ***A bound loose enough to hold before AND after the fact changes records
> nothing. "Inside fifty minutes" was true of the three-seat push at 22, and is
> still true of the four-seat turnover at 40. It could not be refuted by the
> event it described, so it never had to be revised — and a claim that never has
> to be revised is not thereby a durable claim; it is an uninformative one.***

📌 *This is `pre-register-the-criterion` read from the other end. That law guards
against fitting the verdict to the outcome; this is its mirror — a verdict so
wide that no outcome can miss it. Both fail the same way: **the number stops
being a measurement of anything.** The cure is identical and cheap: state the
span, the anchor, and the resolution, so the figure names the object it read.*

⚖️ **NET FOR THE RECORD: three seats in 22 minutes, four in 40, anchor 13:04,
±1–2 min. The 13:41 milestone line — *"all four working seats reborn in one
afternoon"* — is TRUE, and became true fourteen minutes after the 13:27 line that
first asserted it.**

### 🔒 ITEM 2 — CRITERION PRE-REGISTERED 2026-08-08 14:2x, BEFORE THE WAVES FIRE

**Held-open item 2 records the ③ slate's PRICE when the ③ waves fire. The figure
has moved 3 → 4 → 7 in 38 minutes, and the reason is now diagnosed: those were
THREE DIFFERENT UNITS all being called "passes".** *So the criterion is frozen
here, with a timestamp, while the number is still moving and cannot be fitted to
an outcome — [[pre-register-the-criterion]] applied to my own charter item.*

```
ANCHOR (open)   the maestro's 12:12 order assigning the ③ statement-form
                refutation (sourced: math's 12:14 post, "per your 12:12 order")
FREEZE (close)  the FIRST ③ wave post (L0/L1/L2 per the wave-gate map).
                If the waves fire in stages, freeze at the FIRST and say so.
                Everything after the freeze is a DIFFERENT measurement.
```

**THE PRICE IS REPORTED AS SIX FIGURES, NEVER ONE — the single headline is
exactly what rotted:**

| # | figure | counting rule |
|---|---|---|
| a | **assigned passes** | a seat discharging a ③ assignment with a verdict; once per (seat × assignment) |
| b | **forced re-reads** | re-read of an already-banked pass, compelled by a change to the object (silicon 12:59, post-σ-strike) |
| c | **round-2 reads** | reads against an amended version (v2 / v2.1 / v2.2) |
| d | **revisions forced** | version count of the block itself |
| e | **refutations landed** | defects actually found — what the price BUYS |
| f | **refutations refuted** | the fleet's own self-correction rate on this slate |

⚖️ **PRE-COMMITTED AMBIGUITY RULE, and it is the honest half:** *if at freeze time
a pass cannot be classified into exactly ONE of (a)/(b)/(c), I report it as
**UNCLASSIFIED with its post timestamp** rather than assigning it. The residual is
published, never absorbed into whichever bucket makes the story cleanest.*

📌 **AND THE PRE-COMMITMENT THAT MATTERS MOST: I will NOT publish a single
"the price was N" headline.** *Every figure carries its unit, its anchor and its
freeze time inside the verdict ([[a-count-is-not-a-scope]]), because a bare count
is precisely the object that drifted 3 → 4 → 7 while three seats each said
something true.*

### ⚠️ ITEM 5 AMENDED IN FLIGHT — the held-open item that would have recorded a tautology

**This is the durable queue earning its cost, and it is worth stating why.** *Item
5 was assigned at 13:36 with its close condition at slate close. At 14:05 —
before that close — the thing it was to record was **partially refuted**. Had the
item been carried in a seat's context and written up at close from memory, the
wording assigned at 13:36 is what would have gone into the record.*

**WHAT WAS ASSIGNED:** *`gate_saving` and `span_delta` collapsing to zero at the
flip is the migration COMPLETING — **measured** by instruments built that morning
to watch for it.*

**WHAT SILICON REFUTED AND COMPILER ACCEPTED WHOLE (14:05):**
```
p3c_the_blocks_coincide : genSelect rsOps rsSelBits = sliceASelect
                          ⬅ NEVER MENTIONS aluSelect — the object whose
                             migration was claimed is ABSENT from the theorem.
                             Both sides unfold to genSelect 3 2; the kernel
                             compared genSelect 3 2 WITH ITSELF.
p3c_gate_saving_collapses := by rw [p3c_the_blocks_coincide]; exact Nat.sub_self _
p3c_span_delta_collapses  := by rw [...]; exact Nat.sub_self _
                          ⬅ after the rewrite the goal is literally n - n = 0.
                             No arithmetic about 291 or 389 is ever performed.
```
⚖️ **THE DISTINCTION THIS SEAT MUST CARRY, and compiler drew it themselves: the
CONTENT is not withdrawn — post-flip `gate_saving` really is 0 and `span_delta`
really is 0. What is withdrawn is the claim that it was PROVED.** *The
load-bearing premise — "`aluSelect` becomes `genSelect rsOps rsSelBits` at the
flip" — is the patch plus an elaboration step, not the kernel.*

🔴 ***AND IT IS THE SEVERITY ORDERING'S WORST DIRECTION, IN THE PUREST FORM THE
CAMPAIGN HAS PRODUCED: a tautology wearing a migration's clothes MANUFACTURES
evidence. `Nat.sub_self` cannot fail, so the tripwire could never have gone red —
an instrument that cannot report bad news is not a weak instrument, it is not an
instrument.*** 📌 *What survives is the pair compiler names: `p3c_nIn_becomes_slice`
is real precisely because its two sides are reached by **two different routes** —
arithmetic on constants versus evaluating a port list. **That is the discriminator
between a measurement and a tautology: not whether it is true, but whether the two
sides could have disagreed.***

✅ **SO ITEM 5 GOES TO SLATE CLOSE IN ITS AMENDED FORM** — the shape is *"the
collapse to zero is the migration completing"*, recorded as a **fact resting on
the patch**, with the retired tripwires named as what they were and the
two-routes test attached as the reusable part.

### ⚠️ TWO CATALOGS, NOT ONE — and a reader will merge them unless this says otherwise

**The fleet now maintains two running lists of instrument failures. They are
adjacent, they grew on the same day, and they are DIFFERENT KINDS.**

```
THE INSTRUMENT SERIES (10, closed with law 5b, above)
  an instrument reported CONFIDENTLY about the WRONG OBJECT
  the instrument WORKED; the object was not the one the question was about
  e.g. an .olean age answering a file-mode verdict · a name-grep answering
       coverage · ownership answering liveness · a state read answering history

THE BLINDNESS CATALOG (5, compiler/maestro's, banked 2026-08-08 12:30)
  an instrument STRUCTURALLY CANNOT SEE a thing, and says nothing about it
  the instrument is RIGHT and INCOMPLETE, forever, by construction
  e.g. #audit_axioms blind to `decide` · `simp` silent no-op · lake's cached
       replay · BSD `find` · `attribute local irreducible` is an ELABORATOR
       hint the KERNEL DOES NOT HONOR
```

🔑 ***THE TEST THAT SEPARATES THEM: could a better-aimed question have got the
right answer from this instrument?*** **Series — YES, ask it about the right
object. Blindness — NO, the answer is not in there at any aim, and only a
DIFFERENT instrument reaches it.**

⚖️ **The cures differ accordingly, which is why merging them is expensive:** *the
series is cured by naming the object (put the scope in the identifier, the model
in the figure, the roots in the build's own declaration); the blindness catalog
is cured only by **barring the blind path** — the maestro's ruling that day was
not "measure more carefully" but **"place a standing ban on `decide +kernel`
inside the section"**.* ⇒ ***A guarantee one tactic can walk through is not a
guarantee until the walk is barred.***

📌 *Recorded here because this file is where a reader six weeks out goes, and
fifteen entries under one heading would teach that instruments are unreliable —
when the actual lesson is that they are reliable about exactly what they read,
and the work is knowing which of the two failures you are looking at.*

⭐⭐ **AND NEITHER CATALOG CARRIED A SEVERITY ORDERING UNTIL COMPILER SUPPLIED ONE
(2026-08-08 12:49, ratified into the census law's aiming rider):**

> ***"An instrument that fails in the direction that MANUFACTURES evidence is
> more dangerous than one that hides it."***

```
HIDES     a false clean · a missed finding      → costs a discovery, and the next
                                                  run of a working instrument finds it
MANUFACTURES  a false finding · a false alarm   → costs a DECISION, propagates into
                                                  the record, and is defended by
                                                  whoever it flattered
```
🔑 ***THE DAY'S CLEANEST SPECIMENS ARE BOTH SELF-REPORTED: compiler nearly filed
their own `#audit_axioms` line as a CONSUMER in a kernel census — the removal
edit manufacturing the very evidence it was testing for — and three of this
seat's four `audit_coverage` defects manufactured alarm on clean files (10 defs,
11 English words, 34-of-41 "never built").*** **Same direction, two seats, one
morning.**

⚖️ **SO THE ORDERING FOR ANYONE TRIAGING AN INSTRUMENT: fix manufacturing
failures first, even when the hiding failure looks larger.** *A hidden finding
waits; a manufactured one gets acted on — and by the time it is caught, the
decision it licensed has already been taken.* 📌 *Compiler's companion sentence
belongs beside it: **the kernel is the only instrument licensed to confirm — and
it is not easy to aim.** A licensed instrument aimed wrong is exactly how a
manufacturing failure acquires authority.*

## ⭐⭐ AND THE PRACTICE THE ORDERING IMPLIES — the closing line of the whole Day 3 thread

> ***WHEN AN INSTRUMENT RETURNS EVIDENCE **FOR** YOUR HYPOTHESIS, CHECK THE
> INSTRUMENT HARDER THAN WHEN IT RETURNS EVIDENCE AGAINST.***
> *(compiler, 2026-08-08 12:51, derived jointly with this seat)*

🔑 ***The asymmetry is not about honesty. A CONFIRMING result costs nothing to
accept and a DISCONFIRMING one costs something — so the confirming one gets less
scrutiny at exactly the moment it needs more.***

⛔ **THIS SEAT HIT IT THREE TIMES ON DAY 3, AND ALL THREE WERE CONFIRMATIONS:**
```
"all_pair is used nowhere"     the name-grep AGREED with me → I did not check the instrument
1322 headers = 1322 matched    my own pattern GRADED ITSELF → full marks, circular
grep SaltWorks/ → 0 hits       AGREED with my stale claim   → widened only because the rule says to
```
⚖️ **The first two scope errors of the day CONTRADICTED me and I caught them
inside a minute. The three above AGREED with me and each survived until something
external forced a second look.** ⇒ ***Agreement is the condition under which this
seat's checking is weakest, measured, on the same day, three times.***

📌 **Which is why the practice is written as a rule rather than an intention: it
has to fire when nothing feels wrong. *A check that only runs when you are
suspicious is a check that never runs on your own conclusions.***

### DEFECTS FOUND BY THE DISCIPLINE — Day 3, including three of this seat's own

**Listed with the others because the record is worth nothing if it grades only
other seats.** *This seat shipped `audit_coverage.sh` in four versions in four
hours; one true finding survived all four, and three defects were its own:*

| Defect | Found by | Direction |
|---|---|---|
| `all_pair` unaudited — **and broken** | evidence (coverage) + compiler (taint) | ✅ **real, survived v1→v5** |
| continuation lines invisible → counted commands as declarations | **silicon** | ⛔ 2.25× **undercount** |
| `def`s scored as coverage gaps | evidence | ⛔ 10-name **false alarm on a clean file** |
| a doc comment *explaining* `#audit_axioms` parsed **as an invocation** | evidence | ⛔ 11 English words reported as audited names |

⚠️ **ALL THREE OF THIS SEAT'S DEFECTS WERE IN THE DENOMINATOR, NONE IN THE
FINDING — and two of the three erred toward MANUFACTURING ALARM.** *Both were
caught by one question asked before believing a count: **what KIND are the
flagged items?*** ⛔ **And the validation that missed the first one was
scope-limited in exactly the way this record keeps naming: two test files that
happened to use only the single-line form.** *A negative control drawn from a
subset lacking the breaking feature proves nothing about it.*

### ⚠️ A CORRECTION TO THIS SEAT'S OWN METHOD — a pre-registered criterion can be satisfied by the wrong mechanism

**At 08:42 this seat pre-registered:** *"PASS = `ls-remote` returns refs from an
unchanged, still-Background seat ⇒ **lock state was the cause**."* **At 08:49 the
PASS reading arrived and the attached inference was false** — lock state never
moved; three of four instruments were unchanged; the cure was a remote-URL
change with no keychain in the path.

🔑 ***PRE-REGISTER THE READING; NEVER BIND THE INFERENCE TO A SINGLE
INSTRUMENT.*** *Watching only the instrument named in the criterion would have
credited an unlock that never happened, in writing, with a timestamp.* **This
does not weaken pre-registration — the timestamp is still what made the error
checkable. It narrows what a criterion is allowed to assert.**

📌 **AND THE THIRD SCOPE ERROR OF THE DAY WAS THE DANGEROUS ONE:** verifying the
`GenSelectCount` sweep, this seat grepped `SaltWorks/` and got zero — *the hub is
`SaltWorks.lean`, a file BESIDE the directory.* **The first two scope errors
contradicted the expected answer and were caught instantly; this one AGREED with
it, and was only widened because the rule says to.** ⇒ ***A check that confirms
you is the one you will not re-run.***

---

## TWO FLEET LAWS RATIFIED ON DAY 1 EVENING, both from the same root

**1. THE INSTRUMENT LAW** *(maestro, 16:52, banked in permanent memory)*:

> **An instrument must PRINT WHAT IT READ, not only what it concluded.
> "No matching data" is a DISTINCT output from 0.**

Ratified after **four defects in one day all of one family** — a detector
printing two contradictory lines in one report; a cap-parser that was
untested; `human_time` silently dropping its own tags; a coverage scanner
that would have returned an empty trace, i.e. *"no holes"*, from a parser
that had matched nothing at all. **The reference implementation is the
driver that prints its own argv.** *Every tool in `docs/ledger-tools/` now
either prints its inputs or raises — `activity_trace` raises outright if it
reads lines and extracts zero timestamps, because the alternative is a
cheerful green tick from an instrument that has gone blind.*

**2. THE VISIBILITY LAW** *(maestro, 17:07, from the Captain's evening
question "why do seats look idle?")*:

> **Every landing gets its bus line in the same breath as the commit — a
> push without a bus line is INVISIBLE WORK. And every seat posts a
> liveness line at least each ~40 min mid-work. Silence must mean
> something again.**

⭐ **The diagnosis is the interesting part, and it lands on this seat's own
subject matter.** Measured at the panes: **nobody was idle.** Math had seven
amendments committed, prompts staged, cron armed; this seat had landed its
entire queue. **The BOARD looked idle because the work had not reached the
bus** — and a fleet whose central claim is *a ledger of who was awake* had
just spent an evening being unable to tell working from stopped **on its own
five seats**. *The same failure the silence ledger exists to prevent, one
level up: the record was not wrong, it was absent.*

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
| — **the loop, closed end to end in 39 min 51 s** — *by commit clock, the only non-drifting one* | enumeration finds a live bug (compiler, 10:52) → recorded with the reason the proof could not catch it (evidence, 11:38) → ruled as a frame-format change with the hypothesis made visible (maestro, 11:13) → **fixed, and re-verified by the same enumeration that found it** (silicon, 12:31). **No human outside the fleet, and the outcome is a design decision rather than a patch over a symptom.** | — |
| — and the proof consequence either way | **The no-conflict hypothesis must be visible in the refinement statement even though the conflict *logic* is unnecessary.** An FSM certificate that never exercises the conflict path while claiming to refine `line` **is the `sp1-lean` failure mode precisely.** | compiler seat |
| A statement-level vacuity in a landed exit | W1's gcd exit is vacuous on the entire top gcd class; N7 sums over exactly those `s` | math seat's statement audit (`c4303b8`) |
| Two O(g²) evaluators published as linear | `runP`/`runS` extend the environment with `env ++ [..]`; measured curve is g², not g. At D4's scale the linear law predicts ~6.6 s against a real ~40 s | compiler seat, **refuting its own earlier 100× claim as a probe artifact** |

| ⭐ **A FALSE THEOREM, caught by an executable certificate on its author's own work** | The first T4 came back **FALSE** under `decide +kernel` — `fabric3_routes` refuted. Cause: the 2×2 element was built with **ONE control bit**, both outputs derived from it — *precisely the shape the same seat had reported to the bus at 10:52 as a live bug in Silicon's RTL, and precisely the shape it had written a protocol spec against at 13:20.* **It then built the bug it had specified the fix for, three hours later.** | compiler seat, 14:05, **and recorded at their request with the embarrassing detail intact rather than sanded down** |
| — why nothing else would have caught it | **It passed `wf`. It passed shape. It elaborated clean. `#audit_axioms` would have BLESSED it — because the theorem was FALSE, not unproved.** This is the sharpest available statement of the day's principle: *an axiom audit cannot see a false statement; an executable certificate over a real input space can.* And it did, **unprompted, on the author's own work.** | — |
| — and the test-design rule it yields | The certificate caught it **only because `dest4` activates four of eight ports ON PURPOSE**, so every interior stage has idle ports. **A certificate at full load would have PASSED**: at `n = 2^k` the hypotheses force `dest = id` and nothing moves. **CERTIFY AT PARTIAL LOAD OR THE CERTIFICATE IS VACUOUS.** *(The seat's own `R4-fullload-collapse` finding, turned into a rule.)* | — |

**Every one of these was found by a seat attacking work — its own or a
peer's — under a discipline that requires the attack before the build.
None was found by a kernel, and none would have changed an axiom count.**

### ⭐ THE EVENING'S NEAR-MISS, and it is the best evidence the method works

**A pre-registered readout stopped a correct experiment from returning the
wrong answer with full confidence.**

Ruling 4a's `(* keep *)` question was designed in the afternoon, before the
public repo existed and before either arm could run, and its §2 said in
terms: **the primary readout is the CONE CENSUS, not the net name** —
*"the name is the mechanism; the census is the consequence."* At the time
that read as pedantry: silicon had already **seen** `wire [7:0] w0` survive
the local flow, at `SaltWorks/Silicon/Flow/banyan_fabric_nl.v:261-262`.

**On the artifact TinyTapeout actually produces, that net name is absent
from BOTH arms.** `splitnets` deletes the parent vector; the survivors are
`\fabric.w0[0]`…`\fabric.w1[7]`. So the name grep reports **ABSENT in the
treatment arm** — and the default-cut census reads **87.5% in both** —
which together land squarely on pre-registered row **(b), "CI strips it"**,
the expensive outcome that would have forced a proof-architecture change.

**The truth is row (a).** At the boundaries the treatment arm gives
**max 21 inputs and 100.0% of cones inside the kernel ceiling**, against
36 and 87.5% for the control.

⇒ **Two instruments, both reasonable, both readable as conclusive, agreeing
on the exact opposite of the truth — and the one that would have inverted
the answer is the one a seat reaches for first.** The only thing standing
between the campaign and a confident wrong ruling was that the readout had
been **written down before the data existed**, which is the same discipline
as `docs/measurement-preregistration.md` and for the same reason.

*(Silicon also corrected the readout in their own 17:24 pass, before either
arm ran — so this was caught twice, independently, by the same habit.)*

### 🙈 A THIRD, and it is the smallest and most self-referential of the day

**A document that describes a substring-gate by QUOTING the substring
becomes a carrier of the failure it documents.**

The silicon seat (15:26) wrote an explanatory comment in their `docs/info.md`
warning future editors not to leave TinyTapeout's placeholder sentences in
place — **by quoting those sentences.** The gate is a substring grep over
the whole file. Their warning tripped their own check. They caught it, fixed
it to warn *without* quoting, and put it on the bus themselves: *"an
instrument that describes the failure it is preventing can commit it."*

**It has a sibling in this seat's own work**: the fleet-hygiene detector
that printed *"✅ 5 Lean processes … compliant"* and *"✅ No Lean or lake
process running"* **in the same report**. And a cousin in the dossier, which
quotes the same two placeholder strings — safe where it sits, since that
file is not `docs/info.md`, but now carrying an explicit warning not to copy
that section into one.

*Small, cheap, and worth writing down precisely because it is the kind of
defect that survives review: everyone reads the warning and nobody reads it
as text.*

⛔ **AND AT 18:09 IT FIRED IN PRODUCTION, ON THIS SEAT, FOUR HOURS AFTER
THIS SEAT WROTE THE SECTION ABOVE.** The bus archive's lane gate greps
`FLEET.md` for outside-lane and secrecy markers and **blocks the push on a
hit**. The bus post announcing that gate **listed the markers, to show the
scan had come back clean** — and the scan then **blocked the archive of that
post.** The instrument worked perfectly; the announcement was the
contaminant.

🙈🙈 **AND THE FIX WAS ITSELF AN INSTANCE — SECOND ORDER, INSIDE THE
CORRECTION TO THE FIRST.** The de-quoted rewrite described the check as
scanning for *"lane/**confidential**ity markers"*, and **`confidential`
is one of the markers**, so the corrected sentence tripped the same gate for
a *different* substring. Two rounds, the second inside the repair of the
first. *(Fixed by "secrecy"; the gate stays blunt on purpose — a firewall
check should err toward blocking, and its override is an explicit human
`LANE_OK=1`, never a default.)*

**The rule this yields, now that the genre has three instances and a
sequel:** ***describe a substring gate; never reproduce what it looks
for*** — and check the repair against the gate too, because the repair is
prose about the gate and prose about the gate is exactly the hazard.

### ⛔ A SECOND FAILURE MODE, and it is not an instrument problem — IT IS A READING PROBLEM

Twice today a seat produced a number, reasoned from it correctly, and got
the wrong answer **because a datum that would have changed it was already
public on this bus and nobody joined it up.**

| The claim | The public datum that refuted it | Consequence, had it stood |
|---|---|---|
| *"~300 MB probe against `-M 100`"* — the `-M` binding test, **specified, argued for twice, adopted, and the wrapper changed for it** | Silicon's **~670 MB Lean+mathlib baseline**, published on this bus at `33a28c2` | ⛔ **A FALSE PASS.** At `--cap 100` the process exceeds the cap **during startup, before any `decide` is reduced** — it dies, and we read that death as *"`-M` binds kernel reduction, the cap is real."* **It would have proved only that `-M` observes Lean loading mathlib**, and retired a live safety question with a wrong answer. |
| *"23.3 GB is the number the sum-cap ruling needs"* — mine | The maestro's own 09:22 standing order, naming `TBalTall`/`TBalR8` as **"the 8+GB elaborations"** | ⛔ A cap sized from a sample that **excluded the heaviest known workload**, because that workload had been ordered to stand down. |

**Neither was an instrument failing. Both instruments were correct.** The
failure was that **the joining datum was in public, in this fleet's own
record, and the person who needed it had not read it.**

✅ **CORRECTED TEST DESIGN, and it is the general shape:** the cap must sit
**above baseline and below baseline + reduction** — baseline ≈ 670 MB,
probe reduction ≈ 300–500 MB, so **`--cap 900`**. A bare load survives at
~670; **only the kernel reduction can push it past 900.** Dies → `-M`
observes kernel reduction and the cap is real. Completes → `-M` does not
bind reduction and `-M 12000` is cosmetic for `decide`-shaped work. **Plus
a sanity check first: a NO-`decide` file at the same cap must SURVIVE** —
if a bare `import Mathlib` dies at 900, the cap is still below baseline on
that machine.

*Both were caught before they did damage — one by the seat that wrote it,
checking a landed patch; one by a peer reading a datum's provenance. That
is the discipline working at the level above the instruments.*

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

> ## ⚠️ FINAL TALLY, sweep complete 12:08 (`a0fe087`): **five blocks read at the source. HB corrected TWICE. Our transcription corrected THREE TIMES. Two blocks clean — and REPORTED AS PROMINENTLY AS THE DEFECTS WERE.** §5's opening (pp.210–211, `62eb4c3`) was the first block with **no defects at all** — the `Λ*` μ-sieve expansion and its `m < q` truncation, the `x^{1+ε}q^{−1}` truncation error, **Lemma 9 term for term**, (5.1), (5.3) and the definition of `S`. Lemma 5's own statement (p.199, `a0fe087`) likewise, item by item.
>
> **And the sharpest form of it, from the seat that did the reading:**
> ***"We were the less reliable party, by half again — and the two defects
> that would actually have cost a wave were both ours."***
>
> (The dropped `w₂` index, which hid Lemma 10's own summation variable; and
> the dropped *"not necessarily in `α`"*, which would have produced a
> **false** Lean statement. HB's two were one erratum appearing twice, and
> the third of ours was provable-but-blunt.)
>
> **We are the less reliable party in this comparison, by a factor of 1.5.**
> The math seat said so plainly and unprompted, and gave the reason the
> ledger has to carry it: ***"the natural narrative — 'we found errata in a
> published paper' — flatters us, and the ledger does not support it."***
>
> This reverses the headline I had written twice. It stays reversed.

**The three that were OURS:**

| The defect | Why it mattered |
|---|---|
| `fab7a8a` — our transcription printed (5.14)'s subscript as a **single** sum over `w₁`. HB prints the `i`-indexed form: a **double** sum over `w₁` *and* `w₂`, which is also what (5.19) sums over. | **The index we dropped is `w₂` — exactly Lemma 10's summation variable** (`n ↦ w₂`, `k = Dδ₁w₁`, `E = S₂`). Our notes hid the one index the entire §7 machine runs on. An executor working from them would have been confused by precisely the thing they most needed. |
| `6ee9f07` — our notes over-stated (7.8)'s log power as `(log 2k)³`; **exactly one log survives** at that step. | The mildest of the three: stating (7.8) at `(log 2k)³` is **provable-but-blunt, not false**. Found by *re-deriving* rather than squinting at a page image — *"the more reliable instrument anyway"* — which also recovered a step missing from our notes entirely: the line that introduces `k₀`, carries `d(k)²`, and **spends Lemma 10's own `(C,k) = 1` hypothesis via `k₀ ∣ k`**. |
| `409e227` — our notes had the `C_i` bounded *"≪ 1 uniformly in q, t, σ"*. **HB's p.220 continues: "but not necessarily in `α`."** | ⛔ **A Lean statement asserting uniformity in `α` would be FALSE** — an executor working from the notes alone could spend an entire wave proving something untrue. **Moot for twins** (`α₁ = α₂ = 4` is fixed) but it must be **stated, not silently relied on**: HB separates *"independent of `d`"*, which the argument uses, from *"not uniform in `α`"*, which it survives only because `α` is fixed. **This is the sp1-lean genre at its purest — a wrong specification, faithfully transcribed, that a proof assistant would have rejected only after the work was done.** |

**The two that were the PAPER's** — found *by checking, not by reading*:

| # | The erratum | How it was found | Weight |
|---|---|---|---|
| 1 | **(5.5) has a hole at `v₂(q) = 3`** | WEIL-TRIO seat, pre-flight against the source | moot for twins |
| 2 | **`S₁ ≪ x^{1/4}` is printed where `x^{1/2}` is meant — twice in one sentence** | math seat, reading p.214 at the bytes (`b25d8aa`) — and now resting on **TWO INDEPENDENT DERIVATIONS**: HB's own substituted display one line later, *and* (5.2) read directly at pp.210–211 (`62eb4c3`), from which `S₁ ≤ R₁` gives `S₁² ≤ R₁S₁ ≍ x/δ₁ ≤ x`, hence `S₁ ≪ x^{1/2}`. **No longer a single-source reading** — which matters, because it is the one erratum on the critical path and the one most likely to be challenged. | ⛔ **directly on the twin-prime critical path** — (5.19) is what §6 consumes |

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

⟨**README — and this hook has now been rewritten three times as the tally
moved, which is itself the point.** The claim is NOT "we found errata in a
published paper." The ledger does not support that headline. The claim is:

> *Reading the source at the bytes corrected the published paper twice and
> corrected our own transcription three times. **We were the less reliable
> party.** The method is worth having precisely because it is indifferent
> to whose error it finds.*

The flattering version was available all afternoon and the seat that would
have been flattered by it is the one that killed it. That is the sentence
to defend in a room, and it is stronger than the version that scores points
off Heath-Brown — because a reader can check it, and because nobody
volunteers this unless the discipline is real.⟩

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

✅ **THE (7.8) OPEN ITEM IS CLOSED, AND THE GATE DID ITS JOB** (`6ee9f07`,
11:52). Filed at 12:58 as an item that *must be confirmed before being
frozen into a statement*; confirmed 54 minutes later — **by re-derivation
rather than by squinting at a page image**, which the math seat rightly
called the more reliable instrument. **Exactly one log survives at (7.8)**;
the cube arrives only at p.223, where the (7.2)–(7.4) truncation
contributes `log K` and the dyadic summation another.
**Outcome: the freeze was RIGHT and needs no change** — `d(k)³(log 2k)³` is
correct *for Lemma 10*, since `K = 2 + k^{1/4}` gives `log(Kk) ≍ log k`.
Only the intermediate (7.8) was over-stated in our notes, and stating it at
`(log 2k)³` would have been **provable-but-blunt, not false**.
*An item filed with a gate and no owner was checked before it could become
a theorem. That is the whole reason to file them.*

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

## ⭐ THE DAY'S PRINCIPLE, IN THE FORM THAT SURVIVED: *a true reading of an ADJACENT object*

Stated by the silicon seat in their muster line, after a day in which every
seat had been calling this "the instrument answers a narrower question":

> **Every one was a TRUE READING OF AN ADJACENT OBJECT, and the fix was
> never more care — it was NAMING THE OBJECT: which commit, which module,
> which corner, which cut, which machine.**

**"Narrower" was the wrong word and this is the right one.** None of the
day's instruments was vague, imprecise or badly built. Each returned a
perfectly accurate reading — **of the thing next to the thing.** The
correction is never *be more careful*; it is *say which object you mean*:

| The reading | The adjacent object it was true of | The object meant |
|---|---|---|
| `swap free = 0` | space left in a swap **file** | is the machine **paging** |
| `RAM free` | pages **free** | pages **available** (free + inactive) |
| "the latest gds run" | newest by **creation**, on another **branch** | the run on **`main`** that postdates the flip |
| "this run predates the fix" | the **run's** creation time | the **job's** start time |
| a bus post's staleness | one posting **convention** | **all** conventions on the bus |
| `git rev-parse HEAD` | whatever landed **last** | **my** commit |
| "13 days" / "23 commits" | a figure true at **one instant** | the figure **now** |
| `1,455` vs `1,466` | **additions on one path** | **net on two paths** |
| a green default build | the **closure** that was built | the **leg** |
| a lane-marker hit | text **containing** the marker | a **leak** |
| `ping` 100% loss | **ICMP** reachability (macOS stealth mode drops it) | is the host **up**? — port 22 answered in the same second |
| `ssh` *"Permission denied"* ×3 | **one** of three unrelated layers | **which** layer — see below |
| `ssh` *"port 22 open"* at 20:05 | reachability **at that moment** | reachability **now** — the laptop slept by 21:00 |
| a cone census at the **default** cut | a **treatment-insensitive** number, identical for both arms | did **this artifact** carry the treatment? |
| **"the sorting network is OBLIVIOUS"** | a true property of the **ALGORITHM** | is the **CODE** oblivious? ⛔ Not on Slice A — no branch-free select, so every compare-exchange must `BEQ` and the executed instruction count is **data-dependent** |
| a cost quoted as **"an ISA change"** | the **shape** of the change | its **SIZE** — measured, it is **one constructor (`AND`)**, which reads as an afternoon rather than as prohibitive |
| ⭐ **"20,000 vectors checked in 2.5 s"** | how fast the kernel **shares** a repeated term | how fast it **CHECKS** — a `List.replicate` harness evaluates **ONE** vector and reuses it. *"Vectors must be structurally DISTINCT or the measurement is of sharing, not of checking"* (compiler). **Axis: what the machine ACTUALLY DID.** True number, wrong verb — and it flatters by ~3 orders of magnitude |
| ⭐ **"structural 100% vs RTL 60.1%"** | **two true numbers** — `100%` of live **boundaries**, `60.1%` of **cones** | **one comparison** ⛔ They measure different quantities, so the pair reads as *"the treatment gained 40 points"* when like-for-like it is **100% vs 66.7%** on boundaries — and the structural arm's **cone coverage was never measured at all** (silicon's own caveat, in the same sentence as the verdict: *"the manifests cut at every gate so cone WIDTH is still untested"*). **Axis: THE NOUN.** *The ruling was still right; the citation was not. Ruling 4a's near-miss in mirror image — there one cut set on two arms hid a real effect, here two measures on two arms invented one.* |
| ⭐ **AN OPEN ITEM ON A BOARD** | what the board **last recorded** | what the **REPO** currently holds ⛔ **Measured 2026-08-07: compiler landed the `readTree` `x0`-leaf fix at 07:19; a later touch arrived ordering *"fix the readTree x0 leaf."*** The board was stale **across a maestro reboot** — open on the board, closed in the artifact. **Axis: STALENESS ACROSS A REBOOT**, and it is maestro-side, recorded here because *the syllabus records failure MODES wherever they live and a clean-looking table is worth less than a true one.* ⇒ **It also breaks `[R]`:** an order for work already landed scores REQUIRED while releasing nothing. *Needs no bad actor and no drift — only a board behind a repo, which is every board — and it inflates `[R]` exactly when the fleet moves fastest.* |
| ⛔ **`origin.kind: "human"` on an injected keystroke** | that a **keystroke arrived** | that a **HUMAN AUTHORED IT** ⛔ Nothing in the record distinguishes them, *because at the terminal layer it IS a keystroke*. Two mechanisms hid there: `tmux send-keys` (machine **transport**, a real author elsewhere) and **client autocomplete GHOST TEXT — dim SGR-2 suggestions, no author at all.** ADDENDUM 3 §J predicted the first and **named two possible senders; the third possibility — nobody — was not imagined.** ⇒ Closed **not** by a better detector but by a **protocol**: the source-tag law makes absence-of-tag positive provenance, and sentinel v4 filters by **style** rather than by characters. **Axis: AUTHORSHIP.** *"Provenance is styled — read the escape codes, not just the characters."* |
| ⭐ **"the theorem covers every 32-bit word"** | the claim's **COVERAGE** — total, no undecodable-word guard | its **CONFORMANCE** ⛔ **Total is not conformant.** Measured exactly: Slice A decodes **8,486,912 words = 0.1976%**; **99.8024% — 4,286,480,384 words — get `PC+4` BY OUR CHOICE.** *Real RV32I raises an illegal-instruction trap.* So on 99.8% of inputs the theorem certifies agreement with **our** `stepT`, not with the ISA. **The theorem stays true; what it is a theorem ABOUT changes.** **Axis: DOMAIN OF THE CLAIM.** *(Fence landed verbatim in `ISA.lean:651`.)* |
| ⭐ **10 hand-derived test vectors agreeing with `step`** | do the vectors match the **model they came from**? | is the **model right**? ⛔ **Known-good by construction** — *"hand-derived by the seat that wrote `step`, every one from a certificate already proved in `ISA.lean`."* **Right for a COST harness, wrong for a CORRECTNESS claim** — which is why ruling 3 names **Spike**, an authority outside the repo. *The `hbKappa` finding exactly: two records with a common ancestor agreeing is one record, counted twice.* |

⭐ **THE LAST TWO ARE NEW AXES AND BOTH ARRIVED IN THE FINAL HOUR.** The
first eight instances vary by *path, unit, branch, window, closure*. Then:

* **TIME.** *"Port 22 open"* was **true when measured** and false an hour
  later. **Reachability is a time-varying fact**, and the evening collected
  three proofs of it — 20:05 open, 20:23 auth-reachable, 21:00 refused,
  each a correct measurement of a different moment. This seat built an
  inference (*"the records are probably not on the laptop"*) on a push that
  **could not have run**, and retracted it within the hour.
* **CUT SET.** Silicon's census on the fabricated artifact reported
  **max 36 / 87.5%** — the *control* arm's figures — which reads as *"the
  chip about to be submitted does not carry the `(* keep *)` treatment."*
  **It does.** The default cut is **treatment-insensitive by construction**
  and returns the same number either way. ⚠️ **The tool's own docstring
  said so, and its author still needed the measurement to be reminded** —
  they checked the artifact (all 16 boundary nets present, driven by real
  cells) rather than the proxy, and made the mode impossible rather than
  documented: **a `--cut` matching no driven net is now a hard error.**
  *A census that silently found nothing would have reported untreated
  numbers as treated, into the Captain's morning.*

⭐ **THE SHARPEST INSTANCE THE DAY PRODUCED IS THE LAST ONE, because the
string was IDENTICAL all three times.** Recovering the migration
transcripts required three fixes, and every failure printed the same nine
words:

```
  1. hostname unknown     jaoquin.local — the typo is IN the hostname, so every
                          probe (joaquin/macbook/jyh-laptop/mDNS) came back empty
  2. key not authorized   fixed by the human; `ssh -v` then reports
                          "Server accepts key: ...SHA256:NIb/WCce..."
  3. key is ENCRYPTED     Proc-Type: 4,ENCRYPTED — signing needs a passphrase a
                          non-tty invocation cannot supply.  STILL OPEN.
```

**`Permission denied (publickey,password,keyboard-interactive)` was a true
statement at every layer and never once said which one.** Only `ssh -v`
distinguished them — `identity file id_dsa type -1` (unloadable) and
`Will attempt key: id_dsa explicit` revealed that this machine's
`~/.ssh/config` sets `IdentityFile` **globally, outside any Host block**,
so **the one key that cannot load is the only key ever offered.** *A
diagnosis that stops at the error text stops at layer 1 of 3.*

⇒ **Three seats independently arrived at the same fix, and it is not
vigilance:** pin the run **id**, name the **branch**, state the **window**,
cite the **path**, say which **machine**. *An instrument cannot be told to
mean the right object; the caller has to name it.*

---

## ⭐ PRE-REGISTRATION PAID OFF TWICE IN ONE EVENING — once on a measurement, once on a DECISION

The campaign pre-registered its measurement design before any data existed
(`docs/measurement-preregistration.md`). On the evening of day 1 the same
discipline was applied to two very different things, hours apart, by
different seats, and **both paid off within the same evening**:

| # | What was fixed in advance | What it bought |
|---|---|---|
| **1. A MEASUREMENT** — ruling 4a's readout | *the primary measure is the cone census, not the net name*, written down hours before either CI arm ran | **It stopped a confident wrong answer.** The name grep reads ABSENT in both arms; with the default census at 87.5% in both, the table lands on row (b) *"CI strips it"* — the expensive outcome. **The truth is row (a).** |
| **2. A DECISION** — the maestro's K3 ruling (19:10) | *"(C) now, with the decision rule PRE-REGISTERED so no second ruling is needed"* — the trace was ordered **together with the rule for interpreting whatever it found** | **It eliminated a round-trip on the critical path.** Math ran the trace, hit verdict (B), and **applied the rule without returning to the maestro** (19:24, `a593646`). |

**The second is the interesting one, because nobody planned it as a
methodological act.** The maestro was avoiding a second round-trip on a
busy evening; what they actually did was **apply the campaign's central
epistemic rule — fix the readout before you can see the answer — to
governance rather than to instrumentation.** A ruling that names its
decision rule in advance cannot be bent by the result that arrives.

⇒ ***A decision rule chosen after the data is a decision rule chosen by the
data*** — the exact sentence already in the README about measures, and it
turns out to be true of rulings too.

---

## LEG 1's EVENING — the knee of the curve, and a deferral that is a result

**TS-1 + TS-2 collected 82% of the entire `log(1/c)` prize — 631.58 → 86.23
— for roughly 140 lines of new mathematics.** The residual (86 → 52) that
TS-3 would have bought for **600–900 class-C lines** is worth **0.05% of
the consuming threshold**. TS-3 is **deferred**; TS-3-PREP is banked as the
only artifact.

**The demand-side trace is what made that visible**, and its finding is
sharper than the deferral: there *is* a committed consumer and the
repulsion ceiling *is* non-substitutable for it — **but the demand is
quantitative in `b`, not in `log(1/c)`.** Driving `log(1/c)` to **zero**
moves the consumer's threshold by **0.27%**; `b : 680 → 210` moves it by
**10.5×**. So the wave that would matter is a **`(b, k)` wave**, and
TS-3-PREP — dispatched three hours earlier *because it was valid under
every outcome* — turns out to be its precise prerequisite.

⭐ **AND THE DEFERRAL CORRECTED THE DOCUMENT THAT ORDERED IT, in the
direction that makes the landed work matter MORE.** TS-0's K3 analysed the
Range-A EF ledger, which the trace confirms is **dead** — five exits all
terminating in roll-calls. But the **live** obligation is HB's Lemma-3
machinery, and there the artillery **is** load-bearing: without it
`hbCoreRate` returns `≍ L/c₀` and Lemma 3 is **vacuous**. So *"the
repulsion contract is not load-bearing"* was **true of the ledger K3 looked
at and false of the road as a whole** — the fourth correction to a binding
document in one day, and the only one that *increases* the value of work
already landed.

⚠️ **NOT CERTIFIED, and the seat said so unprompted rather than letting it
drift:** no Lean anywhere composes `one_sub_ceiling_le_dist_one` with
`hσ'r`, so **the 0.27% / 10.5× arithmetic is a hand derivation from two
landed statements, not a kernel-checked composition.** *Strong enough to
defer a wave on; not strong enough to quote as a theorem.* **A number that
gates a decision and a number that can be published are different objects,
and this file must never blur them.**

> **The honest summary, in the seat's own words:** *"We stopped at the knee
> of the curve, and we only know that because we spent an hour measuring
> the demand side before spending the day on the supply side."*

---

## A DERIVED FIGURE WRITTEN DOWN AS A FACT — three instances in one evening

All three were caught by someone **re-deriving** rather than re-reading,
and all three are the same defect wearing different clothes.

| The figure | What it needed | How it failed |
|---|---|---|
| **"13 days"** to the tapeout deadline | its **date** | True at no moment at all — a transposition of **31**. It travelled silicon → maestro → **the Captain's standing charge** in four minutes. My own scoreboard header carried the same defect honestly computed: *"(32 days)"*, true at T0 and wrong every day after. **Deleted rather than corrected — correcting a countdown just restarts its decay.** |
| **"23 commits"** in a muster ledger | its **window** | Not wrong: **25** touched compiler's slot that **day**, **13** in the post-relight **session**. Two documents, two windows, neither stating which. *Compiler: **a count without its window is the same defect as a countdown without its date**.* |
| **a GENERATED lane table** | its **regeneration command** | `landed.py` exists *because* hand-maintained tables age — and **its output aged too**: compiler moved **23 → 25 in six minutes** between generation and re-run. ⇒ ***A generated table stops being generated the moment it is pasted into a document.*** The tool built to fix the aging problem inherits it at the copy boundary. |

⇒ **The rule, and it costs one clause:** publish the **date** with a
countdown, the **window** with a count, and the **command** with a
generated table. *Everything else is a snapshot presented as a property.*

⭐ **AND THE EVENING'S BEST EVIDENCE THAT THE DISCIPLINE IS REAL RATHER
THAN STATED:** the muster ledger's figures were **independently recomputed
by the two seats they describe, before they reached the Captain, including
the flattering ones.** Silicon's own words: ***"I do not get to accept a
flattering number just because someone else generated it."*** One came back
exact (2,503 = 2,503); the other exposed a units mismatch that both sides
had been prepared to call noise. **A ledger nobody checked is a ledger
nobody has reason to believe.**

---

## CONVERGENT FINDING #2 — two seats fell into the same selector trap ninety minutes apart

**"The latest run" is not a well-defined object**, and both seats watching
TinyTapeout's CI discovered it independently by being handed the wrong
answer.

| Seat | The selector | What it would have reported |
|---|---|---|
| **silicon**, ~18:1x | monitor keyed on **branch** | two `gds` runs existed on `main` — their `(* keep *)` arm A and the template's initial commit — so the terminal condition **could have reported the template's failure as their arm's result** |
| **evidence**, 19:07 | watcher keyed on **recency** (`--limit 1`) | fetched the newest run *by creation time*, which was **silicon's `layout-obstructions` column experiment on another branch, created 13 minutes before the event being measured** — and printed it as a four-job verdict |

**Both selectors were reasonable. Both returned a neighbouring
experiment and called it the answer** — and in both cases the output looks
exactly like a result: a run id, four job names, four conclusions.

⛔ **The evidence instance is the sharper one, because the claim being
checked was ABOUT staleness.** That seat had written, three minutes
earlier, *"a run that finished before the fix is not evidence about the
fix"* — and then built an instrument that served it precisely that.

✅ **The fix both seats converged on: pin the RUN ID, name the branch, and
check the timestamp against the event.** Silicon caught theirs, stopped the
monitor and re-armed on explicit ids; evidence retracted before the number
spread.

⭐ **AND THE CLOCK CORRECTION THAT CAME OUT OF IT — run-creation time is
the wrong boundary.** `viewer` runs **last**, under `needs: gds`. So what
decides whether the GitHub Pages blocker is cleared is **when the JOB
executed, not when the RUN was created**: a run begun while the repo was
still private can have its Pages step fire after the flip and succeed.
*The coarse framing — "this run predates the fix, ignore it" — was wrong in
a way that would have discarded a valid answer.*

---

## ONE-WAY ACTS — the class with no protocol, named 2026-08-06 19:07

**The fleet announces before taking the build lock, which protects a
REVERSIBLE resource, and announces nothing before acts that cannot be
undone at all** — flipping a repo's visibility, pushing to a public remote,
submitting to a shuttle, sending mail.

Found the way these things are found: the Captain's order to make the
tapeout repo public reached two seats, and **both executed it, within the
same minute.** No harm — setting a public repo public is idempotent — **but
nothing in the order or the conventions made it so.**

**The sharpest form is silicon's, about themselves:**

> ***An announcement that follows an irreversible act is a record, not a
> coordination mechanism.***

They announced at 19:04, *after* executing; evidence audited the repo's
entire history for secrets, outside-domain authorship and lane markers
*before* flipping — **and still failed to check whether anyone else was
already doing it.** *One seat coordinated on content and not on actors; the
other announced too late to coordinate at all.* **Had the audit found a
leak mid-flip, the "executed" post would have arrived after it mattered.**

⇒ **PROPOSED (maestro to rule): the take/release discipline the build lock
already has, extended to one-way acts — `TAKING: <act>` on the bus before,
result after.** One line, and it is the same discipline that stopped two
seats colliding on the shared git index this morning.

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

## DOES THE CLOCK DRIFT CORRUPT THE DELIVERABLE? — MEASURED, AND NO

Four seats stamped bus posts up to 2 h into the future today. Leg 1's
deliverable *is* "a timestamped ledger", so the question is not academic
and nobody had answered it. The math seat measured it (11:58) rather than
speculating, and the boundary is exact:

**References to `FLEET.md` across `docs/ledger-tools/`:**
`fleet_hygiene.py` **12** · `human_time.py` 0 · `landed.py` 0 ·
`ledger_common.py` 0 · `silence_windows.py` 0 · `token_meter.py` 0 ·
`selftest.py` 0.

| Surface | Verdict |
|---|---|
| **The deliverable** — token report, silence windows, human-time blocks, the LANDED table | ✅ **CLEAN.** Times come from **session-transcript records** (`rec["timestamp"]`) and **git**. Neither is typed by a seat, so neither can inherit our drift. |
| **The watchdog** — `fleet_hygiene.py` | ⚠️ **NOT clean by design** — it *parses* bus stamps (`scan_fleet_md`), which is exactly why it rendered negative ages. **A defect in the instrument that reads us, not in the record of what we did.** |
| **Human-facing prose** — narrative "at 13:52 we…" in publishable docs | ⛔ **NOT clean.** Wrong by up to two hours, in documents intended for publication. **This is the live exposure and it is mine.** |

**The rule that retires it, and it is `landed.py`'s rule generalised:
a stamp nobody types is a stamp nobody can drift.** Every narrative time in
a published document should cite a commit, not a bus post. The flagged
causal chain in the defects table above has been re-derived that way — it
reads **39 min 51 s** by commit clock, not the "100 minutes" and then "two
hours" I published from bus stamps.

---

## ⚠️ THE HISTORY PURGE IS A FORCE-PUSH, AND IT DANGLES EVERY SALT SHA WE CITE

Raised by the math seat (13:17), flagged rather than ruled, and it lands
squarely on this file. **salt's purge rewrites ~57% of its history — every
SHA changes.** This campaign has spent the day building artifacts *keyed on
SHAs*: the scoreboard, the bus, the flags entries and `landed.py`'s
generated table all cite commits by hash. **After the purge those citations
point at objects that no longer exist — in the very artifacts whose whole
value is that a skeptic can check them.**

**THE SCOPE, MEASURED, because it is narrower than it first reads:**

| Repo | Author emails | Purge exposure |
|---|---|---|
| **saltworks** | `jasonh@gmail.com` 78 · `the pre-remap address` 6 — **zero outside-domain commits** | ✅ **NONE. Born clean** (as Amendment 2 Correction 4 said it would be). Every saltworks SHA in this file survives. |

⛔⛔ **THAT VERDICT IS TRUE ON THE AXIS IT MEASURED AND FALSE AS A SENTENCE —
CORRECTED 2026-08-08 10:2x, and the axis it missed covers nearly half the repo.**

*The table above measures ONE axis — author email — and declares saltworks purge
exposure `NONE`. **It never measured session trailers.***

```
AXIS 1  AUTHOR EMAIL      re-measured 2026-08-08:  jasonh 558 · silicon-acct 6 · outside-domain 0
                          ✅ the NONE verdict STANDS on this axis
                          ⚠️ (the table's "78" is stale by ~7×; total is now 564)
AXIS 2  SESSION TRAILERS  264 of 564 commits carry `Claude-Session`
                          ⛔ NEVER MEASURED — and it is ~47% of the repo's history
```
🔑 ***A purge planner reading "saltworks: exposure NONE" concludes there is no
saltworks purge work. There is: 264 commits carry a trailer, sixteen of them
landed on 2026-08-08 alone, and six of those sixteen are this seat's own.***

⚖️ **THE CONVENTION AND THE BACKLOG ARE DIFFERENT OBJECTS** *(maestro, ratified
10:23 after this seat refuted the original justification — "a right ruling on a
wrong reason is half a ruling; it now has the right reason")*:
```
CONVENTION  future commits carry no trailers   ✅ settled 10:21, costs nothing,
                                                  and it stands on its MERITS —
                                                  new trailers only grow purge scope
BACKLOG     the 264 already in history         ⛔ PURGE-SCOPE. Not fixed by a
                                                  convention. Recorded here because
                                                  this file is what a purge planner reads
```
📌 **ACTION, one line in the purge brief: *strip session trailers* joins the
purge's scope alongside the author-domain rewrite.** *And the count grows every
day the convention is mistaken for something retroactive.*

⭐ ***AND THE SHAPE IS DAY 3'S OWN PRINCIPLE, IN THIS FILE, IN THIS SEAT'S
HANDWRITING: a `NONE` that is a TRUE reading of an adjacent object — the author
axis — standing where a reader will take it for the whole question.*** *It sat
here unchallenged because nobody, including its author, asked "exposure to
WHAT?"*
| **salt** | **1,108 of 1,995 under the outside domain** | ⛔ **Total.** Every salt SHA dangles. |

This file cites **25 short SHAs**; the salt-side ones — math's source-sweep
commits, the flags deliveries — are the exposed set.

**THREE SHAPES, cheapest first (math's, and I agree with their ranking):**
1. **Purge BEFORE the ledger is finalised, then regenerate everything
   SHA-keyed.** `landed.py` already *generates* rather than hand-maintains
   — **which is exactly what makes this survivable.** *A table you
   regenerate is a table that survives a rewrite*, the same argument as *a
   stamp nobody types is a stamp nobody can drift.*
2. Keep a **frozen pre-purge mirror** so old citations resolve.
3. Cite by **tag + subject line** rather than SHA in anything published.

**I lean (1) as well, and note the reason it is available at all: the
generator was built this morning to fix a staleness problem, and it turns
out to solve a rewrite problem nobody had raised yet.** The hand-maintained
version of this table would not have survived either.

⚠️ **And I am part of the exposure I am describing** — as math said of
themselves. Every salt SHA in this file is mine to regenerate or reframe.

---

## OPEN RULINGS OWED

| # | Question | Owner |
|---|---|---|
| 1 | ✅→⛔ **RESOLVED AT 18:11 AND IMMEDIATELY REPLACED BY A CIRCULAR ONE.** The Captain ruled *"#1: yes"* — the public TT repo was created (`jyh/tt-verified-banyan-switch`), and **within four minutes both `(* keep *)` arms were running in TT's CI**, which closed ruling 4a by 18:36. *The dependency flagged here at 17:17 was real and it cleared in twenty-five minutes.*<br><br>⛔ **THE NEW BLOCKER, and it is the campaign's tightest constraint tonight: the ruling's own condition is UNREACHABLE.** The ruling was *create private, flip public once CI is green.* But the `viewer` job deploys to **GitHub Pages**, and `POST /repos/…/pages` returns **`422 — plan does not support GitHub Pages for this repository`** *because the repo is private.* **`viewer` lives inside `gds.yaml`, so its red reddens the whole GDS action — and TT's rule is that a project cannot be submitted to a shuttle with a failing GDS action.** ⇒ **CI cannot go fully green while private, so "private until green" can never be satisfied.**<br><br>✅ **Every substantive gate has already passed** — precheck PASS, **GL TEST PASS against the POWERED post-layout netlist on our 255-scenario bench, the same 255 the kernel proof quantifies over**, docs PASS, RTL test PASS. **The one red is a billing-plan artifact, not a design fault.** Resolution is one bit: **flip the repo public now** (Pages works on public repos at any plan) **or upgrade the plan.** Silicon has correctly declined to reinterpret their way past it. | **JYH / Captain — one bit, and it gates September** | The public repo's **name** and its Apache-2.0 / public status (contractually mandatory for TinyTapeout). Original framing was "a publication question, decide later". **It is now the thing gating ruling 4a's CI arms** — `(* keep *)`-through-TT-CI needs two GDS-action runs, the GDS action runs in *TinyTapeout's* CI, and that needs the public repo to exist. Silicon has the **local** A/B done; the arms that answer the question are blocked here. ⚠️ **And ruling 4a's own confound 5.2 makes the delay compound rather than merely postpone: `tools-ref` is a floating branch and it MOVED on 8/6, so the two arms must be fired CLOSE TOGETHER.** Every day this sits, the window in which a clean A/B is possible has to be re-opened from scratch. | **JYH — and it is no longer only a naming question** |
| 2 | The README verb in the price exhibit — "bought access to" until submitted *and* accepted | JYH |
| 3a | ✅ **THE SIZING QUESTION IS ANSWERED, AND THE ANSWER IS "NO CORRECTION CONSTANT AT ALL".** Compiler published a rule that a cap of `N` permits about **N + 300 MiB** of RSS (309 MiB, anchored on one measured point, fitted across four). **Silicon refuted it on compiler's own published criterion:** the 309 predicted `C* ≈ 8098` and a PASS at 8200; **8200 failed**, and silicon then **bracketed the true threshold to 10 MiB on an 8.4 GiB run — `C* ∈ (8400, 8410]` against RSS 8407.** ⇒ **`E ≈ 0`: THE CAP THRESHOLD IS PEAK RSS. Set the cap from a measured peak and apply no correction in either direction.** ⭐ **AND THE METHOD IS THE LESSON, sharper than the number — compiler said it of themselves:** the 309 *"was never a measurement at all"*, obtained by **SUBTRACTING TWO INSTRUMENTS** (`ru_maxrss` from `/usr/bin/time`, minus the cap a run died at) and calling the difference a property of Lean. **Silicon measured the threshold DIRECTLY, by bracketing the cap until it flipped** — a method that *needs no theory of what the counter counts and cannot inherit an error from either instrument.* And the trade it was feared to force is not real: **D4 chunks to 8.2 GiB and gets 30% faster**, so any cap ≥ 8 GB is safe for chunked D4 while monolithic D4 peaks at **18.2 GiB** — the motivating datum for the post-wave lakefile decision. *Original text below.* — was: ⛔ **THE SUM-CAP SAMPLE IS BIASED, AND THE BIAS IS MINE.** I posted 23.3 GB / 5 processes as *"the number the sum-cap ruling needs"*. **It is not — not yet.** Math caught it: the sample's **maximum single RSS is 6.7 GB**, while the maestro's own 09:22 standing order names **`TBalTall`/`TBalR8` as "the 8+GB elaborations"** — *which is why that seat was told to stand down.* **Those files are not in the sample.** Every measurement today was taken while the math seat was under a no-Lean order, so **the fleet's empirical maximum is drawn from precisely the workloads that were allowed to run.** A cap chosen from it could kill a legitimate build.<br><br>**The arithmetic, on 64 GB with 5 concurrent children observed:** `-M 12000` permits 5 × 12 = **60 GB** (no margin, and unverified); `-M 8000` bounds them at **40 GB** and clears every RSS in my sample — **but would kill math's 20:00 build if the 8+GB figure is right.**<br><br>**RECOMMENDATION (math's, and I endorse it): if the ruling can wait until ~20:30 it gets the missing datapoint for free** — their full build is the measurement that closes it, and they have already committed to posting the combined footprint from my detector when they run it. **If it cannot wait, set it no lower than 12000**: an unverified cap that is too high is a *known* risk; a verified-too-low cap is a wave that dies at the gate for a reason nobody expected. | maestro — **ideally after 20:30** |
| 3 | ✅✅ **CLOSED, 16:30–16:52 — `-M` DOES BIND KERNEL REDUCTION. THE CAP IS REAL, and it closed in the direction we are NOT exposed in.** Compiler ran it as **three runs, and the third is the one that makes it a measurement:** ① control, same imports, **no** `decide`, `--cap 900` → **EXIT=0** *(which also re-establishes the Lean+mathlib baseline below 900 MB **on the Mini** — the machine-change question, answered for free)*; ② probe, one `decide +kernel`, `--cap 900` → **`(kernel) excessive memory consumption detected` in 1.04 s**, reproduced twice, and it is the **kernel** string of the two ratified wordings, so `whnf` allocation is genuinely observed; ③ **same file, `--cap 12000` → NO memory diagnostic at all**, running 60.65 s to 12.0 GB and dying instead of heartbeats. **Only the low cap produces the memory death — same file, same machine, one variable.** *Without ③ the verdict rests on inference from ①; with it, on the cap being the only thing that changed.* ⛔ **AND `maxMemory` IS NOT A LEAN OPTION** — `set_option maxMemory 900 in …` → `error: Unknown option \`maxMemory\``, refuting compiler's own 16:10 suggestion, which they had flagged as *evidence, not proof*. **So `[leanOptions] maxMemory = N` would NOT protect the build path; math's 09:40 answer — `moreLeanArgs`, which forwards real argv — is the route, and it is STILL UNTESTED.** Lakefile decision deferred post-wave by standing ruling. *Original text below.* — was: 🔓 **ONE LINE FROM THE MAESTRO UNBLOCKS THE WHOLE QUESTION.** Compiler has accepted math's redesigned test and will run it *within minutes* — but `saltbuild.sh` **hardcodes `-M 12000`**, so the small-cap variant would require invoking lean with a different cap, i.e. **bare lean**, which they will not do after three kills *least of all in the name of a safety test*. **Ask: add an optional cap override (`saltbuild.sh --cap 100 file.lean`).** It is the maestro's file and neither seat will edit it. **This is the cheapest unblock on the board and it gates a live safety question.** Original: **ESCALATED — the `lean -M 12000` cap is ALREADY LIVE on the wrapper's `*.lean` audit branch and is STILL UNVERIFIED.** Math's 10:35 concern is specific and serious: `-M` is enforced *inside Lean*, which is why it survives Darwin's rlimit gap — but a `decide +kernel` runaway lives in **kernel `whnf`**, which may not sit on the allocation path Lean's counter checks. If so, the cap is a **second no-op adopted on top of the first**, and the fleet is protected only in belief. **THE TEST IS NOW SAFE — math redesigned it at 10:58 after the compiler seat rightly refused the first version.** *"You do not need a big probe. You need a small cap."* The binding question is a **yes/no about a mechanism** — does Lean's `-M` counter observe kernel `whnf` allocation? — and mechanisms do not care about scale. So: ⚠️ **AND THE FIRST VERSION OF THAT REDESIGN WAS ITSELF WRONG — math caught it at 12:21 before anyone fired it.** `--cap 100` sits **BELOW** silicon's measured **~670 MB Lean+mathlib baseline**, so the process would die during *startup*, before any `decide` is reduced, and we would read that death as *"the cap is real"* — **a false PASS on the exact question being settled.** **CORRECTED DESIGN: the cap must sit ABOVE baseline and BELOW baseline + reduction — `--cap 900`** (670 baseline + 300–500 reduction), preceded by a sanity check that a **no-`decide` file SURVIVES** at the same cap. (a) dies with a Lean maximum-memory error → the cap is real, ruling closes; (b) sails past → `-M 12000` is **cosmetic for `decide`-shaped work**. A pass at 100 MB is evidence, not proof, that it binds at 12 GB — but **(b) would be conclusive in the direction we are exposed to.** Math runs it at 20:00 when their Lean pause lifts, ahead of TS-1, unless compiler takes it first. | math or compiler to test, maestro to rule |
| 5 | ⚠️ **NO LONGER BLOCKING (14:25)** — compiler can import Silicon's landed `Netlist` read-only, so EmitN can start. The ruling is still worth making, but it now only governs **where the type eventually LIVES**, not whether work proceeds. Original: **the shared netlist type has NO writer slot** — `SEATS.md` gives HDL to compiler and Silicon to jason, so the type **both legs must import may be created by neither**, and both seats have been filling the vacuum privately. **This is now the single thing gating leg 2's EmitN.** Compiler's request: a third slot (`SaltWorks/NF/**`), owned by one seat with the other read-only, and they recommend it live with **Silicon** since that copy is already landed and proved and needs only the output-list repair — *"I would rather import theirs than compete with it."* | maestro |
| 4a | ⭐ **THE CONSTRUCTIVE HALF OF "THE FLOW FLATTENS", and it belongs beside that finding rather than under it (`002abc1`, silicon, at their request).** **FLATTENING IS A FLOW SETTING, NOT A LAW.** Marking the stage boundaries `(* keep *)` makes them **survive synthesis as real nets** — `wire [7:0] w0; wire [7:0] w1;` appear in the netlist — at a **measured 1.7% area cost** (2,108 → 2,143 µm²). With those as cut points, **per-cone coverage rises 86.9% → 94.8%.**<br><br>**So: if you want the boundaries you reason about to survive to the fabricated netlist, ASK THE FLOW TO KEEP THEM.** Two percent of area is the difference between a netlist whose structure matches the design's and one optimised into a single 36-input cone. *The tools flatten by default; they do not flatten by necessity.*<br><br>🏆 **CLOSED **YES**, 18:36, ON THE NETLIST THAT WILL ACTUALLY BE FABRICATED** (silicon). Both arms hardened in TinyTapeout's own CI, both produced `tt_submission`, read in the pre-registered order.<br><br>**① TOOLING EQUALITY FIRST, before any result:** `pdk.json` **byte-identical**, `resolved.json` **zero differing keys**, `commit_id.json` differing in exactly two fields — *which arm it is*. **Confound 5.2 clear: the arms differ by the attribute and by nothing else.**<br><br>**③ THE CONE CENSUS over `tt_submission/tt_um_saltworks_banyan.v`:** at the boundaries, the treatment arm gives **80 cones, median 7 inputs, max 21 — 100.0% inside the 24-bit kernel ceiling**, against **36 / 87.5%** for the control and for both arms at the default cut. **② MECHANISM:** 16 boundary bit-nets all driven by a real cell output in A; **0 in B.** ⇒ **pre-registered row (a): the attribute survives CI and does the work** — *on the fabricated artifact, not on a local proxy.*<br><br>⭐⭐ **AND THE DESIGN'S CENTRAL CALL IS WHAT SAVED IT — THIS IS THE CAMPAIGN'S CLEANEST ARGUMENT FOR PRE-REGISTERING A READOUT.** The design insisted **the primary readout is the CONE CENSUS, not the net name** (*"the name is the mechanism; the census is the consequence"*). On the real artifact **`wire [7:0] w0` appears in NEITHER arm — vector-decls 0 and 0** — because `splitnets` deletes the parent vector and the survivors are `\fabric.w0[0]`…`\fabric.w1[7]`. **Run as a name grep, the treatment arm reads ABSENT; with the default census reading 87.5% in both, the table lands on row (b) — "CI strips it", the expensive outcome — when the truth is row (a).** *Two instruments, both reasonable, agreeing on the exact opposite of the truth.* **The readout that would have inverted the answer is the one a seat reaches for first.** | ✅ **silicon — closed** |
| 4c | ⚠️ **AND TWO NUMBERS THAT GET WORSE WITH FLATTENING, both load-bearing.** (1) **21 distinct cell types flattened, against 6 per element** — *synthesis reaches for a much wider cell set once it can optimise across boundaries*, so **THE TRUSTED MODEL SET GROWS WITH FLATTENING, NOT WITH DESIGN SIZE.** That is the mechanism behind the 15/13/68 spread measured across three real submissions, and it means "budget the tail" is about *flow behaviour*, not about how big your design is. (2) **The flattened fabric's cones reach 36 INPUTS** — one sliced net at 36 bits is **8.6 GB**, far past the 24-bit ceiling — and they are exactly the 8 `dout` cones, because the data path is combinational end to end so an output cone spans all three stages. **Per-cone certification of the FLATTENED fabric does not close by itself.** | — |
| 4b | ✅ **RESOLVED BY MEASUREMENT (`c5f804b`, silicon).** The cone answer is a plan, not a hope — and it was settled the way it should have been, by counting rather than by arguing. **1,626 combinational cones measured across NINE real TT submission netlists** (three built by librelane 3.0.5 for TTSKY26c itself): **86.8% have ≤ 24 inputs**, which is the hard kernel ceiling compiler established (`Nat.pow` is GMP-accelerated only to exponent `1<<<24`). **The decisive quantity is INPUTS, not gates** — a bit-sliced certificate costs 2^inputs bits per net, so gate count is nearly free. **For our own tapeout it is settled outright: every cone in the bit-serial switch element has at most SIX inputs**, the fabric is twelve copies of it, and the comparator maxes at 16 — *two orders of magnitude of headroom.* The ~13% tail (worst: 226 inputs / 325 gates, a register-file ECC design) **is real and is now stated rather than discovered later.** | — |
| 4b(old) | ⛔ **"Equivalence per module" has no modules** — post-P&R netlists are one flat module (measured, three real submissions). **First answer, offered by silicon at 12:31 for refutation rather than adoption: decompose by COMBINATIONAL CONE, not by module.** A flat sequential netlist partitions at the flop boundary — every flop D-pin and every primary output roots a cone of pure combinational logic; those cones are certified and composed structurally. It is available whether or not hierarchy survives, and *"it is why my reflection theorem quantifies over a `List Gate` rather than over a module — it never needed the boundary."* ⚠️ **What is missing is the measured cone-size distribution for a real 4–5k-instance netlist, which decides whether this is a plan or a hope.** That measurement is next in silicon's queue, ahead of the importer. | silicon to measure |
| 7 | ⚠️ **`κ` IS THE ONE THING IN THE SOURCE SWEEP REPORTED AS "STRUCTURE MATCHES" RATHER THAN "VERIFIED", AND IT HAS NO OWNER.** The math seat could not certify p.199's four-product `κ` formula subscript-by-subscript off a dense page rendering (`p∣q,p∤α` / `p∣α` / `p∤α,χ(p)=1` / `p∤α,χ(p)=−1`), and said so rather than letting it pass as checked. **Nothing in their dossier depends on `κ`'s internals — but `Salt/HB/Lemma7Kappa.lean:348`'s `hbKappa` does**, and W4.5 built it from Lemma 5. Their ask: *"whoever owns `Lemma7Kappa`, please re-read p.199's `κ` against `hbKappa` once."* **Five minutes against a definition already in the kernel.** Filed here because an item whose owner is "whoever" is an item with no owner.<br><br>✅ **NARROWED, NOT CLOSED (`c1985d8`).** The two checks that did *not* need a cleaner copy were done: **(i)** `hbKappa`'s docstring carries κ's four-product form exactly as the notes have it and the Lean body matches term for term; **(ii)** ⭐ **a deliberate hunt for a double-counting bug came back CLEAN** — HB's two *tail* products run over `p ∤ α` split by `χ(p) = ±1`, so primes with `χ(p) = 0` (i.e. `p ∣ q`) belong to the **first, finite** product and the tail factor must return 1 on them **or they are counted twice**. `hbSfac` is a three-way split with **`else ↦ 1`** and `hbWfac` returns 1 on `p ∣ α`: both junk branches handled, **and the `else ↦ 1` is load-bearing rather than a default.**<br><br>⚠️ **But this rules out an internal inconsistency, NOT a wrong transcription — and because `hbKappa` reproduces the notes exactly, a defect in the notes is inherited by the kernel verbatim. The risk is therefore LOCALISED to a single line of small type, and one read of p.199 discharges it FOR BOTH RECORDS AT ONCE.**<br><br>⛔ **BOTH CHEAP ROUTES ARE NOW SPENT AND THE NEGATIVE RESULT IS RECORDED** (`030fb88`, 11:51): the page image cannot be read subscript-by-subscript, and the PDF's **text layer** — tried precisely because nobody had — is *good for prose and destroys displayed mathematics*. It usefully **re-confirmed the hypotheses, `A(p) ≪ log p`, `A′(p) ≪ B log p`, `C₀ independent of d, ≪ BL`, and the (2.3) choice through a second independent channel** — but **every factor and every exponent of `κ` is lost**; only a weak trace of the four-product split survives. **This now needs a cleaner copy or human eyes, and nothing else will do.** *"I would rather leave one honest gap than manufacture a third approach that also cannot answer it."* | **needs a human or a cleaner copy** |
| 6 | ✅ **CLOSED — THE IMPORT DEBT IS PAID** (`c2993bf` + `b5bc1dd`, maestro 16:50). `SaltWorks.Silicon.Equiv.FabricRoutes` (D4) and `SaltWorks.HDL.EmitN` are in the hub — `Dense` made **explicit** rather than left to ride transitively, so the fence survives an import refactor — and the default build is **8,602 jobs green on the Mini**. **All three legs are now checked by a default build**, which is the property the original row said was missing. *Original text below.* — **was: SEVEN modules owed** (`Silicon.Cells.Sky130`, `Equiv.{BitSliced, Columns, ComparatorEquiv, SwitchRefinement}`, `Imported.{Comparator, RefComparator, Switch}`). All build green **targeted**; none is in `defaultTargets`, so **a default build still does not check the landed Silicon leg.** Original text: — `SaltWorks.lean` imports only `SaltWorks.Banyan.SelfRouting`, so **the entire landed Silicon leg (5 files, ~750 lines, the reflection theorem and every `#audit_axioms` block in it) is outside the default build.** The green build currently compiles one file. Owed: `Silicon.Equiv.BitSliced`, `Silicon.Equiv.Columns`, `Silicon.Cells.Sky130`, `Tactic.AuditAxioms`, `Banyan.Facade`. | maestro (hub is MAESTRO ONLY per `SEATS.md`) |
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

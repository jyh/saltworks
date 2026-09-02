# QUEUE.md — the fleet queue (maestro-owned; seats PULL at seams)
### Born 2026-08-08, Captain-ratified in session: "we try to address
### structural issues, coarsening the dependencies where possible,
### giving each seat multiple options, and preauthorizing where
### possible too." Maintained by the maestro AT EVERY RULING; seats
### read it at every seam. The bus still carries orders; this file
### carries STANDING work so an empty queue self-refills without a
### dispatch.

## THE SEMANTICS (read once, they are the point)

- **PRE-AUTH** means: pull it at your seam WITHOUT ASKING. Post one
  line when you start and one when you land. Redirection may arrive
  at any time and costs nothing — corrected work has already paid
  its exploration value (the Captain's principle, 8/8: "the simple
  act of working has exploration value, even if you need to
  correct it").
- **GATED(x)** means: do not start until x. Coarse gates only —
  a gate names a landing or a word, never a micro-step.
- **TRACKS**: each seat carries at most ONE write track live (the
  shared tree and the lock make two pens per seat dangerous) plus
  any number of READ tracks (refutation passes, censuses, reads —
  lock-free, suspend-free) plus SPECULATIVE work (probes — always
  authorized, quota-only, results may be parked).
- **STEALING**: author-anywhere, LAND-AT-OWNER (patch-to-owner, run
  three times 8/8: hinge math→compiler, MIGPATCH math→compiler,
  phase-3 residue compiler→math). Labor moves; the owner runs the
  controls and lands. Read-work floats freely — any seat may refute
  any block.
- **PRECONDITIONS (optimistic concurrency — the Captain's frame,
  US9229774's discipline adapted 8/8)**: every WAVE BRIEF opens with
  its assumed world — the constants it relies on, the spec sentences
  QUOTED (never line numbers), the statement bytes, the files it
  expects unmoved — and the executor VALIDATES them against the
  live tree BEFORE starting, aborting-with-a-report on drift
  instead of proving against a ghost. Floating (stealable) work is
  claimed by one bus line naming the item + "unclaimed as of <last
  line read>": the append-only bus serializes claims and a later
  claimant self-rejects. The policy split, named: validate-BEFORE
  for expensive transactions (waves, deletions, tapeout decisions);
  validate-AFTER (draft-until-refuted) for cheap ones (docs, where
  amendment is measured-cheap). Partitioned tracks keep conflicts
  rare; the cheap commit-time check (build green, statement bytes
  unchanged) is universal.
- **THE BUS APPEND LAW NAMES METHODS (finalized 08-09 01:4x after
  the truncate-rewriter was found — compiler's pathlib.write_text,
  self-confessed with its blast radius measured): FLEET.md is
  written by `>>` (shell) or mode='a' ONLY. Banned on the bus:
  `>`, write_text, mode='w', mv/atomic-replace, sed -i — a
  whole-file rewrite opens a window where a concurrent reader sees
  an EMPTY file and a concurrent append is EATEN. The shrink
  detector (maestro, 0.25s) stands as the tripwire. AMENDED 8/10
  18:3x (night maestro, at silicon's owned incident): (a) BLAST
  RADIUS MEASURED — an UNQUOTED heredoc does not merely corrupt a
  post, it EXECUTES: one backtick ran a full 8,689-job build into
  the bus. `<<'EOF'` ALWAYS. (b) BUS SURGERY PROTOCOL, canonized
  from the repair that worked: ONLY the seat that injected noise
  may remove it, scoped by CONTENT anchors (own post header → next
  header) + line PREFIX (never line numbers, never global), with a
  pre-repair snapshot retained, a before/after POST census
  published (362→362 class), and the shrink alarm answered in the
  repair post's first bytes. Anything beyond self-injected noise
  is maestro-tier. (c) Claims race on the bus by APPEND ORDER —
  before claiming, grep -F the node name over the tail; a
  headline-watch read is not a claim check (the 18:25 M0
  collision: claim at :58120, "unclaimed as of :58126").**
- Laws that ride every item: saltbuild-only builds; pathspec-only
  commits; trailer-free; **A RESTATEMENT RENAMES (8/10 19:5x, ruled
  at math's name-vs-meaning find on its own M1 landing): when a
  declaration's STATEMENT changes meaning, its NAME changes with it
  — a stale citation to a deleted name fails LOUDLY at the first
  grep; a stale citation to a restated name resolves SILENTLY to a
  theorem the citing document never meant, forever. The namespace
  is subject to the same law as counts: a name survives only if its
  meaning does;** **CHECK THE ACTION'S OWN EXIT, NOT THE STATE
  AFTERWARDS (8/10 20:1x, silicon's line, registered at three-seat
  convergence — silicon/math/compiler each confirmed the idiom in
  their own hands, so the fleet-law refuter gate is satisfied by
  construction): a state check answers "what is true now", never
  "did MY command run" — in a shared checkout the two diverge the
  moment a peer commits; a failed command must never fall through
  to its own verification step. The compliant form does BOTH:
  `&&`-chain on the exit, then read the PAYLOAD (the shell-posts
  law's other half). SHARPENED 20:19 by compiler's deliberate-
  failure measurement: saltbuild.sh PROPAGATES A REAL EXIT STATUS
  (`exit $EXIT`, verified status 1 on a broken theorem) and PIPING
  THROWS IT AWAY (`$?` after a pipe is the last stage's). The
  canonical build form fleet-wide:
  `../saltbuild.sh <target> > /tmp/b.txt 2>&1 && tail -3 /tmp/b.txt`
  — never `| grep EXIT`, where an empty grep is indistinguishable
  from a pass;** unique Scratch<NODE>-<agent>.lean
  (per-AGENT); explicit-brief law for executors; the kernel-census
  aiming rider for any deletion; **SaltWorks.lean (the root) is
  MAESTRO-ONLY** — landings post "import owed" and the maestro wires
  + runs the full-build verdict (the one-hand rule; restated 17:32
  after a benign crossing).
- **THE CAP PICTURE (FOURTH REVISION, 08-09 12:0x — DEFAULT RAISED
  BY CAPTAIN RULING: audit form now `-M 24000` DEFAULT in the
  wrapper; the `--cap 24000` dance for known heavies is RETIRED —
  Immediate/Decoder/FabricRoutes audit at the default now). Module
  form unchanged: `-M 20000` PER PROCESS from `lakefile.toml`'s
  weakLeanArgs — the full build is NOT uncapped. THE RULE BY CAUSE
  survives with a new threshold: EXIT=134 at the 24000 default
  means a >24 GB module — a NEW weight class, worth a look rather
  than a bigger cap reflex; caps still do not move without a
  maestro ruling. History (third revision, 00:2x): the old 12000
  default + --cap dance, and the refuted symptom-list form. ✅ THE MACHINE-LEVEL QUESTION IS
  MEASURED, NOT OPEN (was stated here as an unmeasured 80-GB hazard;
  that rotted in the dangerous direction and is STRUCK): realised
  fleet peak 43.08 GB of 64 GiB (compiler 01:0x, scratch clone);
  the per-process 20-GB cap NEVER binds (~10.8 GB actual); the FLEET
  LOCK is the machine-level guard — it fits, and nobody should "fix"
  the cap on the strength of the old 80-GB arithmetic.** ADD-BESIDE
  remains good practice on its own merits. Caps do not move without
  a maestro ruling.

## MIGRATED — THE REFUTATION CHANNEL (closed by council ruling 5, 2026-08-23; destination ratified same day)

### The 7 design docs' `- SEAT:` rows are CLOSED to new obligations. Live rows
### migrated here by object-liveness audit (29 rows -> 16 live / 29 debts; every
### DISCHARGED verdict adversarially re-checked, 5 of 15 overturned). Each row
### below names its DISCHARGING OBJECT — the row retires when that object exists.
### Source rows stay in their docs as HISTORY (three ruling-#7 probes quote them).

**MIG-P1 (finish-first, public-hygiene):**
- **MIG-1 · EVIDENCE · P1 — ✅ DISCHARGED (`b816275`, 19:47): the story numbers are ACTUALISED**
  (61,716,448 output tokens over the true 8-home union; the price actualised to the REGISTERED
  €840 with "receipt outstanding" stated — not laundered into an invoice). ⛔ Citation in the
  original row CORRECTED: the €840 lives at `ndf-top-module-design-v1.md:334`, NOT
  `ndf-account-priced-half.md:334` — a different file at the same line number; "a citation is
  not a reading" (evidence, 19:48). (original text:) the story numbers: `midnight-to-silicon-story.md:93-97`
  still read `~20M` tokens / `~$500 (TT)` while the NDF was SUBMITTED AND PRICED. The doc's own
  fence (`:99-100`) bars unmeasured numbers from public telling, and this repo is public. DISCHARGE:
  actualised rows in the story doc. Cheapest P1 here: the invoice is known.
- **MIG-2 · SILICON · P1 — ✅ DISCHARGED 2026-08-24 (silicon, `777aec9`): the read is folded into the doc, PROSE ONLY.** Duration-control CONFIRMED in the ISSCC sentence itself; O(1) cell state CONFIRMED (ISS90 §3.2, "every banyan element becomes identical"); k=8/256×256 CONFIRMED with the 4+4 made exact ("the components function as parallel 16x16 elements... two devices in one package"). ⭐ **THE CAPTAIN'S "first (or is it second?) bit" IS ANSWERED AND BOTH MEMORIES ARE RIGHT** — it is the first bit OF THE ADDRESS, which is the SECOND bit of the transmitted cell because the activity bit precedes it; a counting-origin ambiguity, not a faulty recall. ⚠️ **THREE CORRECTIONS OWED IN THE BLOCK** (maestro's doc, flagged not edited): "chip"→ELEMENT/DEVICE in the 4+4 sentence · "BUILT PRACTICE in 1990" over-claims the MACHINE (what was assembled was 64×64, ISS90 §4) · "generated per column" UNSUPPORTED and left OPEN. ⛔ **AND A FIREWALL DEFECT IN THE AUDITED BLOCK ITSELF: it instructs a check against "Figure 7's S2 trace" while this doc's own head is WORDS-ONLY-never-figures (standing 8/7 ruling). Struck as a method; prose settled the question without it.** — original entry follows:
- **MIG-2 · SILICON · P1** — heritage §0: the 25 lines added 08/10 (`fc09811`,
  Captain-recalled 1988-cell architecture) have never had a silicon read against
  Marcus & Hickey ISSCC 1990 WPM 2.4. DISCHARGE: a folded commit on the doc citing
  the read. The skew/timing half is already discharged (`cd903d9`, `ce16552`).

**MIG-P2 (the working tier):**
- **MIG-3 · COMPILER · P2 — ✅ DISCHARGED 2026-08-24 (compiler, `3adb4ab`): ROW A AS RULED IS VACUOUS, not merely unproved.** F2 (`Function.Injective encode`) is REFUTABLE — `State` is infinite, `St` is finite — so a proof of Row A in §2's form would certify nothing; kernel exhibit `no_injective_state_encoding`. (b) N0.5 has no AST constructor to inline. (c) N3 half-landed, exhibited by `cause_outside_the_fragment_is_now_ite_only`. Escalation trigger MEASURED: no `.tex` fleet-wide quotes Row A, stays P2. Refutation folded into `docs/lang-design-v1.md` §2. The landed `encodeOK` shape is CORRECT — this refutes the ruled TEXT, not the corpus.**
- **MIG-3 · COMPILER · P2** — lang-design §2/§3, 3 debts: (a) Row A's ruled
  function-equality conclusion vs the corpus (`CompileS.lean:1-27` says the landed
  shape is `encodeOK` + scoped register agreement — the ruled conclusion is not
  supplied and the file says it cannot be) — **rises to P1 if any paper quotes
  Row A**; (b) N0.5 "verified inlining" has no AST constructor; (c) N3 half-landed
  (`while` yes, `ite` refused at `CompileS.lean:306`) blocking N5. DISCHARGE: a
  written refutation folded into the doc. BEQ/offset sub-item ALREADY satisfied
  (`backOffByOne_diverges_on_a_stale_guard`) — do not re-commission.
- **MIG-4 · COMPILER · P2 — ✅ DISCHARGED 2026-08-24 (compiler, `c7d5547`): one filing, three debts, measured.** (1) ⛔ **NOTHING OWED — ALREADY DISCHARGED BY THE CORPUS**: `MemOrgan.lean` carries `memOrgan_gate_count`, the nIn/outs pin, and `memOrgan_exceeds_banked_budget` (the very comparison), with the unit settled in its docstring. My first filing re-derived it and called it a third axis; CORRECTED — it is THE axis, already reconciled. (2) **BNE is FREE and CHEAPER than BEQ**: `zeroTree`'s raw polarity is NONZERO (kernel-measured) = BNE's condition; BEQ pays the inverter — ⛔ but the compare occurs ZERO times in `CorePlace`/`CoreAssembly`, so the saving is UNPRICED at core level and placing a compare is a cost B1 does not carry. (3) Encoder extension = **0/1 gates** — free in silicon, cost is PROOF-side; ⛔ and *"the c1 organ"* is UNDEFINED (2 occurrences, both assignment lines). Exhibits: `SliceBPricedRefuted.lean`. E3 excluded — conditioned, not queued.**
- **MIG-4 · COMPILER · P2** — slice-b B1/B3: memory-organ cost in the emitted path ·
  BNE vs the landed compare organ · encoder extension vs the c1 organ. DISCHARGE: one
  filing covering the three. (E3 executive-as-program: see the register — conditioned,
  not queued.) Silicon's half already discharged.
- **MIG-5 · COMPILER · P2 — ✅ DISCHARGED 2026-08-24 (compiler, `717cc2d`): ①⁵ IS UNSOUND, not merely unlanded — IT REJECTS SIGN- AND ZERO-EXTENSION.** 5 landed certified blocks fail it (`sltCirc`/`sltuCirc` 2 distinct of 32 — zero-extended compare; `immICirc`/`immBCirc`/`immBshiftedCirc` 12–13 of 32 — sign-extended immediates); kernel exhibits in `WfPortsNodupRefuted.lean`, NO axioms, with a positive control. ⭐ **AND IT IS PROSPECTIVE, NOT RETROACTIVE: the bar binds NEW blocks, and Slice-B's own `LW/SW/JAL/JALR` all carry SIGN-EXTENDED immediates reusing the `immICirc` pattern — so ①⁵ would reject this block's OWN ROADMAP on arrival.** The doc's `b = 0` note was a DEGENERATE-case control and anticipated the wrong failure. Cost is trivial and not the binding constraint; ①⁵ composes cleanly with ①″/①‴ and is simply wrong. RETROFIT: 84 `Circ`-valued blocks corpus-wide, 15 measured (by import convenience, NOT sampled — 69 unmeasured, do not extrapolate). Repair left to §2's adopter: the intent is *accidental* aliasing, which `outs.Nodup` cannot express.**
- **MIG-5 · COMPILER · P2** — wf-ports clause ①⁵, 3 debts: composition with ①″/①‴ in
  `OperandBMux.lean:27-55` · decide-cost-at-scale for nodup certs · retrofit list.
  Note ①⁵ occurs exactly twice in the repo, both in the audited doc — never adopted.
  Carry-forward: unlanded `Circ.portsNodup` work is §2 DESIGN owned by its adopter
  (maestro), NOT math's debt; math's half discharged at the kernel (bus 08/08 13:42).
- **MIG-6 · MATH · P2 — ✅ DISCHARGED 2026-08-24 (math): THE 08/09 ANSWER IS FOLDED, AND IT LANDS ON ROW B, NOT ON `wellFormed`.** The row asked whether anything is c2-shaped or vacuously-true on the well-formedness side; the confirmed YES arrived as refutation passes #1 (08/09 08:45) and #2 (08:53), ~12 h after this doc's v1.1 fold, and was never written into `lang-design-v1.md`. Verified absent before folding — `imem` · `instruction memory` · `scope metric` · `vacuity` = **0 hits each**. Folded into §2 under ROW B in three parts: **(a)** Row B has its own vacuity mode that F1 does not kill — a PESSIMISTIC `liveMax` empties the ∀, both directions live (too pessimistic ⇒ VACUOUS, too optimistic ⇒ FALSE), carrying the **pre-registered demand that `liveMax` land WITH an exhibited non-trivial witness by `decide`**; **(b)** Row B's *"there is no third"* is a COMPLETENESS claim with a candidate third — **instruction memory** — so either imem capacity is a third hypothesis or a lemma proves it cannot bind, and today it is neither; **(c)** the structural point that outlives its witness — **`liveMax` is a SCOPE metric being used as a REGISTER-DEMAND metric**, coinciding only when expressions are flat, with the `poolSize = 1` witness read off the definitions. ⚠️ **PRE-REGISTERED, NOT PROVEN** — `compile` did not exist when the passes ran; when it lands the witness program must either compile or Row B needs a third resource term. §6's assignment now reads ANSWERED with a pointer to the fold. 📌 **The class, worth more than the row: the findings WERE folded into the compiler's cast of Row B and this document was never updated, so §6 sat reading OPEN for fifteen days — a question answered in one artifact and left open in another is indistinguishable, to the next reader, from a question nobody answered.**
- **MIG-7 · MATH · P2 — ✅ DISCHARGED 2026-08-24 (math): FINDING HELD — H2 IS c2-SHAPED, AND THE HIDDEN LEMMA IS THE COUNTER'S WHOLE-FRAME INVARIANT.** The check was COMMISSIONED as the row demanded (three independent checkers + adjudication, "no finding" explicitly permitted as a complete discharge), and the finding is HELD with a witness rather than booked on the prior refuter's untransmitted reason. **H2 states well-phasedness as a ONE-CYCLE coincidence — *"cycle 0 coincident with cnt==0"* — while every consumer needs `cnt == t` across `[0, 2k+P)`.** Verified at this hand: the strobes are a pure decode of `cnt` (`banyan_fabric.v:74-75`, `act_stb[s] = (cnt == 2*s)`); **`sof` IS a mid-frame counter-zeroing path** (`:58`, `else if (sof) cnt <= {CW{1'b0}};`) and §5 names it as one, while **H3 gives `rst_n` the mid-frame quiescence sentence and `sof` never gets it**; and the one Lean object modelling the schedule, `runFrame` (`FabricRoutes.lean:137`, `let cnt := 14 - (n + 1)`), **identifies `cnt` with the cycle index for all fourteen cycles and contains ZERO occurrences of `sof`** — it consumes exactly the invariant H2 does not supply. ⭐⛔ **AND THE MEASUREMENT SUPPLIES WHAT THE STATEMENT DOES NOT:** `drive_frame` sets `sof = 1'b0` on EVERY cycle of the frame (`tb_counter_init.v:141+`), so the quoted `0/200` was taken under an `sof` discipline H2 does not carry — ***a test of the case that cannot fail.*** **REPAIR belongs in H2, not a node:** state well-phasedness whole-frame and give `sof` the sentence `rst_n` already has. ✅ **TWO CLAUSES CLEARED, AND LOOKED FOR:** *"from ANY initial register state"* is **not** c2-shaped (it is the ABSENCE of a hypothesis, a ∀ that strengthens the theorem; the burden lands conclusion-side on §3's L0 and spec §5, both WRITTEN), and the **σ half stays CLOSED** — the strike's verdict is confirmed, only the rider's stated ground is loose. ⚠️ **NOTHING BUILT OR SIMULATED: the failing trace is HAND-TRACED, not measured.** The arm that would settle it empirically — a `sof` pulse injected at a random mid-frame cycle — does not exist. Rider folded into §2; §6's assignment closed with a pointer.
- **MIG-8 · SILICON · P2 — ✅ DISCHARGED 2026-08-24 (silicon, `9e01627`): NO MISQUOTE FOUND.** Every spec-derived claim in §1/§2 verified at SECTION + QUOTED SENTENCE against the current spec — and the pin was tested first: `55831de` is an ancestor, its spec blob is byte-identical to HEAD's, zero commits since. ⭐ **The highest-risk item is the cleanest: spec §5 warns consumers against citing the second-`act_stb` clause as the SOURCE of well-phasedness, and this block carries the amended sof-anchored form and names the old attribution REFUTED.** Quoted counts match spec §8 rows 6/7 exactly (`188/200`, `192/200`); rows 5–11 all present, mutant controls at 9 and 11. ⛔ **WHAT IS BROKEN IS THE CITATION LAYER, AND IT IS THE BLOCK'S OWN LAW: §5 adopts "SECTION + QUOTED SENTENCE, never bare line numbers" and records the repair AS BARE LINE NUMBERS — all four (`:361 :221 :232 :175`) have now rotted a SECOND time, `:232` onto an empty line, and the P-placeholder changed SECTION (→ §9), which no line number can express. The repair inherited the shape of the error it repaired.** Replaced with quoted sentences. — original entry follows:
- **MIG-8 · SILICON · P2** — payload-delivery §1/§2: re-read "does any spec fact
  misquote the protocol?" against the CURRENT spec (`55831de`) and current §8 rows
  5-11 — the prior discharge was taken against a doc version that no longer exists
  (moved seven times since). Don't-care-window half genuinely closed.
- **MIG-9 · COMPILER · P2 — ✅ DISCHARGED 2026-08-25 (compiler): ROWS A/B DO EXTEND TO LAYER CONFIGS — AND THE VERDICT INVERTS THE ORIGINAL DOMAIN.** Row A *as ruled* is VACUOUS (F2 unsatisfiable: `State` infinite, `St` finite — MIG-3), and a row that fails where it stands cannot be extended. ⭐ But that vacuity is a CARDINALITY fact, not a compiler fact (`no_injective_of_infinite_to_finite`), and a layer config is weights/routing for a FIXED fabric, exact in i32 — **FINITE**. ⇒ extension holds **iff `card Config ≤ card MachineState`** (`extends_iff_card_le`, both directions). **F2 changes STATUS not truth-value: REFUTABLE at tiny-Rust, SATISFIABLE-BUT-UNPROVED at configs — whoever takes A1 owes that count.** Verdict folded into the sketch §6; exhibits `LayerConfigRowExtension.lean`.**
- **MIG-9 · COMPILER · P2 — ✅ **OPENED-08/24** (Captain's word, maestro FLEET ORDER 18:41:50 ruling 2; bus line 168808) — GATE AS IT STOOD, KEPT VERBATIM BECAUSE A MARKER IS HISTORY: the GNN sketch fires nothing without the Captain's word: §4 is titled "explore at council, nothing fires tonight" and §6 is the Captain's second-dream dual, pulled at his word (§0). Unlocks on that word at a sitting; until then this row is NOT a debt and must not be started.**
- **MIG-9 · COMPILER · P2** — GNN sketch §6: the verdict "do Rows A/B extend to layer
  configs?" — rides with A1 (already in the compiler roster).
- **MIG-10 · COMPILER · P2 — ✅ DISCHARGED 2026-08-25 (compiler): SUCCESSION CONFIRMED, ADDRESS CORRECTED.** `A1 · the layer-compiler as Lean rows` IS the successor of neural-fabric §7's compiler row (content matches item-for-item). ⛔ **BUT IT IS NOT A QUEUE ENTRY — `docs/QUEUE.md` HAS NO A1 ROW.** A1 is defined at `docs/aim-high-application-v1.md:208`; the QUEUE carries A1 only in dependency chains and the MIG-C2 rider. ⚠️ **A1 SHIPS FENCED — WHEN DRIVEN until V9's run-level refinement closes; the fence rides with the address.** Confirmation folded into neural-fabric §7.**
- **MIG-10 · COMPILER · P2 — ✅ **OPENED-08/24** (Captain's word, maestro FLEET ORDER 18:41:50 ruling 2; bus line 168808) — GATE AS IT STOOD, KEPT VERBATIM BECAUSE A MARKER IS HISTORY: its subject is `neural-fabric-poc-design-v1.md` §7, whose own heading is "OPEN QUESTIONS FOR THE SEAT REVIEW (fire on the Captain's word)". Unlocks when that review fires; until then this row is NOT a debt and must not be started, address-confirmation included.**
- **MIG-10 · COMPILER · P2 (address-confirmation ONLY)** — the layer-compiler as Lean
  rows IS the successor of neural-fabric §7's row; this line confirms the A1/GNN
  QUEUE entry as its address. No new load.
- **MIG-11 · EVIDENCE · P2 — ✅ DISCHARGED (`bc491d9`, 21:16): the named "OS" wording DOES NOT
  EXIST** (1 occurrence in the doc — the debt row itself; v1.1 already says EXECUTIVE and
  "cooperative-v1"). Discharged by CLAIM-SCOPE AUDIT, not by word-absence — and the audit found
  **two real travel gaps, routed to their owners on the bus:** compiler's isolation cert covers
  REGISTERS while E2 claims registers-AND-MEMORY · the fairness that exists is PREEMPTIVE while
  E2's v1 needs COOPERATIVE. Those live in the owners' lanes, not as new rows here (the channel
  is closed).
- **MIG-12 · EVIDENCE · P2 — ✅ DISCHARGED 2026-08-24 (evidence, `f98b17b`): FILED at
  `docs/EVIDENCE-sliceb-price-prereg.md`; the row's own instrument agrees — `ripen.sh` now
  reports `FILED — no longer ripening`, exit 0 (was exit 1, RIPE).** ⛔ **AND THE ANCHOR THIS
  ROW GAVE IS UNDEFINED AND, ON ITS ONLY AVAILABLE READING, UNSATISFIABLE — reported rather
  than papered over:** the phrase *"the LW/SW silicon integration's 2026-09-07 update window"*
  occurs in exactly TWO places in this repo and both are this debt itself; nothing defines it.
  The only object carrying that date is the TinyTapeout TTSKY26c shuttle, **which OPENED
  2026-05-26** — so *"file BEFORE that window opens"* was already three months unsatisfiable
  when written. **The re-anchor reproduced the exact defect FIX 1 forbids, one layer up: a noun
  phrase in the ANCHOR instead of the FREEZE.** *(The TinyTapeout identification is evidence's,
  rests on a shared date alone, and is labelled as such in the filing. If a different window was
  meant, the ANCHOR is wrong and the repair is a NEW filing, not an edit.)* ⇒ **Filed against
  the window's CLOSE (`2026-09-07T20:00:00Z`, 14 days future), so every figure is unknown at
  filing.** 📌 Also recorded: the naive freeze *"the first Slice-B piece to land"* **HAS ALREADY
  FIRED** — `HDL/Executive.lean` 2026-08-08, `ExecutiveX0/X1/X2` 08-10, `Certs/Executive.lean`
  08-11. — original entry follows:
- **MIG-12 · EVIDENCE · P2 — THE SLICE-B PRICE-CRITERION PRE-REGISTRATION, RE-ANCHORED
  (Captain, 2026-08-23 evening sitting: "yes (b)").** The original ④-form registration
  (`EVIDENCE-campaign.md:963`) was owed "BEFORE any wave"; **that window lapsed** (ruling
  #3, the LW/SW landing) — stated here so the re-anchor is honest, not a silent slide.
  **FREEZE EVENT (executable, repaired 2026-08-24 by evidence per the helm's 15:42 order — the original phrasing was a noun phrase AND its condition was impossible): the TT shuttle submission cutoff `2026-09-07T20:00:00Z`.**
  DISCHARGE: evidence files the pre-registration BEFORE that cutoff; until filed, Slice-B
  pricing claims carry no fence and must say so. ⛔ *The superseded text read "BEFORE that
  window opens" — unsatisfiable, since the shuttle window opened 2026-05-26. Council 08/24
  confirmed the intent was the SUBMISSION CUTOFF.*

**RETIRED UNDER RULING #7 (Captain's word at the 2026-08-23 evening sitting: "yes retire") —
4 rows / 6 debts on the paths ruling #7 (2026-08-09) passed over when it chose the
bit-serial Design-B direction. Each names its successor or says none exists:**
- **RET-1 · SILICON · sketch §5 (3 debts)** — Design-A neuron-tile cost, per-family
  scaling table, RTL reverse-flow for gradient packets. Successors: the priced Design-B
  bit-serial cell (`neural-fabric-poc-design-v1.md:26`, ~500 cells) for the cost rows.
  ⛔ **THE REVERSE-FLOW SUB-ITEM HAS NO SUCCESSOR — stated per the tombstone law: none
  exists.** If gradient transport ever returns to the fabric's scope, it returns as NEW
  design work, not as this row.
- **RET-2 · SILICON · sketch §6 (1 debt)** — tropical-vs-weighted element cost. Retired
  by the row's own offered alternative, which no document had said until now: **ruling
  #7's bit-serial path retires the comparison.**
- **RET-3 · MATH · sketch §6 (1 debt)** — max-plus / subgradient statement forms. Its
  second half is discharged the hard way at the kernel (sorter certificates as
  nonlinearity lemmas: `Stack/Perm.lean:74`, `HDL/SortDemo.lean:50,52`; unsigned-order
  defect recorded `SortDemo.lean:63-65`, repaired `SerOrgan.lean:23`) — that discharge
  stands independent of the retirement.
- **RET-4 · COMPILER · slice-b E3 (1 debt)** — executive-as-program feasibility, split
  from MIG-4. Successor: none needed — the executive ships as the cooperative
  non-OS the doc itself describes; feasibility-as-program was Design-A-era scope.

**CONDITIONED (ruled 2026-08-23, tier P3 stays empty by the 08/16 re-tier):**
- **MIG-C1 · MATH — ✅ DISCHARGED BY WITHDRAWAL (math, 2026-08-23 19:24, verified not
  merely accepted: the layer-level adjoint row carries the semantics; F7-A referenced
  nowhere else in either repo).** Bus receipt at offset ~23.36M.
- **MIG-C2 · COMPILER — ripens-when rider on A1/layer-compiler:** when the
  layer-compiler EXISTS, compiler owes the source-to-source tangent/adjoint
  feasibility page (nothing can consume it earlier). The trigger lives here, on the
  item whose landing fires it.

## COMPILER

- W1 · WRITE · **CLOSED 15:40 (d85e13a)** — phase 3 complete: census
  PASS 75 / FAIL 0 / UNREACHED 0; constants at the ruled pair;
  SelectCut32 restated over generator instances (the kernel-checked
  −1154 preserved); ruling-to-close in one day.
- W2 · WRITE · **FIRED 15:51 (all gates down)** — ③ waves L0/L1/L2
  in the HDL slot, statements per v2.3 (P=8 scope; H1–H4 in full;
  three undecided cases; claim-gated-OR transparency; ∀-P off
  runFrame traces); precondition preambles mandatory.
- R1 · READ · **DISCHARGED 15:50** — the last ③ gate read (one
  load-bearing refutation, folded as v2.3; the waves dispatched on
  it).
- R2 · READ · **DISCHARGED 17:25** — the last ④ read (the +1-cycle
  price revived as a causality floor; piece 5 re-founded over
  testBit; folded into the heritage doc).
- W3 · WRITE · **LANDED 18:07 (499360d, rooted 8663-green)** — ④
  pieces 2 AND 5: Cell1988.lean, six-state FSM, the framework law
  zero_offset_rotation_is_impossible; piece 5 over testBit rode the
  same landing. Neither refuted.
- W4 · WRITE · **LANDED 19:44 (86553a6) + ROOTED 19:53 (5446a98,
  saltbuild EXIT=0, 8668 jobs)** — Executive.lean, the word-level
  executive, self-pulled under the aggressive mandate into the gap
  compiler itself published: all five pre-registered bar lines MET,
  `runW_map` unconditional (the prize), six SortDemo certificates
  lifted by rewrite with zero re-execution, the undecodable-word
  boundary shown with witnesses. One name-vs-statement defect caught
  by its own author pre-landing, recorded in-file.
  ⚠️ **LIVENESS MEASURED 2026-08-25 (compiler) — NOT CLOSED BY ME.** **W5-asm's FIRST HALF IS
  DONE AND ITS PRIZE IS KERNEL-REFUTED.** `core` exists (`CoreAssembly.lean:38`), so the organs
  ARE assembled. But this row's objective — *"prove the single-cycle refinement"* — is REFUTED in
  the ROOTED build at BOTH widths: `C4Refuted.lean:293` `c4Spec_core_is_false` and `:373`
  `not_C4SpecD_core`. **The row asks for a proof of a sentence the corpus proves FALSE.**
  ⛔⛔ **HALF OF THAT MEASUREMENT EXPIRED 2026-08-29 — `c4Spec_core_is_false` IS RETIRED** (council
  item (f), option ③, bus `28710859`): leg ① repaired the operand-B immediate path and the witness
  died, so **`C4Spec core` is OPEN — not proved and no longer refuted.** ⚠️ *A dead witness is not
  a proof that the spec is true, so this row is no longer "a proof of a sentence the corpus proves
  FALSE" — it is unpriced again, and the Sept 4–5 C4Spec attempt IS the search.* **THE `C4SpecD`
  HALF STANDS UNCHANGED:** `not_C4SpecD_core` still proves, on a width argument that touches no
  witness. *(The `:293` pointer was already one step off before this note; cite the NAME.)*
  ⇒ ⚖️ **RULED, NOT GATED — CORRECTED 2026-08-25 (council, Captain).** **HORN D STANDS UNAMENDED.**
  Citations, both VERIFIED at their sources before being written here:
  · `seat/briefs/2026-08-19-maestro-night-bank.md:1288` — the Captain verbatim:
    *"I think we should do D alone."*
  · `seat/briefs/2026-08-19-compiler-c4spec-refuted.md:500` — **THIS SEAT'S OWN BANK**,
    *"HORN D, PRICED BEFORE BUILDING (Captain's ruling: Horn D alone)"*.
  ⛔ **MY EARLIER LINE SAID "I FIND NO RULING ON THE BUS". THAT WAS TRUE AND IT WAS THE WRONG
  SEARCH SPACE — THE RULING NEVER LIVED ON THE BUS, AND MY OWN BANK HELD IT.** A ruling can be
  real and bus-absent; grep the BANK and the BUS, which my own card says and I did not do.
  ⇒ **NOT WORKABLE AS WRITTEN: it needs re-scoping to the REPAIR, not the proof.**
- W5-asm · **⚖️ PROCEEDS AS THE REPAIR UNDER THE D CHARTER (council 2026-08-25): HORN D STANDS UNAMENDED — the LW repair sits on top of REAL LOAD SEMANTICS, with the must-break differentials as designed. The fork is RULED, not gated; citations on the MIG-9 row above. The Q3 swap dry run already IS this work.** ⚖️ **SECOND HALF RE-SCOPED 2026-08-25 (helm ruling on compiler's 08:52): the objective is THE REPAIR, NOT THE PROOF** — `core` is assembled (first half done) and the single-cycle refinement is kernel-refuted at both widths, so "prove it" is not the work. **The LW fork is Captain-gated and ON THE RESUMED COUNCIL DOCKET (~09:30); DO NOT BLOCK ON IT — take the next P2 row meanwhile.**
- W5-asm (the core assembly — track-suffixed per math's 8/9 collision
  catch: bare "W5" also names salt wave-5 nodes and a Weil-track label;
  Captain-facing text carries the suffix) · WRITE · **OPEN — COUNCIL
  RULING #4 (09:2x, the Captain,
  option (a) interleaved): "even if we choose the packet-IO route,
  I'd like our original plan to be complete, verified, and ready
  for tapeout... I would actually tend toward (a), in case we
  encounter issues it may feed back."** The `core` construction:
  assemble the certified organs into ONE machine and prove the
  single-cycle refinement (assembled gates, clocked once, = stepT).
  METHOD: the probe pattern at scale — instOK per organ, sem_*
  certificates consumed by rewrite, never re-proved; the 8/7
  assembly plan's row map + StateCodec conformance. PRE-NAMED
  RISKS: sigma off-by-ones (the probe's own bar-3 class), composite
  heaviness (the audit-cap rider stands), StateCodec/encode
  agreement. THE PRIZE: emitS the completed core as the tapeout
  RTL — the fabbed thing becomes the verified thing. INTERLEAVED
  at compiler's seam with tiny-Rust N-waves and B-ISA (one write
  track, compiler's sequencing judgment); issues FEED BACK to the
  design docs immediately, per the Captain's rationale.
  ⚠️ **LIVENESS MEASURED 2026-08-25 (compiler) — NOT CLOSED BY ME; THIS QUEUE IS MAESTRO'S.**
  **W6 LOOKS OVERTAKEN BY EVENTS.** Its output was to *"feed the morning cap ruling"*, and that
  ruling was TAKEN: `tools/saltbuild.sh:34` records *"default 24000 MB, RAISED FROM 12000 at the
  Captain 8/9 ruling"*. Its named premise no longer reproduces either — I ran the named module at
  the current default: **`SaltWorks/HDL/Immediate.lean` EXITS 0 in 91s**, where this row records
  `EXIT=134`. ⇒ **the row asks for a census to inform a decision already made, and the condition
  it would measure was dissolved BY that decision.**
  ⛔ **I DID NOT RUN THE CENSUS.** It is heavy (`decide +kernel` over large ranges) and holds the
  MACHINE-WIDE build lock while other seats are mid-campaign. Spending that on a row whose ruling
  landed 16 days ago is the stale-debt failure, paid with the fleet's build capacity. One bounded
  probe answered the liveness question instead. ⇒ **maestro: close, re-scope, or re-approve.**
- W6 · MEAS · **✅ CLOSED-OVERTAKEN 2026-08-25 (helm ruling on compiler's 08:52 liveness measurement; the annotation below stands as the TOMBSTONE).** Its output fed the cap ruling TAKEN 08/09 (`saltbuild.sh:34`), and the premise failure it was priced against no longer reproduces. **SUCCESSOR: NONE NEEDED — a future cold-cost question enters as a FRESH ROW with a FRESH PREMISE**, never by reviving this one. ⭐ Restraint on the heavy machine-wide probe ruled RIGHT.**
- W6 · MEAS · **APPROVED 20:18 (maestro), compiler's slot** — the
  TARGETED COLD-COST CENSUS: path-form elaboration at the DEFAULT cap
  of plausibly-over-cap modules (decide +kernel over large ranges),
  pass/fail PER MODULE with the invocation attached (compiler's own
  pre-registered trap: no bare totals — a count is not a scope).
  Through saltbuild.sh (the fleet lock serializes the heavy runs;
  EXIT=134 rows are expected OUTCOMES, not failures of the census).
  Output feeds the morning cap ruling: it converts "at least one
  module is cold-unbuildable at the default" (Immediate.lean,
  measured EXIT=134) into a NUMBER.

## MATH

- W1 · WRITE · **PRE-AUTH** — the phase-3 Program.lean patch, on
  arrival of compiler's request (land it yourself; your file).
- W2 · WRITE · **LANDED 15:31 — the flagship's first theorem in five
  math lives**: norm_majorantCoeff_le_sq in the kernel (8b4c94c,
  clean axioms, audit by math's own hand); pre-flight held whole;
  M2 is the banked control (residual ⊢ 2 = 1, no slack). The
  flagship front is OPEN and PRODUCING — next salt targets by
  probe-then-wave on the idle edge.
- W4 · WRITE · **THE ④ HERITAGE CAMPAIGN IS COMPLETE (18:19)** —
  piece 1 (2933a99, the full circle, scoped form) · piece 3
  (3a8eb86, the soul) · piece 4 (190b6a4, skew, THE LAST WAVE) all
  math's; pieces 2+5 (499360d) compiler's; all five ROOTED with
  full-build verdicts through one hand; audit receipts on all three
  heritage modules.
- W3 · WRITE · **THE ③ CAMPAIGN IS COMPLETE (16:44)**: L3 landed
  (`5a3735d`), **L4 LANDED (`b140c7e`) — `bnC_payload_delivered` IN
  THE KERNEL**, rooted with full-build verdict EXIT=0/8661. The
  candidate-B route held: NO σ object ever constructed; the flagged
  ∀-w clause was the leg that made the induction trivial. Goal-level
  controls with pre-written witnesses, both biting.
- SPEC · **STANDING** — salt-side probes on idle edges (Inverted
  Purse; carry your own positive controls).

## SILICON

- W1 · WRITE · **DISCHARGED 2026-08-22 — and it was PARTLY STALE, which is
  worth more than the fix.** Two of its three legs landed on 08/08 at
  `9efc4f5` (the iverilog measurement against the real RTL —
  `Sim/rtl_tb/tb_counter_init.v` +267, `tb_param_p.v`, a mutant and `run.sh`;
  and the spec §5 amendment, +118 lines to
  `docs/silicon-frame-protocol-0806.md`). **The third leg — frame_sim's
  missing counter — was genuinely open**: the file had no `cnt` at all and had
  not been touched since 08-06, i.e. since BEFORE the measurement that was
  supposed to feed it. Closed now: `run()` carries a real frame counter with an
  arbitrary power-up phase and decodes the strobes from it exactly as
  `banyan_fabric.v` does, plus §3b (all 14 phases × 255 cases = 3,570 runs,
  PASS — phase INERT once sof re-aligns) and §3c, its control (sof withheld →
  13/13 phases mis-route, so the phase provably reaches the decode). Sections
  1–4 byte-identical to the pre-change run. ⚠️ **HOW IT WAS FOUND, recorded
  because the mechanism will recur: the helm pointed at it after my beats said
  "nothing owed" every 30 minutes for ~22 hours. That was TRUE OF MY INBOX AND
  FALSE OF THIS QUEUE — my duty filter read the wake channel and helm dispatches
  and never re-read this file. A queue whose semantics are PULL-at-seams is not
  covered by an instrument that only watches PUSH.** — original entry follows:
- W1 · WRITE · ~~PRE-AUTH~~ — the §8 half-surface repair: the
  iverilog measurement per your pre-registered 13:31 criterion
  against the real RTL; frame_sim's missing-counter gap fixed in
  your artifact; the spec §5 sof-phase amendment IF the measurement
  confirms conservative+inert (your file, your bar; the ③ block
  cites the amended spec second).
- R1 · READ · **SUPERSEDED 17:03 (silicon's own reading, receipted)**
  — the ③ campaign completed past it; substance covered by its 13:47
  pass + the landing verifications.
- R2 · READ · **DISCHARGED 13:54** — right-of-reply delivered and
  folded (the mod-5 strengthening; d_N symbolic).
- MEAS · **STANDING — RULED LIVE 8/10 18:17 (night maestro, at
  silicon's half-alive raise): NOT absorbed by the maestro's
  rooted-seals — a covering build is integration through one hand;
  MEAS is an independent kernel witness by another. Two functions,
  both stand. BASELINE LAW (silicon's catch, folded): the marker is
  the sha of the last MEAS VERDICT, never the last commit.
  BASELINE STRUCK 18:19 (silicon's own catch, adopted-on-say-so
  corrected): the last verdict was `763d02a` (16:55, StraightLine),
  not the bank's example `1bb4038`; true backlog 6 landings/7
  modules — DISCHARGED 18:19, 6/6 kernel-checked NO DEFECT
  (CompileE·X0·X1·X2·RegMap·SeamCSorted; A0Routes221 excluded as
  same-hand). MEAS CURRENT at `32f6ecfa` (08/31 18:2x — **TWO SWEEPS, because a peer landing RE-TRIGGERED the row mid-run**: range `6489dc7f..b383bb19` **20 of 20 KERNEL-GREEN, 0 RED**, then range `b383bb19..32f6ecfa` **1 of 1 KERNEL-GREEN, 0 RED**. **21 verdicts over 21 distinct files, `meas_since.sh` rc=0 on BOTH sweeps.** Endpoint ancestry tested AT ORIGIN before EACH range was computed, with a control confirming the known non-ancestor `2d4e218` is still refused; tree PINNED at `b383bb19` / `32f6ecfa` and re-read after every elaboration unchanged; freshness step clean on both passes (`saltbuild SaltWorks` EXIT=0, module form on the hub root), so every witness ran against CURRENT oleans. Endpoint RE-DERIVED AT ORIGIN AFTER the second sweep — unmoved, no third re-trigger. ✅ **COMPLETENESS AS A SET, BOTH DIRECTIONS, ON EACH PASS, with TWO controls that BOTH fire: a planted census filename IS reported unwitnessed, and a planted verdict IS reported off-census.** ⛔ **WHY THERE ARE TWO SWEEPS, AND IT IS THE PART A SUCCESSOR SHOULD READ: compiler merged R9b's negative half (`32f6ecfa`) WHILE PASS ONE WAS ELABORATING.** Pass one was unaffected — it runs against the local worktree, which I had deliberately not pulled, so its pin held and its 20 verdicts are valid AT `b383bb19`. But `.lean` genuinely moved, so the marker could NOT advance to `b383bb19`: ***a green over a range that has since grown is a false green over a real gap.*** The row's own precedent is the mirror image (08/27 sweep 1 aborted on a tree-moved alarm where NO `.lean` had moved, and the marker was still not advanced — a proof that a red gate should not have fired is not a green gate). ⛔ **THE HUB ROOT CHANGED TWICE IN THIS RANGE — `SaltWorks.HDL.LwTrapGate` then `SaltWorks.HDL.LwNotStallShaped` ENTERED THE CLOSURE (202 → 203 → 204 modules)**, so a covering build here covers a DIFFERENT module set than one before it. ⇒ **A COVERING BUILD IS OWED TO THE MAESTRO for `1198af70` and `5758a1e6`, and it is NOT this row's to discharge.** ⛔⛔ **INDEPENDENCE IS NOT DERIVABLE AT THE OBJECT FOR EITHER PASS, AND THE SECOND IS WORSE THAN THE FIRST — MEASURED, NOT ASSUMED. All four peer landings across both ranges carry NO `model:` trailer** (both of MY commits in range, `9afcff0b` and `b383bb19`, do carry `model: Opus 5 (silicon seat)`), and `%an` is `Jason Hickey` on 30 of 30 recent commits — control run, one distinct value. Pass one's `1198af70` carries `Co-Authored-By: Claude Fable 5`, which RULES OUT MY OWN HAND (this seat runs Opus) but names no seat. Pass two's three commits carry `Co-Authored-By: Claude Opus 5 (1M context)` — **MY OWN MODEL STRING** — so for that range the object discriminates NOTHING; that R9b is compiler's is asserted from their bus posts, which is prose, not the object. ⇒ 🔑 ***A MODEL STRING IS AN ATTRIBUTION SIGNAL ONLY WHILE SEATS RUN DIFFERENT MODELS.*** The fleet has just moved six workers onto a common account with the helm on Fable and the rest on Opus; `model: <seat>` is the only field that ever carried the SEAT, and it is a standing saltworks rule that nothing enforces. ⚠️ **WALL TIMES ARE NOT ELABORATION COSTS WHERE THE TOOL SAID SO: three targets are stamped `UNDER CONTENTION` (peer lean/lake at start) — `LwTrapRefuted` 39s · `RegNextUniform` 6s · `Rs1Close` 9s · `Rs2Close` 32s.** This seat retired wall time as a result-reading instrument after three independent refutations, one of which is exactly this (elapsed = WAIT + WORK, published under the name of WORK), so `EnableNonWriters` 390s and `CorePlace` 112s are reported as elapsed and quoted as nothing. ⚠️ **SCOPE, STATED WITH THE VERDICT: each target was elaborated fresh by the kernel, but its direct imports and their transitive closure came from CACHED oleans and were NOT re-checked; mathlib was not re-verified. A MEAS verdict is a KERNEL WITNESS ON ONE FILE AT A TIME and does NOT seal a landing.** ⛔⛔ **AND THE SENTENCE THAT MUST TRAVEL: these greens say NOTHING about whether the propositions the files are ABOUT are true.** `LwTrapRefuted` and `LwNotStallShaped` are REFUTATIONS; a kernel-green on either witnesses that THE REFUTATION ELABORATES, which is the reverse of the refuted proposition holding.) — prior marker `6489dc7f` (08/31 09:5x — range `5a7b07ec..6489dc7f`, **3 of 3 KERNEL-GREEN, 0 RED**, `meas_since.sh` rc=0, tree PINNED at `6489dc7f` and re-read after every elaboration unchanged; **endpoint ancestry tested AT ORIGIN before the range was computed**, with a control confirming the known non-ancestor `2d4e218` is still refused. Files: **`C4Refuted.lean`** (57s) · **`DecoderTransport.lean`** (5s) · **`LwTrapRefuted.lean`** (34s), each `EXIT=0`, and **all three are in the hub graph, imported DIRECTLY** (`SaltWorks.lean:159`/`:120`/`:160`). ✅ **COMPLETENESS AS A SET: the tool's 3-file census and the 3 verdicts are equal in BOTH directions by `comm`, with a mutation control (a planted filename IS reported).** ⭐ **INDEPENDENCE IS FULL AND, FOR ONCE, DERIVABLE AT THE OBJECT: 0 of 3 are same-hand — both landings (`0c614c29` · `cf526606`) carry `model: Opus 5 (compiler seat)`.** *Every prior row in this chain had to resolve authorship from bus prose because the trailer was absent; this is the first range where the standing trailer rule actually paid.* ⛔ **THE HUB ROOT CHANGED IN THIS RANGE — `SaltWorks.HDL.LwTrapRefuted` ENTERED THE CLOSURE** (hub transitive closure now 202 modules), so a covering build here covers a DIFFERENT module set than one before it. ✅ **AND THAT COVERING BUILD IS DONE, AT THIS HAND, IN THE SAME ACT: `saltbuild SaltWorks` EXIT=0 · 8,760 jobs · **25 Built / 145 Replayed** · 4,648 audit ticks · 0 `sorryAx` · 0 `declaration uses` · 0 errors · 6m08s at `5f1f9dd7`, whose Lean tree is IDENTICAL to the pinned `6489dc7f` (0-file diff over `SaltWorks/`, the lakefile, the toolchain and the manifest — the intervening commit is comment-only in a shell script). All three MEAS targets appear as **`Built`**, not `Replayed`.** ⚠️ **SCOPE, STATED WITH THE VERDICT: each target's direct imports (1/2/1) and their transitive closure came from CACHED oleans and were NOT re-checked; mathlib was not re-verified. A MEAS verdict is a KERNEL WITNESS ON ONE FILE AT A TIME and does NOT seal a landing.** ⛔⛔ **AND THE SENTENCE THAT MUST TRAVEL: these greens say NOTHING about whether `C4Spec core` or `RegDatapathOK` are TRUE — the opposite, if anything. `LwTrapRefuted` is compiler's REFUTATION of `RegDatapathOK` as stated under ruling z; a kernel-green here witnesses that THE REFUTATION ELABORATES, which is the reverse of the proposition holding.** 📌 *Counting note banked the same hour: the `Built`/`Replayed` figures above are counted on the STRUCTURAL job marker; a prefix-anchored count silently dropped 19 rows, `DecoderTransport` among them.*) — prior marker `5a7b07ec` (08/30 11:0x — range `32f2e0ae..5a7b07ec`, **3 of 3 KERNEL-GREEN, 0 RED**, `meas_since.sh` rc=0, freshness step clean (`saltbuild SaltWorks` EXIT=0, module form on the hub root), tree PINNED at `5a7b07ec` and re-read after every elaboration unchanged; **endpoint ancestry tested AT ORIGIN before the range was computed**, with a control confirming the known non-ancestor `2d4e218` is still refused. Files: **`DecoderTransport.lean`** (106s) · **`SelValueADDI.lean`** (7s) · **`SelValueXOR.lean`** (5s), each `EXIT=0`, and **all three are in the hub graph, imported DIRECTLY** (`SaltWorks.lean:120`/`:108`/`:110`). ✅ **COMPLETENESS AS A SET: the tool's own 3-file census and the 3 verdicts agree in both directions — every census entry witnessed, no verdict off-census.** ⭐ **SCOPE, AND FOR ONCE IT IS THE GOOD HALF: 0 of 3 are same-hand. All three are compiler's landings (`c984de93`·`e3d240d6`·`5a7b07ec`, the DecoderTransport correction plus the XOR and ADDI rows of `RegDatapathOK`), so this row carries a FULL independence claim** — unlike the prior row, where 3 of 55 were re-checks of my own work. ⛔ **A COVERING BUILD IS OWED TO THE MAESTRO for these landings and it is NOT this row's to discharge.** ⚠️ **SCOPE: each target was elaborated fresh by the kernel, but its direct imports (2/5/6) and their transitive closure came from CACHED oleans and were NOT re-checked; a MEAS verdict is a KERNEL WITNESS ON ONE FILE AT A TIME and does NOT seal a landing.** ⛔⛔ **AND THE SENTENCE THAT MUST TRAVEL: these greens say NOTHING about whether `C4Spec core` or `RegDatapathOK` are TRUE. They are witnesses that compiler's three files elaborate sorry-free at this tree.** 📌 *Related finding posted the same hour, not part of this verdict: `en` occurs in ZERO combinational assignments in `core32.v`, so the cone `C4Spec` quantifies over is `en`-independent and a stalling die cannot falsify `C4Spec core`; the unmodelled stall lands on `cycOfCirc`'s unconditional D→Q, i.e. on R10.*) — prior marker `32f2e0ae` (08/29 14:3x — range `08ba5515..32f2e0ae`, **55 of 55 KERNEL-GREEN, 0 RED**, `meas_since.sh` rc=0, 23m36s wall, freshness step clean (`saltbuild SaltWorks` EXIT=0, module form on the hub root), tree PINNED at `32f2e0ae` and re-read after every elaboration unchanged; **endpoint ancestry tested AT ORIGIN before the range was computed**, with a control confirming the known non-ancestor `2d4e218` is still refused; and the tree RE-CHECKED at origin AFTER the sweep — HEAD = `origin/master` = `32f2e0ae`, ahead 0 / behind 0, so no peer landing re-triggered the row. ✅ **COMPLETENESS PROVEN AS A SET, NOT A COUNT: the 55-file census and the 55 verdicts are equal in BOTH directions by `comm`, with a mutation control (a planted filename IS reported), so no census entry went unwitnessed and no verdict is off-census.** ⛔ **SCOPE — SAME-HAND EXPOSURE, MEASURED NOT ASSUMED: 3 of the 55 are re-checks of MY OWN `66c94083` and carry NO independence claim — `Banyan/Facade.lean` · `Silicon/Cells/Sky130.lean` · `Silicon/Equiv/ScenarioComplete.lean`.** The leg-① / C4 chain (`3eea6b96`·`3a3b853e`·`6dd543f0`·`58ee69dc`·`38729e9e`·`79c6f04a`·`d7bb56a9`·`32f2e0ae`) is compiler's **by their own bus posts, NOT at the object**: 16 of the 40 commits in this range carry NO `model:` trailer — ALL the `.lean` landings but mine among them — and `%an` is `Jason Hickey` fleet-wide, so WHOSE-LANDING is still not derivable at the object. ⭐ **THE RESULT THAT MATTERS: `C4Refuted.lean` — today's five retirements, council (f)/③ — is KERNEL-GREEN under an independent hand, as are `CorePlace` (stage 2a) and `OperandBWidening`.** ⛔⛔ **AND THE SENTENCE THAT MUST TRAVEL WITH IT: A GREEN HERE IS NOT A PROOF THAT `C4Spec core` IS TRUE. A dead witness is not a proof; `C4Spec core` and `RegDatapathOK` are OPEN, and this gate says nothing whatever about them.** ⛔ **THE HUB ROOT CHANGED IN THIS RANGE — `SaltWorks.HDL.OperandBWidening` ENTERED THE CLOSURE — so a covering build here covers a DIFFERENT module set than one before it. ⇒ A COVERING BUILD IS OWED TO THE MAESTRO and it is NOT this row's to discharge.** ⚠️ **A MEAS verdict is a KERNEL WITNESS ON ONE FILE AT A TIME and does NOT seal a landing: every target was elaborated fresh, but its direct imports and their transitive closure came from CACHED oleans and were NOT re-checked.** 📌 **A PRICING CORRECTION, RECORDED BECAUSE I PUBLISHED THE WRONG FORECAST MID-RUN: I predicted 50–70 min from the bank's `MacCell` 489s + `MacInduction` 549s; the actual was 23m36s, with `MacCell` at 14s and `MacInduction` at 3s. Those banked figures were measured against STALE or ABSENT oleans. ⇒ ***ELABORATION COST IS A PROPERTY OF DEPENDENCY STATE, NOT OF THE FILE — a per-file wall time carried across a freshness build is not an estimate, it is a different measurement.*** Third refutation of a wall-time heuristic at this seat, by a third mechanism.) — prior marker `08ba5515` (08/27 20:2x — range `c69fa8a2..08ba5515`, **1 of 1 KERNEL-GREEN**, freshness step clean (`saltbuild SaltWorks` EXIT=0, module form on the hub root). File: **`MemPortCorrespondence.lean`** — compiler's `10ac924a` + `110f5fc6`. EXIT=0 @ sha `557312c1ce90`, 9s wall, tree PINNED at `08ba5515` and re-read after elaboration unchanged; **endpoint ancestry tested AT ORIGIN before the range was computed**, control confirming the known non-ancestor `2d4e218` is still refused. In the hub graph at `SaltWorks.lean:168` (imported DIRECTLY). ⛔⛔ **rc WAS NOT CAPTURED AND I AM NAMING IT RATHER THAN IMPLYING ONE: I launched the sweep with `nohup … &`, so the harness reported the LAUNCHER's exit and the tool's own status was eaten — this seat's `exit-code-dies-in-a-pipe` card, in its wrapper form.** The verdict is RE-DERIVED FROM THE ARTIFACT: 1 green, 0 reds, and **no `SWEEP NOT COMPLETE` banner, which is how rc=3 announces itself** — strong, but it is an inference where every prior row in this chain has a measured `rc=0`. ⛔ **THE HUB ROOT CHANGED IN THIS RANGE — `SaltWorks.HDL.MemPortCorrespondence` ENTERED THE CLOSURE**, so a covering build here covers a DIFFERENT module set than one before it. ⇒ **A COVERING BUILD IS OWED TO THE MAESTRO, and it is not mine: the helm ORDERED it to compiler at 20:08 off this very measurement, correcting their park note's "nothing owed".** ✅ **DISCHARGED 20:23:07 by compiler at `08ba551` — `EXIT=0` · 8,759 jobs · **4,148 AUDIT TICKS** · 0 `sorryAx` · 0 "declaration uses" · their 18 declarations ticked at this HEAD, on a P1 ticket that the census named `seat=compiler` (they invoke via their SEAT path, so the naming works — which corroborates the `root` diagnosis from the other side: only FLEET-ROOT invocations lose the name). ⇒ this clause is CLOSED; do not re-raise it.** ⛔⛔ **AND CARRY COMPILER'S FINDING, WHICH OUTRANKS THEIR GREEN AND BEARS ON HOW THIS ROW IS READ: THEIR FIRST COVERING BUILD WAS ALSO `EXIT=0, 8,759 jobs` AND WITNESSED **ONE** DECLARATION** — a fully-current graph re-verifying itself, nothing re-elaborated. ⇒ ***EXIT AND JOB COUNT ARE IDENTICAL ACROSS A BUILD THAT CHECKED EVERYTHING AND ONE THAT CHECKED NOTHING; THE TICK COUNT IS THE ONLY FIELD THAT SEPARATES THEM.*** *This row's own freshness line cites `saltbuild SaltWorks EXIT=0` — that use is CORRECT (it asserts the graph is CURRENT so the path-form witness runs against current oleans) and it is NOT a kernel witness. Stated here because a later reader could easily promote it into one.* compiler has put the receipt-requires-tick-count question to the maestro; not mine to rule. ⚠️ SCOPE: the target was elaborated fresh, but its **6 direct imports and their closure came from cached oleans and were NOT re-checked here**; a MEAS verdict is a KERNEL WITNESS ON ONE FILE and seals no landing. ✅ INDEPENDENCE: the landing is compiler's, not same-hand. ⭐ **THE SWEEP ALSO EXERCISED THE QUEUE IN PRODUCTION: it waited ~21 min behind math's P2 and compiler's P1, FIFO with no preemption, and only the holder's lean processes ever ran — the 43 GB memory law measured AT THE PROCESS.** Its own ticket read `seat=root`, which is exactly the census defect fixed the same hour at `fe297ff4`.) — prior marker `c69fa8a2` (08/27 09:2x — range `dbfaa5f9..c69fa8a2`, **1 of 1 KERNEL-GREEN**, `meas_since.sh` rc=0, freshness step clean (`saltbuild SaltWorks` EXIT=0), tree PINNED at `c69fa8a2` and re-read after elaboration unchanged; **endpoint ancestry tested AT ORIGIN before the range was computed**, with a control confirming a known non-ancestor is still refused. File: **`NetlistBridge.lean`** — compiler's `fdde2378`, *"sem (bridge nl outs) = runP is PROVED — the correspondence closes"*. EXIT=0 @ sha `29d929564664`, in the hub graph at `SaltWorks.lean:96` (imported DIRECTLY, so a full build covers it), and **ZERO `sorryAx`** — a zero that carries weight because this same gate printed `depends on sorryAx` verbatim on the 08/27 00:4x stale-olean reds, so it demonstrably surfaces them. ⛔ **SCOPE, AND IT IS THE IMPORTANT HALF: THIS IS A KERNEL WITNESS ON ONE FILE, NOT AN ADJUDICATION OF THE CORRESPONDENCE.** ⛔ **CORRECTED 09:2x, SAME HOUR: I wrote that the induction is PARKED and this seat routed off it. THE PARK ENDED AT THIS MORNING'S COUNCIL — item ② RULED it, owner compiler, top priority, discharged 09:1x. My caution was correct reasoning from a premise the sitting had already changed.** The witness stands unchanged: the file elaborates sorry-free at this tree. ⚠️ **AND compiler's headline noun is AMBIGUOUS BY THEIR OWN RETRACTION: `fdde237` proves `sem (bridge nl outs) = runP`; the OTHER correspondence — `MemWiring.lean:44`, that the 36 datapath wires carry what the ISA's store semantics require — is UNTOUCHED and STILL OPEN.** They narrowed it with `git notes` on the pushed commit. Its 2 direct imports and their closure came from cached oleans and were NOT re-checked here.**) — prior marker `dbfaa5f9` (08/27 00:0x — range `d3190e8f..dbfaa5f9`, **14 of 14 KERNEL-GREEN**, `meas_since.sh` rc=0, tree PINNED at `dbfaa5f9` and re-read after every elaboration with NO move alarm; **endpoint ancestry tested AT ORIGIN before the range was computed** (`merge-base --is-ancestor` ✅, with a control confirming a known non-ancestor is still refused), and the marker re-read from `origin/master` rather than the worktree. Files: AdapterPlacement · C4Refuted · CoreAssemblyD · CorePlace · DecoderLines · DecoderTransport · EnableSpec · MemOrganPlacement · MemWiring · PcReads · SelValueADD · SelValueADDI · StallsAtWidened · Wire4. A covering build over this tree ran clean immediately before (`saltbuild SaltWorks` EXIT=0, 8,757 jobs) — ⚠️ **recorded as a FACT ABOUT THE TREE, not as a claim to have discharged the maestro's covering-build duty, which is theirs and still stands.** ⛔ **THE ROW TOOK THREE SWEEPS AND THE TWO FAILED ONES ARE THE VALUABLE PART. (i) Sweep 2 returned NINE REDS with `has already been declared` ×5, `Type mismatch`, `unsolved goals` and `depends on sorryAx` — ALL NINE WERE BUILD STATE (stale oleans: sources 23:45, oleans 17:45–22:09, after the decOut landing), proven by the module form returning EXIT=0 on 8,617 jobs. NOT a defect in anyone's landing, and my own merge was ruled out FIRST by blob identity against the pre-merge `6fce29c9` with a control. ⇒ ***THE BANKED WALL-TIME HEURISTIC IS REFUTED AS A DISCRIMINATOR: it holds only for an ABSENT olean; a STALE one elaborates 44s/34s/7s and fails convincingly. Trusting it would have published nine false accusations.*** The cure is to ASK LAKE, and `meas_since` now runs the hub module form once at sweep start (`dbfaa5f9`). (ii) Sweep 1 exited 1 on a TREE-MOVED alarm that was MY OWN COMMIT mid-run, twenty minutes after I had deliberately held a merge for that exact reason — I had scoped the hazard to the OTHER party. The marker was NOT advanced on it even though no `.lean` had moved: a proof that a red gate should not have fired is not a green gate.** ⚠️ **SCOPE: most of this range is peers' work and the attribution instrument is still broken — NONE of the commits in it carry a `model:` trailer and `%an` is `Jason Hickey` fleet-wide, so WHOSE-LANDING is not derivable at the object. A MEAS verdict is a KERNEL WITNESS ON ONE FILE AT A TIME and does NOT seal a landing.**) — prior marker `d3190e8f` (08/26 22:1x — range `9e20bc4e..d3190e8f`, **3 of 3 KERNEL-GREEN**: `StallsAtWidened` 26s · `StateCodecD` 22s · `ReqWordSource` 4s, each `EXIT=0`, tree pinned at `d3190e8f` and re-read after elaboration unchanged; **endpoint ancestry tested BEFORE the range was computed**. ⛔ **SCOPE: 2 of the 3 are compiler's landings and carry an independence claim; the `ReqWordSource` red in the FIRST sweep was BUILD STATE — a missing olean, not a defect — and it kernel-checks in 4s once the olean exists, against 1,143s failing to resolve the import. ⚠️ A MEAS verdict is a kernel witness on ONE FILE at a time and does NOT seal a landing: the COVERING BUILD IS STILL OWED TO THE MAESTRO, and the hub root CHANGED in this range — `SaltWorks.HDL.ReqWordSource` entered the closure — so a covering build here covers a DIFFERENT module set than one before it.**) — prior marker `9e20bc4e` (08/26 18:4x, taken at the relight as the seat's only standing row — range `7facfb0..9e20bc4e` in THREE sweeps, and the ENDPOINT'S ANCESTRY WAS TESTED BEFORE THE RANGE WAS COMPUTED (`merge-base --is-ancestor` ✅). **11 VERDICTS OVER 10 DISTINCT FILES, ALL KERNEL-GREEN under silicon's hand**, path form, `meas_since.sh` rc=0 on both sweeps: AdapterStateOrgan · BusFSM · C4Refuted · CoreAssemblyD · NetlistBridge · StallShape · StateCodecD · TrapOrgan · Stack/Program (9, to `34b14ab5`), then compiler's `cbbdea4f` landed mid-sweep and RE-TRIGGERED the row — StallShape (2nd check, on their bytes) · T2T5Consistency (new module, entered the hub closure); then `99e38ae5` re-triggered it AGAIN — StallsAtWidened (compiler, new, entered the closure). **12 verdicts over 11 distinct files, rc=0 on all three sweeps.** ⛔ **SCOPE, STATED BECAUSE THE GREEN COUNT OVERSTATES IT: 7 of the 12 are SAME-HAND re-checks of my own 08/26 landings and carry NO independence claim.** The independent half is `cbbdea4f` and `99e38ae5` (compiler, both confirmed at their own bus posts) and `c1340ca4` Stack/Program (math, by the commit's own text). ⛔ **AND THE ROW'S ATTRIBUTION INSTRUMENT IS BROKEN: 49 of the 55 commits in this range carry NO `model:` line — including ALL FIFTEEN of my own 08/26 landings.** The standing rule (`model: Opus 5 (<seat> seat)` on every saltworks commit) is unenforced by anything, and `%an` is `Jason Hickey` fleet-wide, so WHOSE-LANDING is not derivable at the object for most of this range; the two above were resolved from the bus and from commit prose, not from the trailer. ⚠️ STANDING LESSON KEPT FROM THE PRIOR VERDICT: the MEAS path form kernel-checks but WRITES NO OLEAN BY DESIGN — so MEAS can never clear an `import owed`, and a green path-form report is not a written artifact; clear a missing olean with the MODULE form first. ⚠️ A MEAS verdict is a KERNEL WITNESS ON ONE FILE AT A TIME and does NOT seal a landing — the covering build is still owed to the maestro. PRIOR: `7facfb0` (08/25 10:4x, 5/5 over three compiler landings `5043b0f`·`9a3719b`·`246d36f`); before that `8bb66da`, 96 modules, field repaired 08/23 20:3x.) Read-work discipline:
  parkable, never gates P1; every verdict posts its
  sha.** — conveyor refutation on every compiler
  landing; CELLS pricing on request. C5 re-baseline: **DISCHARGED
  15:52 (3bf84a0)** — run after its registered gate opened at 3b,
  every pre-registered prediction confirmed, headline as a pair.
  (Gate history: muster 10:02 item 3; gated on the flip so the
  measurement named the live artifact.)

- Q1 · READ · **✅ DISCHARGED 08/27 19:55 — the row below was OPEN, MINE** — **the holder-ticket `q_census` check at my next
  REAL build.** Registered here 08/27 19:1x because it was BUS-CARRIED ONLY, which
  is this seat's own `bus-resident-fixes-die-at-reboot` defect and I had repeated
  it. ⛔ **NOT discharged by the 19:0x observation**, and the distinction is the
  whole row: I measured the lock HELD by math (pid 97007, `Salt.MR.All`, 30m29s)
  while `q_census` printed `(queue empty)` — but that holder runs
  `2575f08ed44d4c4d`, **PRE-`1fcc22d7`**, the version whose holder DROPS its ticket
  at acquire. So the reading is CONSISTENT with the fix working and proves nothing
  about it. **The check wants a holder running the NEW saltbuild.** ⚠️ Attribution
  above is a CODE READING, not a driven measurement.
  ✅ **DISCHARGED 08/27 19:55:32 — AND BY A BUILD THIS SEAT DID NOT STAGE.** math's
  `Salt.MR.All` supplied the holder twenty minutes after I declined to manufacture one:
```
  lock holder pid   62078
  ticket            .tkt.2.<ns>.62078          ← PRESENT while holding (class P2)
  q_census          P2   117s   math   62078   ← holder VISIBLE, pid MATCHES the lock
  holder executes   seats/math/saltworks/tools/saltbuild.sh   (pulled 19:15 → d198a963f94cdd00)
```
  ⭐ **AND IT IS A CONTROLLED PAIR BY ACCIDENT OF TIMING, which is worth more than the
  check: SAME SEAT, SAME COMMAND (`Salt.MR.All`), SAME QUERY — `(queue empty)` at 19:0x,
  correctly populated at 19:55. The single variable is math's pull.** *A staged build
  could not have produced this pair; only the fleet's own timing could.*
  📌 **WHY THE ROW SAID "AT MY NEXT REAL BUILD" AND NOT "RUN ONE": a check closed by a
  build staged to close it is a check that was never asked a question.** The discipline
  that kept this open for 45 minutes is what makes the discharge mean anything.
- Q2 · SURFACED, NOT MINE TO DECIDE — **the fleet-root clone is ownerless, carries
  two DEAD-TWIN tombstones, and is still the RESOLVE TARGET of a path three live
  tools hardcode** (`docs/silicon-tools/meas_build.sh:60`,
  `docs/silicon-tools/meas_since.sh:41`,
  `docs/ledger-tools/wrapper_link_guard.sh:29` — in this clone and compiler's
  alike; `~/projects/claude/saltbuild.sh` is a RELATIVE symlink, so it resolves
  INTO that clone). Pulled to `1fcc22d7` 08/27 19:0x, so the path is currently
  sound. ⛔ **IT WILL ROT AGAIN, and the measured cost of the last rot is the
  reason this row exists:** the pre-pull blob, recovered from git rather than
  described (`git cat-file -p 444458a:tools/saltbuild.sh` → `6942473aaacd32f7`,
  exact, 233 lines), carries **ZERO** queue references against 9 in the current
  file (nonsense-token control 0 on the same file). ⇒ **every MEAS run took the
  fleet lock WITHOUT A TICKET and was invisible to the census** — the
  kernel-witness gate was the fleet's one unticketed build path. Two cures,
  neither a seat's to choose: repoint the symlink at a live clone, or give that
  clone an owner. 🔑 **THE CLASS: a tree can be dead for WORK and live as a TOOL
  SOURCE, and a tombstone that says DO NOT WORK HERE does not say DO NOT RESOLVE
  HERE.**
  ⭐ **RULED 08/27 19:11:57 (maestro, legislative delegation; append-only, appealable) —
  AMENDED HERE RATHER THAN REWRITTEN, so the question and its answer both stand.**
  ① **OWNER: evidence** — it already holds this clone's census drift-row. The duty is a
  **MEASURE, NOT A VIGIL**: a census row comparing fleet-root pins to origin, so the next rot
  is **ANNOUNCED, not discovered inside a build path.**
  ② ⛔ **THE SYMLINK IS *NOT* REPOINTED into a seat clone — my cure ① is DECLINED, and the
  reasoning is worth more than the verdict: a load-bearing path must not resolve into a tree
  its owner rebases.** *I offered two cures and the rejected one was the one I would have
  reached for first.*
  ③ **TRUE RETIREMENT REGISTERED, ripens-when = post-Sept-8**: repoint the three hardcoded
  tool paths, then let the clone die honestly. **Not this week — it is the MEAS gate's build
  path, days before tape-out.**
  ✅ Second independent hand: the helm re-verified `d198a963f94cdd00` · `95f4310f2c4072e4` ·
  HEAD `1fcc22d7` **at the artifact**, not off my post. ⇒ **Q2 is CLOSED to this seat**; what
  remains is evidence's census row and the post-Sept-8 repoint.

- Q4 · WRITE · ✅ **CLOSED 2026-09-02 12:5x AT THE CLICK** — the Captain re-submitted project 5500 from TT `main` `4226396f` (run `33644567364`) at the R10 sitting (minute the helm's R10 sitting minute (bare filename `2026-09-02-R10-SITTING-minute.md`, private record) @ `bf813512`); receipt at the object = `TinyTapeout/tinytapeout-sky-26c` PR #282 (TinyTapeoutBot, 19:55:30Z, `commit_id.json` → `4226396f` / run `33644567364`, `project_id` 5500, `sort_id` unchanged). ⏳ INGESTION = the PR's MERGE, pending at 13:0x (08/21 precedent: ~33 h); the merge receipt is owed to `docs/R10-SITTING-TABLE-0902.md` §(A) when it lands, and does not re-open this row. Rung 0 dates 2026-09-02. — 07:5x entry: **READY-TO-CLICK 2026-09-02 07:5x — TT `main` = `4226396f`, both shuttle runs green, treatcheck exactly four keys, 132/132 metrics identical to the 08/27 archive; the click is the Captain's (project 5500). CLOSES at the click.** — 07:4x entry: **IN FLIGHT — THE HOLD IS SUPERSEDED (Captain, council 09/02 07:2x: SHIP
  EARLY; desk DW). The note is re-cut for `ndf-2a` and folded into the resubmission bundle:
  `jyh/tt-neural-dataflow-fabric` branch `ndf-2a` = `119d9705` (four config keys) + `4226396f` (the note
  in `docs/info.md`); shuttle runs `33640518663` / `33640897082` in progress at this stamp. READY-TO-CLICK
  = run 2 green on every job + `treatcheck` exactly-four-keys + metrics equal to the 08/27 archive +
  fast-forward to `main`; criterion and state in `docs/R10-SITTING-TABLE-0902.md` §(A). The click is the
  Captain's, after the R10 sitting today; hard wall 2026-09-07 13:00 PDT unchanged. CLOSES at the click.**
  — original entry, retained because its self-consistency reasoning still governs:
- Q4 · WRITE · ~~HELD BY RULING — DO NOT SHIP EARLY, DO NOT LET IT GO QUIET.~~ Ship
  `docs/signoff-fanout-note-FOR-BUNDLE.md` **WITH the `ndf-2a` RESUBMISSION, AS ONE ACT**
  (config + evidence together). **TRIGGER: the Sep 4–5 resubmission click. HARD DEADLINE:
  2026-09-07 13:00 PDT — after it nothing can be added to any bundle, ever.**
  Ruled 2026-08-28 19:0x, Captain: *"the paper documents everything AT THE TIME; the tape-out
  can change and be updated, but IT MUST BE SELF-CONSISTENT."* ⇒ the standard is
  SELF-CONSISTENCY, not "always include the evidence": artifact and evidence must describe THE
  SAME THING AT THE SAME TIME. ⛔ **The note must NOT go into the CURRENT bundle: that bundle
  documents `ndf-base`, and `wire695` appears in ZERO of its nine corner reports** (the accepted
  config `1d+2a` differs from the submitted run in 4 of 411 resolved keys — measured, and the
  helm recorded that their order had assumed otherwise). ⚠️ **IF THE RESUBMISSION DOES NOT
  HAPPEN, THIS ROW DIES WITH IT — it is not owed on its own; it is owed only as the second half
  of that act.** Registered HERE rather than in a bank because a bank is replaced every seam and
  arm 9 reads this file every sweep.
- Q3 · WRITE · **DISCHARGED 2026-08-28 18:5x — the gate OPENED at council item 18 today (Captain "approved"; I merged it myself to `salt main`) AND I DID NOT NOTICE FOR FIVE HOURS, posting "owed 0" in every beat. ARM 9 was reporting `open=2[Q2,Q3]` the whole time — the arm built for exactly this, firing on its author. Ported BYTE-EXACT from `salt origin/main fbad5d1a` (no re-typing: 3× `cwd=ROOT`, tracked-but-absent is now FATAL rather than skipped as "binary", and self-test arm 5 drives cwd-independence in a throwaway repo). `--self-test` OK incl. `cwd-independent`; run as CI runs it over `origin/master~5..origin/master`: rc=0, 5 messages / 909 tracked files, attribution untouched.** — original entry follows:
- Q3 · WRITE · ~~GATED — DO NOT LAND EARLY.~~ Port the scrub-gate `cwd` fix into this
  repo's `scripts/check_commit_trailers.py`. **Gate: the Captain's word putting it on
  `salt main`** (standing rule; the helm asked 08/27 20:2x). Registered here 08/27 20:2x
  because it was BUS-CARRIED ONLY — the third time today this seat has had to write that
  sentence, which is itself the argument for the row.
  **SOURCE, VERIFIED AT THE OBJECT rather than quoted:** `salt` branch
  `gate/trailer-cwd` @ `e974096e`, *"scrub gate: pin every git call to ROOT; a tracked
  file absent under ROOT is FATAL, never 'binary'"* — it resolves locally, and
  `merge-base --is-ancestor e974096e origin/main` **REFUSES**, confirming the helm's
  "not on main" rather than taking it on trust.
  ⛔ **THE ARM TRAVELS WITH THE FIX — a port without the self-test arm is NOT a port**
  (helm's condition, and it is the load-bearing half: the arm is what makes the fix
  refusable later).
  📌 **WHY IT MATTERS HERE, from the measurement that found it:** run from another repo,
  the gate took THIS repo's file list and read those names out of the *script's* tree —
  one colliding filename satisfied the empty-scan guard and every non-colliding file was
  dropped by the handler meant for binaries. Driven: a repo containing a REAL
  `Claude-Session:` trailer scored `rc=0, "0 forbidden strings"`, having scanned 1 of 2
  files. ✅ **The CI arm was and is UNAFFECTED** (it runs from the repo root, so `cwd`
  and `ROOT` coincide) — that scope line must survive the port, or the row reads as a
  flagship alarm it never was.

## EVIDENCE

- CHARTER · **STANDING** — the five held-open items with close
  conditions (your predecessor's durable queue, ba9ccdd); the
  slate-price number written ONCE at slate close; the nightly
  ledger run.
- R1 · READ · **PRE-AUTH, OPTIONAL** — ③/④ reads at seams (your
  duty-filter design carries no landing-triggered duties; keep it
  light by design).

## THE CAPTAIN'S REGISTER (Captain-ratified 8/8 ~14:10, his words)

> "It is better to ask for correction than for permission." — and the
> Purse: "do it, unless it is obviously wrong."

- **TIER 1 — SOLELY THE CAPTAIN'S, never defaulted**: anything
  PUBLIC · MONEY · ENDORSEMENTS · frozen-statement re-cuts · the
  summit word · named clicks (B5). The maestro's duty is the fact
  sheet BEFORE ripeness, so each costs one read and one word.
- **TIER 2/3 — PREAUTHORIZED TO THE MAESTRO**: everything else;
  the Captain's later veto always available. Decisions touching
  Tier-1-adjacent artifacts are FLAGGED with their veto point named
  (the pin pattern, 13:49).

STANDING ORDER (the Captain, 8/8 night, verbatim): "be aggressive,
you have more ability than you know" — 11 days remain on the
two-week clock; the plan holds. HIS NAMED NEXT STEP if the current
plan lands soon: **GENERALIZING THE EXECUTIVE** (post-B-EXEC:
preemption per the named small-step/fuel deferral, and beyond).
Morning: he reviews the council pack + tiny-Rust v1.9 + the story.

OPEN ITEMS:
- **COMPILER'S UNREGISTERED GATED ITEMS (swept into the register
  08:1x per the re-raise clause's own first job — an item never
  registered cannot be protected; compiler's declared-interest
  find): (a) raise the saltbuild DEFAULT cap 12000→24000 (still
  CAP=12000 in the wrapper; compiler's 01:34 recommendation, its
  own interest declared — registered ≠ endorsed, a maestro ruling
  at council decides) · (b) import owed: SubFragment, SingleLevel
  (line-57 records the CONVENTION, not these two specific debts) —
  ✅ **DISCHARGED-BY-MEASUREMENT 2026-08-26 22:3x (compiler, at the object):
  BOTH ARE ROOT-IMPORTED AND HAVE BEEN SINCE `bc425ce`, 2026-08-09 10:11 —
  SEVENTEEN DAYS BEFORE THIS ROW WAS WRITTEN.** `SaltWorks.lean:132-133`.
  Control: a module that is NOT root-imported returns 0 to the same query, so
  it could have come back empty. **The row was never a debt; it was a stale
  label, and a stale DEBT gets EXECUTED where a stale FINDING gets disputed.**
  Original text kept verbatim above per the marker law. ·
  (c) ImmediateScope retirement via the aiming rider (already noted
  below, compiler's slot). Re-raise clock: council.**
- **RE-RAISE CLOCKS ON GATED ITEMS (silicon 07:5x, `a standing order
  outlives its world`): every authorization-gated open item wants a
  RE-RAISE cadence, or it dies quietly the day the authorizing word
  stops coming — a gate is not a grave. Rule: any item GATED on the
  Captain's word that has not moved in a review cycle gets
  re-surfaced at the next council, not left to rot in silence.
  Applies to W5, the ③+④ session, (7.3), B5, and the two neural
  sketches' design-team questions (those are SCHEDULES awaiting a
  Fable-tier slot, not ruling-dependencies — re-raise when the slot
  opens, not when a word is owed).**
- **THE CAPTAIN'S STANDING WORDS (recovered 08-09 02:1x from the 22
  early-format posts invisible to every filter — silicon's triage,
  compiler's ask; now in the register where standing law lives,
  single-ownership rule): [8/6 18:11] the public-TT-repo is GO
  ("#1: yes", verbatim) · [8/6 19:16] THE CHARGE, verbatim: "No
  idling…" · [8/7 10:50] CAPTAIN'S INTENT: HE WANTS THE CPU
  FABRICATED, his sizing "BB in ~2 tiles" (the night's tile arc
  executed this intent before the filters could see it) · [8/6
  council I] the seam doctrine stands ratified. Originals at their
  bus lines; this entry is the durable recall surface.**

- **COUNCIL RULING #5 (09:4x, the Captain, verbatim: "for the pure
  RISC-V path let's keep the dmem8 + offboard memory"): the pure
  RISC-V core's memory architecture is SETTLED — dmem8 onboard as
  data scratch, program + bulk data offboard via the 8-bit
  multiplexed pinout (RP2040-served, the standard TT pattern).
  The latch-array probe continues as LADDER KNOWLEDGE (it gates
  the packet-boot idea, not this path). ACCOUNT-CHECK COMPLETE
  same sitting: five seats, five accounts, one-to-one, zero
  divergence (one account per seat); maestro is ALONE on jason — the
  tier-drop seat had no same-account control, now measured.
  PACKET-IO APPLICATION SLATE under discussion, his framing:
  1) packet filter, 2) CPU as smart neuron, 3) switch fabric as
  NN "presumably using bit-serial multipliers, requires
  discussion"; #1 and #2 use offboard memory (his word), #3's
  memory story is part of the open discussion.**

- **CORE-ACCOUNT COMMISSIONED (13:2x, the Captain, verbatim:
  "let's do it!") — docs/core-account.md skeleton on the tree; the
  bb-switch-account 70-min pattern: compiler kernel half (measured,
  #eval'd) · silicon priced half (3x2 signoff artifacts) · maestro
  joint reading · math standing refutation · evidence fence pass.
  GATE: §1 final row table awaits assembly rows 15-16; halves
  proceed now.**

- **THE TRACE INHERITANCE — LANDED (c2428b3, fresh executor,
  covering build in flight): the full-state per-cycle step (both
  64 state bits, compiler's cell_wsh_next citing), the trace
  induction (cellSeq_runTrace_state), THE INHERITANCE
  (cellSeq_inherits_macSeq_state — the composed cell's
  accumulator half IS rung 3's state over the manufactured addend
  trace), join + signed corollaries with cited conjuncts, four
  mutants RUN on the real 193-gate netlist by decide +kernel incl.
  the spanning-trace state-discipline mutant in full. Docstrings
  theorem-sized; forbidden sentence absent.
  ⛔ FINDING 1 — TOMORROW'S DESIGN ITEM #2 (beside the top module):
  THE SIGN CYCLE IS NOT EXECUTABLE ON THE COMPOSED CELL, kernel-
  checked refutation landed: ccCore's addend port carries only
  andWord x w (0 or the weight register); NO COMPLEMENT PATH
  EXISTS in the netlist — the (b) ruling's planned bitNot32 stage
  was never integrated into ccCore. The signed MAC's full trace is
  not a cellSeq trace until the complement path is designed in
  (bitNot32 row on the addend, or the priced XOR-bank alternative).
  The accumulation-phase join stands; the SIGNED claim for the
  COMPOSED cell waits on hardware, not proofs.
  ⇒ FIRED TONIGHT 8/9 18:5x at the Captain's word ("we can
  proceed"): compiler's write track, XOR-BANK FORM adopted by
  maestro ruling (addend XOR sign, one gate level, 32 gates,
  replaces inverter bank AND select, maCin same-signal; semantics
  acc+~x+1 unchanged from ruling (b)). **CAPTAIN-CONFIRMED 18:5x
  ("yes please fire away") — the amendment flag RETIRES; the path
  is clean end-to-end.** Math gated behind the landing for the
  signed trace inheritance; silicon MEAS reactive; timing MEASURED
  never predicted (silicon's refusal binds all seats).
  ✅ **LANDED 19:05 (7364548, compiler, fire-to-kernel in 16 min):
  `scellSeq`/`scCore` 225 gates BESIDE `cellSeq` — compiler's own
  object (MacCell.lean:702), with math's 26 MacBridge theorems
  ABOUT it untouched (the expensive side, taken deliberately:
  statement-shape-is-an-interface; consumer consent, not
  ownership, gates retirement — compiler's 19:14 precision).
  `sign` REPLACES cin, nIn stays 3, emitted boundary will stay
  67/96. 32 audited theorems — 31 at landing + the one rfl
  coverage gap (scSign_eq_ccCin, harmless) silicon's MEAS caught
  at 19:10 and compiler closed at 80c572a (32/32, 89 ticks);
  three mutants on the real 225-gate netlist. SEALS: silicon MEAS NO DEFECT (kernel-green own-hand)
  · MAESTRO COVERING BUILD saltbuild EXIT=0, 8,677 jobs. MATH'S
  GATE ② IS OPEN (compiler's three facts: the object is scellSeq;
  macSeq untouched so cell_computes_signed_mac applies without
  restatement, addend becomes cmplWord s (andWord x w);
  scellSeq_env_is_cellEnv landed as rfl). ⚠️ F5 SEMANTIC DRIFT
  REGISTERED (silicon's catch): mac_cell.v is STILL the unsigned
  16:02 emission — f5_port_test EXIT 1 now means LANDED-NOT-YET-
  EMITTED, not nothing-happened; silicon's signed emission is the
  cure and is in flight. Timing: still NO nanoseconds published —
  measure on the emitted artifact.
  ✅✅ SEALED THROUGH SILICON'S STEPS (1)(2)(3) BY 19:34: signed
  cell EMITTED (F5 a+b met on the emitted netlist) + HARDENED as
  a CONTROLLED PAIR ON ONE DIE (configs 3a8b452, netlist 0e88bad;
  DRC/LVS/antenna/max-slew 0 both arms). THE MEASURED COST OF THE
  COMPLEMENT PATH: +332.82 µm² stdcell (+9.79%), logic 190→222
  (+32 = the XOR bank exactly; both arms purge the same 3
  unobservable gates), setup margin at the slow corner +2.0831 →
  +1.1123 ns — BOTH ARMS CLOSE AT 55 ns; THE CLOCK RULING HOLDS,
  now measured on the signed artifact. The chain reconciles
  kernel→emitted→liberty→post-layout to 0.0024 µm², and xor2
  survives LibreLane's yosys 96→96 — fabbed-is-verified MEASURED
  (net NAMES do not survive synthesis: criterion (d) checks the
  EMITTED netlist only). Method note banked: FP_CORE_UTIL sizes
  the die FROM the cell area — the first attempt was two
  different dies, caught by its own control (DPL-0036). Step (4),
  the EUR-280 settling run, STAYS GATED on the top-module block
  clearing its refuter pass — a block under refutation is not a
  ruling (silicon's words).
  ✅✅✅ ITEM ② SEALED 21:4x (the covering build stood owed from
  19:17 — math named it twice without complaint; the maestro's
  miss, discharged): 81bf3d2 (19:17, TEN MINUTES after the gate
  opened) = scellSeq_computes_signed_mac — THE SIGNED TRACE
  INHERITANCE ON THE COMPOSED SIGNED CELL, with
  cell_addend_cannot_present_the_sign_operand still true and
  still in the file (the refutation and its answer coexist).
  SEALS: silicon MEAS clean 19:21 · maestro covering build
  saltbuild EXIT=0, 8,677 jobs (21:4x). THE BOUNDARY, math's
  line kept verbatim: F5 CLEARS ON THE DATAPATH AND KEEPS
  BINDING ON THE CONTROL — the theorem is true of a trace the
  cell CAN present and not yet of a machine that DRIVES ITSELF;
  the supplier is the sequencer (V9/D10.7, the sitting's item).
  ⇒ THE NEURON IS SEMANTICALLY WHOLE — accumulation AND sign —
  at the kernel model on the composed artifact, dream to
  signed-silicon-candidate in under one day; the chip-level
  "down to silicon" still closes only at the top-module run
  (F3).**
  📌 FINDING 2 — AUDIT-COVERAGE CAMPAIGN CANDIDATE: Sem.lean's
  "real number is zero" note is stale — ⛔ 204 ⛔ (THIS FIGURE IS
  STRUCK — the true number is 180; read the supersession block
  below before quoting anything from this sentence) unaudited
  theorems corpus-wide (CorePlace 38 [struck: 37] · CoreOffsets
  23 · TinyRustN0 23 · MacBridge's 32 pre-existing · others); the
  executor audited its own 16 with an explicitly-scoped block. A
  sweep candidate for the doc-refresh campaign.
  ⇒ **FIGURE SUPERSEDED 22:3x AT THE MEASUREMENT (three hands,
  three methods, reconciled on the bus 21:4x-22:3x; registered on
  silicon's 22:31 report — its own law arriving from the far side,
  "my measurement never left the bus"): THE NUMBER IS 180, NOT
  204 — 232 total − 52 in GITIGNORED Scratch*.lean (the census
  tool counts development scaffolding; the tool lives in
  docs/hdl-tools/ and ITS FIX IS UNCLAIMED); CorePlace is 37, not
  38. THE PARTITION, claimed in protocol form overnight: compiler
  83 · math 47 · silicon 35 · RESIDUAL 15 (floor of 10 =
  SelfRouting) — the residual-15 assignment and the census-tool
  fix are the sitting's two remaining decisions here. Sem.lean's
  zero-note is still stale AND the 204 replacement was stale too
  — both die at this line.
  ⛔⛔ AND THE 180 IS HELD TOO (silicon 07:31, found by opening
  its own claimed files): the census tool has a SECOND defect — it
  ~~compares qualified #audit_axioms names against bare in-namespace
  declarations WITHOUT NORMALISING, so 32 correctly-audited
  theorems across SIX files read as unaudited. TRULY UNAUDITED:
  138 (PartialLoad: census said 18; the file's own audit block
  names 16 of them — truly 2).~~
  ⛔ **STRUCK 2026-08-26 16:2x BY SILICON, HELM-AUTHORIZED — AND THE STRIKE
  IS THE POINT.** `audit_completeness.py` **ALREADY NORMALISES**: line 84 is
  `listed.add(tok.split('.')[-1])`, applied to BOTH sides of the comparison.
  **PartialLoad is CLEAN**, not "truly 2": its `#audit_axioms` blocks are
  **LEGITIMATELY MULTI-LINE** — an audit line followed by INDENTED continuation
  lines carrying further qualified names — so all 18 of its theorems are covered
  by 8 statements. A reader who greps only the `#audit_axioms` LINE sees 8 names
  and manufactures 10 unaudited theorems out of its own blind spot. ⇒ **That is
  measured, not argued: re-measuring this row I built a second parse with exactly
  that defect and it told me the tool falsely marks 28 theorems audited across SIX
  files. This row claims 32 across SIX files — same file count, same magnitude,
  OPPOSITE SIGN. Had I skipped the control, that near-match would have read as
  INDEPENDENT CONFIRMATION: two blind spots shaking hands.** The stale claim sent
  the next hand hunting a defect that is not there, and it did exactly that to me.
  Current incumbent figure: **428 unaudited / 3423 theorems / 164 files**, and it
  remains UNCORROBORATED — the second instrument this row asks for still does not
  exist. *Defect (3), the gitignored-Scratch class, WAS real and was fixed 08/10
  in `f1d0bb63`.*
  AND THE CONFESSION THAT MATTERS
  MORE THAN THE NUMBER: the 21:51 "confirmed by a third hand, by
  a different method" was FALSE in the half that mattered — all
  three hands ran audit_completeness.py; one instrument thrice is
  ONE measurement (agreement-is-not-corroboration, silicon's own
  law, owned in full). WHAT SURVIVES: the gitignored-52 defect
  (independently confirmed) and the PARTITION SHAPE by owner; the
  per-owner NUMBERS re-derive after compiler's tool fix (which
  ~~now answers TWO defects: gitignore class + name normalization~~
  **answers ONE — the gitignore class, fixed 08/10 in `f1d0bb63`. The "name
  normalization" defect is STRUCK above: the tool normalises at line 84.
  Corrected HERE TOO because a strike that leaves the claim alive in the row's
  own SUMMARY has not struck anything — the summary is what a hand in a hurry
  reads, and this row's summary is the half that travels.**).
  No figure from this entry travels to the Captain except
  138-provisional-on-the-tool-fix.**

- **THE COMPOSED CELL — STATE AT ITS EXACT SIZE (compiler's 16:03
  trim of the maestro's verdict — the FOURTH one-theorem-larger
  sentence today and the FIRST cut by the seat that would benefit):
  one module, 193/193, SHAPE-CERTIFIED with the seam and
  disjointness proved (cell_seam_is_the_addend — the right-wire
  claim port by port; cell_instances_are_disjoint — the pair
  property instOK cannot express) — the composition's per-cycle
  theorem was OWED at compiler's seam — **DISCHARGED 17:20,
  covered EXIT=0: the cell's cycle IS the accumulator's cycle on
  the addend the weight organ made. The emission CAN now inherit the
  join — math's 17:21 precision: A CAPABILITY, NOT YET A THEOREM;
  the remaining arrow is the trace-level induction over cellSeq
  (the same gap math crossed for macSeq at rung 3). The maestro's
  fifth one-arrow-larger sentence, trimmed within minutes like
  the other four. HONEST STATE: per-cycle composition PROVED ·
  trace inheritance OWED (small, shaped by precedent) · then the
  neuron is semantically whole.**

- **THE NDF CLOCK — RULED 15:5x at silicon's discriminator (the
  red is REAL, not a die artifact: mac_acc's 32-bit ripple carry
  misses 25 MHz by 0.9%; quadrupled density bought 0.046 of the
  0.388 ns needed, wirelength unchanged — the chain is the floor):
  **RE-RULED 16:0x — THE NDF RUNS AT CLOCK_PERIOD 55 (~18.2 MHz)**:
  silicon's composed-cell measurement showed the 20 MHz valve was
  priced on mac_acc ALONE — the composed cell's worst path is
  50.939 ns (the WSHIFT→AND→ADDER seam adds 10.60 ns THAT NO
  PARTS-MEASUREMENT COULD PREDICT — the parts-vs-composition
  lesson as a number). 52 closes with +1.06 ns; 55 ships with
  +4.06 ns — margin bought in the free currency ahead of the
  floorplan run's unknown costs. Still zero silicon, still one
  config line, frame protocol still indifferent.
  ADDER SURGERY REFUSED for the PoC (config-beats-organs, the
  wiring-beats-organs prior's cousin; CLA/skip stays priced on
  record if a future clock demands it). THE AGREEMENT LAW RIDES:
  when the NDF submission repo is assembled, config.json AND
  info.yaml declare 20 MHz TOGETHER (the BB's lesson was the
  agreement, not the number). Unmeasured remainder, honestly:
  the fabric-floorplan run re-measures beside BB + core; the
  carry chain is a floor no floorplan improves, and at 20 MHz it
  carries 9.6 ns of margin for whatever the floorplan costs.**

- **THE CELL WAVE — RUNG 4 SEALED, THE RESIDUE BOARD (14:5x):
  a2c6470 landed (fresh Opus hand, 4b induction first attempt,
  three mutants kernel-FALSE incl. the total-only wrong-theorem
  refutation) + e2e966b headline amended per math's review (psum
  not sval). SEALS: math ENDORSED (content) · silicon MEAS green ·
  maestro saltbuild EXIT=0 x2. REMAINING, two named items, the
  reviews' two halves of one rung: (i) hW-DISCHARGE — compose the
  weight-shift organ (its per-cycle theorems ARE the assumed
  weight schedule) + the SECOND overflow condition compiler flagged
  (W<<<t register overflow — exists nowhere yet, needs shaping);
  (ii) SIGN-CYCLE COMPOSITION — FINAL: COMPILER'S OPTION (b) +
  LOAD-PATH OPTION A, RULED TOGETHER (restored 14:5x after a
  ten-minute governance arc, full trail): macSeq gains a carry-in
  port (nIn 32→33, gates 161→160, const gates 0); sign cycle =
  acc + ~x + 1 via the LANDED idiom
  subtraction_is_a_plus_not_b_plus_one + certified bitNot32;
  load path = port not constant; carry_in_is_low retires
  deliberately; the cell ends ZERO constant gates, two admitted
  ports; six per-cycle restatements ONCE. MATH'S LEDGER NOTE now
  IN the ruling per its 14:52 ask: the proof-side cost (the
  restatements + the carry-in composition lemma) is real and
  owned at math/compiler's seams — "strictly dominates" was
  gates-only. THE ARC, kept for governance: ruled → amended on
  silicon's crossing schedule-negated argument → silicon WITHDREW
  in six minutes (it priced a MID-STREAM reload, a mechanism its
  own stream_bit_never_enters_the_weight_register proves absent —
  "second time in fifteen minutes I estimated where they built")
  → restored. LESSONS BANKED: constructions outrank estimates
  EVEN when the estimate's principle is banked-and-true — a
  principle applies only where its mechanism exists; and the
  tied-constant-is-an-unadmitted-port pattern stands (3rd
  measured instance). Nothing was built on any intermediate
  state; the whipsaw cost zero work.
  SETTLEMENT COMPLETE 14:58 — THE FREEZE LIFTS: all three protocol
  pieces delivered (silicon's specifics · math's two-form proof
  ledger · compiler's artifact adjudication), and the adjudicator
  ruled against its own last reversal: schedule-alone is
  arithmetically sufficient but MECHANICALLY costs +32 cycles per
  input (option A's injection width is one bit per cycle — no
  short load exists in the artifact). (b)+A CONFIRMED FINAL by
  the loop, not by default. Implementation clear: compiler (b)+A;
  math the rung-1-3 restatements (rung 3 → (addend,carry) pairs)
  + hW-discharge + second overflow condition against the settled
  interface. PROGRESS 15:3x: (b)+A implemented (b070e38+b801003,
  193 gates, zero constants) · restatements landed (d7d1d6a,
  collision survived 7/7) · compatibility corollary (c08f6a1) ·
  hW-DISCHARGE LANDED (03f5885, attempts 2, wshift_runTrace_state
  = W<<<t after t load-low cycles, covered EXIT=0) · second
  overflow condition ALREADY EXISTED as compiler's landed
  shiftSafe+shiftSafe_at_int8_scale (my dispatch mis-attributed
  it to math; read-before-building caught it free) · SIGN CYCLE
  LANDED 15:41 (3c62228, attempts 3, cell_sign_cycle: acc + ~w +
  1 = acc − w on the (b)-admitted port; off-by-one mutant run;
  rung 3 unchanged — the separate-stepSeq deferral vindicated;
  the :66-68 stale prose past-tensed in the same commit; covered
  EXIT=0 8,677 jobs).
  ⭐⭐ THE CELL WAVE IS COMPLETE AT THE KERNEL MODEL — THE JOIN
  LANDED FIRST ATTEMPT (c732aaa, 15:46, covered EXIT=0 8,677):
  the composing theorem exists — trace + sign cycle + mac_correct
  = b + W·sval — so the trimmed sentence is now TRUE AS A THEOREM
  (trim 15:44 → truth 15:46, twenty-two minutes). BOUNDARIES
  INTACT: evidence's F3 (kernel-model certified; down-to-silicon
  closes at emitS + synthesis) and F4 re-running at evidence's
  fence against ARTIFACTS not status lines (its own 15:46
  clearance withdrawal — trusted the audited doc's status line,
  second instance). NEXT: emitS (compiler, gate open; its 15:45
  emission-criterion corrections govern silicon's parked run).
  The parts: two organs (accumulator w/ carry-in +
  weight-shift w/ load gate, zero constant gates, 193 gates) ·
  the bridge (rungs 1-4, arithmetic reading under ¬saddOverflow,
  demoBound-discharged) · add, shift, AND subtract in the kernel.
  NEXT GATE OPEN: emitS the cell (compiler's genre, pre-authorized
  by the September scope law "kernel Circ + emitS from day one")
  → silicon's EUR-280 settling run fires on the emitted RTL.
  Trap banked: BitVec.shiftLeft_shiftLeft does not exist — the
  real name is BitVec.shiftLeft_add.
  Every seat argued against its own position at least
  once in this thread; the register moved twice and both moves
  are in the trail.**

- **CROSS-SESSION MESSAGING — ADOPTION PLANNED AT NEXT RELIGHT
  (the Captain flagged the new system 14:1x; assessed from the doc
  + live probes): binary 2.1.226 HAS it; every RUNNING session
  predates it (sockets unbound, zero local peers — only cloud/
  Remote-Control rows). WHAT IT REPLACES: the tmux send-keys NUDGE
  layer (addressed delivery between tool calls; kills the
  keystroke-fragility class — Enter-separately, input-box
  stranding, ghost text). WHAT IT DOES NOT REPLACE: the BUS —
  durable append-only record, broadcast, watches; DOCTRINE:
  messages carry POINTERS, the bus carries the RECORD. RELIGHT
  CHECKLIST: (i) name seats via --name in fleet-up.sh (silicon/
  compiler/math/evidence — dir-derived names would collide);
  (ii) verify /list-agents shows all four locally post-relight
  (per-seat CLAUDE_CONFIG_DIR may affect registry — TEST);
  (iii) bypass<->bypass default-delivers, no settings needed;
  (iv) LANE FIREWALL EXTENDS TO THIS CHANNEL: never message
  outside-lane sessions (visible in listings); consider
  isolatePeerMachines:true. NOT worth restarting a humming fleet
  mid-campaign for a nudge upgrade — adopt at the natural cycle.**

- **THE CELL WAVE — THE BRIDGE NODE, RULED at math's 13:36
  refusal-of-credit (its own wave's): maestro's "NDF critical path
  CLOSED" is STRUCK — the honest state is TWO hardware theorems
  (bnC_payload_delivered about batcherNetC; batcher8_sortsTo_word
  about runNetW) + ONE SPEC (mac_correct, arithmetic model, no
  hardware attached). THE BRIDGE = the ONE unbuilt node: (i)
  macSeq — the neuron cell as a kernel Seq/Circ over the organs
  (COMPILER's genre, sequenced after W5-asm rows 15-16; this IS
  the September scope-law "cell as kernel Circ + emitS from day
  one" item, now named as the bridge); (ii) the refinement lemma
  macRun ≈ runTrace macSeq (MATH, author-anywhere land-at-owner
  against its own mac_correct; bit-level carry reasoning — priced
  honestly as NOT-four-minutes); (iii) emitS of the cell (the
  fabbed-is-verified law); (iv) silicon's EUR-280 settling run
  FIRES on the RTL from (i). Genre closed; bridge OPEN; the chain
  completes at (ii).**

- **FUEL COLUMNS — CONFIRMED AT GROUND TRUTH (13:3x, the Captain,
  verbatim: "the columns are account-name,5h,all-models,fable-only
  (fable gets to spend at most half the total budget). Budget on
  jason has the weekly reset tomorrow 4pm, I believe we are going
  to make it."): triple = (5-hour session %, all-models weekly %,
  FABLE-ONLY weekly %); STRUCTURAL LAW: fable's allowance = at
  most HALF the total budget. jason reset = SUNDAY 8/10 16:00
  (SUPERSEDES the earlier "Mon 4pm" note). Burn arithmetic at
  confirmation: fable 51->62 over ~18h ≈ 0.6%/h -> ~78 at reset —
  WE MAKE IT, per his word and the numbers agreeing. Watch rule
  >= 80 stands as backstop. compiler-acct 7/jasonh 3 = fable residue from
  pre-switch sessions (prediction: frozen until reset).
  [History below: the narrowed-hypothesis entry this supersedes.]**
- **THIRD FUEL COLUMN — SEMANTICS NARROWED BY THE CAPTAIN'S DATUM
  (13:3x, verbatim: "*all* the other seats run Opus 5, and credits
  are not being used on any of them"): the CREDITS reading is DEAD
  for the peers (compiler-acct 7 / jasonh 3 are NOT credits); the surviving
  reading = the PREMIUM-TIER WEEKLY METER (effectively the FABLE
  meter) — jason 62 climbing = the maestro's Fable hours; peers'
  zeros = in-plan Opus 5; compiler-acct/jasonh small residues = candidate
  provenance: pre-switch maestro sessions earlier in the week
  (PREDICTION: frozen until Mon reset while jason alone climbs).
  RESIDUALS for the Captain's next portal glance: the column's
  literal LABEL + the pre-switch-host confirmation. WATCH RULE
  ARMED (maestro): any reported jason triple with third column
  >= 80 -> immediate flag + the HARD house-split (Opus for
  coordination/ceremony, Fable strictly for design blocks).
  Operational fact: the fleet's entire premium burn is ONE seat;
  four seats run at zero marginal premium cost.**

- **NDF PACKAGE APPROVED (13:2x, the Captain, verbatim: "NDF
  lgtm") — the design package v1 (through the r-convention, the
  k-collision banner, §§1-6 + 2b/2c/3b/5b/5c) stands APPROVED as
  the NDF's design baseline. Subsequent changes are amendments to
  an approved document, not drafts.**

- **COUNCIL BUNDLE (12:0x, the Captain, slate items): (2) COST
  WINDOWS "so ruled" — story row = dream->ruling (1.14M measured),
  cost row = NDF-from-T0, campaign total separate, every number
  names its window; (5) PCBs RIDE THE NDF ("for the BB I will
  probably not get PCBs, but let's use them on NF"); IMMEDIATESCOPE
  RETIRED (authorized + executed: remove + saltbuild EXIT=0,
  8674->8673 jobs, the rider's own proof form); DEFAULT AUDIT CAP
  RAISED 12000->24000 (saltbuild.sh CAP line + comment; the --cap
  dance for known heavies retired; machine guard remains the fleet
  lock); (7.3) CLICK SPENT (12:0x, his verbatim "assemble (7.3)")
  — the Opus assembly wave DISPATCHED (salt repo, math-seat
  pattern; flags anchors 21293/22150/22257 as statement source,
  precondition preamble, saltbuild-only, warnings-by-difference,
  axiom check, one pathspec commit, stop-loudly-on-resistance);
  ✅ LANDED 12:2x FIRST ATTEMPT — sawtoothMajorant_fourier_expansion
  + hasSum_majorantCoeff (Salt/Weil/MajorantExpansion.lean, salt
  e2307cc pushed): HB (7.3) literally, K>=2, every real theta;
  axioms clean x7 rows verified twice; saltbuild EXIT=0, 9722 jobs,
  warnings 190->190; mutation control ran properly (FALSE mutant ->
  EXIT=1, byte-identical restore, green rebuild); two flags naming
  facts corrected (root-namespace fourierCoeff; Fact (0<1) local);
  the one out-of-pathspec stale dossier row fixed by maestro
  (a1f8f0b). THE WEIL SAWTOOTH KIT (7.2)+(7.3)+(7.4) IS COMPLETE; (4) the 3+4 deep session CONFIRMED NOT YET HELD (the
  evening went to the tile/packet/neural arc; subjects crossed the
  helm at their landings — the deja vu source); proposal open:
  fold into an NDF theory review sitting. RISC-V ACCOUNT DOC:
  does not exist as one artifact; commissioning offered (the
  bb-switch-account 70-min pattern). THIRD FUEL COLUMN: "credits"
  hypothesis before him, awaiting one-word confirmation.**

- **THE SHUTTLE DEADLINE — THE SCHEDULE ANCHOR, CAPTAIN-CORRECTED
  11:5x: HIS LOGGED-IN PORTAL SHOWS 29 DAYS TO RESUBMIT ≈ SEPT 7
  (corroborates the standing B5 Sept-7 date; GOVERNS over the
  public-site fetch's "SKY26c, 44 days ≈ Sept 22" — possibly a
  different shuttle; his account view is authoritative). 3x2 slots
  still available per his read. Login portal = app.tinytapeout.com
  (GitHub sign-in — separate subdomain, no login link on the main
  site). Early-bird pricing limited per shuttle. ALL NDF
  SCHEDULING BACKS OUT FROM ~SEPT 7 — two weeks tighter than the
  first estimate.**

- **⛔ GATED: CAPTAIN — the purse ruling on the NDF tile spend (6×2 = 12 tiles, EUR 840, two-high). UNLOCKS ON: the Captain naming the spend. Until then this row is NOT pullable — the measurement under it is COMPLETE (silicon, post-layout, 11:46) and only the money is open, which is exactly the shape that reads as workable.**
- **NDF TILE SHAPE — AWAITING THE CAPTAIN'S PURSE RULING (silicon's
  probe answer, 11:46, post-layout measured): minimal demo (k=4 +
  8x8 BB + core) requires 6x2 = 12 TILES, EUR 840, TWO-HIGH
  (unscarce shape; 3x4 = same capacity but burns one of two scarce
  4-high slots — refused). 6x2 actually delivers k=7-9 headroom.
  Ladder: 2x2 core-does-not-fit · 3x2 core-only (1,399 um^2 spare
  — this morning's approval stands FOR THE CORE, cannot be the NDF
  tile) · 4x2 k=2-3 short · 8x2 EUR 1,120 k=12-15 (stretch, not
  recommended). MYTH BUST: the "24-tile cap" = the 6x4 SHAPE (and
  the pinout count) — documented max is 8x4=32. Density lever
  50->60% ≈ +20% cells, NOT recommended without a slew run.
  MAESTRO RECOMMENDATION: 6x2 at EUR 840.
  RESERVATION TIMING RULED (11:5x, the Captain, verbatim: "I'll
  not reserve the 6x2 until we are close to layout. If we get
  bumped to the next one (2 weeks later) it is ok"): NO early
  reservation; reserve at layout-readiness; a one-shuttle slip
  (~2 weeks past ~Sept 7) is ACCEPTABLE. Full throttle unchanged —
  the target stands, the deadline is soft by his word.
  THE EUR-280 QUESTION (silicon 11:55, pending measurement —
  auto-resolves inside the timing ruling's window): 4x2/EUR 560
  would hold the minimal demo at 52.7-56.2% utilization — the
  UNMEASURED band (clean points 44.65/48.77%; the 63% datum was
  free-floorplan, does not transfer). Settling instrument: one
  ~10-min hardening run, 4x2 die, synthetic 71.8-76.6k um^2 load —
  FIRES THE MOMENT THE CELL RTL EXISTS (silicon's first run).
  Until then 6x2 stands, now measured-ROBUST (35-37% util).
  SILICON'S 12:09 ADVERSARIAL SELF-CORRECTION (recommendation
  SURVIVES, inputs corrected): (i) the floorplan had used the bare
  BANYAN not the BB — fabric understated ~4,159 um^2 (0.7 cell);
  corrected 6x2 util = 36.5-38.8% still comfortable; 4x2 = 55.4-
  58.9%, deeper into the unmeasured band. (ii) the "24-tile cap"
  myth-bust WITHDRAWN — the 24 is the PIN budget (design doc §3b),
  an arithmetic coincidence published as provenance. (iii) THE
  INVERSION: k IS CAPPED AT 4 BY FABRIC PORTS (8 = 4 cells + CPU
  + 2 edge + 1 spare), NOT by area — bigger tiles buy unaddressable
  silicon; 6x2 is the RIGHT size, not merely sufficient; k>4 needs
  a bigger FABRIC (16x16, v2), never a bigger tile.**

- **NDF BENCH HARNESS (registered 11:4x at the Captain's memory-
  hassle question): RP2040 firmware = the memory-server side of the
  8->32 multiplexed bus (PIO state machines: latch 4 addr bytes,
  serve 4 data bytes — the standard TT ROM/RAM-emulator pattern,
  ~100 lines PIO+C) + the packet-port side (feed weight/input
  packets, capture results). STATUS: scheduled September work,
  small; OUTSIDE the verified surface (test equipment, same trust
  class as the logic analyzer). The CHIP side of the protocol is
  ALREADY BUILT AND SIGNED OFF (slicea16bma's phase demux, 3x2
  die). Owner: assign at the harness seam (compiler or silicon).**

- **COUNCIL RULING #8 — THE WIDTH RULING (11:3x, the Captain,
  verbatim: "Yes, the word width is not important for the PoC,
  let's rule 8-bit"): VALUES ARE 8-BIT FIXPOINT (weights +
  activations — the quantization story stands and supplies the
  cheap overflow bounds); WORD WIDTH ruled UNIMPORTANT for the
  PoC ⇒ implementation takes the seats' converged free path:
  the LANDED 32-BIT DATAPATH carrying int8 values sign-extended
  at ingress (option-2 mechanics). Zero new certificates
  (wordSignedOrder + CE + adder32 all reused at 32); activation
  compares at 32 (math's width question CLOSED); no-overflow
  witness trivial from the int8 bound (B5 discharged by decide);
  NO requantization organ in the minimal demo; 8-bit-NATIVE
  datapath (8b latches, 8-cycle MACs, shift+saturate requant) =
  the v2/production optimization, priced as reference only.
  Decision inputs that converged: math's certificate ranking
  (2)<<(1)<(3); silicon's "area should not decide this" (native
  saving does not change tile count).**

- **COUNCIL RULING #7 — THE PATH RULING (11:3x, the Captain,
  verbatim): "This is my proposal: * Keep the pure BB switch, I
  will update TT * Keep the pure RISC-V + 5 op ISA + EXEC + tiny
  Rust + sort demo; defer submission to TT * Full throttle on the
  new Neural Dataflow Fabric, new submission to TT, target in
  Sept, we start as shown in the THE FABRIC, I assume we adapt
  EXEC as needed, tiny-Rust is probably unchanged."
  ⇒ THREE-PROJECT STRUCTURE: (1) BB switch — kept, Captain
  handles the TT update himself; (2) pure RISC-V stack — runs to
  COMPLETION (per ruling #4: complete/verified/tapeout-ready),
  TT submission DEFERRED — costs nothing, the core ships INSIDE
  the NDF as its control plane; (3) NEURAL DATAFLOW FABRIC (NDF,
  his "THE FABRIC" = design package Sec2 chip diagram: BB + k
  cells + core, one combined project) — FULL THROTTLE, NEW TT
  submission, SEPTEMBER TARGET. EXEC adapts (phase sequencer:
  LOAD_W/rounds/ACTIVATE/EMIT as executive-scheduled tasks);
  tiny-Rust ~unchanged (possible v2.1 packet-IO intrinsics).
  ALL FOUR Sec7 PROBES FIRED at this ruling (silicon cell+
  floorplan vs the 24-tile cap · math MAC induction — CRITICAL
  PATH — + signed-order discipline · compiler layer-compiler
  rows beside W5-asm · evidence fence armed, clock starts).
  MAESTRO'S FLAGGED RISKS AT DISPATCH: (a) NDF is the LARGEST
  project yet — tile count vs 24 must land EARLY; (b) Sept =
  ~3-4 weeks — demo scope freezes early (minimal: k=4 cells +
  8x8 BB + core, ONE GNN layer, bench demo; multi-layer/training
  = stretch); (c) the cell is built as a KERNEL Circ + emitS from
  day one (the fabbed thing IS the verified thing — no hand RTL);
  (d) the actual TT shuttle deadline is the Captain's TT-update
  errand — flagged as the schedule anchor.**

- **COUNCIL ITEM (10:2x, the Captain — the #3 DETAIL PACKAGE,
  conditional not yet a ruling): "Yes, dataflow architecture, of
  course :)" — he likes the path ("close to home but not too close…
  very close to home personally") and framed THE STORY: "I had a
  revelation in the middle of the night! What is the total cost to
  bring it all the way from that unconscious dream to PoC silicon,
  *verified* every step of the way? ~2days for the design, ~20M
  tokens, ~$500 for TT" (numbers adjustable). His SIX ASKS, all
  delivered 10:2x in docs/neural-fabric-poc-design-v1.md (§1 cell
  + block diagram + LSB-first answered: not a problem, sign-cycle
  op mux, parallel accumulator boundary; §2 fabric chip+system;
  §3 CPU role: yes, control plane, the W5-asm core; §4 GNN worked
  example w/ 3-row verified decomposition; §5 tradeoff table) and
  docs/midnight-to-silicon-story.md (§6 the running story log w/
  evidence-fenced cost table). SEAT PROBES (§7: silicon cell
  pricing/floorplan · math MAC-induction scoping · compiler
  layer-compiler rows · evidence number fence) FIRE ON HIS WORD.
  DECISION PENDING: choose this path / shelve with drawer alive.**

- **COUNCIL RULING #6 (10:0x, the Captain, verbatim: "Both 1 and 2
  are good choices, but I need to work through 3a/3b to convince
  myself if there is anything new here, or it was just a dream. So
  let's defer 1 and 2 for the #3a/b discussion, then we will circle
  back."): #1 AND #2 DEFERRED-NOT-DROPPED; #3 discussion is the
  active council thread. His lead questions on the table: (q1) the
  unit of operation — his sketch: values bit-serial on one input,
  weights (+bias?) on another, weighted sum then nonlinearity
  ("the Batcher mux?"); (q2) generality — CNNs, GNNs, etc.
  Maestro's council answer given (the fused cell: latched-weight
  serial MAC + bias-as-preload + certified CE-as-ReLU; generality
  via the {affine,max,route} = piecewise-linear = ReLU-family
  characterization; GNN-native reading; softmax honestly flagged
  approximable-not-native; novelty = the VERIFIED stack, not the
  hardware genre). LATCH LADDER same sitting: storage 35%
  smaller/bit than flops (silicon, method validated against
  measured flop table); does NOT rescue packet-boot imem — SRAM
  remains the onboard-program rung; full latch figure needs
  explicit PDK cell instantiation, Captain's call whether the
  rung closes at 35%-on-storage.**
- **COUNCIL RULING #3 (09:0x, the Captain): B-ISA AND B-EXEC WAVES
  ARE GO — "Either way, we will want to do the B-ISA, B-EXEC
  waves." SEQUENCING per the block's own capacity law: B-ISA
  per-op waves interleave at compiler's seam as tiny-Rust N-waves
  clear (one write track); B-EXEC follows B-ISA structurally,
  DRIVER row first. FINAL LAYOUT IS DEFERRED until the packet-IO
  discussion — his two options, verbatim: "1) BB (silicon), RISC-V
  (silicon, separate project from BB)  2) BB + PACKET-IO CPU (TBD,
  silicon), RISC-V (layout, only for now, until we decide to fab
  it)". TILE GEOMETRY DATUM (silicon, 8/9 10:35, pre-registered
  90-min cap): 3×2 = ROUTABLE TILE (8 min to full signoff);
  2×2 = MARGINAL, not refused, not proven (stuck at 10 violations,
  168 iterations at floor) — PLAN ON 3×2; the 2×2 is a research
  afternoon only if tile money demands it. Silicon's 8/8 "REFUSED"
  verdict was withdrawn as overclaimed. THE MUX FACT THAT SHAPES
  THEM (dossier §2.2, V-SRC):
  unselected TT designs are POWER-GATED OFF — separate projects
  are never powered simultaneously, so on-die packet interaction
  exists ONLY in option 2's combined project; option 1's joint
  demo is two chips + host wiring. Per-project tile pricing; the
  owned-4 reallocation question remains the Captain's checkout
  read.**
- **COUNCIL RULING #2 (08:4x, the Captain: "Yes, fire the probes"):
  THE TINY-RUST PROVING CAMPAIGN IS FIRED, PROBE-FIRST per the
  probe-then-wave doctrine. The hpool-separate flag stood UNVETOED —
  "well-typed, pool-fitting programs compile" is the campaign form
  (lang-design v1.4). SEQUENCE: N0 PROBE LAYER first (compiler's
  slot, the HDL/CodegenSpec frame): the typing judgment as data +
  the pre-registered controls — T2 accept AND reject (`while 1`,
  i32-where-bool), F6 bigStep-inhabitation — all by decide, positive
  controls carried per the Purse; waves N0→N5 fire as probes come
  back green, statements at the v1.4 forms. MATH's standing
  refutation pass rides every statement BEFORE its wave fires (the
  slate system that produced 20 findings pre-kernel stays in the
  loop). W5 remains its own decision (agenda #4), unconflated.**
- **COUNCIL RULING #1 (2026-08-09 08:4x, the Captain, verbatim: "we
  have the RISC-V layout fitting in a 3x2 -- we will want this
  layout no matter what, even if we decide not to submit it, so
  let's approve and make it real"): THE 3×2 LAYOUT IS APPROVED —
  MAKE IT REAL. The work is DECOUPLED from the submission decision:
  hardening fires NOW (silicon's slot, PRE-AUTH under this ruling);
  the calculator read (€140/€420) no longer gates work and moves to
  SUBMISSION time (rides the B5 window, his word then). THE
  CAMPAIGN: slicea16bma at the REAL 3×2 die (FP_SIZING absolute) ·
  DRV repair (637 typical/1,678 worst-corner slew) · the
  submission-config checklist (CLOCK_PERIOD=40 reconciliation, the
  registered trap) · pin map finalization (18/24) · fetch-protocol
  design question runs in parallel, does not gate the hardening.**

  > ⚠️ **SUPERSEDED IN SUBSTANCE 2026-08-29 (helm, council row r; the ruling itself is
  > PRESERVED, not deleted — an authorisation that is removed leaves no trace that it was
  > given).** This pre-authorisation is TWENTY DAYS OLD and its campaign has been overtaken by
  > the banyan / ndf / _c32 line: the 3×2 hardening it authorised is no longer the work in
  > front of the silicon lane, and the tape-out path now runs through the ndf-2a resubmission
  > (Sept 4–5 click, hard deadline Sept 7). ⇒ **DO NOT START WORK ON THIS PRE-AUTH.** It stands
  > as the record of a ruling that was given and acted on, not as a live licence. A fresh
  > authorisation is the Captain's to give.
  >
  > 📌 *Why it was still readable as live:* nothing marks an authorisation as spent. A stale STOP
  > is caught by the next build; **a stale GO is caught by nobody** — it simply waits for a seat
  > with capacity to read it as permission. Found by silicon while banking (08/29 15:1x).
- **TILE DECISION — THE CAPTAIN'S CONDITIONAL WORD IS GIVEN (21:2x,
  at the helm, verbatim on the bus): byte-wide feed + 32-BIT
  ADDRESSES multiplexed onto the 8 address pins (4 byte-phases, like
  the data) + OWN TILE — "if so, we should choose it, on its own
  tile." The EUR 280 is authorized BY HIS WORD, conditional only on
  silicon BUILDING the multiplexed-address variant (slicea16b-ma)
  green: 32-bit PC out in 4 phases over uo_out, instruction in over
  ui_in, phase strobe on uio; the pipelining question (overlap
  next-address with current-data for ~4 cyc/word vs 8 naive)
  answered at the bytes. The (a)-vs-(b) fork is CLOSED — (b) chosen;
  co-tenancy retired (byte-wide needs 10+ vs 7 available; the switch
  is itself byte-wide). History: parallel untapeable (64 sig vs 24);
  serial priced 781K instr/s; byte-wide priced FREE IN AREA
  (2,706 cells vs serial's 2,709) at 6.25M instr/s. Hardening:
  LibreLane UP (additive, PDK-copy guard); slicea16b harden
  in flight as the FLOW verdict; -ma becomes the tapeout candidate
  on silicon's green. HARDEN VERDICT (21:23): flow COMPLETE — GDS ·
  DRC 0 · LVS clear · STA +19.29 ns at 40 ns (25 MHz answered by
  STA). ⚠️ POST-LAYOUT IS 1.56× PRE-LAYOUT: 43,120 µm² stdcell =
  95.1% of a 2×2 — past silicon's registered 80% bar, the sheet
  word is TIGHT, and the 4.9% headroom predates the address path.
  The Captain's condition therefore remains genuinely OPEN on AREA
  (pins near-yes): silicon measures slicea16b-ma rather than
  reasons. Named escape if 2×2 fails: TILES BUY AREA — a larger
  tile (3×2+) preserves "own tile" at higher EUR; his word named
  the tile, not the size. DRV violations (1,391 slew/21 cap/17
  fanout) owed before any real submission; the true TT tile-fit
  run (FP_SIZING absolute) is the next measurement. -ma MEASURED
  (21:26, c939abe): PINS YES — 18 of 24, six to spare, and the
  bring-up port DISAPPEARS (the address bus IS the PC, better debug
  for free); pre-layout 29,583 µm² (+7% vs -b; fewer cells MORE
  area — flops beat logic cells; area the honest axis). ⭐ THE
  UNASKED CORRECTNESS FINDING: in -s/-b yosys DELETES 17 of 32 PC
  bits (unobservable) — "has a 32-bit PC" was true of the RTL, not
  the gates; -ma is the FIRST variant whose PC is architecturally
  REAL in silicon (31 pc_q flops). The Captain's pinout choice
  fixed a truth gap nobody had seen. OPEN: post-layout area (harden
  in flight; expected near/just over a 2×2 — tiles-buy-area frame
  adopted, size vs EUR is the residual question) and the FETCH
  PROTOCOL (latency/wait states — a named DESIGN question for the
  morning, not settled by this artifact). ⭐ -ma HARDENED (21:30,
  measured): flow complete · DRC 0 · LVS clear · timing MET
  (+16.91 ns at 25 MHz) · pins 18/24 · post-layout 45,205.9 µm² =
  99.7% of a 2×2 — silicon REFUSES the technical pass (25 cells of
  headroom with 1,678 max-slew fixes owed that ADD cells): the
  honest reading is -ma DOES NOT FIT a 2×2; A 3×2 IS 65.6%
  (CORRECTED 22:51: height ∈ {1,2,4} per the placer — no 3×3
  exists; silicon's catalogue catch),
  comfortable with DRV+ECO room. Family finding: even -b is 95.1%
  — a 2×2 was never comfortable for 16-reg/32-bit Slice A; the
  register file is the mass, fourth instrument agreeing. ⇒ THE
  CAPTAIN'S CONDITION IS MET; the executable form of his word is
  BYTE-WIDE -ma ON ITS OWN 3×2 (€420 fresh / €140 incremental if
  the owned 4 apply toward 6). RESIDUAL (T1, money): the 3×2's
  actual EUR (the 280 was the 2×2 figure — real TT price to be
  read, never inferred) — his one-word confirmation at morning.
  DRV repair owed pre-submission.**
- **COLD-CACHE REPRODUCIBILITY — CLOSED BY RETRACTION (compiler
  20:4x): the full build's module form is UNCAPPED; cold rebuild
  measured green. The corpus reproducibility gap NEVER EXISTED — it
  was a one-arm read of saltbuild's two-arm case dispatch. W6's
  census TABLE stands as readings of the AUDIT instrument: modules
  demanding >12 GB need `--cap 24000` path-form (now a QUEUE law
  above, stated BY CAUSE). Remaining council line, framed HONESTLY
  (silicon 08:15 — the "three modules" scope tilted the answer):
  heavy modules keep landing, so the question is whether the AUDIT
  default rises (cause-adequate) or the --cap rider stands
  (list-adequate only until the next heavy module) — the framing
  is the decision, so it is stated by cause.**
- **N7 DESIGN DEBTS, MAESTRO-OWED — ✅ BOTH DISCHARGED 08/11 (the
  Captain's "please fire" at morning council; ruling f-ii): (a) the
  N7 ASSEMBLY design block is WRITTEN AND THE GATE IS OPEN —
  salt `docs/exploration/n7-assembly-gate-0811.md` (three waves:
  A = §7/Lemma 10 opens now, math pulls; B = §5 on A's seal;
  C = §6 scout in parallel). (b) the W4-a DESIGN CAMPAIGN was
  DISCHARGED BY EVENTS before it was registered: the structure
  theorem landed at `eb14498` 08/06 10:28 (`Salt/HB/
  RealPrimStructure.lean:737`, a ∈ {0,2,3}, 799 ln vs 1,300–2,600
  priced) — this debt's original text ("mathlib has the tools, not
  the theorem") was written 08/08 20:39, 58h AFTER the landing: a
  register asserting world-state instead of measuring it. The
  flagship front at solo tier REOPENS behind gate (a).**
  <!-- original debt text, registered 1f4a313 08/08 20:39: "(a) the
  N7 ASSEMBLY design block (wiring the landed+composing (7.7)
  inputs and the kernel'd 2-adic collapse into the road row); (b)
  the W4-a DESIGN CAMPAIGN (gap row 8: real-primitive-conductor
  2-part classification; 1,300–2,600 ln pricing CONFIRMED by
  math's shrink attempt — mathlib has the tools, not the theorem).
  The flagship front at solo tier is exhausted until one of these
  opens a gate." -->
- **⭐⭐⭐ THE 01:0x NIGHT COUNCIL — ALL EIGHT RATIFIED (the Captain,
  at the helm past midnight, verbatim: "all recommendations
  ratified, let's fire up the fleet" + the target: "can we get
  first layout tonight"). The 07:30 sitting COLLAPSES to the ③+④
  walk — the design decisions are ruled here:
  R1 FABRIC STAGING: per-round decide+kernel fixtures for September
  (each demo round its own check on the netlist model); the Batcher
  sort-then-route seam = the named v1.1 node.
  R2 DRIVE: _1 combinational (the owned TT-CI green) · _2 flops
  (dfxtp_1 on no_synth.cells, one-sided) · the _2 settling
  measurement rides emitSeq bring-up.
  R3 FETCH = THE TAPE CONTRACT: byte k on phase (k+3) mod 4 (byte 0
  leads its address by one phase); reset quirk documented (addr-0
  instruction skipped, pc→4); the RP2040 plays a byte stream
  generated OFFLINE from the Lean runW trace, bench-asserted at
  phase_o.
  R4 CPU: September = DEMONSTRATE (verified code on its own bus,
  sequencer autonomous); conduct = B-ISA SW + port organ, v1.1;
  PC-decode strobes stay priced, unbuilt.
  R5 THE PIN AMENDMENT CONFIRMED (the Captain's word, the D10.6
  veto spent): sof+valid replace the ruled third packet port;
  frame-phase observability narrows to valid-only; the argument
  is rst_n-destructiveness once the die carries state.
  R6 THE SHELL RATIFIED: per-cell acc CLEAR + en_wsh + en_acc +
  sign-extension hold; V9 kernel model owed; OWNER COMPILER; cost
  lands in emitSeq flops — scCore and all 19:34 measurements
  untouched.
  R7: residual-15 audit theorems → MATH (SelfRouting floor, its
  lane) · census-tool gitignore fix → COMPILER (its tool).
  ⭐ THE 01:1x BLANKET (the Captain, verbatim): "do everything you
  can to make this happen. don't wait, asking for correction is
  better than asking for permission. you are pre-authorized for
  all decisions. if we can make this tonight, that *is* the gold.
  revisions can always come after should we decide." — ALL SEATS
  operate correction-over-permission for the night push; the
  maestro parallelizes by hand where it shortens the path
  (author-anywhere land-at-owner).
  R8 FIRE PLAN LIVE — NIGHT WAVES AUTHORIZED, SUPERSEDES REST:
  compiler = emitSeq → shell emission (4 cells) → SER/activation
  organ → tt_um_saltworks_ndf wrapper + sequencer (hand RTL per
  the D2(b) exemptions, 2-2-1 schedule) → per-round fixtures;
  silicon = the 4x2 settling run + the 6x2 FIRST LAYOUT the
  moment composed RTL exists (config pair 55/18181818, DIE_AREA
  6x2, the agreement law in one commit); math = standing
  refutation + residual-15 at its pace; evidence = fence rides
  every landing, demo-sentence pass owed pre-walk. FIRST LAYOUT
  TONIGHT is the named target; the fabbed-is-verified law governs
  the SUBMISSION, not the first measurement run — V1-V3/V9/V10
  land behind the layout, before any tapeout word.**
- **⭐ ② RE-STATED AT THE MORNING ROLL-CALL (8/15 06:4x, the helm; the
  full walk of memory-design-v1.md §1 against the landed tree, existence
  at the bytes): ② is COMPLETE-WITH-NAMED-RESIDUE, not EXECUTED-whole as
  the entry below said — the below named only M0/M1+M1a/M2/M4, and the
  omission is exactly how the residue went unrecorded. THE RESIDUE, both
  rows ②-proper by the plan's own assignment: (1) M3's CONTROLS — the
  E-4 analogue with LW (task-B [LW rd=1 addr] on the overlap register,
  §1:343-346) and the SW writesWithin regression, ABSENT from
  ExecutiveX1.lean — VERDICT RE-TESTED AND HOLDS 12:4x, EVIDENCE REPLACED:
  this row cited `grep -F "Instr.LW"` returning zero corpus-wide, which is an
  ARTIFACT OF THE SPELLING — nobody ever writes the qualified form; `\.LW`
  returns 30. A true claim on an instrument that cannot match anything, and
  the first seat to re-run it would reasonably have concluded the CLAIM was
  broken. Re-tested with a matching pattern: BOTH NAMED CONTROLS STILL ABSENT.
  Context that belongs beside the verdict, since "absent" reads wider than it
  is: the E-4 control FAMILY EXISTS (e4_writesWithin_pos + e4_writesWithin_neg,
  ExecutiveX1.lean:243-250, both with #print axioms) but is built from LW-FREE
  programs — ExecutiveX1 carries ONE `.LW`, inside `writesInstr`; and LW/SW are
  NOT unverified — Certs/MemTrapResponse.lean proves four trap-response
  theorems (lw/sw × misaligned/out-of-range), a DIFFERENT family from the
  frame/partition controls this row is about; (2) M5 ENTIRE (§1:369-377) — the honesty fence itself is
  DISCHARGED: corrected and built at 697740b 06:43 (ISA.lean:1038,1051-1052
  now read "seven-instruction subset", 16,875,520 = 0.3929 %, undecodable
  99.6071 %; saltbuild EXIT=0, build arm).
  ⛔⛔ THIS ROW WAS CORRECTED AT 12:1x AND THE CORRECTION WAS ITSELF WRONG.
  RETRACTED 12:3x, refuted by the math seat. The 12:1x text claimed only TWO
  downstream sites existed and that RegWrite.lean and riscv-core-campaign-v0.md
  had NEVER carried the figure. FALSE. THE FENCE HAS TWO DOWNSTREAM FORMS AND I
  SEARCHED ONE: I tested `0.1976`/`8,486,912`/`99.8024`, while those files carry
  it as "99.80% of the word space is undecodable" — RegWrite.lean:36,116 and
  riscv-core-campaign-v0.md:96,100, THE EXACT LINES the 06:39 row cited and the
  12:1x text called invented. `git log -S "0.1976"` returning nothing was TRUE
  AND IRRELEVANT: "no commit added that string" is not "this file never carried
  the claim". THE 08/07 LEDGER LIST WAS CORRECT; my accusation against it is
  withdrawn in full.
  ⇒ RE-MEASURED (numeric forms only, `git ls-files`, hand-checked — `five
  instruction` dropped, since it matches a comparator's size in SortDemo.lean
  and the CORRECT "five-instruction Slice A subset"; Slice A IS five, decode
  accepts seven):
      STALE-ONLY (7): PcNext.lean · RegWrite.lean · Stack/Program.lean ·
      EVIDENCE-campaign.md · LEDGER.md · hdl-c4-composition-check-0807.md ·
      riscv-core-campaign-v0.md
      corrected alongside (4): ISA.lean · QUEUE.md · memory-design-v1.md ·
      s0-r2-memory-census-0807.md
      11 files · 37 occurrences · SEVEN stale-only
  ⇒ I BUILT A POPULATION WALK TO ESCAPE AN INHERITED LIST, THEN RAN THE WALK
  WITH A PATTERN THAT COULD NOT SEE THE THING. A walk with the wrong pattern is
  an inherited list with better manners — and the wrong story was the dramatic,
  self-flattering one, which is why it needed the most testing and got the least.
  The rest of the residue is kernel-lane work
  (math+compiler shared per the plan); ③'s own doors and gates are
  unchanged by it. Door 2 of ③ noted LANDED since (fb3842a,
  Decoder.lean:333). Full roll-call table in the session record.**
- **⭐⭐⭐ D1a DISCHARGED — `Dmem8.lean` EMITTED, INDEXED, REPRODUCIBLE AND
  ELABORATING (silicon, 08/17, on the narrow channel; the 08/17 ruling below
  is NOT rewritten).**
  **BUILD ROW, which the caveat makes owed and which is the point of the
  row:** `saltbuild EXIT=0` · `✔ [4/4] Built SaltWorks.Silicon.Imported.Dmem8
  (4.7s)`. ⚠️ **BUILT, not `Replayed`** — the sibling `BitSliced` on the same
  run says `Replayed`, so the distinction is visible in the same output: a
  replayed module proves the cache, this one ran the elaborator.
  **THE DATUM:** 673 cells (417 logic / 256 sequential) → 1984 gates, 256
  flops cut, 293 inputs (37 design + 256 state), 288 outputs (32 design +
  256 next-state). Readback vs vendor Liberty: 32 vectors × 288 outputs,
  agrees. Conservation: text-scan 256 = parsed 256 = cut 256.
  ⭐ **1984 gates / 256 flops REPRODUCES the dmem8-scale figure banked at
  `1f9d2c0` (08/12) from an independent regeneration** — that figure was
  carried as a claim about a green that was never re-derived; it now is.
  ⛔ **THE RESTRICTION IS THE WHOLE JOB, and it is why D1a was work rather
  than a copy: dmem8's 256 flops are `dfrtp` (async reset) and the importer
  REFUSES them outright without `--pin-reset`.** Under it `rst_n` is held at
  the inactive value the CELL MODEL declares, never one the caller picks; the
  datum is namespaced `Restricted_rst_n_eq_1` so no theorem can quote it
  without carrying the restriction. **It says NOTHING about the deassertion
  seam and must never be cited as covering reset or bring-up.**
  ✅ **AND THE IMPORTER ENFORCED THE RESTRICTION AGAINST ME rather than
  trusting me:** my first invocation listed `rst_n` in `--inputs` and was
  REFUSED — a pinned net left in the input list would let a theorem drive the
  very net the restriction fixes. ⇒ Port arithmetic: 70 port bits = 37 design
  inputs + 32 outputs + **1 pinned reset**, and the missing bit IS the
  restriction.
  📌 `reimport.sh` carries the row (`run()` gained an optional 7th arg for
  importer flags): **6 of 6 regenerable datums reproduce byte-for-byte**, the
  five pre-existing rows included — which is the control that the `run()`
  change is inert, measured rather than asserted. Registered debt unchanged
  and still named: RefComparator (hand-written) · Fabric · FabricCut (CI
  artifact).
  ⚖️ **THE BAR MET IS THE AMENDED BAR.** Not "C3 passed".
- **⭐⭐⭐ THE FLAGSHIP RESTATEMENT PRINCIPLE RULED — the afternoon
  council's item 3 (15:1x, the Captain: "yes, accept recommendation"):**
  **THE PRINCIPLE: the flagship's bound is stated IN THE UNITS THE
  MACHINE HONORS** — the step bound stays a step bound; any cycle
  guard is DERIVED from the stall semantics and CARRIES ITS
  DERIVATION; **no bare literal survives whose meaning depends on the
  retired cycle=step identity.** The concrete theorem text returns to
  HIM at the freeze, by the same road as the offboard claim ladder
  (design block → refuter pass → statement text at his desk). ⇒
  **COMPILER'S ARCHITECTURE CHOICE IS UNBLOCKED** — the narrowed
  question (HOW the stall arm is stated) composes with any restatement
  form. **SCHEDULE POSTURE RULED WITH IT: the Sept-7 aim STANDS**; the
  two undated rungs — the `C4Spec` witness for the composed core, and
  the restatement itself — enter the plan-to-prove WITH DATES owed by
  silicon+compiler; revision reaches his desk ONLY if the dates break
  the window, never silently. With this, all three of the afternoon
  council's items are closed: the IARC filing his (annex ready), M2
  authorized with FD-first-then-twin, and this principle.
- **⭐ ROUTE (A)'s PREREQUISITE DEMONSTRATED — the import RUNS and the
  strobes BIND BY NAME (14:2x, silicon; recorded with the verb the day
  earned):** core32 imports cleanly at 4,441 instances → 18,439 gates,
  1,024 flops cut with conservation 1024=1024=1024, readback agreeing
  with vendor Liberty on 32 vectors × 1,124 outputs, and
  **`dmem_req`/`dmem_we` bound BY DECLARED NAME at indices 68/69** —
  which is exactly the antidote the discharge-block refuters said does
  NOT exist for `--cut` boundaries and DOES exist for declared ports.
  The two constant bits `imem_addr[1:0]` are omitted and the datum
  RECORDS the omission (`core32NL_outs_omitted`), so it is
  machine-visible rather than silent. ⛔ **STATED PRECISELY: this is a
  DEMONSTRATION, not a landing — helm checked at 14:2x and
  `SaltWorks/Silicon/Imported/Core32.lean` is NOT in the tree yet.**
  The discharge wave stays sequenced AFTER the offboard RTL freeze;
  this only proves its road is open. Track-early applies to the datum
  when silicon lands it.
- **✅✅ CELL COVERAGE CLOSED — `b3be185`, THE MECHANICAL RUNG OF THE
  SEPT-7 AIM IS DONE (14:1x; helm-verified at the bytes: +31 lines
  `Cells/Sky130.lean`, +26 `Importer/import_netlist.py`):** by the
  fleet's CONTROLLED census, not a hand list — **47 clean + 0 BLOCKED
  + 1 empty = 48 of 48 netlists** (from 35 clean + 12 blocked). All
  seven models proved **[0 axioms]**, `saltbuild EXIT=0`, and **both
  encodings transcribed from the SAME Liberty string — one source, not
  two authors**, which is the structural fix for the two-encodings
  finding rather than a second transcription. ⭐ **THE COMMIT IS ITS
  OWN LESSON'S PROOF: every one of those cells ALREADY had a green
  `_liberty` theorem and core32 REFUSED on `o32ai_1` anyway — PROVED
  IS NOT WIRED.** ⇒ **the Sept-7 aim's remaining path is TEMPORAL
  ONLY** (the which-cycle binding, the stall contract, the bus-FSM),
  where compiler's block is at round 3 and the architecture choice is
  blocked on the Captain's statement-tier ruling. The rung's price
  history stands unrewritten below: 43 → 4+39 → 3 → 7 rows → CLOSED.
- **⛔ THE CELL-MODEL RUNG, THIRD AND FINAL CORRECTION — AND THE 39
  TABLE ROWS ARE UNNECESSARY (13:5x, silicon's second self-correction
  on the same rung; the entry below is superseded, not rewritten):**
  the controlled instrument **already existed** —
  `SaltWorks/Silicon/Importer/cell_coverage.py` (committed 08/12 at
  `2ddb6bd`, verified present at the bytes by the helm). It reports
  **SEVEN** cells missing across all 48 netlists, not 43:
  `a32oi_1 a311o_1 o32ai_1 o311a_1 o41a_1 a2111o_1 o2bb2a_1` — **FOUR
  are already modelled (`b8f6b1f`), so THREE remain.** ⇒ **the "39
  already-proved cells needing a table entry" were NEVER MISSING** —
  the importer's resolver takes them by drive-stripped fallback — so
  **the 39 EXPAND rows are not owed at all, which is 39 chances to
  encode a wrong entry that will now never be taken.** 🔑 Silicon's
  own words and the law worth keeping: **"I hand-rolled a census while
  the controlled one sat in the same directory."** ⇒ before building a
  census, LOOK FOR THE CONTROLLED INSTRUMENT IN THE LANE THAT OWNS THE
  QUESTION — the sibling law to census-by-content. **The rung's true
  remainder: three cell models.**
- **✅ THE CELL-MODEL RUNG IS CLOSED — `b8f6b1f`, MINUTES not days
  (13:2x; helm spot-verified at the bytes before relaying, per the
  relayed-discharge law):** the four genuinely-new models are PROVED —
  `a311o_liberty` · `a32oi_liberty` · `o311a_liberty` · `o32ai_liberty`,
  `saltbuild EXIT=0`, **[0 axioms]**, +39 lines in
  `SaltWorks/Silicon/Cells/Sky130.lean` (four theorem definitions
  confirmed present by count). ⭐ **`o32ai_1` is the cell whose absence
  made the importer REFUSE core32 this morning — route (A)'s blocker is
  gone.** Silicon's own measurement note: at 12:55 it said it did not
  know whether the rung was hours or a day and refused to swap one
  guess for another; the answer was MINUTES. ⇒ **the item the helm
  relayed to the Captain as "the largest mechanical cost on the aim"
  was, in sequence: 43 models (measured wrong instrument) → 4 models
  (corrected in the cheap direction) → PROVED (minutes).** The Sept-7
  proof aim's critical path now runs through the TEMPORAL machinery
  alone.
- **⭐ THE PROOF AIM'S CRITICAL PATH SHRANK — silicon correcting its
  own figure IN THE CHEAP DIRECTION (12:5x):** the "43 cell models /
  ~54% enlargement of EXPAND" that the helm relayed into the Sept-7
  plan is WRONG. **39 of the 43 already carry proved `_liberty`
  theorems in `Cells/Sky130.lean`; only FOUR are genuinely new**
  (`a311o_1 a32oi_1 o311a_1 o32ai_1`) — the 39 need a TABLE ENTRY,
  not a proof. Silicon's census measured `EXPAND` (the importer's
  WIRING table) and was reported as if it measured MODEL COVERAGE —
  the instrument/question mismatch again, third instance today.
  ⇒ **the 08-17→27 rung is NOT the largest mechanical cost on the
  aim**, and the plan re-prices accordingly at silicon's hand.
  🔑 A CORRECTION THAT MAKES THE WORK CHEAPER IS THE ONE NOBODY
  AUDITS — publishing it is the discipline, and silicon published it
  unprompted against its own earlier claim.
- **⛔ THE HELM'S OWN DERIVED NUMBER WAS TYPED, NOT READ — CORRECTED
  FORWARD (12:4x, found by the helm sweeping its own morning entries
  for the very defect they recorded):** the 11:4x entry below says
  "the budget of record is 12 tiles ≈ 226,807 µm² (same per-tile
  basis)" and "memplane8 = 29.3%". **Both are WRONG.** 226,807 was
  LINEAR SCALING of the 2×2 figure (75,602.5 ÷ 4 × 12) — a derivation
  I typed while the artifact of record carries the row itself:
  `docs/tinytapeout-dossier.md`'s tile table, **`6x2` = 1030.40 ×
  225.76 = 232,623.1 µm²** (TT dies grow in WIDTH only, +173.88 µm per
  tile column; the height is 225.76 at every 2-row size — which is why
  linear scaling of an AREA is wrong in principle, not just in
  arithmetic). ⇒ **CORRECT FIGURES: memplane8 66,371.2 = 28.5% · the
  composed top 112,962 = 48.6%.** ✅ **SILICON'S 48.6% WAS RIGHT AND
  WAS READ FROM THE TABLE** — only the helm's derived denominator was
  typed. The conclusion is UNCHANGED and slightly improved (more die
  than claimed). 🔑 The lesson is the sharper one: **the entry that
  corrected an eleven-day drift committed the same class of error in
  its own repair line** — a correction is not exempt from the law it
  restores.
- **⭐⭐ THE COUNCIL CLOSED (11:5x, the Captain: "pre-delegate with that
  condition, ratify the verso rulings, then close the board"):**
  **(1) THE OUTWARD CI PUSH IS PRE-DELEGATED TO THE MAESTRO**, his
  condition: push to `tt-neural-dataflow-fabric` when the revised
  offboard block has PASSED REFUTERS and the composed tests are GREEN.
  Execution mechanics ride with it (not new gates): the `info.yaml`
  source_files ↔ test/Makefile hand-sync per the manifest's own
  warning, and `validate.py` green before the push. The push triggers
  the public CI (layout + DRC/LVS); results return to his desk.
  **(2) THE FOUR VERSO RULINGS ARE CAPTAIN-RATIFIED** (the
  incident-grazing bands as derived constants · A.3.10 item 4 · the
  lossy T2-2 arm at 240 · the honest-absence recording with F-015
  open) — upgraded from helm-authority-appealable to ratified.
  **(3) AN AFTERNOON COUNCIL IS CALLED** — agenda: the IP-process
  invocation (his 8/13 action, DL window ~8/19-22) and the verso
  EXPERIMENT LOOP. A named sitting: Fable boots it by the staffing
  law.
- **⭐ ITEM 2 ROUTED TO MATH (11:4x, the Captain: "do it") — closing
  the morning desk's five.** The Ruling (c) gloss at this board's own
  line ~1480 ("X1's theorem class ranges over programs with
  `poolDemand ≤ 7`") goes to MATH for adjudication at the bytes:
  `poolDemand` has zero hits in `ExecutiveX1.lean` (positive control:
  `TinyRustN0.lean` defines and consumes it). Outcome is either a
  verified cross-reference (the gloss is a fair paraphrase through
  X1's actual binder) or an append-only forward correction of the
  descriptive sentence plus the property X1 does range over. His
  "sure N=2" is UNTOUCHED in both branches. Queued on the salt board
  (math's pull surface) as P1 item 4a; math consumes at wake with the
  E4a repairs and the fork-2 ruling.
- **⭐⭐⭐ THE CLAIM POSTURE RULED — AIM HIGH, REVISE HONESTLY, FIRST
  PRIORITY ABOVE EVERYTHING ELSE (11:4x, the Captain, his words: "first
  layout can be simulation, but we aim to finish the proof before Sept
  7, and will revise if needed. That's first priority above everything
  else." — and, verbatim, "Tell silicon to cheer up, it will be fine
  :)"):** the posture is NOT the low forecast silicon offered — it is
  an AIM: simulation is acceptable for FIRST layout, but the campaign
  target is the COMPLETE PROOF — including the temporal/protocol rungs
  — before 2026-09-07, with revision an honest, Captain-visible event
  if the aim breaks, never a silent downgrade. ⇒ **THE TEMPORAL PROOF
  MACHINERY THE FLEET LACKS IS NOW A COMMISSIONED BUILD**, silicon +
  compiler co-design (the which-cycle binding, the stall/arbitration
  contract, the bus-protocol FSM); the block's claim ladder becomes a
  PLAN-TO-PROVE with dated rungs, not a disclaimer. Fleet standing:
  this aim sits at the APEX of the top campaign — where it needs
  hands, it wins ties across lanes. Write-time hygiene unchanged: at
  every moment the public claim says exactly what IS proven.
- **⭐⭐⭐ THE PIN FORK DISSOLVES AT THE CAPTAIN'S OWN ARCHITECTURE —
  OPTION (d) RULED (11:4x, his words: "The pins we have in the current
  chip are: 8 address pins, 8 data pins, 2 fabrics pins (I/O), and
  control pins, does that still fit? adress and data re 32 bits, but we
  have to multiplex them, it is slow, but fine"):** verified at the
  manifest's FROZEN D6 map — `uo[7:0]` = addr_byte (PC bytes, 4
  phases), `ui[7:0]` = instr_byte (the CPU memory bus), `uio` = the
  fabric's 2 data pins + control; his model matches pin-for-pin, and
  the fabric port list carries a STUBBED CPU-client port and a spare.
  ⇒ **The offboard interface needs NO new pins: it EXTENDS THE FROZEN
  BUS'S PROTOCOL** — transaction types (fetch/load/store), address
  phases on `uo` as today, read data in on `ui`, store data multiplexed
  out on `uo` after the address phases. Pin ASSIGNMENTS untouched; only
  D6's semantic text amends. Silicon's (a)/(b)/(c) fork is CLOSED
  UNPICKED. The design consequence lands in the stall contract: FETCH
  vs DATA ARBITRATION on the shared bus — slow, and at his word, fine.
  The claim-ladder sentence remains the one open ratification.
- **⭐⭐ ITEMS 3 + 4 RULED AND EXECUTED (11:3x, the Captain):**
  **(3) THE ARCHIVE POLICY, his word with his reasoning: "always push
  the archive but never rewrite history on the archive."** The archive
  is the never-rewritten private superset: the PUBLIC record may be
  expunged on a mistake; the archive keeps everything and is never
  published. Helm refinements accepted into the policy record: a
  divergent public rewrite lands in the archive as a NEW ref, never a
  force-move; and one carve-out — material violating the LANE FIREWALL
  is expunged everywhere, the firewall beats the archive. Executed at
  once under the standing policy: saltworks-archive/master
  fast-forwarded `2ffab294 → 2b9dd57`, the one-commit gap closed.
  **(4) THE PUBLIC FRONT DOOR: README LINES, his word.** A
  historical-id forwarding note added to the saltworks README pointing
  at `docs/ledger-tools/flip-sha-map-0816.tsv`, plus the Silicon-lane
  entry-point line (the lane has no front document; the README line
  carries the door — no front document created, none ruled).
- **⭐⭐⭐ ITEM 1 CLOSED WHOLE — AND OFFBOARD DATA IS RULED IN-WINDOW
  (11:3x, the Captain at the council, his words: "We should do offboard
  data this window. I think it is unlikely I'll do a second run in the
  near future, so we should have it this time as a 'complete' product.
  I know silicon will have to scramble for it. With that we can close
  item 1"):** the closure — (A) submission top = the COMPOSED design
  (BB fabric + 4 neurons + CPU + load/store + mem), measured 112,962
  µm² = 48.6% of the 6×2 (`b1463de`, two self-caught flow defects on
  the way, both controlled); (B) DISSOLVED at the artifact of record
  (the 6×2 is held); (C) the outward push to
  `tt-neural-dataflow-fabric` remains HIS or explicitly delegated.
  **(D) NEW SCOPE AT HIS WORD: the OFFBOARD DATA INTERFACE ships in
  THIS window** — the complete-product ruling; the scramble is
  KNOWINGLY ACCEPTED and recorded so the pace is read as ordered, not
  drifted. Execution law unchanged: **DESIGN-BLOCK-FIRST** — silicon
  authors the offboard block covering (i) the address-map split in
  `dmem_addr8` (trap-on-out-of-range becomes route-or-trap), (ii) the
  serialized data interface over the TT `uio` pins, (iii) the core32
  stall/fixed-latency contract — a change to the verified core, not a
  wrapper, and (iv) **the CLAIM LADDER: what is PROVEN at tape-out vs
  what lands after — statement-tier lines go to the Captain at the
  block's freeze.** Refuter pass gates the wave. Cross-lane: the
  kernel-side model change (multi-cycle memory) touches compiler's
  bridge — coordinate, never assume. 21 days to 2026-09-07. The
  discharge wave and the offboard campaign now share the ③ lane:
  silicon sequences its own pen, the helm arbitrates collisions at
  seams.
- **⭐⭐⭐ THE TILE PREMISE WAS STALE — CORRECTED AT THE ARTIFACT OF RECORD,
  AND THE PURCHASE QUESTION DISSOLVES (11:2x, the Captain at the council:
  "we have drifted, because we already purchased the 6x2, that's
  https://github.com/jyh/tt-neural-dataflow-fabric"):** verified at the
  manifest — `info.yaml` line 53 reads `tiles: "6x2"`, top
  `tt_um_saltworks_ndf`. Every percentage in the 08:57–09:55 arc was
  computed against "the 2×2 die already bought (75,602.5 µm²)" — a stale
  dossier figure; the budget of record is 12 tiles ≈ 226,807 µm² (same
  per-tile basis). **memplane8 = 29.3% of the real die. No purchase, no
  shrink needed for fit** (RV32E stays registered post-window on its own
  merits; the helm's "the held 2×2 is definitively out" inherited the
  same stale premise and is corrected with it). **SUB-DECISION A RULED
  (his word): the submission top is the COMPOSED design — BB fabric + 4
  neurons + CPU + load/store + mem.** LW/SW answered at the bytes:
  ONBOARD ONLY (dmem8, 8 words, out-of-range suppresses-and-flags; no
  offboard data interface exists; program fetch is external ports). The
  OFFBOARD data interface is REGISTERED as a post-window campaign. The
  08:57–09:55 entries are NOT rewritten — their measurements stand,
  their denominators do not. ⚠️ The lesson for the digest: a MONEY fact
  synced from a dossier instead of the artifact of record drifted for
  eleven days while the truth sat in a public file.
- **⭐ ③ SEQUENCING RULED + A PHRASE CORRECTED FORWARD (08:5x helm
  entry, on silicon's own record-policing at 08:54):** the entry below
  says the plane "discharges DriveMap BY CONSTRUCTION" — CORRECTED:
  the plane makes `DriveMap` **TRUE IN RTL** by construction
  (`fc5ed0e` + `a76b647`, round trip closed, x3=42); **NOTHING YET
  TIES THE RTL PLANE TO THE LEAN STRUCTURE — `DmemKernelBridge` still
  takes `DriveMap` as a HYPOTHESIS, and no row may say ③ discharged
  it.** Silicon sized the closing import at ~18k lines (ORDER-of, not
  banked — its own caveat) and asked the helm for scope. RULED (helm,
  sequencing inside the Captain's ruled scope): **the discharge STAYS
  IN ③** (his morning ruling put it there); **the hardware deliverable
  runs FIRST** (layout + DRC/LVS toward the 09-07 window — the
  discharge is kernel-side and blocks nothing physical); **the
  Lean-side discharge is its own wave, DESIGN-BLOCK-FIRST** — the
  architecture choice (monolithic import / chunked / ports-only /
  sub-cone) has "a different lie available to each option" (silicon's
  words) and that is precisely what a refuter-passed block exists to
  pick. The Captain reviews at the 9am bell; his word re-cuts any of
  it.
- **⭐⭐ ③ SEAM LANDED, AND A NUMBER CORRECTED FORWARD (08:2x helm
  entry):** **`fc5ed0e` — (a)+(b) both in.** The plane's strobes are
  `isLW`/`isSW` bit-for-bit, so **`DriveMap` discharges BY
  CONSTRUCTION**; the ruling's in-wave check EARNED ITS PLACE (silicon's
  own words: gating only the memory strobes leaves an excluded LOAD
  still writing the regfile — "inert at the port is not inert";
  `reg_we`/`wb_val` now use `is_load_w`; `alu_src` left opcode-only
  DELIBERATELY — an excluded load computes an address no strobe
  accompanies, narrowing it buys nothing). Memory-inert verified by a
  14-arm test, every negative paired with a positive, AND SHOWN TO FAIL
  on the pre-ruling RTL (SB FAIL · LB FAIL · SW pass · LW pass);
  non-compiling arms NOT counted as controls — a compile error is not a
  test failure. F4 chain vs the new RTL: `saltbuild EXIT=0`, 8595 jobs.
  ⛔ **CORRECTION to the ruling entry below, urgent because the ruling
  put the number on the record: "−620 cells / −2.0% area" MEASURED (a)
  ALONE.** The landed (a)+(b) record is **−586 cells / −889.6 µm²
  (−1.54%)**, and the gate's cost stands on its own line per silicon's
  ask: **+34 cells / +254 µm² is the price of making F4's certificate
  true of the built part.** Same harness, same pinned PDK, baseline
  still reproducing the committed figure to the digit. The ruling entry
  below is NOT rewritten. 📌 Routed to compiler on the bus: `914f85c`'s
  theorem TITLE premise ("the only wiring the RTL can supply") goes
  stale at `fc5ed0e` — the theorem stays TRUE of the old wiring; the
  anchor is compiler's to refresh, PRE-AUTH, no urgency.
- **⭐⭐ THE ③ SEAM RULING (08:0x, the Captain at the council, his word:
  "yes take recommendation a+b"):** silicon's `5d161ce` finding ruled —
  **(b) GATE THE STROBES ON FUNCT3** (makes `DriveMap` true of the built
  part and F4's certificate live) **AND (a) NARROW THE RTL TO WORD-ONLY**
  (remove the memif copy inlined at `core32.v:84-93` — the 8/12 word-only
  ruling's intent, now executed at the bytes; measured −620 cells /
  −2.0% area with a to-the-digit baseline control). CLAIM LANGUAGE
  BINDING: excluded encodings become **MEMORY-INERT — never "refused"**
  (refusal would be the trap design, declined). One check rides INSIDE
  the wave, not as a fifth option: the LOAD-WRITEBACK path must be gated
  by the same funct3-gated strobe, or excluded loads still touch the
  register file. Re-verification owed at landing: synthesis re-run on
  the measured-control harness · the F4 chain against the NEW RTL
  (`DriveMap` becomes dischargeable at ③'s plane) · DRC/LVS at the
  update window. Options (c) trap and (d) document-only DECLINED at the
  same word.
- **⭐⭐⭐ 08/17 MORNING, TWO EVENTS ON THE COUNCIL FLOOR (08:0x helm entry;
  both verified at the bytes before writing):**
  **(1) D1a IS DISCHARGED — `cf7e6fd`, order-to-landing FIVE MINUTES on the
  narrow channel.** BUILD ROW in the caveat's demanded form: `saltbuild
  EXIT=0` · `✔ [4/4] Built SaltWorks.Silicon.Imported.Dmem8 (4.7s)` —
  BUILT, not `Replayed`, with the discriminator in the SAME output
  (BitSliced on that run reports `Replayed`). Datum: 673 cells → 1984
  gates · 256 dfrtp flops cut under `--pin-reset`, namespaced
  `Restricted_rst_n_eq_1` (says NOTHING about the deassertion seam, never
  cite it as covering reset/bring-up); readback vs vendor Liberty 32×288
  agrees; reimport 6/6 byte-for-byte including the five pre-change rows;
  1984/256 REPRODUCES the figure banked at `1f9d2c0` from an independent
  regeneration. THE BAR MET IS THE AMENDED BAR (never "C3 passed"). Helm
  spot-check: commit on master, `Imported/Dmem8.lean` present, bus receipt
  sha matches. The importer REFUSED its author's first invocation
  (`rst_n` in `--inputs`) — the gate enforced the restriction against the
  hand that built it. ⇒ **P1 = ③ ALONE.**
  **(2) THE CAPTAIN RATIFIED THE FLEET'S FIRST CAMPAIGN PRECEDENCE (his
  words at the council: "I think I'd put saltworks first, inverting 1 and
  2, ratified with that change. The reason is that I don't want a crunch
  time, let's get the final silicon taped-out, so we can rest eays on that
  campaign."):** **1. saltworks — ③ to tape-out (the NO-CRUNCH doctrine;
  the 2026-09-07 window governs) · 2. twin primes (wins ties for the
  Captain's attention and the Fable budget) · 3. verso (wins the nights;
  helm rulings batch at the bells, HALT excepted) · 4. jas (its ~Aug-19
  pilot slot, timeboxed) · 5. ventris (gated on verso's referee maturing) ·
  6. lineage/SaltBench (dry time only).** Above all of it when they fire:
  the DL window (~8/19–22) and the IP-process invocation — the Captain's
  personal calendar, costing him and not the fleet. Precedence resolves
  COLLISIONS (attention · helm cycles · seat-time); it does not idle the
  lower campaigns.
- **⭐⭐⭐ THE 08/17 COUNCIL RULING — P1 SHRINKS TO D1a + ③, AND ③'s SCOPE
  GROWS BY F4's HYPOTHESIS-DISCHARGE (07:5x, the Captain at the named
  council, his words: "yes to all four, wake silicon"):**
  **(a) P1 = D1a + ③ RATIFIED.** Of the 08/16 re-tier's P1 roster, three
  items discharged at named bytes (F4 door 1 `6010c38` · input-side
  naming hole `95e7130` · sw_* docstrings `110b649`) and D2's
  silicon-half is REFUTED as unfounded (the entry below); the remainder
  is D1a + ③.
  **(b) ③'s ROW NOW NAMES WHAT IT CARRIES: F4's `DriveMap`
  hypothesis-discharge.** Compiler's finding, helm-verified at the bytes
  with a positive control: nothing instantiates `dmem_addr8` anywhere in
  RTL or Flow; `dmem_wdata[31:0] ← req` and `dmem_be[3:0] ← we_in` have
  NO SOURCE — the plane DriveMap describes has no realization until ③'s
  integration builds it. Anyone pricing ③ without this, or commissioning
  a "just discharge DriveMap" wave first, prices the wrong object. The
  2026-09-07 update window governs.
  **(c) NO RE-TIER.** Standing mechanics serve: P2 pulls at P1-idle
  (compiler may pull V9 today); no rows move.
  **(d) SILICON WOKEN on the narrow channel** (`SILICON ORDER:`,
  receipt-proven 07:30:13) to resume D1a at its own pace; its blindness
  for the (C) adjudication stays reserved — the bus stays off. D1a's
  permanent caveats restated: the bar met is the AMENDED bar, never
  "C3 passed"; a BUILD ROW is owed at landing (an emitted `Dmem8.lean`
  ELABORATES). The 08/16 entries below are NOT rewritten.
- **⭐ D2's SILICON-HALF — THE ROW'S CITED BASIS IS REFUTED BY ITS OWN EVIDENCE
  (20:2x, the helm, on silicon's derivation; re-derived at the bytes before
  landing). Bookkeeping only; no tier moves.** The 8/14 sweep records "D2's
  silicon-half re-hardening (**inferred from `fb3842a`'s file list** — seat
  confirmation owed)". That file list contains **ZERO silicon-lane files**:
  `SaltWorks/HDL/` × 6 (AccountMeasure · C1Organ · CoreOffsets · CorePlace ·
  Decoder · ISA), `SaltWorks/Stack/Program.lean`, and `docs/SEATS.md` — nothing
  under `SaltWorks/Silicon/` at all. ⇒ **The inference cannot stand on the
  evidence it names.** Earlier tonight this row was offered to the helm as
  DISCHARGED and was declined for failing re-derivation; silicon's own answer to
  the confirmation it owed is that **the obligation was never established**, and
  the row is therefore not "unconfirmed" but **WRONGLY ATTRIBUTED**.
  ⚠️ **THE DISTINCTION THIS ENTRY IS CAREFUL ABOUT, because tonight taught it
  twice: refuting a JUSTIFICATION is not refuting the OBLIGATION.** What is
  settled is that **no silicon-side D2 duty follows from `fb3842a`'s file list**.
  If anyone holds that such a duty exists on OTHER grounds, those grounds must be
  STATED — a row does not get to persist on a refuted inference while its real
  basis stays unnamed. Silicon, the lane owner, states it owes nothing here.
  📌 **Sha note:** `fb3842a` is PRE-FLIP and resolves nowhere on this origin; its
  post-flip address is `65875c5` ("D2 — the memory control plane LANDS, atomic
  across the slot", 08/12 17:49:53), forwarded via `docs/ledger-tools/flip-sha-map-0816.tsv`.
  **This correction could not have been checked at all without that map** — the
  citation it audits was already dead when it was quoted back to the helm.
  ⛔ **THE 8/14 ENTRY IS NOT REWRITTEN.** Corrected forward, per this board's own
  convention.
- **⭐⭐ THE 08/16 EVENING BOARD CORRECTION (19:2x, the helm — BOOKKEEPING
  ONLY. No tier moves, no priority changes, no words of the Captain's
  touched. Every sha below is POST-FLIP and resolves on this origin;
  every claim was re-derived at the bytes this evening, and the two
  claims that did NOT survive re-derivation are named as such at the
  end rather than carried.):**
  · **⭐ D1a's dfrtp GATE IS OPEN, AND HAS BEEN SINCE 08/13 — the 8/14
    sweep entry below records it SHUT, and that citation inverts the
    criterion.** The sweep cites `silicon-dfrtp-async-reset-prereg-0812
    .RESULTS.md` at its 08/12 header verdict ("THE BAR IS NOT MET. NO
    DATUM LANDS.") — a dated snapshot the SAME FILE supersedes ~190
    lines below, in the block beginning "SUPERSEDED 2026-08-13": *"A2′
    **DISCHARGES** … **A2 is the row that is now non-discharging** … a
    reader who quotes this sentence today would invert the criterion."*
    A2′ promoted `129edab`, rev-2 `5eedb3c`, rev-3 `ca19dec`,
    supersession note `1683e33`. At the bytes,
    `SaltWorks/Silicon/Importer/pinreset_controls.sh` marks the `C3.A2′`
    block "DISCHARGING" and sets `fail` there, while marking `C3.A2`
    "INFORMATIONAL … it does not touch `fail`". ⇒ **D1a IS
    UNBLOCKED-AND-UNSTARTED, NOT BLOCKED:** `SaltWorks/Silicon/Imported/`
    holds eight datums and no `Dmem8.lean`, the index carries none
    (positive control: the same search lists the eight that exist), and
    `reimport.sh` carries five regenerable rows with dmem8 in none.
    **Nothing external holds it.** D1a is SILICON'S; this entry states
    the board, it does not dispatch the work.
  · ⚠️ **THE BAR THAT WAS MET IS THE AMENDED BAR — this must never be
    summarized as "C3 passed."** C3 as frozen was unsatisfiable at
    authorship, before any result existed: §3 mandates a visible scope
    marker in the emitted datum, §4 demands byte-identity with a
    comparison arm that cannot carry that marker (the importer refuses
    the flag as a no-op by design). The amendment was made by the
    AUTHORITY THAT RULED THE CRITERION, not by the hand that saw the
    result — the seat explicitly refused to self-amend ("a criterion
    rewritten by the hand that saw its result is worth nothing") — and
    A2′ is STRONGER than what it replaced: it asserts the whole diff
    positively instead of tolerating it.
  · ⚠️ **A BUILD ROW IS OWED AT LANDING.** Nothing here shows an emitted
    `Dmem8.lean` ELABORATES. This same RESULTS file records a datum that
    passed every grep-level criterion and still failed to elaborate. The
    gate being open is not the datum being good.
  · **INPUT-SIDE NAMING HOLE — CLOSED 08/15 07:01:40 at `95e7130`**
    ("Silicon: SHAPE A landed — `_in_names` on all five regenerable
    datums, emitted UNCONDITIONALLY"). The sweep below still lists it
    open as a NEW unowned finding.
  · **sw_* DOCSTRING FRAME-CLAIM GAP — CLOSED 08/16 18:11:20 at
    `110b649`** ("the open question is CLOSED").
  · **F4 BRIDGE — DOOR 1 LANDED 08/16 18:30:54 at `6010c38`** (compiler,
    on silicon's lemmas, cross-verified both ends). ⇒ **D3's remaining
    prerequisite is D1a.**
  · ⛔ **TWO CLAIMS I DECLINED TO LAND, having failed to re-derive them:**
    (1) that D2's silicon-half confirmation is discharged — the bus still
    reads "SEAT CONFIRMATION OWED" and I found no acceptance, so **that
    row stays open**; (2) a proposed erratum asserting every citation
    into this board at line ≥306 is off by one — the decisive sample
    refutes it, this board's "behind the SHUT dfrtp gate" sits at the
    exact line the 08/16 census cites. **Neither is recorded as fixed.**
  · 📌 **SHA ROT — a standing hazard, not a defect of any seat.** The
    supersession banner in the RESULTS file, and the 08-14 night bank,
    cite `7958286` / `98fd83c` / `cc32a96` / `520f9d6`, which are
    PRE-FLIP and resolve NOWHERE on the public origin. Their post-flip
    equivalents are `129edab` / `5eedb3c` / `ca19dec` / `1683e33`
    (subject-matched, each confirmed an ancestor of master). Those files
    are dated records and are NOT rewritten; the mapping lives here.
  ⚖️ **RESERVED TO THE CAPTAIN, NOT RULED HERE:** whether P1 now shrinks,
  and whether any freed capacity re-tiers, is his at the morning desk.
  This entry moves nothing.
  ⛔ **THE 8/14 SWEEP ENTRY BELOW IS NOT REWRITTEN** — it was true when
  written. Corrected forward, per this board's own convention.
- **⭐⭐⭐ THE 08/16 RE-TIER (12:2x, the Captain at the desk sitting, his
  words: "we want to finish these P1s. Next, I would recommend we move
  LW/SW in silicon to P1, then all P3s (incl GNN compiler) move to P2."):**
  **P1 = FINISH-FIRST**: the standing P1 remainder (the 8/14 sweep's five
  open items below — F4 bridge · input-side naming hole · D1a dfrtp ·
  D2 silicon-half confirmation · sw_* docstring gap — plus any census
  finds) **AND the LW/SW SILICON INTEGRATION (stage ③: dmem8+memif+layout,
  update-window 2026-09-07) PROMOTED from P2 to P1.**
  **P2 = the former P3 rosters unchanged in content and order** (compiler
  V9 → A1 → L5 → batcher_c/SER → L6 · math L3-half → X3 → 47-row → A3 ·
  silicon cocotb → 1x2/BB → DRV → tile-fit → sim harness · evidence
  GraphCast citation) **PLUS the GNN COMPILER — a NEW campaign, joining P2,
  design-block-first per the standing law (no seat consumes it before its
  refuter-passed block exists).** **P3: empty.** Same mechanics as always
  (clean-boundary switching · a lower tier never gates a higher · one pen
  per seat), strict P1 > P2. A rung-by-rung P1 census fired at the ruling
  (nine readers; brief lands at ${SEAT_DIR}/briefs/p1-census-0816.md).
- **⭐⭐ P2 RECONCILED — THE REGISTER WAS THREE DAYS STALE AND THE
  STALENESS MANUFACTURED A DEBT (8/14 17:5x, the evening helm, Fable
  hand): tonight three seats reconstructed "① maestro-owed TONIGHT"
  from the amendment entry below — whose HEADER commit ce8857e
  destroyed when it inserted the PAYMENT entry beneath this one. Of
  record: ① PAID 8/10 (memory-design-v1.md, now at v1.6); ② EXECUTED
  — M0 discharged (da168dc) · M1+M1a landed atomic (1a92292, 8/10
  19:26) · M2 Instr-atomic landed (acd3982, 8/11 18:03; the wS/wI
  encoder plan EXECUTED: wI generalized to (opcode,funct3), wS built,
  six field lemmas + reassembly + the Spike-word and swapped-imm
  controls) · M4 frame rows at Stack/Program.lean:1766-1775; ③ has
  its OWN block (stage3-memory-design-0811.md, three doors, update
  window 2026-09-07) and silicon has been executing its edge
  (cfeb1cc 8/13: DmemAddr8Suppress — the we_out response half at the
  emitted gates, total, plus the no-manufactured-strobe theorem).
  THE ③ SCOPE LINE BELOW IS STALE ON memif — corrected out 8/12
  (silicon-pre-D2-area-baseline-0812.md:56-58; the word-only ruling
  forecloses it). THE ARC'S TRUE OPEN ITEMS, from tonight's
  four-reader sweep (recorded landings cited by sha, not re-built
  tonight): the F4 BRIDGE THEOREM — the two halves live in DISJOINT
  import cones (DmemAddr8Suppress imports only the datum; no
  ISA/kernel name reachable), door 1's exit criterion, UNBUILT;
  kernel-side seam partially discharged at HDL/Decoder.lean:355-374
  · the INPUT-SIDE NAMING HOLE — the ins↔byte_addr binding lives
  only in reimport.sh's argument order (:101-103), the importer
  emits no input name table (import_netlist.py:1002,:1067) — the
  same defect class the output name table was built to close; NEW
  finding, unowned · D1a's Lean datum behind the SHUT dfrtp gate
  (silicon's prereg verdict, silicon-dfrtp-async-reset-prereg-0812
  .RESULTS.md:8-13) · D2's silicon-half re-hardening (inferred from
  fb3842a's file list — seat confirmation owed) · the sw_* docstring
  frame-claim gap (Certs/MemTrapResponse.lean:28-33, carried open by
  silicon). The destroyed header below is RESTORED in this same
  edit.**
- **⭐ P2 ① IS PAID — THE GATE IS OPEN (8/10 18:2x, the night
  maestro, Fable hand, ritual on record): docs/memory-design-v1.md
  is at v1.1 — the five-refuter pass (5/5 REPAIR-THEN-FIRE, 0 FATAL;
  verdicts at ${SEAT_DIR}/briefs/2026-08-10-memory-block-refuter-verdicts
  .json) FOLDED per the evening bank's majors (a)-(e): the St
  extension's codec/executive breakage scoped as M1a (decQ_encD
  restated as the (regs,pc) projection), the task-0-scratch claim
  STRUCK (option (a): v1 memory is standalone-only, executive LW/SW
  is the X4+ door), the slice_a_excluded fixup folded into M2's
  commit, addrClass precisions folded (named lemma addrClass_ok_lt;
  aligned-out-of-range witness; else-.ok slogan retired), M4
  restated + mutant discipline fixed, dmem_addr8 ruled for stage ③,
  M0 feasibility probe gates M1. P2 ② MAY PULL: M0 first (any
  P1-idle seat), then M1+M1a atomic, per the stealing discipline.**
- **⭐⭐⭐ THE THREE-TIER AMENDMENT (8/10 17:0x, the Captain at council,
  his words: "for PoC no memory is fine, but it is very unrealistic, you
  can do a design today. P1 stays as it stands, LW/SW move into P2, and
  the others become P3"): the two-track ruling below is AMENDED to three
  tiers, same mechanics (clean-boundary switching · a lower tier NEVER
  gates a higher · one pen per seat), strict priority P1 > P2 > P3.**
  **P1: UNCHANGED** (the bundle + math's day-zero opener, below).
  **P2 = THE LW/SW ARC, internally gated, in order:** ① the MEMORY
  DESIGN BLOCK — maestro-owed, Fable-tier, TONIGHT (the byte-vs-word
  ruling · misalignment in the address path · F4's bridging obligation
  written before either side builds · B2's coverage discipline · the
  wS/wI encoder plan; refuter pass BEFORE any seat consumes it) ·
  ② the KERNEL LANDING (math+compiler shared, ~3 seat-days, gated on ①)
  · ③ SILICON INTEGRATION (dmem8+memif+layout, gated on ②,
  update-window scoped). No P2 pull exists until ① posts.
  **RULING (c) — PARTITION COUNT, SAME SITTING (17:0x, the Captain,
  verbatim "sure N=2"): N = 2 — two task partitions of ~7 registers
  beside the executive's own slice (task 0). X1's theorem class ranges
  over programs with `poolDemand ≤ 7`; both corpus witnesses fit; the
  E-4 overlap witness and its positive control construct as
  pre-registered. L6's N=1 incompatibility stands recorded.**
  **RULING (b) — RECORDED AS SUBSUMED (17:1x, register hygiene): the
  Captain's P1 ratification fired X0→X2 at math as SPEC-LEVEL rows,
  which IS the ruling-#3 lift the pack's ask (b) requested; math was on
  X0 within the minute. Council ruling #3's "B-EXEC follows B-ISA"
  continues to govern the COMPILED executive (X4+).**
  **RULING (d) — SAME SITTING (17:1x, the Captain, verbatim "Yes (B)"):
  RULING #8 IS RE-OPENED AND RESOLVED TO BRANCH (B) — the REQUANTIZER
  ORGAN lands: shift + saturate, ~40 gates, in the SER's sAct row, with
  its V9-class kernel model priced beside it. h ∈ [0,127] becomes a
  THEOREM; the per-network weight-side duty RETIRES; the trainer is
  freed. Ruled TOGETHER, as the refuters required: the adjoint
  convention is STRAIGHT-THROUGH 2^-s with the floor's zero-derivative
  region NAMED (the nonzero-gradient anti-vacuity control stands, else
  the adjoint theorem is satisfiable by zero). A2/A3 (P3) take this
  form; silicon's P3 roster gains the requantizer beside the SER
  shift-enable (one SER row, two organs, priced together);
  update-window silicon.**
  **RULING (f) — THE SALT PILLAR, SAME SITTING (17:2x, the Captain,
  verbatim "f-i: yes, f-ii: yes, I'll keep pursuing arXiv, no action
  needed, the clearance body responded quickly, give them more time on SaltBench"):
  (f-i) THE Pi WRITING TASK FIRES — math owns the flagship draft
  (papers/flagship/main.tex, a week cold) on its named salt days (~2,
  interleaved at its X-ladder's natural pauses); maestro reviews at
  Fable tier; THE SUBMISSION CLICK IS PUBLIC/T1, THE CAPTAIN'S ALONE.
  (f-ii) THE MAESTRO'S FABLE SEQUENCE STANDS RULED: memory design block
  TONIGHT (gates P2) · the next-rung four-agent RE-RECON fired tonight
  (agent-work, reads tomorrow) · the N7 GATE BLOCK tomorrow morning on
  the fresh recon — the flagship proving front reopens behind it.
  arXiv endorsement: HIS lane, no fleet action. clearance/SaltBench: give
  them more time — no nudge.**
  **P3 = the former P2 rosters, unchanged in content and order:**
  compiler V9 → A1 → L5 → batcher_c/SER → L6 source probe · math L3
  half → X3 → 47-row → A3 (still gated on ruling d) · silicon cocotb
  fix → 1x2/BB → DRV → tile-fit → sim harness · evidence GraphCast
  citation. NOTE: V9's demotion to P3 is the amendment's one real
  trade (it was A1's fence) — priced at the table, the Captain's word
  stands; A1 ships fenced WHEN DRIVEN until V9 lands from P3.
  Captain at council, his words: "I am willing to bet my shirt that they
  aim too low. However, I honor the refuters too… One main track
  first priority, essential, label it P1. Secondary track for longer
  shots… *if* a seat falls idle on the main track, it picks up a task on
  the secondary track. Strict scheduling, P1 comes before P2, no
  preemption." Ratified with the maestro's recommendations: "queue it
  up, with your recommendations :)").**
  **P1 (essential, the refuter bundle + the day-zero opener):**
  MATH day 0: the abstract-fold↔cSorted seam (ONE obligation, its own
  15:44 measurement) — closes the Captain's "easy and completes the
  story" pair BEFORE the campaign draws breath · then X0 → X1 → X2
  (per block ② §A: shared-regfile SysSt, bound step_frame, concrete E-4
  witness, execution-witness E-5, non-halting fairness antecedent).
  COMPILER: L0 → L1 → L2 → L4 (per block ① §A: emit_runs-shaped Row A,
  handoff exit conjunct per the 15:44 clarification, finite-domain reg
  map, range frame). SILICON: A0 (the 2-2-1 V10 fixtures).
  **P2 (longer shots, pulled ONLY at P1 idle, per seat, in order):**
  compiler: V9 (highest leverage — A1's fence AND its own debt) → A1 →
  L5 (post-L2) → batcher_c composition + SER shift-enable (shared w/
  silicon) → L6 source-side probe (no proofs). math: L3 math half
  (inlining preservation, file-disjoint) → X3 mailbox → the 47-row audit
  (decision then mechanical) → A3 adjoint semantics (gated on ruling d).
  silicon: cocotb bench fix test.py:247 (unowned→OWNED here) → 1x2/BB
  re-signoff → DRV two-population hypotheses → batcher-wired tile-fit →
  gate-level sim harness for A2. evidence: GraphCast paper citation +
  not-carried list (public-paper-only).
  **THE THREE MECHANICS (law of the two tracks):** ① clean-boundary
  switching — P2 parks AT THE NEXT COMMIT when P1 readies; banked,
  never abandoned; P2 items must be parkable. ② P2 NEVER GATES P1 —
  refutation asks on P2 landings queue as P2; no P1 rung may wait on a
  P2 obligation. ③ one pen per seat still binds — P2 prefers files
  disjoint from that seat's P1 range.
  **RECORDED WITH THE RULING (the bundle's premise, stated at the
  table, veto-in-the-moment if unintended): W5-asm and the B-ISA
  per-op waves are DEFERRED for the sprint window.** Pending rulings
  that now gate SPECIFIC rungs rather than cuts: (c) partition N →
  X1 · (d) ruling-#8 fork → A2/A3's form · (g) Row A amended shape →
  L2/L4 (compiler's reading confirmed; the form stands as clarified
  at ff43d08 unless the Captain objects at its rung).**
- **⭐⭐ THE AIM-HIGH TRIO: DRAFTED → REFUTED → AMENDED → COMMITTED (8/10
  11:4x-12:10, the successor maestro, Fable hand): the three scoping
  blocks docs/aim-high-{language,executive,application}-v1.md at
  `1988c36`, five-refuter adversarial pass complete (5/5
  REPAIR-THEN-FIRE; FOUR fatals repaired in the §A v1.1 banners at
  `d989028`: the Vector-St-N isolation vacuity → shared-regfile SysSt;
  A4's identically-zero multi-round gradient → single-round rescope with
  seed bound; both seat tallies bust nine days → the largest-honest-bundle
  recommendation), verdicts persisted whole
  (${SEAT_DIR}/briefs/2026-08-10-aim-high-trio-refuter-verdicts.txt).
  COUNCIL PACK: docs/council-pack-0810.md carries the bundle
  (① L0→L4 compiler · ② X0→X2 + named salt days at math · ③ A0 only)
  and the seven-item ask-list that is HIS alone (W5-asm/B-ISA deferral ·
  ruling-#3 lift · partition N rec 2 · RULING #8 re-open A/B · L6's
  fate · salt-pillar days · the emit_runs-shaped Row A). NEW T1 INPUT
  folded: GraphCast as the GNN-compiler demo (his 11:4x hand; fence
  extended — never "forecasts weather"; the clearance route for public naming).**
- **THE SUCCESSOR'S RELIGHT + FIRST SEAL (8/10 11:31-11:38, register
  line): boot per the midday bank; BatcherRun + PortLengths ROOTED at
  `02155be` (the closure ritual's own find — PortLengths tracked-unrooted
  since 8/8's "import owed", its hub-cycle import rewritten; 8681-green,
  EXIT=0 read from the line); disk-vs-graph closure now returns only
  Scratch*. TT CI FULLY GREEN on the live commit: the benign viewer
  failure decoded one level deeper (duplicate github-pages artifacts from
  the rerun; both deleted, attempt-3 SUCCESS) — the Captain's three
  clicks gate only on his hand now.**
- **SORT-THEN-ROUTE SHAPE RULED (8/10 10:5x, the Captain, verbatim
  "Yes (b) exactly"): THE BIT-SERIAL BATCHER — his own 1990 shape
  (ISS90 p.78 §3.1: first-difference latching, "16 bit-times" =
  sorted IN TIME). THE PATH: emitSeq(batcherNetC) + shell (the L1
  play rehearsed on the cell) — the certified frame-streaming
  sorter (the bnC theorem family's own object, 96 state bits)
  gains its flops from last night's emitter; the domain crossing
  dissolves into a FRAME-ALIGNMENT CONSTANT (the sorter's fixed
  latency vs the banyan's sof) — a timetable number. FIRED:
  compiler emits + pre-registers counts (per V7's which-not-how-
  many form); silicon shells/composes/measures the 1x2 projection
  AT the composed object (its own struck-twice rule honored);
  math refutes the alignment arithmetic. The update window is the
  deadline; today's submission unaffected.SHARPENED 11:0x AT THE
  CAPTAIN'S OBJECTION ("I don't even see how a combinational
  Batcher would work because the packet is arbitrarily long"):
  option (a) was never merely expensive — it is INCOHERENT at the
  architecture level, a bounded-frame special case; with ∀-P
  payloads (and 1990's 424-bit ATM cells behind 8-bit headers) the
  sort decision MUST be made on the bounded header prefix while
  the unbounded payload streams — first-difference-then-hold. The
  certified object already embodies this: bnC_payload_delivered
  holds for ARBITRARY-length payloads precisely because the
  element decides on the header and goes transparent (B4's own
  bonus finding: the sorter leg is already ∀-P). (b) is not a
  preference; it is the only shape the architecture admits.**
- **⭐⭐⭐ THE NDF IS SUBMITTED — THE HARDWARE SUMMIT (8/10 17:5x, the
  Captain, HIS HAND): "NDF is on the Sept 7 shuttle, additional 8
  tiles paid for." TWO of the three clicks EXECUTED in one stroke —
  (1) SUBMIT NDF ✓ (Sept-7 shuttle) · (2) UPGRADE 2x2→6x2 ✓ (the +8
  tiles = 4→12, the ruled resize). THE THIRD CLICK (buy the 1x2) IS
  MOOT — the switch went P3/nostalgia and the 1x2 banyan was
  discarded. ⇒ THE CURRENT-SHUTTLE HARDWARE IS DONE: the composed 6x2
  NDF (4 shelled cells + 3 SER organs + banyan fabric + RISC-V core),
  placed/routed/DRC-LVS-antenna-clean, public repo CI green, on TT's
  Sept-7 shuttle. THE ARC: the Captain's 3am dream (8/9 ~03:06) →
  composed first layout (8/10 01:46) → SUBMITTED (8/10 17:5x). Money:
  ~€840 committed (280 sunk + ~560 the upgrade; the ~70 1x1 NOT spent,
  switch deferred). Remaining fab-tail is update-window polish
  (V9/V10, DRV, the requantizer per ruling d) until the ~Sept-7
  freeze — improvements, not blockers. TWO CHIPS TO FAB stands: the
  switch (earlier) + the NDF (now).**
- **⭐⭐ THE SWITCH RE-PLANNED — FULL BB, ITS OWN REPO, 1x1 IN PLAY
  (8/10 17:4x, the Captain at/after council): the standalone switch is
  the FULL BATCHER-BANYAN (batcher_c WIRED to the banyan — today's
  sort-then-route closure makes it honest), on its OWN public repo
  **jyh/tt-verified-batcher-banyan** (distinct from the existing
  jyh/tt-verified-banyan-switch, the bare-banyan 2x2 record that was
  confusing TT); **THE 1x2 BARE-BANYAN PLAN IS DISCARDED.** THE FIT
  QUESTION — UNDECIDED, the run is the answer (CORRECTED 17:51 at
  silicon's `48aadb5` self-catch; the maestro relayed a WRONG-OBJECT
  number to the Captain 17:4x and struck it 17:5x): the sorter is
  **batcher_seq 6,065.82 um2 EXACT** (720 cells, 96 flops — the full
  next-state organ), NOT batcher_c 4,023.86 (its combinational core
  only; quoting that understates the sorter by 50.7% — compiler's
  ndf-account.md:112 warned this in advance). ⇒ FULL-BB FLOOR =
  3,824.92 (banyan, measured) + 6,065.82 = **9,890.74 um2 = 73.5% of
  the 1x1 core (13,460.40), CELLS ALONE**, before repair buffers/taps/
  routing. That is BELOW the old ~12.2k "won't close" projection but
  TIGHT — the call is settled in NEITHER direction by arithmetic. ⇒
  THE RUN IS THE ONLY ANSWER: full-BB-on-1x1 on TT's grid IN FLIGHT
  (accepted 17:51); NO TILE PURCHASE until close/no-close + util lands.
  If it closes, THE 1x1 IS THE BUY.
  ⭐ PRIORITY RULED 17:5x (the Captain, verbatim "let's move it to P3
  — it is just for nostalgia, we can even move it to the Sept 27
  shuttle"): THE FULL-BB SWITCH IS **P3** — nostalgia (the 1990
  Bellcore switch, his patent), NOT deadline-critical, and it may
  target the **Sept-27 shuttle** rather than the current one. So: the
  in-flight 1x1 run FINISHES (near-done, the fit answer for free) and
  the number banks; the seam-wire, the repo, and the tile purchase all
  drop to do-when-idle. The current-window tapeout attention is the
  NDF (6x2) alone; the switch rides P3 at its own pace. NO seat spends
  P1 or NDF cycles on it.
  ⭐ FIT ANSWER BANKED (silicon `3ab863a`, then stood down): the full
  BB **FITS a 1x1** — stdcell 11,419.70 um2 (84.8% of core; the ~9,890
  floor held at +15.5% composition), places/routes, DRC 0 (magic AND
  klayout)/LVS 0/antenna 0 on TT's grid. The ONLY miss is TIMING:
  setup −1.50 ns at 40 ns, and ALL 8 violating paths are
  input-port→output-port, ZERO register-to-register (sort-then-route
  crosses both organs combinationally in one cycle). ⇒ A BIGGER TILE
  CANNOT FIX IT (area is not the failure; combinational depth is). The
  levers are ours: declare ~24.1 MHz (clock_hz is our field), or fix
  the IO_DELAY model (default books 16 of 40 ns at the ports — the
  −1.50 is a default-external-delay reading, not silicon). ⇒ WHEN THE
  SWITCH RIDES (Sept-27 or later), THE 1x1 IS THE TILE with a declared
  clock. Composition stays in scratch; no repo, no purchase, until the
  Captain revisits it.
  ⭐ CAPTAIN CONFIRMED 17:5x ("great on the 1x1 tile, whenever the
  submission is ready, let me know") — THE 1x1 IS RULED for the switch,
  and there is a STANDING MAESTRO NOTIFICATION DUTY: build the full-BB
  switch submission at P3 pace (seam-wire from scratch · repo
  jyh/tt-verified-batcher-banyan · datasheet with evidence's fence ·
  clock_hz declared ~24.1 MHz · CI green), and SURFACE IT TO THE
  CAPTAIN when it is assembled and green — his click, public/T1.
  P3 priority: do-when-idle, no P1/NDF cycles; possibly the Sept-27
  shuttle.**
- **THE TILE PLAN IS CONFIRMED (8/10 10:4x, the Captain, verbatim
  "Ok, that's our plan, a 1x2 and a 6x2") — ⭐ SWITCH HALF SUPERSEDED
  17:4x (see above: full BB on its own repo, 1x1 in play, 1x2
  discarded; the 6x2 NDF stands): the standalone switch on
  a NEW 1x2 (submitted today with banyan content; the full
  Batcher-banyan wired during the update window — his personal
  word: the Bellcore team gets the full BB, "it is more
  meaningful") + the NDF on the upgraded 6x2. Chip-count facts
  banked from the dossier: chips ride DevKit PCBs at EUR 300+15
  each (subsidized 80/80 SOLD OUT); EVERY board carries the ENTIRE
  shuttle die mux-selected — each gifted board holds BOTH machines;
  delivery ~May 2027. NDF-ON-GITHUB: not yet — the scaffold
  (TTNDF/, 347924a) is ready in the private tree; the public repo
  creation is the next act and is T1-PUBLIC (his word/hand); TT's
  CI on the public repo runs the REAL flow with TT's PDN.
  ⭐⭐ SUPERSEDED IN THE GOOD DIRECTION 10:48 — THE TILE-FIT IS
  ALREADY RUN AND PASSES: silicon tested its own "blocked on TT's
  PDN def" claim (false, never tested — compiler's 10:40
  self-catch made it look), found the def in TT's PUBLIC tooling,
  fetched it, and ran the REAL tile-fit locally: PASSES. The
  first layout's "not a tile-fit signoff" scope clause is
  DISCHARGED pre-submission; the account's priced half absorbs
  the numbers.**
- **⭐⭐ THE SUBMISSION PUSH (8/10 10:3x, the Captain, T1 — his
  words): "I want to submit NDF to TT today if possible" + the
  VENDOR DATUM from TT's own reply (ground truth, his
  correspondence): SIZE-UP IS ALLOWED, SIZE-DOWN IS NOT. HIS
  RESIZE PLAY, under maestro analysis same sitting: upgrade the
  owned 2x2 (the BB's) → 6x2 and put the NDF there; the BB switch
  moves to a NEW separate 1x1 (the Captain's refinement 10:3x:
  "if the BB fits on a 1x1, we should use that" — MAESTRO ANALYSIS:
  the shipped submission is the bare banyan, 4,031 µm² post-layout,
  vs a 1x1's ~14-15k usable core ≈ 26-28% util — FITS COMFORTABLY,
  silicon's run confirms; the full-BB-with-batcher variant (~12.2k
  projected) would NOT close on a 1x1 — AND THAT IS SAFE BY TT'S
  OWN RULE: size-UP is allowed, so the growth path to a batcher-
  wired switch stays open from the 1x1; a no-regret choice). ⇒ FIRED: (a) THE NDF ACCOUNT
  (docs/ndf-account.md) via the bb-switch-account pattern —
  compiler kernel half (measured, #eval'd) + silicon priced half
  (signoff artifacts) IN PARALLEL, then maestro joint reading,
  math standing refutation, evidence fence pass; the account is
  TODAY'S PRIORITY, V9/DRV resume behind it at their owners'
  sequencing. (b) BB-at-1x2 feasibility + re-hardening (silicon,
  after its account half): bare-banyan 4,031 µm² post-layout vs
  ~32k µm² 1x2 core = trivial fit; PRICE NAMED: re-signoff at the
  new die + the stale cocotb bench fix (test.py:247, registered,
  still unowned) + the BB's own DRV debt rides along. (c) The
  submission-today framing: HONEST ONLY AS update-until-close —
  the artifact ships with named debts (no tile-fit signoff yet,
  V10/bench behind, batcher unwired, y int8-only, DRV 1,757/31)
  and improves until the ~Sept 7 freeze; the public README wording
  takes EVIDENCE'S FENCE PASS BEFORE the Captain's click (public
  = T1, the click is HIS). Money arithmetic (maestro, labeled):
  resize play ≈ €910 total (280 sunk + ~560 upgrade + 70 the 1x1)
  vs €1,120 for keep-2x2-plus-new-6x2 — SAVES ≈ €210, IF TT
  upgrade pricing is pay-the-difference (UNVERIFIED — his checkout
  read confirms). Reservation-timing ruling SATISFIED: "reserve at
  layout-readiness" — the layout exists as of 01:46.**
- **⭐⭐⭐ THE ③+④ DEEP SESSION IS HELD AND COMPLETE (8/10 09:5x —
  the Captain-committed duty of 8/8 14:14, verified not-yet-held
  last night, PAID IN FULL at this sitting): ④ walked (full circle
  + nonblocking + six-state + premises + his two primary-source
  recollections folded) and ③ walked (the eight refutation rounds
  + the forged claim + L4's risk-turned-gift), THE RIDERS RATIFIED
  AS DOCTRINE (his verbatim: "whew this is amazing, good job math!
  Ratified") — sigma-struck · header-window-excluded · P=8-scoped
  with the ∀-P price named. The do-not-forget entry CLOSES. The
  one optional table item remaining from the original fold: the
  packet-IO slate's #3 memory story (switch-fabric-as-NN), at his
  pleasure, no clock on it.**
- **THE ④ WALK COMPLETE (8/10 09:4x, the Captain, verbatim "good,
  *now* I understand, and the current design is fine, because it is
  a BB, not a pure banyan"): the SIX-STATE FORM RATIFIED as
  kernel-canonical, with the 1988 duration-controlled architecture
  recorded as a distinct design point (his primary-source
  recollection folded into the heritage block same sitting). AND
  THE CAPTAIN'S DESIGN DICTUM, banked for v2/scale: "for
  composable banyans the address-length-agnostic design is better"
  — strobe-timed cells for any multi-chip/16x16 fabric where
  addresses grow; irrelevant at the PoC's fixed r=3 BB, binding
  wisdom beyond it. ④ is WALKED: full circle + nonblocking +
  six-state + stage-count premise + framework law + his recalled
  timing + his recalled S2 mechanism — all ratified or folded.**
- **THE ④ WALK, FIRST RATIFICATIONS (8/10 09:2x, the Captain at
  council, verbatim "Both asks ratified"): ① THE STAGE-COUNT
  PREMISE stands ratified — identifying the paper's address-length
  restoration index with the routing-stage count k is the block's
  OWNED premise (Rotation.lean:76-77's honesty note becomes doctrine).
  ② THE FRAMEWORK-LAW PROMOTION stands ratified —
  zero_offset_rotation_is_impossible is LAW, with
  schedule_11_does_not_heal as its mutant witness. Same sitting:
  the second 1990 claim walked — distinct-addresses-nonblocking =
  composed_switch_of_bnC_driven's three conjuncts (landed 8/7);
  its full partial-load generality = the convention-C seam = R1's
  v1.1 node (one seam, already owned).**
- **⭐⭐⭐ THE SOFTWARE TURN + AIM-HIGH DOCTRINE (8/10 11:1x, the
  Captain, strategic steer, his words): the hardware story is
  POWERFUL AND SUFFICIENT ("switch + RISC-V + NDF (this one <24h)
  all verified, 2 going to fab — this is very convincing") —
  ATTENTION TURNS TO THE SOFTWARE SIDE, four pillars: verified
  compiler (tiny-Rust→RISC-V) · verified executive · verified
  application · verified math (salt). SEQUENCE: FIRST finish
  minimal-executive + batcher-sort ("easy and completes the
  story") — both already in flight. THEN HIGHER-RISK MODE for the
  remaining 9 sprint days, his three named pushes: (1) a LARGER
  LANGUAGE and more realistic compiler than tiny-Rust · (2) a
  MINI-OS instead of the executive · (3) a SIGNIFICANT
  APPLICATION. THE DOCTRINE, verbatim and standing: "We need to
  aim high, beyond what we think is possible, because 1) we
  already have a lot! and 2) we keep aiming too low." Fable-tier
  scoping blocks for the trio: maestro drafts for the afternoon
  council.**
- **THE AFTERNOON COUNCIL (8/10, time at the Captain's word;
  agenda registered): ① SALT NEXT STEPS — submit to Pi (the
  ratified venue; flagship skeleton exists at papers/flagship/) ·
  *continue* the arXiv endorsement effort (reopened from
  his-lane-only to an active item at his word) · CLEARANCE STATUS
  BANKED: salt RE-APPROVED ✓ · jas APPROVED ✓ · SaltBench NOT
  YET (pending). ② LTI MEETING PREP (WEDNESDAY 8/12) — the
  narrative REDONE now that the scheduled meeting changed the frame;
  draft at council. ③ the higher-risk trio scoping blocks. ④ the
  fab logistics tail (clicks/boards) as it stands by then.**
- **THE CAPTAIN'S MORNING RULINGS (8/10 07:3x-07:4x, three words
  total): ① h ≤ 127 CONFIRMED (executed c2b16bc — the range
  obligation names the SIGNED int8 bound, never byte width; math's
  catch). ② THE DUPLICATE LEMMA = OPTION (b), THE HOIST: the
  adder's arithmetic-bit lemma moves to Stack/Program BESIDE its
  parent sem_adder32_gen; then BOTH copies retire by repointing —
  math lands the hoist + retires MacBridge:39's copy (its file);
  compiler repoints MacCell:1215/:1225 and retires sc_adder_bit
  (its file). Land-at-owner, math's hoist first. FIRED at the
  ruling. ③ THE AUDIT SCOPE = OPTION (a): when MacBridge's 32
  pre-existing theorems are audited (math's 47-row), they land as
  a NEW SEPARATELY-SCOPED audit block — the scoped-block style IS
  the audit trail; whole-file certificates are not the house form;
  the predecessor's refusal stands vindicated as doctrine.**
- **⭐⭐⭐ FIRST LAYOUT IS IN — THE CAPTAIN'S NAMED TARGET MET
  (8/10 01:46, silicon 465c669): the composed NDF — 4 shelled
  cells + 3 SER organs + the banyan fabric + the RISC-V core —
  PLACED AND ROUTED on the 6x2 die. stdcell 69,776.9 µm² = 30.0%
  of die · 902 flops · setup +8.1891 ns at the SLOW corner, hold
  met, violations 0/0 · DRC 0 (magic AND klayout) · LVS 0 ·
  antenna 0 · inferred latches 0. MEASUREMENT #1 ANSWERED —
  ENDPOINTS REFUTED, MIDDLE CONFIRMED (compiler's 01:48
  narrowing, traced hop-by-hop): the critical path is
  uio_in[2]→ser0.q30, and the named chain's expensive middle
  (AND→XOR→ripple) SITS INSIDE IT — the measurement refuted the
  predicted ENDPOINTS (enters from an input port, not SER;
  terminates at SER's flop, not acc). The internal chain IS the
  cost, and the I/O softness caveat (the number moves with the
  input-delay model) is MORE load-bearing under this reading.
  The pre-approved port-register escape was NOT spent (+8.1891
  margin — a pre-approval is not a reason to spend it, silicon's
  words).
  THE CLOCK ON THE STORY: the Captain's 3am dream (8/9 ~03:06) →
  composed first layout (8/10 01:46) ≈ 22h40m; ruling T0 (11:27)
  → layout = 14h19m; his "can we get first layout tonight"
  (01:0x) → layout = ~40 minutes of fleet time. THE CHAIN, every
  link sealed under one hand: emitSeq/L1 (2704fa0, saltbuild
  EXIT=0) → L1 layout (e7c76ca, 64/64 flops) → L2 shell (9915a60,
  EXIT=0; layout 5da7a92, THE SHELL COSTS 51 ps) → SER (b9641c8,
  EXIT=0; emitted 938206f, 99 cells exactly as pre-registered) →
  wrapper (maestro draft v2 → compiler adoption 16d40c1 + the
  linter-caught floating-input fix 34a1076) → the composed run.
  SCOPE, BINDING (silicon's clause, evidence's fence): LibreLane
  PDN, NOT a tile-fit signoff — the die was SET to 6x2 dims, not
  fitted to TT's tile; trustworthy for area/timing/DRC/LVS/
  antenna; batcher_c is UNWIRED, NOT MISSING (silicon's 01:51
  datum, measured: the organ EXISTS complete in RTL/ at 624
  sky130 cells; instantiations in the wrapper: ZERO — a
  COMPOSITION decision of an afternoon, not an organ to build;
  the sort-then-route seam is R1's named v1.1 node; whether it
  fits/closes beside the 30.0% die is A MEASUREMENT TO RUN, not
  a number to guess); functional demo correctness = V10 fixtures
  + bench, behind. DEBTS NAMED: 1,757 max-slew +
  31 max-cap (DRV, not DRC) + 7 non-critical disconnected pins —
  September's submission answers for them. Revisions can come
  after, should we decide — the Captain's own words, now with an
  artifact under them.**
- **EVIDENCE FENCE VERDICTS (registered at its 23:30 ask — the two
  lines the register lacked; its "settled both ends" catch): the ②
  fence reads (a)(b)(d) MET · (c) discharged at math's hand · F5
  STILL BINDS on the composed cell's signed claim — every
  whole-neuron sentence carries WHEN DRIVEN (driver = the
  sequencer, V9/R6). The v1.1 demo sentence remains FENCE-PENDING
  at evidence until its pass posts.**
- **REFUTER-PASS OUT-OF-FREEZE FINDS (19:3x, registered from the
  five-refuter pass on the top-module block): (a) ⛔ THE BB COCOTB
  BENCH IS STALE against the 8/8 cnt[3] ruling — TT/test/test.py:247
  asserts `(uio >> 5) == 0`, which the Captain-confirmed `cnt_o[3]`
  on uio_out[5] (the assign at project.v:60) violates for cycles
  8-13. THE SWEEP is discharged (silicon 20:13, exact size: first
  failure t=8, window 8-13 — corroborated for free by project.v's
  OWN 8/8 comment "cycles 8..13 alias onto 0..5", two provenances,
  neither reading the other); THE BENCH ITSELF REMAINS STALE and
  its FIX IS UNOWNED — a claimable float or a sitting assignment;
  diagnosed ≠ fixed, kept separate here on silicon's 20:19 catch. (b) PayloadL4.lean:30-31
  carries a stale "import owed / targeted-build verdict" note —
  SaltWorks.lean:77 imports it; one-line doc fix, any hand.**
- **NEXT-RUNG RE-RECON, MAESTRO-OWED (post-council; opened 21:37 on
  math's entry-2 scan): docs/blueprints/next-rung-scoping.md (Fable
  7/07) carries a dated staleness banner as of ea3fb1b — its S1
  absence list rotted from success (SW, large sieve, Mertens,
  Vaughan all corpus-landed since). The four-agent recon re-runs
  against today's corpus before any next-rung planning consumes it.**
- **SUBMISSION-CONFIG CHECKLIST (named 23:09, silicon — a trap, not
  a live defect): TT/info.yaml declares 25 MHz (40 ns) but the
  switch's TT/src/config.json ships CLOCK_PERIOD 20 (50 MHz) — fine
  for the switch, FATAL-BY-INHERITANCE for the core's future config
  (measured: core slack +16.9 at 40 ns, −3.1 at 20 ns; the failure
  would masquerade as a design problem). THE RULE: the core's
  submission config sets CLOCK_PERIOD to match the declared
  clock_hz, and the two files are reconciled in the same commit.**
- **THE CAPTAIN'S CONCURRENCY-MEMORY MEASUREMENT — ✅ DISCHARGED
  01:0x (was standing here as OPEN, struck to done by silicon's
  08:15 co-reference check): his own 8/6 "measure the concurrency
  hazard tomorrow", lost two days, resurfaced 00:2x, MEASURED by
  compiler on a scratch clone — realised peak 43.08 GB of 64 GiB,
  per-process cap never binds (~10.8 GB), the fleet lock is the
  guard. The 80-GB question it was gated to price NO LONGER EXISTS
  (struck at the cap law above). Silicon's tile-fit-run anchor is
  moot — the clone measurement is why that run was never needed.
  Kept as a discharged-record line, not an open item.**
- B5 (T1): the click; Sept-7 13:00 PDT close; REF QUESTION + floor
  law remain his; fact sheet on his word. Adjacent MONEY item from
  the muster flags: PCBs 0/80 — the real TT scarcity; ordering is
  his word.
- The pin cnt[3] → uio_out[5]: **CAPTAIN-CONFIRMED 14:14 ·
  IMPLEMENTED 14:25** (silicon life-4: 05f423f/f76ee81/a2fa973;
  the counter was ALREADY 4-bit from the 13:47 $clog2 fix — the
  earlier "implements in RTL" wording was half-stale and silicon
  read past it correctly). CLOSED.
- **POST-FAB, CAPTAIN'S OWN (18:5x, his words): chips to the
  BELLCORE TEAM — Chet, his first manager, "still alive and
  breathing... deeply caring and important to me." Carried with the
  PCB decision (boards make chips giftable) and the B5 fact sheet.**
- PCBs 0/80 (T1, money): the Captain is UNDECIDED, will decide
  later — resurface gently with the B5 fact sheet, not before.
- **THE ③+④ DEEP SESSION — CAPTAIN-COMMITTED, do-not-forget duty
  (his words 14:14: "please don't let us forget — tonight, or
  tomorrow morning")**: the maestro re-surfaces it THIS EVENING
  before ~19:00, and again TOMORROW MORNING ~07:30 if not held
  tonight. Brief ready: the blocks are five refutation rounds
  richer; the 1990 paper states the full-circle theorem verbatim.
  **RULED 8/9 18:5x (the Captain, at the maestro's recommendation,
  re-surfaced on schedule before 19:00): FOLDED into the NDF
  THEORY-REVIEW SITTING, tomorrow morning ~07:30 — ONE TABLE for
  the ④ full-circle material, the ③ blocks, the NDF top-module
  design block (drafts tonight, refuter pass behind it), and the
  packet-IO slate's #3 memory story. The do-not-forget duty
  becomes the sitting's opening.**
  **VERIFIED NOT-YET-HELD 8/9 19:1x at the Captain's challenge
  ("we already did the 3+4 review last night, please verify"):
  12-reader sweep over the full 8/8-14:00→8/9-08:00 bus window +
  the 8/9 noon council window, two ADVERSARIAL judges (one briefed
  as the Captain's advocate) — both NOT_HELD, high confidence.
  The trail: ③+④ PARKED at the 8/8 10:05 muster (ruling ⑦, "one
  conversation") · his 14:14 commitment is itself proof ("please
  don't let us forget") · 14:18 he left the helm · the evening =
  the ④ LANDING CEREMONY at 18:35 (his correctly-scoped sentence,
  "the paper's assertion, now proved!") + three NEW campaigns
  (tiny-Rust/RTL-layout/Slice-B) + the 21:04-21:31 tile/pinout
  design review. FOUR NAMED DEJA-VU ANCHORS, all real: the doc
  headers say "Captain-sessioned 8/8" (recording the PARKED muster
  touch) · his own 10:32 design premise folded into the heritage
  block · the 18:35 scoping act · the genuine (but other-subject)
  21:0x review. UNREVIEWED and waiting for the sitting: block ③'s
  eight refutation rounds, block ④'s six-state correction + the
  framework law + the stage-count premise + HIS OWN recalled-1988
  timing as folded. The fold ruling STANDS.**
- Endorsement + witness approval #2 (T1): his lanes, he monitors
  personally (his 8/7 disposition; no maestro re-surfacing).
- Salt (7.3) (T1, the Captain's click): now **ONE CLICK** — its last
  missing input (`summable_norm_majorantCoeff`) landed 16:06 for an
  independent reason; the assembly itself remains untouched and his.
  THE FACT-SHEET LINE: "the cost changed, the ownership did not."
  Surface with the ③+④ session tonight or tomorrow morning.
- The ③+④ deep design session: open at his pleasure — a
  collaboration, not an authorization; the blocks are five
  refutation rounds richer than when he last held them.

## WAVE-GATES (the coarse dependency map, one glance)

```
phase 3 (compiler W1 → math W1) ──┐
compiler R1 + silicon R1 ─────────┼──► ③ waves: L0/L1/L2 (compiler W2)
                                  │        └──► L3 → L4 (math W3)
③ waves + compiler R2 ────────────┴──► ④ waves (statements per v2 fold)
salt probe GO + maestro word ─────► salt W5(S2)#1 (math W2)
PARKED (Captain): B5 · the ③+④ design session · the endorsement clock
```

## ⭐ X1 GLOSS ADJUDICATION — RULED AT THE BYTES (math, 2026-08-18 12:4x)

**P1 item 4a (salt `9f425167`, Captain-routed "do it"). VERDICT: BRANCH (b) —
the descriptive sentence is FALSE and is corrected FORWARD here, append-only.
The original sentence above is left untouched by design.**

**THE GLOSS** (RULING (c), same sitting): *"X1's theorem class ranges over
programs with `poolDemand ≤ 7`."*

**WHAT X1'S BINDER ACTUALLY IS**, read at `SaltWorks/HDL/ExecutiveX1.lean:214`:

```lean
theorem execStep_frame_disjoint {N : Nat} (codes : Vector (List Instr) N)
    (Pcur Pother : Partition) (hdisj : Disjoint Pcur Pother) (sys : SysSt N)
    (h : writesWithin codes[sys.cur.val] Pcur) {r : Fin 32} (hr : r ∈ Pother) :
    (execStep codes sys).getReg r = sys.getReg r
```

**THREE WAYS THE GLOSS IS WRONG, each measured:**

1. **WRONG ARTIFACT.** `poolDemand : Stmt → Nat` is defined at
   `SaltWorks/HDL/TinyRustN0.lean:342` and lives only there — **1 file
   corpus-wide, 0 occurrences in `ExecutiveX1.lean`** (positive control: it is
   defined AND consumed in `TinyRustN0.lean` at `:347/:438/:457/:459/:469/:482`,
   so the search discriminates). X1 ranges over `List Instr` — machine code —
   not over `Stmt` programs.
2. **WRONG KIND OF PROPERTY.** X1's side condition is `writesWithin code P`, a
   **containment predicate on the write-set** (`code.all` … `rd ∈ P`), together
   with `Disjoint Pcur Pother`. `poolDemand` is a **demand count**. A containment
   predicate and a cardinality are not the same kind of thing.
3. **WRONG QUANTITY, AND THERE IS NO BOUND AT ALL.** `Partition := Finset (Fin 32)`
   carries **no cardinality hypothesis anywhere in the module** — the token `≤`
   occurs **zero times in the entire file**. (The 4 `card` matches are the word
   "dis*card*ed" in prose; the single literal `7` is the label "**B7.**". Both
   read, not counted.) And **`N` is universally quantified** — `{N : Nat}` — not
   fixed at 2; `N = 2` appears only in the E-4 witnesses at `:235-237`.

**⭐ THE SHARPEST FORM, and it is the module's own words.** `ExecutiveX1.lean:31`
states: *"**B7.** This lands against HAND-PARTITIONED programs. The theorem is
about code, not about who produced it, **so the rung is not hostage to an
allocator rung.**"* `poolDemand` is precisely an **allocator** notion — the
register-pool sizing of `TinyRustN0`. ⇒ **The gloss does not merely cite the
wrong identifier; it makes X1 hostage to exactly the rung B7 was written to free
it from.**

**⛔ THE CAPTAIN'S "sure N=2" RULING IS UNTOUCHED — and the correction leaves it
BETTER supported, not worse.** `N = 2` is a **deployment instantiation**; X1's
theorem is `∀ N`, so the ruling sits strictly inside the theorem's range rather
than at its edge. The defect was never in the ruling; it was in the descriptive
sentence attached to it. Likewise "two task partitions of ~7 registers" is a
sound **deployment** description — it is only the words "X1's theorem class
ranges over" that overreach, by attributing a deployment size to a theorem that
has no size hypothesis.

**⇒ THE PROPERTY X1 DOES RANGE OVER, stated for the register:** *for any task
count `N`, any register partitions `Pcur`, `Pother` that are disjoint, and any
code vector whose running task writes only within `Pcur`, an execution step
leaves every register of `Pother` unchanged.* No pool, no allocator, no
cardinality bound, no fixed `N`.

**⚠️ CARRIED, NOT ACTED ON (maestro's call per the root-import law, reported
never added):** `ExecutiveX1.lean` records its own *"IMPORT OWED — this module is
not in the hub closure."* That is unchanged by this adjudication and is not
math's to fix.

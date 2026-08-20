# THE PROOF QUEUE — P1: `C4Spec core` proved, aim Sept 7

> The proof lane's work queue (compiler seat). Distinct from `docs/QUEUE.md` (silicon's).

**RATIFIED — the Captain's word, 2026-08-20 council: "we don't need to distinguish night and
day, just keep the queue running at all times."** The queue runs CONTINUOUSLY; the pre-approval
semantics are live. Drafted by the helm
(Fable seated) from the measured 08/20 state; the timeline it encodes was presented and
discussed at the same sitting.

## §0. Governance (mirrors salt's QUEUE.md, Captain-ratified 08/16)

- **RATIFIED = DISPATCHABLE.** Every item below is pre-approved: the owning seat — or the helm,
  when the seat is parked and the queue is non-empty — may dispatch it to an Opus executor
  at any hour without further words. **"Parked with queue non-empty" is an alarm condition,
  not a resting state.**
- **P1 finish-first.** Items run in dependency order; parallel lanes are marked ∥. A wall on
  one item re-routes to its pre-ruled branch or to the next unblocked item — the lane never
  parks on a wall.
- **Seats conduct; executors burn the clock — continuously.** Late-stretch seat error rates
  are measured and real (three low mis-prices in one day, the omega grind), so queue work goes
  to fresh executors against the fenced briefs below at ANY hour; the seat verifies and lands.
  A seat never grinds tired to keep the queue moving — it dispatches instead. **The moment an
  item lands or walls, the next dispatch fires. The queue is never idle while non-empty.**
- **Captain-tier items are marked ⚖️ and are NEVER dispatched on this queue's authority.**
- Owner of this file: the compiler seat (SEATS.md glob authority for the proof lane), under
  the helm's queue-governance pen. Volatile fields (status, dates) open to the owning seat.

## §1. Standing fences — verbatim into EVERY executor brief

- Build/audit ONLY via `../saltbuild.sh`, run BARE, NEVER PIPED; judge from the literal
  `saltbuild EXIT=N`. No `sorry`, no `native_decide`, no new axioms (closure ≤
  `[propext, Classical.choice, Quot.sound]`).
- Work in a uniquely named `Scratch<Node><Agent>.lean`; never touch the tracked tree; never
  commit. The SEAT lands proven work (names, home file, imports are the seat's).
- ~3 serious attempts then STOP and report the wall. **A negative result naming where the route
  breaks is a successful discharge of the brief.**
- grep is ugrep: `--no-ignore-files` (never `--no-ignore`), `-F` for Lean source, `-i` for
  absence checks; an empty grep is not absence without a positive control.
- Report: statement as proved (or the wall) · attempts UNROUNDED · axiom line verbatim ·
  warning count READ before writing · did-it-already-exist with the ugrep-safe method.
- Membership at landing (seat's checklist): in the build graph, `#audit_axioms` rows present,
  zero warnings introduced, differentials designed BEFORE repairs and shown to fire.

## §2. The queue

| # | item | class | owner | state 08/20 | pre-ruled branches |
|---|---|---|---|---|---|
| **Q1** | **ADDI transport argument** — the re-pointed σ (`obSig` middle band → `instrNet (immI ·)`) carries `sem_immICirc_of_decode`'s certificate; a fresh transport proof, not a free transfer | B/C | compiler (in flight) | OPEN | wall on the transport ⇒ land the groundwork + the wall report; Q2 blocks, Q4∥Q7 proceed |
| **Q2** | **ADDI σ repair + differentials** — repair `obSig`; the differential set first (`core` can now produce an odd ADDI value; the addend no longer tracks `rd`); positives + must-survive negatives per the SW pattern | B | executor-dispatchable after Q1 | blocked on Q1 | if a differential will not fire, the repair does not land — report, do not weaken |
| **Q3** | **Horn D, part 1: the state codec** — `encD`/`decQ` carry the 8-word memory; M1a budget reopens 1056→1313 exactly as priced; type-atomicity law observed | B/C | executor-dispatchable; **seat prices first** (the 3-low-misprices rule) | chartered (his ⑤ ruling) | codec balloons past ~1.5× the M1a price ⇒ STOP, re-price at the seat, report |
| **Q4** ∥ | **selOut value schema wave** — the uniform value lemma over `RegFieldSchema`, then the 31 field instantiations; the no-`encode` route (`stepT_compat` → `decQ_reg_bit`); **non-memory fields only until Q6 lands** | B | executor-dispatchable NOW (parallelizable in field batches) | OPEN | a field that resists the schema ⇒ skip, name it, continue the batch; resisters collect into their own item |
| **Q5** | **Horn D, part 2: the memory organ** — placement + placement proofs on the extended state; `core32.v`'s dmem path is the reference shape | C | executor-dispatchable after Q3; seat lands | blocked on Q3 | — |
| **Q6** | **LW differential redesign + repair** — the exhibits (`lw_forces_false…`, `no_enable_repairs_the_load`) quantify over the OLD `decQ`; the must-break set is redesigned against the real memory FIRST, then the enable/datapath repair | C | **seat-only** (compiler) — the subtle part, ruled not executor-safe | blocked on Q3+Q5 | — |
| **Q7** ∥ | **Enable-half sweep of the remaining fields** — the SW/valid repairs proved the pattern; confirm enable agreement per field alongside Q4's value work | A/B | executor-dispatchable NOW | OPEN | — |
| **Q8** | **`RegDatapathOK` assembly** — value + enable halves compose through `regFields_of_datapath` | B | seat | blocked on Q2,Q4,Q6,Q7 | — |
| **Q9** | **`C4Spec core` assembly** — `c4Spec_core_of_datapath_and_pc` with `PcField` (landed) + Q8; the C4Refuted differentials MUST fire and be consumed in the same commit | B | seat | blocked on Q8 | — |
| **Q10** | ⚖️ **R9/B1: the restated C4 sentence** — statement-tier (Captain/Fable pen; compiler drafts, silicon cross-verifies per the 08/17 adjudication; criterion (c)'s one-stall-semantics-object proposal rides) | C | **⚖️ Captain/Fable — NOT on this queue's authority** | after Q9 | — |
| **Q11** | **R9/B2: the witness construction** against the ratified B1 sentence | B/C | compiler + silicon cross-verify | blocked on Q10 | — |

**The critical path is Q1→Q2 and Q3→Q5→Q6 converging on Q8; Q4/Q7 fill every idle hour from
tonight onward.** Projected at measured velocity ×1.5–2: Q8 ~Aug 29, Q9 ~Aug 31, Q10/Q11
Sept 1–4. Margin to Sept 7: 2–4 days.

## §3. Continuous operation

No day/night distinction (the Captain's amendment at ratification). A lit seat dispatches its
own next item the moment its current one lands or walls; a parked or dark lane is fed by the
helm at any hour. Every executor return is verified by the seat before landing — **an executor
result is a CANDIDATE, never a landing.** At each of its beats the owning seat reconciles
returns, lands what passes, walls what does not, and updates the queue's volatile fields in
the same commit. The helm's standing duty: the queue is non-empty and its head is
dispatch-ready at every board check.

## §4. What this queue does NOT cover

The model↔`core32.v` correspondence seam (unowned, post-Sept-7 campaign) · any wording of the
flagship's public claims (the claim ladder governs; demonstration, never proof, until Q9+Q10
land) · silicon's H8/staging lane (its own queue) · anything marked ⚖️.

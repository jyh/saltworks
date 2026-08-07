# THE STACK STORY — pre-registered narrative spine
### Drafted 2026-08-07 (day 2 of the campaign) by the maestro, at the
### Captain's direction. STATUS: the claim below is a TARGET, registered
### before the outcome; every bracketed number is filled from the
### generated ledger at campaign close, never typed from memory. Nothing
### publishes until the artifact exists. Voice per the writeup register;
### publication sweep (tells, em-dash review) applies before any release.

## 1 · The claim (the sentence we are building toward)

> **"We built a verified full stack — an AI agent wrote an application
> in a formally specified language; a verified compiler carried it to a
> verified RV32I core; the fabricated netlist is machine-checked
> equivalent to its specification, ≤ 3 axioms end to end — in
> [N] days, with a fleet of 5 AI seats and one human whose required
> attention was [M] minutes per day. Here is how it scales."**

The application: Batcher's sorting network as software — chosen because
its author first built it in silicon in 1990, and the same algorithm now
runs at every layer of a machine-checked stack: proved as mathematics,
compiled by a proven compiler, executed on proven silicon. The stretch,
if it lands in-window: a verified *executive* (scheduler + message
passing, specified and proved against the ISA semantics) — named
executive, not OS, until it earns the larger word.

## 2 · The artifact chain (what "full stack" means here, exactly)

| layer | artifact | verification |
|---|---|---|
| application | Batcher sort, RV32I, agent-written | sorts + permutes, proved against `step` (S1–S3) |
| [stretch] executive | scheduler/messaging | spec'd + proved against `step` (S4) |
| ISA | `Instr`/`St`/`step` + encode/decode | round-trip proved; vectors vs Spike + SAIL (C2) |
| compiler | Circ DSL → netlist | `emitN_sem` / structural emission (C4) |
| silicon | flow → GDS → re-imported netlist | per-cone equivalence at register boundaries (C5) |
| provenance | the agent's authorship + the full ledger | generated, seat-cross-checked, append-only |

The trusted base is stated at its true size: the importer (~300 lines),
the cell models (cross-checked against the vendor library), the flow's
LVS claim, and the kernel itself. Every boundary is named, none is
hidden.

## 3 · The human-attention figure (measured, two components)

The campaign's design floor is ~40 min/day (morning brief + midday
check + evening seal). The measured figure will be higher and is
reported as two numbers, because they answer different questions:

- **Required attention** — rulings only the human could make (public
  gates, frozen statements, taste, spend envelope): [R] min/day.
- **Chosen engagement** — voluntary participation beyond the floor
  (design conversations, deck visits, debugging alongside the fleet):
  [C] min/day.

The distinction is measured by the ledger's human-time instrument
(four-category tags + the meta/design split, instrumented from day 2;
per-seat, with the instrument seat's own line disclosed). The scaling
claim rests on [R]; that [C] exceeded it is itself a finding — the
system was engaging enough that its human *chose* more than it
required — but the claim never borrows from it.

## 4 · How it scales (analysis under FIXED human attention)

Scope note, deliberate: we analyze scaling the *machine* fleet under
one human's constant attention. Scaling the human side is out of
scope — this work's premise is that the human's role (direction,
taste, final authority) is the part that should *not* scale.

- **5 → ~15 seats: the star holds.** One coordinating seat, standing
  delegation (probe authority, draft-until-refuted freezes, escalation
  ladders with split attempt budgets). Coordination cost is paid in
  *laws*, not headcount — the campaign's own record shows throughput
  doubling from governance changes at constant fleet size.
- **~15 → ~50: the star becomes a tree.** Squadrons with their own
  coordinating seats; squadron buses under one fleet bus (a text file
  in git — the one interface that already spans OSes and sandboxes).
  Coordinators are *fungible by construction*: the persistent memory
  bank, the roster, and the boot kit — not any individual session —
  constitute the role. One invariant never shards: a single fleet
  roster ("remember who the fleet is").
- **~50 → 1000: the bottleneck changes species.** Kernel verification
  parallelizes essentially without limit — checking is the cheap,
  parallel half of the method. What binds is the **design frontier**:
  the number of simultaneously well-posed interfaces. Interface
  definition is serial, senior work; a thousand executors pointed at an
  undesigned problem produce unconsumed supply, not progress (the
  campaign's demand-side discipline exists precisely to prevent this
  at n=5). Corollary from the record: **each order of magnitude of
  fleet requires its own generation of coordination law, and the laws
  are learned from incidents** — so scale is climbed in stages, minting
  the governance at each rung.
- **Calibration**: a verified microkernel (seL4-class results cost
  person-decades historically) projects to a months-scale campaign at
  20–50 well-governed seats — the additional 950 seats buy little,
  because the binding constraint is a dozen sequential design blocks,
  not proof labor.

## 5 · Limitations, stated up front

1. The scaling section is **analysis, not experiment** — no
   multi-squadron drill has been run ([the one-day squadron-split
   drill is named as future work, deliberately low priority; the
   campaign's artifact outranks its own scaling story]).
2. [N], [M], [R], [C] are unfilled until campaign close; if the
   artifact does not complete in-window, this document publishes the
   miss with the same prominence as it would the hit.
3. The executive (S4) and the end-to-end composition (S5) may land
   after the two-week window; the claim-sentence degrades gracefully
   to the rungs that are true, by name.
4. The chain's remaining trust boundary (flow/LVS, cell models,
   importer) is stated in §2 and never elided.

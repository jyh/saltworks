# THE STACK CAMPAIGN v0 — the full-stack verified artifact
### Maestro (Fable), 8/7, DRAFT-UNTIL-REFUTED. Captain-blessed in-channel:
### Batcher sort as the application ("very canonical"), the verified
### EXECUTIVE as the stretch, crypto as the second ascent ("compelling,
### a bit harder"). Consumer: the demo story — "we hand the agent a
### spec; everything below it is proven" — and the Aug 12 LTI narrative.

## The claim being built
**(unverified) agent → verified code → verified compiler → verified
[executive →] verified silicon.** The banyan tile is the PILOT of this
chain (agent-authored Circ + spec'd routing + emitN_sem + fabric_routes);
the CPU makes it PROGRAMMABLE; the application makes it legible.

## Deliverables (each independently shippable, honest names)
- **S0 — SEAM CENSUS, composition-checked (the C0 doctrine).** The
  software/ISA seam at the bytes: program representation (encode/decode
  round-trip is LANDED), the execution model (`step` iteration + fuel),
  and ⚠️ THE MEMORY MODEL — what does `St`'s memory interface actually
  support today? Nothing freezes until every composite elaborates.
- **S1 — the spec**: sortedness + permutation over the machine words
  (mathlib's `List.Sorted`/`List.Perm` — small, standard). Math's lane.
- **S2 — the program**: agent-written Batcher (bitonic) sort in RV32I —
  **REGISTER-RESIDENT (memory ruling 8/7, census 2fc95d8 §3.5 adopted:
  option (0) now; (A) data-memory-only when a consumer states an N
  registers cannot hold; NOT (B) this campaign — it kills
  run_halts_off_the_end, reintroduces fuel, and ends single-cycle).**
  There is NO memory image — the census found S2's original text named
  a missing TYPE: the assembler is `encode` over `List Instr` (what the
  differential harness already does), data lives in registers, n = 8
  (banyan-matched, S3(a)-proved) up to ~24. THE AGENT'S AUTHORSHIP IS LOGGED as part of the
  artifact — "unverified agent" is a claim about provenance, so the
  provenance is part of the deliverable.
- **S3 — the correctness proof**: two-layer refinement (math's lane):
  (a) the ALGORITHM sorts (Batcher merge, abstract — the 1990 resonance
  proved as mathematics); (b) the PROGRAM implements the algorithm
  under `step` semantics (loop invariants; `step` is executable, so
  concrete runs are kernel-computable sanity checks, but the theorem is
  ∀-inputs — genuine C-class proof design).
- **S4 — THE VERIFIED EXECUTIVE (stretch, Captain-blessed)**: a few
  hundred lines — round-robin scheduler + message passing + isolation
  by construction — spec'd in Lean against `step`, proven, running
  UNDER the application. Named EXECUTIVE, not OS, until it earns the
  word (seL4 is person-decades; we claim the rung we stand on).
- **S5 — the composition headline**: the tile's netlist, running P,
  produces sorted output — one theorem chaining S1–S3 through C4/C5's
  flop-boundary equivalence. The stack in a single statement.
- **APP-2 (second ascent, sequenced after Batcher): CRYPTO** —
  ChaCha20 or SHA-256 in RV32I. Compelling (constant-time execution
  pairs naturally with verified silicon; a crypto core people actually
  want attested), harder (bit-twiddling invariants). Sized when S3's
  cost coefficient is measured, not before.

## Kill-checks for the refuters (arrive with answers or run them)
- **R1** Fuel/termination: how does the ∀-inputs theorem handle the
  run length? (Fixed-bound for Batcher on N elements is natural — the
  network is oblivious, its length data-independent: USE that.)
- **R2** The memory model: does `St` support load/store today, or is
  that C1 completion work that gates S2? (Suspected gate — census first.)
- **R3** The `step`↔silicon-cycle bridge: S5 composes through C4/C5;
  neither is landed yet. S1–S3 proceed NOW against `step` alone;
  S5 waits for the ground floor. No overclaiming mid-campaign.
- **R4** Does the executive (S4) change S3? (A program under a
  scheduler proves differently than bare-metal. v1: bare-metal Batcher;
  the executive hosts APP-2.)

## Sequencing (against the 13-day clock)
S0 census: today/tomorrow, behind the C3 at-scale verdict. S1+S3(a):
math, can START NOW — pure Lean, no hardware dependency. S2: after S0
answers R2. S4: opens after S3(b)'s coefficient is known. S5: gated on
C4/C5, honest about it. The LTI story (Aug 12) rides whatever rung is
TRUE that morning — likely "verified compiler + verified silicon +
application spec'd and proving," which is already a story nobody else
can tell.

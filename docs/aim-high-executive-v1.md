# AIM-HIGH BLOCK ② — THE EXECUTIVE THAT EARNS ITS NEXT WORD (v1)

**Maestro draft (Fable hand), 2026-08-10, for the 16:00 council. Feeds the
Captain's push ②: "a MINI-OS instead of the executive." Recon basis:
${SEAT_DIR}/briefs/2026-08-10-aim-high-trio-recon.json (executive_os section).
Refuter pass owed BEFORE council consumption.**

## §0 · THE FENCE THIS BLOCK STANDS BEHIND, THEN REACHES OVER

The corpus pre-committed twice: "Named EXECUTIVE, not OS, until it earns the
word (seL4 is person-decades; we claim the rung we stand on)"
(stack-campaign-v0.md:42-43), and evidence's standing assignment is to audit
any "OS" claim (slice-b-design-v1.md:155-157). This block does not fight the
fence — it names EXACTLY which theorems move the artifact from "interpreter
harness" to "verified cooperative executive with preemptive scheduling at the
spec level," and which LATER capability would earn "mini-OS" (traps + task
loading, post-B-ISA, named-not-promised).

## §1 · THE AIM-HIGH TARGET (the star sentence)

**A VERIFIED MULTITASKING EXECUTIVE OVER THE LANDED MACHINE — round-robin
over N tasks with PREEMPTION BY FUEL QUANTUM, FAIRNESS over infinite runs,
and ISOLATION AS A COMPILER-ENFORCED THEOREM (register-partition frame
lemmas) — with ZERO dependency on unlanded silicon.** The Captain's own
words steer the isolation story: verified compilation gives "guaranteed
isolation; fragmentation is another story" — at Slice A there is no heap, so
fragmentation is out of scope BY CONSTRUCTION, and the guaranteed half is
exactly what we can prove now.

## §2 · THE THREE UNLOCKS THE RECON EXPOSED

1. **Preemption needs no interrupts at the spec level.** The corpus's
   `runFor` is already fuel-parameterized. An executive that runs task i for
   quantum q, snapshots `St`, and rotates IS preemptive timeslicing — as a
   Lean-level scheduler over the landed `step`, stateable TODAY. Hardware
   interrupts stay absent and the claim says "preemptive at the model,
   cooperative-on-silicon-when-compiled" honestly. (This also makes the
   Captain's registered next step — "GENERALIZING THE EXECUTIVE: preemption"
   — the block's spine rather than its deferred tail.)
2. **YIELD's JAL-dependency dissolves in the same move.** E1's "JAL to the
   executive's entry" is the COMPILED executive's convention (rung X4, gated
   on B-ISA). The spec-level executive needs no yield instruction at all —
   the quantum is the yield. B-EXEC's "the executive as a Slice-B program
   (hand-assembled as the fallback…)" clause already blessed exactly this
   split: the machine-code theorem is the point; the language/ISA is an
   on-ramp, not a dependency.
3. **Isolation is decidable per-instruction at five ops.** Every `Instr`
   writes exactly one register (`rd`) and reads two — the write-set analysis
   is a 10-line decidable function. "Task i's program only touches partition
   i" is a `Bool` judgment; the frame theorem lifts it to `step`, then to
   `runFor` slices, then across the whole interleaving. No memory exists, so
   at Slice A the register partition IS the whole isolation story — and the
   theorem is compiler-ENFORCEABLE the moment block ①'s allocator targets a
   partition instead of the full pool (the two blocks meet at one named
   seam: `allocInto : PartitionSpec → … `).

## §3 · WHAT STANDS / WHAT IS ABSENT (recon, confirmed with controls)

Standing: `runW_map` (word lift, unconditional), the Seq/Mealy theory with
`∀ st₀` discipline, the shell's freeze/clear/enable pattern (a context
switch's hardware face, half-landed), ISA + encoder round-trip, the fuel
witnesses (`loop_image_exits_with_work_pending`, `more_fuel_changes_the_answer`)
that PROVE the driver gap. Absent (all grep-verified with positive controls):
any Task type, any scheduler, any yield, any fairness/isolation theorem about
tasks, any infinite-run driver, message passing. `coreShaped_isolation` is a
FALSE FRIEND (conformance-field separability) — pre-registered here as
not-citable.

## §4 · THE DRIVER DECISION (the block decides it, as the design row demands)

B-EXEC's own first row says decide the driver BEFORE drafting statements.
**Decision proposed: STEP-INDEXED over coinductive.** An infinite run is
`Run := Nat → SysSt` with `run_step : ∀ n, sys (n+1) = execStep (sys n)`;
fairness is `∀ i n, ∃ m > n, stepsAt i m` — plain ∀/∃ over Nat, mathlib-native
induction, no coinductive machinery, and the finite-prefix lemmas connect to
`runFor` by construction. Coinductive streams buy elegance and cost tactic
support; fuel-only cannot state fairness at all (proved by the corpus's own
witnesses). The E-5 inhabitance control (one concrete configuration whose run
IS infinite, by construction) is the row's first theorem, before any wave.

## §5 · THE LADDER (stop anywhere; every rung banks alone)

- **X0 · the driver + inhabitance** (math seat, ~1 day). `SysSt` (task table:
  `Vector St N` + current + fuel counters), `execStep`, the step-indexed Run
  form, E-5's infinite-run witness. Also the census's forward-branch
  predicate lands here if block ① has not already landed it (one owner,
  first-lander wires it, SAID in both blocks).
- **X1 · isolation, compiler-enforced** (math+compiler at the named seam).
  `writesWithin : List Instr → Partition → Bool` (decidable);
  `step_frame : writesWithin code P → r ∉ P → (step s i).get r = s.get r`
  lifted to `runFor` and to the interleaving. E-4's pre-registered mutant:
  two OVERLAPPING partitions must make the theorem FALSE (by-construction
  disjointness is what the mutant proves non-tautological). The x0 cell is
  named once: partition indices exclude x0; reads of x0 are free (it is
  constant by `St.get`'s own law).
- **X2 · round-robin + fairness** (math). The scheduler as data (rotation),
  `fair : ∀ i n, ∃ m > n, stepsAt i m` — "steps" = EXECUTES ≥1 instruction
  (E-7's non-trivial reading), with the antecedent honestly stated (every
  task's slice gets a positive quantum; no yield hypothesis needed in the
  preemptive form — WHICH IS THE POINT: the cooperative form's "yields
  infinitely often" antecedent disappears, and with it E-6's scope caveat).
- **X3 · shared services** (math, small). One declared channel: a single
  mailbox register pair between adjacent tasks (channel set FIXED AND
  SYNTACTIC per E-4's c2 discipline; channel-partition disjointness a proved
  row). This is "message passing" at its smallest honest size — S4's sketch
  line becomes one theorem, not a subsystem.
- **X4 · the COMPILED executive** (compiler; gated on B-ISA's JAL/JALR, so
  explicitly OUTSIDE the nine-day promise). The spec-level executive of
  X0-X3 becomes a Slice-B program; yield = JAL convention; the X-theorems
  become refinement obligations. Named-not-promised.
- **X5 · what would EARN "mini-OS"** (named for the council, no clock).
  Traps in the kernel model (B2's spec form — arm inhabitance, no silent
  default; retires the "total is not conformant" fence the ratified way) +
  task images in a memory the state can NAME (option (A), dmem-shaped, F4's
  bridging obligation written first). Until both, the artifact says
  EXECUTIVE, and the story says why that is still real.

## §6 · SEQUENCING, COST, OWNERSHIP

X0-X3 are kernel-only, math-seat work — LOCK-DISJOINT from compiler's
contested seam (W5-asm / B-ISA / block ①'s N-waves). That is the block's
quiet strength: the executive ladder runs in PARALLEL with the language
ladder at a different seat. Nine days: X0 ≈ 1, X1 ≈ 2, X2 ≈ 1.5, X3 ≈ 1 —
comfortably inside the window with math's refutation duties intact. The
blocks ①/② seam (`allocInto`) is scheduled at L4/X1 convergence; if block ①
is cut short, X1 still lands against HAND-PARTITIONED programs (the theorem
is about code, not about who produced it — stated so the rung cannot be
hostage).

## §7 · CLAIM FENCES + VETO POINTS (pre-registered)

- "OS" never appears in an artifact claim under this block; "mini-OS" is
  X5's earned word, later. Evidence's claim-scope audit is invited on §1's
  sentence BEFORE any wave fires.
- "Preemptive" always carries "at the spec level / by fuel quantum"; no
  interrupt exists and no claim implies one. "Isolation" always carries
  "register-partition, no memory exists at Slice A; fragmentation out of
  scope by construction — the heap does not exist."
- VETO POINTS for the Captain: (a) step-indexed driver (vs coinductive);
  (b) preemptive-spec-first (vs the cooperative/yield form first — the
  cooperative form returns at X4 where it belongs); (c) N (task count) — 
  propose N=4, echoing the four-neuron k and keeping fixtures small;
  (d) whether X3's mailbox is in or out of the nine-day scope.

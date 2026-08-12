# THE MEMORY DESIGN BLOCK — LW/SW v1.1 (P2's gate — OPEN)

**Maestro (Fable hand), 2026-08-10 evening, as ruled at council ("for PoC
no memory is fine, but it is very unrealistic, you can do a design
today"). v1 drafted in the 8/10 model-drift window; v1.1 IS the Fable
re-review PLUS the five-refuter fold (5/5 REPAIR-THEN-FIRE, zero FATAL;
verdicts whole at ${SEAT_DIR}/briefs/2026-08-10-memory-block-refuter-verdicts.json;
folded by the night maestro, ritual run, record `claude-fable-5`).
This block gates ALL P2 pulls: the refuter pass has POSTED and the fold
has LANDED — P2 ② may pull. Census basis: docs/s0-r2-memory-census-0807.md;
Slice B basis: docs/slice-b-design-v1.md; silicon pricing:
docs/silicon-slice-b-memory-cells-0808.md. Every file:line pin below was
RE-VERIFIED against the live tree at the fold (several refuter-cited pins
had already drifted; the live values are the ones printed here).**

## §0 · THE DECISIONS, STATED FIRST (each with its refuter-visible reason)

1. **WORD-ONLY v1 — the byte-vs-word ruling, made by NOT PLAYING.**
   v1 lands exactly LW and SW, WORD-addressed, and NO byte/halfword ops
   (no LB/LH/LBU/LHU/SB/SH). The sp1-lean haircut was byte-load
   semantics proved for the wrong statement; v1 has no byte semantics
   to get wrong. The dmem8 RTL is already word-addressed with no byte
   enables ("the honest minimum for LW/SW" — its own header), so the
   kernel model and the organ are INTENDED to agree — pending F4's
   theorem (⬥v1.1: softened from "agree BY CONSTRUCTION"; the
   correspondence is stage ③'s deliverable, not a premise). Byte ops
   are a NAMED v2 door with the census's O4 warning stapled to it.
2. **THE STATE FORM — F2-at-word-grain, at dmem8's exact size:**
   `St` grows two fields: `mem : Vector (BitVec 32) 8` and
   `trapped : Bool`. ⬥v1.1 — the survival rationale, RESTATED at the
   refuters' insistence (r-stateform Q2/Q3, doc-consistency kill): this
   is **an F2-word landing via the F4 TWO-OBJECT BRIDGE**. The census's
   "no single form serves both lanes" verdict priced F2 as a BYTE
   vector at application-less sizes; word-at-8 escapes it (256 flops =
   the priced dmem8 organ, under slice-b B1's 16-word co-tenant
   ceiling, finitely encodable so the core lane stays stateable). But
   the ESCAPE'S PRICE is on the record, not elided: the ISA step and
   the hardware step stop being the same function, and the core codec
   covers **(regs, pc) ONLY** — `decQ_encD` is RESTATED as a
   projection (see M1a), a **deliberate departure from the
   x0-has-storage mirror doctrine** (StateCodec mirrors St's storage;
   mem/trapped are deliberately NOT mirrored — they live in the dmem8
   organ across the F4 bridge). F1 and F3 remain rejected for the
   census's own reasons. **F4's bridging obligation, written NOW
   before either side builds:** the kernel `mem` and dmem8 relate by
   the imported-netlist pattern (Silicon/Imported/*, as
   Comparator/Switch did) — the equivalence theorem is P2 stage ③'s
   deliverable, and NO kernel sentence about memory may say "the
   silicon" until it lands (the F3-fence habit, inherited).
3. **THE TRAP ARCHITECTURE — B2's form, minimally embodied.** The
   input classification is explicit and exhaustive: for LW/SW,
   `addrClass a ∈ {ok, misaligned, outOfRange}` — a TOTAL function
   into a 3-value enum, so no case can be MISSED. ⬥v1.1 — the §4
   slogan "a match, not a default" is RETIRED as inaccurate (r-trap
   KC1): over a `BitVec 32` domain `addrClass` is an if-then-else
   chain ending `else .ok` — that IS a final catch-all, and it is
   benign only because `.ok` is the ACTIVE (read/write) arm, not a
   no-op absorber. The load-bearing safety property is NOT totality
   but the NAMED lemma **`addrClass_ok_lt : addrClass a = .ok →
   a.toNat / 4 < 8`** — the fact that lets `step` construct the
   Vector-8 index. It is a REQUIRED M1 deliverable. Kernel
   classification boundary (⬥v1.1, fixing the U1 size clash at the
   source): `outOfRange ↔ byte_addr ≥ 32` — EIGHT words, dmem8's true
   size, NEVER the 16-word figure the existing mask would suggest
   (see §2). Responses: `ok` → read/write; `misaligned`/`outOfRange`
   → **write SUPPRESSED** (the silicon lesson: the load-bearing term
   is the suppression, not the flag), `trapped := true` (sticky), pc
   advances. No mtvec, no CSRs, no interrupts — those words do not
   appear in v1, and the "executive/OS" fence notes stay untouched.
   **⬥v1.1 — THE TRAP-SEMANTICS FENCE, written here at O7 strength
   (r-trap KC3; it goes verbatim into the `step` docstring BEFORE M1
   builds):** *"On a misaligned or out-of-range LW/SW address this
   machine suppresses the write, advances PC+4, and sets a sticky
   `trapped` flag. That is a deliberate v1 semantics, NOT RV32I —
   RV32I raises a load/store-address-misaligned or access-fault
   exception."* This is a SECOND non-conformance fence, distinct from
   the undecodable-word fence (ISA.lean:648-670), which is NOT
   retired by this block: undecodable words still advance PC+4 with
   no trap; only the two NEW ops carry arms. Say both wherever either
   fence is quoted — and carry the NUMERIC RECOMPUTE (M5): the
   decodable split moves from 99.8024%/0.1976% to **99.607%/0.3929%**
   at the five census-named sites (live-verified: ISA.lean:651 quote
   block + :664-665 table, RegWrite.lean:36,
   docs/hdl-c4-composition-check-0807.md ADDENDUM,
   docs/riscv-core-campaign-v0.md §C4).
4. **THE ENCODERS — unchanged; the plan survived refutation whole
   (r-encoder 4/4 UNFOUNDED).** `wS` built from scratch (S-type:
   imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode — verified
   against the census AND the Spike word `sw ra,0(sp)=0x00112023`) —
   it does not exist (census-verified with a control). `wI`
   GENERALIZED to take (opcode, funct3) as parameters, with BOTH
   field lemmas restated at the general form (verified: change is
   fully local to ISA.lean — every out-of-file `wI` grep hit is a
   substring false-positive). LW = I-type 0000011/010; SW = S-type
   0100011/010 (triple-sourced; no collision with the three landed
   accepting opcodes). `decode`, `stepW`, `stepT`, and
   `decode_encode` all extend; round-trip per op is a pre-registered
   control. ⬥v1.1: M2 now ALSO owns the decoder-census fixup in the
   SAME commit (see M2 — a landed `decide +kernel` theorem goes FALSE
   the moment decode accepts LW/SW; the v1 plan never named it).
5. **FETCH UNTOUCHED — option (A) exactly.** Code remains a host
   value; `run`/`runFor`/`fetch` do not change; `run_halts_off_the_end`
   survives; the fuel story of block ①'s §4 is unaffected. The census's
   recommendation lands as written: data memory only. (Verified by
   r-fences: option B stays rejected with the census's four costs.)
6. **THE EXECUTIVE INTERACTION — ⬥v1.1 RULED OPTION (A), the false
   sentences STRUCK (r-stateform Q1b, r-trap KC3b, r-exec-lang Q1 —
   the fold's first design ruling): v1 memory serves STANDALONE
   single-task `run`/`runFor` programs ONLY. The executive does NOT
   use LW/SW.** The v1 sentence "dmem8 is task 0's private scratch —
   which is exactly where the context-switch pcs go" was FALSE twice
   over and is STRUCK: the pcs live in `SysSt.pcs`
   (ExecutiveX0.lean:57), not in memory, and `SysSt.put`
   (ExecutiveX0.lean:70) writes back only regs+pc, DISCARDING any
   `St.mem`/`St.trapped` a step produced — the executive cannot
   persist a single memory word, so "private scratch" names a
   capability v1 does not have. Executive scratch requires a
   `SysSt.mem` field threaded through put/task and a re-verified
   X0/X1 — that is the **X4+ door, deferred, not claimed**. In v1,
   `St.mem`/`St.trapped` are INERT at SysSt level (structure defaults
   keep X0/X1 elaborating; `SysSt.task` rebuilds each task's St with
   default-empty mem). Also struck: "X1's landed theorem is untouched
   by this block" — the honest sentence is: **X1's theorem STATEMENTS
   are preserved** (execStep_frame :175, execStep_frame_disjoint
   :193, e4_overlap_refutes :238 — all conclude over registers,
   orthogonal to mem); the FILE is mechanically extended:
   `writesInstr` (ExecutiveX1.lean:61) and `step_frame_instr` (:96)
   gain the two arms (LW ↦ `if rd = 0 then none else some rd`,
   keeping the x0-discard guard the existing arms use; SW ↦ `none`),
   the bare St literals in `SysSt.task` (ExecutiveX0.lean:66) and
   `St.init` (ISA.lean:156) gain the two fields, and
   execStep_frame/e4 re-verify — gated by the M3 controls. The
   register-only narrowing STANDS with its verified reason: store
   targets are register-computed runtime values, so no syntactic
   `writesMemWithin` can be sound (a genuine decidability boundary,
   r-exec-lang confirmed) — task-level MEMORY partitions arrive only
   with a static-addressing discipline or the compiled executive
   (X4+, out of window): a named door, not a promise.
7. **THE LANGUAGE INTERACTION — a v2 door, not this block.** Arrays/
   spilling/`u32` indexing consume LW/SW later; nothing in L0-L4
   changes; compileE's var case stays register-based (verified at the
   live file: compileE inducts on Exp, never Instr; emitted code
   byte-identical — memory drops in BESIDE, not through). ⬥v1.1
   executor caveat (r-exec-lang Q3): `StraightLine.step_forward_pc`
   (StraightLine.lean:38) closes by `cases i` and must RE-CLOSE over
   the two new arms — semantically trivial (LW/SW fall through pc+4;
   `isForward`'s wildcard already classifies them true) but the simp
   set must reduce the SW-ok/trap arms' pc to `s.pc + 4`: make those
   arms end in `.next` (or add the pc lemma). A replay, not a design
   change.

## §1 · THE KERNEL WORK PLAN (P2 stage ②, math+compiler shared, ~3 seat-days)

⬥v1.1: M0 and M1a are NEW; M2-M5 amended. Order: M0 → M1(+M1a atomic)
→ M2 → M3/M4 → M5. Any P1-idle seat may pull per the stealing
discipline (author-anywhere, land-at-owner).

- **M0 · THE FEASIBILITY PROBE — ✅ DISCHARGED 8/10 18:31, JOINTLY
  (math + silicon as independent MEAS witness; bus :58745 carries
  the combined row): `deriving DecidableEq` handler succeeds on the
  grown St (clause form, BOTH hands) · whole-state `decide +kernel`
  FEASIBLE at ~1–1.34 s wall, **1.32 GB peak RSS at DEFAULT
  limits** (18x clear of the 24 GB kill wall that took compiler's
  batcherNetC probe — wall clock alone cannot see that wall; a
  feasibility probe reports PEAK MEMORY or it has not answered) ·
  direction-independent (controls differed at first AND last
  fields) · falsity control proved the comparison evaluated ·
  #audit_axioms clean. M1 IS UNGATED and quotes that one row.
  (Original spec follows, kept for the record; r-fences Q5's
  repair; census §6.2/§6.3 named two O(n²) walls and said "before
  anything is written").** A 3-line Scratch (unique per-agent name, never
  committed) confirming: (a) `deriving DecidableEq` survives
  `Vector (BitVec 32) 8` + `Bool` on the grown St; (b) `decide
  +kernel` stays feasible on the 1313-bit St (1056 + 256 + 1) in one
  whole-state comparison. Run through ../saltbuild.sh. If (b) is
  slow: the controls below ALREADY observe specific fields, so the
  wall is survivable — but MEASURE it before M1 writes anything.
- **M1 · THE St-ATOMIC COMMIT (⬥v1.4, RULED (i) at math's 18:56
  stop — THE BOUNDARY LAW, discovered the hard way tonight: THE
  ATOMICITY BOUNDARY FOLLOWS THE TYPE; one type growth per atomic
  commit, each with its own census. M1 SHEDS the Instr
  constructors — `decode_encode` is ∀-quantified over Instr, so a
  stub encode arm makes a landed theorem FALSE and no green
  placeholder exists; the LW/SW constructors, the two step arms,
  and every exhaustive Instr match ride the M2 Instr-atomic commit
  where the encoder already lives.)** CONTENT: `St` gains
  mem/trapped (INERT until M2 — no arm reads them); `addrClass`
  keyed at 8 words (`outOfRange ↔ byte_addr ≥ 32`) with the NAMED
  lemma `addrClass_ok_lt` (§0.3) proved beside it (its consumer
  arrives at M2 — landing def+lemma one commit early is the cheap
  direction); the trap-semantics fence text lands in the file
  docstring now and moves onto `step` at M2; St.init (ISA.lean:156)
  gains `mem := Vector.replicate 8 0, trapped := false`; PLUS ALL
  OF M1a below (same commit). Every one of tonight's five censuses
  is St-side: this commit is specified to the line, buildable, and
  is the single-hand atomic landing the 18:47 ruling directs. The
  arm-inhabitance controls move to M2 with the arms they witness.
- **M1a · THE STATECODEC + EXECUTIVE RECONCILIATION (NEW — ATOMIC
  with M1, same commit or the hub red-builds; r-stateform Q1's
  repair, live-verified pins).** (1) `decQ` (StateCodec.lean:127) and
  `decQtransposed` (:175) construct the new fields as defaults.
  (2) **`decQ_encD` (StateCodec.lean:140) is RESTATED TWICE —
  ⬥v1.5.1 FINAL NAMES (ruled 19:5x, the restatement-renames law):
  the projection headline is `decQ_encD_proj` — the OLD NAME
  `decQ_encD` CEASES TO EXIST so every pre-tonight citation fails
  loudly rather than resolving to a changed meaning; the
  conditional whole-St form keeps `decQ_encD_of_clean` —
  ⬥v1.1.1, per math's 18:40 pre-pull consumer census (bus :59027),
  which found the v1.1 consumer list SHORT BY THREE and one consumer
  unrepaira­ble by the projection alone.** The HEADLINE form is the
  (regs,pc)-PROJECTION: `(decQ (encD s)).regs = s.regs ∧
  (decQ (encD s)).pc = s.pc` — the whole-St form goes FALSE in
  general and extending encD to 1313 bits reopens the flop budget
  and contradicts the F4 two-object bridge. BESIDE it lands the
  CONDITIONAL whole-St round trip, `decQ_encD_of_clean :
  s.mem = Vector.replicate 8 0 → s.trapped = false →
  decQ (encD s) = s` — true for every state this codec is ever fed
  in the Stack lane, because `stOfFn`/`offEndEnv` build exactly such
  states BY CONSTRUCTION. Proof shape: `obtain ⟨regs, pc, mem, tr⟩
  := s`; `St.mk.injEq` is now 4 conjuncts — **and the two
  RECONSTRUCTION sites in the same proof (`encD ⟨regs, pc⟩` at
  StateCodec.lean:142 and :150) gain the two fields too (⬥v1.1.3,
  math's shape census: patching the `obtain` alone fails three
  lines below the edit). FALSE-POSITIVE FENCE (same census, the
  expensive direction): the `{ regs := …, pcs := …, cur := … }`
  literals at ExecutiveX0.lean:153 and ExecutiveX1.lean:217 are
  `SysSt`, NOT `St` — same field NAME, different type. DO NOT
  TOUCH: adding mem/trapped to SysSt is precisely the capability
  §0.6 STRUCK; a sweep that "repairs" all six regs-literals
  re-introduces the ruled-out design through the back door.**
  `decQtransposed`'s
  theorem (:186) restates freely — ZERO consumers outside StateCodec
  (math's census). (3) `SysSt.task` (ExecutiveX0.lean:66) gains
  default mem/trapped (sufficient BECAUSE of the §0.6 ruling: the
  executive does not use memory). (4) **THE WORK LIST, WITH ITS
  UNITS STATED (⬥v1.1.2, closing the math/silicon census delta — a
  count is not a scope): FOUR direct tactic-level consumers of
  `decQ_encD` (silicon's unit — :1231/:1252/:1264/:1494, three hands
  agree) + ONE decQ-SHAPE consumer = FIVE work items (math's unit);
  v1.1 named two and the atomic commit could not have closed.**
  The direct four: **`decQ_envWith` (:1491 statement, :1494 exact) —
  ⬥v1.2, RE-CLASSED at math's 18:49 pre-start find (bus :59395):
  NOT a "generalizes" leaf but a HUB of the headline's own kind —
  `decQ (envWith s w) = s` is a whole-St equality that goes FALSE
  for non-clean s after M1a, with NINETEEN tactic-level consumer
  sites (:1521…:5822, enumerated on the bus). It RESTATES as
  `decQ_envWith_of_clean` (hypothesis: mem = replicate 8 0 ∧
  trapped = false), expected to serve all nineteen with the
  hypothesis discharged definitionally — the six St.init sites gain
  the defaults from M1's own edit, and decQ-built/stepT states are
  clean by M1a(1) + with-updates. THE (a)-READ IS EXECUTED (math
  18:50-18:51, ⬥v1.3): NINE sites instantiate clean and take
  `_of_clean` · TEN are ∀-quantified over arbitrary St (the per-op
  field theorems :2789…:5822) and take THE (A)-FORM RULED 18:5x —
  PER-CONSTRUCTOR projection facts, NO predicate: for each of the
  five slice-A arms, `(step s i).regs`/`.pc` depend only on
  `s.regs`/`s.pc` — DEFINITIONAL per arm (every arm is
  `.set`/`.next`/`.get` with-updates; five tiny lemmas or inline
  simp, whichever reads better per site; one rewrite each). RULED
  AGAINST (B) (a `¬touchesMemory` predicate lemma): the ten
  consumers each need exactly their own arm's fact — a quantified
  form has no consumer today, and its predicate is a hand-maintained
  interface every future op author must keep true (the
  mirror-constant class, paid twice today). THE DOOR, NAMED: when a
  future op family wants the quantified form, its author states
  `step_projEq_of_memFree` WITH its live consumer; the ten sites do
  not move. CONTROL (house mutation law, pre-registered): the
  per-arm scoping must be FALSE outside the five — witness at M1:
  two states equal on regs/pc differing at a loaded mem word make
  the LW arm's projection-congruence FALSE (LW writes rd from mem).
  FACT SETTLED BY THE READ, no ruling needed: every slice-A arm
  PRESERVES mem/trapped (with-update shape) ⇒ "clean" propagates
  through arbitrary slice-A runs with zero extra lemmas. Any
  further dirty site is a same-grade census finding and reopens
  this row.** · `entryLoaded_encD_stOfFn` (:1231) and
  `not_entryLoaded_offEndEnv` (:1252) land only on .pc/.get, so the
  projection suffices — at a TACTIC EDIT each (`rw [decQ_encD]`
  stops working on a conjunction; budget the `.1`/`.2` plumbing) ·
  **`offEndEnv_does_not_sort` (:1264) rewrites the WHOLE STATE under
  `run` — the projection deletes its first step; it rewrites with
  `decQ_encD_of_clean` instead** (offEndEnv is clean by
  construction). The FIFTH work item is NOT a `decQ_encD` consumer:
  `decQ_congr` (:1481) assumes two-field `St.mk.injEq` injectivity —
  r-stateform's original find — and generalizes under this same
  node. The prose at :1226 and :1800 describing the round
  trip as an identity is REWORDED to "identity on clean states;
  projection in general". (5) Control: full-hub build green +
  `#print axioms` on BOTH restated lemmas within the standing three.
  **[CENSUS CLOSURE REASON + LIMIT (math 18:47; annotation, spec
  unchanged): the four swept classes are exactly the constructions
  that NAME the field list (literal · injEq · destructure · St.mk);
  every other path is a `with`-update or delegates to one, copying
  unnamed fields — so the census is re-derivable, not just swept.
  "offEndEnv is clean by construction" is TRACED to bytes: stOfFn =
  St.init + .set chains, all `with`-updates, so
  `decQ_encD_of_clean`'s hypothesis discharges at :1264 by
  definitional unfolding. NAMED LIMIT: an St-valued literal built
  where the sweep did not look hides from all five paths — the
  BUILD is the oracle; after growing St, read the error list and
  treat any site outside this node's list as a census finding, not
  a nuisance.]**
- **M2 · THE Instr-ATOMIC COMMIT (⬥v1.4 — this commit now carries
  EVERYTHING the Instr growth forces, per the boundary law): the
  LW/SW CONSTRUCTORS + the two `step` arms (with the arm-inhabitance
  `decide` controls observing SPECIFIC fields — mem[a]/trapped, the
  ISA.lean:196-198 discipline, aligned-out-of-range witness per §4 —
  and the trap fence moving onto `step`'s docstring) + `wS` +
  generalized `wI` + field lemmas + `decode_encode` for LW/SW
  (ISA.lean) + **the exhaustive-match arms PULLED FORWARD from M3's
  scope because the type forces them: `writesInstr` (LW ↦ `if rd =
  0 then none else some rd`, SW ↦ none) and `step_frame_instr`'s
  two arms (ExecutiveX1.lean — math's file rides the same commit)**.
  ENTRY CONDITION: the Instr MATCH CENSUS (math 18:56, bus :59665):
  exhaustive sites = step (ISA:120) · encode (ISA:549) · writesInstr
  (ExecutiveX1) — all three repaired IN this commit; StraightLine
  and Program carry catch-alls and are SAFE (verify at write time);
  NO STUBS EVER (`decode_encode` refutes them). Assignment decided
  at the pull (spans ISA + ExecutiveX1: single-hand again, or a
  compiler+math patch-to-owner pair — the puller proposes). PLUS,
  IN THE SAME COMMIT, the
  decoder-census fixup (all three refuters' unassigned kill;
  live-verified pins):** (a) delete the lw (0x00012083, :536) and sw
  (0x00112023, :537) rows from `sliceAExcluded`
  (SpikeVectors.lean) — KEEP lb/sb (funct3=000, still rejected under
  word-only v1); (b) `slice_a_excluded_size` 22 → 20 (:594);
  (c) re-verify `slice_a_excluded_rejected` (:578) and
  `rejected_disjoint_from_suite` (:589) over the remaining rows.
  **⬥v1.1 RULING (the fold's third design ruling): lw/sw do NOT
  enter the witnessed differential suite in v1** — that requires the
  `Vec` format (Vectors.lean) to gain memory columns, which is the
  differential harness's own campaign (the census's "critical path
  nobody is looking at"). It is a NAMED DOOR ("Vec-memory-columns"),
  scheduled at the harness's seam, not silently absorbed here.
  Controls: round-trip per op; the swapped-imm-fields wS mutant must
  FAIL it (a valid false-making control, r-encoder verified).
- **M3 · The register-file frame extension — ⬥v1.4: the
  `writesInstr`/`step_frame_instr` ARM ADDITIONS moved INTO M2 (the
  type forces them); M3 keeps the CONTROLS and the theorem work
  (math owns; ExecutiveX1.lean).** LW's arm keeps the x0-discard
  guard, SW ↦ `none` (landed at M2, verified here);
  (`step_frame_instr`'s LW arm needs an addrClass split);
  X1's statements re-verify. **Controls (⬥v1.1, r-fences Q3's
  repair):** the load-bearing one is the **E-4 ANALOGUE WITH LW**:
  task-B program `[LW rd=1 <addr>]` writing the overlap register —
  the register-WRITING new op stressed as a false-making isolation
  control. The v1 "E-4 re-run with SW" control is KEPT but DEMOTED to
  a trivial writesWithin-pass regression, and its scope is LABELED:
  it validates the register frame ONLY (SW writes no register, and
  SysSt.put discards mem — it cannot and does not exercise any
  executive memory effect; r-exec-lang U3).
- **M4 · The memory frame rows (math owns).** SW-ok writes exactly
  `mem[a/4]`; LW writes no memory; and the suppression theorem
  **⬥v1.1 RESTATED (r-fences' internal-consistency kill): "a trapped
  step changes NO MEMORY CELL and NO REGISTER"** — never "writes
  nothing" (a trapped step DOES set `trapped := true` and advance pc;
  the literal form would be a false theorem). **The mutant discipline
  (r-trap KC2 — the house mutation law applied):** the
  write-in-the-trapped-arm mutant must COMPILE (use the total
  `Vector.setD`/truncating-index form — a non-compiling mutant is not
  a control) and must FALSIFY M4 on the pre-registered witness:
  **MISALIGNED-AND-IN-RANGE** (byte addr 5 → word 1 < 8, with
  `mem[1] ≠ get rs2` so the write is observable). The OUT-OF-RANGE
  arm is DECLARED free-by-typing in the kernel (Vector 8 has no slot
  ≥ 8 — with setD the mutant write is a no-op and would PASS
  SPURIOUSLY; one misaligned mutant must not stand in for both arms)
  — its real control lives at the F4 bridge (§2): the RTL
  `~out_of_range` we_out gate relates to the kernel `addrClass = .ok`
  guard, with a dropped-gate RTL mutant at stage ③.
- **M5 · `stepT`/word-level lift extension + the audit sweep
  (shared); `runW_map` re-verified over the grown instruction set.**
  ⬥v1.1 additions: the NUMERIC RECOMPUTE at the five §0.3 sites
  (99.8024%/0.1976% → 99.607%/0.3929%; the census's
  number-propagation warning is the reason it is an explicit node);
  and the whole-St `decide +kernel` suites (`suite_full`,
  `spike_agrees`) gain 257 zero-bits per vector — pre-register a
  build-time probe BEFORE the audit sweep rather than assume the
  +25% scales (r-stateform's minor watch).

## §2 · SILICON (P2 stage ③, update-window scoped — NOT September-gating)

⬥v1.1 — **THE MASK IS RE-RULED (the fold's second design ruling; the
U1 kill, found independently by r-trap and r-exec-lang): dmem8 does
NOT pair with dmem_addr16.** The existing mask is sized for SIXTEEN
words (`out_of_range = |byte_addr[31:6]` → fires only ≥ 64;
`word_index = byte_addr[5:2]` → 4 bits), so byte addresses 32-63 pass
as in-range and ALIAS onto dmem8's 8 slots when the top index bit is
dropped — and the kernel's 8-word `outOfRange` (≥ 32) would DISAGREE
with the RTL's (≥ 64), making F4's equivalence false as cited.
**Stage ③ AUTHORS `dmem_addr8`** (`out_of_range = |byte_addr[31:5]`,
`word_index = byte_addr[4:2]`, 3 bits — the same 14-cell shape,
re-priced trivially) rather than resizing the fabbed-shape organ to
16. Integration: dmem8 + dmem_addr8 behind the kernel landing; the F4
equivalence theorem is the stage's exit criterion, imported-netlist
pattern. **F4 bridge facts the fold pre-registers (r-trap's enum-vs-
bits kill):** the RTL carries `misaligned` and `out_of_range` as TWO
INDEPENDENT bits (a both-bad address sets both); the kernel enum
forces a priority. The bridge therefore relates the RESPONSE (we_out
suppressed + trap raised), not the class label, and states explicitly
that **both trap arms produce the identical response** — else it
relates non-corresponding objects. Stage-③ exit controls: the
dropped-gate RTL mutant (`we_out = we_in & req`) with an out-of-range
witness whose wrapped slot differs — the mutant the RTL's own header
names as load-bearing. No submission artifact changes until the
Captain's word — the update window is the venue.

## §3 · WHAT THIS BLOCK DOES NOT DO (the fence list, pre-registered)

No bytes/halfwords · no unified memory (option B stays REJECTED with
its four costs) · no traps beyond the two memory arms (no CSR, no
mtvec, no interrupt, no privilege) · **no executive use of LW/SW —
v1 memory is standalone-program memory (X4+ door)** · no task-level
memory isolation claim · no language-surface change · no "the
silicon" sentence before F4's theorem · no retirement of the
total-is-not-conformant fence · **the trap-semantics fence (§0.3)
rides beside it — two distinct non-conformances, both named
wherever either is quoted** · no lw/sw rows in the witnessed
differential suite (the Vec-memory-columns door).

## §4 · CONTROLS ROSTER (all pre-registered here, before any wave)

M0 feasibility probe (DecidableEq + 1313-bit decide, gates M1) ·
arm-inhabitance ×3 (decide witnesses observing SPECIFIC fields; the
outOfRange witness must be **ALIGNED-out-of-range** — byte 32 = word
8 — or the classifier's priority order absorbs it into misaligned
and the arm is never witnessed; r-trap KC1c) · write-suppression
mutant in the total setD form, falsifying witness
misaligned-AND-in-range (byte 5) · out-of-range arm: free-by-typing
DECLARED, controlled at the F4 bridge (stage ③ RTL mutant) · encoder
round-trips ×2 + swapped-imm mutant · E-4 analogue with LW writing
the overlap register (the false-making isolation control) + SW
writesWithin regression (register-frame-only, labeled) · `addrClass`
totality is by construction AND the named `addrClass_ok_lt` lemma
carries the actual safety load (the "no default" slogan is retired) ·
numeric-recompute sweep at the five named sites (M5) · **the audit
form is the BUILD-GATED `#audit_axioms` ROLL-CALL, not a manual
`#print axioms` (⬥v1.5, compiler's first-refuter check-4 find on
M1's own landing: two declarations landed with NO audit line, and
an ABSENT audit is SILENT — a green build is exactly as green
without it; hygiene is EXIT=0 PLUS roll-call inclusion, verified by
grep of the roll-call, never inferred from the print). EVERY new
declaration of every M-node enters a roll-call in the same commit —
M2 adds many and inherits this line.**

## §A · THE FOLD RECORD (v1 → v1.1, 2026-08-10 ~18:2x, night maestro, Fable hand)

**Verdict inventory: 22 questions + 11 unassigned kills across 5
refuters (r-stateform, r-trap, r-encoder, r-exec-lang, r-fences); all
5 overall REPAIR-THEN-FIRE; 0 CONFIRMED-FATAL. Disposition: 13
UNFOUNDED (the design held; 4 of those carried precision riders, all
folded), 9 CONFIRMED-REPAIRABLE (all repaired above), 11 kills folded
(3 were the same slice_a_excluded find, 2 the same U1 mask find).**

- **Struck sentences (v1 claims that were FALSE):** "dmem8 is task
  0's private scratch / where the context-switch pcs go" (§0.6 —
  unrepresentable in v1: SysSt.put discards mem); "X1's landed
  theorem is untouched" (§0.6 — statements survive, the file does
  not); "a match, not a default" (§4 — addrClass necessarily ends
  `else .ok`); M4's "trapped step writes NOTHING" (it sets the flag
  and advances pc). Each replaced in place above.
- **Design rulings made at the fold (Fable tier):** ① executive
  interaction = option (a), standalone-only, X4+ door (the smaller,
  v1-honest repair — both r-stateform and r-trap converged on it);
  ② stage ③ authors dmem_addr8, kernel outOfRange keyed ≥ 32 from M1
  onward; ③ lw/sw witnessed-suite entry deferred behind the named
  Vec-memory-columns door.
- **New obligations the plan gained:** M0 (feasibility probe, gates
  M1) · M1a (StateCodec/Executive reconciliation, atomic with M1) ·
  the trap-semantics fence at O7 strength · `addrClass_ok_lt` as a
  named deliverable · the decoder-census fixup inside M2's commit ·
  the five-site numeric recompute in M5 · the F4 response-level
  bridge facts + stage-③ RTL mutant.
- **Pin hygiene:** refuter-cited pins were cross-checked against the
  live tree at fold time; drifted ones (decQ_encD :97→:140,
  slice_a_excluded_rejected :558→:578, slice_a_excluded_size
  :574→:594, rejected_disjoint_from_suite :569→:589, decQ_congr
  :1484→:1481) are printed at their live values above. Executors:
  re-verify pins at YOUR read time — this file's pins were true at
  fold time, and files grow above cited lines (the week's three-for-
  three lesson).
- **What the refuters confirmed intact (no change needed):** the
  encoder plan whole (4/4) · fetch-untouched/option-A · the
  register-only narrowing's decidability reason · the no-silicon-
  sentence fence discipline · trapped:Bool harmless to landed
  invariants · pc-advance-on-trap contradicts nothing landed ·
  the L0-L4 non-interaction (one replay caveat, §0.7).

**REFUTER PASS: POSTED AND FOLDED. P2 ② IS OPEN — M0 is the first
pull (any P1-idle seat), then M1+M1a per the stealing discipline.**

## §B · ⬥v1.6 — THE M2 AMENDMENT (2026-08-11 ~17:0x–17:1x, math hand, four helm rulings)

**M2 landed as ONE atomic commit and grew four times while landing. Every
growth was the same discovery in a different layer: a CORRESPONDENCE CLAIM
THAT WAS TRUE OF A MEMORY-LESS MACHINE.** Nothing here was a proof
difficulty; all four were statement-level, and all four were found before or
by the type-checker rather than by review.

### B.1 · THREE PREDICTED-AND-FIRED CONTROLS, NOW DISPOSED

*A control that fires and is never disposed is a stale pointer with teeth.*

1. **M1a's per-arm scoping control — FIRED, AS WRITTEN.** M1a said: *"the
   per-arm scoping must be FALSE outside the five — two states equal on
   regs/pc differing at a loaded mem word make the LW arm's
   projection-congruence FALSE."* It did. **Disposition:** five landed
   theorems were false under M2, not unproved, and were RE-CUT as conditional
   frame laws under new names with `touchesMem` as the discriminator
   (`step_mem_frame_of_not_touchesMem`, `step_trapped_frame_of_not_touchesMem`,
   `step_regs_of_with_of_not_touchesMem`, and the two `stepT` twins).
   `step_pc_of_with` SURVIVED unchanged — `pc` never depends on memory.
   Positive complements landed beside them (what SW writes, what LW reads,
   what a trapped step suppresses).
2. **§0.2's F4 two-object PRICE — CAME DUE, NOW MARKED PAID.** §0.2 recorded
   that *"the ISA step and the hardware step stop being the same function"*
   and that the codec covers **(regs, pc) ONLY**. Under M2 that stopped being
   a note and became a false theorem: `CycleRealisesStep`'s whole-`St`
   equality is **UNSATISFIABLE** once `stepT` can store, because `decQ`
   constructs `mem := replicate 8 0` for every `cyc`. **Disposition:** re-cut
   to `CycleRealisesStepProj` (the `_proj` house form, after
   `decQ_encD_proj`), with `decQ_cycOf_proj` and
   `cycleRealisesStepProj_of_bits`. **Kernel-checked refutation of the old
   form** on the witness `envWith (St.init.set 1 5) (encode (SW x0,x1,0))`:
   ISA side `mem[0] = 5`, cycle side `mem[0] = 0`.
3. **The `sliceAExcluded` EXPIRY — FIRED ON SCHEDULE.** `SpikeVectors.lean`
   predicted (8/7, math seat) that *"the day loads land in Slice A this
   theorem goes FALSE, breaking the build — that is the correct behaviour."*
   It broke the build on the day, unprompted. **Disposition:** the two
   word-sized rows deleted, `slice_a_excluded_size` 22 → 20; `lb`/`sb` KEPT
   (v1 is word-only). *Nobody had to remember.*

### B.2 · THE FOURTH FINDING — COMPOSITION IS AN EDGE

**The projection is sound for ONE step and does NOT compose.** A store is
invisible to `(regs,pc)`; a later load reads what it left and writes a
REGISTER, so the divergence lands *inside* the projection two cycles in.
⇒ `cycles_realise_steps` gains a **MEMORY-FREE-STREAM hypothesis**
(`∀ i, decode w = some i → ¬ touchesMem i`, as `MemFree`) and is renamed
`cycles_realise_steps_of_memFree`; `cycles_sort`, `sorts_of_C4` and
`sorts_of_fieldwise` thread it. *It discharges by `decide` on any slice-A
stream, which is every stream the compiler emits.*

### B.3 · THE CONTROL PLANE — a kernel/silicon divergence, stated as a theorem

`Decoder.ctrlSpec` matches on `Option Instr`, so **both** the math and
compiler blast-radius censuses missed it and the BUILD caught it. The v1
control word is five op-class bits plus `valid`; `dcMatches` has five rows;
**there is no bit for a memory op and no gate matching its opcode.**
⇒ `ctrlSpec`'s DEFINITION is unchanged and its DOCSTRING re-cuts to slice-A
scope; the divergence lands as
**`ctrlSpec_not_decoded_of_touchesMem`**. The 2048-point plane certificates
survive — *they now certify that this core does not implement these ops.*

### B.4 · ⛔ STAGE ③'s COMMISSIONED DOORS — NOW **THREE**, one price

```
1  dmem8 / dmem_addr8      the organ + the F4 equivalence theorem  (was §2)
2  THE MEMORY CONTROL PLANE port, decode rows, control bits — the datapath
                           this core does not have  (NEW, ⬥v1.6)
3  THE n-STEP MEMORY BRIDGE what discharges MemFree for streams that DO touch
                           memory; until it lands, memory realisation is
                           hypothesised, never claimed  (NEW, ⬥v1.6)
```
**No kernel sentence may say memory "rides on the die" until all three land.**

### B.5 · THE METHOD NOTES THE WAVE BOUGHT

- ***A theorem red because it is FALSE and one red because it is UNPROVED are
  the same line in a build log.*** Only pre-build witnesses tell them apart.
- ***A type's blast radius is what matches on the type OR ON ANYTHING
  CONTAINING IT.*** The wrapper (`Option T`) is where a census dies — it
  killed two independent censuses within one hour.
- ***A transitive closure over one edge type is not the closure: composition
  is an edge.*** Walking "consumes the lemma" missed "consumes the predicate".

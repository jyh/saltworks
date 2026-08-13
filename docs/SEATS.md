# saltworks — seat ownership (the writer-slot law)
Slots are keyed by SEAT, never by account (accounts rotate across relights;
seats do not). "Who is writing this file right now?" is answered by bus
announcement plus the tree — never by this list. This file records
boundaries, not state (the 8/7 lesson: every value written here rotted;
no glob did).
- SaltWorks/Banyan/**   : MAESTRO seat. Read-only to others.
- SaltWorks/HDL/**      : COMPILER seat — leg 2, the verified circuit DSL → Verilog compiler.
- SaltWorks/Silicon/**  : SILICON seat — leg 3, the flow, the netlist importer, equivalence.
- SaltWorks/Stack/**    : MATH seat — the stack campaign's spec + proof lane. Read-only to others.
- SaltWorks/Certs/**    : COMPILER seat — the comprehensibility-cert layer (docs/cert-layer-design-0811.md).
  The block permits Opus executor waves on the A/B rows: executors DRAFT AND VERIFY ONLY, in scratch;
  this seat lands every file and its roll-call row. One writer, many drafters — the glob is CLAIMED,
  not shared (silicon's 12:48 boundary line: two kinds of hand need a declared owner before the first write).
- SaltWorks/Tactic/**   : MAESTRO seat (council ruling 8/12, at compiler's unowned-glob flag) —
  REFEREE INFRASTRUCTURE: the audit tactic must not be owned by any seat whose work it audits.
  Same law governs salt's Salt/Tactic/**; changes by consult, as with root wires. 13 importers
  across 4 slots at ruling time.
- SaltWorks.lean, lakefile.toml, lean-toolchain : MAESTRO ONLY. Seats leave "import owed: <module>" in commit messages; maestro sweeps.
- docs/** : append-friendly; per-seat files preferred (docs/<seat>-*.md).
- EXCEPTIONS (named, dated, removed on expiry — an exception recorded is the law consulted):
  - ⬥ RECORDED, NOT CLAIMED — the D2 cross-slot grant is SPENT and its marker is retired here.
    Helm ruling 2026-08-12 17:15, re-scoped 17:31 from a LIST to the REGION `Stack/Program.lean`
    8000-8650: compiler landed D2 atomically at `fb3842a` because `decoder_outs_eq` goes FALSE the
    instant `dcMatches` grows in the compiler's own file, so no compiler-half could land green.
    Slot owner (math) verified the boundary independently and verified containment after the fact:
    13 hunks, all inside the granted region, nothing in that file outside it. **Ownership of
    `Stack/Program.lean` is unchanged after this commit.** *Kept as a record and not as a grant,
    because the next cross-slot case needs the precedent — and because the grant's own scope had to
    be widened once when the enumeration that justified it was measured too small (22 named vs 31
    swept), which is the part a later reader will need.*
  - ✅ SPENT — the catch-all pre-grant on `HDL/ISA.lean` + `HDL/StraightLine.lean` is retired, and
    **BOTH its targets are converted, so nothing live survives this deletion.** *`isForward` →
    exhaustive arms earlier, by the owner's own hand, so the grant was never exercised.
    `touchesMem` → exhaustive arms at `HDL/ISA.lean:183` in `fb3842a`: **D2 WAS the "next touch"
    the disposition named**, taken in this seat's own file under the standing disposition and
    using no exception.* ⚠️ **Stated as the CURRENT reading rather than as the sweep instruction
    said it, which described `touchesMem` as still a catch-all at `:171` — true when written at
    ~17:28 and falsified by the landing ~19 minutes later.** *An instruction written to stop a
    live obligation being erased had itself gone stale first; the disposition is a figure, and
    figures get read at the bytes.*
  - ✅ SPENT — `HDL/ISA.lean` → MATH, for ONE ADDITIVE control (nonzero-base / negative-immediate
    addressing witness). Stayed additive as granted: three new theorems, zero existing statements
    touched.
  - ✅ SPENT — `HDL/ISA.lean` → THE M2 HAND, expiring at M2's landing. `decode_encode` is
    ∀-quantified over `Instr`, so splitting the new constructor across two seats would have opened
    a window with a new arm and an unproved `decode_encode`; atomicity beat slot purity.
  - ⬥ RECORDED, NOT CLAIMED — M2's atomic commit also touched FOUR files outside math's slot, each
    because the `Instr` growth made a landed statement FALSE there and green-on-main is absolute:
    HDL/Decoder.lean (ctrlSpec + the guard theorem, helm ruling 17:07) · HDL/StraightLine.lean
    (step_forward_pc's dite replay, predicted by the memory block §0.7) · HDL/SpikeVectors.lean (the
    decoder-census fixup the block commissioned INTO this commit) · HDL/CompileS.lean (a docstring
    citing two retired theorem names — the obligation compiler registered at 17:08 and which no
    build could catch). **All four were bus-escalated and helm-ruled before the edit; none was taken
    on math's own authority.** Ownership of all four is unchanged after this commit.
- Discipline: commit small + `git pull --rebase` before every push; unique Scratch<SEAT>.lean; judge only your own final full build; flags-style honesty in docs/LEDGER.md (append-only).

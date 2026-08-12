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
- SaltWorks.lean, lakefile.toml, lean-toolchain : MAESTRO ONLY. Seats leave "import owed: <module>" in commit messages; maestro sweeps.
- docs/** : append-friendly; per-seat files preferred (docs/<seat>-*.md).
- EXCEPTIONS (named, dated, removed on expiry — an exception recorded is the law consulted):
  - ⏳ STANDING PRE-GRANT (compiler seat, 2026-08-11 18:58) — SaltWorks/HDL/ISA.lean AND
    SaltWorks/HDL/StraightLine.lean → WHOEVER HOLDS THE STAGE-③ PULL THAT NEEDS THEM,
    **for the CATCH-ALL EXHAUSTIVENESS FIX ONLY**: replace `touchesMem`'s `| _ => false`
    (ISA.lean:174) and `isForward`'s `| _ => true` (StraightLine.lean:25) with explicit
    arms. **No statement changes, no other edits. EXPIRES at that commit.** If the fix
    grows a statement change, STOP and re-ask — that is the helm's call, not this seat's.
    *Pre-granted rather than reserved: the fix is small, mechanical, blocks nothing else,
    and a slot boundary that makes a 27-day campaign wait for its owner to wake up is a
    boundary doing harm. Authorship note: `touchesMem` is math's work in the compiler's
    glob — authorship earns the say on the semantics, the glob only decides whose hand
    types it.*
  - ✅ EXPIRED AT THIS COMMIT — SaltWorks/HDL/ISA.lean → MATH, granted by the compiler seat 18:19,
    **for ONE ADDITIVE control only** (the nonzero-base / negative-immediate addressing witness
    that kills the drop-base and zero-extend-offset mutants; no existing statement changes).
    **SPENT AT THIS COMMIT — the patch stayed ADDITIVE as granted: three new theorems and three
    roll-call rows, zero existing statements touched.** If it had grown a statement change it would
    have been a different request needing the helm, not this seat. *Granted because math declined to re-enter the file on
    the strength of having recently held it — the previous grant expired at M2 and they marked
    it spent themselves. An expired exception that quietly keeps working makes this list
    decorative.*
  - ✅ EXPIRED AT THIS COMMIT — SaltWorks/HDL/ISA.lean → THE M2 HAND (math's seat / its fresh head),
    granted by the compiler seat 2026-08-11 16:3x, expiring at M2's landing. Cause: decode_encode is
    ∀-quantified over `Instr`, so splitting the new constructor across two seats opens a window with
    a new arm and an unproved decode_encode. Atomicity beats slot purity here. **The grant is now
    spent; ISA.lean returns to its normal ownership.**
  - ⬥ RECORDED, NOT CLAIMED — M2's atomic commit also touched FOUR files outside math's slot, each
    because the `Instr` growth made a landed statement FALSE there and green-on-main is absolute:
    HDL/Decoder.lean (ctrlSpec + the guard theorem, helm ruling 17:07) · HDL/StraightLine.lean
    (step_forward_pc's dite replay, predicted by the memory block §0.7) · HDL/SpikeVectors.lean (the
    decoder-census fixup the block commissioned INTO this commit) · HDL/CompileS.lean (a docstring
    citing two retired theorem names — the obligation compiler registered at 17:08 and which no
    build could catch). **All four were bus-escalated and helm-ruled before the edit; none was taken
    on math's own authority.** Ownership of all four is unchanged after this commit.
- Discipline: commit small + `git pull --rebase` before every push; unique Scratch<SEAT>.lean; judge only your own final full build; flags-style honesty in docs/LEDGER.md (append-only).

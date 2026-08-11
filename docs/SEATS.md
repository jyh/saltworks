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
  - SaltWorks/HDL/ISA.lean → THE M2 HAND (math's seat / its fresh head), granted by the compiler seat
    2026-08-11 16:3x, EXPIRES AT M2's LANDING. Cause: decode_encode is ∀-quantified over `Instr`, so
    splitting the new constructor across two seats opens a window with a new arm and an unproved
    decode_encode. Atomicity beats slot purity here. The compiler seat is on SaltWorks/Certs/** and
    then CompileS.lean (the ite emitter) — neither touches ISA.lean.
- Discipline: commit small + `git pull --rebase` before every push; unique Scratch<SEAT>.lean; judge only your own final full build; flags-style honesty in docs/LEDGER.md (append-only).

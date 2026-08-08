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
- SaltWorks.lean, lakefile.toml, lean-toolchain : MAESTRO ONLY. Seats leave "import owed: <module>" in commit messages; maestro sweeps.
- docs/** : append-friendly; per-seat files preferred (docs/<seat>-*.md).
- EXCEPTIONS (named, dated, removed on expiry — an exception recorded is the law consulted):
  - 2026-08-07: SaltWorks/HDL/AluSelect.lean writable by the MATH seat for the
    ALUSEL-PARAM node only; expires on that node's landing (maestro ruling on
    compiler's recommendation, bus 22:15).
- Discipline: commit small + `git pull --rebase` before every push; unique Scratch<SEAT>.lean; judge only your own final full build; flags-style honesty in docs/LEDGER.md (append-only).

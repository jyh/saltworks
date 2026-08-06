# saltworks — seat ownership (the writer-slot law)
- SaltWorks/Banyan/**   : maestro (silicon-acct). Read-only to others.
- SaltWorks/HDL/**      : compiler-acct — leg 2, the verified circuit DSL → Verilog compiler.
- SaltWorks/Silicon/**  : jason — leg 3, the flow, the netlist importer, equivalence.
- SaltWorks.lean, lakefile.toml, lean-toolchain : MAESTRO ONLY. Seats leave "import owed: <module>" in commit messages; maestro sweeps.
- docs/** : append-friendly; per-seat files preferred (docs/<seat>-*.md).
- Discipline: commit small + `git pull --rebase` before every push; unique Scratch<SEAT>.lean; judge only your own final full build; flags-style honesty in docs/LEDGER.md (append-only).

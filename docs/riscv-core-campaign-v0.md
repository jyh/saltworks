# THE VERIFIED CPU — RV32I campaign freeze v0
### Maestro, night of 8/6→8/7. STATUS: DRAFT — refuter passes at the 07:00
### council; all five seats invited to kill it. The Captain's order, verbatim:
### "go for the gold, an entire cpu, verified" / "do the cpu, verified."
### Supersedes D6's "datapath, never say core" scoping BY THE CAPTAIN'S WORD.

## Objective

An RV32I core — **entire, and verified**: specified in Lean, built in the
proven chain, its fabricated netlist equivalence-checked against the spec,
**≤ 3 axioms end to end**. Single-cycle v1; pipeline is a later campaign,
not a v1 promise. Tape-out on the next TinyTapeout shuttle after TTSKY26c
(exact shuttle read at the site when we get there — no remembered dates).

## The chain — every brick already landed

```
ISA spec (Instr / St / step)          compiler seat — IN FLIGHT tonight
  → core as Circ (leg-2 DSL)          sequential extension LANDED (Seq)
  → emitN                             emitN_sem LANDED (T2, 3 axioms)
  → LibreLane / TT CI → netlist       flow proven on the fabric (D4/D5)
  → importer + cell models            silicon's chain; trusted base = 22
                                      expansions (stated at TRUE size)
  → per-cone decide +kernel           THE CAPTAIN'S FLOP TREATMENT:
    at register boundaries            Q-pins as leaves, D-pins as roots
  → composition by cycle induction    the measured sequential pattern
```

The fabric proved this chain works. The CPU proves it scales. Nothing in
the chain is new; only the design on top of it is.

## Deliverables (each independently shippable)

- **C0 — THE SEAM CENSUS, BEFORE ANYTHING ELSE FREEZES.** Every interface
  in the chain named with BOTH sides' actual Lean identifiers,
  grep-verified at the tree. Tonight's law, paid twice today: the far
  side must EXIST before a freeze about it means anything (silicon's R1
  on the codegen freeze found `step`/`Instr`/`St` absent — that census
  cost one grep; discovered post-build it costs a week).
- **C1 — the ISA triple**: `Instr` (RV32I; v1 exclusions in R5 below),
  `St` (32×32-bit regfile, PC, memory interface), `step : St → Instr → St`
  — pure, total, executable. Owner: compiler (elevated 20:31, keystone).
- **C2 — golden vectors**: `step` exercised against an external test
  suite (riscv-tests subset or equivalent — council item: which suite,
  read at source). A spec nobody ran is a spec nobody checked.
- **C3 — the core in Circ**: datapath + control, single-cycle; regfile as
  flop array. The flop treatment applies from the first line: the
  per-cone census (widths, counts) is C3's FIRST artifact, before any
  proof is attempted.
- **C4 — compile correctness**: `sem (emitN (compile core)) = step` —
  **"the compiler, verified," the council's headline.**
- **C5 — flow + re-import**: the netlist through the flow; per-cone
  equivalence at flop boundaries; MUTATION CONTROLS that make the goal
  FALSE (inject a decode bug; the checker must catch it — math's banked
  validity law: false, not merely unreachable).
- **C6 — tape-out packaging**: pin budget for a CPU tile (R4), the
  next-shuttle decision at the Aug 17 readiness check.

## Laws honored (all minted or re-proven today, none aspirational)

per-cone width ≤ the module law or chunked (corrected chunk table:
one rung, not two) · monolithic elaboration dies ~1300 gates — per-module
always · `bv_decide` dev-only (axiom) · no remembered knob names, dates,
or hostnames — every external fact read at its source · the trusted base
stated at its TRUE size · seam cost paid BEFORE building · instruments
print what they READ · every landing gets its bus line same-breath.

## Kill-checks for the council refuters (arrive with these answered or
## run them at muster — the freeze is not ratified until they fail to kill it)

- **R1** Does C1's `St` match what the RISC-V datapath brief already
  assumes? (The `step` seam is where evidence's brief and compiler's
  codegen freeze meet — one artifact, two consumers, ruled compiler's.)
- **R2** THE ALU CONE: 32-bit add/sub cones exceed the per-cone law by
  construction. The claimed answer — bit-slice with per-slice carry
  obligations (the fabric's own pattern) — must be DEMONSTRATED on one
  slice before C3 freezes, not asserted.
- **R3** THE REGFILE: 1024 state bits. Show the flop-treatment census
  keeps every cone inside the law, and that cycle induction over that
  state shape elaborates (a Scratch probe, not an argument).
- **R4** TT pin budget for a CPU: what memory/debug interface fits the
  tile? (The 1988 answer — bit-serial — may win a third time. If it
  does, say so as engineering, not nostalgia.)
- **R5** "ENTIRE CPU" — state v1's exclusions explicitly (CSRs, traps,
  FENCE, ECALL/EBREAK?) so nobody upgrades the claim later. An honest
  boundary beats a grand one.

## Cost + timeline (aggressive per the Captain's "faster than you think";
## honest per TS-3's lesson — demand-side first, and the 5× numeral-
## carriage coefficient from the TS waves applies to spec-heavy work)

- C0–C2: by Aug 8 (census tonight/tomorrow; triple in flight now).
- C3–C4: target ~Aug 12 — **"the compiler, verified" with `step` running
  is the LTI-meeting demo if it lands; the meeting outranks the demo if
  it doesn't** (the Captain's own orders, Aug 12 row).
- C5: ~Aug 16. C6 decision: Aug 17 readiness check.
- Every estimate above is a target, not a promise; the flags ledger
  arbitrates, as always.

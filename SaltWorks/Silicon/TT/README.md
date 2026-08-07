# Verified 8×8 bit-serial banyan switch — TinyTapeout TTSKY26c

A self-routing 8×8 packet switch fabric whose **gate netlist is proved
equivalent to its specification inside the Lean kernel**. It recreates the
banyan half of **US Patent 4,910,730** (1988) — an ATM packet switch built as
two chips, a Batcher sorter and a banyan router. That two-chip partition is also
the proof's partition: the sorter is the *hypothesis*, the banyan is the
*theorem*. **This chip is the proved half.**

Read the datasheet first: [`docs/info.md`](docs/info.md).

## What is actually proved, and what is not

The synthesized gate netlist of the switch element — real sky130 standard cells,
flip-flops included — computes the same outputs and next state as the Lean
specification **for every state and every input**, checked by kernel reduction
and lifted across cycles by induction. No SAT solver is trusted and no
`native_decide` is used.

**A banyan routes correctly only when the destinations presented to it are
sorted.** Of all 40,320 full-load permutations, exactly **4,096 (10.16 %)** route
without internal collision. The Batcher sorter that would guarantee sortedness is
on neither this chip nor in Lean. So this is a correct router *given a correct
input order*, and the ordering must come from off-chip — as it did in 1988.

## Layout of this directory

| path | what |
|---|---|
| `info.yaml` | the manifest — schema authority is `tt-support-tools/project_info.py` |
| `src/project.v` | the TT wrapper (`tt_um_saltworks_banyan`) |
| `src/config.json` | the two hardening knobs; rationale in [`docs/hardening-choices.md`](docs/hardening-choices.md) |
| `docs/info.md` | the datasheet body spliced into the shuttle datasheet |
| `docs/submission-checklist.md` | prepared / owed / the human's clicks |
| `src/banyan_fabric.v` | the 8×8 fabric: twelve switch elements in three stages |
| `src/bitserial_switch.v` | the 2×2 element — the thing the Lean proof is about |
| `test/` | the cocotb bench — [`test/README.md`](test/README.md) |

`banyan_fabric.v` and `bitserial_switch.v` are **generated into this repo**, not
authored here: they live once upstream, because the same bytes are what the
equivalence proof and the synthesis script read, and a second hand-maintained
copy would drift. What you see in `src/` is that copy, made by a script.

## Checking it

```sh
cd test && make            # the 255-scenario bench at RTL
GATES=yes make             # the same bench against the post-layout netlist
./gl_local.sh <netlist.v>  # ...or against a locally synthesized sky130 netlist
```

The GitHub Actions in this repo run the same bench, plus the hardening flow, the
TinyTapeout precheck, and a gate-level test against the **powered** post-layout
netlist.

`.github/workflows/`, `.devcontainer/`, `.vscode/`, `LICENSE` and `tb.gtkw` are
**TinyTapeout's template repo verbatim** — this repository was created *from*
that template, and those files are deliberately unmodified.

## Licence

Apache-2.0, which TinyTapeout's terms make mandatory for both the design and its
documentation. Copyright 2026 Jason Hickey.

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
| `test/` | the cocotb bench — [`test/README.md`](test/README.md) |
| `assemble.sh` | builds the submission tree; **the RTL is not duplicated here** |
| `validate.py` | offline pre-flight for every gate that needs no EDA toolchain |

**`src/banyan_fabric.v` and `src/bitserial_switch.v` are not checked in.** They
live once, in `SaltWorks/Silicon/RTL/`, because that is what the equivalence
proof and the synthesis script read; `assemble.sh` copies them in. A copy a human
maintains drifts; a copy a script makes does not.

## Assembling and checking it

```sh
./assemble.sh /path/to/tt-repo-clone   # drop our files into a template checkout
./validate.py                          # schema, docs gate, cross-file sync, RTL rules
cd /path/to/tt-repo-clone/test && make # the 255-scenario bench at RTL
```

`.github/workflows/`, `.devcontainer/`, `.vscode/`, `LICENSE` and `tb.gtkw` come
from **TinyTapeout's template repo verbatim** and must not be hand-written —
create the repo *from* the template, then run `assemble.sh` over it.

## Licence

Apache-2.0, which TinyTapeout's terms make mandatory for both the design and its
documentation. Copyright 2026 Jason Hickey.

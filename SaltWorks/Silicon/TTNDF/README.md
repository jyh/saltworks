# NDF — a bit-serial neural dataflow fabric (TinyTapeout, ttsky26c)

MAC cells on a self-routing banyan switch, with a small byte-phase processor beside
them sharing the same 24 pins. Six-by-two tiles.

**Each MAC cell is generated from a Lean model proved correct in the Lean kernel,
and the generated netlist is then proved equivalent to its arithmetic specification
over all inputs by SAT.** The signed accumulation is proved for the drive schedule
the design specifies. **The sequencer that produces that schedule, the pin wrapper
and the fabric glue are hand-written RTL and are not part of either proof** — the
project's claim is precise about which layer it means, and so is this file.

The datasheet is `docs/info.md`. The pin map, tile count and source list are in
`info.yaml`.

## ⛔ THIS IS NOT A SUBMITTABLE TREE YET, AND THE TOOLING SAYS SO RATHER THAN THIS FILE

`assemble.sh` **exits 3** and names what is missing. That is deliberate: an
incomplete tree must not exit 0, because a caller that reads only the exit code
would otherwise ship it.

```
present   info.yaml · src/config.json · docs/info.md · README.md · assemble.sh
missing   test/   — a cocotb bench (see below: blocked, not merely unwritten)
derived   src/*.v — copied from SaltWorks/Silicon/RTL/ by assemble.sh, never
                    committed here
```

**Why the RTL is derived and not checked in:** it lives in one place, because that
is the source both the Lean equivalence proof and `Flow/synth.sh` read. A second
committed copy is a copy a human maintains, and a copy a human maintains drifts.

**Why the bench is blocked rather than lazy:** a testbench binds `PROJECT_SOURCES`,
which must agree with `source_files`, which follows `top_module` — and which top
ships is not yet ruled. A bench written against the wrong top is wasted twice.

## Building the submission tree

```sh
./assemble.sh <target-dir>     # refuses first, copies second
```

It runs `docs/silicon-tools/manifest_check.sh` and **consumes its exit status**: if
`source_files` is not exactly the transitive closure of `top_module`, nothing is
copied. That gate exists because `info.yaml` said in its own comments that *nothing*
checked this agreement — and a comment saying nothing checks this is a defect report
addressed to nobody. It is checked now.

`.github/workflows/`, `.devcontainer/`, `.vscode/` and `LICENSE` come from
TinyTapeout's template repo verbatim and must not be hand-written: create the repo
**from** the template, then run `assemble.sh` over it.

## Layout receipts

There are none yet, and none will be produced locally. `Flow/synth.sh` pins PDK
revision `c6d73a35…`; TinyTapeout hardens against `8afc8346…`. Those two revisions
are byte-identical in `lib/` and `verilog/` — so **cell areas, and therefore the
synthesis numbers, do not depend on the choice** — but they differ in all 893
`sky130_fd_sc_hd` files under `mag/`, `maglef/`, `gds/` and `spice/`, which is
exactly what DRC and LVS consume. A local run would be a receipt for something that
is not what ships. The venue is TinyTapeout's own CI.

Reasoning in full: `docs/silicon-rungzero-layout-venue-0818.md` in the repo root.

## The other submission

`../TT/` is a **different** TinyTapeout project and is untouched by anything here.
This directory exists precisely so that this one never borrows its manifest.

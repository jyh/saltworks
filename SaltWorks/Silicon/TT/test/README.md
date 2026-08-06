# Testbench — the silicon twin of the kernel certificate

`test.py` drives **the same 255 sorted, concentrated destination sets** that
`SaltWorks.Silicon.Equiv.FabricRoutes.fabric_routes` quantifies over in the Lean
kernel: same frames, same payloads, same expected outputs. One suite is checked
by kernel reduction, the other by a simulator against real gates.

**254 of the 255 are partial load, and that is the design constraint.** At full
load, sortedness forces `dest = id`, every switch sits straight, and a broken
element passes. A suite that only ran full load would be vacuous.

## Running it

```sh
make            # RTL
GATES=yes make  # the same testbench against the post-layout netlist
```

TinyTapeout's `gds` workflow runs the gate-level form automatically in its
`gl_test` job, against the **powered** netlist (`powered_netlists: true`), and a
failure there reddens the `gds` workflow — which is blocking for submission.

For the gate-level run outside CI, harden first and copy the netlist to
`gate_level_netlist.v` in this directory; `PDK_ROOT` must point at the sky130A
PDK so the cell models resolve.

Without LibreLane you can still run the bench against a locally *synthesized*
sky130 netlist, which is worth doing before spending a CI cycle:

```sh
./gl_local.sh /path/to/netlist.v   # real sky130 cells, tb.v unmodified
```

Measured: **3/3, 255/255 against real standard cells.** That netlist is
**unpowered and pre-place-and-route**, so it says nothing about setup and nothing
at all about hold — see `../docs/submission-checklist.md` §C.3.

## Local repro notes, because two of these cost real time

- **cocotb 2.0.1 does not build on Python 3.14** — no wheels, and the sdist fails
  at the build-requirements step. Use 3.12 or 3.13.
- **cocotb 2.x, not 1.x**: `Clock(dut.clk, 10, unit="us")` (1.x's `units=` will
  not run), and the Makefile variable is `COCOTB_TEST_MODULES`, not `MODULE`.
- Verified here on Icarus Verilog 13.0 + cocotb 2.0.1 + Python 3.12: **3/3 tests,
  255/255 scenarios.**

## The three tests, and what each is worth

| test | what it establishes |
|---|---|
| `test_counter_alignment` | the frame counter and `valid` track the cycle index the driver *believes* it is driving. Every other test rests on that belief, so it is checked, not assumed — an off-by-one would otherwise show up as a silently mis-aligned pass |
| `test_routes_all_255_scenarios` | every packet arrives on the line its address names, and every unaddressed line stays idle. Frames run back to back with **no reset between them**, which additionally exercises self-initialisation |
| `test_vectors_discriminate` | a **positive control on the STIMULI, not on the DUT**: the same vectors against a Python mirror of the element carrying the routing bug found on 8/6 at 10:52. It fails 254/255 — so the vectors bite. A suite that cannot fail proves nothing, and this one demonstrates it can, on every CI run |

The third one is deliberately narrow in what it claims. It says the vectors
discriminate. It says nothing by itself about the DUT; the other two do that.

## Before you edit either file

`PROJECT_SOURCES` here and `source_files` in `../info.yaml` **must agree, and
nothing in TinyTapeout's flow checks that they do.** `../validate.py` does — run
it after touching either.

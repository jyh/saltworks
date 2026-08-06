#!/bin/bash
# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
#
#   ./gl_local.sh <netlist.v>
#
# Run the shipped 255-scenario bench against a LOCALLY SYNTHESIZED sky130 gate
# netlist, with `tb.v` unmodified. This exists because the gate-level path is
# otherwise first exercised in TinyTapeout's CI, where `gl_test` failing reddens
# the `gds` workflow -- which is blocking for submission. Finding an X-propagation
# or reset problem here costs a minute; finding it there costs a CI cycle.
#
# ⚠️ WHAT THIS IS NOT. It is NOT the artifact the equivalence proof targets:
#   * UNPOWERED -- so `-DGL_TEST` is deliberately NOT passed, and neither the
#     cell models nor our top module carry VPWR/VGND. TT's shuttle builds POWERED
#     netlists (`powered_netlists: true`), and CI runs the powered form.
#   * PRE-PLACE-AND-ROUTE -- functional cell models at unit delay. It says
#     nothing about setup, and nothing at all about HOLD, which is the residual
#     risk on this design.
#   * built by our yosys, not by `librelane==3.0.5`.
# It exercises real sky130 standard cells and the real testbench. That is the
# part worth having early.
set -e -u

NL="${1:?usage: gl_local.sh <netlist.v>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${PDK_ROOT:=$HOME/.volare/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
V="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog"

[ -f "$V/primitives.v" ] || { echo "gl_local: no sky130 models at $V"; \
  echo "  fetch with: volare enable --pdk sky130 <rev>"; exit 1; }

command -v cocotb-config >/dev/null || { echo "gl_local: cocotb not on PATH."; \
  echo "  cocotb 2.0.1 does NOT build on Python 3.14 -- use 3.12/3.13:"; \
  echo "  python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt"; \
  exit 1; }

mkdir -p "$HERE/sim_build"
iverilog -o "$HERE/sim_build/gl_local.vvp" -s tb -g2012 \
  -DFUNCTIONAL -DUNIT_DELAY=#1 \
  "$V/primitives.v" "$V/sky130_fd_sc_hd.v" "$NL" "$HERE/tb.v"

# cocotb's Makefile normally exports these two. Driving vvp directly means
# supplying them by hand, and the failure without them is an obscure dlopen /
# "PYGPI_PYTHON_BIN variable not set" rather than anything about the design.
export LIBPYTHON_LOC="$(cocotb-config --libpython)"
export PYGPI_PYTHON_BIN="$(cocotb-config --python-bin 2>/dev/null || command -v python3)"
export PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}"
export COCOTB_TEST_MODULES=test COCOTB_TOPLEVEL=tb TOPLEVEL_LANG=verilog

exec vvp -M "$(cocotb-config --lib-dir)" -m libcocotbvpi_icarus \
  "$HERE/sim_build/gl_local.vvp"

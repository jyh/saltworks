# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
#
#   make                # RTL simulation
#   GATES=yes make      # the SAME testbench against the post-layout netlist
#
# TinyTapeout's `gds` workflow runs the gate-level form for you in its `gl_test`
# job, against the POWERED netlist, and a failure there reddens the gds workflow
# — which is blocking for submission. So this file is on the critical path.
#
# ⚠️ PROJECT_SOURCES must be kept in sync BY HAND with `source_files` in
#    info.yaml. Nothing in TinyTapeout's flow checks that they agree.
#    `../validate.py` does — run it after touching either.

# DELIBERATE DIVERGENCE FROM THE TEMPLATE, so it does not read as an oversight:
# the template declares `FST ?= -fst` and then never references it, while its
# tb.v writes `tb.fst` — and without the runtime flag iverilog puts VCD-format
# bytes in a file named .fst. We dump `tb.vcd` and drop the dead variable, which
# is self-consistent. Nothing in TT's CI consumes the waveform.
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = project.v banyan_fabric.v bitserial_switch.v

ifneq ($(GATES),yes)

# RTL simulation
SIM_BUILD        = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate-level simulation
SIM_BUILD        = sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# Copied in by the GDS action workflow.
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

COMPILE_ARGS    += -I$(SRC_DIR)

VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# cocotb 2.x: this is COCOTB_TEST_MODULES, not 1.x's MODULE.
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim

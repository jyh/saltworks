# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
#
# UNRUN LOCALLY — cocotb unavailable (python 3.14.4). Referee: TT CI. First CI run is this benchs first receipt.
#
#   make                # RTL simulation
#   GATES=yes make      # the SAME testbench against the post-layout netlist
#
# ⚠️ THE MARKER ABOVE IS THE HELM'S WORDING, REPRODUCED VERBATIM (2026-08-18 18:3x),
# including its exact spelling. It is a DECLARATION, and the ruling it comes from is
# what makes this file honest: an artifact whose referee is DECLARED and EXTERNAL is
# not a claim in a receipts tree — the tree stays honest BY DECLARATION rather than by
# absence. Do not "tidy" this line; it is the thing that distinguishes this file from
# a bench pretending to have passed.
#
# ⛔ PROJECT_SOURCES MUST EQUAL `source_files` IN ../info.yaml, AND THAT IS NOW
# CHECKED — `docs/silicon-tools/manifest_check.sh` compares both against the RTL
# closure and REFUSES on any disagreement. Until this file existed there was nothing
# to agree with, so that gap was EMPTY rather than closed; writing this file made it
# real, so the gate was widened in the same commit.
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_saltworks_ndf_c32.v banyan_fabric.v bitserial_switch.v busadapt8.v core32.v mac_cell_signed_shell.v plane32bus.v ser_organ.v

ifneq ($(GATES),yes)

SIM_BUILD        = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
# Test-only behavioral models of the sky130 cells the emitted RTL instantiates.
# NOT in source_files: the real cells come from the PDK at hardening. Without
# this the test job fails with 1841 "Unknown module type" errors (measured).
VERILOG_SOURCES += $(PWD)/sky130_models.v

else

SIM_BUILD        = sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

COMPILE_ARGS    += -I$(SRC_DIR)

VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# cocotb 2.x: COCOTB_TEST_MODULES, not 1.x's MODULE.
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim

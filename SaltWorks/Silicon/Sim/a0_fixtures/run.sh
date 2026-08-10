#!/bin/sh
# A0 · the 2-2-1's six routes, checked on the EMITTED fabric. SILICON's half.
#   sh SaltWorks/Silicon/Sim/a0_fixtures/run.sh
# Compiler owns the kernel half (decide +kernel over the netlist MODEL); this is
# the ARTIFACT half — the same six routes driven into the RTL and read back.
#
# ⛔ THE TWO DEFECTS THIS HARNESS SHIPPED WITH, both mine, both UNTESTED
# ASSUMPTIONS, and both produced 6/6 FALSE FAILURES against a fabric that was fine:
#   (1) "the payload arrives one frame later" — IT DOES NOT. A second sampling
#       pass OVERWROTE the correct capture with zeros.
#   (2) the schedule was keyed on my loop index; `sof` leaves cnt at 1 on the
#       first driven edge. Now keyed on the fabric's OWN cnt_o — self-aligning.
# ⇒ 6/6 FAIL against a kernel-proved artifact is the tell that the HARNESS is
#   wrong. Instrument one route before believing a sweep.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"; RTL="$HERE/../../RTL"
iverilog -g2012 -o "$HERE/sim_a0" "$HERE/tb_a0_221_routes.v" \
  "$RTL/banyan_fabric.v" "$RTL/bitserial_switch.v"
"$HERE/sim_a0"

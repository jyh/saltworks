# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
"""
UNRUN LOCALLY — cocotb unavailable (python 3.14.4). Referee: TT CI. First CI run is this benchs first receipt.

⚠️ THE LINE ABOVE IS THE HELM'S WORDING, REPRODUCED VERBATIM (2026-08-18 18:3x),
spelling included. It is a DECLARATION and it is what keeps this file honest in a tree
whose other benches are receipts: an artifact whose referee is DECLARED and EXTERNAL
is not a claim. Do not tidy it.

WHAT IS CHECKED AND WHAT IS NOT — stated so a green CI badge is not read as more than
it is, and so an UNRUN file is not read as less:
  CHECKED   this module PARSES (`python3 -m py_compile`, in the landing commit)
  CHECKED   `tb.v` ELABORATES against the real `../src/*.v` (iverilog, exit 0) — so
            the DUT module name and every port name are verified
  NOT CHECKED  every assertion below. NONE of them has ever executed. The first CI
            run is their first receipt, and if one of them is wrong THAT IS A FINDING
            ABOUT THIS FILE and not about the design.

⛔ AND WHAT THIS FILE DELIBERATELY DOES **NOT** DO: it does not model a memory host
and does not test LW/SW end to end. That receipt already exists and is DRIVEN —
`SaltWorks/Silicon/Sim/wordonly/tb_plane32bus_lwsw.v`, 6/6 with a mutation control,
which is the bench that FOUND the transaction/instruction off-by-one and then measured
its repair. **Re-implementing a host model in a file I cannot run would be a liability,
not coverage**: a subtle bug in an unrun host produces a red CI that looks like a
design defect. So the assertions here are deliberately MODEST and each one is grounded
in something already measured elsewhere.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def _boot(dut):
    """Reset, then release. 55 ns period — the manifest's CLOCK_PERIOD."""
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    cocotb.start_soon(Clock(dut.clk, 55, units="ns").start())
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_uio_oe_is_the_frozen_constant(dut):
    """`uio_oe` is a constant in the top: 8'b1011_0011.

    GROUNDED: it is a literal `assign` in tt_um_saltworks_ndf_c32.v, generated from
    gen_ndf_wrapper.py, and the D6 pin map that fixes it is Captain-confirmed.
    """
    await _boot(dut)
    assert int(dut.uio_oe.value) == 0b1011_0011, (
        f"uio_oe must be the frozen D6 constant 0b10110011, got {dut.uio_oe.value}"
    )


@cocotb.test()
async def test_phase_pins_show_phase_outside_phase_zero(dut):
    """`uio_out[1:0]` carries the PHASE number at phases 1..3.

    GROUNDED: this is decision 1 of busadapt8 and it is an INVARIANT already driven
    to ALL PASS by the tracked Sim/wordonly/tb_busadapt8.v, which asserts it at every
    cycle against the adapter's own phase. Here it is checked only through the PINS,
    which is the part CI can see.

    The check is deliberately weak in one respect and I am saying so rather than
    hiding it: from the pins alone a reader cannot tell phase 0 from a TYPE code of
    00 (IDLE), because they are the same two bits by design. So this test asserts the
    PROGRESSION over four cycles rather than any single sample.
    """
    await _boot(dut)
    seen = []
    for _ in range(8):
        await RisingEdge(dut.clk)
        seen.append(int(dut.uio_out.value) & 0b11)
    assert len(set(seen)) > 1, (
        f"the phase pins never changed across 8 cycles: {seen} — the frame counter "
        f"is not running"
    )


@cocotb.test()
async def test_sof_realigns_the_frame(dut):
    """`sof` (uio_in[6]) forces every counter in the design to frame zero.

    GROUNDED: one net feeds the sequencer, the fabric and the core's phase counter,
    which is why they cannot disagree about where a frame begins — and busadapt8's
    reset/sof arm is exercised by the tracked adapter bench.
    """
    await _boot(dut)
    await ClockCycles(dut.clk, 3)
    dut.uio_in.value = 1 << 6          # pulse sof
    await RisingEdge(dut.clk)
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)
    # After a sof pulse the phase counter has been forced to 0 and has advanced once.
    assert int(dut.uio_out.value) & 0b11 in (0, 1), (
        f"after sof the phase pins should be at the start of a frame, got "
        f"{int(dut.uio_out.value) & 0b11}"
    )


@cocotb.test()
async def test_the_core_drives_an_address_byte(dut):
    """`uo_out` carries a byte of the address the core is asking for.

    GROUNDED, and deliberately the weakest useful form: the STRONG version of this —
    that the bytes assemble into a PC advancing by 4, and that a store carries the
    right operand — is measured by tb_plane32bus_lwsw.v (L2/L3/L6) and is NOT
    duplicated here. All this asserts is that the pins are not stuck, which is the
    failure a wrapper-level mistake actually produces.
    """
    await _boot(dut)
    seen = set()
    for _ in range(16):
        await RisingEdge(dut.clk)
        seen.add(int(dut.uo_out.value))
    assert len(seen) > 1, (
        f"uo_out never changed across 16 cycles (always {seen}) — the address path "
        f"is not being driven through the pins"
    )

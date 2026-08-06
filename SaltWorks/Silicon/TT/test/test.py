# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
"""
Cocotb testbench for `tt_um_saltworks_banyan` — the verified 8x8 bit-serial
banyan fabric.

WHAT THIS RUNS, AND WHY THESE CASES
-----------------------------------
The 255 stimuli below are **the same 255 the Lean certificate quantifies over**
(`SaltWorks.Silicon.Equiv.FabricRoutes.fabric_routes`, `allScenarios`): every
non-empty subset of {0..7} in increasing order, sources concentrated on lines
0..n-1. Same frames, same payloads, same expected outputs — one suite checked by
the Lean kernel, the other by a simulator against real gates.

**MOST OF THEM ARE PARTIAL LOAD, and that is the design constraint, not an
accident.** At full load sortedness forces dest = id, every switch sits straight,
and a broken element passes. (Compiler seat's R4-full-load-collapse finding,
8/6 — a certificate that only runs full load is vacuous.) Partial load is also
what produces idle ports at interior stages, which is precisely what the routing
bug found on 8/6 at 10:52 exploited.

WHEN THIS RUNS AGAINST GATES
----------------------------
`GATES=yes make` — and TinyTapeout's `gds` workflow does exactly that
automatically in its `gl_test` job, against the **powered** post-layout netlist
(`powered_netlists: true` for this shuttle). So this file is what checks the
netlist that is actually fabricated, and it is the same file that checks the RTL.

WHAT THE THIRD TEST IS FOR
--------------------------
`test_vectors_discriminate` is a **positive control**. It does not test the DUT:
it tests the *stimuli*, by running them against a Python mirror of the fabric
carrying the actual 10:52 bug, and asserting that they catch it. A suite that
cannot fail proves nothing, and this one demonstrates it can fail — on every CI
run, not once on a developer's laptop. Stated precisely so it is not oversold:
this establishes that the VECTORS discriminate. It says nothing by itself about
the DUT; the other two tests do that.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge

K = 3                    # address bits / stages
HDR = 2 * K              # 6 header cycles: ACT and one address bit per stage
PAYLOAD = 8
FRAME = HDR + PAYLOAD    # 14


# --------------------------------------------------------------------------
# The stimuli. Mirrors SaltWorks/Silicon/Equiv/FabricRoutes.lean exactly.
# --------------------------------------------------------------------------

def payload_of(i):
    """`payloadOf i` — bit b of (i+1), LSB first in TIME (cycle 6+b)."""
    return [((i + 1) >> b) & 1 for b in range(PAYLOAD)]


def mk_frame(active, dest):
    """`mkFrame` — [ACT, a2, ACT, a1, ACT, a0] ++ payload, MSB of the address
    first because stage 0 resolves the most significant bit."""
    hdr = []
    for s in range(K):
        hdr.append(1 if active else 0)
        hdr.append(((dest >> (2 - s)) & 1) if active else 0)
    return hdr


def scenario(ds):
    """`scenario ds` — line i carries a packet for ds[i] when i < len(ds); every
    other line is all zeros, i.e. idle (activity bit 0, claims nothing)."""
    return [mk_frame(True, ds[i]) + payload_of(i) if i < len(ds)
            else [0] * FRAME
            for i in range(8)]


def expected(ds, d):
    """`expected ds d` — what output line d must carry in the payload window."""
    if d in ds:
        return payload_of(ds.index(d))
    return [0] * PAYLOAD


def all_scenarios():
    """`allScenarios` — 255 non-empty sorted, concentrated destination sets."""
    return [[i for i in range(8) if (m >> i) & 1] for m in range(1, 256)]


# --------------------------------------------------------------------------
# A Python mirror of the fabric, parameterised by its element. Used ONLY by the
# discrimination control — the DUT tests never consult it.
# --------------------------------------------------------------------------

PAIRS = {0: [(0, 4), (1, 5), (2, 6), (3, 7)],
         1: [(0, 2), (1, 3), (4, 6), (5, 7)],
         2: [(0, 1), (2, 3), (4, 5), (6, 7)]}


def elem_out_correct(e, i0, i1):
    """`elemOut` — input i claims output j iff it is ACTIVE and its address bit
    selects j. An unclaimed output drives 0, so idleness propagates."""
    a0, a1, s0, s1 = e
    return ((a0 and not s0 and i0) or (a1 and not s1 and i1),
            (a0 and s0 and i0) or (a1 and s1 and i1))


def elem_out_buggy(e, i0, i1):
    """THE 8/6 10:52 BUG, verbatim in its effect:

        assign out0 = (sel0 == 1'b0) ? in0 : in1;

    A plain mux on the address bit, with no activity gating. With port 0 idle,
    sel0 stays 0, out0 takes in0 unconditionally, and an active packet on in1
    bound for out0 is SILENTLY DROPPED."""
    _a0, _a1, s0, s1 = e
    return ((i1 if s0 else i0), (i0 if s1 else i1))


def _stage_out(fs, s, w, elem_fn):
    w = list(w)
    for pos, (lo, hi) in enumerate(PAIRS[s]):
        o0, o1 = elem_fn(fs[s * 4 + pos], w[lo], w[hi])
        w[lo], w[hi] = o0, o1
    return w


def _fabric_next(fs, din, cnt, elem_fn):
    w0 = din
    w1 = _stage_out(fs, 0, w0, elem_fn)
    w2 = _stage_out(fs, 1, w1, elem_fn)
    wires = [w0, w1, w2]
    out = []
    for idx in range(12):
        s = idx // 4
        lo, hi = PAIRS[s][idx % 4]
        w = wires[s]
        a0, a1, s0, s1 = fs[idx]
        astb, sstb = (cnt == 2 * s), (cnt == 2 * s + 1)
        out.append((w[lo] if astb else a0, w[hi] if astb else a1,
                    w[lo] if sstb else s0, w[hi] if sstb else s1))
    return out


def model_run_frame(fs, streams, elem_fn):
    """`runFrame` — 14 cycles; returns the output wire at each cycle, and the
    resulting state (so frames can be run back to back, as the hardware does)."""
    trace = []
    for cnt in range(FRAME):
        din = [bool(streams[i][cnt]) for i in range(8)]
        w = _stage_out(fs, 0, din, elem_fn)
        w = _stage_out(fs, 1, w, elem_fn)
        w = _stage_out(fs, 2, w, elem_fn)
        trace.append(w)
        fs = _fabric_next(fs, din, cnt, elem_fn)
    return trace, fs


INIT_FABRIC = [(False, False, False, False)] * 12


def model_failures(elem_fn):
    """How many of the 255 scenarios does this element model get wrong?"""
    bad = 0
    fs = INIT_FABRIC
    for ds in all_scenarios():
        trace, fs = model_run_frame(fs, scenario(ds), elem_fn)
        for d in range(8):
            got = [1 if trace[HDR + t][d] else 0 for t in range(PAYLOAD)]
            if got != expected(ds, d):
                bad += 1
                break
    return bad


# --------------------------------------------------------------------------
# Driving the DUT
# --------------------------------------------------------------------------

def _resolved(sig, what):
    """Read a signal, refusing X/Z rather than silently coercing them. At gate
    level an uninitialised flop reads X, and int() on an X is either an exception
    or — worse, depending on the version — a zero that looks like a pass."""
    s = str(sig.value)
    if set(s) - {"0", "1"}:
        raise AssertionError(f"{what} is not resolvable: {s!r}")
    return int(s, 2)


async def _cycle(dut, din, sample):
    """Run one clock cycle. Entered just after a rising edge, so `cnt` already
    holds this cycle's value; leaves just after the next rising edge, at which
    the element registers latch what we drove.

    The data path is combinational, so this cycle's output is sampled at the
    falling edge, once it has settled."""
    dut.ui_in.value = din
    await FallingEdge(dut.clk)
    got = (_resolved(dut.uo_out, "uo_out"),
           _resolved(dut.uio_out, "uio_out")) if sample else None
    await RisingEdge(dut.clk)
    return got


async def _start(dut):
    """Clock, reset, and one `sof` pulse to align the frame counter. After this
    returns, the next cycle is cycle 0 of a frame."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # `sof` is sampled at the next rising edge and sets cnt := 0, so the cycle
    # AFTER this one is cycle 0.
    dut.uio_in.value = 1
    await FallingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.uio_in.value = 0


# --------------------------------------------------------------------------
# The tests
# --------------------------------------------------------------------------

@cocotb.test()
async def test_counter_alignment(dut):
    """The frame counter and `valid` must track the cycle index we believe we
    are driving. Every other test's correctness rests on that belief, so it is
    checked rather than assumed — an off-by-one here would otherwise show up as
    a silently mis-aligned pass."""
    await _start(dut)

    idle = [[0] * FRAME for _ in range(8)]
    for _ in range(2):
        for t in range(FRAME):
            _, uio = await _cycle(dut, 0, sample=True)
            cnt = (uio >> 1) & 0x7
            valid = (uio >> 4) & 0x1
            assert cnt == t % 8, f"cycle {t}: cnt_o = {cnt}, expected {t % 8}"
            assert valid == (1 if t >= HDR else 0), \
                f"cycle {t}: valid = {valid}, expected {1 if t >= HDR else 0}"
            assert (uio >> 5) == 0, f"cycle {t}: uio[7:5] must be driven low"
    assert idle  # keep the linter honest about the unused-idle case


@cocotb.test()
async def test_routes_all_255_scenarios(dut):
    """THE certificate's silicon twin: all 255 sorted, concentrated destination
    sets, most of them partial load. Frames run back to back with no reset
    between them, which additionally exercises self-initialisation — every
    register is reloaded at its own strobe, so the previous frame's routing
    cannot survive into this one."""
    await _start(dut)

    scenarios = all_scenarios()
    partial = sum(1 for ds in scenarios if len(ds) < 8)
    assert partial == 254, f"expected 254 partial-load cases, got {partial}"

    failures = []
    for ds in scenarios:
        streams = scenario(ds)
        got = [[] for _ in range(8)]
        for t in range(FRAME):
            din = sum((streams[i][t] & 1) << i for i in range(8))
            out = await _cycle(dut, din, sample=(t >= HDR))
            if out is not None:
                uo = out[0]
                for d in range(8):
                    got[d].append((uo >> d) & 1)
        for d in range(8):
            if got[d] != expected(ds, d):
                failures.append(
                    f"dests={ds} line {d}: got {got[d]}, expected {expected(ds, d)}")

    assert not failures, (
        f"{len(failures)} routing failures across 255 scenarios; first 5:\n  "
        + "\n  ".join(failures[:5]))
    dut._log.info("255/255 sorted+concentrated destination sets route correctly")


@cocotb.test()
async def test_vectors_discriminate(dut):
    """POSITIVE CONTROL — on the STIMULI, not on the DUT.

    The same 255 scenarios are run against a Python mirror of the fabric built
    from the element that shipped on 8/6 before 10:52, whose combinational
    output was a plain mux on the address bit with no activity gating. If the
    vectors could not catch that, a green run of the test above would mean
    nothing. Also runs the correct model, which must pass all 255 — a control
    that fails everything is equally worthless."""
    good = model_failures(elem_out_correct)
    assert good == 0, f"the correct element model failed {good} scenarios"

    bad = model_failures(elem_out_buggy)
    assert bad > 0, (
        "THE STIMULI DO NOT DISCRIMINATE: the 10:52 routing bug passes all 255 "
        "scenarios. Any green result from this suite is vacuous.")
    dut._log.info(
        f"control: the 10:52 bug fails {bad}/255 scenarios — the vectors bite")

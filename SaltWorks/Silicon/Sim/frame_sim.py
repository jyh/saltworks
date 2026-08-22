#!/usr/bin/env python3
"""Cycle-accurate validation of the serial frame protocol (spec v1).

Validates the PROTOCOL, not the Verilog: builds the 8x8 bit-serial banyan out of
the committed element's exact logic, drives real frames through it, and checks
every packet arrives on the line its destination names.

Element logic is transcribed from SaltWorks/Silicon/RTL/bitserial_switch.v:
    c00 = act0 & ~sel0    c01 = act0 &  sel0
    c10 = act1 & ~sel1    c11 = act1 &  sel1
    out0 = (c00 & in0) | (c10 & in1)
    out1 = (c01 & in0) | (c11 & in1)
"""
K = 3               # 8x8
N = 1 << K
P = 8               # payload bits
HDR = 2 * K         # header cycles: k pairs of (activity, address bit)
FRAME = HDR + P


def pairs(stage):
    """Banyan/butterfly pairing at `stage`: lines differing in bit (K-1-stage)."""
    b = 1 << (K - 1 - stage)
    return [(i, i | b) for i in range(N) if not (i & b)]


class Elem:
    __slots__ = ("act0", "act1", "sel0", "sel1")

    def __init__(self, s0=0, s1=0, a0=0, a1=0):
        self.act0, self.act1, self.sel0, self.sel1 = a0, a1, s0, s1

    def out(self, in0, in1):
        c00 = self.act0 and not self.sel0
        c01 = self.act0 and self.sel0
        c10 = self.act1 and not self.sel1
        c11 = self.act1 and self.sel1
        return (int((c00 and in0) or (c10 and in1)),
                int((c01 and in0) or (c11 and in1)))

    def latch(self, in0, in1, act_stb, sel_stb):
        if act_stb:
            self.act0, self.act1 = in0, in1
        if sel_stb:
            self.sel0, self.sel1 = in0, in1


def make_frame(act, dest, payload):
    """[ACT, a_{k-1}, ACT, a_{k-2}, ..., ACT, a_0, payload...]"""
    bits = []
    for s in range(K):
        m = K - 1 - s                       # stage s consumes destination bit m
        bits.append(act)
        bits.append((dest >> m) & 1 if act else 0)
    return bits + list(payload)


def run(packets, init_random=None, init_phase=0, sof=True):
    """packets[i] = None (idle) or (dest, payload-bits). Returns per-line output.

    THE FRAME COUNTER — added 2026-08-22, closing spec §8's half init surface.
    Until now this simulator derived the per-stage strobes from the loop index
    (`act_stb = (t == 2*s)`), which silently ASSUMES the counter powers up
    frame-aligned at 0. The RTL does not: banyan_fabric.v holds a real counter
    whose only zeroing paths are rst_n, sof and the natural wrap, and the
    strobes are a PURE DECODE of it (`act_stb[s] = (cnt == 2*s)`). So §3's
    "arbitrary power-up state" census randomised the ELEMENT state and left the
    COUNTER perfectly initialised — half the surface, which is exactly what the
    8/8 13:31 probe registered as its open successor.

      init_phase : power-up value of cnt (TT power-gates; any 0..FRAME-1)
      sof        : whether the frame's start strobe zeroes the counter

    Defaults reproduce the previous behaviour BIT-FOR-BIT (phase 0 + sof means
    cnt == t for the whole frame), so sections 1/2/3/4 are untouched by this.
    """
    elems = {}
    for s in range(K):
        for (lo, hi) in pairs(s):
            if init_random is not None:
                import random
                r = random.Random(init_random + s * 100 + lo)
                elems[(s, lo)] = Elem(r.randint(0, 1), r.randint(0, 1),
                                      r.randint(0, 1), r.randint(0, 1))
            else:
                elems[(s, lo)] = Elem()

    streams = []
    for i in range(N):
        if packets[i] is None:
            streams.append([0] * FRAME)
        else:
            d, pay = packets[i]
            streams.append(make_frame(1, d, pay))

    captured = [[] for _ in range(N)]
    cnt = init_phase % FRAME
    for t in range(FRAME):
        # banyan_fabric.v: sof zeroes the counter at the frame's first cycle;
        # otherwise it free-runs and wraps at FRAME-1. The strobes below are a
        # decode of THIS value, never of t.
        if sof and t == 0:
            cnt = 0
        wire = [streams[i][t] for i in range(N)]
        latch_jobs = []
        for s in range(K):
            act_stb = (cnt == 2 * s)
            sel_stb = (cnt == 2 * s + 1)
            nxt = list(wire)
            for (lo, hi) in pairs(s):
                e = elems[(s, lo)]
                o0, o1 = e.out(wire[lo], wire[hi])
                nxt[lo], nxt[hi] = o0, o1
                latch_jobs.append((e, wire[lo], wire[hi], act_stb, sel_stb))
            wire = nxt
        for (e, a, b, ast, sst) in latch_jobs:
            e.latch(a, b, ast, sst)
        for i in range(N):
            captured[i].append(wire[i])
        cnt = 0 if cnt == FRAME - 1 else cnt + 1
    return captured


def check(packets, captured, label):
    """Every active packet's payload must appear on its destination line,
    inside the validity window (cycle >= 2K)."""
    ok = True
    expect = {}
    for i, p in enumerate(packets):
        if p is not None:
            d, pay = p
            expect[d] = (i, pay)
    for line in range(N):
        got = captured[line][HDR:]
        if line in expect:
            src, pay = expect[line]
            if got != list(pay):
                print(f"  ✗ {label}: line {line} expected payload of src {src} "
                      f"{pay} got {got}")
                ok = False
        else:
            if any(got):
                print(f"  ✗ {label}: idle line {line} carried {got}")
                ok = False
    return ok


def payload_of(i):
    return [(i >> b) & 1 for b in range(P)]


import itertools, random

print("SERIAL FRAME PROTOCOL v1 — validation\n" + "=" * 52)
print(f"k={K}  lines={N}  header={HDR} cycles  payload={P}  frame={FRAME}\n")

# 1. NECESSITY CENSUS. A banyan is NOT a permutation network. Route every one of
#    the 8! full-load permutations and count how many survive. The hypothesis
#    `StrictMonoOn dest` is what a Batcher sorter would supply -- and with all N
#    lines active, a strictly monotone permutation IS the identity. So if the
#    hypothesis is load-bearing, almost everything here must fail.
import io, contextlib
good = 0
total = 0
for perm in itertools.permutations(range(N)):
    pk = [(perm[i], payload_of(i + 1)) for i in range(N)]
    total += 1
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        if check(pk, run(pk), "perm"):
            good += 1
print(f"1. NECESSITY: of all {total} full-load permutations, {good} route "
      f"correctly ({100.0*good/total:.3f}%) — the rest collide internally.")
print(f"   The hypothesis is NOT decorative: an unsorted input breaks the fabric,")
print(f"   which is precisely why the 1988 design puts a Batcher sorter in front.")

# 2. sorted + concentrated -- the landed theorem's actual hypothesis,
#    with idle ports, which is exactly what broke the old element
fails = 0
total = 0
for n in range(1, N + 1):
    for dests in itertools.combinations(range(N), n):
        pk = [None] * N
        for i in range(n):                      # sources concentrated on 0..n-1
            pk[i] = (dests[i], payload_of(i + 1))   # destinations sorted
        total += 1
        if not check(pk, run(pk), f"n={n} {dests}"):
            fails += 1
            if fails > 3:
                break
print(f"2. ALL {total} sorted+concentrated cases (WITH IDLE PORTS) : "
      f"{'PASS' if fails == 0 else f'{fails} FAIL'}")

# 3. self-initialisation from arbitrary power-up state (TT power-gates)
fails = 0
for seed in range(200):
    n = random.Random(seed).randint(1, N)
    dests = sorted(random.Random(seed + 7).sample(range(N), n))
    pk = [None] * N
    for i in range(n):
        pk[i] = (dests[i], payload_of(i + 1))
    if not check(pk, run(pk, init_random=seed), f"seed {seed}"):
        fails += 1
print(f"3. 200 ARBITRARY power-up states, one frame  : "
      f"{'PASS' if fails == 0 else f'{fails} FAIL'}")

# 3b. THE OTHER HALF OF THE INIT SURFACE: the frame COUNTER's power-up phase.
#     Section 3 randomises element state with the counter pinned at 0. The RTL
#     counter free-runs from whatever the power-gate left behind, so the real
#     census must sweep its phase too. Every phase, every sorted+concentrated
#     case, sof asserted -- this is the "conservative + inert" claim.
fails = 0
checked = 0
for phase in range(FRAME):
    for n in range(1, N + 1):
        for dests in itertools.combinations(range(N), n):
            pk = [None] * N
            for i in range(n):
                pk[i] = (dests[i], payload_of(i + 1))
            checked += 1
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                ok = check(pk, run(pk, init_phase=phase), f"phase {phase}")
            if not ok:
                fails += 1
print(f"3b. ALL {FRAME} counter power-up phases x {checked // FRAME} cases : "
      f"{'PASS' if fails == 0 else f'{fails} FAIL'}  "
      f"({checked} runs — sof re-aligns, so phase is INERT)")

# 3c. CONTROL for 3b — without sof the counter never re-aligns, so a non-zero
#     power-up phase MUST mis-decode the strobes. If this does not fail, 3b is
#     passing because the phase never reached the decode, not because the design
#     is robust: the arm would be testing nothing.
mis = 0
tried = 0
for phase in range(1, FRAME):
    pk = [None] * N
    for i in range(N):
        pk[i] = (i, payload_of(i + 1))
    tried += 1
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        if not check(pk, run(pk, init_phase=phase, sof=False), f"noSOF {phase}"):
            mis += 1
print(f"3c. CONTROL — same, sof WITHHELD               : "
      f"{mis}/{tried} phases mis-route  "
      f"({'phase reaches the decode' if mis else '⚠ 3b IS BLIND'})")

# 4. the control: does this suite actually catch the bug that was fixed?
class OldElem(Elem):
    def out(self, in0, in1):
        return (in0 if self.sel0 == 0 else in1,
                in1 if self.sel1 == 1 else in0)

_Elem = Elem
Elem = OldElem
caught = 0
checked = 0
for n in range(1, N + 1):
    for dests in itertools.combinations(range(N), n):
        pk = [None] * N
        for i in range(n):
            pk[i] = (dests[i], payload_of(i + 1))
        checked += 1
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            good = check(pk, run(pk), "old")
        if not good:
            caught += 1
Elem = _Elem
print(f"4. CONTROL — same suite vs the OLD (buggy) element : "
      f"{caught}/{checked} cases FAIL  "
      f"({'suite is sensitive' if caught else '⚠ SUITE IS BLIND'})")

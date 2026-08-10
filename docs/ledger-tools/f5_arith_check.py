#!/usr/bin/env python3
"""f5_arith_check.py — EXECUTE the emitted netlist and check it against the
kernel's own arithmetic witness. The control for LINK (2), emitS fidelity.

⛔ WHY THIS EXISTS — compiler's ranking, 2026-08-09 19:30, and it is the honest one:

    (1) the DESIGN computes acc - v          ✅ kernel theorems, mutants under them
    (2) the EMITTED artifact IS that design  ⛔ NO CONTROL — and both of us have
                                                been leaning on it all evening
    (3) the emitted artifact's SHAPE matches  ✅ (d), three controls under it

(d) cannot close (2). Compiler said it plainly: arrival-at-the-right-terminal is an
ARITHMETIC fact and no netlist-SHAPE criterion can see it. The partial mutant --
carry-generate rewired, sum XOR intact -- PASSES (d) in its exact form and is still
wrong by one. Shape checks are blind to it.

✅ BUT THE NETLIST IS PURE COMBINATIONAL and2/or2/xor2 IN SSA ORDER, SO IT CAN BE
EXECUTED. This runs the artifact and compares it against the kernel witness that
compiler landed:

    theorem scellSeq_sign_cycle_witness :
      (runTrace scellSeq (bitsOf 3 ++ bitsOf 0) [[true, false, true]]).2
        = bitsOf 6 ++ bitsOf ((0 : BitVec 32) - 3)

⇒ state (wsh=3, acc=0), one cycle of (x=1, load=0, sign=1), expect (wsh=6, acc=-3).
That is an ARITHMETIC check on the ARTIFACT: it tests where the sign ARRIVES, which
is exactly the half (d) is blind to.

⛔ THE FIRST VERSION CHECKED ONLY THAT WITNESS, AND THAT WAS NOT A CONTROL.
MEASURED on this seat's own mutants: the PARTIAL mutant reproduces the witness
EXACTLY and differs from the correct artifact on 25% of swept stimuli. The tool
printed "✅ WITNESS REPRODUCED" for a netlist wrong a quarter of the time -- and I
had just finished writing that a criterion earns its place by what it kills.
⇒ The witness ANCHORS to the landed theorem; a 1,152-point SWEEP against the
two's-complement identity is what DISCRIMINATES. Measured: correct 0 disagreements,
partial 288, full 576.

⚖️ SCOPE, stated so nobody over-reads a green: 1,152 points, ONE CYCLE each, single
cycle state only. It is a CONTROL, not a proof of emission fidelity. Compiler owns
link (2) properly; this gives that link its first negative control from the ARTIFACT
side, tonight, without the fleet lock.

⚠️ AND IT IS NOT A KERNEL RESULT. It is a Python simulation of a Verilog file. It
can only ever DISAGREE usefully: a mismatch is a real finding, a match is evidence
and not a theorem.

EXIT: 0 witness AND sweep clean · 1 MISMATCH (a finding) · 2 could not read/run.
"""

import re
import sys
from pathlib import Path

INSTANCE = re.compile(
    r"^\s*sky130_fd_sc_hd__(?P<type>[a-z0-9_]+)\s+(?P<inst>\S+)\s*\((?P<conns>[^;]*)\);"
)
CONN = re.compile(r"\.(?P<pin>[A-Za-z0-9_]+)\s*\(\s*(?P<net>[^)]*?)\s*\)")
ASSIGN = re.compile(r"^\s*assign\s+(?P<lhs>\w+)\s*=\s*(?P<rhs>\w+)\s*;")

OPS = {
    "and2": lambda a, b: a & b,
    "or2": lambda a, b: a | b,
    "xor2": lambda a, b: a ^ b,
}


def die(msg: str) -> None:
    print(f"f5_arith_check: COULD NOT READ — {msg}", file=sys.stderr)
    sys.exit(2)


def bits_of(v: int, n: int = 32):
    """LSB-first, matching Lean's `bitsOf` convention.

    ⚠️ ASSUMED, then VERIFIED: if this endianness were wrong the witness simply
    would not reproduce, and the tool would report a mismatch it could not explain.
    So the run below tries the stated convention and, on failure, REPORTS what the
    other convention would have given rather than silently trying both and
    announcing whichever worked -- that would make any netlist pass something.
    """
    return [bool((v >> i) & 1) for i in range(n)]


def to_int(bits) -> int:
    return sum(1 << i for i, b in enumerate(bits) if b)


def simulate(path: Path, inputs: dict):
    """Evaluate the netlist. emitS emits SSA, so a single forward pass suffices;
    a gate reading an undefined net is an ERROR, never a default-false."""
    env = dict(inputs)
    gates = assigns = 0
    for line in path.read_text(errors="replace").splitlines():
        m = INSTANCE.match(line)
        if m:
            kind = m.group("type").split("_")[0]
            if kind not in OPS:
                die(f"unknown cell type {m.group('type')} — this simulator knows "
                    f"{sorted(OPS)} only, and guessing a truth table is how a "
                    "simulation starts agreeing with everything")
            c = {x.group("pin"): x.group("net") for x in CONN.finditer(m.group("conns"))}
            a, b, x = c.get("A"), c.get("B"), c.get("X")
            for net in (a, b):
                if net not in env:
                    die(f"gate {m.group('inst')} reads undefined net {net!r} — the "
                        "netlist is not in SSA order, or an input is missing")
            env[x] = OPS[kind](env[a], env[b])
            gates += 1
            continue
        m = ASSIGN.match(line)
        if m:
            rhs = m.group("rhs")
            if rhs not in env:
                die(f"assign reads undefined net {rhs!r}")
            env[m.group("lhs")] = env[rhs]
            assigns += 1
    return env, gates, assigns


def main() -> None:
    if len(sys.argv) < 2:
        die("usage: f5_arith_check.py <emitted-netlist.v>")
    path = Path(sys.argv[1])
    if not path.is_file():
        die(f"no such file: {path}")

    # THE WITNESS, transcribed from the landed theorem and cited in full so a
    # reader checks the transcription rather than trusting it:
    #   scellSeq_sign_cycle_witness :
    #     (runTrace scellSeq (bitsOf 3 ++ bitsOf 0) [[true, false, true]]).2
    #       = bitsOf 6 ++ bitsOf ((0 : BitVec 32) - 3)
    W_IN, ACC_IN = 3, 0
    X, LOAD, SIGN = True, False, True
    W_OUT, ACC_OUT = 6, (-3) & 0xFFFFFFFF

    # port map, from MacCell.lean: ccX 0 · ccLoad 1 · ccCin/scSign 2 ·
    #                              ccWsh k = 3+k · ccAcc k = 35+k
    inputs = {"i0": X, "i1": LOAD, "i2": SIGN}
    for k, b in enumerate(bits_of(W_IN)):
        inputs[f"i{3 + k}"] = b
    for k, b in enumerate(bits_of(ACC_IN)):
        inputs[f"i{35 + k}"] = b

    env, ngates, nassigns = simulate(path, inputs)

    outs = []
    k = 0
    while f"o{k}" in env:
        outs.append(env[f"o{k}"])
        k += 1
    if len(outs) != 96:
        die(f"expected 96 outputs, drove {len(outs)} — wrong artifact?")

    print("=" * 72)
    print("F5 ARITHMETIC CHECK — the emitted netlist EXECUTED against the kernel witness")
    print("=" * 72)
    print(f"ARTIFACT   {path}")
    print(f"EVALUATED  {ngates} gates · {nassigns} assigns · 96 outputs driven")
    print(f"WITNESS    scellSeq_sign_cycle_witness (landed, decide +kernel)")
    print(f"STIMULUS   wsh={W_IN} acc={ACC_IN} · x={int(X)} load={int(LOAD)} sign={int(SIGN)}")
    print(f"EXPECTED   wsh={W_OUT} acc={ACC_OUT} (= 0 - 3 in BitVec 32)")

    # outs = 32 outputs ++ 64 next-state; the state half is the last 64.
    state = outs[32:]
    got_w, got_acc = to_int(state[:32]), to_int(state[32:])
    print(f"GOT        wsh={got_w} acc={got_acc}")
    print("-" * 72)

    witness_ok = (got_w == W_OUT and got_acc == ACC_OUT)
    print(("✅ WITNESS REPRODUCED" if witness_ok else "⛔ WITNESS MISMATCH")
          + " (the landed theorem's single cycle)")

    # ⛔⛔ AND ONE WITNESS IS NOT A CONTROL. MEASURED, on this seat's own mutants:
    # the PARTIAL mutant reproduces this witness EXACTLY and differs from the
    # correct artifact on 200 of 800 swept stimuli (25%). My first version of this
    # tool printed "✅ WITNESS REPRODUCED" for a netlist that is wrong a quarter of
    # the time -- a control with one stimulus passes most of a broken design.
    # 🔑 Same family as a criterion that cannot fail: a control whose coverage is
    # one point measures almost nothing and reads exactly like coverage.
    # ⇒ The witness ANCHORS to the landed theorem; the SWEEP is what discriminates.
    #
    # THE REFERENCE is the two's-complement identity the design is built on:
    #     acc_next = acc + (andWord x w XOR sign) + sign
    # VALIDATED against the correct artifact before being trusted as a reference:
    # 1152 stimuli, 0 disagreements.
    M = 0xFFFFFFFF

    def spec(w, acc, x, ld, sg):
        raw = w if x else 0
        return (acc + ((raw ^ M) if sg else raw) + (1 if sg else 0)) & M

    vals = [0, 1, 3, 7, 255, 65535, 0x7FFFFFFF, 0xFFFFFFFF,
            0xAAAAAAAA, 0x55555555, 12345, 0x80000000]
    bad, total, first = 0, 0, None
    for w in vals:
        for acc in vals:
            for x in (True, False):
                for ld in (True, False):
                    for sg in (True, False):
                        total += 1
                        inp = {"i0": x, "i1": ld, "i2": sg}
                        for k, b in enumerate(bits_of(w)):
                            inp[f"i{3 + k}"] = b
                        for k, b in enumerate(bits_of(acc)):
                            inp[f"i{35 + k}"] = b
                        e, _, _ = simulate(path, inp)
                        st = [e[f"o{k}"] for k in range(96)][32:]
                        got = to_int(st[32:])
                        want = spec(w, acc, x, ld, sg)
                        if got != want:
                            bad += 1
                            if first is None:
                                first = (w, acc, x, ld, sg, want, got)
    print(f"SWEEP      {total} stimuli against acc + (andWord x w XOR sign) + sign")
    print(f"           {bad} disagreement(s)"
          + ("" if bad else " — the artifact realises the identity on every point tested"))
    print("-" * 72)

    if witness_ok and bad == 0:
        print("✅ LINK (2) CONTROL PASSES — witness reproduced AND the sweep is clean.")
        print(f"   ⚠️ SCOPE: {total} points, one cycle each, single-cycle state only.")
        print("   Evidence for emission fidelity, not a proof of it. Compiler owns (2).")
        sys.exit(0)

    print("⛔ MISMATCH — THIS IS A FINDING.")
    if not witness_ok:
        print(f"   witness: wsh expected {W_OUT} got {got_w} · "
              f"acc expected {ACC_OUT} got {got_acc}")
    if bad:
        w, acc, x, ld, sg, want, got = first
        print(f"   sweep: {bad}/{total} disagree. First: w={w} acc={acc} "
              f"x={int(x)} load={int(ld)} sign={int(sg)} -> expected {want}, got {got}")
        if (got - want) & M == M:
            print("   📌 got = expected - 1: the carry-in never arrived. The OFF-BY-ONE")
            print("      (d) cannot see, because arrival is arithmetic and (d) is shape.")
    sys.exit(1)

    print("⛔ MISMATCH — THIS IS A FINDING.")
    print(f"   wsh  expected {W_OUT}  got {got_w}   {'ok' if got_w == W_OUT else 'DIFFERS'}")
    print(f"   acc  expected {ACC_OUT}  got {got_acc} {'ok' if got_acc == ACC_OUT else 'DIFFERS'}")
    if got_acc == ((~ACC_IN - W_IN) & 0xFFFFFFFF) or got_acc == ((ACC_IN + ~W_IN) & 0xFFFFFFFF):
        print("   📌 acc looks like acc + ~v (the carry-in never arrived) — the")
        print("      OFF-BY-ONE this check exists to catch, which (d) cannot see.")
    sys.exit(1)


if __name__ == "__main__":
    main()

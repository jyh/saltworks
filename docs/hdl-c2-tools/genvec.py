#!/usr/bin/env python3
"""C2 GENERATOR — Spike-witnessed (state, instr, state') vectors for SaltWorks.

Council ruling 3: Spike is a WITNESS, not an oracle.  This program is the
untrusted offline generator; every claim it supports is kernel-checked on the
Lean side by `Vec.checkFull`.

THREE DESIGN RULES, each of which this program obeys mechanically:

  R1  THE PRE-STATE IS READ BACK FROM THE WITNESS, NEVER ASSUMED.
      The prologue that materialises a state is itself made of instructions
      under test, and Spike's reset sequence leaves registers non-zero that
      we never wrote (measured: t0 = 0x80000000, a1 = 0x1020).  A vector that
      states an assumed pre-state is a vector about a state the witness was
      never in.

  R2  THE INSTRUCTION WORD COMES FROM THE ASSEMBLER, NOT FROM OUR `encode`.
      We write a mnemonic; riscv64-elf-as encodes it; we read the resulting
      32 bits out of Spike's own disassembly line.  `SaltWorks.ISA.encode`
      appears nowhere in this path, so a bug in it cannot make a vector agree.

  R3  ONLY WHAT THE WITNESS SAID IS WRITTEN DOWN.  post is a diff of two
      register dumps taken from Spike; pc and pc' likewise.
"""
import os, random, re, subprocess, sys, tempfile

SP = os.path.dirname(os.path.abspath(__file__))
SPIKE = os.path.join(SP, "inst", "bin", "spike")

LD = """OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS { . = 0x80000000; .text : { *(.text) } .data : { *(.data) } }
"""

ABI = ["zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1",
       "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7",
       "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11",
       "t3", "t4", "t5", "t6"]
IDX = {n: i for i, n in enumerate(ABI)}
IDX["fp"] = 8

M32 = 0xFFFFFFFF


def asm_source(pre, mnemonic):
    """pre: {1..31: value}.  mnemonic: assembly text of the instruction under test."""
    out = [".section .text", ".globl _start", "_start:"]
    for r in range(1, 32):
        out.append("  li x%d, 0x%08x" % (r, pre.get(r, 0) & M32))
    out.append("test_instr:")
    out.append("  " + mnemonic)          # <- the ASSEMBLER encodes this
    out.append("  nop\n  nop\n  nop\n  nop\n  nop\n  nop\n  nop\n  nop")
    out.append("  nop\n  nop\n  nop\n  nop\n  nop\n  nop\n  nop\n  nop")
    out.append("after:\n  j after")
    out.append(".section .data")
    # .align 3 IS LOAD-BEARING.  fesvr reads tohost as an 8-byte object and
    # throws `misaligned address` if it is not 8-aligned.  .text's length
    # varies with how many `li`s expand to lui+addi — i.e. with the RANDOM
    # PRE-STATE VALUES — so without this, ~44% of vectors are rejected and
    # the rejection is CORRELATED WITH THE VALUE DISTRIBUTION being sampled.
    out.append(".align 3")
    out.append("tohost:   .dword 0")
    out.append("fromhost: .dword 0")
    return "\n".join(out) + "\n"


def build_elf(src, d):
    s, o, e, l = (os.path.join(d, n) for n in ("t.s", "t.o", "t.elf", "t.ld"))
    open(s, "w").write(src)
    open(l, "w").write(LD)
    subprocess.run(["riscv64-elf-as", "-march=rv32i", "-mabi=ilp32", s, "-o", o],
                   check=True, capture_output=True)
    subprocess.run(["riscv64-elf-ld", "-m", "elf32lriscv", "-T", l, o, "-o", e],
                   check=True, capture_output=True)
    return e


def sym(elf, name):
    out = subprocess.run(["riscv64-elf-nm", elf], check=True,
                         capture_output=True, text=True).stdout
    for ln in out.splitlines():
        f = ln.split()
        if len(f) == 3 and f[2] == name:
            return int(f[0], 16)
    raise KeyError(name)


def parse_regs(block):
    vals = {}
    for tok, hexv in re.findall(r"([a-z][a-z0-9]*)\s*:\s*0x([0-9a-fA-F]+)", block):
        if tok in IDX:
            vals[IDX[tok]] = int(hexv, 16) & M32
    return vals


TRACE = re.compile(r"core\s+\d+:\s+0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)\s*(.*)")


def one(pre, mnemonic, d):
    """Return a vector dict, or None if Spike did not produce a clean triple."""
    elf = build_elf(asm_source(pre, mnemonic), d)
    tpc = sym(elf, "test_instr")
    cmds = os.path.join(d, "cmd")
    open(cmds, "w").write("until pc 0 %#x\nreg 0\npc 0\nrun 1\nreg 0\npc 0\nquit\n" % tpc)
    p = subprocess.run([SPIKE, "--isa=rv32i", "-d", "--debug-cmd=" + cmds, elf],
                       capture_output=True, text=True, timeout=60)
    txt = p.stderr + p.stdout
    # Layout: <regdump A> <pc> <trace line> <regdump B> <pc'>
    m = TRACE.search(txt)
    if not m:
        return None
    word = int(m.group(2), 16)
    disasm = m.group(3).strip()
    head, tail = txt[:m.start()], txt[m.end():]
    pcs = re.findall(r"^\s*0x([0-9a-fA-F]{8})\s*$", txt, re.M)
    if len(pcs) < 2:
        return None
    pre_r, post_r = parse_regs(head), parse_regs(tail)
    if not pre_r or not post_r:
        return None
    pc, pc2 = int(pcs[0], 16) & M32, int(pcs[1], 16) & M32
    if pc != tpc:
        return None
    return {"pre": {r: v for r, v in pre_r.items() if r != 0 and v != 0},
            "pc": pc, "word": word, "disasm": disasm,
            "post": {r: v for r, v in post_r.items()
                     if r != 0 and pre_r.get(r, 0) != v},
            "pc2": pc2}


def rand_val(rng):
    """Values biased to the corners that break implementations."""
    return rng.choice([0, 1, M32, 0x7FFFFFFF, 0x80000000, 2, 0xFFFFFFFE,
                       rng.getrandbits(32), rng.getrandbits(32),
                       rng.getrandbits(8), rng.getrandbits(16)]) & M32


KINDS = ["add", "addi", "xor", "slt", "beq"]


def rand_case(rng, pre, i):
    """STRATIFIED by instruction — round-robin, so a rare random draw cannot
    leave an instruction untested.  Returns (mnemonic, possibly-mutated pre)."""
    kind = KINDS[i % len(KINDS)]
    rd, a, b = rng.randrange(32), rng.randrange(32), rng.randrange(32)
    # x0 as DESTINATION — silicon's P5, the strongest single vector shape.
    if rng.random() < 0.15:
        rd = 0
    # rd aliasing a source: the in-place case a plausible implementation breaks.
    if rng.random() < 0.15:
        rd = a
    if kind == "addi":
        imm = rng.choice([0, 1, -1, 2047, -2048, rng.randrange(-2048, 2048)])
        return "addi x%d, x%d, %d" % (rd, a, imm), pre
    if kind == "beq":
        # HALF THE BRANCHES MUST BE TAKEN, or BEQ is untested in the direction
        # that matters: a random 32-bit pair is essentially never equal.
        if rng.random() < 0.5:
            if rng.random() < 0.3:
                b = a                       # same register — trivially equal
            else:
                pre = dict(pre)
                if a != 0 and b != 0:
                    pre[b] = pre.get(a, 0)  # forced equal via the pre-state
                elif a == 0 and b != 0:
                    pre[b] = 0
                elif b == 0 and a != 0:
                    pre[a] = 0
        # FORWARD ONLY — the consumer's stated promise (Vectors.lean:116).
        return ("beq x%d, x%d, test_instr + %d"
                % (a, b, rng.choice([4, 8, 16, 32])), pre)
    return "%s x%d, x%d, x%d" % (kind, rd, a, b), pre


def lean_vec(v):
    def sparse(d):
        return "[" + ", ".join("(%d, 0x%08X)" % (r, x) for r, x in sorted(d.items())) + "]"
    return ("  { pre := %s, pc := 0x%08X, word := 0x%08X,\n    post := %s, pc' := 0x%08X }"
            % (sparse(v["pre"]), v["pc"], v["word"], sparse(v["post"]), v["pc2"]))


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 20260807
    rng = random.Random(seed)
    vecs, tried, kinds, taken = [], 0, {}, 0
    d = tempfile.mkdtemp()
    while len(vecs) < n and tried < n * 4:
        pre = {r: rand_val(rng) for r in range(1, 32)}
        mn, pre = rand_case(rng, pre, tried)
        tried += 1
        v = one(pre, mn, d)
        if v is None:
            continue
        k = mn.split()[0]
        kinds[k] = kinds.get(k, 0) + 1
        if k == "beq" and v["pc2"] != (v["pc"] + 4) & M32:
            taken += 1
        vecs.append(v)
    sys.stderr.write("generated %d/%d (tried %d) kinds=%s beq_taken=%d\n"
                     % (len(vecs), n, tried, kinds, taken))
    for v in vecs:
        print(lean_vec(v) + ",   -- " + v["disasm"])


if __name__ == "__main__":
    main()

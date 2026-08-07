#!/usr/bin/env python3
"""C2 — the REJECTION arm: words the vector format cannot represent.

`Vec.actual` is `Option St` and `checkFull` compares against `some`, so a word
that BOTH sides reject — real agreement, and the case where a third-party word
is most informative — has no `Vec`.  This program supplies that arm as two
lists, and Lean checks our side of each by `decide +kernel`.

TWO CLASSES, AND THEY MUST NOT BE MERGED:

  A  Spike TRAPS (trap_illegal_instruction) and `decode` returns none
     -> GENUINE AGREEMENT on rejection.

  B  Spike EXECUTES the word and `decode` returns none
     -> DISAGREEMENT, AND OURS IS CORRECT.  These are legal RV32I instructions
        that Slice A deliberately excludes.  Treating Spike as an ORACLE here
        would "fix" decode to accept LUI and silently destroy the stated scope.
        This is the class that makes "witness, not oracle" concrete.
"""
import os, random, re, subprocess, sys, tempfile

SP = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SP)
import genvec

SAIL = os.path.join(SP, "sail-riscv", "build", "c_emulator", "sail_riscv_sim")
TRAP = re.compile(r"trap_illegal_instruction|illegal", re.I)

# Legal RV32I, deliberately outside Slice A (ADD/ADDI/XOR/SLT/BEQ).
EXCLUDED = [
    "lui x1, 1", "auipc x2, 1", "jal x1, test_instr + 8", "jalr x1, x2, 0",
    "lw x1, 0(x2)", "sw x1, 0(x2)", "lb x3, 4(x2)", "sb x3, 4(x2)",
    "sll x3, x1, x2", "srl x3, x1, x2", "sra x3, x1, x2",
    "or x3, x1, x2", "and x3, x1, x2", "sub x3, x1, x2",
    "sltu x3, x1, x2", "xori x3, x1, 5", "ori x3, x1, 5", "andi x3, x1, 5",
    "slti x3, x1, 5", "bne x1, x2, test_instr + 8",
    "blt x1, x2, test_instr + 8", "bge x1, x2, test_instr + 8",
]


def spike_verdict(word_or_mn, d, raw=True):
    """Return (word, 'trap'|'exec', disasm)."""
    body = (".word 0x%08x" % word_or_mn) if raw else word_or_mn
    elf = genvec.build_elf(genvec.asm_source({1: 5, 2: 7}, body), d)
    tpc = genvec.sym(elf, "test_instr")
    cmds = os.path.join(d, "cmd")
    open(cmds, "w").write("until pc 0 %#x\nrun 1\npc 0\nquit\n" % tpc)
    p = subprocess.run([genvec.SPIKE, "--isa=rv32i", "-d", "--debug-cmd=" + cmds, elf],
                       capture_output=True, text=True, timeout=60)
    txt = p.stderr + p.stdout
    m = genvec.TRACE.search(txt)
    if TRAP.search(txt):
        # recover the word from tval, or from the raw request
        tv = re.search(r"tval 0x([0-9a-fA-F]+)", txt)
        w = int(tv.group(1), 16) if tv else (word_or_mn if raw else None)
        return w, "trap", ""
    if m:
        return int(m.group(2), 16), "exec", m.group(3).strip()
    return None, "?", ""


def sail_verdict(word, d):
    """Independent second opinion on the SAME word."""
    elf = genvec.build_elf(genvec.asm_source({1: 5, 2: 7}, ".word 0x%08x" % word), d)
    apc = genvec.sym(elf, "after")
    p = subprocess.run([SAIL, "--rv32", "--trace-instr", "--trace-gpr",
                        "--stop-at-pc", hex(apc), elf],
                       capture_output=True, text=True, timeout=60)
    txt = p.stdout + p.stderr
    return "trap" if TRAP.search(txt) else "exec"


def main():
    nA = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    rng = random.Random(int(sys.argv[2]) if len(sys.argv) > 2 else 8072026)
    d = tempfile.mkdtemp()

    classA, tried, sail_disagree = [], 0, []
    while len(classA) < nA and tried < nA * 40:
        tried += 1
        w = rng.getrandbits(32)
        got, verdict, _ = spike_verdict(w, d)
        if verdict != "trap" or got != w:
            continue
        sv = sail_verdict(w, d)
        if sv != "trap":
            sail_disagree.append((w, sv))
            continue
        classA.append(w)

    classB = []
    for mn in EXCLUDED:
        w, verdict, dis = spike_verdict(mn, d, raw=False)
        if verdict == "exec":
            classB.append((w, dis))

    sys.stderr.write("class A (both witnesses TRAP): %d of %d tried\n" % (len(classA), tried))
    sys.stderr.write("class B (Spike EXECUTES, Slice A excludes): %d\n" % len(classB))
    sys.stderr.write("SAIL/Spike disagreements on class A: %d %s\n"
                     % (len(sail_disagree), sail_disagree[:5]))

    print("-- CLASS A: Spike traps, SAIL traps")
    for w in classA:
        print("  0x%08X#32," % w)
    print("-- CLASS B: Spike executes; Slice A excludes")
    for w, dis in classB:
        print("  0x%08X#32,   -- %s" % (w, dis))


if __name__ == "__main__":
    main()

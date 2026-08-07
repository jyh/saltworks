#!/usr/bin/env python3
"""C2 — the ONE-TIME SAIL CROSS-CHECK (council ruling 3's second reference).

Replays the EXACT 120 vectors landed in SaltWorks/HDL/SpikeVectors.lean through
the official Sail RISC-V model and compares SAIL's answer against what is
written in the Lean file.

WHAT IS COMPARED, and it is deliberately the file rather than a fresh Spike run:
the landed `pre`/`word` are rebuilt into an ELF, SAIL executes it, and SAIL's
post-state and pc' are checked against the landed `post`/`pc'`. A fresh Spike
run agreeing with a fresh SAIL run would be a weaker statement — it would not
tie SAIL to the artifact the kernel actually checks.

CORRELATED-ERROR NOTE: Spike and SAIL are independent implementations, but they
are not independent of the RISC-V manual. Three-way agreement excludes an error
in any ONE of them; it does not exclude an error the specification itself
carries.

METHOD NOTE, stated because it differs from the Spike harness: Spike's debug
mode dumps the whole register file, so nothing is reconstructed there. SAIL
offers no register dump, only a write trace -- so the state here IS rebuilt, by
replaying the "reg <- value" events SAIL itself emits. That is bookkeeping over
the witness's own statements, not a second model of the machine; but it is a
weaker instrument than Spike's and is labelled as such.
"""
import os, re, subprocess, sys, tempfile

SP = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.join(SP, "sail-riscv", "build", "c_emulator", "sail_riscv_sim")
LEAN = "/Users/jyh/projects/claude/saltworks/SaltWorks/HDL/SpikeVectors.lean"
M32 = 0xFFFFFFFF

sys.path.insert(0, SP)
import genvec

VEC = re.compile(
    r"\{\s*pre\s*:=\s*\[(?P<pre>[^\]]*)\]\s*,\s*pc\s*:=\s*0x(?P<pc>[0-9A-Fa-f]+)\s*,"
    r"\s*word\s*:=\s*0x(?P<word>[0-9A-Fa-f]+)\s*,\s*post\s*:=\s*\[(?P<post>[^\]]*)\]"
    r"\s*,\s*pc'\s*:=\s*0x(?P<pc2>[0-9A-Fa-f]+)\s*\}")
PAIR = re.compile(r"\(\s*(\d+)\s*,\s*0x([0-9A-Fa-f]+)\s*\)")


def parse_lean():
    src = open(LEAN).read()
    start = src.index("def spikeSuite")
    body = src[start:src.index("\n/-!", start)]
    out = []
    for m in VEC.finditer(body):
        out.append({
            "pre": {int(r): int(v, 16) for r, v in PAIR.findall(m.group("pre"))},
            "pc": int(m.group("pc"), 16),
            "word": int(m.group("word"), 16),
            "post": {int(r): int(v, 16) for r, v in PAIR.findall(m.group("post"))},
            "pc2": int(m.group("pc2"), 16),
        })
    return out


ABI = genvec.ABI
IDX = genvec.IDX
WRITE = re.compile(r"^([a-z][a-z0-9]*)\s*<-\s*0x([0-9A-Fa-f]+)\s*$")
INSTR = re.compile(r"^\[\d+\]\s*\[\w+\]:\s*0x([0-9A-Fa-f]+)\s*\(0x([0-9A-Fa-f]+)\)")


def sail_step(pre, word, d):
    """Build the ELF from the LANDED pre/word, run SAIL, return (pc, post, pc')."""
    # .word emits OUR exact landed word — no mnemonic, no re-encoding.
    src = genvec.asm_source(pre, ".word 0x%08x" % word)
    elf = genvec.build_elf(src, d)
    tpc, apc = genvec.sym(elf, "test_instr"), genvec.sym(elf, "after")
    p = subprocess.run([SIM, "--rv32", "--use-abi-names", "--trace-instr",
                        "--trace-gpr", "--stop-at-pc", hex(apc), elf],
                       capture_output=True, text=True, timeout=120)
    lines = (p.stdout + p.stderr).splitlines()

    regs, cur_pc, pre_state, post_state, seen, nxt = {}, None, None, None, False, None
    for ln in lines:
        ln = ln.strip()
        mi = INSTR.match(ln)
        if mi:
            pc = int(mi.group(1), 16)
            if seen and nxt is None:          # the instruction AFTER the test one
                nxt = pc
                post_state = dict(regs)
            if pc == tpc:
                pre_state = dict(regs)        # state entering the test instruction
                seen = True
            cur_pc = pc
            continue
        mw = WRITE.match(ln)
        if mw and mw.group(1) in IDX:
            regs[IDX[mw.group(1)]] = int(mw.group(2), 16) & M32
    if post_state is None and seen:
        post_state = dict(regs)
    if pre_state is None:
        return None
    return tpc, pre_state, post_state, nxt


def main():
    vecs = parse_lean()
    print("parsed %d vectors from %s" % (len(vecs), os.path.basename(LEAN)))
    if not vecs:
        sys.exit("PARSE FAILED — refusing to report agreement on an empty set")
    d = tempfile.mkdtemp()
    agree, disagree, skipped = 0, [], 0
    for i, v in enumerate(vecs):
        r = sail_step(v["pre"], v["word"], d)
        if r is None:
            skipped += 1
            continue
        tpc, pre_s, post_s, nxt = r
        why = []
        if tpc != v["pc"]:
            why.append("pc %#x vs landed %#x" % (tpc, v["pc"]))
        # SAIL's pre-state must match the landed pre (non-zero entries)
        sail_pre = {r_: x for r_, x in pre_s.items() if r_ != 0 and x != 0}
        if sail_pre != v["pre"]:
            d1 = {k: (sail_pre.get(k), v["pre"].get(k))
                  for k in set(sail_pre) | set(v["pre"])
                  if sail_pre.get(k) != v["pre"].get(k)}
            why.append("pre differs: %s" % d1)
        sail_post = {r_: x for r_, x in (post_s or {}).items()
                     if r_ != 0 and pre_s.get(r_, 0) != x}
        if sail_post != v["post"]:
            why.append("post %s vs landed %s" % (sail_post, v["post"]))
        if nxt is not None and nxt != v["pc2"]:
            why.append("pc' %#x vs landed %#x" % (nxt, v["pc2"]))
        if why:
            disagree.append((i, v["word"], why))
        else:
            agree += 1
    print("\n=== SAIL CROSS-CHECK vs the LANDED suite ===")
    print("agree     %d" % agree)
    print("disagree  %d" % len(disagree))
    print("skipped   %d  (SAIL produced no usable trace)" % skipped)
    for i, w, why in disagree[:10]:
        print("  [%3d] word=0x%08X  %s" % (i, w, "; ".join(why)))
    if disagree:
        sys.exit(1)


if __name__ == "__main__":
    main()

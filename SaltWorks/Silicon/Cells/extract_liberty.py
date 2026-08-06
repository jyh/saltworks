#!/usr/bin/env python3
"""Extract exact Boolean functions for sky130 standard cells from the PDK's own
Liberty file.

WHY THIS EXISTS. The Lean cell models are TRUSTED — a wrong model makes the whole
equivalence chain vacuous. So they must not be hand-guessed. This reads the
vendor's machine-readable spec and prints, for each cell, its input pins and the
verbatim `function` string (or, for sequential cells, the `ff` block's
next_state / clocked_on). Those strings are the source the Lean models in
SaltWorks/Silicon/Cells/ are written against, and a diff against this output is
the first of the model cross-checks (see the refuter doc, R2).

This script is DEV TOOLING, not part of the trusted base: nothing it prints is
believed without a human reading it into a Lean definition, and the Lean
definitions are what the kernel sees.

    ./extract_liberty.py                      # the cells our designs actually use
    ./extract_liberty.py nand2_1 mux2_1 ...   # named cells
    ./extract_liberty.py --all                # every cell in the library

Liberty is located via PDK_ROOT / PDK_VER, same defaults as ../Flow/synth.sh.
"""
import os, re, sys

# The union of cells that synthesis of our two designs actually selected
# (see ../Flow/*_stat.txt). NOT a frozen trusted set — see hardware-versions.md §3.
DEFAULT_CELLS = [
    "a222oi_1", "a22oi_1", "a31oi_1", "and2_0", "clkinv_1",
    "lpflow_inputiso1p_1", "lpflow_isobufsrc_1", "mux2_1", "mux2i_1",
    "nand2_1", "o22ai_1", "o2bb2ai_1", "dfxtp_1",
]

PDK_VER = os.environ.get("PDK_VER", "c6d73a35f524070e85faff4a6a9eef49553ebc2b")
PDK_ROOT = os.environ.get(
    "PDK_ROOT", os.path.expanduser(f"~/.volare/volare/sky130/versions/{PDK_VER}"))
LIB = os.path.join(
    PDK_ROOT, "sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib")


def blocks(s, kw):
    """Yield (name, body) for each `kw ("name") { ... }`, brace-matched.

    Liberty is not regular -- pin blocks nest inside cell blocks and both nest
    timing/power blocks -- so match braces rather than trusting indentation.
    The (?<![a-z_]) guard stops `pin` from also matching `pg_pin`. The header
    may carry several comma-separated quoted args -- `ff ("IQ","IQ_N")` -- so
    take everything up to the closing paren and strip quotes afterwards.
    """
    for m in re.finditer(r'(?<![a-z_])' + kw + r'\s*\(([^)]*)\)\s*\{', s):
        i = s.index('{', m.end() - 1)
        depth, j = 0, i
        while True:
            if s[j] == '{':
                depth += 1
            elif s[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        yield m.group(1).replace('"', '').strip(), s[i + 1:j]


def attr(key, body):
    """A Liberty scalar attribute; values may or may not be quoted."""
    m = re.search(key + r'\s*:\s*"?([^";]*)"?\s*;', body)
    return m.group(1).strip() if m else None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    want = None if "--all" in sys.argv else set(args or DEFAULT_CELLS)

    if not os.path.exists(LIB):
        sys.exit(f"liberty not found: {LIB}\n"
                 f"  fetch with: volare enable --pdk sky130 {PDK_VER}")
    txt = open(LIB).read()

    print(f"# source : {LIB}")
    print(f"# pdk    : {PDK_VER}")
    print(f"# NOTE   : every cell also carries pg_pins VPWR/VGND/VPB/VNB, which the")
    print(f"#          importer discards -- exactly four per instance, always.\n")

    seen = set()
    for name, body in blocks(txt, 'cell'):
        short = name.replace("sky130_fd_sc_hd__", "")
        if want is not None and short not in want:
            continue
        seen.add(short)
        ins, outs = [], []
        for pin, pb in blocks(body, 'pin'):
            d = attr('direction', pb)
            if d == 'input':
                ins.append(pin)
            elif d == 'output':
                f = re.search(r'\n\s*function\s*:\s*"([^"]*)"', pb)
                outs.append((pin, f.group(1) if f else '(sequential)'))
        seq = ""
        for ffname, fb in blocks(body, 'ff'):
            seq = f"   [FF {ffname}: next_state={attr('next_state', fb)} clocked_on={attr('clocked_on', fb)}]"
        fn = "; ".join(f"{o} = {e}" for o, e in outs)
        print(f"{short:22s} in=({','.join(ins)})")
        print(f"{'':22s} {fn}{seq}")

    if want is not None:
        for missing in sorted(want - seen):
            print(f"{missing:22s} !! NOT FOUND IN LIBRARY", file=sys.stderr)


if __name__ == "__main__":
    main()

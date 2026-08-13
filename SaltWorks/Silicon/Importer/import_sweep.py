#!/usr/bin/env python3
"""IMPORT SWEEP — for every netlist in Flow/, does the importer ACCEPT it, and if
not, what is the actual blocker?

## Why this exists, and what it is NOT

`docs/silicon-cell-coverage-census-0812.md` measures CELL COVERAGE. Its own §7
says a cell-clean netlist is not promised to import — and within the hour that
caveat fired: `dmem_addr8` and `dmem_addr16` were cell-clean and refused anyway,
on the range-assign grammar. Cell coverage is a proxy. **This is the ground
truth the proxy was standing in for.**

⛔ **THIS SWEEP ANSWERS "DOES IT IMPORT", NOT "IS THIS THE RIGHT DATUM."**

The port ORDER of a datum is load-bearing and is NOT recoverable from the
netlist — `reimport.sh` records that for the two data whose orders were lost,
and `readback.py` records that a swapped `--outputs` pair permutes the datum and
its reference identically, so nothing catches it. This tool derives *a* valid
port list from the module's own declaration purely to drive the importer. **A
netlist reported IMPORTS here has not been shown to yield the datum any
downstream proof wants.** Nothing it produces is written to the tree.

    ./import_sweep.py            # sweep Flow/*.v
    ./import_sweep.py dmem16     # one netlist, full importer output
"""
import os, re, sys, subprocess, collections, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FLOW = os.path.join(HERE, "..", "Flow")
IMP = os.path.join(HERE, "import_netlist.py")

MODULE_RE = re.compile(r"^\s*module\s+(\w+)\s*\(", re.M)
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?(\w+)\s*;", re.M)


def ports_of(text):
    """-> (module_name, [(dir, name, width_or_None)]) in DECLARATION order.

    Declaration order is the only order available. It is not asserted to be the
    order any downstream datum wants — see the module docstring."""
    m = MODULE_RE.search(text)
    if not m:
        return None, []
    seen, out = set(), []
    for d, hi, lo, name in PORT_RE.findall(text):
        if name in seen:
            continue                      # yosys re-declares each port as a wire
        seen.add(name)
        width = None if hi is None or hi == "" else (int(hi) - int(lo) + 1)
        out.append((d, name, width))
    return m.group(1), out


def expand(name, width):
    return [name] if width is None else [f"{name}[{i}]" for i in range(width)]


def blocker(log, path_hint=""):
    """Classify the importer's refusal from its own message. Unrecognised text
    is reported VERBATIM as 'other' — never bucketed into a known class."""
    for line in log.splitlines():
        if "no expansion for cell" in line:
            c = re.search(r"cell '([^']+)'", line)
            return "unmodelled-cell", (c.group(1) if c else line.strip())
        if "unmodelled sequential cell" in line:
            c = re.search(r"cell\(s\): (\S+)", line)
            return "unmodelled-flop", (c.group(1) if c else line.strip())
        if "uses a RANGE" in line:
            return "range-grammar", line.split("--")[0].strip()
        if line.startswith("importer:") and "wrote" not in line \
                and line[len("importer:"):].strip() not in (path_hint, ""):
            return "other", line[len("importer:"):].strip()
    return "other", (log.strip().splitlines() or ["<no output>"])[-1]


def sweep_one(fn, verbose=False):
    path = os.path.join(FLOW, fn)
    text = open(path).read()
    top, ports = ports_of(text)
    if top is None:
        return ("SKIP", "no module declaration", None)
    ins = [(n, w) for d, n, w in ports if d == "input"]
    outs = [(n, w) for d, n, w in ports if d == "output"]
    if not outs:
        return ("SKIP", "module declares NO outputs — nothing to import", None)
    # async-reset flops must be pinned, and the pinned net must NOT be listed
    # as an input (control NCx). Both facts come from the importer's own rules.
    pin = "rst_n" if "dfrtp" in text and any(n == "rst_n" for n, _ in ins) else None
    inlist, outlist = [], []
    for n, w in ins:
        if n == pin:
            continue
        inlist += expand(n, w)
    for n, w in outs:
        outlist += expand(n, w)
    # ⛔ THE OUTPUT MUST BE A REAL FILE. An earlier draft passed `--out
    # /dev/null` and the sweep reported 0 of 46 importing -- including dmem8,
    # dmem16 and dmem32, which this seat had proved clean twenty minutes
    # earlier. Cause: readback reads the emitted datum back FROM DISK, and
    # /dev/null reads empty, so every netlist that got far enough to be CHECKED
    # was recorded as a failure. The sweep was strictest exactly where the
    # importer was doing the most work. Caught only because the result
    # contradicted a fact already measured.
    with tempfile.TemporaryDirectory() as td:
        cmd = [sys.executable, IMP, path, "--top", top,
               "--out", os.path.join(td, "out.lean"),
               "--name", f"{top}NL", "--inputs", ",".join(inlist),
               "--outputs", ",".join(outlist)]
        if pin:
            cmd += ["--pin-reset", pin]
        p = subprocess.run(cmd, capture_output=True, text=True)
    log = p.stdout + p.stderr
    if verbose:
        print(log)
    if p.returncode == 0:
        g = re.search(r"gates emitted\s*:\s*(\d+)", log)
        f = re.search(r"flops cut\s*:\s*(\d+)", log)
        rb = "readback" in log
        return ("IMPORTS", f"{g.group(1) if g else '?'} gates, "
                           f"{f.group(1) if f else '0'} flops"
                           f"{'' if rb else ', NO READBACK'}", pin)
    return ("BLOCKED",) + blocker(log, path)


def main():
    if len(sys.argv) > 1:
        fn = sys.argv[1]
        if not fn.endswith(".v"):
            fn += "_nl.v"
        print(sweep_one(fn, verbose=True))
        return 0
    files = sorted(f for f in os.listdir(FLOW) if f.endswith(".v"))
    kinds = collections.Counter()
    by_blocker = collections.defaultdict(list)
    imports, skips = [], []
    for fn in files:
        r = sweep_one(fn)
        kinds[r[0]] += 1
        if r[0] == "IMPORTS":
            imports.append((fn, r[1], r[2]))
            print(f"  ✅ {fn:28s} IMPORTS   {r[1]}{'  [pinned ' + r[2] + ']' if r[2] else ''}")
        elif r[0] == "SKIP":
            skips.append((fn, r[1]))
            print(f"  ⚠ {fn:28s} SKIP      {r[1]}")
        else:
            by_blocker[r[1]].append((fn, r[2]))
            print(f"  ⛔ {fn:28s} {r[1]:16s} {r[2]}")

    total = sum(kinds.values())
    print(f"\nimport sweep: {kinds['IMPORTS']} import + {kinds['BLOCKED']} blocked "
          f"+ {kinds['SKIP']} skipped = {total} of {len(files)} netlists")
    if total != len(files):
        print("  ⛔ buckets do not sum to the denominator"); return 1
    print("\nBLOCKERS BY CLASS — ⚠ THE FIRST GATE HIT, NOT THE ONLY ONE:")
    for k, v in sorted(by_blocker.items(), key=lambda kv: -len(kv[1])):
        names = collections.Counter(x[1] for x in v)
        print(f"  {k:16s} {len(v):2d} netlist(s)   {dict(names)}")
    print("  ⚠ The importer refuses at the FIRST problem it meets, and the range")
    print("    check runs BEFORE cell expansion. So a netlist listed under")
    print("    'range-grammar' may ALSO be missing cells, and clearing the grammar")
    print("    would merely advance it to its next refusal. A class count here is")
    print("    NOT the number of netlists that class would free — cross it with the")
    print("    cell census to get that. (Measured 8/12: the grammar is the SOLE")
    print("    remaining gate for 2 of its 13, not for 13.)")
    print("\n⛔ REMINDER: 'IMPORTS' means the importer ACCEPTED a port list derived "
          "from the module\n   declaration. It does NOT mean the resulting datum has "
          "the port ORDER any\n   downstream proof requires — that is unrecoverable "
          "from the netlist.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

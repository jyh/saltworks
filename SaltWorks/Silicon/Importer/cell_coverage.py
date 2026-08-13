#!/usr/bin/env python3
"""CELL COVERAGE CENSUS — for every netlist in Flow/, which cells stand between
it and an import, measured against the importer's OWN resolver.

## Why this exists

`nand4_1` was the single cell between the flow and a clean `dmem8` import. That
was known only because someone ran the importer and read the refusal. For the
other 45 netlists the answer is unknown, and "unknown" is the state in which a
cost gets discovered late. This turns it into a printed, priced list.

## ⛔ THE RULE THIS TOOL EXISTS TO OBEY

**It calls `expansion_for`, `base_of`, `SEQ_MODELS`, `SEQ_PREFIX` and
`PHYSICAL_PREFIX` from `import_netlist` itself. It does not restate them.**

The predecessor of this seat computed "7 missing cells" TWICE, and both times
the number was wrong, because the check compared BASE names against a key set
that mixes full names (`nand2_1`) with base names (`and3`). The resolver's rule
is: exact key first, then drive-stripped. A census that re-types that rule is
testing its own copy. *Cure, both times: read the resolver's own function.*

## The extractor is CONTROLLED, not trusted

A regex over Verilog text is not the importer's parser, so its instance count is
validated against the trusted parser's own reported count on a netlist that
imports cleanly. An extractor whose number nobody checked is how this fleet
spent 8/12; see the four-broken-extractors tally on the bus.

**The controls are not optional and there is no flag to skip them** — they run
first, and a census whose controls fail REFUSES to print (exit 1) rather than
printing numbers with a caveat. *An earlier draft of this docstring advertised a
`--control` flag that was never implemented, which is the same defect this seat
had just reported in the frozen prereg's own reproduction command. A documented
flag that does not exist is a documented command that cannot run.*

    ./cell_coverage.py                 # census over Flow/*.v; controls always run
"""
import os, re, sys, collections, types

HERE = os.path.dirname(os.path.abspath(__file__))
FLOW = os.path.join(HERE, "..", "Flow")
IMPSRC = os.path.join(HERE, "import_netlist.py")

# `import_netlist.py` is a SCRIPT: its argparse runs at module level, so a plain
# `import` of it executes the CLI and exits. The tables and the resolver are all
# defined above that line.
#
# ⛔ So this loads THE IMPORTER'S OWN BYTES, truncated at the CLI — not a copy of
# its rules. The alternative was to restructure the importer under a
# `__main__` guard, which inverts the dependency (a trusted, byte-compared file
# edited to serve a census) for no gain here.
#
# A MOVED CUT POINT IS A REFUSAL, NEVER A SILENT PARTIAL LOAD.
def load_importer_defs():
    src = open(IMPSRC).read()
    marker = "\nap = argparse.ArgumentParser()"
    if src.count(marker) != 1:
        sys.exit("⛔ REFUSING: cannot locate the single CLI boundary in "
                 "import_netlist.py; its structure changed. Fix this tool, do "
                 "not guess a cut point.")
    mod = types.ModuleType("import_netlist_defs")
    mod.__file__ = IMPSRC
    exec(compile(src[:src.index(marker)], IMPSRC, "exec"), mod.__dict__)
    need = ("EXPAND", "SEQ_MODELS", "SEQ_PREFIX", "PHYSICAL_PREFIX",
            "expansion_for", "base_of")
    absent = [n for n in need if not hasattr(mod, n)]
    if absent:
        sys.exit(f"⛔ REFUSING: the truncated load is missing {absent}")
    return mod

IMP = load_importer_defs()          # the resolver, not a copy of it
CELL_RE = re.compile(r"sky130_fd_sc_hd__(\w+)")


def cells_of(path):
    """-> Counter of cell-name -> instance count, by text scan."""
    with open(path) as f:
        return collections.Counter(CELL_RE.findall(f.read()))


def classify(cell):
    """-> 'physical' | 'seq-ok' | 'seq-MISSING' | 'logic-ok' | 'logic-MISSING'.

    Every branch delegates to the importer's own predicates."""
    if cell.startswith(IMP.PHYSICAL_PREFIX):
        return "physical"
    if cell.startswith(IMP.SEQ_PREFIX):
        return "seq-ok" if IMP.SEQ_MODELS.get(IMP.base_of(cell)) else "seq-MISSING"
    return "logic-ok" if IMP.expansion_for(cell) else "logic-MISSING"


def control():
    """Tie the text extractor to the TRUSTED parser on a netlist that imports.

    dmem8 is the reference: the importer reports its own instance total, and
    this census must agree with it after physical cells are excluded — the
    importer's 'instances' line counts logic + sequential only."""
    path = os.path.join(FLOW, "dmem8_nl.v")
    if not os.path.isfile(path):
        print("  ⛔ CONTROL CANNOT RUN — dmem8_nl.v absent. Refusing to report a census.")
        return False
    c = cells_of(path)
    mine = sum(n for k, n in c.items() if not k.startswith(IMP.PHYSICAL_PREFIX))
    expected = 673            # importer's own line, run 2026-08-12, EXIT=0
    print(f"  extractor control on dmem8_nl.v: text scan {mine}, "
          f"trusted parser {expected} — {'AGREE' if mine == expected else 'DISAGREE'}")
    if mine != expected:
        print("  ⛔ the extractor disagrees with the parser; every count below is suspect")
        return False
    # a control must be shown able to fail
    bogus = re.compile(r"sky130_fd_sc_hd__(nand2_1)")
    planted = len(bogus.findall(open(path).read()))
    print(f"  control-of-the-control: a deliberately narrowed pattern sees "
          f"{planted}, not {mine} — the comparison can go DISAGREE")

    # THE FLIP CONTROL — the strongest one available, because its answer is
    # known independently: `nand4_1` landed 2026-08-12 and was measured at 17
    # instances by a separate census. Pull it back out of the resolver and
    # dmem8 must go from CLEAN to blocked-on-exactly-that-cell.
    before = {c: n for c, n in c.items() if classify(c).endswith("MISSING")}
    saved = IMP.EXPAND.pop("nand4_1", None)
    after = {k: n for k, n in cells_of(path).items() if classify(k).endswith("MISSING")}
    if saved is not None:
        IMP.EXPAND["nand4_1"] = saved
    ok = (not before) and after == {"nand4_1": 17}
    print(f"  flip control: dmem8 is {'CLEAN' if not before else before} with nand4_1 "
          f"modelled, {after} without — "
          f"{'DISCRIMINATES' if ok else '⛔ DID NOT DISCRIMINATE'}")
    if not ok:
        print("  ⛔ the census does not respond to a known change; refusing to report it")
        return False
    return True


def main():
    if not os.path.isdir(FLOW):
        print(f"⛔ REFUSING: {FLOW} is not a directory"); return 2
    print("cell coverage: extractor control")
    if not control():
        return 1

    files = sorted(f for f in os.listdir(FLOW) if f.endswith(".v"))
    print(f"\ncell coverage: {len(files)} netlist(s) in Flow/ — the denominator\n")

    missing_by_cell = collections.Counter()      # cell -> instances across corpus
    blocked_by_cell = collections.defaultdict(set)   # cell -> netlists it blocks
    clean, blocked, empty = [], [], []
    per_netlist = {}   # netlist -> {cell: instances}, blocked ones only

    for fn in files:
        c = cells_of(os.path.join(FLOW, fn))
        if not c:
            # ⛔ NOT "clean". "every cell is modelled" is VACUOUSLY true of zero
            # cells, and counting it as covered inflates the coverage figure with
            # a design that does not exist. Synthesis deletes a module whose
            # outputs nobody can observe — see [[unobservable-state-is-deleted]].
            empty.append(fn)
            print(f"  ⚠ {fn:32s} NO cells — EMPTY MODULE, excluded from both counts")
            continue
        miss = collections.Counter()
        for cell, n in c.items():
            if classify(cell).endswith("MISSING"):
                miss[cell] += n
        if miss:
            blocked.append(fn)
            per_netlist[fn] = dict(miss)
            for cell, n in miss.items():
                missing_by_cell[cell] += n
                blocked_by_cell[cell].add(fn)
            names = " ".join(f"{k}x{v}" for k, v in sorted(miss.items()))
            print(f"  ⛔ {fn:32s} {len(miss)} unmodelled: {names}")
        else:
            clean.append(fn)

    # THE SCOPE INSIDE THE VERDICT: name the clean ones, do not just count them.
    # A count is not a scope, and a coverage figure nobody can audit is a claim.
    print("\n  CLEAN — every cell modelled (named, so the count can be checked):")
    for fn in clean:
        print(f"    ✅ {fn}")

    print(f"\ncell coverage: {len(clean)} clean + {len(blocked)} blocked + "
          f"{len(empty)} empty = {len(clean)+len(blocked)+len(empty)} of {len(files)} netlists")
    if len(clean) + len(blocked) + len(empty) != len(files):
        print("  ⛔ the three buckets do not sum to the denominator — census is incomplete")
        return 1
    if missing_by_cell:
        # ⚠️ "APPEARS IN" IS NOT "FREES". A netlist is unblocked only when ALL of
        # its missing cells are modelled, so adding one cell frees exactly those
        # netlists where it is the SOLE blocker. An earlier draft of this tool
        # printed the appears-in column under the heading "ranked by netlists
        # freed", which reads as a delivery estimate and would have been quoted
        # as one. Both numbers are printed, and they are very different.
        sole = collections.Counter()
        for fn, miss in per_netlist.items():
            if len(miss) == 1:
                sole[next(iter(miss))] += 1
        print("\nTHE PRICED LIST — 'appears in' is NOT 'frees'; a netlist needs ALL its cells:")
        print(f"  {'cell':24s} {'appears-in':>10s} {'FREES ALONE':>12s} {'instances':>10s}")
        for cell, nets in sorted(blocked_by_cell.items(),
                                 key=lambda kv: (-len(kv[1]), kv[0])):
            print(f"  {cell:24s} {len(nets):10d} {sole[cell]:12d} "
                  f"{missing_by_cell[cell]:10d}")
        print(f"\n  ⇒ single cells that unblock a netlist on their own: "
              f"{sum(sole.values())} netlist(s) across {len(sole)} cell(s)")

        # the greedy cover: how many cells before the corpus opens
        remaining = {fn: set(m) for fn, m in per_netlist.items()}
        have, order = set(), []
        while remaining:
            cand = collections.Counter()
            for fn, need in remaining.items():
                for c in need - have:
                    cand[c] += 1
            if not cand:
                break
            pick = max(sorted(cand), key=lambda c: cand[c])
            have.add(pick)
            freed = [fn for fn, need in remaining.items() if need <= have]
            for fn in freed:
                del remaining[fn]
            order.append((pick, len(have), len(freed), len(remaining)))
        print("\n  GREEDY COVER — cells added in leverage order, netlists still blocked:")
        for pick, ncells, freed, left in order:
            if freed or ncells % 5 == 0 or left == 0:
                print(f"    +{pick:22s} {ncells:2d} cell(s) modelled -> "
                      f"{freed:2d} freed, {left:2d} still blocked")
    return 0


if __name__ == "__main__":
    sys.exit(main())

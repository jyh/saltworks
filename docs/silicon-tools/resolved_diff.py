#!/usr/bin/env python3
"""resolved_diff.py — is THIS run configured like THAT run?

  python3 resolved_diff.py <reference-resolved.json> <mine-resolved.json> [--selftest]

Compares two LibreLane `resolved.json` files and reports every NON-PATH key whose value
differs. Exit 0 iff the difference set is EMPTY.

⛔ WHY THIS EXISTS, and it cost a 9-minute run to learn. Reproducing a submitted chip, I
built my config from the submitted `src/config.json` and DROPPED four keys that were absent
from the submitted run's 411-key resolved set, reasoning "absent from what RAN means not a
variable". ***THEY WERE NOT ABSENT. THEY WERE RENAMED.***

    FP_IO_HLENGTH -> IO_PIN_H_LENGTH    FP_PDN_MULTILAYER -> PDN_MULTILAYER
    FP_IO_VLENGTH -> IO_PIN_V_LENGTH    FP_PDN_VPITCH     -> PDN_VPITCH

Dropping the legacy names left LibreLane's DEFAULTS in place (PDN_VPITCH 153.6 vs TT's
38.87, PDN_MULTILAYER True vs False) and I never set RT_MAX_LAYER at all, so my run routed
on met5 where the shuttle routes on met4. Every one of those makes routing EASIER, and the
run came back with 2.13 ns MORE setup slack than the chip it claimed to reproduce — the
flattering direction, which is the one that gets believed.

⇒ ***A CONFIG YOU WROTE IS A HYPOTHESIS. THE `resolved.json` IS WHAT RAN.*** Compare the
RESOLVED sets, not the configs, and require the difference to be EMPTY. Metric proximity is
a weak proxy: my metrics were within 5% on three of five axes while the routing layer,
the power-grid pitch and the IO pin geometry were all different.

Path-valued entries are ignored: they encode the host, not the design.
"""
import json, sys

def pathish(v):
    if isinstance(v, str):
        return '/' in v
    if isinstance(v, (list, tuple)):
        return any(pathish(x) for x in v)
    if isinstance(v, dict):
        return any(pathish(x) for x in v.values())
    return False

def diff(ref, mine):
    out = []
    for k in sorted(set(ref) | set(mine)):
        if k not in ref:   out.append((k, '(absent)', mine[k])); continue
        if k not in mine:  out.append((k, ref[k], '(absent)')); continue
        a, b = ref[k], mine[k]
        if a == b or pathish(a) or pathish(b):
            continue
        out.append((k, a, b))
    return out

def selftest():
    print("SELFTEST resolved_diff — driven BOTH ways:")
    rc = 0
    base = {"A": 1, "P": "/x/y", "B": True}
    same = dict(base)
    d = diff(base, same)
    print(f"  identical configs -> {len(d)} diffs  {'✅' if not d else '⛔'}")
    if d: rc = 1
    # the real defect this tool exists for: a differing scalar must be CAUGHT
    changed = dict(base); changed["B"] = False
    d = diff(base, changed)
    caught = any(k == "B" for k, _, _ in d)
    print(f"  one changed scalar -> caught: {'✅' if caught else '⛔ MISSES — the tool proves nothing'}")
    if not caught: rc = 1
    # a differing PATH must be IGNORED (host, not design)
    hostdiff = dict(base); hostdiff["P"] = "/other/path"
    d = diff(base, hostdiff)
    print(f"  path-only difference -> ignored: {'✅' if not d else '⛔ noisy'}")
    if d: rc = 1
    # a MISSING key must be caught, not silently skipped
    missing = {k: v for k, v in base.items() if k != "B"}
    d = diff(base, missing)
    caught = any(k == "B" for k, _, _ in d)
    print(f"  key absent on one side -> caught: {'✅' if caught else '⛔ MISSES'}")
    if not caught: rc = 1
    print("⇒ " + ("✅ SELFTEST PASSED" if rc == 0 else "⛔ SELFTEST FAILED"))
    return rc

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(2)
    ref = json.load(open(sys.argv[1])); mine = json.load(open(sys.argv[2]))
    d = diff(ref, mine)
    print(f"resolved_diff: reference {len(ref)} keys · mine {len(mine)} keys · "
          f"{len(d)} NON-PATH difference(s)")
    for k, a, b in d:
        sa, sb = repr(a), repr(b)
        print(f"  ⛔ {k:34s} ref={sa[:64]}")
        print(f"     {'':34s} me ={sb[:64]}")
    if not d:
        print("  ✅ EMPTY — this run is configured exactly like the reference (paths aside).")
    sys.exit(0 if not d else 1)

#!/usr/bin/env python3
"""Which git-tracked modules are OUTSIDE the hub's transitive import closure?

A module outside it is not built by `lake build`, so its `#audit_axioms` never
fire, and "the default build covers X" is FALSE for it. Reported twice by hand
in one evening (Renumber 19:52, ISA 20:52) -- a fact rediscovered by hand twice
is a fact that wants an instrument.

It counts `#audit_axioms` SITES IN THE FILE ITSELF, and that choice is the whole
point of the tool rather than a detail. The number I published by hand at 19:50
-- "the renumber's 31 declarations are outside the default build" -- was WRONG.
It came from subtracting a targeted run's tick count from a full build's, and a
targeted run of `Renumber.lean` re-audits its IMPORTS too: 33 ticks, of which
only 12 are Renumber's. The other 21 belong to modules that are inside the
closure and were never missing. The true number is 12.

That is the same defect as the 309 MiB memory constant published this morning --
A NUMBER DERIVED BY SUBTRACTING TWO INSTRUMENTS, where the difference is not the
quantity you named. Hence: count the sites directly, in the file, and never
infer this from a delta again.

Usage:  python3 docs/ledger-tools/import-closure.py
Exit 1 if any tracked module is outside the closure, so it can gate a commit.
"""
import re, subprocess, sys, os

ROOT = "/Users/jyh/projects/claude/saltworks"
HUB  = "SaltWorks.lean"

def mod_of(path):                       # SaltWorks/HDL/ISA.lean -> SaltWorks.HDL.ISA
    return path[:-5].replace("/", ".")

def path_of(mod):
    return mod.replace(".", "/") + ".lean"

tracked = subprocess.run(["git","-C",ROOT,"ls-files","*.lean"],
                         capture_output=True, text=True).stdout.split()
tracked = [p for p in tracked if not p.startswith(".lake")]
bypath  = {p: mod_of(p) for p in tracked}
known   = set(bypath.values())

IMPORT = re.compile(r'^\s*import\s+([A-Za-z0-9_.]+)', re.M)
def imports(p):
    fp = os.path.join(ROOT, p)
    if not os.path.exists(fp): return []
    return IMPORT.findall(open(fp, encoding='utf-8', errors='replace').read())

# transitive closure from the hub
seen, stack = set(), [mod_of(HUB)]
while stack:
    m = stack.pop()
    if m in seen: continue
    seen.add(m)
    for i in imports(path_of(m)):
        if i in known and i not in seen:
            stack.append(i)

AUDIT = re.compile(r'^\s*#audit_axioms\b', re.M)
outside = []
for p, m in sorted(bypath.items()):
    if p == HUB or m in seen: continue
    n = len(AUDIT.findall(open(os.path.join(ROOT,p), encoding='utf-8', errors='replace').read()))
    outside.append((m, n))

tot = sum(n for _, n in outside)
print(f"hub: {HUB}   tracked .lean: {len(tracked)}   in closure: {len(seen)}   OUTSIDE: {len(outside)}")
for m, n in outside:
    print(f"  ⛔ {m:<34} {n:>3} audit site(s) never fire in the default build")
print(f"TOTAL audit sites outside the default build: {tot}")
sys.exit(1 if outside else 0)

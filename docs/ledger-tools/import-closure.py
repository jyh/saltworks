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
        CLOSURE_ROOT=/some/repo python3 docs/ledger-tools/import-closure.py

EXIT CODES ARE THREE-WAY ON PURPOSE (evidence seat, 21:0x, adopting the
16:52 instrument law -- "no matching data" is a DISTINCT output from 0):

    0   every tracked module is inside the closure
    1   something is OUTSIDE  -- the gate this tool exists to be
    2   COULD NOT READ the repo -- neither of the above is known

Why 2 exists: this tool gates a commit, and the first version returned
**exit 0 with "OUTSIDE: 0" when `git ls-files` failed**. An empty `tracked`
list has nothing that can be outside it, so a tool that had read NOTHING
printed the same clean green as a fully-covered repo. *A gate that passes
when it cannot read the repo is a gate that opens when the lock is broken.*
Measured on a fixture pointed at a non-repo, not reasoned about.

Same family as `ledger_common.activity_trace`, which raises if it reads
transcript lines and extracts zero timestamps. The logic below is the
compiler seat's and is untouched; these are guards around it.
"""
import re, subprocess, sys, os

ROOT = os.environ.get("CLOSURE_ROOT", "/Users/jyh/projects/claude/saltworks")
HUB  = "SaltWorks.lean"

def mod_of(path):                       # SaltWorks/HDL/ISA.lean -> SaltWorks.HDL.ISA
    return path[:-5].replace("/", ".")

def path_of(mod):
    return mod.replace(".", "/") + ".lean"

_git = subprocess.run(["git","-C",ROOT,"ls-files","*.lean"],
                      capture_output=True, text=True)
if _git.returncode != 0:
    print(f"import-closure: ⛔ CANNOT READ REPO — `git ls-files` failed in {ROOT!r}\n"
          f"  {(_git.stderr or '').strip()[:200]}\n"
          f"  Reporting NOTHING rather than 'OUTSIDE: 0'. This is exit 2, not a pass.",
          file=sys.stderr)
    sys.exit(2)

tracked = _git.stdout.split()
tracked = [p for p in tracked if not p.startswith(".lake")]

# ⚠️ THE LIBRARY, NOT EVERY TRACKED .lean. The closure question is "which LIBRARY
# modules does the hub fail to reach"; a standalone .lean TOOL is outside the hub
# by design and always will be. On 2026-08-07 `docs/hdl-tools/reach_census.lean`
# landed -- a Lean metaprogram, not a module -- and this tool reported OUTSIDE 8 -> 10
# while the audit-site total (the number that matters) stayed at 53, because the
# tool carries no audit sites. The evidence seat quoted the inflated module count on
# the bus one paragraph before catching it. The SITE total was never wrong; the
# MODULE count was, and only because the population was wrong.
_nonlib = [p for p in tracked if p != HUB and not p.startswith("SaltWorks/")]
tracked = [p for p in tracked if p == HUB or p.startswith("SaltWorks/")]
if _nonlib:
    print(f"import-closure: {len(_nonlib)} tracked .lean file(s) excluded as NON-LIBRARY "
          f"(outside SaltWorks/): {', '.join(sorted(_nonlib))}")

if not tracked:
    print(f"import-closure: ⛔ ZERO tracked .lean files under {ROOT!r} — an empty set "
          f"has nothing outside it, so 'OUTSIDE: 0' here would mean 'I read nothing', "
          f"not 'everything is covered'. Exit 2.", file=sys.stderr)
    sys.exit(2)

if not os.path.exists(os.path.join(ROOT, HUB)):
    print(f"import-closure: ⛔ HUB {HUB!r} NOT FOUND under {ROOT!r} — the closure would "
          f"be empty and every module would be reported outside. Exit 2.", file=sys.stderr)
    sys.exit(2)
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

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

# ⛔⛔ THE CORPUS IS MULTI-ROOTED SINCE 2026-08-08 10:5x, AND THIS TOOL KNEW ONE ROOT.
# The maestro added a SECOND lean_lib — `SaltWorksAudit`, rooted at
# SaltWorks.HDL.PortLengths — for modules that IMPORT the hub in order to audit the
# corpus. Such a module CANNOT be imported back by the hub: that is a build cycle,
# and the maestro hit exactly that (~2 min of broken shared tree at 10:50).
# ⇒ PortLengths is not unswept. It is deliberately ABOVE the hub, and it IS built.
# With HUB hardcoded, this guard reported it OUTSIDE **forever**.
# 🔑 A GUARD THAT CRIES WOLF PERMANENTLY IS A GUARD PEOPLE STOP READING — and this
# one caught three real omissions on 8/8 alone (5 modules 08:49 · GenSelectCount
# 09:2x · 4 modules 10:48). Silicon caught the false positive within minutes.
# THE FIX: read the roots from lakefile.toml. The tool's model of "the build" must
# come FROM the build's own declaration, never from a constant in the instrument.
def _discover_roots():
    """Every lean_lib's root MODULE names, from lakefile.toml. Returns (roots, how)."""
    env = os.environ.get("CLOSURE_ROOTS")          # override, for differential tests
    if env:
        return [r.strip() for r in env.split(",") if r.strip()], "CLOSURE_ROOTS env"
    lf = os.path.join(ROOT, "lakefile.toml")
    if not os.path.exists(lf):
        return [], "lakefile.toml NOT FOUND"
    txt = open(lf, encoding="utf-8", errors="replace").read()
    roots, how = [], "lakefile.toml"
    try:
        import tomllib                              # 3.11+: real parsing
        data = tomllib.loads(txt)
        for lib in data.get("lean_lib", []):
            r = lib.get("roots")
            if r:   roots.extend(r)
            elif lib.get("name"): roots.append(lib["name"])
        how = "lakefile.toml (tomllib)"
    except Exception:                               # regex fallback, stated not hidden
        for blk in re.split(r'^\[\[lean_lib\]\]', txt, flags=re.M)[1:]:
            blk = re.split(r'^\[', blk, flags=re.M)[0]
            r = re.search(r'^\s*roots\s*=\s*\[([^\]]*)\]', blk, re.M)
            if r:
                roots.extend(re.findall(r'"([^"]+)"', r.group(1)))
            else:
                n = re.search(r'^\s*name\s*=\s*"([^"]+)"', blk, re.M)
                if n: roots.append(n.group(1))
        how = "lakefile.toml (regex fallback — tomllib unavailable)"
    return roots, how

ROOT_MODS, ROOTS_HOW = _discover_roots()
if not ROOT_MODS:
    print(f"import-closure: ⛔ NO BUILD ROOTS DISCOVERED ({ROOTS_HOW}). Every module "
          f"would report OUTSIDE, which would be a true statement about an empty "
          f"closure and a false one about the corpus. Exit 2.", file=sys.stderr)
    sys.exit(2)
ROOT_PATHS = {m.replace(".", "/") + ".lean" for m in ROOT_MODS}
HUB = sorted(ROOT_PATHS)[0]   # retained only for messages that name a single file

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
_nonlib = [p for p in tracked if p not in ROOT_PATHS and not p.startswith("SaltWorks/")]
tracked = [p for p in tracked if p in ROOT_PATHS or p.startswith("SaltWorks/")]
if _nonlib:
    print(f"import-closure: {len(_nonlib)} tracked .lean file(s) excluded as NON-LIBRARY "
          f"(outside SaltWorks/): {', '.join(sorted(_nonlib))}")

if not tracked:
    print(f"import-closure: ⛔ ZERO tracked .lean files under {ROOT!r} — an empty set "
          f"has nothing outside it, so 'OUTSIDE: 0' here would mean 'I read nothing', "
          f"not 'everything is covered'. Exit 2.", file=sys.stderr)
    sys.exit(2)

missing = [p for p in sorted(ROOT_PATHS) if not os.path.exists(os.path.join(ROOT, p))]
if missing:
    print(f"import-closure: ⛔ DECLARED ROOT(S) NOT FOUND under {ROOT!r}: {missing} — the "
          f"closure would be short and modules would be falsely reported outside. Exit 2.", file=sys.stderr)
    sys.exit(2)
bypath  = {p: mod_of(p) for p in tracked}
known   = set(bypath.values())

IMPORT = re.compile(r'^\s*import\s+([A-Za-z0-9_.]+)', re.M)
def imports(p):
    fp = os.path.join(ROOT, p)
    if not os.path.exists(fp): return []
    return IMPORT.findall(open(fp, encoding='utf-8', errors='replace').read())

# transitive closure from the hub
seen, stack = set(), [m for m in ROOT_MODS]
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
    if p in ROOT_PATHS or m in seen: continue
    n = len(AUDIT.findall(open(os.path.join(ROOT,p), encoding='utf-8', errors='replace').read()))
    outside.append((m, n))

tot = sum(n for _, n in outside)
print(f"roots ({ROOTS_HOW}): {', '.join(sorted(ROOT_MODS))}")
print(f"tracked .lean: {len(tracked)}   in closure: {len(seen)}   OUTSIDE: {len(outside)}")
for m, n in outside:
    print(f"  ⛔ {m:<34} {n:>3} audit site(s) never fire in the default build")
print(f"TOTAL audit sites outside the default build: {tot}")
sys.exit(1 if outside else 0)

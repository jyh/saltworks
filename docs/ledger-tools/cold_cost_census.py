#!/usr/bin/env python3
"""Cold-cost census — which ROOTED modules can still be ELABORATED at saltbuild's
default memory cap?

WHY THIS EXISTS (compiler, 2026-08-08 20:1x)
--------------------------------------------
Every full-build verdict in this campaign is dominated by REPLAY. A measured example:
`../saltbuild.sh SaltWorks` returned `EXIT=0`, 8,667 jobs, **Built 0 / Replayed 75, in
3.3 seconds**. That green says the cache is intact. It does not say this machine's kernel
can still elaborate the corpus.

And it matters, because at least one rooted module CANNOT:

    SaltWorks/HDL/Immediate.lean  pristine, path form, DEFAULT cap -> EXIT=134
                                  lean::memory_exception at 'interpreter'
                                  ... and --cap 24000 -> EXIT=0 (80 s)

A cold cache is not hypothetical: a fresh clone, a new machine, a CI runner, a
cache-cleared successor and the eventual public gate all start cold. The 2026-08-06
laptop->Mac-Mini migration already taught this fleet that oleans travel by rsync and the
kernel does not.

WHAT IT REPORTS, AND THE RULE IT OBEYS
--------------------------------------
⛔ ONE ROW PER MODULE, EACH CARRYING ITS OWN INVOCATION. No bare total.
That is pre-registered on the bus and it is not decoration: a single number over an
unstated module set is the "a count is not a scope" failure, and a cost census is the
easiest place in this corpus to publish a confident number from the wrong object.

DEFECTS THIS TOOL HAS, STATED BY IT RATHER THAN DISCOVERED IN IT
---------------------------------------------------------------
1. The candidate SELECTION is a heuristic (`decide +kernel` count and the largest
   `List.range` literal). A module can be expensive for reasons this misses --
   `Nat.rec` blowups, big `BitVec` products, deep `simp`. So a module absent from the
   report is UNTESTED, never "cheap". The report says so per run.
2. It measures ONE module at a time. Four seats building concurrently on a 64 GiB
   machine is a different question (the banked concurrency hazard) and this tool does
   not answer it.
3. PASS here means "elaborates at the default cap TODAY, alone, on this machine". It is
   not a promise about a different machine or a loaded one.
4. It does not clear any cache. It uses the PATH form, which re-elaborates the named
   file but still REPLAYS that file's dependencies -- so a PASS means "this module's own
   elaboration fits", not "the tree from cold fits". The tree-from-cold number is the sum
   of every module's own elaboration, and this tool measures only the candidates.
"""

import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SALTBUILD = REPO.parent / "saltbuild.sh"


def rooted_modules() -> list[Path]:
    """Modules reachable from the root — the only ones a cold FULL build must elaborate."""
    root = REPO / "SaltWorks.lean"
    out = []
    for line in root.read_text().splitlines():
        m = re.match(r"^import\s+(SaltWorks\.[A-Za-z0-9_.]+)\s*$", line)
        if m:
            p = REPO / (m.group(1).replace(".", "/") + ".lean")
            if p.is_file():
                out.append(p)
    return out


def heaviness(path: Path) -> tuple[int, int]:
    """(count of `decide +kernel`, largest `List.range` literal). A HEURISTIC — see defect 1."""
    text = path.read_text(errors="replace")
    dk = text.count("decide +kernel")
    ranges = [int(n) for n in re.findall(r"List\.range\s+(\d+)", text)]
    return dk, (max(ranges) if ranges else 0)


def elaborate(path: Path, cap: str | None) -> tuple[int, float, str]:
    """PATH form => re-elaborates this file. Returns (exit, seconds, saltbuild's verdict)."""
    rel = str(path.relative_to(REPO))
    cmd = [str(SALTBUILD)] + (["--cap", cap] if cap else []) + [rel]
    t0 = time.monotonic()
    r = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, timeout=1800)
    dt = time.monotonic() - t0
    blob = r.stdout + r.stderr
    verdict = ""
    for ln in blob.splitlines():
        if "saltbuild EXIT=" in ln:
            verdict = ln.strip()
    if "memory_exception" in blob:
        verdict += "  [memory_exception]"
    return r.returncode, dt, verdict


def main() -> int:
    min_range = int(sys.argv[1]) if len(sys.argv) > 1 else 128
    retry_cap = "24000"

    mods = rooted_modules()
    cands = []
    for p in mods:
        dk, mx = heaviness(p)
        if dk > 0 and mx >= min_range:
            cands.append((mx, dk, p))
    cands.sort(reverse=True, key=lambda t: (t[0], t[1]))

    print(f"COLD-COST CENSUS · rooted modules = {len(mods)} · "
          f"candidates = {len(cands)} (heuristic: decide+kernel > 0 AND max List.range >= {min_range})")
    print(f"⚠️  A module NOT LISTED BELOW IS UNTESTED, NOT CHEAP — the selection is a heuristic.")
    print(f"⚠️  PASS = elaborates at the DEFAULT cap today, ALONE, on this machine. Deps still replay.")
    print()

    fails = []
    for mx, dk, p in cands:
        rel = str(p.relative_to(REPO))
        rc, dt, verdict = elaborate(p, None)
        status = "PASS" if rc == 0 else "OVER-CAP"
        line = (f"{status:9s} {rel:52s} maxRange={mx:<6d} decide+kernel={dk:<3d} "
                f"{dt:6.1f}s  ← ../saltbuild.sh {rel}")
        print(line)
        print(f"          verdict: {verdict}")
        if rc != 0:
            fails.append(rel)
            rc2, dt2, v2 = elaborate(p, retry_cap)
            print(f"          retry:   ../saltbuild.sh --cap {retry_cap} {rel}"
                  f"  →  {'PASS' if rc2 == 0 else 'STILL FAILS'} ({dt2:.1f}s)")
            print(f"          verdict: {v2}")
        sys.stdout.flush()

    print()
    print(f"OVER-CAP at the default: {len(fails)} of {len(cands)} candidates tested")
    for f in fails:
        print(f"   ⛔ {f}")
    print(f"⚠️  SCOPE OF THAT COUNT: {len(cands)} candidates out of {len(mods)} rooted modules, "
          f"selected by the heuristic above. It is NOT a count over the corpus.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

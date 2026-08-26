#!/usr/bin/env python3
"""Report Scratch explorations that were PROMOTED into landed modules.

WHY THIS EXISTS
---------------
On 2026-08-26 a measurement of c4spec STEP 7 reported a landed, kernel-checked
theorem as "scratch, unbuilt". The theorem was `renumbering_offsets`. It lives in
`SaltWorks/HDL/StateCodecD.lean`, which the root imports. The grep had landed in
`SaltWorks/HDL/ScratchQ3CodecEx.lean` -- a 401-line copy differing in 4 lines,
carrying the same theorem at the same line number.

The false verdict reached the bus and voided an order that was issued on it.

  ⛔ `grep` + "this file is unimported, therefore this fact is UNBUILT" IS UNSOUND
     IN THIS TREE. The `import owed means UNBUILT` law is true of a MODULE. It is
     NOT true of a THEOREM, because the theorem may exist in a landed twin under a
     different module name.

  ⇒ THE SOUND QUERY IS BY THEOREM NAME ACROSS LANDED MODULES, never by whichever
    file the grep happened to land in first.

WHY A SCRIPT AND NOT A COMMENT IN EACH FILE
-------------------------------------------
Every one of these Scratch files is GITIGNORED. A tombstone header written into
them is LOCAL TO ONE CLONE and reaches no other seat -- each seat carries its own
untracked copies. A tracked script travels with the repo and runs against whatever
copies the reader actually has, which is the only form that helps anybody else.
(Local headers are still worth writing; they are just not the fix.)

USAGE
  python3 scripts/scratch_twins.py            # report the twin map
  python3 scripts/scratch_twins.py --check    # exit 1 if any twin is undeclared
  python3 scripts/scratch_twins.py --selftest # drive both arms
"""
import sys, pathlib, itertools

ROOT = pathlib.Path(__file__).resolve().parent.parent
NEAR = 12          # lines-differing threshold for "the same file, promoted"


def imported_modules(root: pathlib.Path) -> set:
    """Module names the root actually imports -- the definition of LANDED."""
    f = root / "SaltWorks.lean"
    if not f.exists():
        return set()
    out = set()
    for line in f.read_text().splitlines():
        line = line.strip()
        if line.startswith("import "):
            out.add(line.split()[1].split(".")[-1])
    return out


def diff_count(a: list, b: list) -> int:
    """Cheap symmetric line-difference count. Not a real diff -- it does not need
    to be: it only separates 'a promoted copy' from 'a different file', and the
    two populations are orders of magnitude apart (0-6 vs hundreds)."""
    from collections import Counter
    ca, cb = Counter(a), Counter(b)
    return sum((ca - cb).values()) + sum((cb - ca).values())


def find_twins(root: pathlib.Path):
    imp = imported_modules(root)
    scratch, landed = [], []
    for p in sorted(root.glob("SaltWorks/**/*.lean")):
        (scratch if p.stem.startswith("Scratch") else landed).append(p)
    # ⛔ DO NOT BUCKET BY EXACT LINE COUNT. The first cut did, and it went BLIND on
    # this very tree the moment the remedy was applied: adding a one-line PROMOTED
    # header changes the length by 1, the exact bucket misses, and the report said
    # "0 twins -- every Scratch module is unique" while 14 sat on disk. An instrument
    # that fails exactly when you fix the thing it detects is worse than no
    # instrument, because its silence reads as success. Bucket by a WINDOW.
    cache = {l: l.read_text().splitlines() for l in landed}
    pairs = []
    for s in scratch:
        sl = s.read_text().splitlines()
        for l, ll in cache.items():
            if abs(len(ll) - len(sl)) > NEAR:
                continue
            d = diff_count(sl, ll)
            if d < NEAR:
                pairs.append((s, l, len(sl), d, l.stem in imp, s.stem in imp))
    return pairs


def declared(s: pathlib.Path) -> bool:
    head = s.read_text().splitlines()
    return bool(head) and "PROMOTED" in head[0]


def main(argv) -> int:
    if "--selftest" in argv:
        return selftest()
    pairs = find_twins(ROOT)
    check = "--check" in argv
    undeclared = 0
    print(f"scratch_twins: {len(pairs)} promoted-exploration pair(s) in {ROOT.name}")
    for s, l, n, d, l_imp, s_imp in pairs:
        mark = "" if declared(s) else "  <- UNDECLARED (no PROMOTED header)"
        if not declared(s):
            undeclared += 1
        print(f"  {s.relative_to(ROOT)}")
        print(f"    -> promoted to {l.relative_to(ROOT)}  "
              f"({n} lines, {d} differing; successor imported={l_imp}, copy imported={s_imp}){mark}")
    if not pairs:
        print("  none -- every Scratch module is unique. A grep cannot land on a twin here.")
    # ⛔ The exit code is about DECLARATION, not about twins existing. Twins are
    # normal: exploration then promotion. What is dangerous is an UNMARKED twin.
    if check and undeclared:
        print(f"FAIL: {undeclared} twin(s) carry no PROMOTED header.", file=sys.stderr)
        return 1
    return 0


def selftest() -> int:
    """Both arms, on fixtures -- the report must be able to say NO."""
    import tempfile, shutil
    ok = fail = 0
    def arm(name, cond):
        nonlocal ok, fail
        if cond: ok += 1; print(f"  PASS {name}")
        else:    fail += 1; print(f"  FAIL {name}")
    with tempfile.TemporaryDirectory() as td:
        r = pathlib.Path(td)
        (r / "SaltWorks").mkdir()
        (r / "SaltWorks.lean").write_text("import SaltWorks.Real\n")
        body = "\n".join(f"line {i}" for i in range(40))
        (r / "SaltWorks" / "Real.lean").write_text(body + "\n")
        (r / "SaltWorks" / "ScratchReal.lean").write_text(body.replace("line 7", "line seven") + "\n")
        (r / "SaltWorks" / "Unrelated.lean").write_text("\n".join(f"other {i}" for i in range(40)) + "\n")
        pairs = find_twins(r)
        arm("finds the promoted twin", len(pairs) == 1 and pairs[0][1].stem == "Real")
        arm("marks the successor as imported", pairs and pairs[0][4] is True)
        arm("marks the copy as NOT imported", pairs and pairs[0][5] is False)
        # NEGATIVE ARM: a same-length but genuinely different file must NOT pair.
        arm("does not pair an unrelated same-length file",
            all(p[1].stem != "Unrelated" for p in pairs))
        arm("undeclared twin detected", not declared(pairs[0][0]))
        # and once declared, it is no longer undeclared -- the check can go green
        p = pairs[0][0]
        p.write_text("-- PROMOTED to Real.lean\n" + p.read_text())
        arm("declaring the twin clears it", declared(p))
    print(f"scratch_twins selftest: {ok} passed, {fail} failed, {ok+fail} arms")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

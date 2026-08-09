#!/usr/bin/env python3
"""CENSUS — classify every tracked module as PASS / FAIL / UNREACHED / UNWIRED, because a build's error list CANNOT do it.

WHY THIS EXISTS (compiler, 2026-08-08, phase 3).  A module that fails to compile
masks its dependents: lake reports the failure, the dependents never elaborate,
and they are NOT listed.  So an error list has two shapes -- "error" and "no
error" -- while reality has THREE, and the third (never ran) is byte-identical to
a pass.  I read "zero errors in SaltWorks/HDL/**" off a census and nearly
published it as "all my files are green at the ruled pair"; two of them had never
been elaborated at all.

Silicon's sharpening (13:56), adopted: a module's absence from an error list has
two explanations and the list cannot separate them, so a census over a
PARTIALLY-FAILING tree owes the trichotomy in its OUTPUT, where the next run
cannot present it as a binary.

TWO WRONG VERSIONS PRECEDED THIS ONE, and both failures are the reason it is
shaped this way:

 (1) MTIME DISCRIMINATOR -- "no error and olean older than build start =>
     UNREACHED".  Against a known-green, fully cached tree it reported
     PASS 0 / FAIL 0 / UNREACHED 75.  Every module.  A cached build REPLAYS and
     rebuilds nothing, so every olean legitimately predates it: the test
     conflates "masked" with "already current".  That is this seat's own
     `replayed-is-not-checked` law arriving inverted.  Caught only by running it
     on a case whose answer I already knew.

 (2) BASH ASSOCIATIVE ARRAYS -- macOS /bin/bash is 3.2 and has no `declare -A`.
     The script errored on every line that mattered AND STILL PRINTED
     "PASS 0 FAIL 0 UNREACHED 0", which reads exactly like a clean tree.  An
     instrument that prints a verdict after its own machinery collapsed is worse
     than one that crashes, so this version REFUSES to print a table it could not
     build.

THE SOUND DISCRIMINATOR IS THE IMPORT GRAPH, NOT A TIMESTAMP:
    own error lines                    -> FAIL
    transitively imports a FAIL module -> UNREACHED (masked)
    no olean at all                    -> UNREACHED (never built)
    otherwise                          -> PASS
No mtimes anywhere.  Sound on cached builds, partial builds, and retrospectively
-- the three places version (1) lied.

LIMIT 1, honestly: FAIL is read from error TEXT, so a failure lake reports without a
`path:line:` prefix would be missed.  The output cross-checks against lake's own
"- SaltWorks.X" failed-module list and DISAGREES LOUDLY if the two differ.

⛔ LIMIT 2 — FOUND 2026-08-08 18:0x.  **PASS DOES NOT MEAN "COVERED BY THE BUILD
GRAPH".**  The PASS rule is "no error AND an olean exists", so a module that NO ROOT
IMPORTS still scores PASS — on the strength of an olean left by an earlier TARGETED
build.  Current by coincidence; rechecked by nothing.
   Caught on `SaltWorks.HDL.PayloadRefutations`: I landed it, targeted-built it, read
   `PASS 82 / FAIL 0 / UNREACHED 0`, and only then noticed `SaltWorks.lean` never
   imports it.  **The census had certified a module the default build does not touch.**
   ✅ CLOSED 18:1x — the tool now walks the ROOTS (SaltWorks.lean plus every lakefile
     `roots = [...]`) to a transitive closure, and a green tracked module no root reaches
     is reported UNWIRED rather than PASS.  Positive control run before landing: with the
     root import the module classifies PASS, without it UNWIRED, and no other module
     loses reachability.  I tested the LOGIC directly rather than edit the maestro-only
     root to force the case.
     The lakefile's own comment records the neighbouring hazard — above-hub audit
     modules can never be imported BY the hub, hence the second root.  This is its
     MIRROR: a module below the hub that simply never got wired.
   ⇒ Same family as this file's other defects: an instrument that reports faithfully on
     the objects it can see, and is silent about membership in the set that matters.

USAGE:  docs/compiler-census.py <build-output-file>
"""
import re
import subprocess
import sys
from pathlib import Path

LIBDIR = Path(".lake/build/lib/lean")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    out_path = Path(sys.argv[1])
    if not out_path.is_file():
        print(f"census: no such build output: {out_path}", file=sys.stderr)
        return 2
    text = out_path.read_text(errors="replace")

    srcs = [
        s for s in subprocess.run(
            ["git", "ls-files", "SaltWorks/*.lean", "SaltWorks/**/*.lean"],
            capture_output=True, text=True, check=True,
        ).stdout.split()
        if "/Scratch" not in s and not Path(s).name.startswith("Scratch")
    ]
    if not srcs:
        print("census: REFUSING TO REPORT — module list is empty. The population "
              "could not be built, so any table would be a manufactured clean "
              "result.", file=sys.stderr)
        return 3

    def mod_of(src: str) -> str:
        return "SaltWorks." + src[len("SaltWorks/"):].removesuffix(".lean").replace("/", ".")

    src_of = {mod_of(s): s for s in srcs}
    imports_of = {
        m: [ln.split()[1] for ln in Path(s).read_text(errors="replace").splitlines()
            if ln.startswith("import SaltWorks")]
        for m, s in src_of.items()
    }

    # --- ROOT REACHABILITY (LIMIT 2's closure): which modules can any root reach? ---
    roots: list[str] = []
    rootfile = Path("SaltWorks.lean")
    if rootfile.is_file():
        roots.append("SaltWorks")
        imports_of["SaltWorks"] = [
            ln.split()[1] for ln in rootfile.read_text(errors="replace").splitlines()
            if ln.startswith("import SaltWorks")
        ]
    lake = Path("lakefile.toml")
    if lake.is_file():
        for m in re.finditer(r'roots\s*=\s*\[([^\]]*)\]', lake.read_text(errors="replace")):
            roots += re.findall(r'"([^"]+)"', m.group(1))
    reachable: set[str] = set()
    frontier = list(roots)
    while frontier:
        cur = frontier.pop()
        if cur in reachable:
            continue
        reachable.add(cur)
        frontier += imports_of.get(cur, [])

    status: dict[str, str] = {}
    err_count: dict[str, int] = {}
    for mod, src in src_of.items():
        n = len(re.findall(rf"error: {re.escape(src)}:", text))
        if n:
            status[mod], err_count[mod] = "FAIL", n

    # transitive importers of anything FAIL -> UNREACHED (fixpoint)
    changed = True
    while changed:
        changed = False
        for mod in src_of:
            if status.get(mod) in ("FAIL", "UNREACHED"):
                continue
            if any(status.get(d) in ("FAIL", "UNREACHED") for d in imports_of[mod]):
                status[mod] = "UNREACHED"
                changed = True

    for mod, src in src_of.items():
        if mod in status:
            continue
        olean = LIBDIR / Path(src).with_suffix(".olean")
        if not olean.is_file():
            status[mod] = "UNREACHED"
        elif mod not in reachable:
            status[mod] = "UNWIRED"
        else:
            status[mod] = "PASS"

    print(f"\n{'STATUS':<11} MODULE")
    print("-" * 76)
    for mod in sorted(status):
        st = status[mod]
        if st == "FAIL":
            print(f"{st:<11} {mod}  ({err_count[mod]} error lines)")
        elif st == "UNWIRED":
            print(f"{st:<11} {mod}  (green, tracked — and NO ROOT REACHES IT)")
        elif st == "UNREACHED":
            why = "masked behind a FAIL" if any(
                status.get(d) in ("FAIL", "UNREACHED") for d in imports_of[mod]
            ) else "no olean produced"
            print(f"{st:<11} {mod}  ({why})")
    print("-" * 76)
    tally = {k: sum(1 for v in status.values() if v == k)
             for k in ("PASS", "FAIL", "UNREACHED", "UNWIRED")}
    print(f"PASS {tally['PASS']}   FAIL {tally['FAIL']}   UNREACHED {tally['UNREACHED']}"
          f"   UNWIRED {tally['UNWIRED']}"
          f"   (of {len(src_of)} tracked modules; PASS rows omitted —")
    print("                                    only the classes a green-looking census HIDES are printed)")

    lake_failed = sorted(set(re.findall(r"^- (SaltWorks\S+)", text, re.M)))
    mine_failed = sorted(m for m, v in status.items() if v == "FAIL")
    print(f"\nlake's own failed-module list : {lake_failed or '(none)'}")
    print(f"this script's FAIL set        : {mine_failed or '(none)'}")
    if lake_failed != mine_failed:
        print("⛔ DISAGREEMENT between lake's failed list and the error-text scan. "
              "Trust lake; this script's FAIL detection missed something.")
    if tally["UNREACHED"]:
        print("\n⛔ UNREACHED IS NOT PASS — those modules were not elaborated by this build.")
    if tally["UNWIRED"]:
        print("⛔ UNWIRED IS NOT PASS EITHER — green and tracked, but no root reaches them, "
              "so nothing rebuilds them when their dependencies move.")
    print(f"\n(roots walked for reachability: {sorted(roots)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())

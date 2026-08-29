#!/usr/bin/env python3
"""treatcheck.py — did this run apply EXACTLY the treatment its config declares, and nothing else?

  python3 treatcheck.py <base-config.json> <arm-config.json> <reference-resolved.json> <arm-resolved.json>
  python3 treatcheck.py --selftest

  exit 0 = the resolved difference set EQUALS the declared treatment
       1 = REFUSED (extra keys, missing keys, or both)
       2 = usage / unreadable / cannot measure

⛔ WHY THIS EXISTS, 2026-08-28 17:4x. `resolved_diff.py` answers *"is this run configured like
   that run?"* and REQUIRES THE DIFFERENCE TO BE EMPTY. That is exactly right for a reproduction
   arm and **structurally wrong for a treatment arm**, which differs ON PURPOSE: run it on `ndf-2a`
   and it refuses, correctly and uselessly. So in `harden_run.sh` its status was PRINTED and never
   consumed — a check that cannot pass gets demoted to a printout, which is how a real gate dies.
   ⇒ ***THE QUESTION A TREATMENT ARM NEEDS IS NOT "ANY DIFFERENCE?" BUT "EXACTLY THE DECLARED
      DIFFERENCE?"*** — and that question has a reachable YES, so it can be a gate.

⛔ IT REFUSES IN BOTH DIRECTIONS, AND THEY ARE DIFFERENT DEFECTS:
   EXTRA   a key differs that the arm never declared ⇒ CONTAMINATION. This is the defect
           `resolved_diff.py`'s own docstring records: four renamed keys left LibreLane defaults in
           place, the run routed on met5 where the shuttle routes on met4, and it came back with
           2.13 ns MORE setup slack than the chip it claimed to reproduce. Contamination flatters.
   MISSING a key the arm declared does NOT differ in what ran ⇒ THE TREATMENT NEVER HAPPENED.
           The result is then a true measurement of the BASELINE wearing the arm's name, and every
           control in the experiment still passes.

📌 The comparator is IMPORTED from `resolved_diff.py`, never re-typed: a pattern re-typed is a
   pattern re-invented, and this seat spent four wrong numbers on that lesson this morning.
"""
import json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import resolved_diff  # noqa: E402  — the tool's OWN comparator, imported not re-typed


def keyset(a, b):
    """Non-path keys whose values differ between two mappings, via resolved_diff's own diff()."""
    return {k for k, _, _ in resolved_diff.diff(a, b)}


def check(base_cfg, arm_cfg, ref_resolved, arm_resolved, label=""):
    declared = keyset(base_cfg, arm_cfg)
    actual = keyset(ref_resolved, arm_resolved)
    extra, missing = sorted(actual - declared), sorted(declared - actual)
    print(f"treatcheck{(' ' + label) if label else ''}: declared {len(declared)} · "
          f"resolved {len(actual)} · reference {len(ref_resolved)} keys")
    print(f"    declared treatment : {sorted(declared)}")
    print(f"    actually resolved  : {sorted(actual)}")
    if extra:
        print("  ⛔ EXTRA — differs in what RAN but the arm never declared it (CONTAMINATION):")
        for k in extra:
            print(f"       {k:34s} ref={repr(ref_resolved.get(k))[:48]}  me={repr(arm_resolved.get(k))[:48]}")
    if missing:
        print("  ⛔ MISSING — declared by the arm but IDENTICAL in what ran (TREATMENT NOT APPLIED):")
        for k in missing:
            print(f"       {k:34s} value={repr(arm_resolved.get(k))[:48]}")
    if extra or missing:
        print("  ⛔ TREATMENT GATE: REFUSED.")
        return 1
    print("  ✅ TREATMENT GATE: the run differs from the reference in EXACTLY its declared keys.")
    print("     ⚠️ This says the CONFIGURATION matches the declaration. It says nothing about "
          "whether the treatment had the intended EFFECT.")
    return 0


def selftest():
    rc = 0
    print("SELFTEST treatcheck — fixtures (portable):")
    base = {"A": 1, "B": 2, "P": "/host/path"}
    arm = {"A": 1, "B": 9, "P": "/host/path"}          # declares B
    ref = {"A": 1, "B": 2, "P": "/ref/path"}

    def arm_case(name, resolved, want):
        nonlocal rc
        got = check(base, arm, ref, resolved, label=name)
        ok = got == want
        print(f"  {'✅' if ok else '⛔'} {name}: rc={got} wanted {want}\n")
        if not ok:
            rc = 1

    arm_case("exact treatment",     {"A": 1, "B": 9, "P": "/mine"},           0)
    arm_case("treatment MISSING",   {"A": 1, "B": 2, "P": "/mine"},           1)
    arm_case("EXTRA contamination", {"A": 7, "B": 9, "P": "/mine"},           1)
    arm_case("both at once",        {"A": 7, "B": 2, "P": "/mine"},           1)
    # a path-only difference must not register as either
    arm_case("path-only noise",     {"A": 1, "B": 9, "P": "/somewhere/else"}, 0)

    # The archived runs live in the PRIVATE archive; its path is never written in a public tree.
    ARCH = os.path.join(os.environ.get("SALTWORKS_ARCHIVE_ROOT", "/nonexistent-set-SALTWORKS_ARCHIVE_ROOT"), "silicon-ndf-drv-0827")
    if "SALTWORKS_ARCHIVE_ROOT" not in os.environ:
        print("PRODUCTION ARMS SKIPPED: SALTWORKS_ARCHIVE_ROOT is unset (the archive path is private; export it to run them)")
    CFG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "silicon-runs-0827")
    if os.path.isdir(ARCH):
        print("PRODUCTION ARMS (411-key resolved sets from the archived DRV runs):")
        R = json.load(open(f"{ARCH}/inputs/tt-submitted-reference/tt_submission/resolved.json"))
        BC = json.load(open(f"{CFG}/config-ndf-base.json"))
        for tag in ("ndf-1d", "ndf-2a", "ndf-2b"):
            got = check(BC, json.load(open(f"{CFG}/config-{tag}.json")), R,
                        json.load(open(f"{ARCH}/ndf/{tag}/resolved.json")), label=tag)
            print(f"  {'✅' if got == 0 else '⛔'} {tag}: rc={got} wanted 0\n")
            if got != 0:
                rc = 1
        # ⭐ REAL FAILURE ARMS, BUILT FROM REAL RUNS RATHER THAN SYNTHESISED:
        #    2a's declaration against 1d's ACTUAL resolved set is exactly what
        #    "the CTS treatment silently never happened" looks like on this box.
        got = check(BC, json.load(open(f"{CFG}/config-ndf-2a.json")), R,
                    json.load(open(f"{ARCH}/ndf/ndf-1d/resolved.json")), label="2a decl vs 1d run")
        print(f"  {'✅' if got == 1 else '⛔'} MISSING arm (real data): rc={got} wanted 1\n")
        if got != 1:
            rc = 1
        got = check(BC, json.load(open(f"{CFG}/config-ndf-1d.json")), R,
                    json.load(open(f"{ARCH}/ndf/ndf-2a/resolved.json")), label="1d decl vs 2a run")
        print(f"  {'✅' if got == 1 else '⛔'} EXTRA arm (real data): rc={got} wanted 1\n")
        if got != 1:
            rc = 1
    else:
        print(f"⚠️ PRODUCTION ARMS SKIPPED — archive not mounted at {ARCH}.")
        print("   Fixtures prove the MECHANISM; the archive arms prove it on 411-key real sets.")
        print("   A skip is reported, never silent.")
    print("⇒ " + ("✅ SELFTEST PASSED" if rc == 0 else "⛔ SELFTEST FAILED"))
    return rc


if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if len(sys.argv) < 5:
        print(__doc__)
        sys.exit(2)
    try:
        a, b, c, d = (json.load(open(p)) for p in sys.argv[1:5])
    except (OSError, ValueError) as e:
        print(f"treatcheck: cannot read an input — {e}  (a blank is not a pass)")
        sys.exit(2)
    sys.exit(check(a, b, c, d))

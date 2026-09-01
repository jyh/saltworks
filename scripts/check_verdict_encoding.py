#!/usr/bin/env python3
"""A gate's VERDICT must survive a non-UTF-8 locale, or the gate has not run.

THE SPECIMEN THAT MOTIVATED THIS GATE IS IN THIS REPOSITORY AND WAS FIRING
BEFORE IT WAS WRITTEN. On real Windows (kenai, Python 3.12.10, stdout
redirected as it is in every CI step), `check_private_paths.py --self-test`
prints:

    ... pin audit driven on a real scratch repo <?> trichotomy ...

where `<?>` is U+FFFD. The gate's own em-dash (U+2014) was silently transcoded
to the single cp1252 byte 0x97, the stream stopped being valid UTF-8, and every
UTF-8 reader downstream -- the forge's log viewer above all -- substitutes the
replacement character. Exit status 0. Nothing reported it. It is the SUCCESS
path, so it happens on every green run.

=> THE RULE THIS GATE ENFORCES: a gate's output is a RECEIPT. A receipt that is
mojibake on one platform, or absent because the process died printing it, is
not a weaker receipt -- it is not a receipt. See `utf8_stdout.py` for the two
failure modes measured (LOSSY/exit 0 and FATAL/exit 1) and for why the repair
belongs in the gate rather than in the workflow's environment.

WHY THIS GATE IS PORTABLE AND THE WINDOWS LANE IS STILL NEEDED. This check
FORCES a cp1252 stdout on the child process, so it is a property of the source
that any platform can adjudicate -- it runs on ubuntu and reds there. That is
deliberate: the class must not be watchable only where it is native, or it goes
dark the day the Windows runner is unavailable. What the portable gate CANNOT
do is catch the failures nobody thought to simulate, which is the entire
argument for running the real gates on a real Windows runner as well. The two
are not redundant; they answer different questions, and the Scrub workflow
carries both.

NOT CLAIMED: that the hosted `windows-latest` image reproduces kenai's cp1252
default. It has never been measured, because this repository has never run a
Windows job. The lane added beside this gate is what measures it, and this
gate's forced-cp1252 arm holds whether it does or not.
"""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from utf8_stdout import ensure_utf8_stdout  # noqa: E402

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = REPO / "scripts"

# The child's stdout is forced to the codec real Windows hands a redirected
# stream. `surrogateescape` matches what was MEASURED there (Python 3.12.10),
# not the `strict` a reader would assume -- and the difference matters: strict
# turns the LOSSY mode fatal, which would make this gate pass for the wrong
# reason on a source that is still broken.
FORCED_LOCALE = "cp1252:surrogateescape"

# Every gate whose verdict this repository's CI reads. A gate absent from this
# list is unwatched, so the source arm below asserts the list is COMPLETE
# against the filesystem rather than trusting anyone to update it.
WATCHED = (
    "check_commit_trailers.py",
    "check_pr_descriptions.py",
    "check_private_paths.py",
    "check_verdict_encoding.py",
)

# An ASCII token that ONLY a completed run emits. Not the exit code: the FATAL
# mode exits 1, which is also "finding found", and it is not a duration or a
# byte count either -- both of those pass a run that died mid-sentence.
VERDICT_TOKEN = re.compile(rb"SELF-TEST[^\n]*\bOK\b")

# ⛔ AND THE TOKEN ARM ALONE IS NOT ENOUGH -- caught by this gate's own
# self-test, which is the entire reason the self-test exists. When the FATAL
# mode fires, CPython prints the OFFENDING SOURCE LINE in the traceback, and
# for these gates that line IS the print statement carrying the verdict:
#
#     File "check_private_paths.py", line 402, in main
#       print("check_private_paths SELF-TEST [gate ...]: OK (...)")
#
# So the token the gate never actually emitted appears in the output anyway,
# and a crashed run reads as a completed one. The first draft of this file
# passed the FATAL fixture for exactly that reason.
#
# The repair is not a cleverer token -- any token in a printed string is by
# construction also in the source line that prints it. It is an INDEPENDENT
# assertion on a marker only the interpreter emits, and a token search confined
# to the output that precedes it.
CRASH_MARKER = b"Traceback (most recent call last)"


def _run_under_cp1252(argv, cwd):
    """Run a gate with a non-UTF-8 stdout and return (exit code, RAW BYTES).

    Bytes, never str: decoding here would repair the very corruption the caller
    is trying to observe, and the check would pass on a broken gate.
    """
    env = dict(os.environ)
    env["PYTHONIOENCODING"] = FORCED_LOCALE
    # A parent already in UTF-8 mode would override the line above and the
    # child would be clean no matter what its source says -- the instrument
    # silently measuring nothing. Cleared rather than assumed absent.
    env.pop("PYTHONUTF8", None)
    env.pop("PYTHONLEGACYWINDOWSSTDIO", None)
    proc = subprocess.run(
        [sys.executable, *argv],
        cwd=str(cwd), env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        timeout=300,
    )
    return proc.returncode, proc.stdout


def _judge(name, code, raw, want_code, want_token=True):
    """Three independent assertions. Each catches a failure the others miss."""
    bad = []
    if code != want_code:
        bad.append(f"{name}: exit {code}, expected {want_code}")
    try:
        raw.decode("utf-8")
    except UnicodeDecodeError as e:
        high = sorted({b for b in raw if b > 0x7F})
        bad.append(
            f"{name}: verdict is NOT valid UTF-8 ({e.reason} at byte {e.start}); "
            f"high bytes {[hex(b) for b in high]} -- a UTF-8 reader renders "
            f"U+FFFD here. LOSSY mode: the gate exited {code} and said nothing "
            f"about it.")
    # The interpreter's own marker, checked INDEPENDENTLY of the token: see
    # CRASH_MARKER above for why the token alone reads a crash as a success.
    crashed = CRASH_MARKER in raw
    if crashed:
        bad.append(
            f"{name}: the process DIED while producing its verdict "
            f"(traceback present). FATAL mode. Tail: {raw[-200:]!r}")
    # Search only what preceded the traceback, so the echoed source line cannot
    # supply the token the run never printed.
    emitted = raw.split(CRASH_MARKER)[0] if crashed else raw
    if want_token and not VERDICT_TOKEN.search(emitted):
        bad.append(
            f"{name}: no completed-run verdict in {len(emitted)} bytes of "
            f"output before any traceback. Tail: {emitted[-200:]!r}")
    return bad


def _run_native(argv, cwd):
    """Run a gate under whatever THIS platform's default stdout codec is.

    The deliberate opposite of `_run_under_cp1252`: nothing is forced and
    nothing is cleared, because the question this answers is what the runner
    actually does. On a UTF-8 platform it passes trivially and says so; on a
    cp1252 one it is the arm that catches what the simulation did not think to
    simulate.
    """
    proc = subprocess.run(
        [sys.executable, *argv],
        cwd=str(cwd),
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        timeout=300,
    )
    return proc.returncode, proc.stdout


def check_native() -> int:
    """THE UNSIMULATED ARM. Every watched gate, this platform's real codec.

    Kept separate from `check_repo_gates` rather than folded into it: one
    measures a property of the SOURCE (forced codec, same verdict everywhere),
    the other measures a property of the RUNNER. Merging them would produce a
    single green whose meaning depended on which platform printed it.
    """
    # ⛔ REPORTED FROM A CHILD, NOT FROM `sys.stdout` HERE. This process called
    # ensure_utf8_stdout() in main() before reaching this line, so its OWN
    # stdout says 'utf-8' on every platform -- printing that would report the
    # repair as if it were the runner's default and quietly answer a different
    # question than the one asked. Caught on kenai, where the parent said
    # 'utf-8' while the child it was judging was still natively cp1252.
    _, probe = _run_native(
        ["-c", "import sys,locale;print(f'stdout.encoding={sys.stdout.encoding!r} "
               "errors={sys.stdout.errors!r} "
               "preferred={locale.getpreferredencoding(False)!r} "
               "utf8_mode={sys.flags.utf8_mode}')"], REPO)
    print("native codec of a fresh child here: "
          + probe.decode("utf-8", "backslashreplace").strip())
    bad = []
    for name in WATCHED:
        path = SCRIPTS / name
        if not path.exists():
            bad.append(f"{name}: WATCHED names a gate that does not exist")
            continue
        code, raw = _run_native([str(path), "--self-test"], REPO)
        bad += _judge(name, code, raw, want_code=0)
    if bad:
        print(f"FAIL [verdict-encoding --native]: {len(bad)} finding(s).\n")
        for b in bad:
            print(f"  - {b}")
        return 1
    print(f"check_verdict_encoding --native: OK -- {len(WATCHED)} gate(s) keep "
          f"a valid UTF-8 verdict under this runner's OWN default codec.")
    return 0


def check_repo_gates():
    """THE REAL ARM: every watched gate's self-test, under a cp1252 stdout."""
    bad = []
    for name in WATCHED:
        path = SCRIPTS / name
        if not path.exists():
            bad.append(f"{name}: WATCHED names a gate that does not exist")
            continue
        code, raw = _run_under_cp1252([str(path), "--self-test"], REPO)
        bad += _judge(name, code, raw, want_code=0)

    # THE LIST ITSELF IS AN ASSERTION. A gate added to scripts/ and not to
    # WATCHED would be unwatched here while everything stayed green -- the
    # lane-coverage class one level down, which is the class this whole row
    # exists to close.
    on_disk = {p.name for p in SCRIPTS.glob("check_*.py")}
    missed = on_disk - set(WATCHED)
    if missed:
        bad.append(f"gates present but UNWATCHED by this file: {sorted(missed)}"
                   " -- add them to WATCHED or state why they carry no verdict")

    # THE SOURCE ARM. The runtime arm above proves today's output is clean; it
    # cannot prove the NEXT em-dash will be. Only a call to ensure_utf8_stdout
    # makes that structural.
    for name in WATCHED:
        path = SCRIPTS / name
        if not path.exists():
            continue
        src = path.read_text(encoding="utf-8")
        if "ensure_utf8_stdout()" not in src:
            bad.append(f"{name}: never calls ensure_utf8_stdout() -- its verdict "
                       f"is at the locale's mercy the moment it prints a "
                       f"non-ASCII character")

    if bad:
        print(f"FAIL [verdict-encoding]: {len(bad)} finding(s).\n")
        for b in bad:
            print(f"  - {b}")
        print("\nRepair: call ensure_utf8_stdout() at entry (see "
              "scripts/utf8_stdout.py). Do NOT set PYTHONUTF8 in the workflow "
              "-- that hides the class from the lane that watches it.")
        return 1
    print(f"check_verdict_encoding SELF-TEST-EQUIVALENT: OK -- {len(WATCHED)} "
          f"gate(s) keep a valid UTF-8 verdict under {FORCED_LOCALE}.")
    return 0


# ---------------------------------------------------------------- self-test

_LOSSY_FIXTURE = (
    'print("SELF-TEST: OK \\u2014 a verdict with an em-dash")\n'
)

_FATAL_FIXTURE = (
    'print("SELF-TEST: OK \\u26d4 a char cp1252 has no byte for")\n'
)

_FIXED_FIXTURE = (
    "import sys\n"
    "sys.path.insert(0, {scripts!r})\n"
    "from utf8_stdout import ensure_utf8_stdout\n"
    "ensure_utf8_stdout()\n"
    'print("SELF-TEST: OK \\u2014 an em-dash \\u26d4 and worse")\n'
)


def self_test():
    """BOTH ARMS DRIVEN, and the two failure modes driven SEPARATELY.

    A single 'it breaks' fixture would let a repair that fixes one mode and not
    the other report success -- and these two fail in opposite directions, so
    that is not a hypothetical.
    """
    failures = []
    with tempfile.TemporaryDirectory() as td:
        d = pathlib.Path(td)

        # ARM 1 -- LOSSY. Must be CAUGHT: exit 0, output present, not UTF-8.
        (d / "lossy.py").write_text(_LOSSY_FIXTURE, encoding="utf-8")
        code, raw = _run_under_cp1252([str(d / "lossy.py")], d)
        found = _judge("lossy", code, raw, want_code=0)
        if code != 0:
            failures.append(f"LOSSY fixture should exit 0, got {code} -- the "
                            f"fixture is driving the FATAL mode instead")
        if not any("NOT valid UTF-8" in f for f in found):
            failures.append("LOSSY fixture was not caught: an em-dash through "
                            "cp1252 must leave the stream invalid UTF-8")
        if raw and 0x97 not in set(raw):
            failures.append("LOSSY fixture did not produce the cp1252 em-dash "
                            "byte 0x97 -- the instrument is not measuring cp1252")

        # ARM 2 -- FATAL. Must be CAUGHT, and by the TOKEN arm, not the codec
        # arm: there is no output at all to be invalid.
        (d / "fatal.py").write_text(_FATAL_FIXTURE, encoding="utf-8")
        code, raw = _run_under_cp1252([str(d / "fatal.py")], d)
        if code == 0:
            failures.append("FATAL fixture should have died printing, got exit 0")
        found = _judge("fatal", code, raw, want_code=0)
        if not any("DIED while producing its verdict" in f for f in found):
            failures.append("FATAL fixture was not caught by the crash arm")
        # THE REGRESSION THIS FILE'S OWN FIRST DRAFT NEEDED. The traceback
        # echoes the source line, so the raw output DOES contain the token;
        # assert that fact explicitly, so a future edit that drops the
        # traceback-stripping cannot pass this arm by accident.
        if not VERDICT_TOKEN.search(raw):
            failures.append("FATAL fixture no longer carries the token in its "
                            "traceback -- this arm is no longer testing the "
                            "confusion it was written for")
        # ...and that the STRIPPED output carries it no longer. Both arms firing
        # here is correct, not a double count: the print died before emitting a
        # byte, so there genuinely is no verdict AND there is a traceback. What
        # would be wrong is the token surviving the split.
        if VERDICT_TOKEN.search(raw.split(CRASH_MARKER)[0]):
            failures.append("the token survived the traceback split -- the "
                            "echoed source line is still being counted as a "
                            "verdict, which is the defect this arm exists for")

        # ARM 3 -- THE CONTROL, and it is the arm that proves the other two are
        # not simply always-true. Same characters, both of them, plus the
        # repair: must pass ALL THREE assertions.
        (d / "fixed.py").write_text(
            _FIXED_FIXTURE.format(scripts=str(SCRIPTS)), encoding="utf-8")
        code, raw = _run_under_cp1252([str(d / "fixed.py")], d)
        found = _judge("fixed", code, raw, want_code=0)
        if found:
            failures.append(f"CONTROL failed -- the repair does not repair: {found}")
        if ("—".encode("utf-8") not in raw
                or "⛔".encode("utf-8") not in raw):
            failures.append("CONTROL did not carry both characters through as "
                            "UTF-8; it may be passing by printing nothing")

    if failures:
        print(f"check_verdict_encoding SELF-TEST: FAIL ({len(failures)})")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("check_verdict_encoding SELF-TEST: OK (LOSSY caught by the codec arm; "
          "FATAL caught by the crash arm, and the echoed source line does "
          "not launder into a verdict; control carries both characters "
          "through the repair and passes all three assertions)")
    return 0


def main():
    ensure_utf8_stdout()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--native", action="store_true",
                    help="judge each gate under THIS platform's own stdout "
                         "codec instead of a forced cp1252")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if a.native:
        return check_native()
    return check_repo_gates()


if __name__ == "__main__":
    sys.exit(main())

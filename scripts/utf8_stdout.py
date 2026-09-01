"""A gate's verdict must survive the platform's locale.

MEASURED ON REAL WINDOWS (kenai, Python 3.12.10, 2026-08-31), not reasoned:
with stdout redirected -- which is every CI step -- `sys.stdout.encoding` is
**cp1252** and `errors` is `surrogateescape`. macOS and Linux default to UTF-8,
so the whole class below is invisible on them BY CONSTRUCTION. It needs no
Windows to be true; it only needed a Windows box to be noticed.

TWO FAILURE MODES, and they fail in OPPOSITE directions. That is the reason
this module exists rather than a one-line reconfigure at each call site: a
reader who has seen only one of them will "fix" the other wrongly.

  LOSSY (silent, exit 0).  A character that IS in the cp1252 table transcodes
  without complaint. The em-dash this repo's gates print in nearly every
  verdict -- `OK - 3 open PR(s)` is spelled with U+2014 -- becomes the single
  byte 0x97. The step exits 0 and the log LOOKS fine to the process that wrote
  it. It is no longer valid UTF-8, so every UTF-8 reader downstream -- the
  forge's own log viewer above all -- substitutes U+FFFD. The verdict is
  corrupted and NOTHING reports it.

  FATAL (loud, exit 1, and worse).  A character that is NOT in the 256-entry
  cp1252 table raises UnicodeEncodeError. Measured: stdout is EMPTY and the
  process exits **1**. That is the SAME exit code these gates use for "finding
  found", so a crash while printing a finding is indistinguishable from the
  finding itself -- except the finding text is gone. And it runs the other way
  too: `check_pr_descriptions.py` echoes forge prose it did not author (a PR
  title, a body, an API error string) into notes printed on the CLEAN path, so
  one emoji in one PR title reds a clean repo with an empty log.

WHY THIS AND NOT `PYTHONUTF8=1` IN THE WORKFLOW. Setting the interpreter into
UTF-8 mode from the lane repairs the symptom for whatever the lane happens to
run and leaves every other invocation -- a developer's shell, a hook, a
scheduled task, another workflow -- exactly as broken. It also makes the
Windows lane pass straight over the class it exists to watch, which is the
jas lane's stated doctrine (`test.yml`: "DO NOT set PYTHONUTF8,
PYTHONIOENCODING or PYTHONLEGACYWINDOWSSTDIO here"). The gate owns its own
receipt; the environment is not asked to be kind.

`errors="backslashreplace"` is deliberate and is NOT redundant under UTF-8.
Forge JSON can carry lone surrogates, which UTF-8 cannot encode either; with
strict errors that is the FATAL mode again, one layer down. backslashreplace
keeps the verdict printable and lossy-but-VISIBLE (`\udce9`) rather than
absent. A gate that cannot say what it found has not run.
"""

from __future__ import annotations

import sys

# The exact byte a cp1252 em-dash collapses to. Named here because the gate that
# checks this property asserts against it, and a bare 0x97 in a test reads as a
# magic number three months from now.
CP1252_EMDASH_BYTE = 0x97


def ensure_utf8_stdout() -> None:
    """Pin stdout/stderr to UTF-8 for the life of this process.

    Idempotent and safe to call before argument parsing. Both streams: a
    traceback on stderr is a verdict too, and it is the one that carries the
    forge prose when the FATAL mode fires.
    """
    for stream in (sys.stdout, sys.stderr):
        # `reconfigure` exists on TextIOWrapper only. Under pytest's capture, or
        # anything else that swaps in a plain object, it does not -- and a gate
        # that dies here would fail for the opposite of the reason it exists.
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is None:
            continue
        reconfigure(encoding="utf-8", errors="backslashreplace")

#!/usr/bin/env python3
"""Does a provenance bundle actually BIND the artifact it ships with?

WHY THIS EXISTS. On 2026-08-07 the S2 bundle (`a5d2ef7`) landed with an
honest-sounding qualification: *"this bundle certifies PROVENANCE, NOT
CONTENTS -- a faithful copy of what the executor did, whose interior nobody
has vetted."* The qualification was written because nobody could READ a
548 KB transcript into a working context.

**But a transcript does not have to be read to be checked.** The executor's
`Write` and `Edit` tool calls are structured data. Replay them in order and
you get a file; hash that file against the committed blob and the bundle
either reproduces the artifact or it does not. That is a MACHINE question,
and the size of the file is exactly why a machine should answer it.

The first run of this tool on S2 returned IDENTICAL -- 23,837 characters,
515 lines, character-for-character. So the bundle binds contents after all,
and its README understated itself.

⛔ WHAT A GREEN FROM THIS TOOL DOES AND DOES NOT MEAN.
  IT DOES mean: the artifact in git is exactly what the logged tool calls
    produced -- no hand-edit, no post-hoc touch-up, no drift since.
  IT DOES NOT mean the transcript's interior has been vetted. Replaying a
    record proves the record produced the file; it says NOTHING about
    whether what the agent did along the way was sound. Content-BOUND is
    not content-VETTED, and this tool only ever answers the first.
  IT DOES NOT mean the transcript is a faithful copy of its source -- that
    is `--source`, a separate check, because a doctored transcript replays
    to whatever it was doctored to say.

📌 THE DRIFT THIS EXISTS TO CATCH. The S2 README claimed the bundle was
bound "in the same commit". It was not: the program landed in `bf2de34` and
the bundle in `a5d2ef7`, one commit later. Nothing about that is dishonest
-- `a5d2ef7` descends from `bf2de34`, so the record cannot predate the
artifact -- but "same commit" was the mechanism claimed, and it was not the
mechanism used. A LATER commit can edit `Program.lean` and the bundle will
sit there unchanged, still described as bound. This tool is what makes that
detectable, and it is why the check belongs in CI rather than in a README.

⛔ AND THE DRIFT ARRIVED IN NINETY MINUTES, WHICH CORRECTED THIS TOOL'S OWN
ANCHORING. At 14:0x the same day, math added 841 lines of S3(b) to
`Program.lean`. Legitimate development -- and it made the first version of this
check, anchored at `HEAD:...`, go permanently red. The reasoning behind that
anchor ("a pinned rev passes forever while the artifact drifts") is right for a
FROZEN artifact and WRONG for a LIVE MODULE.

  => A birth record binds a BIRTH. Pin the birth commit, and the replay claim --
     "the executor's logged tool calls reproduce this file exactly" -- stays true
     and checkable forever. Whether HEAD has since moved on is a different and
     equally real question; it belongs to `docs/provenance/verify.sh`, which
     answers it by pinning the CURRENT blob.

A gate that reds on expected behaviour is a gate someone switches off, and that
failure mode loses BOTH checks.

    python3 docs/ledger-tools/provenance_replay.py \
        --bundle docs/provenance/s2/s2-executor-transcript.jsonl \
        --target /Users/jyh/projects/claude/saltworks/SaltWorks/Stack/Program.lean \
        --against bf2de34:SaltWorks/Stack/Program.lean

    python3 docs/ledger-tools/provenance_replay.py --manifest docs/provenance/REPLAY-MANIFEST.tsv

EXIT: 0 replay reproduces the blob · 1 MISMATCH (drift, or never bound) ·
2 could not read/replay -- following `import-closure.py`'s three-way exit
for the reason that tool learned the hard way: a green from something that
read nothing is worse than a red.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


class Unreadable(Exception):
    """Anything that would otherwise produce a green from an empty read."""


def sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def git_blob(rev_path: str) -> bytes:
    """`rev:path` -> bytes. Raises Unreadable rather than returning b''."""
    p = subprocess.run(["git", "-C", REPO, "cat-file", "-p", rev_path],
                       capture_output=True)
    if p.returncode != 0:
        raise Unreadable(f"git cat-file {rev_path}: {p.stderr.decode().strip()}")
    return p.stdout


def read_ops(bundle: str, target: str):
    """Every Write/Edit tool call in the transcript aimed at `target`, in order.

    A transcript line that will not parse is a REFUSAL, not a skip: a bundle
    with unparseable lines is a bundle whose op sequence may have holes, and
    a hole silently drops an edit that would have changed the answer.
    """
    if not os.path.exists(bundle):
        raise Unreadable(f"no such bundle: {bundle}")
    ops, seen_any, bad = [], False, 0
    with open(bundle, encoding="utf-8", errors="strict") as fh:
        for n, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            seen_any = True
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                bad += 1
                continue
            msg = rec.get("message") or {}
            content = msg.get("content") if isinstance(msg, dict) else None
            if not isinstance(content, list):
                continue
            for c in content:
                if not (isinstance(c, dict) and c.get("type") == "tool_use"):
                    continue
                inp = c.get("input") or {}
                if inp.get("file_path") != target:
                    continue
                ops.append((n, c.get("name"), inp))
    if not seen_any:
        raise Unreadable(f"bundle is empty: {bundle}")
    if bad:
        raise Unreadable(f"{bad} unparseable line(s) in {bundle} -- op sequence may have holes")
    return ops


def replay(ops):
    """Apply the ops in transcript order. Returns (text, trace)."""
    buf, trace = None, []
    for n, name, inp in ops:
        if name == "Write":
            buf = inp.get("content")
            if buf is None:
                raise Unreadable(f"line {n}: Write with no content")
            trace.append(f"  line {n:5d}  Write   -> {len(buf)} chars, {len(buf.splitlines())} lines")
        elif name in ("Edit", "NotebookEdit"):
            if buf is None:
                raise Unreadable(f"line {n}: {name} before any Write -- "
                                 "the bundle does not contain the file's creation")
            old, new = inp.get("old_string"), inp.get("new_string")
            if old is None or new is None:
                raise Unreadable(f"line {n}: {name} missing old_string/new_string")
            if old not in buf:
                raise Unreadable(f"line {n}: {name} old_string not present -- "
                                 "the file was changed by something outside this bundle")
            count = buf.count(old)
            if inp.get("replace_all"):
                buf = buf.replace(old, new)
            else:
                if count > 1:
                    raise Unreadable(f"line {n}: {name} old_string occurs {count}x "
                                     "without replace_all -- ambiguous replay")
                buf = buf.replace(old, new, 1)
            trace.append(f"  line {n:5d}  {name:6s}  -> {len(buf)} chars "
                         f"(-{len(old)}+{len(new)})")
        else:
            trace.append(f"  line {n:5d}  {name} (not a mutation, ignored)")
    if buf is None:
        raise Unreadable("no Write/Edit for that target in this bundle -- "
                         "nothing to replay (check --target: it is the "
                         "ABSOLUTE path as the executor saw it)")
    return buf, trace


def check_one(bundle: str, target: str, against: str, source: str | None, quiet=False) -> int:
    out = print if not quiet else (lambda *a, **k: None)
    ops = read_ops(bundle, target)
    text, trace = replay(ops)
    blob = git_blob(against)

    out(f"BUNDLE   {os.path.relpath(bundle, REPO)}")
    out(f"TARGET   {target}")
    out(f"AGAINST  {against}")
    out(f"OPS      {len(ops)} mutation(s) replayed")
    for t in trace:
        out(t)

    got = text.encode("utf-8")
    out(f"\n  replayed  {len(got):7d} bytes  {len(text.splitlines()):4d} lines  {sha256(got)}")
    out(f"  committed {len(blob):7d} bytes  "
        f"{len(blob.decode('utf-8', 'replace').splitlines()):4d} lines  {sha256(blob)}")

    rc = 0
    if got == blob:
        out("\n✅ BOUND — the replay reproduces the committed artifact exactly.")
        out("   (content-BOUND, not content-VETTED: see this file's docstring.)")
    else:
        out("\n⛔ MISMATCH — the bundle does NOT reproduce the committed artifact.")
        out("   Either the artifact drifted after the bundle landed, or the")
        out("   bundle never bound it. Both are findings; neither is a green.")
        rc = 1

    if source:
        if not os.path.exists(source):
            out(f"\n⚠️  SOURCE not on disk: {source} (copy unverifiable, not disproved)")
        else:
            with open(source, "rb") as fh:
                sbytes = fh.read()
            with open(bundle, "rb") as fh:
                bbytes = fh.read()
            if sbytes == bbytes:
                out(f"\n✅ FAITHFUL COPY — bundle == source, {sha256(bbytes)}")
            else:
                out(f"\n⛔ COPY DIFFERS from source {source}")
                out(f"   bundle {sha256(bbytes)}\n   source {sha256(sbytes)}")
                rc = 1

    # One closing line, because a reader who sees "✅ BOUND" and stops reading
    # would miss a ⛔ printed beneath it. The verdict is the LAST thing said.
    out(f"\nVERDICT: {'PASS' if rc == 0 else 'FAIL'} (exit {rc})")
    return rc


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--bundle", help="the transcript .jsonl")
    ap.add_argument("--target", help="absolute file path AS THE EXECUTOR SAW IT")
    ap.add_argument("--against", help="git rev:path to compare against")
    ap.add_argument("--source", help="the machine-local original, to verify the copy")
    ap.add_argument("--manifest", help="TSV: bundle<TAB>target<TAB>against[<TAB>source]; "
                                       "'#' comments. Checks every row, worst exit wins.")
    a = ap.parse_args()

    try:
        if a.manifest:
            rows = []
            with open(a.manifest, encoding="utf-8") as fh:
                for line in fh:
                    line = line.rstrip("\n")
                    if not line.strip() or line.lstrip().startswith("#"):
                        continue
                    rows.append(line.split("\t"))
            if not rows:
                raise Unreadable(f"manifest has no rows: {a.manifest}")
            worst = 0
            for i, r in enumerate(rows):
                if len(r) < 3:
                    raise Unreadable(f"manifest row {i+1}: need 3 columns, got {len(r)}")
                print("=" * 72)
                worst = max(worst, check_one(r[0], r[1], r[2],
                                             r[3] if len(r) > 3 else None))
            print("=" * 72)
            print(f"{len(rows)} bundle(s) checked, worst exit {worst}")
            return worst
        if not (a.bundle and a.target and a.against):
            ap.error("--bundle, --target and --against are all required "
                     "(or use --manifest)")
        return check_one(a.bundle, a.target, a.against, a.source)
    except Unreadable as e:
        print(f"⛔ COULD NOT CHECK: {e}", file=sys.stderr)
        print("   exit 2 — this is NOT a pass. Nothing was verified.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())

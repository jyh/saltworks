#!/usr/bin/env python3
"""gate_scan.py -- the hooks ask the GATES' questions, with the gates' own patterns.

WHY THIS EXISTS
---------------
Until 2026-09-13 the pre-push and commit-msg hooks carried their own copy of the
session-trailer pattern, typed as a grep. The copy was narrower than the gate it
claimed to mirror: a lowercase key, a space before the colon, and a chat-service
URL that is not a session URL all went RED in CI and PASSED both hooks (census D
#2, driven: 3 of 5 shapes). CI runs after the push has landed, so the hook was the
only check before the public remote, and it was the weaker one.
  => A HOOK THAT RETYPES A GATE'S PATTERN IS A SECOND GATE WITH NO TEST, AND IT
     DRIFTS IN THE DIRECTION NOBODY SEES: it only ever lets more through.

So nothing here spells a forbidden shape. The patterns and the matching functions
are LOADED FROM THE GATE SCRIPTS the caller names, and a gate that cannot be loaded
is a refusal (exit 2), never a pass.

THE SECOND GAP THIS CLOSES (census D #3)
----------------------------------------
`check_private_paths.py --range A..B` scans the NET diff. A path added in one commit
and removed in the next is in neither endpoint, so it passed the hook -- while both
blobs reach the public remote and every clone receives them. CI's `--history` arm
sees it, after the fact. `push` mode here walks the pushed range ONE COMMIT AT A
TIME with the gate's own `commit_introduced` (merges charged only for what no parent
carries), and filters by the gate's own history baseline key: the same verdict CI's
`--history` would reach, restricted to the commits this push sends.

The same introduced lines are also scanned with the TRAILER gate's patterns. That
gate scans the tip's tracked files in CI, so a session URL added in one commit and
removed in the next passes it too. Same population, same fix.

USAGE (the hooks are the callers; the repo root is the working directory)
    gate_scan.py message --trailers-gate T MSGFILE
    gate_scan.py push --trailers-gate T --paths-gate P [--history-baseline B] RANGE
exit 0 clean, 1 finding (named on stderr), 2 could not look (refuse).

This file is 100644 on purpose: the hooks invoke it as "$PY" gate_scan.py after
choosing an interpreter by execution, and the executable bit would invite running
its shebang on a machine where `python3` is a stub.
"""
import argparse
import subprocess
import sys
import types


def load_gate(path: str, needs: tuple):
    """Exec a gate's source as a module. Its main() sits behind __main__, so
    nothing runs. Returns None when the file is unreadable or lacks a name the
    caller needs -- the caller refuses, it never falls back to a local copy."""
    try:
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
    except OSError:
        return None
    mod = types.ModuleType("_gate_" + str(abs(hash(path))))
    mod.__file__ = path
    try:
        exec(compile(src, path, "exec"), mod.__dict__)
    except Exception as e:  # a gate that cannot load is a gate that cannot look
        print(f"gate_scan: {path} failed to load: {type(e).__name__}: {e}", file=sys.stderr)
        return None
    missing = [n for n in needs if not hasattr(mod, n)]
    if missing:
        print(f"gate_scan: {path} lacks {', '.join(missing)}", file=sys.stderr)
        return None
    return mod


def git(*args: str) -> str:
    return subprocess.run(["git", *args], capture_output=True, text=True,
                          encoding="utf-8", check=True).stdout


def show(rows, verb: str) -> None:
    for ident, what, line in rows:
        print(f"    {ident}  {verb} {what}", file=sys.stderr)
        # The trailer gate returns a LINE NUMBER in place of the text (desk PX);
        # the paths gate returns the line, and this output is local.
        if isinstance(line, int):
            print(f"        at line {line}", file=sys.stderr)
        elif line:
            print(f"        {line[:110]}", file=sys.stderr)


def message_mode(trailers, msgfile: str) -> int:
    try:
        with open(msgfile, encoding="utf-8") as fh:
            body = fh.read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"gate_scan: cannot read the message file: {e}", file=sys.stderr)
        return 2
    found = trailers.scan([("message", body)])
    if found:
        show(found, "carries")
        return 1
    return 0


def push_mode(trailers, paths, baseline_path, rev_range: str) -> int:
    try:
        commits = [l.split() for l in git("rev-list", "--parents", rev_range).splitlines() if l.strip()]
        # `git log RANGE` walks the same set rev-list just listed; one call reads every message.
        log = git("log", "--format=%H%x1f%B@@GATESCAN@@", rev_range)
    except subprocess.CalledProcessError as e:
        print(f"gate_scan: cannot list '{rev_range}': {e.stderr.strip()}", file=sys.stderr)
        return 2
    # FAIL CLOSED, the gates' own rule: nothing scanned is not nothing wrong.
    if not commits:
        print(f"gate_scan: ZERO commits in '{rev_range}' -- refusing to call that clean.", file=sys.stderr)
        return 2

    baseline = paths.load_history_baseline(baseline_path) if baseline_path else paths.load_history_baseline()
    accepted = baseline or set()
    empty = paths.empty_tree_sha()
    bodies = {}
    for chunk in log.split("@@GATESCAN@@"):
        chunk = chunk.strip("\n")
        if chunk:
            sha, _, body = chunk.partition("\x1f")
            bodies[sha.strip()] = body

    msg_bad, line_bad = [], []
    nlines = nbase = 0
    for sha, *parents in commits:
        short = sha[:10]
        if sha not in bodies:
            print(f"gate_scan: no message read for {short} -- refusing.", file=sys.stderr)
            return 2
        msg_bad += [(short, what, line) for _, what, line in trailers.scan([(sha, bodies[sha])])]
        rows = paths.commit_introduced(sha, parents, empty)
        nlines += len(rows)
        for f, what, line in paths.scan(rows):
            if paths.history_key(sha, f, line) in accepted:
                nbase += 1
            else:
                line_bad.append((f"{short} {f}", what, line))
        line_bad += [(f"{short} {f}", what, line) for f, what, line in trailers.scan(rows)]

    if msg_bad:
        print(f"REFUSED: {len(msg_bad)} commit message(s) carry a shape the trailer gate forbids:", file=sys.stderr)
        show(msg_bad, "carries")
    if line_bad:
        print(f"REFUSED: {len(line_bad)} line(s) INTRODUCED by a commit in this push match a gate's"
              " forbidden shape.\n  Per commit, so a line a later commit removes still counts:"
              " its blob is pushed either way.", file=sys.stderr)
        show(line_bad, "introduces")
    if msg_bad or line_bad:
        return 1
    print(f"gate_scan OK: {len(commits)} commit(s) one at a time -- messages vs "
          f"{len(trailers.FORBIDDEN)} trailer shape(s); {nlines} introduced line(s) vs "
          f"{len(paths.FORBIDDEN)} path shape(s) + the trailer shapes"
          + (f"; {nbase} accepted by the history baseline" if nbase else "")
          + ("" if baseline is not None else "; NO history baseline was found, so none is accepted")
          + ".")
    return 0


def main(argv) -> int:
    ap = argparse.ArgumentParser(description="the hooks' view of the gates")
    sub = ap.add_subparsers(dest="mode", required=True)
    m = sub.add_parser("message")
    m.add_argument("--trailers-gate", required=True)
    m.add_argument("msgfile")
    p = sub.add_parser("push")
    p.add_argument("--trailers-gate", required=True)
    p.add_argument("--paths-gate", required=True)
    p.add_argument("--history-baseline", default=None)
    p.add_argument("range")
    args = ap.parse_args(argv)

    trailers = load_gate(args.trailers_gate, ("FORBIDDEN", "scan"))
    if trailers is None:
        print(f"gate_scan: the trailer gate could not be loaded from {args.trailers_gate}.", file=sys.stderr)
        return 2
    if args.mode == "message":
        return message_mode(trailers, args.msgfile)
    paths = load_gate(args.paths_gate, ("FORBIDDEN", "scan", "commit_introduced", "empty_tree_sha",
                                        "history_key", "load_history_baseline"))
    if paths is None:
        print(f"gate_scan: the private-paths gate could not be loaded from {args.paths_gate}.", file=sys.stderr)
        return 2
    return push_mode(trailers, paths, args.history_baseline, args.range)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except subprocess.CalledProcessError as e:
        # A git call inside a gate function failed. That is "could not look",
        # and it must not read as a finding (1) any more than as a pass (0).
        print(f"gate_scan: git failed mid-scan: {e.cmd}: {(e.stderr or '').strip()}", file=sys.stderr)
        sys.exit(2)

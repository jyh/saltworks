#!/usr/bin/env python3
"""sealgate — COMMIT, THEN OPEN. An order gate for publish-before-checking.

A protocol whose integrity depends on ORDER cannot be enforced by intending to
follow it. This tool is the enforcing artifact for one such protocol shape:

    1. you write your verdicts;
    2. you COMMIT to them — a hash of those exact bytes is appended to a record
       and that record is PUSHED, so the commitment is outside your hand;
    3. only then may you OPEN the reference you are being scored against.

Step 3 is the one that must be mechanised. Every other step is honest by
default; step 3 is where a mind that has seen the answer cannot un-see it, and
where "I checked my verdicts were final first" is unfalsifiable after the fact.

⭐ THE GENERAL LAW THIS IMPLEMENTS (helm, 2026-08-16 22:56:58): any protocol
  whose integrity depends on ORDER can be enforced by making the LATER step
  verify the EARLIER step's PUBLISHED ARTIFACT and REFUSE on mismatch.
⚠️ AND ITS RIDER, WHICH IS WHY THIS TOOL IS SHAPED NARROWLY: the gate only holds
  where the property is DECIDABLE. "Is this declaration honest?" is not, and a
  gate placed on the undecidable half would be decoration. So this gate decides
  exactly one question — DOES A PUBLISHED COMMITMENT EXIST WHOSE HASH EQUALS
  THESE BYTES? — and claims nothing about whether the verdicts are any good.

⛔ WHY `open` DOES THE OPENING, AND DOES NOT MERELY ADVISE. This seat has already
  shipped the other shape: a correct check whose exit status nothing consumes,
  read carefully, with the guarded bytes printing one line below the refusal.
  A CORRECT CHECK NOTHING CONSUMES IS A PRINTOUT. So the reference is emitted BY
  this tool or not at all — `tool && action` collapsed into one object, the same
  form as `fenceread.sh` beside it.

⛔ NO RE-ROLL. `commit` refuses a second commitment for a label that already has
  one. A protocol that lets you re-commit after a peek is a protocol with no
  earlier step. The refusal is the feature; a new label is the honest move, and
  the record shows both.

⛔ PUBLISHED MEANS AT THE REMOTE, NOT ON DISK. A commitment sitting in a working
  tree is a note to yourself: you can edit it, and nobody can tell. `open`
  therefore reads the record from `--published-at` (a remote-tracking ref, e.g.
  `origin/master`) via `git show`, never from the file on disk. A record that is
  written but unpushed refuses, loudly, naming the push as the fix.
  ⚠️ THE FETCH IS YOURS TO DO. A remote-tracking ref is a LOCAL CACHE — this
    seat's banked law — so `open` reports the ref's own commit and tells you to
    fetch; it cannot distinguish "not pushed" from "pushed but not fetched", and
    it says so instead of guessing.

Exit codes: 0 = allowed (commitment written, or reference emitted)
            1 = REFUSED (nothing emitted; the reason is on stderr)
            2 = usage / environment error
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import os
import re
import subprocess
import sys

REC_RE = re.compile(
    r"^SEAL\s+label=(?P<label>\S+)\s+sha256=(?P<sha>[0-9a-f]{64})\s+"
    r"bytes=(?P<bytes>\d+)\s+at=(?P<at>\S+)\s*$"
)


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_record(text):
    """Return {label: (sha, nbytes, at)} for every well-formed SEAL line.

    Malformed lines are IGNORED rather than fatal: the record is append-only and
    a human may write prose around the machine lines. A label with two SEAL
    lines is a collision and is surfaced by the caller, never silently resolved
    to the first or the last."""
    out = {}
    dupes = set()
    for line in text.splitlines():
        m = REC_RE.match(line.strip())
        if not m:
            continue
        lab = m.group("label")
        if lab in out:
            dupes.add(lab)
        out[lab] = (m.group("sha"), int(m.group("bytes")), m.group("at"))
    return out, dupes


def git_show(repo, ref, path):
    """Read `path` as of `ref`. Returns (text, None) or (None, error-string)."""
    r = subprocess.run(["git", "-C", repo, "show", "%s:%s" % (ref, path)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None, r.stderr.strip()
    return r.stdout, None


def git_rev(repo, ref):
    r = subprocess.run(["git", "-C", repo, "rev-parse", ref],
                       capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def cmd_commit(args):
    if not os.path.isfile(args.verdicts):
        sys.stderr.write("sealgate: no such verdicts file: %s\n" % args.verdicts)
        return 2
    if os.path.getsize(args.verdicts) == 0:
        # An empty commitment is the void case: it would let any later file be
        # declared "what I meant all along" by simply never being compared.
        sys.stderr.write("sealgate: ⛔ REFUSED — verdicts file is EMPTY.\n")
        return 1

    existing_text = ""
    if os.path.isfile(args.record):
        with open(args.record) as fh:
            existing_text = fh.read()
    seen, dupes = parse_record(existing_text)
    if args.label in seen:
        sys.stderr.write(
            "sealgate: ⛔ REFUSED — label %r already has a commitment "
            "(sha256=%s, at=%s).\n" % (args.label, seen[args.label][0][:16],
                                       seen[args.label][2]))
        sys.stderr.write(
            "sealgate: there is no re-roll. Use a NEW label; the record keeps both.\n")
        return 1

    sha = sha256_of(args.verdicts)
    n = os.path.getsize(args.verdicts)
    at = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    line = "SEAL label=%s sha256=%s bytes=%d at=%s\n" % (args.label, sha, n, at)
    with open(args.record, "a") as fh:
        fh.write(line)
    sys.stdout.write(line)
    sys.stdout.write(
        "sealgate: ✅ commitment APPENDED to %s.\n"
        "sealgate: ⛔ IT IS NOT PUBLISHED YET. Commit and PUSH that record; "
        "`open` reads it from the remote, never from this disk.\n" % args.record)
    return 0


def cmd_open(args):
    if not os.path.isfile(args.verdicts):
        sys.stderr.write("sealgate: no such verdicts file: %s\n" % args.verdicts)
        return 2
    if not os.path.isfile(args.reference):
        sys.stderr.write("sealgate: no such reference: %s\n" % args.reference)
        return 2

    text, err = git_show(args.repo, args.published_at, args.record_path)
    if text is None:
        sys.stderr.write(
            "sealgate: ⛔ REFUSED — cannot read %s at %s: %s\n"
            % (args.record_path, args.published_at, err))
        sys.stderr.write(
            "sealgate: the reference was NOT opened. Push the record, then "
            "`git fetch`, then retry.\n")
        return 1

    seen, dupes = parse_record(text)
    ref_commit = git_rev(args.repo, args.published_at) or "<unknown>"
    if args.label in dupes:
        sys.stderr.write(
            "sealgate: ⛔ REFUSED — label %r has MORE THAN ONE commitment in the "
            "published record. A collision is a human question, not a tie to "
            "break.\n" % args.label)
        return 1
    if args.label not in seen:
        sys.stderr.write(
            "sealgate: ⛔ REFUSED — no published commitment for label %r.\n"
            % args.label)
        sys.stderr.write(
            "sealgate: %s is at %s. A remote-tracking ref is a LOCAL CACHE: this "
            "cannot tell 'never pushed' from 'pushed but not fetched'. Fetch, "
            "then retry.\n" % (args.published_at, ref_commit[:12]))
        return 1

    want_sha, want_n, at = seen[args.label]
    got_sha = sha256_of(args.verdicts)
    got_n = os.path.getsize(args.verdicts)
    if got_sha != want_sha:
        sys.stderr.write(
            "sealgate: ⛔ REFUSED — the verdicts file does not match the "
            "published commitment for %r.\n" % args.label)
        sys.stderr.write("sealgate:   published  sha256=%s bytes=%d at=%s\n"
                         % (want_sha, want_n, at))
        sys.stderr.write("sealgate:   on disk    sha256=%s bytes=%d\n"
                         % (got_sha, got_n))
        sys.stderr.write(
            "sealgate: the reference was NOT opened. Either restore the "
            "committed bytes, or commit the new ones under a NEW label and say "
            "on the record that you did.\n")
        return 1

    sys.stderr.write(
        "sealgate: ✅ ALLOWED — %r matches the record published at %s (%s), "
        "sha256=%s, committed %s.\n"
        % (args.label, args.published_at, ref_commit[:12], want_sha[:16], at))
    with open(args.reference) as fh:
        sys.stdout.write(fh.read())
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd")

    c = sub.add_parser("commit", help="hash the verdicts and append a commitment")
    c.add_argument("--verdicts", required=True)
    c.add_argument("--record", required=True)
    c.add_argument("--label", required=True)
    c.set_defaults(fn=cmd_commit)

    o = sub.add_parser("open", help="emit the reference IF the commitment is published and matches")
    o.add_argument("--verdicts", required=True)
    o.add_argument("--reference", required=True)
    o.add_argument("--repo", default=".", help="git repo holding the record")
    o.add_argument("--record-path", required=True,
                   help="path of the record INSIDE the repo, as git sees it")
    o.add_argument("--published-at", default="origin/master",
                   help="remote-tracking ref the record must already be visible at")
    o.add_argument("--label", required=True)
    o.set_defaults(fn=cmd_open)

    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()
    if not getattr(args, "fn", None):
        ap.print_help()
        return 2
    return args.fn(args)


# ═══ SELF-TEST ════════════════════════════════════════════════════════════════
# ⛔ IT DRIVES A REAL GIT REPO WITH A REAL REMOTE, not a mock. The whole claim of
#   this tool is about what is visible AT A REMOTE, and a mock of `git show` would
#   test my model of git rather than git. Every arm asserts on the REFERENCE
#   BYTES — the thing that must not leak — not merely on an exit code, because
#   the failure this tool exists to prevent is bytes reaching a reader while a
#   refusal prints beside them.

def self_test():
    import shutil
    import tempfile

    fails, ran = [], []

    def check(name, cond, detail=""):
        ran.append(name)
        if cond:
            print("  ✅ %s" % name)
        else:
            print("  ⛔ %s  %s" % (name, detail))
            fails.append(name)

    def run(argv):
        """Capture stdout/stderr/rc of a main() call."""
        import io
        import contextlib
        so, se = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(so), contextlib.redirect_stderr(se):
            rc = main(argv)
        return rc, so.getvalue(), se.getvalue()

    tmp = tempfile.mkdtemp(prefix="sealgate-selftest-")
    try:
        bare = os.path.join(tmp, "remote.git")
        work = os.path.join(tmp, "work")
        subprocess.run(["git", "init", "-q", "--bare", bare], check=True)
        subprocess.run(["git", "init", "-q", "-b", "master", work], check=True)
        subprocess.run(["git", "-C", work, "config", "user.email", "s@e.at"], check=True)
        subprocess.run(["git", "-C", work, "config", "user.name", "selftest"], check=True)
        subprocess.run(["git", "-C", work, "remote", "add", "origin", bare], check=True)

        rec_rel = "record.txt"
        rec = os.path.join(work, rec_rel)
        verdicts = os.path.join(work, "verdicts.txt")
        reference = os.path.join(tmp, "REFERENCE.txt")
        SECRET = "THE-REFERENCE-BYTES-THAT-MUST-NOT-LEAK\n"
        with open(reference, "w") as fh:
            fh.write(SECRET)
        with open(verdicts, "w") as fh:
            fh.write("row1 discussed\nrow2 decided\n")
        open(rec, "w").close()

        def push():
            subprocess.run(["git", "-C", work, "add", "-A"], check=True)
            subprocess.run(["git", "-C", work, "commit", "-q", "-m", "rec"], check=True)
            subprocess.run(["git", "-C", work, "push", "-q", "origin", "master"], check=True)
            subprocess.run(["git", "-C", work, "fetch", "-q", "origin"], check=True)

        def opencmd(label="L1"):
            return run(["open", "--verdicts", verdicts, "--reference", reference,
                        "--repo", work, "--record-path", rec_rel,
                        "--published-at", "origin/master", "--label", label])

        # 1 — BEFORE ANY COMMITMENT: refuse, and emit no reference bytes.
        #     (The record file does not exist at the remote at all yet.)
        rc, out, err = opencmd()
        check("no record at the remote: refuses", rc == 1, "rc=%d" % rc)
        check("no record at the remote: reference bytes NOT emitted", SECRET not in out)

        # 2 — commit locally, do NOT push. Still refuses: a commitment on disk is
        #     a note to yourself.
        rc, out, err = run(["commit", "--verdicts", verdicts, "--record", rec,
                            "--label", "L1"])
        check("commit writes a SEAL line", rc == 0 and "SEAL label=L1" in out, out.strip())
        push_pending = open(rec).read()
        check("commit says it is not published yet", "NOT PUBLISHED" in out)
        # the record exists on disk but the remote has no commit yet
        rc, out, err = opencmd()
        check("committed-but-unpushed: refuses", rc == 1, "rc=%d" % rc)
        check("committed-but-unpushed: reference bytes NOT emitted", SECRET not in out)

        # 3 — push, then open: ALLOWED, and the reference IS emitted. A gate that
        #     can only refuse is as useless as one that cannot.
        push()
        rc, out, err = opencmd()
        check("published + matching: ALLOWED", rc == 0, "rc=%d err=%s" % (rc, err.strip()))
        check("published + matching: reference bytes ARE emitted", SECRET in out)

        # 4 — MUTATE the verdicts after committing: refuse, no bytes. This is the
        #     defect the whole tool exists for.
        with open(verdicts, "a") as fh:
            fh.write("row3 decided\n")
        rc, out, err = opencmd()
        check("verdicts edited after the commitment: refuses", rc == 1, "rc=%d" % rc)
        check("verdicts edited after the commitment: NO reference bytes", SECRET not in out)
        check("the refusal prints BOTH hashes", "published" in err and "on disk" in err)

        # 5 — NO RE-ROLL: a second commitment under the same label is refused.
        rc, out, err = run(["commit", "--verdicts", verdicts, "--record", rec,
                            "--label", "L1"])
        check("re-roll under the same label: refused", rc == 1, "rc=%d" % rc)
        check("re-roll leaves the record byte-identical", open(rec).read() == push_pending)

        # 6 — a NEW label is the honest move, and it works end to end.
        rc, out, err = run(["commit", "--verdicts", verdicts, "--record", rec,
                            "--label", "L2"])
        check("new label accepted", rc == 0 and "label=L2" in out)
        push()
        rc, out, err = opencmd("L2")
        check("new label opens once published", rc == 0 and SECRET in out)
        check("the SUPERSEDED label still refuses the edited file", opencmd("L1")[0] == 1)

        # 7 — an EMPTY verdicts file is refused at commit time: an empty
        #     commitment is satisfiable by anything you write later.
        empty = os.path.join(work, "empty.txt")
        open(empty, "w").close()
        rc, out, err = run(["commit", "--verdicts", empty, "--record", rec,
                            "--label", "L3"])
        check("empty verdicts refused at commit", rc == 1 and "EMPTY" in err)

        # 8 — a DUPLICATE label in the PUBLISHED record is a human question, not
        #     a tie to break. (Hand-written, since `commit` refuses to make one.)
        with open(rec, "a") as fh:
            fh.write("SEAL label=L2 sha256=%s bytes=1 at=2026-01-01T00:00:00Z\n"
                     % ("0" * 64))
        push()
        rc, out, err = opencmd("L2")
        check("duplicate published label: refuses", rc == 1, "rc=%d" % rc)
        check("duplicate published label: NO reference bytes", SECRET not in out)

        # 9 — the parser ignores prose and malformed lines rather than choking.
        seen, dupes = parse_record(
            "some prose\nSEAL label=X sha256=%s bytes=3 at=T\nSEAL garbage\n" % ("a" * 64))
        check("parser reads the machine line past prose", list(seen) == ["X"], str(seen))
        check("parser ignores a malformed SEAL line", "garbage" not in str(seen))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if fails:
        print("sealgate --self-test: %d checks, %d FAILED: %s"
              % (len(ran), len(fails), ", ".join(fails)))
    else:
        print("sealgate --self-test: ALL GREEN (%d checks)" % len(ran))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Council 5b ruled the firewall line at PATHS. Nothing enforced it.

WHY THIS EXISTS
---------------
On 2026-08-25 at 10:49:22 the council ruled, in the Captain's words as minuted:
**paths into the private record are forbidden on public repos; bare filenames
are softened opportunistically; role-wording is the standard.** The minute also
recorded that the CI gate for it was "booked construction" — booked, not built.

Booked is not built, and the gap was measured rather than assumed. Of the 9
commits that landed on this repository at or after that stamp, **3 carried a
path-shaped string** — one of them 1 minute 41 seconds after the ruling, and one
of them written by the seat that then built this gate. Nothing anywhere tested
for it: the sibling gate in this directory scans commit messages and file
contents for a session trailer and a chat URL, and for nothing else.

That 3-of-9 rate is the justification. A rule obeyed by remembering is obeyed
for exactly as long as it is remembered, and the first lapse arrived inside two
minutes.

⭐ **AND THE FIRST CENSUS OF THAT RATE WAS RIGHT BY ARITHMETIC AND WRONG BY
MEMBERSHIP -- WHICH IS WORSE THAN BEING WRONG.** The hand census that justified
this gate scanned COMMIT MESSAGES ONLY and named three commits. This gate, run
over the same window with both arms and the ruled definition, also finds three
-- but not the same three. One named commit drops out (its absolute path points
into a PUBLIC tool, and the ruling forbade paths into the PRIVATE record, not
absolute paths generally). One unnamed commit enters, seven minutes after the
ruling, because it added a private path into a tracked FILE, which a
message-only census is structurally blind to.

TWO INDEPENDENT ERRORS CANCELLED INTO A MATCHING COUNT. Had the totals been
compared without the membership, the agreement would have read as
corroboration of a set that was one-third wrong. A count is not a scope, and
two counts agreeing is not two measurements agreeing.

WHAT COUNTS AS THE PRIVATE RECORD
---------------------------------
Not a guess — the fleet map is the authority, and these are the roots it names
as never-public: the seat repo (PRIVATE FOREVER), the employer-lane repos, the
two private project repos, the per-seat runtime config directories, the kit run
surface, and the fleet bus. They are assembled from parts below so that this
file's own source does not match its own patterns. That is not cleverness; a
detector whose documentation trips it is a shape this fleet has hit repeatedly,
and the sibling gate carries the same defence for the same reason.

**AND THIS FILE TRIPPED ITSELF ON ITS FIRST RUN, THREE TIMES.** The patterns
were assembled from parts, correctly -- but the PROSE explaining them spelled
two forbidden shapes out verbatim, as examples of what is forbidden. The
explanation of a rule is a carrier of the rule. Nothing here spells a forbidden
shape literally now; every example is assembled or described in words.

WHAT IS DELIBERATELY *NOT* FORBIDDEN
------------------------------------
* **A bare filename.** The ruling softens these explicitly. The bus file's bare
  name passes; the same name suffixed with a colon and a line number does not,
  because a line-anchored citation is a pointer INTO the private record's
  contents rather than a mention of its name. (Neither form is spelled out
  anywhere in this file, deliberately -- see the note on carriers below.) That
  reading is a judgement this gate makes visible rather than hides: it is a
  separate shape with its own label, so it can be struck on its own.
* **Role-wording**, which the ruling names as the standard: "the helm's brief",
  "another seat's bank", "the private record". This gate must never make the
  compliant form harder than the forbidden one.
* **Absolute paths into PUBLIC repos.** `/Users/x/projects/claude/saltworks/...`
  reveals machine layout, but the ruling forbade paths into the PRIVATE RECORD
  and said nothing about this. Measured here at the time of writing: 33 tracked
  files and 78 occurrences carry that shape. Sweeping them in would be quietly
  extending an instrument past its ruling — the exact move the same council's
  law harvest condemned ("declare an instrument's blind spot, never quietly
  extend it"). DECLARED, therefore, and left alone.

THE FRAME THIS INSTRUMENT MEASURES (it travels; it must say)
------------------------------------------------------------
This file is byte-identical in salt, saltworks and jas. Every number in it was
measured in **saltworks**, the repo where it was written, on 2026-08-25. A
travelling tool that quotes one repo's anchor as if it were universal is a
shape this fleet has already paid for, so the other two were measured at the
same hour and are recorded here rather than assumed:

    repo        commits   tracked   full-history findings (message arm)
    saltworks      2127       847   14
    salt           2142      1425    0   <- clean history; the delta rule still
                                          applies, so it stays clean
    jas            3191      2114    5   <- all genuine, all one shape: a path
                                          into the commons repo, in a message

None of the three contains a directory whose top-level name collides with a
private-record root, checked in all three before this shipped -- a repo that
did would red on every ordinary reference to its own tree.

WHY THE SCAN IS A DELTA, NOT ALL OF HISTORY
-------------------------------------------
Measured before this gate was written, over 2127 commits and 847 tracked files:
history already carries ~15 commits and ~50 files with these shapes, all of them
predating the ruling and protected by the commencement clause (no ex post
facto). A full-history scan would therefore be permanently red, which is the
red-sweep-gets-abandoned failure the sibling workflow's own header documents and
solves the same way. The enforceable content of the ruling is **"no NEW path
into the private record enters a public repo"**, so that is what this scans:
the pushed delta's commit messages, and the delta's added/modified file lines.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys

# ---------------------------------------------------------------------------
# THE PRIVATE-RECORD ROOTS. Assembled from parts so this file's own prose above
# never matches the patterns below. Verified by the self-test, which would
# otherwise pass vacuously by excluding the one file that matters.
# ---------------------------------------------------------------------------
_SEAT = "se" + "at"                    # the commons/memory-mirror repo
_EMPLOYER = ["lo" + "ca", "ho" + "ll", "pcc-" + "bios"]
_PRIVATE_PROJ = ["si" + "la", "mor" + "pho"]
_CFGDIR = r"\.claude-" + _SEAT + r"-[A-Za-z0-9_-]+"
_KIT_RE = "Documents" + r"[/" + chr(92)*2 + r"]+" + _SEAT   # separator-agnostic
_KIT = "Documents/" + _SEAT                                      # display form only
_BUS = "FLEET" + r"\.md"

_ROOTS = [_SEAT] + _EMPLOYER + _PRIVATE_PROJ
_ROOT_ALT = "|".join(_ROOTS)

# A path REACHES INTO a root when the root name is followed by a separator and
# at least one more component. A bare root name in prose is not a path; the root
# plus a separator plus a component is.
#
# ⛔ THE LEFT GUARD EXCLUDES WORD CHARACTERS ONLY, AND THAT IS THE WHOLE POINT.
# The first draft also excluded `/` and `.`, to stop a root name appearing mid
# path. It did stop that -- and it stopped the ABSOLUTE form too, because an
# absolute path into the private record has a `/` immediately before the root.
# That is the single case this gate most exists for, and the first draft was
# structurally blind to it. Caught by the self-test's real-instance fixture,
# not by reading. Plural and suffixed forms are excluded by the RIGHT side
# instead: a public clone path has another letter after the root, never a
# separator, so it cannot match.
# ⛔ SEPARATOR CLASS, NOT A LITERAL SLASH -- ADDED AFTER A MEASUREMENT, 08/25.
# The first shipped version required a forward slash. Driven against six path
# shapes, FOUR WERE BLIND: a backslash-separated path, a half-normalised mixed
# path, a UNC double-backslash form, and a drive-letter absolute path. This
# fleet has a Windows seat, so those are authored shapes, not exotica.
#
# ⚠️ AND THE FIX IS IN THE PATTERN, NOT IN THE CI MATRIX. Wiring this gate onto
# a Windows runner does NOT make it see a backslash: both arms read git OBJECT
# bytes (measured -- no CR in either arm's output, and diff path headers are
# forward-slash on every platform), so the same regex over the same objects
# returns the same verdict wherever it executes. A lane changes WHERE a gate
# runs; only the pattern changes WHAT it can match.
_SEP = r"[/\\]+"
_INTO = rf"(?<![A-Za-z0-9_-])(?:{_ROOT_ALT}){_SEP}[A-Za-z0-9_.-]+"

FORBIDDEN = [
    (re.compile(_INTO),
     "a path into a private-record repo"),
    (re.compile(_CFGDIR),
     "a per-" + _SEAT + " runtime config directory"),
    (re.compile(rf"(?<![A-Za-z0-9_-]){_KIT_RE}(?:{_SEP}|\b)"),
     "the kit run surface"),
    (re.compile(rf"{_BUS}:\d+"),
     "a line-anchored citation into the fleet bus"),
]

# Named so a future reader does not "tidy" these into the forbidden list.
PRESERVED = [
    "a bare bus filename (the ruling softens bare filenames)",
    "role-wording: the helm's brief, another " + _SEAT + "'s bank",
    "absolute paths into PUBLIC repos (declared out of scope, not overlooked)",
]


def commit_messages(rev_range: str) -> list[tuple[str, str]]:
    """(sha, message) for every commit in `rev_range`, newest first."""
    sep = "@@PATHCOMMIT@@"
    out = subprocess.run(
        ["git", "log", f"--format=%H%x1f%B{sep}", rev_range],
        capture_output=True, text=True, encoding="utf-8", check=True,
    ).stdout
    rows = []
    for chunk in out.split(sep):
        chunk = chunk.strip("\n")
        if not chunk:
            continue
        sha, _, body = chunk.partition("\x1f")
        rows.append((sha.strip(), body))
    return rows


def range_is_two_dot(rev_range: str) -> bool:
    """`git log HEAD` means every commit; `git diff HEAD` means the WORKING TREE.

    THE SAME ARGUMENT NAMES TWO DIFFERENT THINGS TO THE TWO COMMANDS THIS GATE
    RUNS, and the divergence is silent. Caught while porting: run against a
    clean clone with `--range HEAD`, the message arm scanned 2142 commits and
    the file arm scanned NOTHING -- and the summary line printed
    "0 added lines scanned", which reads as a clean measurement of a real scan.

    A zero that means "I could not look" and a zero that means "nothing was
    there" are the same number. So the file arm now declares which it is.
    """
    return ".." in rev_range


def added_lines(rev_range: str) -> list[tuple[str, str]]:
    """(path:line-ish, added text) for lines this delta ADDS to tracked files.

    WHY ADDED LINES AND NOT WHOLE FILES. The sibling trailer gate scans whole
    tracked files, and can, because its forbidden population is zero. This
    one's is not: ~50 files already carry these shapes from before the ruling.
    Scanning whole files would red on a file somebody merely touched, which
    punishes the wrong commit and teaches the gate is noise. A delta scan
    charges each commit for what it ADDS.

    A deletion is never a finding: removing a forbidden path is the repair.
    """
    out = subprocess.run(
        ["git", "diff", "--unified=0", "--no-color", rev_range],
        capture_output=True, text=True, encoding="utf-8", check=True,
    ).stdout
    rows: list[tuple[str, str]] = []
    path = "?"
    for line in out.splitlines():
        if line.startswith("+++ b/"):
            path = line[6:]
        elif line.startswith("+") and not line.startswith("+++"):
            rows.append((path, line[1:]))
    return rows


def scan(rows: list[tuple[str, str]]) -> list[tuple[str, str, str]]:
    """(id, what, line) for every violation found."""
    bad = []
    for ident, body in rows:
        for pattern, what in FORBIDDEN:
            m = pattern.search(body)
            if m:
                line = next((l for l in body.splitlines() if m.group(0) in l),
                            m.group(0))
                bad.append((ident, what, line.strip()))
    return bad


def _is_empty_scan_fatal(rows) -> bool:
    """The fail-closed rule, as a function so the self-test can prove it."""
    return len(rows) == 0


def is_shallow() -> bool:
    out = subprocess.run(["git", "rev-parse", "--is-shallow-repository"],
                         capture_output=True, text=True, encoding="utf-8")
    return out.stdout.strip() == "true"


def self_test() -> int:
    """BOTH ARMS DRIVEN BEFORE TRUST. A planted path must FAIL; a role-worded
    message must PASS. The fixtures are the three real instances that were
    measured in this repository after the ruling — not invented shapes."""
    failures = []

    # 1. THE EMPTY SET, FIRST. A scan with nothing in it must not read as clean.
    if scan([]) != []:
        failures.append("scan([]) should find nothing to report")
    if not _is_empty_scan_fatal([]):
        failures.append("an empty scan must be FATAL, not green")

    # 2. ARM ONE — THE REAL INSTANCES. These three are verbatim fragments of
    #    commit messages that actually landed here after the ruling stamp.
    real = [
        # message arm -- the gate author's own commit, 3h26m after the ruling
        ("4787935", "AND 0 inside every .pdf in " + _SEAT + "/papers -- the control word"),
        # message arm -- 1 minute 41 seconds after the ruling
        ("5466ad9", "citations verified against " + _SEAT + "/briefs/kit-revision-0813.md"),
        # FILE arm -- 7 minutes after the ruling, and INVISIBLE to a
        # message-only census. This fixture exists because the hand census
        # missed it and the gate did not.
        ("ee5a84a", "the council ruled this sitting (`" + _SEAT
                    + "/briefs/2026-08-19-maestro-night-bank.md:1288`)"),
        # historical, kept as the only specimen of the kit-surface shape
        ("c9d3b50", "the kit copy at ~/" + _KIT + "/bus_watch.sh"),
    ]
    for ident, text in real:
        if not scan([(ident, text)]):
            failures.append(f"real instance {ident} must be caught")
    # Count DISTINCT ROWS caught, never findings: one string can legitimately
    # match two shapes (an absolute kit path is also a path into a private repo),
    # and a findings-count assertion would fail on a correct gate.
    if len({b[0] for b in scan(real)}) != len(real):
        failures.append(f"all {len(real)} real instances, got "
                        f"{len({b[0] for b in scan(real)})}")

    # 3. ARM ONE, continued — one planted specimen per remaining shape.
    planted = [
        ("p-emp", "see " + _EMPLOYER[0] + "/notes/x.md"),
        ("p-priv", "see " + _PRIVATE_PROJ[1] + "/design/y.md"),
        ("p-cfg", "config lives in ~/.claude-" + _SEAT + "-evidence/settings.json"),
        ("p-bus", "as minuted at " + _BUS.replace(chr(92), "") + ":171311"),
        # THE FOUR SHAPES THAT WERE BLIND UNTIL 08/25. Assembled, never spelled.
        ("p-bslash", "see " + _SEAT + chr(92) + "briefs" + chr(92) + "x.md"),
        ("p-mixed", "see " + _SEAT + chr(92) + "briefs/x.md"),
        ("p-unc", "see " + chr(92)*2 + "host" + chr(92) + _SEAT + chr(92) + "briefs"),
        ("p-drive", "see C:" + chr(92) + "Users" + chr(92) + "j" + chr(92)
                    + _SEAT + chr(92) + "briefs" + chr(92) + "x.md"),
        # CRLF was already caught; kept as a control so a future edit cannot
        # silently lose it.
        ("p-crlf", "see " + _SEAT + "/briefs/x.md" + chr(13)),
    ]
    for ident, text in planted:
        if not scan([(ident, text)]):
            failures.append(f"planted shape {ident} must be caught")

    # 4. ARM TWO — THE COMPLIANT FORMS MUST PASS. A gate that reds the ruled
    #    standard is worse than no gate: it teaches people to route around it.
    clean = [
        ("c-role", "as the helm minuted in its own brief, and the maestro ruled"),
        ("c-role2", "another " + _SEAT + "'s bank carries the superseded value"),
        ("c-bare", "the bus (FLEET.md) is unversioned and outside every git tree"),
        ("c-pub", "docs/QUEUE.md and SaltWorks/Silicon/TT/info.yaml both changed"),
        ("c-pubabs", "/Users/x/projects/claude/saltworks/docs/QUEUE.md is public"),
        ("c-clone", "the clone at " + _SEAT + "s/evidence/saltworks is a PUBLIC path"),
        ("c-word", "the evidence " + _SEAT + " and the silicon " + _SEAT + " agree"),
        ("c-winpub", "C:" + chr(92) + "src" + chr(92) + "saltworks" + chr(92) + "docs"),
        ("c-plural-bs", "the clone at " + _SEAT + "s" + chr(92) + "evidence"),
        ("c-meta", "this gate forbids paths into the private record"),
    ]
    for ident, text in clean:
        got = scan([(ident, text)])
        if got:
            failures.append(f"compliant form {ident} must PASS, got {got[0][1]}")

    # 5. THE ARM-COVERAGE DECLARATION. A range the file arm cannot scan must be
    #    reported as a gap, never silently as a zero.
    if range_is_two_dot("HEAD"):
        failures.append("'HEAD' must be recognised as NOT a two-dot range")
    if not range_is_two_dot("abc..HEAD"):
        failures.append("'abc..HEAD' must be recognised as a two-dot range")

    # 6. THIS FILE'S OWN SOURCE must not match. A detector that trips on its own
    #    documentation cannot be committed, and this fleet has shipped that.
    try:
        with open(__file__, encoding="utf-8") as fh:
            own = fh.read()
        hits = scan([("SELF", own)])
        if hits:
            failures.append(f"this file's own source trips the gate: {hits[0][1]}")
    except OSError:
        failures.append("could not read own source for the self-match check")

    for f in failures:
        print(f"SELF-TEST FAIL: {f}")
    if failures:
        return 1
    print(f"check_private_paths SELF-TEST: OK (empty scan fatal proven FIRST; "
          f"{len(real)} real post-ruling instances caught; {len(planted)} planted "
          f"shapes caught; {len(clean)} compliant forms passed; own source clean)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="council 5b firewall gate")
    ap.add_argument("--range", default=None,
                    help="git revision range to scan (messages + added lines)")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    if args.range is None:
        print("FAIL: --range is required. This gate scans a DELTA by design; "
              "see the module docstring for why a full-history scan is red.")
        return 1

    if is_shallow():
        print("FAIL: this is a SHALLOW clone. A delta gate on a one-commit "
              "checkout scans one commit and reports success.\n"
              "      CI must check out with `fetch-depth: 0` for this job.")
        return 1

    file_arm = range_is_two_dot(args.range)
    try:
        msgs = commit_messages(args.range)
        lines = added_lines(args.range) if file_arm else []
    except subprocess.CalledProcessError as e:
        print(f"FAIL: could not read '{args.range}': {e}")
        return 1

    # FAIL CLOSED: nothing scanned is not the same as nothing wrong. A push that
    # genuinely adds no commit does not reach this gate at all.
    if _is_empty_scan_fatal(msgs):
        print(f"FAIL: scanned ZERO commits for '{args.range}'. An empty scan is "
              f"not a clean scan — this gate refuses to report success on it.")
        return 1

    bad = scan(msgs) + scan(lines)
    if bad:
        print(f"FAIL: {len(bad)} private-record path(s) entering a PUBLIC repo.\n")
        print("Council 2026-08-25 ruled the firewall line at PATHS: paths into")
        print("the private record are forbidden on public repos. Bare filenames")
        print("are softened; role-wording is the standard. Rewrite the reference")
        print("as a ROLE ('the helm's brief') or a bare filename, not a path.\n")
        for ident, what, line in bad:
            print(f"  {ident[:40]}  {what}")
            print(f"      {line[:110]}")
        print("\nA commit message already pushed cannot be edited without a")
        print("force-push; fix it BEFORE the push, which is why this runs here.")
        return 1

    if file_arm:
        arm2 = f"{len(lines)} added lines scanned"
    else:
        arm2 = ("FILE ARM NOT RUN -- '" + args.range + "' is not a two-dot "
                "range, so `git diff` would compare the working tree, not the "
                "delta. This is a DECLARED GAP, not a clean result")
    print(f"check_private_paths: OK ({len(msgs)} commit messages scanned and "
          f"{arm2}, for '{args.range}'; 0 paths into the private record). "
          f"Not scanned, by ruling: {'; '.join(PRESERVED)}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

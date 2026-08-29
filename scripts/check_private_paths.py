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
This file is byte-identical in salt, saltworks and jas. Every number below was
measured by this gate, and each row NAMES ITS REF.

⛔ THE FIRST VERSION OF THIS BLOCK SAID "salt · 2142 commits · 0 findings" AND
THAT WAS MEASURED ON THE DEFAULT BRANCH ALONE. A long-lived branch of the same
repo carried ELEVEN. I NAMED A REPO WHERE I HAD MEASURED A REF -- not false,
but under-scoped, which is worse: it reads as a repo-level clean bill, and it
was quoted as a frame disclosure for four hours. A REPO DOES NOT HAVE A FINDING
COUNT; A REF DOES.

    ref                        commits  tracked  message-arm findings
    saltworks  master             2138      850  14
    salt       main               2145     1426   0
    salt       math/w1-e3-port    2579     1463   0   <- was 11; a Captain-ruled
                                                         purge cleared them
    jas        main               3192     2115   5   <- genuine, all one shape,
                                                         all predating the ruling

These are SNAPSHOTS taken 2026-08-25, not properties. A branch that forked
before this gate landed has never been scanned end to end; if you own a
long-lived branch, one full-range run is cheap and yours to own.

No repo contains a directory whose top-level name collides with a private-record
root, checked in all three before this shipped -- a repo that did would red on
every ordinary reference to its own tree.

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
import os
import hashlib
import pathlib
import re
import subprocess
import sys

def self_id() -> str:
    """This file's own content hash, printed in every verdict.

    WHY. A ruling made this gate's verdict a required receipt, and the criterion
    was "the MECHANISM'S verdict". Four copies of it existed across two repos and
    two refs at that moment; had any differed, the receipt would have named four
    objects and nobody would have noticed. I checked them by hand and they
    matched -- but a receipt whose instrument must be identified BY HAND is one
    unverified step from meaningless.

    AN INSTRUMENT THAT DOES NOT NAME ITSELF MAKES EVERY RECEIPT ABOUT IT
    UNFALSIFIABLE. Now every line this tool prints carries the bytes that printed
    it, and a reader can reproduce or refute the number without trusting the run.
    """
    try:
        return hashlib.sha256(
            pathlib.Path(__file__).read_bytes()).hexdigest()[:16]
    except OSError:
        return "unreadable"


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

# ⛔ THE DURABLE LOCAL TIER (born 2026-08-25) IS A PRIVATE ROOT WHOSE NAME IS AN
# ORDINARY WORD, so it CANNOT join _ROOTS. Measured before deciding: a bare
# root of that name matches EIGHT existing occurrences in one sibling repo --
# every one of them the standard system prefix under a slash, in a CI workflow
# and two docs. Adding it unqualified would red that repo on ordinary content,
# which is how a gate earns the reputation that gets it deleted.
#
# So it is matched ONLY in the two forms that actually identify the private
# tier rather than any directory of that name: prefixed by the fleet parent, or
# as a bare-repository name. Both assembled from parts.
# DECLARED CONSEQUENCE: an unqualified reference to a directory of that name is
# NOT caught. That is a real hole, chosen with its measurement in hand.
_LOCALWORD = "lo" + "cal"
_BS = chr(92)
_SEPCLASS = "[/" + _BS + _BS + "]+"
_FLEETPARENT = "projects" + _SEPCLASS + "claude"
_LOCAL_QUALIFIED = (_FLEETPARENT + _SEPCLASS + _LOCALWORD
                    + "(?:[/" + _BS + _BS + "]|" + _BS + "b)")
_LOCAL_BAREREPO = _LOCALWORD + _BS + ".git"
# The backup volume that holds it is itself a private-record location.
_BACKUPVOL = ("Volumes" + _SEPCLASS + "Content[ _]HD" + _SEPCLASS
              + "Salt" + "works")

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
    (re.compile(_LOCAL_QUALIFIED),
     "a path into the durable local tier"),
    (re.compile(_LOCAL_BAREREPO),
     "the durable local tier's bare repository"),
    (re.compile(_BACKUPVOL),
     "the backup volume holding the private record"),
]

# Named so a future reader does not "tidy" these into the forbidden list.
PRESERVED = [
    "a bare bus filename (the ruling softens bare filenames)",
    "role-wording: the helm's brief, another " + _SEAT + "'s bank",
    "absolute paths into PUBLIC repos (declared out of scope, not overlooked)",
]


# ---------------------------------------------------------------------------
# THE PRESERVED-RECORD EXEMPTION — Captain's ruling, 2026-08-25 21:1x.
#
# Five sites on one long-lived branch cite the private record and are PRESERVED
# BY RULING: they are records of observations, and a record of an observation
# must not change. The purge that cleared that branch's commit messages was
# message-only and correctly did not touch them.
#
# ⛔ WHAT WAS GRANTED IS NOT A MUTE. The ruling's words: green while each is
# preserved EXACTLY, RED THE MOMENT ONE DRIFTS -- "an exemption that just mutes
# them is not what was granted". So each site is pinned by the SHA-256 of its
# exact line, and drift-sensitivity falls out in both directions:
#
#   line EDITED   -> the new text hashes differently -> matches no pin
#                    -> it is an ORDINARY FINDING and the gate REDS. Automatic.
#   line GONE     -> the pin stops resolving at its ref -> the PIN AUDIT REDS.
#                    A delta scan alone is blind to this; that is why the audit
#                    exists as a second arm rather than a nicety.
#
# ⚠️ SCOPED BY REPO **AND** REF, and that is not caution -- it is measured. This
# file ships byte-identical to three public repos, and `docs/QUEUE.md` EXISTS IN
# TWO OF THEM AS COMPLETELY DIFFERENT FILES. A path-scoped exemption would mute
# a finding in the wrong repository, which is the adjacent-object trap wearing a
# ruling's authority. An exemption is granted for SITES, never for STRINGS.
EXEMPT = [
    {"repo": "salt", "ref": "math/w1-e3-port",
     "file": "docs/QUEUE.md",
     "sha": "3953079dbac0d60e"},
    {"repo": "salt", "ref": "math/w1-e3-port",
     "file": "docs/QUEUE.md",
     "sha": "8cf038855c616f6b"},
    {"repo": "salt", "ref": "math/w1-e3-port",
     "file": "docs/blueprints/arc.md",
     "sha": "429bb871b876cbe4"},
    {"repo": "salt", "ref": "math/w1-e3-port",
     "file": "docs/exploration/wf3-waveb-design.md",
     "sha": "4a6445edfc087eab"},
    {"repo": "salt", "ref": "math/w1-e3-port",
     "file": "docs/exploration/wf3-waveb-design.md",
     "sha": "dace3b578b8b23f8"},
]


def repo_slug() -> str:
    """This repo's name from its origin URL. EXACT match, never a substring --
    two of the three repos this file ships to differ by a suffix."""
    out = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                         capture_output=True, text=True, encoding="utf-8")
    url = out.stdout.strip()
    if not url:
        return ""
    return url.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git")


def active_exemptions() -> list:
    """Only the pins granted for THIS repo. Elsewhere the list is empty and the
    gate behaves as though no exemption exists -- which is correct: the ruling
    exempted five sites in one repository, not five strings everywhere."""
    slug = repo_slug()
    return [e for e in EXEMPT if e["repo"] == slug]


def line_sha(text: str) -> str:
    return hashlib.sha256(text.strip().encode("utf-8")).hexdigest()[:16]


def partition(findings, exempt):
    """Split findings into (violations, exempted) by BYTE-EXACT line hash.

    A finding is exempted only when its file AND the sha of its exact line both
    match a pin. One changed character produces a different sha and the finding
    survives as a violation -- which is the whole mechanism, not a side effect.
    """
    pins = {(e["file"], e["sha"]) for e in exempt}
    viol, exm = [], []
    for f in findings:
        ident, what, line = f
        (exm if (ident, line_sha(line)) in pins else viol).append(f)
    return viol, exm


def audit_pins(exempt, ref="HEAD"):
    """(intact, drifted, unresolvable) -- does each pin still match at its ref?

    THE ARM A DELTA SCAN CANNOT HAVE. If a preserved line is deleted or edited,
    a delta of the same push may show nothing at all; the pin stops resolving,
    and only a look at the tree can say so. A pin whose ref is not present in
    this checkout is UNRESOLVABLE, never 'intact' -- reported, never assumed.
    """
    intact, drifted, unresolvable = [], [], []
    for e in exempt:
        # ⛔ THE REF AND THE FILE ARE SEPARATE QUESTIONS, AND CONFLATING THEM
        # FAILS OPEN. First draft treated "git show ref:file failed" as
        # UNRESOLVABLE, which is right when the REF is absent (this checkout
        # simply does not have that branch) and WRONG when the ref is present
        # and the FILE was deleted -- that is the preserved record being
        # destroyed, reported as "not applicable". Found by driving the arm.
        ref = None
        for cand in (e["ref"], f'origin/{e["ref"]}'):
            if subprocess.run(["git", "rev-parse", "--verify", "--quiet", cand],
                              capture_output=True).returncode == 0:
                ref = cand
                break
        if ref is None:
            unresolvable.append(e)          # the branch is not in this checkout
            continue
        blob = subprocess.run(["git", "show", f'{ref}:{e["file"]}'],
                              capture_output=True, text=True, encoding="utf-8")
        if blob.returncode != 0:
            drifted.append(e)               # ref IS here and the FILE is gone
            continue
        if any(line_sha(l) == e["sha"] for l in blob.stdout.splitlines()):
            intact.append(e)
        else:
            drifted.append(e)
    return intact, drifted, unresolvable


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
        # THE DURABLE LOCAL TIER (root born 08/25). Only the QUALIFIED forms;
        # the bare word is the declared hole and is controlled for below.
        ("l-qual", "see projects/claude/" + _LOCALWORD + "/x.md"),
        ("l-qual-bs", "see projects" + chr(92) + "claude" + chr(92)
                      + _LOCALWORD + chr(92) + "x.md"),
        ("l-repo", "the bare repo " + _LOCALWORD + ".git"),
        ("l-vol", "/Volumes/Content HD/" + "Salt" + "works/archives"),
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
        # THE DECLARED HOLE, KEPT AS A CONTROL: the ordinary word must never
        # fire, or one sibling repo reds on eight pre-existing occurrences.
        ("c-usr", "installed to /usr/" + _LOCALWORD + "/bin"),
        ("c-usrlib", "on the path /usr/" + _LOCALWORD + "/lib/python3.12"),
        ("c-localprose", _LOCALWORD + "/remote divergence was the cause"),
        ("c-meta", "this gate forbids paths into the private record"),
    ]
    for ident, text in clean:
        got = scan([(ident, text)])
        if got:
            failures.append(f"compliant form {ident} must PASS, got {got[0][1]}")

    # 4c. THE PRESERVED-RECORD EXEMPTION. Byte-exactness is the whole grant,
    #     so the arm that matters is the ONE-CHARACTER change.
    if len(EXEMPT) != 5:
        failures.append(f"expected 5 pins, found {len(EXEMPT)}")
    # A line that hashes to a REAL pin cannot be constructed here, so the arms
    # are driven on a SYNTHETIC pin over a line this test controls. The real
    # pins are driven against the live branch separately, and that receipt is
    # in the commit message.
    S = "se" + "at"
    site = "see " + S + "/briefs/preserved-record-fixture.md for the verdict"
    fake = [{"repo": repo_slug() or "x", "ref": "r", "file": "docs/F.md",
             "sha": line_sha(site)}]
    found = scan([("docs/F.md", site)])
    if not found:
        failures.append("the exemption fixture must be a finding before it is exempt")
    viol, exm = partition(found, fake)
    if viol or len(exm) != 1:
        failures.append(f"an exact-match site must be EXEMPTED, got {len(viol)} viol")
    # ...and ONE CHARACTER of drift must survive as a violation.
    drift = scan([("docs/F.md", site + ".")])
    viol2, exm2 = partition(drift, fake)
    if exm2 or len(viol2) != 1:
        failures.append("a one-character drift must NOT be exempted")
    # ...and the SAME line in a DIFFERENT file must not be exempted.
    other = scan([("docs/OTHER.md", site)])
    viol3, exm3 = partition(other, fake)
    if exm3 or len(viol3) != 1:
        failures.append("an exemption is per-SITE, not per-STRING")
    # ...and with no active exemptions, nothing is muted.
    viol4, exm4 = partition(found, [])
    if exm4 or len(viol4) != 1:
        failures.append("with no active exemptions nothing may be exempted")

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
    print(f"check_private_paths SELF-TEST [gate {self_id()}]: OK "
          f"(empty scan fatal proven FIRST; "
          f"{len(real)} real post-ruling instances caught; {len(planted)} planted "
          f"shapes caught; {len(clean)} compliant forms passed; own source clean)")
    return 0


# ---------------------------------------------------------------------------
# THE TREE RATCHET — added 2026-08-29 by the helm on the council's row m.
#
# WHY A SECOND ARM. The delta gate fired on FIVE consecutive pushes for one file
# (08/29 00:19-01:16 UTC) and nobody repaired it; the sixth push touched other
# files, its delta was clean, and the run went GREEN with the violation still
# in the tree. A delta gate charges the commit that ADDS a path; it cannot
# charge the tree for KEEPING one. That is the stale-known-hole shape: a fired
# gate that is not acted on is laundered by the next green.
#
# WHY NOT A WHOLE-TREE GATE. The tree carried 67 findings in 27 files on the
# day this was written, most of them line-anchored bus citations in 08/13-08/16
# ledgers that are RECORDS and were never in the ruling's scope to rewrite. A
# gate that reds on all of them would be routed around inside a day.
#
# SO: A RATCHET. `private_paths_baseline.tsv` lists the ACCEPTED residue as
# (file, line-sha16). `--tree` scans every tracked text file and REDS on any
# finding NOT in the baseline -- new residue, or residue that moved (a moved
# line hashes the same but its file changed; an edited line hashes anew).
# Baseline entries no longer present are reported as debt paid, never as a
# failure. The baseline shrinks by `--write-baseline` after a real repair; it
# grows only by the same explicit act, which is a reviewed diff, not a silent
# pass. The gate's own source is excluded (it assembles the shapes from parts
# and is self-tested for that separately).
# ---------------------------------------------------------------------------
BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "private_paths_baseline.tsv")


def tree_rows(exclude_self: bool = True) -> list[tuple[str, str]]:
    """(path, line) for every line of every tracked text file."""
    out = subprocess.run(["git", "ls-files", "-z"], capture_output=True,
                         check=True).stdout.decode("utf-8", "replace")
    rows: list[tuple[str, str]] = []
    own = os.path.relpath(os.path.abspath(__file__), os.getcwd())
    for path in out.split("\0"):
        if not path or (exclude_self and path == own):
            continue
        try:
            with open(path, "rb") as fh:
                blob = fh.read()
        except (IsADirectoryError, FileNotFoundError):
            continue
        if b"\0" in blob[:8192]:
            continue  # binary
        for line in blob.decode("utf-8", "replace").splitlines():
            rows.append((path, line))
    return rows


def load_baseline() -> set[tuple[str, str]]:
    try:
        with open(BASELINE, encoding="utf-8") as fh:
            return {tuple(l.rstrip("\n").split("\t")[:2])
                    for l in fh if l.strip() and not l.startswith("#")}
    except FileNotFoundError:
        return set()


def tree_findings() -> list[tuple[str, str, str]]:
    return scan(tree_rows())


def tree_mode(write: bool) -> int:
    found = tree_findings()
    keys = {(f, line_sha(line)) for f, _, line in found}
    if write:
        with open(BASELINE, "w", encoding="utf-8") as fh:
            fh.write("# private_paths_baseline.tsv -- ACCEPTED residue for the tree ratchet "
                     "(check_private_paths.py --tree).\n# file<TAB>line-sha16<TAB>what. "
                     "Shrink it after a repair with --tree --write-baseline; a growth is a "
                     "reviewed diff.\n")
            for f, what, line in sorted(found):
                fh.write(f"{f}\t{line_sha(line)}\t{what}\n")
        print(f"check_private_paths --write-baseline: {len(found)} accepted residue "
              f"line(s) in {len({f for f,_,_ in found})} file(s) written to {os.path.basename(BASELINE)}")
        return 0
    base = load_baseline()
    if not base and found:
        print(f"FAIL [gate {self_id()}]: --tree has NO BASELINE and the tree carries "
              f"{len(found)} finding(s). Write one deliberately with --tree --write-baseline.")
        return 1
    new = [f for f in found if (f[0], line_sha(f[2])) not in base]
    paid = base - keys
    if new:
        print(f"FAIL [gate {self_id()}] TREE RATCHET: {len(new)} private-record path(s) "
              f"in the tree that the baseline does not accept.\n")
        print("A delta gate fired on these (or would have) and the tree still carries")
        print("them. Rewrite as ROLE wording or a bare filename; do not add to the")
        print("baseline unless the council preserved the site.\n")
        for f, what, line in new:
            print(f"  {f}  {what}")
            print(f"      {line[:110]}")
        return 1
    print(f"check_private_paths --tree [gate {self_id()}]: OK ({len(found)} accepted residue "
          f"line(s) in {len({f for f,_,_ in found})} file(s), all in the baseline; "
          f"{len(paid)} baseline entr{'y' if len(paid)==1 else 'ies'} no longer present"
          + (" -- debt paid; shrink the baseline with --tree --write-baseline" if paid else "")
          + "). 0 NEW residue.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="council 5b firewall gate")
    ap.add_argument("--range", default=None,
                    help="git revision range to scan (messages + added lines)")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--tree", action="store_true",
                    help="ratchet: whole-tree residue vs the committed baseline")
    ap.add_argument("--write-baseline", action="store_true",
                    help="with --tree: (re)write the accepted-residue baseline")
    args = ap.parse_args()

    if args.tree:
        return tree_mode(args.write_baseline)

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

    exempt = active_exemptions()
    bad, exempted = partition(scan(msgs) + scan(lines), exempt)

    # THE PIN AUDIT — the arm a delta scan cannot have. Run before the verdict,
    # because a drifted pin is a failure even on a push that touches nothing.
    intact, drifted, unresolvable = audit_pins(exempt, args.range.split("..")[-1])
    if drifted:
        print(f"FAIL [gate {self_id()}]: {len(drifted)} PRESERVED-RECORD PIN(S) "
              f"HAVE DRIFTED.\n")
        print("The 2026-08-25 ruling preserved these sites EXACTLY. A pin that no")
        print("longer matches means the preserved record changed -- which the")
        print("exemption does not cover and was never intended to hide.\n")
        for e in drifted:
            print(f'  {e["file"]}  @{e["ref"]}  pin {e["sha"]} no longer matches')
        print("\nEither restore the line byte-for-byte, or take a new ruling.")
        return 1

    if bad:
        print(f"FAIL [gate {self_id()}]: {len(bad)} private-record path(s) "
              f"entering a PUBLIC repo.\n")
        print("Council 2026-08-25 ruled the firewall line at PATHS: paths into")
        print("the private record are forbidden on public repos. Bare filenames")
        print("are softened; role-wording is the standard. Rewrite the reference")
        print("as a ROLE ('the helm's brief') or a bare filename, not a path.\n")
        for ident, what, line in bad:
            print(f"  {ident[:40]}  {what}")
            print(f"      {line[:110]}")
        print("\nIF YOU ARE DEMONSTRATING A FORBIDDEN FORM rather than citing one:")
        print("assemble it from parts or describe it in words. A literal example")
        print("is still an instance -- this gate tripped ITSELF three times that")
        print("way on its first run, and the paragraph explaining how to avoid it")
        print("sits in this script, which is the one file nobody opens while")
        print("fixing a commit the tool just refused. (compiler seat, 08/25.)")
        print("\nA commit message already pushed cannot be edited without a")
        print("force-push; fix it BEFORE the push, which is why this runs here.")
        return 1

    if exempted:
        print(f"NOTE [gate {self_id()}]: {len(exempted)} finding(s) EXEMPTED BY "
              f"RULING (2026-08-25) -- preserved-record sites, pinned byte-exact.")
        print("      THIS IS NOT A CLEAN RESULT. These lines DO cite the private")
        print("      record; they are preserved deliberately and are green only")
        print("      while they match their pins exactly.")
        for e in exempted:
            print(f"        {e[0]}  {e[1]}")
    if exempt:
        print(f"  PIN AUDIT: {len(intact)} intact, {len(drifted)} drifted, "
              f"{len(unresolvable)} unresolvable"
              + (" (ref not in this checkout -- NOT counted as intact)"
                 if unresolvable else ""))
    else:
        print(f"  PIN AUDIT: not applicable in '{repo_slug() or 'unknown repo'}'"
              f" -- {len(EXEMPT)} pin(s) exist and none are scoped here."
              f" Stated rather than silently skipped.")

    if file_arm:
        arm2 = f"{len(lines)} added lines scanned"
    else:
        arm2 = ("FILE ARM NOT RUN -- '" + args.range + "' is not a two-dot "
                "range, so `git diff` would compare the working tree, not the "
                "delta. This is a DECLARED GAP, not a clean result")
    print(f"check_private_paths [gate {self_id()}]: OK ({len(msgs)} commit messages scanned and "
          f"{arm2}, for '{args.range}'; " + ("0 paths into the private record" if not exempted else f"0 UNEXEMPTED paths, {len(exempted)} EXEMPTED BY RULING -- see the NOTE above; this line is NOT a clean bill") + "). "
          f"Not scanned, by ruling: {'; '.join(PRESERVED)}.\n"
          f"  WATCHING {len(FORBIDDEN)} shapes: "
          + "; ".join(w for _, w in FORBIDDEN) + ".\n"
          f"  ROOTS ARE A HAND-COPIED SNAPSHOT of a fleet map that lives OUTSIDE"
          f" these repos and MOVES. Last reconciled 2026-08-25. A private root"
          f" born after that date is NOT watched until this list is edited.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

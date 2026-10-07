#!/usr/bin/env python3
"""No infrastructure name (a host, an account) may sit in the public tree.

WHY THIS EXISTS
---------------
The private-paths gate (check_private_paths.py) fires on PATHS into the private
record. The 2026-09-02 refuter pass on the v1 flip package found 41 occurrences of
a class no gate covered: the name of the machine the episodes ran on and the name
of the subscription account that ran them, in frozen documents, evidence READMEs
and harness defaults. They were replaced by role words ("the Studio", "the bench
account", the ssh alias `studio`) and the class is GATED here, so that it is held
by an instrument rather than remembered.

WHAT IT CHECKS
--------------
Every tracked, text file, case-insensitively, for the forbidden names. The names
are ASSEMBLED in this file rather than spelled, for the same reason the trailer
gate assembles its fixture: this gate scans itself.

FAILING CLOSED
--------------
A scan over zero files REDS. `--self-test` proves the empty scan is fatal, that a
planted name is caught in every case and prefix form, and that the role words pass,
before the tree scan is trusted.

WHAT IT DOES NOT DO
-------------------
It does not scan commit MESSAGES. History carried one such message at the time this
gate was written; whether that history is rewritten before the flip is the owner's
decision (PUBLISH-CHECKLIST.md), and a gate that reds on a decision not yet taken is
a gate that gets abandoned.

PORTED TO salt 2026-10-07 BY THE HELM (154th head) UNDER COUNCIL 2026-10-07 RULING 3, his words "ratchet only is
fine": salt's tree carries infrastructure names today (26 lines in 6 files at the port, all documentation and
Lean comments), so here the TREE ARM IS A RATCHET -- it accepts the residue listed in
scripts/infra_names_baseline.tsv (file, line-sha16; never the text, never the name) and REDS on anything NEW.
The push arm (--range) accepts an added line only when it is byte-identical to a baselined line in the same file
(a verbatim move); an EDITED line that still carries a name is NEW, and the remedy is to drop the name from the
line, not to grow the baseline. saltbench's copy (the source of this port) has a clean tree and reds on any hit;
the two files are otherwise kept the same so a fix in one ports to the other.

"""
from __future__ import annotations

import argparse
import hashlib
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                   cwd=pathlib.Path(__file__).resolve().parent,
                                   capture_output=True, text=True, check=True).stdout.strip())

# Assembled, never spelled — this gate scans itself.
#
# ⛔⛔ WIDENED 2026-09-10, on `systems`'s measurement of a FALSE GREEN. This list held exactly ONE
#   stem, because when the gate was written the host and the account SHARED it. The fleet now runs
#   FOUR accounts across FOUR boxes, and a BOX NAME (2 files) and an ACCOUNT NAME (2 files) were sitting
#   on PUBLIC main with Scrub GREEN. The gate was never wrong; it was OUTGROWN, and nothing announced
#   that.  ⇒ 🔑 AN ARM THAT NAMES ONE MEMBER OF A SET GOES VACUOUS WHEN THE SET GROWS.
FORBIDDEN = [
    "kri" + "ter" + "ion",      # a box, and an account: the original single stem
    "yu" + "kon",               # the box the seats run on
    "ke" + "nai",               # a box
    "jao" + "quin",             # a box
    "ja" + "son" + "h",         # an account
    "jy" + "aletheia",          # an account
    "claude-account-" + "ja" + "son",   # see the note below: the bare stem is NOT gateable
    "salt" + "forge",           # an account, added 2026-09-12 on the Captain's order at council
    "kat" + "mai",              # the run box, RENAMED 2026-09-25 from the first stem (which stays: it is an account too)
]

# ⛔ THE ONE THAT CANNOT BE A BARE SUBSTRING, AND THE REASON IS NOT A TECHNICALITY.
#   One account's name is the Captain's own GIVEN NAME, which appears legitimately in this public
#   repo as AUTHORSHIP -- `CITATION.cff` and `paper/saltbench-v1.tex` (\author{...}, and twice in the
#   bibliography). A bare substring rule would RED the paper's author line, and a gate that reds on
#   correct content is a gate that gets deleted. So that account is gated in its CONFIG-DIR SHAPE
#   only, which no byline can produce.
#   ⇒ 🔑 A NAME THAT IS ALSO A PERSON'S NAME IS GATEABLE ONLY IN THE SHAPES INFRASTRUCTURE USES.
#   ⇒ Anything this shape cannot catch is carried by the CONVENTION instead: a public tree names
#     accounts by anonymised label (ACCOUNT A / ACCOUNT B), with the mapping in the private record.

# ⛔ WHAT THIS TRIPWIRE DOES AND -- MORE IMPORTANTLY -- WHAT IT DOES NOT.
#   It refuses to scan when the forbidden set has SHRUNK below the count declared here. That catches
#   a name being DELETED. It does NOT catch the failure that actually happened, which was the FLEET
#   GROWING while this list stood still: both lines below are edited by the same hand, so they move
#   together and neither can notice a new account or a new box existing.
#   ⇒ 🔑 A DECLARATION AND THE THING IT DESCRIBES, EDITED TOGETHER, CANNOT CHECK EACH OTHER.
#   ⇒ **Completeness is not checkable from inside this repo at all.** The roster lives outside it and
#     MOVES, and CI cannot read it. Only a FLEET-SIDE check that reads the roster can know this set is
#     incomplete; that check is the load-bearing one and this is a second lock, not the lock.
#     (Named by `systems` on the bus, 2026-09-10, correcting this seat's first claim for it.)
#   The count is printed on every run so a reader can compare it against the fleet map rather than
#   trusting a date. Reconciled against the fleet roster on the date below -- its box column and its
#   account column. Adding a box or an account means editing BOTH lines, deliberately.
DECLARED_NAMES = 9
DECLARED_RECONCILED = "2026-09-25"

# THE RECONCILIATION ITSELF, WRITTEN OUT, so a reader can check COMPLETENESS without re-deriving it.
# The roster carries 6 ACCOUNTS and 4 BOXES -- 10 entities, covered by the 9 stems above because two
# stems each cover a box and an account that share a word. (Since 2026-09-25 the run box has its own
# stem; the first stem stays for the account that shares its old word, and for the tree's history.) Entity -> the stem that catches it:
#
#     account  jy-aletheia      -> its own stem
#     account  ja-son           -> the CONFIG-DIR shape only (see the note above: it is also a byline)
#     account  jy-<the box word>-> the box stem, as a substring
#     account  ja-son-h         -> its own stem
#     account  salt-forge       -> its own stem       (added 2026-09-12)
#     account  <box4>-local     -> the box-4 stem, as a substring
#     box      yu-kon           -> its own stem       box  ke-nai   -> its own stem
#     box      kat-mai          -> its own stem       box  jao-quin -> its own stem
#     (the run box, named <the box word> until 2026-09-25; that stem still catches the old name)
#
# ⛔ THIS TABLE IS A SNAPSHOT OF A FILE THAT LIVES ELSEWHERE AND MOVES, exactly like the roots list
#   in the private-paths gate. It is written down not because it stays true but because a reader who
#   suspects it has stopped being true can check it in one pass instead of rebuilding the derivation.


def tracked_files() -> list[tuple[str, str]]:
    out = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, check=True).stdout
    rows = []
    for rel in out.decode("utf-8").split("\0"):
        if not rel:
            continue
        p = ROOT / rel
        if not p.is_file():
            continue
        data = p.read_bytes()
        if b"\0" in data:
            continue  # binary
        rows.append((rel, data.decode("utf-8", errors="replace")))
    return rows


def scan(rows: list[tuple[str, str]]) -> list[tuple[str, int, str]]:
    found = []
    for rel, text in rows:
        for i, line in enumerate(text.splitlines(), 1):
            low = line.lower()
            if any(n in low for n in FORBIDDEN):
                found.append((rel, i, line.strip()[:160]))
    return found


# ⛔⛔ THE FINDING LINE WITHHOLDS THE MATCHED TEXT — desk row `PX`, the Captain's word 2026-09-16
#   ("yes, accept rec"), executed by the 79th helm head.
#
#   WHY. This gate exists to stop an infrastructure name entering a PUBLIC repo. Until this change it
#   REPORTED each finding as `  <file>:<line>: <the whole matched line>` — and on a public repo that
#   report lands in a world-readable Actions log. ⇒ 🔑 THE MECHANISM BUILT TO STOP A PRIVATE STRING
#   ENTERING THE RECORD PUBLISHED A SAMPLE OF EXACTLY WHAT IT CAUGHT.
#
#   ⭐ DRIVEN BEFORE THE CHANGE, ON A SCRATCH REPO: a planted line printed the account name, the home
#   path AND an unrelated marker that happened to share the line. **The leak is not bounded by the
#   name it matched** — it is the whole line, to 160 characters.
#
#   ⭐ MEASURED AT THE FORGE, the reason this was not hypothetical: across 92 failed Scrub runs on the
#   five gated public repos, 25 carried a gate FAIL block, and the home-directory / host / account
#   classes appear in saltbench runs ONLY — because this file is the only UNTRUNCATED echoer and it
#   runs in this repo alone (404 in salt, saltworks, jas, x86lean).
#
#   ⛔ WHAT IS KEPT, AND WHY IT IS NOT A BARE COUNT. Row I(c) (08/31) already paid for that mistake:
#   *"a count is not a scope; the verdict carries its scope or it carries nothing."* A fixer needs to
#   find the occurrence, so the FILE and the LINE NUMBER stay. What goes is the TEXT.
_FINDING_LABEL = "an infrastructure name (account or host)"


def finding_line(rel: str, i: int) -> str:
    """The one place a finding is rendered. File + line + CATEGORY, never the matched text."""
    return f"  {rel}:{i}: {_FINDING_LABEL}"


def self_test() -> int:
    failures = []
    # 1. The empty set is FATAL, first.
    if scan([]) != []:
        failures.append("scan([]) must find nothing")
    if not _is_empty_scan_fatal([]):
        failures.append("an empty file set must be FATAL, not green")
    # 2. EVERY name is planted, in every case and prefix form -- not just FORBIDDEN[0]. A per-name
    #    loop is the arm that a widened list cannot silently outgrow.
    for stem in FORBIDDEN:
        for form in (stem, stem.capitalize(), "x" + stem, "ssh " + stem + "-lan 'x'", stem.upper()):
            if len(scan([("f.md", f"a line\n{form} here\n")])) != 1:
                failures.append(f"planted form {form!r} must be caught exactly once")
    # 2b. THE TRIPWIRE ITSELF, driven: a set smaller than the declaration must be FATAL. Without this
    #     arm the declaration is a comment, and a comment cannot fail.
    if _declared_ok(FORBIDDEN[:-1]):
        failures.append("a set smaller than DECLARED_NAMES must be FATAL")
    if not _declared_ok(FORBIDDEN):
        failures.append("the live set must satisfy its own declaration")
    # 2c. The author's given name, standing alone as a byline, must PASS -- it is authorship, not
    #     infrastructure, and it is in this repo's own CITATION.cff and paper.
    if scan([("CITATION.cff", "  given-names: Ja" + "son\n\\author{Ja" + "son Hickey}\n")]):
        failures.append("an author byline must not be caught")
    # 3. The role words pass.
    clean = [("g.md", "on the Studio, on the bench account, STUDIO=\"${STUDIO:-studio}\", ssh studio 'x'\n")]
    if scan(clean):
        failures.append("role words must pass")
    # 4. The gate scans itself and is clean (it assembles, never spells).
    me = pathlib.Path(__file__).read_text(encoding="utf-8")
    if scan([("scripts/check_infra_names.py", me)]):
        failures.append("this file must not spell the name it forbids")
    # 5. ⛔⛔ THE FINDING LINE MUST NOT CARRY THE MATCHED TEXT — desk `PX`. This is the arm that makes
    #    the withholding a PROPERTY and not a habit: the renderer is driven on a real finding and the
    #    output is checked for the very thing it must never contain.
    #    ⚠️ THE LEAK WAS NEVER BOUNDED BY THE NAME IT MATCHED — the old form printed the WHOLE line, so
    #    anything sharing that line went to a public log too. The control below plants exactly that:
    #    a secret-shaped neighbour with no infrastructure name of its own.
    planted_name = "salt" + "forge"
    neighbour = "SIDECAR-SECRET-XYZ"
    probe_line = f"export CFG=/Users/jyh/.claude-account-{planted_name}/x  # {neighbour}"
    hits = scan([("cfg.sh", probe_line + "\n")])
    if len(hits) != 1:
        failures.append("the finding-line probe must produce exactly one hit to render")
    else:
        rel, i, matched = hits[0]
        rendered = finding_line(rel, i)
        if planted_name in rendered:
            failures.append("the finding line LEAKS the matched infrastructure name")
        if neighbour in rendered:
            failures.append("the finding line LEAKS a neighbour string sharing the matched line")
        if matched in rendered:
            failures.append("the finding line LEAKS the matched text")
        # ⭐ AND IT MUST STILL BE ACTIONABLE — row I(c): a count is not a scope. A renderer that
        #   withheld the file or the line number would pass every check above and be useless.
        if f"{rel}:{i}" not in rendered:
            failures.append("the finding line must still name the FILE and the LINE NUMBER")
        # ⭐ THE VACUITY CONTROL: the old form must FAIL the very checks the new form passes, or the
        #   arm proves nothing about the change.
        old_form = f"  {rel}:{i}: {matched}"
        if planted_name not in old_form or neighbour not in old_form:
            failures.append("CONTROL: the pre-change form should have leaked; this arm is vacuous")

    # 6. THE RATCHET, on the pure verdict (salt, ruling 3): a baselined line passes; the same line EDITED is
    #    NEW; a missing baseline with findings is UNARMED-FATAL (never a pass); an accepted line that vanished
    #    is debt PAID, not red; a baselined line MOVED to another file is NEW (keyed by file -- stated).
    nm = "salt" + "forge"
    base_line = f"ran on {nm} last night"
    f1 = scan_with_lines([("d.md", base_line + "\n")])
    if len(f1) != 1:
        failures.append("ratchet fixture must produce exactly one finding")
    else:
        key = {("d.md", line_sha(base_line))}
        new, paid, unarmed = tree_verdict(f1, key)
        if new or paid or unarmed:
            failures.append("a baselined line must PASS the tree ratchet")
        edited = scan_with_lines([("d.md", base_line + " again\n")])
        new, paid, unarmed = tree_verdict(edited, key)
        if len(new) != 1 or len(paid) != 1 or unarmed:
            failures.append("an EDITED baselined line must be NEW and leave the old entry as debt paid")
        new, paid, unarmed = tree_verdict(f1, None)
        if not unarmed:
            failures.append("a MISSING baseline with findings must be UNARMED-FATAL")
        new, paid, unarmed = tree_verdict([], key)
        if new or unarmed or len(paid) != 1:
            failures.append("a vanished accepted line must read as debt PAID, not red")
        moved = scan_with_lines([("e.md", base_line + "\n")])
        new, _paid, _u = tree_verdict(moved, key)
        if len(new) != 1:
            failures.append("a baselined line MOVED to another file must be NEW (keyed by file)")
        if line_sha(base_line) in finding_line("d.md", 1) or nm in finding_line("d.md", 1):
            failures.append("the finding line must carry neither the digest nor the name")
    for f in failures:
        print(f"SELF-TEST FAIL: {f}")
    if failures:
        return 1
    print(f"check_infra_names SELF-TEST: OK (empty scan fatal proven FIRST, "
          f"{len(FORBIDDEN) * 5} planted forms caught across {len(FORBIDDEN)} name(s), "
          f"the shrunk-set tripwire fires, an author byline passes, role words pass, self clean, "
          f"the finding line withholds the matched text and still names file:line; the tree ratchet: baselined passes, edited is new, missing baseline is fatal, vanished is paid, moved is new)")
    return 0


def _is_empty_scan_fatal(rows) -> bool:
    return len(rows) == 0


def _declared_ok(names) -> bool:
    """The forbidden set must not be SMALLER than what was reconciled against the roster."""
    return len(names) >= DECLARED_NAMES



# ---------------------------------------------------------------------------
# THE TREE RATCHET (salt, 2026-10-07, ruling 3). Mirrors check_private_paths.py --tree exactly in form:
# (file, line-sha16), a MISSING baseline with findings is UNARMED-FATAL (never "write it now"), an EMPTY
# baseline with findings reds, baseline entries no longer present are debt PAID and reported, never red.
# ---------------------------------------------------------------------------
TREE_BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "infra_names_baseline.tsv")


def line_sha(line: str) -> str:
    return hashlib.sha256(line.encode("utf-8", "replace")).hexdigest()[:16]


def load_tree_baseline():
    """set of accepted (file, line-sha16), or None when no baseline file exists. None != empty."""
    try:
        with open(TREE_BASELINE, encoding="utf-8") as fh:
            return {tuple(l.rstrip("\n").split("\t")[:2]) for l in fh if l.strip() and not l.startswith("#")}
    except FileNotFoundError:
        return None


def scan_with_lines(rows: list) -> list:
    """Like scan(), but keeps the WHOLE line (for its digest). The digest is all that ever leaves this function."""
    found = []
    for rel, text in rows:
        for i, line in enumerate(text.splitlines(), 1):
            low = line.lower()
            if any(n in low for n in FORBIDDEN):
                found.append((rel, i, line))
    return found


def tree_verdict(found: list, baseline) -> tuple:
    """PURE: (new, paid, unarmed_fatal). `found` is scan_with_lines output; baseline is a set or None."""
    if baseline is None and found:
        return (found, set(), True)
    base = baseline or set()
    keys = {(rel, line_sha(line)) for rel, _i, line in found}
    new = [f for f in found if (f[0], line_sha(f[2])) not in base]
    return (new, base - keys, False)


def tree_mode(write: bool) -> int:
    rows = tracked_files()
    if _is_empty_scan_fatal(rows):
        print("FAIL: zero tracked text files -- refusing to call an empty scan clean")
        return 1
    found = scan_with_lines(rows)
    if write:
        with open(TREE_BASELINE, "w", encoding="utf-8", newline="") as fh:
            fh.write("# infra_names_baseline.tsv -- ACCEPTED residue for the tree ratchet (check_infra_names.py --tree).\n"
                     "# file<TAB>line-sha16<TAB>what. NEVER the line and NEVER the name. Shrink it after a repair with\n"
                     "# --tree --write-baseline; a growth is a reviewed diff (council 2026-10-07 ruling 3: ratchet only).\n")
            for rel, _i, line in sorted(found, key=lambda f: (f[0], line_sha(f[2]))):
                fh.write(f"{rel}\t{line_sha(line)}\t{_FINDING_LABEL}\n")
        print(f"check_infra_names --tree --write-baseline: {len(found)} accepted residue line(s) in "
              f"{len({r for r, _, _ in found})} file(s) written to {os.path.basename(TREE_BASELINE)}")
        return 0
    new, paid, unarmed = tree_verdict(found, load_tree_baseline())
    if unarmed:
        print(f"FAIL: --tree has NO BASELINE and the tree carries {len(found)} finding(s), named below. "
              f"Write the baseline deliberately with --tree --write-baseline (a reviewed act, not a fix).")
        for rel, i, _line in found:
            print(finding_line(rel, i))
        return 1
    if new:
        print(f"FAIL TREE RATCHET: {len(new)} infrastructure-name line(s) in the tree that "
              f"{os.path.basename(TREE_BASELINE)} does not accept (NEW, or an accepted line EDITED). "
              f"Drop the name from the line; do not grow the baseline for it.")
        for rel, i, _line in new:
            print(finding_line(rel, i))
        return 1
    print(f"check_infra_names --tree: OK ({len(found)} accepted residue line(s) in "
          f"{len({r for r, _, _ in found})} file(s), all in the baseline; {len(paid)} baseline entr"
          f"{'y' if len(paid) == 1 else 'ies'} no longer present"
          + (" -- debt paid; shrink the baseline with --tree --write-baseline" if paid else "") + "). 0 NEW.")
    return 0


# ---------------------------------------------------------------------------
# ⛔⛔ THE HISTORY AND RANGE ARMS, ADDED 2026-09-11.
# Measured that night, on the helm's ruling about the SIBLING gate: this file
# had `[-h] [--self-test]` and nothing else. No range arm, no history arm, no
# message arm. It scanned the tracked TREE and had never read a single commit —
# and it is the gate on HOST AND ACCOUNT NAMES, the class the fleet has an
# explicit law about and the one that actually leaked.
#   ⇒ Measured over saltbench's 360 commits the first time this ran:
#       current tree   0 occurrences        ✅
#       history      107 occurrences in 36 commits, NONE of them still in the tree
#   ⇒ 🔑 A GATE WITH ONE ARM IS CLEAN ABOUT THE ONLY POPULATION IT CAN SEE, and
#     the tree is the population that MOVES. Everything it ever caught and
#     everything anyone ever tidied away is still in a public clone.
#
# ⛔ THE RATCHET IS NOT A REPAIR AND MUST NOT READ AS ONE. A pushed commit's
# content cannot be changed without a force-push, ruled out 08/30 and in any
# case a Captain-level call on a public repo an arXiv paper now cites. This
# freezes the population and COUNTS it. It stops tomorrow's commit and says
# nothing whatever about yesterday's.
# ---------------------------------------------------------------------------
HIST_BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "infra_names_history_baseline.tsv")
EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"


def _git(args: list) -> str:
    return subprocess.run(["git"] + args, capture_output=True, text=True,
                          encoding="utf-8", errors="replace").stdout


def load_hist_baseline() -> set:
    """Accepted (sha, file) pairs. An absent file is an EMPTY set, never a pass."""
    out = set()
    if not os.path.exists(HIST_BASELINE):
        return out
    with open(HIST_BASELINE, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) >= 2:
                out.add((parts[0], parts[1]))
    return out


def added_rows(base: str, sha: str) -> list:
    """(path, added text) for what this commit ADDS. A deletion is never a finding."""
    out = _git(["diff", "--unified=0", "--no-color", base, sha])
    rows, path = [], "?"
    for line in out.splitlines():
        if line.startswith("+++ b/"):
            path = line[6:]
        elif line.startswith("+") and not line.startswith("+++"):
            rows.append((path, line[1:]))
    return rows


def _is_shallow() -> bool:
    return _git(["rev-parse", "--is-shallow-repository"]).strip() == "true"


def history_mode(write: bool) -> int:
    # ⛔⛔ A SHALLOW CLONE FAILS, AND THIS GUARD WAS MISSING FOR ONE CI RUN.
    #   Driven, and caught only by reading the COUNT in a PASSING line rather than the
    #   colour beside it: this arm's first CI run printed
    #       check_infra_names --history: OK (1 commits scanned; 40 accepted, 0 new)
    #   while the sibling in the same workflow printed 358. The job checks out at the
    #   default depth, and without this guard a one-commit history scans the truncation
    #   and reports success -- a green that means nothing, in a gate whose whole job is
    #   to report a negative.
    #   ⇒ 🔑 THE WORKFLOW WAS ALSO FIXED (fetch-depth: 0), AND THAT IS NOT THE REPAIR.
    #     A script that depends on its caller being configured correctly has moved the
    #     guard to the one place a reader of the script cannot see it.
    if _is_shallow():
        print("FAIL: this is a SHALLOW clone. A full-history ratchet on a truncated "
              "history scans the truncation, not the history.\n"
              "      CI must check out with `fetch-depth: 0` for this job.")
        return 1
    shas = _git(["rev-list", "HEAD"]).split()
    if not shas:
        print("FAIL: scanned ZERO commits from HEAD. An empty scan is not a clean scan.")
        return 1
    per = {}
    total = 0
    for sha in shas:
        parents = _git(["rev-list", "--parents", "-n", "1", sha]).split()
        # ⛔ first parent, so a merge is charged for what it BRINGS, not for the
        #   whole branch; and a root commit against the empty tree, because the
        #   first commit is exactly where a pre-gate name sits.
        base = parents[1] if len(parents) > 1 else EMPTY_TREE
        rows = added_rows(base, sha)
        if not rows:
            continue
        for rel, _i, _line in scan(rows):
            per.setdefault((sha[:12], rel), 0)
            per[(sha[:12], rel)] += 1
            total += 1
    if write:
        with open(HIST_BASELINE, "w", encoding="utf-8", newline="") as fh:
            fh.write("# infra_names_history_baseline.tsv -- ACCEPTED historical commits whose ADDED "
                     "LINES carry an infrastructure name (check_infra_names.py --history).\n"
                     "# sha<TAB>file<TAB>count. NEVER the line and NEVER the name: an excerpt would "
                     "put the name into the tree, where the tree arm correctly reds on it.\n"
                     "# This list does not shrink without a force-push, which is a Captain-level call "
                     "on a public repo. A GROWTH is a reviewed diff.\n")
            for k in sorted(per):
                fh.write(f"{k[0]}\t{k[1]}\t{per[k]}\n")
        print(f"check_infra_names --history --write-baseline: {len(per)} accepted (commit, file) "
              f"pair(s), {total} occurrence(s), written to {os.path.basename(HIST_BASELINE)}")
        return 0
    base_set = load_hist_baseline()
    new = [k for k in sorted(per) if k not in base_set]
    if new:
        print(f"FAIL: {len(new)} NEW infrastructure-name finding(s) in history, not in "
              f"{os.path.basename(HIST_BASELINE)} ({len(shas)} commits scanned):")
        for sha, rel in new[:20]:
            print(f"  {sha}  {rel}")
        return 1
    print(f"check_infra_names --history: OK ({len(shas)} commits scanned; "
          f"{len(base_set)} accepted historical (commit, file) pair(s), 0 new)")
    return 0


def range_mode(rev_range: str) -> int:
    """The arm CI runs on a push: what THIS delta adds, against nothing."""
    rows = added_rows(*rev_range.split("..", 1)) if ".." in rev_range else added_rows(EMPTY_TREE, rev_range)
    found = scan_with_lines(rows)
    # the ratchet's one allowance at the delta: an added line byte-identical to a baselined line of the SAME
    # file (a verbatim move or re-add). An edited line hashes anew and is NEW.
    base = load_tree_baseline() or set()
    found = [f for f in found if (f[0], line_sha(f[2])) not in base]
    for rel, i, _line in found:
        print(finding_line(rel, i))
    if found:
        print(f"FAIL: {len(found)} NEW infrastructure-name occurrence(s) added by {rev_range} "
              f"(ratchet: an edited line that keeps a name is new; drop the name from the line)")
        return 1
    print(f"check_infra_names --range {rev_range}: OK ({len(rows)} added lines, 0 new occurrences)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--history", action="store_true",
                    help="ratchet: added lines of EVERY commit in history vs the committed baseline")
    ap.add_argument("--range", default=None,
                    help="scan the added lines of a git revision range (the push arm)")
    ap.add_argument("--tree", action="store_true",
                    help="ratchet: every tracked text file vs scripts/infra_names_baseline.tsv (the default)")
    ap.add_argument("--write-baseline", action="store_true",
                    help="with --history or --tree: write that arm's accepted baseline")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if a.history and a.range:
        print("FAIL: --history and --range are separate arms; run them separately so a red names its arm.")
        return 1
    if not _declared_ok(FORBIDDEN):
        print(f"FAIL: {len(FORBIDDEN)} forbidden name(s) against DECLARED_NAMES={DECLARED_NAMES} "
              f"(reconciled {DECLARED_RECONCILED}) -- a set that has shrunk is a gate that has been "
              f"quietly narrowed; refusing to scan.")
        return 1
    if a.history:
        return history_mode(a.write_baseline)
    if a.range:
        return range_mode(a.range)
    return tree_mode(a.write_baseline)
    rows = tracked_files()  # unreachable in salt: the bare run IS the tree ratchet (kept so the source diff vs saltbench stays small)
    if _is_empty_scan_fatal(rows):
        print("FAIL: zero tracked text files -- refusing to call an empty scan clean")
        return 1
    found = scan(rows)
    for rel, i, _line in found:
        print(finding_line(rel, i))
    if found:
        print(f"FAIL: {len(found)} infrastructure-name occurrence(s) in {len({r for r, _, _ in found})} file(s)")
        return 1
    print(f"check_infra_names: OK ({len(rows)} tracked text files, 0 occurrences; "
          f"{len(FORBIDDEN)} names WATCHED BY NAME, reconciled against the fleet roster {DECLARED_RECONCILED} -- \n"
          f"  the count is printed so a reader can compare it against the fleet map instead of trusting the date.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

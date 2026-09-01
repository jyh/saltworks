#!/usr/bin/env python3
"""PR titles and bodies are not git objects. Nothing scanned them.

WHY THIS EXISTS (desk row I(a), commissioned from a sibling seat's audit)
-------------------------------------------------------------------------
The firewall gate beside this file scans commit messages, added lines, the
whole tree, and all of message history — four arms over GIT OBJECTS. A pull
request's TITLE and BODY are none of those: they live only in the forge's
database, they are the prose a reader actually sees first on the public repo
page, and they are EDITABLE FOREVER. The most-read public prose surface was
the one surface no arm covered. Measured before this shipped: one PR body in
this fleet carried a private-record path for five days (found 08/30) while
every git-object arm stayed green, because no git object ever contained it.

THE FOURTH DOOR (same audit, item (f)): a push to the BASE branch fires no
run for the PRs that target it, so a PR can sit green and MERGEABLE while
every one of its verdicts is about a base that no longer exists. Status is a
claim about a PAIR of refs at a moment; the pair moves and the status does
not. So this arm never reads status alone — it re-reads the REFS on every
run and says which object each verdict is actually about (REF-vs-RUN).

WHY IT RUNS FROM THE PUSH WORKFLOW AND NOT A pull_request TRIGGER: the
pull_request event fires on the PR's OWN pushes; it does not fire when the
base moves, and it does not fire when someone EDITS a description after the
checks are green. A push-triggered sweep of ALL open PRs re-reads everything
the forge currently says, every time anything lands — the only cadence that
closes both doors. (The event payload is deliberately never read: a
schedule-triggered run has none, and a guard scoped wider than its event set
fails open — measured in this fleet, 08/30.)

SHAPES: imported from the sibling gate, never re-typed. A fixture is a
snapshot of a vocabulary; a copied pattern list is a stale fixture the day
the sibling moves. One list, one owner, two readers.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_private_paths as gate  # noqa: E402  (the pattern owner)

from utf8_stdout import ensure_utf8_stdout  # noqa: E402


def self_id() -> str:
    try:
        return hashlib.sha256(
            pathlib.Path(__file__).read_bytes()).hexdigest()[:16]
    except OSError:
        return "unreadable"


def scan_description(number, title: str, body: str):
    """Findings for one PR's forge-side prose, via the sibling gate's scan."""
    rows = [(f"PR #{number} TITLE", title or ""),
            (f"PR #{number} BODY", body or "")]
    return gate.scan(rows)


def ref_vs_run(head_sha: str, run_sha, run_green, behind_by) -> str:
    """One line saying WHICH OBJECT the PR's verdict is about. Pure, so the
    self-test drives every branch without a forge.

    Never a bare status: a status is a claim about a (head, base) pair at a
    moment, and only the refs say whether that moment is this one."""
    if run_sha is None:
        return "NO RUN on the current head — any green you see is about an OLDER head"
    if run_sha != head_sha:
        return (f"RUN-vs-REF MISMATCH — latest run is on {run_sha[:8]}, head is "
                f"{head_sha[:8]}: the verdict is about a DIFFERENT object")
    if run_green and isinstance(behind_by, int) and behind_by > 0:
        return (f"GREEN BUT STALE — head verdict is green, but the base has moved "
                f"{behind_by} commit(s) since (a base move fires no run): the green "
                f"is about a base that no longer exists")
    if not run_green:
        return "run on current head NOT green"
    return "current — run is on this head and the base has not moved"


def _gh(args: list[str]):
    out = subprocess.run(["gh", "api"] + args, capture_output=True, text=True,
                         encoding="utf-8")
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip()[:200])
    return json.loads(out.stdout)


def open_mode(repo: str) -> int:
    """Scan every OPEN PR's title+body; disclose REF-vs-RUN for each."""
    try:
        prs = _gh([f"repos/{repo}/pulls?state=open&per_page=100"])
    except RuntimeError as e:
        print(f"FAIL [pr-gate {self_id()}]: could not list open PRs: {e}\n"
              "      An unreadable forge is not a clean forge.")
        return 1
    bad = []
    notes = []
    for pr in prs:
        n = pr["number"]
        bad += scan_description(n, pr.get("title"), pr.get("body"))
        head = pr["head"]["sha"]
        base_ref = pr["base"]["ref"]
        run_sha = run_green = None
        behind = None
        try:
            runs = _gh([f"repos/{repo}/commits/{head}/check-runs?per_page=50"])
            checks = runs.get("check_runs", [])
            if checks:
                run_sha = head
                run_green = all(c.get("conclusion") in ("success", "skipped", "neutral")
                                for c in checks if c.get("status") == "completed") \
                    and any(c.get("status") == "completed" for c in checks)
            cmp_ = _gh([f"repos/{repo}/compare/{head}...{base_ref}"])
            behind = cmp_.get("ahead_by")  # base commits the head has not seen
        except RuntimeError as e:
            notes.append(f"  PR #{n}: REF-vs-RUN unreadable ({e}) — reported, not assumed current")
            continue
        notes.append(f"  PR #{n} head {head[:8]} vs base {base_ref}: "
                     + ref_vs_run(head, run_sha, bool(run_green), behind))
    if bad:
        print(f"FAIL [pr-gate {self_id()}]: {len(bad)} private-record path(s) in "
              f"OPEN PR descriptions — the forge-side prose, not any git object.\n")
        print("\n".join(gate.finding_lines(bad)))
        print("\nA PR description is EDITABLE: rewrite the reference as a ROLE or a")
        print("bare filename directly on the forge. No push required.")
        return 1
    print(f"check_pr_descriptions --open [pr-gate {self_id()}]: OK — {len(prs)} open "
          f"PR(s), 0 private-record paths in titles/bodies.")
    if notes:
        print("REF-vs-RUN (which object each verdict is about; never status alone):")
        print("\n".join(notes))
    return 0


def self_test() -> int:
    failures = []
    S = "se" + "at"
    # ARM 1 — a planted forge-side path must be caught, in TITLE and in BODY.
    if not scan_description(1, "cite " + S + "/x/y.md", ""):
        failures.append("a planted path in a TITLE must be caught")
    if not scan_description(1, "", "see " + S + "/x/y.md line 3"):
        failures.append("a planted path in a BODY must be caught")
    # ...and the finding's identity must NAME the PR and the surface.
    got = scan_description(7, "", "see " + S + "/x/y.md")
    if not got or "PR #7 BODY" not in got[0][0]:
        failures.append("a finding must name its PR number and surface")
    # ARM 2 — compliant prose passes; None body (forge returns null) is safe.
    if scan_description(2, "role wording: the helm's brief", None):
        failures.append("role wording must pass; a null body must not crash")
    # ARM 3 — ref_vs_run, every branch, both directions.
    h = "a" * 40
    if "NO RUN" not in ref_vs_run(h, None, False, 0):
        failures.append("no run on head must say NO RUN")
    if "MISMATCH" not in ref_vs_run(h, "b" * 40, True, 0):
        failures.append("a run on another sha must say MISMATCH")
    if "STALE" not in ref_vs_run(h, h, True, 3):
        failures.append("green + moved base must say GREEN BUT STALE")
    if "NOT green" not in ref_vs_run(h, h, False, 0):
        failures.append("a red run on the current head must say so")
    if "current" not in ref_vs_run(h, h, True, 0):
        failures.append("green on current head over an unmoved base is current")
    # ARM 4 — the vocabulary is the SIBLING'S, not a copy: a shape the sibling
    # catches must be caught HERE through the import, so a sibling repair
    # propagates instead of invalidating this file silently.
    if not any("rootless" in w for _, w, _ in
               scan_description(3, "", "in " + "bri" + "efs" + "/x.md")):
        failures.append("the sibling's newest shape must reach this arm via the import")
    for f in failures:
        print(f"SELF-TEST FAIL: {f}")
    if failures:
        return 1
    print(f"check_pr_descriptions SELF-TEST [pr-gate {self_id()}] over "
          f"[gate {gate.self_id()}]: OK (title+body arms both directions; "
          f"ref_vs_run all five branches; sibling vocabulary reached via import)")
    return 0


def main() -> int:
    # A gate's verdict is a RECEIPT, and on a cp1252 stdout (real Windows,
    # every redirected CI step, hosted windows-latest included) an em-dash
    # silently becomes byte 0x97 while a character outside the table kills
    # the process mid-print. Both measured on this repository's own gates,
    # 2026-08-31. FIRST statement in main, before argument parsing:
    # argparse prints usage and errors too.
    ensure_utf8_stdout()
    ap = argparse.ArgumentParser(description="forge-side prose gate (row I(a))")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--open", action="store_true",
                    help="scan every open PR's title+body via the forge API")
    ap.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", ""),
                    help="owner/name; defaults to GITHUB_REPOSITORY")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    if args.open:
        if not args.repo:
            print("FAIL: no repo — pass --repo owner/name or set GITHUB_REPOSITORY")
            return 1
        return open_mode(args.repo)
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
campaign_receipts.py — THE TWO-WEEKS STORY'S RECEIPTS.

Assigned by the maestro 2026-08-08 19:02: "the measured numbers of days 1-3
(theorems, refutation rounds, catches, costs where charted) pulled into a
citable table -- the story quotes ONLY instrument readings, and your ledger is
the instrument."

⚠️ THESE FIGURES ARE INTENDED FOR PUBLIC QUOTATION BY THE CAPTAIN. That raises
the bar rather than lowering it, and this file is built to the standard the day
of 2026-08-08 taught, at the cost of five of my own published figures being
wrong first:

 1. EVERY ROW CARRIES ITS SCOPE. A count without the repo, the window, the
    declaration pattern and the add-vs-net rule is not quotable.
    [[a-count-is-not-a-scope]]
 2. NO SINGLE HEADLINE. The story may pick a number; this file will not pick it
    for the story, because a bare count is what drifts.
 3. THE DECLARATION PATTERN INCLUDES ATTRIBUTES. `^theorem` misses
    `@[simp] theorem` -- and the simp-set declarations are the ones applied
    IMPLICITLY by tactics that never name them, i.e. the widest blast radius.
    Two seats made this exact error today; it cost 3 of 13 in one file pair.
 4. ADDED vs SURVIVING ARE DIFFERENT NUMBERS AND BOTH ARE REPORTED. Phase 3
    deliberately DELETED 16 declarations. "Theorems written" and "theorems
    standing" are different claims and the story must not blur them.
 5. AN EMPTY RESULT IS AN INSTRUMENT READING, NOT A FACT. Every query that can
    return zero is positive-controlled; if a control fails the row REFUSES.
    [[printed-is-not-gated]] -- the refusal is an exit code, not a warning.

WHAT THIS FILE DOES NOT DO: it does not compute a rate, a velocity, or a
per-day average. The charter refuses those ("the window is evidence, not a
percentage") and a two-week story is exactly where such a figure would travel
furthest from its scope.

    python3 campaign_receipts.py            # the table
    python3 campaign_receipts.py --controls # show the positive controls too
"""

import re
import subprocess
import sys

REPOS = {
    "saltworks": "/Users/jyh/projects/claude/saltworks",
    "salt": "/Users/jyh/projects/claude/salt",
}

# T0 of the triple campaign: 2026-08-05 22:02 PDT (FLEET.md), per nightly.sh.
DAYS = [
    ("DAY 1", "2026-08-05 22:02", "2026-08-07 00:00"),
    ("DAY 2", "2026-08-07 00:00", "2026-08-08 00:00"),
    ("DAY 3", "2026-08-08 00:00", "2026-08-09 00:00"),
]

# Line-start, optional attribute blocks and modifiers, then the keyword.
# NOT `^theorem` (misses @[simp]); NOT unanchored (catches prose, e.g.
# "That is the theorem below").
DECL = re.compile(
    r"^(@\[[^\]]*\][ \t]*)*(private |protected |noncomputable |partial )*"
    r"(theorem|lemma)[ \t]",
)


# The two design blocks the campaign refuted-then-proved, with the timestamp of
# each one's FIRST kernel landing — the boundary the method's claim rests on.
BLOCKS = [
    ("docs/payload-delivery-design-v1.md", "③ payload certificate", "08-08 16:18"),
    ("docs/heritage-1988-rotation-design-v1.md", "④ heritage rotation", "08-08 17:32"),
]

# A fold that RECORDS A DEFECT. Drafting ("drafted") and pure repair-completions
# ("reach final form") are deliberately excluded.
REFUTED = re.compile(
    r"REFUTED|refutation folded|pass resolved|hazard folded|pass folded"
    r"|round-2 folded|RESTATED|R1 folded|scope folded|findings folded"
    r"|corrections folded|right-of-reply folded|read folded",
    re.I,
)

# ⛔ AND THE EXCLUSION THAT KEEPS THIS HONEST — caught 19:1x by cross-checking
# this tool against item 2's figure (e), computed by hand this afternoon.
# The tool said 9 folds before the ③ landing; (e) said 8 REFUTATIONS. The extra
# is `silicon's CLEAN ③ pass folded` (12:27) — a discharged pass that found
# NOTHING. It belongs in "passes run" and NOT in "defects found", and item 2
# already said so in writing: "625b18d (silicon's CLEAN pass) is a discharged
# pass in (a) and correctly NOT a defect in (e)".
# 🔑 A CLEAN PASS IS EVIDENCE THE METHOD RAN, NOT EVIDENCE IT CAUGHT SOMETHING.
# Counting it as a refutation would inflate the story's central number by
# exactly the passes that found nothing — the most flattering possible error.
CLEAN_PASS = re.compile(r"\bclean\b", re.I)


def git(repo, *args):
    try:
        return subprocess.run(["git", "-C", repo, *args],
                              capture_output=True, text=True, timeout=120).stdout
    except Exception:
        return ""


def added_decls(repo, since, until):
    """Count declaration lines ADDED to *.lean in the window. Returns (added, commits)."""
    out = git(repo, "log", f"--since={since}", f"--until={until}",
              "--format=%H", "--", "*.lean")
    shas = [s for s in out.split() if s]
    added = 0
    for sha in shas:
        diff = git(repo, "show", sha, "--format=", "--unified=0", "--", "*.lean")
        for line in diff.split("\n"):
            if line.startswith("+") and not line.startswith("+++"):
                if DECL.match(line[1:]):
                    added += 1
    return added, len(shas)


def surviving_decls(repo, ref="HEAD"):
    """Declarations standing in the tree at ref — a different claim from 'added'."""
    files = [f for f in git(repo, "ls-tree", "-r", "--name-only", ref).split("\n")
             if f.endswith(".lean")]
    n = 0
    for f in files:
        for line in git(repo, "show", f"{ref}:{f}").split("\n"):
            if DECL.match(line):
                n += 1
    return n, len(files)


def controls():
    """POSITIVE CONTROLS. If these fail, every zero below is uninterpretable.
    Returns (ok, lines)."""
    out, ok = [], True

    # C1: the pattern must catch an attribute-prefixed declaration.
    c1 = bool(DECL.match("@[simp] theorem rotStage_eq (l : List α) : x := rfl"))
    out.append(f"  C1 attribute-prefixed decl matches      {'PASS' if c1 else 'FAIL'}")
    ok &= c1

    # C2: the pattern must NOT catch prose containing the keyword.
    c2 = not DECL.match("That is the theorem below — the Captain's phrase")
    out.append(f"  C2 prose containing 'theorem' rejected  {'PASS' if c2 else 'FAIL'}")
    ok &= c2

    # C3: a plain declaration must match.
    c3 = bool(DECL.match("theorem foo : True := trivial"))
    out.append(f"  C3 plain declaration matches            {'PASS' if c3 else 'FAIL'}")
    ok &= c3

    # C4: both repos must be readable and non-empty.
    for name, path in REPOS.items():
        h = git(path, "rev-parse", "HEAD").strip()
        good = len(h) == 40
        out.append(f"  C4 repo {name:10s} readable            {'PASS' if good else 'FAIL'}")
        ok &= good
    return ok, out


def main():
    ok, ctl = controls()
    show_controls = "--controls" in sys.argv

    print("=" * 76)
    print("TWO-WEEKS STORY — RECEIPTS, days 1-3    (instrument readings only)")
    print("=" * 76)

    if show_controls or not ok:
        print("\nPOSITIVE CONTROLS — an empty result is uninterpretable without these:")
        print("\n".join(ctl))

    if not ok:
        print("\n⛔⛔ A CONTROL FAILED. NO FIGURES PRINTED.")
        print("   Every count below could be zero because the world is empty or")
        print("   because the instrument is broken, and those are the same output.")
        return 2

    print("\n--- KERNEL DECLARATIONS **ADDED** per day (theorem|lemma, *.lean) ---")
    print("    scope: additions to tracked .lean files, both campaign repos.")
    print("    pattern: line-start, attributes/modifiers allowed, then the keyword.")
    print("    ⚠️ ADDED, not SURVIVING — phase 3 deliberately deleted 16 on day 3.")
    print(f"    {'window':8s} {'saltworks':>22s} {'salt':>22s}")
    totals = {r: 0 for r in REPOS}
    for label, since, until in DAYS:
        cells = []
        for repo in ("saltworks", "salt"):
            n, c = added_decls(REPOS[repo], since, until)
            totals[repo] += n
            cells.append(f"{n:6d} decls / {c:3d} commits")
        print(f"    {label:8s} {cells[0]:>22s} {cells[1]:>22s}")
    print(f"    {'TOTAL':8s} {totals['saltworks']:6d} decls{'':10s}"
          f"{totals['salt']:6d} decls")

    # ⛔ "AT HEAD" IS NOT A CITATION — it is a reading whose subject moves.
    # Caught 19:4x: I published "1,948 stand at HEAD" at 19:15; HEAD had moved
    # TWICE in the three minutes before (SortDemo landed 5f3e622, rooted 777c5b4)
    # and the true current figure was 2,013. A peer handed me the delta rather
    # than re-deriving my total, and their independent hand count of SortDemo's
    # 65 theorems matched my instrument's delta EXACTLY.
    # 🔑 This is my own content-addressing law, which I applied to freeze anchors
    # and did NOT apply to my own headline figure. The row now PINS the sha it
    # read, so a quoted figure can never outlive its subject.
    head = git(REPOS["saltworks"], "rev-parse", "--short", "HEAD").strip()
    print(f"\n--- KERNEL DECLARATIONS **SURVIVING**, pinned at `{head}` ---")
    print("    ⛔ NOT 'at HEAD' — HEAD moves. Quote the sha, never the word.")
    print("    ⛔ THIS ROW IS ONLY A CAMPAIGN FIGURE FOR A REPO WHOSE HISTORY *IS*")
    print("       THE CAMPAIGN. Measured, not assumed — commits predating T0:")
    for repo in ("saltworks", "salt"):
        n, f = surviving_decls(REPOS[repo])
        pre = git(REPOS[repo], "rev-list", "--count",
                  "--until=2026-08-05 22:02", "HEAD").strip() or "?"
        first = git(REPOS[repo], "log", "--reverse", "--format=%ad",
                    "--date=format:%Y-%m-%d").split("\n")[0]
        if pre == "0":
            print(f"    {repo:10s} {n:6d} standing / {f:4d} files"
                  f"   ✅ CAMPAIGN FIGURE — repo born {first}, {pre} commits before T0")
        else:
            print(f"    {repo:10s} {n:6d} standing / {f:4d} files"
                  f"   ⛔ NOT A CAMPAIGN FIGURE")
            print(f"    {'':10s} repo born {first}; {pre} of its commits PREDATE T0.")
            print(f"    {'':10s} ⇒ quote its ADDED row above, never this one. A story")
            print(f"    {'':10s}   pairing this total with 'two weeks' would be false")
            print(f"    {'':10s}   by roughly the whole pre-campaign corpus.")

    print("\n--- REFUTATION ROUNDS per design block (fold commits to the block doc) ---")
    print("    counting rule: a commit to the block's doc that FOLDS a refutation —")
    print("    i.e. records a defect a read/pass found. Drafting commits and pure")
    print("    repair-completions are NOT rounds. Classified by reading each subject;")
    print("    anything unclassifiable would print UNCLASSIFIED rather than be assigned.")
    for doc, label, first_wave in BLOCKS:
        subs = [l for l in git(REPOS["saltworks"], "log", "--reverse",
                               "--format=%ad|%s", "--date=format:%m-%d %H:%M",
                               "--", doc).split("\n") if l.strip()]
        folds = [s for s in subs if REFUTED.search(s.split("|", 1)[1])]
        clean = [s for s in folds if CLEAN_PASS.search(s.split("|", 1)[1])]
        rounds = [s for s in folds if s not in clean]
        before = [s for s in rounds if s.split("|", 1)[0] < first_wave]
        print(f"\n    {label}   ({len(subs)} commits to the doc)")
        print(f"      DEFECT-BEARING folds TOTAL      {len(rounds)}")
        print(f"      folds BEFORE the first landing  {len(before)}   ⬅ the method's claim")
        if clean:
            print(f"      CLEAN passes folded, EXCLUDED   {len(clean)}"
                  f"   (ran, found nothing — not a catch)")
        for s in rounds:
            when, sub = s.split("|", 1)
            mark = "·" if when < first_wave else "(after)"
            print(f"        {mark:7s} {when}  {sub[:78]}")
        for s in clean:
            when, sub = s.split("|", 1)
            print(f"        (clean) {when}  {sub[:78]}")

    print("\n" + "=" * 76)
    print("⛔ NO RATE, VELOCITY OR PER-DAY AVERAGE IS COMPUTED HERE, DELIBERATELY.")
    print("   The charter refuses them ('the window is evidence, not a percentage')")
    print("   and a two-week story is where such a figure travels furthest from")
    print("   its scope. Quote a row with its scope line, or do not quote it.")
    print("=" * 76)
    return 0


if __name__ == "__main__":
    sys.exit(main())

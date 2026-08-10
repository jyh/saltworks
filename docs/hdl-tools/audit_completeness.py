#!/usr/bin/env python3
"""Is every THEOREM in leg 2 covered by an `#audit_axioms` line?

`#audit_axioms` takes a LIST OF NAMES, so it is a whitelist: it bounds what is
checked from above and NOTHING ENFORCES THAT THE LIST IS COMPLETE.  A theorem
nobody lists is a theorem nobody audits, and the build stays green.
`SaltWorks/HDL/Sem.lean` records that gap and says the completeness check
"belongs in CI rather than in anyone's memory".  This is it.

Exit 0 = complete · 1 = unaudited theorems found · 2 = could not check.
The three-way exit is deliberate: a green from a tool that read nothing is worse
than a red.

⛔ AND THIS SCRIPT COMMITTED THAT EXACT SIN FOR A DAY (found by math 2026-08-07
19:02, confirmed and widened here).  The default root was `SaltWorks/HDL` and the
glob was NON-RECURSIVE, so it read 35 files of the repo's 48 and 404 theorems of
its ~967.  SIX OF THE SEVEN directories holding .lean files were never audited --
including SaltWorks/Stack, which holds MORE theorems (563) than the scope that
was read, and 2 unaudited ones.  Naming the parent (`SaltWorks`) read ZERO files
and exited 2.

🔑 The defence this docstring used to offer -- "it prints WHAT IT READ (file and
theorem counts)" -- WAS THE BUG WEARING THE FIX'S CLOTHES.  A COUNT IS NOT A
SCOPE: "READ: 35 files" cannot distinguish `all of them` from `35 of 48`, and the
RESULT line (the one that gets quoted) carried neither the root nor the count.
⇒ EVERY LINE THIS TOOL PRINTS NOW NAMES ITS ROOT.  A verdict that cannot be
quoted without its scope is the only kind worth printing.

⚠️ THE FIRST VERSION OF THIS SCRIPT REPORTED 149 UNAUDITED DECLARATIONS AND WAS
WRONG.  It regex-matched `^(theorem|def|abbrev)\\s+NAME` against the RAW source,
so prose inside docstrings that happened to begin a line with those words was
read as a declaration -- it "found" theorems named `is`, `goes`, `rather`,
`above` and `mentioning`.  Comments are stripped first for exactly that reason.
A tool that scans Lean source and does not strip comments is measuring the prose.
That applies to BOTH sides of the comparison: an `#audit_axioms` line quoted
inside a docstring is prose about auditing, not an audit.
"""
import re, sys, glob, os, subprocess

def strip_comments(src: str) -> str:
    out, i, depth = [], 0, 0
    while i < len(src):
        if src.startswith('/-', i):
            depth += 1; i += 2; continue
        if src.startswith('-/', i) and depth > 0:
            depth -= 1; i += 2; out.append(' '); continue
        if depth == 0 and src.startswith('--', i):
            j = src.find('\n', i); i = len(src) if j < 0 else j; continue
        if depth == 0:
            out.append(src[i])
        i += 1
    return ''.join(out), depth

def _tree_state(files):
    """HEAD sha and which of `files` are uncommitted, captured WITH the reading.

    Returns ('?', []) if git is unavailable -- an unknown tree state is reported
    as unknown, never as clean."""
    try:
        head = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'],
                              capture_output=True, text=True, timeout=10).stdout.strip() or '?'
        out = subprocess.run(['git', 'status', '--porcelain', '--'] + list(files),
                             capture_output=True, text=True, timeout=30).stdout
        dirty = [ln[3:].strip() for ln in out.splitlines() if ln.strip()]
        return head, dirty
    except Exception as e:
        # ⛔ NOT `return '?', []` — an empty dirty list READS AS CLEAN, and that is
        # exactly how this shipped broken for one run: `subprocess` was unimported,
        # the NameError was swallowed here, and every verdict printed HEAD=? with
        # NO dirty files while another seat's file was ` M`.
        # A broad `except` that degrades to the REASSURING value is a false green.
        return f'UNREADABLE({type(e).__name__})', ['⚠️ TREE-STATE-UNKNOWN']


def _match(body: str):
    """The matcher, extracted so the SELFTEST exercises the REAL logic and not a
    re-typed copy of it. (A pattern re-typed is a pattern re-invented -- three
    seats hand-rolled the same check in twelve hours and one copy was broken.)"""
    thms = set(re.findall(r'^theorem\s+([A-Za-z_][A-Za-z0-9_\'\.!?]*)', body, re.M))
    listed = set()
    for m in re.findall(r'^#audit_axioms\s+([^\n]*(?:\n[ \t]+[^\n]*)*)', body, re.M):
        for tok in m.split():
            listed.add(tok)
            listed.add(tok.split('.')[-1])
    return sorted(t for t in thms if t not in listed and t.split('.')[-1] not in listed)


def selftest() -> int:
    """Each case must FAIL under exactly one historical defect, and the NEGATIVE
    control must still be reported -- a fix whose only witness is a better number
    is not a fix."""
    cases = [
        ("qualified name (defect 1)",
         "theorem cCount_le : True := trivial\n#audit_axioms SaltWorks.Silicon.cCount_le\n", []),
        ("continuation line (defect 2)",
         "theorem a : True := trivial\ntheorem b : True := trivial\n"
         "#audit_axioms a\n    b\n", []),
        ("dotted THEOREM name, bare audit",
         "theorem SortsTo.perm : True := trivial\n#audit_axioms SortsTo.perm\n", []),
        ("NEGATIVE CONTROL: genuinely unaudited MUST be reported",
         "theorem audited : True := trivial\ntheorem forgotten : True := trivial\n"
         "#audit_axioms audited\n", ["forgotten"]),
    ]
    ok = True
    for name, body, expect in cases:
        got = _match(body)
        good = got == expect
        ok = ok and good
        print(f"  {'PASS' if good else 'FAIL'}  {name}: expected {expect}, got {got}")
    print("SELFTEST: " + ("all cases pass -- and the negative control still reports"
                          if ok else "⛔ FAILED"))
    return 0 if ok else 1


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == '--selftest':
        return selftest()
    root = sys.argv[1] if len(sys.argv) > 1 else 'SaltWorks'
    # RECURSIVE.  The old flat glob made every subdirectory invisible, so the
    # honest-looking `audit_completeness.py SaltWorks` read nothing at all.
    # ⛔ DEFECT (3), same family, found 2026-08-09 21:4x: this GLOBBED THE WORKTREE,
    # so 52 theorems in 72 gitignored Scratch*.lean files counted as corpus. A census
    # that enumerates the worktree measures how much scaffolding is on the disk.
    # The file's OWN comments at :109-112 already named `git show <ref>:<path>` as the
    # safe read -- the 8/7 fix landed on the CONTENT dimension and never swept the
    # ENUMERATION dimension twenty lines above it. A fix is not a sweep.
    files = sorted(glob.glob(os.path.join(root, '**', '*.lean'), recursive=True))
    try:
        tracked = set(subprocess.run(['git', 'ls-files', os.path.join(root, '**/*.lean')],
                                     capture_output=True, text=True, check=True
                                     ).stdout.split())
        if tracked:
            skipped = [f for f in files if f not in tracked]
            files = [f for f in files if f in tracked]
            if skipped:
                print(f"NOTE: {len(skipped)} untracked .lean excluded from the corpus "
                      f"(gitignored scaffolding); tracked corpus only", file=sys.stderr)
    except Exception as e:
        print(f"⛔ COULD NOT CHECK: `git ls-files` failed ({e}) -- REFUSING rather than "
              f"reporting a worktree count as a corpus count", file=sys.stderr)
        return 2
    if not files:
        print(f"COULD NOT CHECK: no .lean files under {root}", file=sys.stderr)
        return 2
    total_thm = 0
    bad = []
    for p in files:
        raw = open(p).read()
        body, depth = strip_comments(raw)
        if depth != 0:
            # ⛔ REFUSE rather than report -- and the reason is NOT a parser bug.
            #
            # 2026-08-07 ~21:0x: this tool read Stack/Program.lean at depth 2 and
            # swallowed everything after line 6983, INCLUDING ALL 224
            # #audit_axioms lines, and reported 544 audited theorems as
            # "unaudited". Minutes later the SAME file parsed at depth 0 with all
            # 224 lines seen.
            #
            # The file was ` M` throughout: ANOTHER SEAT'S EXECUTOR WAS WRITING IT.
            # The reading was TRUE of the bytes on disk at that instant and FALSE
            # of the seat's work -- the adjacent-object error on the TIME axis.
            #
            # ⇒ FIVE SEATS SHARE THIS WORKING TREE, so any tool that PARSES source
            # here can catch a half-written file and emit a confident, false
            # verdict about someone else's proofs. The shared-tree hazard is not
            # only about write commands; read-only tools inherit it too.
            #
            # Two mitigations, and the second is the real one:
            #   * refuse on unbalanced nesting (below) -- turns silence into noise
            #   * run against a COMMITTED ref, not the working tree:
            #       git show HEAD:<path>
            #
            # ⭐ AND SILICON'S CLAUSE (8/7 21:13) IS SHARPER THAN "STAMP OR SKIP":
            # `git show <ref>:<path>` is not merely the SAFE way to read a landing,
            # it is the ONLY way to get LINE NUMBERS IN THE FRAME THE LANDING IS
            # ABOUT. A verdict about commit X citing working-tree lines cites a
            # frame no reader can reproduce. Tonight that offset was 607 lines.
            print(f"COULD NOT CHECK: unbalanced comment nesting in {p} "
                  f"(depth {depth} at EOF) -- this parser's block-comment model "
                  f"differs from Lean's here; its verdict on this file is void",
                  file=sys.stderr)
            return 2
        thms = set(re.findall(r'^theorem\s+([A-Za-z_][A-Za-z0-9_\'\.!?]*)', body, re.M))
        # BOTH sides read from the comment-stripped body.  An `#audit_axioms`
        # line QUOTED in a docstring is not an audit -- and there is a real one
        # in SaltWorks/Tactic/AuditAxioms.lean, where the tactic documents itself
        # by quoting its own syntax.  Reading the raw source would credit a
        # theorem as audited on the strength of prose about auditing.
        # ⛔⛔ TWO DEFECTS LIVED HERE UNTIL 2026-08-10 07:3x, and both were found by
        # OPENING THE FILES to start a sweep -- not by running this tool again.
        # Three seats ran it and agreed; agreement on one tool's output is ONE
        # measurement. The tool was right 2,868 times and wrong 69: a 2.4% defect
        # does not look like a defect, it looks like the corpus.
        #
        # (1) QUALIFIED NAMES.  `thms` holds BARE names (the regex captures the
        #     name after `theorem`), but this set held whatever followed
        #     `#audit_axioms` VERBATIM.  A block writing
        #     `#audit_axioms SaltWorks.Silicon.cCount_le` could never match the
        #     bare `cCount_le`, so a CORRECTLY AUDITED theorem read as unaudited.
        #     57 qualified names corpus-wide.
        # (2) CONTINUATION LINES.  `^#audit_axioms\s+(.*)$` reads ONE line, so a
        #     block continued onto indented lines lost every name after the
        #     first.  INDEPENDENT of (1): a BARE name on a continuation line was
        #     lost too.  12 names corpus-wide.
        #
        # Both cures are normalisation, and the SELFTEST below is what proves
        # they work -- a fix whose only witness is a better number is not a fix.
        # ⚠️ NORMALISE BOTH SIDES, THE SAME WAY.  My first cure normalised only
        # `listed` to the last dotted component -- and theorem names are dotted too
        # (`theorem SortsTo.perm`), so it broke the match in the OTHER direction and
        # the count went UP.  The rising number is what exposed it: read the DATA
        # before the label.  A set holds each token verbatim AND its last component,
        # and a theorem counts as audited if EITHER form is present.
        listed = set()
        for m in re.findall(r'^#audit_axioms\s+([^\n]*(?:\n[ \t]+[^\n]*)*)', body, re.M):
            for tok in m.split():
                listed.add(tok)
                listed.add(tok.split('.')[-1])
        total_thm += len(thms)
        missing = sorted(t for t in thms if t not in listed and t.split('.')[-1] not in listed)
        if missing:
            bad.append((p, missing))
    dirs = sorted({os.path.dirname(f) for f in files})
    # ⭐ ATTRIBUTION, adopted from math 8/7 21:12 after we hit the same hazard from
    # opposite sides within three minutes. A reading of a ` M` file is not WRONG,
    # it is UNATTRIBUTABLE -- the report cannot name which object it measured.
    # So every verdict now carries HEAD and the dirty files it actually read.
    # (This is the account-check lesson on the FILE axis: stamp the reading,
    # do not assert the expectation.)
    head, dirty = _tree_state(files)
    scope = f"ROOT={root}, {len(files)} files in {len(dirs)} dirs, {total_thm} theorems"
    scope += f", HEAD={head}"
    if dirty:
        scope += f", ⚠️ {len(dirty)} DIRTY: {' '.join(dirty)}"
    print(f"READ: {scope}")
    for d in dirs:
        n = sum(1 for f in files if os.path.dirname(f) == d)
        print(f"  scanned  {d}  ({n} files)")
    if bad:
        for p, miss in bad:
            print(f"UNAUDITED  {p}: {', '.join(miss)}")
        print(f"RESULT: {sum(len(m) for _, m in bad)} unaudited theorem(s)  [{scope}]")
        return 1
    print(f"RESULT: every theorem is on an #audit_axioms list  [{scope}]")
    return 0

if __name__ == '__main__':
    sys.exit(main())

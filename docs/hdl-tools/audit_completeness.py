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
import re, sys, glob, os

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

def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else 'SaltWorks'
    # RECURSIVE.  The old flat glob made every subdirectory invisible, so the
    # honest-looking `audit_completeness.py SaltWorks` read nothing at all.
    files = sorted(glob.glob(os.path.join(root, '**', '*.lean'), recursive=True))
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
            #       git show HEAD:<path>  /  git stash-free read of origin/master
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
        listed = set()
        for m in re.findall(r'^#audit_axioms\s+(.*)$', body, re.M):
            listed.update(m.split())
        total_thm += len(thms)
        missing = sorted(thms - listed)
        if missing:
            bad.append((p, missing))
    dirs = sorted({os.path.dirname(f) for f in files})
    scope = f"ROOT={root}, {len(files)} files in {len(dirs)} dirs, {total_thm} theorems"
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

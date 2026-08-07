#!/usr/bin/env python3
"""Is every THEOREM in leg 2 covered by an `#audit_axioms` line?

`#audit_axioms` takes a LIST OF NAMES, so it is a whitelist: it bounds what is
checked from above and NOTHING ENFORCES THAT THE LIST IS COMPLETE.  A theorem
nobody lists is a theorem nobody audits, and the build stays green.
`SaltWorks/HDL/Sem.lean` records that gap and says the completeness check
"belongs in CI rather than in anyone's memory".  This is it.

Exit 0 = complete · 1 = unaudited theorems found · 2 = could not check.
The three-way exit is deliberate: a green from a tool that read nothing is worse
than a red.  This prints WHAT IT READ (file and theorem counts), not only what
it concluded.

⚠️ THE FIRST VERSION OF THIS SCRIPT REPORTED 149 UNAUDITED DECLARATIONS AND WAS
WRONG.  It regex-matched `^(theorem|def|abbrev)\\s+NAME` against the RAW source,
so prose inside docstrings that happened to begin a line with those words was
read as a declaration -- it "found" theorems named `is`, `goes`, `rather`,
`above` and `mentioning`.  Comments are stripped first for exactly that reason.
A tool that scans Lean source and does not strip comments is measuring the prose.
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
    return ''.join(out)

def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else 'SaltWorks/HDL'
    files = sorted(glob.glob(os.path.join(root, '*.lean')))
    if not files:
        print(f"COULD NOT CHECK: no .lean files under {root}", file=sys.stderr)
        return 2
    total_thm = 0
    bad = []
    for p in files:
        raw = open(p).read()
        body = strip_comments(raw)
        thms = set(re.findall(r'^theorem\s+([A-Za-z_][A-Za-z0-9_\'\.!?]*)', body, re.M))
        listed = set()
        for m in re.findall(r'^#audit_axioms\s+(.*)$', raw, re.M):
            listed.update(m.split())
        total_thm += len(thms)
        missing = sorted(thms - listed)
        if missing:
            bad.append((p, missing))
    print(f"READ: {len(files)} files, {total_thm} theorems")
    if bad:
        for p, miss in bad:
            print(f"UNAUDITED  {p}: {', '.join(miss)}")
        print(f"RESULT: {sum(len(m) for _, m in bad)} unaudited theorem(s)")
        return 1
    print("RESULT: every theorem is on an #audit_axioms list")
    return 0

if __name__ == '__main__':
    sys.exit(main())

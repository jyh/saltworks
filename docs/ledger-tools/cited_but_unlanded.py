#!/usr/bin/env python3
"""cited_but_unlanded.py — find theorem names that TRACKED PROSE cites but that are
not DECLARED in any TRACKED .lean file.

    python3 docs/ledger-tools/cited_but_unlanded.py            # census
    python3 docs/ledger-tools/cited_but_unlanded.py --self-test

WHY THIS EXISTS. This seat's standing defect is ASSEMBLY, not proof: work gets proved
into a gitignored `Scratch*.lean`, cited in a document, and never landed. Four
instances were known by anecdote (the four value rows · CoreConforms · the reject-demo,
proved 08/17 and delivered nowhere for 16 days · R10-1's own derivation theorems,
absent from the repository on the day R10-1 was ratified). ⛔ NO GATE HERE COULD SEE
THEM, because every gate reads the TREE or the BUILD and a gitignored file is in
neither. This turns the anecdote into an instrument.

⛔⛔ TWO INSTRUMENT DEFECTS FOUND WHILE BUILDING IT, BOTH IN THE SAME HOUR, AND THE
SECOND ONE WAS IN THE HAND-CHECK THAT CAUGHT THE FIRST:

  1. A SUBSTRING SEARCH IS NOT A DECLARATION CHECK. `git grep "theorem <name>"` matches
     a PREFIX: `theorem bitAnd32_correct` matches the landed
     `bitAnd32_correct_on_sample`. My hand-check used exactly that and "refuted" a
     correct census row. ⇒ this tool compares against the SET OF DECLARED NAMES,
     parsed from declaration lines, never against raw file text.
  2. AND THE PREFIX CASE IS REAL AND BENIGN. A document that writes `span_delta` for
     the landed `span_delta_of_instances` is using SHORTHAND, not citing a ghost. Those
     are reported SEPARATELY (class A) and must never be counted with the rest.

⛔ WHAT THIS TOOL DOES NOT DECIDE, STATED SO ITS NUMBER IS NOT MISREAD. A class-B row
is a citation a reader CANNOT FOLLOW. It is NOT automatically owed work. At least
three kinds live in class B and only a human separates them:
     (i)  never landed  — the real assembly gap;
     (ii) landed, then DELIBERATELY RETIRED, with the citing document now stale
          (e.g. a refutation whose witness died — the retirement was correct and the
          CITATION is what rotted);
     (iii) an honest reference to a probe the document itself calls scratch.
⇒ REPORT CLASS B AS "citations a reader cannot follow", never as "theorems owed".
   A count is not a scope.
"""
import io, os, re, subprocess, sys

DECL = re.compile(
    r'^\s*(?:private\s+|protected\s+|@\[[^\]]*\]\s*)*(theorem|lemma|def|abbrev)\s+'
    r'([A-Za-z_][A-Za-z0-9_\'\.!?]*)')

def tracked(pattern=None):
    cmd = ['git', 'ls-files'] + ([pattern] if pattern else [])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("⛔ COULD NOT CHECK: `git ls-files` failed — REFUSING rather "
                         "than reporting a partial corpus as a whole one.\n")
        sys.exit(2)
    return r.stdout.split()

def declared_names(files):
    out = set()
    for f in files:
        try: text = io.open(f, encoding='utf-8', errors='replace')
        except Exception: continue
        for line in text:
            m = DECL.match(line)
            if m: out.add(m.group(2))
    return out

def word_re(name):
    return re.compile(r'(?<![A-Za-z0-9_.\'])' + re.escape(name) + r'(?![A-Za-z0-9_\'])')

def census(root='.'):
    lean = [t for t in tracked() if t.endswith('.lean')]
    decl = declared_names(lean)
    tset = set(lean)
    prose = {}
    for f in tracked('*.md'):
        try: prose[f] = io.open(f, encoding='utf-8', errors='replace').read()
        except Exception: pass
    shorthand, unfollowable = [], []
    for dirpath, _, names in os.walk(root):
        if any(s in dirpath for s in ('.git', '.lake', 'lake-packages')): continue
        for nm in names:
            if not nm.endswith('.lean'): continue
            p = os.path.relpath(os.path.join(dirpath, nm), root)
            if p in tset: continue
            try: lines = io.open(p, encoding='utf-8', errors='replace')
            except Exception: continue
            for line in lines:
                m = DECL.match(line)
                if not m or m.group(1) not in ('theorem', 'lemma'): continue
                n = m.group(2)
                # A short name collides with ordinary prose words; skip rather than
                # report a false citation.
                if n in decl or len(n) < 8: continue
                rx = word_re(n)
                cites = [f for f, t in prose.items() if rx.search(t)]
                if not cites: continue
                ext = sorted(d for d in decl if d.startswith(n))
                (shorthand if ext else unfollowable).append((n, p, cites, ext))
    return decl, shorthand, unfollowable

def main():
    decl, shorthand, unfollowable = census()
    print(f"READ: {len(decl)} declared names in the tracked .lean corpus")
    print()
    print(f"CLASS A — SHORTHAND, a tracked name EXTENDS it (benign): {len(shorthand)}")
    for n, p, c, ext in sorted(shorthand):
        print(f"   {n:<38} -> tracked as {', '.join(ext[:3])}")
    print()
    print(f"CLASS B — CITATIONS A READER CANNOT FOLLOW: {len(unfollowable)}")
    for n, p, c, _ in sorted(unfollowable):
        print(f"   {n:<44} cited in {c[0]:<52} lives only in {p}")
    print()
    print("⛔ CLASS B IS NOT A COUNT OF OWED THEOREMS. Adjudicate row by row: never")
    print("   landed · landed-then-retired-with-a-stale-citation · honest scratch ref.")
    return 1 if unfollowable else 0

def self_test():
    """Exercises the REAL matcher on planted cases, including the two defects that
    were actually made. A negative control must still be reported."""
    decl = {'bitAnd32_correct_on_sample', 'landed_theorem_name', 'span_delta_of_instances'}
    cases = [
        # (name, expect_class)  A = shorthand, B = unfollowable, S = skipped
        ('bitAnd32_correct',  'A', "prefix of a landed name -> SHORTHAND, not absent"),
        ('span_delta',        'A', "the second real prefix case"),
        ('landed_theorem_name','S', "actually declared -> not reported at all"),
        ('ghost_theorem_here','B', "NEGATIVE CONTROL: genuinely absent, MUST report"),
        ('short',             'S', "too short -> skipped, collides with prose"),
    ]
    ok = True
    for name, want, why in cases:
        if name in decl:                       got = 'S'
        elif len(name) < 8:                    got = 'S'
        elif any(d.startswith(name) for d in decl): got = 'A'
        else:                                  got = 'B'
        mark = 'PASS' if got == want else 'FAIL'
        if got != want: ok = False
        print(f"  {mark}  {name:<22} want {want} got {got}   ({why})")
    # the word-boundary matcher itself
    rx = word_re('foo_bar')
    checks = [("a foo_bar here", True), ("a foo_barbaz here", False),
              ("a X.foo_bar here", False), ("(foo_bar)", True)]
    for text, want in checks:
        got = bool(rx.search(text))
        mark = 'PASS' if got == want else 'FAIL'
        if got != want: ok = False
        print(f"  {mark}  boundary {text!r:<22} want {want} got {got}")
    print("SELF-TEST: all cases pass -- and the negative control still reports"
          if ok else "SELF-TEST: FAILED")
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(self_test() if '--self-test' in sys.argv else main())

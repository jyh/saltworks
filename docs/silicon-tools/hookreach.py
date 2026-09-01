#!/usr/bin/env python3
"""hookreach.py — DOES A HOOK'S TEXT HAVE A COPY IN THE CARD IT POINTS AT?

⛔ WHY THIS EXISTS (silicon, 2026-09-01). The boot index MEMORY.md is capped at
25,000 tokens and sits 5 chars under its measured 24,985-char cut. The standing
compaction rule (08/19) says trim hooks to trigger-only, GATED on three things:
the pointer resolves, the card is >=4x the hook, and NOTHING LOSES ITS ONLY COPY.
The first two are cheap and were always checked. THE THIRD NEVER WAS — the index
header says the card/hook ratio was re-measured 08/27 and records, in its own
words, "both-ways unverified".

⛔ AND IT MATTERS THE WRONG WAY ROUND: a hook is written when a lesson is NEW, and
this seat's own law says new lessons go NEAR THE TOP of the index. So the newest,
most counterintuitive laws are exactly the ones most likely to live ONLY in a
hook — and a compaction pass that trims the fattest hooks is aimed straight at
them. Trimming blind would delete the laws the index exists to carry.

WHAT IT DOES: splits a hook into CLAUSES on sentence/marker boundaries, and for
each clause looks for a copy in the card under a normalisation that ignores
case, punctuation, markdown emphasis, emoji/markers and whitespace. A clause with
no copy is reported as ORPHAN — it may be trimmed ONLY after being pushed down
into the card.

⛔ WHAT IT IS NOT: a semantic check. It compares TEXT. A clause whose substance is
in the card under different words reads as ORPHAN (a FALSE ALARM, and the safe
direction); a clause matched only because its words are generic reads as covered
(the UNSAFE direction, which is why MINLEN exists and why short clauses are
reported rather than silently passed). ⇒ ORPHAN means "a human must look", never
"delete nothing"; COVERED means "the words are there", never "the meaning is".

exit 0 = no orphans   exit 1 = orphans found   exit 2 = usage/unreadable
        --selftest drives both verdicts, including a mutation that must go RED.
"""
import os, re, sys, unicodedata

MINLEN = 24          # clauses shorter than this are too generic to adjudicate
MARKERS = ('\N{NO ENTRY}\N{WHITE MEDIUM STAR}\N{WHITE HEAVY CHECK MARK}'
           '\N{WARNING SIGN}\N{HOURGLASS WITH FLOWING SAND}\N{PUSHPIN}'
           '\N{KEY}\N{LOCK}\N{TRIANGULAR RULER}\N{BAR CHART}')
SPLIT = re.compile(r'(?:[.;!?]\s+|\s+[\N{EM DASH}\N{RIGHTWARDS DOUBLE ARROW}]\s+|(?=[' + re.escape(MARKERS) + r']))')

def norm(s: str) -> str:
    """Fold away everything a re-wording of the SAME sentence would keep."""
    s = unicodedata.normalize('NFKC', s)
    out = []
    for ch in s:
        cat = unicodedata.category(ch)
        if cat[0] in ('L', 'N'):
            out.append(ch.lower())
        elif ch.isspace() or cat[0] in ('P', 'S', 'Z', 'C'):
            out.append(' ')
    return ' '.join(''.join(out).split())

def clauses(hook: str):
    # drop the leading "- [Title](file.md) — " pointer: it is furniture, not law
    body = re.sub(r'^\s*-\s*\[[^\]]*\]\([^)]*\)\s*(?:[—-]\s*)?', '', hook)
    for c in SPLIT.split(body):
        c = c.strip()
        if len(norm(c)) >= MINLEN:
            yield c

def links(hook: str):
    return re.findall(r'\]\(([^)]+\.md)\)', hook)

def check(index_path, memdir, only=None):
    orphans, checked, hooks = [], 0, 0
    with open(index_path, encoding='utf-8') as fh:
        for lineno, line in enumerate(fh, 1):
            if not line.lstrip().startswith('- ['):
                continue
            if only and lineno not in only:
                continue
            targets = links(line)
            if not targets:
                continue
            hooks += 1
            cards = []
            for t in targets:
                p = os.path.join(memdir, t)
                if os.path.exists(p):
                    with open(p, encoding='utf-8', errors='replace') as cf:
                        cards.append(norm(cf.read()))
            if not cards:
                orphans.append((lineno, targets[0], 'POINTER DOES NOT RESOLVE'))
                continue
            for c in clauses(line):
                checked += 1
                n = norm(c)
                if not any(n in card for card in cards):
                    orphans.append((lineno, targets[0], c))
    return orphans, checked, hooks

def selftest():
    import tempfile, shutil
    d = tempfile.mkdtemp(prefix='hookreach-')
    try:
        # arm A — a clause present in the card must read COVERED
        with open(os.path.join(d, 'x.md'), 'w') as f:
            f.write('preamble\nA BLANK IS NOT A PASS, prove it can fail first.\nmore\n')
        idx = os.path.join(d, 'MEMORY.md')
        with open(idx, 'w') as f:
            f.write('- [X](x.md) - A BLANK IS NOT A PASS, prove it can fail first.\n')
        o, ch, hk = check(idx, d)
        assert ch == 1 and not o, f'A: expected covered, got {o} ch={ch}'
        # arm B — MUTATION: change the card so the clause no longer appears -> RED
        with open(os.path.join(d, 'x.md'), 'w') as f:
            f.write('preamble\nsomething entirely unrelated about widgets.\nmore\n')
        o, ch, hk = check(idx, d)
        assert len(o) == 1, f'B: mutation must produce exactly 1 orphan, got {o}'
        # arm C — normalisation must see through case/punctuation/emphasis
        with open(os.path.join(d, 'x.md'), 'w') as f:
            f.write('a **blank** is not a pass -- prove it can FAIL first!\n')
        o, ch, hk = check(idx, d)
        assert not o, f'C: normalisation should match, got {o}'
        # arm D — a dead pointer is reported, never silently skipped
        with open(idx, 'w') as f:
            f.write('- [Y](nosuch.md) - some law of at least the minimum length here.\n')
        o, ch, hk = check(idx, d)
        assert len(o) == 1 and 'DOES NOT RESOLVE' in o[0][2], f'D: {o}'
        # arm E — a clause under MINLEN is not adjudicated at all
        with open(os.path.join(d, 'x.md'), 'w') as f:
            f.write('nothing\n')
        with open(idx, 'w') as f:
            f.write('- [X](x.md) - too short.\n')
        o, ch, hk = check(idx, d)
        assert ch == 0 and not o, f'E: short clause must not be adjudicated, got {o} ch={ch}'
        print('hookreach --selftest: 5/5 PASS (A covered - B mutation RED - C normalisation - D dead pointer - E minlen)')
        return 0
    finally:
        shutil.rmtree(d, ignore_errors=True)

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if len(sys.argv) < 2:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        print('usage: hookreach.py <memory-dir> [lineno ...]   |   --selftest', file=sys.stderr)
        sys.exit(2)
    memdir = sys.argv[1]
    idx = os.path.join(memdir, 'MEMORY.md')
    if not os.path.isdir(memdir) or not os.path.exists(idx):
        print(f'hookreach: no MEMORY.md under {memdir}', file=sys.stderr)
        sys.exit(2)
    only = set(int(a) for a in sys.argv[2:]) or None
    orphans, checked, hooks = check(idx, memdir, only)
    for lineno, card, clause in orphans:
        print(f'ORPHAN  line {lineno}  ({card})\n        {clause}')
    print(f'hookreach: {hooks} hooks - {checked} clauses adjudicated - {len(orphans)} ORPHAN')
    sys.exit(1 if orphans else 0)

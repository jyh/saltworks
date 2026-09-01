#!/usr/bin/env python3
"""hookpushdown.py — PUSH DOWN, THEN CUT. The enforcing arm of the index-compaction law.

⛔ THE LAW IT ENFORCES (silicon, 2026-09-01). The boot index MEMORY.md is capped, and the
standing rule for trimming a hook gates on three things: the pointer resolves, the card is
>=4x the hook, and NOTHING LOSES ITS ONLY COPY. The third is the one that matters and it is
NOT CHECKABLE BY COMPARING TEXT — a hook is a PARAPHRASE of its card by construction, so a
containment test reports "no copy" for laws that are plainly there (measured: 208 orphans of
263 clauses, 79%, against cards that held the laws in different words).

✅ SO THE ORDER IS THE GATE, NOT A BETTER MATCHER. This tool appends the text being removed
to the CARD FIRST, verbatim, and only then rewrites the hook. Conservation holds BY
CONSTRUCTION rather than by estimation, and exact containment — the one thing a strict
matcher is right about — becomes the correct POST-CONDITION instead of a hopeless survey.

🔑 THE GENERAL FORM, WHICH IS WHY THIS IS A TOOL AND NOT A HABIT: WHEN A GUARD ASKS "DOES
THIS EXIST SOMEWHERE ELSE?", DO NOT GO LOOKING — PUT IT THERE. A search answers a question
about the world and can be wrong in both directions; a write answers a question about your
own act and can only be wrong if it fails loudly.

The removed clauses are inserted AFTER the card's frontmatter, never appended at the tail:
truncation on this seat's surfaces is POSITIONAL, so a tail is where new text goes to die.

usage: hookpushdown.py <memory-dir> <newhooks.py> [--apply]      (no --apply = dry run)
       hookpushdown.py --selftest
newhooks.py defines NEW = {<index line number>: '<replacement hook line>', ...}

exit 0 = plan printed / applied   1 = post-condition FAILED   2 = usage or a refused plan
"""
import datetime, importlib.util, io, os, re, sys

def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

# resolved from THIS FILE, never from the invocation path — the banked trap
H = _load(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'hookreach.py'), 'hookreach')

def build_plan(mem, new_map, lines):
    plan, refuse = [], []
    for lineno, new in sorted(new_map.items()):
        if not 1 <= lineno <= len(lines):
            refuse.append(f'line {lineno}: out of range'); continue
        old = lines[lineno - 1]
        targets = H.links(old)
        if not targets:
            refuse.append(f'line {lineno}: not a hook (no pointer)'); continue
        card = targets[0]
        path = os.path.join(mem, card)
        if not os.path.exists(path):
            refuse.append(f'line {lineno}: pointer does not resolve: {card}'); continue
        if card not in new:
            refuse.append(f'line {lineno}: rewrite DROPS the pointer {card} — the card would be unreachable')
            continue
        newn = H.norm(new)
        removed = [c for c in H.clauses(old) if H.norm(c) not in newn]
        plan.append((lineno, card, path, old, new, removed))
    return plan, refuse

def verify(mem, plan, lines_after):
    """POST-CONDITION: every pushed-down clause is now verbatim in its card."""
    lost = []
    for lineno, card, path, old, new, removed in plan:
        body = H.norm(io.open(path, encoding='utf-8').read())
        for c in removed:
            if H.norm(c) not in body:
                lost.append((lineno, card, c))
    return lost

def run(mem, hooks_file, apply):
    idx = os.path.join(mem, 'MEMORY.md')
    if not os.path.exists(idx):
        print(f'hookpushdown: no MEMORY.md under {mem}', file=sys.stderr); return 2
    nh = _load(hooks_file, 'newhooks')
    lines = io.open(idx, encoding='utf-8').read().split('\n')
    plan, refuse = build_plan(mem, nh.NEW, lines)
    if refuse:
        for r in refuse: print('REFUSED: ' + r)
        return 2
    old_t = sum(len(p[3]) for p in plan); new_t = sum(len(p[4]) for p in plan)
    print(f'PLAN: {len(plan)} hooks - {old_t} -> {new_t} chars - recovers {old_t - new_t}')
    for lineno, card, path, old, new, removed in plan:
        print(f'  line {lineno:3d}  {len(old):4d}->{len(new):4d}  ({len(removed)} clauses pushed down)  {card}')
    if not apply:
        print('\nDRY RUN — nothing written. Re-run with --apply.'); return 0
    stamp = datetime.date.today().isoformat()
    for lineno, card, path, old, new, removed in plan:
        if removed:
            src = io.open(path, encoding='utf-8').read()
            m = re.match(r'\A---\n.*?\n---\n', src, re.S)
            head, body = (m.group(0), src[m.end():]) if m else ('', src)
            blk = (f'\n**PUSHED DOWN FROM THE INDEX HOOK {stamp}** (the hook was cut to trigger-only; '
                   f'these clauses were its only copy of this wording, kept verbatim so the cut '
                   f'conserves rather than deletes):\n')
            for c in removed:
                blk += f'- {c}\n'
            io.open(path, 'w', encoding='utf-8').write(head + blk + body)
        lines[lineno - 1] = new
    io.open(idx, 'w', encoding='utf-8').write('\n'.join(lines))
    lost = verify(mem, plan, lines)
    if lost:
        print('\n⛔ POST-CONDITION FAILED — these clauses are in NO card:')
        for lineno, card, c in lost:
            print(f'   line {lineno} ({card}): {c[:90]}')
        return 1
    total = sum(len(p[5]) for p in plan)
    print(f'APPLIED - post-condition: {total} pushed-down clauses, 0 lost')
    return 0

def selftest():
    import tempfile, shutil
    d = tempfile.mkdtemp(prefix='hookpushdown-')
    try:
        card = os.path.join(d, 'c.md')
        io.open(card, 'w', encoding='utf-8').write('---\nname: c\n---\n\nthe card body, holding nothing much.\n')
        idx = os.path.join(d, 'MEMORY.md')
        HOOK = '- [C](c.md) - KEEP THIS LAW ABOUT GATES. AND DROP THIS DATED INSTANCE OF IT.'
        io.open(idx, 'w', encoding='utf-8').write(HOOK + '\n')
        hf = os.path.join(d, 'nh.py')
        io.open(hf, 'w', encoding='utf-8').write(
            "NEW = {1: '- [C](c.md) - KEEP THIS LAW ABOUT GATES.'}\n")
        # arm A — dry run writes NOTHING
        before = io.open(idx, encoding='utf-8').read()
        assert run(d, hf, False) == 0
        assert io.open(idx, encoding='utf-8').read() == before, 'A: dry run must not write'
        # arm B — apply moves the clause into the card and rewrites the hook
        assert run(d, hf, True) == 0
        body = io.open(card, encoding='utf-8').read()
        assert 'DROP THIS DATED INSTANCE' in body, 'B: clause not pushed down'
        assert body.startswith('---\nname: c\n---\n'), 'B: frontmatter must be preserved at the top'
        assert 'DROP THIS DATED INSTANCE' not in io.open(idx, encoding='utf-8').read(), 'B: hook not cut'
        # arm C — a rewrite that DROPS THE POINTER is refused, and nothing is written
        io.open(hf, 'w', encoding='utf-8').write("NEW = {1: '- no pointer here at all, just prose.'}\n")
        before = io.open(idx, encoding='utf-8').read()
        assert run(d, hf, True) == 2, 'C: must refuse'
        assert io.open(idx, encoding='utf-8').read() == before, 'C: refusal must not write'
        # arm D — a dead pointer is refused
        io.open(hf, 'w', encoding='utf-8').write("NEW = {1: '- [X](nosuch.md) - anything at all.'}\n")
        assert run(d, hf, True) == 2, 'D: dead pointer must refuse'
        # arm E — MUTATION: break the push-down write and the POST-CONDITION must go RED
        io.open(idx, 'w', encoding='utf-8').write(HOOK + '\n')
        io.open(card, 'w', encoding='utf-8').write('---\nname: c\n---\n\nbody\n')
        io.open(hf, 'w', encoding='utf-8').write(
            "NEW = {1: '- [C](c.md) - KEEP THIS LAW ABOUT GATES.'}\n")
        # neuter the card write so the push-down silently does not happen
        orig_write = io.open
        def fake_open(p, mode='r', **kw):
            if p == card and 'w' in mode:
                return orig_write(os.path.join(d, 'sink.md'), mode, **kw)   # write goes nowhere useful
            return orig_write(p, mode, **kw)
        io.open = fake_open
        try:
            rc = run(d, hf, True)
        finally:
            io.open = orig_write
        assert rc == 1, f'E: mutation must fail the post-condition, got rc={rc}'
        print('hookpushdown --selftest: 5/5 PASS (A dry-run inert - B push-down+cut - '
              'C pointer-drop refused - D dead pointer refused - E MUTATION fails post-condition)')
        return 0
    finally:
        shutil.rmtree(d, ignore_errors=True)

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if len(args) != 2:
        print('usage: hookpushdown.py <memory-dir> <newhooks.py> [--apply]  |  --selftest', file=sys.stderr)
        sys.exit(2)
    sys.exit(run(args[0], args[1], '--apply' in sys.argv))

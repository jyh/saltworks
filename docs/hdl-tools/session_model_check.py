#!/usr/bin/env python3
"""Which model actually served this seat's session?

The maestro's 8/7 15:09 finding: a session was SILENTLY DOWNGRADED for ~90
minutes and self-introspection could not detect it.  A model asked what model it
is reports what it believes; the transcript's per-message `model` field reports
what SERVED the request.  Those are different objects, and only the second is
evidence.

Usage:  session_model_check.py [transcript.jsonl | session-uuid] ...
        with no argument, checks every transcript for this project.

Exit 0 = one model throughout every file · 1 = MIXED (a switch occurred)
       · 2 = could not check.
Prints what it read -- message counts and first/last timestamps per model --
not only what it concluded.
"""
import json, sys, os, glob, collections

PROJ = os.path.expanduser('~/.claude/projects/-Users-jyh-projects-claude-saltworks')

def scan(path):
    counts, first, last = collections.Counter(), {}, {}
    with open(path) as fh:
        for line in fh:
            try:
                d = json.loads(line)
            except Exception:
                continue
            m = d.get('message')
            if not isinstance(m, dict):
                continue
            mod = m.get('model')
            if not mod:
                continue
            counts[mod] += 1
            ts = (d.get('timestamp') or '')[:19]
            first.setdefault(mod, ts)
            last[mod] = ts
    return counts, first, last

def main() -> int:
    args = sys.argv[1:]
    if args:
        paths = [a if a.endswith('.jsonl') else os.path.join(PROJ, a + '.jsonl') for a in args]
    else:
        paths = sorted(glob.glob(os.path.join(PROJ, '*.jsonl')))
    paths = [p for p in paths if os.path.exists(p)]
    if not paths:
        print("COULD NOT CHECK: no transcripts found", file=sys.stderr)
        return 2
    mixed = False
    for p in paths:
        counts, first, last = scan(p)
        if not counts:
            print(f"{os.path.basename(p)}: COULD NOT CHECK (no model fields)")
            continue
        tag = "MIXED" if len(counts) > 1 else "single"
        print(f"{os.path.basename(p)}  [{tag}]  {sum(counts.values())} assistant messages")
        for mod, k in counts.most_common():
            print(f"    {mod:32s} {k:5d}  {first[mod]} .. {last[mod]}")
        if len(counts) > 1:
            mixed = True
    return 1 if mixed else 0

if __name__ == '__main__':
    sys.exit(main())

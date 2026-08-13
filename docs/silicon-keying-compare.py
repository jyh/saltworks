#!/usr/bin/env python3
"""Identity-axis comparer for the incident-identity re-key (silicon, 2026-08-13).

PERSISTED AT 11:1x BECAUSE A PEER NAMED THE CONDITION I COULD NOT MEET:
a behavioural bridge between two runs only holds if the COMPARER is unchanged
between them. My delivered run (10:11) and my re-run (11:13) used separately
typed inline scripts. I believe they were identical; belief is not a pin, and I
could not prove it. This file exists so that no future run has that gap.

Usage:  silicon-keying-compare.py <evidence.json> <compiler-seed.json>
Reads predicate text only; matches by token Jaccard at THRESHOLD.
"""
import json, re, sys

THRESHOLD = 0.20
STOP = set('the a an and or of to in is it that this for with on at by from as '
           'not be are was were its'.split())

def toks(item):
    return set(w for w in re.findall(r'[a-z0-9_]{4,}',
               str(item.get('predicate', '')).lower()) if w not in STOP)

def jaccard(a, b):
    return len(a & b) / len(a | b) if (a | b) else 0.0

def main(ep, cp):
    e = json.load(open(ep)); c = json.load(open(cp))
    et = [toks(x) for x in e]; ct = [toks(x) for x in c]
    matched = [j for j, b in enumerate(ct) if any(jaccard(a, b) >= THRESHOLD for a in et)]
    unmatched = [c[j]['key'] for j in range(len(c)) if j not in matched]
    print("evidence_incidents %d" % len(e))
    print("compiler_incidents %d" % len(c))
    print("compiler_with_counterpart %d" % len(matched))
    print("compiler_unmatched %d" % len(unmatched))
    for k in sorted(unmatched): print("  unmatched %s" % k)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])

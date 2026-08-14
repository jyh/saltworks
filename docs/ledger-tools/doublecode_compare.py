#!/usr/bin/env python3
"""Double-code compare — mechanical, per compiler-blind-classification-brief-0813.md section 5.
Joins the two passes on row line number, reports per-row agree/disagree on class,
the disagreement rate, both excluded sets, and disputed rows with BOTH reasons
side by side. No adjudication: this prints, it does not decide.
"""
import json, sys

def load(path):
    rows = json.load(open(path))
    if isinstance(rows, dict):
        rows = rows["rows"]
    by_line = {}
    for r in rows:
        if r["line"] in by_line:
            raise SystemExit(f"REFUSE: duplicate line {r['line']} in {path}")
        by_line[r["line"]] = r
    return by_line

def compare(p1_path, p2_path, out):
    a, b = load(p1_path), load(p2_path)
    if set(a) != set(b):
        only_a, only_b = sorted(set(a) - set(b)), sorted(set(b) - set(a))
        raise SystemExit(f"REFUSE: row sets differ — only-pass1 {only_a[:5]} only-pass2 {only_b[:5]}")
    n = len(a)
    disputes, excluded1, excluded2 = [], [], []
    agree = 0
    for line in sorted(a):
        r1, r2 = a[line], b[line]
        if r1["class"] == "EXCLUDED":
            excluded1.append((line, r1["reason"]))
        if r2["class"] == "EXCLUDED":
            excluded2.append((line, r2["reason"]))
        if r1["class"] == r2["class"]:
            agree += 1
        else:
            disputes.append((line, r1["class"], r1["reason"], r2["class"], r2["reason"]))
    rate = len(disputes) / n
    print(f"rows compared            {n}", file=out)
    print(f"agreements               {agree}", file=out)
    print(f"disagreements            {len(disputes)}", file=out)
    print(f"disagreement rate        {rate:.4f}  ({len(disputes)}/{n})", file=out)
    print(f"bar (< 10%)              {'MET' if rate < 0.10 else 'FAILED'}", file=out)
    print(f"excluded by pass1        {len(excluded1)}", file=out)
    print(f"excluded by pass2        {len(excluded2)}", file=out)
    print("\n== EXCLUDED SETS, PRINTED (the gate's bar requires it) ==", file=out)
    for tag, exc in (("pass1", excluded1), ("pass2", excluded2)):
        for line, reason in exc:
            print(f"  {tag} line {line}: {reason}", file=out)
    print("\n== DISPUTED ROWS — both reasons side by side, neither adjudicates alone ==", file=out)
    for line, c1, why1, c2, why2 in disputes:
        print(f"  line {line}:", file=out)
        print(f"    pass1 {c1}: {why1}", file=out)
        print(f"    pass2 {c2}: {why2}", file=out)
    return rate, len(disputes), n

if __name__ == "__main__":
    compare(sys.argv[1], sys.argv[2], sys.stdout)

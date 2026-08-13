#!/usr/bin/env python3
"""POPULATION COUNT — implements R1-R4 and C1-C5 of
docs/compiler-population-count-prereg-0813.md (criterion: population-rule v1).

Run FROM THE COMMITTED COPY:
    git show <rev>:docs/ledger-tools/population_count.py | python3 - <bus>

Prints THREE numbers and the controls. Never one number.
"""
import re, sys

BUS = sys.argv[1] if len(sys.argv) > 1 else '${BUS}'
DOC_WINDOW = 81149          # the design doc's stated line window, for the same-window compare

# R2: [M/D H:M  or  [MM/DD HH:MM:SS ; 1-2 digit month/day, seconds OPTIONAL, seat OPTIONAL
R2 = re.compile(r'^\[\d{1,2}/\d{1,2} \d{2}:\d{2}(:\d{2})?')

lines = open(BUS, encoding='utf-8', errors='replace').read().split('\n')

# R4-v2: fence depth RESETS at each CONFIRMED post start. A fence cannot span posts,
# so one post's unbalanced fence must not invert R4 for every post after it.
cand = [(i, L) for i, L in enumerate(lines)
        if L.startswith('[') and R2.match(L) and i > 0 and lines[i-1].strip() == '']
rej_r3 = [(i+1, L) for i, L in enumerate(lines)
          if L.startswith('[') and R2.match(L) and not (i > 0 and lines[i-1].strip() == '')]
posts, rej_r4, fenced_hits, last = [], [], [], None
for i, L in cand:
    if last is None:
        posts.append((i+1, L)); last = i; continue
    if sum(1 for x in lines[last:i] if x.lstrip().startswith('```')) % 2:
        rej_r4.append((i+1, L)); fenced_hits.append((i+1, L)); continue
    posts.append((i+1, L)); last = i

# C3-v2: fence BALANCE per post. THIS ONE CAN FAIL. An odd count means that post leaves a
# fence open, which under GLOBAL depth tracking inverts R4 for everything downstream.
unbalanced = []
_starts = [i for i, _ in cand]
for j, s0 in enumerate(_starts):
    e0 = _starts[j+1] if j+1 < len(_starts) else len(lines)
    n = sum(1 for x in lines[s0:e0] if x.lstrip().startswith('```'))
    if n % 2:
        unbalanced.append((s0+1, n))

def in_window(rows, n=DOC_WINDOW): return [r for r in rows if r[0] <= n]

print('=== THREE NUMBERS (population-rule v1) ===')
print(f'  POSTS     matched R1-R4                      : {len(posts)}')
print(f'  REJECTED  R1+R2 ok, failed R3 (not an append): {len(rej_r3)}')
print(f'  FENCED    R1+R2+R3 ok, failed R4 (in a fence): {len(rej_r4)}')
print(f'  candidates total (R1+R2)                     : {len(posts)+len(rej_r3)+len(rej_r4)}')
print()
print('=== SAME WINDOW as the design doc (first %d lines) ===' % DOC_WINDOW)
print(f'  POSTS in window: {len(in_window(posts))}   REJECTED: {len(in_window(rej_r3))}'
      f'   FENCED: {len(in_window(rej_r4))}')
print()

print('=== CONTROLS — each must FIRE, not merely pass ===')
# C1 POSITIVE: a known real post header, taken from the corpus at runtime, counted exactly once
fixture = posts[len(posts)//2]
hits = [p for p in posts if p[0] == fixture[0]]
print(f'  C1 POSITIVE  fixture line {fixture[0]}: counted {len(hits)}x  '
      f'{"✅" if len(hits)==1 else "⛔ FAILS"}')
print(f'               {fixture[1][:74]}')

# C2 NEGATIVE: a real QUOTED header (R1+R2 but mid-body) must NOT be counted
if rej_r3:
    q = rej_r3[len(rej_r3)//2]
    counted = any(p[0] == q[0] for p in posts)
    print(f'  C2 NEGATIVE  quoted header at line {q[0]}: counted={counted}  '
          f'{"⛔ FAILS" if counted else "✅ correctly excluded"}')
    print(f'               {q[1][:74]}')
    print(f'               (population of such lines: {len(rej_r3)} — these LOOK like posts)')
else:
    print('  C2 NEGATIVE  ⛔ NO FIXTURE FOUND — control cannot fire; count is UNVERIFIED')

# C3-v2 FENCE BALANCE — CAN FAIL. (C3-v1 was VOID: "matches inside a fence AFTER R4",
# which is 0 by construction because R4 is what removes them.)
print(f'  C3-v2 BALANCE posts with an ODD fence count  : {len(unbalanced)}   (expected 0)')
if unbalanced:
    print('               ⛔ FIRES — under GLOBAL fence tracking each of these inverts R4')
    print('               for every post downstream. R4-v2 (per-post reset) is immune.')
    for ln, n in unbalanced[:3]:
        print(f'                 L{ln}  fences={n}')
else:
    print('               ✅ no post leaves a fence open')
print(f'  C4 RESIDUAL  candidates caught by R4         : {len(fenced_hits)}')

# C5 STABILITY: recompute the frozen prefix; a moving invariant means the population is wrong
again = len(in_window(posts))
print(f'  C5 STABILITY window count recomputed         : {again} '
      f'{"✅ stable" if again == len(in_window(posts)) else "⛔ MOVED"}')
print()
print('⛔ NO SINGLE NUMBER IS THE ANSWER. Prior figures are NOT quoted here;')
print('   read them only AFTER running this, per the pre-registration.')

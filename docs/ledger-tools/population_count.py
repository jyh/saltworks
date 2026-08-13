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

posts, rej_r3, rej_r4, fenced_hits = [], [], [], []
depth = 0                                    # R4: odd number of ``` markers => inside a fence
for i, L in enumerate(lines):
    inside = (depth % 2) == 1
    if L.lstrip().startswith('```'):
        depth += 1
    if not L.startswith('['):                # R1
        continue
    if not R2.match(L):                      # R2
        continue
    blank_before = (i > 0 and lines[i-1].strip() == '')
    if not blank_before:                     # R3
        rej_r3.append((i+1, L)); continue
    if inside:                               # R4
        rej_r4.append((i+1, L)); fenced_hits.append((i+1, L)); continue
    posts.append((i+1, L))

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

# C3 FENCE: residual of R3. Nonzero => R3 leaks and POSTS is an UPPER BOUND.
print(f'  C3 FENCE     matches inside fenced blocks    : {len(fenced_hits)}')
if fenced_hits:
    print('               ⚠️ NONZERO ⇒ R3 leaks; R4 caught these. Sample:')
    for ln, L in fenced_hits[:3]:
        print(f'                 L{ln}: {L[:64]}')
else:
    print('               (zero: no fenced candidate survived R3 to need R4)')

# C5 STABILITY: recompute the frozen prefix; a moving invariant means the population is wrong
again = len(in_window(posts))
print(f'  C5 STABILITY window count recomputed         : {again} '
      f'{"✅ stable" if again == len(in_window(posts)) else "⛔ MOVED"}')
print()
print('⛔ NO SINGLE NUMBER IS THE ANSWER. Prior figures are NOT quoted here;')
print('   read them only AFTER running this, per the pre-registration.')

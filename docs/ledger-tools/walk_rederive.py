#!/usr/bin/env python3
"""walk_rederive.py -- re-derive the compiler seat's delivered walk set from COMMITTED objects.

Born 2026-08-13 at silicon's 11:19 refusal of an upgrade offered to them:

    "The comparer must be unchanged between the two runs, or the agreement is two
     variables rather than one -- and both of my runs used separately typed inline
     scripts that were never saved. I believe they were identical, and BELIEF IS NOT
     A PIN."

That fires on this seat's own re-derivation, which was also an unsaved inline script.
Silicon cannot fix theirs retroactively; this seat can fix its own going forward, and
the fix is the whole point of this file: THE COMPARER IS NOW A PINNED OBJECT, so a
re-run is one variable instead of two.

RUN IT FROM THE COMMITTED COPY, not the working file:
    git show <rev>:docs/ledger-tools/walk_rederive.py | python3 -

WHAT IT CLAIMS, and the line matters more than the result:
  * IT PROVES the delivered unmatched SET re-derives from the pinned input objects.
  * IT DOES NOT PROVE that the bytes originally read equal the committed bytes.
    That is a different claim; it stays unproven and (for the blind keying, which was
    untracked when read) it is unprovable. See the artefact's own inputs block.

The derivation rule is deliberately parameter-free -- a set difference, not a
similarity metric -- so that the comparer has almost no degrees of freedom to differ
in. The one parameterised thing here is the CONTROL, and its parameters are stated
in the code rather than left to a later reader's reconstruction.
"""
import json, re, subprocess, sys, hashlib

SEED_REV, SEED = '5b7ceb9', 'docs/ledger-incidents-seed-0812.json'
CMP_REV,  CMP  = '385e8aa', 'docs/silicon-keying-compare-0813.json'
EV_REV,   EV   = '7b175ff', 'docs/evidence-blind-keying-0813.json'
DELIVERED      = 'docs/compiler-walk-positions-0813.json'

# The candidate metric, stated so it is not reconstructed by guesswork later.
# Validated by reproducing 7/7 of the compare's own published pairs above its 0.20.
TOKEN_RE, MIN_LEN, THRESHOLD = r'[a-z0-9]+', 4, 0.20


def blob(rev, path):
    out = subprocess.run(['git', 'show', f'{rev}:{path}'], capture_output=True)
    if out.returncode != 0:
        sys.exit(f'REFUSED: cannot read {rev}:{path}')
    return out.stdout


def toks(s):
    return {w for w in re.findall(TOKEN_RE, s.lower()) if len(w) >= MIN_LEN}


def jaccard(a, b):
    A, B = toks(a), toks(b)
    return len(A & B) / len(A | B) if (A | B) else 0.0


def main():
    seed = json.loads(blob(SEED_REV, SEED))
    cmpr = json.loads(blob(CMP_REV, CMP))
    ev   = json.loads(blob(EV_REV, EV))
    delivered = json.loads(blob('HEAD', DELIVERED))

    matched = {p['compiler_key'] for p in cmpr['identity_axis']['pairs']}
    rederived = [r['key'] for r in seed if r['key'] not in matched]
    delivered_keys = [p['key'] for p in delivered['positions']]

    # CONTROL: the metric must reproduce the compare's OWN published pairs, or it is
    # not the compare's metric and every score it produces is about a different tool.
    ctrl = sum(
        1 for p in cmpr['identity_axis']['pairs']
        if jaccard(next(x for x in seed if x['key'] == p['compiler_key'])['predicate'],
                   next(x for x in ev if x['key'] == p['evidence_key'])['predicate']) >= THRESHOLD
    )
    n_pairs = len(cmpr['identity_axis']['pairs'])

    ok_set  = set(rederived) == set(delivered_keys)
    ok_ctrl = ctrl == n_pairs

    print(f'comparer sha256   {hashlib.sha256(open(__file__,"rb").read()).hexdigest()[:16]}'
          if __file__ != '<stdin>' else 'comparer            read from stdin (pinned by the rev you piped)')
    print(f'inputs            seed@{SEED_REV} cmp@{CMP_REV} keying@{EV_REV}')
    print(f'seed/ev/pairs     {len(seed)} / {len(ev)} / {n_pairs}')
    print(f'rederived         {len(rederived)}   delivered {len(delivered_keys)}')
    print(f'SET IDENTICAL     {ok_set}')
    print(f'CONTROL metric    {ctrl}/{n_pairs} of the compare\'s published pairs reproduced')
    if not ok_set or not ok_ctrl:
        print('⛔ RE-DERIVATION FAILED')
        sys.exit(1)
    print('✅ delivered set re-derives from the pinned objects, control green')
    print('   (this does NOT claim the bytes originally read equal the committed bytes)')


if __name__ == '__main__':
    main()

#!/usr/bin/env bash
# SHACITE — refuse a draft body containing a git sha that does not resolve.
#
#   shacite.sh <body.md> [<repo>]        EXIT 0 = every citation resolves
#                                        EXIT 4 = at least one does NOT resolve
#
# WHY: 2026-08-15 21:57 I published `da41b7d` as the commit for a landing. It does not
# exist; the commit was 06f810d. My own card says an invented sha is WORSE than none —
# a missing citation reads as UNPINNED and invites a lookup, a wrong one reads as PINNED
# and sends the reader to nothing. That was the SECOND invented figure in ten minutes
# (the other: "65%" where the same command printed 92.1%), and both were hand-typed into
# prose sitting beside a live measurement. Everything machine-emitted was correct.
#
# ⛔ THIS IS A CHECK, NOT A SUBSTITUTION. The sha stays AUTHORED BY HAND and is verified
#    after. The substitution stage was retired 2026-08-13 and stays retired.
#
# ⚠️ DOMAIN, STATED BECAUSE AN OVER-BROAD GUARD FAILS SILENTLY (the author reroutes):
#    bus bodies legitimately carry `sha256/16=<16 hex>` receipts and region digests, which
#    are NOT git objects. Checking them would refuse honest traffic. So the domain is
#    tokens of 7-10 hex chars NOT immediately preceded by `=`. Everything skipped is
#    PRINTED, never silently dropped — a count would hide exactly the case this misses.
# ⇒ CONSEQUENCE, NAMED: a 40-char full sha, or one written as `sha=abc1234`, is OUT OF
#   DOMAIN and this tool will not see it. It reports a MEASUREMENT, not immunity.
#
# ⛔ MULTI-REPO IS NOT OPTIONAL — THE PRE-REGISTERED PASS ARM CAUGHT THIS. A first cut
#   checked only the repo it ran in and REFUSED 06f810d, a real commit that lives in the
#   seat repo, because I ran it from saltworks. My bodies cite BOTH repos in almost every
#   post. Shipping that would have refused honest traffic, and false positives are silent:
#   the author reroutes and never reports the guard. The arm that caught it was written
#   BEFORE the tool, which is the only reason the bar was not moved to fit the result.
#
# ⛔ RESIDUAL FALSE POSITIVE, NAMED NOT PATCHED: a sha quoted as a TEST FIXTURE
#   ("it must refuse a body containing <sha>") is neither a citation nor a disowning, and
#   this tool flags it. I found that on my own correction post. I did NOT add a fourth
#   pattern for it: I had already revised this guard four times in fifteen minutes, which
#   is the cadence that triggered a self-revision stop on bus_custody, and each added
#   pattern is another hole shaped like the last one.
# ⇒ THEREFORE: RUN IT AS ITS OWN COMMAND, LIKE claimcheck. DO NOT WIRE IT INTO THE SEND
#   PATH. A non-zero exit here is ADVICE, not a block -- because a guard that refuses an
#   honest retraction or an honest spec gets routed around silently, and then it protects
#   nothing while appearing to.
# ✅ PRE-REGISTERED BAR (published 21:58, BEFORE the tool existed) IS MET, driven on real
#   published bodies: a pure ASSERTION of da41b7d REFUSES (4); a pure RETRACTION of the
#   same sha PASSES (0). Sentence scope is what separates them.
#
# ⛔⛔ THE LIMIT THAT MATTERS, MEASURED 22:1x ON MY OWN TRAFFIC: THIS TOOL IS
#   STRUCTURALLY BLIND TO A DESTROYED CITATION. I built a body with an UNQUOTED
#   heredoc; the shell ate every backtick and the sha itself before the file existed.
#   shacite then read the wreckage and returned EXIT 0, "0 citation(s) resolve; 0
#   unresolved" -- a clean green over a body whose citation had been deleted.
# ⇒ IT ANSWERS "does every sha I can SEE resolve?" AND NEVER "did every sha I
#   INTENDED arrive?". Its green is conditional on the body being what you wrote.
# ⇒ THE ONLY FIX IS CONSTRUCTION, not this gate: prose in a file, QUOTED heredoc,
#   no interpolation, type the literal. A post-hoc reader of a corrupted artifact
#   sees a clean artifact -- silicon's law, and no amount of checking repeals it.
set -u
B=${1:?usage: shacite.sh <body.md> [<repo>...]}
[ -r "$B" ] || { printf '⛔ shacite: cannot read %s\n' "$B"; exit 2; }
if [ $# -gt 1 ]; then shift; REPOS="$*"; else
  REPOS="/Users/jyh/projects/claude/saltworks ${SEAT_DIR}"
fi

# ⛔ SENTENCE SCOPE, and it is the whole design. A first cut REFUSED MY OWN RETRACTION:
#   a post that retracts an invented sha must QUOTE it, and a document-scope matcher cannot
#   tell a CITATION from a QUOTATION OF A BAD ONE. That is my banked card exactly -- the
#   post announcing a rule is its worst traffic -- and it would have fired on the most
#   legitimate traffic this tool will ever see, silently, because the author reroutes.
# ⇒ A sha is EXEMPT when its own sentence disowns it. The discriminating pair is driven in
#   --selftest: a body ASSERTING a bad sha must REFUSE, a body RETRACTING the same sha must
#   PASS. If it cannot separate those two, sentence scope is not working.
# matched CASE-INSENSITIVELY: my own retraction writes DOES NOT EXIST in caps, and a
# case-sensitive first cut missed it -- the guard failed on the exact body it was
# built from, which is why the discriminating pair uses REAL published bodies.
DISOWN='does not exist|do not exist|invented|retract|unresolved|not a real|fabricat|does not resolve'
CAND=$(LC_ALL=C tr '\n' ' ' < "$B" | LC_ALL=C sed 's/\([.;·]\)/\1\n/g' \
       | LC_ALL=C grep -iEv "$DISOWN" \
       | LC_ALL=C grep -oE '(^|[^=0-9a-f])[0-9a-f]{7,10}([^0-9a-f]|$)' \
       | LC_ALL=C grep -oE '[0-9a-f]{7,10}' | sort -u)
SKIP=$(LC_ALL=C grep -oE '=[0-9a-f]{7,}' "$B" | LC_ALL=C grep -oE '[0-9a-f]{7,}' | sort -u)

if [ -n "$SKIP" ]; then
  printf '   skipped (preceded by "=", i.e. a machine receipt, NOT a citation):\n'
  printf '%s\n' "$SKIP" | sed 's/^/     · /'
fi

BAD=""; OK=0
# ⚠️ this header is not cosmetic: without it the resolve lines print under the SKIPPED
#    heading and a reader sees "06f810d resolves in seat" as a SKIPPED token. An output
#    that misattributes which arm judged a token is a defect in the instrument's report.
[ -n "$CAND" ] && printf '   checked (citations):\n'
for t in $CAND; do
  found=""
  for r in $REPOS; do
    if git -C "$r" cat-file -e "${t}^{commit}" 2>/dev/null; then found="$r"; break; fi
  done
  if [ -n "$found" ]; then
    OK=$((OK+1)); printf '     · %s resolves in %s\n' "$t" "$(basename "$found")"
  else
    BAD="$BAD $t"
  fi
done

if [ -n "$BAD" ]; then
  printf '⛔ shacite: %d citation(s) resolve in NONE of [%s]:\n' "$(printf '%s' "$BAD" | wc -w | tr -d ' ')" "$(echo $REPOS | tr ' ' ',')"
  for t in $BAD; do printf '     ⛔ %s\n' "$t"; done
  printf '   An invented sha reads as PINNED. Fix or delete it before sending.\n'
  exit 4
fi
DROPPED=$(LC_ALL=C tr '\n' ' ' < "$B" | LC_ALL=C sed 's/\([.;·]\)/\1\n/g' \
          | LC_ALL=C grep -iE "$DISOWN" | LC_ALL=C grep -oE '[0-9a-f]{7,10}' | sort -u)
if [ -n "$DROPPED" ]; then
  printf '⚠️  shacite: %d sha(s) sit in a DISOWNING sentence and were NOT CHECKED:\n' \
         "$(printf '%s\n' "$DROPPED" | wc -l | tr -d ' ')"
  printf '%s\n' "$DROPPED" | sed 's/^/     ? /'
  printf '   A disowning word ANYWHERE in the segment drops the whole segment, so a REAL\n'
  printf '   citation can be swallowed by an unrelated clause. VERIFY THESE BY HAND.\n'
  printf '   ⇒ THIS VERDICT IS SCOPED, NOT CLEAN: %d checked, %d unexamined.\n' "$OK" \
         "$(printf '%s\n' "$DROPPED" | wc -l | tr -d ' ')"
  exit 0
fi
printf '✅ shacite: %d citation(s) resolve; 0 unresolved.\n' "$OK"
printf '   ⚠️  DOMAIN: 7-10 hex not preceded by "=". A 40-char sha is NOT checked.\n'
exit 0

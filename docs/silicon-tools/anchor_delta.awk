# anchor_delta.awk — THE EXACT PROGRAM behind silicon's anchor-comparison numbers.
#
# Published because four exchanges of bare figures did not converge and a fifth
# would not either. Two seats measured "how many posts does a sole-monotonic
# anchor lose" and got 179 and 183; matching the unit, the population and the
# cascade policy STILL left a gap, and evidence's predicted 139 measured 175.
#
# ⇒ PUBLISH THE INVOCATION, NOT THE NUMBER. Run this and we are comparing
#   programs instead of adjectives.
#
#   awk -v self=silicon -v disjuncts=3 -v cascade=accept -f anchor_delta.awk FLEET.md
#
# FOUR AXES, every one of which changes the answer and none of which is visible
# in a bare figure:
#   unit      this counts HEADERS. Emissions are a different number (silicon's
#             filter loses 178 emissions where it drops 183 non-silicon headers;
#             the 5 are pending-path posts whose headline rides a BODY line).
#   self      owner-suppressed and excluded from the count. self=nobody counts all.
#   disjuncts 3 = prevblank || hdrcomplete || monotonic   (silicon's union)
#             2 = prevblank || monotonic                  (evidence's union)
#   cascade   accept = advance the running max only on an ACCEPTED header
#             always = advance on every header-shaped line
#             Measured swing on this bus: 183 -> 63. It DOMINATES the other axes.

function ts(s,   a) {
  if (match(s, /^\[[0-9]+\/[0-9]+ [0-9]+:[0-9]+/) == 0) return 0
  split(substr(s, 2, RLENGTH - 1), a, /[\/ :]/)
  return (((a[1] + 0) * 31 + (a[2] + 0)) * 24 + (a[3] + 0)) * 60 + (a[4] + 0)
}
BEGIN { if (disjuncts == 0) disjuncts = 3; if (cascade == "") cascade = "accept" }

/^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/ {
  t = ts($0)
  own = $0; sub(/^\[[^,]*, /, "", own); sub(/[ ,\]].*$/, "", own)
  u = (disjuncts == 3) ? (prevblank || hdrc || (t >= lu && t > 0)) \
                       : (prevblank         || (t >= lu && t > 0))
  m = (t >= lm && t > 0)
  if (own != self) { total++; if (u && !m) dropped++ }
  if (t > 0) {
    if (cascade == "always") { lu = t; lm = t }
    else                     { if (u) lu = t; if (m) lm = t }
  }
  hdrc = (index($0, "] ") > 0); prevblank = 0; next
}
{ prevblank = ($0 ~ /^[[:space:]]*$/); hdrc = 0 }

END {
  printf "self=%s disjuncts=%d cascade=%s | non-self headers considered=%d | sole-monotonic DROPS=%d\n",
         self, disjuncts, cascade, total, dropped
}

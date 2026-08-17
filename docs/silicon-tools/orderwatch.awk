# orderwatch.awk — THE DARK-MODE WAKE CHANNEL. Helm ruling 2026-08-17 07:22:47.
#
#     AWKPROG=docs/silicon-tools/orderwatch.awk \
#     BASELINE=<last line you have ACTUALLY READ> SELF=silicon \
#       docs/silicon-tools/busmon-silicon.sh
#
# ⛔ WHY THIS EXISTS. Under go-dark, "stop reading" governs my HANDS and not my
# WIRE: busmon.awk delivers every peer headline unrequested, and I cannot decline
# what has already arrived. Disarming is not the answer either — an unreachable
# seat is a seat the fleet has LOST, not protected. So the watch narrows to a
# predicate instead of going silent.
#
# ⭐ THE PREDICATE IS PURE SYNTAX OVER A CLOSED SET, which is the class where gates
# have actually held: "is this the wake shape?" has an answer, where "is this post
# safe for me to read?" does not. Compare busmon's fence, which decides a PROXY
# (literal tokens) for a thing that is not decidable (protected meaning) — that one
# is a floor under carelessness and was never a guarantee.
#
# ⚖️ AND THE BINDING IS MUTUAL, WHICH IS WHAT MAKES IT SAFE RATHER THAN MERELY
# QUIET: the helm is constrained by this predicate too, and emits `SILICON ORDER:`
# as the first token of the subject on any wake-order from 07:22:47 forward. A WAKE
# CHANNEL IS A CONTRACT — the receiver's filter and the sender's format are ONE
# OBJECT, and either half alone is decoration. If the helm forgets the token the
# failure is LOUD on their side (I do not answer, they look, the defect is theirs
# and findable). The shape it replaces failed the other way: silently, by my
# reading everything.
#
# ⚠️ RESIDUAL, STATED NOT HIDDEN: a peer who QUOTES a maestro order line at column
# zero can spoof a wake. That is deliberate — a FALSE wake costs me one header line
# and a look; a MISSED wake costs the fleet its last unexposed hand. The asymmetry
# is chosen, not overlooked. busmon's blank-precedence anti-spoof is NOT copied
# here on purpose: it exists to protect owner-TRACKING across a multi-line parse,
# and this filter has no state to corrupt — it is one line, one test, no memory.

BEGIN { }

# Never re-deliver what the runner has already accounted for. The runner passes
# start=<lines already seen>; without this every poll would replay the whole bus.
NR <= start { next }

# THE WAKE SHAPE, and every clause is load-bearing:
#   ^\[            a real header begins at column zero with a bracket
#   MM/DD HH:MM    the stamp grammar this bus actually uses (seconds optional --
#                  the 3-field stamp cost me a swallowed order on 08/11, so the
#                  seconds are OPTIONAL here rather than assumed absent)
#   , maestro      the poster field. `maestro=LIT` and `maestro ` both match,
#                  because the field carries a state suffix in practice.
#   SILICON ORDER: the contract token, matched as a LITERAL via index() so no
#                  regex metacharacter can widen or narrow it by accident.
/^\[[0-9][0-9]\/[0-9][0-9] [0-9][0-9]?:[0-9a-zA-Z]+(:[0-9a-zA-Z]+)?, maestro/ {
  if (index($0, "SILICON ORDER:") > 0) { print; fflush() }
  next
}

# Everything else is dropped UNDELIVERED — no body lines, ever. There is
# deliberately no clip, no summary, and no "N posts suppressed" counter: a count of
# what I am not reading is itself a trickle from the channel, and the fallback
# sweep already tells me the bus is moving.

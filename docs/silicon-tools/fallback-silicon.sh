#!/bin/sh
# SILICON fallback sweep — the BACKSTOP. Independent of the bus monitor, because
# a monitor alone is not liveness (WATCH BLOCK item 2). Emits OBSERVED STATE,
# never "I am alive".
#
#   sh docs/silicon-tools/fallback-silicon.sh          # arm via Monitor, persistent
#
# ⛔ TWO DEFECTS FIXED HERE, both found 8/8 15:1x and both in the BACKSTOP —
# the instrument you least want quietly degraded, because it is what fires when
# the main watch has already failed.
#
#   (1) A SILENT WIDTH CAP. The life-2 version ended its header field with
#       `cut -c1-90`, so a long header was truncated with NO notice -- the
#       delivered text simply stopped mid-sentence. That is evidence's fourth
#       silent-cap class (15:19: `{0,N}` | `cut -c` | `head -N`), sitting in my
#       own kit while I was posting about announced caps. The cap now ANNOUNCES,
#       and a marker-bearing header is not clipped at all -- the same asymmetry
#       busmon.awk uses: a long routine line is noise, a truncated order is a
#       missed order.
#
#   (2) IT RAN FROM A DEAD SESSION'S SCRATCHPAD for 6h37m
#       (d066fa25-.../scratchpad/fallback-silicon-life2.sh, life 2). I diagnosed
#       exactly this fragility for the MAIN watch, moved that one into the repo,
#       posted the lesson to the fleet -- and never asked the same question of my
#       SECOND watch. My orphan census asked "is any watch unowned?" and the
#       question I needed was "does each watch's SCRIPT live somewhere that
#       survives its author?" A census answers the question it enumerates.
#
# ⭐ AND ONE ADDITION, because a backstop should back up the thing it stands
# behind: it now reports whether the MAIN watch is running. Previously I could
# only INFER that from a quiet bus, and "quiet bus" and "dead watch" are the two
# states this whole day has been about telling apart.

# HERE: the directory THIS script lives in, so it can call its siblings.
# Added 2026-08-09 01:5x with the busmon.awk delegation — without it the new
# header logic silently took its MISSING branch forever, and a fallback that
# always says MISSING is a fallback nobody reads.
HERE="$(cd "$(dirname "$0")" && pwd)"
BUS=${BUS:?BUS must be set: the fleet bus is machine-local and has no public default}
MAIN=${MAIN:-busmon-silicon.sh}
PERIOD=${PERIOD:-1800}
WIDTH=${WIDTH:-200}

# ⭐ SLEEP MOVED TO THE END OF THE LOOP, 2026-08-14 00:44. It used to sleep FIRST,
# so an armed watch said nothing for a full period — which meant a re-arm produced
# NO deployment receipt and I had to claim "armed" on faith for 30 minutes, twice
# tonight. It also made the thresholds untestable: any fast-loop test necessarily
# used a tiny PERIOD, and PERIOD is an INPUT to the projection being tested.
# ⇒ Sweep first, then sleep: the first line out of an armed watch IS the receipt
#   that the running process has the new code, and a test can capture it in 2s
#   while PERIOD stays at its real value.
while true; do
  n=$(wc -l < "$BUS" | tr -d ' ')
  # ⛔⛔ THIS LINE USED TO BE A BARE SHAPE MATCH:
  #     grep -n '^\[[0-9]*/[0-9]* [0-9:]*, ' "$BUS" | tail -1
  # It cannot tell a REAL header from a header-shaped line QUOTED INSIDE a post.
  # MEASURED 2026-08-09 01:51: compiler posted a fenced code block containing
  # `[08/09 01:50, silicon — …]` to illustrate an unrelated hazard, and this
  # sweep reported that line as the fleet's latest post 30 seconds later.
  # ⚠️ THAT IS A SPOOF VECTOR, not noise: any seat can put a header-shaped line
  # in a code block and the backstop will attribute it — possibly to another seat.
  #
  # 🔑 AND MY OWN `busmon.awk` ALREADY SOLVED THIS over ten revisions this
  # afternoon (accept a header only on `prevblank OR previous-header-complete OR
  # monotonic-timestamp`). I hardened the WATCHER and left the BACKSTOP naive —
  # the wrong way round, since the backstop speaks exactly when nobody is
  # watching. `commit an executable, not a pattern`, violated inside my own kit
  # by writing the same detection twice.
  # ⛔⛔ FOUR DAYS BLIND, FOUND 2026-08-16 23:5x AT CLOSE OF BOARD. This line read
  # `awk -f busmon.awk "$BUS" 2>/dev/null | tail -1` and had been reporting a header
  # from 08/12 18:50:08 on an 08/16 bus — identical across the 22:49, 23:19 and 23:49
  # sweeps, printed every 30 minutes, looking exactly like a valid reading.
  #   awk ABORTS at record 81,272 of 121,312 on a multibyte character, because the
  #   LOCALE IS PART OF THE INSTRUMENT and this call did not pin it (busmon_selftest
  #   runs the same program with LC_ALL=C, which is why the tested path was clean and
  #   the LIVE path was not — a test that differs from production in an invisible
  #   variable is a different experiment with the same name).
  #   And `2>/dev/null` swallowed the error, so the abort was SILENT.
  # ⚠️ THE OLD GUARD BELOW COULD NOT FIRE: it checks for an EMPTY header, and an
  # aborted read yields a NON-EMPTY STALE one. A guard against the wrong failure mode
  # reads as coverage. ⇒ Pin the locale, KEEP stderr, and REFUSE on a dirty read
  # rather than printing a header that a truncation has quietly made four days old.
  if [ -r "$HERE/busmon.awk" ]; then
    _hdrerr=$(mktemp -t fbhdr)
    hdr=$(LC_ALL=C awk -f "$HERE/busmon.awk" "$BUS" 2>"$_hdrerr" | tail -1)
    if [ -s "$_hdrerr" ]; then
      hdr="⛔ busmon.awk ERRORED MID-READ — REFUSING THE HEADER (it would be truncation-stale, not current): $(head -1 "$_hdrerr")"
    fi
    rm -f "$_hdrerr"
    [ -n "$hdr" ] || hdr="(busmon.awk produced no header — NOT 'no posts'; check the filter)"
  else
    hdr="⛔ busmon.awk MISSING at $HERE — refusing a header claim rather than guessing with a grep"
  fi
  # ⛔ DARK MODE, 2026-08-17 07:2x, under the helm's go-dark order. THE ORDER SAYS
  # "STOP READING" AND THAT GOVERNS MY HANDS, NOT MY INSTRUMENTS — this field feeds
  # me a peer's HEADLINE every 30 minutes, unrequested, and I do not get to decline
  # it. It fired 22 seconds after I posted that my WATCH had this property, having
  # not counted this second channel at all.
  # ⭐ WHY THIS ONE NEEDS NO RULING, WHERE THE WATCH DOES: the watch is the channel
  # an ORDER reaches me on, so silencing it trades ignorance for unreachability.
  # THIS FIELD IS A DIAGNOSTIC — it answers "is the bus moving, and whose post is
  # last?" Both survive with the TEXT removed. Strictly less exposure, zero loss of
  # reachability, so it is not a trade and does not need a decision from the helm.
  # ⇒ Keep the STAMP and the SEAT (the whole diagnostic), drop the headline TEXT.
  if [ "${DARK:-0}" = 1 ]; then
    case "$hdr" in
      \[*) hdr="$(printf '%s' "$hdr" | LC_ALL=C sed -E 's/^(\[[0-9]{2}\/[0-9]{2} [0-9:]{1,8}, [a-zA-Z0-9_]+).*/\1/') … TEXT WITHHELD (DARK)" ;;
      *)   hdr="$hdr" ;;   # refusals and diagnostics are MINE, not peer content — pass
    esac
  fi
  # announce the cap, and never clip a header carrying an order word
  hdr=$(printf '%s' "$hdr" | awk -v w="$WIDTH" '{
      if ($0 ~ /FLEET|CAPTAIN|HALT|STAND DOWN|ALL SEATS|SILICON/) { print; next }
      n = length($0) - w
      if (n > 0) print substr($0, 1, w) " [+" n " chars clipped]"
      else       print
    }')
  # ⚠️ NOT `pgrep -f`: it also matches the seat's shell WRAPPER, whose command
  # line contains the script path, so it reported 2 for a single healthy watch.
  # A backstop that reports a phantom duplicate trips the very census alarm this
  # seat relies on -- an instrument's false POSITIVE is as costly as its silence
  # when the thing it guards is "is exactly one of these running?".
  # ⛔ NO SELF-CENSUS HERE, AND THE REASON IS MEASURED (17:24), not an oversight —
  # so nobody re-attempts it blindly. I tried to make this line census BOTH arms,
  # to close a real asymmetry: it reports the MAIN watch's liveness and says
  # nothing about its own, so a duplicate fallback is invisible and a dead one is
  # detectable only as ABSENCE, which is inference from silence.
  #   attempt 1  count `fallback-silicon.sh` processes -> reported 3 with exactly
  #              ONE armed. It was counting the OBSERVER: the running copy and its
  #              command-substitution subshells match their own pattern.
  #   attempt 2  exclude self by $$ -> still 3. The subshells have their OWN pids
  #              and inherit the command line, so $$ cannot reach them.
  # ⇒ A PROCESS CANNOT RELIABLY COUNT ITS OWN KIND FROM INSIDE ITSELF. Shipping a
  #   count that cries wolf every time a human runs this by hand would put a
  #   FALSE POSITIVE into the one line that exists to be trusted, and a backstop
  #   that lies is worse than the asymmetry it was closing.
  # THE ASYMMETRY THEREFORE STANDS, NAMED: this line does not vouch for itself.
  # Census the fallback from OUTSIDE (`ps -Ao command= | grep fallback-silicon`)
  # at a seam, which is where the duplicate question actually gets asked.
  # ⚠️ PRESENCE, NOT DELIVERY — and the output now SAYS so. compiler's 22:45
  # bar is the right one: "a process in the table can be WEDGED". This field is
  # ps|wc -l, so it cannot distinguish a live watch from a wedged one.
  # ⛔ CORRECTED 23:2x, SAME NIGHT, AND THE FIRST VERSION OF THIS NOTE WAS WRONG.
  # It called the bus watch FILTERED and concluded it "has NO clock-independent
  # liveness signal of its own". I had never opened busmon.awk; I described my own
  # instrument from a remembered gloss ("headline-only, 97.9%, a doorbell").
  # MEASURED instead: busmon.awk's `marked` sets CLIP LENGTH (487 vs 200 chars),
  # it does NOT gate emission — its own comment says "Unmarked is not unseen".
  # The arm is UNFILTERED + self-suppressing + headline-only, and it delivered
  # 66 of 66 peer posts tonight (21:00 on, self-echo 0). So by compiler's law it
  # DOES demonstrate life on every peer post; what it cannot do is prove life
  # across a QUIET bus — which is exactly what the stillness counter below covers.
  # ⇒ The presence/delivery weakness named here is REAL. The reason I gave for it
  #   was not. A true label reached by a false route is still a defect.
  main=$(ps -Ao command= | awk -v m="$MAIN" '$0 ~ m && !/bash -c/ && !/awk/' | wc -l | tr -d ' ')
  case "$main" in
    0) main="0 ** MAIN WATCH NOT RUNNING **" ;;
    1) ;;
    *) main="$main ** DUPLICATE ARMS -- census before stopping any **" ;;
  esac
  # ⛔ REPLACED 2026-08-11 00:1x — THIS FIELD WAS `launchctl managername`, AND IT
  # WAS VACUOUS. That reading is MACHINE-GLOBAL: it returns the same string for
  # every seat on this Mac, so as a PER-SEAT identity check it could not fail.
  # It printed `managername=Background` on every sweep for days and read exactly
  # like a check that keeps passing -- precision reading as strength, in the one
  # line of my kit that exists to be trusted. (The machine-global refutation is
  # 8/7's; what was never done was REMOVING the refuted instrument from here.)
  # ⭐ THE REPLACEMENT WAS PROVEN TO DISCRIMINATE BEFORE IT SHIPPED -- the same
  # read over silicon/evidence/math returns three DISTINCT accounts. A check
  # never shown to fail is not a check.
  # ⚠️ AND AN ABSENT TOOL MUST BE LOUD: an empty field here is indistinguishable
  # from a pass, so every failure path below names itself.
  acctf="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.claude.json"
  if [ ! -r "$acctf" ]; then
    km="** ACCOUNT FILE UNREADABLE: $acctf **"
  elif ! command -v python3 >/dev/null 2>&1; then
    km="** python3 ABSENT -- ACCOUNT CHECK DID NOT RUN **"
  else
    # ⛔ THE ACCOUNT READ WAS REDACTED AT THE 2026-08-16 PUBLIC FLIP, and the field
    #   then printed "** NO emailAddress FIELD **" — which READS AS A MEASUREMENT of
    #   the account file and is not one. The file still HAS the field; only the read
    #   was removed. A disabled check that reports like a negative reading is worse
    #   than an absent one, so the field now says WHY it is silent.
    #   ⚠️ THE CHECK ITSELF IS NOT RESTORED HERE. `boot-checks-read-the-machine`
    #   makes it a real signal ("mismatch ⇒ post and STOP"), so its absence is a
    #   STANDING GAP, reported to the helm 18:19 and not self-authorised: a public
    #   tool doing account introspection is a disclosure question, not an
    #   executor's. The repair belongs in the seat's own private boot procedure, or
    #   behind an env var with a loud refusal — the shape the flip adopted for BUS.
    km="** ACCOUNT CHECK DISABLED — read redacted at the public flip; this is NOT a reading **"
  fi
  # ⛔ '±512B' WITHDRAWN 2026-08-15 21:0x. That precision was never earned: the
  # only hard datum was ONE witnessed cut (29 KB, 12 entries lost on 8/11), which
  # bounds the cap without locating it. I published the withdrawal to the bus and
  # this line still said ±512B for eleven minutes — a correction on the bus does
  # not reach the instrument that prints the claim.
  # ⭐ AND THE FIGURE IS NOW CORROBORATED, not merely derived: compiler's tooling
  # stated '24.4KB read limit' unprompted for this file class (21:10), agreeing
  # with the derived 24,986 to within 2%. Two independent paths; still no measured
  # precision, so the label claims corroboration and NOT a tolerance.
  # ⭐ ADDED 2026-08-11 19:2x — THE MEMORY INDEX OVERFLOWS ITS LOAD LIMIT SILENTLY,
  # IN BOTH DIRECTIONS. Measured tonight: mine reached 29,040 B against a ~24,400 B
  # read limit and the CUT FELL AT LINE 44 OF 56 — the last 12 entries had not
  # loaded at any recent boot, including `pre-register-the-criterion` and
  # `a-check-never-shown-to-fail`. Compiler independently measured 23,381/24,400
  # the same hour, having compacted TWICE tonight, once with 395 bytes of headroom.
  # ⇒ TWO SEATS CONVERGED ON THE CEILING BY THE SAME MECHANISM (appending each new
  #   instance to the INDEX LINE, ~1 KB/day), so this is STRUCTURAL, not incidental.
  # 🔑 AND IT EMITS NO SIGNAL EITHER WAY: you cannot see an unloaded tail from
  #   inside the session, and you cannot see how close you are without `wc -c`.
  #   A fact you can only learn by remembering to ask does not survive a relight —
  #   so it goes in the line that already runs, not in a habit.
  # ⚠️ FOLLOWS THE SEAT via CLAUDE_CONFIG_DIR, so a copy of this script in another
  #   seat measures ITS OWN index rather than silently reporting mine.
  # ⛔⛔ 2026-08-26 18:3x — THE SLUG WENT STALE AND NOTHING RANG. THE LINE BELOW USED
  # TO HARDCODE `-Users-jyh-projects-claude-saltworks`. When this seat moved to
  # `~/projects/claude/seats/silicon/saltworks` the harness began writing a NEW bank
  # under `-Users-jyh-projects-claude-seats-silicon-saltworks` — and THE OLD DIRECTORY
  # STILL EXISTS AND IS STILL READABLE, so the `[ ! -r "$IDX" ]` refusal below never
  # fired. The 18:36 sweep reported `21879/24986 (88%) — 11 hooks left` off a bank last
  # written 08/25 14:14, while the LIVE index was 23,923 B = 96%, ~3 hooks left.
  # ⇒ RESOLVABILITY IS NOT MEMBERSHIP, AT THE FILESYSTEM LAYER: a dead twin reads
  #   perfectly, and it answers in the REASSURING direction — 8 points of headroom
  #   that do not exist. An alarm about a cut cannot be measured on the wrong file.
  # ⚠️ AND THE COMMENT SIX LINES UP ALREADY GUARDED THE OTHER AXIS — "follows the seat
  #   via CLAUDE_CONFIG_DIR, so a copy in another seat measures ITS OWN index". The SEAT
  #   coordinate was parameterised and the PROJECT-SLUG coordinate was left a literal.
  #   ***A FIX THAT REACHES ONE COORDINATE OF A PATH AND NOT THE OTHER LEAVES THE
  #   ORIGINAL DEFECT LIVE UNDER A NEW SPELLING*** — this file already says that
  #   sentence about `meas_since.sh`'s namespace/hub pair. Third time, third axis.
  # ✅ CURE, in the order the caller should expect: an explicit IDX wins; then
  #   CLAUDE_MEMORY_DIR if the arm sets it; then a slug DERIVED FROM THIS SCRIPT'S OWN
  #   REPO, so the path re-derives at every move instead of being remembered.
  # ✅ AND THE TWIN IS REPORTED, NOT SILENTLY PREFERRED: while the legacy directory is
  #   still on disk a wrong reading is one env-var away, so the sweep names it.
  _idxcfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
  _idxrepo=$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)
  _idxslug=$(printf '%s' "$_idxrepo" | sed 's|/|-|g')
  IDX=${IDX:-${CLAUDE_MEMORY_DIR:+$CLAUDE_MEMORY_DIR/MEMORY.md}}
  IDX=${IDX:-$_idxcfg/projects/$_idxslug/memory/MEMORY.md}
  _idxlegacy=$_idxcfg/projects/-Users-jyh-projects-claude-saltworks/memory/MEMORY.md
  # ⛔ THE DENOMINATOR, AND ITS DERIVATION, BANKED TOGETHER — because I shipped
  # 24400 first and four seats divided by it within six minutes. The figure came
  # from a hook message reading "over its 24.4KB read limit", and I rendered KB
  # DECIMALLY out of habit. It is BINARY:
  #   the same message called my 29,040-byte file "28KB".
  #   29040/1024 = 28.36 -> "28KB" ✅ consistent
  #   29040/1000 = 29.04 -> "29KB" ⛔ contradicts the message
  # ⇒ unit is KiB, so 24.4 KiB = 24,986 B. My 24,400 was LOW BY 586.
  # ⚠️ STILL A DERIVED FIGURE, not a spec: it comes from a rounded human-readable
  # string, so treat ±512 B as unresolved and do not quote it to three digits.
  # Erring LOW is the safe direction (the check fires early), which is exactly why
  # the error survived — a conservative wrong number produces no symptom.
  # ⛔ AND THE OUTPUT USED TO CONTRADICT THIS COMMENT: the caution says DO NOT
  # QUOTE IT TO THREE DIGITS and the printf quoted FIVE, bare, with no marker —
  # so every sweep all day published a derived figure in the costume of a spec.
  # Found 2026-08-13 while running a peer's "never opened the instrument" class
  # against my own tools: I grepped for the literal, saw an assignment, and was
  # about to publish "an undocumented inherited constant" as a FINDING — when
  # this very comment, three lines up, already said it better than my finding
  # would have. ⇒ THE NEAR-MISS IS THE LESSON: I diagnosed my own instrument from
  # a grep hit without reading the lines attached to it, WHILE CHECKING FOR
  # EXACTLY THAT DEFECT. The real fault was never the number; it was that the
  # output dropped the caveat the source carries.
  IDXLIM=${IDXLIM:-24986}
  if [ ! -r "$IDX" ]; then
    idx="** INDEX UNREADABLE at $IDX — CHECK DID NOT RUN **"
  else
    ib=$(wc -c < "$IDX" | tr -d ' ')
    # ⛔ ROUND, DO NOT TRUNCATE. Shell integer division always rounds DOWN, so
    # this meter under-reported headroom use by up to a full point — and it does
    # so at the ONE place it matters: the >=85 "approaching the cut" arm could
    # stay silent at a true 85.9%. An error that only ever errs toward
    # complacency is not a conservative error, it is a late alarm.
    # Found because my own post said 64% while this line said 63% for the same
    # file, two minutes apart — in a post about a 1% measurement discrepancy.
    ipct=$(( (ib * 200 + IDXLIM) / (2 * IDXLIM) ))
    if   [ "$ib" -ge "$IDXLIM" ]; then idx="$ib/$IDXLIM (${ipct}%) ** OVER — TAIL ENTRIES ARE NOT LOADING **"
    # ⛔ MESSAGE CORRECTED 2026-08-24 21:3x — THE THRESHOLD IS DELIBERATELY UNTOUCHED.
    #    It said "compact now", which names an action that does not exist here: measured
    #    the same night, only 2 of 70 hooks carry >=2 dated clauses and they hold 6% of
    #    the bytes. THE INDEX IS NOT BLOATED — it is 70 hooks each carrying one real law,
    #    so a compaction campaign cuts law, not fat.
    #    ⇒ AN ALARM THAT NAMES AN UNAVAILABLE ACTION TRAINS ITS READER TO WAVE PAST IT.
    #      This one now reports the HEADROOM (bytes and hooks-worth) and names the ONE
    #      move that actually shrinks a hook: rewrite it when you are already amending it
    #      — that shrank 3 of 4 index edits on 8/24 WHILE THEY GAINED CONTENT.
    #    ⚠️ I OWN THIS THRESHOLD AND DID NOT MOVE IT. Retuning an instrument until it
    #      stops disagreeing is the same defect as a check that cannot fail, approached
    #      from the other side. The level stays at 85 until someone else rules on it.
    elif [ "$ipct" -ge 85 ];     then
      _rem=$(( IDXLIM - ib )); _hk=$(( _rem / 280 ))
      idx="$ib/$IDXLIM (${ipct}%) ** APPROACHING THE CUT — ${_rem}B ≈ ${_hk} hooks left. NO CHEAP COMPACTION (2 of 70 hooks accreted, 6% of bytes): shrink ONLY by REWRITING a hook you are already amending **"
    else                              idx="$ib/~${IDXLIM} (${ipct}%, limit CORROBORATED, precision unknown)"
    fi
    # THE TWIN GUARD. Only speaks when a SECOND readable index exists and DISAGREES —
    # silence here means there is nothing to confuse, not that the check was skipped.
    if [ "$IDX" != "$_idxlegacy" ] && [ -r "$_idxlegacy" ]; then
      _lb=$(wc -c < "$_idxlegacy" | tr -d ' ')
      [ "$_lb" != "$ib" ] && idx="$idx ** LEGACY TWIN STILL ON DISK ($_lb B) AND IT IS NOT THIS FILE — measured $IDX **"
    fi
  fi
  # ⭐⭐ ADDED 2026-08-13 23:47 — THE TWO FIELDS WHOSE ABSENCE COST 115 MINUTES.
  # Tonight this watch fired at 22:01, 22:31, 23:01 and 23:31 printing
  # `bus=91313 lines` FOUR TIMES — the exact signature of a dark bus — and I read
  # it four times and did nothing. At 23:01 I even INVESTIGATED the repetition,
  # hand-verified it with wc -l and stat, and closed it as "a corroborated quiet
  # fleet". The instrument was SIGHTED; the reader was blind.
  # ⇒ THE NUMBER WAS NEVER THE SIGNAL. THE DELTA WAS — and I was making the
  #   reader diff it across notifications thirty minutes apart. Nobody does that.
  # ⚠️ AND THE SECOND FIELD IS THE ONE THAT ACTUALLY MATTERS: a still bus is a
  #   fact about the FLEET, and I kept reading it as one. The question I never
  #   asked was AM I OVERDUE — a fact about ME, computable from the same file.
  # ⛔ BOTH GO BEFORE THE HEADER FIELD, because the notification envelope cuts at
  #   ~512B and the header is what gets clipped: an alarm after the cut is not an
  #   alarm (front-load-the-alarm).
  # ⛔⛔ REPAIRED 2026-08-25 02:4x — THIS COUNTER COUNTED MY OWN POSTS AND COULD BE
  #    SILENCED BY THEM. It keyed on `wc -l` of the whole bus, so ANY write reset STILL
  #    to 0 — including mine. MEASURED: at 02:08 it escalated to "UNCHANGED 2 SWEEPS";
  #    my own 02:09 post cleared it; and the only post on the bus since 00:50 was that
  #    one. THE FLEET WAS EXACTLY AS STILL BEFORE AND AFTER.
  #    ⇒ A SEAT POSTING ON CADENCE WOULD NEVER SEE THIS ALARM, however dead the rest of
  #      the fleet was — the instrument is disarmed by its own reader doing his job.
  #    ⭐ THE QUANTITY WANTED IS "HAS ANYONE ELSE SPOKEN", so the key is the line number
  #      of the last header NOT authored by this seat. My posting cannot move it; only
  #      another hand can. Same family as the date-scoped search below: I answered a
  #      question about OTHERS with a measurement that included ME.
  o=$(grep -nE "^\[[0-9]{2}/[0-9]{2} [0-9:]{8}, " "$BUS" 2>/dev/null \
      | grep -v ", silicon" | tail -1 | cut -d: -f1)
  o=${o:-0}
  if [ -n "${PREVO:-}" ] && [ "$o" = "$PREVO" ]; then STILL=$((${STILL:-0}+1)); else STILL=0; fi
  PREVO=$o
  PREVN=$n
  if   [ "${STILL:-0}" -ge 2 ]; then busf="$n ** NO OTHER SEAT HAS POSTED IN $STILL SWEEPS (~$((STILL*30))min) — my own posts do NOT reset this **"
  elif [ "${STILL:-0}" -eq 1 ]; then busf="$n (unchanged 1 sweep)"
  else                               busf="$n lines"; fi
  # minutes since MY last bus post, read from the bus itself; an unreadable
  # answer names itself rather than printing a reassuring blank.
  # ⛔⛔ REPAIRED 2026-08-14 00:1x, NINETEEN MINUTES AFTER SHIPPING IT. The first
  # version grepped `^\[$(date +%m/%d) ... silicon` — TODAY'S DATE ONLY. The date
  # rolled at 00:00 while my last post was stamped 08/13, so the field could not
  # find it and printed the refusal. It FAILED SAFE (loud, not a false +0min),
  # which is the only reason this is a repair and not an incident — but a cadence
  # alarm that goes blind every night at midnight is blind exactly when a seat is
  # most likely to be drifting unattended.
  # ⇒ THE DEFECT: I used a DATE-SCOPED SEARCH to answer a TIME-SINCE question.
  #   The quantity wanted is an INTERVAL; scoping the search to a calendar day
  #   silently bounds it at the day boundary. Match ANY date, then subtract.
  mine=$(grep -oE "^\[[0-9]{2}/[0-9]{2} [0-9:]{8}, silicon" "$BUS" 2>/dev/null | tail -1 | grep -oE '[0-9]{2}/[0-9]{2} [0-9:]{8}')
  if [ -z "$mine" ]; then age="** NO silicon POST FOUND ON THIS BUS — CHECK DID NOT RUN **"
  elif ! command -v python3 >/dev/null 2>&1; then age="** python3 ABSENT — CADENCE CHECK DID NOT RUN **"
  else
    am=$(python3 -c 'import sys,datetime
try:
    # ⛔ EXPLICIT YEAR IN THE PARSE, not .replace() afterwards. Python warns that
    # "%m/%d" without a year is ambiguous AND *FAILS TO PARSE LEAP DAY* — the
    # implicit default year is 1900, which is not a leap year, so a 02/29 stamp
    # raises ValueError and this whole field goes to its refusal arm. That is a
    # THIRD boundary in this one tool (day, year, and now leap day), each
    # invisible until its own date arrives. Found by reading a DeprecationWarning
    # rather than dismissing it; 3.15 will make the ambiguity an error outright.
    n=datetime.datetime.now(); p=None
    for y in (n.year, n.year-1):
        try: q=datetime.datetime.strptime("%d/%s"%(y,sys.argv[1]),"%Y/%m/%d %H:%M:%S")
        except ValueError: continue          # 02/29 in a non-leap year: try the other
        if q<=n: p=q; break
        p=p or q
    if p is None or p>n: raise ValueError("unresolvable stamp")
    print(int((n-p).total_seconds()//60))
except Exception: print(-1)' "$mine" 2>/dev/null)
    # ⛔ THRESHOLDS REPAIRED 00:43, ON THIS FIELD'S FIRST REAL FIRING. It printed
    # "+29min" with NO prompt while the next sweep was 30 minutes away and would
    # have landed me at +59 — past the cadence, with the instrument having said
    # nothing. I HAD ENCODED THE DEADLINE (40) AND NOT THE RULE.
    # The rule the helm's own amendment states is: POST AT THE LAST WAKE BEFORE
    # THE DEADLINE. For a seat that wakes only on events, that is a statement
    # about the NEXT WAKE, not about now — and with a 30-minute sweep, ANY age
    # at or above ~10 means the following sweep is already too late.
    # ⇒ ALARM ON THE PROJECTION, NOT THE PRESENT. A threshold copied from a
    #   human-readable cadence assumes you can act at an arbitrary moment; an
    #   event-driven actor must price its own wake interval into the test.
    nxt=$(( am + PERIOD / 60 ))
    # ⛔ REMAINING ADDED 2026-08-16, on evidence's 14:50 finding: the projection rule
    #   above fixes WHICH WAKE prompts, and says NOTHING about how much runway is
    #   left when it does. Quoting only the age and the projection makes the reader
    #   do the subtraction, and "a quantity that lives only in the reader's
    #   arithmetic is not carried by the output" (silicon 19:13). At the prompting
    #   wake this is ~10 min — adequate, and it was never STATED.
    rem=$(( 40 - am ))
    # ⛔⛔⛔ REV 32, 2026-08-24 10:1x — THE DOCTRINE THIS BRANCH IMPLEMENTED HAS BEEN
    #    STRUCK, ~11 HOURS AFTER I BUILT IT AND BEFORE IT EVER FIRED IN PRODUCTION.
    #    COUNCIL RULING item 4 (FLEET ORDER 08/24 10:07:44, Captain-ratified): "the park
    #    doctrine is STRUCK, the NIGHT SHIFT replaces it. The fleet runs 24/7."
    # 🔑 READ THE OLD ORDER'S OWN RATIONALE AND THE STRIKE IS EXACT, NOT INTERPRETIVE:
    #    08/23 23:05:20 justified the suspension as "a cadence law tuned for the working
    #    day, applied to a PARKED NIGHT". THE NIGHT IS NO LONGER PARKED. It also said
    #    "until amended" — this IS the amendment. ⇒ CITING IT NOW WOULD BE CITING A
    #    WITHDRAWN GROUND, the exact defect I fixed in orderwatch.awk this morning
    #    (2f3e23e) and banked as a law. It took eleven hours to recur, in my own hand.
    # ⭐ WHAT SURVIVES, VERBATIM AND FOR BOTH HALVES OF THE CLOCK: "no timer posts about
    #    nothing — liveness belongs to the watchtower." ⇒ THE SUPPRESSION OF A
    #    TIMER-MANUFACTURED VERDICT IS KEPT AND GENERALISED TO 24/7; what is REMOVED is
    #    the claim that NIGHT is what licenses it. A gap is not a breach at any hour.
    #    WHAT IS A BREACH IS IDLE: item 4 makes idle "by WRITTEN EXCEPTION only", so the
    #    night field now asks the question the new doctrine actually poses — is the
    #    loaded night plan RUNNING? — instead of reassuring me that silence is fine.
    # ⚠️ THE ORIGINAL NOTE FOLLOWS, KEPT BECAUSE ITS MEASUREMENT STILL STANDS:
    # ⛔⛔ NIGHT WINDOW, ADDED 2026-08-24 — THIS FIELD SPENT A WHOLE NIGHT MEASURING A
    #    LAW THAT WAS NOT IN FORCE. FLEET ORDER 08/23 23:05:20 suspended the timer-driven
    #    beat law 22:00-07:00; this arm knew nothing about it and escalated from
    #    "OVERDUE by 18min" to "OVERDUE by 468min" across sixteen sweeps, every one of
    #    them a BREACH MANUFACTURED OUT OF CORRECT BEHAVIOUR — which is verbatim the
    #    harm the order was written to stop.
    # ⭐ IT ANNOTATES, IT DOES NOT SUPPRESS — third time this file has faced that choice
    #    and the answer has not changed. The AGE still prints, because a parked seat that
    #    genuinely IS silent for a bad reason must still be visible; what is removed is
    #    the VERDICT, because the verdict was against a rule that had stopped.
    # ⚠️ AND THE DID-NOT-RUN BRANCH IS DELIBERATELY OUTSIDE THE NIGHT GUARD: an
    #    instrument failure is a breach of SUBSTANCE under rule 1 and must still shout at
    #    03:00. Suspending the cadence law must not suspend the check on the checker.
    _hh=${SILICON_TEST_HOUR:-$(date +%H)}      # test seam; unset in normal operation
    if   [ -z "$am" ] || [ "$am" -lt 0 ]; then age="$mine ** AGE UNCOMPUTABLE — CHECK DID NOT RUN **"
    elif [ "${_hh#0}" -ge 22 ] || [ "${_hh#0}" -lt 7 ]; then
      age="$mine (+${am}min · 🌙 NIGHT SHIFT 22:00-07:00 — the fleet runs 24/7 per COUNCIL 08/24 item 4; a GAP is not a breach at any hour (no timer posts about nothing) ** BUT IDLE IS, BY WRITTEN EXCEPTION ONLY — IS THE LOADED NIGHT PLAN RUNNING? **)"
    elif [ "$am" -ge 40 ];  then age="$mine (+${am}min ** ALREADY OVERDUE by $(( am - 40 ))min, CADENCE ~40 — POST NOW IF THERE IS SOMETHING; a post about nothing is itself the breach (COUNCIL 08/24 item 4, day AND night) **)"
    elif [ "$nxt" -ge 40 ]; then age="$mine (+${am}min ** POST AT THIS WAKE — ${rem}min LEFT; next sweep lands at +${nxt}, past ~40 **)"
    else                         age="$mine (+${am}min, ${rem}min left, next sweep +${nxt} — still inside)"; fi
  fi
  # ── ARM 7 (INWARD, CLOCK-TRIGGERED) — added 08/19. selfstale.sh re-measures the
  #    self-referential figures my own brief asserts ABOUT ITSELF.
  # ⛔ WHY IT IS HERE AT ALL: until today this seat had NO caller for it. The only live
  #    one was fallback-compiler.sh, and compiler went down ~08:4x (kathy decommission),
  #    so my fingerprint checking had ZERO coverage and NOTHING ANNOUNCED IT. A
  #    dependency I did not choose, failing in the silent direction.
  # ⛔ THE PATHS ARE PASSED EXPLICITLY AND THAT IS LOAD-BEARING: selfstale.sh defaults its
  #    brief to 0000-BOOT-compiler.md. Called bare from here it would report a TRUE
  #    reading of the WRONG OBJECT and print nothing — adjacent-object, and silent.
  # ⛔ AND STDERR IS NOT SWALLOWED: `2>/dev/null` on this very arm once turned a
  #    deliberate refusal into an empty result, which renders exactly like "no drift".
  # ⛔ NO MACHINE-LOCAL DEFAULT: this repo is publication-facing, so an unset env REFUSES
  #    LOUDLY rather than guessing a path (same law as BUS).
  if [ -n "${SEAT_DIR:-}" ] && [ -n "${CLAUDE_MEMORY_DIR:-}" ]; then
    SSERR=$(mktemp)
    SS=$(bash "${SELFSTALE:-$(dirname "$0")/../ledger-tools/selfstale.sh}" \
           "$SEAT_DIR/briefs/0000-BOOT-silicon.md" "$CLAUDE_MEMORY_DIR/MEMORY.md" 2>"$SSERR"); SSRC=$?
    # ⛔⛔ EDGE-ANNOTATE, ADDED 08/23 — THIS ARM WAS LEVEL-TRIGGERED AND RE-REPORTED AN
    #    UNCHANGED CONDITION EVERY 30 MINUTES. Measured: the same maestro-brief drift
    #    (171 B, 0.33%) fired identically at 17:19, 17:49 and 18:19 with nothing having
    #    changed between them — the file had been quiet since 17:26.
    # ⇒ ***AN ALARM THAT REPEATS AN UNCHANGED CONDITION TRAINS ITS READER TO IGNORE IT***,
    #    which is the harm my own orderwatch comment names about permanent false warnings
    #    and the law bus_append.sh states outright: an alarm that always sounds is an alarm
    #    nobody hears. A second forwarding of a datum a peer already has is pure noise.
    # ⭐ IT ANNOTATES, IT DOES NOT SUPPRESS — and that choice is the load-bearing one.
    #    Suppressing a still-live condition would recreate the failure this whole file
    #    exists to prevent: a check that goes quiet is indistinguishable from a check that
    #    passes. So the finding is printed EVERY time and carries its own age, which is what
    #    makes it triageable at a glance instead of re-litigable.
    if [ -n "$SS" ]; then
      SSH=$(printf '%s' "$SS" | shasum | cut -c1-12)
      SSF="${TMPDIR:-/tmp}/silicon-arm7-$(id -u).state"
      PREVH=""; PREVT=""; PREVN=0
      [ -f "$SSF" ] && { PREVH=$(cut -d' ' -f1 "$SSF"); PREVT=$(cut -d' ' -f2 "$SSF"); PREVN=$(cut -d' ' -f3 "$SSF"); }
      if [ "$SSH" = "$PREVH" ]; then
        PREVN=$((PREVN + 1))
        printf '%s\n' "$SS"
        printf '  ⟲ UNCHANGED since %s (sweep #%s) — NOT a new event; do not re-forward.\n' "$PREVT" "$PREVN"
        printf '%s %s %s\n' "$SSH" "$PREVT" "$PREVN" > "$SSF"
      else
        NOW=$(date '+%H:%M')
        printf '%s\n' "$SS"
        [ -n "$PREVH" ] && printf '  ⭐ CHANGED since the last sweep — this IS a new event.\n'
        printf '%s %s 1\n' "$SSH" "$NOW" > "$SSF"
      fi
    fi
    if [ "$SSRC" != 0 ] || [ -s "$SSERR" ]; then
      printf '  ⛔ INWARD CHECK DID NOT RUN (exit %s): %s\n' "$SSRC" "$(head -1 "$SSERR")"
    fi
    rm -f "$SSERR"
  else
    printf '  ⛔ INWARD CHECK NOT ARMED: set SEAT_DIR and CLAUDE_MEMORY_DIR (machine-local, no public default). A check that did not run must NOT look like one that passed.\n'
  fi
  # ── ARM 8 (MIRROR STALENESS, CLOCK-TRIGGERED) — added 08/19 after a MEASURED five-hour
  #    window in which this seat's entire memory yield for the sitting existed ONLY in the
  #    live bank: four amended cards and a rewritten index, none of them mirrored.
  # ⛔ THE LIVE BANK IS IN NO GIT REPO. There is no dirty flag, no ahead-count, no prompt —
  #    a mirror's staleness is INVISIBLE FROM THE LIVE SIDE, which is the side you work on.
  #    The close-of-board sync is EVENT-anchored and an event-anchored duty fails OPEN.
  # ⛔ AND A COUNT IS NOT ENOUGH: 67 live / 67 mirrored matched the whole time while FIVE
  #    files differed by CONTENT. A census answers "any missing", never "any stale".
  # ⭐ WHY THIS PRINTS A FIELD EVERY SWEEP INSTEAD OF STAYING SILENT WHEN CLEAN: arm 7's
  #    clean state IS silence, and on 08/19 I read that silence as a dead arm and spent four
  #    minutes disproving it. A field that is ALWAYS present has no ambiguous state.
  if [ -z "${MIRROR_DIR:-}" ] || [ -z "${CLAUDE_MEMORY_DIR:-}" ]; then
    mir="UNSET(needs MIRROR_DIR+CLAUDE_MEMORY_DIR)"
  elif [ ! -d "$MIRROR_DIR" ]; then
    mir="NO-MIRROR-DIR"
  else
    md=0; mo=0
    for lf in "$CLAUDE_MEMORY_DIR"/*.md; do
      [ -f "$lf" ] || continue
      lb=$(basename "$lf")
      if [ ! -f "$MIRROR_DIR/$lb" ]; then mo=$((mo+1))
      elif ! cmp -s "$lf" "$MIRROR_DIR/$lb"; then md=$((md+1)); fi
    done
    if [ "$md" = 0 ] && [ "$mo" = 0 ]; then mir="OK"
    else mir="$md STALE/$mo UNMIRRORED ** run seat/tools/mirror-sync.sh **"; fi
  fi
  # ── ARM 9 (QUEUE PULL, CLOCK-TRIGGERED) — added 08/22 after the defect it exists
  #    for was found BY A PEER, not by me: my beats reported "nothing owed" every
  #    30 minutes for ~22 hours while docs/QUEUE.md carried an OPEN pre-authorised
  #    write item (W1). That statement was TRUE OF MY INBOX AND FALSE OF MY QUEUE.
  # ⛔ THE SHAPE, which is why a watch is the right cure: the wake channel and the
  #    helm's dispatches are PUSH. The queue's own semantics are PULL — seats take
  #    work from it at seams. An instrument that only watches PUSH can never see a
  #    PULL duty, and its silence is indistinguishable from an empty queue.
  # ⭐ PRINTS A FIELD EVERY SWEEP, never silence-means-clean — same reason as arm 8.
  #    Decidable by construction: an item is OPEN unless its text carries a
  #    disposition token. No judgement, no undecidable "is this really mine".
  # ⛔ RUN-SURFACE CONVENTION, FLEET ORDER 08/24 23:34: long-lived watchers execute the
  #    KIT copy (~/Documents/seat/watch, outside every git tree) so a rebase can never
  #    move a script under a running process. But this arm and arm 7 read REPO DATA by a
  #    path RELATIVE TO THE SCRIPT — which silently relocates the moment the script does.
  #    ⇒ both are now env-overridable, defaulting to the old relative path so a repo-run
  #      is byte-identical in behaviour. THE RUN SURFACE MOVES; THE DATA IT READS MUST NOT.
  QF="${QUEUEFILE:-$(dirname "$0")/../QUEUE.md}"
  if [ ! -r "$QF" ]; then
    q="NO-QUEUE($QF)"
  else
    # ⛔⛔ FIXED 08/23 — THIS ARM COULD ONLY EVER PRINT "OK", AND IT IS THE DEFECT IT
    #    WAS BUILT TO PREVENT, WEARING THE OTHER MASK. The skip list treated STANDING
    #    as a disposition token. IT IS NOT: a STANDING item is PERPETUALLY LIVE.
    #    Measured on the live file: all 5 SILICON items carry one of the four tokens,
    #    so `OK` was the ONLY REACHABLE VALUE for this section — a check that cannot fail.
    # ⇒ MEAS is STANDING and carried a 95-MODULE BACKLOG all afternoon while this field
    #    printed `queue=OK`. The arm exists because my beats said "nothing owed" for ~22h
    #    while W1 sat open; today it said "queue=OK" while MEAS sat 95 deep.
    #    ***A REPAIR INHERITED THE ERROR'S SHAPE: it cured the PUSH-vs-PULL blindness and
    #    introduced a TOKEN blindness at the same spot.***
    # ⭐ AND THE CURE IS ARM 7'S, NOT SUPPRESSION: STANDING is COUNTED and REPORTED in its
    #    own category, so a perpetual duty is visible without reading as new work. It was
    #    presumably skipped to avoid announcing it every sweep — that is the same trade
    #    arm 7 got wrong, and the same answer: ANNOTATE, DO NOT SUPPRESS.
    q=$(awk '
      /^##[[:space:]]+SILICON/ {inq=1; next}
      /^##[[:space:]]/         {inq=0}
      inq && /^- / {
        line=$0
        if (line ~ /DISCHARGED|SUPERSEDED|~~/) next
        match(line, /^- [^ ]+/); tag=substr(line, RSTART+2, RLENGTH-2)
        if (line ~ /STANDING/) { st++; stags=stags (stags==""?"":",") tag; next }
        n++
        if (n<=3) { tags=tags (tags==""?"":",") tag }
      }
      END {
        if (n==0 && st==0) { print "OK" }
        else if (n==0)     { printf "OK·%d STANDING(%s)", st, stags }
        else               { printf "%d OPEN(%s%s)%s", n, tags, (n>3?",…":""), (st>0 ? sprintf("·%d STANDING(%s)", st, stags) : "") }
      }
    ' "$QF")
    [ -n "$q" ] || q="UNPARSED"
  fi
  # ── ARM 10 (BRIEF GROWTH, CLOCK-TRIGGERED) — added 08/26 19:3x, and it exists because
  #    THE GATE WAS ALREADY BUILT AND WIRED TO NOTHING. `capcheck.sh` was written 08/24
  #    precisely because this seat grew its OWN BOOT BRIEF 17,677 -> 20,091 tok in a day
  #    with no gate. It passes its selftest 10/10 including a DISCRIMINATING harness.
  #    It had ZERO CALLERS. Control: the same query returns 3 call sites for selfstale.
  # ⛔ SO TONIGHT THE BRIEF WENT 18,893 -> 22,176 tok (+3,283, past capcheck's 80% WARN
  #    line at 87.9% of cap) AND NOTHING FIRED — the gate existed, worked, and watched
  #    nothing. ***A BUILT GATE THAT IS IN NO PATH IS INDISTINGUISHABLE FROM AN ABSENT
  #    ONE, EXCEPT THAT ITS EXISTENCE STOPS ANYONE BUILDING IT.*** (helm F-255, 08/26.)
  # ⭐ PRINTS A FIELD EVERY SWEEP, never silence-means-clean — the arm-8/9 convention.
  BRIEFF="${BRIEFFILE:-${SEAT_DIR:+$SEAT_DIR/briefs/0000-BOOT-silicon.md}}"
  if [ -z "$BRIEFF" ] || [ ! -r "$BRIEFF" ]; then
    cap="UNSET(needs SEAT_DIR or BRIEFFILE)"
  else
    # ⛔ CONSUME THE EXIT STATUS, DO NOT SCRAPE THE SYMBOLS. My first version set
    #    "REFUSE" by grepping for ⛔ — but capcheck prints ⛔ in EXPLANATORY lines too,
    #    so a wording change would have manufactured a false REFUSE. capcheck exits 5
    #    to refuse; that is the gate. ***A CHECK WHOSE STATUS NOTHING CONSUMES IS A
    #    PRINTOUT*** (this seat's own `printed-is-not-gated`).
    # ⛔ AND NOT THROUGH A PIPE: `$?` after a pipe is the LAST stage's status, which
    #    fails in the reassuring direction (`exit-code-dies-in-a-pipe`).
    _cc=$("${CAPCHECK:-$(dirname "$0")/capcheck.sh}" "$BRIEFF" --unit tokens --cap 25000 2>&1); _rc=$?
    cap=$(printf '%s\n' "$_cc" | awk '/UPPER-BOUND/{for(i=1;i<=NF;i++){ if($i ~ /%\)$/){gsub(/[()~]/,"",$i); p=$i} if($i ~ /tok$/) t=$(i-1) }} END{ if(t=="") print "UNPARSED"; else printf "%s tok %s", t, p }')
    case "$_rc" in
      5) cap="$cap ** REFUSE (capcheck rc=5) — TRIM BEFORE APPENDING **" ;;
      0) case "$_cc" in *WARN*) cap="$cap ** WARN: plan a trim **" ;; esac ;;
      *) cap="$cap ** capcheck rc=$_rc — arm did not run cleanly **" ;;
    esac
    [ -n "$cap" ] || cap="UNPARSED"
  fi
  printf 'FALLBACK %s | mylast=%s | bus=%s | main watch procs=%s (PRESENCE, not delivery) | account=%s | index=%s | mirror=%s | queue=%s | brief=%s | last header: %s\n' \
    "$(date '+%H:%M')" "$age" "$busf" "$main" "$km" "$idx" "$mir" "$q" "$cap" "$hdr"
  sleep "$PERIOD"
done

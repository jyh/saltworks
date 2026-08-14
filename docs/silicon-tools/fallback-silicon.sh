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
BUS=${BUS:-${BUS}}
MAIN=${MAIN:-busmon-silicon.sh}
PERIOD=${PERIOD:-1800}
WIDTH=${WIDTH:-200}

while true; do
  sleep "$PERIOD"
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
  if [ -r "$HERE/busmon.awk" ]; then
    hdr=$(awk -f "$HERE/busmon.awk" "$BUS" 2>/dev/null | tail -1)
    [ -n "$hdr" ] || hdr="(busmon.awk produced no header — NOT 'no posts'; check the filter)"
  else
    hdr="⛔ busmon.awk MISSING at $HERE — refusing a header claim rather than guessing with a grep"
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
    km=$(python3 -c 'import json,sys
try:
    a = {}  # [REDACTED: account-object read]
    e = a.get("emailAddress")
    print(e if e else "** NO emailAddress FIELD **")
except Exception as ex:
    print("** ACCOUNT READ FAILED: %s **" % ex)' "$acctf" 2>&1)
  fi
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
  IDX=${IDX:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/-Users-jyh-projects-claude-saltworks/memory/MEMORY.md}
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
    ipct=$(( ib * 100 / IDXLIM ))
    if   [ "$ib" -ge "$IDXLIM" ]; then idx="$ib/$IDXLIM (${ipct}%) ** OVER — TAIL ENTRIES ARE NOT LOADING **"
    elif [ "$ipct" -ge 85 ];     then idx="$ib/$IDXLIM (${ipct}%) ** APPROACHING THE CUT — compact now **"
    else                              idx="$ib/~${IDXLIM} (${ipct}%, limit DERIVED ±512B)"
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
  if [ -n "${PREVN:-}" ] && [ "$n" = "$PREVN" ]; then STILL=$((${STILL:-0}+1)); else STILL=0; fi
  PREVN=$n
  if   [ "${STILL:-0}" -ge 2 ]; then busf="$n ** BUS UNCHANGED $STILL SWEEPS (~$((STILL*30))min) — IS THE SILENCE MINE? **"
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
    n=datetime.datetime.now(); p=datetime.datetime.strptime(sys.argv[1],"%m/%d %H:%M:%S").replace(year=n.year)
    if p>n: p=p.replace(year=n.year-1)          # a Dec-31 post read on Jan-1
    print(int((n-p).total_seconds()//60))
except Exception: print(-1)' "$mine" 2>/dev/null)
    if   [ -z "$am" ] || [ "$am" -lt 0 ]; then age="$mine ** AGE UNCOMPUTABLE — CHECK DID NOT RUN **"
    elif [ "$am" -ge 40 ]; then age="$mine (+${am}min ** OVERDUE, CADENCE IS ~40 — POST NOW **)"
    elif [ "$am" -ge 30 ]; then age="$mine (+${am}min — post at THIS wake, not the next)"
    else                       age="$mine (+${am}min)"; fi
  fi
  printf 'FALLBACK %s | mylast=%s | bus=%s | main watch procs=%s | account=%s | index=%s | last header: %s\n' \
    "$(date '+%H:%M')" "$age" "$busf" "$main" "$km" "$idx" "$hdr"
done

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
  printf 'FALLBACK %s | bus=%s lines | main watch procs=%s | account=%s | last header: %s\n' \
    "$(date '+%H:%M')" "$n" "$main" "$km" "$hdr"
done

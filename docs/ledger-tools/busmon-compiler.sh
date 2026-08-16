#!/bin/bash
# compiler seat · session b2d20534 · bus watch — path IS the identity
#
# rev18 08/15 20:4x — THIS FILE NOW MATCHES THE RUNNING PROCESS. IT DID NOT BEFORE.
# ⛔ THE DEFECT WAS FILE-VS-PROCESS DRIFT, NOT A BAD FILTER. dcb39eb claimed to
#   "preserve the EXACT bytes my running bus watch was armed from" and did not: the
#   file carried a hardcoded month while the LIVE rev16 process ran the date-agnostic
#   filter below. I read the FILE, concluded the WATCH would go blind on 09/01, and
#   posted that to the fleet. The watch was fine. The ARCHIVE was wrong.
# ⇒ A FILE THAT CLAIMS TO MIRROR A PROCESS IS A CLAIM, AND NOTHING RE-CHECKED IT.
#   The live command is recoverable from the process; compare, do not assume.
# ⚠️ AND MY "FIX" WAS A REGRESSION: rev17 required a time field and a comma before the
#   seat name, so it MISSED `[08/15, compiler — …]` and `[08/15 20:00:00 compiler — …]`
#   which the live filter caught. rev14 already lost a one-line post this way.
#   Restored to the LIVE bytes verbatim rather than to my improved version.
BUS=${BUS}
tail -n 0 -F "$BUS" | grep -E --line-buffered '^\[[0-9]{1,2}/[0-9]{1,2}[ ,][^]]*(maestro|math|evidence|silicon|compiler)|MAESTRO|HELM|KILL|REFUT|CANARY|canary'

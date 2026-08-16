#!/bin/bash
# compiler seat · session b2d20534 · bus watch — path IS the identity
# rev17 08/15 20:4x: the month was HARDCODED `08/`. The seat-header arm would have gone
# blind on 09/01 -- PARTIALLY and SILENTLY, since MAESTRO|HELM|KILL|REFUT|CANARY carry no
# date anchor and would have kept the watch looking alive while every ROUTINE seat post
# was dropped. That is the rev14 failure mode exactly.
# ⛔ THE LABEL IS WHY IT SURVIVED: this filter was described as `date-agnostic` in the
# Monitor description. The label named the REPAIR (a day hardcode removed, recovered from
# rev15's live process), not the PROPERTY -- and an asserted property is an untested one.
# Found by sweeping, not by failing. Verify with a 09/ fixture, never by reading.
BUS=${BUS}
tail -n 0 -F "$BUS" | grep -E --line-buffered '^\[[0-9]+/[0-9]+ [0-9:]+, (maestro|math|evidence|silicon|compiler)|MAESTRO|HELM|KILL|REFUT|CANARY|canary'

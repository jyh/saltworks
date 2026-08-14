#!/bin/bash
# compiler seat · session b2d20534 · bus watch — path IS the identity
BUS=${BUS}
tail -n 0 -F "$BUS" | grep -E --line-buffered '^\[08/[0-9]+ [0-9:]+, (maestro|math|evidence|silicon|compiler)|MAESTRO|HELM|KILL|REFUT|CANARY|canary'

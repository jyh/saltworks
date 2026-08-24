#!/bin/sh
# issuance_markers.sh — the FROZEN marker set for the issuance-predicate trial.
#
# ⛔⛔ THIS FILE EXISTS TO BE HASHED BEFORE PHASE 1 OPENS.
#   v3 §3 named the last hole honestly: "the features are frozen in v1/v2 TEXT and the
#   reviewer did not author them — but THE FREEZE IS A DOCUMENT, NOT A MECHANISM."
#   A document freeze is a promise; a committed hash is a fact a later edit cannot hide.
#   ⇒ Phase 2 computes markers with THIS FILE AT THIS SHA. If the sha differs at scoring
#     time, the trial is VOID — not adjusted, VOID. That is the point of freezing it.
#
# ⚠️ IT MUST NOT BE RUN DURING PHASE 1. Blindness in this trial is BY CONSTRUCTION: the
#   operator records dispositions against RAW firings and the markers do not exist in any
#   output. Running this during Phase 1 does not merely break a rule, it destroys the
#   independence the agreement statistic is built on.
#
# usage:  issuance_markers.sh <file-of-raw-lines>   -> "<markers|none>\t<line>" per line
set -u
F=${1:?usage: issuance_markers.sh <file-of-raw-lines>}

awk '
  {
    line = $0; m = ""
    # in-backticks : the token inside `...` — a citation, not an utterance.
    #   CONTAINMENT, not "a backtick somewhere": the reviewer caught its own regex
    #   spanning two separate backtick pairs and reporting a false hit. (review §F)
    if (match(line, /`[^`]*(HALT|STAND DOWN|STAND-DOWN)[^`]*`/))            m = m "in-backticks,"
    # in-alternation : TOKEN|TOKEN — a filter pattern being recited, not issued.
    if (match(line, /(HALT|STAND DOWN|STAND-DOWN)[ ]*\|/) ||
        match(line, /\|[ ]*(HALT|STAND DOWN|STAND-DOWN)/))                  m = m "in-alternation,"
    # negated : "no ... has been issued" — the ghost case.
    if (match(line, /(^|[^A-Za-z])([Nn][Oo]|NOT|not|never)[^.]*(HALT|STAND DOWN|STAND-DOWN)/)) m = m "negated,"
    # filter-talk : a seat describing its own arm.  THE LARGEST FALSE CLASS (compiler: 10/27).
    if (match(line, /(my|your|its|the|MY|YOUR|THE)[ ]+(order[- ]?word|arm|filter|watch|pattern)/)) m = m "filter-talk,"
    # reporting-verb : "read/quoted/said/announced ... TOKEN" — a reporting clause.
    if (match(line, /(read|quoted|said|says|announce|describ|cit|report)[a-z]*[^.]*(HALT|STAND DOWN|STAND-DOWN)/)) m = m "reporting-verb,"
    sub(/,$/, "", m)
    printf "%s\t%s\n", (m == "" ? "none" : m), line
  }
' "$F"

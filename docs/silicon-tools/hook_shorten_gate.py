#!/usr/bin/env python3
"""Refuse to shorten an index hook that is the ONLY carrier of a fact.

WHY THIS EXISTS (desk row GW, 2026-09-06; bench's method, silicon's port).
MEMORY.md is cut from the TAIL at 24,985 CHARACTERS, so shortening a hook is
the only way to buy boot headroom -- and the obvious way to shorten one is to
delete the half that looks redundant. IT IS NOT RELIABLY REDUNDANT. bench ran
this gate over its own index and it REFUSED THREE TIMES, surfacing 27 facts
that existed nowhere but in a hook. A hook is the author's own summary, written
at the moment the lesson was learnt; the card is often written EARLIER.

THE CONTRACT: every distinctive token present in the OLD hook and absent from
the NEW hook must be present in the CARD. Otherwise: exit 1, write nothing.

⛔ WHAT THIS GATE DOES *NOT* CHECK, stated so the hole is KNOWN and not implicit
(this seat's own law: an undeclared gap reads as COVERED):
  - It checks TOKEN PRESENCE, never MEANING. A card containing the same words in
    a different claim passes. Presence cannot audit a self-correcting corpus.
  - It is blind to a fact carried by SYNTAX rather than vocabulary (an arrow, a
    negation) when every word survives elsewhere.
  ⇒ It is a REFUSER, not a certifier: its GREEN means "no dropped vocabulary is
    unreachable", never "the shortening is safe". Read the diff too.

⚖️ WAIVERS, AND WHY THEY ARE A FLAG AND NOT A JUDGEMENT CALL. Most real refusals
are SYNONYMS: the card says "I GOT THE FIRST VERSION WRONG", the hook said
"write-up". The tempting repair is to paste the hook's word into the card so the
gate goes green -- that is GAMING THE GATE, and it leaves the next head a check
satisfied by the very padding it was meant to catch (this seat has shipped that
exact defect: `exp>0` SATISFIED BY THE EXACT TYPO IT GUARDS). So a waiver is
explicit, per-token, and CARRIES A REASON THAT IS PRINTED INTO THE OUTPUT --
never a silent override, and never a blanket --force. An unwaived token still
refuses. A waiver without a reason refuses too.
"""
import sys, re, unicodedata

# Words that carry no locating power. Deliberately SHORT: over-filtering here
# turns the gate silently permissive, and a permissive gate is the failure mode
# this whole row is about.
STOP = set("""a an the and or but if then than that this these those is are was were be been being
am do does did doing have has had having i my me we our you your it its of in on at to for from by
with without as so not no nor only just also very can could may might must shall should will would
one two three four when where which who whom what how why all any both each few more most other some
such own same too s t don now here there they them their he she his her him one out up down over
under again further once about into through during before after above below between off why""".split())

TOKEN_RE = re.compile(r"[0-9a-z][0-9a-z._/+-]*", re.I)

def norm(s: str) -> str:
    # NFKC so a fullwidth or composed form cannot masquerade as a different token.
    return unicodedata.normalize("NFKC", s).lower()

def tokens(text: str) -> set:
    out = set()
    for m in TOKEN_RE.finditer(norm(text)):
        tok = m.group(0).strip("._/-+")
        if len(tok) < 3:            # 'rc', 'my' -- no locating power
            continue
        if tok in STOP:
            continue
        if tok.isdigit() and len(tok) < 3:
            continue
        out.add(tok)
    return out

def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--waive=")]
    waivers = {}
    for a in argv[1:]:
        if a.startswith("--waive="):
            spec = a[len("--waive="):]
            tok, _, reason = spec.partition("=")
            if not reason.strip():
                print(f"⛔ REFUSED: --waive={tok} carries no reason. A waiver without a "
                      f"reason is a silent override.", file=sys.stderr)
                return 2
            waivers[norm(tok)] = reason.strip()
    if len(args) != 3:
        print("usage: hook_shorten_gate.py <old-hook-file> <new-hook-file> <card-file> "
              "[--waive=<token>=<reason> ...]", file=sys.stderr)
        return 2
    argv = [argv[0]] + args
    old, new, card = (open(p, encoding="utf-8").read() for p in args)
    dropped = tokens(old) - tokens(new)
    card_toks = tokens(card)
    missing_raw = sorted(t for t in dropped if t not in card_toks)
    missing = [t for t in missing_raw if t not in waivers]
    waived = [t for t in missing_raw if t in waivers]
    print(f"hook_shorten_gate: old={len(old)} chars  new={len(new)} chars  saved={len(old)-len(new)}")
    print(f"hook_shorten_gate: distinctive tokens dropped from the hook: {len(dropped)}")
    if missing:
        print(f"⛔ REFUSED: {len(missing)} dropped token(s) appear NOWHERE in {argv[3]}.", file=sys.stderr)
        print("   These facts live ONLY in the hook. LIFT THEM INTO THE CARD FIRST.", file=sys.stderr)
        for t in missing:
            print(f"     - {t}", file=sys.stderr)
        return 1
    for t in waived:
        print(f"⚖️  WAIVED {t!r}: {waivers[t]}")
    unused = [t for t in waivers if t not in missing_raw]
    if unused:
        print(f"⚠️  {len(unused)} waiver(s) matched no refusal (stale, or the token is in the "
              f"card already): {', '.join(sorted(unused))}")
    print(f"✅ every dropped token is present in the card, or waived with a reason "
          f"({len(card_toks)} card tokens searched, {len(waived)} waived)")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))

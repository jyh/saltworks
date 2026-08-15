# DREAM RESULT — stale_site.py: THE ARTIFACT FAILED. THE DIAGNOSIS IS THE FINDING.

**Branch `dreams/evidence-stale-site` · evidence seat · 2026-08-14 night · NOT FOR ADOPTION.**

## The dream
Four times in 48 hours a document carried TWO statuses for ONE object, with the
superseding text near the superseded text and no annotation at either site. Readers
landed on whichever their access path reached. Cost today: 21 h of a gated arc, one
falsely accepted debt, three retractions including mine. **I tried to build the detector.**

## The verdict: IT DOES NOT WORK
```
POSITIVE 1  SEATS.md @ fb3842a (SPENT vs STANDING)      0 candidates   ⛔ MISSED
POSITIVE 2  QUEUE.md pre-annotation (PAID vs owed)      8 candidates   ⛔ none is the real pair
NEGATIVE    QUEUE.md today (annotated)                 12 candidates   ⛔ should be quiet
```
Two repairs applied after seeing results; still failing. **I stopped there** — a
criterion repaired against its own output is worth nothing, and I had already done it twice.

## ⭐ WHAT THE FAILURE BOUGHT — THE CLASS IS NOT ONE CLASS

The two real instances have **structurally different** shapes, and no single key-matching
detector can hold both:

```
NOMINAL     QUEUE.md  the two sites share an identifier (P2 / ① / MEMORY DESIGN BLOCK)
            -> in principle detectable by key-matching
            -> BUT the identifier WRAPS: "① the MEMORY\n  DESIGN BLOCK", so the key is
               destroyed by a line break. my-extractors-assume-one-line, on the tool
               built tonight to catch law violations. Flattening did not rescue it.

POSITIONAL  SEATS.md  ":38 SPENT AT THIS COMMIT — the pre-grant BELOW is retired"
                      ":47 ⏳ STANDING PRE-GRANT"
            -> THE SITES SHARE NO IDENTIFIER AT ALL. The reference is DEICTIC — "below".
            -> A key-matching detector cannot see this IN PRINCIPLE, not by defect.
```
⇒ ***I ENUMERATED A CLASS FROM THE INSTANCES I COULD SEE AND THE POPULATION WAS WIDER —
the closure law, on the design of a detector rather than on a grant.***

## The second failure, worth as much as the first
My key extractor returns `COMPILER`, `MEASURED`, `DEFERRED`, `THE MAESTRO` as
"identifiers" while missing `P2`/`①`. **Generic ALL-CAPS prose is rare enough to look
distinctive; real identifiers recur often enough to look generic.** My rarity heuristic
was exactly backwards for this corpus, and widening it did not fix the ranking — it only
changed which noise surfaced.

## What asks for the waking world
**Nothing. Do not adopt this tool.** What is worth carrying is the decomposition:
- a POSITIONAL-reference detector is a different instrument (resolve "below"/"above"/
  "the entry beneath", then read the target's status) and is the one that would have
  caught SEATS.md;
- the NOMINAL case needs identifier extraction that survives wrapping AND ranks by
  document-structural salience, not by rarity.

📌 **Honest limit on this very report: two positive controls is not a population.** The
class was named from four instances; I built fixtures for two, and the other two
(`main.tex:335`, the Tier-1 defining line) were never run.

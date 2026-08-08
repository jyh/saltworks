# EVIDENCE SEAT — NIGHT BANK, 2026-08-07

**Written for a successor who will not have the transcript.** Facts the repo already
records are omitted deliberately — the ledger, the census, the refutations and the
muster are all committed and citable. **What follows is judgement.**

Seat booted 13:08 (context-full reboot). Model `claude-opus-5`, stable across 670+
messages — verified, not assumed.

---

## 1. WHAT IS OWED, AND BY WHOM — the only section that matters at 05:30

**Not mine to close. Do not let these become unowned in a handover:**

| item | owner | state |
|---|---|---|
| **Human-time categories for 8/7** | **maestro / Captain** | worksheet generated (8 blocks, 11h 14m, 224 msgs). ⛔ **The measurer must not also be the source** — this seat will not self-tag the Captain's own engagement. Until tagged, the muster carries **`not computed`**, never `0h 00m`. |
| **The 49 unaudited theorems** | **maestro** | true measurement under the HDL seat's convention; most sit in `Silicon/Equiv` (18 in `PartialLoad`), `Banyan`, `Stack` — **other seats' slots**. Nobody is calling them defective; **nobody has ever looked.** Whether that convention binds is a ruling. |
| ~~**`regNext8_correct`**~~ | ~~compiler~~ | ✅ **CLOSED 20:2x, `fb3fa0a` — struck from OWED, verified at the bytes.** ⚠️ **"Closed" means ANNOTATED, NOT PROVEN:** the declaration now states it is a **nine-point sample at the WRONG SIZE** (`regNextN 8 8`, while the shipping part is `regNextN 32 32`). *The name is deliberately NOT changed — other seats cite it, and a record that silently repairs its past is worth less than one that shows where it was wrong.* ⇒ **The sampling remains; the CONCEALMENT does not. Do not read this row as an unconditional certificate.** |
| **5 modules outside the closure** | compiler / silicon | `import-closure` exits 1 by design until swept. Was 9 modules / 55 sites at 17:4x → **5 / 10** at 19:15. |

**Mine, and BLOCKED rather than idle:**

- **The sampled/exhaustive column.** ⚠️ **I first called the blocker "a fanin-restricted
  congruence lemma". THAT NAME IS WRONG** — compiler ruled out `sem_congr_on` (its
  hypothesis is unsatisfiable here: one gate per word bit, so even *ignored* bits are in
  some gate's fanin) and `run_agree_of_inputs` (removes gate-output nets, not unread
  *inputs*). ✅ **The real blocker is a CONE lemma: *"if input `i` is not in the transitive
  fanin of any output, the outputs are independent of `i`."*** ⭐⭐ **IT NOW EXISTS —
  `SaltWorks/HDL/Cone.lean`, landed 22:1x, verified at the bytes:
  `sem_indep_of_input (c) (i) (env) (b) (ho : ∀ n ∈ c.outs, coneOf i c.gates n = false) :
  sem c (upd env i b) = sem c env`** — 39 declarations, EXIT=0, 0 `sorry`, ≤3 axioms,
  `cone` COMPUTABLE (`cone_nil`/`_cons`/`_append`), and it ships a worked instance on the
  real network (`bnCCore_elem0_indep_of_elem23_state`). *Ordered at ~21:35, landed ~22:15.*

  ⚠️ **BUT IT CLOSES ONLY ONE OF THE COLUMN'S TWO BLOCKERS, AND A SUCCESSOR MUST NOT READ
  IT AS "UNBLOCKED":**
  - ✅ **UNREAD axes — settled.** "An enumeration covers an axis if the block *cannot read*
    the nets it leaves out" is now a theorem instead of an argument.
  - ⛔ **READ-BUT-PERIODIC axes — still open.** The shifter reads all 32 shift bits; 32
    values suffice because behaviour is periodic mod 32. **That is a QUOTIENT, not a dead
    input, and `sem_indep_of_input` says nothing about it.** No periodicity lemma exists.* **Do not restart the column as a boolean
  flag — the property is per-axis and needs a proved quotient, not a cardinality.** *Three
  designs died establishing that; see `EVIDENCE-proof-debt-table-0807.md` §5.*
- **The census tool.** Stays in `ScratchEVIDENCEDEPS.lean` until raw == cleaned.
  `MERELY-BUILT` is `86 ≤ n ≤ 112`; the residue is `deriving` instances, and **the NAME
  cannot separate them** — `instGates`/`instOuts` are hand-written defs that capitalise
  exactly as `deriving` does. The correct test is the constant's **type** (is its head a
  class?), which needs the environment threaded into the filter.

## 2. THREE THINGS A REBOOTED ME MUST NOT LOSE — judgement, not fact

1. ⛔ **NEVER PUBLISH THE HUMAN-TIME ZERO.** `0h 00m` is a tagging gap, not a
   measurement. *"The Captain directed for 0h 00m today"* is the worst sentence this
   campaign could emit, and the tool only avoided emitting it because it announces
   untagged blocks instead of summing them to zero.
2. ⛔ **`B-PROVEN` MEANS "HAS A CERTIFICATE", NOT "HAS AN UNCONDITIONAL ONE".** The
   census cannot see the distinction the 16:33 ruling turns on. Until the column exists,
   every proven-about figure carries that caveat **in the sentence that quotes it**.
3. ⛔ **THE CENSUS MOVES ITS OWN SUBJECT.** Published 15:53; by 16:07 two of four
   headline names were closed by the seat that owned them; by 17:0x the adder's
   unconditional theorem existed. **Never re-quote a census — re-run it.**

## 3. HOW I WAS WRONG TODAY, because the list is the useful part

Four numbers **deflated by me before anyone quoted them** (54 Sky130 cells, the module
count, `MERELY-BUILT`, structural-only) — and **one inflated**: I overstated two of four
tier-①ᵇ rows in the *alarming* direction, and compiler corrected me toward its own work
looking better. ***Overstating in the alarming direction is the same defect as
understating in the flattering one, and worse from the seat whose job is the number.***

**Twice: right conclusion, wrong reason** (`inc32`'s route; the human-time zero's
mechanism). **Twice: quoted from memory after measuring** (`_on_sample = 6` after
measuring 20; `ea1a0dd` after pushing `68a67c4`). **Once: an invalid control set** — my
census's four positive controls were themselves sampled certificates, chosen from a
belief I had not tested.

📌 **The mechanism fixes, which are what actually held:** header by `printf`, body by a
**quoted** heredoc, hash substituted by `git log` in the same command. *Adopted 13:34
after I corrupted 9 lines of compiler's history with a global substitution; it then
protected all 36 of my posts from the backtick-execution hazard that bit two other seats
tonight.* **Resolving to be careful did not work; changing the mechanism did.**

## 4. THE WATCH

Monitor `bus_watch.sh` (pid 42246, parented to `--name evidence`) + a 30-min fallback
sweep. **Both re-verified by PPID chain at 20:17, not by `ps` alone** — a neighbour's
`sleep 1800` was nearly logged as mine at 13:34. ⚠️ **The fallback caught two omissions
today that the filtered monitor never would have, because both were MINE** — a missed
liveness beat and an unposted landing. *A monitor watches others; only a timer watches
you.*

## 5. DRAIN

`202/512`, four readings (12:35 · 13:23 · 14:48 · 18:00), **zero drain in 5h25m**.
Count gate OPEN, **span gate binding** (5.4 h of 36). ⛔ **No slope before ~00:35 on
8/9, and the "~20/day" figure that started this instrument would have predicted 4–5
tiles gone today. It predicted wrong.**

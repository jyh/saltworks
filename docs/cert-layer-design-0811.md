# CERT-LAYER — comprehensibility certificates for the paper-cited claims
**Maestro (Fable), 2026-08-11 ~12:4x, at the Captain's word at council ("formal certificates
that simplify the specification… we haven't done much — perhaps we should in the time we
have"). Fleet-open: seats pull at their seams. The Nature draft's §2 five-deliverable
sentence is GATED on this campaign landing across the target list.**

## OBJECTIVE
For each paper-cited headline claim, ONE certificate file: a restatement of the claim in
simplified vocabulary, with a kernel-checked proof linking the restatement to the
landed theorem, so a reader comprehends what was proved from the certificate file ALONE.
This is the artifact that makes statement-level review — the human's one remaining duty —
tractable, and it is the fifth deliverable of the workflow the paper names.

## THE PATTERN (industry has converged on the shape; ours adds the proof)
zeta-23-lean ships a `comparator/` of trusted statements; AxiomMath ships a comparator
harness. Ours differs in one respect that matters: the certificate is not merely a
restatement — it carries a PROOF (equivalence where possible, implication where equivalence
is false, STATED WHICH) connecting it to the landed theorem. A restatement without a proof
is documentation; a restatement with one is a certificate.

## RULES (iron; every executor brief carries them)
1. **Minimal imports.** A cert file imports the landed theorem's module and prelude-grade
   vocabulary ONLY. If the restatement needs a corpus-internal definition, that definition
   gets UNFOLDED into simpler terms or the cert explains it in its docstring header.
2. **No weakening AND no strengthening — a translation has two ways to lie (evidence,
   12:48, pre-registered before any cert exists).** Downward: the certificate states NO
   LESS than the paper quotes. Upward: the cert's LEAN statement cannot overstate — rule 3
   makes it kernel-proved from the landed theorem, so soundness is mechanical — but the
   cert's DOCSTRING is prose, and prose is where readable forms quietly claim more than
   formal ones ("kernel-proved" inheriting SAT links; "the engine's regime" hiding four
   binders). Where the cert is an implication (cert ← theorem), the docstring says exactly
   what generality was traded for readability. Refuter check at seal, TWO comparisons per
   claim: cert-Lean vs paper-quote (adequacy) AND cert-docstring vs cert-Lean (the gloss
   claims nothing the statement does not carry).
3. **Direction declared**: `theorem cert_X : <plain form>` proved FROM the landed name —
   `iff` when true, `←`-implication otherwise, named in the docstring.
4. **Axiom line per cert** (`#print axioms` residue quoted in the file header comment;
   at most the standard three).
5. Roll-call row in the SAME commit (Salt/Certs/All.lean · SaltWorks/Certs/All.lean).
6. House laws ride: saltbuild BARE; grep -F (-e for alternation); pathspec-only commits;
   sorry only in Scratch (the glob covers both repos); give up loudly at ~3 attempts.

## TARGET LIST v1 — salt (`Salt/Certs/`), one file each
bounded_gaps_unconditional · chen_headline · chen_goldbach · gaps_le_twelve (+ its
_of_hasLevel form, one file) · siegelWalfisz_holds (unfold Salt.BV.SiegelWalfisz into plain
binders) · vaughan · analytic_LS + char_LS (one file, two certs) · zeta_zero_free_region_pow
· vmvt (the bound shape in plain exponent vocabulary — the one likely class-C translation) ·
norm_kloosterman_estermann · twin_bar/no_twin_weight/least_k_theorem (one file: THE WALL) ·
sufficient_true_not_parityInv · log_chowla_two_door_only (its one hypothesis NAMED in plain
terms) · psiTot_pnt. **≈14 files, class A/B except vmvt.**

## TARGET LIST v1 — saltworks (`SaltWorks/Certs/`)
the compileE/compileS simulation theorems · the while/ite scheme correctness pair ·
decode_encode · the payload theorem + rot^k = id (THE 1990 CERT — the one the paper's §1
story rests on; write it first, write it beautifully) · witness_chain_discharged ·
step_frame/writesInstr (the executive's isolation claims, plain form). **≈6 files.**

## ASSIGNMENT (amended 12:5x after the seats' answers)
- **saltworks side: COMPILER'S FRESH HEAD, on relight (ordered).** Both standing seats
  declined at depth within a minute — compiler at ~12h ("authored design judgement, the
  class I decline at depth") and silicon immediately after so the slot never waited — and
  compiler COSTED THE LANE for its successor instead (bus 12:48:41): the exact theorem
  names (run_compileS_correct_of_branchFree · compileS_correct_of_branchFree ·
  reaches_of_compileS_of_branchFree · reaches_of_compileS_including_while · the scheme
  pair · witness_chain_discharged) and THE TRAP, which is rule 2's upward direction made
  concrete: encodeOK covers REGISTERS ONLY (not mem, not trapped), so the naive plain form
  "the compiled code computes what the source says" is FALSE; the honest plain form is
  "every variable the source has in scope ends in the register the compiler assigned,
  holding that variable's value." The 1990 cert (payload + rot^k = id) first.
- **SEATS.md**: the commit that CREATES each Certs/ directory adds its SEATS.md ownership
  row in the SAME commit (silicon's 12:48 boundary line — two kinds of writer need a
  declared owner before the first write).
- **math**: salt-side at its seam — INTERLEAVE with Wave A at natural pauses (a cert file is
  a clean small unit between elaboration stretches) or after A's seal; its call.
- **Opus executor waves**: permitted for the A/B rows under the standard dispatch laws
  (model: opus; node name first; the rules above in every brief).
- **evidence**: the cert-vs-paper-quote refuter pass at seal (rule 2's check is its lane).
- **maestro**: owns vmvt's translation if it goes class C; owns the roll-call wiring.

## GATE
The campaign is SEALED when both target lists build green with roll-calls, axioms clean,
and evidence's quote-check passes. The Nature §2 sentence unfreezes on the seal. Freeze-week
re-check: any paper-quoted claim added later gets its cert in the same wave.

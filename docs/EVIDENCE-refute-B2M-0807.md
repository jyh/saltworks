# FRESH-EYES REFUTATION — the crown: `batcher8_banyan_selfrouting`

**Duty:** the maestro's standing refutation order, priority (2) — *"byte-verify the
axiom census and the four controls."* **Method:** every claim below was checked by
**running** something, not by reading a docstring. The probe is
`ScratchEVIDENCEB2M.lean` (gitignored by convention; reproduced verbatim at the
bottom so anyone can rerun it), elaborated via `../saltbuild.sh`, **EXIT=0**.

---

## Verdict

✅ **The census is clean, the four controls are real and discriminating, and my
strongest hypothesis was wrong.** ⛔ **One finding: of the three conjuncts in the
conclusion, the third is FREE — it holds for every function, with no network and no
hypotheses — and the docstring presents all three as content.**

---

## ✅ The axiom census — byte-verified, not read

`#audit_axioms` is a *claim*; `#print axioms` is the *reading*. I ran the reading:

```
batcher8_banyan_selfrouting          [propext, Classical.choice, Quot.sound]
banyan_selfrouting_of_sorts_bool     [propext, Classical.choice, Quot.sound]
batcher8_banyan_selfrouting_of_nodup [propext, Classical.choice, Quot.sound]
banyan_conflict_of_const             [propext, Quot.sound]
```

⭐ **No `sorryAx`. No `Lean.ofReducibleBool`, no `Lean.trustCompiler`** — so nothing
in the crown's dependency cone went through `native_decide`. **Three foundational
axioms, which is the whitelist exactly.**

**And the mechanism behind the claim is sound too, which I checked rather than
assumed** (`SaltWorks/Tactic/AuditAxioms.lean`): `#audit_axioms` **`throwError`s** —
a hard build error, not a log line — the whitelist is exactly
`[propext, Classical.choice, Quot.sound]`, and an *unknown declaration name* is also
an error, so a typo cannot silently audit nothing.

## ✅ The four controls — real, paired, and discriminating

The repo's stated law is that a mutated input must make the goal **false**, not
merely unreachable. All four satisfy it, and they come as two pairs that between
them show **neither hypothesis can be dropped**:

| control | axioms | what it establishes |
|---|---|---|
| `dup_isSorted` (`![1,1]`) | `[propext]` | the input **is** sorted — so what fails next is not sortedness |
| `dup_not_strictMonoOn` | `[propext, Quot.sound]` | …and it **fails** `StrictMonoOn` ⇒ **`Function.Injective` is load-bearing** |
| `swap_injective` (`![1,0]`) | `[propext, Classical.choice, Quot.sound]` | the input **is** injective |
| `swap_not_strictMonoOn` | `[propext, Quot.sound]` | …and it **fails** for want of sortedness ⇒ **sortedness is load-bearing** |

⭐ **This is the right shape and it is rarer than it looks: each pair establishes
the *sufficiency gap* of one hypothesis by exhibiting an input that satisfies the
other one.** *A single "here is something that fails" control would not have
distinguished which hypothesis was doing the work.*

## ✅ My strongest hypothesis was WRONG — reported as required

I expected `Stack/Bridge.lean` to sit **outside** the hub's import closure, which
would mean its two `#audit_axioms` sites never fire in the default build — the exact
class `import-closure.py` exists to catch. **The module's own docstring invites the
reading:** *"`Stack/Perm.lean` — which the hub builds — carries everything but these
two applications."*

⛔ **It is in the hub.** `SaltWorks.lean:33: import SaltWorks.Stack.Bridge`. **The
audits fire. Verified to fail; survives.**

## ⛔ THE FINDING — conjunct 3 of the conclusion is free

The conclusion is a three-conjunct statement, and the docstring describes all three
as results:

> *every stage boundary `m ≤ k` has distinct occupied lines; at the input boundary
> source `s` sits on line `s`; **at the output boundary it sits on its destination**.*

**`Banyan.line_zero (s d : ℕ) : line 0 s d = d`** is a definitional identity. So the
third conjunct is that lemma instantiated — and I proved it for an **arbitrary**
destination function, with **no network, no injectivity, no address bound, and no
mention of Batcher**:

```lean
theorem conjunct3_is_free (d : ℕ → ℕ) : ∀ s, Banyan.line 0 s (d s) = d s :=
  fun s => Banyan.line_zero s (d s)          -- axioms: [propext]

theorem conjunct3_at_a_nonsense_map :
    ∀ s, Banyan.line 0 s ((fun x => x * 37 + 5) s) = s * 37 + 5 :=
  conjunct3_is_free _                        -- elaborates
```

📐 **And conjunct 2 costs only two bound facts** — `line_of_lt` — **not a routing
argument:**

```lean
theorem conjunct2_costs_only_bounds {k : ℕ} (d : ℕ → ℕ)
    (hd : ∀ s, d s < 2 ^ k) (hs : ∀ s, s < 8 → s < 2 ^ k) :
    ∀ s < 8, Banyan.line k s (d s) = s :=
  fun s h => Banyan.line_of_lt k s (d s) (hs s h) (hd s)
```

⇒ ***The routing content of the crown is conjunct 1 alone — `Set.InjOn` at every
stage boundary. That is where the sorting network is spent, and it is a real and
substantial result.*** **Conjuncts 2 and 3 are boundary bookkeeping.**

⚖️ **THE FAIR CAVEAT, and it matters: the three conjuncts are inherited VERBATIM
from upstream `banyan_selfrouting`, and the docstring says so** — *"The three
conjuncts are `banyan_selfrouting`'s, unchanged."* **So this is an upstream
statement-shape observation, not a defect introduced here, and `Bridge.lean` is
honest about inheriting it.**

📌 **Where the risk actually lands is the MUSTER LINE.** *"Conflict-freedom at every
stage, the input boundary, the output boundary"* reads as three results. **It is one
result and two boundary identities, and the campaign should say so before a reader
counts to three.**

---

## Separate live finding — an import-closure REGRESSION, not B2M

`import-closure.py` **exit 1** on the live tree:

```
hub: SaltWorks.lean   tracked .lean: 62   in closure: 54   OUTSIDE: 8
  HDL.BatcherNetC                20 audit site(s) never fire
  HDL.Bitwise                    17
  HDL.SeamC                       8
  Silicon.Equiv.CERefinement      1
  Silicon.Equiv.CERefinementC     1
  + ScenarioComplete, Imported.CompareExchange, Imported.CompareExchangeC (0 each)
TOTAL audit sites outside the default build: 47
```

⚠️ **The board read `import-closure 0 outside` this morning.** These are today's
Convention-C and `core` landings that have not been swept into the hub yet.
**47 audit sites are currently claims nobody's build is checking.** *Not a defect in
anyone's proof — a sweep that has not happened yet, and the tool is doing exactly
its job by saying so.*

---

## The probe, in full — rerun it yourself

```lean
import SaltWorks.Stack.Bridge
namespace ScratchEvidenceB2M
open SaltWorks SaltWorks.Stack

theorem conjunct3_is_free (d : ℕ → ℕ) : ∀ s, Banyan.line 0 s (d s) = d s :=
  fun s => Banyan.line_zero s (d s)

theorem conjunct3_of_crown_needs_nothing {v : Fin 8 → ℕ} :
    ∀ s, Banyan.line 0 s (extendIio 0 (runNet batcher8 v) s)
       = extendIio 0 (runNet batcher8 v) s := conjunct3_is_free _

theorem conjunct2_costs_only_bounds {k : ℕ} (d : ℕ → ℕ)
    (hd : ∀ s, d s < 2 ^ k) (hs : ∀ s, s < 8 → s < 2 ^ k) :
    ∀ s < 8, Banyan.line k s (d s) = s :=
  fun s h => Banyan.line_of_lt k s (d s) (hs s h) (hd s)

#print axioms batcher8_banyan_selfrouting
#print axioms dup_isSorted
#print axioms dup_not_strictMonoOn
#print axioms swap_injective
#print axioms swap_not_strictMonoOn
end ScratchEvidenceB2M
```

⚠️ **One honesty note on my own probe: its first run reported
`conjunct3_is_free depends on axioms: [sorryAx]`.** *That was not a finding — it was
my own namespace error (`Banyan.line` does not resolve under `open SaltWorks.Stack`
alone), and a failed elaboration reports `sorryAx`.* ***A red `#print axioms` on a
file that did not compile says nothing about the theorem and everything about the
file.*** **Fixed with `open SaltWorks SaltWorks.Stack`; the EXIT=0 run is the one
quoted above.**

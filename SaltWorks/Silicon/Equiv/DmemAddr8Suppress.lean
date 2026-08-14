/-
DmemAddr8Suppress — THE STATEMENT LAYER FOR THE LW/SW FRONT'S WRITE STROBE.

`dmem_addr8.v:59-65` states the load-bearing property of this module IN PROSE
and says why it is load-bearing:

    "A trap that raises a flag but still lets `we` through writes to a wrong
     word and then reports an error — the isolation frame would be FALSE while
     the trap logic looked correct. `we_out` is gated on the SAME predicate
     `trap` is raised on, so the two cannot disagree."

That sentence has been the module's guarantee since it was written, carried by
a comment. This file makes it a machine-checked proposition ABOUT THE GATES the
synthesiser actually emitted — not about the RTL text, and not about a spec.

⛔ WHY IT COULD NOT BE STATED BEFORE TONIGHT, both halves now discharged:
  (1) the netlist carrying `we_out` did not import — range-grammar; cured by
      call (4) option (b) at `61fcc74`.
  (2) the datum bound outputs BY ORDER ONLY, so `outs[3]` meant `we_out` by an
      argument no proof could read. Cured by the name table (`cc32a96`): the
      binding is now IN the datum and is checked below before it is used.

⭐ THE PROOF IS A FOUR-ATOM TAUTOLOGY, NOT AN ENUMERATION, AND THAT IS FORCED:
the joint support of `trap` and `we_out` is 31 primary inputs (2^31 cases), so
`decide +kernel` over the input space is not available at any budget. But the
two nets touch the 27 high address bits ONLY through `out_of_range` (net 69),
so the proposition is a tautology in `misaligned`, `out_of_range`, `req`,
`we_in`. Generalising those two nets is what makes it TOTAL rather than a
statement over some sampled subspace.

⚠️ WHAT THIS DOES NOT SAY — the F4 bridge relates the RESPONSE, never the CLASS
LABEL, and this file honours that: nothing here claims the RTL reproduces the
kernel's `addrClass` PRIORITY. It cannot and must not — `dmem_addr8.v:44-57`
records that both trap bits rise independently at byte 33 by RULING, while the
kernel enum forces one label. This is the response half, and only that half.
-/
import SaltWorks.Silicon.Imported.DmemAddr8

namespace SaltWorks.Silicon.Imported

open SaltWorks.Silicon

/-! ## 1 · The name binding, checked before it is used -/

/-- `outs[3]` IS the port named `we_out`, and `outs[2]` IS `trap` — read from
the datum's own recorded name table rather than asserted in a comment. Every
theorem below indexes 78 and 72; these two lemmas are what tie those numerals
to the ports the RTL declares. -/
theorem dmemAddr8_we_out_is_index_3 :
    dmemAddr8NL_out_names.getD 3 "" = "we_out"
    ∧ dmemAddr8NL_outs.getD 3 0 = 78 := by decide

theorem dmemAddr8_trap_is_index_2 :
    dmemAddr8NL_out_names.getD 2 "" = "trap"
    ∧ dmemAddr8NL_outs.getD 2 0 = 72 := by decide

/-- The datum's port coverage is TOTAL: it omits no declared output, so no
guarantee below is quietly scoped to a sub-cone. -/
theorem dmemAddr8_no_omitted_outputs :
    dmemAddr8NL_outs_omitted = [] ∧ dmemAddr8NL_out_names.length = 7 := by decide

/-! ## 2 · The write-suppression law, at the gates

THE SHAPE THE SYNTHESISER LEFT, read off the emitted gates rather than assumed:

    net 34 = or 1 0            misaligned
    net 70 = or 34 48          net 73 = or 34 48     ← DUPLICATE GATES: abc
    net 71 = or 70 68          net 74 = or 73 68     ← never merged these
    net 72 = and 71 32         trap    = (mis ∨ oor) ∧ req
    net 75 = and 33 32         net 76 = not 75
    net 77 = or 74 76          net 78 = not 77       we_out

⭐ `trap` and `we_out` therefore share the SUBTERM `((e34 ∨ e48) ∨ e68)`, one
under a negation — so the conjunction is a tautology in THREE atoms, and the
27 high address bits never have to be enumerated. The duplicate gates are why
this reads as a shared subterm at all; had abc merged them the argument would
be identical, just with one net index.
-/

/-- Net 34 is `misaligned`, net 69 is `out_of_range`. -/
abbrev dmemAddr8_env (ins : Nat → Bool) : List Bool := runP ins [] dmemAddr8NL

/-- The pure Boolean core, isolated so the netlist lemmas below carry no
reasoning of their own: a strobe gated on `¬x` cannot coincide with a trap
raised on `x`, whatever `x` is. THREE atoms — this is the whole argument, and
it is why the 27 high address bits are never enumerated. -/
theorem dmemAddr8_bool_suppress (x q w : Bool) :
    ((!(x || !(w && q))) && (x && q)) = false := by
  cases x <;> cases q <;> cases w <;> rfl

/-! ### The two shape lemmas — each `rfl`, each asserting nothing

⚠️ EACH MENTIONS `dmemAddr8_env` EXACTLY ONCE, AND THAT IS THE WHOLE REASON THEY
CHECK. `runP` grows its environment by `env ++ [·]` and each `stepP` does a
`getD` over that growing list, so ONE evaluation is already near-cubic in the
gate count; a draft phrased with three mentions of `dmemAddr8_env` burned
4,000,000 heartbeats and 2m20s without closing, while its two-mention sibling
passed at the default budget. THE CIRCUIT WAS NEVER THE COST. That is this
seat's oldest recurring defect — re-read the quantifier, not the design — and
it is recorded here because the fix is invisible once applied.

⭐ THE RIGHT-HAND SIDES ARE MACHINE-GENERATED from the emitted gate list, not
typed. `x` below is net 71 rendered as an expression in `ins`, and rendering
net 74 produces THE SAME 362 CHARACTERS — which is the duplicate-gate fact
above, established by construction rather than asserted. Because these are
`rfl`, they are also a TRIPWIRE: if the netlist is ever re-synthesised into a
different shape, these lemmas fail loudly instead of proving something else. -/

theorem dmemAddr8_net78_eq (ins : Nat → Bool) :
    (dmemAddr8_env ins).getD 78 false
      = !(((((ins 1 || ins 0) || !(((!(((ins 21 || ins 22) || ins 19)) && !((((ins 17 || ins 18) || ins 15) || ins 24))) && !((((ins 29 || ins 30) || ins 27) || ins 20))))) || !((((!((((ins 9 || ins 10) || ins 7) || ins 16)) && !((((ins 8 || ins 5) || ins 6) || ins 12))) && !((((ins 25 || ins 26) || ins 23) || ins 31))) && !((((ins 13 || ins 14) || ins 11) || ins 28)))))) || !((ins 33 && ins 32))) := by
  simp [dmemAddr8_env, dmemAddr8NL, runP, stepP]

theorem dmemAddr8_net72_eq (ins : Nat → Bool) :
    (dmemAddr8_env ins).getD 72 false
      = (((((ins 1 || ins 0) || !(((!(((ins 21 || ins 22) || ins 19)) && !((((ins 17 || ins 18) || ins 15) || ins 24))) && !((((ins 29 || ins 30) || ins 27) || ins 20))))) || !((((!((((ins 9 || ins 10) || ins 7) || ins 16)) && !((((ins 8 || ins 5) || ins 6) || ins 12))) && !((((ins 25 || ins 26) || ins 23) || ins 31))) && !((((ins 13 || ins 14) || ins 11) || ins 28)))))) && ins 32) := by
  simp [dmemAddr8_env, dmemAddr8NL, runP, stepP]

/-- ⭐ **THE WRITE-SUPPRESSION LAW.** For EVERY input configuration — all 2^34,
no sampling, no subspace restriction — the emitted netlist never raises
`we_out` and `trap` together. This is the proposition `dmem_addr8.v:59-65`
states in prose as the reason the isolation frame is true. -/
theorem dmemAddr8_we_out_excludes_trap (ins : Nat → Bool) :
    ((dmemAddr8_env ins).getD 78 false && (dmemAddr8_env ins).getD 72 false)
      = false := by
  rw [dmemAddr8_net78_eq, dmemAddr8_net72_eq]
  exact dmemAddr8_bool_suppress _ _ _

/-- **NO WRITE WITHOUT A REQUESTED STORE.** `we_out` high forces both `we_in`
and `req` high — the strobe cannot be manufactured by the address path. -/
theorem dmemAddr8_we_out_implies_store_requested (ins : Nat → Bool) :
    (dmemAddr8_env ins).getD 78 false = true → (ins 33 && ins 32) = true := by
  rw [dmemAddr8_net78_eq]
  intro h
  rcases Bool.eq_false_or_eq_true (ins 33 && ins 32) with hw | hw
  · exact hw
  · rw [hw] at h; simp at h

end SaltWorks.Silicon.Imported

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Silicon.Imported.dmemAddr8_we_out_is_index_3
  SaltWorks.Silicon.Imported.dmemAddr8_trap_is_index_2
  SaltWorks.Silicon.Imported.dmemAddr8_no_omitted_outputs
  SaltWorks.Silicon.Imported.dmemAddr8_bool_suppress
  SaltWorks.Silicon.Imported.dmemAddr8_net78_eq
  SaltWorks.Silicon.Imported.dmemAddr8_net72_eq
  SaltWorks.Silicon.Imported.dmemAddr8_we_out_excludes_trap
  SaltWorks.Silicon.Imported.dmemAddr8_we_out_implies_store_requested
end Audit

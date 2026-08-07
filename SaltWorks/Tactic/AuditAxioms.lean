/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Lean

/-!
# `#audit_axioms` — in-file axiom-dependency assertion

A command that turns the project's scratch-file `#print axioms` ceremony into a
committed, build-failing assertion. For each named declaration it collects the
same transitive axiom dependencies that `#print axioms` reports (via the kernel
environment traversal in `Lean.collectAxioms`), and it **fails elaboration** if
any dependency lies outside the project whitelist
`{propext, Classical.choice, Quot.sound}`. On success it logs a terse
`✓ name [n axioms]`.

This is a pure metaprogram: it adds no axioms of its own and uses no compiled /
`native_decide` evaluation. It merely inspects the environment the kernel has
already built.

## Usage

```
import Salt.Tactic.AuditAxioms
open Salt.Tactic

#audit_axioms Nat.add_comm Nat.mul_comm      -- ✓ each, or a build error naming the offender
```

Intended adoption: a single `#audit_axioms` block listing a track's headliner
declarations at the bottom of each track's `All.lean`. A dependency on a stray
axiom then fails `lake build` directly, rather than only at out-of-band lint
time.

## Extending the whitelist

`auditWhitelist` is an ordinary definition. A track that must (deliberately)
admit another axiom can rebind or extend it in its own namespace — the intent is
that every such extension is a visible, reviewed edit rather than a silent drift.
-/

namespace Salt.Tactic

open Lean Elab Command

/-- The axioms a project declaration is permitted to depend on: Lean's three
foundational axioms. Any other axiom in a declaration's transitive dependencies
is a hard error for `#audit_axioms`. -/
def auditWhitelist : List Name :=
  [``propext, ``Classical.choice, ``Quot.sound]

/-- Audit one resolved constant against `auditWhitelist`.

`collectAxioms` computes the transitive axiom dependencies exactly as
`#print axioms` does (the pre-computed per-module axiom table for imported
declarations, or a direct body walk for local ones). If every dependency is
whitelisted we log `✓ name [n axioms]`; otherwise we `throwError`, naming the
offenders. -/
def auditAxiomsOf (constName : Name) : CommandElabM Unit := do
  let axs ← collectAxioms constName
  let offenders := (axs.filter fun a => !auditWhitelist.contains a).qsort Name.lt
  if offenders.isEmpty then
    logInfo m!"✓ {constName} [{axs.size} axioms]"
  else
    -- Render names as a plain joined `String` (not an interpolated `List Name`)
    -- so the message is a single deterministic line, independent of the
    -- pretty-printer's width-driven line breaking.
    let render (ns : List Name) : String := ", ".intercalate (ns.map toString)
    throwError
      "#audit_axioms: '{constName}' depends on non-whitelisted axiom(s): \
       {render offenders.toList}. Allowed: {render auditWhitelist}. Extend \
       `Salt.Tactic.auditWhitelist` deliberately if this is intended."

/-- `#audit_axioms decl₁ decl₂ … declₙ` — assert that every listed declaration
depends only on the whitelisted axioms (`propext`, `Classical.choice`,
`Quot.sound`). Fails the build, naming the offender, on any other axiom
dependency; also fails on an unknown declaration name. Logs `✓ name [n axioms]`
per declaration on success. -/
elab (name := auditAxiomsCmd) "#audit_axioms" ids:ident+ : command => do
  for id in ids do
    -- Resolves overloads and *throws on an unknown name*, so both an unknown
    -- declaration and a non-whitelisted axiom are build errors.
    let cs ← liftCoreM <| realizeGlobalConstWithInfos id
    cs.forM auditAxiomsOf

end Salt.Tactic

/-! ## Self-tests (kernel-checked at build time via `#guard_msgs`)

The positive case (`Nat.add_comm`, axiom-clean) and the two failure paths — a
non-whitelisted axiom dependency, and an unknown name — are pinned below. If the
command's behavior regresses, these `#guard_msgs` blocks fail the build. -/

section Tests
open Salt.Tactic

/-- info: ✓ Nat.add_comm [0 axioms] -/
#guard_msgs in
#audit_axioms Nat.add_comm

-- Two whitelisted decls at once (multi-argument form).
/--
info: ✓ Nat.add_comm [0 axioms]
---
info: ✓ Nat.mul_comm [0 axioms]
-/
#guard_msgs in
#audit_axioms Nat.add_comm Nat.mul_comm

-- Failure path A: a declaration depending on a non-whitelisted axiom. We name
-- the reflection axiom `Lean.ofReduceBool` (introduced by `native_decide`)
-- directly — it is an axiom, so it depends on itself (plus `Lean.trustCompiler`)
-- and is not whitelisted.
/--
error: #audit_axioms: 'Lean.ofReduceBool' depends on non-whitelisted axiom(s): Lean.ofReduceBool, Lean.trustCompiler. Allowed: propext, Classical.choice, Quot.sound. Extend `Salt.Tactic.auditWhitelist` deliberately if this is intended.
-/
#guard_msgs in
#audit_axioms Lean.ofReduceBool

-- Failure path B: an unknown declaration name is a build error.
/-- error: Unknown constant `Salt.Tactic.thisDeclDoesNotExist` -/
#guard_msgs in
#audit_axioms Salt.Tactic.thisDeclDoesNotExist

/-! ### Failure path C: A BROKEN PROOF, which is the one that matters in practice

Measured 2026-08-06 (silicon seat, E1). A proof that fails leaves the environment
in exactly one of two states, and the two paths above cover them BOTH — but only
by accident of what they were written for, so the second one is pinned here
explicitly:

* **elaboration ABORTS** (heartbeat, recursion depth, kernel rejection) — the
  declaration is never added, the name does not resolve, and path B fires.
* **elaboration RECOVERS** (`sorry`, a failing tactic, a type mismatch) — the
  declaration IS added, carrying `sorryAx`, which is not whitelisted. **That is
  this test**, and nothing above exercised `sorryAx` specifically: path A uses
  `Lean.ofReduceBool`, an axiom nobody reaches by writing a bad proof.

There is no third state, which is why the claim *"a green tick from
`#audit_axioms` is not evidence the theorem exists"* was **false** and was
withdrawn from the campaign README. The tick cannot be printed for a broken
proof, and this file now fails the build if that ever stops being true. -/

/-- warning: declaration uses `sorry` -/
#guard_msgs in
theorem brokenProof : (2 : Nat) + 2 = 4 := by sorry

/--
error: #audit_axioms: 'brokenProof' depends on non-whitelisted axiom(s): sorryAx. Allowed: propext, Classical.choice, Quot.sound. Extend `Salt.Tactic.auditWhitelist` deliberately if this is intended.
-/
#guard_msgs in
#audit_axioms brokenProof

end Tests

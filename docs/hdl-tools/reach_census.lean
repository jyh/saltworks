/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
/-
⚠️ NON-LIBRARY METAPROGRAM — NOT part of `SaltWorks`, NOT reachable from the hub,
and it never should be.  It is a TOOL that imports the library in order to walk
its environment; counting it as a module the hub "fails to reach" is a category
error.  `docs/ledger-tools/import-closure.py` excludes non-`SaltWorks/` paths for
exactly this reason (and PRINTS the exclusion) -- but a file that relies on an
external filter to classify it correctly should say what it is, so: this is a
tool, and its home is `docs/`.

REACH CENSUS — "what is this theorem ABOUT?", answered by Lean rather than grep.

Run:  ../saltbuild.sh docs/hdl-tools/reach_census.lean
Cost: ~5m20s, ~5.6 GB peak.  It takes the fleet lock -- announce it.

## What it answers

For each theorem in a module OUTSIDE the hub closure, which IN-CLOSURE
definitions is it about?  Walks the STATEMENT type and unfolds only constants
declared in the SAME outside module, stopping at everything else.

That middle path is the whole trick, and it is why two shell-based attempts
failed on 2026-08-07:
  statement-only          missed `sub_via_adder_correct`, because
                          `theorem _ : subOK = true` never names `adder32` --
                          the link is inside `subOK`'s BODY
  unfold everything       drowned in `Circ` (41), `Net` (25), `Op` (13): the
                          types every theorem is written in

VALIDATED against a hand-derived ground truth: it must place `adder32` in the
class, via `sub_via_adder_correct`.  It does.

## ⛔ WHAT IT DOES **NOT** ANSWER, stated because the first run's header claimed
## it did

It computes "in-closure definitions REACHED BY outside theorems".  That is NOT
"definitions whose ONLY certificates are outside" -- for that the IN-closure
theorems' subjects must be subtracted.  Reading the raw reach list as the
stronger claim manufactures false positives.

## ✅ THE SUBTRACTION IS NOW PAID (2026-08-07 23:5x, compiler)

The header called it OWED from the day it was written, and a fleet seat read the
reach list as the stronger claim within three minutes of my publishing it -- so
it was not a theoretical debt.  `certifiedInside` now computes it and `report`
prints the residual.

**RESULT: residual 0.**  All nine reached definitions are certified inside the
hub, abundantly: `Stack.batcher8` 39, `Stack.runNet` 36, `Stack.extendIio` 25,
`Banyan.line` 22, `Silicon.runP` 20, `Silicon.Netlist` 11, `Stack.IsSorted` 6,
`ceCNL`/`ceCNL_outs` 3 each.  ⇒ **The outside modules are a BUILD-COVERAGE gap
(the nightly does not kernel-check those files), NOT a certification gap.**

⚖️ **Why the residual may be stated flatly despite a weak instrument.**
`certifiedInside` matches STATEMENT constants only, so it can MISS a certificate
whose link sits inside a body.  A missed certificate leaves a candidate wrongly
IN the residual ⇒ **this instrument can only OVERSTATE the residual.**  It
measured 0, and a residual cannot be negative, so the true residual is 0.  *The
weakness runs against the conclusion, which is what makes the conclusion safe --
had it measured 7, that number would be an upper bound and nothing more.*

📌 *The header used to cite `decQ`, `encD`, `wordOf`, `stepT` and "~15 false
positives".  Those describe the ROTTED four-module configuration and no longer
correspond to anything this tool prints; kept only as a record of the class.*

## Known leak

`isNoise` keeps only `.defnInfo` and drops `_proof`/`_aux`/`match_`/`._`, so
STRUCTURE PROJECTIONS survive (`Circ.outs`, `Circ.nIn`, `Seq.nIn`) and so do
EQUATION LEMMAS (`Seq.wf.eq_1`).  One layer better than drowning in types, and
the same shape.

## Scope -- DERIVED, not declared (fixed 2026-08-07 23:4x, compiler)

`outsideMods` USED TO BE hardcoded to four HDL modules "outside the hub as of
2026-08-07", with a note saying to regenerate it rather than trust it.  By that
evening **all four had been swept into the hub and the list was 100 % rotted** --
and because `reach` also used it to decide what counts as IN-closure, the rot
corrupted the classification, not merely the header.  *The warning was written,
read, and did not fire; a value that encodes a fact about the world needs a
derivation, not a caveat.*

It is now COMPUTED from the environment's recorded import graph: the closure of
`SaltWorks`, subtracted from the loaded `SaltWorks.*` modules.  `scopeReport`
prints it, and every verdict carries it -- a scope you cannot quote without.

Cross-checked 2026-08-07 23:4x against an independent instrument (a Python regex
over `^import` lines): both say FIVE, and name the same five.  Note the Lean
figure counts modules LOADED here; `Scratch*.lean` are gitignored working files
and are outside the hub by construction -- a filesystem walk that counts them
reports 13 and disagrees with every tracked-file census.
-/
import SaltWorks
import SaltWorks.Silicon.Equiv.CERefinement
import SaltWorks.Silicon.Equiv.CERefinementC
import SaltWorks.Silicon.Equiv.PartialLoad
import SaltWorks.Silicon.Equiv.ScenarioComplete
import SaltWorks.Silicon.Imported.CompareExchange

open Lean

namespace SaltWorks.Reach

/-- Modules reachable from `root` by following recorded imports. -/
def closureOf (env : Environment) (root : Name) : NameSet := Id.run do
  let names := env.header.moduleNames
  let data  := env.header.moduleData
  let mut idx : Std.HashMap Name Nat := {}
  for i in [0:names.size] do
    idx := idx.insert names[i]! i
  let mut seen : NameSet := {}
  let mut todo : List Name := [root]
  while !todo.isEmpty do
    match todo with
    | [] => pure ()
    | m :: rest =>
      todo := rest
      if !seen.contains m then
        seen := seen.insert m
        if let some i := idx[m]? then
          if let some d := data[i]? then
            for imp in d.imports do
              todo := imp.module :: todo
  return seen

/-- The `SaltWorks.*` modules loaded here that are NOT in the hub's closure.
DERIVED — see the Scope note.  Never hardcode this. -/
def outsideModsOf (env : Environment) : Array Name :=
  let cl := closureOf env `SaltWorks
  (env.header.moduleNames.filter
    (fun m => (`SaltWorks).isPrefixOf m || m == `SaltWorks)).filter (fun m => !cl.contains m)

/-- Scope line, printed BEFORE the expensive walk so a killed run still
answers the cheap question. -/
def scopeReport : CoreM Unit := do
  let env ← getEnv
  let outside := outsideModsOf env
  let all := env.header.moduleNames.filter
    (fun m => (`SaltWorks).isPrefixOf m || m == `SaltWorks)
  IO.println s!"SCOPE  loaded {all.size} SaltWorks modules · in closure {all.size - outside.size} · OUTSIDE {outside.size}"
  for m in outside do IO.println s!"  outside: {m}"

#eval scopeReport

def modOf (env : Environment) (n : Name) : Option Name := do
  let idx ← env.getModuleIdxFor? n
  env.header.moduleNames[idx.toNat]?

/-- Transitive statement-constants, unfolding only defs declared in `home`.
`outside` is the DERIVED outside-module set (see `outsideModsOf`); it decides
what counts as in-closure, which is why hardcoding it corrupted classification
and not merely the header. -/
partial def reach (env : Environment) (outside : NameSet) (home : Name) (seen : NameSet)
    (todo : List Name) (acc : NameSet) : NameSet :=
  match todo with
  | [] => acc
  | n :: rest =>
    if seen.contains n then reach env outside home seen rest acc else
    let seen := seen.insert n
    match env.find? n with
    | none => reach env outside home seen rest acc
    | some ci =>
      let m := modOf env n
      if m == some home then
        -- local helper: unfold its TYPE and its VALUE
        let next := ci.type.getUsedConstants.toList
                      ++ (ci.value?.map (·.getUsedConstants.toList) |>.getD [])
        reach env outside home seen (next ++ rest) acc
      else
        let acc := if m.isSome && !(outside.contains m.get!) then acc.insert n else acc
        reach env outside home seen rest acc

/-- Substring test. -/
def has (s pat : String) : Bool := (s.splitOn pat).length > 1

/-- Internal / machinery names that are vocabulary rather than subject.
Only DEFINITIONS are subjects: types, constructors and projections are the
language every theorem is written in, which is why a scan that keeps them
drowns in `Circ`, `Gate` and `Op`. -/
def isNoise (env : Environment) (n : Name) : Bool :=
  let s := n.toString
  match env.find? n with
  | some (.defnInfo _) => has s "_proof" || has s "_aux" || has s "match_" || has s "._"
  | _                  => true

/-- For each candidate, the IN-CLOSURE theorems that name it in their STATEMENT.
Statement-only by design: see the BOUND note in the header — missing a
certificate can only overstate the residual, never understate it. -/
def certifiedInside (env : Environment) (cands : NameSet) : Std.HashMap Name (Array Name) := Id.run do
  let cl := closureOf env `SaltWorks
  let mut hit : Std.HashMap Name (Array Name) := {}
  for (n, ci) in env.constants.toList do
    if ci matches .thmInfo _ then
      if !(has n.toString "_proof") then
        match modOf env n with
        | some m =>
          if cl.contains m && (`SaltWorks).isPrefixOf m then
            for c in ci.type.getUsedConstants do
              if cands.contains c then hit := hit.insert c ((hit.getD c #[]).push n)
        | none => pure ()
  return hit

def report : CoreM Unit := do
  let env ← getEnv
  let outsideArr := outsideModsOf env
  let outside : NameSet := outsideArr.foldl (fun s m => s.insert m) {}
  -- INVERT the map: in-closure definition -> the outside theorems about it.
  let mut inv : Std.HashMap Name (Array Name) := {}
  for home in outsideArr do
    for (n, ci) in env.constants.toList do
      if modOf env n == some home then
        if ci matches .thmInfo _ then
          if !(has n.toString "_proof") then
            let hits := reach env outside home {} ci.type.getUsedConstants.toList {}
            for h in hits.toList do
              if (`SaltWorks).isPrefixOf h && !(isNoise env h) then
                inv := inv.insert h ((inv.getD h #[]).push n)
  let ks := inv.toList.toArray.qsort (fun a b => b.2.size < a.2.size)
  -- ⛔ HEADLINE FIXED 2026-08-07 (compiler).  This line USED to read "whose only
  -- certificates live OUTSIDE the hub" -- the stronger claim this tool's own
  -- header says it does NOT compute, and which manufactures ~15 false positives.
  -- The docstring corrected it; the PRINTED line asserted it, and the printed
  -- line is the one that gets quoted.  A correct body does not repair a
  -- quotable headline.
  IO.println s!"IN-CLOSURE DEFINITIONS REACHED BY outside theorems: {ks.size}"
  IO.println s!"  [scope: {outsideArr.size} outside modules — {outsideArr.toList}]"
  for (d, thms) in ks do
    IO.println s!"  {d}   <- {thms.size} outside theorem(s): {thms.toList.take 3}"
  -- THE SUBTRACTION.  Owed since this file was written; paid 2026-08-07.
  let cands : NameSet := ks.foldl (fun s (d, _) => s.insert d) {}
  let inside := certifiedInside env cands
  let mut residual : List Name := []
  IO.println ""
  IO.println "SUBTRACTION — which of the above are ALSO certified INSIDE the hub?"
  for (d, _) in ks do
    match inside[d]? with
    | some ws => IO.println s!"  inside-certified  {d}  <- {ws.size} in-closure thm(s): {ws.toList.take 2}"
    | none    => residual := d :: residual
  IO.println s!"RESIDUAL — reached from outside with NO in-closure certificate: {residual.length}"
  for d in residual.reverse do IO.println s!"    {d}"
  IO.println "  [BOUND: `certifiedInside` matches STATEMENT constants only, so it can MISS"
  IO.println "   a certificate whose link is in a body. That can only OVERSTATE the residual,"
  IO.println "   so residual 0 is exact and any residual > 0 is an UPPER BOUND.]"
  IO.println "  [SCOPE: candidates are IN-CLOSURE definitions only. Objects DEFINED in the"
  IO.println "   outside modules (e.g. `ceNL`) are never candidates — this says NOTHING"
  IO.println "   about them, and nothing about the build-coverage gap itself.]"

#eval report

end SaltWorks.Reach

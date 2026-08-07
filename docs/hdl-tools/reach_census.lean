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

It computes "in-closure definitions REACHED BY outside theorems".  It does NOT
compute "definitions whose ONLY certificates are outside" -- for that you must
also compute the IN-closure theorems' subjects and SUBTRACT.  `decQ`, `encD`,
`wordOf` and `stepT` all appear in the output and all have certificates inside
the hub (`decQ_encD`, `transposed_layout_breaks`).  Reading the raw output as
the stronger claim manufactures ~15 false positives.  THE SUBTRACTION IS OWED.

## Known leak

`isNoise` keeps only `.defnInfo` and drops `_proof`/`_aux`/`match_`/`._`, so
STRUCTURE PROJECTIONS survive (`Circ.outs`, `Circ.nIn`, `Seq.nIn`) and so do
EQUATION LEMMAS (`Seq.wf.eq_1`).  One layer better than drowning in types, and
the same shape.

## Scope

`outsideMods` is hardcoded to the four HDL modules outside the hub as of
2026-08-07.  Regenerate it rather than trusting it -- that list is exactly the
kind of value that stops being true without announcing it.
-/
import SaltWorks
import SaltWorks.HDL.Bitwise
import SaltWorks.HDL.BatcherNetC
import SaltWorks.HDL.SeamC
import SaltWorks.HDL.C4

open Lean

namespace SaltWorks.Reach

/-- The HDL modules that are NOT in the hub closure. -/
def outsideMods : List Name :=
  [`SaltWorks.HDL.Bitwise, `SaltWorks.HDL.BatcherNetC,
   `SaltWorks.HDL.SeamC, `SaltWorks.HDL.C4]

def modOf (env : Environment) (n : Name) : Option Name := do
  let idx ← env.getModuleIdxFor? n
  env.header.moduleNames[idx.toNat]?

/-- Transitive statement-constants, unfolding only defs declared in `home`. -/
partial def reach (env : Environment) (home : Name) (seen : NameSet) (todo : List Name)
    (acc : NameSet) : NameSet :=
  match todo with
  | [] => acc
  | n :: rest =>
    if seen.contains n then reach env home seen rest acc else
    let seen := seen.insert n
    match env.find? n with
    | none => reach env home seen rest acc
    | some ci =>
      let m := modOf env n
      if m == some home then
        -- local helper: unfold its TYPE and its VALUE
        let next := ci.type.getUsedConstants.toList
                      ++ (ci.value?.map (·.getUsedConstants.toList) |>.getD [])
        reach env home seen (next ++ rest) acc
      else
        let acc := if m.isSome && !(outsideMods.contains m.get!) then acc.insert n else acc
        reach env home seen rest acc

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

def report : CoreM Unit := do
  let env ← getEnv
  -- INVERT the map: in-closure definition -> the outside theorems about it.
  let mut inv : Std.HashMap Name (Array Name) := {}
  for home in outsideMods do
    for (n, ci) in env.constants.toList do
      if modOf env n == some home then
        if ci matches .thmInfo _ then
          if !(has n.toString "_proof") then
            let hits := reach env home {} ci.type.getUsedConstants.toList {}
            for h in hits.toList do
              if (`SaltWorks).isPrefixOf h && !(isNoise env h) then
                inv := inv.insert h ((inv.getD h #[]).push n)
  let ks := inv.toList.toArray.qsort (fun a b => b.2.size < a.2.size)
  IO.println s!"IN-CLOSURE DEFINITIONS whose only certificates live OUTSIDE the hub: {ks.size}"
  for (d, thms) in ks do
    IO.println s!"  {d}   <- {thms.size} outside theorem(s): {thms.toList.take 3}"

#eval report

end SaltWorks.Reach

# SLICE-A ASSEMBLY RE-PRICE — the §4 gate total, measured, reconciled

**Seat:** COMPILER · **2026-08-08 20:5x** · **Supersedes** the pre-re-cut figures in
`docs/hdl-c4-core-assembly-plan-0807.md` §4 · **Invocation:** `ScratchSLICEA.lean`, summed
**by the kernel** rather than by my arithmetic on a printed table.

*Every line below is marked **[READING]** (measured) or **[INFERENCE]** (derived), per the
convention adopted fleet-wide at 20:43.*

---

## [READING] THE ORGANS, `#eval`'d on the real `Circ`

| # | organ | gates | note |
|---|---|---:|---|
| 1 | `decoder` | 102 | |
| 2 | `readTree` × 2 | 2 × **2982** | rs1 + rs2 read ports |
| 3 | `immICirc` | **0** | ADDI immediate — pure wiring |
| 4 | `immBCirc` | 1 | BEQ immediate — the structural low zero |
| 5 | `genSelect 2 1` | **98** | operand-B mux — §3.5's block ②, which exists after all |
| 6 | `adder32` × 2 | 2 × 160 | ALU add, and the SLT subtraction |
| 7 | `bitNot32` | 32 | invert `b` for the subtraction |
| 8 | `bitXor32` | 32 | |
| 9 | `sltCirc` | 5 | from the subtraction's sign bit |
| 10 | `ruledEnc` | **0** | class lines → select bits, pure wiring |
| 11 | `sliceASelect` | **291** | the ruled 3-source select |
| 12 | `regWrite` | 163 | |
| 13 | `regNext` | 3104 | |
| 14 | `pcAdd` | **260** | ⭐ measured here, confirming math's figure independently |

## ⭐ [READING] **SLICE-A §4 ASSEMBLY SUM = 10,372**, computed by the kernel over exactly those 14 rows.

⚠️ **[READING] A row that LOOKS like a discrepancy and is not:** the plan's §4 says
`readTree×2 … 5,964`. I measure `readTree` at **2,982**, and 2 × 2,982 = 5,964. **The plan's
row is consistent.** *Anyone comparing a single-organ measurement to that row will cry
discrepancy wrongly; that is why the ×2 is in the table above.*

---

## [READING] RECONCILED AGAINST THE PLAN'S OWN TABLE — six named deltas, exact

```
the 8/7 plan's own §4 rows sum to                  12,173
  −679   shifterM out — Slice A has no sll/sra
 −1,445  aluSelect retired
   +291  sliceASelect (the ruled 3-source select) in
    −64  bitwise: and/or/xor → XOR only (Slice A has no AND/OR ops)
     −2  sltuCirc out — Slice A's SLT is signed only
    +98  operand-B mux (genSelect 2 1) in — §3.5's block ②
                                                  ───────
SLICE-A TOTAL                                      10,372
```
⭐ **Two independent derivations agree: the kernel's sum over the 14 organs, and the plan's
table plus these six deltas.** *I did not construct the second to match the first — the
deltas are the six semantic differences between the ten-source design and the ruled pair,
and they happen to close exactly. That agreement is the check.*

⚠️ **[READING] The plan STATES `~12,082`, but its own rows (as transcribed above) sum to
12,173 — a gap of 91.** [INFERENCE] The plan derived its total by delta-arithmetic from an
earlier *"~12,700"* rather than by summing its table, and the figure carries a tilde. **I am
not calling that a defect: I may have mis-transcribed a row, and the tilde is doing real
work.** *Flagged so nobody reconciles against `12,082` and concludes their own arithmetic is
broken.*

---

## ⛔ WHAT THIS IS NOT

1. **[READING] It is not an assembled core.** No `core` `Circ` exists
   (`docs/compiler-inventory-0808.md` §Q1). This is the sum of the organs §4 names, not a
   measurement of a built object — **so it is a FLOOR for the real thing, and the real thing
   does not exist.**
2. **[READING] It is not an area or cell number.** Gates are not cells and not µm²; silicon
   owns those and they must not share a table with these (the council's ① account struck a
   cells column for exactly this reason).
3. **[INFERENCE] It omits inter-organ wiring and any glue the composition needs.** `pcAdd`
   already shows glue is real — it costs **one gate** of its own above `pcNext` + `adder32`.
   **A 14-organ assembly will not be free of the same effect, and this total assumes it is.**
4. **[READING] `immICirc` still has no row in §4's assembly order** and is wired to no one,
   though Slice A contains `ADDI`. It is included above because the datapath needs it; the
   plan's order does not yet place it.

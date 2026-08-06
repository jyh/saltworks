# `src/config.json` — why these two numbers, and why nothing else

JSON has no comments, and `src/config.json` is read by a schema-validating tool.
Commentary belongs here, not in there: a `"//"` key is a setting to a parser that
does not know it is a joke, and duplicate `"//"` keys are not even reliably legal
JSON. The file ships with exactly two keys.

## `CLOCK_PERIOD: 20`

20 ns is 50 MHz — **deliberately faster than the 25 MHz `info.yaml` requests**,
so signoff carries ~2× setup margin over the rate we claim. The core is nowhere
near binding: the data path is three stages of two-way muxing, a handful of gate
delays.

The real ceiling is not the core, it is the pad: **the TT pad's maximum OUTPUT
rate is 33 MHz, half its input ceiling**, and a bit-serial fabric toggles every
output every cycle. That is why `info.yaml` asks for 25 MHz rather than the
template's 50.

⚠️ **This buys nothing on HOLD.** Lowering (or raising) the target clock fixes
setup only; hold is a function of the placed netlist, is checked by the flow on
**all** corners, and is the residual risk on this design. Do not read the setup
margin as safety.

## `PL_TARGET_DENSITY_PCT: 60`

TT's docs say 60; TT's FAQ says 62. They disagree, and 60 is the documented
default. It is not a close call here either way: the wrapper synthesizes to
**268 cells / 2,143 µm² — 11.9 % of one tile, 3.0 % of the four bought**, so
placement density is far from binding.

## What is deliberately NOT here

`DESIGN_NAME`, `VERILOG_FILES`, `DIE_AREA`, `FP_DEF_TEMPLATE`, `VDD_PIN`,
`GND_PIN`, `RT_MAX_LAYER`.

`tt_tool.py --create-user-config` writes those into `src/user_config.json`, and
`create_merged_config` applies user_config **last**:

```python
config = read_config("src/config")
config.update(user_config)
```

So any of those keys set here is **silently discarded** — it would read as a
setting and behave as a no-op. If a flow experiment appears to have had no
effect, this is the first thing to check.

## The one that would fail the chip, not the build

**No `met5`.** The precheck hard-fails on `met5.drawing/pin/label` because TT's
power grid owns that layer, and routing is capped at `RT_MAX_LAYER = met4` —
which, per the paragraph above, is set in `user_config.json` and cannot be
overridden from here. Nothing in this design asks for met5; the note is here
because the failure mode is a precheck red, not a lint warning.

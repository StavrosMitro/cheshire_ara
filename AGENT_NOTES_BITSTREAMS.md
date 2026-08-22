# ZCU102 Cheshire+Ara — Bitstream Inventory

All bitstreams live in `/home/stavros/bitstreams/` (local, not on the sshfs mount — Vivado Lab
reads them from there via `$::BITDIR` in `tcl/ila_capture.tcl`). Every `.bit` has a matching
`.ltx` (probe/debug-core definitions for that exact build) when it carries any ILA/VIO — program
them together, an `.ltx` from a different build gives wrong or missing probe names.

Written after `AGENT_NOTES_ZCU102.md` (the full multi-session debugging log this inventory used
to be a small part of, §16–19 in particular) disappeared from the filesystem on 2026-08-21 —
never git-tracked, no recovery path, cause unknown. This file exists so "which bitstream is which"
survives even if that happens again. Confidence is marked per entry: **CONFIRMED** means directly
tested this investigation and the result is known; everything else is inferred from filename/date
correlation with what's independently known about that period, not independently re-verified.

---

## Local cleanup, 2026-08-21

All July-dated `.bit`/`.ltx` files deleted from `/home/stavros/bitstreams/` (12 files: `v6`, `v7`,
`no_llc`, `with_llc`, `less_signals_llc_fifo`, `jul8_no_p0_probes`, `jul9_p0_levels`,
`jul27_prefix`, each `.bit`+`.ltx` pair counted once). `v1`–`v5` (June-dated) and `jul29_v1fix`
(named for July but actually copied 2026-08-04) were kept — deletion was scoped to actual file
mtime, not name. The historical-table entries for the deleted files above are left in this
document for reference even though the files themselves are gone.

## Probe-strip in progress, 2026-08-21 (Stage 2 of the utilization-cleanup plan)

Every `(* mark_debug *)` ILA probe and its associated `dbg_*` signal declarations/logic has been
removed from the live RTL tree (not just the attribute — the underlying counters/sticky-bits/FSM
taps were real synthesized logic and had to go too for a trustworthy utilization number). Scope:
`hw/cheshire_soc.sv`, `target/xilinx/src/cheshire_top_xilinx.sv`,
`target/xilinx/src/phy_definitions.svh` (dead `` `define ila(...) `` macro, never invoked),
`cva6_patched/core/cva6.sv`, `cva6_patched/core/load_unit.sv`, and all 5 files under
`cva6_patched/core/cache_subsystem/` that had probes (`wt_axi_adapter.sv`,
`wt_dcache_wbuffer.sv`, `wt_dcache_ctrl.sv`, `cva6_icache.sv`, `wt_dcache_missunit.sv`).
`deps/ara/hardware/` was confirmed to have zero probe instrumentation — nothing to touch there.

VIO was investigated separately and found to need NO removal: `` `define USE_VIO `` has been
commented out for zcu102 since the K1 era (`target/xilinx/src/phy_definitions.svh`, "stays OFF
on purpose") — `i_vio` was never actually synthesized into any zcu102 bitstream, confirmed
empirically (`get_hw_vios` returns empty on the Part E build). The `vio i_vio(...)` instantiation
and `CHS_XILINX_IPS_zcu102 := clkwiz vio zynqmp` IP-list entry are still present in source but are
dead code for this board and cost nothing in the bitstream — not worth touching for a utilization
measurement.

Verified clean two ways: `grep -rl "mark_debug"` across `hw/`, `target/xilinx/src/`,
`cva6_patched/`, `deps/ara/hardware/` returns zero hits outside `.bak*` files; and a begin/end
count-delta check per edited file (the delta between `begin` and `end` occurrences, which is a
per-file structural constant unrelated to mark_debug — driven by things like `endmodule`/`endcase`
that don't pair with a `begin` — was confirmed IDENTICAL before/after every edit, proving each
removed block was self-contained and nothing was left dangling).

★ Backups, two layers: a full pre-strip copy of all 10 files at
`/home/stavros/bitstreams/probes_snapshot_20260821/` (mirrors each file's repo-relative path —
restore the whole instrumented tree in one step if a future session needs the probes back), plus
individual `<file>.bak_20260821_probestrip` copies next to each live file, matching this repo's
existing per-edit backup convention.

**NOT YET BUILT.** RTL edits are done and verified; the actual synth+impl+bitstream run (needed
for the Stage-2 utilization number) hasn't happened yet — same division of labor as Part E: edits
prepared here, build has to run on coroni.

---

## Currently programmed / recommended

**`cheshire_top_xilinx_partE_verified_20260821.bit` (+ `.ltx`)** — CONFIRMED, 2026-08-21.

The permanent NI-DRAM fix (`Cva6NiDramRule` config field, replaces the old `ni_disable_i` VIO
diagnostic switch entirely — NI is fixed in RTL, not toggled at runtime). No VIO core: confirmed
via `get_hw_vios` returning empty on connect. Has 1 ILA core (probes intact, not yet the
probe-free build the utilization-cleanup plan calls for). Verified with `vggnet_k7.fpga.bin`
(batch=4, 10 epochs, 400-image real CIFAR-100-C slice, pretrained-checkpoint fine-tune) via the
sentinel protocol, 3/3 clean: exit `0x0`, 467s each run, byte-identical timing across all three.
This is the first time the permanent fix has been built or run — it was RTL-complete and sitting
untouched for two days before this test.

This is also what `cheshire_top_xilinx.bit`/`.ltx` (the unsuffixed "currently active" pointer,
read by every `vivado_lab -mode tcl` script) currently points at — same file, copied under both
names.

**Use this one** unless you're specifically testing something else. Next planned step (see the
approved plan, "Part E bitstream: verify, strip probes, measure utilization...") is a probe-free
rebuild of this same RTL for a clean utilization baseline — that will supersede this file for
*measurement* purposes but this one stays the reference "known-good, fully probed" build.

---

## Known-good, superseded

**`cheshire_top_xilinx_preNIfix_vio_20260819_1045.bit` (+ `.ltx`)** — CONFIRMED, 2026-08-19.

The bitstream every hardware test in this investigation ran on before Part E: `ni_disable_i` VIO
switch (set via `vio_set_ni_disable 1` through `tcl/k1_arm.tcl`/`tcl/ila_capture.tcl`), NI-DRAM
deadlock worked around at runtime rather than fixed in RTL. Extensively tested and confirmed
working: fmatmul (3/3 pass), fc_layer (3/3 pass, exit 0x2 — reported error count, not a hang),
vggnet through several iterations (crashed on missing syscall stubs → fixed; crashed on a
`printf.h`-shadowing bug → fixed; crashed on a genuine Ara RTL bug in float vector reductions →
worked around in `batchnorm_layer.c`; then 3/3 clean at both the 2-step smoke-test size and the
full 10-epoch/400-image size). Keep — this is the fallback if Part E ever needs to be
bisected against the old mechanism.

**`cheshire_top_xilinx_pre_k1final_aug16_1121.bit` (+ `.ltx`)** — inferred, 2026-08-16.

Name and date line up with the NI-DRAM root-cause session (icache/load_unit/wbuffer speculative-
fetch deadlock, `is_inside_nonidempotent_regions` on the DRAM rule). Most likely the build that
first added the `ni_disable_i` VIO switch and probe set used for the K1/K1F sentinel-protocol
measurement runs that proved the NI-DRAM rule was the cause (15/15 frozen-with-switch-off,
alive-with-switch-on). Not independently re-tested this round — superseded by the two entries
above either way.

---

## Historical / investigation-specific — not recommended for new work

Dates below are the file's own mtime; several bitstreams are consistent with a session's *name*
in `AGENT_NOTES_ZCU102.md` but the correspondence is inferred, not re-verified.

| File | Date | Best-guess identity |
|---|---|---|
| `cheshire_top_xilinx_preF1_20260805.bit`/`.ltx` | 08-05 | Matches the old notes' §15.1 citation exactly ("2026-08-05 12:03, 93 probes/575 bits") — the bitstream behind the whole F1/H1/I1/J2 CVA6 D-cache investigation (MSHR-stuck hypothesis raised and later refuted). |
| `cheshire_top_xilinx_jul27_prefix.bit`/`.ltx` | 07-27 | Matches the round-2 probe rework session (conservation counters + wedge detector replacing round-1 level probes) and the LLC-flush-poll-bug fix. |
| `cheshire_top_xilinx_jul29_v1fix.bit`/`.ltx` | copied 08-04, named for 07-29 | Likely carries the Ara sequencer lost-request fix (`ara_sequencer.sv`, addrgen-exception/indexed-load ordering, two upstream commits applied as patches). |
| `cheshire_top_xilinx_aug7.bit`/`.ltx` | 08-07 | Probe-set iteration between the preF1 and Aug-8 builds. Not independently identified further. |
| `cheshire.zcu102.bit`/`.ltx` | 08-08 00:26 | Unclear which specific change; 4 minutes older than the next entry, likely the same content copied under two names. |
| `cheshire_top_xilinx_f2_aug8.bit`/`.ltx` | 08-08 00:30 | See above. |
| `cheshire_top_xilinx_jul9_p0_levels.bit`/`.ltx` | 07-09 | Round-1 (level-probe style) P0 instrumentation, before the round-2 counter-based rework. |
| `cheshire_top_xilinx_jul8_no_p0_probes.bit`/`.ltx` | 07-08 | P0 probes stripped for that day's build — one day before the p0_levels build above re-added them. |
| `cheshire_top_xilinx_less_signals_llc_fifo.bit` | 07-07 14:44 | Reduced-probe-count LLC/FIFO-related variant. No `.ltx` present — probe names for this one are lost even if the bitstream is still valid. |
| `cheshire_top_xilinx_with_llc.bit` | 07-07 10:54 | LLC not bypassed (counterpart to `no_llc` below). No `.ltx`. |
| `cheshire_top_xilinx_no_llc.bit` | 07-02 19:43 | LLC-bypass (`LlcNotBypass=0`) change from the 2026-07-02 bring-up session — CVA6 write-through stores reach DDR live, no sweep-to-evict needed. No `.ltx`. |
| `cheshire_top_xilinx_v7.bit`/`.ltx` | 07-02 13:59 | First `.ltx` in the early sequence; date matches "CORE CONFIRMED WORKING" (memtest3 + ILA proof of clock/reset/fetch/DDR read+write) — plausibly *the* bitstream that proved the core alive, but not certain which of v1–v7 that capture actually used. |
| `cheshire_top_xilinx_v1.bit` … `v6.bit` | 06-26 to 07-02 | Early bring-up iterations (clock-pin fix, MMCM retune, LUT-overflow/synthesis-strategy fix, `.ltx` copy-guard fix). No `.ltx` on any of these — pre-dates ILA probe instrumentation entirely. Sequential attempts, not individually identified. |

---

## Gaps / things to fix if this file is used going forward

- Several historical builds have no `.ltx` at all (`no_llc`, `with_llc`, `less_signals_llc_fifo`,
  `v1`–`v6`) — if one of these is ever reprogrammed, `ila_attach`/`ila_connect` will fail to find
  probes even if the bitstream itself is fine. Not a bug, just means those are bit-only artifacts.
- The `v1`–`v6` correspondence to specific §4-era fixes (HP0 datapath, clock pin, LUT overflow)
  was not re-derived this pass — if that history matters later, it needs someone to actually
  bisect-test them, not just trust the sequential naming.
- If `AGENT_NOTES_ZCU102.md`'s full history is worth reconstructing (not just this bitstream
  slice), the conversation transcript this file was written from still has the complete §1–19
  content in-context and can regenerate it on request.

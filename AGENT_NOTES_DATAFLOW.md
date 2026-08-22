# ZCU102 Cheshire+Ara — Phase 2: Dataflow & Scalar Utilisation

**Started 2026-08-20.** Repo root (sshfs mount): `/home/stavros/sshfs_dir` == server `~/cheshire_soc`.

> **Phase 1 (bring-up) is archived in [`fpga_port_archive.md`](fpga_port_archive.md)** — §1-19, the port,
> the two NI root causes, the Ara reduction bug, the app build artefacts. Read it if you need *why the
> machine works*. Read **this** file if you need *how to make it fast*.

**Phase 2 question:** given a memory hierarchy we have now actually measured, how should the training
dataflows be laid out, and can the idle scalar core be put to work?

---

## 0. Status line

| | |
|---|---|
| Machine correctness | ✅ vggnet runs clean on HW (archive §19.6) — via the `ni_disable` VIO workaround |
| **Permanent NI fix (`Cva6NiDramRule`)** | ❌ **RTL written, NEVER SYNTHESISED.** Gates everything below. |
| Dataflow design | 🔵 this document |
| Anything measured on HW in Phase 2 | ❌ none yet — all Phase 2 numbers are from Phase 1 ILA captures + RTL |

**Nothing in this file has been validated on hardware in Phase 2.** Latencies (§2) are re-read from a
Phase 1 capture; everything else is derived from RTL constants or arithmetic. Marked per-claim below.

---

## 1. The machine, as verified in RTL

Every row here was read from the source this session, not recalled.

| Parameter | Value | Source |
|---|---|---|
| `soc_clk` | **50 MHz** (300 MHz sys_clk in, MMCM /24) | `impl_sys.tcl:53`, archive §5 |
| `AxiDataWidth` (crossbar) | **64 bit** | `hw/cheshire_pkg.sv:581` |
| Ara lanes / VLEN | **`NR_LANES=2`, `VLEN=2048`** | `target/xilinx/scripts/add_sources.zcu102.tcl:673-674` |
| Ara `FPUSupport` | `FPUSupportHalfSingleDouble` — **FP16/32/64 all synthesised** | `deps/ara/hardware/src/ara.sv:14`, not overridden by Cheshire |
| LLC | 8 ways × 256 lines × 8 blocks × 8 B = **128 KiB**, 64 B line | `cheshire_pkg.sv:621-626`, `:287-289` |
| SPM | at `AmSpm = 0x1000_0000`, sized `= get_llc_size()`, ways selected by `CFG_SPM` @ `0x0300_1000` | `cheshire_pkg.sv:373-377` |
| **SPM is cached in L1-D** | `AmSpm` ∈ `CachedRegionAddrBase` | `cheshire_pkg.sv:534` |
| L1-D | **8 KiB, 4-way, 32 B line (=256 bit), 64 sets, write-through** | `cva6_patched/core/include/cv64a6_imafdcv_sv39_config_pkg.sv:44-46`, `:72` |
| L1-I | 4 KiB, 4-way, 16 B line | same file `:41-43` |
| **L1-D outstanding read misses** | **1** — *"currently we only have one outstanding read TX"* | `wt_dcache_missunit.sv:220`; `mask_reads = mshr_vld_q` at `:448` |
| `NrLoadBufEntries` | 2 | config pkg `:60` |
| `WtDcacheWbufDepth` | 8 | config pkg `:54` |
| CVA6 packed SIMD | **`XFVec = 0`, `XF16 = 0`, `XF8 = 0`** (plumbed but off) | config pkg `:18-21`; `fpu_wrap.sv:65`, `decoder.sv:471` |
| `Dma` on zcu102 | **0** (disabled) | `target/xilinx/src/cheshire_top_xilinx.sv:119` |
| DMA capability *if enabled* | `DmaConfEnableTwoD=1`, `DmaNumAxInFlight=16` | `cheshire_pkg.sv:658-659` |

### Which CVA6 tree actually compiles
`Bender.lock:105-109` pins `cva6` to a **Path source**, `/home/smitropoulos/cheshire_soc/cva6_patched`
— *not* the `mp-17/cva6 @ mp/pulp-v2` git rev in `Bender.yml:25`. The lock overrides it. So
`cva6_patched/` is the live tree (it carries the Phase 1 NI guards). Cross-checked: the copy under
`deps/ara/hardware/deps/cva6/` has byte-identical cache params, so the numbers hold either way.

---

## 2. Memory hierarchy — MEASURED

Re-read from the Phase 1 capture `iladata_K4_A_pad2_transition.csv` (CVA6 AR→R timestamps,
`p3` = the LLC's DRAM-side port):

| Path | Cycles | How |
|---|---|---|
| **L1-D miss → LLC hit** | **17** | AR@2048 → R@2065, `p3` never moved. Split: 4 in + 11 LLC + 2 back |
| **LLC → DDR round trip** | **~31** | p3 samples: 31, 36, 31, 30, 31, 31, 31, 30, 31 |
| **L1-D miss → LLC miss → DDR** | **~48** | 17 + 31; cross-checks archive §15.6h's 45-cycle miss-to-miss spacing |
| **Peak bandwidth** | **8 B/cycle = 400 MB/s** | 64 bit @ 50 MHz — *derived* |

Context: a real Ara L2 is ~7 cycles. Ours is 17. That gap is the premise of this whole phase.

---

## 3. ★ AXI topology — the constraint that governs everything

**Ara and CVA6 are separate masters on the same 64-bit crossbar.**

```systemverilog
localparam int unsigned AraDataWideWidth = 32 * Cfg.AraNrLanes;   // = 64 with NrLanes=2
axi_dw_converter #(.AxiSlvPortDataWidth(64), .AxiMstPortDataWidth(64))  // PASS-THROUGH
assign axi_in_req[AxiIn.ara] = axi_ara_narrow_req;                // its own crossbar port
```
`hw/cheshire_soc.sv:1001`, `:1065`, `:1139`

Ara's so-called *wide* port is 64 bits — **exactly CVA6's width**, and the down-converter is a no-op at
2 lanes. Consequences, and they are not negotiable:

1. **Concurrency adds zero bandwidth.** Every byte the scalar core moves is a byte Ara does not get.
   Any "run the scalar core in parallel" plan is a bandwidth *allocation* decision, not a parallelism win.
2. The 400 MB/s of §2 is the **whole machine's** ceiling, shared.
3. Widening Ara's port means raising `NrLanes` (→ `AraDataWideWidth = 32×NrLanes`), which is a LUT
   decision, not a memory one.

---

## 4. Compute throughput per precision — DERIVED

Each Ara lane is a 64-bit datapath; 2 lanes = 128 bit/cycle of elements.

| | FMA/cyc | peak @50 MHz | elem/cyc from mem | **balance (flop/byte)** |
|---|---|---|---|---|
| FP64 | 2 | 200 MFLOP/s | 1 | 0.5 |
| **FP32** | 4 | **400 MFLOP/s** | 2 | **1.0** |
| **FP16** | 8 | **800 MFLOP/s** | 4 | **2.0** |

Memory is fixed at 8 B/cyc, so **the required arithmetic intensity doubles with each step down in
precision.** Lower precision does not make the memory problem easier — it makes it twice as hard.

**But tiling requirement is precision-invariant.** For a `T×T×T` block, AI = `T/s` (s = bytes/element):
```
FP64: T/8 ≥ 0.5 → T ≥ 4      FP32: T/4 ≥ 1.0 → T ≥ 4      FP16: T/2 ≥ 2.0 → T ≥ 4
```
The element shrink exactly cancels the throughput gain. **T ≥ 4 always**; use T = 32-64 for margin.

**Working set in a 1 MiB LLC** (`3T²` elements + double buffer): FP32 T ≲ 200, FP16 T ≲ 290. Far more
headroom than needed → **1 MiB is generous; 512 KiB (`LlcNumLines 256→1024`) likely suffices.**

⚠ FP64 is synthesised but (per user) unused. `FPUSupportHalfSingle` + `FixPtSupport` off would free
LUTs+DSPs — the archive §8 area lever. **Check no `double` survives in a vector loop first.**

---

## 5. ★ The `vfmacc.vf` rule — why you may not need `vlse` at all

Ara's own reference matmul already solves the column-major problem, and not with strided vector loads:

```c
t0 = *a, a += N;              // stride-N SCALAR load = walking a COLUMN of A
t1 = *a, a += N;
asm volatile("vle64.v v16, (%0);" ::"r"(b));   // unit-stride VECTOR load of a B ROW
asm volatile("vfmacc.vf v0, %0, v16" ::"f"(t0));
```
`~/ara/apps/fmatmul/kernel/fmatmul.c:133-160`

> **For `C = A·B` in `vfmacc.vf` form: the B operand must be row-contiguous. The A operand may have
> ANY stride — it is fetched by scalar loads and broadcast, and hides under the vector compute.**

There is no `vlse` anywhere in `fmatmul`. The transpose is absorbed into the scalar operand slot.

---

## 6. ★ The LMUL budget — DERIVED, and it is a hard kernel rule

Per inner iteration of the 4×4 kernel:

| | cycles |
|---|---|
| 4× `vfmacc.vf` @ LMUL=4 → 4 × (4×2048 bit ÷ 128 bit/cyc) | **256** |
| 4 scalar strided loads, DDR miss, serialised by the 1-MSHR limit (4×48) | **192** ✅ hides |
| same, if A is SPM-resident (4×17) | **68** ✅ hides easily |
| bus occupancy (1024 B vector + 128 B scalar ÷ 8 B/cyc) | 144 → **56% utilised** |

The 256 is **invariant in SEW** — at LMUL=4 you always push 4×2048 bits through 128 bit/cycle,
whether FP64, FP32 or FP16. Therefore:

```
LMUL=1 →  64 cyc shadow vs 192 scalar → SCALAR-BOUND (3x)
LMUL=2 → 128 cyc shadow vs 192 scalar → SCALAR-BOUND
LMUL=4 → 256 cyc shadow vs 192 scalar → compute-bound, 25% margin
LMUL=8 → 512 cyc shadow               → comfortable
```

> **RULE: use LMUL ≥ 4 in every matmul kernel, or the scalar column walk becomes the bottleneck.**

Staging the A operand in SPM (68 cyc) is what makes LMUL=2 viable. **That is the SPM's value for
compute — not bulk staging.**

⚠ Archive §19.5: at LMUL>1, float reductions reject legal `vs1`. Keep reduction accumulators in
8-aligned registers (v8/v16/v24) until the RTL patch lands.

---

## 7. ★ Layout algebra for the training step

For an FC layer `Y = X·W`, X (N,I), W (I,O). Each GEMM has two formulations; the constraint is
always "which tensor lands in the B slot and must therefore be row-contiguous":

| GEMM | Option A | Option B |
|---|---|---|
| Forward `Y = X·W` | B=W → **W row-major** | B=Xᵀ → X stored transposed |
| `dX = dY·Wᵀ` | B=Wᵀ → **W stored transposed** | B=dYᵀ → **dY stored transposed** |
| `dW = Xᵀ·dY` | B=dY → **dY row-major** | B=X → **X row-major** |

Two self-consistent schemes exist, and **they cost the same one transpose per iteration**:

### Scheme 1 — "Option 1" / feature-major gradients (`G = dYᵀ`)
`Y=X·W` ✅ · `dXᵀ=W·G` ✅ · `dWᵀ=G·X` ✅ · **optimizer must transpose dWᵀ→dW ❌**
- Math verified correct, and the chain closes: each layer emits `dXᵀ` (I,N) = exactly the `G` the
  previous layer wants.
- Cost: the transpose sits **inside the optimizer, on the critical path**, and reads dWᵀ column-wise
  → every element a fresh 32 B line at 12.5% efficiency on a 1-MSHR core. Expensive.
- Breaks the layer API (`forward` returns (N,O), `backward` consumes (O,N)) and forks the mental model.

### Scheme 2 — dual-W (**RECOMMENDED**)
Keep both `W` (I,O) and `Wᵀ` (O,I) in sync.
`Y=X·W` ✅ · `dX=dY·Wᵀ` ✅ · `dW=Xᵀ·dY` ✅ · **update is unit-stride elementwise ✅**
- Remaining cost: one `W → Wᵀ` regeneration per iteration.
- **Better placement:** it is pure movement of a tensor that is *frozen during backward* → the DMA
  can do it fully in the background, off the critical path.
- All tensors stay batch-major; the layer API survives.
- Cost: 2× weight memory. Cheap against DDR.

⚠ **Correction to carry:** "the memory bottleneck disappears" is only true **with tiling over O**.
With one accumulator, `dWᵀ=G·X` has AI = 0.5 flop/byte — *below* the FP32 balance of 1.0, i.e.
memory-bound. Need ≥2 accumulators (FP32) / ≥4 (FP16), exactly as `fmatmul` uses 4.

---

## 8. ★ Scalar utilisation — the analysis

**The idea:** scalar core does the weight update of layer *i-1* while Ara does the backward pass of
layer *i*. **Verdict: it works, and it needs essentially none of the hardware one would design for it.**

### 8.1 It already hides, today, with zero RTL change
`W[i] -= lr*dW[i]` is **contiguous, not strided**. 32 B line = 8× FP32:

| | |
|---|---|
| 5 instr/element (2×`flw`, `fmul`, `fsub`, `fsw`), single-issue in-order | 5 cyc/elem |
| 2 line fills per 8 elements, 48 cyc, serialised (1 MSHR) | **12 cyc/elem** ← dominates |
| 1M FP32 params | **~240 ms** |
| same work on Ara (12 MB @ 8 B/cyc) | ~30 ms |
| available shadow: backward GEMMs, same layer, batch 32 | **320-500 ms** |

240 < 320 → **hides.** Bus cost: 0.67 B/cyc = **8% of the 8 B/cyc**, against the GEMM's 56%. Fits.

### 8.2 Why replacing L1-D with a core-local scratchpad does NOT pay
Even at **zero** memory latency the loop is issue-bound: 5 instructions/element on a single-issue core.
```
perfect scratchpad → 5 cyc/elem → 100 ms
today (L1-D+DDR)   → 12 cyc/elem → 240 ms
```
Both hide under 320 ms → **end-to-end gain is zero.** And CVA6 offers no SPM mode
(`DCacheType ∈ {WT, WB, HPDCACHE*}`), so it means new RTL inside the LSU — on the core that already
cost two subtle bugs (archive §16, §17). **Don't.**

### 8.3 ★ The real hazard: LLC thrash
The update streams **8 MB** (W + dW) through a shared **128 KiB** LLC — 64× its capacity. It will
**evict every one of Ara's tiles.**

> **This is the actual reason to use the SPM: pin Ara's tiles in SPM ways (never evicted) and let the
> scalar stream flow through the cache ways.** Nothing to do with scalar latency. Zero new RTL —
> `CFG_SPM` @ `0x0300_1000` already exists.

### 8.4 The ceiling
`update_time / step_time = 2/N` where N = batch:
```
batch 12 → 16.7%     batch 32 → 6.3%     batch 64 → 3.1%
```
That is the **maximum** win from perfect overlap. Amdahl caps this before the complexity does — size
the engineering effort accordingly.

### 8.5 CVA6 packed SIMD (`XFVec`)
Off (`:18-21`), but fully plumbed — enabling is a **config change**, fpnew supports it. It does cost
LUTs (vectorial fpnew slices). But 2×FP32 packed → 2.5 cyc/elem while you are memory-limited at 12,
**and already hiding**. Buys nothing here. Spend the LUTs on the DMA instead.

### 8.6 What the plan actually needs
**Needs:** dual-W layout (§7) · SPM ways for Ara's tiles (§8.3) · `fence` at layer boundaries.
**Does not need:** L1-D removal · core-local scratchpad · 2D DMA for column gather · `XFVec`.

---

## 9. Config knobs available without new RTL

| Knob | Where | Effect |
|---|---|---|
| `Cva6NiDramRule` | `cheshire_pkg.sv:87/566`, `cheshire_top_xilinx.sv:154` | **the permanent NI fix — unbuilt** |
| `LlcNumLines` 256 → 1024 / 2048 | `cheshire_pkg.sv:623` | 512 KiB / 1 MiB LLC **and** SPM (SPM size = LLC size) |
| `CFG_SPM` @ `0x0300_1000` | runtime register | how many of the 8 ways are scratchpad |
| `ret.Dma = 0 → 1` | `cheshire_top_xilinx.sv:119` | enables iDMA (~8.1k LUT); needed for background `W→Wᵀ` and tile prefetch |
| `FPUSupport` → `FPUSupportHalfSingle` | Ara instantiation | drops FP64 → frees LUT+DSP (funds the DMA) |
| `CVA6ConfigFVecEn` 0→1 | config pkg `:21` | scalar packed SIMD — **not recommended, see §8.5** |

**DMA verdict:** worth enabling, but for **contiguous DDR→SPM tile fills and the background `W→Wᵀ`**.
A 2D strided *gather from DDR* is 4 useful bytes per 64 B line — it is a double-buffering engine, not
a transpose engine. Strided reads only pay off from **LLC/SPM-resident** data (one beat per element).

---

## 10. Open / gating

1. ★ **Build and program the `Cva6NiDramRule` bitstream** (archive §19.1). Still never synthesised.
   **Nothing in §2-8 is measurable until this lands.** Ship it alone, not bundled.
2. Then, as a *separate* build: LLC resize + `FPUSupport` + `Dma=1` (all config, one bitstream).
3. Phase 2 has produced **no hardware measurements**. First ones to take, once (1) lands:
   - LLC hit rate = `1 − p3_ar/p1_ar` using the existing counters
   - actual `flop/byte` of the current kernels vs the §4 balance points
   - whether the scalar update really hides (§8.1) — a sticky "scalar still running at GEMM end" flag
4. Carried from Phase 1: conv_layer never rebuilt with current crt0; Ara reduction patch unapplied
   and bug report unsent; real vggnet training run; stale 2026-07-03 binaries.

---

## 11. Method rules (Phase 2 additions)

* **Check the port width before believing in concurrency.** The whole scalar/vector overlap question
  changed shape once `AraDataWideWidth = 32×NrLanes = 64` turned up — the dw_converter is a no-op and
  there is no second bandwidth path. One grep, ahead of a lot of arithmetic.
* **Distinguish issue-bound from memory-bound before designing a memory fix.** §8.2's scratchpad plan
  was sound reasoning against the wrong bottleneck; a single-issue core has a floor no SRAM can lower.
* **`Bender.lock` can override `Bender.yml` with a Path source.** Confirm which tree compiles before
  quoting any RTL constant (`:105-109`).
* **Compute the Amdahl ceiling first.** §8.4's `2/N` bounds the entire scalar-overlap effort at 6% for
  batch 32 — worth knowing before, not after, designing for it.
* Phase 1 rules still apply: filter `objdump -D` to `.text`; look for a *second* independent cause
  before doubting a fix that worked; confirm on hardware, not in disassembly; `make -B` after any
  header move (no `-MMD` in this build).

# axi_dw_upsizer — same-ID outstanding reads

Directed testbench for the serialization limit described in
`AGENT_NOTES_FP16_4LANE.md` §52–§53.

## What it tests

`axi_dw_upsizer` allows exactly **one outstanding read per AXI ID**. Every
incoming AR whose ID matches a busy context is routed to that busy context
(`id_clash_upsizer`, `axi_dw_upsizer.sv:275/286`), and a busy context never
grants because the grant lives only in the `R_IDLE` arm (`:368-369`).

`axi_llc` issues **every** refill with `AxReqId = 9`
(`axi_llc_ax_master.sv:129`), because its `r_master` consumes descriptors in
FIFO order and therefore needs in-order responses. Both modules are correct in
isolation. Composed, the LLC gets 1 outstanding refill instead of the 4–6 its
pipeline is built for, and pays the full DDR latency on every 64 B line.

This only bites at **2 lanes**, where `SocDataWidth = 64` and the PS HP0 port is
128 b so the converter is instantiated. At 4 lanes the widths match and it
collapses to wires.

## Expected results

| | TEST 1 |
|---|---|
| current RTL | **FAILS** — 1 AR issued instead of 4 |
| fixed RTL | passes — 4 ARs issued before the first `RLAST` |

That failure is the deliverable. Run this *before* touching the RTL.

## Tests

1. **four same-ID (9) refill reads, no R returned** — the red one. Counts
   downstream AR handshakes while every response is held back.
2. **same-ID data integrity** — payload is address-derived (the 64-bit half at
   byte address `A` carries the value `A`), so a burst handed to the wrong
   context shows up as a data mismatch, not merely as reordering.
3. **ID 0** — an idle context has `r_req_q.ar = '0`, so its recorded ID reads as
   0. Any blocking rule not qualified with "has a pending AR" aliases against
   every idle context. ID 0 is what Ara's VLSU emits (`addrgen.sv:883`).
4. **four different IDs** — regression baseline; this already works today and
   must keep working.
5. **upstream R backpressure inside a master beat** — one 128-bit master beat is
   held two cycles while two 64-bit slave beats are produced (`:515`).

Not yet covered (§53.5): mixed IDs with out-of-order responses across IDs,
simultaneous queue push/pop (`FULL_BW`), filling `AxiMaxReads` completely, and
the ATOP assertion. Several of those only *do* anything once the fix exists.

## Running

```bash
./run_xsim.sh                 # Vivado XSim, AxiMaxReads=8
MAXREADS=24 ./run_xsim.sh     # the ZCU102 dram_wrapper value
./run_vsim.sh                 # Questa / ModelSim
```

`run_xsim.sh` needs the **full** Vivado (server, `vitis-2021.1`). Vivado_Lab has
no simulator. `run_vsim.sh` needs Questa, which is **not currently installed** on
the laptop — the licence is valid but `~/altera/25.1std/questa_fse` does not
exist (§52.8).

`CHECKOUTS` defaults to `../.bender/git/checkouts`; override it if the sources
move.

## Style

Deliberately procedural: no classes, no `randomize()`, no `common_verification`
dependency. That is why it runs on both XSim and Questa FSE, and it is also why
the repo's own class-heavy `tb_axi_dw_upsizer.sv` is `allow_failure` in the XSim
CI job. That existing testbench never forces several same-ID reads to be live at
once, which is why it passes today.

## Dependencies

**16 files** — see `filelist.f`. The upsizer is *not* self-contained: besides
`lzc`, `onehot_to_bin` and `rr_arb_tree` it instantiates `axi_err_slv` (`:185`)
and `axi_demux` (`:208`), which pull in `axi_atop_filter`, `axi_demux_simple`,
`fifo_v3`, `spill_register`, `spill_register_flushable`, `stream_register`,
`counter` and `delta_counter`.

Two include directories are needed, both wired up in the run scripts:

| dir | provides |
|---|---|
| `axi/include` | `axi/typedef.svh`, `axi/assign.svh` |
| `common_cells/include` | `common_cells/registers.svh`, `assertions.svh` |

## Status

Compiles under `xvlog` (Vivado 2021.1). First `xelab` attempt failed on the
missing `axi_err_slv` / `axi_demux`; the file list is now the full transitive
closure. **Not yet executed** — no simulator on the laptop, so runs happen on
the server.

## Where the fix goes

`.bender/git/checkouts/` is generated and will be overwritten. The RTL change
and this testbench belong in a fork of `pulp-platform/axi` (currently
`Bender.yml:16`, `version: 0.39.2`). See §53.2–§53.3 for the reviewed design:
relax `id_clash` to `same_id_pending` rather than deleting it, `id_queue` with
`FULL_BW=1` pushed at allocation, pop on the last accepted narrow beat.

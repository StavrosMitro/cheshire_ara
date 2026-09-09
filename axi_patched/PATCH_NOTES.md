# axi_patched — local fork of pulp-platform/axi 0.39.2

Upstream: `https://github.com/pulp-platform/axi.git`
Revision: `ac5deb3ff086aa34b168f392c051e92603d6c0e2` (v0.39.2)

**Exactly one file differs from upstream: `src/axi_dw_upsizer.sv`.**

Verify at any time:

```bash
diff -rq .bender/git/checkouts/axi-ecdc900686449c15 axi_patched
```

Wired in through `Bender.lock` (`axi: source: Path:`), following the same
convention already used for `cva6_patched`. `Bender.yml` still declares the git
dependency; the lock redirects it.

## What changed and why

`axi_dw_upsizer` allowed exactly **one outstanding read per AXI ID**. Every
incoming AR whose ID matched a busy context was routed to that busy context
(`id_clash_upsizer`), and a busy context never grants — the grant lives only in
the `R_IDLE` arm of the FSM.

`axi_llc` issues **every** refill with a fixed ID (`AxReqId = 9`,
`axi_llc_ax_master.sv:129`) because its `r_master` consumes descriptors in FIFO
order and therefore needs in-order responses. Both modules are correct in
isolation. Composed, the LLC got 1 outstanding refill instead of the 4–6 its
pipeline is built for, and paid the full DDR latency on every 64 B line.

This only bites at **2 lanes**, where `SocDataWidth = 64` and the PS HP0 port is
128 b so the converter is instantiated. At 4 lanes the widths match and
`axi_dw_converter` collapses to wires.

### The five changes

```
(1) same_id_pending[t] = (arb_slv_ar_id == mst_ar_id[t]) && mst_ar_valid_tran[t]
    replaces id_clash_upsizer — block only until the master AR handshake, not
    for the whole transaction lifetime
(2) idx_ar_upsizer = idx_idle_upsizer, with ar_id_blocked = |same_id_pending
    used purely as a boolean; deletes one onehot_to_bin entirely
(3) id_queue #(.CAPACITY(AxiMaxReads), .FULL_BW(1'b1), .data_t(tran_id_t))
    replaces rid_upsizer_match + the second onehot_to_bin.
    FULL_BW must be 1: the default 0 blocks a pop on a push cycle, and the
    upsizer's R path has no response buffer.
(4) idqueue_push[t] at ALLOCATION (not at the AR handshake), which is what
    keeps ATOPs working — an ATOP allocates a context but issues no master AR
(5) idqueue_pop[t] on the last ACCEPTED narrow beat
```

Plus five immediate assertions (push-without-grant, pop-without-valid,
`$onehot0` on push and on pop, ATOP-shares-an-ID).

**Why (1) is airtight:** at most one *unissued* same-ID AR can exist, so two
same-ID ARs can never be pending at the round-robin `i_mst_ar_arb` together.
Reordering becomes impossible by construction, so allocation order equals
downstream issue order — which is what makes the allocation-time push in (4)
correct.

`id_queue` was already in the build's source list; `axi_dw_downsizer` uses it.
No new source, no manifest change beyond the lock redirect.

## Verification

| | |
|---|---|
| directed testbench, stock vs patched | `axi_upsizer_work/` — 23 checks, 0 regressions, at `AxiMaxReads=24` and at both `64→128` and `128→256` |
| build | LUT +2,301 (+1.6 %), FF +1,458, BRAM/DSP unchanged, **WNS 3.095 → 1.429 ns — closes** |
| FPGA A/B | `fc_layer16only` forward **301,352 → 176,737 cycles = 1.705×**, 48.9 % → 83.4 % of vector peak |

Full record: `AGENT_NOTES_FP16_4LANE.md` §52–§53.

## Not done

- upstream random regression across all 36 width pairs (needed for a PR, not
  for this design)
- no PR has been opened; this is a local fork

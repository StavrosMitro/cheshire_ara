# Copyright 2018 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>
# Paul Scheffler <cykoenig@iis.ee.ethz.ch>

# Initialize implementation
set xilinx_root [file dirname [file dirname [file normalize [info script]]]]
source ${xilinx_root}/scripts/common.tcl

# K4-BUILD-INFRA: init_impl (common.tcl) unconditionally does
# `file delete -force [glob ${project_root}/*]` before creating a fresh
# project -- this is what silently destroyed the previous failed run's
# checkpoints (cheshire.runs/impl_1/*.dcp) the moment this build started.
# Salvage anything a prior run left behind before that wipe happens.
set _pre_board [lindex $argv 0]
set _pre_proj  [lindex $argv 1]
set _pre_root  ${xilinx_root}/build/${_pre_board}.${_pre_proj}
set _pre_impl1 ${_pre_root}/${_pre_proj}.runs/impl_1
if {[file isdirectory $_pre_impl1]} {
    set _pre_stamp [clock format [clock seconds] -format %Y%m%d_%H%M%S]
    set _pre_ckpt  ${xilinx_root}/ckpt/salvaged_${_pre_stamp}
    set _pre_dcps  [glob -nocomplain ${_pre_impl1}/*.dcp]
    if {[llength $_pre_dcps] > 0} {
        file mkdir $_pre_ckpt
        foreach _f $_pre_dcps { file copy -force $_f $_pre_ckpt }
        puts "K4-BUILD-INFRA: salvaged [llength $_pre_dcps] checkpoint(s) from\
              prior run to $_pre_ckpt before init_impl wipes ${_pre_root}"
    }
}

init_impl $xilinx_root $argc $argv

# Addtional args provide IPs
read_ip [exec realpath {*}[lrange $argv 2 end]]

# Load constraints
import_files -fileset constrs_1 -norecurse ${xilinx_root}/constraints/${proj}.xdc
import_files -fileset constrs_1 -norecurse ${xilinx_root}/constraints/${board}.xdc

# Load RTL sources
source ${xilinx_root}/scripts/add_sources.${board}.tcl

# Set top module
set_property top ${proj}_top_xilinx [current_fileset]
update_compile_order -fileset sources_1

# Set synthesis properties
# TODO: investigate resource-affordable retiming
# soc_clk is only 50 MHz -> huge timing slack. Use an AREA strategy, not a
# performance one: Flow_PerfOptimized_high inflates LUTs (full flatten, register
# replication, little resource sharing) and pushed the ZU9EG over 100% LUTs.
set_property XPM_LIBRARIES XPM_MEMORY [current_project]
set_property strategy Flow_AreaOptimized_high [get_runs synth_1]

# Elaborate and open design to explore all clocks
synth_design -rtl -name rtl_1
report_clocks -file ${project_root}/clocks.rpt

# Synthesis
launch_runs -jobs $num_jobs synth_1
wait_on_run synth_1
open_run synth_1

# Generate synthesis reports
gen_reports ${project_root}/reports.synth

# Instantiate debug core and ILAs
# TODO: debug this
# insert_ilas {sys_clk}   ;# ILA-DEBUG: 300 MHz sys_clk ILA + cross-domain paths
#                            broke timing under Flow_RuntimeOptimized.
# Clock the ILA on soc_clk (50 MHz) -> all probes single-domain, timing trivial.
# If soc_clk is dead, vivado_lab reports "debug hub not detected / no clock",
# which itself tells us soc_clk is dead.
insert_ilas {soc_clk}

# Set implementation properties
# SPEED: 50 MHz normally has huge slack, but the added ILA mark_debug probes
# (P0a/P0b/P0c) ate enough congestion margin to trip ~27 CVA6 issue/scoreboard
# endpoints by up to -0.161ns (WNS). Flow_RuntimeOptimized skips phys_opt
# entirely, so nothing closes that last sliver. Performance_ExplorePostRoutePhysOpt
# adds one targeted post-route phys_opt pass for exactly this (small residual setup
# violations) -- it does NOT touch synth_1 (still Flow_AreaOptimized_high above),
# so LUT budget (see AGENT_NOTES_ZCU102.md §4.4/§8) is unaffected.
# set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]
# set_property strategy Flow_RuntimeOptimized [get_runs impl_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# K3/K4: extending ni_disable_i into i_cva6_icache (new dbg_ic_* probes placed
# nearby) shifted placement enough to fail HOLD on a pre-existing, zero-logic
# FF-to-FF path (i_cva6_icache/vaddr_q_reg[5] -> i_frontend/icache_vaddr_q_reg[5]):
# 5 endpoints, worst slack -0.021ns.
#
# Tried STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE ExploreWithAggressiveHoldFix:
# did NOT move the violation (still 5 endpoints, still -0.021ns exactly -- a
# post-route phys_opt pass evidently can't touch a path this short), and on an
# already congestion-level-5 design the aggressive pass left 683 nets partially
# routed (DRC RTSTAT-6), failing write_bitstream outright. Reverted.
#
# K4-BUILD fix ladder step 1: hold-fixing on a path this short happens mainly in
# route_design, not post-route physopt. ExtraNetDelay_high biases PLACE_DESIGN
# toward more conservative net delays, which tends to buy hold margin on short
# paths without touching the setup-oriented impl_1 strategy above.
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraNetDelay_high [get_runs impl_1]

# K5 3c: the bitstream that actually passed timing was NOT produced by this
# file -- it came from a standalone checkpoint script (k4_ckpt_route_test.tcl)
# that opened a placed.dcp built with ExtraNetDelay_high above, then ran a
# PLAIN, directiveless route_design, then went straight to write_bitstream
# with NO post-route phys_opt_design step at all. That combination is the
# only one empirically proven to close the -0.021ns hold violation. Pin
# ROUTE_DESIGN to Default explicitly so this managed run reproduces that
# route step exactly rather than relying on whatever Performance_Explore-
# PostRoutePhysOpt's built-in default happens to be.
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Default [get_runs impl_1]
# NOTE: this strategy still runs a post-route phys_opt_design step (that is
# the whole reason Performance_ExplorePostRoutePhysOpt was chosen -- see the
# comment above insert_ilas: it fixes ~27 unrelated CVA6 issue/scoreboard
# setup endpoints). That step was NEVER combined-tested with the new hold-
# sensitive placement; only place+route+no-physopt is proven. Left running
# rather than disabled, because skipping it risks reopening that older,
# unrelated setup failure -- but this is a real gap, not an assumption to
# build on. If timing fails again below, check whether WHS regressed between
# the routed and postroute_physopt checkpoints archived below; that isolates
# which step is responsible before trying another directive.

# Implementation
# K4-BUILD-INFRA 1c attempted: stopping at -to_step place_design, then calling
# open_run impl_1 to report post-place timing, then launch_runs again -to_step
# write_bitstream. REVERTED -- the first open_run failed with "Run 'impl_1'
# has not been launched. Unable to open" and killed the whole build right
# after place_design, before route_design ever ran, wasting the full
# synth+place wall-clock time on nothing. Root cause not fully diagnosed
# (open_run apparently doesn't accept a run parked mid-flow the way this
# assumed); not worth another guess given the cost of being wrong here.
# This build still launches as ONE continuous run for that reason -- it never
# stops mid-flow. Checkpoint capture below is a passive filesystem poll
# running alongside it, not a staged/resumed run.
#
# K5 3c: the external shell-script watcher used during the K4 build
# (watch_checkpoints.sh) died silently at some point after that build
# finished -- found dead, with no alarm, when this build was being prepared.
# An always-on background process nobody is watching is exactly the kind of
# thing that can silently stop protecting a 6-7h build. Archival is now
# done from inside this same vivado_lab process instead, tied to the run's
# own lifetime: if vivado_lab is alive the archiver is running, and if
# vivado_lab dies the build failed anyway. Same size-stability guard as the
# watcher (require an unchanged size across two checks before trusting a
# .dcp is complete) -- that guard exists because the watcher previously
# copied a placed.dcp mid-write (6.4MB partial vs 156MB real) and corrupted
# the archive; a partial copy here would silently poison a future recovery.
# K5-PRELAUNCH 3a: report timing at BOTH post-route and post-physopt, from
# the archived checkpoint copies (never the live run directory), so we learn
# whether physopt can be dropped permanently -- it was never combined-tested
# with this placement (see the note above). This opens/closes a STANDALONE
# checkpoint in this script's own design slot; it does not touch the impl_1
# run object or its child process (launch_runs runs implementation in a
# separate process in project mode -- this session only currently has
# synth_1 open from earlier, via open_run synth_1). Fully catch-wrapped: if
# this reasoning is wrong about something, the worst case is a printed
# warning, not a broken build -- wait_on_run/open_run impl_1 at the end of
# this script do not depend on anything in this block succeeding.
proc k5_report_ckpt_timing {label ckpt_path} {
    puts "K5-BUILD-INFRA: === timing report for $label ($ckpt_path) ==="
    if {[catch {
        catch { close_design }
        open_checkpoint $ckpt_path
        set _s [report_timing_summary -no_header -no_detailed_paths -return_string]
        puts "K5-BUILD-INFRA \[$label\] timing constraints met: [string match -nocase {*timing constraints are met*} $_s]"
        report_timing_summary -no_header -no_detailed_paths
        puts "K5-BUILD-INFRA \[$label\] icache->frontend path (i_cva6_icache/vaddr_q_reg\[*\] -> i_frontend/icache_vaddr_q_reg\[*\]):"
        report_timing -hold -from [get_pins -hier -filter {NAME =~ "*i_cva6_icache/vaddr_q_reg*/C"}] \
                              -to   [get_pins -hier -filter {NAME =~ "*i_frontend/icache_vaddr_q_reg*/D"}] \
                              -max_paths 10 -path_type full
        close_design
    } _cerr]} {
        puts "K5-BUILD-INFRA WARNING: timing report for $label failed, skipping ($_cerr)"
        catch { close_design }
    }
}

launch_runs -jobs $num_jobs impl_1 -to_step write_bitstream

set _ckpt_out ${xilinx_root}/ckpt
file mkdir $_ckpt_out
set _run_dir ${project_root}/${proj}.runs/impl_1
array set _archived {}
puts "K5-BUILD-INFRA: archiving checkpoints from ${_run_dir} to ${_ckpt_out} as they complete"
# K5-PRELAUNCH 3b: these two exact basenames (routed.dcp, postroute_physopt.dcp)
# are the empirically-confirmed names watch_checkpoints.sh observed and
# copied during the actual K4 build -- not guessed. routed.dcp is the one
# the proven-good recipe (k4_ckpt_route_test.tcl) opens for its
# place+route+no-physopt write_bitstream fallback (~20min from a hold
# failure instead of another ~7h), so it must be among the archived files;
# confirmed by the exact-match trigger below firing k5_report_ckpt_timing.
# Safety cap: PROGRESS is the standard Vivado run-progress property, but this
# was never run against a real Vivado (only vivado_lab -- JTAG/ILA/VIO only --
# is available outside the build machine), so its exact return format is
# unverified here. 1000 iterations * 30s = ~8.3h, comfortably above the ~7h
# this build takes; if PROGRESS never reads "100%" for some format reason,
# this bails out and falls through to wait_on_run (the real, authoritative
# completion check) instead of hanging the whole build forever on a loop
# that only ever existed to archive checkpoints as a convenience.
set _poll_cap 1000
for {set _i 0} {$_i < $_poll_cap} {incr _i} {
    if {[catch {get_property PROGRESS [get_runs impl_1]} _prog]} { set _prog "" }
    foreach _dcp [glob -nocomplain ${_run_dir}/*.dcp] {
        set _base [file tail $_dcp]
        if {[info exists _archived($_base)]} { continue }
        if {![file exists $_dcp]} { continue }
        set _sz1 [file size $_dcp]
        after 2000
        if {[file exists $_dcp] && [file size $_dcp] == $_sz1 && $_sz1 > 0} {
            file copy -force $_dcp ${_ckpt_out}/${_base}
            set _archived($_base) 1
            puts "K5-BUILD-INFRA: archived $_base (${_sz1} bytes) -> ${_ckpt_out}"
            if {$_base eq "routed.dcp"} {
                k5_report_ckpt_timing "POST-ROUTE (pre-physopt)" ${_ckpt_out}/${_base}
            } elseif {$_base eq "postroute_physopt.dcp"} {
                k5_report_ckpt_timing "POST-PHYSOPT" ${_ckpt_out}/${_base}
            }
        }
    }
    if {$_prog == "100%"} { break }
    if {$_i == [expr {$_poll_cap - 1}]} {
        puts "K5-BUILD-INFRA: WARNING -- checkpoint archival loop hit its ${_poll_cap}-iteration\
              cap without PROGRESS reading 100% (last value: '$_prog'). Falling through to\
              wait_on_run; this is a fail-safe, not expected to trigger."
    }
    after 30000
}
wait_on_run impl_1
open_run impl_1

# Generate implementation reports
gen_reports ${project_root}/reports.impl

# K4/K5: always report the specific icache<->frontend hold path regardless of
# overall pass/fail -- this is the exact interface D1 measures to confirm the
# icache gate mechanism, so a corrupted fetch-address bit here could silently
# masquerade as evidence for the wrong reason even on a build that otherwise
# reports timing met. Same -from/-to pin filter as k4_ckpt_route_test.tcl,
# which is the one that actually ran successfully during the K4 build --
# reused verbatim rather than the -through form this had before, which was
# never run for real. Wrapped in catch: a cell/path rename would break this
# report without invalidating the build.
puts "=== icache->frontend path (i_cva6_icache/vaddr_q_reg[*] -> i_frontend/icache_vaddr_q_reg[*]) ==="
if {[catch {
    report_timing -hold -from [get_pins -hier -filter {NAME =~ "*i_cva6_icache/vaddr_q_reg*/C"}] \
                          -to   [get_pins -hier -filter {NAME =~ "*i_frontend/icache_vaddr_q_reg*/D"}] \
                          -max_paths 10 -path_type full
} _terr]} {
    puts "WARNING: could not report the icache->frontend path directly ($_terr)."
    puts "Falling back to a name-filtered search of the worst 20 hold paths:"
    catch { report_timing -hold -max_paths 20 -nworst 1 -path_type summary }
}

# Check timing constraints
set trep [report_timing_summary -no_header -no_detailed_paths -return_string]
if { ![string match -nocase {*timing constraints are met*} $trep] } {
    puts "Error: Timing constraints not met for ${proj} on ${board}."
    puts "=== WNS/WHS summary ==="
    report_timing_summary -no_header -no_detailed_paths
    puts "=== worst 10 HOLD paths ==="
    report_timing -hold -max_paths 10 -nworst 10 -path_type summary
    return -code error
}

# Copy out final bitstream
file mkdir ${xilinx_root}/out
file copy -force ${project_root}/${proj}.runs/impl_1/cheshire_top_xilinx.bit \
    ${xilinx_root}/out/${proj}.${board}.bit
# The .ltx (debug-probes) file only exists when a debug core/ILA was inserted.
# On ZCU102 no ILA/VIO is in the design, so guard the copy to avoid a spurious
# build failure after the bitstream is already written.
set ltx_src ${project_root}/${proj}.runs/impl_1/cheshire_top_xilinx.ltx
if {[file exists $ltx_src]} {
    file copy -force $ltx_src ${xilinx_root}/out/${proj}.${board}.ltx
} else {
    puts "Note: no .ltx (no debug cores in design); skipping .ltx copy."
}

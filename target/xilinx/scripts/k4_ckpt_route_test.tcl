# K4-BUILD: fast hold-fix test from a preserved placed checkpoint.
# Run standalone, NOT via the impl_sys.tcl/make flow, from ANY directory --
# all paths below are computed from this script's own location, matching the
# pattern impl_sys.tcl uses, so cwd (repo root vs. deps/ara/cheshire vs.
# anywhere else) cannot silently break a relative path:
#
#   vivado -mode batch -source /home/smitropoulos/cheshire_soc/target/xilinx/scripts/k4_ckpt_route_test.tcl \
#       | tee ~/build_K4_ckpt_test.log
#
# (checkpoint path defaults to the salvaged ExtraNetDelay_high placement below;
# pass -tclargs <other.dcp> to point at a different one)
#
# This is the ExtraNetDelay_high placement from the run that crashed on the
# Part-1c open_run bug right after place_design -- never routed. Testing
# whether a PLAIN default route_design (no special directive) already closes
# the hold violation, since route_design does its own hold-fixing by default
# and we've never actually seen it run on this placement. If this clears, it
# also answers K4-BUILD Part 4 for free: the expensive multi-pass
# Performance_ExplorePostRoutePhysOpt strategy may not even be needed anymore
# now that WNS is +0.700ns instead of the -0.161ns it was adopted for.

set xilinx_root [file dirname [file dirname [file normalize [info script]]]]

set ckpt [lindex $argv 0]
if {$ckpt eq ""} {
    set ckpt ${xilinx_root}/ckpt/cheshire_top_xilinx_placed.dcp
}
if {![file exists $ckpt]} {
    puts "Error: checkpoint not found: $ckpt"
    return -code error
}
puts "Using checkpoint: $ckpt"

open_checkpoint $ckpt

puts "=== plain route_design (default directive) ==="
route_design

puts "=== WNS/WHS summary ==="
report_timing_summary -no_header -no_detailed_paths

puts "=== worst 10 HOLD paths ==="
report_timing -hold -max_paths 10 -nworst 10 -path_type summary

puts "=== the specific icache -> frontend vaddr path, both directions, whatever the sign ==="
catch {
    report_timing -hold -from [get_pins -hier -filter {NAME =~ "*i_cva6_icache/vaddr_q_reg*/C"}] \
                          -to   [get_pins -hier -filter {NAME =~ "*i_frontend/icache_vaddr_q_reg*/D"}] \
                          -max_paths 10 -path_type full
} report_err
if {$report_err ne ""} { puts "report_timing on the specific path failed: $report_err" }

set trep [report_timing_summary -no_header -no_detailed_paths -return_string]
if {[string match -nocase {*timing constraints are met*} $trep]} {
    puts "=== TIMING MET on plain route_design -- writing out bitstream+probes ==="
    file mkdir ${xilinx_root}/ckpt
    file mkdir ${xilinx_root}/out
    write_checkpoint -force ${xilinx_root}/ckpt/fixed_plainroute.dcp
    write_bitstream  -force ${xilinx_root}/out/cheshire.zcu102.bit
    write_debug_probes -force ${xilinx_root}/out/cheshire.zcu102.ltx
    puts "=== DONE -- bitstream and .ltx written to ${xilinx_root}/out/ ==="
} else {
    puts "=== still failing after plain route_design -- do NOT write a bitstream ==="
    puts "Next: try 'route_design -directive AlternateCLBRouting' from the same checkpoint (K4-BUILD Part 3 step A)."
}

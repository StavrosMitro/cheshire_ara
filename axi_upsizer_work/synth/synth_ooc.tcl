# Out-of-context synthesis of axi_dw_upsizer via synth_wrap_upsizer.
#
#   vivado -mode batch -source synth_ooc.tcl -tclargs <outdir> <part> \
#          <period_ns> <maxreads> <slvw> <mstw> <incdir> <incdir> <src> ...
#
# Driven by run_synth.sh -- see that script for the argument order.

set outdir    [lindex $argv 0]
set part      [lindex $argv 1]
set period    [lindex $argv 2]
set maxreads  [lindex $argv 3]
set slvw      [lindex $argv 4]
set mstw      [lindex $argv 5]
set incdirs   [list [lindex $argv 6] [lindex $argv 7]]
set srcs      [lrange $argv 8 end]

file mkdir $outdir

puts "### part      : $part"
puts "### period    : $period ns"
puts "### geometry  : ${slvw} -> ${mstw}, AxiMaxReads=$maxreads"
puts "### sources   : [llength $srcs]"

create_project -in_memory -part $part

foreach f $srcs {
  read_verilog -sv $f
}
set_property include_dirs $incdirs [current_fileset]

# A clock so the tool has something to optimise against.
#
# This MUST arrive as an XDC read before synth_design. In the non-project flow
# there is no open design until synth_design elaborates one, so a bare
# `create_clock` here fails with "No open design".
#
# OOC timing stays indicative only: the real paths to the LLC, the IW converter
# and the CDC are not present, and nothing is placed.
set xdc_file [file join $outdir clk.xdc]
set fh [open $xdc_file w]
puts $fh "create_clock -period $period -name clk_i \[get_ports clk_i\]"
close $fh
read_xdc $xdc_file

synth_design -top synth_wrap_upsizer -part $part -mode out_of_context \
  -generic MaxReads=$maxreads \
  -generic SlvDataWidth=$slvw \
  -generic MstDataWidth=$mstw

opt_design -quiet

report_utilization           -file $outdir/utilization.rpt
report_utilization -hierarchical -hierarchical_depth 4 \
                             -file $outdir/utilization_hier.rpt
report_timing_summary        -file $outdir/timing.rpt
report_timing -max_paths 5 -nworst 5 -delay_type max \
                             -file $outdir/timing_paths.rpt

# Machine-readable summary for the comparison step.
set fh [open $outdir/summary.txt w]
puts $fh [report_utilization -return_string]
close $fh

# The DUT on its own, excluding the wrapper's shift register and XOR tree.
set fh [open $outdir/dut_only.rpt w]
puts $fh [report_utilization -cells [get_cells i_dut] -return_string]
close $fh

puts "### wrote reports to $outdir"

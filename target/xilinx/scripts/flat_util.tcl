# Reopen the implemented ZCU102 run and emit a FLAT utilization summary
# (the "CLB LUTs ... Util%" table), alongside the hierarchical one.
# Run from anywhere:  vivado -mode batch -source <path>/flat_util.tcl
set root /home/smitropoulos/cheshire_soc/target/xilinx/build/zcu102.cheshire
open_project $root/cheshire.xpr
open_run impl_1
report_utilization -file $root/reports.impl/utilization_flat.rpt
puts "Wrote $root/reports.impl/utilization_flat.rpt"

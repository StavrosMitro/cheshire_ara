# Copyright 2018 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# STEPS.PLACE_DESIGN.TCL.PRE hook for impl_1 -- see impl_sys.tcl.
#
# WHY THIS FILE EXISTS AS A HOOK RATHER THAN A LINE IN impl_sys.tcl:
# `launch_runs` executes implementation in a SEPARATE PROCESS in project mode,
# so a `set_param` in impl_sys.tcl never reaches the placer. Vivado sources this
# script inside that child process, immediately before place_design, which is
# exactly where the check below fires.
#
# WHAT IT DISABLES, AND WHY THAT IS SAFE:
# The 4-lane build died like this (impl_1/runme.log, 2026-08-26):
#     Command: place_design -directive ExtraNetDelay_high
#     Running DRC as a precondition to command place_design
#     ERROR: [DRC UTLZ-1] ... requires 283731 ... only 274080 compatible sites
#     ERROR: [Vivado_Tcl 4-23] Error(s) found during DRC. Placer not run.
#
# UTLZ-1 compares LUT *cells* (post-opt_design, PRE-combining) against LUT
# *sites*. It does not model LUT combining, which happens during place_design --
# i.e. after this check. Measured on the 2-lane build's placed report:
#     LUT6 75,865 + LUT5 40,005 + LUT4 28,761
#   + LUT3 34,602 + LUT2 25,862 + LUT1 2,718   = 207,813 cells
#     LUT as Logic ............................. 173,115 sites
#       using O5 and O6 ........................  34,698 pairs combined
#     207,813 - 34,698 = 173,115 exactly  ->  16.7% reduction
#
# Xilinx documents this override in the error message itself. Applying 0.833 to
# 283,731 estimates ~236k sites (~86%), which would fit. That is an ESTIMATE
# from one data point: masku's wide muxes skew toward LUT6, the one primitive
# that cannot be combined, so the real ratio is likely worse.
#
# If it still does not fit, the placer now fails with an honest message
# ("Not enough LUT sites") instead of refusing to start.
#
# !! REMOVE THIS HOOK once the design fits comfortably, otherwise a future
# !! over-utilisation will fail obscurely deep inside the placer rather than
# !! being reported plainly up front.

set_param drc.disableLUTOverUtilError 1
puts "PRE-PLACE: drc.disableLUTOverUtilError=1 -- UTLZ-1 downgraded to a warning\
      so place_design can attempt LUT combining. See scripts/pre_place.tcl."

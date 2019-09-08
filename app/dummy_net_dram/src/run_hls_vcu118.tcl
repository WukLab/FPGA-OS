#
# Copyright (c) 2019, Wuklab, UCSD.
#

# Create a project
open_project	-reset generated_hls_project 

# The source file and test bench
add_files	top.cpp -cflags -I../../../include/
add_files -tb	tb.cpp  -cflags -I../../../include/

# Specify the top-level function for synthesis
set_top		dummy_net_dram

###########################
# Solution settings

# Create solution1
open_solution -reset solution1

# Specify a Xilinx device and clock period
#
# VCU118:	xcvu9p-flga2104-1-i
# VCU108:	xcvu095-ffva2104-2-e
# ArtyA7:	xc7a100tcsg324-1
#
set_part {xcvu9p-flga2104-1-i}
create_clock -period 8 -name default
set_clock_uncertainty 1.25

# Simulate the C code 
csim_design

# Synthesis the C code
csynth_design

# Export IP block
export_design -format ip_catalog -display_name "dummy_net_dram" -description "Dummy network and dram IP" -vendor "wuklab" -version "1.0"

# Do not perform any other steps
# - The basic project will be opened in the GUI 
exit

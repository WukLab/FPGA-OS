#
# Copyright (c) 2019, Wuklab, UCSD.
#

# Create a project
open_project	-reset generated_hls_project 

# The source file and test bench
add_files	top_512.cpp	-cflags -I../../../include
add_files -tb	tb_512.cpp	-cflags -I../../../include

# Specify the top-level function for synthesis
set_top		sysnet_rx_512

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

# 125MHz
create_clock -period 8 -name default
set_clock_uncertainty 1.25

# Simulate the C code 
#csim_design

# Synthesis the C code
csynth_design

# Export IP block
export_design -format ip_catalog -display_name "net_sysnet_rx" -description "SysNet RX Path" -vendor "wuklab" -version "1.0"

# Do not perform any other steps
# - The basic project will be opened in the GUI 
exit

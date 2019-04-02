#
# Copyright (c) 2019, Wuklab, Purdue University.
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
# VCU108:	xcvu095-2ffva2104e
set_part {xcvu095-ffva2104-2-e}

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

#
# Copyright (c) 2019, Wuklab, UCSD.
# Last Updated: Oct 22, 2019
#
# Template script for generating a Vivado HLS project.
# 1) generated_hls_project/ will be created.
#    This is listed in top-level .gitignore.
#    DO NOT CHANGE THIS.
# 2) solution 1 is used.
# 3) simulation, synthesis, and IP export will be executed.
#
# To customize:
# - Change added file name
# - Change top-level function name
# - Change exported IP parameters

# If the script is run in this way:
#   vivado_hls -f run_hls.tcl -tclargs $(TARGET_BOARD)
set board "[lindex $argv 2]"

# Create a project
open_project	-reset generated_hls_project 

# The source file and test bench
# Customize the -I path
add_files	core.cpp -cflags -I./include
add_files -tb	tb.cpp	 -cflags -I./include

# Specify the top-level function for synthesis
set_top		BoilerRuleAll

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
switch $board {
	vcu118 {
		set_part {xcvu9p-flga2104-1-i}
	}
	vcu108 {
		set_part {xcvu095-ffva2104-2-e}
	}
	arty_a7 {
		set_part {xc7a100tcsg324-1}
	}
	default {
		puts "Unknown board: $board"
		exit
	}
}
create_clock -period 10 -name default
set_clock_uncertainty 1.25

# Simulate the C code 
csim_design

# Synthesis the C code
csynth_design

# Export IP block
export_design -format ip_catalog -display_name "IP_NAME_HERE" -description "CHANGEME" -vendor "purdue.wuklab" -version "1.0"

# Do not perform any other steps
# - The basic project will be opened in the GUI 
exit

# Copyright (c) 2019, Wuklab, Purdue University.
#
# Template script for generating a Vivado HLS project.
# 1) generated_hls_project/ will be created.
#    This is listed in top-level .gitignore.
#    DO NOT CHANGE THIS.
# 2) solution 1 is used.
# 3) simulation, synthesis, and IP export will be executed.
#
# To customize:
# 1) Change part and clock
# 2) Change added file name
# 3) Change top-level function name
# 4) Change exported IP parameters

# Create a project
open_project	-reset generated_hls_project 

# The source file and test bench
add_files	core.cpp	-cflags "-I../../include"
add_files	chunk_alloc.cpp	-cflags "-I../../include"
add_files -tb	core_tb.cpp	-cflags "-I../../include"

# Specify the top-level function for synthesis
set_top		chunk_alloc

###########################
# Solution settings

# Create solution1
open_solution -reset solution1

# Specify a Xilinx device and clock period
#
# VCU108:	xcvu095-ffva2104-2-e
# ArtyA7:	xc7a100tcsg324-1
#
set_part {xcvu095-ffva2104-2-e}
create_clock -period 10 -name default
config_rtl  -encoding onehot -reset control  -reset_level high  -vivado_impl_strategy default -vivado_phys_opt place -vivado_synth_design_args {-directive sdx_optimization_effort_high} -vivado_synth_strategy default
set_clock_uncertainty 1.25

# Simulate the C code 
# csim_design

# Synthesis the C code
csynth_design

# Export IP block
export_design -format ip_catalog -display_name "CHUNK_ALLOCATOR" -description "Allocator for System Memory Chunk Unit" -vendor "purdue.wuklab" -version "1.0"

# Do not perform any other steps
# - The basic project will be opened in the GUI 
exit

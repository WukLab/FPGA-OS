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
open_project	-reset generated_mcd_buddy_project

add_files sources/hashTable/cc.cpp                      -cflags "-I../../../include"
add_files sources/hashTable/compare.cpp                 -cflags "-I../../../include"
add_files sources/hashTable/hash.cpp                    -cflags "-I../../../include"
add_files sources/hashTable/hashTableWithBuddy.cpp      -cflags "-I../../../include"
add_files sources/hashTable/memRead.cpp                 -cflags "-I../../../include"
add_files sources/hashTable/memWriteWithBuddy.cpp       -cflags "-I../../../include"
add_files sources/requestParser/requestParser.cpp       -cflags "-I../../../include"
add_files sources/responseFormatter/binResponse.cpp     -cflags "-I../../../include"
add_files sources/valueStore/valueStore.cpp             -cflags "-I../../../include"
add_files sources/globals.cpp                           -cflags "-I../../../include"
add_files sources/memcachedBuddy.cpp                    -cflags "-I../../../include"

add_files -tb ../../../alloc/buddy/buddy.cpp            -cflags "-I../../../include"
add_files -tb ../../../alloc/buddy/core.cpp             -cflags "-I../../../include"
add_files -tb sources/memcachedBuddy_tb.cpp          	-cflags "-I../../../include"

# Specify the top-level function for synthesis
set_top		memcachedBuddy

###########################
# Solution settings

# Create solution1
open_solution -reset solution1

set_part {xcvu095-ffva2104-2-e}
#create_clock -period 8 -name default
#config_rtl -encoding onehot -reset all -reset_level high -reset_async -vivado_impl_strategy default -vivado_phys_opt place -vivado_synth_design_args {-directive sdx_optimization_effort_high} -vivado_synth_strategy default
#set_clock_uncertainty 1.25

create_clock -period 6.66 -name default
config_rtl -reset all -reset_async

# Simulate the C code
# csim_design

# Synthesis the C code
csynth_design

export_design -format ip_catalog -display_name "Memcached Pipeline for Buddy" -description "A 4 stage memcached pipeline with DRAM value stores supporting only the binary protocol" -vendor "xilinx.labs" -version "1.07"
exit

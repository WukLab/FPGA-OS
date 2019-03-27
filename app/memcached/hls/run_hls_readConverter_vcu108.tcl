open_project generated_readConverter_project

set_top readConverter

add_files ../buildUoeMcdSingleDramPCIe/src/hls/axiDataMoverReadConverter/readConverter.cpp

open_solution "solution1"
#set_part {xc7a100tcsg324-1}
set_part {xcvu095-ffva2104-2-e}
create_clock -period 6.66 -name default
config_rtl -reset all -reset_async

csynth_design
export_design -format ip_catalog -display_name "Mem. Read Command Converter" -description "Converts the memcached pipeline mem. read commands to a format understood by the AXI data mover IP block" -vendor "xilinx.labs" -version "1.04"
exit

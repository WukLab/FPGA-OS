open_project writeConverter_prj

set_top writeConverter

add_files ../src/hls/axiDataMoverWriteConverter/writeConverter.cpp

open_solution "solution1"
set_part {xc7vx690tffg1157-2}
create_clock -period 6.66 -name default
config_rtl -reset all -reset_async

csynth_design
export_design -format ip_catalog -display_name "Mem. Write Command Converter" -description "Converts the memcached pipeline mem. write commands to a format understood by the AXI data mover IP block" -vendor "xilinx.labs" -version "1.05"
exit

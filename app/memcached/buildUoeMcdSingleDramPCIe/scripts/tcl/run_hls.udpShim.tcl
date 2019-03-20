open_project udpShim_prj

set_top udpShim

add_files ../src/hls/udpShim/udpShim.cpp
add_files -tb ../src/hls/udpShim/udpShim_tb.cpp

open_solution "solution1"
set_part {xc7vx690tffg1761-2}
create_clock -period 6.66 -name default
config_rtl -reset all -reset_async

csynth_design
export_design -format ip_catalog -display_name "UDP-to-MCD Shim " -description "This module interfaces between the memcached and the udp core." -vendor "xilinx.labs" -version "1.16"
exit

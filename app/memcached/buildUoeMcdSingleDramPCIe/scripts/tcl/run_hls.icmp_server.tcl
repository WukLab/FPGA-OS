open_project icmpServer_prj

set_top icmp_server

add_files ../src/hls/icmp_server/icmp_server.cpp
add_files -tb ../src/hls/icmp_server/test_icmp_server.cpp

open_solution "solution1"
#set_part {xc7a100tcsg324-1}
set_part {xcvu095-ffva2104-2-e}
create_clock -period 6.66 -name default

#csim_design  -clean
#csim_design  -clean -setup
csynth_design
#cosim_design -tool xsim -rtl verilog -trace_level all 
export_design -format ip_catalog -display_name "ICMP Server" -vendor "xilinx.labs" -version "1.67"

exit

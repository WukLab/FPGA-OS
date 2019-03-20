open_project arp_server_prj

set_top arp_server

add_files ../src/hls/arp_server/arp_server.cpp
add_files -tb ../src/hls/arp_server/test_arp_server.cpp

open_solution "solution1"
#set_part {xc7a100tcsg324-1}
set_part {xcvu095-ffva2104-2-e}
create_clock -period 6.66 -name default

#csim_design -clean
#csim_design -clean -setup
csynth_design
#cosim_design -tool xsim -rtl verilog -trace_level all 
export_design -format ip_catalog -display_name "ARP Server for 10G TOE Design" -description "Replies to ARP queries and resolves IP addresses." -vendor "xilinx.labs" -version "1.14"
exit

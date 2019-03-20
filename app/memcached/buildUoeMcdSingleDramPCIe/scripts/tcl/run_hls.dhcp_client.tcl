open_project dhcp_prj

set_top dhcp_client

add_files ../src/hls/dhcp_client/dhcp_client.cpp
add_files -tb ../src/hls/dhcp_client/test_dhcp_client.cpp

open_solution "solution1"
set_part {xc7vx690tffg1761-2}
create_clock -period 6.66 -name default

csynth_design
export_design -format ip_catalog -display_name "DHCP Client" -description "DHCP Client to be used with the Xilinx Labs TCP & UDP offload engines." -vendor "xilinx.labs" -version "1.05"
exit

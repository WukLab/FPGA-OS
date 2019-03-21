open_project macIpEncode_prj

set_top mac_ip_encode

add_files ../src/hls/mac_ip_encode/mac_ip_encode.cpp
add_files -tb ../src/hls/mac_ip_encode/test_mac_ip_encode.cpp

open_solution "solution1"
#set_part {xc7a100tcsg324-1}
set_part {xcvu095-ffva2104-2-e}
create_clock -period 6.66 -name default

#csim_design  -clean -argv {in.dat out.dat}
#csim_design  -clean
csynth_design
#cosim_design -tool xsim -rtl verilog -trace_level all 
export_design -format ip_catalog -display_name "MAC IP Encoder for 10G TCP Offload Engine" -vendor "xilinx.labs" -version "1.04"

exit


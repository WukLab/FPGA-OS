open_project dummyPCIeJoint_prj

set_top dummyPCIeJoint

add_files sources/otherModules/dummyPCIeAddressAllocation/dummyPCIeJoint.cpp

open_solution "solution1"
set_part {xc7vx690tffg1157-2}
create_clock -period 6.4 -name default

csynth_design
export_design -format ip_catalog -display_name " Model for emulating host side memory management" -description "A BRAM model for emulating host side memory management." -vendor "xilinx.labs" -version "1.0"

exit

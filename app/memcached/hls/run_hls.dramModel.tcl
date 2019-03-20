open_project dramModel_prj

set_top dramModel

add_files sources/otherModules/dramModel/dramModel.cpp

open_solution "solution1"
set_part {xc7vx690tffg1157-2}
create_clock -period 6.4 -name default

csynth_design
export_design -format ip_catalog -display_name "Dram Model for the KVS Pipeline" -description "A BRAM Value Store imitating the I/F of the DDR one." -vendor "xilinx.labs" -version "1.0"

exit

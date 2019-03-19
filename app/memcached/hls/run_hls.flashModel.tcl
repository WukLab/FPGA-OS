open_project flashModel_prj

set_top flashModel

add_files sources/otherModules/flashModel/flashModel.cpp

open_solution "solution1"
set_part {xc7vx690tffg1157-2}
create_clock -period 6.4 -name default

csynth_design
export_design -format ip_catalog -display_name "Flash Model for the KVS Pipeline" -description "A BRAM Value Store imitating the I/F of the SSD one." -vendor "xilinx.labs" -version "1.0"

exit

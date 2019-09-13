#
# Copyright (c) 2019, Wuklab, UCSD.
#
# Some simple Vivado scripts used throughout the project.
# This script file is NOT supposed to run AS IS.
# You SHOULD customize the various parameters within each command.
# When in doubt, use Vivado console to read help manual.
#

# VCU108
create_project ${_xil_proj_name_} "./generated_vivado_project" -part xcvu095-ffva2104-2-e
# VCU118
create_project ${_xil_proj_name_} "./generated_vivado_project" -part xcvu9p-flga2104-2L-e

#
# Script to save current project into a script file
# Used when there is NO block diagram design
#
write_project_tcl -no_copy_sources -force -target_proj_dir ./generated_vivado_project ./run_vivado.tcl

#
# Script to save current project into a script file
# Used when there is block diagram design
#
write_project_tcl -force -target_proj_dir ./generated_vivado_project ./run_vivado.tcl

#
# Script to save a block diagram as a script file
#
write_bd_tcl -bd_folder ./generated_vivado_project/bd ./create_bd_design_X.tcl

#
# Script to run the block diagram within the top-level script
# If there is no dependency, put these lines at the bottom of
# the top-level script, but before IP package script.
#
source create_bd_design_X.tcl

#
# Script to add generated_ip/ to IP paths
#
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../generated_ip"]" $obj
update_ip_catalog -rebuild

#
# Script to create wrapper for BD
# and add the source
# Adjust path accordingly
#
make_wrapper -files [get_files ${origin_dir}/generated_vivado_project/mm_sys_mm.srcs/sources_1/bd/sys_mm/sys_mm.bd] -top
add_files -norecurse ${origin_dir}/generated_vivado_project/mm_sys_mm.srcs/sources_1/bd/sys_mm/hdl/sys_mm_wrapper.v

#
# Script to export current project as an IP into generated_ip/
#
ipx::package_project -root_dir ../../generated_ip/mm_axi_wrapper -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force
update_ip_catalog -rebuild

#
# Script to export a board design as an IP into generated_ip/
#
ipx::package_project -root_dir ../generated_ip/foo -vendor wuklab -library user -taxonomy UserIP -module design_1 -import_files

#
# 2018.2 If simulation complains [VRFC 10-2063]
# Run this in project
#
set_property sim.use_ip_compiled_libs 0 [current_project]

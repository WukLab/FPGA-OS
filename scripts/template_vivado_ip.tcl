#
# Script to save current project into a script file
# This generated script file can be used rebuild the project AS IS.
# Note that Board Design needs to be generated seperately.
#
write_project_tcl -no_copy_sources -force -target_proj_dir ./generated_vivado_project ./run_vivado.tcl

#
# Script to add generated_ip/ to IP paths
#
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../generated_ip"]" $obj
update_ip_catalog -rebuild

#
# Script to export current project as an IP into generated_ip/
#
ipx::package_project -root_dir ../../generated_ip/mm_axi_wrapper -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force
update_ip_catalog -rebuild

#
# Script to export a board design as an IP into generated_ip/
#
ipx::package_project -root_dir ../generated_ip/foo -vendor wuklab -library user -taxonomy UserIP -module design_1 -import_files

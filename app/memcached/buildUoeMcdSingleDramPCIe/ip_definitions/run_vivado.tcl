set proj_name "pcie_mem_alloc"
set root_dir [pwd]
set proj_dir $root_dir/generated_vivado_project
set hdl_dir $root_dir/pcie_mem_alloc

# Create project
#create_project $proj_name $proj_dir -part xc7a100tcsg324-1 -force
create_project $proj_name $proj_dir -part xcvu095-ffva2104-2-e -force

# prepare pcie sub modules
add_files ${root_dir}/pcie2axilite_bridge
ipx::package_project -root_dir ${root_dir}/../../../../generated_ip/pcie2axilite_bridge -vendor xilinx.com -library user -taxonomy /UserIP -force -import_files
ipx::remove_bus_interface s_axi [ipx::current_core]
ipx::remove_port s_axi_awaddr [ipx::current_core]
ipx::remove_port s_axi_awprot [ipx::current_core]
ipx::remove_port s_axi_awvalid [ipx::current_core]
ipx::remove_port s_axi_awready [ipx::current_core]
ipx::remove_port s_axi_wdata [ipx::current_core]
ipx::remove_port s_axi_wstrb [ipx::current_core]
ipx::remove_port s_axi_wvalid [ipx::current_core]
ipx::remove_port s_axi_wready [ipx::current_core]
ipx::remove_port s_axi_bresp [ipx::current_core]
ipx::remove_port s_axi_bvalid [ipx::current_core]
ipx::remove_port s_axi_bready [ipx::current_core]
ipx::remove_port s_axi_araddr [ipx::current_core]
ipx::remove_port s_axi_arprot [ipx::current_core]
ipx::remove_port s_axi_arvalid [ipx::current_core]
ipx::remove_port s_axi_arready [ipx::current_core]
ipx::remove_port s_axi_rdata [ipx::current_core]
ipx::remove_port s_axi_rresp [ipx::current_core]
ipx::remove_port s_axi_rvalid [ipx::current_core]
ipx::remove_port s_axi_rready [ipx::current_core]
ipx::remove_memory_map s_axi [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axis_cc -clock axi_clk [ipx::current_core]
set_property value m_axi:m_axis_cc [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces axi_clk -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif s_axis_cq -clock axi_clk [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  ${root_dir}/../../../../generated_ip [current_project]
update_ip_catalog
remove_files {${root_dir}/pcie2axilite_bridge/axi_read_controller.v ${root_dir}/pcie2axilite_bridge/axi_write_controller.v  ${root_dir}/pcie2axilite_bridge/maxi_controller.v ${root_dir}/pcie2axilite_bridge/maxis_controller.v ${root_dir}/pcie2axilite_bridge/pcie_2_axilite.v  ${root_dir}/pcie2axilite_bridge/s_axi_config.v ${root_dir}/pcie2axilite_bridge/saxis_controller.v ${root_dir}/pcie2axilite_bridge/tag_manager.v}

# Add sources
add_files $hdl_dir

set_property top pcie_mem_alloc_top [current_fileset]
source ipCore_gen.tcl

#set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
#set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 300 [get_runs synth_1]
#set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
#set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
#set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
#launch_runs synth_1 -jobs 1 
#wait_on_run synth_1
#launch_runs impl_1 -to_step write_bitstream -jobs 1
#wait_on_run impl_1

ipx::package_project -root_dir ${root_dir}/../../../../generated_ip/memcached_pcie_alloc_vcu108 -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force -generated_files

update_ip_catalog -rebuild

close_project
puts "INFO: Project created: ${proj_name}"

exit

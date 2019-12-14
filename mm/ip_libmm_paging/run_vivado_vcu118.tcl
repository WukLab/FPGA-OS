# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "generated_vivado_project"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "run_vivado_vcu118.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/generated_vivado_project"]"

# Create project
create_project -f ${_xil_proj_name_} "./generated_vivado_project" -part xcvu9p-flga2104-2L-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]

set ver [version -short]
switch $ver {
	2019.1 {
		set_property -name "board_part" -value "xilinx.com:vcu118:part0:2.3" -objects $obj
	}
	2019.1.3 {
		set_property -name "board_part" -value "xilinx.com:vcu118:part0:2.3" -objects $obj
	}
	default {
		set_property -name "board_part" -value "xilinx.com:vcu118:part0:2.0" -objects $obj
	}
}

set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "dsa.accelerator_binary_content" -value "bitstream" -objects $obj
set_property -name "dsa.accelerator_binary_format" -value "xclbin2" -objects $obj
set_property -name "dsa.board_id" -value "vcu118" -objects $obj
set_property -name "dsa.description" -value "Vivado generated DSA" -objects $obj
set_property -name "dsa.dr_bd_base_address" -value "0" -objects $obj
set_property -name "dsa.emu_dir" -value "emu" -objects $obj
set_property -name "dsa.flash_interface_type" -value "bpix16" -objects $obj
set_property -name "dsa.flash_offset_address" -value "0" -objects $obj
set_property -name "dsa.flash_size" -value "1024" -objects $obj
set_property -name "dsa.host_architecture" -value "x86_64" -objects $obj
set_property -name "dsa.host_interface" -value "pcie" -objects $obj
set_property -name "dsa.num_compute_units" -value "60" -objects $obj
set_property -name "dsa.platform_state" -value "pre_synth" -objects $obj
set_property -name "dsa.vendor" -value "xilinx" -objects $obj
set_property -name "dsa.version" -value "0.0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO XPM_MEMORY" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../generated_ip"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/arch_defines.v"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/arch_package.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/MemoryArray.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/ddr4_sdram_model_wrapper.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/proj_package.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/StateTableCore.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/StateTable.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/timing_tasks.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/ddr4_model.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/interface.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/ddr4_tb_top.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/glbl.v"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/microblaze_mcs_0.sv"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
set file "$origin_dir/../../system/vcu118/tb/ddr4_model/arch_package.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/MemoryArray.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/ddr4_sdram_model_wrapper.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/proj_package.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/StateTableCore.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/StateTable.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/timing_tasks.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/ddr4_model.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/interface.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/ddr4_tb_top.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/microblaze_mcs_0.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj


# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "ddr4_tb_top" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Empty (no sources present)

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/arch_defines.v"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/arch_package.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/MemoryArray.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/ddr4_sdram_model_wrapper.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/proj_package.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/StateTableCore.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/StateTable.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/timing_tasks.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/ddr4_model.sv"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/interface.sv"] \
 [file normalize "${origin_dir}/rtl/tb.v"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/glbl.v"] \
 [file normalize "${origin_dir}/../../system/vcu118/tb/ddr4_model/microblaze_mcs_0.sv"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset file properties for remote files
set file "$origin_dir/../../system/vcu118/tb/ddr4_model/arch_package.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/MemoryArray.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/ddr4_sdram_model_wrapper.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/proj_package.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/StateTableCore.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/StateTable.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/timing_tasks.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/ddr4_model.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/interface.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/../../system/vcu118/tb/ddr4_model/microblaze_mcs_0.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj


# Set 'sim_1' fileset file properties for local files
# None

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "libmm_tb_top" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
# Empty (no sources present)

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]


# Adding sources referenced in BDs, if not already added


# Proc to create BD libmm_ip_top_TB
proc cr_bd_libmm_ip_top_TB { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name libmm_ip_top_TB

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set axis_data_fifo [get_ipdefs -filter NAME==axis_data_fifo]
  common::send_msg_id "BD_TCL-006" "INFO" "XX $axis_data_fifo"

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:axi_datamover:5.1\
  purdue.wuklab:hls:bram_hashtable:1.0\
  Wuklab.UCSD:hls:buddy_alloc_mux:1.0\
  UCSD.wuklab:hls:coord_top:1.0\
  purdue.wuklab:hls:paging_top:1.0\
  wuklab:hls:mm_segfix_hls:1.0\
  Wuklab.UCSD:hls:buddy_allocator:1.0\
  xilinx.com:ip:sim_clk_gen:1.0\
  Wuklab.UCSD:hls:virt_addr_allocator:1.0\
  ${axis_data_fifo}\
  xilinx.com:ip:axi_crossbar:2.1\
  xilinx.com:ip:axi_dwidth_converter:2.1\
  xilinx.com:ip:ddr4:2.2\
  xilinx.com:ip:util_vector_logic:2.0\
  "

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

  }

  if { $bCheckIPsPassed != 1 } {
    common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  
# Hierarchical cell: mc
proc create_hier_cell_mc { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_mc() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 C0_DDR4_S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1

  # Create pins
  create_bd_pin -dir O -type clk c0_ddr4_ui_clk
  create_bd_pin -dir I -type clk c0_sys_clk_i_0
  create_bd_pin -dir O -from 0 -to 0 -type rst mc_ddr4_ui_clk_rst_n
  create_bd_pin -dir O mc_init_calib_complete
  create_bd_pin -dir I -type rst sys_rst_0

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
  set_property -dict [ list \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1} \
 ] $ddr4_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins C0_SYS_CLK] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_pins ddr4_sdram_c1] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net mover_AXI [get_bd_intf_pins C0_DDR4_S_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]

  # Create port connections
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins c0_ddr4_ui_clk] [get_bd_pins ddr4_0/c0_ddr4_ui_clk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net ddr4_0_c0_init_calib_complete [get_bd_pins mc_init_calib_complete] [get_bd_pins ddr4_0/c0_init_calib_complete]
  connect_bd_net -net sys_rst_0_1 [get_bd_pins sys_rst_0] [get_bd_pins ddr4_0/sys_rst]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins ddr4_0/c0_ddr4_aresetn] [get_bd_pins util_vector_logic_0/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: fifos
proc create_hier_cell_fifos { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_fifos() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS2
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS3
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS2
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS3

  # Create pins
  create_bd_pin -dir I -type rst mc_ddr4_ui_clk_rst_n
  create_bd_pin -dir I -type clk s_axis_aclk

  set axis_data_fifo [get_ipdefs -filter NAME==axis_data_fifo]

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16} \
 ] $axis_data_fifo_0

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16} \
 ] $axis_data_fifo_1

  # Create instance: axis_data_fifo_2, and set properties
  set axis_data_fifo_2 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_2 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16} \
 ] $axis_data_fifo_2

  # Create instance: axis_data_fifo_3, and set properties
  set axis_data_fifo_3 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_3 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16} \
 ] $axis_data_fifo_3

  # Create interface connections
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS1 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS1 [get_bd_intf_pins M_AXIS3] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_2_M_AXIS [get_bd_intf_pins M_AXIS1] [get_bd_intf_pins axis_data_fifo_2/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_3_M_AXIS [get_bd_intf_pins M_AXIS2] [get_bd_intf_pins axis_data_fifo_3/M_AXIS]
  connect_bd_intf_net -intf_net bram_hashtable_0_BRAM_rd_data [get_bd_intf_pins S_AXIS3] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
  connect_bd_intf_net -intf_net mapping_hls_top_BRAM_rd_cmd_V [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
  connect_bd_intf_net -intf_net mapping_hls_top_BRAM_wr_cmd_V [get_bd_intf_pins S_AXIS1] [get_bd_intf_pins axis_data_fifo_2/S_AXIS]
  connect_bd_intf_net -intf_net mapping_hls_top_BRAM_wr_data [get_bd_intf_pins S_AXIS2] [get_bd_intf_pins axis_data_fifo_3/S_AXIS]

  # Create port connections
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins s_axis_aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins axis_data_fifo_2/s_axis_aclk] [get_bd_pins axis_data_fifo_3/s_axis_aclk]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins axis_data_fifo_2/s_axis_aresetn] [get_bd_pins axis_data_fifo_3/s_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: axi_interconnect
proc create_hier_cell_axi_interconnect { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_axi_interconnect() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst mc_ddr4_ui_clk_rst_n

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S01_BASE_ID {0x00000100} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_BASE_ID {0x00000200} \
   CONFIG.S03_BASE_ID {0x00000300} \
   CONFIG.S04_BASE_ID {0x00000400} \
   CONFIG.S05_BASE_ID {0x00000500} \
   CONFIG.S06_BASE_ID {0x00000600} \
   CONFIG.S07_BASE_ID {0x00000700} \
   CONFIG.S08_BASE_ID {0x00000800} \
   CONFIG.S09_BASE_ID {0x00000900} \
   CONFIG.S10_BASE_ID {0x00000a00} \
   CONFIG.S11_BASE_ID {0x00000b00} \
   CONFIG.S12_BASE_ID {0x00000c00} \
   CONFIG.S13_BASE_ID {0x00000d00} \
   CONFIG.S14_BASE_ID {0x00000e00} \
   CONFIG.S15_BASE_ID {0x00000f00} \
   CONFIG.STRATEGY {2} \
 ] $axi_crossbar_0

  # Create instance: axi_dwidth_converter_0, and set properties
  set axi_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0 ]

  # Create instance: axi_dwidth_converter_1, and set properties
  set axi_dwidth_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_crossbar_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_datamover_M_AXI_MM2S [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_datamover_M_AXI_S2MM [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net axi_dwidth_converter_0_M_AXI [get_bd_intf_pins axi_crossbar_0/S02_AXI] [get_bd_intf_pins axi_dwidth_converter_0/M_AXI]
  connect_bd_intf_net -intf_net axi_dwidth_converter_1_M_AXI [get_bd_intf_pins axi_crossbar_0/S03_AXI] [get_bd_intf_pins axi_dwidth_converter_1/M_AXI]
  connect_bd_intf_net -intf_net heap_allocator_m_axi_dram [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_dwidth_converter_1/S_AXI]
  connect_bd_intf_net -intf_net phy_mem_allocator_m_axi_dram [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_dwidth_converter_0/S_AXI]

  # Create port connections
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] [get_bd_pins axi_dwidth_converter_1/s_axi_aclk]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] [get_bd_pins axi_dwidth_converter_1/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: Buffer_ToBeRemoved
proc create_hier_cell_Buffer_ToBeRemoved { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Buffer_ToBeRemoved() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 in_read_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 in_read_m
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 in_write_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 in_write_m

  # Create pins
  create_bd_pin -dir I -type rst mc_ddr4_ui_clk_rst_n
  create_bd_pin -dir I -type clk s_axis_aclk

  set axis_data_fifo [get_ipdefs -filter NAME==axis_data_fifo]

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16} \
   CONFIG.TDATA_NUM_BYTES {9} \
 ] $axis_data_fifo_0

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16} \
   CONFIG.TDATA_NUM_BYTES {9} \
 ] $axis_data_fifo_1

  # Create interface connections
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins in_read_m] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins in_write_m] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
  connect_bd_intf_net -intf_net in_read_0_1 [get_bd_intf_pins in_read_0] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
  connect_bd_intf_net -intf_net in_write_0_1 [get_bd_intf_pins in_write_0] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]

  # Create port connections
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins s_axis_aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ctrl_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ctrl_in_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_opcode {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value opcode} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 2} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}} field_addr_len {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value addr_len} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 32} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 2} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}}}}} \
   CONFIG.TDATA_NUM_BYTES {5} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $ctrl_in_0
  set ctrl_out_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ctrl_out_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $ctrl_out_0
  set ddr4_sdram_c1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1 ]
  set in_read_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 in_read_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {9} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $in_read_0
  set in_write_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 in_write_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {9} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $in_write_0
  set out_read_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 out_read_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $out_read_0
  set out_write_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 out_write_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $out_write_0

  # Create ports
  set c0_sys_clk_i_0 [ create_bd_port -dir I -type clk c0_sys_clk_i_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300120000} \
 ] $c0_sys_clk_i_0
  set mc_ddr4_ui_clk_rst_n [ create_bd_port -dir O -from 0 -to 0 mc_ddr4_ui_clk_rst_n ]
  set mc_init_calib_complete [ create_bd_port -dir O mc_init_calib_complete ]
  set sys_rst_0 [ create_bd_port -dir I -type rst sys_rst_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst_0

  # Create instance: Buffer_ToBeRemoved
  create_hier_cell_Buffer_ToBeRemoved [current_bd_instance .] Buffer_ToBeRemoved

  # Create instance: axi_datamover, and set properties
  set axi_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover ]
  set_property -dict [ list \
   CONFIG.c_dummy {1} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_mm2s_id_width {8} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axi_s2mm_id_width {8} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_btt_used {23} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_mm2s_include_sf {false} \
   CONFIG.c_s2mm_btt_used {23} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_s_axis_s2mm_tdata_width {512} \
 ] $axi_datamover

  # Create instance: axi_interconnect
  create_hier_cell_axi_interconnect [current_bd_instance .] axi_interconnect

  # Create instance: bram_hashtable_0, and set properties
  set bram_hashtable_0 [ create_bd_cell -type ip -vlnv purdue.wuklab:hls:bram_hashtable:1.0 bram_hashtable_0 ]

  # Create instance: buddy_alloc_mux, and set properties
  set buddy_alloc_mux [ create_bd_cell -type ip -vlnv Wuklab.UCSD:hls:buddy_alloc_mux:1.0 buddy_alloc_mux ]

  # Create instance: coordinator, and set properties
  set coordinator [ create_bd_cell -type ip -vlnv UCSD.wuklab:hls:coord_top:1.0 coordinator ]

  # Create instance: fifos
  create_hier_cell_fifos [current_bd_instance .] fifos

  # Create instance: virt_addr_allocator, and set properties
  set virt_addr_allocator [ create_bd_cell -type ip -vlnv Wuklab.UCSD:hls:virt_addr_allocator:1.0 virt_addr_allocator ]

  # Create instance: mapping_hls_top, and set properties
  set mapping_hls_top [ create_bd_cell -type ip -vlnv purdue.wuklab:hls:paging_top:1.0 mapping_hls_top ]

  # Create instance: mc
  create_hier_cell_mc [current_bd_instance .] mc

  # Create instance: mm_segfix_hls_0, and set properties
  set mm_segfix_hls_0 [ create_bd_cell -type ip -vlnv wuklab:hls:mm_segfix_hls:1.0 mm_segfix_hls_0 ]

  # Create instance: phy_mem_allocator, and set properties
  set phy_mem_allocator [ create_bd_cell -type ip -vlnv Wuklab.UCSD:hls:buddy_allocator:1.0 phy_mem_allocator ]

  # Create instance: sim_clk_gen_0, and set properties
  set sim_clk_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:sim_clk_gen:1.0 sim_clk_gen_0 ]
  set_property -dict [ list \
   CONFIG.CLOCK_TYPE {Differential} \
   CONFIG.FREQ_HZ {250000000} \
 ] $sim_clk_gen_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins mc/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net axi_datamover_M_AXIS_MM2S [get_bd_intf_pins axi_datamover/M_AXIS_MM2S] [get_bd_intf_pins mapping_hls_top/DRAM_rd_data]
  connect_bd_intf_net -intf_net axi_datamover_M_AXIS_MM2S_STS [get_bd_intf_pins axi_datamover/M_AXIS_MM2S_STS] [get_bd_intf_pins mapping_hls_top/DRAM_rd_status_V_V]
  connect_bd_intf_net -intf_net axi_datamover_M_AXIS_S2MM_STS [get_bd_intf_pins axi_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins mapping_hls_top/DRAM_wr_status_V_V]
  connect_bd_intf_net -intf_net axi_datamover_M_AXI_MM2S [get_bd_intf_pins axi_datamover/M_AXI_MM2S] [get_bd_intf_pins axi_interconnect/S00_AXI]
  connect_bd_intf_net -intf_net axi_datamover_M_AXI_S2MM [get_bd_intf_pins axi_datamover/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect/S01_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins Buffer_ToBeRemoved/in_read_m] [get_bd_intf_pins mapping_hls_top/in_read_V]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS1 [get_bd_intf_pins bram_hashtable_0/BRAM_rd_cmd_V] [get_bd_intf_pins fifos/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins Buffer_ToBeRemoved/in_write_m] [get_bd_intf_pins mapping_hls_top/in_write_V]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS1 [get_bd_intf_pins fifos/M_AXIS3] [get_bd_intf_pins mapping_hls_top/BRAM_rd_data]
  connect_bd_intf_net -intf_net axis_data_fifo_2_M_AXIS [get_bd_intf_pins bram_hashtable_0/BRAM_wr_cmd_V] [get_bd_intf_pins fifos/M_AXIS1]
  connect_bd_intf_net -intf_net axis_data_fifo_3_M_AXIS [get_bd_intf_pins bram_hashtable_0/BRAM_wr_data] [get_bd_intf_pins fifos/M_AXIS2]
  connect_bd_intf_net -intf_net bram_hashtable_0_BRAM_rd_data [get_bd_intf_pins bram_hashtable_0/BRAM_rd_data] [get_bd_intf_pins fifos/S_AXIS3]
  connect_bd_intf_net -intf_net buddy_alloc_mux_0_buddy_alloc_ret_1_V [get_bd_intf_pins buddy_alloc_mux/buddy_alloc_ret_1_V] [get_bd_intf_pins coordinator/buddy_alloc_ret_V]
  connect_bd_intf_net -intf_net buddy_alloc_mux_0_buddy_alloc_ret_2_V [get_bd_intf_pins buddy_alloc_mux/buddy_alloc_ret_2_V] [get_bd_intf_pins mapping_hls_top/alloc_ret_V]
  connect_bd_intf_net -intf_net buddy_alloc_mux_0_fwd_buddy_alloc_req_V [get_bd_intf_pins buddy_alloc_mux/fwd_buddy_alloc_req_V] [get_bd_intf_pins phy_mem_allocator/alloc_V]
  connect_bd_intf_net -intf_net coord_top_0_seg_alloc_req_V [get_bd_intf_pins coordinator/seg_alloc_req_V] [get_bd_intf_pins mm_segfix_hls_0/ctl_in_V]
  connect_bd_intf_net -intf_net coordinator_buddy_alloc_req_V [get_bd_intf_pins buddy_alloc_mux/buddy_alloc_req_1_V] [get_bd_intf_pins coordinator/buddy_alloc_req_V]
  connect_bd_intf_net -intf_net coordinator_ctrl_out_V [get_bd_intf_ports ctrl_out_0] [get_bd_intf_pins coordinator/ctrl_out_V]
  connect_bd_intf_net -intf_net coordinator_init_buddy_addr_V [get_bd_intf_pins coordinator/init_buddy_addr_V] [get_bd_intf_pins phy_mem_allocator/buddy_init_V]
  connect_bd_intf_net -intf_net coordinator_init_heap_addr_V [get_bd_intf_pins coordinator/init_heap_addr_V] [get_bd_intf_pins virt_addr_allocator/buddy_init_V]
  connect_bd_intf_net -intf_net coordinator_init_tbl_addr_V_V [get_bd_intf_pins coordinator/init_tbl_addr_V_V] [get_bd_intf_pins mapping_hls_top/base_addr_V_V]
  connect_bd_intf_net -intf_net ctrl_in_V_0_1 [get_bd_intf_ports ctrl_in_0] [get_bd_intf_pins coordinator/ctrl_in_V]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins mc/ddr4_sdram_c1]
  connect_bd_intf_net -intf_net in_read_0_1 [get_bd_intf_ports in_read_0] [get_bd_intf_pins Buffer_ToBeRemoved/in_read_0]
  connect_bd_intf_net -intf_net in_write_0_1 [get_bd_intf_ports in_write_0] [get_bd_intf_pins Buffer_ToBeRemoved/in_write_0]
  connect_bd_intf_net -intf_net mapping_hls_top_BRAM_rd_cmd_V [get_bd_intf_pins fifos/S_AXIS] [get_bd_intf_pins mapping_hls_top/BRAM_rd_cmd_V]
  connect_bd_intf_net -intf_net mapping_hls_top_BRAM_wr_cmd_V [get_bd_intf_pins fifos/S_AXIS1] [get_bd_intf_pins mapping_hls_top/BRAM_wr_cmd_V]
  connect_bd_intf_net -intf_net mapping_hls_top_BRAM_wr_data [get_bd_intf_pins fifos/S_AXIS2] [get_bd_intf_pins mapping_hls_top/BRAM_wr_data]
  connect_bd_intf_net -intf_net mapping_hls_top_DRAM_rd_cmd_V [get_bd_intf_pins axi_datamover/S_AXIS_MM2S_CMD] [get_bd_intf_pins mapping_hls_top/DRAM_rd_cmd_V]
  connect_bd_intf_net -intf_net mapping_hls_top_DRAM_wr_cmd_V [get_bd_intf_pins axi_datamover/S_AXIS_S2MM_CMD] [get_bd_intf_pins mapping_hls_top/DRAM_wr_cmd_V]
  connect_bd_intf_net -intf_net mapping_hls_top_DRAM_wr_data [get_bd_intf_pins axi_datamover/S_AXIS_S2MM] [get_bd_intf_pins mapping_hls_top/DRAM_wr_data]
  connect_bd_intf_net -intf_net mapping_hls_top_alloc_V [get_bd_intf_pins buddy_alloc_mux/buddy_alloc_req_2_V] [get_bd_intf_pins mapping_hls_top/alloc_V]
  connect_bd_intf_net -intf_net mapping_hls_top_out_read_V [get_bd_intf_ports out_read_0] [get_bd_intf_pins mapping_hls_top/out_read_V]
  connect_bd_intf_net -intf_net mapping_hls_top_out_write_V [get_bd_intf_ports out_write_0] [get_bd_intf_pins mapping_hls_top/out_write_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_ctl_out_V [get_bd_intf_pins coordinator/seg_alloc_ret_V] [get_bd_intf_pins mm_segfix_hls_0/ctl_out_V]
  connect_bd_intf_net -intf_net phy_mem_allocator_alloc_ret_V [get_bd_intf_pins buddy_alloc_mux/fwd_buddy_alloc_ret_V] [get_bd_intf_pins phy_mem_allocator/alloc_ret_V]
  connect_bd_intf_net -intf_net phy_mem_allocator_m_axi_dram [get_bd_intf_pins axi_interconnect/S_AXI] [get_bd_intf_pins phy_mem_allocator/m_axi_dram]
  connect_bd_intf_net -intf_net sim_clk_gen_0_diff_clk [get_bd_intf_pins mc/C0_SYS_CLK] [get_bd_intf_pins sim_clk_gen_0/diff_clk]
  connect_bd_intf_net -intf_net virt_addr_allocator_m_axi_dram [get_bd_intf_pins axi_interconnect/S_AXI1] [get_bd_intf_pins virt_addr_allocator/m_axi_dram]

  # Create port connections
  connect_bd_net -net c0_sys_clk_i_0_1 [get_bd_ports c0_sys_clk_i_0] [get_bd_pins mc/c0_sys_clk_i_0]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins Buffer_ToBeRemoved/s_axis_aclk] [get_bd_pins axi_datamover/m_axi_mm2s_aclk] [get_bd_pins axi_datamover/m_axi_s2mm_aclk] [get_bd_pins axi_datamover/m_axis_mm2s_cmdsts_aclk] [get_bd_pins axi_datamover/m_axis_s2mm_cmdsts_awclk] [get_bd_pins axi_interconnect/aclk] [get_bd_pins bram_hashtable_0/ap_clk] [get_bd_pins buddy_alloc_mux/ap_clk] [get_bd_pins coordinator/ap_clk] [get_bd_pins fifos/s_axis_aclk] [get_bd_pins mapping_hls_top/ap_clk] [get_bd_pins mc/c0_ddr4_ui_clk] [get_bd_pins mm_segfix_hls_0/ap_clk] [get_bd_pins phy_mem_allocator/ap_clk] [get_bd_pins virt_addr_allocator/ap_clk]
  connect_bd_net -net ddr4_0_c0_init_calib_complete [get_bd_ports mc_init_calib_complete] [get_bd_pins mc/mc_init_calib_complete]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst_0] [get_bd_pins mc/sys_rst_0]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_ports mc_ddr4_ui_clk_rst_n] [get_bd_pins Buffer_ToBeRemoved/mc_ddr4_ui_clk_rst_n] [get_bd_pins axi_datamover/m_axi_mm2s_aresetn] [get_bd_pins axi_datamover/m_axi_s2mm_aresetn] [get_bd_pins axi_datamover/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins axi_datamover/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins axi_interconnect/mc_ddr4_ui_clk_rst_n] [get_bd_pins bram_hashtable_0/ap_rst_n] [get_bd_pins buddy_alloc_mux/ap_rst_n] [get_bd_pins coordinator/ap_rst_n] [get_bd_pins fifos/mc_ddr4_ui_clk_rst_n] [get_bd_pins mapping_hls_top/ap_rst_n] [get_bd_pins mc/mc_ddr4_ui_clk_rst_n] [get_bd_pins mm_segfix_hls_0/ap_rst_n] [get_bd_pins phy_mem_allocator/ap_rst_n] [get_bd_pins virt_addr_allocator/ap_rst_n]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_datamover/Data_MM2S] [get_bd_addr_segs mc/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_ddr4_0_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_datamover/Data_S2MM] [get_bd_addr_segs mc/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_ddr4_0_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces virt_addr_allocator/Data_m_axi_dram] [get_bd_addr_segs mc/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_ddr4_0_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces phy_mem_allocator/Data_m_axi_dram] [get_bd_addr_segs mc/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_ddr4_0_C0_DDR4_ADDRESS_BLOCK


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_libmm_ip_top_TB()
cr_bd_libmm_ip_top_TB ""
set_property REGISTERED_WITH_MANAGER "1" [get_files libmm_ip_top_TB.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files libmm_ip_top_TB.bd ] 

puts "INFO: Project created:${_xil_proj_name_}"
exit

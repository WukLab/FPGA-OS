# Vivado (TM) v2018.2 (64-bit)

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
set script_file "run_vivado.tcl"

# Help information for this script
proc help {} {
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
      "--help"         { help }
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
set orig_proj_dir "[file normalize "$origin_dir/"]"

# Create project
create_project -f ${_xil_proj_name_} "./generated_vivado_project" -part xcvu095-ffva2104-2-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:vcu108:part0:1.4" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "dsa.accelerator_binary_content" -value "bitstream" -objects $obj
set_property -name "dsa.accelerator_binary_format" -value "xclbin2" -objects $obj
set_property -name "dsa.board_id" -value "vcu108" -objects $obj
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
set_property -name "dsa.uses_pr" -value "1" -objects $obj
set_property -name "dsa.vendor" -value "xilinx" -objects $obj
set_property -name "dsa.version" -value "0.0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "6" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "6" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "6" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "6" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "6" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "6" -objects $obj
set_property -name "webtalk.xcelium_export_sim" -value "4" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "6" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "60" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

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
# Import local files from the original project
set files [list \
 [file normalize "${origin_dir}/ip/axi_ethernet_0.xci"]\
 [file normalize "${origin_dir}/rtl/axi_mac/axi_ethernet_0_axi_lite_ctrl.v" ]\
 [file normalize "${origin_dir}/rtl/axi_mac/axi_ethernet_0_bit_sync.v" ]\
 [file normalize "${origin_dir}/rtl/axi_mac/axi_ethernet_0_clocks_resets.v" ]\
 [file normalize "${origin_dir}/rtl/axi_mac/axi_ethernet_0_example.v" ]\
 [file normalize "${origin_dir}/rtl/axi_mac/axi_ethernet_0_reset_sync.v" ]\
 [file normalize "${origin_dir}/rtl/axi_mac/axi_ethernet_0_support.v" ]\
 [file normalize "${origin_dir}/rtl/qsfp_mac/sm.v"]\
 [file normalize "${origin_dir}/rtl/qsfp_mac/axi4_lite.v"]\
 [file normalize "${origin_dir}/rtl/top_axi_mac.v" ]\
 [file normalize "${origin_dir}/rtl/top_qsfp_mac.v" ]\
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
# None

# Set 'sources_1' fileset file properties for local files
set file "$origin_dir/ip/axi_ethernet_0.xci"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
set_property -name "registered_with_manager" -value "1" -objects $file_obj
if { ![get_property "is_locked" $file_obj] } {
  set_property -name "synth_checkpoint_mode" -value "Hierarchical" -objects $file_obj
}
set_property -name "registered_with_manager" -value "1" -objects $file_obj


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "top" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

#
# Create Constraints Fileset
# - constrs_1: for mac_qsfp
# - constrs_2: for mac_axi
#

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/rtl/top_qsfp_mac.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "rtl/top_qsfp_mac.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'constrs_2' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_2] ""]} {
  create_fileset -constrset constrs_2
}

# Set 'constrs_2' fileset object
set obj [get_filesets constrs_2]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/rtl/axi_mac/axi_ethernet_0_example_design.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "rtl/axi_mac/axi_ethernet_0_example_design.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_2] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj
set_property -name "processing_order" -value "EARLY" -objects $file_obj

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/rtl/axi_mac/axi_ethernet_0_ex_des_loc.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "rtl/axi_mac/axi_ethernet_0_ex_des_loc.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_2] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj
set_property -name "processing_order" -value "LATE" -objects $file_obj

# Set 'constrs_2' fileset properties
set obj [get_filesets constrs_2]

#
# Create Simulation Filesets
# - sim_1: for mac_qsfp
# - sim_2: for mac_axi
#

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Import local files from the original project
set files [list \
 [file normalize "${origin_dir}/tb/top_qsfp_mac_tb.v" ]\
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "legofpga_mac_qsfp_tb" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj


# Create 'sim_2' fileset (if not found)
if {[string equal [get_filesets -quiet sim_2] ""]} {
  create_fileset -simset sim_2
}

# Set 'sim_2' fileset object
set obj [get_filesets sim_2]
# Import local files from the original project
set files [list \
 [file normalize "${origin_dir}/tb/axi_ethernet_0_frame_typ.v" ]\
 [file normalize "${origin_dir}/tb/top_axi_mac_tb.v" ]\
]
add_files -norecurse -fileset $obj $files

# Set 'sim_2' fileset file properties for local files
set file "$origin_dir/tb/axi_ethernet_0_frame_typ.v"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_2] [list "*$file"]]
set_property -name "used_in" -value "implementation simulation" -objects $file_obj
set_property -name "used_in_synthesis" -value "0" -objects $file_obj

set file "$origin_dir/tb/top_axi_mac_tb.v"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_2] [list "*$file"]]
set_property -name "used_in" -value "implementation simulation" -objects $file_obj
set_property -name "used_in_synthesis" -value "0" -objects $file_obj

# Set 'sim_2' fileset properties
set obj [get_filesets sim_2]

#
# Create Block Diagrams
#

# Proc to create BD LegoFPGA_axis8
proc cr_bd_LegoFPGA_axis8 { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name LegoFPGA_axis8

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:axis_data_fifo:1.1\
  xilinx.com:ip:ddr4:2.2\
  wuklab:hls:dummy_net_dram:1.0\
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
  set ddr4_sdram_c1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1 ]
  set from_mac [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_mac ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 8} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
   CONFIG.TDATA_NUM_BYTES {1} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
   ] $from_mac
  set to_mac [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_mac ]

  # Create ports
  set clk_125 [ create_bd_port -dir I -type clk clk_125 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {from_mac:to_mac:m_axi_dram} \
 ] $clk_125
  set clk_125_rstn [ create_bd_port -dir I -type rst clk_125_rstn ]
  set clk_300 [ create_bd_port -dir I -type clk clk_300 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {clk_300_rstn} \
   CONFIG.FREQ_HZ {300000000} \
 ] $clk_300
  set clk_300_rstn [ create_bd_port -dir I -type rst clk_300_rstn ]
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $axi_interconnect_0

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {1} \
 ] $axis_data_fifo_0

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
  set_property -dict [ list \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1} \
 ] $ddr4_0

  # Create instance: dummy_net_dram_0, and set properties
  set dummy_net_dram_0 [ create_bd_cell -type ip -vlnv wuklab:hls:dummy_net_dram:1.0 dummy_net_dram_0 ]

  # Create instance: rx_8to512, and set properties
  set rx_8to512 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 rx_8to512 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_FIFO_DEPTH {1024} \
 ] $rx_8to512

  # Create instance: tx_512to8, and set properties
  set tx_512to8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 tx_512to8 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_FIFO_DEPTH {1024} \
 ] $tx_512to8

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_ports to_mac] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net dummy_net_dram_0_m_axi_dram_V [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins dummy_net_dram_0/m_axi_dram_V]
  connect_bd_intf_net -intf_net dummy_net_dram_0_to_net [get_bd_intf_pins dummy_net_dram_0/to_net] [get_bd_intf_pins tx_512to8/S00_AXIS]
  connect_bd_intf_net -intf_net from_mac_1 [get_bd_intf_ports from_mac] [get_bd_intf_pins rx_8to512/S00_AXIS]
  connect_bd_intf_net -intf_net rx_8to512_M00_AXIS [get_bd_intf_pins dummy_net_dram_0/from_net] [get_bd_intf_pins rx_8to512/M00_AXIS]
  connect_bd_intf_net -intf_net tx_512to8_M00_AXIS [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins tx_512to8/M00_AXIS]

  # Create port connections
  connect_bd_net -net M00_ACLK_1 [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins ddr4_0/c0_ddr4_ui_clk]
  connect_bd_net -net ap_clk_0_1 [get_bd_ports clk_125] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins dummy_net_dram_0/ap_clk] [get_bd_pins rx_8to512/ACLK] [get_bd_pins rx_8to512/M00_AXIS_ACLK] [get_bd_pins rx_8to512/S00_AXIS_ACLK] [get_bd_pins tx_512to8/ACLK] [get_bd_pins tx_512to8/M00_AXIS_ACLK] [get_bd_pins tx_512to8/S00_AXIS_ACLK]
  connect_bd_net -net ap_rst_n_0_1 [get_bd_ports clk_125_rstn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins dummy_net_dram_0/ap_rst_n] [get_bd_pins rx_8to512/ARESETN] [get_bd_pins rx_8to512/M00_AXIS_ARESETN] [get_bd_pins rx_8to512/S00_AXIS_ARESETN] [get_bd_pins tx_512to8/ARESETN] [get_bd_pins tx_512to8/M00_AXIS_ARESETN] [get_bd_pins tx_512to8/S00_AXIS_ARESETN]
  connect_bd_net -net c0_ddr4_aresetn_0_1 [get_bd_ports clk_300_rstn] [get_bd_pins ddr4_0/c0_ddr4_aresetn]
  connect_bd_net -net c0_sys_clk_i_0_1 [get_bd_ports clk_300] [get_bd_pins ddr4_0/c0_sys_clk_i]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst] [get_bd_pins ddr4_0/sys_rst]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins util_vector_logic_0/Res]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
common::send_msg_id "BD_TCL-1000" "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

  close_bd_design $design_name 
}
# End of cr_bd_LegoFPGA_axis8()
cr_bd_LegoFPGA_axis8 ""
set_property IS_MANAGED "0" [get_files LegoFPGA_axis8.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files LegoFPGA_axis8.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files LegoFPGA_axis8.bd ] 



# Proc to create BD clock_mac_axi
proc cr_bd_clock_mac_axi { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name clock_mac_axi

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:clk_wiz:6.0\
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

  # Create ports
  set clk_50 [ create_bd_port -dir O -type clk clk_50 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {50000000} \
 ] $clk_50
  set clk_100 [ create_bd_port -dir O -type clk clk_100 ]
  set clk_125 [ create_bd_port -dir O -type clk clk_125 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
 ] $clk_125
  set clk_166 [ create_bd_port -dir O -type clk clk_166 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {166666666} \
 ] $clk_166
  set clk_300 [ create_bd_port -dir O -type clk clk_300 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
 ] $clk_300
  set clk_in1_n_0 [ create_bd_port -dir I -type clk clk_in1_n_0 ]
  set clk_in1_p_0 [ create_bd_port -dir I -type clk clk_in1_p_0 ]
  set mmcm_lock_i_2 [ create_bd_port -dir O mmcm_lock_i_2 ]
  set mmcm_locked_i [ create_bd_port -dir O mmcm_locked_i ]
  set reset_0 [ create_bd_port -dir I -type rst reset_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset_0

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_JITTER {95.332} \
   CONFIG.CLKOUT1_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {300.000} \
   CONFIG.CLKOUT2_JITTER {112.261} \
   CONFIG.CLKOUT2_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {116.566} \
   CONFIG.CLKOUT3_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT3_USED {false} \
   CONFIG.CLKOUT4_JITTER {107.102} \
   CONFIG.CLKOUT4_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {166.666} \
   CONFIG.CLKOUT4_USED {false} \
   CONFIG.CLKOUT5_JITTER {134.978} \
   CONFIG.CLKOUT5_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {50.000} \
   CONFIG.CLKOUT5_USED {false} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sysclk_125} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {9.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.750} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {9} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {1} \
   CONFIG.MMCM_CLKOUT3_DIVIDE {1} \
   CONFIG.MMCM_CLKOUT4_DIVIDE {1} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {2} \
   CONFIG.RESET_PORT {reset} \
   CONFIG.RESET_TYPE {ACTIVE_HIGH} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $clk_wiz_0

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_JITTER {113.052} \
   CONFIG.CLKOUT1_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {166.666} \
   CONFIG.CLKOUT2_JITTER {143.688} \
   CONFIG.CLKOUT2_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {124.615} \
   CONFIG.CLKOUT3_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLKOUT4_JITTER {107.102} \
   CONFIG.CLKOUT4_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {166.666} \
   CONFIG.CLKOUT4_USED {false} \
   CONFIG.CLKOUT5_JITTER {134.978} \
   CONFIG.CLKOUT5_PHASE_ERROR {89.430} \
   CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {50.000} \
   CONFIG.CLKOUT5_USED {false} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sysclk_125} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {6.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {20} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {10} \
   CONFIG.MMCM_CLKOUT3_DIVIDE {1} \
   CONFIG.MMCM_CLKOUT4_DIVIDE {1} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {3} \
   CONFIG.RESET_PORT {reset} \
   CONFIG.RESET_TYPE {ACTIVE_HIGH} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $clk_wiz_1

  # Create port connections
  connect_bd_net -net clk_in1_n_0_1 [get_bd_ports clk_in1_n_0] [get_bd_pins clk_wiz_0/clk_in1_n] [get_bd_pins clk_wiz_1/clk_in1_n]
  connect_bd_net -net clk_in1_p_0_1 [get_bd_ports clk_in1_p_0] [get_bd_pins clk_wiz_0/clk_in1_p] [get_bd_pins clk_wiz_1/clk_in1_p]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_ports clk_300] [get_bd_pins clk_wiz_0/clk_out1]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_ports clk_125] [get_bd_pins clk_wiz_0/clk_out2]
  connect_bd_net -net clk_wiz_0_locked [get_bd_ports mmcm_locked_i] [get_bd_pins clk_wiz_0/locked]
  connect_bd_net -net clk_wiz_1_clk_out1 [get_bd_ports clk_166] [get_bd_pins clk_wiz_1/clk_out1]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_ports clk_50] [get_bd_pins clk_wiz_1/clk_out2]
  connect_bd_net -net clk_wiz_1_clk_out3 [get_bd_ports clk_100] [get_bd_pins clk_wiz_1/clk_out3]
  connect_bd_net -net clk_wiz_1_locked [get_bd_ports mmcm_lock_i_2] [get_bd_pins clk_wiz_1/locked]
  connect_bd_net -net reset_0_1 [get_bd_ports reset_0] [get_bd_pins clk_wiz_0/reset] [get_bd_pins clk_wiz_1/reset]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_clock_mac_axi()
cr_bd_clock_mac_axi ""
set_property IS_MANAGED "0" [get_files clock_mac_axi.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files clock_mac_axi.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files clock_mac_axi.bd ] 


# Proc to create BD clock_mac_qsfp
proc cr_bd_clock_mac_qsfp { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name clock_mac_qsfp

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:clk_wiz:6.0\
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
  set default_sysclk_125 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_sysclk_125 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $default_sysclk_125

  # Create ports
  set clk_100 [ create_bd_port -dir O -type clk clk_100 ]
  set clk_125 [ create_bd_port -dir O -type clk clk_125 ]
  set clk_300 [ create_bd_port -dir O -type clk clk_300 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
 ] $clk_300
  set clk_locked [ create_bd_port -dir O clk_locked ]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_JITTER {105.610} \
   CONFIG.CLKOUT1_PHASE_ERROR {97.646} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {300.000} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {10.125} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.375} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.USE_LOCKED {false} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_0

  # Create instance: sys_clkwiz_125, and set properties
  set sys_clkwiz_125 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 sys_clkwiz_125 ]
  set_property -dict [ list \
   CONFIG.CLKOUT2_JITTER {119.348} \
   CONFIG.CLKOUT2_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sysclk_125} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {8} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {2} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_RESET {false} \
 ] $sys_clkwiz_125

  # Create interface connections
  connect_bd_intf_net -intf_net sysclk_125_1 [get_bd_intf_ports default_sysclk_125] [get_bd_intf_pins sys_clkwiz_125/CLK_IN1_D]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_ports clk_300] [get_bd_pins clk_wiz_0/clk_out1]
  connect_bd_net -net clk_wiz_0_clk_out3 [get_bd_ports clk_100] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins sys_clkwiz_125/clk_out1]
  connect_bd_net -net clk_wiz_0_clk_out4 [get_bd_ports clk_125] [get_bd_pins sys_clkwiz_125/clk_out2]
  connect_bd_net -net clk_wiz_0_locked1 [get_bd_ports clk_locked] [get_bd_pins sys_clkwiz_125/locked]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_clock_mac_qsfp()
cr_bd_clock_mac_qsfp ""
set_property IS_MANAGED "0" [get_files clock_mac_qsfp.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files clock_mac_qsfp.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files clock_mac_qsfp.bd ] 


# Proc to create BD LegoFPGA_axis64
proc cr_bd_LegoFPGA_axis64 { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name LegoFPGA_axis64

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:ila:6.2\
  xilinx.com:ip:jtag_axi:1.2\
  xilinx.com:ip:vio:3.0\
  wuklab:hls:app_rdma_test:1.0\
  xilinx.com:ip:ddr4:2.2\
  xilinx.com:ip:util_vector_logic:2.0\
  wuklab:hls:app_rdma:1.0\
  xilinx.com:ip:xlconstant:1.1\
  wuklab:hls:sysnet_rx_512:1.0\
  xilinx.com:ip:axis_data_fifo:1.1\
  wuklab:hls:sysnet_tx_512:1.0\
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

  
# Hierarchical cell: sysnet_tx_top
proc create_hier_cell_sysnet_tx_top { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_sysnet_tx_top() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net

  # Create pins
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n
  create_bd_pin -dir I -type clk to_net_clk_390
  create_bd_pin -dir I -type rst to_net_clk_390_rst_n

  # Create instance: axis_512_to_64, and set properties
  set axis_512_to_64 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_512_to_64 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_FIFO_DEPTH {1024} \
 ] $axis_512_to_64

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.IS_ACLK_ASYNC {0} \
   CONFIG.TDATA_NUM_BYTES {8} \
 ] $axis_data_fifo_0

  # Create instance: sysnet_tx_512_0, and set properties
  set sysnet_tx_512_0 [ create_bd_cell -type ip -vlnv wuklab:hls:sysnet_tx_512:1.0 sysnet_tx_512_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins input_1] [get_bd_intf_pins sysnet_tx_512_0/input_1]
  connect_bd_intf_net -intf_net app_rdma_0_to_net [get_bd_intf_pins input_0] [get_bd_intf_pins sysnet_tx_512_0/input_0]
  connect_bd_intf_net -intf_net axis_512_to_64_M00_AXIS [get_bd_intf_pins axis_512_to_64/M00_AXIS] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins to_net] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net sysnet_tx_512_0_output_r [get_bd_intf_pins axis_512_to_64/S00_AXIS] [get_bd_intf_pins sysnet_tx_512_0/output_r]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins axis_512_to_64/ACLK] [get_bd_pins axis_512_to_64/S00_AXIS_ACLK] [get_bd_pins sysnet_tx_512_0/ap_clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins axis_512_to_64/ARESETN] [get_bd_pins axis_512_to_64/S00_AXIS_ARESETN] [get_bd_pins sysnet_tx_512_0/ap_rst_n]
  connect_bd_net -net to_net_clk_390_1 [get_bd_pins to_net_clk_390] [get_bd_pins axis_512_to_64/M00_AXIS_ACLK] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
  connect_bd_net -net to_net_clk_390_rst_n_1 [get_bd_pins to_net_clk_390_rst_n] [get_bd_pins axis_512_to_64/M00_AXIS_ARESETN] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: sysnet_rx_top
proc create_hier_cell_sysnet_rx_top { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_sysnet_rx_top() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_1

  # Create pins
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n
  create_bd_pin -dir I -type clk from_net_clk_390
  create_bd_pin -dir I -type rst from_net_clk_390_rst_n

  # Create instance: axis_64_to_512, and set properties
  set axis_64_to_512 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_64_to_512 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_FIFO_DEPTH {1024} \
 ] $axis_64_to_512

  # Create instance: sysnet_rx_512_0, and set properties
  set sysnet_rx_512_0 [ create_bd_cell -type ip -vlnv wuklab:hls:sysnet_rx_512:1.0 sysnet_rx_512_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins output_1] [get_bd_intf_pins sysnet_rx_512_0/output_1]
  connect_bd_intf_net -intf_net S00_AXIS_0_1 [get_bd_intf_pins from_net] [get_bd_intf_pins axis_64_to_512/S00_AXIS]
  connect_bd_intf_net -intf_net axis_64_to_512_M00_AXIS [get_bd_intf_pins axis_64_to_512/M00_AXIS] [get_bd_intf_pins sysnet_rx_512_0/input_r]
  connect_bd_intf_net -intf_net sysnet_rx_512_0_output_0 [get_bd_intf_pins output_0] [get_bd_intf_pins sysnet_rx_512_0/output_0]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins axis_64_to_512/ACLK] [get_bd_pins axis_64_to_512/M00_AXIS_ACLK] [get_bd_pins sysnet_rx_512_0/ap_clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins axis_64_to_512/ARESETN] [get_bd_pins axis_64_to_512/M00_AXIS_ARESETN] [get_bd_pins sysnet_rx_512_0/ap_rst_n]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_pins from_net_clk_390] [get_bd_pins axis_64_to_512/S00_AXIS_ACLK]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_pins from_net_clk_390_rst_n] [get_bd_pins axis_64_to_512/S00_AXIS_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: app_rdm_top
proc create_hier_cell_app_rdm_top { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_app_rdm_top() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_MEM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net

  # Create pins
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n

  # Create instance: app_rdma_0, and set properties
  set app_rdma_0 [ create_bd_cell -type ip -vlnv wuklab:hls:app_rdma:1.0 app_rdma_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net app_rdma_0_m_axi_MEM [get_bd_intf_pins m_axi_MEM] [get_bd_intf_pins app_rdma_0/m_axi_MEM]
  connect_bd_intf_net -intf_net app_rdma_0_to_net [get_bd_intf_pins to_net] [get_bd_intf_pins app_rdma_0/to_net]
  connect_bd_intf_net -intf_net sysnet_rx_512_0_output_0 [get_bd_intf_pins from_net] [get_bd_intf_pins app_rdma_0/from_net]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins app_rdma_0/ap_clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins app_rdma_0/ap_rst_n]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins app_rdma_0/dram_in_V] [get_bd_pins app_rdma_0/dram_out_V] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: Top_Network
proc create_hier_cell_Top_Network { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Top_Network() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net

  # Create pins
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n
  create_bd_pin -dir I -type clk from_net_clk_390
  create_bd_pin -dir I -type rst from_net_clk_390_rst_n
  create_bd_pin -dir I -type clk to_net_clk_390
  create_bd_pin -dir I -type rst to_net_clk_390_rst_n

  # Create instance: sysnet_rx_top
  create_hier_cell_sysnet_rx_top $hier_obj sysnet_rx_top

  # Create instance: sysnet_tx_top
  create_hier_cell_sysnet_tx_top $hier_obj sysnet_tx_top

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXIS_0_1 [get_bd_intf_pins from_net] [get_bd_intf_pins sysnet_rx_top/from_net]
  connect_bd_intf_net -intf_net app_rdma_0_to_net [get_bd_intf_pins input_0] [get_bd_intf_pins sysnet_tx_top/input_0]
  connect_bd_intf_net -intf_net app_rdma_test_0_to_net [get_bd_intf_pins input_1] [get_bd_intf_pins sysnet_tx_top/input_1]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins to_net] [get_bd_intf_pins sysnet_tx_top/to_net]
  connect_bd_intf_net -intf_net sysnet_rx_512_0_output_0 [get_bd_intf_pins output_0] [get_bd_intf_pins sysnet_rx_top/output_0]
  connect_bd_intf_net -intf_net sysnet_rx_top_output_1 [get_bd_intf_pins output_1] [get_bd_intf_pins sysnet_rx_top/output_1]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins sysnet_rx_top/clk_125] [get_bd_pins sysnet_tx_top/clk_125]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins sysnet_rx_top/clk_125_rst_n] [get_bd_pins sysnet_tx_top/clk_125_rst_n]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_pins from_net_clk_390] [get_bd_pins sysnet_rx_top/from_net_clk_390]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_pins from_net_clk_390_rst_n] [get_bd_pins sysnet_rx_top/from_net_clk_390_rst_n]
  connect_bd_net -net to_net_clk_390_1 [get_bd_pins to_net_clk_390] [get_bd_pins sysnet_tx_top/to_net_clk_390]
  connect_bd_net -net to_net_clk_390_rst_n_1 [get_bd_pins to_net_clk_390_rst_n] [get_bd_pins sysnet_tx_top/to_net_clk_390_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: Top_Memory
proc create_hier_cell_Top_Memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Top_Memory() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1

  # Create pins
  create_bd_pin -dir O -type rst ARESETN
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n
  create_bd_pin -dir I -type clk clk_300
  create_bd_pin -dir I -type rst clk_300_rst_n
  create_bd_pin -dir I -type rst sys_rst

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {3} \
 ] $axi_interconnect_0

  # Create instance: mc_ddr4_0, and set properties
  set mc_ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 mc_ddr4_0 ]
  set_property -dict [ list \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1} \
 ] $mc_ddr4_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net app_rdma_0_m_axi_MEM [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net app_rdma_test_0_m_axi_dram [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_interconnect_0/S02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins mc_ddr4_0/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_pins ddr4_sdram_c1] [get_bd_intf_pins mc_ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_interconnect_0/S01_AXI]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_0/S02_ARESETN]
  connect_bd_net -net c0_ddr4_aresetn_0_1 [get_bd_pins clk_300_rst_n] [get_bd_pins mc_ddr4_0/c0_ddr4_aresetn]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins ARESETN] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net c0_ddr4_ui_clk_rstn_1 [get_bd_pins mc_ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net c0_sys_clk_i_0_1 [get_bd_pins clk_300] [get_bd_pins mc_ddr4_0/c0_sys_clk_i]
  connect_bd_net -net mc_ddr4_0_c0_ddr4_ui_clk [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins mc_ddr4_0/c0_ddr4_ui_clk]
  connect_bd_net -net sys_rst_0_1 [get_bd_pins sys_rst] [get_bd_pins mc_ddr4_0/sys_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: Top_App_RDM
proc create_hier_cell_Top_App_RDM { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Top_App_RDM() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_MEM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dram
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net1

  # Create pins
  create_bd_pin -dir I ap_start
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n

  # Create instance: app_rdm_top
  create_hier_cell_app_rdm_top $hier_obj app_rdm_top

  # Create instance: app_rdma_test_0, and set properties
  set app_rdma_test_0 [ create_bd_cell -type ip -vlnv wuklab:hls:app_rdma_test:1.0 app_rdma_test_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net app_rdma_0_m_axi_MEM [get_bd_intf_pins m_axi_MEM] [get_bd_intf_pins app_rdm_top/m_axi_MEM]
  connect_bd_intf_net -intf_net app_rdma_0_to_net [get_bd_intf_pins to_net1] [get_bd_intf_pins app_rdm_top/to_net]
  connect_bd_intf_net -intf_net app_rdma_test_0_m_axi_dram [get_bd_intf_pins m_axi_dram] [get_bd_intf_pins app_rdma_test_0/m_axi_dram]
  connect_bd_intf_net -intf_net app_rdma_test_0_to_net [get_bd_intf_pins to_net] [get_bd_intf_pins app_rdma_test_0/to_net]
  connect_bd_intf_net -intf_net sysnet_rx_512_0_output_0 [get_bd_intf_pins from_net1] [get_bd_intf_pins app_rdm_top/from_net]
  connect_bd_intf_net -intf_net sysnet_rx_top_output_1 [get_bd_intf_pins from_net] [get_bd_intf_pins app_rdma_test_0/from_net]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins app_rdm_top/clk_125] [get_bd_pins app_rdma_test_0/ap_clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins app_rdm_top/clk_125_rst_n] [get_bd_pins app_rdma_test_0/ap_rst_n]
  connect_bd_net -net ap_start_1 [get_bd_pins ap_start] [get_bd_pins app_rdma_test_0/ap_start]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: Debug
proc create_hier_cell_Debug { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Debug() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  # Create pins
  create_bd_pin -dir I -type clk clk_125
  create_bd_pin -dir I -type rst clk_125_rst_n
  create_bd_pin -dir I -from 0 -to 0 mac_ready
  create_bd_pin -dir I -from 0 -to 0 probe0
  create_bd_pin -dir O -from 0 -to 0 probe_out0

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [ list \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {2} \
 ] $ila_0

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0 ]

  # Create instance: vio_0, and set properties
  set vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0 ]
  set_property -dict [ list \
   CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
   CONFIG.C_NUM_PROBE_IN {0} \
 ] $vio_0

  # Create interface connections
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_125] [get_bd_pins ila_0/clk] [get_bd_pins jtag_axi_0/aclk] [get_bd_pins vio_0/clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_125_rst_n] [get_bd_pins jtag_axi_0/aresetn]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins probe0] [get_bd_pins ila_0/probe0]
  connect_bd_net -net mac_ready_1 [get_bd_pins mac_ready] [get_bd_pins ila_0/probe1]
  connect_bd_net -net vio_0_probe_out0 [get_bd_pins probe_out0] [get_bd_pins vio_0/probe_out0]

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
  set ddr4_sdram_c1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1 ]
  set from_net [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {390000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {8} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $from_net
  set to_net [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {390000000} \
   ] $to_net

  # Create ports
  set clk_125 [ create_bd_port -dir I -type clk clk_125 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {clk_125_rst_n} \
   CONFIG.FREQ_HZ {125000000} \
 ] $clk_125
  set clk_125_rst_n [ create_bd_port -dir I -type rst clk_125_rst_n ]
  set clk_300 [ create_bd_port -dir I -type clk clk_300 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {clk_300_rst_n} \
   CONFIG.FREQ_HZ {300000000} \
 ] $clk_300
  set clk_300_rst_n [ create_bd_port -dir I -type rst clk_300_rst_n ]
  set from_net_clk_390 [ create_bd_port -dir I -type clk from_net_clk_390 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {from_net} \
   CONFIG.ASSOCIATED_RESET {from_net_clk_390_rst_n} \
   CONFIG.FREQ_HZ {390000000} \
 ] $from_net_clk_390
  set from_net_clk_390_rst_n [ create_bd_port -dir I -type rst from_net_clk_390_rst_n ]
  set mac_ready [ create_bd_port -dir I -from 0 -to 0 -type data mac_ready ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
 ] $mac_ready
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst
  set to_net_clk_390 [ create_bd_port -dir I -type clk to_net_clk_390 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {390000000} \
 ] $to_net_clk_390
  set to_net_clk_390_rst_n [ create_bd_port -dir I -type rst to_net_clk_390_rst_n ]

  # Create instance: Debug
  create_hier_cell_Debug [current_bd_instance .] Debug

  # Create instance: Top_App_RDM
  create_hier_cell_Top_App_RDM [current_bd_instance .] Top_App_RDM

  # Create instance: Top_Memory
  create_hier_cell_Top_Memory [current_bd_instance .] Top_Memory

  # Create instance: Top_Network
  create_hier_cell_Top_Network [current_bd_instance .] Top_Network

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXIS_0_1 [get_bd_intf_ports from_net] [get_bd_intf_pins Top_Network/from_net]
  connect_bd_intf_net -intf_net app_rdma_0_m_axi_MEM [get_bd_intf_pins Top_App_RDM/m_axi_MEM] [get_bd_intf_pins Top_Memory/S00_AXI]
  connect_bd_intf_net -intf_net app_rdma_0_to_net [get_bd_intf_pins Top_App_RDM/to_net1] [get_bd_intf_pins Top_Network/input_0]
  connect_bd_intf_net -intf_net app_rdma_test_0_m_axi_dram [get_bd_intf_pins Top_App_RDM/m_axi_dram] [get_bd_intf_pins Top_Memory/S02_AXI]
  connect_bd_intf_net -intf_net app_rdma_test_0_to_net [get_bd_intf_pins Top_App_RDM/to_net] [get_bd_intf_pins Top_Network/input_1]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_ports to_net] [get_bd_intf_pins Top_Network/to_net]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins Top_Memory/ddr4_sdram_c1]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins Debug/M_AXI] [get_bd_intf_pins Top_Memory/S01_AXI]
  connect_bd_intf_net -intf_net sysnet_rx_512_0_output_0 [get_bd_intf_pins Top_App_RDM/from_net1] [get_bd_intf_pins Top_Network/output_0]
  connect_bd_intf_net -intf_net sysnet_rx_top_output_1 [get_bd_intf_pins Top_App_RDM/from_net] [get_bd_intf_pins Top_Network/output_1]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_ports clk_125] [get_bd_pins Debug/clk_125] [get_bd_pins Top_App_RDM/clk_125] [get_bd_pins Top_Memory/clk_125] [get_bd_pins Top_Network/clk_125]
  connect_bd_net -net ARESETN_0_1 [get_bd_ports clk_125_rst_n] [get_bd_pins Debug/clk_125_rst_n] [get_bd_pins Top_App_RDM/clk_125_rst_n] [get_bd_pins Top_Memory/clk_125_rst_n] [get_bd_pins Top_Network/clk_125_rst_n]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_ports from_net_clk_390] [get_bd_pins Top_Network/from_net_clk_390]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_ports from_net_clk_390_rst_n] [get_bd_pins Top_Network/from_net_clk_390_rst_n]
  connect_bd_net -net c0_ddr4_aresetn_0_1 [get_bd_ports clk_300_rst_n] [get_bd_pins Top_Memory/clk_300_rst_n]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins Debug/probe0] [get_bd_pins Top_Memory/ARESETN]
  connect_bd_net -net c0_sys_clk_i_0_1 [get_bd_ports clk_300] [get_bd_pins Top_Memory/clk_300]
  connect_bd_net -net mac_ready_1 [get_bd_ports mac_ready] [get_bd_pins Debug/mac_ready]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst] [get_bd_pins Top_Memory/sys_rst]
  connect_bd_net -net to_net_clk_390_1 [get_bd_ports to_net_clk_390] [get_bd_pins Top_Network/to_net_clk_390]
  connect_bd_net -net to_net_clk_390_rst_n_1 [get_bd_ports to_net_clk_390_rst_n] [get_bd_pins Top_Network/to_net_clk_390_rst_n]
  connect_bd_net -net vio_0_probe_out0 [get_bd_pins Debug/probe_out0] [get_bd_pins Top_App_RDM/ap_start]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces Debug/jtag_axi_0/Data] [get_bd_addr_segs Top_Memory/mc_ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_0_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces Top_App_RDM/app_rdma_test_0/Data_m_axi_dram] [get_bd_addr_segs Top_Memory/mc_ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_0_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces Top_App_RDM/app_rdm_top/app_rdma_0/Data_m_axi_MEM] [get_bd_addr_segs Top_Memory/mc_ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_0_C0_DDR4_ADDRESS_BLOCK


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
common::send_msg_id "BD_TCL-1000" "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

  close_bd_design $design_name 
}
# End of cr_bd_LegoFPGA_axis64()
cr_bd_LegoFPGA_axis64 ""
set_property IS_MANAGED "0" [get_files LegoFPGA_axis64.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files LegoFPGA_axis64.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files LegoFPGA_axis64.bd ] 


# Proc to create BD mac_qsfp
proc cr_bd_mac_qsfp { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name mac_qsfp

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:xxv_ethernet:2.4\
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
  set AN_LT [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_xxv_ethernet:statistics_ports:2.0 AN_LT ]
  set ctl_tx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_xxv_ethernet:ctrl_ports:2.0 ctl_tx ]
  set gt_ref_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_ref_clk_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {161132812} \
   ] $gt_ref_clk_0
  set gt_serial_port_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 gt_serial_port_0 ]
  set rx_axis [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 rx_axis ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {390625000} \
   CONFIG.PHASE {0} \
   ] $rx_axis
  set s_axi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi
  set stat_rx [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_xxv_ethernet:statistics_ports:2.0 stat_rx ]
  set stat_tx [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_xxv_ethernet:statistics_ports:2.0 stat_tx ]
  set tx_axis [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 tx_axis ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {8} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
   ] $tx_axis

  # Create ports
  set an_clk [ create_bd_port -dir I -type clk an_clk ]
  set an_loc_np_data_0 [ create_bd_port -dir I -from 47 -to 0 an_loc_np_data_0 ]
  set an_reset_0 [ create_bd_port -dir I -type rst an_reset_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $an_reset_0
  set ctl_an_loc_np_0 [ create_bd_port -dir I ctl_an_loc_np_0 ]
  set ctl_an_lp_np_ack_0 [ create_bd_port -dir I ctl_an_lp_np_ack_0 ]
  set dclk [ create_bd_port -dir I -type clk dclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {sys_reset} \
 ] $dclk
  set gt_refclk_out_0 [ create_bd_port -dir O -type clk gt_refclk_out_0 ]
  set gtpowergood_out_0 [ create_bd_port -dir O gtpowergood_out_0 ]
  set gtwiz_reset_rx_datapath_0 [ create_bd_port -dir I -type rst gtwiz_reset_rx_datapath_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $gtwiz_reset_rx_datapath_0
  set gtwiz_reset_tx_datapath_0 [ create_bd_port -dir I -type rst gtwiz_reset_tx_datapath_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $gtwiz_reset_tx_datapath_0
  set lt_tx_sof_0 [ create_bd_port -dir O lt_tx_sof_0 ]
  set pm_tick_0 [ create_bd_port -dir I pm_tick_0 ]
  set rx_clk_out_0 [ create_bd_port -dir O -type clk rx_clk_out_0 ]
  set rx_core_clk_0 [ create_bd_port -dir I -type clk rx_core_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {rx_axis} \
   CONFIG.ASSOCIATED_RESET {rx_reset_0} \
   CONFIG.FREQ_HZ {390625000} \
   CONFIG.PHASE {0} \
 ] $rx_core_clk_0
  set rx_preambleout_0 [ create_bd_port -dir O -from 55 -to 0 rx_preambleout_0 ]
  set rx_reset_0 [ create_bd_port -dir I -type rst rx_reset_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rx_reset_0
  set rxoutclksel_in_0 [ create_bd_port -dir I -from 2 -to 0 rxoutclksel_in_0 ]
  set rxrecclkout_0 [ create_bd_port -dir O -type clk rxrecclkout_0 ]
  set s_axi_aclk_0 [ create_bd_port -dir I -type clk s_axi_aclk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {s_axi} \
   CONFIG.ASSOCIATED_RESET {s_axi_aresetn_0} \
 ] $s_axi_aclk_0
  set s_axi_aresetn_0 [ create_bd_port -dir I -type rst s_axi_aresetn_0 ]
  set stat_an_start_an_good_check_0 [ create_bd_port -dir O stat_an_start_an_good_check_0 ]
  set stat_rx_status_0 [ create_bd_port -dir O stat_rx_status_0 ]
  set sys_reset [ create_bd_port -dir I -type rst sys_reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_reset
  set tx_clk_out_0 [ create_bd_port -dir O -type clk tx_clk_out_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {tx_axis} \
 ] $tx_clk_out_0
  set tx_preamblein_0 [ create_bd_port -dir I -from 55 -to 0 tx_preamblein_0 ]
  set tx_reset_0 [ create_bd_port -dir I -type rst tx_reset_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $tx_reset_0
  set tx_unfout_0 [ create_bd_port -dir O tx_unfout_0 ]
  set txoutclksel_in_0 [ create_bd_port -dir I -from 2 -to 0 txoutclksel_in_0 ]
  set user_reg0_0 [ create_bd_port -dir O -from 31 -to 0 user_reg0_0 ]
  set user_rx_reset_0 [ create_bd_port -dir O -type rst user_rx_reset_0 ]
  set user_tx_reset_0 [ create_bd_port -dir O -type rst user_tx_reset_0 ]

  # Create instance: xxv_ethernet_0, and set properties
  set xxv_ethernet_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xxv_ethernet:2.4 xxv_ethernet_0 ]
  set_property -dict [ list \
   CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp_mgt_si570_clock2} \
   CONFIG.ETHERNET_BOARD_INTERFACE {qsfp_1x} \
   CONFIG.INCLUDE_AUTO_NEG_LT_LOGIC {Include AN/LT Logic} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $xxv_ethernet_0

  # Create interface connections
  connect_bd_intf_net -intf_net axis_tx_0_0_1 [get_bd_intf_ports tx_axis] [get_bd_intf_pins xxv_ethernet_0/axis_tx_0]
  connect_bd_intf_net -intf_net ctl_tx_0_0_1 [get_bd_intf_ports ctl_tx] [get_bd_intf_pins xxv_ethernet_0/ctl_tx_0]
  connect_bd_intf_net -intf_net gt_ref_clk_0_1 [get_bd_intf_ports gt_ref_clk_0] [get_bd_intf_pins xxv_ethernet_0/gt_ref_clk]
  connect_bd_intf_net -intf_net s_axi_0_0_1 [get_bd_intf_ports s_axi] [get_bd_intf_pins xxv_ethernet_0/s_axi_0]
  connect_bd_intf_net -intf_net xxv_ethernet_0_AN_LT_stat_0 [get_bd_intf_ports AN_LT] [get_bd_intf_pins xxv_ethernet_0/AN_LT_stat_0]
  connect_bd_intf_net -intf_net xxv_ethernet_0_axis_rx_0 [get_bd_intf_ports rx_axis] [get_bd_intf_pins xxv_ethernet_0/axis_rx_0]
  connect_bd_intf_net -intf_net xxv_ethernet_0_gt_serial_port [get_bd_intf_ports gt_serial_port_0] [get_bd_intf_pins xxv_ethernet_0/gt_serial_port]
  connect_bd_intf_net -intf_net xxv_ethernet_0_stat_rx_0 [get_bd_intf_ports stat_rx] [get_bd_intf_pins xxv_ethernet_0/stat_rx_0]
  connect_bd_intf_net -intf_net xxv_ethernet_0_stat_tx_0 [get_bd_intf_ports stat_tx] [get_bd_intf_pins xxv_ethernet_0/stat_tx_0]

  # Create port connections
  connect_bd_net -net an_clk_0_0_1 [get_bd_ports an_clk] [get_bd_pins xxv_ethernet_0/an_clk_0]
  connect_bd_net -net an_loc_np_data_0_0_1 [get_bd_ports an_loc_np_data_0] [get_bd_pins xxv_ethernet_0/an_loc_np_data_0]
  connect_bd_net -net an_reset_0_0_1 [get_bd_ports an_reset_0] [get_bd_pins xxv_ethernet_0/an_reset_0]
  connect_bd_net -net ctl_an_loc_np_0_0_1 [get_bd_ports ctl_an_loc_np_0] [get_bd_pins xxv_ethernet_0/ctl_an_loc_np_0]
  connect_bd_net -net ctl_an_lp_np_ack_0_0_1 [get_bd_ports ctl_an_lp_np_ack_0] [get_bd_pins xxv_ethernet_0/ctl_an_lp_np_ack_0]
  connect_bd_net -net dclk_0_1 [get_bd_ports dclk] [get_bd_pins xxv_ethernet_0/dclk]
  connect_bd_net -net gtwiz_reset_rx_datapath_0_0_1 [get_bd_ports gtwiz_reset_rx_datapath_0] [get_bd_pins xxv_ethernet_0/gtwiz_reset_rx_datapath_0]
  connect_bd_net -net gtwiz_reset_tx_datapath_0_0_1 [get_bd_ports gtwiz_reset_tx_datapath_0] [get_bd_pins xxv_ethernet_0/gtwiz_reset_tx_datapath_0]
  connect_bd_net -net pm_tick_0_0_1 [get_bd_ports pm_tick_0] [get_bd_pins xxv_ethernet_0/pm_tick_0]
  connect_bd_net -net rx_core_clk_0_0_1 [get_bd_ports rx_core_clk_0] [get_bd_pins xxv_ethernet_0/rx_core_clk_0]
  connect_bd_net -net rx_reset_0_0_1 [get_bd_ports rx_reset_0] [get_bd_pins xxv_ethernet_0/rx_reset_0]
  connect_bd_net -net rxoutclksel_in_0_0_1 [get_bd_ports rxoutclksel_in_0] [get_bd_pins xxv_ethernet_0/rxoutclksel_in_0]
  connect_bd_net -net s_axi_aclk_0_0_1 [get_bd_ports s_axi_aclk_0] [get_bd_pins xxv_ethernet_0/s_axi_aclk_0]
  connect_bd_net -net s_axi_aresetn_0_0_1 [get_bd_ports s_axi_aresetn_0] [get_bd_pins xxv_ethernet_0/s_axi_aresetn_0]
  connect_bd_net -net sys_reset_0_1 [get_bd_ports sys_reset] [get_bd_pins xxv_ethernet_0/sys_reset]
  connect_bd_net -net tx_preamblein_0_0_1 [get_bd_ports tx_preamblein_0] [get_bd_pins xxv_ethernet_0/tx_preamblein_0]
  connect_bd_net -net tx_reset_0_0_1 [get_bd_ports tx_reset_0] [get_bd_pins xxv_ethernet_0/tx_reset_0]
  connect_bd_net -net txoutclksel_in_0_0_1 [get_bd_ports txoutclksel_in_0] [get_bd_pins xxv_ethernet_0/txoutclksel_in_0]
  connect_bd_net -net xxv_ethernet_0_gt_refclk_out [get_bd_ports gt_refclk_out_0] [get_bd_pins xxv_ethernet_0/gt_refclk_out]
  connect_bd_net -net xxv_ethernet_0_gtpowergood_out_0 [get_bd_ports gtpowergood_out_0] [get_bd_pins xxv_ethernet_0/gtpowergood_out_0]
  connect_bd_net -net xxv_ethernet_0_lt_tx_sof_0 [get_bd_ports lt_tx_sof_0] [get_bd_pins xxv_ethernet_0/lt_tx_sof_0]
  connect_bd_net -net xxv_ethernet_0_rx_clk_out_0 [get_bd_ports rx_clk_out_0] [get_bd_pins xxv_ethernet_0/rx_clk_out_0]
  connect_bd_net -net xxv_ethernet_0_rx_preambleout_0 [get_bd_ports rx_preambleout_0] [get_bd_pins xxv_ethernet_0/rx_preambleout_0]
  connect_bd_net -net xxv_ethernet_0_rxrecclkout_0 [get_bd_ports rxrecclkout_0] [get_bd_pins xxv_ethernet_0/rxrecclkout_0]
  connect_bd_net -net xxv_ethernet_0_stat_an_start_an_good_check_0 [get_bd_ports stat_an_start_an_good_check_0] [get_bd_pins xxv_ethernet_0/stat_an_start_an_good_check_0]
  connect_bd_net -net xxv_ethernet_0_stat_rx_status_0 [get_bd_ports stat_rx_status_0] [get_bd_pins xxv_ethernet_0/stat_rx_status_0]
  connect_bd_net -net xxv_ethernet_0_tx_clk_out_0 [get_bd_ports tx_clk_out_0] [get_bd_pins xxv_ethernet_0/tx_clk_out_0]
  connect_bd_net -net xxv_ethernet_0_tx_unfout_0 [get_bd_ports tx_unfout_0] [get_bd_pins xxv_ethernet_0/tx_unfout_0]
  connect_bd_net -net xxv_ethernet_0_user_reg0_0 [get_bd_ports user_reg0_0] [get_bd_pins xxv_ethernet_0/user_reg0_0]
  connect_bd_net -net xxv_ethernet_0_user_rx_reset_0 [get_bd_ports user_rx_reset_0] [get_bd_pins xxv_ethernet_0/user_rx_reset_0]
  connect_bd_net -net xxv_ethernet_0_user_tx_reset_0 [get_bd_ports user_tx_reset_0] [get_bd_pins xxv_ethernet_0/user_tx_reset_0]

  # Create address segments
  create_bd_addr_seg -range 0x01000000 -offset 0x00000000 [get_bd_addr_spaces s_axi] [get_bd_addr_segs xxv_ethernet_0/s_axi_0/Reg] SEG_xxv_ethernet_0_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_mac_qsfp()
cr_bd_mac_qsfp ""
set_property IS_MANAGED "0" [get_files mac_qsfp.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files mac_qsfp.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files mac_qsfp.bd ] 

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xcvu095-ffva2104-2-e -flow {Vivado Synthesis 2018} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2018" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj
# Create 'synth_1_synth_report_utilization_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs synth_1] synth_1_synth_report_utilization_0] "" ] } {
  create_report_config -report_name synth_1_synth_report_utilization_0 -report_type report_utilization:1.0 -steps synth_design -runs synth_1
}
set obj [get_report_configs -of_objects [get_runs synth_1] synth_1_synth_report_utilization_0]
if { $obj != "" } {

}
set obj [get_runs synth_1]
set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part xcvu095-ffva2104-2-e -flow {Vivado Implementation 2018} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2018" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Implementation Default Reports} $obj
set_property set_report_strategy_name 0 $obj
# Create 'impl_1_init_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_init_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_init_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps init_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_init_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_opt_report_drc_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_drc_0] "" ] } {
  create_report_config -report_name impl_1_opt_report_drc_0 -report_type report_drc:1.0 -steps opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_drc_0]
if { $obj != "" } {

}
# Create 'impl_1_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_power_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_power_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_power_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps power_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_power_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_place_report_io_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_io_0] "" ] } {
  create_report_config -report_name impl_1_place_report_io_0 -report_type report_io:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_io_0]
if { $obj != "" } {

}
# Create 'impl_1_place_report_utilization_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_utilization_0] "" ] } {
  create_report_config -report_name impl_1_place_report_utilization_0 -report_type report_utilization:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_utilization_0]
if { $obj != "" } {

}
# Create 'impl_1_place_report_control_sets_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_control_sets_0] "" ] } {
  create_report_config -report_name impl_1_place_report_control_sets_0 -report_type report_control_sets:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_control_sets_0]
if { $obj != "" } {

}
# Create 'impl_1_place_report_incremental_reuse_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_0] "" ] } {
  create_report_config -report_name impl_1_place_report_incremental_reuse_0 -report_type report_incremental_reuse:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_place_report_incremental_reuse_1' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_1] "" ] } {
  create_report_config -report_name impl_1_place_report_incremental_reuse_1 -report_type report_incremental_reuse:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_1]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_place_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_place_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_post_place_power_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_place_power_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_post_place_power_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps post_place_power_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_place_power_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_phys_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_phys_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_phys_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps phys_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_phys_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_route_report_drc_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_drc_0] "" ] } {
  create_report_config -report_name impl_1_route_report_drc_0 -report_type report_drc:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_drc_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_methodology_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_methodology_0] "" ] } {
  create_report_config -report_name impl_1_route_report_methodology_0 -report_type report_methodology:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_methodology_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_power_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_power_0] "" ] } {
  create_report_config -report_name impl_1_route_report_power_0 -report_type report_power:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_power_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_route_status_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_route_status_0] "" ] } {
  create_report_config -report_name impl_1_route_report_route_status_0 -report_type report_route_status:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_route_status_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_route_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_timing_summary_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_incremental_reuse_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_incremental_reuse_0] "" ] } {
  create_report_config -report_name impl_1_route_report_incremental_reuse_0 -report_type report_incremental_reuse:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_incremental_reuse_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_clock_utilization_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_clock_utilization_0] "" ] } {
  create_report_config -report_name impl_1_route_report_clock_utilization_0 -report_type report_clock_utilization:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_clock_utilization_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_bus_skew_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_bus_skew_0] "" ] } {
  create_report_config -report_name impl_1_route_report_bus_skew_0 -report_type report_bus_skew:1.1 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_bus_skew_0]
if { $obj != "" } {

}
# Create 'impl_1_post_route_phys_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_post_route_phys_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps post_route_phys_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_timing_summary_0]
if { $obj != "" } {

}
# Create 'impl_1_post_route_phys_opt_report_bus_skew_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_bus_skew_0] "" ] } {
  create_report_config -report_name impl_1_post_route_phys_opt_report_bus_skew_0 -report_type report_bus_skew:1.1 -steps post_route_phys_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_bus_skew_0]
if { $obj != "" } {

}
set obj [get_runs impl_1]
set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:${_xil_proj_name_}"

exit

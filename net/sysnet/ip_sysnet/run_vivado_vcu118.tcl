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
set orig_proj_dir "[file normalize "$origin_dir/generated_vivado_project"]"

# Create project
create_project -f ${_xil_proj_name_} "./generated_vivado_project" -part xcvu9p-flga2104-2L-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:vcu118:part0:2.0" -objects $obj
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

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../../generated_ip"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
# Set 'sources_1' fileset file properties for remote files
# None

# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]

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
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]


# Adding sources referenced in BDs, if not already added


# Proc to create BD sysnet
proc cr_bd_sysnet { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name sysnet

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  wuklab:hls:sysnet_rx_512:1.0\
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

  
# Hierarchical cell: sysnet
proc create_hier_cell_sysnet_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_sysnet_1() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_0_0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_1_0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_r_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_0_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_1_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_r_0

  # Create pins
  create_bd_pin -dir I -type clk ap_clk_0
  create_bd_pin -dir I -type rst ap_rst_n_0

  # Create instance: sysnet_rx_512_0, and set properties
  set sysnet_rx_512_0 [ create_bd_cell -type ip -vlnv wuklab:hls:sysnet_rx_512:1.0 sysnet_rx_512_0 ]

  # Create instance: sysnet_tx_512_0, and set properties
  set sysnet_tx_512_0 [ create_bd_cell -type ip -vlnv wuklab:hls:sysnet_tx_512:1.0 sysnet_tx_512_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins output_0_0] [get_bd_intf_pins sysnet_rx_512_0/output_0]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins input_0_0] [get_bd_intf_pins sysnet_tx_512_0/input_0]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins input_1_0] [get_bd_intf_pins sysnet_tx_512_0/input_1]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins output_1_0] [get_bd_intf_pins sysnet_rx_512_0/output_1]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins input_r_0] [get_bd_intf_pins sysnet_rx_512_0/input_r]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins output_r_0] [get_bd_intf_pins sysnet_tx_512_0/output_r]

  # Create port connections
  connect_bd_net -net ap_clk_0_1 [get_bd_pins ap_clk_0] [get_bd_pins sysnet_rx_512_0/ap_clk] [get_bd_pins sysnet_tx_512_0/ap_clk]
  connect_bd_net -net ap_rst_n_0_1 [get_bd_pins ap_rst_n_0] [get_bd_pins sysnet_rx_512_0/ap_rst_n] [get_bd_pins sysnet_tx_512_0/ap_rst_n]

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
  set from_mac [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_mac ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 512} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 64} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $from_mac
  set to_libnet_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_libnet_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $to_libnet_0
  set to_libnet_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_libnet_1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $to_libnet_1
  set to_mac [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_mac ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $to_mac
  set to_sysnet_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 to_sysnet_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 512} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 64} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $to_sysnet_0
  set to_sysnet_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 to_sysnet_1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 512} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 64} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $to_sysnet_1

  # Create ports
  set sysnet_clk [ create_bd_port -dir I -type clk sysnet_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {sysnet_rst_n} \
   CONFIG.FREQ_HZ {125000000} \
 ] $sysnet_clk
  set sysnet_rst_n [ create_bd_port -dir I -type rst sysnet_rst_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $sysnet_rst_n

  # Create instance: sysnet
  create_hier_cell_sysnet_1 [current_bd_instance .] sysnet

  # Create interface connections
  connect_bd_intf_net -intf_net input_0_0_1 [get_bd_intf_ports to_sysnet_0] [get_bd_intf_pins sysnet/input_0_0]
  connect_bd_intf_net -intf_net input_1_0_1 [get_bd_intf_ports to_sysnet_1] [get_bd_intf_pins sysnet/input_1_0]
  connect_bd_intf_net -intf_net input_r_0_1 [get_bd_intf_ports from_mac] [get_bd_intf_pins sysnet/input_r_0]
  connect_bd_intf_net -intf_net sysnet_output_0_0 [get_bd_intf_ports to_libnet_0] [get_bd_intf_pins sysnet/output_0_0]
  connect_bd_intf_net -intf_net sysnet_output_1_0 [get_bd_intf_ports to_libnet_1] [get_bd_intf_pins sysnet/output_1_0]
  connect_bd_intf_net -intf_net sysnet_output_r_0 [get_bd_intf_ports to_mac] [get_bd_intf_pins sysnet/output_r_0]

  # Create port connections
  connect_bd_net -net ap_clk_0_1 [get_bd_ports sysnet_clk] [get_bd_pins sysnet/ap_clk_0]
  connect_bd_net -net ap_rst_n_0_1 [get_bd_ports sysnet_rst_n] [get_bd_pins sysnet/ap_rst_n_0]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_sysnet()
cr_bd_sysnet ""
set_property IS_MANAGED "0" [get_files sysnet.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files sysnet.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files sysnet.bd ] 


make_wrapper -files [get_files ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/sysnet/sysnet.bd] -top
add_files -norecurse ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/sysnet/hdl/sysnet_wrapper.v

# Export the project, not just the block diagram
ipx::package_project -root_dir ../../../generated_ip/net_ip_sysnet_vcu118 -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force

update_ip_catalog -rebuild
puts "INFO: Project created:${_xil_proj_name_}"
exit

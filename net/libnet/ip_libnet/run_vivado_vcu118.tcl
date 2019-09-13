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
set script_file "run_vivado_vcu108.tcl"

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

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../../generated_ip"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

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

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/rtl/ack_queue.v"] \
 [file normalize "${origin_dir}/rtl/rx_libnet_512.v"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for local files
# None

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
 [file normalize "${origin_dir}/tb/rx_libnet_512_tb.v"] \
 [file normalize "${origin_dir}/tb/ack_queue_tb.v"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset file properties for remote files
# None

# Set 'sim_1' fileset file properties for local files
# None

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "rx_libnet_512_tb" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj


# Adding sources referenced in BDs, if not already added
if { [get_files ack_queue.v] == "" } {
  import_files -quiet -fileset sources_1 /root/ys/FPGA/net/libnet/ip_libnet/rtl/ack_queue.v
}
if { [get_files rx_libnet_512.v] == "" } {
  import_files -quiet -fileset sources_1 /root/ys/FPGA/net/libnet/ip_libnet/rtl/rx_libnet_512.v
}
if { [get_files rx_libnet_512.v] == "" } {
  import_files -quiet -fileset sources_1 /root/ys/FPGA/net/libnet/ip_libnet/rtl/rx_libnet_512.v
}


# Proc to create BD ip_libnet
proc cr_bd_ip_libnet { parentCell } {
# The design that will be created by this Tcl proc contains the following 
# module references:
# ack_queue, rx_libnet_512, rx_libnet_512



  # CHANGE DESIGN NAME HERE
  set design_name ip_libnet

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK Modules
  ##################################################################
  set bCheckModules 1
  if { $bCheckModules == 1 } {
     set list_check_mods "\ 
  ack_queue\
  rx_libnet_512\
  rx_libnet_512\
  "

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
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
  set ack_to_sysnet [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ack_to_sysnet ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $ack_to_sysnet
  set libnet_to_app_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 libnet_to_app_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $libnet_to_app_0
  set libnet_to_app_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 libnet_to_app_1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $libnet_to_app_1
  set sysnet_to_libnet_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 sysnet_to_libnet_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $sysnet_to_libnet_0
  set sysnet_to_libnet_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 sysnet_to_libnet_1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $sysnet_to_libnet_1

  # Create ports
  set clk_0 [ create_bd_port -dir I -type clk clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {sysnet_to_libnet_0:ack_to_sysnet:libnet_to_app_0:libnet_to_app_1:sysnet_to_libnet_1} \
   CONFIG.FREQ_HZ {125000000} \
 ] $clk_0
  set resetn_0 [ create_bd_port -dir I -type rst resetn_0 ]

  # Create instance: ack_queue_0, and set properties
  set block_name ack_queue
  set block_cell_name ack_queue_0
  if { [catch {set ack_queue_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ack_queue_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rx_libnet_512_0, and set properties
  set block_name rx_libnet_512
  set block_cell_name rx_libnet_512_0
  if { [catch {set rx_libnet_512_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rx_libnet_512_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rx_libnet_512_1, and set properties
  set block_name rx_libnet_512
  set block_cell_name rx_libnet_512_1
  if { [catch {set rx_libnet_512_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rx_libnet_512_1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net ack_queue_0_tx [get_bd_intf_ports ack_to_sysnet] [get_bd_intf_pins ack_queue_0/tx]
  connect_bd_intf_net -intf_net rx_0_1 [get_bd_intf_ports sysnet_to_libnet_0] [get_bd_intf_pins rx_libnet_512_0/rx]
  connect_bd_intf_net -intf_net rx_0_2 [get_bd_intf_ports sysnet_to_libnet_1] [get_bd_intf_pins rx_libnet_512_1/rx]
  connect_bd_intf_net -intf_net rx_libnet_512_0_tx [get_bd_intf_ports libnet_to_app_0] [get_bd_intf_pins rx_libnet_512_0/tx]
  connect_bd_intf_net -intf_net rx_libnet_512_1_tx [get_bd_intf_ports libnet_to_app_1] [get_bd_intf_pins rx_libnet_512_1/tx]

  # Create port connections
  connect_bd_net -net clk_0_1 [get_bd_ports clk_0] [get_bd_pins ack_queue_0/clk] [get_bd_pins rx_libnet_512_0/clk] [get_bd_pins rx_libnet_512_1/clk]
  connect_bd_net -net resetn_0_1 [get_bd_ports resetn_0] [get_bd_pins ack_queue_0/resetn] [get_bd_pins rx_libnet_512_0/resetn] [get_bd_pins rx_libnet_512_1/resetn]
  connect_bd_net -net rx_libnet_512_0_seq_expected [get_bd_pins ack_queue_0/seq0_in] [get_bd_pins rx_libnet_512_0/seq_expected]
  connect_bd_net -net rx_libnet_512_0_seq_valid [get_bd_pins ack_queue_0/seq0_valid] [get_bd_pins rx_libnet_512_0/seq_valid]
  connect_bd_net -net rx_libnet_512_1_seq_expected [get_bd_pins ack_queue_0/seq1_in] [get_bd_pins rx_libnet_512_1/seq_expected]
  connect_bd_net -net rx_libnet_512_1_seq_valid [get_bd_pins ack_queue_0/seq1_valid] [get_bd_pins rx_libnet_512_1/seq_valid]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
common::send_msg_id "BD_TCL-1000" "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

  close_bd_design $design_name 
}
# End of cr_bd_ip_libnet()
cr_bd_ip_libnet ""
set_property IS_MANAGED "0" [get_files ip_libnet.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files ip_libnet.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files ip_libnet.bd ] 

make_wrapper -files [get_files ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/ip_libnet/ip_libnet.bd] -top
add_files -norecurse ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/ip_libnet/hdl/ip_libnet_wrapper.v

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "ip_libnet_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# Export the project, not just the block diagram
ipx::package_project -root_dir ../../../generated_ip/net_ip_libnet_vcu118 -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force

update_ip_catalog -rebuild

puts "INFO: Project created:${_xil_proj_name_}"
exit

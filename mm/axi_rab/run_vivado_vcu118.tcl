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
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../generated_ip"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
# Translator is a temporary one
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/rtl_single_clock/top.v"] \
 [file normalize "${origin_dir}/rtl_single_clock/axi_addr_ch_rxs.v"] \
 [file normalize "${origin_dir}/rtl_single_clock/axi_addr_ch_txs.v"] \
 [file normalize "${origin_dir}/rtl_single_clock/axi_wdata_chs.v"] \
 [file normalize "${origin_dir}/rtl_single_clock/axi_rdata_chs.v"] \
 [file normalize "${origin_dir}/rtl_single_clock/axi_bresp_chs.v"] \
 [file normalize "${origin_dir}/rtl/synch_fifo.v"]   \
 [file normalize "${origin_dir}/tb/translator.v"] \
]
add_files -norecurse -fileset $obj $files

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

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/top.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$origin_dir/top.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_part" -value "xcvu9p-flga2104-2L-e" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${origin_dir}/tb/sim_tb_top.sv"] \
]
add_files -norecurse -fileset $obj $files


# Proc to create BD axi_rab_bd
proc cr_bd_axi_rab_bd { parentCell } {
# The design that will be created by this Tcl proc contains the following 
# module references:
# axi_rab_top



  # CHANGE DESIGN NAME HERE
  set design_name axi_rab_bd

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK Modules
  ##################################################################
  set bCheckModules 1
  if { $bCheckModules == 1 } {
     set list_check_mods "\ 
  axi_rab_top\
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
  set fromMM_RD_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 fromMM_RD_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {5} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $fromMM_RD_0
  set fromMM_WR_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 fromMM_WR_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {5} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $fromMM_WR_0
  set m_axi_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $m_axi_0
  set s_axi_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {1} \
   CONFIG.AWUSER_WIDTH {1} \
   CONFIG.BUSER_WIDTH {1} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {8} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {1} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {1} \
   ] $s_axi_0
  set toMM_RD_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 toMM_RD_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $toMM_RD_0
  set toMM_WR_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 toMM_WR_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $toMM_WR_0

  # Create ports
  set s_aresetn_0 [ create_bd_port -dir I -type rst s_aresetn_0 ]
  set s_axi_clk_0 [ create_bd_port -dir I -type clk s_axi_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0:fromMM_WR_0:s_axi_0:toMM_RD_0:toMM_WR_0:m_axi_0} \
   CONFIG.ASSOCIATED_RESET {s_aresetn_0} \
   CONFIG.FREQ_HZ {300000000} \
 ] $s_axi_clk_0

  # Create instance: axi_rab_top_0, and set properties
  set block_name axi_rab_top
  set block_cell_name axi_rab_top_0
  if { [catch {set axi_rab_top_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_rab_top_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
 ] [get_bd_pins /axi_rab_top_0/s_axi_clk]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_rab_top_0_m_axi [get_bd_intf_ports m_axi_0] [get_bd_intf_pins axi_rab_top_0/m_axi]
  connect_bd_intf_net -intf_net axi_rab_top_0_toMM_RD [get_bd_intf_ports toMM_RD_0] [get_bd_intf_pins axi_rab_top_0/toMM_RD]
  connect_bd_intf_net -intf_net axi_rab_top_0_toMM_WR [get_bd_intf_ports toMM_WR_0] [get_bd_intf_pins axi_rab_top_0/toMM_WR]
  connect_bd_intf_net -intf_net fromMM_RD_0_1 [get_bd_intf_ports fromMM_RD_0] [get_bd_intf_pins axi_rab_top_0/fromMM_RD]
  connect_bd_intf_net -intf_net fromMM_WR_0_1 [get_bd_intf_ports fromMM_WR_0] [get_bd_intf_pins axi_rab_top_0/fromMM_WR]
  connect_bd_intf_net -intf_net s_axi_0_1 [get_bd_intf_ports s_axi_0] [get_bd_intf_pins axi_rab_top_0/s_axi]

  # Create port connections
  connect_bd_net -net s_aresetn_0_1 [get_bd_ports s_aresetn_0] [get_bd_pins axi_rab_top_0/s_aresetn]
  connect_bd_net -net s_axi_clk_0_1 [get_bd_ports s_axi_clk_0] [get_bd_pins axi_rab_top_0/s_axi_clk]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_rab_top_0/m_axi] [get_bd_addr_segs m_axi_0/Reg] SEG_m_axi_0_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs axi_rab_top_0/s_axi/reg0] SEG_axi_rab_top_0_reg0

set_property CONFIG.FREQ_HZ 300000000 [get_bd_pins /axi_rab_top_0/s_axi_clk]
set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins /axi_rab_top_0/fromMM_RD]
set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins /axi_rab_top_0/fromMM_WR]
set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins /axi_rab_top_0/toMM_RD]
set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins /axi_rab_top_0/toMM_WR]
set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins /axi_rab_top_0/m_axi]

set_property CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0} [get_bd_ports /s_axi_clk_0]
set_property CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0:fromMM_WR_0} [get_bd_ports /s_axi_clk_0]
set_property CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0:fromMM_WR_0:s_axi_0} [get_bd_ports /s_axi_clk_0]
set_property CONFIG.ASSOCIATED_RESET {s_aresetn_0} [get_bd_ports /s_axi_clk_0]
set_property CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0:fromMM_WR_0:s_axi_0:toMM_RD_0} [get_bd_ports /s_axi_clk_0]
set_property CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0:fromMM_WR_0:s_axi_0:toMM_RD_0:toMM_WR_0} [get_bd_ports /s_axi_clk_0]
set_property CONFIG.ASSOCIATED_BUSIF {fromMM_RD_0:fromMM_WR_0:s_axi_0:toMM_RD_0:toMM_WR_0:m_axi_0} [get_bd_ports /s_axi_clk_0]

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_axi_rab_bd()
cr_bd_axi_rab_bd ""
set_property REGISTERED_WITH_MANAGER "1" [get_files axi_rab_bd.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files axi_rab_bd.bd ] 

make_wrapper -files [get_files ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/axi_rab_bd/axi_rab_bd.bd] -top
add_files -norecurse ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/axi_rab_bd/hdl/axi_rab_bd_wrapper.v

ipx::package_project -root_dir ../../generated_ip/mm_axi_rab_vcu118 -vendor wuklab -library user -taxonomy UserIP -module axi_rab_bd -import_files
update_ip_catalog -rebuild

puts "INFO: Project created:${_xil_proj_name_}"
exit

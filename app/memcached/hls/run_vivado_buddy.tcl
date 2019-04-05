# Vivado (TM) v2018.2.2 (64-bit)

#
# This project only include Memcached pipeline and the Datamovers.
# We don't include another AXI interconnect here, mainly because
# we want to avoid using another layer of AXI interconnect to save
# latency.
#

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "memcached_buddy"

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
set orig_proj_dir "[file normalize "$origin_dir/generated_vivado_buddy_project"]"

# Create project
create_project -force ${_xil_proj_name_} "./generated_vivado_buddy_project" -part xcvu095-ffva2104-2-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "dsa.accelerator_binary_content" -value "bitstream" -objects $obj
set_property -name "dsa.accelerator_binary_format" -value "xclbin2" -objects $obj
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
set_property -name "part" -value "xcvu095-ffva2104-2-e" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "2" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "2" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "2" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "2" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "2" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "2" -objects $obj
set_property -name "webtalk.xcelium_export_sim" -value "2" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "2" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO XPM_MEMORY" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../../generated_ip"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
#set obj [get_filesets sources_1]
#set_property -name "top" -value "memcachedBuddy_top" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Empty (no sources present)

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_part" -value "xcvu095-ffva2104-2-e" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)


# Proc to create BD memcached_top_for_buddy
proc cr_bd_memcached_top_for_buddy { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name memcached_top_for_buddy

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.labs:hls:memcachedBuddy:1.07\
  xilinx.com:ip:axi_datamover:5.1\
  xilinx.com:ip:axis_clock_converter:1.1\
  xilinx.labs:hls:readConverter:1.04\
  xilinx.labs:hls:writeConverter:1.05\
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

  
# Hierarchical cell: vs
proc create_hier_cell_vs { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_vs() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_RD_C1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_WR_C1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memRdCmd_V
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 memRdData_V_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrCmd_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrData_V_V

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk mem_c0_clk
  create_bd_pin -dir I -type rst mem_c0_resetn

  # Create instance: vs_axi_datamover, and set properties
  set vs_axi_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 vs_axi_datamover ]
  set_property -dict [ list \
   CONFIG.c_dummy {0} \
   CONFIG.c_enable_mm2s_adv_sig {0} \
   CONFIG.c_enable_s2mm_adv_sig {0} \
   CONFIG.c_include_mm2s_dre {false} \
   CONFIG.c_include_s2mm_dre {false} \
   CONFIG.c_m_axi_mm2s_arid {3} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_mm2s_id_width {8} \
   CONFIG.c_m_axi_s2mm_awid {4} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axi_s2mm_id_width {8} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_btt_used {23} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_mm2s_include_sf {false} \
   CONFIG.c_s2mm_btt_used {23} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_s2mm_support_indet_btt {false} \
   CONFIG.c_s_axis_s2mm_tdata_width {512} \
   CONFIG.c_single_interface {0} \
 ] $vs_axi_datamover

  # Create instance: vs_rd_axis_clock_converter, and set properties
  set vs_rd_axis_clock_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 vs_rd_axis_clock_converter ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
 ] $vs_rd_axis_clock_converter

  # Create instance: vs_readConverter, and set properties
  set vs_readConverter [ create_bd_cell -type ip -vlnv xilinx.labs:hls:readConverter:1.04 vs_readConverter ]

  # Create instance: vs_wr_axis_clock_converter, and set properties
  set vs_wr_axis_clock_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 vs_wr_axis_clock_converter ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
 ] $vs_wr_axis_clock_converter

  # Create instance: vs_writeConverter, and set properties
  set vs_writeConverter [ create_bd_cell -type ip -vlnv xilinx.labs:hls:writeConverter:1.05 vs_writeConverter ]

  # Create interface connections
  connect_bd_intf_net -intf_net memRdCmd_V_1 [get_bd_intf_pins memRdCmd_V] [get_bd_intf_pins vs_readConverter/memRdCmd_V]
  connect_bd_intf_net -intf_net memWrCmd_V_1 [get_bd_intf_pins memWrCmd_V] [get_bd_intf_pins vs_writeConverter/memWrCmd_V]
  connect_bd_intf_net -intf_net memWrData_V_V_1 [get_bd_intf_pins memWrData_V_V] [get_bd_intf_pins vs_writeConverter/memWrData_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXIS_MM2S [get_bd_intf_pins vs_axi_datamover/M_AXIS_MM2S] [get_bd_intf_pins vs_rd_axis_clock_converter/S_AXIS]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXIS_MM2S_STS [get_bd_intf_pins vs_axi_datamover/M_AXIS_MM2S_STS] [get_bd_intf_pins vs_readConverter/dmRdStatus_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXIS_S2MM_STS [get_bd_intf_pins vs_axi_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins vs_writeConverter/dmWrStatus_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_MM2S [get_bd_intf_pins MCD_AXI2DRAM_RD_C1] [get_bd_intf_pins vs_axi_datamover/M_AXI_MM2S]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_S2MM [get_bd_intf_pins MCD_AXI2DRAM_WR_C1] [get_bd_intf_pins vs_axi_datamover/M_AXI_S2MM]
  connect_bd_intf_net -intf_net vs_rd_axis_clock_converter_M_AXIS [get_bd_intf_pins vs_rd_axis_clock_converter/M_AXIS] [get_bd_intf_pins vs_readConverter/dmRdData_V]
  connect_bd_intf_net -intf_net vs_readConverter_dmRdCmd_V [get_bd_intf_pins vs_axi_datamover/S_AXIS_MM2S_CMD] [get_bd_intf_pins vs_readConverter/dmRdCmd_V]
  connect_bd_intf_net -intf_net vs_readConverter_memRdData_V_V [get_bd_intf_pins memRdData_V_V] [get_bd_intf_pins vs_readConverter/memRdData_V_V]
  connect_bd_intf_net -intf_net vs_wr_axis_clock_converter_M_AXIS [get_bd_intf_pins vs_axi_datamover/S_AXIS_S2MM] [get_bd_intf_pins vs_wr_axis_clock_converter/M_AXIS]
  connect_bd_intf_net -intf_net vs_writeConverter_dmWrCmd_V [get_bd_intf_pins vs_axi_datamover/S_AXIS_S2MM_CMD] [get_bd_intf_pins vs_writeConverter/dmWrCmd_V]
  connect_bd_intf_net -intf_net vs_writeConverter_dmWrData_V [get_bd_intf_pins vs_wr_axis_clock_converter/S_AXIS] [get_bd_intf_pins vs_writeConverter/dmWrData_V]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aclk] [get_bd_pins vs_axi_datamover/m_axis_mm2s_cmdsts_aclk] [get_bd_pins vs_axi_datamover/m_axis_s2mm_cmdsts_awclk] [get_bd_pins vs_rd_axis_clock_converter/m_axis_aclk] [get_bd_pins vs_readConverter/aclk] [get_bd_pins vs_wr_axis_clock_converter/s_axis_aclk] [get_bd_pins vs_writeConverter/aclk]
  connect_bd_net -net Net1 [get_bd_pins aresetn] [get_bd_pins vs_axi_datamover/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins vs_axi_datamover/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins vs_rd_axis_clock_converter/m_axis_aresetn] [get_bd_pins vs_readConverter/aresetn] [get_bd_pins vs_wr_axis_clock_converter/s_axis_aresetn] [get_bd_pins vs_writeConverter/aresetn]
  connect_bd_net -net Net2 [get_bd_pins mem_c0_clk] [get_bd_pins vs_axi_datamover/m_axi_mm2s_aclk] [get_bd_pins vs_axi_datamover/m_axi_s2mm_aclk] [get_bd_pins vs_rd_axis_clock_converter/s_axis_aclk] [get_bd_pins vs_wr_axis_clock_converter/m_axis_aclk]
  connect_bd_net -net Net4 [get_bd_pins mem_c0_resetn] [get_bd_pins vs_axi_datamover/m_axi_mm2s_aresetn] [get_bd_pins vs_axi_datamover/m_axi_s2mm_aresetn] [get_bd_pins vs_rd_axis_clock_converter/s_axis_aresetn] [get_bd_pins vs_wr_axis_clock_converter/m_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: ht
proc create_hier_cell_ht { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_ht() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_RD_C0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_WR_C0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memRdCmd_V
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 memRdData_V_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrCmd_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrData_V_V

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk mem_c0_clk
  create_bd_pin -dir I -type rst mem_c0_resetn

  # Create instance: ht_axi_datamover, and set properties
  set ht_axi_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 ht_axi_datamover ]
  set_property -dict [ list \
   CONFIG.c_dummy {0} \
   CONFIG.c_enable_mm2s_adv_sig {0} \
   CONFIG.c_enable_s2mm {0} \
   CONFIG.c_enable_s2mm_adv_sig {0} \
   CONFIG.c_include_mm2s_dre {false} \
   CONFIG.c_include_s2mm {Omit} \
   CONFIG.c_include_s2mm_dre {false} \
   CONFIG.c_include_s2mm_stsfifo {false} \
   CONFIG.c_m_axi_mm2s_arid {1} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_mm2s_id_width {8} \
   CONFIG.c_m_axi_s2mm_awid {1} \
   CONFIG.c_m_axi_s2mm_data_width {32} \
   CONFIG.c_m_axi_s2mm_id_width {4} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_btt_used {23} \
   CONFIG.c_mm2s_burst_size {2} \
   CONFIG.c_mm2s_include_sf {false} \
   CONFIG.c_s2mm_addr_pipe_depth {3} \
   CONFIG.c_s2mm_btt_used {16} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_s2mm_support_indet_btt {false} \
   CONFIG.c_s_axis_s2mm_tdata_width {32} \
   CONFIG.c_single_interface {0} \
 ] $ht_axi_datamover

  # Create instance: ht_axi_datamover1, and set properties
  set ht_axi_datamover1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 ht_axi_datamover1 ]
  set_property -dict [ list \
   CONFIG.c_dummy {0} \
   CONFIG.c_enable_mm2s {0} \
   CONFIG.c_enable_mm2s_adv_sig {0} \
   CONFIG.c_enable_s2mm_adv_sig {0} \
   CONFIG.c_include_mm2s {Omit} \
   CONFIG.c_include_mm2s_dre {false} \
   CONFIG.c_include_mm2s_stsfifo {false} \
   CONFIG.c_include_s2mm_dre {false} \
   CONFIG.c_m_axi_mm2s_data_width {32} \
   CONFIG.c_m_axi_mm2s_id_width {4} \
   CONFIG.c_m_axi_s2mm_awid {2} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axi_s2mm_id_width {8} \
   CONFIG.c_m_axis_mm2s_tdata_width {32} \
   CONFIG.c_mm2s_btt_used {16} \
   CONFIG.c_mm2s_burst_size {2} \
   CONFIG.c_mm2s_include_sf {false} \
   CONFIG.c_s2mm_btt_used {23} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_s2mm_support_indet_btt {false} \
   CONFIG.c_s_axis_s2mm_tdata_width {512} \
   CONFIG.c_single_interface {0} \
 ] $ht_axi_datamover1

  # Create instance: ht_rd_axis_clock_converter, and set properties
  set ht_rd_axis_clock_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 ht_rd_axis_clock_converter ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
 ] $ht_rd_axis_clock_converter

  # Create instance: ht_readConverter, and set properties
  set ht_readConverter [ create_bd_cell -type ip -vlnv xilinx.labs:hls:readConverter:1.04 ht_readConverter ]

  # Create instance: ht_wr_axis_clock_converter, and set properties
  set ht_wr_axis_clock_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 ht_wr_axis_clock_converter ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
 ] $ht_wr_axis_clock_converter

  # Create instance: ht_writeConverter, and set properties
  set ht_writeConverter [ create_bd_cell -type ip -vlnv xilinx.labs:hls:writeConverter:1.05 ht_writeConverter ]

  # Create interface connections
  connect_bd_intf_net -intf_net ht_axi_datamover1_M_AXIS_S2MM_STS [get_bd_intf_pins ht_axi_datamover1/M_AXIS_S2MM_STS] [get_bd_intf_pins ht_writeConverter/dmWrStatus_V_V]
  connect_bd_intf_net -intf_net ht_axi_datamover1_M_AXI_S2MM [get_bd_intf_pins MCD_AXI2DRAM_WR_C0] [get_bd_intf_pins ht_axi_datamover1/M_AXI_S2MM]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXIS_MM2S [get_bd_intf_pins ht_axi_datamover/M_AXIS_MM2S] [get_bd_intf_pins ht_rd_axis_clock_converter/S_AXIS]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXIS_MM2S_STS [get_bd_intf_pins ht_axi_datamover/M_AXIS_MM2S_STS] [get_bd_intf_pins ht_readConverter/dmRdStatus_V_V]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_MM2S [get_bd_intf_pins MCD_AXI2DRAM_RD_C0] [get_bd_intf_pins ht_axi_datamover/M_AXI_MM2S]
  connect_bd_intf_net -intf_net ht_rd_axis_clock_converter_M_AXIS [get_bd_intf_pins ht_rd_axis_clock_converter/M_AXIS] [get_bd_intf_pins ht_readConverter/dmRdData_V]
  connect_bd_intf_net -intf_net ht_readConverter_dmRdCmd_V [get_bd_intf_pins ht_axi_datamover/S_AXIS_MM2S_CMD] [get_bd_intf_pins ht_readConverter/dmRdCmd_V]
  connect_bd_intf_net -intf_net ht_readConverter_memRdData_V_V [get_bd_intf_pins memRdData_V_V] [get_bd_intf_pins ht_readConverter/memRdData_V_V]
  connect_bd_intf_net -intf_net ht_wr_axis_clock_converter_M_AXIS [get_bd_intf_pins ht_axi_datamover1/S_AXIS_S2MM] [get_bd_intf_pins ht_wr_axis_clock_converter/M_AXIS]
  connect_bd_intf_net -intf_net ht_writeConverter_dmWrCmd_V [get_bd_intf_pins ht_axi_datamover1/S_AXIS_S2MM_CMD] [get_bd_intf_pins ht_writeConverter/dmWrCmd_V]
  connect_bd_intf_net -intf_net ht_writeConverter_dmWrData_V [get_bd_intf_pins ht_wr_axis_clock_converter/S_AXIS] [get_bd_intf_pins ht_writeConverter/dmWrData_V]
  connect_bd_intf_net -intf_net memRdCmd_V_1 [get_bd_intf_pins memRdCmd_V] [get_bd_intf_pins ht_readConverter/memRdCmd_V]
  connect_bd_intf_net -intf_net memWrCmd_V_1 [get_bd_intf_pins memWrCmd_V] [get_bd_intf_pins ht_writeConverter/memWrCmd_V]
  connect_bd_intf_net -intf_net memWrData_V_V_1 [get_bd_intf_pins memWrData_V_V] [get_bd_intf_pins ht_writeConverter/memWrData_V_V]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aclk] [get_bd_pins ht_axi_datamover/m_axis_mm2s_cmdsts_aclk] [get_bd_pins ht_axi_datamover1/m_axis_s2mm_cmdsts_awclk] [get_bd_pins ht_rd_axis_clock_converter/m_axis_aclk] [get_bd_pins ht_readConverter/aclk] [get_bd_pins ht_wr_axis_clock_converter/s_axis_aclk] [get_bd_pins ht_writeConverter/aclk]
  connect_bd_net -net Net1 [get_bd_pins aresetn] [get_bd_pins ht_axi_datamover/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins ht_axi_datamover1/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins ht_rd_axis_clock_converter/m_axis_aresetn] [get_bd_pins ht_readConverter/aresetn] [get_bd_pins ht_wr_axis_clock_converter/s_axis_aresetn] [get_bd_pins ht_writeConverter/aresetn]
  connect_bd_net -net Net2 [get_bd_pins mem_c0_clk] [get_bd_pins ht_axi_datamover/m_axi_mm2s_aclk] [get_bd_pins ht_axi_datamover1/m_axi_s2mm_aclk] [get_bd_pins ht_rd_axis_clock_converter/s_axis_aclk] [get_bd_pins ht_wr_axis_clock_converter/m_axis_aclk]
  connect_bd_net -net Net4 [get_bd_pins mem_c0_resetn] [get_bd_pins ht_axi_datamover/m_axi_mm2s_aresetn] [get_bd_pins ht_axi_datamover1/m_axi_s2mm_aresetn] [get_bd_pins ht_rd_axis_clock_converter/s_axis_aresetn] [get_bd_pins ht_wr_axis_clock_converter/m_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: mover
proc create_hier_cell_mover { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_mover() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_RD_C0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_RD_C1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_WR_C0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_WR_C1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memRdCmd_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memRdCmd_V1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 memRdData_V_V
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 memRdData_V_V1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrCmd_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrCmd_V1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrData_V_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 memWrData_V_V1

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk mem_c0_clk
  create_bd_pin -dir I -type rst mem_c0_resetn

  # Create instance: ht
  create_hier_cell_ht $hier_obj ht

  # Create instance: vs
  create_hier_cell_vs $hier_obj vs

  # Create interface connections
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_MM2S [get_bd_intf_pins MCD_AXI2DRAM_RD_C0] [get_bd_intf_pins ht/MCD_AXI2DRAM_RD_C0]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_S2MM [get_bd_intf_pins MCD_AXI2DRAM_WR_C0] [get_bd_intf_pins ht/MCD_AXI2DRAM_WR_C0]
  connect_bd_intf_net -intf_net ht_readConverter_memRdData_V_V [get_bd_intf_pins memRdData_V_V1] [get_bd_intf_pins ht/memRdData_V_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_dramValueStoreMemRdCmd_V [get_bd_intf_pins memRdCmd_V] [get_bd_intf_pins vs/memRdCmd_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_dramValueStoreMemWrCmd_V [get_bd_intf_pins memWrCmd_V] [get_bd_intf_pins vs/memWrCmd_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_dramValueStoreMemWrData_V_V [get_bd_intf_pins memWrData_V_V] [get_bd_intf_pins vs/memWrData_V_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_hashTableMemRdCmd_V [get_bd_intf_pins memRdCmd_V1] [get_bd_intf_pins ht/memRdCmd_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_hashTableMemWrCmd_V [get_bd_intf_pins memWrCmd_V1] [get_bd_intf_pins ht/memWrCmd_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_hashTableMemWrData_V_V [get_bd_intf_pins memWrData_V_V1] [get_bd_intf_pins ht/memWrData_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_MM2S [get_bd_intf_pins MCD_AXI2DRAM_RD_C1] [get_bd_intf_pins vs/MCD_AXI2DRAM_RD_C1]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_S2MM [get_bd_intf_pins MCD_AXI2DRAM_WR_C1] [get_bd_intf_pins vs/MCD_AXI2DRAM_WR_C1]
  connect_bd_intf_net -intf_net vs_readConverter_memRdData_V_V [get_bd_intf_pins memRdData_V_V] [get_bd_intf_pins vs/memRdData_V_V]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aclk] [get_bd_pins ht/aclk] [get_bd_pins vs/aclk]
  connect_bd_net -net Net1 [get_bd_pins aresetn] [get_bd_pins ht/aresetn] [get_bd_pins vs/aresetn]
  connect_bd_net -net Net2 [get_bd_pins mem_c0_clk] [get_bd_pins ht/mem_c0_clk] [get_bd_pins vs/mem_c0_clk]
  connect_bd_net -net Net4 [get_bd_pins mem_c0_resetn] [get_bd_pins ht/mem_c0_resetn] [get_bd_pins vs/mem_c0_resetn]

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
  set MCD_AXI2DRAM_RD_C0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_RD_C0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_ONLY} \
   ] $MCD_AXI2DRAM_RD_C0
  set MCD_AXI2DRAM_RD_C1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_RD_C1 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_ONLY} \
   ] $MCD_AXI2DRAM_RD_C1
  set MCD_AXI2DRAM_WR_C0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_WR_C0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
   ] $MCD_AXI2DRAM_WR_C0
  set MCD_AXI2DRAM_WR_C1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MCD_AXI2DRAM_WR_C1 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
   ] $MCD_AXI2DRAM_WR_C1
  set alloc_V_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 alloc_V_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {150000000} \
   ] $alloc_V_0
  set alloc_ret_V_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 alloc_ret_V_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {150000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {CLK {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}} TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 33} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_stat {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value stat} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_addr {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value addr} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 32} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}}} TDATA_WIDTH 40}} \
   CONFIG.TDATA_NUM_BYTES {5} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $alloc_ret_V_0
  set fromNet [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 fromNet ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {150000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 64} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 112} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
   CONFIG.TDATA_NUM_BYTES {8} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {112} \
   ] $fromNet
  set toNet [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 toNet ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {150000000} \
   ] $toNet

  # Create ports
  set aclk [ create_bd_port -dir I -type clk aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {fromNet:toNet:alloc_ret_V_0:alloc_V_0} \
   CONFIG.FREQ_HZ {150000000} \
 ] $aclk
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set mem_c0_clk [ create_bd_port -dir I -type clk mem_c0_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {MCD_AXI2DRAM_RD_C0:MCD_AXI2DRAM_WR_C0:MCD_AXI2DRAM_RD_C1:MCD_AXI2DRAM_WR_C1} \
   CONFIG.FREQ_HZ {300000000} \
 ] $mem_c0_clk
  set mem_c0_resetn [ create_bd_port -dir I -type rst mem_c0_resetn ]

  # Create instance: memcachedBuddy_0, and set properties
  set memcachedBuddy_0 [ create_bd_cell -type ip -vlnv xilinx.labs:hls:memcachedBuddy:1.07 memcachedBuddy_0 ]

  # Create instance: mover
  create_hier_cell_mover [current_bd_instance .] mover

  # Create interface connections
  connect_bd_intf_net -intf_net alloc_ret_V_0_1 [get_bd_intf_ports alloc_ret_V_0] [get_bd_intf_pins memcachedBuddy_0/alloc_ret_V]
  connect_bd_intf_net -intf_net fromNet_1 [get_bd_intf_ports fromNet] [get_bd_intf_pins memcachedBuddy_0/inData]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_MM2S [get_bd_intf_ports MCD_AXI2DRAM_RD_C0] [get_bd_intf_pins mover/MCD_AXI2DRAM_RD_C0]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_S2MM [get_bd_intf_ports MCD_AXI2DRAM_WR_C0] [get_bd_intf_pins mover/MCD_AXI2DRAM_WR_C0]
  connect_bd_intf_net -intf_net memRdCmd_V1_1 [get_bd_intf_pins memcachedBuddy_0/hashTableMemRdCmd_V] [get_bd_intf_pins mover/memRdCmd_V1]
  connect_bd_intf_net -intf_net memWrCmd_V1_1 [get_bd_intf_pins memcachedBuddy_0/hashTableMemWrCmd_V] [get_bd_intf_pins mover/memWrCmd_V1]
  connect_bd_intf_net -intf_net memWrCmd_V_1 [get_bd_intf_pins memcachedBuddy_0/dramValueStoreMemWrCmd_V] [get_bd_intf_pins mover/memWrCmd_V]
  connect_bd_intf_net -intf_net memWrData_V_V1_1 [get_bd_intf_pins memcachedBuddy_0/hashTableMemWrData_V_V] [get_bd_intf_pins mover/memWrData_V_V1]
  connect_bd_intf_net -intf_net memWrData_V_V_1 [get_bd_intf_pins memcachedBuddy_0/dramValueStoreMemWrData_V_V] [get_bd_intf_pins mover/memWrData_V_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_alloc_V [get_bd_intf_ports alloc_V_0] [get_bd_intf_pins memcachedBuddy_0/alloc_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_dramValueStoreMemRdCmd_V [get_bd_intf_pins memcachedBuddy_0/dramValueStoreMemRdCmd_V] [get_bd_intf_pins mover/memRdCmd_V]
  connect_bd_intf_net -intf_net memcachedBuddy_0_outData [get_bd_intf_ports toNet] [get_bd_intf_pins memcachedBuddy_0/outData]
  connect_bd_intf_net -intf_net mover_memRdData_V_V [get_bd_intf_pins memcachedBuddy_0/dramValueStoreMemRdData_V_V] [get_bd_intf_pins mover/memRdData_V_V]
  connect_bd_intf_net -intf_net mover_memRdData_V_V1 [get_bd_intf_pins memcachedBuddy_0/hashTableMemRdData_V_V] [get_bd_intf_pins mover/memRdData_V_V1]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_MM2S [get_bd_intf_ports MCD_AXI2DRAM_RD_C1] [get_bd_intf_pins mover/MCD_AXI2DRAM_RD_C1]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_S2MM [get_bd_intf_ports MCD_AXI2DRAM_WR_C1] [get_bd_intf_pins mover/MCD_AXI2DRAM_WR_C1]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports aclk] [get_bd_pins memcachedBuddy_0/ap_clk] [get_bd_pins mover/aclk]
  connect_bd_net -net Net1 [get_bd_ports aresetn] [get_bd_pins memcachedBuddy_0/ap_rst_n] [get_bd_pins mover/aresetn]
  connect_bd_net -net Net2 [get_bd_ports mem_c0_clk] [get_bd_pins mover/mem_c0_clk]
  connect_bd_net -net Net4 [get_bd_ports mem_c0_resetn] [get_bd_pins mover/mem_c0_resetn]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces mover/ht/ht_axi_datamover/Data_MM2S] [get_bd_addr_segs MCD_AXI2DRAM_RD_C0/Reg] SEG_MCD_AXI2DRAM_RD_C0_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces mover/ht/ht_axi_datamover1/Data_S2MM] [get_bd_addr_segs MCD_AXI2DRAM_WR_C0/Reg] SEG_MCD_AXI2DRAM_WR_C0_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces mover/vs/vs_axi_datamover/Data_MM2S] [get_bd_addr_segs MCD_AXI2DRAM_RD_C1/Reg] SEG_MCD_AXI2DRAM_RD_C1_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces mover/vs/vs_axi_datamover/Data_S2MM] [get_bd_addr_segs MCD_AXI2DRAM_WR_C1/Reg] SEG_MCD_AXI2DRAM_WR_C1_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_memcached_top_for_buddy()
cr_bd_memcached_top_for_buddy ""
set_property IS_MANAGED "0" [get_files memcached_top_for_buddy.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files memcached_top_for_buddy.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files memcached_top_for_buddy.bd ] 

##################################################################
# Make wrappers so that these IPs can be treated as black boxes 
##################################################################
#make_wrapper -files [get_files ${origin_dir}/generated_vivado_buddy_project/memcached_buddy.srcs/sources_1/bd/memcached_top_for_buddy/memcached_top_for_buddy.bd] -top
#add_files -norecurse ${origin_dir}/generated_vivado_buddy_project/memcached_buddy.srcs/sources_1/bd/memcached_top_for_buddy/hdl/memcached_top_for_buddy_wrapper.v


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
set_property -name "part" -value "xcvu095-ffva2104-2-e" -objects $obj
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
set_property -name "part" -value "xcvu095-ffva2104-2-e" -objects $obj
set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

#####################################################
#
####################################################

set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 300 [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]

#ipx::package_project -root_dir ${origin_dir}/../../../generated_ip/app_memcached_buddy_vcu108 -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force

ipx::package_project -root_dir ${origin_dir}/../../../generated_ip/app_memcached_buddy_vcu108 -vendor wuklab -library user -taxonomy UserIP -module memcached_top_for_buddy -import_files

update_ip_catalog -rebuild

puts "INFO: Project created:${_xil_proj_name_}"
exit

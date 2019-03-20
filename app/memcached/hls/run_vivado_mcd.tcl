################################################################
# This is a generated script based on design: mcd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source mcd_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Set the project name
set _xil_proj_name_ "memcached_pipeline"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

create_project -force ${_xil_proj_name_} "./generated_vivado_project" -part xcvu095-ffva2104-2-e


set_property  ip_repo_paths  ${script_folder}/../../../generated_ip [current_project]

update_ip_catalog

# CHANGE DESIGN NAME HERE
variable design_name
set design_name memcached_pipeline

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
# xilinx.labs:hls:flashModel:1.0\
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_datamover:5.1\
xilinx.com:ip:axis_clock_converter:1.1\
xilinx.labs:hls:readConverter:1.04\
xilinx.labs:hls:writeConverter:1.05\
xilinx.labs:hls:memcachedPipeline:1.07\
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

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

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
  set alloc2mcd_DramIn_V_V_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 alloc2mcd_DramIn_V_V_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {CLK {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}}}} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $alloc2mcd_DramIn_V_V_0
#  set alloc2mcd_FlashIn_V_V_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 alloc2mcd_FlashIn_V_V_0 ]
#  set_property -dict [ list \
#   CONFIG.HAS_TKEEP {0} \
#   CONFIG.HAS_TLAST {0} \
#   CONFIG.HAS_TREADY {1} \
#   CONFIG.HAS_TSTRB {0} \
#   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {CLK {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}}}} \
#   CONFIG.TDATA_NUM_BYTES {4} \
#   CONFIG.TDEST_WIDTH {0} \
#   CONFIG.TID_WIDTH {0} \
#   CONFIG.TUSER_WIDTH {0} \
#   ] $alloc2mcd_FlashIn_V_V_0
  set fromNet [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 fromNet ]
  set_property -dict [ list \
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
  set mcd2alloc_V_V_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 mcd2alloc_V_V_0 ]
  set toNet [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 toNet ]

  # Create ports
  set aclk [ create_bd_port -dir I -type clk aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {fromNet:toNet:alloc2mcd_DramIn_V_V_0:mcd2alloc_V_V_0} \
 ] $aclk
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set flushAck_V_0 [ create_bd_port -dir I -from 0 -to 0 -type data flushAck_V_0 ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
 ] $flushAck_V_0
  set flushDone_V_0 [ create_bd_port -dir O -from 0 -to 0 -type data flushDone_V_0 ]
  set flushReq_V_0 [ create_bd_port -dir O -from 0 -to 0 -type data flushReq_V_0 ]
  set mem_c0_clk [ create_bd_port -dir I -type clk mem_c0_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {MCD_AXI2DRAM_RD_C0:MCD_AXI2DRAM_WR_C0} \
 ] $mem_c0_clk
  set mem_c0_resetn [ create_bd_port -dir I -type rst mem_c0_resetn ]
  set mem_c1_clk [ create_bd_port -dir I -type clk mem_c1_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {MCD_AXI2DRAM_RD_C1:MCD_AXI2DRAM_WR_C1} \
 ] $mem_c1_clk
  set mem_c1_resetn [ create_bd_port -dir I -type rst mem_c1_resetn ]

  # Create instance: flashModel_0, and set properties
  #set flashModel_0 [ create_bd_cell -type ip -vlnv xilinx.labs:hls:flashModel:1.0 flashModel_0 ]

  # Create instance: ht_axi_datamover, and set properties
  set ht_axi_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 ht_axi_datamover ]
  set_property -dict [ list \
   CONFIG.c_dummy {0} \
   CONFIG.c_enable_mm2s_adv_sig {0} \
   CONFIG.c_enable_s2mm_adv_sig {0} \
   CONFIG.c_include_mm2s_dre {false} \
   CONFIG.c_include_s2mm_dre {false} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_mm2s_id_width {5} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axi_s2mm_id_width {5} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_btt_used {23} \
   CONFIG.c_mm2s_burst_size {4} \
   CONFIG.c_s2mm_btt_used {23} \
   CONFIG.c_s2mm_burst_size {4} \
   CONFIG.c_s2mm_support_indet_btt {false} \
   CONFIG.c_s_axis_s2mm_tdata_width {512} \
   CONFIG.c_single_interface {0} \
 ] $ht_axi_datamover

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

  # Create instance: memcachedPipeline_0, and set properties
  set memcachedPipeline_0 [ create_bd_cell -type ip -vlnv xilinx.labs:hls:memcachedPipeline:1.07 memcachedPipeline_0 ]

  # Create instance: vs_axi_datamover, and set properties
  set vs_axi_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 vs_axi_datamover ]
  set_property -dict [ list \
   CONFIG.c_dummy {0} \
   CONFIG.c_enable_mm2s_adv_sig {0} \
   CONFIG.c_enable_s2mm_adv_sig {0} \
   CONFIG.c_include_mm2s_dre {false} \
   CONFIG.c_include_s2mm_dre {false} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_mm2s_id_width {5} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axi_s2mm_id_width {5} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_btt_used {23} \
   CONFIG.c_mm2s_burst_size {4} \
   CONFIG.c_s2mm_btt_used {23} \
   CONFIG.c_s2mm_burst_size {4} \
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
  connect_bd_intf_net -intf_net addressAssignDramIn_V_V_0_1 [get_bd_intf_ports alloc2mcd_DramIn_V_V_0] [get_bd_intf_pins memcachedPipeline_0/addressAssignDramIn_V_V]
  #connect_bd_intf_net -intf_net addressAssignFlashIn_V_V_0_1 [get_bd_intf_ports alloc2mcd_FlashIn_V_V_0] [get_bd_intf_pins memcachedPipeline_0/addressAssignFlashIn_V_V]
  #connect_bd_intf_net -intf_net flashModel_0_rdDataOut_V_V [get_bd_intf_pins flashModel_0/rdDataOut_V_V] [get_bd_intf_pins memcachedPipeline_0/flashValueStoreMemRdData_V_V]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXIS_MM2S [get_bd_intf_pins ht_axi_datamover/M_AXIS_MM2S] [get_bd_intf_pins ht_rd_axis_clock_converter/S_AXIS]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXIS_MM2S_STS [get_bd_intf_pins ht_axi_datamover/M_AXIS_MM2S_STS] [get_bd_intf_pins ht_readConverter/dmRdStatus_V_V]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXIS_S2MM_STS [get_bd_intf_pins ht_axi_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins ht_writeConverter/dmWrStatus_V_V]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_MM2S [get_bd_intf_ports MCD_AXI2DRAM_RD_C0] [get_bd_intf_pins ht_axi_datamover/M_AXI_MM2S]
  connect_bd_intf_net -intf_net ht_axi_datamover_M_AXI_S2MM [get_bd_intf_ports MCD_AXI2DRAM_WR_C0] [get_bd_intf_pins ht_axi_datamover/M_AXI_S2MM]
  connect_bd_intf_net -intf_net ht_rd_axis_clock_converter_M_AXIS [get_bd_intf_pins ht_rd_axis_clock_converter/M_AXIS] [get_bd_intf_pins ht_readConverter/dmRdData_V]
  connect_bd_intf_net -intf_net ht_readConverter_dmRdCmd_V [get_bd_intf_pins ht_axi_datamover/S_AXIS_MM2S_CMD] [get_bd_intf_pins ht_readConverter/dmRdCmd_V]
  connect_bd_intf_net -intf_net ht_wr_axis_clock_converter_M_AXIS [get_bd_intf_pins ht_axi_datamover/S_AXIS_S2MM] [get_bd_intf_pins ht_wr_axis_clock_converter/M_AXIS]
  connect_bd_intf_net -intf_net ht_writeConverter_dmWrCmd_V [get_bd_intf_pins ht_axi_datamover/S_AXIS_S2MM_CMD] [get_bd_intf_pins ht_writeConverter/dmWrCmd_V]
  connect_bd_intf_net -intf_net ht_writeConverter_dmWrData_V [get_bd_intf_pins ht_wr_axis_clock_converter/S_AXIS] [get_bd_intf_pins ht_writeConverter/dmWrData_V]
  connect_bd_intf_net -intf_net inData_0_1 [get_bd_intf_ports fromNet] [get_bd_intf_pins memcachedPipeline_0/inData]
  connect_bd_intf_net -intf_net memcachedPipeline_0_addressReturnOut_V_V [get_bd_intf_ports mcd2alloc_V_V_0] [get_bd_intf_pins memcachedPipeline_0/addressReturnOut_V_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_dramValueStoreMemRdCmd_V [get_bd_intf_pins memcachedPipeline_0/dramValueStoreMemRdCmd_V] [get_bd_intf_pins vs_readConverter/memRdCmd_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_dramValueStoreMemWrCmd_V [get_bd_intf_pins memcachedPipeline_0/dramValueStoreMemWrCmd_V] [get_bd_intf_pins vs_writeConverter/memWrCmd_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_dramValueStoreMemWrData_V_V [get_bd_intf_pins memcachedPipeline_0/dramValueStoreMemWrData_V_V] [get_bd_intf_pins vs_writeConverter/memWrData_V_V]
  #connect_bd_intf_net -intf_net memcachedPipeline_0_flashValueStoreMemRdCmd_V [get_bd_intf_pins flashModel_0/rdCmdIn_V] [get_bd_intf_pins memcachedPipeline_0/flashValueStoreMemRdCmd_V]
  #connect_bd_intf_net -intf_net memcachedPipeline_0_flashValueStoreMemWrCmd_V [get_bd_intf_pins flashModel_0/wrCmdIn_V] [get_bd_intf_pins memcachedPipeline_0/flashValueStoreMemWrCmd_V]
  #connect_bd_intf_net -intf_net memcachedPipeline_0_flashValueStoreMemWrData_V_V [get_bd_intf_pins flashModel_0/wrDataIn_V_V] [get_bd_intf_pins memcachedPipeline_0/flashValueStoreMemWrData_V_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_hashTableMemRdCmd_V [get_bd_intf_pins ht_readConverter/memRdCmd_V] [get_bd_intf_pins memcachedPipeline_0/hashTableMemRdCmd_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_hashTableMemWrCmd_V [get_bd_intf_pins ht_writeConverter/memWrCmd_V] [get_bd_intf_pins memcachedPipeline_0/hashTableMemWrCmd_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_hashTableMemWrData_V_V [get_bd_intf_pins ht_writeConverter/memWrData_V_V] [get_bd_intf_pins memcachedPipeline_0/hashTableMemWrData_V_V]
  connect_bd_intf_net -intf_net memcachedPipeline_0_outData [get_bd_intf_ports toNet] [get_bd_intf_pins memcachedPipeline_0/outData]
  connect_bd_intf_net -intf_net readConverter_0_memRdData_V_V [get_bd_intf_pins ht_readConverter/memRdData_V_V] [get_bd_intf_pins memcachedPipeline_0/hashTableMemRdData_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXIS_MM2S [get_bd_intf_pins vs_axi_datamover/M_AXIS_MM2S] [get_bd_intf_pins vs_rd_axis_clock_converter/S_AXIS]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXIS_MM2S_STS [get_bd_intf_pins vs_axi_datamover/M_AXIS_MM2S_STS] [get_bd_intf_pins vs_readConverter/dmRdStatus_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXIS_S2MM_STS [get_bd_intf_pins vs_axi_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins vs_writeConverter/dmWrStatus_V_V]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_MM2S [get_bd_intf_ports MCD_AXI2DRAM_RD_C1] [get_bd_intf_pins vs_axi_datamover/M_AXI_MM2S]
  connect_bd_intf_net -intf_net vs_axi_datamover_M_AXI_S2MM [get_bd_intf_ports MCD_AXI2DRAM_WR_C1] [get_bd_intf_pins vs_axi_datamover/M_AXI_S2MM]
  connect_bd_intf_net -intf_net vs_rd_axis_clock_converter_M_AXIS [get_bd_intf_pins vs_rd_axis_clock_converter/M_AXIS] [get_bd_intf_pins vs_readConverter/dmRdData_V]
  connect_bd_intf_net -intf_net vs_readConverter_dmRdCmd_V [get_bd_intf_pins vs_axi_datamover/S_AXIS_MM2S_CMD] [get_bd_intf_pins vs_readConverter/dmRdCmd_V]
  connect_bd_intf_net -intf_net vs_readConverter_memRdData_V_V [get_bd_intf_pins memcachedPipeline_0/dramValueStoreMemRdData_V_V] [get_bd_intf_pins vs_readConverter/memRdData_V_V]
  connect_bd_intf_net -intf_net vs_wr_axis_clock_converter_M_AXIS [get_bd_intf_pins vs_axi_datamover/S_AXIS_S2MM] [get_bd_intf_pins vs_wr_axis_clock_converter/M_AXIS]
  connect_bd_intf_net -intf_net vs_writeConverter_dmWrCmd_V [get_bd_intf_pins vs_axi_datamover/S_AXIS_S2MM_CMD] [get_bd_intf_pins vs_writeConverter/dmWrCmd_V]
  connect_bd_intf_net -intf_net vs_writeConverter_dmWrData_V [get_bd_intf_pins vs_wr_axis_clock_converter/S_AXIS] [get_bd_intf_pins vs_writeConverter/dmWrData_V]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports aclk] [get_bd_pins ht_axi_datamover/m_axis_mm2s_cmdsts_aclk] [get_bd_pins ht_axi_datamover/m_axis_s2mm_cmdsts_awclk] [get_bd_pins ht_rd_axis_clock_converter/m_axis_aclk] [get_bd_pins ht_readConverter/aclk] [get_bd_pins ht_wr_axis_clock_converter/s_axis_aclk] [get_bd_pins ht_writeConverter/aclk] [get_bd_pins memcachedPipeline_0/ap_clk] [get_bd_pins vs_axi_datamover/m_axis_mm2s_cmdsts_aclk] [get_bd_pins vs_axi_datamover/m_axis_s2mm_cmdsts_awclk] [get_bd_pins vs_rd_axis_clock_converter/m_axis_aclk] [get_bd_pins vs_readConverter/aclk] [get_bd_pins vs_wr_axis_clock_converter/s_axis_aclk] [get_bd_pins vs_writeConverter/aclk]
  connect_bd_net -net Net1 [get_bd_ports aresetn] [get_bd_pins ht_axi_datamover/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins ht_axi_datamover/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins ht_rd_axis_clock_converter/m_axis_aresetn] [get_bd_pins ht_readConverter/aresetn] [get_bd_pins ht_wr_axis_clock_converter/s_axis_aresetn] [get_bd_pins ht_writeConverter/aresetn] [get_bd_pins memcachedPipeline_0/ap_rst_n] [get_bd_pins vs_axi_datamover/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins vs_axi_datamover/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins vs_rd_axis_clock_converter/m_axis_aresetn] [get_bd_pins vs_readConverter/aresetn] [get_bd_pins vs_wr_axis_clock_converter/s_axis_aresetn] [get_bd_pins vs_writeConverter/aresetn]
  connect_bd_net -net Net2 [get_bd_ports mem_c0_clk] [get_bd_pins ht_axi_datamover/m_axi_mm2s_aclk] [get_bd_pins ht_axi_datamover/m_axi_s2mm_aclk] [get_bd_pins ht_rd_axis_clock_converter/s_axis_aclk] [get_bd_pins ht_wr_axis_clock_converter/m_axis_aclk]
  connect_bd_net -net Net4 [get_bd_ports mem_c0_resetn] [get_bd_pins ht_axi_datamover/m_axi_mm2s_aresetn] [get_bd_pins ht_axi_datamover/m_axi_s2mm_aresetn] [get_bd_pins ht_rd_axis_clock_converter/s_axis_aresetn] [get_bd_pins ht_wr_axis_clock_converter/m_axis_aresetn]
  connect_bd_net -net Net6 [get_bd_ports mem_c1_clk] [get_bd_pins vs_axi_datamover/m_axi_mm2s_aclk] [get_bd_pins vs_axi_datamover/m_axi_s2mm_aclk] [get_bd_pins vs_rd_axis_clock_converter/s_axis_aclk] [get_bd_pins vs_wr_axis_clock_converter/m_axis_aclk]
  connect_bd_net -net Net8 [get_bd_ports mem_c1_resetn] [get_bd_pins vs_axi_datamover/m_axi_mm2s_aresetn] [get_bd_pins vs_axi_datamover/m_axi_s2mm_aresetn] [get_bd_pins vs_rd_axis_clock_converter/s_axis_aresetn] [get_bd_pins vs_wr_axis_clock_converter/m_axis_aresetn]
  connect_bd_net -net flushAck_V_0_1 [get_bd_ports flushAck_V_0] [get_bd_pins memcachedPipeline_0/flushAck_V]
  connect_bd_net -net memcachedPipeline_0_flushDone_V [get_bd_ports flushDone_V_0] [get_bd_pins memcachedPipeline_0/flushDone_V]
  connect_bd_net -net memcachedPipeline_0_flushReq_V [get_bd_ports flushReq_V_0] [get_bd_pins memcachedPipeline_0/flushReq_V]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

#################################################################
# add  synth and impl here
##################################################################

make_wrapper -files [get_files ${origin_dir}/generated_vivado_project/memcached_pipeline.srcs/sources_1/bd/memcached_pipeline/memcached_pipeline.bd] -top
add_files -norecurse ${origin_dir}/generated_vivado_project/memcached_pipeline.srcs/sources_1/bd/memcached_pipeline/hdl/memcached_pipeline_wrapper.v

##################################################################
# package and export  the design as IP 
##################################################################
ipx::package_project -root_dir ${origin_dir}/../../../generated_ip/app_memcached_vcu108 -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force

update_ip_catalog -rebuild

puts "INFO: Project created:${_xil_proj_name_}"

exit

# Proc to create BD sys_mm
proc cr_bd_sys_mm { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name sys_mm

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  wuklab:user:axi_mmu_wrapper_sync:1.0\
  wuklab:hls:mm_segfix_hls:1.0\
  xilinx.com:ip:xlconstant:1.1\
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
  set ctl_out_V_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ctl_out_V_0 ]
  set ctrl_V_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ctrl_V_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_opcode {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value opcode} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_rw {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value rw} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_pid {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value pid} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 8} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 2} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_idx {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value idx} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 4} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 10} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}}}}} \
   CONFIG.TDATA_NUM_BYTES {2} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $ctrl_V_0
  set ctrl_stat_V_V_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ctrl_stat_V_V_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $ctrl_stat_V_V_0
  set m_axi_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.CLK_DOMAIN {sys_mm_s_axi_clk_0} \
   CONFIG.DATA_WIDTH {512} \
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
   CONFIG.CLK_DOMAIN {sys_mm_s_axi_clk_0} \
   CONFIG.DATA_WIDTH {512} \
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
   CONFIG.ID_WIDTH {11} \
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

  # Create ports
  set s_aresetn_0 [ create_bd_port -dir I -type rst s_aresetn_0 ]
  set s_axi_clk_0 [ create_bd_port -dir I -type clk s_axi_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {s_axi_0:m_axi_0:ctrl_V_0:ctrl_stat_V_V_0} \
   CONFIG.FREQ_HZ {300000000} \
 ] $s_axi_clk_0

  # Create instance: axi_mmu_wrapper_sync_0, and set properties
  set axi_mmu_wrapper_sync_0 [ create_bd_cell -type ip -vlnv wuklab:user:axi_mmu_wrapper_sync:1.0 axi_mmu_wrapper_sync_0 ]
  set_property -dict [ list \
   CONFIG.AR_BUF_SZ {16} \
   CONFIG.AW_BUF_SZ {16} \
   CONFIG.AXI_ARUSER_WIDTH {1} \
   CONFIG.AXI_AWUSER_WIDTH {1} \
   CONFIG.AXI_BUSER_WIDTH {1} \
   CONFIG.AXI_DATA_WIDTH {512} \
   CONFIG.AXI_ID_WIDTH {11} \
   CONFIG.AXI_RUSER_WIDTH {1} \
   CONFIG.AXI_STRB_WIDTH {16} \
   CONFIG.AXI_WUSER_WIDTH {1} \
 ] $axi_mmu_wrapper_sync_0

  # Create instance: mm_segfix_hls_0, and set properties
  set mm_segfix_hls_0 [ create_bd_cell -type ip -vlnv wuklab:hls:mm_segfix_hls:1.0 mm_segfix_hls_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_mmu_wrapper_sync_0_m_axi [get_bd_intf_ports m_axi_0] [get_bd_intf_pins axi_mmu_wrapper_sync_0/m_axi]
  connect_bd_intf_net -intf_net axi_mmu_wrapper_sync_0_toMM_RD [get_bd_intf_pins axi_mmu_wrapper_sync_0/toMM_RD] [get_bd_intf_pins mm_segfix_hls_0/rd_in_V]
  connect_bd_intf_net -intf_net axi_mmu_wrapper_sync_0_toMM_WR [get_bd_intf_pins axi_mmu_wrapper_sync_0/toMM_WR] [get_bd_intf_pins mm_segfix_hls_0/wr_in_V]
  connect_bd_intf_net -intf_net ctrl_V_0_1 [get_bd_intf_ports ctrl_V_0] [get_bd_intf_pins mm_segfix_hls_0/ctl_in_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_ctl_out_V [get_bd_intf_ports ctl_out_V_0] [get_bd_intf_pins mm_segfix_hls_0/ctl_out_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_rd_out_V [get_bd_intf_pins axi_mmu_wrapper_sync_0/fromMM_RD] [get_bd_intf_pins mm_segfix_hls_0/rd_out_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_wr_out_V [get_bd_intf_pins axi_mmu_wrapper_sync_0/fromMM_WR] [get_bd_intf_pins mm_segfix_hls_0/wr_out_V]
  connect_bd_intf_net -intf_net s_axi_0_1 [get_bd_intf_ports s_axi_0] [get_bd_intf_pins axi_mmu_wrapper_sync_0/s_axi]

  # Create port connections
  connect_bd_net -net s_aresetn_0_1 [get_bd_ports s_aresetn_0] [get_bd_pins axi_mmu_wrapper_sync_0/s_aresetn] [get_bd_pins mm_segfix_hls_0/ap_rst_n]
  connect_bd_net -net s_axi_clk_0_1 [get_bd_ports s_axi_clk_0] [get_bd_pins axi_mmu_wrapper_sync_0/s_axi_clk] [get_bd_pins mm_segfix_hls_0/ap_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins mm_segfix_hls_0/ap_start] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_mmu_wrapper_sync_0/m_axi] [get_bd_addr_segs m_axi_0/Reg] SEG_m_axi_0_Reg

  # Exclude Address Segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs axi_mmu_wrapper_sync_0/s_axi/reg0] SEG_axi_mmu_wrapper_sync_0_reg0
  exclude_bd_addr_seg [get_bd_addr_segs s_axi_0/SEG_axi_mmu_wrapper_sync_0_reg0]


  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 6.8.11  2018-08-07 bk=1.4403 VDI=40 GEI=35 GUI=JA:9.0 TLS
#  -string -flagsOSRD
preplace port s_axi_0 -pg 1 -y 120 -defaultsOSRD
preplace port ctrl_V_0 -pg 1 -y 320 -defaultsOSRD
preplace port ctrl_stat_V_V_0 -pg 1 -y 20 -defaultsOSRD
preplace port ctl_out_V_0 -pg 1 -y 280 -defaultsOSRD
preplace port s_aresetn_0 -pg 1 -y 160 -defaultsOSRD
preplace port s_axi_clk_0 -pg 1 -y 140 -defaultsOSRD
preplace port m_axi_0 -pg 1 -y 140 -defaultsOSRD
preplace inst xlconstant_0 -pg 1 -lvl 1 -y 260 -defaultsOSRD
preplace inst mm_segfix_hls_0 -pg 1 -lvl 2 -y 300 -defaultsOSRD
preplace inst axi_mmu_wrapper_sync_0 -pg 1 -lvl 1 -y 120 -defaultsOSRD
preplace netloc mm_segfix_hls_0_wr_out_V 1 0 3 30 20 NJ 20 600
preplace netloc mm_segfix_hls_0_rd_out_V 1 0 3 20 10 NJ 10 610
preplace netloc mm_segfix_hls_0_ctl_out_V 1 2 1 NJ
preplace netloc axi_mmu_wrapper_sync_0_toMM_RD 1 1 1 300
preplace netloc s_aresetn_0_1 1 0 2 20 360 NJ
preplace netloc axi_mmu_wrapper_sync_0_toMM_WR 1 1 1 290
preplace netloc s_axi_clk_0_1 1 0 2 30 340 NJ
preplace netloc xlconstant_0_dout 1 1 1 NJ
preplace netloc ctrl_V_0_1 1 0 2 NJ 320 NJ
preplace netloc axi_mmu_wrapper_sync_0_m_axi 1 1 2 NJ 140 NJ
preplace netloc s_axi_0_1 1 0 1 NJ
levelinfo -pg 1 0 160 450 630 -top 0 -bot 420
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
common::send_msg_id "BD_TCL-1000" "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

  close_bd_design $design_name 
}
# End of cr_bd_sys_mm()
cr_bd_sys_mm ""
set_property REGISTERED_WITH_MANAGER "1" [get_files sys_mm.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files sys_mm.bd ] 

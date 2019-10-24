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
  wuklab:user:axi_rab_bd:1.0\
  wuklab:hls:mm_segfix_hls:1.0\
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
  set sysmm_axi_in [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 sysmm_axi_in ]
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
   ] $sysmm_axi_in
  set sysmm_axi_out [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 sysmm_axi_out ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $sysmm_axi_out
  set sysmm_ctl_in [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 sysmm_ctl_in ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_opcode {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value opcode} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 8} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_addr_len {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value addr_len} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 32} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 8} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}}}}} \
   CONFIG.TDATA_NUM_BYTES {5} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $sysmm_ctl_in
  set sysmm_ctl_out [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 sysmm_ctl_out ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $sysmm_ctl_out

  # Create ports
  set sysmm_clk [ create_bd_port -dir I -type clk sysmm_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {sysmm_ctl_in:sysmm_axi_out:sysmm_axi_in:sysmm_ctl_out} \
   CONFIG.ASSOCIATED_RESET {sysmm_rst_n} \
   CONFIG.FREQ_HZ {300000000} \
 ] $sysmm_clk
  set sysmm_rst_n [ create_bd_port -dir I -type rst sysmm_rst_n ]

  # Create instance: axi_rab_bd_0, and set properties
  set axi_rab_bd_0 [ create_bd_cell -type ip -vlnv wuklab:user:axi_rab_bd:1.0 axi_rab_bd_0 ]

  # Create instance: mm_segfix_hls_0, and set properties
  set mm_segfix_hls_0 [ create_bd_cell -type ip -vlnv wuklab:hls:mm_segfix_hls:1.0 mm_segfix_hls_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_rab_bd_0_m_axi_0 [get_bd_intf_ports sysmm_axi_out] [get_bd_intf_pins axi_rab_bd_0/m_axi_0]
  connect_bd_intf_net -intf_net axi_rab_bd_0_toMM_RD_0 [get_bd_intf_pins axi_rab_bd_0/toMM_RD_0] [get_bd_intf_pins mm_segfix_hls_0/rd_in_V]
  connect_bd_intf_net -intf_net axi_rab_bd_0_toMM_WR_0 [get_bd_intf_pins axi_rab_bd_0/toMM_WR_0] [get_bd_intf_pins mm_segfix_hls_0/wr_in_V]
  connect_bd_intf_net -intf_net ctl_in_V_0_1 [get_bd_intf_ports sysmm_ctl_in] [get_bd_intf_pins mm_segfix_hls_0/ctl_in_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_ctl_out_V [get_bd_intf_ports sysmm_ctl_out] [get_bd_intf_pins mm_segfix_hls_0/ctl_out_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_rd_out_V [get_bd_intf_pins axi_rab_bd_0/fromMM_RD_0] [get_bd_intf_pins mm_segfix_hls_0/rd_out_V]
  connect_bd_intf_net -intf_net mm_segfix_hls_0_wr_out_V [get_bd_intf_pins axi_rab_bd_0/fromMM_WR_0] [get_bd_intf_pins mm_segfix_hls_0/wr_out_V]
  connect_bd_intf_net -intf_net s_axi_0_0_1 [get_bd_intf_ports sysmm_axi_in] [get_bd_intf_pins axi_rab_bd_0/s_axi_0]

  # Create port connections
  connect_bd_net -net s_aresetn_0_0_1 [get_bd_ports sysmm_rst_n] [get_bd_pins axi_rab_bd_0/s_aresetn_0] [get_bd_pins mm_segfix_hls_0/ap_rst_n]
  connect_bd_net -net s_axi_clk_0_0_1 [get_bd_ports sysmm_clk] [get_bd_pins axi_rab_bd_0/s_axi_clk_0] [get_bd_pins mm_segfix_hls_0/ap_clk]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_rab_bd_0/m_axi_0] [get_bd_addr_segs sysmm_axi_out/Reg] SEG_m_axi_0_0_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces sysmm_axi_in] [get_bd_addr_segs axi_rab_bd_0/s_axi_0/Reg0] SEG_axi_rab_bd_0_Reg0

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 6.8.11  2018-08-07 bk=1.4403 VDI=40 GEI=35 GUI=JA:9.0 TLS
#  -string -flagsOSRD
preplace port sysmm_clk -pg 1 -y 130 -defaultsOSRD
preplace port sysmm_axi_out -pg 1 -y 290 -defaultsOSRD
preplace port sysmm_ctl_out -pg 1 -y 90 -defaultsOSRD
preplace port sysmm_rst_n -pg 1 -y 150 -defaultsOSRD
preplace port sysmm_axi_in -pg 1 -y 310 -defaultsOSRD
preplace port sysmm_ctl_in -pg 1 -y 70 -defaultsOSRD
preplace inst mm_segfix_hls_0 -pg 1 -lvl 1 -y 110 -defaultsOSRD
preplace inst axi_rab_bd_0 -pg 1 -lvl 2 -y 310 -defaultsOSRD
preplace netloc mm_segfix_hls_0_wr_out_V 1 1 1 340
preplace netloc s_axi_0_0_1 1 0 2 NJ 310 NJ
preplace netloc axi_rab_bd_0_m_axi_0 1 2 1 NJ
preplace netloc axi_rab_bd_0_toMM_RD_0 1 0 3 40 210 NJ 210 650
preplace netloc mm_segfix_hls_0_rd_out_V 1 1 1 350
preplace netloc mm_segfix_hls_0_ctl_out_V 1 1 2 NJ 90 NJ
preplace netloc ctl_in_V_0_1 1 0 1 NJ
preplace netloc axi_rab_bd_0_toMM_WR_0 1 0 3 30 10 NJ 10 660
preplace netloc s_axi_clk_0_0_1 1 0 2 30 350 NJ
preplace netloc s_aresetn_0_0_1 1 0 2 20 330 NJ
levelinfo -pg 1 0 190 500 680 -top 0 -bot 410
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_sys_mm()
cr_bd_sys_mm ""
set_property REGISTERED_WITH_MANAGER "1" [get_files sys_mm.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files sys_mm.bd ] 

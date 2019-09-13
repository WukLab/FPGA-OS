proc cr_bd_LegoFPGA_RDM_KVS_for_pcie_raw { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name LegoFPGA_RDM_KVS_for_pcie_raw

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\
  wuklab:user:memcached_top_for_buddy:1.0\
  xilinx.com:ip:axis_data_fifo:1.1\
  Wuklab.UCSD:hls:buddy_allocator:1.0\
  wuklab:hls:sysnet_rx_256:1.0\
  xilinx.com:ip:ddr4:2.2\
  xilinx.com:ip:util_vector_logic:2.0\
  wuklab:user:mapping_ip_top:1.0\
  wuklab:hls:rdm_mapping:1.0\
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


# Hierarchical cell: RDM
proc create_hier_cell_RDM { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_RDM() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 alloc_req_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 alloc_ret_V
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 from_net
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_hashtable
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_rdm
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 to_net

  # Create pins
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst mc_ddr4_ui_clk_rst_n

  # Create instance: HashTable, and set properties
  set HashTable [ create_bd_cell -type ip -vlnv wuklab:user:mapping_ip_top:1.0 HashTable ]

  # Create instance: RDM_Mapping, and set properties
  set RDM_Mapping [ create_bd_cell -type ip -vlnv wuklab:hls:rdm_mapping:1.0 RDM_Mapping ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net CDC_RX_BUF_M00_AXIS [get_bd_intf_pins from_net] [get_bd_intf_pins RDM_Mapping/from_net]
  connect_bd_intf_net -intf_net RDM_Mapping_alloc_req_V [get_bd_intf_pins alloc_req_V] [get_bd_intf_pins RDM_Mapping/alloc_req_V]
  #connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins m_axi_rdm] [get_bd_intf_pins RDM_Mapping/m_axi_dram_V]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins m_axi_hashtable] [get_bd_intf_pins HashTable/M00_AXI_0]
  connect_bd_intf_net -intf_net buddy_allocator_0_alloc_ret_V [get_bd_intf_pins alloc_ret_V] [get_bd_intf_pins RDM_Mapping/alloc_ret_V]
  connect_bd_intf_net -intf_net mapping_ip_top_0_out_read_0 [get_bd_intf_pins HashTable/out_read_0] [get_bd_intf_pins RDM_Mapping/map_ret_V]
  connect_bd_intf_net -intf_net rdm_mapping_0_map_req_V [get_bd_intf_pins HashTable/in_read_0] [get_bd_intf_pins RDM_Mapping/map_req_V]
  connect_bd_intf_net -intf_net rdm_mapping_0_to_net [get_bd_intf_pins to_net] [get_bd_intf_pins RDM_Mapping/to_net]

  # Create port connections
  connect_bd_net -net MC_c0_ddr4_ui_clk [get_bd_pins ap_clk] [get_bd_pins HashTable/ap_clk] [get_bd_pins RDM_Mapping/ap_clk]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins HashTable/ap_rstn] [get_bd_pins RDM_Mapping/ap_rst_n]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins HashTable/in_write_0_tvalid] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: MC
proc create_hier_cell_MC { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_MC() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1

  # Create pins
  create_bd_pin -dir O -type clk c0_ddr4_ui_clk
  create_bd_pin -dir O -from 0 -to 0 -type rst c0_ddr4_ui_clk_rstn
  create_bd_pin -dir O c0_init_calib_complete_0
  create_bd_pin -dir I -type rst sys_rst

  # Create instance: mc_ddr4_core, and set properties
  set mc_ddr4_core [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 mc_ddr4_core ]
  set_property -dict [ list \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_250mhz_clk1} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1} \
   CONFIG.System_Clock {Differential} \
 ] $mc_ddr4_core

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_0_1 [get_bd_intf_pins C0_SYS_CLK_0] [get_bd_intf_pins mc_ddr4_core/C0_SYS_CLK]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins C0_DDR4_S_AXI] [get_bd_intf_pins mc_ddr4_core/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_pins ddr4_sdram_c1] [get_bd_intf_pins mc_ddr4_core/C0_DDR4]

  # Create port connections
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins c0_ddr4_ui_clk_rstn] [get_bd_pins mc_ddr4_core/c0_ddr4_aresetn] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net c0_ddr4_ui_clk_rstn_1 [get_bd_pins mc_ddr4_core/c0_ddr4_ui_clk_sync_rst] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net mc_ddr4_0_c0_ddr4_ui_clk [get_bd_pins c0_ddr4_ui_clk] [get_bd_pins mc_ddr4_core/c0_ddr4_ui_clk]
  connect_bd_net -net mc_ddr4_core_c0_init_calib_complete [get_bd_pins c0_init_calib_complete_0] [get_bd_pins mc_ddr4_core/c0_init_calib_complete]
  connect_bd_net -net sys_rst_0_1 [get_bd_pins sys_rst] [get_bd_pins mc_ddr4_core/sys_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CRC_RX
proc create_hier_cell_CRC_RX { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_CRC_RX() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 RX

  # Create pins
  create_bd_pin -dir I -type clk M00_AXIS_ACLK
  create_bd_pin -dir I -type clk RX_clk
  create_bd_pin -dir I -type rst RX_rst_n
  create_bd_pin -dir I -type rst mc_ddr4_ui_clk_rst_n

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32768} \
   CONFIG.FIFO_MODE {1} \
 ] $axis_data_fifo_0

  # Create instance: axis_interconnect_0, and set properties
  set axis_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {4096} \
   CONFIG.M00_FIFO_MODE {1} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_FIFO_DEPTH {4096} \
   CONFIG.S00_FIFO_MODE {1} \
   CONFIG.S00_HAS_REGSLICE {1} \
 ] $axis_interconnect_0

  # Create interface connections
  connect_bd_intf_net -intf_net CDC_RX_BUF_M00_AXIS [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_interconnect_0/M00_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axis_interconnect_0/S00_AXIS]
  connect_bd_intf_net -intf_net from_net_1 [get_bd_intf_pins RX] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]

  # Create port connections
  connect_bd_net -net MC_c0_ddr4_ui_clk [get_bd_pins M00_AXIS_ACLK] [get_bd_pins axis_interconnect_0/ACLK] [get_bd_pins axis_interconnect_0/M00_AXIS_ACLK]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_pins RX_clk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_interconnect_0/S00_AXIS_ACLK]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_pins RX_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_interconnect_0/S00_AXIS_ARESETN]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins axis_interconnect_0/ARESETN] [get_bd_pins axis_interconnect_0/M00_AXIS_ARESETN]

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
  set C0_SYS_CLK_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $C0_SYS_CLK_0
  set RX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 RX ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {64} \
   ] $RX
  set TX [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 TX ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $TX
  set ddr4_sdram_c1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1 ]

  # Create ports
  set RX_clk [ create_bd_port -dir I -type clk RX_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {RX} \
   CONFIG.ASSOCIATED_RESET {RX_rst_n} \
   CONFIG.FREQ_HZ {250000000} \
 ] $RX_clk
  set RX_rst_n [ create_bd_port -dir I -type rst RX_rst_n ]
  set TX_clk [ create_bd_port -dir I -type clk TX_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {TX} \
   CONFIG.ASSOCIATED_RESET {TX_rst_n} \
   CONFIG.FREQ_HZ {250000000} \
 ] $TX_clk
  set TX_rst_n [ create_bd_port -dir I -type rst TX_rst_n ]
  set clk_150 [ create_bd_port -dir I -type clk clk_150 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {150000000} \
 ] $clk_150
  set clk_150_rst_n [ create_bd_port -dir I -type rst clk_150_rst_n ]
  set driver_ready [ create_bd_port -dir I -from 0 -to 0 -type data driver_ready ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}} \
 ] $driver_ready
  set mc_ddr4_ui_clk_rst_n [ create_bd_port -dir O -from 0 -to 0 mc_ddr4_ui_clk_rst_n ]
  set mc_init_calib_complete [ create_bd_port -dir O mc_init_calib_complete ]
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst

  # Create instance: CRC_RX
  create_hier_cell_CRC_RX [current_bd_instance .] CRC_RX

  # Create instance: KVS, and set properties
  set KVS [ create_bd_cell -type ip -vlnv wuklab:user:memcached_top_for_buddy:1.0 KVS ]

  # Create instance: MC
  create_hier_cell_MC [current_bd_instance .] MC

  # Create instance: RDM
  create_hier_cell_RDM [current_bd_instance .] RDM

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {7} \
   CONFIG.S00_ARB_PRIORITY {15} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S01_ARB_PRIORITY {14} \
   CONFIG.S01_HAS_DATA_FIFO {2} \
   CONFIG.S02_HAS_DATA_FIFO {2} \
   CONFIG.S03_HAS_DATA_FIFO {2} \
   CONFIG.S04_HAS_DATA_FIFO {2} \
   CONFIG.S05_HAS_DATA_FIFO {2} \
   CONFIG.S06_HAS_DATA_FIFO {2} \
   CONFIG.STRATEGY {2} \
 ] $axi_interconnect_0

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32768} \
   CONFIG.IS_ACLK_ASYNC {0} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
   CONFIG.TDATA_NUM_BYTES {32} \
 ] $axis_data_fifo_1

  # Create instance: axis_interconnect_1, and set properties
  set axis_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {512} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_FIFO_DEPTH {512} \
   CONFIG.S00_HAS_REGSLICE {1} \
 ] $axis_interconnect_1

  # Create instance: buddy_allocator_0, and set properties
  set buddy_allocator_0 [ create_bd_cell -type ip -vlnv purdue.wuklab:hls:buddy_allocator:1.0 buddy_allocator_0 ]

  # Create instance: sysnet_rx_256, and set properties
  set sysnet_rx_256 [ create_bd_cell -type ip -vlnv wuklab:hls:sysnet_rx_256:1.0 sysnet_rx_256 ]

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_0_1 [get_bd_intf_ports C0_SYS_CLK_0] [get_bd_intf_pins MC/C0_SYS_CLK_0]
  connect_bd_intf_net -intf_net CRC_RX_M00_AXIS [get_bd_intf_pins CRC_RX/M00_AXIS] [get_bd_intf_pins sysnet_rx_256/input_r]
  connect_bd_intf_net -intf_net KVS_toNet [get_bd_intf_pins KVS/toNet] [get_bd_intf_pins axis_interconnect_1/S01_AXIS]
  connect_bd_intf_net -intf_net RDM_Mapping_alloc_req_V [get_bd_intf_pins RDM/alloc_req_V] [get_bd_intf_pins buddy_allocator_0/alloc_V]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins RDM/m_axi_hashtable] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins MC/C0_DDR4_S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_rdm [get_bd_intf_pins RDM/m_axi_rdm] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_ports TX] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_interconnect_1_M00_AXIS [get_bd_intf_pins axis_data_fifo_1/S_AXIS] [get_bd_intf_pins axis_interconnect_1/M00_AXIS]
  connect_bd_intf_net -intf_net buddy_allocator_0_alloc_ret_V [get_bd_intf_pins RDM/alloc_ret_V] [get_bd_intf_pins buddy_allocator_0/alloc_ret_V]
  connect_bd_intf_net -intf_net buddy_allocator_0_m_axi_dram [get_bd_intf_pins axi_interconnect_0/S02_AXI] [get_bd_intf_pins buddy_allocator_0/m_axi_dram]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins MC/ddr4_sdram_c1]
  connect_bd_intf_net -intf_net from_net_1 [get_bd_intf_ports RX] [get_bd_intf_pins CRC_RX/RX]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_RD_C0 [get_bd_intf_pins KVS/MCD_AXI2DRAM_RD_C0] [get_bd_intf_pins axi_interconnect_0/S03_AXI]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_RD_C1 [get_bd_intf_pins KVS/MCD_AXI2DRAM_RD_C1] [get_bd_intf_pins axi_interconnect_0/S04_AXI]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_WR_C0 [get_bd_intf_pins KVS/MCD_AXI2DRAM_WR_C0] [get_bd_intf_pins axi_interconnect_0/S05_AXI]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_WR_C1 [get_bd_intf_pins KVS/MCD_AXI2DRAM_WR_C1] [get_bd_intf_pins axi_interconnect_0/S06_AXI]
  connect_bd_intf_net -intf_net rdm_mapping_0_to_net [get_bd_intf_pins RDM/to_net] [get_bd_intf_pins axis_interconnect_1/S00_AXIS]
  connect_bd_intf_net -intf_net sysnet_rx_256_0_output_0 [get_bd_intf_pins RDM/from_net] [get_bd_intf_pins sysnet_rx_256/output_0]
  connect_bd_intf_net -intf_net sysnet_rx_256_0_output_1 [get_bd_intf_pins KVS/fromNet] [get_bd_intf_pins sysnet_rx_256/output_1]

  # Create port connections
  connect_bd_net -net MC_c0_ddr4_ui_clk [get_bd_pins CRC_RX/M00_AXIS_ACLK] [get_bd_pins KVS/mem_c0_clk] [get_bd_pins MC/c0_ddr4_ui_clk] [get_bd_pins RDM/ap_clk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK] [get_bd_pins axi_interconnect_0/S03_ACLK] [get_bd_pins axi_interconnect_0/S04_ACLK] [get_bd_pins axi_interconnect_0/S05_ACLK] [get_bd_pins axi_interconnect_0/S06_ACLK] [get_bd_pins axis_interconnect_1/ACLK] [get_bd_pins axis_interconnect_1/S00_AXIS_ACLK] [get_bd_pins buddy_allocator_0/ap_clk]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_ports RX_clk] [get_bd_pins CRC_RX/RX_clk]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_ports RX_rst_n] [get_bd_pins CRC_RX/RX_rst_n]
  connect_bd_net -net S01_AXIS_ACLK_1 [get_bd_ports clk_150] [get_bd_pins KVS/aclk] [get_bd_pins axis_interconnect_1/S01_AXIS_ACLK]
  connect_bd_net -net S01_AXIS_ARESETN_1 [get_bd_ports clk_150_rst_n] [get_bd_pins KVS/aresetn] [get_bd_pins axis_interconnect_1/S01_AXIS_ARESETN]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_ports mc_ddr4_ui_clk_rst_n] [get_bd_pins CRC_RX/mc_ddr4_ui_clk_rst_n] [get_bd_pins KVS/mem_c0_resetn] [get_bd_pins MC/c0_ddr4_ui_clk_rstn] [get_bd_pins RDM/mc_ddr4_ui_clk_rst_n] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_0/S02_ARESETN] [get_bd_pins axi_interconnect_0/S03_ARESETN] [get_bd_pins axi_interconnect_0/S04_ARESETN] [get_bd_pins axi_interconnect_0/S05_ARESETN] [get_bd_pins axi_interconnect_0/S06_ARESETN] [get_bd_pins axis_interconnect_1/ARESETN] [get_bd_pins axis_interconnect_1/S00_AXIS_ARESETN] [get_bd_pins buddy_allocator_0/ap_rst_n]
  connect_bd_net -net mac_ready_1 [get_bd_ports driver_ready] [get_bd_pins buddy_allocator_0/ap_start]
  connect_bd_net -net mc_ddr4_wrapper_c0_init_calib_complete_0 [get_bd_ports mc_init_calib_complete] [get_bd_pins MC/c0_init_calib_complete_0]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst] [get_bd_pins MC/sys_rst]
  connect_bd_net -net to_net_clk_390_1 [get_bd_ports TX_clk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins axis_interconnect_1/M00_AXIS_ACLK]
  connect_bd_net -net to_net_clk_390_rst_n_1 [get_bd_ports TX_rst_n] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins axis_interconnect_1/M00_AXIS_ARESETN]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces KVS/MCD_AXI2DRAM_RD_C0] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces KVS/MCD_AXI2DRAM_RD_C1] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces KVS/MCD_AXI2DRAM_WR_C0] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces KVS/MCD_AXI2DRAM_WR_C1] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces buddy_allocator_0/Data_m_axi_dram] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces RDM/HashTable/M00_AXI_0] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  #create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces RDM/RDM_Mapping/Data_m_axi_dram_V] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design

  close_bd_design $design_name
}
# End of cr_bd_LegoFPGA_RDM_KVS_for_pcie_raw()
cr_bd_LegoFPGA_RDM_KVS_for_pcie_raw ""
set_property IS_MANAGED "0" [get_files LegoFPGA_RDM_KVS_for_pcie_raw.bd ]
set_property REGISTERED_WITH_MANAGER "1" [get_files LegoFPGA_RDM_KVS_for_pcie_raw.bd ]
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files LegoFPGA_RDM_KVS_for_pcie_raw.bd ]

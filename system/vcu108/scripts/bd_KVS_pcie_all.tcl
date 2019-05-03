proc cr_bd_LegoFPGA_KVS_for_pcie_all { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name LegoFPGA_KVS_for_pcie_all

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
  purdue.wuklab:hls:buddy_allocator:1.0\
  xilinx.com:ip:xlconstant:1.1\
  xilinx.com:ip:ddr4:2.2\
  xilinx.com:ip:util_vector_logic:2.0\
  xilinx.com:ip:axis_data_fifo:1.1\
  xilinx.com:ip:axis_dwidth_converter:1.1\
  wuklab:hls:libnet_rx_256:1.0\
  purdue.wuklab:hls:chunk_alloc:1.0\
  wuklab:user:sys_mm_wrapper:1.0\
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


# Hierarchical cell: mmu
proc create_hier_cell_mmu { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_mmu() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_0

  # Create pins
  create_bd_pin -dir I mc_ddr4_ui_clk_rst_n
  create_bd_pin -dir I s_axi_clk_0

  # Create instance: chunk_alloc_0, and set properties
  set chunk_alloc_0 [ create_bd_cell -type ip -vlnv purdue.wuklab:hls:chunk_alloc:1.0 chunk_alloc_0 ]

  # Create instance: constant_zero, and set properties
  set constant_zero [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_zero ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $constant_zero

  # Create instance: sys_mm_wrapper_0, and set properties
  set sys_mm_wrapper_0 [ create_bd_cell -type ip -vlnv wuklab:user:sys_mm_wrapper:1.0 sys_mm_wrapper_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins s_axi_0] [get_bd_intf_pins sys_mm_wrapper_0/s_axi_0]
  connect_bd_intf_net -intf_net chunk_alloc_0_ctrl_V [get_bd_intf_pins chunk_alloc_0/ctrl_V] [get_bd_intf_pins sys_mm_wrapper_0/ctrl_V_0]
  connect_bd_intf_net -intf_net sys_mm_wrapper_0_ctrl_stat_V_V_0 [get_bd_intf_pins chunk_alloc_0/ctrl_ret_V_V] [get_bd_intf_pins sys_mm_wrapper_0/ctrl_stat_V_V_0]
  connect_bd_intf_net -intf_net sys_mm_wrapper_0_m_axi_0 [get_bd_intf_pins m_axi_0] [get_bd_intf_pins sys_mm_wrapper_0/m_axi_0]

  # Create port connections
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins chunk_alloc_0/ap_rst_n] [get_bd_pins sys_mm_wrapper_0/s_aresetn_0]
  connect_bd_net -net constant_zero_dout [get_bd_pins chunk_alloc_0/alloc_V_TVALID] [get_bd_pins chunk_alloc_0/alloc_ret_V_TREADY] [get_bd_pins constant_zero/dout]
  connect_bd_net -net mc_ddr4_0_c0_ddr4_ui_clk [get_bd_pins s_axi_clk_0] [get_bd_pins chunk_alloc_0/ap_clk] [get_bd_pins sys_mm_wrapper_0/s_axi_clk_0]

  # Set port frequency
  set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins sys_mm_wrapper_0/ctrl_stat_V_V_0]
  set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins sys_mm_wrapper_0/m_axi_0]
  set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins sys_mm_wrapper_0/ctrl_V_0]
  set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_pins sys_mm_wrapper_0/s_axi_0]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: libnet_rx
proc create_hier_cell_libnet_rx { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_libnet_rx() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ack_out
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 input_r

  # Create pins
  create_bd_pin -dir I -type clk clk_150
  create_bd_pin -dir I -type rst clk_150_rst_n

  # Create instance: axis_256_to_64, and set properties
  set axis_256_to_64 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_256_to_64 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {8} \
 ] $axis_256_to_64

  # Create instance: libnet_rx_256_0, and set properties
  set libnet_rx_256_0 [ create_bd_cell -type ip -vlnv wuklab:hls:libnet_rx_256:1.0 libnet_rx_256_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_256_to_64/M_AXIS]
  connect_bd_intf_net -intf_net axis_interconnect_0_M00_AXIS [get_bd_intf_pins input_r] [get_bd_intf_pins libnet_rx_256_0/input_r]
  connect_bd_intf_net -intf_net libnet_rx_256_0_ack_out [get_bd_intf_pins ack_out] [get_bd_intf_pins libnet_rx_256_0/ack_out]
  connect_bd_intf_net -intf_net libnet_rx_256_0_data_out [get_bd_intf_pins axis_256_to_64/S_AXIS] [get_bd_intf_pins libnet_rx_256_0/data_out]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_150] [get_bd_pins axis_256_to_64/aclk] [get_bd_pins libnet_rx_256_0/ap_clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_150_rst_n] [get_bd_pins axis_256_to_64/aresetn] [get_bd_pins libnet_rx_256_0/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: cdc_tx
proc create_hier_cell_cdc_tx { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_cdc_tx() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 TX

  # Create pins
  create_bd_pin -dir I -type clk TX_clk
  create_bd_pin -dir I -type rst TX_rst_n
  create_bd_pin -dir I -type clk clk_150
  create_bd_pin -dir I -type rst clk_150_rst_n

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {1024} \
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

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins TX] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_interconnect_1_M00_AXIS [get_bd_intf_pins axis_data_fifo_1/S_AXIS] [get_bd_intf_pins axis_interconnect_1/M00_AXIS]
  connect_bd_intf_net -intf_net libnet_rx_256_0_ack_out [get_bd_intf_pins S01_AXIS] [get_bd_intf_pins axis_interconnect_1/S01_AXIS]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_toNet [get_bd_intf_pins S00_AXIS] [get_bd_intf_pins axis_interconnect_1/S00_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_150] [get_bd_pins axis_interconnect_1/ACLK] [get_bd_pins axis_interconnect_1/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S01_AXIS_ACLK]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_150_rst_n] [get_bd_pins axis_interconnect_1/ARESETN] [get_bd_pins axis_interconnect_1/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S01_AXIS_ARESETN]
  connect_bd_net -net to_net_clk_390_1 [get_bd_pins TX_clk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins axis_interconnect_1/M00_AXIS_ACLK]
  connect_bd_net -net to_net_clk_390_rst_n_1 [get_bd_pins TX_rst_n] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins axis_interconnect_1/M00_AXIS_ARESETN]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins axis_interconnect_1/S00_ARB_REQ_SUPPRESS] [get_bd_pins axis_interconnect_1/S01_ARB_REQ_SUPPRESS] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: cdc_rx
proc create_hier_cell_cdc_rx { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_cdc_rx() - Empty argument(s)!"}
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
  create_bd_pin -dir I -type clk RX_clk
  create_bd_pin -dir I -type rst RX_rst_n
  create_bd_pin -dir I -type clk clk_150
  create_bd_pin -dir I -type rst clk_150_rst_n

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {1024} \
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
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axis_interconnect_0/S00_AXIS]
  connect_bd_intf_net -intf_net axis_interconnect_0_M00_AXIS [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_interconnect_0/M00_AXIS]
  connect_bd_intf_net -intf_net from_net_1 [get_bd_intf_pins RX] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_150] [get_bd_pins axis_interconnect_0/ACLK] [get_bd_pins axis_interconnect_0/M00_AXIS_ACLK]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_150_rst_n] [get_bd_pins axis_interconnect_0/ARESETN] [get_bd_pins axis_interconnect_0/M00_AXIS_ARESETN]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_pins RX_clk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_interconnect_0/S00_AXIS_ACLK]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_pins RX_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_interconnect_0/S00_AXIS_ARESETN]

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
   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_sysclk1_300} \
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

# Hierarchical cell: Buddy
proc create_hier_cell_Buddy { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Buddy() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 alloc_V
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 alloc_ret_V
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dram

  # Create pins
  create_bd_pin -dir I -type clk clk_150
  create_bd_pin -dir I -type rst clk_150_rst_n

  # Create instance: buddy_allocator_0, and set properties
  set buddy_allocator_0 [ create_bd_cell -type ip -vlnv purdue.wuklab:hls:buddy_allocator:1.0 buddy_allocator_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Buddy_alloc_ret_V [get_bd_intf_pins alloc_ret_V] [get_bd_intf_pins buddy_allocator_0/alloc_ret_V]
  connect_bd_intf_net -intf_net Buddy_m_axi_dram [get_bd_intf_pins m_axi_dram] [get_bd_intf_pins buddy_allocator_0/m_axi_dram]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_alloc_V_0 [get_bd_intf_pins alloc_V] [get_bd_intf_pins buddy_allocator_0/alloc_V]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_pins clk_150] [get_bd_pins buddy_allocator_0/ap_clk]
  connect_bd_net -net ARESETN_0_1 [get_bd_pins clk_150_rst_n] [get_bd_pins buddy_allocator_0/ap_rst_n]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins buddy_allocator_0/ap_start] [get_bd_pins xlconstant_0/dout]

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
   CONFIG.ASSOCIATED_RESET {clk_150_rst_n} \
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

  # Create instance: Buddy
  create_hier_cell_Buddy [current_bd_instance .] Buddy

  # Create instance: MC
  create_hier_cell_MC [current_bd_instance .] MC

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {5} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S01_HAS_DATA_FIFO {2} \
   CONFIG.S02_HAS_DATA_FIFO {2} \
   CONFIG.S03_HAS_DATA_FIFO {2} \
   CONFIG.S04_HAS_DATA_FIFO {2} \
   CONFIG.STRATEGY {2} \
 ] $axi_interconnect_0

  # Create instance: cdc_rx
  create_hier_cell_cdc_rx [current_bd_instance .] cdc_rx

  # Create instance: cdc_tx
  create_hier_cell_cdc_tx [current_bd_instance .] cdc_tx

  # Create instance: libnet_rx
  create_hier_cell_libnet_rx [current_bd_instance .] libnet_rx

  # Create instance: memcached_top_for_bu_0, and set properties
  set memcached_top_for_bu_0 [ create_bd_cell -type ip -vlnv wuklab:user:memcached_top_for_buddy:1.0 memcached_top_for_bu_0 ]

  # Create instance: mmu
  create_hier_cell_mmu [current_bd_instance .] mmu

  # Create interface connections
  connect_bd_intf_net -intf_net Buddy_alloc_ret_V [get_bd_intf_pins Buddy/alloc_ret_V] [get_bd_intf_pins memcached_top_for_bu_0/alloc_ret_V_0]
  connect_bd_intf_net -intf_net Buddy_m_axi_dram [get_bd_intf_pins Buddy/m_axi_dram] [get_bd_intf_pins axi_interconnect_0/S04_AXI]
  connect_bd_intf_net -intf_net C0_SYS_CLK_0_1 [get_bd_intf_ports C0_SYS_CLK_0] [get_bd_intf_pins MC/C0_SYS_CLK_0]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins mmu/s_axi_0]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_ports TX] [get_bd_intf_pins cdc_tx/TX]
  connect_bd_intf_net -intf_net axis_data_fifo_2_M_AXIS [get_bd_intf_pins libnet_rx/M_AXIS] [get_bd_intf_pins memcached_top_for_bu_0/fromNet]
  connect_bd_intf_net -intf_net axis_interconnect_0_M00_AXIS [get_bd_intf_pins cdc_rx/M00_AXIS] [get_bd_intf_pins libnet_rx/input_r]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins MC/ddr4_sdram_c1]
  connect_bd_intf_net -intf_net from_net_1 [get_bd_intf_ports RX] [get_bd_intf_pins cdc_rx/RX]
  connect_bd_intf_net -intf_net libnet_rx_256_0_ack_out [get_bd_intf_pins cdc_tx/S01_AXIS] [get_bd_intf_pins libnet_rx/ack_out]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_RD_C0 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins memcached_top_for_bu_0/MCD_AXI2DRAM_RD_C0]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_RD_C1 [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins memcached_top_for_bu_0/MCD_AXI2DRAM_RD_C1]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_WR_C0 [get_bd_intf_pins axi_interconnect_0/S02_AXI] [get_bd_intf_pins memcached_top_for_bu_0/MCD_AXI2DRAM_WR_C0]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_MCD_AXI2DRAM_WR_C1 [get_bd_intf_pins axi_interconnect_0/S03_AXI] [get_bd_intf_pins memcached_top_for_bu_0/MCD_AXI2DRAM_WR_C1]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_alloc_V_0 [get_bd_intf_pins Buddy/alloc_V] [get_bd_intf_pins memcached_top_for_bu_0/alloc_V_0]
  connect_bd_intf_net -intf_net memcached_top_for_bu_0_toNet [get_bd_intf_pins cdc_tx/S00_AXIS] [get_bd_intf_pins memcached_top_for_bu_0/toNet]
  connect_bd_intf_net -intf_net sys_mm_wrapper_0_m_axi_0 [get_bd_intf_pins MC/C0_DDR4_S_AXI] [get_bd_intf_pins mmu/m_axi_0]

  # Create port connections
  connect_bd_net -net ACLK_0_1 [get_bd_ports clk_150] [get_bd_pins Buddy/clk_150] [get_bd_pins axi_interconnect_0/S04_ACLK] [get_bd_pins cdc_rx/clk_150] [get_bd_pins cdc_tx/clk_150] [get_bd_pins libnet_rx/clk_150] [get_bd_pins memcached_top_for_bu_0/aclk]
  connect_bd_net -net ARESETN_0_1 [get_bd_ports clk_150_rst_n] [get_bd_pins Buddy/clk_150_rst_n] [get_bd_pins axi_interconnect_0/S04_ARESETN] [get_bd_pins cdc_rx/clk_150_rst_n] [get_bd_pins cdc_tx/clk_150_rst_n] [get_bd_pins libnet_rx/clk_150_rst_n] [get_bd_pins memcached_top_for_bu_0/aresetn]
  connect_bd_net -net S00_AXIS_ACLK_0_1 [get_bd_ports RX_clk] [get_bd_pins cdc_rx/RX_clk]
  connect_bd_net -net S00_AXIS_ARESETN_0_1 [get_bd_ports RX_rst_n] [get_bd_pins cdc_rx/RX_rst_n]
  connect_bd_net -net c0_ddr4_ui_clk_rstn [get_bd_ports mc_ddr4_ui_clk_rst_n] [get_bd_pins MC/c0_ddr4_ui_clk_rstn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_0/S02_ARESETN] [get_bd_pins axi_interconnect_0/S03_ARESETN] [get_bd_pins memcached_top_for_bu_0/mem_c0_resetn] [get_bd_pins mmu/mc_ddr4_ui_clk_rst_n]
  connect_bd_net -net mc_ddr4_0_c0_ddr4_ui_clk [get_bd_pins MC/c0_ddr4_ui_clk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK] [get_bd_pins axi_interconnect_0/S03_ACLK] [get_bd_pins memcached_top_for_bu_0/mem_c0_clk] [get_bd_pins mmu/s_axi_clk_0]
  connect_bd_net -net mc_ddr4_wrapper_c0_init_calib_complete_0 [get_bd_ports mc_init_calib_complete] [get_bd_pins MC/c0_init_calib_complete_0]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst] [get_bd_pins MC/sys_rst]
  connect_bd_net -net to_net_clk_390_1 [get_bd_ports TX_clk] [get_bd_pins cdc_tx/TX_clk]
  connect_bd_net -net to_net_clk_390_rst_n_1 [get_bd_ports TX_rst_n] [get_bd_pins cdc_tx/TX_rst_n]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces mmu/sys_mm_wrapper_0/m_axi_0] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces memcached_top_for_bu_0/MCD_AXI2DRAM_RD_C0] [get_bd_addr_segs mmu/sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces memcached_top_for_bu_0/MCD_AXI2DRAM_RD_C1] [get_bd_addr_segs mmu/sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces memcached_top_for_bu_0/MCD_AXI2DRAM_WR_C0] [get_bd_addr_segs mmu/sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces memcached_top_for_bu_0/MCD_AXI2DRAM_WR_C1] [get_bd_addr_segs mmu/sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces Buddy/buddy_allocator_0/Data_m_axi_dram] [get_bd_addr_segs mmu/sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name
}
# End of cr_bd_LegoFPGA_KVS_for_pcie_all()
cr_bd_LegoFPGA_KVS_for_pcie_all ""
set_property IS_MANAGED "0" [get_files LegoFPGA_KVS_for_pcie_all.bd ]
set_property REGISTERED_WITH_MANAGER "1" [get_files LegoFPGA_KVS_for_pcie_all.bd ]
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files LegoFPGA_KVS_for_pcie_all.bd ]

proc cr_bd_LegoFPGA_RDM_for_pcie_all { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name LegoFPGA_RDM_for_pcie_all

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set axis_data_fifo [get_ipdefs -filter NAME==axis_data_fifo]

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  wuklab:user:mapping_ip_top:1.0\
  Wuklab.UCSD:hls:rdm_mapping:1.0\
  xilinx.com:ip:axi_datamover:5.1\
  $axis_data_fifo\
  xilinx.com:ip:axis_dwidth_converter:1.1\
  Wuklab.UCSD:hls:buddy_allocator:1.0\
  wuklab:user:sys_mm_wrapper:1.0\
  xilinx.com:ip:xlconstant:1.1\
  xilinx.com:ip:ddr4:2.2\
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
  create_bd_pin -dir O -from 0 -to 0 mc_ddr4_ui_clk_rst_n
  create_bd_pin -dir O mc_init_calib_complete
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
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_pins ddr4_sdram_c1] [get_bd_intf_pins mc_ddr4_core/C0_DDR4]
  connect_bd_intf_net -intf_net sys_mm_wrapper_0_m_axi_0 [get_bd_intf_pins C0_DDR4_S_AXI] [get_bd_intf_pins mc_ddr4_core/C0_DDR4_S_AXI]

  # Create port connections
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins mc_ddr4_ui_clk_rst_n] [get_bd_pins mc_ddr4_core/c0_ddr4_aresetn] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net MC_c0_ddr4_ui_clk [get_bd_pins c0_ddr4_ui_clk] [get_bd_pins mc_ddr4_core/c0_ddr4_ui_clk]
  connect_bd_net -net c0_ddr4_ui_clk_rstn_1 [get_bd_pins mc_ddr4_core/c0_ddr4_ui_clk_sync_rst] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net mc_ddr4_wrapper_c0_init_calib_complete_0 [get_bd_pins mc_init_calib_complete] [get_bd_pins mc_ddr4_core/c0_init_calib_complete]
  connect_bd_net -net sys_rst_0_1 [get_bd_pins sys_rst] [get_bd_pins mc_ddr4_core/sys_rst]

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
   CONFIG.ASSOCIATED_BUSIF {RX:TX} \
   CONFIG.ASSOCIATED_RESET {RX_rst_n} \
   CONFIG.FREQ_HZ {250000000} \
 ] $RX_clk
  set RX_rst_n [ create_bd_port -dir I -type rst RX_rst_n ]
  set mc_ddr4_ui_clk_rst_n [ create_bd_port -dir O -from 0 -to 0 mc_ddr4_ui_clk_rst_n ]
  set mc_init_calib_complete [ create_bd_port -dir O mc_init_calib_complete ]
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst

  # Create instance: HashTable, and set properties
  set HashTable [ create_bd_cell -type ip -vlnv wuklab:user:mapping_ip_top:1.0 HashTable ]

  # Create instance: MC
  create_hier_cell_MC [current_bd_instance .] MC

  # Create instance: RDM_Mapping, and set properties
  set RDM_Mapping [ create_bd_cell -type ip -vlnv Wuklab.UCSD:hls:rdm_mapping:1.0 RDM_Mapping ]

  # Create instance: axi_datamover_0, and set properties
  set axi_datamover_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover_0 ]
  set_property -dict [ list \
   CONFIG.c_dummy {1} \
   CONFIG.c_enable_s2mm {1} \
   CONFIG.c_include_s2mm {Full} \
   CONFIG.c_include_s2mm_stsfifo {true} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_s2mm_awid {1} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_btt_used {23} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_mm2s_include_sf {false} \
   CONFIG.c_s2mm_addr_pipe_depth {3} \
   CONFIG.c_s2mm_btt_used {23} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_s_axis_s2mm_tdata_width {512} \
 ] $axi_datamover_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_ARB_PRIORITY {14} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S01_ARB_PRIORITY {0} \
   CONFIG.S01_HAS_DATA_FIFO {2} \
   CONFIG.S02_HAS_DATA_FIFO {2} \
   CONFIG.S03_ARB_PRIORITY {15} \
   CONFIG.S03_HAS_DATA_FIFO {2} \
   CONFIG.STRATEGY {2} \
 ] $axi_interconnect_0

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {8192} \
 ] $axis_data_fifo_0

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv $axis_data_fifo axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {8192} \
 ] $axis_data_fifo_1

  # Create instance: axis_dwidth_converter_0, and set properties
  set axis_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {64} \
   CONFIG.S_TDATA_NUM_BYTES {32} \
 ] $axis_dwidth_converter_0

  # Create instance: axis_dwidth_converter_1, and set properties
  set axis_dwidth_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_1 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {32} \
   CONFIG.S_TDATA_NUM_BYTES {64} \
 ] $axis_dwidth_converter_1

  # Create instance: buddy_allocator_0, and set properties
  set buddy_allocator_0 [ create_bd_cell -type ip -vlnv Wuklab.UCSD:hls:buddy_allocator:1.0 buddy_allocator_0 ]

  # Create instance: sys_mm_wrapper_0, and set properties
  set sys_mm_wrapper_0 [ create_bd_cell -type ip -vlnv wuklab:user:sys_mm_wrapper:1.0 sys_mm_wrapper_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]

  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_2

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_0_1 [get_bd_intf_ports C0_SYS_CLK_0] [get_bd_intf_pins MC/C0_SYS_CLK_0]
  connect_bd_intf_net -intf_net RDM_Mapping_DRAM_rd_cmd_V [get_bd_intf_pins RDM_Mapping/DRAM_rd_cmd_V] [get_bd_intf_pins axi_datamover_0/S_AXIS_MM2S_CMD]
  connect_bd_intf_net -intf_net RDM_Mapping_DRAM_wr_cmd_V [get_bd_intf_pins RDM_Mapping/DRAM_wr_cmd_V] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net RDM_Mapping_DRAM_wr_data [get_bd_intf_pins RDM_Mapping/DRAM_wr_data] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net RDM_Mapping_alloc_req_V [get_bd_intf_pins RDM_Mapping/alloc_req_V] [get_bd_intf_pins buddy_allocator_0/alloc_V]
  connect_bd_intf_net -intf_net RDM_Mapping_to_net [get_bd_intf_pins RDM_Mapping/to_net] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
  connect_bd_intf_net -intf_net RX_1 [get_bd_intf_ports RX] [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_datamover_0/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins HashTable/M00_AXI_0] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_MM2S [get_bd_intf_pins RDM_Mapping/DRAM_rd_data] [get_bd_intf_pins axi_datamover_0/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_MM2S_STS [get_bd_intf_pins RDM_Mapping/DRAM_rd_status_V_V] [get_bd_intf_pins axi_datamover_0/M_AXIS_MM2S_STS]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_S2MM_STS [get_bd_intf_pins RDM_Mapping/DRAM_wr_status_V_V] [get_bd_intf_pins axi_datamover_0/M_AXIS_S2MM_STS]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_MM2S [get_bd_intf_pins axi_datamover_0/M_AXI_MM2S] [get_bd_intf_pins axi_interconnect_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins sys_mm_wrapper_0/s_axi_0]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS1 [get_bd_intf_pins axis_data_fifo_1/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_2_M_AXIS [get_bd_intf_pins RDM_Mapping/from_net] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_1_M_AXIS [get_bd_intf_ports TX] [get_bd_intf_pins axis_dwidth_converter_1/M_AXIS]
  connect_bd_intf_net -intf_net buddy_allocator_0_alloc_ret_V [get_bd_intf_pins RDM_Mapping/alloc_ret_V] [get_bd_intf_pins buddy_allocator_0/alloc_ret_V]
  connect_bd_intf_net -intf_net buddy_allocator_0_m_axi_dram [get_bd_intf_pins axi_interconnect_0/S02_AXI] [get_bd_intf_pins buddy_allocator_0/m_axi_dram]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins MC/ddr4_sdram_c1]
  connect_bd_intf_net -intf_net mapping_ip_top_0_out_read_0 [get_bd_intf_pins HashTable/out_read_0] [get_bd_intf_pins RDM_Mapping/map_ret_V]
  connect_bd_intf_net -intf_net rdm_mapping_0_map_req_V [get_bd_intf_pins HashTable/in_read_0] [get_bd_intf_pins RDM_Mapping/map_req_V]
  connect_bd_intf_net -intf_net sys_mm_wrapper_0_m_axi_0 [get_bd_intf_pins MC/C0_DDR4_S_AXI] [get_bd_intf_pins sys_mm_wrapper_0/m_axi_0]

  # Create port connections
  connect_bd_net -net M00_ARESETN_1 [get_bd_ports mc_ddr4_ui_clk_rst_n] [get_bd_pins MC/mc_ddr4_ui_clk_rst_n] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins sys_mm_wrapper_0/s_aresetn_0]
  connect_bd_net -net MC_c0_ddr4_ui_clk [get_bd_pins MC/c0_ddr4_ui_clk] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins sys_mm_wrapper_0/s_axi_clk_0]
  connect_bd_net -net RX_clk_1 [get_bd_ports RX_clk] [get_bd_pins HashTable/ap_clk] [get_bd_pins RDM_Mapping/ap_clk] [get_bd_pins axi_datamover_0/m_axi_mm2s_aclk] [get_bd_pins axi_datamover_0/m_axi_s2mm_aclk] [get_bd_pins axi_datamover_0/m_axis_mm2s_cmdsts_aclk] [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_awclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK] [get_bd_pins axi_interconnect_0/S03_ACLK] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins axis_dwidth_converter_0/aclk] [get_bd_pins axis_dwidth_converter_1/aclk] [get_bd_pins buddy_allocator_0/ap_clk]
  connect_bd_net -net RX_rst_n_1 [get_bd_ports RX_rst_n] [get_bd_pins HashTable/ap_rstn] [get_bd_pins RDM_Mapping/ap_rst_n] [get_bd_pins axi_datamover_0/m_axi_mm2s_aresetn] [get_bd_pins axi_datamover_0/m_axi_s2mm_aresetn] [get_bd_pins axi_datamover_0/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_0/S02_ARESETN] [get_bd_pins axi_interconnect_0/S03_ARESETN] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins axis_dwidth_converter_0/aresetn] [get_bd_pins axis_dwidth_converter_1/aresetn] [get_bd_pins buddy_allocator_0/ap_rst_n]
  connect_bd_net -net mc_ddr4_wrapper_c0_init_calib_complete_0 [get_bd_ports mc_init_calib_complete] [get_bd_pins MC/mc_init_calib_complete]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst] [get_bd_pins MC/sys_rst]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins HashTable/in_write_0_tvalid] [get_bd_pins HashTable/out_write_0_tready] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins buddy_allocator_0/ap_start] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlconstant_2_dout [get_bd_pins sys_mm_wrapper_0/ctrl_V_0_tvalid] [get_bd_pins sys_mm_wrapper_0/ctrl_stat_V_V_0_tready] [get_bd_pins xlconstant_2/dout]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces HashTable/M00_AXI_0] [get_bd_addr_segs sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_datamover_0/Data_MM2S] [get_bd_addr_segs sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces axi_datamover_0/Data_S2MM] [get_bd_addr_segs sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces buddy_allocator_0/Data_m_axi_dram] [get_bd_addr_segs sys_mm_wrapper_0/s_axi_0/reg0] SEG_sys_mm_wrapper_0_reg0
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces sys_mm_wrapper_0/m_axi_0] [get_bd_addr_segs MC/mc_ddr4_core/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] SEG_mc_ddr4_core_C0_DDR4_ADDRESS_BLOCK


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
common::send_msg_id "BD_TCL-1000" "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

  close_bd_design $design_name 
}
# End of cr_bd_LegoFPGA_RDM_for_pcie_all()
cr_bd_LegoFPGA_RDM_for_pcie_all ""
set_property IS_MANAGED "0" [get_files LegoFPGA_RDM_for_pcie_all.bd ] 
set_property REGISTERED_WITH_MANAGER "1" [get_files LegoFPGA_RDM_for_pcie_all.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files LegoFPGA_RDM_for_pcie_all.bd ] 

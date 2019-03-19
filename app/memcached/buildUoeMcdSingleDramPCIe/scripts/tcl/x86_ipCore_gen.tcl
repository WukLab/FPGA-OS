create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name cmd_fifo_xgemac_txif
set_property -dict [list \
	CONFIG.Input_Data_Width {1} \
	CONFIG.Input_Depth {4096} \
	CONFIG.Output_Data_Width {1} \
	CONFIG.Output_Depth {4096} \
	CONFIG.Data_Count_Width {12} \
	CONFIG.Write_Data_Count_Width {12} \
	CONFIG.Read_Data_Count_Width {12} \
	CONFIG.Full_Threshold_Assert_Value {4094} \
	CONFIG.Full_Threshold_Negate_Value {4093}] [get_ips cmd_fifo_xgemac_txif]
generate_target {instantiation_template} [get_files cmd_fifo_xgemac_txif.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name axis_sync_fifo
set_property -dict [list \
	CONFIG.INTERFACE_TYPE {AXI_STREAM} \
	CONFIG.TDATA_NUM_BYTES {8} \
	CONFIG.TUSER_WIDTH {0} \
	CONFIG.Enable_TLAST {true} \
	CONFIG.HAS_TKEEP {true} \
	CONFIG.Input_Depth_axis {4096} \
	CONFIG.Enable_Data_Counts_axis {true} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {1} \
	CONFIG.TSTRB_WIDTH {8} \
	CONFIG.TKEEP_WIDTH {8} \
	CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
	CONFIG.Full_Threshold_Assert_Value_wach {15} \
	CONFIG.Empty_Threshold_Assert_Value_wach {14} \
	CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
	CONFIG.Full_Threshold_Assert_Value_wrch {15} \
	CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
	CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
	CONFIG.Full_Threshold_Assert_Value_rach {15} \
	CONFIG.Empty_Threshold_Assert_Value_rach {14} \
	CONFIG.Full_Threshold_Assert_Value_axis {4095} \
	CONFIG.Empty_Threshold_Assert_Value_axis {4094}] [get_ips axis_sync_fifo]
generate_target {instantiation_template} [get_files axis_sync_fifo.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name rx_fifo
set_property -dict [list \
	CONFIG.INTERFACE_TYPE {AXI_STREAM} \
	CONFIG.TDATA_NUM_BYTES {8} \
	CONFIG.TUSER_WIDTH {0} \
	CONFIG.Enable_TLAST {true} \
	CONFIG.HAS_TKEEP {true} \
	CONFIG.Enable_Data_Counts_axis {true} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {1} \
	CONFIG.TSTRB_WIDTH {8} \
	CONFIG.TKEEP_WIDTH {8} \
	CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
	CONFIG.Full_Threshold_Assert_Value_wach {15} \
	CONFIG.Empty_Threshold_Assert_Value_wach {14} \
	CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
	CONFIG.Full_Threshold_Assert_Value_wrch {15} \
	CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
	CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
	CONFIG.Full_Threshold_Assert_Value_rach {15} \
	CONFIG.Empty_Threshold_Assert_Value_rach {14}] [get_ips rx_fifo]
generate_target {instantiation_template} [get_files rx_fifo.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name singleSignalCDC
set_property -dict [list \
	CONFIG.Fifo_Implementation {Independent_Clocks_Distributed_RAM} \
	CONFIG.Input_Data_Width {1} \
	CONFIG.Input_Depth {16} \
	CONFIG.Reset_Pin {false} \
	CONFIG.Output_Data_Width {1} \
	CONFIG.Output_Depth {16} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {0} \
	CONFIG.Use_Dout_Reset {false} \
	CONFIG.Data_Count_Width {4} \
	CONFIG.Write_Data_Count_Width {4} \
	CONFIG.Read_Data_Count_Width {4} \
	CONFIG.Full_Threshold_Assert_Value {13} \
	CONFIG.Full_Threshold_Negate_Value {12}] [get_ips singleSignalCDC]
generate_target {instantiation_template} [get_files singleSignalCDC.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name memMgmt_async_fifo
set_property -dict [list \
	CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
	CONFIG.Performance_Options {First_Word_Fall_Through} \
	CONFIG.Input_Data_Width {32} \
	CONFIG.Input_Depth {16} \
	CONFIG.Output_Data_Width {32} \
	CONFIG.Output_Depth {16} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {1} \
	CONFIG.Data_Count_Width {4} \
	CONFIG.Write_Data_Count_Width {4} \
	CONFIG.Read_Data_Count_Width {4} \
	CONFIG.Full_Threshold_Assert_Value {15} \
	CONFIG.Full_Threshold_Negate_Value {14} \
	CONFIG.Empty_Threshold_Assert_Value {4} \
	CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips memMgmt_async_fifo]
generate_target {instantiation_template} [get_files memMgmt_async_fifo.xci]

create_ip -name ten_gig_eth_pcs_pma -vendor xilinx.com -library ip -module_name ten_gig_eth_pcs_pma_ip
set_property -dict [list \
	CONFIG.MDIO_Management {false} \
	CONFIG.base_kr {BASE-R}] [get_ips ten_gig_eth_pcs_pma_ip]
generate_target {instantiation_template} [get_files ten_gig_eth_pcs_pma_ip.xci]

create_ip -name ten_gig_eth_mac -vendor xilinx.com -library ip -module_name ten_gig_eth_mac_ip
set_property -dict [list \
	CONFIG.Management_Interface {false} \
	CONFIG.Statistics_Gathering {false}] [get_ips ten_gig_eth_mac_ip]
generate_target {instantiation_template} [get_files ten_gig_eth_mac_ip.xci]

create_ip -name axis_register_slice -vendor xilinx.com -library ip -module_name axis_register_slice_64
set_property -dict [list \
	CONFIG.TDATA_NUM_BYTES {8} \
	CONFIG.HAS_TKEEP {1} \
	CONFIG.HAS_TLAST {1}] [get_ips axis_register_slice_64]
generate_target {instantiation_template} [get_files axis_register_slice_64.xci]

create_ip -name axi_datamover -vendor xilinx.com -library ip -module_name axi_datamover_0
set_property -dict [list \
	CONFIG.c_m_axi_mm2s_data_width {512} \
	CONFIG.c_m_axis_mm2s_tdata_width {512} \
	CONFIG.c_mm2s_burst_size {4} \
	CONFIG.c_mm2s_btt_used {23} \
	CONFIG.c_m_axi_s2mm_data_width {512} \
	CONFIG.c_s_axis_s2mm_tdata_width {512} \
	CONFIG.c_s2mm_burst_size {4} \
	CONFIG.c_s2mm_btt_used {23} \
	CONFIG.c_mm2s_stscmd_is_async {true} \
	CONFIG.c_s2mm_stscmd_is_async {true} \
	CONFIG.c_m_axi_mm2s_id_width {5} \
	CONFIG.c_m_axi_s2mm_id_width {5}] [get_ips axi_datamover_0]
generate_target {instantiation_template} [get_files axi_datamover_0.xci]

create_ip -name axis_clock_converter -vendor xilinx.com -library ip -module_name axis_clock_converter_512
set_property -dict [list \
	CONFIG.TDATA_NUM_BYTES {64} \
	CONFIG.HAS_TKEEP {1} \
	CONFIG.HAS_TLAST {1}] [get_ips axis_clock_converter_512]
generate_target {instantiation_template} [get_files axis_clock_converter_512.xci]

#pcie sub modules
create_ip -name pcie3_7x -vendor xilinx.com -library ip -module_name pcie2axilite_sub_pcie3_7x_0
set_property -dict [list \
	CONFIG.pcie_blk_locn {X0Y2} \
	CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {false} \
	CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
	CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {2.5_GT/s} \
	CONFIG.AXISTEN_IF_RC_STRADDLE {false} \
	CONFIG.pf0_base_class_menu {Simple_communication_controllers} \
	CONFIG.pf0_class_code_base {05} \
	CONFIG.pf0_class_code_sub {80} \
	CONFIG.pf0_bar0_size {4} \
	CONFIG.mode_selection {Advanced} \
	CONFIG.en_ext_clk {false} \
	CONFIG.shared_logic_in_core {true} \
	CONFIG.cfg_fc_if {false} \
	CONFIG.cfg_ext_if {false} \
	CONFIG.cfg_status_if {false} \
	CONFIG.per_func_status_if {false} \
	CONFIG.cfg_mgmt_if {false} \
	CONFIG.rcv_msg_if {false} \
	CONFIG.cfg_tx_msg_if {false} \
	CONFIG.cfg_ctl_if {false} \
	CONFIG.tx_fc_if {false} \
	CONFIG.gen_x0y1 {false} \
	CONFIG.gen_x0y2 {true} \
	CONFIG.tandem_mode {None} \
	CONFIG.axisten_if_width {64_bit} \
	CONFIG.PF0_DEVICE_ID {0007} \
	CONFIG.pf0_sub_class_interface_menu {Generic_XT_compatible_serial_controller} \
	CONFIG.PF0_CLASS_CODE {058000} \
	CONFIG.PF1_DEVICE_ID {7011} \
	CONFIG.pipe_mode_sim {None} \
	CONFIG.axisten_freq {250} \
	CONFIG.aspm_support {No_ASPM}] [get_ips pcie2axilite_sub_pcie3_7x_0]
generate_target {instantiation_template} [get_files pcie2axilite_sub_pcie3_7x_0.xci]

create_ip -name pcie_2_axilite -vendor xilinx.com -library user -version 1.0 -module_name pcie2axilite_sub_pcie_2_axilite_0
set_property -dict [list \
	CONFIG.BAR0SIZE {0xFFFFFFFFFFFFF000} \
	CONFIG.BAR2AXI1_TRANSLATION {0x00000000c2000000} \
	CONFIG.BAR2AXI0_TRANSLATION {0x0000000000000000} \
	CONFIG.AXIS_TDATA_WIDTH {64} \
	CONFIG.S_AXI_TDATA_WIDTH {32} \
	CONFIG.M_AXI_TDATA_WIDTH {32}] [get_ips pcie2axilite_sub_pcie_2_axilite_0]
generate_target {instantiation_template} [get_files pcie2axilite_sub_pcie_2_axilite_0.xci]

create_ip -name axis_interconnect -vendor xilinx.com -library ip -module_name axis_interconnect_2to1
set_property -dict [list \
	CONFIG.C_NUM_SI_SLOTS {2} \
	CONFIG.SWITCH_TDATA_NUM_BYTES {8} \
	CONFIG.HAS_TSTRB {false} \
	CONFIG.HAS_TID {false} \
	CONFIG.HAS_TDEST {false} \
	CONFIG.SWITCH_PACKET_MODE {true} \
	CONFIG.C_SWITCH_MAX_XFERS_PER_ARB {0} \
	CONFIG.C_M00_AXIS_REG_CONFIG {1} \
	CONFIG.C_S00_AXIS_REG_CONFIG {1} \
	CONFIG.C_S01_AXIS_REG_CONFIG {1} \
	CONFIG.C_SWITCH_NUM_CYCLES_TIMEOUT {0} \
	CONFIG.M00_AXIS_TDATA_NUM_BYTES {8} \
	CONFIG.S00_AXIS_TDATA_NUM_BYTES {8} \
	CONFIG.S01_AXIS_TDATA_NUM_BYTES {8} \
	CONFIG.M00_S01_CONNECTIVITY {true}] [get_ips axis_interconnect_2to1]
generate_target {instantiation_template} [get_files axis_interconnect_2to1.xci]

create_ip -name icmp_server -vendor xilinx.labs -library hls -module_name icmp_server_ip
generate_target {instantiation_template} [get_files icmp_server_ip.xci]

create_ip -name udpAppMux -vendor xilinx.labs -library hls -module_name udpAppMux_0
generate_target {instantiation_template} [get_files udpAppMux_0.xci]

create_ip -name dhcp_client -vendor xilinx.labs -library hls -module_name dhcp_client_0
generate_target {instantiation_template} [get_files dhcp_client_0.xci]

create_ip -name arp_server -vendor xilinx.labs -library hls -module_name arp_server_ip
generate_target {instantiation_template} [get_files arp_server_ip.xci]

create_ip -name udp -vendor xilinx.labs -library hls -module_name udp_0
generate_target {instantiation_template} [get_files udp_0.xci]

create_ip -name ip_handler -vendor xilinx.labs -library hls -module_name ip_handler_ip
generate_target {instantiation_template} [get_files ip_handler_ip.xci]

create_ip -name mac_ip_encode -vendor xilinx.labs -library hls  -module_name mac_ip_encode_ip
generate_target {instantiation_template} [get_files mac_ip_encode_ip.xci]

create_ip -name udpShim -vendor xilinx.labs -library hls  -module_name udpShim_ip
generate_target {instantiation_template} [get_files udpShim_ip.xci]

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
	] [get_ips singleSignalCDC]
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
	] [get_ips memMgmt_async_fifo]
generate_target {instantiation_template} [get_files memMgmt_async_fifo.xci]

#pcie sub modules
#CONFIG.shared_logic_in_core {true} \
#CONFIG.pipe_mode_sim {None} 
create_ip -name pcie3_ultrascale -vendor xilinx.com -library ip -module_name pcie2axilite_sub_pcie3_7x_0
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

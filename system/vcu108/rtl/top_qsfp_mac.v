/*
 * Copyright (c) 2019, Wuklab, Purdue University. All rights reserved.
 *
 * Target board: Xilinx VCU108.
 *
 * Top-level module for the whole system.
 * This file is just connecting three submodules together:
 *	- 10G/25G MAC IP block diagram
 *	- State machine for MAC IP
 *	- LegoFPGA block diagram
 *
 * IO Signals:
 * 	- Clock
 * 	- Reset
 * 	- Misc
 * 	- GT
 * 	- DDR4
 */

`timescale 1fs/1fs

(* DowngradeIPIdentifiedWarnings="yes" *)
module legofpga_mac_qsfp
(
	input  wire [1-1:0] gt_rxp_in,
	input  wire [1-1:0] gt_rxn_in,
	output wire [1-1:0] gt_txp_out,
	output wire [1-1:0] gt_txn_out,

	input             gt_refclk_p,
	input             gt_refclk_n,

	input             sys_reset,
	input             dclk,

	output wire	rx_gt_locked_led_0,
	output wire	rx_block_lock_led_0,
	output wire [4:0]completion_status
);

	// AXI4 Lite
	wire s_axi_aclk_0;
	wire s_axi_aresetn_0;
	wire [31:0] s_axi_awaddr_0;
	wire s_axi_awvalid_0;
	wire s_axi_awready_0;
	wire [31:0] s_axi_wdata_0;
	wire [3:0] s_axi_wstrb_0;
	wire s_axi_wvalid_0;
	wire s_axi_wready_0;
	wire [1:0] s_axi_bresp_0;
	wire s_axi_bvalid_0;
	wire s_axi_bready_0;
	wire [31:0] s_axi_araddr_0;
	wire s_axi_arvalid_0;
	wire s_axi_arready_0;
	wire [31:0] s_axi_rdata_0;
	wire [1:0] s_axi_rresp_0;
	wire s_axi_rvalid_0;
	wire s_axi_rready_0;
	wire pm_tick_0;
	wire  block_lock_led_0;

	wire rx_core_clk_0;
	wire rx_clk_out_0;
	wire tx_clk_out_0;
	//assign rx_core_clk_0 = tx_clk_out_0;
	assign rx_core_clk_0 = rx_clk_out_0;

	// RX_0 Signals
	wire rx_reset_0;
	wire user_rx_reset_0;
	wire rxrecclkout_0;

	// RX_0 User Interface Signals
	wire rx_axis_tvalid_0;
	wire [63:0] rx_axis_tdata_0;
	wire rx_axis_tlast_0;
	wire [7:0] rx_axis_tkeep_0;
	wire rx_axis_tuser_0;
	wire [55:0] rx_preambleout_0;

	// RX_0 Stats Signals
	wire stat_rx_block_lock_0;
	wire stat_rx_framing_err_valid_0;
	wire stat_rx_framing_err_0;
	wire stat_rx_hi_ber_0;
	wire stat_rx_valid_ctrl_code_0;
	wire stat_rx_bad_code_0;
	wire [1:0] stat_rx_total_packets_0;
	wire stat_rx_total_good_packets_0;
	wire [3:0] stat_rx_total_bytes_0;
	wire [13:0] stat_rx_total_good_bytes_0;
	wire stat_rx_packet_small_0;
	wire stat_rx_jabber_0;
	wire stat_rx_packet_large_0;
	wire stat_rx_oversize_0;
	wire stat_rx_undersize_0;
	wire stat_rx_toolong_0;
	wire stat_rx_fragment_0;
	wire stat_rx_packet_64_bytes_0;
	wire stat_rx_packet_65_127_bytes_0;
	wire stat_rx_packet_128_255_bytes_0;
	wire stat_rx_packet_256_511_bytes_0;
	wire stat_rx_packet_512_1023_bytes_0;
	wire stat_rx_packet_1024_1518_bytes_0;
	wire stat_rx_packet_1519_1522_bytes_0;
	wire stat_rx_packet_1523_1548_bytes_0;
	wire [1:0] stat_rx_bad_fcs_0;
	wire stat_rx_packet_bad_fcs_0;
	wire [1:0] stat_rx_stomped_fcs_0;
	wire stat_rx_packet_1549_2047_bytes_0;
	wire stat_rx_packet_2048_4095_bytes_0;
	wire stat_rx_packet_4096_8191_bytes_0;
	wire stat_rx_packet_8192_9215_bytes_0;
	wire stat_rx_bad_preamble_0;
	wire stat_rx_bad_sfd_0;
	wire stat_rx_got_signal_os_0;
	wire stat_rx_test_pattern_mismatch_0;
	wire stat_rx_truncated_0;
	wire stat_rx_local_fault_0;
	wire stat_rx_remote_fault_0;
	wire stat_rx_internal_local_fault_0;
	wire stat_rx_received_local_fault_0;
	wire stat_rx_status_0;
	// TX_0 Signals
	wire tx_reset_0;
	wire user_tx_reset_0;

	// TX_0 User Interface Signals
	wire tx_axis_tready_0;
	wire tx_axis_tvalid_0;
	wire [63:0] tx_axis_tdata_0;
	wire tx_axis_tlast_0;
	wire [7:0] tx_axis_tkeep_0;
	wire tx_axis_tuser_0;
	wire tx_unfout_0;
	wire [55:0] tx_preamblein_0;

	// TX_0 Control Signals
	wire ctl_tx_send_lfi_0;
	wire ctl_tx_send_rfi_0;
	wire ctl_tx_send_idle_0;

	// TX_0 Stats Signals
	wire stat_tx_total_packets_0;
	wire [3:0] stat_tx_total_bytes_0;
	wire stat_tx_total_good_packets_0;
	wire [13:0] stat_tx_total_good_bytes_0;
	wire stat_tx_packet_64_bytes_0;
	wire stat_tx_packet_65_127_bytes_0;
	wire stat_tx_packet_128_255_bytes_0;
	wire stat_tx_packet_256_511_bytes_0;
	wire stat_tx_packet_512_1023_bytes_0;
	wire stat_tx_packet_1024_1518_bytes_0;
	wire stat_tx_packet_1519_1522_bytes_0;
	wire stat_tx_packet_1523_1548_bytes_0;
	wire stat_tx_packet_small_0;
	wire stat_tx_packet_large_0;
	wire stat_tx_packet_1549_2047_bytes_0;
	wire stat_tx_packet_2048_4095_bytes_0;
	wire stat_tx_packet_4096_8191_bytes_0;
	wire stat_tx_packet_8192_9215_bytes_0;
	wire stat_tx_bad_fcs_0;
	wire stat_tx_frame_error_0;
	wire stat_tx_local_fault_0;

	wire gtwiz_reset_tx_datapath_0;
	wire gtwiz_reset_rx_datapath_0;
	assign gtwiz_reset_tx_datapath_0 = 1'b0; 
	assign gtwiz_reset_rx_datapath_0 = 1'b0; 
	wire gtpowergood_out_0;
	wire [2:0] txoutclksel_in_0;
	wire [2:0] rxoutclksel_in_0;

	assign txoutclksel_in_0 = 3'b101;    // this value should not be changed as per gtwizard 
	assign rxoutclksel_in_0 = 3'b101;    // this value should not be changed as per gtwizard
	wire [31:0] user_reg0_0;

	wire gt_refclk_out;

	wire mac_ready;
	wire fsm_out_pktgen_enable;
	wire fsm_out_sys_reset;

	assign rx_block_lock_led_0 = block_lock_led_0 & stat_rx_status_0;

	/*
	 * mac_ready indicate the the MAC layer is ready
	 * to be used by LegoFPGA layer.
	 *
	 * The *_led signals are legacy code from reference
	 * design. the pktgen_enable is from FSM output.
	 */
	assign mac_ready = fsm_out_pktgen_enable &
			   rx_gt_locked_led_0 &
			   rx_block_lock_led_0;

	/*
	 * This is a block diagram, which only has the xxv IP.
	 * The BD is created from Board IP list.
	 */
	mac_qsfp u_mac_qsfp (
		.gt_serial_port_0_grx_p	(gt_rxp_in),
		.gt_serial_port_0_grx_n	(gt_rxn_in),
		.gt_serial_port_0_gtx_p	(gt_txp_out),
		.gt_serial_port_0_gtx_n	(gt_txn_out),

		.gt_ref_clk_0_clk_p	(gt_refclk_p),
		.gt_ref_clk_0_clk_n	(gt_refclk_n),
		.gt_refclk_out_0	(gt_refclk_out),

		// RX User Interface Signals
		.rx_clk_out_0		(rx_clk_out_0),
		.rx_axis_tdata		(rx_axis_tdata_0),
		.rx_axis_tkeep		(rx_axis_tkeep_0),
		.rx_axis_tlast		(rx_axis_tlast_0),
		.rx_axis_tuser		(rx_axis_tuser_0),
		.rx_axis_tvalid		(rx_axis_tvalid_0),
		.rx_preambleout_0	(rx_preambleout_0),

		.rx_core_clk_0		(rx_core_clk_0),

		// TX User Interface Signals
		.tx_clk_out_0		(tx_clk_out_0),
		.tx_axis_tdata		(tx_axis_tdata_0),
		.tx_axis_tkeep		(tx_axis_tkeep_0),
		.tx_axis_tlast		(tx_axis_tlast_0),
		.tx_axis_tready		(tx_axis_tready_0),
		.tx_axis_tuser		(tx_axis_tuser_0),
		.tx_axis_tvalid		(tx_axis_tvalid_0),
		.tx_unfout_0		(tx_unfout_0),
		.tx_preamblein_0	(tx_preamblein_0),

		// AXI Lite Slave
		.s_axi_aclk_0		(s_axi_aclk_0),
		.s_axi_aresetn_0	(s_axi_aresetn_0),
		.s_axi_awaddr		(s_axi_awaddr_0),
		.s_axi_awvalid		(s_axi_awvalid_0),
		.s_axi_awready		(s_axi_awready_0),
		.s_axi_wdata		(s_axi_wdata_0),
		.s_axi_wstrb		(s_axi_wstrb_0),
		.s_axi_wvalid		(s_axi_wvalid_0),
		.s_axi_wready		(s_axi_wready_0),
		.s_axi_bresp		(s_axi_bresp_0),
		.s_axi_bvalid		(s_axi_bvalid_0),
		.s_axi_bready		(s_axi_bready_0),
		.s_axi_araddr		(s_axi_araddr_0),
		.s_axi_arvalid		(s_axi_arvalid_0),
		.s_axi_arready		(s_axi_arready_0),
		.s_axi_rdata		(s_axi_rdata_0),
		.s_axi_rresp		(s_axi_rresp_0),
		.s_axi_rvalid		(s_axi_rvalid_0),
		.s_axi_rready		(s_axi_rready_0),

		.rx_reset_0		(rx_reset_0),
		.tx_reset_0		(tx_reset_0),
		.user_rx_reset_0	(user_rx_reset_0),
		.user_tx_reset_0	(user_tx_reset_0),
		.rxrecclkout_0		(rxrecclkout_0),

		.pm_tick_0		(pm_tick_0),
		.user_reg0_0		(user_reg0_0),

		// TX Control Signals
		.ctl_tx_ctl_tx_send_lfi		(ctl_tx_send_lfi_0),
		.ctl_tx_ctl_tx_send_rfi		(ctl_tx_send_rfi_0),
		.ctl_tx_ctl_tx_send_idle	(ctl_tx_send_idle_0),

		.gtwiz_reset_tx_datapath_0	(gtwiz_reset_tx_datapath_0),
		.gtwiz_reset_rx_datapath_0	(gtwiz_reset_rx_datapath_0),
		.gtpowergood_out_0		(gtpowergood_out_0),
		.txoutclksel_in_0		(txoutclksel_in_0),
		.rxoutclksel_in_0		(rxoutclksel_in_0),
		.sys_reset			(sys_reset),
		.dclk				(dclk),

		// RX Stats Signals
		.stat_rx_stat_rx_block_lock		(stat_rx_block_lock_0),
		.stat_rx_stat_rx_framing_err_valid	(stat_rx_framing_err_valid_0),
		.stat_rx_stat_rx_framing_err		(stat_rx_framing_err_0),
		.stat_rx_stat_rx_hi_ber			(stat_rx_hi_ber_0),
		.stat_rx_stat_rx_valid_ctrl_code	(stat_rx_valid_ctrl_code_0),
		.stat_rx_stat_rx_bad_code		(stat_rx_bad_code_0),
		.stat_rx_stat_rx_total_packets		(stat_rx_total_packets_0),
		.stat_rx_stat_rx_total_good_packets	(stat_rx_total_good_packets_0),
		.stat_rx_stat_rx_total_bytes		(stat_rx_total_bytes_0),
		.stat_rx_stat_rx_total_good_bytes	(stat_rx_total_good_bytes_0),
		.stat_rx_stat_rx_packet_small		(stat_rx_packet_small_0),
		.stat_rx_stat_rx_jabber			(stat_rx_jabber_0),
		.stat_rx_stat_rx_packet_large		(stat_rx_packet_large_0),
		.stat_rx_stat_rx_oversize		(stat_rx_oversize_0),
		.stat_rx_stat_rx_undersize		(stat_rx_undersize_0),
		.stat_rx_stat_rx_toolong		(stat_rx_toolong_0),
		.stat_rx_stat_rx_fragment		(stat_rx_fragment_0),
		.stat_rx_stat_rx_packet_64_bytes	(stat_rx_packet_64_bytes_0),
		.stat_rx_stat_rx_packet_65_127_bytes	(stat_rx_packet_65_127_bytes_0),
		.stat_rx_stat_rx_packet_128_255_bytes	(stat_rx_packet_128_255_bytes_0),
		.stat_rx_stat_rx_packet_256_511_bytes	(stat_rx_packet_256_511_bytes_0),
		.stat_rx_stat_rx_packet_512_1023_bytes	(stat_rx_packet_512_1023_bytes_0),
		.stat_rx_stat_rx_packet_1024_1518_bytes	(stat_rx_packet_1024_1518_bytes_0),
		.stat_rx_stat_rx_packet_1519_1522_bytes	(stat_rx_packet_1519_1522_bytes_0),
		.stat_rx_stat_rx_packet_1523_1548_bytes	(stat_rx_packet_1523_1548_bytes_0),
		.stat_rx_stat_rx_bad_fcs		(stat_rx_bad_fcs_0),
		.stat_rx_stat_rx_packet_bad_fcs		(stat_rx_packet_bad_fcs_0),
		.stat_rx_stat_rx_stomped_fcs		(stat_rx_stomped_fcs_0),
		.stat_rx_stat_rx_packet_1549_2047_bytes	(stat_rx_packet_1549_2047_bytes_0),
		.stat_rx_stat_rx_packet_2048_4095_bytes	(stat_rx_packet_2048_4095_bytes_0),
		.stat_rx_stat_rx_packet_4096_8191_bytes	(stat_rx_packet_4096_8191_bytes_0),
		.stat_rx_stat_rx_packet_8192_9215_bytes	(stat_rx_packet_8192_9215_bytes_0),
		.stat_rx_stat_rx_bad_preamble		(stat_rx_bad_preamble_0),
		.stat_rx_stat_rx_bad_sfd		(stat_rx_bad_sfd_0),
		.stat_rx_stat_rx_got_signal_os		(stat_rx_got_signal_os_0),
		.stat_rx_stat_rx_test_pattern_mismatch	(stat_rx_test_pattern_mismatch_0),
		.stat_rx_stat_rx_truncated		(stat_rx_truncated_0),
		.stat_rx_stat_rx_local_fault		(stat_rx_local_fault_0),
		.stat_rx_stat_rx_remote_fault		(stat_rx_remote_fault_0),
		.stat_rx_stat_rx_internal_local_fault	(stat_rx_internal_local_fault_0),
		.stat_rx_stat_rx_received_local_fault	(stat_rx_received_local_fault_0),

		.stat_rx_status_0			(stat_rx_status_0),

		// TX Stats Signals
		.stat_tx_stat_tx_total_packets		(stat_tx_total_packets_0),
		.stat_tx_stat_tx_total_bytes		(stat_tx_total_bytes_0),
		.stat_tx_stat_tx_total_good_packets	(stat_tx_total_good_packets_0),
		.stat_tx_stat_tx_total_good_bytes	(stat_tx_total_good_bytes_0),
		.stat_tx_stat_tx_packet_64_bytes	(stat_tx_packet_64_bytes_0),
		.stat_tx_stat_tx_packet_65_127_bytes	(stat_tx_packet_65_127_bytes_0),
		.stat_tx_stat_tx_packet_128_255_bytes	(stat_tx_packet_128_255_bytes_0),
		.stat_tx_stat_tx_packet_256_511_bytes	(stat_tx_packet_256_511_bytes_0),
		.stat_tx_stat_tx_packet_512_1023_bytes	(stat_tx_packet_512_1023_bytes_0),
		.stat_tx_stat_tx_packet_1024_1518_bytes	(stat_tx_packet_1024_1518_bytes_0),
		.stat_tx_stat_tx_packet_1519_1522_bytes	(stat_tx_packet_1519_1522_bytes_0),
		.stat_tx_stat_tx_packet_1523_1548_bytes	(stat_tx_packet_1523_1548_bytes_0),
		.stat_tx_stat_tx_packet_small		(stat_tx_packet_small_0),
		.stat_tx_stat_tx_packet_large		(stat_tx_packet_large_0),
		.stat_tx_stat_tx_packet_1549_2047_bytes	(stat_tx_packet_1549_2047_bytes_0),
		.stat_tx_stat_tx_packet_2048_4095_bytes	(stat_tx_packet_2048_4095_bytes_0),
		.stat_tx_stat_tx_packet_4096_8191_bytes	(stat_tx_packet_4096_8191_bytes_0),
		.stat_tx_stat_tx_packet_8192_9215_bytes	(stat_tx_packet_8192_9215_bytes_0),
		.stat_tx_stat_tx_bad_fcs		(stat_tx_bad_fcs_0),
		.stat_tx_stat_tx_frame_error		(stat_tx_frame_error_0),
		.stat_tx_stat_tx_local_fault		(stat_tx_local_fault_0)
	);

	// MAC is not taking this tready.
	// This means MAC will just send data unconditionally.
	wire legofpga_from_net_tready;

	LegoFPGA_axis64 u_legofpag (
		.clk_125		(),
		.clk_125_rst_n		(),

		.mac_ready		(mac_ready),

		.from_net_clk_390	(rx_clk_out_0),
		.from_net_clk_390_rst_n	(~user_rx_reset_0),

		.from_net_tvalid	(rx_axis_tvalid_0),
		.from_net_tready	(legofpga_from_net_tready),
		.from_net_tdata		(rx_axis_tdata_0),
		.from_net_tkeep		(rx_axis_tkeep_0),
		.from_net_tuser		(rx_axis_tuser_0),
		.from_net_tlast		(rx_axis_tlast_0),

		.to_net_clk_390		(tx_clk_out_0),
		.to_net_clk_390_rst_n	(~user_tx_reset_0),

		.to_net_tvalid		(tx_axis_tvalid_0),
		.to_net_tready		(tx_axis_tready_0),
		.to_net_tdata		(tx_axis_tdata_0),
		.to_net_tuser		(tx_axis_tuser_0),
		.to_net_tlast		(tx_axis_tlast_0),
		.to_net_tkeep		(tx_axis_tkeep_0)
	);

	/*
	 * State machine and AXI4 Lite controller
	 * Prepare the MAC for data transmitting.
	 */
	mac_qsfp_sm u_mac_qsfp_sm (
		.dclk			(dclk),
		.sys_reset		(sys_reset),

		.fsm_out_pktgen_enable	(fsm_out_pktgen_enable),
		.fsm_out_sys_reset	(fsm_out_sys_reset),

		// User Interface signals
		.completion_status	(completion_status),
		.rx_gt_locked_led	(rx_gt_locked_led_0),
		.rx_block_lock_led	(block_lock_led_0),

		// RX AXIS Related
		.mon_clk		(rx_clk_out_0),
		.rx_preambleout		(rx_preambleout_0),
		.rx_reset		(rx_reset_0),
		.user_rx_reset		(user_rx_reset_0),

		// TX AXIS
		.gen_clk		(tx_clk_out_0),
		.tx_preamblein		(tx_preamblein_0),
		.user_tx_reset		(user_tx_reset_0),
		.tx_reset		(tx_reset_0),
		.tx_unfout		(tx_unfout_0),

		// TX Control Signals
		.ctl_tx_send_lfi	(ctl_tx_send_lfi_0),
		.ctl_tx_send_rfi	(ctl_tx_send_rfi_0),
		.ctl_tx_send_idle	(ctl_tx_send_idle_0),

		// AXI4 Lite Interface Signals
		.s_axi_aclk (s_axi_aclk_0),
		.s_axi_aresetn (s_axi_aresetn_0),
		.s_axi_awaddr (s_axi_awaddr_0),
		.s_axi_awvalid (s_axi_awvalid_0),
		.s_axi_awready (s_axi_awready_0),
		.s_axi_wdata (s_axi_wdata_0),
		.s_axi_wstrb (s_axi_wstrb_0),
		.s_axi_wvalid (s_axi_wvalid_0),
		.s_axi_wready (s_axi_wready_0),
		.s_axi_bresp (s_axi_bresp_0),
		.s_axi_bvalid (s_axi_bvalid_0),
		.s_axi_bready (s_axi_bready_0),
		.s_axi_araddr (s_axi_araddr_0),
		.s_axi_arvalid (s_axi_arvalid_0),
		.s_axi_arready (s_axi_arready_0),
		.s_axi_rdata (s_axi_rdata_0),
		.s_axi_rresp (s_axi_rresp_0),
		.s_axi_rvalid (s_axi_rvalid_0),
		.s_axi_rready (s_axi_rready_0),
		.pm_tick (pm_tick_0),

		// RX Stats Signals
		.stat_rx_block_lock (stat_rx_block_lock_0),
		.stat_rx_framing_err_valid (stat_rx_framing_err_valid_0),
		.stat_rx_framing_err (stat_rx_framing_err_0),
		.stat_rx_hi_ber (stat_rx_hi_ber_0),
		.stat_rx_valid_ctrl_code (stat_rx_valid_ctrl_code_0),
		.stat_rx_bad_code (stat_rx_bad_code_0),
		.stat_rx_total_packets (stat_rx_total_packets_0),
		.stat_rx_total_good_packets (stat_rx_total_good_packets_0),
		.stat_rx_total_bytes (stat_rx_total_bytes_0),
		.stat_rx_total_good_bytes (stat_rx_total_good_bytes_0),
		.stat_rx_packet_small (stat_rx_packet_small_0),
		.stat_rx_jabber (stat_rx_jabber_0),
		.stat_rx_packet_large (stat_rx_packet_large_0),
		.stat_rx_oversize (stat_rx_oversize_0),
		.stat_rx_undersize (stat_rx_undersize_0),
		.stat_rx_toolong (stat_rx_toolong_0),
		.stat_rx_fragment (stat_rx_fragment_0),
		.stat_rx_packet_64_bytes (stat_rx_packet_64_bytes_0),
		.stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes_0),
		.stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes_0),
		.stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes_0),
		.stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes_0),
		.stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes_0),
		.stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes_0),
		.stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes_0),
		.stat_rx_bad_fcs (stat_rx_bad_fcs_0),
		.stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs_0),
		.stat_rx_stomped_fcs (stat_rx_stomped_fcs_0),
		.stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes_0),
		.stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes_0),
		.stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes_0),
		.stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes_0),
		.stat_rx_bad_preamble (stat_rx_bad_preamble_0),
		.stat_rx_bad_sfd (stat_rx_bad_sfd_0),
		.stat_rx_got_signal_os (stat_rx_got_signal_os_0),
		.stat_rx_test_pattern_mismatch (stat_rx_test_pattern_mismatch_0),
		.stat_rx_truncated (stat_rx_truncated_0),
		.stat_rx_local_fault (stat_rx_local_fault_0),
		.stat_rx_remote_fault (stat_rx_remote_fault_0),
		.stat_rx_internal_local_fault (stat_rx_internal_local_fault_0),
		.stat_rx_received_local_fault (stat_rx_received_local_fault_0),

		// TX Stats Signals
		.stat_tx_total_packets (stat_tx_total_packets_0),
		.stat_tx_total_bytes (stat_tx_total_bytes_0),
		.stat_tx_total_good_packets (stat_tx_total_good_packets_0),
		.stat_tx_total_good_bytes (stat_tx_total_good_bytes_0),
		.stat_tx_packet_64_bytes (stat_tx_packet_64_bytes_0),
		.stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes_0),
		.stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes_0),
		.stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes_0),
		.stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes_0),
		.stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes_0),
		.stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes_0),
		.stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes_0),
		.stat_tx_packet_small (stat_tx_packet_small_0),
		.stat_tx_packet_large (stat_tx_packet_large_0),
		.stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes_0),
		.stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes_0),
		.stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes_0),
		.stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes_0),
		.stat_tx_bad_fcs (stat_tx_bad_fcs_0),
		.stat_tx_frame_error (stat_tx_frame_error_0),
		.stat_tx_local_fault (stat_tx_local_fault_0)
	);

endmodule

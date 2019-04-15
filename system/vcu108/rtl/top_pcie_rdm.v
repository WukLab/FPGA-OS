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
 *
 * Reference:
 * 	- PG210: 10G/25G High Speed Ethernet Subsystem.
 */

`timescale 1fs/1fs

(* DowngradeIPIdentifiedWarnings="yes" *)
module legofpga_pcie_rdm #
(
	parameter PL_LINK_CAP_MAX_LINK_WIDTH          = 8,            // 1- X1; 2 - X2; 4 - X4; 8 - X8
	parameter PL_SIM_FAST_LINK_TRAINING           = "FALSE",      // Simulation Speedup
	parameter PL_LINK_CAP_MAX_LINK_SPEED          = 4,             // 1- GEN1; 2 - GEN2; 4 - GEN3
	parameter C_DATA_WIDTH                        = 256 ,
	parameter EXT_PIPE_SIM                        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
	parameter C_ROOT_PORT                         = "FALSE",      // PCIe block is in root port mode
	parameter C_DEVICE_NUMBER                     = 0,            // Device number for Root Port configurations only
	parameter AXIS_CCIX_RX_TDATA_WIDTH     = 256,
	parameter AXIS_CCIX_TX_TDATA_WIDTH     = 256,
	parameter AXIS_CCIX_RX_TUSER_WIDTH     = 46,
	parameter AXIS_CCIX_TX_TUSER_WIDTH     = 46
)
(
	/* Board Clock */
	input	pcie_dedicated_100_clk_p,
	input	pcie_dedicated_100_clk_n,
	input	default_sysclk_125_clk_n,
	input	default_sysclk_125_clk_p,
	input	default_sysclk_300_clk_n,
	input	default_sysclk_300_clk_p,

	/* reset */
	input	sys_rst_n,
	output	user_lnk_up,

	/* PCIE Interface */
	output	[(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txp,
	output	[(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txn,
	input	[(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxp,
	input	[(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxn,

	output ddr4_sdram_c1_act_n,
	output [16:0]ddr4_sdram_c1_adr,
	output [1:0]ddr4_sdram_c1_ba,
	output ddr4_sdram_c1_bg,
	output ddr4_sdram_c1_ck_c,
	output ddr4_sdram_c1_ck_t,
	output ddr4_sdram_c1_cke,
	output ddr4_sdram_c1_cs_n,
	inout [7:0]ddr4_sdram_c1_dm_n,
	inout [63:0]ddr4_sdram_c1_dq,
	inout [7:0]ddr4_sdram_c1_dqs_c,
	inout [7:0]ddr4_sdram_c1_dqs_t,
	output ddr4_sdram_c1_odt,
	output ddr4_sdram_c1_reset_n
);

   /* keep all the parameter compliant with Xilinx PCIE testbench */
   // Local Parameters derived from user selection
   localparam integer   USER_CLK_FREQ       = ((PL_LINK_CAP_MAX_LINK_SPEED == 3'h4) ? 5 : 4);
   localparam           TCQ                 = 1;
   localparam           C_S_AXI_ID_WIDTH    = 4;
   localparam           C_M_AXI_ID_WIDTH    = 4;
   localparam           C_S_AXI_DATA_WIDTH  = C_DATA_WIDTH;
   localparam           C_M_AXI_DATA_WIDTH  = C_DATA_WIDTH;
   localparam           C_S_AXI_ADDR_WIDTH  = 64;
   localparam           C_M_AXI_ADDR_WIDTH  = 64;
   localparam           C_NUM_USR_IRQ       = 1;

	// AXI streaming ports
	wire                      m_axis_h2c_tvalid_0;
	wire                      m_axis_h2c_tready_0;
	wire [C_DATA_WIDTH-1:0]   m_axis_h2c_tdata_0;
	wire [C_DATA_WIDTH/8-1:0] m_axis_h2c_tkeep_0;
	wire                      m_axis_h2c_tlast_0;

	wire                      s_axis_c2h_tvalid_0;
	wire                      s_axis_c2h_tready_0;
	wire [C_DATA_WIDTH-1:0]   s_axis_c2h_tdata_0;
	wire [C_DATA_WIDTH/8-1:0] s_axis_c2h_tkeep_0;
	wire                      s_axis_c2h_tlast_0;

	// pcie unused signals
	reg [C_NUM_USR_IRQ-1:0]   usr_irq_req = 0;
	wire [C_NUM_USR_IRQ-1:0]  usr_irq_ack;

	// reset Signals
	wire user_resetn_250;
	wire _sys_reset, sys_reset;
	wire clk_125_rst_n;
	wire sys_rst_n_c;

	// clocks
	wire user_clk_250;
	wire dclk, clk_100, clk_125, clk_150, clk_locked;
	wire pcie_clk, pcie_clk_gt;

	/* 100MHZ is used in the reference design */
	assign dclk = clk_100;
	assign _sys_reset = ~clk_locked;

	/*
	 * sys_reset is issued when clock is ready.
	 * sys_reset is sent to MAC layer only.
	 */
	user_cdc_sync u_sync_reset (
		.clk                 (dclk),
		.signal_in           (_sys_reset),
		.signal_out          (sys_reset)
	);

	user_cdc_sync u_sync_clk_125_rst_N (
		.clk                 (clk_125),
		.signal_in           (user_resetn_250),
		.signal_out          (clk_125_rst_n)
	);

	clock_mac_qsfp u_clock_gen (
		/* Input: Board Clock */
		.default_sysclk_125_clk_n    (default_sysclk_125_clk_n),
		.default_sysclk_125_clk_p    (default_sysclk_125_clk_p),

		/* Ouputs */
		.clk_100        (clk_100),
		.clk_125        (clk_125),
		.clk_150        (clk_150),
		.clk_locked        (clk_locked)
	);

	// PCIE Ref clock buffer
	IBUFDS_GTE3 # (.REFCLK_HROW_CK_SEL(2'b00))
	refclk_ibuf (
		.O(pcie_clk_gt),
		.ODIV2(pcie_clk),
		.I(pcie_dedicated_100_clk_p),
		.CEB(1'b0),
		.IB(pcie_dedicated_100_clk_n)
	);
	// PCIE Reset buffer
	IBUF
	sys_reset_n_ibuf (
		.O(sys_rst_n_c),
		.I(sys_rst_n)
	);

	pcie u_pcie (
		.sys_rst_n          (sys_rst_n_c),
		.sys_clk            (pcie_clk),
		.sys_clk_gt         (pcie_clk_gt),

		// PCIE interface
		.pcie_mgt_txn       (pci_exp_txn),
		.pcie_mgt_txp       (pci_exp_txp),
		.pcie_mgt_rxn		(pci_exp_rxn),
		.pcie_mgt_rxp		(pci_exp_rxp),

		// AXI streaming ports
		.S_AXIS_C2H_tdata(s_axis_c2h_tdata_0),
		.S_AXIS_C2H_tlast(s_axis_c2h_tlast_0),
		.S_AXIS_C2H_tvalid(s_axis_c2h_tvalid_0),
		.S_AXIS_C2H_tready(s_axis_c2h_tready_0),
		.S_AXIS_C2H_tkeep(s_axis_c2h_tkeep_0),
		.M_AXIS_H2C_tdata(m_axis_h2c_tdata_0),
		.M_AXIS_H2C_tlast(m_axis_h2c_tlast_0),
		.M_AXIS_H2C_tvalid(m_axis_h2c_tvalid_0),
		.M_AXIS_H2C_tready(m_axis_h2c_tready_0),
		.M_AXIS_H2C_tkeep(m_axis_h2c_tkeep_0),

		// unused
		.usr_irq_req       (usr_irq_req),
		.usr_irq_ack       (usr_irq_ack),

		//---------- Shared Logic Internal -------------------------
		// unused
		.pcie3_us_int_shared_logic_ints_qpll1lock_out          (),
		.pcie3_us_int_shared_logic_ints_qpll1outrefclk_out     (),
		.pcie3_us_int_shared_logic_ints_qpll1outclk_out        (),

		//-- AXI Global
		.axi_aclk        (user_clk_250),
		.axi_aresetn     (user_resetn_250),

		.user_lnk_up     (user_lnk_up)
	);

	/*
	 * Applications
	 * originally design is for MAC, later changed to PCIE
	 * so user reset and clock interface may look weird
	 */
	LegoFPGA_axis64 u_LegoFPGA (
		.sys_rst                (sys_reset),

		.clk_125                (clk_125),
		.clk_125_rst_n          (clk_125_rst_n),

		// For MC
		.C0_SYS_CLK_0_clk_n     (default_sysclk_300_clk_n),
		.C0_SYS_CLK_0_clk_p     (default_sysclk_300_clk_p),

		// AXI reset & clock from PCIE
		.from_net_clk_390       (user_clk_250),
		.from_net_clk_390_rst_n (user_resetn_250),
		.to_net_clk_390         (user_clk_250),
		.to_net_clk_390_rst_n   (user_resetn_250),

		// PCIE ready
		.mac_ready(user_lnk_up),

		// Data from PCIE
		.from_net_tvalid        (m_axis_h2c_tvalid_0),
		.from_net_tready        (m_axis_h2c_tready_0),
		.from_net_tdata         (m_axis_h2c_tdata_0),
		.from_net_tkeep         (m_axis_h2c_tkeep_0),
		.from_net_tlast         (m_axis_h2c_tlast_0),

		// Data to PCIE
		.to_net_tvalid          (s_axis_c2h_tvalid_0),
		.to_net_tready          (s_axis_c2h_tready_0),
		.to_net_tdata           (s_axis_c2h_tdata_0),
		.to_net_tkeep           (s_axis_c2h_tkeep_0),
		.to_net_tlast           (s_axis_c2h_tlast_0),

		// DDR4 interface
		.ddr4_sdram_c1_act_n    (ddr4_sdram_c1_act_n),
		.ddr4_sdram_c1_adr      (ddr4_sdram_c1_adr),
		.ddr4_sdram_c1_ba       (ddr4_sdram_c1_ba),
		.ddr4_sdram_c1_bg       (ddr4_sdram_c1_bg),
		.ddr4_sdram_c1_ck_c     (ddr4_sdram_c1_ck_c),
		.ddr4_sdram_c1_ck_t     (ddr4_sdram_c1_ck_t),
		.ddr4_sdram_c1_cke      (ddr4_sdram_c1_cke),
		.ddr4_sdram_c1_cs_n     (ddr4_sdram_c1_cs_n),
		.ddr4_sdram_c1_dm_n     (ddr4_sdram_c1_dm_n),
		.ddr4_sdram_c1_dq       (ddr4_sdram_c1_dq),
		.ddr4_sdram_c1_dqs_c    (ddr4_sdram_c1_dqs_c),
		.ddr4_sdram_c1_dqs_t    (ddr4_sdram_c1_dqs_t),
		.ddr4_sdram_c1_odt      (ddr4_sdram_c1_odt),
		.ddr4_sdram_c1_reset_n  (ddr4_sdram_c1_reset_n)
	);

endmodule

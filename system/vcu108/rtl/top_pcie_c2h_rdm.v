/*
 * Copyright (c) 2019, Wuklab, UCSD. All rights reserved.
 * Target board: Xilinx VCU108.
 */

`timescale 1fs/1fs

module top_pcie_c2h_RDM #
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
	input	default_sysclk2_300_clk_n,
        input   default_sysclk2_300_clk_p,

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
	wire clk_150_rst_n;
	wire clk_300_rst_n;
	wire sys_rst_n_c;

	// clocks
	wire user_clk_250;
	wire clk_100, clk_125, clk_150, clk_300, clk_locked, clk_300_locked;
	wire pcie_clk, pcie_clk_gt;

	clock_sysclk u_clock_gen (
		/* Input: Board Clock */
		.default_sysclk_125_clk_n    (default_sysclk_125_clk_n),
		.default_sysclk_125_clk_p    (default_sysclk_125_clk_p),

		/* Ouputs */
		.clk_100        (clk_100),
		.clk_125        (clk_125),
		.clk_150        (clk_150),
		.clk_locked     (clk_locked)
	);

        sys_clock_300 u_clock_300 (
                .default_sysclk2_300_clk_n      (default_sysclk2_300_clk_n),
                .default_sysclk2_300_clk_p      (default_sysclk2_300_clk_p),
                .clk_300                        (clk_300),
                .clk_300_locked                 (clk_300_locked)
        );

	assign _sys_reset = ~clk_locked;

	/*
	 * sys_reset (ACTIVE_HIGH) is issued when clock is ready.
	 * This is issued to MC only.
	 */
	user_cdc_sync u_sync_reset (
		.clk                 (clk_100),
		.signal_in           (_sys_reset),
		.signal_out          (sys_reset)
	);

	/*
	 * user_resetn_250 comes from PCIe.
	 * Use it as the driving reset for others
	 * All of them are ACTIVE_LOW.
	 */
	user_cdc_sync u_sync_clk_300_rst_N (
                .clk                 (clk_300),
                .signal_in           (user_resetn_250),
                .signal_out          (clk_300_rst_n)
        );	

	user_cdc_sync u_sync_clk_150_rst_N (
		.clk                 (clk_150),
		.signal_in           (user_resetn_250),
		.signal_out          (clk_150_rst_n)
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

	reg dsc_bypass_c2h_dsc_byp_load;
	wire dsc_bypass_c2h_dsc_byp_ready;

	always @ (posedge user_clk_250) begin
		if (!user_resetn_250) begin
			dsc_bypass_c2h_dsc_byp_load <= 1'b0;
		end else begin
			if (dsc_bypass_c2h_dsc_byp_ready) begin
				dsc_bypass_c2h_dsc_byp_load <= 1'b1;
			end else begin
				dsc_bypass_c2h_dsc_byp_load <= 1'b0;
			end
		end
	end

	pcie_c2h_bypass u_pcie (
		.sys_rst_n	(sys_rst_n_c),
		.sys_clk	(pcie_clk),
		.sys_clk_gt	(pcie_clk_gt),

		// PCIe interface
		.pcie_mgt_txn	(pci_exp_txn),
		.pcie_mgt_txp	(pci_exp_txp),
		.pcie_mgt_rxn	(pci_exp_rxn),
		.pcie_mgt_rxp	(pci_exp_rxp),

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

		// Descriptor Bypass
		// dst_addr should have been reserved via memmap
		.dsc_bypass_c2h_dsc_byp_dst_addr	(64'h100000000),
		.dsc_bypass_c2h_dsc_byp_src_addr	(64'h0),
		.dsc_bypass_c2h_dsc_byp_len		(28'h1000),
		.dsc_bypass_c2h_dsc_byp_ctl		(16'h0),
		.dsc_bypass_c2h_dsc_byp_ready		(dsc_bypass_c2h_dsc_byp_ready),
		.dsc_bypass_c2h_dsc_byp_load		(dsc_bypass_c2h_dsc_byp_load),

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

	LegoFPGA_RDM_for_pcie_raw
	u_LegoFPGA (
		// MC clock
		.C0_SYS_CLK_0_clk_n     (default_sysclk_300_clk_n),
		.C0_SYS_CLK_0_clk_p     (default_sysclk_300_clk_p),

		// MC reset
		.sys_rst	(sys_reset),

		.driver_ready	(user_lnk_up),

		.clk_150	(clk_150),
		.clk_300	(clk_300),
		.clk_300_rst_n	(clk_300_rst_n),

		// AXIS reset & clock from PCIe
		.RX_clk		(user_clk_250),
		.TX_clk		(user_clk_250),
		.RX_rst_n	(user_resetn_250),
		.TX_rst_n	(user_resetn_250),

		// From PCIe to KVS
		.RX_tvalid	(m_axis_h2c_tvalid_0),
		.RX_tready	(m_axis_h2c_tready_0),
		.RX_tdata	(m_axis_h2c_tdata_0),
		.RX_tkeep	(m_axis_h2c_tkeep_0),
		.RX_tlast	(m_axis_h2c_tlast_0),

		// From KVS to PCIe
		.TX_tvalid	(s_axis_c2h_tvalid_0),
		.TX_tready	(s_axis_c2h_tready_0),
		.TX_tdata	(s_axis_c2h_tdata_0),
		.TX_tkeep	(s_axis_c2h_tkeep_0),
		.TX_tlast	(s_axis_c2h_tlast_0),

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

/*
 * The xdma_app was originall ported from the xdma example design
 * I modified it a little bit to always send out packet to PCIe.
 * It was used to test c2h descriptor bypass.
 */

/*

  // XDMA taget application
  xdma_app #(
    .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH)
  ) xdma_app_i (
      // AXI streaming ports
      .s_axis_c2h_tdata_0(s_axis_c2h_tdata_0),  
      .s_axis_c2h_tlast_0(s_axis_c2h_tlast_0),
      .s_axis_c2h_tvalid_0(s_axis_c2h_tvalid_0), 
      .s_axis_c2h_tready_0(s_axis_c2h_tready_0),
      .s_axis_c2h_tkeep_0(s_axis_c2h_tkeep_0),
      .m_axis_h2c_tdata_0(m_axis_h2c_tdata_0),
      .m_axis_h2c_tlast_0(m_axis_h2c_tlast_0),
      .m_axis_h2c_tvalid_0(m_axis_h2c_tvalid_0),
      .m_axis_h2c_tready_0(m_axis_h2c_tready_0),
      .m_axis_h2c_tkeep_0(m_axis_h2c_tkeep_0),


      .user_clk(user_clk_250),
      .user_resetn(user_resetn_250),
      .user_lnk_up(user_lnk_up)
  );

 */

/*
module xdma_app #(
  parameter TCQ                         = 1,
  parameter C_M_AXI_ID_WIDTH            = 4,
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 8,
  parameter C_DATA_WIDTH                = 256,
  parameter C_M_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_RQ_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 137 : 62),
  parameter C_S_AXIS_CQP_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 183 : 88),
  parameter C_M_AXIS_RC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 161 : 75),
  parameter C_S_AXIS_CC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ?  81 : 33),
  parameter C_S_KEEP_WIDTH              = C_S_AXI_DATA_WIDTH / 32,
  parameter C_M_KEEP_WIDTH              = (C_M_AXI_DATA_WIDTH / 32),
  parameter C_XDMA_NUM_CHNL             = 1
)
(


//VU9P_TUL_EX_String= FALSE


      // AXI streaming ports
    output reg [C_DATA_WIDTH-1:0] s_axis_c2h_tdata_0,  
    output reg s_axis_c2h_tlast_0,
    output reg s_axis_c2h_tvalid_0,
    input  wire s_axis_c2h_tready_0,
    output reg [C_DATA_WIDTH/8-1:0] s_axis_c2h_tkeep_0,
    input  wire [C_DATA_WIDTH-1:0] m_axis_h2c_tdata_0,
    input  wire m_axis_h2c_tlast_0,
    input  wire m_axis_h2c_tvalid_0,
    output wire m_axis_h2c_tready_0,
    input  wire [C_DATA_WIDTH/8-1:0] m_axis_h2c_tkeep_0,

  // System IO signals
  input  wire         user_resetn,
 
  input  wire         user_clk,
  input  wire		user_lnk_up

);

  reg [31:0] nr_packets = 32'h10000;
  reg [31:0] nr_units = 32'h10;
  

  assign m_axis_h2c_tready_0 = 1'b1;

  always @(posedge user_clk) begin
    if (user_lnk_up && s_axis_c2h_tready_0 && nr_packets) begin
    //if (nr_packets) begin
     
        if (nr_units) begin
          s_axis_c2h_tdata_0 <= 256'h66;
          s_axis_c2h_tvalid_0 <= 1'b1;
          s_axis_c2h_tkeep_0 <= 32'hffffffff;
          s_axis_c2h_tlast_0 <= 32'b0;
          nr_units <= nr_units - 1'b1;
        end else begin
          s_axis_c2h_tdata_0 <= 256'h67;
          s_axis_c2h_tvalid_0 <= 1'b1;
          s_axis_c2h_tkeep_0 <= 32'hffffffff;
          s_axis_c2h_tlast_0 <= 32'b1;
          
          nr_units <= 32'h07;
          nr_packets <= nr_packets - 1'b1;
        end

    
    end else begin
          s_axis_c2h_tdata_0 <= 256'b0;
          s_axis_c2h_tvalid_0 <= 1'b0;
          s_axis_c2h_tkeep_0 <= 32'h0;
          s_axis_c2h_tlast_0 <= 32'b0;
    end
  end


endmodule
*/

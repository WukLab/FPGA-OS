/*
 * YS:
 * -  The original tb is not doing too much work.
 *    Majority of the work is done by the pkt_mon module.
 * -  This tb is not using gt to send any data, it will
 *    loopback whatever sent out from MAC. Shame.
 */

`define SIM_SPEED_UP

`timescale 1fs/1fs

module legofpga_mac_qsfp_ddr4_tb
(
);
	reg             sys_reset;
	wire [1-1:0] gt_txp_out;
	wire [1-1:0] gt_txn_out;
	wire            rx_gt_locked_led_0;
	wire            rx_block_lock_led_0;

    wire         sysclk_125_clk_n;
	wire         sysclk_125_clk_p;
	wire         sysclk_161_clk_n;
	wire         sysclk_161_clk_p;

    wire	default_sysclk_300_clk_p;
	wire	default_sysclk_300_clk_n;

    reg         sysclk_125_clk_ref;
    reg         sysclk_300_clk_ref;
    reg         sysclk_161_clk_ref;

    wire        ddr4_act_n;
    wire [16:0] ddr4_adr;
    wire [1:0]  ddr4_ba;
    wire        ddr4_bg;
    wire        ddr4_ck_c;
    wire        ddr4_ck_t;
    wire        ddr4_cke;
    wire        ddr4_cs_n;
    wire [7:0]  ddr4_dm_n;
    wire [63:0] ddr4_dq;
    wire [7:0]  ddr4_dqs_c;
    wire [7:0]  ddr4_dqs_t;
    wire        ddr4_odt;
    wire        ddr4_reset_n;

	legofpga_mac_qsfp	DUT (
		.default_sysclk_125_clk_n	(sysclk_125_clk_n),
		.default_sysclk_125_clk_p	(sysclk_125_clk_p),
		.default_sysclk_161_clk_n	(sysclk_161_clk_n),
		.default_sysclk_161_clk_p	(sysclk_161_clk_p),
		.default_sysclk_300_clk_n	(default_sysclk_300_clk_n),
		.default_sysclk_300_clk_p	(default_sysclk_300_clk_p),

		.gt_rxp_in			(gt_txp_out),
		.gt_rxn_in			(gt_txn_out),
		.gt_txp_out			(gt_txp_out),
		.gt_txn_out			(gt_txn_out),

		.rx_gt_locked_led_0		(rx_gt_locked_led_0),
		.rx_block_lock_led_0		(rx_block_lock_led_0),
        
        /* DRAM interface */ 
        .ddr4_sdram_c1_act_n          (ddr4_act_n),
        .ddr4_sdram_c1_adr	          (ddr4_adr),
        .ddr4_sdram_c1_ba	          (ddr4_ba),
        .ddr4_sdram_c1_bg	          (ddr4_bg),
        .ddr4_sdram_c1_ck_c	          (ddr4_ck_c),
        .ddr4_sdram_c1_ck_t	          (ddr4_ck_t),
        .ddr4_sdram_c1_cke	          (ddr4_cke),
        .ddr4_sdram_c1_cs_n	          (ddr4_cs_n),
        .ddr4_sdram_c1_dm_n	          (ddr4_dm_n),
        .ddr4_sdram_c1_dq	          (ddr4_dq),
        .ddr4_sdram_c1_dqs_c          (ddr4_dqs_c),
        .ddr4_sdram_c1_dqs_t          (ddr4_dqs_t),
        .ddr4_sdram_c1_odt	          (ddr4_odt),
        .ddr4_sdram_c1_reset_n        (ddr4_reset_n)
	);
    
    ddr4_tb_top MEM_MODEL (
        .c0_ddr4_act_n            (ddr4_act_n),
        .c0_ddr4_adr              (ddr4_adr),
        .c0_ddr4_ba               (ddr4_ba),
        .c0_ddr4_bg               (ddr4_bg),
        .c0_ddr4_ck_c_int         (ddr4_ck_c),
        .c0_ddr4_ck_t_int         (ddr4_ck_t),
        .c0_ddr4_cke              (ddr4_cke),
        .c0_ddr4_cs_n             (ddr4_cs_n),
        .c0_ddr4_dm_dbi_n         (ddr4_dm_n),
        .c0_ddr4_dq               (ddr4_dq),
        .c0_ddr4_dqs_c            (ddr4_dqs_c),
        .c0_ddr4_dqs_t            (ddr4_dqs_t),
        .c0_ddr4_odt              (ddr4_odt),
        .c0_ddr4_reset_n          (ddr4_reset_n)
    );


    initial
    begin
    `ifdef SIM_SPEED_UP
    `else
      $display("****************");
      $display("INFO : Simulation time may be longer. For faster simulation, please use SIM_SPEED_UP option. For more information refer product guide.");
      $display("****************");
    `endif
    
      sysclk_300_clk_ref = 1;
      sysclk_161_clk_ref = 1;
      sysclk_125_clk_ref = 1;

      // One lock
      $display("INFO : waiting for the gt lock..........");
      wait(rx_gt_locked_led_0);
      $display("INFO : GT LOCKED");

      // One lock
      $display("INFO : WAITING FOR rx_block_lock..........");
      wait(rx_block_lock_led_0);
      $display("INFO : CORE 25GE rx block locked");

      //
      // Having above two signals asserted is not enough.
      // We should use the `mac_ready` as the green light.
      // Once `mac_ready` is asserted, this TB can send stuff.
      // `mac_ready` is in top_mac_qsfp.c, not exported now.
      //

      $display("TB idle.");
      repeat(12)
        #8_00_000_000;

    end
        
    always
        #3103030.303 sysclk_161_clk_ref = ~sysclk_161_clk_ref;
        
    always
        #1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;
        
    always
        #4000000.000 sysclk_125_clk_ref = ~sysclk_125_clk_ref;

    assign sysclk_161_clk_p         = sysclk_161_clk_ref;
    assign default_sysclk_300_clk_p = sysclk_300_clk_ref;
    assign sysclk_125_clk_p         = sysclk_125_clk_ref;

    assign sysclk_161_clk_n         = ~sysclk_161_clk_ref;
    assign default_sysclk_300_clk_n = ~sysclk_300_clk_ref;
    assign sysclk_125_clk_n         = ~sysclk_125_clk_ref;

endmodule

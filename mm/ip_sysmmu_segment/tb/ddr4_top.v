`timescale 1fs/1fs

module sysmmu_tb_top;

// 390MHZ for network
parameter CLK_PERIOD = 2560000;
parameter TIMEOUT_THRESH = 100000000;

	wire		default_sysclk_300_clk_p;
	wire		default_sysclk_300_clk_n;

	reg         	sysclk_125_clk_ref;
	reg         	sysclk_300_clk_ref;
	reg         	sysclk_390_clk_ref;

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

	reg             sys_reset;
	reg		sysclk_125_rst_n;
	reg		sysclk_390_rst_n;

	reg [63:0] tx_tdata;
	reg [7:0] tx_tkeep;
	reg [63:0] tx_tuser;
	reg tx_tvalid;
	reg tx_tlast;
	wire tx_tready;

	wire [63:0] rx_tdata;
	wire [7:0] rx_tkeep;
	wire [63:0] rx_tuser;
	wire rx_tvalid;
	wire rx_tlast;
	reg rx_tready;

	wire [159:0] s_axi_check;
	wire [159:0] m_axi_check;
	wire s_axi_check_vld;
    wire m_axi_check_vld;

	wire mc_init_calib_complete;
	//wire mc_ddr4_ui_clk_rst_n;

	reg start_tg, stop_tg;

	sys_mm_tb_wrapper DUT (
		// DDR4 MC
		.C0_SYS_CLK_0_clk_n		(default_sysclk_300_clk_n),
		.C0_SYS_CLK_0_clk_p		(default_sysclk_300_clk_p),

		.mc_init_calib_complete		(mc_init_calib_complete),

		.sys_rst			(sys_reset),

		/* DRAM interface */
		.ddr4_sdram_c1_act_n          (ddr4_act_n),
		.ddr4_sdram_c1_adr	      (ddr4_adr),
		.ddr4_sdram_c1_ba	      (ddr4_ba),
		.ddr4_sdram_c1_bg	      (ddr4_bg),
		.ddr4_sdram_c1_ck_c	      (ddr4_ck_c),
		.ddr4_sdram_c1_ck_t	      (ddr4_ck_t),
		.ddr4_sdram_c1_cke	      (ddr4_cke),
		.ddr4_sdram_c1_cs_n	      (ddr4_cs_n),
		.ddr4_sdram_c1_dm_n	      (ddr4_dm_n),
		.ddr4_sdram_c1_dq	      (ddr4_dq),
		.ddr4_sdram_c1_dqs_c          (ddr4_dqs_c),
		.ddr4_sdram_c1_dqs_t          (ddr4_dqs_t),
		.ddr4_sdram_c1_odt	      (ddr4_odt),
		.ddr4_sdram_c1_reset_n        (ddr4_reset_n),

		.ctrl_tdata ('b0),
        .ctrl_tready (),
        .ctrl_tvalid (1'b0),
        .ctrl_stat_tdata (),
        .ctrl_stat_tready (1'b1),
        .ctrl_stat_tvalid (),

        .pc_status_0 (m_axi_check),
        .pc_asserted_0 (m_axi_check_vld),
        .pc_status_1 (s_axi_check),
        .pc_asserted_1 (s_axi_check_vld),

        .core_ext_start_0 (start_tg)
        //.core_ext_stop_0  (stop_tg)

	);

	ddr4_tb_top ddr4_mem_model (
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
		.c0_ddr4_reset_n          (ddr4_reset_n),
		.model_enable_in(1'b1)
	);

	// Generate reset signals
	initial begin
	    start_tg = 0;
		sysclk_300_clk_ref = 1;

		// Reset MC
		sys_reset = 1'b0;
	    #CLK_PERIOD;
	    sys_reset = 1'b1;
	    #(CLK_PERIOD*10);
	        sys_reset = 1'b0;
		#(CLK_PERIOD*4);

		// Wait until MC is ready
		wait(mc_init_calib_complete == 1'b1);
		//wait(DUT.mc_ddr4_ui_clk_rst_n == 1'b1);

		//#50000000
		#5000000
		start_tg = 1'b1;
	end

	// Clock generation
	always
		#1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;

	assign default_sysclk_300_clk_p = sysclk_300_clk_ref;
	assign default_sysclk_300_clk_n = ~sysclk_300_clk_ref;


endmodule

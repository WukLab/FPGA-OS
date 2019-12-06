`timescale 1fs/1fs

module libmm_tb_top;

parameter CLK_PERIOD = 3333333;

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

	reg sysclk_300_clk_ref;
	reg sys_reset;

	wire mc_ddr4_ui_clk_rst_n;
	wire mc_init_calib_complete;
	reg mc_enable_model;
	reg enable_send;

	reg [39:0]ctrl_in_tdata;
	wire ctrl_in_tready;
	reg ctrl_in_tvalid;

	wire [39:0]ctrl_out_tdata;
	reg ctrl_out_tready;
	wire ctrl_out_tvalid;

	reg [71:0]in_read_tdata;
	wire in_read_tready;
	reg in_read_tvalid;

	reg [71:0]in_write_tdata;
	wire in_write_tready;
	reg in_write_tvalid;

	wire [47:0]out_read_tdata;
	reg out_read_tready;
	wire out_read_tvalid;
	wire [47:0]out_write_tdata;
	reg out_write_tready;
	wire out_write_tvalid;

	libmm_ip_top_TB DUT(
		.c0_sys_clk_i_0			(sysclk_300_clk_ref),
		.sys_rst_0			(sys_reset),
		.mc_ddr4_ui_clk_rst_n		(mc_ddr4_ui_clk_rst_n),
		.mc_init_calib_complete		(mc_init_calib_complete),

		.ctrl_in_0_tdata		(ctrl_in_tdata),
		.ctrl_in_0_tready		(ctrl_in_tready),
		.ctrl_in_0_tvalid		(ctrl_in_tvalid),
		.ctrl_out_0_tdata		(ctrl_out_tdata),
		.ctrl_out_0_tready		(ctrl_out_tready),
		.ctrl_out_0_tvalid		(ctrl_out_tvalid),

		.in_read_0_tdata		(in_read_tdata),
		.in_read_0_tready		(in_read_tready),
		.in_read_0_tvalid		(in_read_tvalid),
		.in_write_0_tdata		(in_write_tdata),
		.in_write_0_tready		(in_write_tready),
		.in_write_0_tvalid		(in_write_tvalid),

		.out_read_0_tdata		(out_read_tdata),
		.out_read_0_tready		(out_read_tready),
		.out_read_0_tvalid		(out_read_tvalid),
		.out_write_0_tdata		(out_write_tdata),
		.out_write_0_tready		(out_write_tready),
		.out_write_0_tvalid		(out_write_tvalid),

		/* DRAM interface */
		.ddr4_sdram_c1_act_n		(ddr4_act_n),
		.ddr4_sdram_c1_adr		(ddr4_adr),
		.ddr4_sdram_c1_ba		(ddr4_ba),
		.ddr4_sdram_c1_bg		(ddr4_bg),
		.ddr4_sdram_c1_ck_c		(ddr4_ck_c),
		.ddr4_sdram_c1_ck_t		(ddr4_ck_t),
		.ddr4_sdram_c1_cke		(ddr4_cke),
		.ddr4_sdram_c1_cs_n		(ddr4_cs_n),
		.ddr4_sdram_c1_dm_n		(ddr4_dm_n),
		.ddr4_sdram_c1_dq		(ddr4_dq),
		.ddr4_sdram_c1_dqs_c		(ddr4_dqs_c),
		.ddr4_sdram_c1_dqs_t		(ddr4_dqs_t),
		.ddr4_sdram_c1_odt		(ddr4_odt),
		.ddr4_sdram_c1_reset_n		(ddr4_reset_n)
	);

	ddr4_tb_top ddr4_mem_model (
		.model_enable_in	(mc_enable_model),
		.c0_ddr4_act_n		(ddr4_act_n),
		.c0_ddr4_adr		(ddr4_adr),
		.c0_ddr4_ba		(ddr4_ba),
		.c0_ddr4_bg		(ddr4_bg),
		.c0_ddr4_ck_c_int	(ddr4_ck_c),
		.c0_ddr4_ck_t_int	(ddr4_ck_t),
		.c0_ddr4_cke		(ddr4_cke),
		.c0_ddr4_cs_n		(ddr4_cs_n),
		.c0_ddr4_dm_dbi_n	(ddr4_dm_n),
		.c0_ddr4_dq		(ddr4_dq),
		.c0_ddr4_dqs_c		(ddr4_dqs_c),
		.c0_ddr4_dqs_t		(ddr4_dqs_t),
		.c0_ddr4_odt		(ddr4_odt),
		.c0_ddr4_reset_n	(ddr4_reset_n)
	);

	initial begin
		enable_send = 1'b0;
		sysclk_300_clk_ref = 1;

		sys_reset = 1'b0;
		#200000

		sys_reset = 1'b1;
		mc_enable_model = 1'b0;
		#5000 mc_enable_model = 1'b1;

		#200000
		sys_reset = 1'b0;
		#100000

		wait(mc_init_calib_complete == 1'b1);
		wait(mc_ddr4_ui_clk_rst_n == 1'b1);

		#50000000
		enable_send = 1'b1;
	end
	
	always begin
		#1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;
	end

	// Send initiate command
	initial begin
		wait(enable_send == 1'b1);
		@(posedge sysclk_300_clk_ref);

		ctrl_in_tdata = 40'h0000000000;
		ctrl_in_tvalid = 1'b1;

		#CLK_PERIOD
		ctrl_in_tvalid = 1'b0;
	end

	initial begin
		wait(enable_send == 1'b1);
		@(posedge sysclk_300_clk_ref);

		while (1) begin
			if (ctrl_out_tvalid) begin
				ctrl_out_tready = 1'b1;
				$display("Control output: %h\n", ctrl_out_tdata);
				#CLK_PERIOD;
			end else begin
				#CLK_PERIOD;
			end
		end
	end

endmodule

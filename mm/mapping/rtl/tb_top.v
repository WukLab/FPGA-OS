`timescale 1fs/1fs

module mapping_tb_top;

parameter IN_FILEPATH="/root/Github/FPGA/mm/mapping/rtl/input.txt";
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

	reg         	sysclk_300_clk_ref;
	reg             sys_reset;

	wire mc_init_calib_complete;
	wire mc_ddr4_ui_clk_rst_n;
	reg mc_enable_model;
	reg enable_send;

	reg [72:0] in_read_tdata;
	reg in_read_tvalid;
	wire in_read_tready;

	reg [72:0] in_write_tdata;
	reg in_write_tvalid;
	wire in_write_tready;

	reg [72:0] in_ctl_tdata;
	reg in_ctl_tvalid;
	wire in_ctl_tready;

	wire [72:0] out_read_tdata, out_write_tdata;
	wire out_read_tvalid, out_write_tvalid;
	reg out_read_tready, out_write_tready;

	wire [72:0] out_ctl_tdata;
	wire out_ctl_tvalid;
	reg out_ctl_tready;

	mapping_ip_top DUT (
		.c0_sys_clk_i_0			(sysclk_300_clk_ref),
		.sys_rst_0			(sys_reset),
		.mc_ddr4_ui_clk_rst_n		(mc_ddr4_ui_clk_rst_n),
		.mc_init_calib_complete		(mc_init_calib_complete),

		.in_read_0_tdata		(in_read_tdata),
		.in_read_0_tready		(in_read_tready),
		.in_read_0_tvalid		(in_read_tvalid),
		.in_write_0_tdata		(in_write_tdata),
		.in_write_0_tready		(in_write_tready),
		.in_write_0_tvalid		(in_write_tvalid),

		.out_read_0_tdata		(out_read_tdata),
		.out_read_0_tvalid		(out_read_tvalid),
		.out_read_0_tready		(out_read_tready),
		.out_write_0_tdata		(out_write_tdata),
		.out_write_0_tvalid		(out_write_tvalid),
		.out_write_0_tready		(out_write_tready),

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
		.ddr4_sdram_c1_reset_n        (ddr4_reset_n)
	);

	ddr4_tb_top ddr4_mem_model (
		.model_enable_in          (mc_enable_model),
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

	initial begin
		mc_enable_model = 1'b0;
		enable_send = 1'b0;
		sysclk_300_clk_ref = 1;

		// Reset MC
		sys_reset = 1'b0;
	        #200000;

	        sys_reset = 1'b1;
		mc_enable_model = 1'b0;
		#5000 mc_enable_model = 1'b1;

	        #200000
	        sys_reset = 1'b0;
		#100000;

		// Wait until MC is ready
		wait(mc_init_calib_complete == 1'b1);
		wait(mc_ddr4_ui_clk_rst_n == 1'b1);

		#50000000
		enable_send = 1'b1;
	end

	always
		#1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;

	integer infd, finished_send, req_type;

	// Send datapath requests
	initial begin
		finished_send = 0;
		infd = 0;
		req_type = 0;

		out_read_tready = 1;
		out_write_tready = 1;
		out_ctl_tready = 1;

		infd = $fopen(IN_FILEPATH,"r");
		if (infd == 0) begin
		    $display("ERROR, input file not found\n");
		    $finish;

		end

		wait(enable_send == 1'b1);
		@(posedge sysclk_300_clk_ref);

		while (!finished_send) begin
			$fscanf(infd, "%d\n", req_type);
			if (req_type == 0) begin
				// Read request
				if (in_read_tready) begin
					$fscanf(infd, "%h\n", in_read_tdata);
					in_read_tvalid = 1;
				end else begin
					in_read_tvalid = 0;
				end
			end else begin
				// Write request
				if (in_write_tready) begin
					$fscanf(infd, "%h\n", in_write_tdata);
					in_write_tvalid = 1;
				end else begin
					in_write_tvalid = 0;
				end
			end

			if ($feof(infd)) begin
				finished_send = 1;
				$display("Finish sending.");
			end

		  	#CLK_PERIOD;
		  	in_read_tvalid = 0;
		  	in_write_tvalid = 0;
		end
	end

endmodule;

/*
 * This testbench is used to verify the whole KVS block diagram design.
 * Network inputs are read from a file and network outputs are saved as well.
 */

`timescale 1fs/1fs

module bd_kvs_tb;

// Change this to absolute path
parameter IN_FILEPATH="/root/ys/FPGA-2/system/vcu108/tb/kvs/input.txt";
parameter OUT_FILEPATH="/root/ys/FPGA-2/system/vcu108/tb/kvs/output.txt";

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

	wire mc_init_calib_complete;
	wire mc_ddr4_ui_clk_rst_n;

	reg start_send;

	LegoFPGA_axis64_KVS	DUT (
		// DDR4 MC
		.C0_SYS_CLK_0_clk_n		(default_sysclk_300_clk_n),
		.C0_SYS_CLK_0_clk_p		(default_sysclk_300_clk_p),

		.mc_ddr4_ui_clk_rst_n		(mc_ddr4_ui_clk_rst_n),
		.mc_init_calib_complete		(mc_init_calib_complete),

		.sys_rst			(sys_reset),
		.mac_ready			(1'b1),

		// General logic
		.clk_125			(sysclk_125_clk_ref),
		.clk_125_rst_n			(sysclk_125_rst_n),

		.from_net_clk_390		(sysclk_390_clk_ref),
		.from_net_clk_390_rst_n		(sysclk_390_rst_n),

		.to_net_clk_390			(sysclk_390_clk_ref),
		.to_net_clk_390_rst_n		(sysclk_390_rst_n),

		.from_net_tdata			(tx_tdata),
		.from_net_tkeep			(tx_tkeep),
		.from_net_tlast			(tx_tlast),
		.from_net_tready		(tx_tready),
		.from_net_tuser			(tx_tuser),
		.from_net_tvalid		(tx_tvalid),

		.to_net_tdata			(rx_tdata),
		.to_net_tkeep			(rx_tkeep),
		.to_net_tlast			(rx_tlast),
		.to_net_tready			(rx_tready),
		.to_net_tuser			(rx_tuser),
		.to_net_tvalid			(rx_tvalid),

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

	integer infd, outfd;
	integer pktlen, finished, timeout, timedout;

	initial begin
		start_send = 1'b0;
		sysclk_125_rst_n = 1'b1;
		sysclk_390_rst_n = 1'b1;

		sysclk_125_clk_ref = 1;
		sysclk_300_clk_ref = 1;
		sysclk_390_clk_ref = 1;

		sys_reset = 1'b0;
	        #200;
	        sys_reset = 1'b1;
	        #200
	        sys_reset = 1'b0;
		#100;

		wait(mc_init_calib_complete == 1'b1);
		wait(mc_ddr4_ui_clk_rst_n == 1'b1);

		// Generate reset signals
		@(posedge sysclk_125_clk_ref);
		sysclk_125_rst_n = 0;
		#200
		@(posedge sysclk_125_clk_ref);
                sysclk_125_rst_n = 1;

	        @(posedge sysclk_390_clk_ref);
                sysclk_390_rst_n = 0;
                #200;
                @(posedge sysclk_390_clk_ref);
                sysclk_390_rst_n = 1;

		#500
		start_send = 1'b1;
	end

  // Send Data to DUT
  initial begin
        finished = 0;
        pktlen = 1;
	tx_tdata = 0;
        tx_tkeep = 8'hFF;
        tx_tuser = 8'h00;
        tx_tvalid = 0;
        tx_tlast = 0;

        infd = $fopen(IN_FILEPATH,"r");
        if (infd == 0) begin
            $display("ERROR, input file not found\n");
            $finish;
        end
        
        // Wait reset signals
	wait(start_send == 1'b1);

	// Synchronize to network clk
        @(posedge sysclk_390_clk_ref);

        while (!finished) begin
            $fscanf(infd,"%d\n",pktlen);

            while (pktlen != 0) begin
                if (tx_tready) begin
                    $fscanf(infd,"%h %h\n",tx_tdata, tx_tkeep);
                    pktlen = pktlen - 1;
                    
                    if (pktlen == 0) begin
                        tx_tlast = 1;
                    end else begin
                        tx_tlast = 0;
                    end 
                    tx_tvalid = 1;
                    
                    if ($feof(infd)) begin
                        finished = 1;
                    end
                end
		else begin
                    tx_tvalid = 0;
                end

                if (!finished && (pktlen != 0)) begin
                    # CLK_PERIOD;
                end
            end

            # CLK_PERIOD;
            tx_tvalid = 0;
	end
  end

    // Receive data from DUT
    initial begin
        outfd = $fopen(OUT_FILEPATH,"w");
        rx_tready = 1;
        timedout = 0;

        if (outfd == 0) begin
            $display("ERROR, can't write output file\n");
            $finish;
        end

        // wait reset signals
	wait(start_send == 1'b1);

	// Synchronize to network clk
        @(posedge sysclk_390_clk_ref);

        while (1) begin
            if (rx_tvalid) begin
                $fdisplay(outfd,"%h %h", rx_tdata, rx_tkeep);
                # CLK_PERIOD;
            end
            else begin
                # CLK_PERIOD;
            end
        end
    end

    // Clock generation
    always
        #1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;
        
    always
        #4000000.000 sysclk_125_clk_ref = ~sysclk_125_clk_ref;

    always
        #1280000.000 sysclk_390_clk_ref = ~sysclk_390_clk_ref;

    assign default_sysclk_300_clk_p = sysclk_300_clk_ref;
    assign default_sysclk_300_clk_n = ~sysclk_300_clk_ref;

endmodule

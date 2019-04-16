/*
 * This testbench is used to verify the whole RDM BD
 * when the BD is used to hook with PCIe.
 */

`timescale 1fs/1fs

module RDM_BD_for_pcie_tb;

// Change this to absolute path
parameter IN_FILEPATH="/root/ys/FPGA/system/vcu108/tb/rdm/input_pcie.txt";
parameter OUT_FILEPATH="/root/ys/FPGA/system/vcu108/tb/rdm/output_pcie.txt";

// 250MHZ for PCIe AXI-Stream
parameter CLK_PERIOD = 4000000;
parameter TIMEOUT_THRESH = 100000000;

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

	reg	sys_reset;
	reg	sysclk_250_rst_n;

	wire	default_sysclk_300_clk_p;
	wire	default_sysclk_300_clk_n;
    
	reg	sysclk_300_clk_ref;
	reg	sysclk_250_clk_ref;

	reg [255:0] tx_tdata;
	reg [31:0] tx_tkeep;
	reg [63:0] tx_tuser;
	reg tx_tvalid;
	reg tx_tlast;
	wire tx_tready;

	wire [255:0] rx_tdata;
	wire [31:0] rx_tkeep;
	wire [63:0] rx_tuser;
	wire rx_tvalid;
	wire rx_tlast;
	reg rx_tready;

	wire mc_init_calib_complete;
	wire mc_ddr4_ui_clk_rst_n;
	reg mc_enable_model;

	reg enable_send;

	LegoFPGA_RDM_for_pcie	DUT (
		// DDR4 MC
		.C0_SYS_CLK_0_clk_n		(default_sysclk_300_clk_n),
		.C0_SYS_CLK_0_clk_p		(default_sysclk_300_clk_p),

		.mc_ddr4_ui_clk_rst_n		(mc_ddr4_ui_clk_rst_n),
		.mc_init_calib_complete		(mc_init_calib_complete),

		.sys_rst			(sys_reset),
		.driver_ready			(1'b1),

		.RX_clk			(sysclk_250_clk_ref),
		.RX_rst_n		(sysclk_250_rst_n),

		.TX_clk			(sysclk_250_clk_ref),
		.TX_rst_n		(sysclk_250_rst_n),

		.RX_tdata		(tx_tdata),
		.RX_tkeep		(tx_tkeep),
		.RX_tlast		(tx_tlast),
		.RX_tready		(tx_tready),
		.RX_tuser		(tx_tuser),
		.RX_tvalid		(tx_tvalid),

		.TX_tdata		(rx_tdata),
		.TX_tkeep		(rx_tkeep),
		.TX_tlast		(rx_tlast),
		.TX_tready		(rx_tready),
		.TX_tuser		(rx_tuser),
		.TX_tvalid		(rx_tvalid),

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

	// Generate reset signals
	initial begin
		mc_enable_model = 1'b0;
		enable_send = 1'b0;
		sysclk_250_rst_n = 1'b1;

		sysclk_300_clk_ref = 1;
		sysclk_250_clk_ref = 1;

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

	        @(posedge sysclk_250_clk_ref);
                sysclk_250_rst_n = 0;
                #50000000
                @(posedge sysclk_250_clk_ref);
                sysclk_250_rst_n = 1;

		#50000000
		enable_send = 1'b1;
	end

	always
		#1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;
	    
	always
		#2000000.000 sysclk_250_clk_ref = ~sysclk_250_clk_ref;

	assign default_sysclk_300_clk_p = sysclk_300_clk_ref;
	assign default_sysclk_300_clk_n = ~sysclk_300_clk_ref;


	// Counters for evaluation
	reg [63:0] send_start, send_end, receive_start, receive_end;
	reg [63:0] nr_requests_send, nr_requests_received;

	integer infd, outfd, pktlen, finished_send;

	reg [63:0] this_packet_start, this_packet_end;

	// Send Data to DUT
	initial begin
	      finished_send = 0;
	      pktlen = 1;
	      nr_requests_send = 0;
	      nr_requests_received = 0;

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
	      wait(enable_send == 1'b1);

	      // Synchronize to network clk
	      @(posedge sysclk_250_clk_ref);

	      send_start = $time;
	      $display("INFO: %t: Start sending packets.", send_start);

	      while (!finished_send) begin
		  $fscanf(infd,"%d\n",pktlen);
		  
		  // Take a break
		  if (pktlen == 0) begin
		      wait(nr_requests_send == nr_requests_received);
		  end else begin
		      nr_requests_send = nr_requests_send + 1;
		      this_packet_start = $time;
		      $display("Send packet [%d] %d", nr_requests_send, $time);
                  end
 
		  while (pktlen != 0) begin
		      if (tx_tready) begin
			  $fscanf(infd,"%h\n",tx_tdata);
			  tx_tkeep = 32'h0xffffffff;
			  pktlen = pktlen - 1;
			  
			  if (pktlen == 0) begin
			      tx_tlast = 1;
			  end else begin
			      tx_tlast = 0;
			  end 
			  tx_tvalid = 1;

			  if ($feof(infd)) begin
			      finished_send = 1;
			      send_end = $time;
			      $display("INFO: %t: Finish sending packets.", send_end);
			  end
		      end else begin
			  tx_tvalid = 0;
		      end

		      if (!finished_send && (pktlen != 0)) begin
			  # CLK_PERIOD;
		      end
		  end

		  # CLK_PERIOD;
		  tx_tvalid = 0;

/*
		  wait(nr_requests_send == nr_requests_received);
		  $display("This packet [%d - %d], latency: %d",
		  	this_packet_start, this_packet_end,
			this_packet_end - this_packet_start);
*/
	      end
	end

	// Receive data from DUT
	initial begin
	    rx_tready = 1;
	    receive_start = 0;

	    outfd = $fopen(OUT_FILEPATH,"w");
	    if (outfd == 0) begin
		$display("ERROR, can't write output file\n");
		$finish;
	    end

	    // wait reset signals
	    wait(enable_send == 1'b1);

	    // Synchronize to network clk
	    @(posedge sysclk_250_clk_ref);

	    while (1) begin
		if (rx_tvalid) begin
		    if (receive_start == 0) begin
		    	receive_start = $time;
		    end

		    if (rx_tlast) begin
			if (nr_requests_received == (nr_requests_send - 1)) begin
				receive_end = $time;
			end
		    	nr_requests_received = nr_requests_received + 1;
		    	$display("%t: nr_sent: %d nr_received: %d",
		    	          $time, nr_requests_send, nr_requests_received);

		    	this_packet_end = $time;
		    end

		    //$display("%t: %h %h %d", $time, rx_tdata, rx_tkeep, rx_tlast);
		    $fdisplay(outfd, "%h %h %d", rx_tdata, rx_tkeep, rx_tlast);
		    # CLK_PERIOD;
		end
		else begin
		    # CLK_PERIOD;
		end
	    end
	end

	// Monitor status
	initial begin
		wait (finished_send == 1);
		wait (nr_requests_send == nr_requests_received);

		$display("INFO: TX Time: [%d - %d]", send_start, send_end);
		$display("INFO: RX Time: [%d - %d]", receive_start, receive_end);
		$display("INFO: NR Requests TX: %d ", nr_requests_send);
		$display("INFO: NR Requests RX: %d ", nr_requests_received);

		$fclose(infd);
		$fclose(outfd);
		$finish;
	end

endmodule

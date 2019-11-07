/*
 * Copyright (c) 2019, Wuklab, UCSD. All rights reserved.
 *
 * This module sits between the HLS controller and the ICAPE3 primitive.
 * We deal with the I and O that are in AXI-Stream. Other signals just bypass.
 * This IP is stupid. We have this IP because Lastweek can not write Verilog. :-|
 */

module strip (
	input clk,

	/*
	 * Interface with the ICAP
	 * I and O are in raw format
	 */
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP avail" *)	input	AVAIL_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP o" *)		input [31:0] data_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP prdone" *)	input	PRDONE_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP prerror" *)	input	PRERROR_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP csib" *)		output	CSIB_to_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP i" *)		output reg [31:0] data_to_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP rdwrb" *)	output	RDWRB_to_icap,
	
	
	/*
	 * Interface with the HLS controller
	 * I and O are in AXI-Stream format
	 */
	output		AVAIL_to_hls,
	output		PRDONE_to_hls,
	output		PRERROR_to_hls,
	
	output reg [31:0] data_to_hls_tdata,
	output reg	data_to_hls_tvalid,
	input		data_to_hls_tready,
	
	input		CSIB_from_hls,
	input		CSIB_from_hls_valid,
	input		RDWRB_from_hls,
	input		RDWRB_from_hls_valid,

	input [31:0]	data_from_hls_tdata,
	input		data_from_hls_tvalid,
	output reg	data_from_hls_tready
);

	/* Output single-lane signals go to the HLS IP directly */
	assign AVAIL_to_hls = AVAIL_from_icap;
	assign PRDONE_to_hls = PRDONE_from_icap;
	assign PRERROR_to_hls = PRERROR_from_icap;

	/*
	 * CSIB:	Active-low ICAP input enable
	 * RDWRB:	Read (Active High) or Write (Active Low) select input
	 *
	 * These might be X from HLS. Output DISABLE/READ if not valid.
	 */
	assign CSIB_to_icap = CSIB_from_hls_valid? CSIB_from_hls : 1'b1;
	assign RDWRB_to_icap = RDWRB_from_hls_valid? RDWRB_from_hls : 1'b1;

	always @(posedge clk) begin
		/*
		 * From ICAP3 to HLS
		 * We should accept the data if Read mode is enabled.
		 *
		 * TODO
		 * In simulation, I found the value of O will be ZZZZZZZZ
		 * after the RDWRB is set to read. How to detect this?
		 */
		if (RDWRB_to_icap  == 1'b1)
	    	    //data_from_icap != 32'hZZZZZZZZ)
	    	    //data_from_icap != 32'hXXXXXXXX)
		begin
			data_to_hls_tdata <= data_from_icap;
			data_to_hls_tvalid <= 1'b1;
		end else begin
			data_to_hls_tdata <= 0;
			data_to_hls_tvalid <= 1'b0;
		end

		/*
		 * From HLS to ICAP3
		 * we need to check if the signals are valid
		 */
		data_from_hls_tready <= 1'b1;
		if (data_from_hls_tvalid) begin
			data_to_icap <= data_from_hls_tdata;
		end
	end

endmodule

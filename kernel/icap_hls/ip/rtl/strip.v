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
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP i" *)		output [31:0] data_to_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP rdwrb" *)	output	RDWRB_to_icap,
	
	
	/*
	 * Interface with the HLS controller
	 * I and O are in AXI-Stream format
	 */
	output		AVAIL_to_hls,
	output		PRDONE_to_hls,
	output		PRERROR_to_hls,
	
	output [31:0]	data_to_hls_tdata,
	output		data_to_hls_tvalid,
	input		data_to_hls_tready,
	
	input		CSIB_from_hls,
	input		CSIB_from_hls_valid,
	input		RDWRB_from_hls,
	input		RDWRB_from_hls_valid,

	input [31:0]	data_from_hls_tdata,
	input		data_from_hls_tvalid,
	output		data_from_hls_tready
);

	parameter CSIB_ENABLE = 1'b0;
	parameter CSIB_DISABLE = 1'b1;
	parameter RDWRB_WRITE = 1'b0;
	parameter RDWRB_READ = 1'b1;

	wire valid_input_from_icap;

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
	assign CSIB_to_icap = CSIB_from_hls_valid ? CSIB_from_hls : CSIB_DISABLE;
	assign RDWRB_to_icap = RDWRB_from_hls_valid ? RDWRB_from_hls : RDWRB_READ;

	/*
	 * Data from HLS to ICAP3
	 * we need to check if the signals are valid
	 * 32'bffffffff is dummy word.
	 */
	assign data_from_hls_tready = 1'b1;
	assign data_to_icap = data_from_hls_tvalid ? data_from_hls_tdata : 32'hFFFFFFFF;

	/*
	 * Data from ICAP3 to HLS
	 * Valid if Read mode is enabled when CSIB is also enabled.
	 */
	assign valid_input_from_icap = (RDWRB_to_icap == RDWRB_READ && CSIB_to_icap == CSIB_ENABLE) ? 1'b1 : 1'b0;
	assign data_to_hls_tvalid = (valid_input_from_icap == 1'b1 && data_to_hls_tready == 1'b1) ? 1'b1 : 1'b0;
	assign data_to_hls_tdata = valid_input_from_icap ? data_from_icap : 32'b00000000;

endmodule

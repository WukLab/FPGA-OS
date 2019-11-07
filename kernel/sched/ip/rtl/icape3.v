/*
 * Copyright (c) 2019，Wuklab, UCSD.
 * Ultrascale+ ICAPE3 Wrapper. Reference: UG570.
 */

/*
 * Description about ICAPE3 Pin:
 * AVAIL (O):	ICAP available
 * CSIB (I):	Active-Low ICAP input enable
 * I[31:0]:	Configuration data input bus to ICAP
 * O[31:0]:	Configuration data output bus from ICAP. If no data is beging
 *		read, contains current status.
 * PRDONE (O):	PR Complete. Default is high. Goes Low when FDRI packet is seen,
 *		and goes back High when DESYNC is seen and EOS is High.
 * PRERROR (O):	PR error. Default is Low. Goes High when partial configuration
 * 		bitstream error is detected. Can be reset by loading RCRC command.
 * RDWRB (I):	Read (Active High) or Write (Active Low) Select input.
 */
module icape3_wrapper (
	input CLK,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP avail" *)	output        AVAIL,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP o" *)		output [31:0] O,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP prdone" *)	output        PRDONE,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP prerror" *)	output        PRERROR,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP csib" *)	input         CSIB,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP i" *)		input [31:0]  I,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 ICAP rdwrb" *)	input         RDWRB
);

	/*
	 * TODO
	 * Add bitswapping for I and O.
	 */

	wire [31:0] I_Swapped;

	/* This code is derived from the Vivado language template. */
	ICAPE3 #(
		.DEVICE_ID(32'h03628093),	// Specifies the pre-programmed Device ID value to be used for simulation purposes.
		.ICAP_AUTO_SWITCH("DISABLE"),	// Enable switch ICAP using sync word
		.SIM_CFG_FILE_NAME("NONE")	// Specifies the Raw Bitstream (RBT) file to be parsed by the simulation model
	) ICAPE3_inst (
		.AVAIL(AVAIL),			// 1-bit output: Availability status of ICAP
		.O(O),				// 32-bit output: Configuration data output bus
		.PRDONE(PRDONE),		// 1-bit output: Indicates completion of Partial Reconfiguration
		.PRERROR(PRERROR),		// 1-bit output: Indicates Error during Partial Reconfiguration
		.CLK(CLK),			// 1-bit input: Clock input
		.CSIB(CSIB),			// 1-bit input: Active-Low ICAP enable
		.I(I),				// 32-bit input: Configuration data input bus
		.RDWRB(RDWRB)			// 1-bit input: Read/Write Select input
	);

	generate begin: xhdl0
		genvar j;
		for (j = 0; j <= 3; j = j + 1) begin : mirror_j
			genvar i;
			for (i=0; i<=7; i=i+1) begin : mirror_i
				assign I_Swapped[j * 8 + i] = I[j * 8 + 7 - i];
			end
		end
	end endgenerate

endmodule

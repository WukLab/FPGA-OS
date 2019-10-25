module strip(
	input clk,

    /*
     * Interface with the ICAP
     */
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP avail" *)
	input        AVAIL_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP o" *)
	input [31:0] data_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP prdone" *)
	input        PRDONE_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP prerror" *)
	input        PRERROR_from_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP csib" *)
	output         CSIB_to_icap,
	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP i" *)
	output [31:0]  data_to_icap,

	(* X_INTERFACE_INFO = "xilinx.com:interface:icap:1.0 with_ICAP rdwrb" *)
	output         RDWRB_to_icap,
	
	
    /*
     * Interface with the HLS
     */
	output        AVAIL_to_hls,
	output        PRDONE_to_hls,
	output        PRERROR_to_hls,
	
	output [31:0] data_to_hls_tdata,
	output        data_to_hls_tvalid,
	input         data_to_hls_tready,
	
	input         CSIB_from_hls,
	input         CSIB_from_hls_valid,
	input         RDWRB_from_hls,
	input         RDWRB_from_hls_valid,

	input [31:0]  data_from_hls_tdata,
	input         data_from_hls_tvalid,
	output        data_from_hls_tready

);

endmodule

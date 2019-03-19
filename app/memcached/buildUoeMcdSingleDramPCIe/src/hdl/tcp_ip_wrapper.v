`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.11.2013 10:48:44
// Design Name: 
// Module Name: tcp_ip_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tcp_ip_wrapper(
    input           aclk,
    //input       reset,
    input           aresetn,
    // network interface streams
    output          AXI_M_Stream_TVALID,
    input           AXI_M_Stream_TREADY,
    output[63:0]    AXI_M_Stream_TDATA,
    output[7:0]     AXI_M_Stream_TKEEP,
    output          AXI_M_Stream_TLAST,

    input           AXI_S_Stream_TVALID,
    output          AXI_S_Stream_TREADY,
    input[63:0]     AXI_S_Stream_TDATA,
    input[7:0]      AXI_S_Stream_TKEEP,
    input           AXI_S_Stream_TLAST,
    // Debug streams
    output[7:0]     axi_debug1_tkeep,
    output[63:0]    axi_debug1_tdata,
    output          axi_debug1_tvalid,
    output          axi_debug1_tready,
    output          axi_debug1_tlast,
    
    output[7:0]     axi_debug2_tkeep,
    output[63:0]    axi_debug2_tdata,
    output          axi_debug2_tvalid,
    output          axi_debug2_tready,
    output          axi_debug2_tlast,
    // UDP Core App I/F //
    output[63:0]    rxDataIn_TDATA,
    output          rxDataIn_TVALID,
    input           rxDataIn_TREADY,
    output [7:0]    rxDataIn_TKEEP,
    output          rxDataIn_TLAST,
    output[95:0]    rxMetadataIn_V_TDATA,
    output          rxMetadataIn_V_TVALID,
    input           rxMetadataIn_V_TREADY,
    input[15:0]     requestPortOpenOut_V_TDATA,
    input           requestPortOpenOut_V_TVALID,
    output          requestPortOpenOut_V_TREADY,
    output[7:0]     portOpenReplyIn_V_V_TDATA,
    output          portOpenReplyIn_V_V_TVALID,
    input           portOpenReplyIn_V_V_TREADY,

    input           udpTxDataOut_TVALID,
    output          udpTxDataOut_TREADY,
    input[63:0]     udpTxDataOut_TDATA,
    input[7:0]      udpTxDataOut_TKEEP,
    input           udpTxDataOut_TLAST,

    input           udpTxMetadataOut_V_TVALID,
    output          udpTxMetadataOut_V_TREADY,
    input[95:0]     udpTxMetadataOut_V_TDATA,

    input           udpTxLengthOut_V_V_TVALID,
    output          udpTxLengthOut_V_V_TREADY,
    input[15:0]     udpTxLengthOut_V_V_TDATA);

// IP Handler Outputs
wire            axi_iph_to_arp_slice_tvalid;
wire            axi_iph_to_arp_slice_tready;
wire[63:0]      axi_iph_to_arp_slice_tdata;
wire[7:0]       axi_iph_to_arp_slice_tkeep;
wire            axi_iph_to_arp_slice_tlast;
wire            axi_iph_to_icmp_slice_tvalid;
wire            axi_iph_to_icmp_slice_tready;
wire[63:0]      axi_iph_to_icmp_slice_tdata;
wire[7:0]       axi_iph_to_icmp_slice_tkeep;
wire            axi_iph_to_icmp_slice_tlast;

//Slice connections on RX path
wire            axi_arp_slice_to_arp_tvalid;
wire            axi_arp_slice_to_arp_tready;
wire[63:0]      axi_arp_slice_to_arp_tdata;
wire[7:0]       axi_arp_slice_to_arp_tkeep;
wire            axi_arp_slice_to_arp_tlast;
wire            axi_icmp_slice_to_icmp_tvalid;
wire            axi_icmp_slice_to_icmp_tready;
wire[63:0]      axi_icmp_slice_to_icmp_tdata;
wire[7:0]       axi_icmp_slice_to_icmp_tkeep;
wire            axi_icmp_slice_to_icmp_tlast;
wire            axi_toe_slice_to_toe_tvalid;
wire            axi_toe_slice_to_toe_tready;
wire[63:0]      axi_toe_slice_to_toe_tdata;
wire[7:0]       axi_toe_slice_to_toe_tkeep;
wire            axi_toe_slice_to_toe_tlast;

// MAC-IP Encode Inputs
wire            axi_intercon_to_mie_tvalid;
wire            axi_intercon_to_mie_tready;
wire[63:0]      axi_intercon_to_mie_tdata;
wire[7:0]       axi_intercon_to_mie_tkeep;
wire            axi_intercon_to_mie_tlast;
wire            axi_mie_to_intercon_tvalid;
wire            axi_mie_to_intercon_tready;
wire[63:0]      axi_mie_to_intercon_tdata;
wire[7:0]       axi_mie_to_intercon_tkeep;
wire            axi_mie_to_intercon_tlast;
//Slice connections on RX path
wire            axi_arp_to_arp_slice_tvalid;
wire            axi_arp_to_arp_slice_tready;
wire[63:0]      axi_arp_to_arp_slice_tdata;
wire[7:0]       axi_arp_to_arp_slice_tkeep;
wire            axi_arp_to_arp_slice_tlast;
wire            axi_icmp_to_icmp_slice_tvalid;
wire            axi_icmp_to_icmp_slice_tready;
wire[63:0]      axi_icmp_to_icmp_slice_tdata;
wire[7:0]       axi_icmp_to_icmp_slice_tkeep;
wire            axi_icmp_to_icmp_slice_tlast;

wire        axi_udp_to_merge_tvalid;
wire        axi_udp_to_merge_tready;
wire[63:0]  axi_udp_to_merge_tdata;
wire[7:0]   axi_udp_to_merge_tkeep;
wire        axi_udp_to_merge_tlast;

wire        axi_iph_to_udp_tvalid;
wire        axi_iph_to_udp_tready;
wire[63:0]  axi_iph_to_udp_tdata;
wire[7:0]   axi_iph_to_udp_tkeep;
wire        axi_iph_to_udp_tlast;

wire        axis_udp_to_icmp_tready;
wire        axis_udp_to_icmp_tvalid;
wire[63:0]  axis_udp_to_icmp_tdata;
wire[7:0]   axis_udp_to_icmp_tkeep;
wire        axis_udp_to_icmp_tlast;

wire        axis_ttl_to_icmp_tready;
wire        axis_ttl_to_icmp_tvalid;
wire[63:0]  axis_ttl_to_icmp_tdata;
wire[7:0]   axis_ttl_to_icmp_tkeep;
wire        axis_ttl_to_icmp_tlast;

// UDP Controller
udp_0 myUDP (
  .inputPathInData_TVALID(axi_iph_to_udp_tvalid),               // input wire inputPathInData_TVALID
  .inputPathInData_TREADY(axi_iph_to_udp_tready),               // output wire inputPathInData_TREADY
  .inputPathInData_TDATA(axi_iph_to_udp_tdata),                 // input wire [63 : 0] inputPathInData_TDATA
  .inputPathInData_TKEEP(axi_iph_to_udp_tkeep),                 // input wire [7 : 0] inputPathInData_TKEEP
  .inputPathInData_TLAST(axi_iph_to_udp_tlast),                 // input wire [0 : 0] inputPathInData_TLAST
  .inputpathOutData_TVALID(rxDataIn_TVALID),                    // output wire inputpathOutData_V_TVALID
  .inputpathOutData_TREADY(rxDataIn_TREADY),                    // input wire inputpathOutData_V_TREADY
  .inputpathOutData_TDATA(rxDataIn_TDATA),                      // output wire [71 : 0] inputpathOutData_V_TDATA
  .inputpathOutData_TKEEP(rxDataIn_TKEEP),                      // output wire [7:0]  
  .inputpathOutData_TLAST(rxDataIn_TLAST),                      // output wire
  .openPort_TVALID(requestPortOpenOut_V_TVALID),                // input wire openPort_V_TVALID
  .openPort_TREADY(requestPortOpenOut_V_TREADY),                // output wire openPort_V_TREADY
  .openPort_TDATA(requestPortOpenOut_V_TDATA),                  // input wire [7 : 0] openPort_V_TDATA
  .confirmPortStatus_TVALID(portOpenReplyIn_V_V_TVALID),        // output wire confirmPortStatus_V_V_TVALID
  .confirmPortStatus_TREADY(portOpenReplyIn_V_V_TVALID),        // input wire confirmPortStatus_V_V_TREADY
  .confirmPortStatus_TDATA(portOpenReplyIn_V_V_TDATA),          // output wire [15 : 0] confirmPortStatus_V_V_TDATA
  .inputPathOutputMetadata_TVALID(rxMetadataIn_V_TVALID),       // output wire inputPathOutputMetadata_V_TVALID
  .inputPathOutputMetadata_TREADY(rxMetadataIn_V_TREADY),       // input wire inputPathOutputMetadata_V_TREADY
  .inputPathOutputMetadata_TDATA(rxMetadataIn_V_TDATA),         // output wire [95 : 0] inputPathOutputMetadata_V_TDATA
  .portRelease_TVALID(1'b0),                                    // input wire portRelease_V_V_TVALID
  .portRelease_TREADY(),                                        // output wire portRelease_V_V_TREADY
  .portRelease_TDATA(15'b0),                                    // input wire [15 : 0] portRelease_V_V_TDATA
  .outputPathInData_TVALID(udpTxDataOut_TVALID),                // input wire outputPathInData_V_TVALID
  .outputPathInData_TREADY(udpTxDataOut_TREADY),                // output wire outputPathInData_V_TREADY
  .outputPathInData_TDATA(udpTxDataOut_TDATA),                  // input wire [71 : 0] outputPathInData_V_TDATA
  .outputPathInData_TKEEP(udpTxDataOut_TKEEP),                  // input wire [7 : 0] outputPathInData_TKEEP
  .outputPathInData_TLAST(udpTxDataOut_TLAST),                  // input wire [0 : 0] outputPathInData_TLAST
  .outputPathOutData_TVALID(axi_udp_to_merge_tvalid),           // output wire outputPathOutData_TVALID
  .outputPathOutData_TREADY(axi_udp_to_merge_tready),           // input wire outputPathOutData_TREADY
  .outputPathOutData_TDATA(axi_udp_to_merge_tdata),             // output wire [63 : 0] outputPathOutData_TDATA
  .outputPathOutData_TKEEP(axi_udp_to_merge_tkeep),             // output wire [7 : 0] outputPathOutData_TKEEP
  .outputPathOutData_TLAST(axi_udp_to_merge_tlast),             // output wire [0 : 0] outputPathOutData_TLAST  
  .outputPathInMetadata_TVALID(udpTxMetadataOut_V_TVALID),      // input wire outputPathInMetadata_V_TVALID
  .outputPathInMetadata_TREADY(udpTxMetadataOut_V_TREADY),      // output wire outputPathInMetadata_V_TREADY
  .outputPathInMetadata_TDATA(udpTxMetadataOut_V_TDATA),        // input wire [95 : 0] outputPathInMetadata_V_TDATA
  .outputpathInLength_TVALID(udpTxLengthOut_V_V_TVALID),        // input wire outputpathInLength_V_V_TVALID
  .outputpathInLength_TREADY(udpTxLengthOut_V_V_TREADY),        // output wire outputpathInLength_V_V_TREADY
  .outputpathInLength_TDATA(udpTxLengthOut_V_V_TDATA),          // input wire [15 : 0] outputpathInLength_V_V_TDATA
  .inputPathPortUnreachable_TVALID(axis_udp_to_icmp_tvalid),    // output wire inputPathPortUnreachable_TVALID
  .inputPathPortUnreachable_TREADY(axis_udp_to_icmp_tready),    // input wire inputPathPortUnreachable_TREADY
  .inputPathPortUnreachable_TDATA(axis_udp_to_icmp_tdata),      // output wire [63 : 0] inputPathPortUnreachable_TDATA
  .inputPathPortUnreachable_TKEEP(axis_udp_to_icmp_tkeep),      // output wire [7 : 0] inputPathPortUnreachable_TKEEP
  .inputPathPortUnreachable_TLAST(axis_udp_to_icmp_tlast),      // output wire [0 : 0] inputPathPortUnreachable_TLAST
  //.ap_start(1'b1),                                            // input wire ap_start
  //.ap_ready(),                                                // output wire ap_ready
  //.ap_done(),                                                 // output wire ap_done
  //.ap_idle(),                                                 // output wire ap_idle
  .aclk(aclk),                                                  // input wire ap_clk
  .aresetn(aresetn)                                             // input wire ap_rst_n
);

ip_handler_ip ip_handler_inst (
.ARPdataOut_TVALID(axi_iph_to_arp_slice_tvalid),    // output AXI4Stream_M_TVALID
.ARPdataOut_TREADY(axi_iph_to_arp_slice_tready),    // input AXI4Stream_M_TREADY
.ARPdataOut_TDATA(axi_iph_to_arp_slice_tdata),      // output [63 : 0] AXI4Stream_M_TDATA
.ARPdataOut_TKEEP(axi_iph_to_arp_slice_tkeep),      // output [7 : 0] AXI4Stream_M_TSTRB
.ARPdataOut_TLAST(axi_iph_to_arp_slice_tlast),      // output [0 : 0] AXI4Stream_M_TLAST

.ICMPdataOut_TVALID(axi_iph_to_icmp_slice_tvalid),  // output AXI4Stream_M_TVALID
.ICMPdataOut_TREADY(axi_iph_to_icmp_slice_tready),  // input AXI4Stream_M_TREADY
.ICMPdataOut_TDATA(axi_iph_to_icmp_slice_tdata),    // output [63 : 0] AXI4Stream_M_TDATA
.ICMPdataOut_TKEEP(axi_iph_to_icmp_slice_tkeep),    // output [7 : 0] AXI4Stream_M_TSTRB
.ICMPdataOut_TLAST(axi_iph_to_icmp_slice_tlast),    // output [0 : 0] AXI4Stream_M_TLAST

.ICMPexpDataOut_TVALID(axis_ttl_to_icmp_tvalid),  // output wire m_axis_ICMPexp_TVALID
.ICMPexpDataOut_TREADY(axis_ttl_to_icmp_tready),  // input wire m_axis_ICMPexp_TREADY
.ICMPexpDataOut_TDATA(axis_ttl_to_icmp_tdata),    // output wire [63 : 0] m_axis_ICMPexp_TDATA
.ICMPexpDataOut_TKEEP(axis_ttl_to_icmp_tkeep),    // output wire [7 : 0] m_axis_ICMPexp_TKEEP
.ICMPexpDataOut_TLAST(axis_ttl_to_icmp_tlast),    // output wire [0 : 0] m_axis_ICMPexp_TLAST
  
.UDPdataOut_TVALID(axi_iph_to_udp_tvalid),          // output AXI4Stream_M_TVALID
.UDPdataOut_TREADY(axi_iph_to_udp_tready),          // input AXI4Stream_M_TREADY
.UDPdataOut_TDATA(axi_iph_to_udp_tdata),            // output [63 : 0] AXI4Stream_M_TDATA
.UDPdataOut_TKEEP(axi_iph_to_udp_tkeep),            // output [7 : 0] AXI4Stream_M_TSTRB
.UDPdataOut_TLAST(axi_iph_to_udp_tlast),            // output [0 : 0]  

.TCPdataOut_TVALID(),                               // output AXI4Stream_M_TVALID
.TCPdataOut_TREADY(1'b1),                           // input AXI4Stream_M_TREADY
.TCPdataOut_TDATA(),                                // output [63 : 0] AXI4Stream_M_TDATA
.TCPdataOut_TKEEP(),                                // output [7 : 0] AXI4Stream_M_TSTRB
.TCPdataOut_TLAST(),                                // output [0 : 0] AXI4Stream_M_TLAST

.dataIn_TVALID(AXI_S_Stream_TVALID),            // input AXI4Stream_S_TVALID
.dataIn_TREADY(AXI_S_Stream_TREADY),            // output AXI4Stream_S_TREADY
.dataIn_TDATA(AXI_S_Stream_TDATA),              // input [63 : 0] AXI4Stream_S_TDATA
.dataIn_TKEEP(AXI_S_Stream_TKEEP),              // input [7 : 0] AXI4Stream_S_TSTRB
.dataIn_TLAST(AXI_S_Stream_TLAST),              // input [0 : 0] AXI4Stream_S_TLAST

.regIpAddress_V(32'h01010101),                          //was iph_ip_address
.myMacAddress_V(48'hE59D02350A00),
.ap_clk(aclk),                                            // input aclk
.ap_rst_n(aresetn)                                       // input aresetn
);

// ARP lookup
wire        axis_arp_lookup_request_TVALID;
wire        axis_arp_lookup_request_TREADY;
wire[31:0]  axis_arp_lookup_request_TDATA;
wire        axis_arp_lookup_reply_TVALID;
wire        axis_arp_lookup_reply_TREADY;
wire[55:0]  axis_arp_lookup_reply_TDATA;

mac_ip_encode_ip mac_ip_encode_inst (
.dataOut_TVALID(axi_mie_to_intercon_tvalid),
.dataOut_TREADY(axi_mie_to_intercon_tready),
.dataOut_TDATA(axi_mie_to_intercon_tdata),
.dataOut_TKEEP(axi_mie_to_intercon_tkeep),
.dataOut_TLAST(axi_mie_to_intercon_tlast),
.arpTableOut_V_V_TVALID(axis_arp_lookup_request_TVALID),
.arpTableOut_V_V_TREADY(axis_arp_lookup_request_TREADY),
.arpTableOut_V_V_TDATA(axis_arp_lookup_request_TDATA),
.dataIn_TVALID(axi_intercon_to_mie_tvalid),
.dataIn_TREADY(axi_intercon_to_mie_tready),
.dataIn_TDATA(axi_intercon_to_mie_tdata),
.dataIn_TKEEP(axi_intercon_to_mie_tkeep),
.dataIn_TLAST(axi_intercon_to_mie_tlast),
.arpTableIn_V_TVALID(axis_arp_lookup_reply_TVALID),
.arpTableIn_V_TREADY(axis_arp_lookup_reply_TREADY),
.arpTableIn_V_TDATA(axis_arp_lookup_reply_TDATA),
.regSubNetMask_V(32'h00FFFFFF),
.regDefaultGateway_V(32'h01010101),
.myMacAddress_V(48'hE59D02350A00),
.ap_clk(aclk),                                                        // input aclk
.ap_rst_n(aresetn)                                                  // input aresetn
);

// merges icmp and tcp
axis_interconnect_2to1 ip_merger (
  .ACLK(aclk),                                      // input ACLK
  .ARESETN(aresetn),                                // input ARESETN
  .S00_AXIS_ACLK(aclk),                             // input S00_AXIS_ACLK
  .S01_AXIS_ACLK(aclk),                             // input S01_AXIS_ACLK
  .S00_AXIS_ARESETN(aresetn),                       // input S00_AXIS_ARESETN
  .S01_AXIS_ARESETN(aresetn),                       // input S01_AXIS_ARESETN
  .S00_AXIS_TVALID(axi_icmp_to_icmp_slice_tvalid),  // input S00_AXIS_TVALID
  .S01_AXIS_TVALID(axi_udp_to_merge_tvalid),        // input S02_AXIS_TVALID
  .S00_AXIS_TREADY(axi_icmp_to_icmp_slice_tready),  // output S00_AXIS_TREADY
  .S01_AXIS_TREADY(axi_udp_to_merge_tready),        // output S02_AXIS_TREADY
  .S00_AXIS_TDATA(axi_icmp_to_icmp_slice_tdata),    // input [63 : 0] S00_AXIS_TDATA
  .S01_AXIS_TDATA(axi_udp_to_merge_tdata),          // input [63 : 0] S02_AXIS_TDATA
  .S00_AXIS_TKEEP(axi_icmp_to_icmp_slice_tkeep),    // input [7 : 0] S00_AXIS_TKEEP
  .S01_AXIS_TKEEP(axi_udp_to_merge_tkeep),          // input [7 : 0] S02_AXIS_TKEEP
  .S00_AXIS_TLAST(axi_icmp_to_icmp_slice_tlast),    // input S00_AXIS_TLAST
  .S01_AXIS_TLAST(axi_udp_to_merge_tlast),          // input S02_AXIS_TLAST
  .M00_AXIS_ACLK(aclk),                             // input M00_AXIS_ACLK
  .M00_AXIS_ARESETN(aresetn),                       // input M00_AXIS_ARESETN
  .M00_AXIS_TVALID(axi_intercon_to_mie_tvalid),     // output M00_AXIS_TVALID
  .M00_AXIS_TREADY(axi_intercon_to_mie_tready),     // input M00_AXIS_TREADY
  .M00_AXIS_TDATA(axi_intercon_to_mie_tdata),       // output [63 : 0] M00_AXIS_TDATA
  .M00_AXIS_TKEEP(axi_intercon_to_mie_tkeep),       // output [7 : 0] M00_AXIS_TKEEP
  .M00_AXIS_TLAST(axi_intercon_to_mie_tlast),       // output M00_AXIS_TLAST
  .S00_ARB_REQ_SUPPRESS(1'b0),                      // input S00_ARB_REQ_SUPPRESS
  .S01_ARB_REQ_SUPPRESS(1'b0)                       // input S01_ARB_REQ_SUPPRESS
);

// merges ip and arp
axis_interconnect_2to1 mac_merger (
  .ACLK(aclk), // input ACLK
  .ARESETN(aresetn), // input ARESETN
  .S00_AXIS_ACLK(aclk), // input S00_AXIS_ACLK
  .S01_AXIS_ACLK(aclk), // input S01_AXIS_ACLK
  .S00_AXIS_ARESETN(aresetn), // input S00_AXIS_ARESETN
  .S01_AXIS_ARESETN(aresetn), // input S01_AXIS_ARESETN
  .S00_AXIS_TVALID(axi_arp_to_arp_slice_tvalid), // input S00_AXIS_TVALID
  .S01_AXIS_TVALID(axi_mie_to_intercon_tvalid), // input S01_AXIS_TVALID
  .S00_AXIS_TREADY(axi_arp_to_arp_slice_tready), // output S00_AXIS_TREADY
  .S01_AXIS_TREADY(axi_mie_to_intercon_tready), // output S01_AXIS_TREADY
  .S00_AXIS_TDATA(axi_arp_to_arp_slice_tdata), // input [63 : 0] S00_AXIS_TDATA
  .S01_AXIS_TDATA(axi_mie_to_intercon_tdata), // input [63 : 0] S01_AXIS_TDATA
  .S00_AXIS_TKEEP(axi_arp_to_arp_slice_tkeep), // input [7 : 0] S00_AXIS_TKEEP
  .S01_AXIS_TKEEP(axi_mie_to_intercon_tkeep), // input [7 : 0] S01_AXIS_TKEEP
  .S00_AXIS_TLAST(axi_arp_to_arp_slice_tlast), // input S00_AXIS_TLAST
  .S01_AXIS_TLAST(axi_mie_to_intercon_tlast), // input S01_AXIS_TLAST
  .M00_AXIS_ACLK(aclk), // input M00_AXIS_ACLK
  .M00_AXIS_ARESETN(aresetn), // input M00_AXIS_ARESETN
  .M00_AXIS_TVALID(AXI_M_Stream_TVALID), // output M00_AXIS_TVALID
  .M00_AXIS_TREADY(AXI_M_Stream_TREADY), // input M00_AXIS_TREADY
  .M00_AXIS_TDATA(AXI_M_Stream_TDATA), // output [63 : 0] M00_AXIS_TDATA
  .M00_AXIS_TKEEP(AXI_M_Stream_TKEEP), // output [7 : 0] M00_AXIS_TKEEP
  .M00_AXIS_TLAST(AXI_M_Stream_TLAST), // output M00_AXIS_TLAST
  .S00_ARB_REQ_SUPPRESS(1'b0), // input S00_ARB_REQ_SUPPRESS
  .S01_ARB_REQ_SUPPRESS(1'b0) // input S01_ARB_REQ_SUPPRESS
);
arpServerWrapper arpServerInst (
.myIpAddress(32'h01010101),                          //was iph_ip_address
.myMacAddress(48'hE59D02350A00),
.axi_arp_to_arp_slice_tvalid(axi_arp_to_arp_slice_tvalid),
.axi_arp_to_arp_slice_tready(axi_arp_to_arp_slice_tready),
.axi_arp_to_arp_slice_tdata(axi_arp_to_arp_slice_tdata),
.axi_arp_to_arp_slice_tkeep(axi_arp_to_arp_slice_tkeep),
.axi_arp_to_arp_slice_tlast(axi_arp_to_arp_slice_tlast),
.axis_arp_lookup_reply_TVALID(axis_arp_lookup_reply_TVALID),
.axis_arp_lookup_reply_TREADY(axis_arp_lookup_reply_TREADY),
.axis_arp_lookup_reply_TDATA(axis_arp_lookup_reply_TDATA),
.axi_arp_slice_to_arp_tvalid(axi_arp_slice_to_arp_tvalid),
.axi_arp_slice_to_arp_tready(axi_arp_slice_to_arp_tready),
.axi_arp_slice_to_arp_tdata(axi_arp_slice_to_arp_tdata),
.axi_arp_slice_to_arp_tkeep(axi_arp_slice_to_arp_tkeep),
.axi_arp_slice_to_arp_tlast(axi_arp_slice_to_arp_tlast),
.axis_arp_lookup_request_TVALID(axis_arp_lookup_request_TVALID),
.axis_arp_lookup_request_TREADY(axis_arp_lookup_request_TREADY),
.axis_arp_lookup_request_TDATA(axis_arp_lookup_request_TDATA),
.aclk(aclk), // input aclk
.aresetn(aresetn)); // input aresetn

assign  axi_debug1_tkeep    = axi_mie_to_intercon_tkeep;
assign  axi_debug1_tdata    = axi_mie_to_intercon_tdata;
assign  axi_debug1_tvalid   = axi_mie_to_intercon_tvalid;
assign  axi_debug1_tready   = axi_mie_to_intercon_tready;
assign  axi_debug1_tlast    = axi_mie_to_intercon_tlast;

assign  axi_debug2_tkeep    = axi_iph_to_udp_tkeep;
assign  axi_debug2_tdata    = axi_iph_to_udp_tdata;
assign  axi_debug2_tvalid   = axi_iph_to_udp_tvalid;
assign  axi_debug2_tready   = axi_iph_to_udp_tready;
assign  axi_debug2_tlast    = axi_iph_to_udp_tlast;

icmp_server_ip icmp_server_inst (
.dataOut_TVALID(axi_icmp_to_icmp_slice_tvalid),
.dataOut_TREADY(axi_icmp_to_icmp_slice_tready),
.dataOut_TDATA(axi_icmp_to_icmp_slice_tdata),
.dataOut_TKEEP(axi_icmp_to_icmp_slice_tkeep),
.dataOut_TLAST(axi_icmp_to_icmp_slice_tlast),
.dataIn_TVALID(axi_icmp_slice_to_icmp_tvalid),
.dataIn_TREADY(axi_icmp_slice_to_icmp_tready),
.dataIn_TDATA(axi_icmp_slice_to_icmp_tdata),
.dataIn_TKEEP(axi_icmp_slice_to_icmp_tkeep),
.dataIn_TLAST(axi_icmp_slice_to_icmp_tlast),
.udpIn_TVALID(axis_udp_to_icmp_tvalid),                    // input wire udpIn_TVALID
.udpIn_TREADY(axis_udp_to_icmp_tready),                    // output wire udpIn_TREADY
.udpIn_TDATA(axis_udp_to_icmp_tdata),                      // input wire [63 : 0] udpIn_TDATA
.udpIn_TKEEP(axis_udp_to_icmp_tkeep),                      // input wire [7 : 0] udpIn_TKEEP
.udpIn_TLAST(axis_udp_to_icmp_tlast),                      // input wire [0 : 0] udpIn_TLAST
.ttlIn_TVALID(axis_ttl_to_icmp_tvalid),         // input wire ttlIn_TVALID
.ttlIn_TREADY(axis_ttl_to_icmp_tready),         // output wire ttlIn_TREADY
.ttlIn_TDATA(axis_ttl_to_icmp_tdata),           // input wire [63 : 0] ttlIn_TDATA
.ttlIn_TKEEP(axis_ttl_to_icmp_tkeep),           // input wire [7 : 0] ttlIn_TKEEP
.ttlIn_TLAST(axis_ttl_to_icmp_tlast),           // input wire [0 : 0] ttlIn_TLAST
.ap_clk(aclk),                                    // input aclk
.ap_rst_n(aresetn)                              // input aresetn
);
   
/*
 * Slices
 */
 // ARP Input Slice
axis_register_slice_64 axis_register_arp_in_slice(
 .aclk(aclk),
 .aresetn(aresetn),
 .s_axis_tvalid(axi_iph_to_arp_slice_tvalid),
 .s_axis_tready(axi_iph_to_arp_slice_tready),
 .s_axis_tdata(axi_iph_to_arp_slice_tdata),
 .s_axis_tkeep(axi_iph_to_arp_slice_tkeep),
 .s_axis_tlast(axi_iph_to_arp_slice_tlast),
 .m_axis_tvalid(axi_arp_slice_to_arp_tvalid),
 .m_axis_tready(axi_arp_slice_to_arp_tready),
 .m_axis_tdata(axi_arp_slice_to_arp_tdata),
 .m_axis_tkeep(axi_arp_slice_to_arp_tkeep),
 .m_axis_tlast(axi_arp_slice_to_arp_tlast)
);
 // ICMP Input Slice
axis_register_slice_64 axis_register_icmp_in_slice(
  .aclk(aclk),
  .aresetn(aresetn),
  .s_axis_tvalid(axi_iph_to_icmp_slice_tvalid),
  .s_axis_tready(axi_iph_to_icmp_slice_tready),
  .s_axis_tdata(axi_iph_to_icmp_slice_tdata),
  .s_axis_tkeep(axi_iph_to_icmp_slice_tkeep),
  .s_axis_tlast(axi_iph_to_icmp_slice_tlast),
  .m_axis_tvalid(axi_icmp_slice_to_icmp_tvalid),
  .m_axis_tready(axi_icmp_slice_to_icmp_tready),
  .m_axis_tdata(axi_icmp_slice_to_icmp_tdata),
  .m_axis_tkeep(axi_icmp_slice_to_icmp_tkeep),
  .m_axis_tlast(axi_icmp_slice_to_icmp_tlast)
);
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/20/2014 10:35:44 AM
// Design Name: 
// Module Name: memcached_flash_top
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


module UoeMcdSingleDramPCIe_top 
(
input xphy_refclk_n,
input xphy_refclk_p,

//10G interface signals
output          xphy0_txp,
output          xphy0_txn,
input           xphy0_rxp,
input           xphy0_rxn,
    
output[1:0]     sfp_tx_disable,
output          sfp_on,

//pcie ports
input [7:0]pcie_7x_mgt_rxn,
input [7:0]pcie_7x_mgt_rxp,
output [7:0]pcie_7x_mgt_txn,
output [7:0]pcie_7x_mgt_txp,
input pcie_clkp,
input pcie_clkn,
input pcie_reset,

input             pok_dram, //used as reset to 
//dramp ports
   inout [71:0]                         c0_ddr3_dq,
   inout [8:0]                        c0_ddr3_dqs_n,
   inout [8:0]                        c0_ddr3_dqs_p,

   // Outputs
   output [15:0]                       c0_ddr3_addr,
   output [2:0]                      c0_ddr3_ba,
   output                                       c0_ddr3_ras_n,
   output                                       c0_ddr3_cas_n,
   output                                       c0_ddr3_we_n,
   output                                       c0_ddr3_reset_n,
   output [1:0]                        c0_ddr3_ck_p,
   output [1:0]                        c0_ddr3_ck_n,
   output [1:0]                       c0_ddr3_cke,
   output [1:0]           c0_ddr3_cs_n,
   output [1:0]                       c0_ddr3_odt,

   // Inputs
   
   // Differential system clocks
   input                                        c0_sys_clk_p,
   input                                        c0_sys_clk_n,
   // differential iodelayctrl clk (reference clock)
   input                                        clk_ref_p,
   input                                        clk_ref_n,
      
   // Inouts
   inout [71:0]                         c1_ddr3_dq,
   inout [8:0]                        c1_ddr3_dqs_n,
   inout [8:0]                        c1_ddr3_dqs_p,

   // Outputs
   output [15:0]                       c1_ddr3_addr,
   output [2:0]                      c1_ddr3_ba,
   output                                       c1_ddr3_ras_n,
   output                                       c1_ddr3_cas_n,
   output                                       c1_ddr3_we_n,
   output                                       c1_ddr3_reset_n,
   output [1:0]                        c1_ddr3_ck_p,
   output [1:0]                        c1_ddr3_ck_n,
   output [1:0]                       c1_ddr3_cke,
   output [1:0]           c1_ddr3_cs_n,
   output [1:0]                       c1_ddr3_odt,

   // Inputs
   
   // Differential system clocks
   input                                        c1_sys_clk_p,
   input                                        c1_sys_clk_n,
   output [8:0] c0_ddr3_dm,
   output [8:0] c1_ddr3_dm,
   output[1:0]  dram_on
    
);

wire clk156_buf, clk;
reg aresetn_r;
wire aresetn;

(*MARK_DEBUG="TRUE"*)wire network_init;

wire[31:0] systemIpAddress;
wire       systemIpAddress_valid;

/*
 * Network Signals
 */
(*MARK_DEBUG="TRUE"*)wire        AXI_M_Stream_TVALID;
(*MARK_DEBUG="TRUE"*)wire        AXI_M_Stream_TREADY;
wire[63:0]  AXI_M_Stream_TDATA;
wire[7:0]   AXI_M_Stream_TKEEP;
(*MARK_DEBUG="TRUE"*)wire        AXI_M_Stream_TLAST;

(*MARK_DEBUG="TRUE"*)wire        AXI_S_Stream_TVALID;
(*MARK_DEBUG="TRUE"*)wire        AXI_S_Stream_TREADY;
wire[63:0]  AXI_S_Stream_TDATA;
wire[7:0]   AXI_S_Stream_TKEEP;
(*MARK_DEBUG="TRUE"*)wire        AXI_S_Stream_TLAST;

 //rx status
(*MARK_DEBUG="TRUE"*)wire           nic_rx_fifo_overflow;
wire [29:0]   nic_rx_statistics_vector;
wire          nic_rx_statistics_valid;

/*
 * Application Signals
 */
 // listen&close port
  // open&close connection
wire        axis_listen_port_TVALID;
wire        axis_listen_port_TREADY;
wire[15:0]  axis_listen_port_TDATA;
wire        axis_listen_port_status_TVALID;
wire        axis_listen_port_status_TREADY;
wire[7:0]   axis_listen_port_status_TDATA;
 // notifications and pkg fetching
wire        axis_notifications_TVALID;
wire        axis_notifications_TREADY;
wire[87:0]  axis_notifications_TDATA;
wire        axis_read_package_TVALID;
wire        axis_read_package_TREADY;
wire[31:0]  axis_read_package_TDATA;
// open&close connection
wire        axis_open_connection_TVALID;
wire        axis_open_connection_TREADY;
wire[47:0]  axis_open_connection_TDATA;
wire        axis_open_status_TVALID;
wire        axis_open_status_TREADY;
wire[23:0]  axis_open_status_TDATA;
wire        axis_close_connection_TVALID;
wire        axis_close_connection_TREADY;
wire[15:0]  axis_close_connection_TDATA;
// rx data
wire        axis_rx_metadata_TVALID;
wire        axis_rx_metadata_TREADY;
wire[15:0]  axis_rx_metadata_TDATA;
wire        axis_rx_data_TVALID;
wire        axis_rx_data_TREADY;
wire[63:0]  axis_rx_data_TDATA;
wire[7:0]   axis_rx_data_TKEEP;
wire        axis_rx_data_TLAST;
// tx data
wire        axis_tx_metadata_TVALID;
wire        axis_tx_metadata_TREADY;
wire[31:0]  axis_tx_metadata_TDATA;
wire        axis_tx_data_TVALID;
wire        axis_tx_data_TREADY;
wire[63:0]  axis_tx_data_TDATA;
wire[7:0]   axis_tx_data_TKEEP;
wire        axis_tx_data_TLAST;
wire        axis_tx_status_TVALID;
wire        axis_tx_status_TREADY;
wire[23:0]  axis_tx_status_TDATA;

(*MARK_DEBUG="TRUE"*)wire[7:0]   rxDataOut_TKEEP;      // input wire [7 : 0] probe1
(*MARK_DEBUG="TRUE"*)wire[63:0]  rxDataOut_TDATA;      // input wire [63 : 0] probe0
wire[111:0]  rxDataOut_TUSER;      // input wire [111 : 0] probe0
(*MARK_DEBUG="TRUE"*)wire        rxDataOut_TVALID;    // input wire [0 : 0] probe2
(*MARK_DEBUG="TRUE"*)wire        rxDataOut_TREADY;    // output wire [0 : 0] probe3
(*MARK_DEBUG="TRUE"*)wire        rxDataOut_TLAST;      // input wire [0 : 0] probe4


//pcie related signals
wire pcie_clk;
wire pcie_user_lnk_up;
(*MARK_DEBUG="TRUE"*)reg pcie_user_lnk_up_r;
  
wire [31: 0] pcie_axi_AWADDR;
wire pcie_axi_AWVALID;
wire pcie_axi_AWREADY;

wire [31: 0]   pcie_axi_WDATA;
wire [3: 0] pcie_axi_WSTRB;
wire pcie_axi_WVALID;
wire pcie_axi_WREADY;

wire [1:0] pcie_axi_BRESP;
wire pcie_axi_BVALID;
wire pcie_axi_BREADY;
     
wire [31: 0] pcie_axi_ARADDR;
wire pcie_axi_ARVALID;
wire pcie_axi_ARREADY;
     
wire [31: 0] pcie_axi_RDATA;
wire [1:0] pcie_axi_RRESP;
wire pcie_axi_RVALID;
wire  pcie_axi_RREADY;

 //signals from and to kvsGenVer module
wire [31:0] device2host_data;	
wire device2host_valid;
wire device2host_ready;
        
wire [31:0] host2device_data;
wire host2device_valid;
wire host2device_ready;

//mem interface signals
wire           c0_ui_clk;
wire           c0_init_calib_complete;
(*MARK_DEBUG="TRUE"*)reg            c0_init_calib_complete_r;
wire           c1_ui_clk;
wire           c1_init_calib_complete;
(*MARK_DEBUG="TRUE"*)reg            c1_init_calib_complete_r;

(*MARK_DEBUG="TRUE"*)wire           ht_s_axis_read_cmd_tvalid;
(*MARK_DEBUG="TRUE"*)wire          ht_s_axis_read_cmd_tready;
wire[71:0]     ht_s_axis_read_cmd_tdata;
//read status
(*MARK_DEBUG="TRUE"*)wire          ht_m_axis_read_sts_tvalid;
(*MARK_DEBUG="TRUE"*)wire           ht_m_axis_read_sts_tready;
wire[7:0]     ht_m_axis_read_sts_tdata;
//read stream
wire[511:0]    ht_m_axis_read_tdata;
wire[63:0]     ht_m_axis_read_tkeep;
(*MARK_DEBUG="TRUE"*)wire          ht_m_axis_read_tlast;
(*MARK_DEBUG="TRUE"*)wire          ht_m_axis_read_tvalid;
(*MARK_DEBUG="TRUE"*)wire           ht_m_axis_read_tready;

//write commands
(*MARK_DEBUG="TRUE"*)wire           ht_s_axis_write_cmd_tvalid;
(*MARK_DEBUG="TRUE"*)wire          ht_s_axis_write_cmd_tready;
wire[71:0]     ht_s_axis_write_cmd_tdata;
//write status
(*MARK_DEBUG="TRUE"*)wire          ht_m_axis_write_sts_tvalid;
(*MARK_DEBUG="TRUE"*)wire           ht_m_axis_write_sts_tready;
wire[7:0]     ht_m_axis_write_sts_tdata;
//write stream
wire[511:0]     ht_s_axis_write_tdata;
wire[63:0]      ht_s_axis_write_tkeep;
(*MARK_DEBUG="TRUE"*)wire            ht_s_axis_write_tlast;
(*MARK_DEBUG="TRUE"*)wire            ht_s_axis_write_tvalid;
(*MARK_DEBUG="TRUE"*)wire           ht_s_axis_write_tready;

(*MARK_DEBUG="TRUE"*)wire           vs_s_axis_read_cmd_tvalid;
(*MARK_DEBUG="TRUE"*)wire          vs_s_axis_read_cmd_tready;
wire[71:0]     vs_s_axis_read_cmd_tdata;
//read status
(*MARK_DEBUG="TRUE"*)wire          vs_m_axis_read_sts_tvalid;
(*MARK_DEBUG="TRUE"*)wire           vs_m_axis_read_sts_tready;
wire[7:0]     vs_m_axis_read_sts_tdata;
//read stream
wire[511:0]    vs_m_axis_read_tdata;
wire[63:0]     vs_m_axis_read_tkeep;
(*MARK_DEBUG="TRUE"*)wire          vs_m_axis_read_tlast;
(*MARK_DEBUG="TRUE"*)wire          vs_m_axis_read_tvalid;
(*MARK_DEBUG="TRUE"*)wire           vs_m_axis_read_tready;

//write commands
(*MARK_DEBUG="TRUE"*)wire           vs_s_axis_write_cmd_tvalid;
(*MARK_DEBUG="TRUE"*)wire          vs_s_axis_write_cmd_tready;
wire[71:0]     vs_s_axis_write_cmd_tdata;
//write status
(*MARK_DEBUG="TRUE"*)wire          vs_m_axis_write_sts_tvalid;
(*MARK_DEBUG="TRUE"*)wire           vs_m_axis_write_sts_tready;
wire[7:0]     vs_m_axis_write_sts_tdata;
//write stream
wire[511:0]     vs_s_axis_write_tdata;
wire[63:0]      vs_s_axis_write_tkeep;
(*MARK_DEBUG="TRUE"*)wire            vs_s_axis_write_tlast;
(*MARK_DEBUG="TRUE"*)wire            vs_s_axis_write_tvalid;
(*MARK_DEBUG="TRUE"*)wire           vs_s_axis_write_tready;

eth10g_interface  n10g_interface_inst(
       .reset(1'b0),
       .aresetn(aresetn),
       
       .xphy_refclk_p(xphy_refclk_p),
       .xphy_refclk_n(xphy_refclk_n),
       
       .xphy0_txp(xphy0_txp),
       .xphy0_txn(xphy0_txn),
       .xphy0_rxp(xphy0_rxp),
       .xphy0_rxn(xphy0_rxn),
       
       
       .axis_i_0_tdata(AXI_S_Stream_TDATA),
       .axis_i_0_tvalid(AXI_S_Stream_TVALID),
       .axis_i_0_tlast(AXI_S_Stream_TLAST),
       .axis_i_0_tuser(),
       .axis_i_0_tkeep(AXI_S_Stream_TKEEP),
       .axis_i_0_tready(AXI_S_Stream_TREADY),
       .nic_rx_fifo_overflow(nic_rx_fifo_overflow),
       .nic_rx_statistics_vector(nic_rx_statistics_vector),
       .nic_rx_statistics_valid(nic_rx_statistics_valid),   
       
       .axis_o_0_tdata(AXI_M_Stream_TDATA),
       .axis_o_0_tvalid(AXI_M_Stream_TVALID),
       .axis_o_0_tlast(AXI_M_Stream_TLAST),
       .axis_o_0_tuser(0),
       .axis_o_0_tkeep(AXI_M_Stream_TKEEP),
       .axis_o_0_tready(AXI_M_Stream_TREADY),
           
       .sfp_tx_disable(sfp_tx_disable),
       .clk156_out(clk),
       .network_reset_done(network_init),
       .led()
       );
  
always @(posedge clk) begin
    c0_init_calib_complete_r <= c0_init_calib_complete;
    c1_init_calib_complete_r <= c1_init_calib_complete;
end
  
always @(posedge clk) begin
    pcie_user_lnk_up_r <= pcie_user_lnk_up;
end

always @(posedge clk) begin
    if (pcie_user_lnk_up_r & c0_init_calib_complete_r & c1_init_calib_complete_r & network_init)
        aresetn_r <= 1'b1;
    else
        aresetn_r <= 1'b0;
end

assign aresetn = aresetn_r;

assign sfp_on = 1'b1;
assign dram_on = 2'b11;

//manually tie off ddr3_dm
    assign c0_ddr3_dm = 9'b0;
    assign c1_ddr3_dm = 9'b0;


dram_inf mem_inf_inst (
.clk156_25(clk),
.reset156_25_n(aresetn),

.sys_rst(pcie_reset & pok_dram),
//ddr3 pins
// Differential system clocks
.c0_sys_clk_p(c0_sys_clk_p),
.c0_sys_clk_n(c0_sys_clk_n),
.c1_sys_clk_p(c1_sys_clk_p),
.c1_sys_clk_n(c1_sys_clk_n),

// differential iodelayctrl clk (reference clock)
.clk_ref_p(clk_ref_p),
.clk_ref_n(clk_ref_n),
//SODIMM 0
// Inouts
.c0_ddr3_dq(c0_ddr3_dq),
.c0_ddr3_dqs_n(c0_ddr3_dqs_n),
.c0_ddr3_dqs_p(c0_ddr3_dqs_p),

// Outputs
.c0_ddr3_addr(c0_ddr3_addr),
.c0_ddr3_ba(c0_ddr3_ba),
.c0_ddr3_ras_n(c0_ddr3_ras_n),
.c0_ddr3_cas_n(c0_ddr3_cas_n),
.c0_ddr3_we_n(c0_ddr3_we_n),
.c0_ddr3_reset_n(c0_ddr3_reset_n),
.c0_ddr3_ck_p(c0_ddr3_ck_p),
.c0_ddr3_ck_n(c0_ddr3_ck_n),
.c0_ddr3_cke(c0_ddr3_cke),
.c0_ddr3_cs_n(c0_ddr3_cs_n),
.c0_ddr3_odt(c0_ddr3_odt),
.c0_ui_clk(c0_ui_clk),
.c0_init_calib_complete(c0_init_calib_complete),

//SODIMM 1
// Inouts
.c1_ddr3_dq(c1_ddr3_dq),
.c1_ddr3_dqs_n(c1_ddr3_dqs_n),
.c1_ddr3_dqs_p(c1_ddr3_dqs_p),

// Outputs
.c1_ddr3_addr(c1_ddr3_addr),
.c1_ddr3_ba(c1_ddr3_ba),
.c1_ddr3_ras_n(c1_ddr3_ras_n),
.c1_ddr3_cas_n(c1_ddr3_cas_n),
.c1_ddr3_we_n(c1_ddr3_we_n),
.c1_ddr3_reset_n(c1_ddr3_reset_n),
.c1_ddr3_ck_p(c1_ddr3_ck_p),
.c1_ddr3_ck_n(c1_ddr3_ck_n),
.c1_ddr3_cke(c1_ddr3_cke),
.c1_ddr3_cs_n(c1_ddr3_cs_n),
.c1_ddr3_odt(c1_ddr3_odt),
//ui outputs
.c1_ui_clk(c1_ui_clk),
.c1_init_calib_complete(c1_init_calib_complete),

//ht stream interface signals
.ht_s_axis_read_cmd_tvalid(ht_s_axis_read_cmd_tvalid),
.ht_s_axis_read_cmd_tready(ht_s_axis_read_cmd_tready),
.ht_s_axis_read_cmd_tdata(ht_s_axis_read_cmd_tdata),
//read status
.ht_m_axis_read_sts_tvalid(ht_m_axis_read_sts_tvalid),
.ht_m_axis_read_sts_tready(ht_m_axis_read_sts_tready),
.ht_m_axis_read_sts_tdata(ht_m_axis_read_sts_tdata),
//read stream
.ht_m_axis_read_tdata(ht_m_axis_read_tdata),
.ht_m_axis_read_tkeep(ht_m_axis_read_tkeep),
.ht_m_axis_read_tlast(ht_m_axis_read_tlast),
.ht_m_axis_read_tvalid(ht_m_axis_read_tvalid),
.ht_m_axis_read_tready(ht_m_axis_read_tready),

//write commands
.ht_s_axis_write_cmd_tvalid(ht_s_axis_write_cmd_tvalid),
.ht_s_axis_write_cmd_tready(ht_s_axis_write_cmd_tready),
.ht_s_axis_write_cmd_tdata(ht_s_axis_write_cmd_tdata),
//write status
.ht_m_axis_write_sts_tvalid(ht_m_axis_write_sts_tvalid),
.ht_m_axis_write_sts_tready(ht_m_axis_write_sts_tready),
.ht_m_axis_write_sts_tdata(ht_m_axis_write_sts_tdata),
//write stream
.ht_s_axis_write_tdata(ht_s_axis_write_tdata),
.ht_s_axis_write_tkeep(ht_s_axis_write_tkeep),
.ht_s_axis_write_tlast(ht_s_axis_write_tlast),
.ht_s_axis_write_tvalid(ht_s_axis_write_tvalid),
.ht_s_axis_write_tready(ht_s_axis_write_tready),

//upd stream interface signals
.vs_s_axis_read_cmd_tvalid(vs_s_axis_read_cmd_tvalid),
.vs_s_axis_read_cmd_tready(vs_s_axis_read_cmd_tready),
.vs_s_axis_read_cmd_tdata(vs_s_axis_read_cmd_tdata),
//read status
.vs_m_axis_read_sts_tvalid(vs_m_axis_read_sts_tvalid),
.vs_m_axis_read_sts_tready(vs_m_axis_read_sts_tready),
.vs_m_axis_read_sts_tdata(vs_m_axis_read_sts_tdata),
//read stream
.vs_m_axis_read_tdata(vs_m_axis_read_tdata),
.vs_m_axis_read_tkeep(vs_m_axis_read_tkeep),
.vs_m_axis_read_tlast(vs_m_axis_read_tlast),
.vs_m_axis_read_tvalid(vs_m_axis_read_tvalid),
.vs_m_axis_read_tready(vs_m_axis_read_tready),

//write commands
.vs_s_axis_write_cmd_tvalid(vs_s_axis_write_cmd_tvalid),
.vs_s_axis_write_cmd_tready(vs_s_axis_write_cmd_tready),
.vs_s_axis_write_cmd_tdata(vs_s_axis_write_cmd_tdata),
//write status
.vs_m_axis_write_sts_tvalid(vs_m_axis_write_sts_tvalid),
.vs_m_axis_write_sts_tready(vs_m_axis_write_sts_tready),
.vs_m_axis_write_sts_tdata(vs_m_axis_write_sts_tdata),
//write stream
.vs_s_axis_write_tdata(vs_s_axis_write_tdata),
.vs_s_axis_write_tkeep(vs_s_axis_write_tkeep),
.vs_s_axis_write_tlast(vs_s_axis_write_tlast),
.vs_s_axis_write_tvalid(vs_s_axis_write_tvalid),
.vs_s_axis_write_tready(vs_s_axis_write_tready)
);


pcie_bridge pcie_bridge_inst(
    .pcie_7x_mgt_rxn(pcie_7x_mgt_rxn),
    .pcie_7x_mgt_rxp(pcie_7x_mgt_rxp),
    .pcie_7x_mgt_txn(pcie_7x_mgt_txn),
    .pcie_7x_mgt_txp(pcie_7x_mgt_txp),
    .pcie_clkp(pcie_clkp), 
    .pcie_clkn(pcie_clkn),
    .pcie_reset(~pcie_reset),
    
    .clkOut(pcie_clk),
    .user_lnk_up(pcie_user_lnk_up),
    
    .pcie_axi_AWADDR(pcie_axi_AWADDR),
    .pcie_axi_AWVALID(pcie_axi_AWVALID),
    .pcie_axi_AWREADY(pcie_axi_AWREADY),
       
    .pcie_axi_WDATA(pcie_axi_WDATA),
    .pcie_axi_WSTRB(pcie_axi_WSTRB),
    .pcie_axi_WVALID(pcie_axi_WVALID),
    .pcie_axi_WREADY(pcie_axi_WREADY),
      
    .pcie_axi_BRESP(pcie_axi_BRESP),
    .pcie_axi_BVALID(pcie_axi_BVALID),
    .pcie_axi_BREADY(pcie_axi_BREADY),
       
    .pcie_axi_ARADDR(pcie_axi_ARADDR),
    .pcie_axi_ARVALID(pcie_axi_ARVALID),
    .pcie_axi_ARREADY(pcie_axi_ARREADY),
       
    .pcie_axi_RDATA(pcie_axi_RDATA),
    .pcie_axi_RRESP(pcie_axi_RRESP),
    .pcie_axi_RVALID(pcie_axi_RVALID),
    .pcie_axi_RREADY(pcie_axi_RREADY)
   );


// Rx Side Data
wire        udp2muxRxDataIn_TVALID;
wire        udp2muxRxDataIn_TREADY;
wire[63:0]  udp2muxRxDataIn_TDATA;
wire        udp2muxRxDataIn_TLAST;
wire[7:0]   udp2muxRxDataIn_TKEEP;

wire        mux2dhcpRxDataIn_TVALID;
wire        mux2dhcpRxDataIn_TREADY;
wire[63:0]  mux2dhcpRxDataIn_TDATA;
wire        mux2dhcpRxDataIn_TLAST;
wire[7:0]   mux2dhcpRxDataIn_TKEEP;

wire        mux2shimRxDataIn_TVALID;
wire        mux2shimRxDataIn_TREADY;
wire[63:0]  mux2shimRxDataIn_TDATA;
wire        mux2shimRxDataIn_TLAST;
wire[7:0]   mux2shimRxDataIn_TKEEP;
/// Rx Side Metadata
wire        udp2muxRxMetadataIn_V_TVALID;
wire        udp2muxRxMetadataIn_V_TREADY;
wire[95:0]  udp2muxRxMetadataIn_V_TDATA;

wire        mux2dhcpRxMetadataIn_V_TVALID;
wire        mux2dhcpRxMetadataIn_V_TREADY;
wire[95:0]  mux2dhcpRxMetadataIn_V_TDATA;

wire        mux2shimRxMetadataIn_V_TVALID;
wire        mux2shimRxMetadataIn_V_TREADY;
wire[95:0]  mux2shimRxMetadataIn_V_TDATA;
/// Signals for opening ports ///
wire        mux2udp_requestPortOpenOut_V_TVALID;
wire        mux2udp_requestPortOpenOut_V_TREADY;
wire[15:0]  mux2udp_requestPortOpenOut_V_TDATA; // OK
wire        udp2mux_portOpenReplyIn_V_V_TVALID;
wire        udp2mux_portOpenReplyIn_V_V_TREADY;
wire[7:0]   udp2mux_portOpenReplyIn_V_V_TDATA; // OK

wire        dhcp2mux_requestPortOpenOut_V_TVALID;
wire        dhcp2mux_requestPortOpenOut_V_TREADY;
wire[15:0]  dhcp2mux_requestPortOpenOut_V_TDATA;
wire        mux2dhcp_portOpenReplyIn_V_V_TVALID;
wire        mux2dhcp_portOpenReplyIn_V_V_TREADY;
wire[7:0]   mux2dhcp_portOpenReplyIn_V_V_TDATA;

wire        shim2mux_requestPortOpenOut_V_TVALID;
wire        shim2mux_requestPortOpenOut_V_TREADY;
wire[15:0]  shim2mux_requestPortOpenOut_V_TDATA;
wire        mux2shim_portOpenReplyIn_V_V_TVALID;
wire        mux2shim_portOpenReplyIn_V_V_TREADY;
wire[7:0]   mux2shim_portOpenReplyIn_V_V_TDATA;

(*MARK_DEBUG="TRUE"*)wire        mcd_to_shim_TVALID;
(*MARK_DEBUG="TRUE"*)wire        mcd_to_shim_TREADY;
wire[63:0]  mcd_to_shim_TDATA;
wire[7:0]   mcd_to_shim_TKEEP;
(*MARK_DEBUG="TRUE"*)wire        mcd_to_shim_TLAST;
wire[111:0] mcd_to_shim_TUSER;
/// Signals for connecting the data i/o's to the mux
wire        shim2mux_TVALID;
wire        shim2mux_TREADY;
wire[63:0]  shim2mux_TDATA;
wire[7:0]   shim2mux_TKEEP;
wire        shim2mux_TLAST;

wire        dhcp2mux_TVALID;
wire        dhcp2mux_TREADY;
wire[63:0]  dhcp2mux_TDATA;
wire[7:0]   dhcp2mux_TKEEP;
wire        dhcp2mux_TLAST;

wire        mux2udp_TVALID;
wire        mux2udp_TREADY;
wire[63:0]  mux2udp_TDATA;
wire[7:0]   mux2udp_TKEEP;
wire        mux2udp_TLAST;
//// Tx Side Metadata
wire        mux2udpTxMetadataOut_V_TVALID;
wire        mux2udpTxMetadataOut_V_TREADY;
wire[95:0]  mux2udpTxMetadataOut_V_TDATA;

wire        dhcp2muxTxMetadataOut_V_TVALID;
wire        dhcp2muxTxMetadataOut_V_TREADY;
wire[95:0]  dhcp2muxTxMetadataOut_V_TDATA;

wire        shim2muxTxMetadataOut_V_TVALID;
wire        shim2muxTxMetadataOut_V_TREADY;
wire[95:0]  shim2muxTxMetadataOut_V_TDATA;
/// Tx Side Packet Length
wire        mux2udpTxLengthOut_V_V_TVALID;
wire        mux2udpTxLengthOut_V_V_TREADY;
wire[15:0]  mux2udpTxLengthOut_V_V_TDATA;

wire        dhcp2muxTxLengthOut_V_V_TVALID;
wire        dhcp2muxTxLengthOut_V_V_TREADY;
wire[15:0]  dhcp2muxTxLengthOut_V_V_TDATA;

wire        shim2muxTxLengthOut_V_V_TVALID;
wire        shim2muxTxLengthOut_V_V_TREADY;
wire[15:0]  shim2muxTxLengthOut_V_V_TDATA;

wire testReset;

/*
 * TCP/IP Wrapper Module
 */
wire [15:0] regSessionCount_V;
wire regSessionCount_V_ap_vld;

wire[7:0]   axi_debug1_tkeep;
wire[63:0]  axi_debug1_tdata;
wire        axi_debug1_tvalid;
wire        axi_debug1_tready;
wire        axi_debug1_tlast;

wire[7:0]   axi_debug2_tkeep;
wire[63:0]  axi_debug2_tdata;
wire        axi_debug2_tvalid;
wire        axi_debug2_tready;
wire        axi_debug2_tlast;

tcp_ip_wrapper tcp_ip_inst(
.aclk           (clk),
//.reset           (reset),
.aresetn           (aresetn),
// Debug streams
.axi_debug1_tkeep(axi_debug1_tkeep),  // input wire [7 : 0] probe1
.axi_debug1_tdata(axi_debug1_tdata),  // input wire [63 : 0] probe0
.axi_debug1_tvalid(axi_debug1_tvalid),  // input wire [0 : 0] probe2
.axi_debug1_tready(axi_debug1_tready),  // input wire [0 : 0] probe3
.axi_debug1_tlast(axi_debug1_tlast),  // input wire [0 : 0] probe4
.axi_debug2_tkeep(axi_debug2_tkeep),  // input wire [7 : 0] probe1
.axi_debug2_tdata(axi_debug2_tdata),  // input wire [63 : 0] probe0
.axi_debug2_tvalid(axi_debug2_tvalid),  // input wire [0 : 0] probe2
.axi_debug2_tready(axi_debug2_tready),  // input wire [0 : 0] probe3
.axi_debug2_tlast(axi_debug2_tlast),  // input wire [0 : 0] probe4
// network interface streams
.AXI_M_Stream_TVALID           (AXI_M_Stream_TVALID),
.AXI_M_Stream_TREADY           (AXI_M_Stream_TREADY),
.AXI_M_Stream_TDATA           (AXI_M_Stream_TDATA),
.AXI_M_Stream_TKEEP           (AXI_M_Stream_TKEEP),
.AXI_M_Stream_TLAST           (AXI_M_Stream_TLAST),

.AXI_S_Stream_TVALID           (AXI_S_Stream_TVALID),
.AXI_S_Stream_TREADY           (AXI_S_Stream_TREADY),
.AXI_S_Stream_TDATA           (AXI_S_Stream_TDATA),
.AXI_S_Stream_TKEEP           (AXI_S_Stream_TKEEP),
.AXI_S_Stream_TLAST           (AXI_S_Stream_TLAST),
// UDP Core App I/F //
.rxDataIn_TVALID(udp2muxRxDataIn_TVALID),                          // output wire rxDataIn_TVALID
.rxDataIn_TREADY(udp2muxRxDataIn_TREADY),                          // input wire rxDataIn_TREADY
.rxDataIn_TDATA(udp2muxRxDataIn_TDATA),                            // output wire [63 : 0] rxDataIn_TDATA
.rxDataIn_TLAST(udp2muxRxDataIn_TLAST),                            // output wire [0 : 0] rxDataIn_TLAST
.rxDataIn_TKEEP(udp2muxRxDataIn_TKEEP),                            // output wire [7 : 0] rxDataIn_TKEEP
.rxMetadataIn_V_TVALID(udp2muxRxMetadataIn_V_TVALID),              // output wire rxMetadataIn_V_TVALID
.rxMetadataIn_V_TREADY(udp2muxRxMetadataIn_V_TREADY),              // input wire rxMetadataIn_V_TREADY
.rxMetadataIn_V_TDATA(udp2muxRxMetadataIn_V_TDATA),                // output wire [95 : 0] rxMetadataIn_V_TDATA
.requestPortOpenOut_V_TVALID(mux2udp_requestPortOpenOut_V_TVALID),  // input wire requestPortOpenOut_V_TVALID
.requestPortOpenOut_V_TREADY(mux2udp_requestPortOpenOut_V_TREADY),  // output wire requestPortOpenOut_V_TREADY
.requestPortOpenOut_V_TDATA(mux2udp_requestPortOpenOut_V_TDATA),    // input wire [15 : 0] requestPortOpenOut_V_TDATA //OK
.portOpenReplyIn_V_V_TVALID(udp2mux_portOpenReplyIn_V_V_TVALID),    // output wire portOpenReplyIn_V_V_TVALID
.portOpenReplyIn_V_V_TREADY(udp2mux_portOpenReplyIn_V_V_TREADY),    // input wire portOpenReplyIn_V_V_TREADY
.portOpenReplyIn_V_V_TDATA(udp2mux_portOpenReplyIn_V_V_TDATA),      // output wire [7 : 0] portOpenReplyIn_V_V_TDATA //OK
.udpTxDataOut_TVALID(mux2udp_TVALID),
.udpTxDataOut_TREADY(mux2udp_TREADY),
.udpTxDataOut_TDATA(mux2udp_TDATA),
.udpTxDataOut_TKEEP(mux2udp_TKEEP),
.udpTxDataOut_TLAST(mux2udp_TLAST),
.udpTxMetadataOut_V_TVALID(mux2udpTxMetadataOut_V_TVALID),
.udpTxMetadataOut_V_TREADY(mux2udpTxMetadataOut_V_TREADY),
.udpTxMetadataOut_V_TDATA(mux2udpTxMetadataOut_V_TDATA),
.udpTxLengthOut_V_V_TVALID(mux2udpTxLengthOut_V_V_TVALID),
.udpTxLengthOut_V_V_TREADY(mux2udpTxLengthOut_V_V_TREADY),
.udpTxLengthOut_V_V_TDATA(mux2udpTxLengthOut_V_V_TDATA));

wire [31:0] stats0;
//stats 0 sits between network extractor and pipeline
stats_module #(.data_size(64)) stats_module_i0( 
.ACLK(clk),
.RESET(~aresetn),

.M_AXIS_TDATA(), 
.M_AXIS_TVALID(),
.M_AXIS_TREADY(rxDataOut_TREADY),

.S_AXIS_TDATA(rxDataOut_TDATA),
.S_AXIS_TVALID(rxDataOut_TVALID),
.S_AXIS_TREADY(),

.STATS_DATA(stats0)
);

wire [31:0] stats1;
//stats 1 sits between network extractor and pipeline
stats_module #(.data_size(64)) stats_module_i1( 
.ACLK(clk),
.RESET(~aresetn),

.M_AXIS_TDATA(), 
.M_AXIS_TVALID(),
.M_AXIS_TREADY(mcd_to_shim_TREADY),

.S_AXIS_TDATA(mcd_to_shim_TDATA),
.S_AXIS_TVALID(mcd_to_shim_TVALID),
.S_AXIS_TREADY(),

.STATS_DATA(stats1)
);

mcdSingleDramPCIe mcd_inst (
 .clk(clk),                                         // input wire aclk
 .aresetn(aresetn),                                      // input wire aresetn
 .AXI_M_Stream_TVALID(mcd_to_shim_TVALID),
 .AXI_M_Stream_TREADY(mcd_to_shim_TREADY),
 .AXI_M_Stream_TDATA(mcd_to_shim_TDATA),
 .AXI_M_Stream_TKEEP(mcd_to_shim_TKEEP),
 .AXI_M_Stream_TUSER(mcd_to_shim_TUSER),
 .AXI_M_Stream_TLAST(mcd_to_shim_TLAST),
 
 .AXI_S_Stream_TVALID(rxDataOut_TVALID),
 .AXI_S_Stream_TREADY(rxDataOut_TREADY),
 .AXI_S_Stream_TDATA(rxDataOut_TDATA),
 .AXI_S_Stream_TKEEP(rxDataOut_TKEEP),
 .AXI_S_Stream_TUSER(rxDataOut_TUSER),
 .AXI_S_Stream_TLAST(rxDataOut_TLAST),
 
 //stats signals
.stats0(stats0),
.stats1(stats1),
 
 //pcie interface
 .pcie_axi_AWADDR(pcie_axi_AWADDR),
 .pcie_axi_AWVALID(pcie_axi_AWVALID),
 .pcie_axi_AWREADY(pcie_axi_AWREADY),
 
 //data write
 .pcie_axi_WDATA(pcie_axi_WDATA),
 .pcie_axi_WSTRB(pcie_axi_WSTRB),
 .pcie_axi_WVALID(pcie_axi_WVALID),
 .pcie_axi_WREADY(pcie_axi_WREADY),
 
 //write response (handhake)
 .pcie_axi_BRESP(pcie_axi_BRESP),
 .pcie_axi_BVALID(pcie_axi_BVALID),
 .pcie_axi_BREADY(pcie_axi_BREADY),
 
 //address read
 .pcie_axi_ARADDR(pcie_axi_ARADDR),
 .pcie_axi_ARVALID(pcie_axi_ARVALID),
 .pcie_axi_ARREADY(pcie_axi_ARREADY),
 
 //data read
 .pcie_axi_RDATA(pcie_axi_RDATA),
 .pcie_axi_RRESP(pcie_axi_RRESP),
 .pcie_axi_RVALID(pcie_axi_RVALID),
 .pcie_axi_RREADY(pcie_axi_RREADY),
 .pcieClk(pcie_clk),
 .pcie_user_lnk_up(pcie_user_lnk_up),
 
 //signals to DRAM memory interface
 //ht stream interface signals
 .ht_s_axis_read_cmd_tvalid(ht_s_axis_read_cmd_tvalid),
 .ht_s_axis_read_cmd_tready(ht_s_axis_read_cmd_tready),
 .ht_s_axis_read_cmd_tdata(ht_s_axis_read_cmd_tdata),
 //read status
 .ht_m_axis_read_sts_tvalid(ht_m_axis_read_sts_tvalid),
 .ht_m_axis_read_sts_tready(ht_m_axis_read_sts_tready),
 .ht_m_axis_read_sts_tdata(ht_m_axis_read_sts_tdata),
 //read stream
 .ht_m_axis_read_tdata(ht_m_axis_read_tdata),
 .ht_m_axis_read_tkeep(ht_m_axis_read_tkeep),
 .ht_m_axis_read_tlast(ht_m_axis_read_tlast),
 .ht_m_axis_read_tvalid(ht_m_axis_read_tvalid),
 .ht_m_axis_read_tready(ht_m_axis_read_tready),
 
 //write commands
 .ht_s_axis_write_cmd_tvalid(ht_s_axis_write_cmd_tvalid),
 .ht_s_axis_write_cmd_tready(ht_s_axis_write_cmd_tready),
 .ht_s_axis_write_cmd_tdata(ht_s_axis_write_cmd_tdata),
 //write status
.ht_m_axis_write_sts_tvalid(ht_m_axis_write_sts_tvalid),
.ht_m_axis_write_sts_tready(ht_m_axis_write_sts_tready),
.ht_m_axis_write_sts_tdata(ht_m_axis_write_sts_tdata),
 //write stream
.ht_s_axis_write_tdata(ht_s_axis_write_tdata),
.ht_s_axis_write_tkeep(ht_s_axis_write_tkeep),
.ht_s_axis_write_tlast(ht_s_axis_write_tlast),
.ht_s_axis_write_tvalid(ht_s_axis_write_tvalid),
.ht_s_axis_write_tready(ht_s_axis_write_tready),
 
 //vs stream interface signals
.vs_s_axis_read_cmd_tvalid(vs_s_axis_read_cmd_tvalid),
.vs_s_axis_read_cmd_tready(vs_s_axis_read_cmd_tready),
.vs_s_axis_read_cmd_tdata(vs_s_axis_read_cmd_tdata),
 //read status
.vs_m_axis_read_sts_tvalid(vs_m_axis_read_sts_tvalid),
.vs_m_axis_read_sts_tready(vs_m_axis_read_sts_tready),
.vs_m_axis_read_sts_tdata(vs_m_axis_read_sts_tdata),
 //read stream
.vs_m_axis_read_tdata(vs_m_axis_read_tdata),
.vs_m_axis_read_tkeep(vs_m_axis_read_tkeep),
.vs_m_axis_read_tlast(vs_m_axis_read_tlast),
.vs_m_axis_read_tvalid(vs_m_axis_read_tvalid),
.vs_m_axis_read_tready(vs_m_axis_read_tready),
 
 //write commands
.vs_s_axis_write_cmd_tvalid(vs_s_axis_write_cmd_tvalid),
.vs_s_axis_write_cmd_tready(vs_s_axis_write_cmd_tready),
.vs_s_axis_write_cmd_tdata(vs_s_axis_write_cmd_tdata),
 //write status
.vs_m_axis_write_sts_tvalid(vs_m_axis_write_sts_tvalid),
.vs_m_axis_write_sts_tready(vs_m_axis_write_sts_tready),
.vs_m_axis_write_sts_tdata(vs_m_axis_write_sts_tdata),
 //write stream
.vs_s_axis_write_tdata(vs_s_axis_write_tdata),
.vs_s_axis_write_tkeep(vs_s_axis_write_tkeep),
.vs_s_axis_write_tlast(vs_s_axis_write_tlast),
.vs_s_axis_write_tvalid(vs_s_axis_write_tvalid),
.vs_s_axis_write_tready(vs_s_axis_write_tready)
 );
 
 udpAppMux_0 myAppMux (
 //udpappmux_top myAppMux (
   .portOpenReplyIn_TVALID(udp2mux_portOpenReplyIn_V_V_TVALID),                  // input wire portOpenReplyIn_TVALID
   .portOpenReplyIn_TREADY(udp2mux_portOpenReplyIn_V_V_TREADY),                  // output wire portOpenReplyIn_TREADY
   .portOpenReplyIn_TDATA(udp2mux_portOpenReplyIn_V_V_TDATA),                    // input wire [7 : 0] portOpenReplyIn_TDATA             // OK
   .requestPortOpenOut_TVALID(mux2udp_requestPortOpenOut_V_TVALID),              // output wire requestPortOpenOut_TVALID
   .requestPortOpenOut_TREADY(mux2udp_requestPortOpenOut_V_TREADY),              // input wire requestPortOpenOut_TREADY
   .requestPortOpenOut_TDATA(mux2udp_requestPortOpenOut_V_TDATA),                // output wire [15 : 0] requestPortOpenOut_TDATA        // OK
   
   .portOpenReplyOutApp_TVALID(mux2shim_portOpenReplyIn_V_V_TVALID),             // output wire portOpenReplyOutApp_TVALID
   .portOpenReplyOutApp_TREADY(mux2shim_portOpenReplyIn_V_V_TREADY),             // input wire portOpenReplyOutApp_TREADY
   .portOpenReplyOutApp_TDATA(mux2shim_portOpenReplyIn_V_V_TDATA),               // output wire [7 : 0] portOpenReplyOutApp_TDATA        // OK
   .requestPortOpenInApp_TVALID(shim2mux_requestPortOpenOut_V_TVALID),           // input wire requestPortOpenInApp_TVALID
   .requestPortOpenInApp_TREADY(shim2mux_requestPortOpenOut_V_TREADY),           // output wire requestPortOpenInApp_TREADY
   .requestPortOpenInApp_TDATA(shim2mux_requestPortOpenOut_V_TDATA),             // input wire [15 : 0] requestPortOpenInApp_TDATA       // OK (Comment width is correct)
     
   .portOpenReplyOutDhcp_TVALID(mux2dhcp_portOpenReplyIn_V_V_TVALID),            // output wire portOpenReplyOutDhcp_TVALID
   .portOpenReplyOutDhcp_TREADY(mux2dhcp_portOpenReplyIn_V_V_TREADY),            // input wire portOpenReplyOutDhcp_TREADY
   .portOpenReplyOutDhcp_TDATA(mux2dhcp_portOpenReplyIn_V_V_TDATA),              // output wire [7 : 0] portOpenReplyOutDhcp_TDATA
   .requestPortOpenInDhcp_TVALID(dhcp2mux_requestPortOpenOut_V_TVALID),          // input wire requestPortOpenInDhcp_TVALID
   .requestPortOpenInDhcp_TREADY(dhcp2mux_requestPortOpenOut_V_TREADY),          // output wire requestPortOpenInDhcp_TREADY
   .requestPortOpenInDhcp_TDATA(dhcp2mux_requestPortOpenOut_V_TDATA),            // input wire [15 : 0] requestPortOpenInDhcp_TDATA
   .rxDataIn_TVALID(udp2muxRxDataIn_TVALID),                               // input wire rxDataIn_TVALID
   .rxDataIn_TREADY(udp2muxRxDataIn_TREADY),                               // output wire rxDataIn_TREADY
   .rxDataIn_TDATA(udp2muxRxDataIn_TDATA),                                // input wire [63 : 0] rxDataIn_TDATA
   .rxDataIn_TKEEP(udp2muxRxDataIn_TKEEP),                                // input wire [7 : 0] rxDataIn_TKEEP
   .rxDataIn_TLAST(udp2muxRxDataIn_TLAST),                                // input wire [0 : 0] rxDataIn_TLAST
   .rxDataOutApp_TVALID(mux2shimRxDataIn_TVALID),                           // output wire rxDataOutApp_TVALID
   .rxDataOutApp_TREADY(mux2shimRxDataIn_TREADY),                           // input wire rxDataOutApp_TREADY
   .rxDataOutApp_TDATA(mux2shimRxDataIn_TDATA),                            // output wire [63 : 0] rxDataOutApp_TDATA
   .rxDataOutApp_TKEEP(mux2shimRxDataIn_TKEEP),                            // output wire [7 : 0] rxDataOutApp_TKEEP
   .rxDataOutApp_TLAST(mux2shimRxDataIn_TLAST),                            // output wire [0 : 0] rxDataOutApp_TLAST
   .rxDataOutDhcp_TVALID(mux2dhcpRxDataIn_TVALID),                          // output wire rxDataOutDhcp_TVALID
   .rxDataOutDhcp_TREADY(mux2dhcpRxDataIn_TREADY),                          // input wire rxDataOutDhcp_TREADY
   .rxDataOutDhcp_TDATA(mux2dhcpRxDataIn_TDATA),                           // output wire [63 : 0] rxDataOutDhcp_TDATA
   .rxDataOutDhcp_TKEEP(mux2dhcpRxDataIn_TKEEP),                           // output wire [7 : 0] rxDataOutDhcp_TKEEP
   .rxDataOutDhcp_TLAST(mux2dhcpRxDataIn_TLAST),                           // output wire [0 : 0] rxDataOutDhcp_TLAST
   .rxMetadataIn_TVALID(udp2muxRxMetadataIn_V_TVALID),                           // input wire rxMetadataIn_TVALID
   .rxMetadataIn_TREADY(udp2muxRxMetadataIn_V_TREADY),                           // output wire rxMetadataIn_TREADY
   .rxMetadataIn_TDATA(udp2muxRxMetadataIn_V_TDATA),                            // input wire [95 : 0] rxMetadataIn_TDATA
   .rxMetadataOutApp_TVALID(mux2shimRxMetadataIn_V_TVALID),                       // output wire rxMetadataOutApp_TVALID
   .rxMetadataOutApp_TREADY(mux2shimRxMetadataIn_V_TREADY),                       // input wire rxMetadataOutApp_TREADY
   .rxMetadataOutApp_TDATA(mux2shimRxMetadataIn_V_TDATA),                        // output wire [95 : 0] rxMetadataOutApp_TDATA
   .rxMetadataOutDhcp_TVALID(mux2dhcpRxMetadataIn_V_TVALID),                      // output wire rxMetadataOutDhcp_TVALID
   .rxMetadataOutDhcp_TREADY(mux2dhcpRxMetadataIn_V_TREADY),                      // input wire rxMetadataOutDhcp_TREADY
   .rxMetadataOutDhcp_TDATA(mux2dhcpRxMetadataIn_V_TDATA),                       // output wire [95 : 0] rxMetadataOutDhcp_TDATA
   .txDataInApp_TVALID(shim2mux_TVALID),                            // input wire txDataInApp_TVALID
   .txDataInApp_TREADY(shim2mux_TREADY),                            // output wire txDataInApp_TREADY
   .txDataInApp_TDATA(shim2mux_TDATA),                             // input wire [63 : 0] txDataInApp_TDATA
   .txDataInApp_TKEEP(shim2mux_TKEEP),                             // input wire [7 : 0] txDataInApp_TKEEP
   .txDataInApp_TLAST(shim2mux_TLAST),                             // input wire [0 : 0] txDataInApp_TLAST
   .txDataInDhcp_TVALID(dhcp2mux_TVALID),                           // input wire txDataInDhcp_TVALID
   .txDataInDhcp_TREADY(dhcp2mux_TREADY),                           // output wire txDataInDhcp_TREADY
   .txDataInDhcp_TDATA(dhcp2mux_TDATA),                            // input wire [63 : 0] txDataInDhcp_TDATA
   .txDataInDhcp_TKEEP(dhcp2mux_TKEEP),                            // input wire [7 : 0] txDataInDhcp_TKEEP
   .txDataInDhcp_TLAST(dhcp2mux_TLAST),                            // input wire [0 : 0] txDataInDhcp_TLAST
   .txDataOut_TVALID(mux2udp_TVALID),                              // output wire txDataOut_TVALID
   .txDataOut_TREADY(mux2udp_TREADY),                              // input wire txDataOut_TREADY
   .txDataOut_TDATA(mux2udp_TDATA),                               // output wire [63 : 0] txDataOut_TDATA
   .txDataOut_TKEEP(mux2udp_TKEEP),                               // output wire [7 : 0] txDataOut_TKEEP
   .txDataOut_TLAST(mux2udp_TLAST),                               // output wire [0 : 0] txDataOut_TLAST
   .txLengthInApp_TVALID(shim2muxTxLengthOut_V_V_TVALID),                            // input wire txLengthInApp_TVALID
   .txLengthInApp_TREADY(shim2muxTxLengthOut_V_V_TREADY),                            // output wire txLengthInApp_TREADY
   .txLengthInApp_TDATA(shim2muxTxLengthOut_V_V_TDATA),                              // input wire [15 : 0] txLengthInApp_TDATA
   .txLengthInDhcp_TVALID(dhcp2muxTxLengthOut_V_V_TVALID),                           // input wire txLengthInDhcp_TVALID
   .txLengthInDhcp_TREADY(dhcp2muxTxLengthOut_V_V_TREADY),                           // output wire txLengthInDhcp_TREADY
   .txLengthInDhcp_TDATA(dhcp2muxTxLengthOut_V_V_TDATA),                             // input wire [15 : 0] txLengthInDhcp_TDATA
   .txLengthOut_TVALID(mux2udpTxLengthOut_V_V_TVALID),                               // output wire txLengthOut_TVALID
   .txLengthOut_TREADY(mux2udpTxLengthOut_V_V_TREADY),                               // input wire txLengthOut_TREADY
   .txLengthOut_TDATA(mux2udpTxLengthOut_V_V_TDATA),                                 // output wire [15 : 0] txLengthOut_TDATA
   .txMetadataInApp_TVALID(shim2muxTxMetadataOut_V_TVALID),                        // input wire txMetadataInApp_TVALID
   .txMetadataInApp_TREADY(shim2muxTxMetadataOut_V_TREADY),                        // output wire txMetadataInApp_TREADY
   .txMetadataInApp_TDATA(shim2muxTxMetadataOut_V_TDATA),                         // input wire [95 : 0] txMetadataInApp_TDATA
   .txMetadataInDhcp_TVALID(dhcp2muxTxMetadataOut_V_TVALID),                       // input wire txMetadataInDhcp_TVALID
   .txMetadataInDhcp_TREADY(dhcp2muxTxMetadataOut_V_TREADY),                       // output wire txMetadataInDhcp_TREADY
   .txMetadataInDhcp_TDATA(dhcp2muxTxMetadataOut_V_TDATA),                        // input wire [95 : 0] txMetadataInDhcp_TDATA
   .txMetadataOut_TVALID(mux2udpTxMetadataOut_V_TVALID),                          // output wire txMetadataOut_TVALID
   .txMetadataOut_TREADY(mux2udpTxMetadataOut_V_TREADY),                          // input wire txMetadataOut_TREADY
   .txMetadataOut_TDATA(mux2udpTxMetadataOut_V_TDATA),                           // output wire [95 : 0] txMetadataOut_TDATA
   .aclk(clk),                                   // input wire aclk
   .aresetn(aresetn)                                 // input wire aresetn
 );

dhcp_client_0 myDhcpClient (
  .dhcpEnable_V(1'b0),
  .inputIpAddress_V(32'b0),
  .dhcpIpAddressOut_V(systemIpAddress),                          // output wire [31 : 0] dhcpIpAddressOut_V
  .myMacAddress_V(48'hE59D02350A00),
  .m_axis_open_port_TVALID(dhcp2mux_requestPortOpenOut_V_TVALID),                // output wire m_axis_open_port_TVALID
  .m_axis_open_port_TREADY(dhcp2mux_requestPortOpenOut_V_TREADY),                // input wire m_axis_open_port_TREADY
  .m_axis_open_port_TDATA(dhcp2mux_requestPortOpenOut_V_TDATA),                  // output wire [15 : 0] m_axis_open_port_TDATA
  .m_axis_tx_data_TVALID(dhcp2mux_TVALID),                    // output wire m_axis_tx_data_TVALID
  .m_axis_tx_data_TREADY(dhcp2mux_TREADY),                    // input wire m_axis_tx_data_TREADY
  .m_axis_tx_data_TDATA(dhcp2mux_TDATA),                      // output wire [63 : 0] m_axis_tx_data_TDATA
  .m_axis_tx_data_TKEEP(dhcp2mux_TKEEP),                      // output wire [7 : 0] m_axis_tx_data_TKEEP
  .m_axis_tx_data_TLAST(dhcp2mux_TLAST),                      // output wire [0 : 0] m_axis_tx_data_TLAST
  .m_axis_tx_length_TVALID(dhcp2muxTxLengthOut_V_V_TVALID),                // output wire m_axis_tx_length_TVALID
  .m_axis_tx_length_TREADY(dhcp2muxTxLengthOut_V_V_TREADY),                // input wire m_axis_tx_length_TREADY
  .m_axis_tx_length_TDATA(dhcp2muxTxLengthOut_V_V_TDATA),                  // output wire [15 : 0] m_axis_tx_length_TDATA
  .m_axis_tx_metadata_TVALID(dhcp2muxTxMetadataOut_V_TVALID),            // output wire m_axis_tx_metadata_TVALID
  .m_axis_tx_metadata_TREADY(dhcp2muxTxMetadataOut_V_TREADY),            // input wire m_axis_tx_metadata_TREADY
  .m_axis_tx_metadata_TDATA(dhcp2muxTxMetadataOut_V_TDATA),              // output wire [95 : 0] m_axis_tx_metadata_TDATA
  .s_axis_open_port_status_TVALID(mux2dhcp_portOpenReplyIn_V_V_TVALID),  // input wire s_axis_open_port_status_TVALID
  .s_axis_open_port_status_TREADY(mux2dhcp_portOpenReplyIn_V_V_TREADY),  // output wire s_axis_open_port_status_TREADY
  .s_axis_open_port_status_TDATA(mux2dhcp_portOpenReplyIn_V_V_TDATA),    // input wire [7 : 0] s_axis_open_port_status_TDATA
  .s_axis_rx_data_TVALID(mux2dhcpRxDataIn_TVALID),                    // input wire s_axis_rx_data_TVALID
  .s_axis_rx_data_TREADY(mux2dhcpRxDataIn_TREADY),                    // output wire s_axis_rx_data_TREADY
  .s_axis_rx_data_TDATA(mux2dhcpRxDataIn_TDATA),                      // input wire [63 : 0] s_axis_rx_data_TDATA
  .s_axis_rx_data_TKEEP(mux2dhcpRxDataIn_TKEEP),                      // input wire [7 : 0] s_axis_rx_data_TKEEP
  .s_axis_rx_data_TLAST(mux2dhcpRxDataIn_TLAST),                      // input wire [0 : 0] s_axis_rx_data_TLAST
  .s_axis_rx_metadata_TVALID(mux2dhcpRxMetadataIn_V_TVALID),            // input wire s_axis_rx_metadata_TVALID
  .s_axis_rx_metadata_TREADY(mux2dhcpRxMetadataIn_V_TREADY),            // output wire s_axis_rx_metadata_TREADY
  .s_axis_rx_metadata_TDATA(mux2dhcpRxMetadataIn_V_TDATA),              // input wire [95 : 0] s_axis_rx_metadata_TDATA
  .aclk(clk),                                                      // input wire aclk
  .aresetn(aresetn)                                                // input wire aresetn
);

//udpShim_ip myShim (
udpShim_ip myShim (
//udpshim_top myShim (
  .portOpenReplyIn_TVALID(mux2shim_portOpenReplyIn_V_V_TVALID),       // input wire portOpenReplyIn_V_V_TVALID
  .portOpenReplyIn_TREADY(mux2shim_portOpenReplyIn_V_V_TREADY),       // output wire portOpenReplyIn_V_V_TREADY
  .portOpenReplyIn_TDATA(mux2shim_portOpenReplyIn_V_V_TDATA),         // input wire portOpenReplyIn_V_V_TDATA
  .requestPortOpenOut_TVALID(shim2mux_requestPortOpenOut_V_TVALID),   // output wire [15:0] requestPortOpenOut_V_TVALID//
  .requestPortOpenOut_TREADY(shim2mux_requestPortOpenOut_V_TREADY),   // input wire requestPortOpenOut_V_TREADY//
  .requestPortOpenOut_TDATA(shim2mux_requestPortOpenOut_V_TDATA),     // output wire [7 : 0] requestPortOpenOut_V_TDATA//
  .rxDataIn_TVALID(mux2shimRxDataIn_TVALID),                         // input wire rxDataIn_TVALID//
  .rxDataIn_TREADY(mux2shimRxDataIn_TREADY),                         // output wire rxDataIn_TREADY//
  .rxDataIn_TDATA(mux2shimRxDataIn_TDATA),                           // input wire [63 : 0] rxDataIn_TDATA//
  .rxDataIn_TLAST(mux2shimRxDataIn_TLAST),                           // input wire [0 : 0] rxDataIn_TLAST//
  .rxDataIn_TKEEP(mux2shimRxDataIn_TKEEP),                           // input wire [7 : 0] rxDataIn_TKEEP//
  .rxMetadataIn_TVALID(mux2shimRxMetadataIn_V_TVALID),              // input wire rxMetadataIn_V_TVALID//
  .rxMetadataIn_TREADY(mux2shimRxMetadataIn_V_TREADY),              // output wire rxMetadataIn_V_TREADY//
  .rxMetadataIn_TDATA(mux2shimRxMetadataIn_V_TDATA),                // input wire [95 : 0] rxMetadataIn_V_TDATA//
  .txDataOut_TVALID(shim2mux_TVALID),                    // output wire txDataOut_TVALID
  .txDataOut_TREADY(shim2mux_TREADY),                    // input wire txDataOut_TREADY
  .txDataOut_TDATA(shim2mux_TDATA),                      // output wire [63 : 0] txDataOut_TDATA
  .txDataOut_TKEEP(shim2mux_TKEEP),                      // output wire [7 : 0] txDataOut_TKEEP
  .txDataOut_TLAST(shim2mux_TLAST),                      // output wire [0 : 0] txDataOut_TLAST
  .txLengthOut_TVALID(shim2muxTxLengthOut_V_V_TVALID),               // output wire txLengthOut_V_V_TVALID//
  .txLengthOut_TREADY(shim2muxTxLengthOut_V_V_TREADY),               // input wire txLengthOut_V_V_TREADY//
  .txLengthOut_TDATA(shim2muxTxLengthOut_V_V_TDATA),                 // output wire [15 : 0] txLengthOut_V_V_TDATA//
  .txMetadataOut_TVALID(shim2muxTxMetadataOut_V_TVALID),             // output wire txMetadataOut_V_TVALID//
  .txMetadataOut_TREADY(shim2muxTxMetadataOut_V_TREADY),             // input wire txMetadataOut_V_TREADY//
  .txMetadataOut_TDATA(shim2muxTxMetadataOut_V_TDATA),               // output wire [95 : 0] txMetadataOut_V_TDATA//
  /// Ports to and from the MCD Pipeline
  .rxDataOut_TVALID(rxDataOut_TVALID),                          // output wire rxDataOut_TVALID
  .rxDataOut_TREADY(rxDataOut_TREADY),                          // input wire rxDataOut_TREADY
  .rxDataOut_TDATA(rxDataOut_TDATA),                            // output wire [63 : 0] rxDataOut_TDATA
  .rxDataOut_TUSER(rxDataOut_TUSER),                            // output wire [111 : 0] rxDataOut_TUSER
  .rxDataOut_TKEEP(rxDataOut_TKEEP),                            // output wire [7 : 0] rxDataOut_TKEEP
  .rxDataOut_TLAST(rxDataOut_TLAST),                            // output wire [0 : 0] rxDataOut_TLAST
  .txDataIn_TVALID(mcd_to_shim_TVALID),                       // output wire txDataOut_TVALID//
  .txDataIn_TREADY(mcd_to_shim_TREADY),                       // input wire txDataOut_TREADY//
  .txDataIn_TDATA(mcd_to_shim_TDATA),                         // output wire [63 : 0] txDataOut_TDATA//
  .txDataIn_TKEEP(mcd_to_shim_TKEEP),                         // output wire [7 : 0] txDataOut_TKEEP//
  .txDataIn_TLAST(mcd_to_shim_TLAST),                         // output wire [0 : 0] txDataOut_TLAST//
  .txDataIn_TUSER(mcd_to_shim_TUSER),                          // input wire [111 : 0] txDataIn_TUSER//
  .portToOpen_V(15'h2BCB),
  .aclk(clk),                                               // input wire aclk
  .aresetn(aresetn)                                             // input wire aresetn
);
/* ------------------------------------------------------------ */
       /* ChipScope Debugging                                          */
       /* ------------------------------------------------------------ */
       //chipscope debugging
       /*reg [255:0] data;
       reg [31:0]  trig0;
       wire [35:0] control0, control1;
       wire vio_reset;
             
       chipscope_icon icon0
       (
           .CONTROL0 (control0),
           .CONTROL1 (control1)
       );
       
       chipscope_ila ila0
       (
           .CLK     (clk),
           .CONTROL (control0),
           .TRIG0   (trig0),
           .DATA    (data)
       );
       chipscope_vio vio0
       (
           .CONTROL(control1),
           .ASYNC_OUT(vio_reset)
       );
       
       always @(posedge clk) begin
           trig0[0] <= aresetn;
           trig0[1] <= rxDataOut_TVALID;
           trig0[2] <= rxDataOut_TREADY;
           trig0[3] <= udp2muxRxDataIn_TVALID;
           trig0[4] <= udp2muxRxDataIn_TREADY;
          
           
           data[0] <= aresetn;
           data[1] <= rxDataOut_TVALID;
           data[2] <= rxDataOut_TREADY;
           data[3] <= rxDataOut_TLAST;
           data[11:4] <= rxDataOut_TKEEP;
           data[75:12] <= rxDataOut_TDATA;
           data[76] <= mcd_to_shim_TVALID;
           data[77] <= mcd_to_shim_TREADY;
           data[78] <= mcd_to_shim_TLAST;
           data[86:79] <= mcd_to_shim_TKEEP;
           data[150:87] <= mcd_to_shim_TDATA;
           
           data[151] <= mux2shimRxDataIn_TVALID;
           data[152] <= mux2shimRxDataIn_TREADY;
           data[153] <= mux2shimRxDataIn_TLAST;
           data[161:154] <= mux2shimRxDataIn_TKEEP;
           data[225:162] <= mux2shimRxDataIn_TDATA;
           data[226] <= shim2mux_TVALID;
           data[227] <= shim2mux_TREADY;
           data[228] <= shim2mux_TLAST;
           data[236:229] <= shim2mux_TKEEP;
       end*/
 
endmodule

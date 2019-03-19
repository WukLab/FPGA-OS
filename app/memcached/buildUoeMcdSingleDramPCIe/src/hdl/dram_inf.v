`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2013 02:22:48 PM
// Design Name: 
// Module Name: mem_inf
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


module dram_inf
(
input clk156_25,
input reset156_25_n,

input sys_rst,
//ddr3 pins
// Differential system clocks
input				c0_sys_clk_p,
input				c0_sys_clk_n,
input				c1_sys_clk_p,
input				c1_sys_clk_n,

// differential iodelayctrl clk (reference clock)
input				clk_ref_p,
input				clk_ref_n,
//SODIMM 0
// Inouts
inout [71:0]       c0_ddr3_dq,
inout [8:0]        c0_ddr3_dqs_n,
inout [8:0]        c0_ddr3_dqs_p,

// Outputs
output [15:0]     c0_ddr3_addr,
output [2:0]      c0_ddr3_ba,
output            c0_ddr3_ras_n,
output            c0_ddr3_cas_n,
output            c0_ddr3_we_n,
output            c0_ddr3_reset_n,
output[1:0]       c0_ddr3_ck_p,
output[1:0]       c0_ddr3_ck_n,
output[1:0]       c0_ddr3_cke,
output[1:0]       c0_ddr3_cs_n,
output[1:0]       c0_ddr3_odt,
output            c0_ui_clk,
output            c0_init_calib_complete,

//SODIMM 1
// Inouts
inout [71:0]      c1_ddr3_dq,
inout [8:0]       c1_ddr3_dqs_n,
inout [8:0]       c1_ddr3_dqs_p,

// Outputs
output [15:0]    c1_ddr3_addr,
output [2:0]     c1_ddr3_ba,
output           c1_ddr3_ras_n,
output           c1_ddr3_cas_n,
output           c1_ddr3_we_n,
output           c1_ddr3_reset_n,
output[1:0]      c1_ddr3_ck_p,
output[1:0]      c1_ddr3_ck_n,
output[1:0]      c1_ddr3_cke,
output[1:0]      c1_ddr3_cs_n,
output[1:0]      c1_ddr3_odt,
//ui outputs
output           c1_ui_clk,
output           c1_init_calib_complete,

//ht stream interface signals
input           ht_s_axis_read_cmd_tvalid,
output          ht_s_axis_read_cmd_tready,
input[71:0]     ht_s_axis_read_cmd_tdata,
//read status
output          ht_m_axis_read_sts_tvalid,
input           ht_m_axis_read_sts_tready,
output[7:0]     ht_m_axis_read_sts_tdata,
//read stream
output[511:0]    ht_m_axis_read_tdata,
output[63:0]     ht_m_axis_read_tkeep,
output          ht_m_axis_read_tlast,
output          ht_m_axis_read_tvalid,
input           ht_m_axis_read_tready,

//write commands
input           ht_s_axis_write_cmd_tvalid,
output          ht_s_axis_write_cmd_tready,
input[71:0]     ht_s_axis_write_cmd_tdata,
//write status
output          ht_m_axis_write_sts_tvalid,
input           ht_m_axis_write_sts_tready,
output[7:0]     ht_m_axis_write_sts_tdata,
//write stream
input[511:0]     ht_s_axis_write_tdata,
input[63:0]      ht_s_axis_write_tkeep,
input           ht_s_axis_write_tlast,
input           ht_s_axis_write_tvalid,
output          ht_s_axis_write_tready,

//value store stream interface signals
input           vs_s_axis_read_cmd_tvalid,
output          vs_s_axis_read_cmd_tready,
input[71:0]     vs_s_axis_read_cmd_tdata,
//read status
output          vs_m_axis_read_sts_tvalid,
input           vs_m_axis_read_sts_tready,
output[7:0]     vs_m_axis_read_sts_tdata,
//read stream
output[511:0]    vs_m_axis_read_tdata,
output[63:0]     vs_m_axis_read_tkeep,
output          vs_m_axis_read_tlast,
output          vs_m_axis_read_tvalid,
input           vs_m_axis_read_tready,

//write commands
input           vs_s_axis_write_cmd_tvalid,
output          vs_s_axis_write_cmd_tready,
input[71:0]     vs_s_axis_write_cmd_tdata,
//write status
output          vs_m_axis_write_sts_tvalid,
input           vs_m_axis_write_sts_tready,
output[7:0]     vs_m_axis_write_sts_tdata,
//write stream
input[511:0]     vs_s_axis_write_tdata,
input[63:0]      vs_s_axis_write_tkeep,
input            vs_s_axis_write_tlast,
input            vs_s_axis_write_tvalid,
output           vs_s_axis_write_tready
);

//data streams in c0_ui_clk
wire[511:0]    c0_m_axis_read_tdata;
wire[63:0]     c0_m_axis_read_tkeep;
wire          c0_m_axis_read_tlast;
wire          c0_m_axis_read_tvalid;
wire           c0_m_axis_read_tready;

wire[511:0]     c0_s_axis_write_tdata;
wire[63:0]      c0_s_axis_write_tkeep;
wire            c0_s_axis_write_tlast;
wire            c0_s_axis_write_tvalid;
wire           c0_s_axis_write_tready;

//data streams in c1_ui_clk domain
//read stream
wire[511:0]    c1_m_axis_read_tdata;
wire[63:0]     c1_m_axis_read_tkeep;
wire          c1_m_axis_read_tlast;
wire          c1_m_axis_read_tvalid;
wire           c1_m_axis_read_tready;

wire[511:0]     c1_s_axis_write_tdata;
wire[63:0]      c1_s_axis_write_tkeep;
wire            c1_s_axis_write_tlast;
wire            c1_s_axis_write_tvalid;
wire           c1_s_axis_write_tready;


 // user interface signals
wire                   c0_ui_clk_sync_rst;
wire                   c0_mmcm_locked;
      
reg                    c0_aresetn_r;
   
// Slave Interface Write Address Ports
wire  [4:0]            c0_s_axi_awid;
wire  [32:0]           c0_s_axi_awaddr;
wire  [7:0]            c0_s_axi_awlen;
wire  [2:0]            c0_s_axi_awsize;
wire  [1:0]            c0_s_axi_awburst;

wire                   c0_s_axi_awvalid;
wire                   c0_s_axi_awready;
// Slave Interface Write Data Ports
wire  [511:0]          c0_s_axi_wdata;
wire  [63:0]           c0_s_axi_wstrb;
wire                   c0_s_axi_wlast;
wire                   c0_s_axi_wvalid;
wire                   c0_s_axi_wready;
// Slave Interface Write Response Ports
wire [4:0]             c0_s_axi_bid;
wire [1:0]             c0_s_axi_bresp;
wire                   c0_s_axi_bvalid;
wire                   c0_s_axi_bready;

// Slave Interface Read Address Ports
wire  [4:0]           c0_s_axi_arid;
wire  [32:0]          c0_s_axi_araddr;
wire  [7:0]           c0_s_axi_arlen;
wire  [2:0]           c0_s_axi_arsize;
wire  [1:0]           c0_s_axi_arburst;
wire                  c0_s_axi_arvalid;
wire                  c0_s_axi_arready;
// Slave Interface Read Data Ports
wire [4:0]       c0_s_axi_rid;
wire [511:0]     c0_s_axi_rdata;
wire [1:0]       c0_s_axi_rresp;
wire             c0_s_axi_rlast;
wire             c0_s_axi_rvalid;
wire             c0_s_axi_rready;

// user interface signals
wire             c1_ui_clk_sync_rst;
wire             c1_mmcm_locked;
      
reg              c1_aresetn_r;
   
// Slave Interface Write Address Ports
wire [4:0]      c1_s_axi_awid;
wire [32:0]     c1_s_axi_awaddr;
wire [7:0]      c1_s_axi_awlen;
wire [2:0]      c1_s_axi_awsize;
wire [1:0]      c1_s_axi_awburst;

wire            c1_s_axi_awvalid;
wire            c1_s_axi_awready;
// Slave Interface Write Data Ports
wire [511:0]    c1_s_axi_wdata;
wire [63:0]     c1_s_axi_wstrb;
wire            c1_s_axi_wlast;
wire            c1_s_axi_wvalid;
wire            c1_s_axi_wready;
// Slave Interface Write Response Ports
wire [4:0]      c1_s_axi_bid;
wire [1:0]      c1_s_axi_bresp;
wire            c1_s_axi_bvalid;
wire            c1_s_axi_bready;

// Slave Interface Read Address Ports
wire [4:0]      c1_s_axi_arid;
wire [32:0]     c1_s_axi_araddr;
wire [7:0]      c1_s_axi_arlen;
wire [2:0]      c1_s_axi_arsize;
wire [1:0]      c1_s_axi_arburst;
wire            c1_s_axi_arvalid;
wire            c1_s_axi_arready;
// Slave Interface Read Data Ports
wire [4:0]      c1_s_axi_rid;
wire [511:0]    c1_s_axi_rdata;
wire [1:0]      c1_s_axi_rresp;
wire            c1_s_axi_rlast;
wire            c1_s_axi_rvalid;
wire            c1_s_axi_rready;

always @(posedge c0_ui_clk)
    c0_aresetn_r <= ~c0_ui_clk_sync_rst & c0_mmcm_locked;
    
always @(posedge c1_ui_clk)
    c1_aresetn_r <= ~c1_ui_clk_sync_rst & c1_mmcm_locked;
    
assign c0_s_axi_awaddr[32] = 1'b0;
assign c0_s_axi_araddr[32] = 1'b0;
assign c1_s_axi_awaddr[32] = 1'b0;
assign c1_s_axi_araddr[32] = 1'b0;

axi_datamover_0 ht2dram_data_mover (
  .m_axi_mm2s_aclk(c0_ui_clk),                        // input wire m_axi_mm2s_aclk
  .m_axi_mm2s_aresetn(c0_aresetn_r),                  // input wire m_axi_mm2s_aresetn
  .mm2s_err(),                                      // output wire mm2s_err
  .m_axis_mm2s_cmdsts_aclk(clk156_25),        // input wire m_axis_mm2s_cmdsts_aclk
  .m_axis_mm2s_cmdsts_aresetn(reset156_25_n),  // input wire m_axis_mm2s_cmdsts_aresetn
  
  .s_axis_mm2s_cmd_tvalid(ht_s_axis_read_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
  .s_axis_mm2s_cmd_tready(ht_s_axis_read_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
  .s_axis_mm2s_cmd_tdata(ht_s_axis_read_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata
  .m_axis_mm2s_sts_tvalid(ht_m_axis_read_sts_tvalid),          // output wire m_axis_mm2s_sts_tvalid
  .m_axis_mm2s_sts_tready(ht_m_axis_read_sts_tready),          // input wire m_axis_mm2s_sts_tready
  .m_axis_mm2s_sts_tdata(ht_m_axis_read_sts_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
  .m_axis_mm2s_sts_tkeep(),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
  .m_axis_mm2s_sts_tlast(),            // output wire m_axis_mm2s_sts_tlast
  .m_axi_mm2s_arid(c0_s_axi_arid),                        // output wire [4 : 0] m_axi_mm2s_arid
  .m_axi_mm2s_araddr(c0_s_axi_araddr[31:0]),                    // output wire [31 : 0] m_axi_mm2s_araddr //with axi_datamover only 4GB memory can be used
  .m_axi_mm2s_arlen(c0_s_axi_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
  .m_axi_mm2s_arsize(c0_s_axi_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
  .m_axi_mm2s_arburst(c0_s_axi_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
  .m_axi_mm2s_arprot(),                    // output wire [2 : 0] m_axi_mm2s_arprot
  .m_axi_mm2s_arcache(),                  // output wire [3 : 0] m_axi_mm2s_arcache
  .m_axi_mm2s_aruser(),                    // output wire [3 : 0] m_axi_mm2s_aruser
  .m_axi_mm2s_arvalid(c0_s_axi_arvalid),                  // output wire m_axi_mm2s_arvalid
  .m_axi_mm2s_arready(c0_s_axi_arready),                  // input wire m_axi_mm2s_arready
  .m_axi_mm2s_rdata(c0_s_axi_rdata),                      // input wire [511 : 0] m_axi_mm2s_rdata
  .m_axi_mm2s_rresp(c0_s_axi_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
  .m_axi_mm2s_rlast(c0_s_axi_rlast),                      // input wire m_axi_mm2s_rlast
  .m_axi_mm2s_rvalid(c0_s_axi_rvalid),                    // input wire m_axi_mm2s_rvalid
  .m_axi_mm2s_rready(c0_s_axi_rready),                    // output wire m_axi_mm2s_rready
  .m_axis_mm2s_tdata(c0_m_axis_read_tdata),                    // output wire [511 : 0] m_axis_mm2s_tdata
  .m_axis_mm2s_tkeep(c0_m_axis_read_tkeep),                    // output wire [63 : 0] m_axis_mm2s_tkeep
  .m_axis_mm2s_tlast(c0_m_axis_read_tlast),                    // output wire m_axis_mm2s_tlast
  .m_axis_mm2s_tvalid(c0_m_axis_read_tvalid),                  // output wire m_axis_mm2s_tvalid
  .m_axis_mm2s_tready(c0_m_axis_read_tready),                  // input wire m_axis_mm2s_tready
  
  .m_axi_s2mm_aclk(c0_ui_clk),                        // input wire m_axi_s2mm_aclk
  .m_axi_s2mm_aresetn(c0_aresetn_r),                  // input wire m_axi_s2mm_aresetn
  .s2mm_err(),                                      // output wire s2mm_err
  .m_axis_s2mm_cmdsts_awclk(clk156_25),      // input wire m_axis_s2mm_cmdsts_awclk
  .m_axis_s2mm_cmdsts_aresetn(reset156_25_n),  // input wire m_axis_s2mm_cmdsts_aresetn
  
  .s_axis_s2mm_cmd_tvalid(ht_s_axis_write_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
  .s_axis_s2mm_cmd_tready(ht_s_axis_write_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
  .s_axis_s2mm_cmd_tdata(ht_s_axis_write_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata
  .m_axis_s2mm_sts_tvalid(ht_m_axis_write_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
  .m_axis_s2mm_sts_tready(ht_m_axis_write_sts_tready),          // input wire m_axis_s2mm_sts_tready
  .m_axis_s2mm_sts_tdata(ht_m_axis_write_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
  .m_axis_s2mm_sts_tkeep(),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
  .m_axis_s2mm_sts_tlast(),            // output wire m_axis_s2mm_sts_tlast
  .m_axi_s2mm_awid(c0_s_axi_awid),                        // output wire [4 : 0] m_axi_s2mm_awid
  .m_axi_s2mm_awaddr(c0_s_axi_awaddr[31:0]),                    // output wire [31 : 0] m_axi_s2mm_awaddr
  .m_axi_s2mm_awlen(c0_s_axi_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
  .m_axi_s2mm_awsize(c0_s_axi_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
  .m_axi_s2mm_awburst(c0_s_axi_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
  .m_axi_s2mm_awprot(),                    // output wire [2 : 0] m_axi_s2mm_awprot
  .m_axi_s2mm_awcache(),                  // output wire [3 : 0] m_axi_s2mm_awcache
  .m_axi_s2mm_awuser(),                    // output wire [3 : 0] m_axi_s2mm_awuser
  .m_axi_s2mm_awvalid(c0_s_axi_awvalid),                  // output wire m_axi_s2mm_awvalid
  .m_axi_s2mm_awready(c0_s_axi_awready),                  // input wire m_axi_s2mm_awready
  .m_axi_s2mm_wdata(c0_s_axi_wdata),                      // output wire [511 : 0] m_axi_s2mm_wdata
  .m_axi_s2mm_wstrb(c0_s_axi_wstrb),                      // output wire [63 : 0] m_axi_s2mm_wstrb
  .m_axi_s2mm_wlast(c0_s_axi_wlast),                      // output wire m_axi_s2mm_wlast
  .m_axi_s2mm_wvalid(c0_s_axi_wvalid),                    // output wire m_axi_s2mm_wvalid
  .m_axi_s2mm_wready(c0_s_axi_wready),                    // input wire m_axi_s2mm_wready
  .m_axi_s2mm_bresp(c0_s_axi_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
  .m_axi_s2mm_bvalid(c0_s_axi_bvalid),                    // input wire m_axi_s2mm_bvalid
  .m_axi_s2mm_bready(c0_s_axi_bready),                    // output wire m_axi_s2mm_bready
  .s_axis_s2mm_tdata(c0_s_axis_write_tdata),                    // input wire [511 : 0] s_axis_s2mm_tdata
  .s_axis_s2mm_tkeep(c0_s_axis_write_tkeep),                    // input wire [63 : 0] s_axis_s2mm_tkeep
  .s_axis_s2mm_tlast(c0_s_axis_write_tlast),                    // input wire s_axis_s2mm_tlast
  .s_axis_s2mm_tvalid(c0_s_axis_write_tvalid),                  // input wire s_axis_s2mm_tvalid
  .s_axis_s2mm_tready(c0_s_axis_write_tready)                  // output wire s_axis_s2mm_tready
);

axis_clock_converter_512 ht_c0_read_data_conv (
  .s_axis_aresetn(c0_aresetn_r),  // input wire s_axis_aresetn
  .m_axis_aresetn(reset156_25_n),  // input wire m_axis_aresetn
  .s_axis_aclk(c0_ui_clk),        // input wire s_axis_aclk
  .s_axis_tvalid(c0_m_axis_read_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(c0_m_axis_read_tready),    // output wire s_axis_tready
  .s_axis_tdata(c0_m_axis_read_tdata),      // input wire [4095 : 0] s_axis_tdata
  .s_axis_tkeep(c0_m_axis_read_tkeep),      // input wire [511 : 0] s_axis_tkeep
  .s_axis_tlast(c0_m_axis_read_tlast),      // input wire s_axis_tlast
  .m_axis_aclk(clk156_25),        // input wire m_axis_aclk
  .m_axis_tvalid(ht_m_axis_read_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(ht_m_axis_read_tready),    // input wire m_axis_tready
  .m_axis_tdata(ht_m_axis_read_tdata),      // output wire [4095 : 0] m_axis_tdata
  .m_axis_tkeep(ht_m_axis_read_tkeep),      // output wire [511 : 0] m_axis_tkeep
  .m_axis_tlast(ht_m_axis_read_tlast)      // output wire m_axis_tlast
);

axis_clock_converter_512 ht_c0_write_data_conv(
  .s_axis_aresetn(reset156_25_n),  // input wire s_axis_aresetn
  .m_axis_aresetn(c0_aresetn_r),  // input wire m_axis_aresetn
  .s_axis_aclk(clk156_25),        // input wire s_axis_aclk
  .s_axis_tvalid(ht_s_axis_write_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(ht_s_axis_write_tready),    // output wire s_axis_tready
  .s_axis_tdata(ht_s_axis_write_tdata),      // input wire [4095 : 0] s_axis_tdata
  .s_axis_tkeep(ht_s_axis_write_tkeep),      // input wire [511 : 0] s_axis_tkeep
  .s_axis_tlast(ht_s_axis_write_tlast),      // input wire s_axis_tlast
  .m_axis_aclk(c0_ui_clk),        // input wire m_axis_aclk
  .m_axis_tvalid(c0_s_axis_write_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(c0_s_axis_write_tready),    // input wire m_axis_tready
  .m_axis_tdata(c0_s_axis_write_tdata),      // output wire [4095 : 0] m_axis_tdata
  .m_axis_tkeep(c0_s_axis_write_tkeep),      // output wire [511 : 0] m_axis_tkeep
  .m_axis_tlast(c0_s_axis_write_tlast)      // output wire m_axis_tlast
);

axi_datamover_0 vs2dram_data_mover (
  .m_axi_mm2s_aclk(c1_ui_clk),                        // input wire m_axi_mm2s_aclk
  .m_axi_mm2s_aresetn(c1_aresetn_r),                  // input wire m_axi_mm2s_aresetn
  .mm2s_err(),                                      // output wire mm2s_err
  .m_axis_mm2s_cmdsts_aclk(clk156_25),        // input wire m_axis_mm2s_cmdsts_aclk
  .m_axis_mm2s_cmdsts_aresetn(reset156_25_n),  // input wire m_axis_mm2s_cmdsts_aresetn
  
  .s_axis_mm2s_cmd_tvalid(vs_s_axis_read_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
  .s_axis_mm2s_cmd_tready(vs_s_axis_read_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
  .s_axis_mm2s_cmd_tdata(vs_s_axis_read_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata
  .m_axis_mm2s_sts_tvalid(vs_m_axis_read_sts_tvalid),          // output wire m_axis_mm2s_sts_tvalid
  .m_axis_mm2s_sts_tready(vs_m_axis_read_sts_tready),          // input wire m_axis_mm2s_sts_tready
  .m_axis_mm2s_sts_tdata(vs_m_axis_read_sts_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
  .m_axis_mm2s_sts_tkeep(),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
  .m_axis_mm2s_sts_tlast(),            // output wire m_axis_mm2s_sts_tlast
  .m_axi_mm2s_arid(c1_s_axi_arid),                        // output wire [4 : 0] m_axi_mm2s_arid
  .m_axi_mm2s_araddr(c1_s_axi_araddr[31:0]),                    // output wire [31 : 0] m_axi_mm2s_araddr //with axi_datamover only 4GB memory can be used
  .m_axi_mm2s_arlen(c1_s_axi_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
  .m_axi_mm2s_arsize(c1_s_axi_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
  .m_axi_mm2s_arburst(c1_s_axi_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
  .m_axi_mm2s_arprot(),                    // output wire [2 : 0] m_axi_mm2s_arprot
  .m_axi_mm2s_arcache(),                  // output wire [3 : 0] m_axi_mm2s_arcache
  .m_axi_mm2s_aruser(),                    // output wire [3 : 0] m_axi_mm2s_aruser
  .m_axi_mm2s_arvalid(c1_s_axi_arvalid),                  // output wire m_axi_mm2s_arvalid
  .m_axi_mm2s_arready(c1_s_axi_arready),                  // input wire m_axi_mm2s_arready
  .m_axi_mm2s_rdata(c1_s_axi_rdata),                      // input wire [511 : 0] m_axi_mm2s_rdata
  .m_axi_mm2s_rresp(c1_s_axi_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
  .m_axi_mm2s_rlast(c1_s_axi_rlast),                      // input wire m_axi_mm2s_rlast
  .m_axi_mm2s_rvalid(c1_s_axi_rvalid),                    // input wire m_axi_mm2s_rvalid
  .m_axi_mm2s_rready(c1_s_axi_rready),                    // output wire m_axi_mm2s_rready
  .m_axis_mm2s_tdata(c1_m_axis_read_tdata),                    // output wire [511 : 0] m_axis_mm2s_tdata
  .m_axis_mm2s_tkeep(c1_m_axis_read_tkeep),                    // output wire [63 : 0] m_axis_mm2s_tkeep
  .m_axis_mm2s_tlast(c1_m_axis_read_tlast),                    // output wire m_axis_mm2s_tlast
  .m_axis_mm2s_tvalid(c1_m_axis_read_tvalid),                  // output wire m_axis_mm2s_tvalid
  .m_axis_mm2s_tready(c1_m_axis_read_tready),                  // input wire m_axis_mm2s_tready
  
  .m_axi_s2mm_aclk(c1_ui_clk),                        // input wire m_axi_s2mm_aclk
  .m_axi_s2mm_aresetn(c1_aresetn_r),                  // input wire m_axi_s2mm_aresetn
  .s2mm_err(),                                      // output wire s2mm_err
  .m_axis_s2mm_cmdsts_awclk(clk156_25),      // input wire m_axis_s2mm_cmdsts_awclk
  .m_axis_s2mm_cmdsts_aresetn(reset156_25_n),  // input wire m_axis_s2mm_cmdsts_aresetn
  
  .s_axis_s2mm_cmd_tvalid(vs_s_axis_write_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
  .s_axis_s2mm_cmd_tready(vs_s_axis_write_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
  .s_axis_s2mm_cmd_tdata(vs_s_axis_write_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata
  .m_axis_s2mm_sts_tvalid(vs_m_axis_write_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
  .m_axis_s2mm_sts_tready(vs_m_axis_write_sts_tready),          // input wire m_axis_s2mm_sts_tready
  .m_axis_s2mm_sts_tdata(vs_m_axis_write_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
  .m_axis_s2mm_sts_tkeep(),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
  .m_axis_s2mm_sts_tlast(),            // output wire m_axis_s2mm_sts_tlast
  .m_axi_s2mm_awid(c1_s_axi_awid),                        // output wire [4 : 0] m_axi_s2mm_awid
  .m_axi_s2mm_awaddr(c1_s_axi_awaddr[31:0]),                    // output wire [31 : 0] m_axi_s2mm_awaddr
  .m_axi_s2mm_awlen(c1_s_axi_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
  .m_axi_s2mm_awsize(c1_s_axi_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
  .m_axi_s2mm_awburst(c1_s_axi_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
  .m_axi_s2mm_awprot(),                    // output wire [2 : 0] m_axi_s2mm_awprot
  .m_axi_s2mm_awcache(),                  // output wire [3 : 0] m_axi_s2mm_awcache
  .m_axi_s2mm_awuser(),                    // output wire [3 : 0] m_axi_s2mm_awuser
  .m_axi_s2mm_awvalid(c1_s_axi_awvalid),                  // output wire m_axi_s2mm_awvalid
  .m_axi_s2mm_awready(c1_s_axi_awready),                  // input wire m_axi_s2mm_awready
  .m_axi_s2mm_wdata(c1_s_axi_wdata),                      // output wire [511 : 0] m_axi_s2mm_wdata
  .m_axi_s2mm_wstrb(c1_s_axi_wstrb),                      // output wire [63 : 0] m_axi_s2mm_wstrb
  .m_axi_s2mm_wlast(c1_s_axi_wlast),                      // output wire m_axi_s2mm_wlast
  .m_axi_s2mm_wvalid(c1_s_axi_wvalid),                    // output wire m_axi_s2mm_wvalid
  .m_axi_s2mm_wready(c1_s_axi_wready),                    // input wire m_axi_s2mm_wready
  .m_axi_s2mm_bresp(c1_s_axi_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
  .m_axi_s2mm_bvalid(c1_s_axi_bvalid),                    // input wire m_axi_s2mm_bvalid
  .m_axi_s2mm_bready(c1_s_axi_bready),                    // output wire m_axi_s2mm_bready
  .s_axis_s2mm_tdata(c1_s_axis_write_tdata),                    // input wire [511 : 0] s_axis_s2mm_tdata
  .s_axis_s2mm_tkeep(c1_s_axis_write_tkeep),                    // input wire [63 : 0] s_axis_s2mm_tkeep
  .s_axis_s2mm_tlast(c1_s_axis_write_tlast),                    // input wire s_axis_s2mm_tlast
  .s_axis_s2mm_tvalid(c1_s_axis_write_tvalid),                  // input wire s_axis_s2mm_tvalid
  .s_axis_s2mm_tready(c1_s_axis_write_tready)                  // output wire s_axis_s2mm_tready
);

axis_clock_converter_512 vs_c1_read_data_conv (
  .s_axis_aresetn(c1_aresetn_r),  // input wire s_axis_aresetn
  .m_axis_aresetn(reset156_25_n),  // input wire m_axis_aresetn
  .s_axis_aclk(c1_ui_clk),        // input wire s_axis_aclk
  .s_axis_tvalid(c1_m_axis_read_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(c1_m_axis_read_tready),    // output wire s_axis_tready
  .s_axis_tdata(c1_m_axis_read_tdata),      // input wire [4095 : 0] s_axis_tdata
  .s_axis_tkeep(c1_m_axis_read_tkeep),      // input wire [511 : 0] s_axis_tkeep
  .s_axis_tlast(c1_m_axis_read_tlast),      // input wire s_axis_tlast
  .m_axis_aclk(clk156_25),        // input wire m_axis_aclk
  .m_axis_tvalid(vs_m_axis_read_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(vs_m_axis_read_tready),    // input wire m_axis_tready
  .m_axis_tdata(vs_m_axis_read_tdata),      // output wire [4095 : 0] m_axis_tdata
  .m_axis_tkeep(vs_m_axis_read_tkeep),      // output wire [511 : 0] m_axis_tkeep
  .m_axis_tlast(vs_m_axis_read_tlast)      // output wire m_axis_tlast
);

axis_clock_converter_512 vs_c1_write_data_conv(
  .s_axis_aresetn(reset156_25_n),  // input wire s_axis_aresetn
  .m_axis_aresetn(c1_aresetn_r),  // input wire m_axis_aresetn
  .s_axis_aclk(clk156_25),        // input wire s_axis_aclk
  .s_axis_tvalid(vs_s_axis_write_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(vs_s_axis_write_tready),    // output wire s_axis_tready
  .s_axis_tdata(vs_s_axis_write_tdata),      // input wire [4095 : 0] s_axis_tdata
  .s_axis_tkeep(vs_s_axis_write_tkeep),      // input wire [511 : 0] s_axis_tkeep
  .s_axis_tlast(vs_s_axis_write_tlast),      // input wire s_axis_tlast
  .m_axis_aclk(c1_ui_clk),        // input wire m_axis_aclk
  .m_axis_tvalid(c1_s_axis_write_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(c1_s_axis_write_tready),    // input wire m_axis_tready
  .m_axis_tdata(c1_s_axis_write_tdata),      // output wire [4095 : 0] m_axis_tdata
  .m_axis_tkeep(c1_s_axis_write_tkeep),      // output wire [511 : 0] m_axis_tkeep
  .m_axis_tlast(c1_s_axis_write_tlast)      // output wire m_axis_tlast
);

//mig_axi_mm_dual mig_dual_inst (
mig_7series_0 mig_dual_inst(
    // Memory interface ports
    .c0_ddr3_addr                      (c0_ddr3_addr),  // output [15:0]		c0_ddr3_addr
    .c0_ddr3_ba                        (c0_ddr3_ba),  // output [2:0]		c0_ddr3_ba
    .c0_ddr3_cas_n                     (c0_ddr3_cas_n),  // output			c0_ddr3_cas_n
    .c0_ddr3_ck_n                      (c0_ddr3_ck_n),  // output [1:0]		c0_ddr3_ck_n
    .c0_ddr3_ck_p                      (c0_ddr3_ck_p),  // output [1:0]		c0_ddr3_ck_p
    .c0_ddr3_cke                       (c0_ddr3_cke),  // output [1:0]		c0_ddr3_cke
    .c0_ddr3_ras_n                     (c0_ddr3_ras_n),  // output			c0_ddr3_ras_n
    .c0_ddr3_reset_n                   (c0_ddr3_reset_n),  // output			c0_ddr3_reset_n
    .c0_ddr3_we_n                      (c0_ddr3_we_n),  // output			c0_ddr3_we_n
    .c0_ddr3_dq                        (c0_ddr3_dq),  // inout [71:0]		c0_ddr3_dq
    .c0_ddr3_dqs_n                     (c0_ddr3_dqs_n),  // inout [8:0]		c0_ddr3_dqs_n
    .c0_ddr3_dqs_p                     (c0_ddr3_dqs_p),  // inout [8:0]		c0_ddr3_dqs_p
    .c0_init_calib_complete            (c0_init_calib_complete),  // output			init_calib_complete
      
	.c0_ddr3_cs_n                      (c0_ddr3_cs_n),  // output [1:0]		c0_ddr3_cs_n
    .c0_ddr3_odt                       (c0_ddr3_odt),  // output [1:0]		c0_ddr3_odt
    // Application interface ports
    .c0_ui_clk                         (c0_ui_clk),  // output			c0_ui_clk
    .c0_ui_clk_sync_rst                (c0_ui_clk_sync_rst),  // output			c0_ui_clk_sync_rst
    .c0_mmcm_locked                    (c0_mmcm_locked),  // output			c0_mmcm_locked
    .c0_aresetn                        (c0_aresetn_r),  // input			c0_aresetn
    .c0_app_sr_req                     (1'b0),  // input			c0_app_sr_req
    .c0_app_ref_req                    (1'b0),  // input			c0_app_ref_req
    .c0_app_zq_req                     (1'b0),  // input			c0_app_zq_req
    .c0_app_sr_active                  (),  // output			c0_app_sr_active
    .c0_app_ref_ack                    (),  // output			c0_app_ref_ack
    .c0_app_zq_ack                     (),  // output			c0_app_zq_ack
    // Slave Interface Write Address Ports
    .c0_s_axi_awid                     (c0_s_axi_awid),  // input [4:0]			c0_s_axi_awid
    .c0_s_axi_awaddr                   (c0_s_axi_awaddr),  // input [32:0]			c0_s_axi_awaddr
    .c0_s_axi_awlen                    (c0_s_axi_awlen),  // input [7:0]			c0_s_axi_awlen
    .c0_s_axi_awsize                   (c0_s_axi_awsize),  // input [2:0]			c0_s_axi_awsize
    .c0_s_axi_awburst                  (c0_s_axi_awburst),  // input [1:0]			c0_s_axi_awburst
    .c0_s_axi_awlock                   (1'b0),  // input [0:0]			c0_s_axi_awlock
    .c0_s_axi_awcache                  (4'b0),  // input [3:0]			c0_s_axi_awcache
    .c0_s_axi_awprot                   (3'b0),  // input [2:0]			c0_s_axi_awprot
    .c0_s_axi_awqos                    (4'b0),  // input [3:0]			c0_s_axi_awqos
    .c0_s_axi_awvalid                  (c0_s_axi_awvalid),  // input			c0_s_axi_awvalid
    .c0_s_axi_awready                  (c0_s_axi_awready),  // output			c0_s_axi_awready
    // Slave Interface Write Data Ports
    .c0_s_axi_wdata                    (c0_s_axi_wdata),  // input [511:0]			c0_s_axi_wdata
    .c0_s_axi_wstrb                    (c0_s_axi_wstrb),  // input [63:0]			c0_s_axi_wstrb
    .c0_s_axi_wlast                    (c0_s_axi_wlast),  // input			c0_s_axi_wlast
    .c0_s_axi_wvalid                   (c0_s_axi_wvalid),  // input			c0_s_axi_wvalid
    .c0_s_axi_wready                   (c0_s_axi_wready),  // output			c0_s_axi_wready
    // Slave Interface Write Response Ports
    .c0_s_axi_bid                      (c0_s_axi_bid),  // output [4:0]			c0_s_axi_bid
    .c0_s_axi_bresp                    (c0_s_axi_bresp),  // output [1:0]			c0_s_axi_bresp
    .c0_s_axi_bvalid                   (c0_s_axi_bvalid),  // output			c0_s_axi_bvalid
    .c0_s_axi_bready                   (c0_s_axi_bready),  // input			c0_s_axi_bready
    // Slave Interface Read Address Ports
    .c0_s_axi_arid                     (c0_s_axi_arid),  // input [4:0]			c0_s_axi_arid
    .c0_s_axi_araddr                   (c0_s_axi_araddr),  // input [32:0]			c0_s_axi_araddr
    .c0_s_axi_arlen                    (c0_s_axi_arlen),  // input [7:0]			c0_s_axi_arlen
    .c0_s_axi_arsize                   (c0_s_axi_arsize),  // input [2:0]			c0_s_axi_arsize
    .c0_s_axi_arburst                  (c0_s_axi_arburst),  // input [1:0]			c0_s_axi_arburst
    .c0_s_axi_arlock                   (1'b0),  // input [0:0]			c0_s_axi_arlock
    .c0_s_axi_arcache                  (4'b0),  // input [3:0]			c0_s_axi_arcache
    .c0_s_axi_arprot                   (3'b0),  // input [2:0]			c0_s_axi_arprot
    .c0_s_axi_arqos                    (4'b0),  // input [3:0]			c0_s_axi_arqos
    .c0_s_axi_arvalid                  (c0_s_axi_arvalid),  // input			c0_s_axi_arvalid
    .c0_s_axi_arready                  (c0_s_axi_arready),  // output			c0_s_axi_arready
    // Slave Interface Read Data Ports
    .c0_s_axi_rid                      (c0_s_axi_rid),  // output [4:0]			c0_s_axi_rid
    .c0_s_axi_rdata                    (c0_s_axi_rdata),  // output [511:0]			c0_s_axi_rdata
    .c0_s_axi_rresp                    (c0_s_axi_rresp),  // output [1:0]			c0_s_axi_rresp
    .c0_s_axi_rlast                    (c0_s_axi_rlast),  // output			c0_s_axi_rlast
    .c0_s_axi_rvalid                   (c0_s_axi_rvalid),  // output			c0_s_axi_rvalid
    .c0_s_axi_rready                   (c0_s_axi_rready),  // input			c0_s_axi_rready
	// AXI CTRL port
    .c0_s_axi_ctrl_awvalid             (1'b0),  // input			c0_s_axi_ctrl_awvalid
    .c0_s_axi_ctrl_awready             (),  // output			c0_s_axi_ctrl_awready
    .c0_s_axi_ctrl_awaddr              (32'b0),  // input [31:0]			c0_s_axi_ctrl_awaddr
    // Slave Interface Write Data Ports
    .c0_s_axi_ctrl_wvalid              (1'b0),  // input			c0_s_axi_ctrl_wvalid
    .c0_s_axi_ctrl_wready              (),  // output			c0_s_axi_ctrl_wready
    .c0_s_axi_ctrl_wdata               (32'b0),  // input [31:0]			c0_s_axi_ctrl_wdata
    // Slave Interface Write Response Ports
    .c0_s_axi_ctrl_bvalid              (),  // output			c0_s_axi_ctrl_bvalid
    .c0_s_axi_ctrl_bready              (1'b1),  // input			c0_s_axi_ctrl_bready
    .c0_s_axi_ctrl_bresp               (),  // output [1:0]			c0_s_axi_ctrl_bresp
    // Slave Interface Read Address Ports
    .c0_s_axi_ctrl_arvalid             (1'b0),  // input			c0_s_axi_ctrl_arvalid
    .c0_s_axi_ctrl_arready             (),  // output			c0_s_axi_ctrl_arready
    .c0_s_axi_ctrl_araddr              (32'b0),  // input [31:0]			c0_s_axi_ctrl_araddr
    // Slave Interface Read Data Ports
    .c0_s_axi_ctrl_rvalid              (),  // output			c0_s_axi_ctrl_rvalid
    .c0_s_axi_ctrl_rready              (1'b1),  // input			c0_s_axi_ctrl_rready
    .c0_s_axi_ctrl_rdata               (),  // output [31:0]			c0_s_axi_ctrl_rdata
    .c0_s_axi_ctrl_rresp               (),  // output [1:0]			c0_s_axi_ctrl_rresp
    // Interrupt output
    .c0_interrupt                      (),  // output			c0_interrupt
	.c0_app_ecc_multiple_err           (),  // output [7:0]			c0_app_ecc_multiple_err
    // System Clock Ports
    .c0_sys_clk_p                       (c0_sys_clk_p),  // input				c0_sys_clk_p
    .c0_sys_clk_n                       (c0_sys_clk_n),  // input				c0_sys_clk_n
    // Reference Clock Ports
    .clk_ref_p                      (clk_ref_p),  // input				clk_ref_p
    .clk_ref_n                      (clk_ref_n),  // input				clk_ref_n
    // Memory interface ports
    .c1_ddr3_addr                      (c1_ddr3_addr),  // output [15:0]		c1_ddr3_addr
    .c1_ddr3_ba                        (c1_ddr3_ba),  // output [2:0]		c1_ddr3_ba
    .c1_ddr3_cas_n                     (c1_ddr3_cas_n),  // output			c1_ddr3_cas_n
    .c1_ddr3_ck_n                      (c1_ddr3_ck_n),  // output [1:0]		c1_ddr3_ck_n
    .c1_ddr3_ck_p                      (c1_ddr3_ck_p),  // output [1:0]		c1_ddr3_ck_p
    .c1_ddr3_cke                       (c1_ddr3_cke),  // output [1:0]		c1_ddr3_cke
    .c1_ddr3_ras_n                     (c1_ddr3_ras_n),  // output			c1_ddr3_ras_n
    .c1_ddr3_reset_n                   (c1_ddr3_reset_n),  // output			c1_ddr3_reset_n
    .c1_ddr3_we_n                      (c1_ddr3_we_n),  // output			c1_ddr3_we_n
    .c1_ddr3_dq                        (c1_ddr3_dq),  // inout [71:0]		c1_ddr3_dq
    .c1_ddr3_dqs_n                     (c1_ddr3_dqs_n),  // inout [8:0]		c1_ddr3_dqs_n
    .c1_ddr3_dqs_p                     (c1_ddr3_dqs_p),  // inout [8:0]		c1_ddr3_dqs_p
    .c1_init_calib_complete            (c1_init_calib_complete),  // output			init_calib_complete
      
	.c1_ddr3_cs_n                      (c1_ddr3_cs_n),  // output [1:0]		c1_ddr3_cs_n
    .c1_ddr3_odt                       (c1_ddr3_odt),  // output [1:0]		c1_ddr3_odt
    // Application interface ports
    .c1_ui_clk                         (c1_ui_clk),  // output			c1_ui_clk
    .c1_ui_clk_sync_rst                (c1_ui_clk_sync_rst),  // output			c1_ui_clk_sync_rst
    .c1_mmcm_locked                    (c1_mmcm_locked),  // output			c1_mmcm_locked
    .c1_aresetn                        (c1_aresetn_r),  // input			c1_aresetn
    .c1_app_sr_req                     (1'b0),  // input			c1_app_sr_req
    .c1_app_ref_req                    (1'b0),  // input			c1_app_ref_req
    .c1_app_zq_req                     (1'b0),  // input			c1_app_zq_req
    .c1_app_sr_active                  (),  // output			c1_app_sr_active
    .c1_app_ref_ack                    (),  // output			c1_app_ref_ack
    .c1_app_zq_ack                     (),  // output			c1_app_zq_ack
    // Slave Interface Write Address Ports
    .c1_s_axi_awid                     (c1_s_axi_awid),  // input [4:0]			c1_s_axi_awid
    .c1_s_axi_awaddr                   (c1_s_axi_awaddr),  // input [32:0]			c1_s_axi_awaddr
    .c1_s_axi_awlen                    (c1_s_axi_awlen),  // input [7:0]			c1_s_axi_awlen
    .c1_s_axi_awsize                   (c1_s_axi_awsize),  // input [2:0]			c1_s_axi_awsize
    .c1_s_axi_awburst                  (c1_s_axi_awburst),  // input [1:0]			c1_s_axi_awburst
    .c1_s_axi_awlock                   (1'b0),  // input [0:0]			c1_s_axi_awlock
    .c1_s_axi_awcache                  (4'b0),  // input [3:0]			c1_s_axi_awcache
    .c1_s_axi_awprot                   (3'b0),  // input [2:0]			c1_s_axi_awprot
    .c1_s_axi_awqos                    (4'b0),  // input [3:0]			c1_s_axi_awqos
    .c1_s_axi_awvalid                  (c1_s_axi_awvalid),  // input			c1_s_axi_awvalid
    .c1_s_axi_awready                  (c1_s_axi_awready),  // output			c1_s_axi_awready
    // Slave Interface Write Data Ports
    .c1_s_axi_wdata                    (c1_s_axi_wdata),  // input [511:0]			c1_s_axi_wdata
    .c1_s_axi_wstrb                    (c1_s_axi_wstrb),  // input [63:0]			c1_s_axi_wstrb
    .c1_s_axi_wlast                    (c1_s_axi_wlast),  // input			c1_s_axi_wlast
    .c1_s_axi_wvalid                   (c1_s_axi_wvalid),  // input			c1_s_axi_wvalid
    .c1_s_axi_wready                   (c1_s_axi_wready),  // output			c1_s_axi_wready
    // Slave Interface Write Response Ports
    .c1_s_axi_bid                      (c1_s_axi_bid),  // output [4:0]			c1_s_axi_bid
    .c1_s_axi_bresp                    (c1_s_axi_bresp),  // output [1:0]			c1_s_axi_bresp
    .c1_s_axi_bvalid                   (c1_s_axi_bvalid),  // output			c1_s_axi_bvalid
    .c1_s_axi_bready                   (c1_s_axi_bready),  // input			c1_s_axi_bready
    // Slave Interface Read Address Ports
    .c1_s_axi_arid                     (c1_s_axi_arid),  // input [4:0]			c1_s_axi_arid
    .c1_s_axi_araddr                   (c1_s_axi_araddr),  // input [32:0]			c1_s_axi_araddr
    .c1_s_axi_arlen                    (c1_s_axi_arlen),  // input [7:0]			c1_s_axi_arlen
    .c1_s_axi_arsize                   (c1_s_axi_arsize),  // input [2:0]			c1_s_axi_arsize
    .c1_s_axi_arburst                  (c1_s_axi_arburst),  // input [1:0]			c1_s_axi_arburst
    .c1_s_axi_arlock                   (1'b0),  // input [0:0]			c1_s_axi_arlock
    .c1_s_axi_arcache                  (4'b0),  // input [3:0]			c1_s_axi_arcache
    .c1_s_axi_arprot                   (3'b0),  // input [2:0]			c1_s_axi_arprot
    .c1_s_axi_arqos                    (4'b0),  // input [3:0]			c1_s_axi_arqos
    .c1_s_axi_arvalid                  (c1_s_axi_arvalid),  // input			c1_s_axi_arvalid
    .c1_s_axi_arready                  (c1_s_axi_arready),  // output			c1_s_axi_arready
    // Slave Interface Read Data Ports
    .c1_s_axi_rid                      (c1_s_axi_rid),  // output [4:0]			c1_s_axi_rid
    .c1_s_axi_rdata                    (c1_s_axi_rdata),  // output [511:0]			c1_s_axi_rdata
    .c1_s_axi_rresp                    (c1_s_axi_rresp),  // output [1:0]			c1_s_axi_rresp
    .c1_s_axi_rlast                    (c1_s_axi_rlast),  // output			c1_s_axi_rlast
    .c1_s_axi_rvalid                   (c1_s_axi_rvalid),  // output			c1_s_axi_rvalid
    .c1_s_axi_rready                   (c1_s_axi_rready),  // input			c1_s_axi_rready
	// AXI CTRL port
    .c1_s_axi_ctrl_awvalid             (1'b0),  // input			c1_s_axi_ctrl_awvalid
    .c1_s_axi_ctrl_awready             (),  // output			c1_s_axi_ctrl_awready
    .c1_s_axi_ctrl_awaddr              (32'b0),  // input [31:0]			c1_s_axi_ctrl_awaddr
    // Slave Interface Write Data Ports
    .c1_s_axi_ctrl_wvalid              (1'b0),  // input			c1_s_axi_ctrl_wvalid
    .c1_s_axi_ctrl_wready              (),  // output			c1_s_axi_ctrl_wready
    .c1_s_axi_ctrl_wdata               (32'b0),  // input [31:0]			c1_s_axi_ctrl_wdata
    // Slave Interface Write Response Ports
    .c1_s_axi_ctrl_bvalid              (),  // output			c1_s_axi_ctrl_bvalid
    .c1_s_axi_ctrl_bready              (1'b1),  // input			c1_s_axi_ctrl_bready
    .c1_s_axi_ctrl_bresp               (),  // output [1:0]			c1_s_axi_ctrl_bresp
    // Slave Interface Read Address Ports
    .c1_s_axi_ctrl_arvalid             (1'b0),  // input			c1_s_axi_ctrl_arvalid
    .c1_s_axi_ctrl_arready             (),  // output			c1_s_axi_ctrl_arready
    .c1_s_axi_ctrl_araddr              (32'b0),  // input [31:0]			c1_s_axi_ctrl_araddr
    // Slave Interface Read Data Ports
    .c1_s_axi_ctrl_rvalid              (),  // output			c1_s_axi_ctrl_rvalid
    .c1_s_axi_ctrl_rready              (1'b1),  // input			c1_s_axi_ctrl_rready
    .c1_s_axi_ctrl_rdata               (),  // output [31:0]			c1_s_axi_ctrl_rdata
    .c1_s_axi_ctrl_rresp               (),  // output [1:0]			c1_s_axi_ctrl_rresp
    // Interrupt output
    .c1_interrupt                      (),  // output			c1_interrupt
	.c1_app_ecc_multiple_err           (),  // output [7:0]			c1_app_ecc_multiple_err
    // System Clock Ports
    .c1_sys_clk_p                       (c1_sys_clk_p),  // input				c1_sys_clk_p
    .c1_sys_clk_n                       (c1_sys_clk_n),  // input				c1_sys_clk_n
    .sys_rst                        (sys_rst) // input sys_rst
);

/* ------------------------------------------------------------ */
       /* ChipScope Debugging                                          */
       /* ------------------------------------------------------------ */
       //chipscope debugging
 /*      reg [255:0] data;
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
           .CLK     (c1_ui_clk),
           .CONTROL (control0),
           .TRIG0   (trig0),
           .DATA    (data)
       );
       chipscope_vio vio0
       (
           .CONTROL(control1),
           .ASYNC_OUT(vio_reset)
       );
       
       always @(posedge c1_ui_clk) begin
            trig0[0] <= c1_aresetn_r;           
            trig0[1] <=  c1_s_axi_awvalid;
            trig0[2] <=  c1_s_axi_awready;
           // Slave Interface Write Data Ports
           trig0[3] <=  c1_s_axi_wlast;
           trig0[4] <=  c1_s_axi_wvalid;
           trig0[5] <=  c1_s_axi_wready;
           // Slave Interface Write Response Ports
           trig0[6] <= c1_s_axi_bvalid;
           trig0[7] <= c1_s_axi_bready;
           
           // Slave Interface Read Address Ports
           trig0[8]     <=   c1_s_axi_arvalid;
           trig0[9]     <=   c1_s_axi_arready;
           // Slave Interface Read Data Ports
           trig0[10]   <=     c1_s_axi_rlast;
           trig0[11]   <=     c1_s_axi_rvalid;
           trig0[12]   <=     c1_s_axi_rready;
                   
       
            data[0] <= c1_aresetn_r;
            data[5:1] <= c1_s_axi_awid;
            data[38:6] <= c1_s_axi_awaddr;
            data[46:39] <=  c1_s_axi_awlen;
            data[49:47] <=  c1_s_axi_awsize;
            data[51:50] <=  c1_s_axi_awburst;
            
            data[52] <=  c1_s_axi_awvalid;
            data[53] <=  c1_s_axi_awready;
            // Slave Interface Write Data Ports
            data[54] <=  c1_s_axi_wlast;
            data[55] <=  c1_s_axi_wvalid;
            data[56] <=  c1_s_axi_wready;
            // Slave Interface Write Response Ports
            data[61:57] <= c1_s_axi_bid;
            data[63:62] <= c1_s_axi_bresp;
            data[64] <= c1_s_axi_bvalid;
            data[65] <= c1_s_axi_bready;
            
            // Slave Interface Read Address Ports
            data[70:66] <= c1_s_axi_arid;
            data[103:71] <=  c1_s_axi_araddr;
            data[111:104]  <=  c1_s_axi_arlen;
            data[114:112]  <=  c1_s_axi_arsize;
            data[116:115]  <=  c1_s_axi_arburst;
            data[117]     <=   c1_s_axi_arvalid;
            data[118]     <=   c1_s_axi_arready;
            // Slave Interface Read Data Ports
            data[123:119] <=   c1_s_axi_rid;
            data[125:124] <=   c1_s_axi_rresp;
            data[126]   <=     c1_s_axi_rlast;
            data[127]   <=     c1_s_axi_rvalid;
            data[128]   <=     c1_s_axi_rready;
       end*/
       
endmodule

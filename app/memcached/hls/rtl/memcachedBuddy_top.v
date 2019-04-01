module memcachedBuddy_top #(
    parameter ALLOC_DATA_WID = 32,
    parameter NET_DATA_WID   = 64,
    parameter DRAM_DATA_WID  = 512,
    parameter NET_USER_WID   = 112,
    parameter ADDR_WID       = 32
)
(
 input          mem_clk,
 input          mem_resetn,
 input          apclk,
 input          apresetn,
 input   [63:0] from_net_tdata,                
 input    [7:0] from_net_tkeep,
 input          from_net_tlast,                
 output         from_net_tready,               
 input  [111:0] from_net_tuser,
 input          from_net_tvalid,               
 output  [63:0] to_net_tdata,
 output   [7:0] to_net_tkeep,                  
 output         to_net_tlast,                  
 input          to_net_tready,                 
 output [111:0] to_net_tuser,                  
 output         to_net_tvalid,                
 output  [31:0] toDRAM_araddr,
 output   [1:0] toDRAM_arburst,
 output   [3:0] toDRAM_arcache,
 output   [4:0] toDRAM_arid,
 output   [7:0] toDRAM_arlen,
 output   [2:0] toDRAM_arprot,
 input          toDRAM_arready,
 output   [2:0] toDRAM_arsize,
 output         toDRAM_arvalid,
 output   [3:0] toDRAM_arqos,
 output         toDRAM_arlock,
 output   [3:0] toDRAM_arregion,
 output  [31:0] toDRAM_awaddr,
 output   [1:0] toDRAM_awburst,
 output   [3:0] toDRAM_awcache,
 output   [4:0] toDRAM_awid,
 output   [7:0] toDRAM_awlen,
 output   [2:0] toDRAM_awprot,
 input          toDRAM_awready,
 output   [2:0] toDRAM_awsize,
 output         toDRAM_awvalid,
 output   [3:0] toDRAM_awregion,
 output         toDRAM_awlock,
 output   [3:0] toDRAM_awqos,
 input    [4:0] toDRAM_bid,
 output         toDRAM_bready,
 input    [1:0] toDRAM_bresp,
 input          toDRAM_bvalid,
 input  [511:0] toDRAM_rdata,
 input    [4:0] toDRAM_rid,
 input          toDRAM_rlast,
 output         toDRAM_rready,
 input    [1:0] toDRAM_rresp,
 input          toDRAM_rvalid,
 output [511:0] toDRAM_wdata,
 output         toDRAM_wlast,
 input          toDRAM_wready,
 output  [63:0] toDRAM_wstrb, 
 output         toDRAM_wvalid
);

wire [31:0] axi2dram_ht_araddr;
wire [1:0]  axi2dram_ht_arburst;
wire [3:0]  axi2dram_ht_arcache;
wire [4:0]  axi2dram_ht_arid;
wire [7:0]  axi2dram_ht_arlen;
wire [2:0]  axi2dram_ht_arprot;
wire        axi2dram_ht_arready;
wire [2:0]  axi2dram_ht_arsize;
wire        axi2dram_ht_arvalid;
wire [3:0]  axi2dram_ht_aruser;
wire [511:0]axi2dram_ht_rdata;
wire        axi2dram_ht_rlast;
wire        axi2dram_ht_rready;
wire [1:0]  axi2dram_ht_rresp;
wire        axi2dram_ht_rvalid;
wire [31:0] axi2dram_vs_araddr;
wire [1:0]  axi2dram_vs_arburst;
wire [3:0]  axi2dram_vs_arcache;
wire [4:0]  axi2dram_vs_arid;
wire [7:0]  axi2dram_vs_arlen;
wire [2:0]  axi2dram_vs_arprot;
wire        axi2dram_vs_arready;
wire [2:0]  axi2dram_vs_arsize;
wire [3:0]  axi2dram_vs_aruser;
wire        axi2dram_vs_arvalid;
wire [511:0]axi2dram_vs_rdata;
wire        axi2dram_vs_rlast;
wire        axi2dram_vs_rready;
wire [1:0]  axi2dram_vs_rresp;
wire        axi2dram_vs_rvalid;
wire [31:0] axi2dram_buddy_araddr;
wire [1:0]  axi2dram_buddy_arburst;
wire [3:0]  axi2dram_buddy_arcache;
wire [4:0]  axi2dram_buddy_arid;
wire [7:0]  axi2dram_buddy_arlen;
wire [2:0]  axi2dram_buddy_arprot;
wire        axi2dram_buddy_arready;
wire [2:0]  axi2dram_buddy_arsize;
wire [3:0]  axi2dram_buddy_aruser;
wire        axi2dram_buddy_arvalid;
wire [511:0]axi2dram_buddy_rdata;
wire        axi2dram_buddy_rlast;
wire        axi2dram_buddy_rready;
wire [1:0]  axi2dram_buddy_rresp;
wire        axi2dram_buddy_rvalid;
wire [31:0] axi2dram_ht_awaddr;
wire [1:0]  axi2dram_ht_awburst;
wire [3:0]  axi2dram_ht_awcache;
wire [4:0]  axi2dram_ht_awid;
wire [7:0]  axi2dram_ht_awlen;
wire [2:0]  axi2dram_ht_awprot;
wire        axi2dram_ht_awready;
wire [2:0]  axi2dram_ht_awsize;
wire [3:0]  axi2dram_ht_awuser;
wire        axi2dram_ht_awvalid;
wire        axi2dram_ht_bready;
wire [1:0]  axi2dram_ht_bresp;
wire        axi2dram_ht_bvalid;
wire [511:0]axi2dram_ht_wdata;
wire        axi2dram_ht_wlast;
wire        axi2dram_ht_wready;
wire [63:0] axi2dram_ht_wstrb;
wire        axi2dram_ht_wvalid;
wire [31:0] axi2dram_vs_awaddr;
wire [1:0]  axi2dram_vs_awburst;
wire [3:0]  axi2dram_vs_awcache;
wire [4:0]  axi2dram_vs_awid;
wire [7:0]  axi2dram_vs_awlen;
wire [2:0]  axi2dram_vs_awprot;
wire        axi2dram_vs_awready;
wire [2:0]  axi2dram_vs_awsize;
wire [3:0]  axi2dram_vs_awuser;
wire        axi2dram_vs_awvalid;
wire        axi2dram_vs_bready;
wire [1:0]  axi2dram_vs_bresp;
wire        axi2dram_vs_bvalid;
wire [511:0]axi2dram_vs_wdata;
wire        axi2dram_vs_wlast;
wire        axi2dram_vs_wready;
wire [63:0] axi2dram_vs_wstrb;
wire        axi2dram_vs_wvalid;
wire [31:0] axi2dram_buddy_awaddr;
wire [1:0]  axi2dram_buddy_awburst;
wire [3:0]  axi2dram_buddy_awcache;
wire [4:0]  axi2dram_buddy_awid;
wire [7:0]  axi2dram_buddy_awlen;
wire [2:0]  axi2dram_buddy_awprot;
wire        axi2dram_buddy_awready;
wire [2:0]  axi2dram_buddy_awsize;
wire [3:0]  axi2dram_buddy_awuser;
wire        axi2dram_buddy_awvalid;
wire        axi2dram_buddy_bready;
wire [1:0]  axi2dram_buddy_bresp;
wire        axi2dram_buddy_bvalid;
wire [511:0]axi2dram_buddy_wdata;
wire        axi2dram_buddy_wlast;
wire        axi2dram_buddy_wready;
wire [63:0] axi2dram_buddy_wstrb;
wire        axi2dram_buddy_wvalid;

memcached_pipeline u_mcd_buddy(
     .MCD_AXI2DRAM_RD_C0_araddr     (axi2dram_ht_araddr),
     .MCD_AXI2DRAM_RD_C0_arburst    (axi2dram_ht_arburst),
     .MCD_AXI2DRAM_RD_C0_arcache    (axi2dram_ht_arcache),
     .MCD_AXI2DRAM_RD_C0_arid       (axi2dram_ht_arid),
     .MCD_AXI2DRAM_RD_C0_arlen      (axi2dram_ht_arlen),
     .MCD_AXI2DRAM_RD_C0_arprot     (axi2dram_ht_arprot),
     .MCD_AXI2DRAM_RD_C0_arready    (axi2dram_ht_arready),
     .MCD_AXI2DRAM_RD_C0_arsize     (axi2dram_ht_arsize),
     .MCD_AXI2DRAM_RD_C0_aruser     (axi2dram_ht_aruser),
     .MCD_AXI2DRAM_RD_C0_arvalid    (axi2dram_ht_arvalid),
     .MCD_AXI2DRAM_RD_C0_rdata      (axi2dram_ht_rdata),
     .MCD_AXI2DRAM_RD_C0_rlast      (axi2dram_ht_rlast),
     .MCD_AXI2DRAM_RD_C0_rready     (axi2dram_ht_rready),
     .MCD_AXI2DRAM_RD_C0_rresp      (axi2dram_ht_rresp),
     .MCD_AXI2DRAM_RD_C0_rvalid     (axi2dram_ht_rvalid),
     .MCD_AXI2DRAM_RD_C1_araddr     (axi2dram_vs_araddr),
     .MCD_AXI2DRAM_RD_C1_arburst    (axi2dram_vs_arburst), 
     .MCD_AXI2DRAM_RD_C1_arcache    (axi2dram_vs_arcache),
     .MCD_AXI2DRAM_RD_C1_arid       (axi2dram_vs_arid),
     .MCD_AXI2DRAM_RD_C1_arlen      (axi2dram_vs_arlen),
     .MCD_AXI2DRAM_RD_C1_arprot     (axi2dram_vs_arprot),
     .MCD_AXI2DRAM_RD_C1_arready    (axi2dram_vs_arready),
     .MCD_AXI2DRAM_RD_C1_arsize     (axi2dram_vs_arsize),
     .MCD_AXI2DRAM_RD_C1_aruser     (axi2dram_vs_aruser),
     .MCD_AXI2DRAM_RD_C1_arvalid    (axi2dram_vs_arvalid),
     .MCD_AXI2DRAM_RD_C1_rdata      (axi2dram_vs_rdata),
     .MCD_AXI2DRAM_RD_C1_rlast      (axi2dram_vs_rlast),
     .MCD_AXI2DRAM_RD_C1_rready     (axi2dram_vs_rready),
     .MCD_AXI2DRAM_RD_C1_rresp      (axi2dram_vs_rresp),
     .MCD_AXI2DRAM_RD_C1_rvalid     (axi2dram_vs_rvalid),
     .MCD_AXI2DRAM_WR_C0_awaddr     (axi2dram_ht_awaddr),
     .MCD_AXI2DRAM_WR_C0_awburst    (axi2dram_ht_awburst),
     .MCD_AXI2DRAM_WR_C0_awcache    (axi2dram_ht_awcache),
     .MCD_AXI2DRAM_WR_C0_awid       (axi2dram_ht_awid),
     .MCD_AXI2DRAM_WR_C0_awlen      (axi2dram_ht_awlen),
     .MCD_AXI2DRAM_WR_C0_awprot     (axi2dram_ht_awprot),
     .MCD_AXI2DRAM_WR_C0_awready    (axi2dram_ht_awready),
     .MCD_AXI2DRAM_WR_C0_awsize     (axi2dram_ht_awsize),
     .MCD_AXI2DRAM_WR_C0_awuser     (axi2dram_ht_awuser),
     .MCD_AXI2DRAM_WR_C0_awvalid    (axi2dram_ht_awvalid),
     .MCD_AXI2DRAM_WR_C0_bready     (axi2dram_ht_bready),
     .MCD_AXI2DRAM_WR_C0_bresp      (axi2dram_ht_bresp),
     .MCD_AXI2DRAM_WR_C0_bvalid     (axi2dram_ht_bvalid),
     .MCD_AXI2DRAM_WR_C0_wdata      (axi2dram_ht_wdata),
     .MCD_AXI2DRAM_WR_C0_wlast      (axi2dram_ht_wlast),
     .MCD_AXI2DRAM_WR_C0_wready     (axi2dram_ht_wready),
     .MCD_AXI2DRAM_WR_C0_wstrb      (axi2dram_ht_wstrb),
     .MCD_AXI2DRAM_WR_C0_wvalid     (axi2dram_ht_wvalid),
     .MCD_AXI2DRAM_WR_C1_awaddr     (axi2dram_vs_awaddr),
     .MCD_AXI2DRAM_WR_C1_awburst    (axi2dram_vs_awburst),
     .MCD_AXI2DRAM_WR_C1_awcache    (axi2dram_vs_awcache),
     .MCD_AXI2DRAM_WR_C1_awid       (axi2dram_vs_awid),
     .MCD_AXI2DRAM_WR_C1_awlen      (axi2dram_vs_awlen),
     .MCD_AXI2DRAM_WR_C1_awprot     (axi2dram_vs_awprot),
     .MCD_AXI2DRAM_WR_C1_awready    (axi2dram_vs_awready),
     .MCD_AXI2DRAM_WR_C1_awsize     (axi2dram_vs_awsize),
     .MCD_AXI2DRAM_WR_C1_awuser     (axi2dram_vs_awuser),
     .MCD_AXI2DRAM_WR_C1_awvalid    (axi2dram_vs_awvalid), 
     .MCD_AXI2DRAM_WR_C1_bready     (axi2dram_vs_bready),
     .MCD_AXI2DRAM_WR_C1_bresp      (axi2dram_vs_bresp),
     .MCD_AXI2DRAM_WR_C1_bvalid     (axi2dram_vs_bvalid),
     .MCD_AXI2DRAM_WR_C1_wdata      (axi2dram_vs_wdata),
     .MCD_AXI2DRAM_WR_C1_wlast      (axi2dram_vs_wlast),
     .MCD_AXI2DRAM_WR_C1_wready     (axi2dram_vs_wready),
     .MCD_AXI2DRAM_WR_C1_wstrb      (axi2dram_vs_wstrb),
     .MCD_AXI2DRAM_WR_C1_wvalid     (axi2dram_vs_wvalid),
     .aclk                          (apclk),
     .aresetn                       (apresetn),
     .fromNet_tdata                 (from_net_tdata),
     .fromNet_tkeep                 (from_net_tkeep),
     .fromNet_tlast                 (from_net_tlast),
     .fromNet_tready                (from_net_tready),
     .fromNet_tuser                 (from_net_tuser),
     .fromNet_tvalid                (from_net_tvalid),
     .mem_c0_clk                    (mem_clk),
     .mem_c0_resetn                 (mem_resetn),
     .toNet_tdata                   (to_net_tdata),
     .toNet_tkeep                   (to_net_tkeep),
     .toNet_tlast                   (to_net_tlast),
     .toNet_tready                  (to_net_tready),
     .toNet_tuser                   (to_net_tuser),
     .toNet_tvalid                  (to_net_tvalid)
);

axi_interconnect u_ht_vs_interconnect(
 .APCLK_0            (apclk),
 .ARESETN_0          (apresetn),
 .M00_AXI_0_araddr   (toDRAM_araddr),
 .M00_AXI_0_arburst  (toDRAM_arburst),
 .M00_AXI_0_arcache  (toDRAM_arcache),
 .M00_AXI_0_arid     (toDRAM_arid),
 .M00_AXI_0_arlen    (toDRAM_arlen),
 .M00_AXI_0_arlock   (toDRAM_arlock),
 .M00_AXI_0_arprot   (toDRAM_arprot),
 .M00_AXI_0_arqos    (toDRAM_arqos),
 .M00_AXI_0_arready  (toDRAM_arready),
 .M00_AXI_0_arregion (toDRAM_arregion),
 .M00_AXI_0_arsize   (toDRAM_arsize),
 .M00_AXI_0_arvalid  (toDRAM_arvalid),
 .M00_AXI_0_awaddr   (toDRAM_awaddr),
 .M00_AXI_0_awburst  (toDRAM_awburst),
 .M00_AXI_0_awcache  (toDRAM_awcache),
 .M00_AXI_0_awid     (toDRAM_awid),
 .M00_AXI_0_awlen    (toDRAM_awlen),
 .M00_AXI_0_awlock   (toDRAM_awlock),
 .M00_AXI_0_awprot   (toDRAM_awprot),
 .M00_AXI_0_awqos    (toDRAM_awqos),
 .M00_AXI_0_awready  (toDRAM_awready),
 .M00_AXI_0_awregion (toDRAM_awregion),
 .M00_AXI_0_awsize   (toDRAM_awsize),
 .M00_AXI_0_awvalid  (toDRAM_awvalid),
 .M00_AXI_0_bid      (toDRAM_bid),
 .M00_AXI_0_bready   (toDRAM_bready),
 .M00_AXI_0_bresp    (toDRAM_bresp),
 .M00_AXI_0_bvalid   (toDRAM_bvalid),
 .M00_AXI_0_rdata    (toDRAM_rdata),
 .M00_AXI_0_rid      (toDRAM_rid),
 .M00_AXI_0_rlast    (toDRAM_rlast),
 .M00_AXI_0_rready   (toDRAM_rready),
 .M00_AXI_0_rresp    (toDRAM_rresp),
 .M00_AXI_0_rvalid   (toDRAM_rvalid),
 .M00_AXI_0_wdata    (toDRAM_wdata),
 .M00_AXI_0_wlast    (toDRAM_wlast),
 .M00_AXI_0_wready   (toDRAM_wready),
 .M00_AXI_0_wstrb    (toDRAM_wstrb),
 .M00_AXI_0_wvalid   (toDRAM_wvalid),
 .S00_AXI_0_araddr   (axi2dram_ht_araddr),
 .S00_AXI_0_arburst  (axi2dram_ht_arburst),
 .S00_AXI_0_arcache  (axi2dram_ht_arcache),
 .S00_AXI_0_arlen    (axi2dram_ht_arlen),
 .S00_AXI_0_arlock   (),
 .S00_AXI_0_arprot   (axi2dram_ht_arprot),
 .S00_AXI_0_arqos    (),
 .S00_AXI_0_arready  (axi2dram_ht_arready),
 .S00_AXI_0_arsize   (axi2dram_ht_arsize),
 .S00_AXI_0_arvalid  (axi2dram_ht_arvalid),
 .S00_AXI_0_awaddr   (axi2dram_ht_awaddr),
 .S00_AXI_0_awburst  (axi2dram_ht_awburst),
 .S00_AXI_0_awcache  (axi2dram_ht_awcache),
 .S00_AXI_0_awlen    (axi2dram_ht_awlen),
 .S00_AXI_0_awlock   (),
 .S00_AXI_0_awprot   (axi2dram_ht_awprot),
 .S00_AXI_0_awqos    (),
 .S00_AXI_0_awready  (axi2dram_ht_awready),
 .S00_AXI_0_awsize   (axi2dram_ht_awsize),
 .S00_AXI_0_awvalid  (axi2dram_ht_awvalid),
 .S00_AXI_0_bready   (axi2dram_ht_bready),
 .S00_AXI_0_bresp    (axi2dram_ht_bresp),
 .S00_AXI_0_bvalid   (axi2dram_ht_bvalid),
 .S00_AXI_0_rdata    (axi2dram_ht_rdata),
 .S00_AXI_0_rlast    (axi2dram_ht_rlast),
 .S00_AXI_0_rready   (axi2dram_ht_rready),
 .S00_AXI_0_rresp    (axi2dram_ht_rresp),
 .S00_AXI_0_rvalid   (axi2dram_ht_rvalid),
 .S00_AXI_0_wdata    (axi2dram_ht_wdata),
 .S00_AXI_0_wlast    (axi2dram_ht_wlast),
 .S00_AXI_0_wready   (axi2dram_ht_wready),
 .S00_AXI_0_wstrb    (axi2dram_ht_wstrb),
 .S00_AXI_0_wvalid   (axi2dram_ht_wvalid),
 .S01_AXI_0_araddr   (axi2dram_vs_araddr),
 .S01_AXI_0_arburst  (axi2dram_vs_arburst),
 .S01_AXI_0_arcache  (axi2dram_vs_arcache),
 .S01_AXI_0_arlen    (axi2dram_vs_arlen),
 .S01_AXI_0_arlock   (),
 .S01_AXI_0_arprot   (axi2dram_vs_arprot),
 .S01_AXI_0_arqos    (),
 .S01_AXI_0_arready  (axi2dram_vs_arready),
 .S01_AXI_0_arsize   (axi2dram_vs_arsize),
 .S01_AXI_0_arvalid  (axi2dram_vs_arvalid),
 .S01_AXI_0_awaddr   (axi2dram_vs_awaddr),
 .S01_AXI_0_awburst  (axi2dram_vs_awburst),
 .S01_AXI_0_awcache  (axi2dram_vs_awcache),
 .S01_AXI_0_awlen    (axi2dram_vs_awlen),
 .S01_AXI_0_awlock   (),
 .S01_AXI_0_awprot   (axi2dram_vs_awprot),
 .S01_AXI_0_awqos    (),
 .S01_AXI_0_awready  (axi2dram_vs_awready),
 .S01_AXI_0_awsize   (axi2dram_vs_awsize),
 .S01_AXI_0_awvalid  (axi2dram_vs_awvalid),
 .S01_AXI_0_bready   (axi2dram_vs_bready),
 .S01_AXI_0_bresp    (axi2dram_vs_bresp),
 .S01_AXI_0_bvalid   (axi2dram_vs_bvalid),
 .S01_AXI_0_rdata    (axi2dram_vs_rdata),
 .S01_AXI_0_rlast    (axi2dram_vs_rlast),
 .S01_AXI_0_rready   (axi2dram_vs_rready),
 .S01_AXI_0_rresp    (axi2dram_vs_rresp),
 .S01_AXI_0_rvalid   (axi2dram_vs_rvalid),
 .S01_AXI_0_wdata    (axi2dram_vs_wdata),
 .S01_AXI_0_wlast    (axi2dram_vs_wlast),
 .S01_AXI_0_wready   (axi2dram_vs_wready),
 .S01_AXI_0_wstrb    (axi2dram_vs_wstrb),
 .S01_AXI_0_wvalid   (axi2dram_vs_wvalid),
 .S02_AXI_0_araddr   (axi2dram_buddy_araddr),
 .S02_AXI_0_arburst  (axi2dram_buddy_arburst),
 .S02_AXI_0_arcache  (axi2dram_buddy_arcache),
 .S02_AXI_0_arlen    (axi2dram_buddy_arlen),
 .S02_AXI_0_arlock   (),
 .S02_AXI_0_arprot   (axi2dram_buddy_arprot),
 .S02_AXI_0_arqos    (),
 .S02_AXI_0_arready  (axi2dram_buddy_arready),
 .S02_AXI_0_arsize   (axi2dram_buddy_arsize),
 .S02_AXI_0_arvalid  (axi2dram_buddy_arvalid),
 .S02_AXI_0_awaddr   (axi2dram_buddy_awaddr),
 .S02_AXI_0_awburst  (axi2dram_buddy_awburst),
 .S02_AXI_0_awcache  (axi2dram_buddy_awcache),
 .S02_AXI_0_awlen    (axi2dram_buddy_awlen),
 .S02_AXI_0_awlock   (),
 .S02_AXI_0_awprot   (axi2dram_buddy_awprot),
 .S02_AXI_0_awqos    (),
 .S02_AXI_0_awready  (axi2dram_buddy_awready),
 .S02_AXI_0_awsize   (axi2dram_buddy_awsize),
 .S02_AXI_0_awvalid  (axi2dram_buddy_awvalid),
 .S02_AXI_0_bready   (axi2dram_buddy_bready),
 .S02_AXI_0_bresp    (axi2dram_buddy_bresp),
 .S02_AXI_0_bvalid   (axi2dram_buddy_bvalid),
 .S02_AXI_0_rdata    (axi2dram_buddy_rdata),
 .S02_AXI_0_rlast    (axi2dram_buddy_rlast),
 .S02_AXI_0_rready   (axi2dram_buddy_rready),
 .S02_AXI_0_rresp    (axi2dram_buddy_rresp),
 .S02_AXI_0_rvalid   (axi2dram_buddy_rvalid),
 .S02_AXI_0_wdata    (axi2dram_buddy_wdata),
 .S02_AXI_0_wlast    (axi2dram_buddy_wlast),
 .S02_AXI_0_wready   (axi2dram_buddy_wready),
 .S02_AXI_0_wstrb    (axi2dram_buddy_wstrb),
 .S02_AXI_0_wvalid   (axi2dram_buddy_wvalid),
 .axi_clk            (mem_clk),
 .axi_resetn         (mem_resetn)
);

endmodule

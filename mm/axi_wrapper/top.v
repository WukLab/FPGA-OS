module axi_wrapper #
(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32,
	parameter STRB_WIDTH = (DATA_WIDTH/8),
	parameter ID_WIDTH = 8,
	parameter AWUSER_ENABLE = 0,
	parameter AWUSER_WIDTH = 1,
	parameter WUSER_ENABLE = 0,
	parameter WUSER_WIDTH = 1,
	parameter BUSER_ENABLE = 0,
	parameter BUSER_WIDTH = 1,
	parameter ARUSER_ENABLE = 0,
	parameter ARUSER_WIDTH = 1,
	parameter RUSER_ENABLE = 0,
	parameter RUSER_WIDTH = 1
)
(
	input  wire                     s_axi_clk,
	input  wire                     m_axi_clk,
	
	/*
	 * AXI slave interface
	 */
	input  wire [ID_WIDTH-1:0]      s_axi_awid,
	input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
	input  wire [7:0]               s_axi_awlen,
	input  wire [2:0]               s_axi_awsize,
	input  wire [1:0]               s_axi_awburst,
	input  wire                     s_axi_awlock,
	input  wire [3:0]               s_axi_awcache,
	input  wire [2:0]               s_axi_awprot,
	input  wire [3:0]               s_axi_awqos,
	input  wire [3:0]               s_axi_awregion,
	input  wire [AWUSER_WIDTH-1:0]  s_axi_awuser,
	input  wire                     s_axi_awvalid,
	output wire                     s_axi_awready,
	input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
	input  wire [STRB_WIDTH-1:0]    s_axi_wstrb,
	input  wire                     s_axi_wlast,
	input  wire [WUSER_WIDTH-1:0]   s_axi_wuser,
	input  wire                     s_axi_wvalid,
	output wire                     s_axi_wready,
	output wire [ID_WIDTH-1:0]      s_axi_bid,
	output wire [1:0]               s_axi_bresp,
	output wire [BUSER_WIDTH-1:0]   s_axi_buser,
	output wire                     s_axi_bvalid,
	input  wire                     s_axi_bready,
	input  wire [ID_WIDTH-1:0]      s_axi_arid,
	input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
	input  wire [7:0]               s_axi_arlen,
	input  wire [2:0]               s_axi_arsize,
	input  wire [1:0]               s_axi_arburst,
	input  wire                     s_axi_arlock,
	input  wire [3:0]               s_axi_arcache,
	input  wire [2:0]               s_axi_arprot,
	input  wire [3:0]               s_axi_arqos,
	input  wire [3:0]               s_axi_arregion,
	input  wire [ARUSER_WIDTH-1:0]  s_axi_aruser,
	input  wire                     s_axi_arvalid,
	output wire                     s_axi_arready,
	output wire [ID_WIDTH-1:0]      s_axi_rid,
	output wire [DATA_WIDTH-1:0]    s_axi_rdata,
	output wire [1:0]               s_axi_rresp,
	output wire                     s_axi_rlast,
	output wire [RUSER_WIDTH-1:0]   s_axi_ruser,
	output wire                     s_axi_rvalid,
	input  wire                     s_axi_rready,
	
	/*
	 * AXI master interface
	 */
	output wire [ID_WIDTH-1:0]      m_axi_awid,
	output wire [ADDR_WIDTH-1:0]    m_axi_awaddr,
	output wire [7:0]               m_axi_awlen,
	output wire [2:0]               m_axi_awsize,
	output wire [1:0]               m_axi_awburst,
	output wire                     m_axi_awlock,
	output wire [3:0]               m_axi_awcache,
	output wire [2:0]               m_axi_awprot,
	output wire [3:0]               m_axi_awqos,
	output wire [3:0]               m_axi_awregion,
	output wire [AWUSER_WIDTH-1:0]  m_axi_awuser,
	output wire                     m_axi_awvalid,
	input  wire                     m_axi_awready,
	output wire [DATA_WIDTH-1:0]    m_axi_wdata,
	output wire [STRB_WIDTH-1:0]    m_axi_wstrb,
	output wire                     m_axi_wlast,
	output wire [WUSER_WIDTH-1:0]   m_axi_wuser,
	output wire                     m_axi_wvalid,
	input  wire                     m_axi_wready,
	input  wire [ID_WIDTH-1:0]      m_axi_bid,
	input  wire [1:0]               m_axi_bresp,
	input  wire [BUSER_WIDTH-1:0]   m_axi_buser,
	input  wire                     m_axi_bvalid,
	output wire                     m_axi_bready,
	output wire [ID_WIDTH-1:0]      m_axi_arid,
	output wire [ADDR_WIDTH-1:0]    m_axi_araddr,
	output wire [7:0]               m_axi_arlen,
	output wire [2:0]               m_axi_arsize,
	output wire [1:0]               m_axi_arburst,
	output wire                     m_axi_arlock,
	output wire [3:0]               m_axi_arcache,
	output wire [2:0]               m_axi_arprot,
	output wire [3:0]               m_axi_arqos,
	output wire [3:0]               m_axi_arregion,
	output wire [ARUSER_WIDTH-1:0]  m_axi_aruser,
	output wire                     m_axi_arvalid,
	input  wire                     m_axi_arready,
	input  wire [ID_WIDTH-1:0]      m_axi_rid,
	input  wire [DATA_WIDTH-1:0]    m_axi_rdata,
	input  wire [1:0]               m_axi_rresp,
	input  wire                     m_axi_rlast,
	input  wire [RUSER_WIDTH-1:0]   m_axi_ruser,
	input  wire                     m_axi_rvalid,
	output wire                     m_axi_rready
);

	assign m_axi_awid = s_axi_awid;
	assign m_axi_awaddr = s_axi_awaddr;
	assign m_axi_awlen = s_axi_awlen;
	assign m_axi_awsize = s_axi_awsize;
	assign m_axi_awburst = s_axi_awburst;
	assign m_axi_awlock= s_axi_awlock;
	assign m_axi_awcache= s_axi_awcache;
	assign m_axi_awprot = s_axi_awprot;
	assign m_axi_awqos = s_axi_awqos;
	assign m_axi_awregion = s_axi_awregion;
	assign m_axi_awuser = s_axi_awuser;
	assign m_axi_awvalid = s_axi_awvalid;
	assign m_axi_awready = s_axi_awready;
	assign m_axi_awdata = s_axi_wdata;
	assign m_axi_awstrb = s_axi_wstrb;
	assign m_axi_wlast = s_axi_wlast;
	assign m_axi_wuser = s_axi_wuser;
	assign m_axi_wvalid = s_axi_wvalid;
	assign m_axi_wready = s_axi_wready;
	assign m_axi_bid = s_axi_bid;
	assign m_axi_bresp = s_axi_bresp;
	assign m_axi_buser = s_axi_buser;
	assign m_axi_bvalid = s_axi_bvalid;
	assign m_axi_bready = s_axi_bready;
	assign m_axi_arid = s_axi_arid;
	assign m_axi_araddr = s_axi_araddr;
	assign m_axi_arlen = s_axi_arlen;
	assign m_axi_arsize = s_axi_arsize;
	assign m_axi_arburst = s_axi_arburst;
	assign m_axi_arlock = s_axi_arlock;
	assign m_axi_arcache = s_axi_arcache;
	assign m_axi_arprot = s_axi_arprot;
	assign m_axi_arqos = s_axi_arqos;
	assign m_axi_arregion = s_axi_arregion;
	assign m_axi_aruser = s_axi_aruser;
	assign m_axi_arvalid = s_axi_arvalid;
	assign m_axi_arready = s_axi_arready;
	assign m_axi_rid = s_axi_rid;
	assign m_axi_rdata = s_axi_rdata;
	assign m_axi_rresp = s_axi_rresp;
	assign m_axi_rlast = s_axi_rlast;
	assign m_axi_ruser = s_axi_ruser;
	assign m_axi_rvalid = s_axi_rvalid;
	assign m_axi_rready = s_axi_rready;

endmodule

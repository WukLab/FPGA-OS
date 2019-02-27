/*------------------------------------------------------------------------------
 * Title      : AXI based MMU IP
 * Project    : LegoFPGA 
 *------------------------------------------------------------------------------
 * File       : axi_mmu_wrapper 
 * -----------------------------------------------------------------------------
 * Description: This is the top level for the MMU IP. It acts as slave to a master
 *              AXI and sends virtual address to translation unit and on successful 
 *              translation receives a done and the Physical address which is sent
 *              to the slave (Memory controller or other consumer).
 * ------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module axi_mmu_wrapper #(
    parameter AW_BUF_SZ = 32,
    parameter AR_BUF_SZ = 32,
    parameter W_BUF_SZ  = 256,
    parameter R_BUF_SZ  = 256,
    parameter B_BUF_SZ  = 16
)
(
    input         s_axi_clk,
    input         m_axi_clk,
    input         s_aresetn,
    input         m_aresetn,

/*WRITE ADDRESS CHANNEL*/
/* slave write address channel of MMU sharing interface with master app/interconnect AXI */
    input  [3:0]  s_axi_AWID,
    input [31:0]  s_axi_AWADDR,
    input  [7:0]  s_axi_AWLEN,
    input  [2:0]  s_axi_AWSIZE,
    input  [1:0]  s_axi_AWBURST,
    input  [2:0]  s_axi_AWPROT,
    input  [3:0]  s_axi_AWCACHE,
    input  [1:0]  s_axi_AWUSER,
    input         s_axi_AWLOCK,
    input         s_axi_AWVALID,
    output        s_axi_AWREADY,
/* master write address channel of MMU sharing interface with slave Mem/Sys AXI*/
    output  [3:0] m_axi_AWID,
    output [31:0] m_axi_AWADDR,
    output  [7:0] m_axi_AWLEN,
    output  [2:0] m_axi_AWSIZE,
    output  [1:0] m_axi_AWBURST,
    output  [2:0] m_axi_AWPROT,
    output  [3:0] m_axi_AWCACHE,
    output  [1:0] m_axi_AWUSER,
    output        m_axi_AWLOCK,
    output        m_axi_AWVALID, 
    input         m_axi_AWREADY,

/*WRITE DATA CHANNEL*/
/* Slave write data channel of MMU sharing interface with master App/Interconnect AXI */
    input  [3:0]  s_axi_WID,
    input [31:0]  s_axi_WDATA,
    input  [3:0]  s_axi_WSTRB,
    input  [1:0]  s_axi_WUSER,
    input         s_axi_WLAST,
    input         s_axi_WVALID,
    output        s_axi_WREADY,
/* Master write data channel of MMU sharing interface with slave sys/mem AXI */
    output  [3:0] m_axi_WID,
    output [31:0] m_axi_WDATA,
    output  [3:0] m_axi_WSTRB,
    output  [1:0] m_axi_WUSER,
    output        m_axi_WLAST,
    output        m_axi_WVALID,
    input         m_axi_WREADY,

/*WRITE RESPONSE CHANNEL*/
/* write resp channel of MMU sharing interface with slave sys/mem AXI */
    input   [3:0] m_axi_BID,
    input   [1:0] m_axi_BRESP,
    input   [1:0] m_axi_BUSER,
    input         m_axi_BVALID,
    output        m_axi_BREADY,

/* write resp channel of MMU sharing interface with actual master i.e. App/interconnect */
    output  [3:0] s_axi_BID,
    output  [1:0] s_axi_BRESP,
    output  [1:0] s_axi_BUSER,
    output        s_axi_BVALID,
    input         s_axi_BREADY,

/* READ ADDRESS CHANNEL*/
/* slave read address channel of MMU sharing interface with master app/interconnect AXI */
    input  [3:0]  s_axi_ARID,
    input [31:0]  s_axi_ARADDR,
    input  [7:0]  s_axi_ARLEN,
    input  [2:0]  s_axi_ARSIZE,
    input  [1:0]  s_axi_ARBURST,
    input  [2:0]  s_axi_ARPROT,
    input  [3:0]  s_axi_ARCACHE,
    input  [1:0]  s_axi_ARUSER,
    input         s_axi_ARLOCK,
    input         s_axi_ARVALID,
    output        s_axi_ARREADY,
/* Master read address channel of MMU sharing interface with slave Mem/Sys AXI */
    output  [3:0] m_axi_ARID,
    output [31:0] m_axi_ARADDR,
    output  [7:0] m_axi_ARLEN,
    output  [2:0] m_axi_ARSIZE,
    output  [1:0] m_axi_ARBURST,
    output  [2:0] m_axi_ARPROT,
    output  [3:0] m_axi_ARCACHE,
    output  [1:0] m_axi_ARUSER,
    output        m_axi_ARLOCK,
    output        m_axi_ARVALID, 
    input         m_axi_ARREADY,
    
/* READ DATA CHANNEL*/
/* read data channel of MMU sharing interface with slave sys/mem AXI */
    input   [3:0] m_axi_RID,
    input  [31:0] m_axi_RDATA,
    input   [1:0] m_axi_RRESP,
    input   [1:0] m_axi_RUSER,
    input         m_axi_RLAST,
    input         m_axi_RVALID,
    output        m_axi_RREADY,
    
/* read data channel of MMU sharing interface with actual master i.e. App/interconnect */
    output  [3:0] s_axi_RID,
    output [31:0] s_axi_RDATA,
    output  [1:0] s_axi_RRESP,
    output  [1:0] s_axi_RUSER,
    output        s_axi_RLAST,
    output        s_axi_RVALID,
    input         s_axi_RREADY,

/* Output to traslation module */
    output [31:0] tmp_araddr,
    output  [2:0] tmp_arsize,
    output  [7:0] tmp_arlen,
    output [31:0] tmp_awaddr,
    output  [2:0] tmp_awsize,
    output  [7:0] tmp_awlen,
    input  [31:0] p_raddr,
    input  [31:0] p_waddr,
    input         t_rdone,
    input         t_wdone
);

//Wire
wire  [0:0] t_wdone    , t_rdone   , iaxi_rdone, iaxi_wdone; 
wire  [3:0] tmp_awid   , tmp_arid  , tmp_wid,     tmp_wstrb;
wire [31:0] tmp_awaddr , tmp_araddr, p_raddr    , p_waddr, tmp_wdata;
wire  [7:0] tmp_awlen  , tmp_arlen;
wire  [2:0] tmp_awsize , tmp_arsize, tmp_awprot , tmp_arprot;
wire  [3:0] tmp_awcache, tmp_arcache;
wire  [1:0] tmp_awuser , tmp_aruser, tmp_awburst, tmp_arburst;
wire        tmp_awlock , tmp_arlock;
/* Write Data */
axi_addr_ch_rx #(.BUF_SZ(AW_BUF_SZ))
               AXI_WA_RX ( .rx_clk    (s_axi_clk),
                           .reset_    (s_aresetn),
                           .in_id     (s_axi_AWID),
                           .in_addr   (s_axi_AWADDR),
                           .in_len    (s_axi_AWLEN),
                           .in_size   (s_axi_AWSIZE),
                           .in_burst  (s_axi_AWBURST),
                           .in_prot   (s_axi_AWPROT),
                           .in_user   (s_axi_AWUSER),
                           .in_cache  (s_axi_AWCACHE),
                           .in_lock   (s_axi_AWLOCK),
                           .in_valid  (s_axi_AWVALID),
                           .out_ready (s_axi_AWREADY),
                           .out_id    (tmp_awid),
                           .out_addr  (tmp_awaddr),
                           .out_len   (tmp_awlen),
                           .out_size  (tmp_awsize),
                           .out_burst (tmp_awburst),
                           .out_prot  (tmp_awprot),
                           .out_user  (tmp_awuser),
                           .out_cache (tmp_awcache),
                           .out_lock  (tmp_awlock),
                           .i_buf_rd  (iaxi_wdone)
                         );
                     
axi_addr_ch_tx AXI_WA_TX ( .tx_clk    (m_axi_clk),
                           .reset_    (m_aresetn),
                           .in_id     (tmp_awid),
                           .in_len    (tmp_awlen),
                           .in_size   (tmp_awsize),
                           .in_burst  (tmp_awburst),
                           .in_prot   (tmp_awprot),
                           .in_user   (tmp_awuser),
                           .in_cache  (tmp_awcache),
                           .in_lock   (tmp_awlock),
                           .out_id    (m_axi_AWID  ),
                           .out_addr  (m_axi_AWADDR),
                           .out_len   (m_axi_AWLEN ),
                           .out_size  (m_axi_AWSIZE),
                           .out_burst (m_axi_AWBURST),
                           .out_prot  (m_axi_AWPROT),
                           .out_user  (m_axi_AWUSER),
                           .out_cache (m_axi_AWCACHE),
                           .out_lock  (m_axi_AWLOCK),
                           .out_valid (m_axi_AWVALID),
                           .in_ready  (m_axi_AWREADY),
                           .phy_addr  (p_waddr),
                           .t_done    (t_wdone)
                         );

sync2d #(.DW(1)) sync2d_awready_masterClk(.d(t_wdone), .q(iaxi_wdone), .clk(s_axi_clk));

/* Write Data */
axi_wdata_ch #(.BUF_SZ(W_BUF_SZ))
             AXI_WDAT_CH ( .rx_clk     (s_axi_clk),
                           .tx_clk     (m_axi_clk),
                           .rxreset_   (s_aresetn),
                           .txreset_   (m_aresetn),

                           .in_wid     (s_axi_WID),
                           .in_wdata   (s_axi_WDATA),
                           .in_wstrb   (s_axi_WSTRB),
                           .in_wlast   (s_axi_WLAST),
                           .in_wuser   (s_axi_WUSER),
                           .in_swvalid (s_axi_WVALID),
                           .out_swready(s_axi_WREADY),

                           .out_wid    (m_axi_WID),
                           .out_wdata  (m_axi_WDATA),
                           .out_wstrb  (m_axi_WSTRB),
                           .out_wlast  (m_axi_WLAST),
                           .out_wuser  (m_axi_WUSER),
                           .out_mwvalid(m_axi_WVALID),
                           .in_mwready (m_axi_WREADY),

                           .start      (t_wdone)
                         );

/* Write response channel */
axi_bresp_ch #(.BUF_SZ(B_BUF_SZ))
             AXI_B_CH ( .rxclk      (m_axi_clk),
                        .rxreset_   (m_aresetn),
                        .txclk      (s_axi_clk),
                        .txreset_   (s_aresetn),

                        .in_mbid    (m_axi_BID),
                        .in_mbresp  (m_axi_BRESP),
                        .in_mbuser  (m_axi_BUSER),
                        .in_mbvalid (m_axi_BVALID),
                        .out_mbready(m_axi_BREADY),

                        .out_sbid   (s_axi_BID),
                        .out_sbresp (s_axi_BRESP),
                        .out_sbuser (s_axi_BUSER),
                        .out_sbvalid(s_axi_BVALID),
                        .in_sbready (s_axi_BREADY)
                      );
        
/* Read Address */
axi_addr_ch_rx #(.BUF_SZ(AR_BUF_SZ))
               AXI_RA_RX ( .rx_clk    (s_axi_clk),
                           .reset_    (s_aresetn),
                           .in_id     (s_axi_ARID),
                           .in_addr   (s_axi_ARADDR),
                           .in_len    (s_axi_ARLEN),
                           .in_size   (s_axi_ARSIZE),
                           .in_burst  (s_axi_ARBURST),
                           .in_prot   (s_axi_ARPROT),
                           .in_user   (s_axi_ARUSER),
                           .in_cache  (s_axi_ARCACHE),
                           .in_lock   (s_axi_ARLOCK),
                           .in_valid  (s_axi_ARVALID),
                           .out_ready (s_axi_ARREADY),
                           .out_id    (tmp_arid),
                           .out_addr  (tmp_araddr),
                           .out_len   (tmp_arlen),
                           .out_size  (tmp_arsize),
                           .out_burst (tmp_arburst),
                           .out_prot  (tmp_arprot),
                           .out_user  (tmp_aruser),
                           .out_cache (tmp_arcache),
                           .out_lock  (tmp_arlock),
                           .i_buf_rd  (iaxi_rdone)
                         );
                     
axi_addr_ch_tx AXI_RA_TX ( .tx_clk    (m_axi_clk),
                           .reset_    (m_aresetn),
                           .in_id     (tmp_arid),
                           .in_len    (tmp_arlen),
                           .in_size   (tmp_arsize),
                           .in_burst  (tmp_arburst),
                           .in_prot   (tmp_arprot),
                           .in_user   (tmp_aruser),
                           .in_cache  (tmp_arcache),
                           .in_lock   (tmp_arlock),
                           .out_id    (m_axi_ARID  ),
                           .out_addr  (m_axi_ARADDR),
                           .out_len   (m_axi_ARLEN ),
                           .out_size  (m_axi_ARSIZE),
                           .out_burst (m_axi_ARBURST),
                           .out_prot  (m_axi_ARPROT),
                           .out_user  (m_axi_ARUSER),
                           .out_cache (m_axi_ARCACHE),
                           .out_lock  (m_axi_ARLOCK),
                           .out_valid (m_axi_ARVALID),
                           .in_ready  (m_axi_ARREADY),
                           .phy_addr  (p_raddr),
                           .t_done    (t_rdone)
                         );

sync2d #(.DW(1)) sync2d_arready_masterClk(.d(t_rdone), .q(iaxi_rdone), .clk(s_axi_clk));

/* Read Data channel */
axi_rdata_ch #(.BUF_SZ(R_BUF_SZ))
             AXI_RDAT_CH ( .rxclk      (m_axi_clk),
                           .rxreset_   (m_aresetn),
                           .txclk      (s_axi_clk),
                           .txreset_   (s_aresetn),
                           
                           .in_rid     (m_axi_RID),
                           .in_rdata   (m_axi_RDATA),
                           .in_rresp   (m_axi_RRESP),
                           .in_ruser   (m_axi_RUSER),
                           .in_rlast   (m_axi_RLAST),
                           .in_mrvalid (m_axi_RVALID),
                           .out_mrready(m_axi_RREADY),
                       
                           .out_rid    (s_axi_RID),
                           .out_rdata  (s_axi_RDATA),
                           .out_rresp  (s_axi_RRESP),
                           .out_ruser  (s_axi_RUSER),
                           .out_rlast  (s_axi_RLAST),
                           .out_srvalid(s_axi_RVALID),
                           .in_srready (s_axi_RREADY)
                         );

endmodule

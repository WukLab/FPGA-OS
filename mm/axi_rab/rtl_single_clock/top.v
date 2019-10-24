/*------------------------------------------------------------------------------
 * Title      : AXI-MM Remapping Address Block (rab)
 * -----------------------------------------------------------------------------
 * Description: This is the top level for the MMU IP. It acts as slave to a master
 *              AXI and sends virtual address to translation unit and on successful
 *              translation receives a done and the Physical address which is sent
 *              to the slave (Memory controller or other consumer).
 * ------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module axi_rab_top #(
    parameter AW_BUF_SZ        = 32,
    parameter AR_BUF_SZ        = 32,
    parameter W_BUF_SZ         = 256,
    parameter R_BUF_SZ         = 256,
    parameter B_BUF_SZ         = 16,
    parameter AXI_DATA_WIDTH   = 32,
    parameter AXI_ADDR_WIDTH   = 32,
	parameter AXI_STRB_WIDTH   = (AXI_DATA_WIDTH/8),
	parameter AXI_ID_WIDTH     = 8,
	parameter AXI_AWUSER_WIDTH = 1,
	parameter AXI_WUSER_WIDTH  = 1,
	parameter AXI_BUSER_WIDTH  = 1,
	parameter AXI_ARUSER_WIDTH = 1,
	parameter AXI_RUSER_WIDTH  = 1,
    /* VIRT_ADDR + ID + LENGTH + SIZE + padding */
    parameter AXIS_TO_MM_WIDTH    = AXI_ADDR_WIDTH + AXI_ID_WIDTH + 8 + 3 + 5,
    /* PHY_ADDR + DONE/DROP + padding*/
    parameter AXIS_FROM_MM_WIDTH  = AXI_ADDR_WIDTH + 1 + 7
)
(
/*
 * AXI clk and reset single clock domain
 */
    input         s_axi_clk,
    input         s_aresetn,

/* WRITE ADDRESS CHANNEL*/
/* slave write address channel of MMU sharing interface with master app/interconnect AXI */
    input     [AXI_ID_WIDTH-1:0] s_axi_AWID,
    input   [AXI_ADDR_WIDTH-1:0] s_axi_AWADDR,
    input                  [7:0] s_axi_AWLEN,
    input                  [2:0] s_axi_AWSIZE,
    input                  [1:0] s_axi_AWBURST,
    input                  [2:0] s_axi_AWPROT,
    input                  [3:0] s_axi_AWCACHE,
    input [AXI_AWUSER_WIDTH-1:0] s_axi_AWUSER,
    input                        s_axi_AWLOCK,
    input                        s_axi_AWVALID,
    output                       s_axi_AWREADY,
/* master write address channel of MMU sharing interface with slave Mem/Sys AXI*/
    output     [AXI_ID_WIDTH-1:0] m_axi_AWID,
    output   [AXI_ADDR_WIDTH-1:0] m_axi_AWADDR,
    output                  [7:0] m_axi_AWLEN,
    output                  [2:0] m_axi_AWSIZE,
    output                  [1:0] m_axi_AWBURST,
    output                  [2:0] m_axi_AWPROT,
    output                  [3:0] m_axi_AWCACHE,
    output [AXI_AWUSER_WIDTH-1:0] m_axi_AWUSER,
    output                        m_axi_AWLOCK,
    output                        m_axi_AWVALID,
    input                         m_axi_AWREADY,

/*WRITE DATA CHANNEL*/
/* Slave write data channel of MMU sharing interface with master App/Interconnect AXI */
    input  [AXI_DATA_WIDTH-1:0] s_axi_WDATA,
    input  [AXI_STRB_WIDTH-1:0] s_axi_WSTRB,
    input [AXI_WUSER_WIDTH-1:0] s_axi_WUSER,
    input                       s_axi_WLAST,
    input                       s_axi_WVALID,
    output                      s_axi_WREADY,
/* Master write data channel of MMU sharing interface with slave sys/mem AXI */
    output  [AXI_DATA_WIDTH-1:0] m_axi_WDATA,
    output  [AXI_STRB_WIDTH-1:0] m_axi_WSTRB,
    output [AXI_WUSER_WIDTH-1:0] m_axi_WUSER,
    output                       m_axi_WLAST,
    output                       m_axi_WVALID,
    input                        m_axi_WREADY,

/*WRITE RESPONSE CHANNEL*/
/* write resp channel of MMU sharing interface with slave sys/mem AXI */
    input    [AXI_ID_WIDTH-1:0] m_axi_BID,
    input                 [1:0] m_axi_BRESP,
    input [AXI_BUSER_WIDTH-1:0] m_axi_BUSER,
    input                       m_axi_BVALID,
    output                      m_axi_BREADY,

/* write resp channel of MMU sharing interface with actual master i.e. App/interconnect */
    output    [AXI_ID_WIDTH-1:0] s_axi_BID,
    output                 [1:0] s_axi_BRESP,
    output [AXI_BUSER_WIDTH-1:0] s_axi_BUSER,
    output                       s_axi_BVALID,
    input                        s_axi_BREADY,

/* READ ADDRESS CHANNEL*/
/* slave read address channel of MMU sharing interface with master app/interconnect AXI */
    input     [AXI_ID_WIDTH-1:0] s_axi_ARID,
    input   [AXI_ADDR_WIDTH-1:0] s_axi_ARADDR,
    input                  [7:0] s_axi_ARLEN,
    input                  [2:0] s_axi_ARSIZE,
    input                  [1:0] s_axi_ARBURST,
    input                  [2:0] s_axi_ARPROT,
    input                  [3:0] s_axi_ARCACHE,
    input [AXI_ARUSER_WIDTH-1:0] s_axi_ARUSER,
    input                        s_axi_ARLOCK,
    input                        s_axi_ARVALID,
    output                       s_axi_ARREADY,
/* Master read address channel of MMU sharing interface with slave Mem/Sys AXI */
    output     [AXI_ID_WIDTH-1:0] m_axi_ARID,
    output   [AXI_ADDR_WIDTH-1:0] m_axi_ARADDR,
    output                  [7:0] m_axi_ARLEN,
    output                  [2:0] m_axi_ARSIZE,
    output                  [2:0] m_axi_ARPROT,
    output                  [3:0] m_axi_ARCACHE,
    output                  [1:0] m_axi_ARBURST,
    output [AXI_ARUSER_WIDTH-1:0] m_axi_ARUSER,
    output                        m_axi_ARLOCK,
    output                        m_axi_ARVALID,
    input                         m_axi_ARREADY,

/* READ DATA CHANNEL*/
/* read data channel of MMU sharing interface with slave sys/mem AXI */
    input    [AXI_ID_WIDTH-1:0] m_axi_RID,
    input  [AXI_DATA_WIDTH-1:0] m_axi_RDATA,
    input                 [1:0] m_axi_RRESP,
    input [AXI_RUSER_WIDTH-1:0] m_axi_RUSER,
    input                       m_axi_RLAST,
    input                       m_axi_RVALID,
    output                      m_axi_RREADY,

/* read data channel of MMU sharing interface with actual master i.e. App/interconnect */
    output    [AXI_ID_WIDTH-1:0] s_axi_RID,
    output  [AXI_DATA_WIDTH-1:0] s_axi_RDATA,
    output                 [1:0] s_axi_RRESP,
    output [AXI_RUSER_WIDTH-1:0] s_axi_RUSER,
    output                       s_axi_RLAST,
    output                       s_axi_RVALID,
    input                        s_axi_RREADY,

/* connections with MMU */
/*
 * axis stream data to the MMU - data packing
 * ADDR_WIDTH-1:0					-- virtual address,
 * ADDR_WIDTH+AXI_ID_WIDTH-1:ADDR_WIDTH			-- transaction ID, used for PID,
 * ADDR_WIDTH+AXI_ID_WIDTH+7:ADDR_WIDTH+AXI_ID_WIDTH	-- length
 * ADDR_WIDTH+AXI_ID_WIDTH+10:ADDR_WIDTH+AXI_ID_WIDTH+8	-- size
 */
    output [AXIS_TO_MM_WIDTH-1:0] toMM_RD_tdata,
    output                          toMM_RD_tvalid,
    input                           toMM_RD_tready,

    output [AXIS_TO_MM_WIDTH-1:0] toMM_WR_tdata,
    output                          toMM_WR_tvalid,
    input                           toMM_WR_tready,

/* axis from the MMU -- data packing -- MSB == 0 -> drop, MSB == 1 -> done, lower ADDR_WIDTH is the physical address */
    input [AXIS_FROM_MM_WIDTH-1:0] fromMM_RD_tdata,
    input                          fromMM_RD_tvalid,
    output                         fromMM_RD_tready,

    input [AXIS_FROM_MM_WIDTH-1:0] fromMM_WR_tdata,
    input                          fromMM_WR_tvalid,
    output                         fromMM_WR_tready
);

//Reg
reg  firstw , firstr , toMM_RD_tvalid, toMM_WR_tvalid, drpr, drpw;
reg [AXIS_TO_MM_WIDTH-1:0] toMM_RD_tdata, toMM_WR_tdata;
reg rd_nxt_raddr_l, rd_nxt_waddr_l;

//Wire
wire [AXI_ID_WIDTH-1:0] tmp_awid, tmp_arid;
wire [AXI_ADDR_WIDTH-1:0] tmp_awaddr, tmp_araddr, p_raddr, p_waddr;
wire [7:0] tmp_awlen, tmp_arlen;
wire [2:0] tmp_awsize, tmp_arsize, tmp_awprot, tmp_arprot;
wire [3:0] tmp_awcache, tmp_arcache;
wire [AXI_AWUSER_WIDTH-1:0] tmp_awuser;
wire [AXI_ARUSER_WIDTH-1:0] tmp_aruser;
wire [1:0] tmp_awburst, tmp_arburst;
wire       tmp_awlock , tmp_arlock, t_wdone, t_rdone, r_drop, w_drop, rd_nxt_waddr, rd_nxt_raddr;
wire       rd_rxbuf_empty, wr_rxbuf_empty, rd_drop_done, w_drop_done, rd_txn_sent, wr_txn_sent;

assign fromMM_RD_tready = 1;
assign fromMM_WR_tready = 1;

assign p_raddr = fromMM_RD_tvalid & fromMM_RD_tready & ~fromMM_RD_tdata[AXI_ADDR_WIDTH] ? fromMM_RD_tdata [AXI_ADDR_WIDTH-1:0] : 'h0;
assign p_waddr = fromMM_WR_tvalid & fromMM_WR_tready & ~fromMM_WR_tdata[AXI_ADDR_WIDTH] ? fromMM_WR_tdata [AXI_ADDR_WIDTH-1:0] : 'h0;
assign t_wdone = fromMM_WR_tvalid & fromMM_WR_tready & ~fromMM_WR_tdata[AXI_ADDR_WIDTH];
assign t_rdone = fromMM_RD_tvalid & fromMM_RD_tready & ~fromMM_RD_tdata[AXI_ADDR_WIDTH];
assign w_drop  = fromMM_WR_tvalid & fromMM_WR_tready & fromMM_WR_tdata[AXI_ADDR_WIDTH];
assign r_drop  = fromMM_RD_tvalid & fromMM_RD_tready & fromMM_RD_tdata[AXI_ADDR_WIDTH];

/* can be more efficient -- once rd and wr triggered don't do anything -- gate the clock */
always @(posedge s_axi_clk) begin
    if (~s_aresetn) begin
        toMM_RD_tvalid  <= 'b0;
        toMM_RD_tdata   <= 'b0;
        toMM_WR_tvalid  <= 'b0;
        toMM_WR_tdata   <= 'b0;
        firstr          <= 'b0;
        firstw          <= 'b0;
        drpr            <= 'b0;
        drpw            <= 'b0;
        rd_nxt_waddr_l  <= 'b0;
        rd_nxt_raddr_l  <= 'b0;
    end else begin
        if (((~firstr & ~drpr) | rd_nxt_raddr_l ) &  ~rd_rxbuf_empty) begin
            if (~firstr) begin
                firstr      <= 1;
            end
            toMM_RD_tvalid  <= 1;
            toMM_RD_tdata   <=  { 5'b0, tmp_arsize, tmp_arlen, tmp_arid, tmp_araddr };
            rd_nxt_raddr_l  <= 'b0;
        end else if (r_drop) begin
            drpr   <= 1;
        end else if (rd_drop_done) begin
            drpr   <= 0;
            if ( rd_rxbuf_empty ) begin
                firstr <= 0;
            end
        end else begin
            if (toMM_RD_tready) begin
                toMM_RD_tvalid  <= 0;
            end
        end
        if (((~firstw & ~drpw) | rd_nxt_waddr_l) & ~wr_rxbuf_empty) begin
            if (~firstw) begin
                firstw      <= 1'b1;
            end
            toMM_WR_tvalid  <= 1'b1;
            toMM_WR_tdata   <=  { 5'b0, tmp_awsize, tmp_awlen, tmp_awid, tmp_awaddr };
            rd_nxt_waddr_l  <= 'b0;
        end else if (w_drop) begin
            drpw   <= 1;
        end else if (w_drop_done) begin
            drpw   <= 0;
            if ( wr_rxbuf_empty ) begin
                firstw <= 0;
            end
        end else begin
            if (toMM_WR_tready) begin
                toMM_WR_tvalid  <= 0;
            end
        end
        if (rd_nxt_waddr)
            rd_nxt_waddr_l <= rd_nxt_waddr;
        if (rd_nxt_raddr)
            rd_nxt_raddr_l <= rd_nxt_raddr;
    end
end

assign rd_nxt_waddr = t_wdone | w_drop_done; /* for write drop => clear the write data buffer TODO :: ?? jump pointer ?? and if done then wait for all data to be sent */
assign rd_nxt_raddr = t_rdone | rd_drop_done; /* for read drops wait till read data has been completed*/

/* Write Data */
axi_addr_ch_rxs #(
    .BUF_SZ    (AW_BUF_SZ),
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
	.ID_WIDTH  (AXI_ID_WIDTH),
	.USER_WIDTH(AXI_AWUSER_WIDTH)
)
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
                           .i_buf_rd  (rd_nxt_waddr),
                           .buf_empty (wr_rxbuf_empty)
                         );

axi_addr_ch_txs #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
	.ID_WIDTH  (AXI_ID_WIDTH),
	.USER_WIDTH(AXI_AWUSER_WIDTH)
)
               AXI_WA_TX ( .tx_clk    (s_axi_clk),
                           .reset_    (s_aresetn),
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

/* Write Data */
axi_wdata_chs #(
    .BUF_SZ    (W_BUF_SZ),
    .DATA_WIDTH(AXI_DATA_WIDTH),
	.STRB_WIDTH(AXI_STRB_WIDTH),
	.USER_WIDTH(AXI_WUSER_WIDTH)
)
             AXI_WDAT_CH ( .clk        (s_axi_clk),
                           .reset_     (s_aresetn),

                           .in_wdata   (s_axi_WDATA),
                           .in_wstrb   (s_axi_WSTRB),
                           .in_wlast   (s_axi_WLAST),
                           .in_wuser   (s_axi_WUSER),
                           .in_swvalid (s_axi_WVALID),
                           .out_swready(s_axi_WREADY),

                           .out_wdata  (m_axi_WDATA),
                           .out_wstrb  (m_axi_WSTRB),
                           .out_wlast  (m_axi_WLAST),
                           .out_wuser  (m_axi_WUSER),
                           .out_mwvalid(m_axi_WVALID),
                           .in_mwready (m_axi_WREADY),

                           .done       (t_wdone),
                           .drop       (w_drop),
                           .drop_done  (w_drop_done)
                         );

/* Write response channel */
axi_bresp_chs #(
    .BUF_SZ    (B_BUF_SZ),
    .ID_WIDTH  (AXI_ID_WIDTH),
	.USER_WIDTH(AXI_BUSER_WIDTH)
)
             AXI_B_CH ( .clk        (s_axi_clk),
                        .reset_     (s_aresetn),

                        .in_mbid    (m_axi_BID),
                        .in_mbresp  (m_axi_BRESP),
                        .in_mbuser  (m_axi_BUSER),
                        .in_mbvalid (m_axi_BVALID),
                        .out_mbready(m_axi_BREADY),

                        .out_sbid   (s_axi_BID),
                        .out_sbresp (s_axi_BRESP),
                        .out_sbuser (s_axi_BUSER),
                        .out_sbvalid(s_axi_BVALID),
                        .in_sbready (s_axi_BREADY),

                        .in_awid    (tmp_awid),
                        .in_awuser  (tmp_awuser),
                        .drop       (w_drop)
                      );

/* Read Address */
axi_addr_ch_rxs #(
    .BUF_SZ    (AR_BUF_SZ),
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
	.ID_WIDTH  (AXI_ID_WIDTH),
	.USER_WIDTH(AXI_ARUSER_WIDTH)
)
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
                           .i_buf_rd  (rd_nxt_raddr),
                           .buf_empty (rd_rxbuf_empty)
                         );

axi_addr_ch_txs #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
	.ID_WIDTH  (AXI_ID_WIDTH),
	.USER_WIDTH(AXI_ARUSER_WIDTH)
)
               AXI_RA_TX ( .tx_clk    (s_axi_clk),
                           .reset_    (s_aresetn),
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

/* Read Data channel */
axi_rdata_chs #(
    .BUF_SZ  (R_BUF_SZ),
    .DATA_WID(AXI_DATA_WIDTH),
	.ID_WID  (AXI_ID_WIDTH),
	.USER_WID(AXI_RUSER_WIDTH)
)
             AXI_RDAT_CH ( .clk        (s_axi_clk),
                           .reset_     (s_aresetn),

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
                           .in_srready (s_axi_RREADY),

                           .in_arid    (tmp_arid),
                           .in_aruser  (tmp_aruser),
                           .in_arsize  (tmp_arsize),
                           .in_arlen   (tmp_arlen),
                           .drop       (r_drop),
                           .drop_done  (rd_drop_done)
                         );

endmodule

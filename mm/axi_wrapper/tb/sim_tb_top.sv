`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2019 05:52:01 PM
// Design Name: 
// Module Name: sim_tb_top
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


module sim_tb_top();

reg axiClk, reset_;
reg  [7:0] waid, raid, wid, rid, bid, tmp_id, tmp_id1;
reg [31:0] raddr, waddr, data, rd_count, wr_count, prev_rd_count;
reg  [7:0] wlen, rlen, tmplen;
reg  [2:0] rdusr, wrusr, arusr, awusr, buser, tmp_usr, tmpusr;
reg  m_wav, m_rav, m_wv, s_war, s_rar, s_wr, wlst, def_sr, writing , rlst, m_bvld, m_rvld;
wire m_war, m_rar, m_wr, s_wav, s_rav, s_wv, s_wlast, s_rlock, s_wlock, m_brdy, s_bvld, m_rrdy, s_rvld, s_rlst;
wire  [3:0] s_waid , s_raid  , s_wid, s_bid, s_rid, s_wstrb;
wire [31:0] s_waddr, s_raddr, s_wdata, s_rdata;
wire  [7:0] s_wlen , s_rlen;
wire  [2:0] s_wsz  , s_rsz, s_wprot , s_rprot;
wire  [3:0] s_wcache, s_rcache;
wire  [1:0] s_wusr , s_rusr, s_wdusr, s_wbrst, s_rbrst, s_brsp, s_busr, s_rrsp, s_rdusr;
integer i;

wire [31:0] v_raddr, v_waddr, p_raddr, p_waddr;
wire  [7:0] v_rlen , v_wlen;
wire  [2:0] v_rsz  , v_wsz;
wire        t_rdone, t_wdone, start_rd, start_wr;

reg [31:0] rdata;
reg  [1:0] bresp, rresp;
reg  [3:0] wstrb; 

assign s_wr = 1'b1;
assign s_rar = 1'b1;

// initialize everything and de-assert reset 
initial begin
    $dumpvars;
    #5;
    reset_ = 1'b0;
    axiClk   = 1'b0;
    axiClk   = 1'b0;
    writing  = 0;
    #5;
    waid   = 4'h0; raid  = 4'h0; wid = 4'h0;
    wstrb  = 4'hF; rid   = 'h0 ; bid = 'h0;
    rlen   = 'h0;  buser = 'h0 ; m_bvld = 'b0;
    m_rvld = 'b0;  rdata = 'h0 ;
    raddr  = {32{1'b0}};
    waddr  = {32{1'b0}};
    data   = {32{1'b0}};
    wlen   = 0;
    wlst   = 0; rlst = 0;
    rdusr  = 'b0; wrusr = 'b0;
    m_wav  = 1'b0; m_rav = 1'b0; m_wv = 1'b0;
    prev_rd_count = 'h0; rd_count = 'h0; wr_count = 'h0;
    repeat(5) @(posedge axiClk);
    reset_ = 1'b1;
end

// Simple clock generation
always 
    #10 axiClk = ~axiClk;

initial begin
    wait(reset_ === 1'b1);
    @(posedge axiClk);
    fork
        drive_master_signals(); // active stimulus
        drive_read_resp(); // active stimulus
    join_none
    repeat(2000) @(posedge axiClk);
    wait((rd_count + wr_count) == 50);
    wait(prev_rd_count == rd_count);
end

task drive_master_signals();
    repeat(50) begin
        i = $urandom_range(0,1);
        repeat($urandom_range(1, 25)) @(posedge axiClk);
        // keep everything after the clock
        if (i == 0) begin
            waddr = $urandom_range(32'h0000_0100, 32'h10FF_0000);
            waid  = $urandom_range(0,15);
            wlen  = $urandom_range(1,32);
            m_wav = 1'b1;
            wait(m_war == 1);
            @(posedge axiClk);
            m_wav = 1'b0;
            wid   = waid;
            m_wv  = 1'b1;
            for (integer j=0; j<wlen ; j=j+1) begin
                if ( j == 0) begin
                    wait (m_wr == 1); 
                end
                if (j == wlen-1) begin
                    wlst = 1'b1;
                end
                data = (j % 2) ? 32'hdead_beef : 32'hdead_dead;
                @(posedge axiClk);
            end
            m_wv = 1'b0;
            wlst = 1'b0;
            data = 32'h0;
            wr_count = wr_count+1;
        end else begin
            m_rav = 1'b1;
            raddr = $urandom_range(32'h0000_0100, 32'h10FF_0000);
            raid  = $urandom_range(1,15);
            rlen  = $urandom_range(1,32);
            wait(m_rar == 1);
            @(posedge axiClk);
            m_rav = 1'b0;
            rd_count = rd_count+1;
        end
        repeat($urandom_range(1,6)) @(posedge axiClk);
    end
endtask

axi_mmu_wrapper_sync #(.AXI_ID_WIDTH(4), .AXI_AWUSER_WIDTH(2), .AXI_ARUSER_WIDTH(2), .AXI_RUSER_WIDTH(2), .AXI_WUSER_WIDTH(2), .AXI_BUSER_WIDTH(2)) DUT(
    .s_axi_clk(axiClk),
    .s_aresetn(reset_),
    .s_axi_AWID   (waid),
    .s_axi_AWADDR (waddr),
    .s_axi_AWLEN  (wlen),
    .s_axi_AWSIZE ('h1),
    .s_axi_AWBURST('h0),
    .s_axi_AWPROT ('h1),
    .s_axi_AWUSER ('h0),
    .s_axi_AWCACHE('h0),
    .s_axi_AWLOCK ('h0),
    .s_axi_AWVALID(m_wav),
    .s_axi_AWREADY(m_war),
    .m_axi_AWID   (s_waid),
    .m_axi_AWADDR (s_waddr),
    .m_axi_AWLEN  (s_wlen),
    .m_axi_AWSIZE (s_wsz),
    .m_axi_AWBURST(s_wbrst),
    .m_axi_AWPROT (s_wprot),
    .m_axi_AWUSER (s_wusr),
    .m_axi_AWCACHE(s_wcache),
    .m_axi_AWLOCK (s_wlock),
    .m_axi_AWVALID(s_wav), 
    .m_axi_AWREADY(1'b1),
    .s_axi_ARID   (raid),
    .s_axi_ARADDR (raddr),
    .s_axi_ARLEN  (rlen),
    .s_axi_ARSIZE ('h1),
    .s_axi_ARBURST('h0),
    .s_axi_ARPROT ('h1),
    .s_axi_ARUSER ('h0),
    .s_axi_ARCACHE('h0),
    .s_axi_ARLOCK ('h0),
    .s_axi_ARVALID(m_rav),
    .s_axi_ARREADY(m_rar),
    .m_axi_ARID   (s_raid),
    .m_axi_ARADDR (s_raddr),
    .m_axi_ARLEN  (s_rlen),
    .m_axi_ARSIZE (s_rsz),
    .m_axi_ARBURST(s_rbrst),
    .m_axi_ARPROT (s_rprot),
    .m_axi_ARUSER (s_rusr),
    .m_axi_ARCACHE(s_rcache),
    .m_axi_ARLOCK (s_rlock),
    .m_axi_ARVALID(s_rav), 
    .m_axi_ARREADY(1'b1),
    .s_axi_WDATA  (data),
    .s_axi_WSTRB  (wstrb),
    .s_axi_WLAST  (wlst),
    .s_axi_WUSER  ('h0),
    .s_axi_WVALID (m_wv),
    .s_axi_WREADY (m_wr),
    .m_axi_WDATA  (s_wdata),
    .m_axi_WSTRB  (s_wstrb),
    .m_axi_WLAST  (s_wlast),
    .m_axi_WUSER  (s_wdusr),
    .m_axi_WVALID (s_wv),
    .m_axi_WREADY (1'b1),
    .m_axi_BID    (bid),
    .m_axi_BRESP  (bresp),
    .m_axi_BUSER  (buser),
    .m_axi_BVALID (m_bvld),
    .m_axi_BREADY (m_brdy),
    .s_axi_BID    (s_bid),
    .s_axi_BRESP  (s_brsp),
    .s_axi_BUSER  (s_busr),
    .s_axi_BVALID (s_bvld),
    .s_axi_BREADY (1'b1),
    .m_axi_RID    (rid),
    .m_axi_RDATA  (rdata),
    .m_axi_RRESP  (rresp),
    .m_axi_RUSER  (rdusr),
    .m_axi_RLAST  (rlst),
    .m_axi_RVALID (m_rvld),
    .m_axi_RREADY (m_rrdy),
    .s_axi_RID    (s_rid),
    .s_axi_RDATA  (s_rdata),
    .s_axi_RRESP  (s_rrsp),
    .s_axi_RUSER  (s_rdusr),
    .s_axi_RLAST  (s_rlst),
    .s_axi_RVALID (s_rvld),
    .s_axi_RREADY (1'b1),
    .virt_rd_addr (v_raddr),
    .virt_rd_size (v_rsz),
    .virt_rd_len  (v_rlen),
    .virt_wr_addr (v_waddr),
    .virt_wr_size (v_wsz),
    .virt_wr_len  (v_wlen),
    .phys_rd_addr (p_raddr),
    .phys_wr_addr (p_waddr),
    .rd_trans_done(t_rdone),
    .wr_trans_done(t_wdone),
    .rd_drop      (rdrop),
    .wr_drop      (wdrop),
    .start_rd_translation(start_rd),
    .start_wr_translation(start_wr)
);

translation_simple TR0 ( .clk       (axiClk),
                         .reset_    (reset_),
                         .v_raddr   (v_raddr),
                         .v_waddr   (v_waddr),
                         .r_size    (v_rsz),
                         .r_len     (v_rlen),
                         .w_size    (v_wsz),
                         .w_len     (v_wlen),
                         .p_raddr   (p_raddr),
                         .p_waddr   (p_waddr),
                         .t_rdone   (t_rdone),
                         .t_wdone   (t_wdone),
                         .r_drop    (rdrop),
                         .w_drop    (wdrop),
                         .rstart    (start_rd),
                         .wstart    (start_wr)
                       );

/* Write Response generation */
always @(s_wv or s_wr or s_wlast) begin
    if (reset_) begin
        if (s_wv & s_wr & s_wlast) begin
            tmp_id  = s_waid;
            tmp_usr = s_wdusr;
            @(posedge axiClk);
            m_bvld = 1'b1;
            bresp  = $urandom_range(0, $urandom_range(0,3));
            bid    = tmp_id;
            buser  = tmp_usr;
        end else begin
            @(posedge axiClk);
            wait (m_brdy == 1);
            m_bvld = 1'b0;
        end
    end
end

task drive_read_resp();
    wait(prev_rd_count != rd_count);
    while (prev_rd_count != rd_count) begin
        repeat($urandom_range(40, 48)) @(posedge axiClk); 
        tmplen  = $urandom_range(1, 32);   
        repeat($urandom_range(3, 6)) @(posedge axiClk);
        m_rvld = 1'b1;
        rresp  = $urandom_range(0, $urandom_range(0,3));
        rid    = $urandom_range(0,1);
        rdusr  = $urandom_range(0,2);
        for (integer j = 0; j < tmplen; j++) begin
            if (j == 0) begin
                wait(m_rrdy == 1);
            end
            if (j == tmplen - 1) begin
                rlst = 1;
            end
            rdata = j%2 ? 32'hdead_beef : 32'hdead_dead;
            @(posedge axiClk);
        end
        rlst = 0;
        m_rvld    = 1'b0;
        @(posedge axiClk);
        prev_rd_count += 1;
        if ((prev_rd_count == rd_count) && ((rd_count + wr_count) != 50)) begin
            wait(s_rar == 1);
        end
    end
endtask 

endmodule

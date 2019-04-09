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
integer i, fwi, frai, frdi, fbi, fwdi, fwo, frao, frdo, fbo, fwdo;

wire [42:0] vrd_data, vwr_data;
wire [32:0] prd_data, pwr_data;
wire        vrd_valid, vrd_ready, vwr_valid, vwr_ready;
wire        prd_valid, prd_ready, pwr_valid, pwr_ready;

reg [31:0] rdata;
reg  [1:0] bresp, rresp;
reg  [3:0] wstrb;
reg [6:0] count;

// initialize everything and de-assert reset 
initial begin
    $dumpvars;
    fwi  = $fopen("infile1.txt", "w+");
    frai = $fopen("infile2.txt", "w+");
    frdi = $fopen("infile3.txt", "w+");
    fbi  = $fopen("infile4.txt", "w+");
    fwdi = $fopen("infile5.txt", "w+");
    fwo  = $fopen("outfile1.txt", "w+");
    frao = $fopen("outfile2.txt", "w+");
    frdo = $fopen("outfile3.txt", "w+");
    fbo  = $fopen("outfile4.txt", "w+");
    fwdo = $fopen("outfile5.txt", "w+");
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
    s_war = 1'b1;
    s_rar = 1'b1;
    s_wr  = 1'b1;
    prev_rd_count = 'h0; rd_count = 'h0; wr_count = 'h0;
    repeat(5) @(posedge axiClk);
    reset_ = 1'b1;

    wait (prev_rd_count + wr_count == 100);
    repeat(100) @(posedge axiClk);
    $fclose(fwi  );
    $fclose(frai );
    $fclose(frdi );
    $fclose(fbi  );
    $fclose(fwdi );
    $fclose(fwo  );
    $fclose(frao );
    $fclose(frdo );
    $fclose(fbo  );
    $fclose(fwdo );
    #100ps
    $finish();
end

`ifndef PERF
always @(posedge axiClk) begin
    if (~reset_) begin
        count <= 0;
    end else begin
        if (count[6]) begin
            if (count[5]) begin
                s_war <= 0;
                s_rar <= 0;
                if (count[4]) begin
                    s_wr  <= 0;
                end
            end
        end else begin
            s_war <= 1;
            s_rar <= 1;
            s_wr  <= 1;
        end
        count <= count + 1;
    end
end
`endif

always @(posedge axiClk) begin
    if (~reset_) begin
    end else begin
        if (s_wav & s_war) begin
            $fdisplay(fwo, "Addr : %h, ID : %h, Len : %h", s_waddr, s_waid, s_wlen); 
        end
        if (s_rav & s_rar) begin
            $fdisplay(frao, "Addr : %h, ID : %h, Len : %h", s_raddr, s_raid, s_rlen); 
        end
        if (s_wv & s_wr) begin
            $fdisplay(fwdo, "Data : %h, Last : %h", s_wdata, s_wlast); 
        end
        if (s_rvld) begin
            $fdisplay(frdo, "Data : %h, Resp : %h, Last : %h", s_rdata, s_rrsp, s_rlst); 
        end
        if (s_bvld) begin
            $fdisplay(fbo, "ID : %h, Resp : %h", s_bid, s_brsp); 
        end
    end
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
    wait(prev_rd_count == rd_count);
end

task drive_master_signals();
    repeat(100) begin
        i = $urandom_range(0,1);
`ifdef PERF
        @(posedge axiClk);
`else
        repeat($urandom_range(1, 25)) @(posedge axiClk);
`endif
        // keep everything after the clock
        if (i == 0) begin
            waddr = $urandom_range(32'h0000_0100, 32'h10FF_0000);
            waid  = $urandom_range(0,15);
            wlen  = $urandom_range(1,32);
            m_wav = 1'b1;
            $fdisplay(fwi, "Addr : %h, ID : %h, Len : %h", waddr, waid, wlen); 
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
                $fdisplay(fwdi, "Data : %h, Last : %h", data, wlst); 
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
            $fdisplay(frai, "Addr : %h, ID : %h, Len : %h", raddr, raid, rlen); 
            wait(m_rar == 1);
            @(posedge axiClk);
            m_rav = 1'b0;
            rd_count = rd_count+1;
        end
`ifndef PERF
        repeat($urandom_range(1,6)) @(posedge axiClk);
`endif
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
    .m_axi_AWREADY(s_war),
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
    .m_axi_ARREADY(s_rar),
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
    .m_axi_WREADY (s_wr),
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
    .toMM_RD_tdata   (vrd_data ),
    .toMM_RD_tvalid  (vrd_valid),
    .toMM_RD_tready  (vrd_ready),
    .toMM_WR_tdata   (vwr_data ),
    .toMM_WR_tvalid  (vwr_valid),
    .toMM_WR_tready  (vwr_ready),
    .fromMM_RD_tdata (prd_data ),
    .fromMM_RD_tvalid(prd_valid),
    .fromMM_RD_tready(prd_ready),
    .fromMM_WR_tdata (pwr_data ),
    .fromMM_WR_tvalid(pwr_valid),
    .fromMM_WR_tready(pwr_ready)
);

translation_simple TR0 ( .clk       (axiClk),
                         .reset_    (reset_),
                         .axis_ird_tdata  (vrd_data ),
                         .axis_ird_tvalid (vrd_valid),
                         .axis_ird_tready (vrd_ready),
                         .axis_iwr_tdata  (vwr_data ),
                         .axis_iwr_tvalid (vwr_valid),
                         .axis_iwr_tready (vwr_ready),

                         .axis_ord_tdata  (prd_data ),
                         .axis_ord_tvalid (prd_valid),
                         .axis_ord_tready (prd_ready),
                         .axis_owr_tdata  (pwr_data ),
                         .axis_owr_tvalid (pwr_valid),
                         .axis_owr_tready (pwr_ready)
                       );

/* Write Response generation */
always @(s_wv or s_wr or s_wlast) begin
    if (reset_) begin
        if (s_wv & s_wr & s_wlast) begin
            tmp_id  = s_waid;
            tmp_usr = s_wdusr;
            @(posedge axiClk);
            m_bvld = 1'b1;
            bresp  = $urandom_range(0, $urandom_range(0,2));
            bid    = tmp_id;
            buser  = tmp_usr;
            $fdisplay(fbi, "ID : %h, Resp : %h", bid, bresp);             
        end else begin
            @(posedge axiClk);
            wait (m_brdy == 1);
            m_bvld = 1'b0;
        end
    end
end

task drive_read_resp();
    while (1) begin
        if (prev_rd_count != rd_count) begin
            repeat($urandom_range(40, 48)) @(posedge axiClk); 
            tmplen  = $urandom_range(1, 32);   
            repeat($urandom_range(3, 6)) @(posedge axiClk);
            m_rvld = 1'b1;
            rresp  = $urandom_range(0, $urandom_range(0,2));
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
                $fdisplay(frdi, "Data : %h, Resp : %h, Last : %h", rdata, rresp, rlst); 
                @(posedge axiClk);
            end
            rlst = 0;
            m_rvld    = 1'b0;
            @(posedge axiClk);
            prev_rd_count += 1;
            if ((prev_rd_count == rd_count) && ((rd_count + wr_count) != 50)) begin
                wait(s_rar == 1);
            end
        end else begin
`ifndef PERF
            repeat(10) @(posedge axiClk);
`else
            @(posedge axiClk);
`endif
        end
    end
endtask 

endmodule

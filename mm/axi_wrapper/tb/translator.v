/*------------------------------------------------------------------------------
 * Title      : AXI based MMU IP
 * Project    : LegoFPGA 
 *------------------------------------------------------------------------------
 * File       : translator.v 
 * -----------------------------------------------------------------------------
 * Description: A simple translator model which looks up a default value table (currently 0)
 * ------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module translation_simple (
    input         clk,
    input         reset_, 
    
    input  [42:0] axis_ird_tdata,
    input         axis_ird_tvalid,
    output        axis_ird_tready,
    input  [42:0] axis_iwr_tdata,
    input         axis_iwr_tvalid,
    output        axis_iwr_tready,

    output [32:0] axis_ord_tdata,
    output        axis_ord_tvalid,
    input         axis_ord_tready,
    output [32:0] axis_owr_tdata,
    output        axis_owr_tvalid,
    input         axis_owr_tready
);

reg [31:0] roffset , woffset, rcount, wcount;
reg [31:0] tmp_waddr, tmp_raddr;
wire [31:0] v_raddr, v_waddr;
wire [31:0] rstart, wstart;
reg rdone, wdone, rvalid, wvalid;
reg [31:0] segTable [0:31];
integer i;
reg [5:0] count;

reg iwr_ready, ird_ready;

always @(posedge clk) begin
    if (~reset_) begin
        count <= 0;
        iwr_ready <= 1;
        ird_ready <= 1;
    end else begin
        if ( count[5] ) begin
            if (count[4]) begin
                ird_ready <= 0;
                if (count[3]) begin
                    iwr_ready <= 0;
                end
            end
        end else begin
            iwr_ready <= 1;
            ird_ready <= 1;
        end
        count <= count + 1;
    end
end

assign axis_iwr_tready = iwr_ready;
assign axis_ird_tready = ird_ready;

assign axis_ord_tdata = {rdone, tmp_raddr};
assign axis_owr_tdata = {wdone, tmp_waddr};
assign axis_ord_tvalid = rvalid;
assign axis_owr_tvalid = wvalid;

assign v_raddr = axis_ird_tvalid & axis_ird_tready ? axis_ird_tdata[31:0] : 'h0;
assign v_waddr = axis_iwr_tvalid & axis_iwr_tready ? axis_iwr_tdata[31:0] : 'h0;
assign rstart = axis_ird_tvalid & axis_ird_tready;
assign wstart = axis_iwr_tvalid & axis_iwr_tready;

/* read address translation */
always @(posedge clk) begin
    if(~reset_) begin
        tmp_raddr <= 'b0;
        roffset   <= 'b0;
        rdone     <= 'b0;
        rvalid    <= 'b0;
        for ( i = 0; i < 32; i = i + 1) begin
            segTable[i] <= i * 32'h1000;
        end
    end else begin
        roffset   <= rcount;
        if (roffset != rcount) begin
            if ( rcount + wcount != 31 && rcount + wcount != 40 ) begin
                rdone <= 1'b1;
            end
            tmp_raddr <= v_raddr[31:0] + segTable[v_raddr[31:27]];
            rvalid    <= 1'b1;
        end else begin
            if ( axis_ord_tready ) begin
                rvalid    <= 'b0;
                rdone     <= 'b0;
                tmp_raddr <= 'b0;
            end
        end
    end
end

/* write address translation */
always @(posedge clk) begin
    if(~reset_) begin
        tmp_waddr <= 'b0;
        woffset   <= 'b0;
        wdone     <= 'b0;
        wvalid    <= 'b0;
    end else begin
        woffset   <= wcount;
        if (woffset != wcount) begin
            if ( rcount + wcount != 32 && rcount + wcount != 40 ) begin
                wdone <= 1'b1;
            end
            wvalid    <= 1'b1;
            tmp_waddr <= v_waddr[31:0] + segTable[v_waddr[31:27]];
        end else begin
            if (axis_owr_tready) begin
                wvalid    <= 'b0;
                wdone     <= 'b0;
                tmp_waddr <= 'b0;
            end
        end
    end
end

/* Logic for done pulse */
always @(posedge rstart or negedge reset_) begin
    if (~reset_) begin
        rcount = 'h0;
    end else begin
        rcount = rcount + 1;
    end
end

always @(posedge wstart or negedge reset_) begin
    if (~reset_) begin
        wcount = 0;
    end else begin
        wcount = wcount + 1;
    end
end

endmodule

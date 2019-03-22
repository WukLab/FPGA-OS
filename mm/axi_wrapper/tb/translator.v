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
    input  [31:0] v_raddr,
    input  [31:0] v_waddr,
    input   [2:0] r_size,
    input   [7:0] r_len,
    input   [2:0] w_size,
    input   [7:0] w_len,
    input         rstart,
    input         wstart,
    output [31:0] p_raddr,
    output [31:0] p_waddr,
    output        t_rdone,
    output        t_wdone,
    output        r_drop,
    output        w_drop
);

reg [31:0] roffset , woffset, rcount, wcount;
reg [31:0] tmp_waddr, tmp_raddr;
reg rdone, wdone, rdrop, wdrop;
reg [31:0] segTable [0:31];
integer i;

assign p_raddr = tmp_raddr;
assign p_waddr = tmp_waddr;
assign t_rdone = rdone;
assign t_wdone = wdone;
assign r_drop  = rdrop;
assign w_drop  = wdrop;

/* read address translation */
always @(posedge clk) begin
    if(~reset_) begin
        tmp_raddr <= 'h0;
        roffset   <= 'h0;
        rdone     <= 'b0;
        rdrop     <= 'b0;
        for ( i = 0; i < 32; i = i + 1) begin
            segTable[i] <= i * 32'h1000;
        end
    end else begin
        tmp_raddr <= v_raddr[31:0] + segTable[v_raddr[31:27]];
        roffset   <= rcount;
        if (roffset != rcount) begin
            if ( rcount + wcount == 31 ) begin
                rdrop <= 1'b1;
            end else begin
                rdone <= 1'b1;
            end
        end else begin
            rdone <= 1'b0;
            rdrop <= 1'b0;
        end
    end
end

/* write address translation */
always @(posedge clk) begin
    if(~reset_) begin
        tmp_waddr <= 'h0;
        woffset   <= 'h0;
        wdone     <= 'b0;
        wdrop     <= 'b0;
    end else begin
        tmp_waddr <= v_waddr[31:0] + segTable[v_waddr[31:27]];
        woffset   <= wcount;
        if (woffset != wcount) begin
            if ( rcount + wcount == 32 ) begin
                wdrop <= 1'b1;
            end else begin
                wdone <= 1'b1;
            end
        end else begin
            wdone <= 1'b0;
            wdrop <= 1'b0;
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

/*------------------------------------------------------------------------------
 * Title      : AXI based MMU IP
 * Project    : LegoFPGA 
 *------------------------------------------------------------------------------
 * File       : translator.v 
 * -----------------------------------------------------------------------------
 * Description: A simple translator model with variable delays
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
    output [31:0] p_raddr,
    output [31:0] p_waddr,
    output        t_rdone,
    output        t_wdone
/* Bus/simple wire connection to cache or LUT */

/*AXI to memory controller (analogous to lower level of memory) */
);

reg rdone, wdone;
wire r_timer_done, w_timer_done;
reg [31:0] roffset = 32'h1000, woffset = 32'h1100;
reg [31:0] tmp_waddr, tmp_raddr;
reg rstart = 0, wstart = 0;
reg rstart_d, wstart_d;

assign p_raddr = tmp_raddr;
assign p_waddr = tmp_waddr;
assign t_rdone = rdone;
assign t_wdone = wdone;

always @(posedge clk) begin
    if(~reset_) begin
        tmp_raddr <= 'h0;
        rdone     <= 1'b0;
    end else begin
        if (r_timer_done) begin
            tmp_raddr <= v_raddr + roffset;
            rdone     <= 1'b1;
        end else begin
            rdone     <= 1'b0;
        end
    end
end

always @(posedge clk) begin
    if(~reset_) begin
        tmp_waddr <= 'h0;
        wdone     <= 1'b0;
    end else begin
        if (w_timer_done) begin
            tmp_waddr <= v_waddr + woffset;
            wdone     <= 1'b1;
        end else begin
            wdone     <= 1'b0;
        end
    end
end

/*Sample timer non-synthesizable -- part of testbench to say*/
always @(v_raddr or rstart_d) begin
    if (~rstart & ~rstart_d) begin
        rstart = 1'b1;
    end else if (rstart & ~rstart_d) begin
        rstart = 1'b0;
    end
end

always @ (v_waddr or wstart_d) begin
    if (~wstart & ~wstart_d) begin
        wstart = 1'b1;
    end else if (wstart & ~wstart_d) begin
        wstart = 1'b0;
    end
end

always @(posedge clk) begin
    if (rstart & ~rstart_d) begin
        rstart_d <= 1'b1;
    end else begin
        rstart_d <= 1'b0;
    end
    if (wstart & ~wstart_d) begin
        wstart_d <= 1'b1;
    end else begin
        wstart_d <= 1'b0;
    end
end

timer WR_TIMER (.clk(clk), .reset_(reset_), .start(wstart_d), .done(w_timer_done)); 
timer RD_TIMER (.clk(clk), .reset_(reset_), .start(rstart_d), .done(r_timer_done)); 

endmodule


module timer (
    input  clk,
    input  reset_,
    input  start,
    output done
  );

reg [9:0] limit, timer;
reg tick;

assign done = (timer == limit);

always @(posedge clk) begin
    if ( !reset_ ) begin
        timer <= 10'h0;
        limit <= 10'h28; // 40 clocks
    end else begin
        if (tick & ~done) begin
            timer    <= timer + 10'b1;
        end else begin
            timer    <= 10'b0;
        end 
    end
end 

always @(posedge clk) begin
    if (~reset_) begin
        tick <= 1'b0;
    end else begin
        if ( start ) begin
            tick <= 1'b1;
        end else if (done) begin
            tick <= 1'b0;
        end
    end
end

endmodule

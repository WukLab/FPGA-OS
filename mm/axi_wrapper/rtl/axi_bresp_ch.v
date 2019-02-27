/* ------------------------------------------------------------------------------
 * Title      : AXI based MMU IP
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : axi_bresp_ch 
 * -----------------------------------------------------------------------------
 * Description: This is the write response channel which will propagate the
 *              responses from memory side towards actual master.
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps

module axi_bresp_ch #(
    parameter BUF_SZ = 64
)
(
/* memory from actual slave */
    input             rxclk,
    input             rxreset_,
/* Apps/towards actual master */
    input             txclk,
    input             txreset_,

    input       [3:0] in_mbid,
    input       [1:0] in_mbresp,
    input       [1:0] in_mbuser,
    input             in_mbvalid,
    output            out_mbready,
    
    output reg  [3:0] out_sbid,
    output reg  [1:0] out_sbresp,
    output reg  [1:0] out_sbuser,
    output reg        out_sbvalid,
    input             in_sbready
);

reg  rd_en;
reg [1:0] state, state_n;
reg [2:0] count, countn;
wire wr_en, b_empty, b_full, b_a_empty, b_a_full;
wire [7:0] data_in, data_out;

assign out_mbready = ~b_full & ~b_a_full;
assign wr_en = in_mbvalid & out_mbready;

assign data_in[3:0] = in_mbid;
assign data_in[5:4] = in_mbuser;
assign data_in[7:6] = in_mbresp;

always @(posedge txclk) begin
    if(~txreset_) begin
        {out_sbid, out_sbuser, out_sbresp} <= 'h0;
        out_sbvalid <= 1'b0;
    end else begin
        if (rd_en) begin
            out_sbid    <= data_out[3:0]; 
            out_sbuser  <= data_out[5:4];
            out_sbresp  <= data_out[7:6];
            out_sbvalid <= 1'b1; 
        end else if (in_sbready & out_sbvalid) begin
            out_sbvalid <= 1'b0;
        end
    end
end

always @(posedge txclk) begin
    if (~txreset_) begin
        state <= 2'b0;
        count <= 3'b0; 
    end else begin
        state <= state_n;
        count <= countn;
    end
end

always @(state or b_empty or count) begin
    state_n = state;
    rd_en   = 0;
    case (state)
        0 : begin
                if (~b_empty) begin 
                    state_n = 1;
                end
                countn = 0;
            end
        1 : begin
                rd_en = 1;
                state_n = 2;
            end
        2 : begin
                if (count == 3 | b_empty) begin
                    state_n = 0;
                end
                countn = countn+1;
            end
    endcase
end

/* instantiating the FIFO for the read data worst case when the original requester is not ready to accept the read data*/
async_fifo #(.DW(8), .FIFO_DEPTH(BUF_SZ))  RDATA_BUF( .srcclk    (rxclk),
                                                      .dstclk    (txclk),
                                                      .srcrst_   (rxreset_),
                                                      .dstrst_   (txreset_),
                                                      .wr_en     (wr_en),
                                                      .rd_en     (rd_en),
                                                      .data_in   (data_in),
                                                      .data_out  (data_out),
                                                      .full      (b_full),
                                                      .empty     (b_empty),
                                                      .almost_full (b_a_full),
                                                      .almost_empty(b_a_empty)
                                                    );

endmodule

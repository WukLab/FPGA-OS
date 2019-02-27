/* ------------------------------------------------------------------------------
 * Title      : AXI based MMU IP 
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : axi_rdata_ch
 * -----------------------------------------------------------------------------
 * Description: This is the read data channel that sends the read data back to
 *              the original requester. Just a fifo to read till last whenever
 *              not empty. Burst and other consideration to follow.
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps

// TODO :: Make it parameterized across DATA/USER
module axi_rdata_ch #(
    parameter BUF_SZ = 256
)
(
/*rx here is the mem side*/
    input             rxclk,
    input             rxreset_,
/*tx is the app/intrcnnct side*/
    input             txclk,
    input             txreset_,
/*input from mem/system side */
    input       [3:0] in_rid,
    input      [31:0] in_rdata,
    input       [1:0] in_rresp,
    input       [1:0] in_ruser,
    input             in_rlast,
    input             in_mrvalid,
    output            out_mrready, /*ready back to the MC*/
/*output to the AXI app/interconnect side */
    output reg  [3:0] out_rid,
    output reg [31:0] out_rdata,
    output reg  [1:0] out_rresp,
    output reg  [1:0] out_ruser,
    output reg        out_rlast,
    output reg        out_srvalid,
    input             in_srready /*ready from App/Interconnect*/
);

reg       rd_en, last; 
reg [1:0] state, state_n;
reg [2:0] count, countn;
wire [40:0] data_in, data_out;
wire        wr_en, r_empty, r_full, r_a_full, r_a_empty;

assign data_in[3:0]   = in_rid;
assign data_in[35:4]  = in_rdata;
assign data_in[37:36] = in_rresp;
assign data_in[39:38] = in_ruser;
assign data_in[40:40] = in_rlast;

assign out_mrready = ~r_full & ~r_a_full;
assign wr_en       = in_mrvalid & out_mrready;

always @(posedge txclk) begin
    if (~txreset_) begin
        out_rid     <= 4'b0;
        out_rdata   <= 32'b0;
        out_rresp   <= 2'b0;
        out_rlast   <= 1'b0;
        out_ruser   <= 2'b0;
        out_srvalid <= 1'b0;
    end else begin
        if (rd_en) begin
            out_rid     <= data_out[3:0]  ;
            out_rdata   <= data_out[35:4] ;
            out_rresp   <= data_out[37:36];
            out_ruser   <= data_out[39:38];
            out_rlast   <= data_out[40:40];
            out_srvalid <= rd_en;
        end
        else if (in_srready & out_srvalid ) begin
            out_srvalid <= 1'b0;
            out_rlast   <= 1'b0;
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

//TODO :: Add burst considerations as well
always @(state or r_empty or count or data_out) begin
    state_n = state;
    rd_en   = 0;
    case (state)
        0 : begin
                if (~r_empty) begin 
                    state_n = 1;
                end
                countn = 0;
            end
        1 : begin
                rd_en = 1;
                if (data_out[40:40] | r_a_empty) begin
                    state_n = 2;
                    last    = data_out[40:40];
                end
            end
        2 : begin
                if (last & r_a_empty & ~r_empty) begin
                    state_n = 2;
                end else if (count == 5 | r_empty) begin
                    state_n = 0;
                    countn = countn+1;
                end
            end
    endcase
end

/* instantiating the FIFO for the read data worst case when the original requester is not ready to accept the read data*/
async_fifo #(.DW(41), .FIFO_DEPTH(BUF_SZ))  RDATA_BUF( .srcclk    (rxclk),
                                                    .dstclk    (txclk),
                                                    .srcrst_   (rxreset_),
                                                    .dstrst_   (txreset_),
                                                    .wr_en     (wr_en),
                                                    .rd_en     (rd_en),
                                                    .data_in   (data_in),
                                                    .data_out  (data_out),
                                                    .full      (r_full),
                                                    .empty     (r_empty),
                                                    .almost_full (r_a_full),
                                                    .almost_empty(r_a_empty)
                                                  );

endmodule

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

module axi_bresp_chs #(
    parameter BUF_SZ     = 64,
    parameter ID_WIDTH   = 8,
    parameter USER_WIDTH = 2
)
(
    input             clk,
    input             reset_,

    input   [ID_WIDTH-1:0] in_mbid,
    input            [1:0] in_mbresp,
    input [USER_WIDTH-1:0] in_mbuser,
    input                  in_mbvalid,
    output                 out_mbready,
    
    output reg   [ID_WIDTH-1:0] out_sbid,
    output reg            [1:0] out_sbresp,
    output reg [USER_WIDTH-1:0] out_sbuser,
    output reg                  out_sbvalid,
    input                       in_sbready,
    
    input   [ID_WIDTH-1:0] in_awid,
    input [USER_WIDTH-1:0] in_awuser,
    input                  drop
);

localparam BUF_WID = ID_WIDTH + USER_WIDTH + 2;
localparam ID_END  = ID_WIDTH + 2;

localparam OKAY   = 2'b00;
localparam EXOKAY = 2'b01;
localparam SLVERR = 2'b10;
localparam DECERR = 2'b11;

wire rd_en;
wire wr_en, b_empty, b_full;
wire [BUF_WID-1:0] data_in, data_out;
reg empty_d;

assign out_mbready = ~b_full;
assign wr_en = in_mbvalid & out_mbready;

assign data_in[1:0]              = in_mbresp;
assign data_in[ID_END-1:2]       = in_mbid;
assign data_in[BUF_WID-1:ID_END] = in_mbuser;

always @(posedge clk) begin
    if(~reset_) begin
        {out_sbid, out_sbuser, out_sbresp} <= 'h0;
        out_sbvalid <= 1'b0;
        empty_d     <= 'b0;
    end else begin
        empty_d     <= b_empty;
        if (drop) begin
            out_sbresp  <= DECERR;
            out_sbid    <= in_awid; 
            out_sbuser  <= in_awuser;
            out_sbvalid <= 1'b1;
        end
        else if (in_sbready & out_sbvalid & ~rd_en) begin
            out_sbvalid <= 1'b0;
        end
        else if (rd_en) begin
            out_sbresp  <= data_out[1:0];
            out_sbid    <= data_out[ID_END-1:2]; 
            out_sbuser  <= data_out[BUF_WID-1:ID_END];
            out_sbvalid <= 1'b1;
        end
    end
end

assign rd_en = ((~b_empty & empty_d) | (in_sbready & out_sbvalid & ~b_empty)) & ~drop ;

/* instantiating the FIFO for the read data worst case when the original requester is not ready to accept the read data*/
synch_fifo #(.DW(BUF_WID), .FIFO_DEPTH(BUF_SZ))  RDATA_BUF(
                                                      .clk       (clk),
                                                      .rst_      (reset_),
                                                      .wr_en     (wr_en),
                                                      .rd_en     (rd_en),
                                                      .data_i    (data_in),
                                                      .data_o    (data_out),
                                                      .full      (b_full),
                                                      .empty     (b_empty)
                                                    );

endmodule

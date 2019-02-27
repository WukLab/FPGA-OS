/* ------------------------------------------------------------------------------
 * Title      : AXI based MMU IP 
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : axi_addr_ch_rx 
 * -----------------------------------------------------------------------------
 * Description: This is the address channel receiver with RX_BUF instantiated that
 *              sends the address out to be consumed by translator. Used for
 *              both read and write address channel
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps

// TODO :: Make it parameterized across ADDR/USER
module axi_addr_ch_rx #(
    parameter BUF_SZ = 64
)
(
    input         rx_clk,
    input         reset_,
    input   [3:0] in_id,
    input  [31:0] in_addr,
    input   [7:0] in_len,
    input   [2:0] in_size,
    input   [1:0] in_burst,
    input   [2:0] in_prot,
    input   [3:0] in_cache,
    input   [1:0] in_user,
    input         in_lock,
    input         in_valid,
    output        out_ready,
    output  [3:0] out_id,
    output [31:0] out_addr,
    output  [7:0] out_len,
    output  [2:0] out_size,
    output  [1:0] out_burst,
    output  [2:0] out_prot,
    output  [3:0] out_cache,
    output  [1:0] out_user,
    output        out_lock,
    input         i_buf_rd
);

wire [58:0] data_in, data_out;
wire wr_en, rd_en, empty, full;
reg  wvalid_d, rvalid_d, i_buf_rd_d;  

assign out_ready  = ~full;

assign data_in[3:0]   = in_id;
assign data_in[35:4]  = in_addr;
assign data_in[43:36] = in_len;
assign data_in[46:44] = in_size;
assign data_in[48:47] = in_burst;
assign data_in[51:49] = in_prot;
assign data_in[55:52] = in_cache;
assign data_in[57:56] = in_user;
assign data_in[58:58] = in_lock;

assign out_id    = ~empty ? data_out[3:0]   : out_id   ;
assign out_addr  = ~empty ? data_out[35:4]  : out_addr ;
assign out_len   = ~empty ? data_out[43:36] : out_len  ;
assign out_size  = ~empty ? data_out[46:44] : out_size ;
assign out_burst = ~empty ? data_out[48:47] : out_burst;
assign out_prot  = ~empty ? data_out[51:49] : out_prot ;
assign out_cache = ~empty ? data_out[55:52] : out_cache;
assign out_user  = ~empty ? data_out[57:56] : out_user ;
assign out_lock  = ~empty ? data_out[58:58] : out_lock ;

assign wr_en = in_valid & out_ready;
assign rd_en = i_buf_rd  & ~i_buf_rd_d;

always @(posedge rx_clk) begin
    if(~reset_) begin
        wvalid_d   <= 1'b0;
        i_buf_rd_d <= 1'b0;
    end else begin
        wvalid_d   <= in_valid;
        i_buf_rd_d <= i_buf_rd;
    end
end

/* instantiating the FIFO fro read address. */
synch_fifo #(.DW(59), .FIFO_DEPTH(BUF_SZ)) ADDR_RX_BUF( .clk    (rx_clk),
                                                        .rst_   (reset_),
                                                        .wr_en  (wr_en),
                                                        .rd_en  (rd_en),
                                                        .data_i (data_in),
                                                        .data_o (data_out),
                                                        .full   (full),
                                                        .empty  (empty)
                                                      );


endmodule

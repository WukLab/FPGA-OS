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

module axi_addr_ch_rx #(
    parameter BUF_SZ = 64,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter USER_WIDTH = 2
)
(
    input                   rx_clk,
    input                   reset_,
    input    [ID_WIDTH-1:0] in_id,
    input  [ADDR_WIDTH-1:0] in_addr,
    input             [7:0] in_len,
    input             [2:0] in_size,
    input             [1:0] in_burst,
    input             [2:0] in_prot,
    input             [3:0] in_cache,
    input  [USER_WIDTH-1:0] in_user,
    input                  in_lock,
    input                  in_valid,
    output                  out_ready,
    output   [ID_WIDTH-1:0] out_id,
    output [ADDR_WIDTH-1:0] out_addr,
    output            [7:0] out_len,
    output            [2:0] out_size,
    output            [1:0] out_burst,
    output            [2:0] out_prot,
    output            [3:0] out_cache,
    output [USER_WIDTH-1:0] out_user,
    output                  out_lock,
    input                   i_buf_rd
);

localparam BUF_WID  = ID_WIDTH + USER_WIDTH + ADDR_WIDTH + 21;
localparam ID_END   = ID_WIDTH + 21;
localparam ADDR_END = ADDR_WIDTH + ID_END;

wire [BUF_WID-1:0] data_in, data_out;
wire wr_en, rd_en, empty, full;
reg  wvalid_d, rvalid_d, i_buf_rd_d;  

assign out_ready  = ~full;


assign data_in[7:0]                = in_len;
assign data_in[10:8]               = in_size;
assign data_in[12:11]              = in_burst;
assign data_in[15:13]              = in_prot;
assign data_in[19:16]              = in_cache;
assign data_in[20:20]              = in_lock;
assign data_in[ID_END-1:21]        = in_id;
assign data_in[ADDR_END-1:ID_END]  = in_addr;
assign data_in[BUF_WID-1:ADDR_END] = in_user;

assign out_len   = ~empty ? data_out[7:0]               : out_len  ;
assign out_size  = ~empty ? data_out[10:8]              : out_size ;
assign out_burst = ~empty ? data_out[12:11]             : out_burst;
assign out_prot  = ~empty ? data_out[15:13]             : out_prot ;
assign out_cache = ~empty ? data_out[19:16]             : out_cache;
assign out_lock  = ~empty ? data_out[20:20]             : out_lock ;
assign out_id    = ~empty ? data_out[ID_END-1:21]       : out_id   ;
assign out_addr  = ~empty ? data_out[ADDR_END-1:ID_END] : out_addr ;
assign out_user  = ~empty ? data_out[BUF_WID-1:ADDR_END]: out_user ;

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
synch_fifo #(.DW(BUF_WID), .FIFO_DEPTH(BUF_SZ)) ADDR_RX_BUF( .clk    (rx_clk),
                                                             .rst_   (reset_),
                                                             .wr_en  (wr_en),
                                                             .rd_en  (rd_en),
                                                             .data_i (data_in),
                                                             .data_o (data_out),
                                                             .full   (full),
                                                             .empty  (empty)
                                                           );

endmodule

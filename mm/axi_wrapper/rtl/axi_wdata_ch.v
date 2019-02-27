/* ------------------------------------------------------------------------------
 * Title      : AXI based MMU IP 
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : axi_wdata_ch
 * -----------------------------------------------------------------------------
 * Description: This is the write data channel receiver with RX_BUF instantiated that
 *              sends the write address to the translation module.
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps

// TODO :: Make it parameterized across DATA/USER
module axi_wdata_ch #(
    parameter BUF_SZ = 256
)
(
    input             rx_clk,
    input             rxreset_,
    input             tx_clk,
    input             txreset_,
    input       [3:0] in_wid,
    input      [31:0] in_wdata,
    input       [3:0] in_wstrb,
    input       [1:0] in_wuser,
    input             in_wlast,
    input             in_swvalid,
    output            out_swready,
    output reg  [3:0] out_wid,
    output reg [31:0] out_wdata,
    output reg  [3:0] out_wstrb,
    output reg  [1:0] out_wuser,
    output reg        out_wlast,
    output reg        out_mwvalid,
    input             in_mwready,
    input             start
);

reg         rd_en, flag; 

wire [42:0] data_in, data_out;
wire        wr_en, w_empty, w_full, a_emp, a_full;

assign data_in[3:0]   = in_wid;
assign data_in[35:4]  = in_wdata;
assign data_in[39:36] = in_wstrb;
assign data_in[40:40] = in_wlast;
assign data_in[42:41] = in_wuser;

assign out_swready = ~a_full & ~w_full; // if almost full then we cannot be sure if we can write 
assign wr_en       = in_swvalid & out_swready;

always @(posedge tx_clk) begin
    if (~txreset_ | ~rd_en) begin
        out_wid     <= 4'h0;
        out_wdata   <= 32'h0;
        out_wstrb   <= 4'h0;
        out_wlast   <= 1'b0;
        out_wuser   <= 2'b0;
        out_mwvalid <= 1'b0;
    end else begin
        if (rd_en) begin
            out_wid     <= data_out[3:0];
            out_wdata   <= data_out[35:4];
            out_wstrb   <= data_out[39:36];
            out_wlast   <= data_out[40:40];
            out_wuser   <= data_out[42:41];
            out_mwvalid <= 1'b1;
        end
    end
end

always @(posedge tx_clk) begin
    if(~txreset_) begin
        rd_en <= 1'b0;
        flag  <= 1'b0;
    end else begin
        if (start &  ~rd_en) begin
            rd_en <= 1'b1;
            if (data_out[40:40]) begin
                flag <= 1'b1;
            end
        end else begin
            if (data_out[40:40] | flag ) begin
                rd_en <= 1'b0;
                flag  <= 1'b0;
            end
        end 
    end
end

/* instantiating the FIFO for the write data worst case all burst for all thw writes */
async_fifo #(.DW(43), .FIFO_DEPTH(BUF_SZ)) WRDATA_RX_BUF ( .srcclk    (rx_clk),
                                                           .dstclk    (tx_clk),
                                                           .srcrst_   (rxreset_),
                                                           .dstrst_   (txreset_),
                                                           .wr_en     (wr_en),
                                                           .rd_en     (rd_en),
                                                           .data_in   (data_in),
                                                           .data_out  (data_out),
                                                           .full      (w_full),
                                                           .empty     (w_empty),
                                                           .almost_full (a_full),
                                                           .almost_empty(a_emp)
                                                         );

endmodule

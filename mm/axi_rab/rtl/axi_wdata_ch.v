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
    parameter BUF_SZ     = 256,
    parameter DATA_WIDTH = 32, 
	parameter STRB_WIDTH = DATA_WIDTH/8,
	parameter USER_WIDTH = 2 
)
(
    input                       rx_clk,
    input                       rxreset_,
    input                       tx_clk,
    input                       txreset_,
    input [DATA_WIDTH-1:0]      in_wdata,
    input [STRB_WIDTH-1:0]      in_wstrb,
    input [USER_WIDTH-1:0]      in_wuser,
    input                       in_wlast,
    input                       in_swvalid,
    output                      out_swready,
    output reg [DATA_WIDTH-1:0] out_wdata,
    output reg [STRB_WIDTH-1:0] out_wstrb,
    output reg [USER_WIDTH-1:0] out_wuser,
    output reg                  out_wlast,
    output reg                  out_mwvalid,
    input                       in_mwready,
    input                       start
);

reg         rd_en, flag;

localparam BUF_WID  = USER_WIDTH + DATA_WIDTH + STRB_WIDTH + 1; 
localparam DATA_END = DATA_WIDTH + 1; 
localparam STRB_END = STRB_WIDTH + DATA_END; 

wire [BUF_WID-1:0] data_in, data_out;
wire        wr_en, w_empty, w_full, a_emp, a_full;

assign data_in[0:0]                 = in_wlast;
assign data_in[DATA_END-1:1]        = in_wdata;
assign data_in[STRB_END-1:DATA_END] = in_wstrb;
assign data_in[BUF_WID-1:STRB_END]  = in_wuser;

assign out_swready = ~a_full & ~w_full; // if almost full then we cannot be sure if we can write 
assign wr_en       = in_swvalid & out_swready;

always @(posedge tx_clk) begin
    if (~txreset_ | ~rd_en) begin
        out_wdata   <= 'h0;
        out_wstrb   <= 4'h0;
        out_wlast   <= 1'b0;
        out_wuser   <= 2'b0;
        out_mwvalid <= 1'b0;
    end else begin
        if (rd_en) begin
            out_wlast   <= data_out[0:0]                ;
            out_wdata   <= data_out[DATA_END-1:1]       ;
            out_wstrb   <= data_out[STRB_END-1:DATA_END];
            out_wuser   <= data_out[BUF_WID-1:STRB_END] ;
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
            if (data_out[0:0]) begin
                flag <= 1'b1;
            end
        end else begin
            if (data_out[0:0] | flag ) begin
                rd_en <= 1'b0;
                flag  <= 1'b0;
            end
        end 
    end
end

/* instantiating the FIFO for the write data worst case all burst for all thw writes */
async_fifo #(.DW(BUF_WID), .FIFO_DEPTH(BUF_SZ)) WRDATA_RX_BUF ( .srcclk    (rx_clk),
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

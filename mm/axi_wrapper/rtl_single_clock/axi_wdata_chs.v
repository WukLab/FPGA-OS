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

module axi_wdata_chs #(
    parameter BUF_SZ     = 256,
    parameter DATA_WIDTH = 32, 
	parameter STRB_WIDTH = DATA_WIDTH/8,
	parameter USER_WIDTH = 2 
)
(
    input                       clk,
    input                       reset_,
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
    input                       done,
    input                       drop,
    output reg                  drop_done
);

reg        rd_en, tx_en, t_c = 0, count = 0;
reg [6:0]  drop_count = 'b0, done_count = 'b0;
reg [1:0]  state, state_n;

localparam BUF_WID  = USER_WIDTH + DATA_WIDTH + STRB_WIDTH + 1; 
localparam DATA_END = DATA_WIDTH + 1; 
localparam STRB_END = STRB_WIDTH + DATA_END; 

wire [BUF_WID-1:0] data_in, data_out;
wire               wr_en, w_empty, w_full;

assign data_in[0:0]                 = in_wlast;
assign data_in[DATA_END-1:1]        = in_wdata;
assign data_in[STRB_END-1:DATA_END] = in_wstrb;
assign data_in[BUF_WID-1:STRB_END]  = in_wuser;

assign out_swready = ~w_full; 
assign wr_en       = in_swvalid & out_swready;

always @(posedge clk) begin
    if (~reset_) begin
        out_wdata   <= 'h0;
        out_wstrb   <= 4'h0;
        out_wlast   <= 1'b0;
        out_wuser   <= 2'b0;
        out_mwvalid <= 1'b0;
    end else begin
        if (tx_en) begin
            if (count == 0 | (out_mwvalid & in_mwready)) begin
                out_wlast   <= data_out[0:0]                ;
                out_wdata   <= data_out[DATA_END-1:1]       ;
                out_wstrb   <= data_out[STRB_END-1:DATA_END];
                out_wuser   <= data_out[BUF_WID-1:STRB_END] ;
                out_mwvalid <= 1'b1;
                count       <= count | 1;
            end
        end 
        else if (out_mwvalid & in_mwready) begin
            out_mwvalid <= 1'b0;
            out_wlast   <= 1'b0;
            count       <= 1'b0;
        end
    end
end

always @(posedge clk) begin
    if (~reset_) begin
        state <= 2'b0;
    end else begin
        state <= state_n;
    end
end

/* FSM to read from buffer and send on the channel */
always @(state or data_out or out_mwvalid or in_mwready or done or drop) begin
    rd_en = 0;
    case (state)
        0 : begin /* IDLE */ 
                if ( drop | drop_count != 0 ) begin
                    drop_count = drop ? drop_count+1 : drop_count;
                    state_n    = 2'd2;
                end else if (done | done_count != 0) begin
                    done_count = done ? done_count+1 : done_count;
                    state_n    = 2'd1;
                    t_c        = 0; 
                end else begin
                    state_n    = 2'b0;
                end
                tx_en = 0;
                drop_done = 0;
            end
        1 : begin /* Translation success - READ from fifo and SEND till last */
                rd_en = 1;
                tx_en = 1;
                if (w_empty) begin
                    rd_en = 0;
                    tx_en = 0;
                end
                else if (data_out[0]) begin
                    state_n = 2'b0;
                    t_c     = 1;
                    done_count = done_count - 1'b1;
                end else if ( out_mwvalid & ~in_mwready ) begin
                    rd_en   = 0;                 
                end
                if ( drop ) begin
                    drop_count = drop_count + 1'b1;
                end
                /* if the next address translated while sending the current keep it so that even that can be sent*/
                if ( done & out_mwvalid ) begin
                    done_count = done_count + 1'b1;
                end
            end
        2 : begin  /* translation failed - READ from fifo and DROP till last */
                rd_en = 1;
                if ( data_out[0] ) begin
                    state_n   = 2'b0;
                    drop_done = 1;
                    drop_count = drop_count - 1'b1;
                end
                if (done) begin
                    done_count = done_count + 1'b1;
                end
            end
    endcase
end

/* instantiating the FIFO for the write data worst case all burst for all thw writes */
synch_fifo #(.DW(BUF_WID), .FIFO_DEPTH(BUF_SZ)) WRDATA_RX_BUF (
                                                           .clk     (clk),
                                                           .rst_    (reset_),
                                                           .wr_en   (wr_en),
                                                           .rd_en   (rd_en),
                                                           .data_i  (data_in),
                                                           .data_o  (data_out),
                                                           .full    (w_full),
                                                           .empty   (w_empty)
                                                         );

endmodule

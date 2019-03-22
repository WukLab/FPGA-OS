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

module axi_rdata_chs #(
    parameter BUF_SZ   = 256,
    parameter ID_WID   = 8,
    parameter DATA_WID = 32,
    parameter USER_WID = 2
)
(
/*rx here is the mem side*/
    input                clk,
    input                reset_,
/*input from mem/system side */
    input   [ID_WID-1:0] in_rid,
    input [DATA_WID-1:0] in_rdata,
    input          [1:0] in_rresp,
    input [USER_WID-1:0] in_ruser,
    input                in_rlast,
    input                in_mrvalid,
    output               out_mrready, /*ready back to the MC*/
/*output to the AXI app/interconnect side */
    output reg   [ID_WID-1:0] out_rid,
    output reg [DATA_WID-1:0] out_rdata,
    output reg          [1:0] out_rresp,
    output reg [USER_WID-1:0] out_ruser,
    output reg                out_rlast,
    output reg                out_srvalid,
    input                     in_srready, /*ready from App/Interconnect*/
                        
    input   [ID_WID-1:0] in_arid, 
    input [USER_WID-1:0] in_aruser,
    input          [2:0] in_arsize,
    input          [7:0] in_arlen, 
    input                drop,
    output reg           drop_done
);

localparam BUF_WID = ID_WID + USER_WID + DATA_WID + 3;
localparam ID_END   = 3 + ID_WID;
localparam DATA_END = ID_END + DATA_WID;
localparam NUM_RD_BEAT = DATA_WID/32;

reg       rd_en, tx_en, drop_seen; 
reg [1:0] state, state_n;
reg [7:0] count;
wire [BUF_WID-1:0] data_in, data_out;
wire      wr_en, r_empty, r_full;

localparam OKAY   = 2'b00;
localparam EXOKAY = 2'b01;
localparam SLVERR = 2'b10;
localparam DECERR = 2'b11;

assign data_in[1:0]                = in_rresp;
assign data_in[2:2]                = in_rlast;
assign data_in[ID_END-1:3]         = in_rid;
assign data_in[DATA_END-1:ID_END]  = in_rdata;
assign data_in[BUF_WID-1:DATA_END] = in_ruser;

assign out_mrready = ~r_full;
assign wr_en       = in_mrvalid & out_mrready;

always @(posedge clk) begin
    if (~reset_) begin
        {out_rid, out_rdata, out_rresp, out_rlast, out_ruser} <= 'b0; 
        out_srvalid <= 'b0;
        state       <= 'b0;
        count       <= 'b0;
        drop_done   <= 1'b0; 
    end else begin
        if (tx_en) begin
            if ( state_n == 2 | count != 0 ) begin
                out_rid     <= in_arid;
                out_rdata   <= {NUM_RD_BEAT{32'hdead_dead}};
                out_rresp   <= DECERR;
                out_ruser   <= in_aruser;
                if (count == 0) begin
                    count     <= count + 1;
                    out_rlast <= ( in_arlen == 1 ) ? 'b1 : 'b0;
                end
                else if (in_srready) begin
                    if ( count == in_arlen - 1 ) begin
                        out_rlast <= 1'b1;
                        drop_done <= 1'b1; 
                    end else begin
                        out_rlast <= 1'b0;
                        count     <= count + 1; 
                    end
                end
            end else begin
                out_rid     <= data_out[ID_END-1:3]        ;
                out_rdata   <= data_out[DATA_END-1:ID_END] ;
                out_rresp   <= data_out[1:0]               ;
                out_ruser   <= data_out[BUF_WID-1:DATA_END];
                out_rlast   <= data_out[2:2]               ;
            end
            out_srvalid <= 1'b1;
        end
        else if (in_srready & out_srvalid ) begin
            out_srvalid <= 1'b0;
            out_rlast   <= 1'b0;
            count       <=  'b0; 
            drop_done   <= 1'b0; 
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

/* TODO :: Add burst considerations as well FSM is a placeholder for that - some extra LUTs very small number wasted here */
always @(state or drop or data_out or r_empty or count ) begin
    state_n = state;
    rd_en = 0;
    tx_en = 0;
    case (state)
        0 : begin /* IDLE */ 
                if (drop | drop_seen) begin
                    state_n = 2;
                end else if (~r_empty) begin
                    state_n = 1;
                end
                drop_seen = 0;
            end
        1 : begin /* READ */
                rd_en = 1;
                tx_en = 1;
                if (r_empty) begin
                    rd_en   = 0;
                    tx_en   = 0;
                end else if (data_out[2:2]) begin
                    state_n = 0;
                end else if (out_srvalid & ~in_srready) begin
                    rd_en   = 0;                 
                end
                
                if (drop) begin
                    drop_seen = 1;
                end
            end
        2 : begin  /* DROP */
                tx_en = 1;
                if ( count == in_arlen - 1 ) begin
                    state_n = 0;
                end
            end
    endcase
end

/* instantiating the FIFO for the read data worst case when the original requester is not ready to accept the read data*/
synch_fifo #(.DW(BUF_WID), .FIFO_DEPTH(BUF_SZ))  RDATA_BUF( 
                                                    .clk       (clk),
                                                    .rst_      (reset_),
                                                    .wr_en     (wr_en),
                                                    .rd_en     (rd_en),
                                                    .data_i    (data_in),
                                                    .data_o    (data_out),
                                                    .full      (r_full),
                                                    .empty     (r_empty)
                                                  );

endmodule

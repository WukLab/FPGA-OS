`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple parameterized synchronous fifo
//////////////////////////////////////////////////////////////////////////////////
module synch_fifo #(    
parameter FIFO_DEPTH = 128,
parameter DW         = 32
)
(
    input               clk,
    input               rst_,
    input               rd_en,
    input               wr_en,
    input      [DW-1:0] data_i,
    output     [DW-1:0] data_o,
    output              full,
    output              empty
);

localparam AW = $clog2(FIFO_DEPTH);

// Read and write pointer
reg [AW:0] rd_ptr;
reg [AW:0] wr_ptr;

//FIFO memory. Initializing with all 0 to avoid any x-prop
reg [DW-1:0] fifo [0:FIFO_DEPTH-1];

always @(posedge clk) begin
    if(~rst_) begin
        rd_ptr <= 'h0;
        wr_ptr <= 'h0;
    end else begin
        if (wr_en & ~full) begin
            wr_ptr               <= wr_ptr + 'd1;
            fifo[wr_ptr[AW-1:0]] <= data_i;
        end 
        if (rd_en & ~empty) begin
            rd_ptr               <= rd_ptr + 'd1;
        end 
    end
end

assign full   = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) & (wr_ptr[AW] != rd_ptr[AW]);
assign empty  = (wr_ptr == rd_ptr);
assign data_o = fifo[rd_ptr[AW-1:0]];    
    
endmodule

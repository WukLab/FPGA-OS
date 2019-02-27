`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple parameterized synchronous fifo
//////////////////////////////////////////////////////////////////////////////////
module async_fifo #(    
parameter FIFO_DEPTH = 128,
parameter DW         = 32
)
(
// signals toward the write side - src clk domain
    input               srcclk,
    input               srcrst_,
    input               wr_en,
    input      [DW-1:0] data_in,
    output              full,
    output              almost_full,
    
// signals toward the read side - dest clk domain
    input               dstclk,
    input               dstrst_,
    input               rd_en,
    output     [DW-1:0] data_out,
    output              empty,
    output              almost_empty
);

localparam AW = $clog2(FIFO_DEPTH);

// Read and write pointer and corresponding gray counter
reg [AW-1:0] rd_ptr;
reg [AW-1:0] wr_ptr;
reg [AW-1:0] ptr_diff;
// Synchronized versions of the counters
wire [AW-1:0] rd_sync, rd_ptr_sync, rd_ptr_g;
wire [AW-1:0] wr_sync, wr_ptr_sync, wr_ptr_g;

//FIFO memory. Initializing with all 0 to avoid any x-prop
reg [DW-1:0] fifo [0:FIFO_DEPTH-1];

always @(posedge srcclk or negedge srcrst_) begin
    if(~srcrst_) begin
        wr_ptr <= 'h0;
    end else begin
        if (wr_en & ~full) begin
            wr_ptr               <= wr_ptr + 'd1;
            fifo[wr_ptr[AW-1:0]] <= data_in;
        end 
    end
end

always @(posedge dstclk or negedge dstrst_) begin
    if(~dstrst_) begin
        rd_ptr <= 'h0;
    end else begin
        if (rd_en & ~empty) begin
            rd_ptr <= rd_ptr + 'd1;
        end 
    end
end

always @(*) begin //ptr_diff changes as read or write clock change
    if(wr_ptr > rd_ptr) begin
        ptr_diff = wr_ptr - rd_ptr;
    end else if(wr_ptr < rd_ptr ) begin
        ptr_diff = ((FIFO_DEPTH - rd_ptr) + wr_ptr);
    end else begin
        ptr_diff = 0;
    end
end

assign data_out = fifo[rd_ptr[AW-1:0]];   

//--write pointer synchronizer controled by read clock--//
sync2d #(.DW(AW+1)) syn2d_wr_g(.d(wr_ptr_g), .q(wr_sync), .clk(dstclk));

//--read pointer synchronizer controled by write clock--//
sync2d #(.DW(AW+1)) syn2d_rd_g(.d(rd_ptr_g), .q(rd_sync), .clk(srcclk));

//--Combinational logic--//
//--Binary pointer--//
assign full  = ((wr_ptr[AW-1 : 0] - rd_ptr_sync[AW-1 : 0]) == FIFO_DEPTH);
assign empty = (wr_ptr_sync == rd_ptr) ;

//-- Gray pointer--//
//assign wr_full  = ((wr_ptr[AW-2 : 0] == rd_ptr_sync[AW-2 : 0]) && 
//                (wr_ptr[AW-1] != rd_ptr_sync[AW-1]) &&
//                (wr_ptr[AW] != rd_ptr_sync[AW]));

//--binary code to gray code--//
assign wr_ptr_g = bin2gray(wr_ptr);
assign rd_ptr_g = bin2gray(rd_ptr);

//--gray code to binary code--//
assign wr_ptr_sync = gray2bin(wr_sync);
assign rd_ptr_sync = gray2bin(rd_sync);

assign almost_empty = (ptr_diff == 1);
assign almost_full  = (ptr_diff >= FIFO_DEPTH-1);

function [AW-1:0] gray2bin ;
    input [AW-1:0] gray;
    integer i;
    begin
        gray2bin[AW-1] = gray[AW-1];
        for (i=AW-2; i>=0; i=i-1) 
            gray2bin[i] = gray2bin[i+1]^gray[i];
    end
endfunction
      
      
function [AW-1:0] bin2gray;
    input [AW-1:0] bin;
    integer i;
    begin
        for (i=0; i<AW-1; i=i+1) 
            bin2gray[i] = bin[i+1] ^ bin[i];
        bin2gray[AW-1] = bin[AW-1];
    end
endfunction

endmodule

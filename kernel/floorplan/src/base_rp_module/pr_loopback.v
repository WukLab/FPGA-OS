`timescale 1ns / 1ps

module pr_loopback(
    input clock,
    input [31:0] in,
    output reg [31:0] out
    );

    reg [31:0] local_counter;
    reg [31:0] cached_input;
    
    always @(posedge clock) begin
        local_counter <= local_counter + 1;
        out <= local_counter;
        cached_input <= in;
    end

endmodule

`timescale 1ns / 1ps
module hls_startGen(clk, rst, startCore);

	 input clk, rst;
	 output startCore;
	 reg startCore;
	 
	// Declare state register
	reg [2:0] state;
	parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
	
	initial begin 
		state = 2'b00;
	end
	
	always@(posedge clk or posedge rst) begin
	if (rst)
		begin
			startCore <= 1'b0;
			state <= S0;
		end
	else
		begin
			case (state)
				S0: begin
					startCore <= 1'b0;
					state <= S1;
					end
				S1: begin
					state <= S2;
					end
				S2: begin
					state <= S3;			
					startCore <= 1'b1;
					end
			endcase
		end
	end

endmodule

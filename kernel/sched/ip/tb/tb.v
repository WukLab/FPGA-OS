/*
 * Copyright (c) 2019, Wuklab, UCSD. All rights reserved.
 */

`timescale 1fs/1fs

module icap_controller_tb();

	wire clk_p;
	wire clk_n;
	reg clk_ref;

	initial begin
		clk_ref = 1;
	end

	always
		#4000000.000 clk_ref = ~clk_ref;

	assign clk_p = clk_ref;
	assign clk_n = ~clk_ref;

	icap_controller_wrapper DUT (
		.sysclk_125_clk_n(clk_n),
		.sysclk_125_clk_p(clk_p)
	);
	
endmodule

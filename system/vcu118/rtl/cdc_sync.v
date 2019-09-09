(* DowngradeIPIdentifiedWarnings="yes" *)
module user_cdc_sync
(
	input clk,
	input signal_in,
	output reg signal_out
);

       wire sig_in_cdc_from ;
       (* ASYNC_REG = "TRUE" *) reg  s_out_d2_cdc_to;
       (* ASYNC_REG = "TRUE" *) reg  s_out_d3;
       (* ASYNC_REG = "TRUE" *) reg  s_out_d4;

      assign sig_in_cdc_from = signal_in;

      always @(posedge clk)
      begin
        signal_out       <= s_out_d4;
        s_out_d4         <= s_out_d3;
        s_out_d3         <= s_out_d2_cdc_to;
        s_out_d2_cdc_to  <= sig_in_cdc_from;
      end
endmodule
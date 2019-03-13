/*
 * YS:
 * -  The original tb is not doing too much work.
 *    Majority of the work is done by the pkt_mon module.
 * -  This tb is not using gt to send any data, it will
 *    loopback whatever sent out from MAC. Shame.
 */

`define SIM_SPEED_UP

`timescale 1fs/1fs

module legofpga_mac_qsfp_tb
(
);

  task  display_result;
        input [4:0] completion_status;
        begin
            if ( completion_status == 5'd1 ) 
               begin
                  $display("INFO : Sanity Completed and Passed");
                  $display("INFO : CORE TEST SUCCESSFULLY COMPLETED and PASSED");
                  $display("INFO : Test Completed Successfully");
               end
            else begin
               $display("%c[1;31m",27);
               $display("******");
               $display("INFO : Sanity Completed");
               case ( completion_status )
                 5'd0:  $display("ERROR@%0t : Test did not run.", $time );
                 5'd2:  $display("ERROR@%0t : No block lock on any lanes.", $time );
                 5'd3:  $display("ERROR@%0t : Not all lanes achieved block lock.", $time );
                 5'd4:  $display("ERROR@%0t : Some lanes lost block lock after achieving block lock.", $time );
                 5'd5:  $display("ERROR@%0t : No lane sync on any lanes.", $time );
                 5'd6:  $display("ERROR@%0t : Not all lanes achieved sync.", $time );
                 5'd7:  $display("ERROR@%0t : Some lanes lost sync after achieving sync.", $time );
                 5'd8:  $display("ERROR@%0t : No alignment status or rx_status was achieved.", $time );
                 5'd9:  $display("ERROR@%0t : Loss of alignment status or rx_status after both were achieved.", $time );
                 5'd10: $display("ERROR@%0t : TX timed out.", $time );
                 5'd11: $display("ERROR@%0t : No tx data was sent.", $time );
                 5'd12: $display("ERROR@%0t : Number of packets received did not equal the number of packets sent.", $time );
                 5'd13: $display("ERROR@%0t : Total number of bytes received did not equal the total number of bytes sent.", $time );
                 5'd14: $display("ERROR@%0t : An lbus protocol error was detected.", $time );
                 5'd15: $display("ERROR@%0t : Bit errors were detected in the received packets.", $time );
                 5'd31: $display("ERROR@%0t : Test is stuck in reset.", $time );
                 default: $display("ERROR@%0t : An invalid completion status (%h) was detected.", $time, completion_status );
               endcase
               $display("******");
               $display("%c[0m",27);
               $display("ERROR : All the Test Cases Completed but Failed with Errors/Warnings");
            end
        end
    endtask


	reg             dclk;
	reg             gt_refclk_p;
	reg             gt_refclk_n;
	reg             sys_reset;
	wire [1-1:0] gt_txp_out;
	wire [1-1:0] gt_txn_out;
	wire            rx_gt_locked_led_0;
	wire            rx_block_lock_led_0;
	reg             timed_out;
	reg             time_out_cntr_en;
	reg  [24 :0]    time_out_cntr;
	wire [4:0]      completion_status;

	legofpga_mac_qsfp	DUT (
		.gt_rxp_in		(gt_txp_out),
		.gt_rxn_in		(gt_txn_out),
		.gt_txp_out		(gt_txp_out),
		.gt_txn_out		(gt_txn_out),

		.gt_refclk_p		(gt_refclk_p),
		.gt_refclk_n		(gt_refclk_n),

		.sys_reset		(sys_reset),
		.dclk			(dclk),

		.rx_gt_locked_led_0	(rx_gt_locked_led_0),
		.rx_block_lock_led_0	(rx_block_lock_led_0),
		.completion_status	(completion_status)
	);

    initial
    begin
    `ifdef SIM_SPEED_UP
    `else
      $display("****************");
      $display("INFO : Simulation time may be longer. For faster simulation, please use SIM_SPEED_UP option. For more information refer product guide.");
      $display("****************");
    `endif

      gt_refclk_p = 0;
      gt_refclk_n = 1;
      dclk   = 0;
      sys_reset  = 1; 

      repeat (20) @(posedge dclk);
      sys_reset = 0;
      $display("INFO : sys_reset sent");

      // One lock
      $display("INFO : WAITING FOR THE GT LOCK..........");
      time_out_cntr_en = 1;
      wait(rx_gt_locked_led_0 || timed_out);

      if (rx_gt_locked_led_0)
          $display("INFO : GT LOCKED");
      else 
      begin
          $display("ERROR: GT LOCK FAILED - Timed Out");
          $finish; 
      end
      time_out_cntr_en = 0;

      // One lock
      $display("INFO : WAITING FOR rx_block_lock..........");
      repeat (1) @(posedge dclk);
      time_out_cntr_en = 1;
      wait(rx_block_lock_led_0 || timed_out);
   
      if(rx_block_lock_led_0) 
         $display("INFO : CORE 25GE rx block locked");
      else 
      begin
          $display("ERROR: CORE 25GE RX BLOCK LOCK FAILED - Timed Out");
          $finish; 
      end
      time_out_cntr_en = 0;

      $display("INFO : Waiting for completion status..........");
      wait ( ( completion_status != 5'h1F ) && ( completion_status != 5'h0 ) ) ;
      display_result(completion_status);

  $finish; 

    end

    //////////////////////////////////////////////////
    ////time_out_cntr signal generation Max 26ms
    //////////////////////////////////////////////////
    always @( posedge dclk or negedge sys_reset )
    begin
        if ( sys_reset == 1'b1 )
        begin
            timed_out     <= 1'b0;
            time_out_cntr <= 24'd0;
        end
        else
        begin
            timed_out <= time_out_cntr[20];
            if (time_out_cntr_en == 1'b1)
                time_out_cntr <= time_out_cntr + 24'd1;
            else
                time_out_cntr <= 24'd0;
        end
    end


    initial
    begin
        gt_refclk_p =1;
        forever #3103030.303   gt_refclk_p = ~ gt_refclk_p;
    end

    initial
    begin
        gt_refclk_n =0;
        forever #3103030.303   gt_refclk_n = ~ gt_refclk_n;
    end

    initial
    begin
        dclk =1;
        forever #5000000.000   dclk = ~ dclk;
    end

endmodule

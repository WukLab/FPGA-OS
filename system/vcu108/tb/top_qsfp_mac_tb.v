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


	reg             sys_reset;
	wire [1-1:0] gt_txp_out;
	wire [1-1:0] gt_txn_out;
	wire            rx_gt_locked_led_0;
	wire            rx_block_lock_led_0;
	wire [4:0]      completion_status;

	reg             sysclk_125_clk_n;
	reg             sysclk_125_clk_p;
	reg             sysclk_161_clk_n;
	reg             sysclk_161_clk_p;

	legofpga_mac_qsfp	DUT (
		.default_sysclk_125_clk_n	(sysclk_125_clk_n),
		.default_sysclk_125_clk_p	(sysclk_125_clk_p),
		.default_sysclk_161_clk_n	(sysclk_161_clk_n),
		.default_sysclk_161_clk_p	(sysclk_161_clk_p),

		.gt_rxp_in			(gt_txp_out),
		.gt_rxn_in			(gt_txn_out),
		.gt_txp_out			(gt_txp_out),
		.gt_txn_out			(gt_txn_out),

		.rx_gt_locked_led_0		(rx_gt_locked_led_0),
		.rx_block_lock_led_0		(rx_block_lock_led_0),
		.completion_status		(completion_status)
	);

    initial
    begin
    `ifdef SIM_SPEED_UP
    `else
      $display("****************");
      $display("INFO : Simulation time may be longer. For faster simulation, please use SIM_SPEED_UP option. For more information refer product guide.");
      $display("****************");
    `endif

      sysclk_125_clk_n = 1;
      sysclk_125_clk_p = 0;

      sysclk_161_clk_n = 1;
      sysclk_161_clk_p = 0;

      // One lock
      $display("INFO : waiting for the gt lock..........");
      wait(rx_gt_locked_led_0);
      $display("INFO : GT LOCKED");

      // One lock
      $display("INFO : WAITING FOR rx_block_lock..........");
      wait(rx_block_lock_led_0);
      $display("INFO : CORE 25GE rx block locked");

      //
      // Having above two signals asserted is not enough.
      // We should use the `mac_ready` as the green light.
      // Once `mac_ready` is asserted, this TB can send stuff.
      // `mac_ready` is in top_mac_qsfp.c, not exported now.
      //

      // Completion status does not matter for us.
      // It's here just for skip the time. Can be removed.
      $display("INFO : Waiting for completion status..........");
      wait ( ( completion_status != 5'h1F ) && ( completion_status != 5'h0 ) ) ;
      display_result(completion_status);

    $finish; 

    end

    initial
    begin
        sysclk_161_clk_p = 1;
        forever #3103030.303   sysclk_161_clk_p = ~ sysclk_161_clk_p;
    end

    initial
    begin
        sysclk_161_clk_n = 0;
        forever #3103030.303   sysclk_161_clk_n = ~ sysclk_161_clk_n;
    end

    initial
    begin
        sysclk_125_clk_p =1;
        forever #4000000.000 sysclk_125_clk_p = ~ sysclk_125_clk_p;
    end

    initial
    begin
        sysclk_125_clk_n =0;
        forever #4000000.000  sysclk_125_clk_n = ~ sysclk_125_clk_n;
    end

endmodule

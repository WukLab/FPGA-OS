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
	reg             sys_reset;
	wire [1-1:0] gt_txp_out;
	wire [1-1:0] gt_txn_out;
	wire            rx_gt_locked_led_0;
	wire            rx_block_lock_led_0;

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
		.rx_block_lock_led_0		(rx_block_lock_led_0)
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

      $display("TB idle.");
      repeat(12)
        #8_00_000_000;

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

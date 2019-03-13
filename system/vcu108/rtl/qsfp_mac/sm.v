/*
 * The control path to bring up 10G/25G MAC IP.
 * Derived from the original reference design.
 * A lot code has been removed.
 * 	- YS (03/13/19)
 */

`define SIM_SPEED_UP

`timescale 1fs/1fs

(* DowngradeIPIdentifiedWarnings="yes" *)
module mac_qsfp_sm
(
	input		dclk,
	input		sys_reset,

	output		fsm_out_pktgen_enable,
	output		fsm_out_sys_reset,

	output reg [4:0]completion_status,
	output wire	rx_gt_locked_led,
	output wire	rx_block_lock_led,

	// RX AXIS Related
	input		mon_clk,
	input  wire	[55:0] rx_preambleout,
	input  wire	user_rx_reset,
	output wire	rx_reset,

	// TX AXIS Related
	input		gen_clk,
	output wire	[55:0] tx_preamblein,
	input  wire	user_tx_reset,
	output wire	tx_reset,
	input  wire	tx_unfout,

  // REMOVE ME
  input  wire tx_axis_tready,
  output wire tx_axis_tvalid,
  output wire [63:0] tx_axis_tdata,
  output wire tx_axis_tlast,
  output wire [7:0] tx_axis_tkeep,
  output wire tx_axis_tuser,

  input  wire rx_axis_tvalid,
  input  wire [63:0] rx_axis_tdata,
  input  wire rx_axis_tlast,
  input  wire [7:0] rx_axis_tkeep,
  input  wire rx_axis_tuser,

	// TX Control
	output wire	ctl_tx_send_lfi,
	output wire	ctl_tx_send_rfi,
	output wire	ctl_tx_send_idle,

	// AXI4 Lite
	output wire s_axi_aclk,
	output wire s_axi_aresetn,
	output wire [31:0] s_axi_awaddr,
	output wire s_axi_awvalid,
	input  wire s_axi_awready,
	output wire [31:0] s_axi_wdata,
	output wire [3:0] s_axi_wstrb,
	output wire s_axi_wvalid,
	input  wire s_axi_wready,
	input  wire [1:0] s_axi_bresp,
	input  wire s_axi_bvalid,
	output wire s_axi_bready,
	output wire [31:0] s_axi_araddr,
	output wire s_axi_arvalid,
	input  wire s_axi_arready,
	input  wire [31:0] s_axi_rdata,
	input  wire [1:0] s_axi_rresp,
	input  wire s_axi_rvalid,
	output wire s_axi_rready,
	output wire pm_tick,

	// RX Stat
	input  wire stat_rx_block_lock,
	input  wire stat_rx_framing_err_valid,
	input  wire stat_rx_framing_err,
	input  wire stat_rx_hi_ber,
	input  wire stat_rx_valid_ctrl_code,
	input  wire stat_rx_bad_code,
	input  wire [1:0] stat_rx_total_packets,
	input  wire stat_rx_total_good_packets,
	input  wire [3:0] stat_rx_total_bytes,
	input  wire [13:0] stat_rx_total_good_bytes,
	input  wire stat_rx_packet_small,
	input  wire stat_rx_jabber,
	input  wire stat_rx_packet_large,
	input  wire stat_rx_oversize,
	input  wire stat_rx_undersize,
	input  wire stat_rx_toolong,
	input  wire stat_rx_fragment,
	input  wire stat_rx_packet_64_bytes,
	input  wire stat_rx_packet_65_127_bytes,
	input  wire stat_rx_packet_128_255_bytes,
	input  wire stat_rx_packet_256_511_bytes,
	input  wire stat_rx_packet_512_1023_bytes,
	input  wire stat_rx_packet_1024_1518_bytes,
	input  wire stat_rx_packet_1519_1522_bytes,
	input  wire stat_rx_packet_1523_1548_bytes,
	input  wire [1:0] stat_rx_bad_fcs,
	input  wire stat_rx_packet_bad_fcs,
	input  wire [1:0] stat_rx_stomped_fcs,
	input  wire stat_rx_packet_1549_2047_bytes,
	input  wire stat_rx_packet_2048_4095_bytes,
	input  wire stat_rx_packet_4096_8191_bytes,
	input  wire stat_rx_packet_8192_9215_bytes,
	input  wire stat_rx_bad_preamble,
	input  wire stat_rx_bad_sfd,
	input  wire stat_rx_got_signal_os,
	input  wire stat_rx_test_pattern_mismatch,
	input  wire	 stat_rx_truncated,
	input  wire stat_rx_local_fault,
	input  wire stat_rx_remote_fault,
	input  wire stat_rx_internal_local_fault,
	input  wire stat_rx_received_local_fault,

	// TX Stat
	input  wire stat_tx_total_packets,
	input  wire [3:0] stat_tx_total_bytes,
	input  wire stat_tx_total_good_packets,
	input  wire [13:0] stat_tx_total_good_bytes,
	input  wire stat_tx_packet_64_bytes,
	input  wire stat_tx_packet_65_127_bytes,
	input  wire stat_tx_packet_128_255_bytes,
	input  wire stat_tx_packet_256_511_bytes,
	input  wire stat_tx_packet_512_1023_bytes,
	input  wire stat_tx_packet_1024_1518_bytes,
	input  wire stat_tx_packet_1519_1522_bytes,
	input  wire stat_tx_packet_1523_1548_bytes,
	input  wire stat_tx_packet_small,
	input  wire stat_tx_packet_large,
	input  wire stat_tx_packet_1549_2047_bytes,
	input  wire stat_tx_packet_2048_4095_bytes,
	input  wire stat_tx_packet_4096_8191_bytes,
	input  wire stat_tx_packet_8192_9215_bytes,
	input  wire stat_tx_bad_fcs,
	input  wire stat_tx_frame_error,
	input  wire stat_tx_local_fault
);

	wire [4:0] completion_status_int;
	wire stat_rx_aligned;
	wire stat_rx_synced;
	wire stat_rx_block_lock_sync;
	wire rx_block_lock_sync;

	// AXI4 Lite interface ports
	wire axi_fsm_restart;
	assign s_axi_aclk	= dclk;
	assign s_axi_aresetn	= ~sys_reset;
	assign pm_tick		= 1'b0;

	xxv_ethernet_0_axi4_lite_user_if u_axi4_lite_sm
	(
		.s_axi_aclk (s_axi_aclk),
		.s_axi_sreset (~s_axi_aresetn ),
		.stat_rx_aligned (stat_rx_block_lock),
		.rx_gt_locked(~rx_reset),
		.restart (axi_fsm_restart),
		.completion_status (completion_status),
		.s_axi_pm_tick (pm_tick),
		.s_axi_awaddr (s_axi_awaddr),
		.s_axi_awvalid (s_axi_awvalid),
		.s_axi_awready (s_axi_awready),
		.s_axi_wdata (s_axi_wdata),
		.s_axi_wstrb (s_axi_wstrb),
		.s_axi_wvalid (s_axi_wvalid),
		.s_axi_wready (s_axi_wready),
		.s_axi_bresp (s_axi_bresp),
		.s_axi_bvalid (s_axi_bvalid),
		.s_axi_bready (s_axi_bready),
		.s_axi_araddr (s_axi_araddr),
		.s_axi_arvalid (s_axi_arvalid),
		.s_axi_arready (s_axi_arready),
		.s_axi_rdata (s_axi_rdata),
		.s_axi_rresp (s_axi_rresp),
		.s_axi_rvalid (s_axi_rvalid),
		.s_axi_rready (s_axi_rready),
		.stat_reg_compare ()
	);

	/*
	 * Not sure what they meant
	 * Derived from original code without change
	 */
	assign ctl_tx_send_rfi	= 1'b0;
	assign ctl_tx_send_lfi	= 1'b0;
	assign ctl_tx_send_idle	= 1'b0;

	// RX TX AXIS Related Outputs
	assign tx_reset		= 1'b0;
	assign rx_reset		= 1'b0;
	assign tx_preamblein	= 56'b0;

	assign stat_rx_status	= stat_rx_block_lock_sync;
	assign stat_rx_aligned	= stat_rx_block_lock_sync;
	assign stat_rx_synced	= stat_rx_block_lock_sync;

	user_cdc_sync i_block_lock_syncer (
		.clk                 (dclk),
		.signal_in           (stat_rx_block_lock),
		.signal_out          (stat_rx_block_lock_sync)
	);

	user_cdc_sync i_block_lock_syncer_gen (
		.clk                 (gen_clk),
		.signal_in           (stat_rx_block_lock),
		.signal_out          (rx_block_lock_sync)
	);

	FSM_AXIS i_EXAMPLE_FSM  (
		  /* Input to fsm */
		  .dclk                        (dclk),
		  .fsm_reset                   (sys_reset | axi_fsm_restart ),
		  .stat_rx_block_lock          (stat_rx_block_lock_sync),
		  .stat_rx_synced              (stat_rx_synced),
		  .stat_rx_aligned             (stat_rx_aligned),
		  .stat_rx_status              (stat_rx_status),

		  // Output from fsm
		  // - fsm_out_pktgen_enable: wait until its is 1
		  //   before sending out any packets.
		  // - fsm_out_sys_reset:
		  .sys_reset                   (fsm_out_sys_reset),
		  .pktgen_enable               (fsm_out_pktgen_enable),
		  .completion_status           (completion_status_int)
	);

	  always @(posedge dclk, posedge sys_reset)
	  begin
	      if (sys_reset == 1'b1)
	      begin
		  completion_status    <= 5'b0;
	      end else
	      begin
		  completion_status    <= completion_status_int;
	      end
	  end

	// Now deal with gt_locked and block_lock signals
	gen_lock_signals u_gen_lock (
		.rx_clk			(mon_clk),
		.tx_resetn		(user_tx_reset),
		.rx_resetn		(user_rx_reset),
		.sys_reset		(sys_reset),
		.stat_rx_block_lock	(stat_rx_block_lock),
		.rx_gt_locked_led	(rx_gt_locked_led),
		.rx_block_lock_led	(rx_block_lock_led)
	);
endmodule

module gen_lock_signals
(
	input wire	rx_clk,
	input wire	tx_resetn,
	input wire	rx_resetn,
	input wire	sys_reset,
	input wire	stat_rx_block_lock,

	output wire	rx_gt_locked_led,
	output reg	rx_block_lock_led
);

	reg	rx_gt_locked_led_int;
	reg	rx_gt_locked_led_1d;
	reg	rx_gt_locked_led_2d;
	reg	rx_gt_locked_led_3d;
	reg	rx_block_lock_led_1d;
	reg	rx_block_lock_led_2d;
	reg	rx_block_lock_led_3d;

	wire	rx_block_lock;
	assign	rx_block_lock		= stat_rx_block_lock;
	assign	rx_gt_locked_led	= ~tx_resetn & rx_gt_locked_led_int;

	always @( posedge rx_clk )
	begin
		if (rx_resetn == 1'b1 )
		begin
			rx_gt_locked_led_1d     <= 1'b0;
			rx_gt_locked_led_2d     <= 1'b0;
			rx_gt_locked_led_3d     <= 1'b0;
			rx_block_lock_led_1d    <= 1'b0;
			rx_block_lock_led_2d    <= 1'b0;
			rx_block_lock_led_3d    <= 1'b0;
		end
		else begin
			rx_gt_locked_led_1d     <= ~rx_resetn;
			rx_gt_locked_led_2d     <= rx_gt_locked_led_1d;
			rx_gt_locked_led_3d     <= rx_gt_locked_led_2d;
			rx_block_lock_led_1d    <= rx_block_lock;
			rx_block_lock_led_2d    <= rx_block_lock_led_1d;
			rx_block_lock_led_3d    <= rx_block_lock_led_2d;
		end
	end

	always @(posedge rx_clk, posedge sys_reset)
	begin
		if (sys_reset == 1'b1 )
		begin
			rx_gt_locked_led_int     <= 1'b0;
			rx_block_lock_led        <= 1'b0;
		end else
		begin
			rx_gt_locked_led_int     <= rx_gt_locked_led_3d;
			rx_block_lock_led        <= rx_block_lock_led_3d;
		end
	end
endmodule

module FSM_AXIS
#( 
	parameter VL_LANES_PER_GENERATOR = 1
)
(
	input wire dclk,
	input wire fsm_reset,
	input wire [VL_LANES_PER_GENERATOR-1:0] stat_rx_block_lock,
	input wire [VL_LANES_PER_GENERATOR-1:0] stat_rx_synced,
	input wire stat_rx_aligned,
	input wire stat_rx_status,

	output reg sys_reset,
	output reg pktgen_enable,
	output reg [4:0] completion_status
);

`ifdef SIM_SPEED_UP
	 parameter [31:0] STARTUP_TIME = 32'd5000;
`else
	 parameter [31:0] STARTUP_TIME = 32'd50_000;
`endif

	 parameter        GENERATOR_COUNT = 1;
	 parameter [4:0]   NO_START = {5{1'b1}},
			   TEST_START = 5'd0,
			   SUCCESSFUL_COMPLETION = 5'd1,
			   NO_BLOCK_LOCK = 5'd2,
			   PARTIAL_BLOCK_LOCK = 5'd3,
			   INCONSISTENT_BLOCK_LOCK = 5'd4,
			   NO_LANE_SYNC = 5'd5,
			   PARTIAL_LANE_SYNC = 5'd6,
			   INCONSISTENT_LANE_SYNC = 5'd7,
			   NO_ALIGN_OR_STATUS = 5'd8,
			   LOSS_OF_STATUS = 5'd9,
			   TX_TIMED_OUT = 5'd10,
			   NO_DATA_SENT = 5'd11,
			   SENT_COUNT_MISMATCH = 5'd12,
			   BYTE_COUNT_MISMATCH = 5'd13,
			   LBUS_PROTOCOL = 5'd14,
			   BIT_ERRORS_IN_DATA = 5'd15;

	/* Parameter definitions of STATE variables for 5 bit state machine */
	localparam [4:0]  S0 = 5'b00000,     // S0 = 0
			  S1 = 5'b00001,     // S1 = 1
			  S2 = 5'b00011,     // S2 = 3
			  S3 = 5'b00010,     // S3 = 2
			  S4 = 5'b00110,     // S4 = 6
			  S5 = 5'b00111,     // S5 = 7
			  S6 = 5'b00101,     // S6 = 5
			  S7 = 5'b00100,     // S7 = 4
			  S8 = 5'b01100,     // S8 = 12
			  S9 = 5'b01101,     // S9 = 13
			  S10 = 5'b01111,     // S10 = 15
			  S11 = 5'b01110,     // S11 = 14
			  S12 = 5'b01010,     // S12 = 10
			  S13 = 5'b01011,     // S13 = 11
			  S14 = 5'b01001,     // S14 = 9
			  S15 = 5'b01000,     // S15 = 8
			  S16 = 5'b11000,     // S16 = 24
			  S17 = 5'b11001;     // S17 = 25


	reg [4:0] state ;
	reg [31:0] common_timer;

	always @( posedge dclk )
	    begin
	      if ( fsm_reset == 1'b1 ) begin
		common_timer <= 0;
		state <= S0;
		sys_reset <= 1'b0 ;
		pktgen_enable <= 1'b0;
		completion_status <= NO_START ;
	      end
	      else begin :check_loop
		integer i;
		common_timer <= |common_timer ? common_timer - 1 : common_timer;

		case ( state )
		  S0: state <= S1;
		  S1: begin
`ifdef SIM_SPEED_UP
			common_timer <= cvt_us ( 32'd100 );	// If this is the example simulation then only wait for 100 us
`else
			common_timer <= cvt_us ( 32'd10_000 );	// Wait for 10ms...do nothing; settling time for MMCs, oscilators, QPLLs etc.
`endif
			completion_status <= TEST_START;
			state <= S2;
		      end
		  S2: state <= (|common_timer) ? S2 : S3;
		  S3: begin
			common_timer <= 3;
			sys_reset <= 1'b1;
			state <= S4;
		      end
		  S4: state <= (|common_timer) ? S4 : S5;
		  S5: begin
			common_timer <= cvt_us( 5 ); // Allow about 5 us for the reset to propagate into the downstream hardware
			sys_reset <= 1'b0;           // Clear the reset
			state <= S16;
		      end
		 S16: state <= (|common_timer) ? S16 : S17;
		 S17: begin
			common_timer <= cvt_us( STARTUP_TIME );            // Set 20ms wait period
			state <= S6;
		      end
		  S6: if(|common_timer) state <= |stat_rx_block_lock ? S7 : S6 ;
		      else begin
			state <= S15;
			completion_status <= NO_BLOCK_LOCK;
		      end
		  S7: if(|common_timer) state <= &stat_rx_block_lock ? S8 : S7 ;
		      else begin
			state <= S15;
			completion_status <= PARTIAL_BLOCK_LOCK;
		      end
		  S8: if(|common_timer) begin
			if( ~&stat_rx_block_lock ) begin
			  state <= S15;
			  completion_status <= INCONSISTENT_BLOCK_LOCK;
			end
			else state <= |stat_rx_synced ? S9 : S8 ;
		      end
		      else begin
			state <= S15;
			completion_status <= NO_LANE_SYNC;
		      end
		  S9: if(|common_timer) begin
			if( ~&stat_rx_block_lock ) begin
			  state <= S15;
			  completion_status <= INCONSISTENT_BLOCK_LOCK;
			end
			else state <= &stat_rx_synced ? S10 : S9 ;
		      end
		      else begin
			state <= S15;
			completion_status <= PARTIAL_LANE_SYNC;
		      end
		  S10: if(|common_timer) begin
			if( ~&stat_rx_block_lock ) begin
			  state <= S15;
			  completion_status <= INCONSISTENT_BLOCK_LOCK;
			end
			else if( ~&stat_rx_synced ) begin
			  state <= S15;
			  completion_status <= INCONSISTENT_LANE_SYNC;
			end
			else begin
			  state <= (stat_rx_aligned && stat_rx_status ) ? S11 : S10 ;
			end
		      end
		      else begin
			state <= S15;
			completion_status <= NO_ALIGN_OR_STATUS;
		      end
		  S11: begin
			 state <= S12;
	`ifdef SIM_SPEED_UP
			 common_timer <= cvt_us( 32'd50 );            // Set 50us wait period while aligned (simulation only )
	`else
			 common_timer <= cvt_us( 32'd1_000 );            // Set 1ms wait period while aligned
	`endif
		       end
		  S12: if(|common_timer) begin
			 if( ~&stat_rx_block_lock || ~&stat_rx_synced || ~stat_rx_aligned || ~stat_rx_status ) begin
			   state <= S15;
			   completion_status <= LOSS_OF_STATUS;
			 end
		       end
		       else begin
			state <= S13;
			pktgen_enable <= 1'b1;                          // Turn on the packet generator
	`ifdef SIM_SPEED_UP
			common_timer <= cvt_us( 32'd200 );            
	`else
			common_timer <= cvt_us( 32'd10_000 );
	`endif
		      end
		  S13: if(|common_timer) begin
			 if( ~&stat_rx_block_lock || ~&stat_rx_synced || ~stat_rx_aligned || ~stat_rx_status ) begin
			   state <= S15;
			   completion_status <= LOSS_OF_STATUS;
			 end
		       end
		       else state <= S14;
		  S14: begin
			 state <= S15;
			 completion_status <= SUCCESSFUL_COMPLETION;
		       end
		  S15: state <= S15;            // Finish and wait forever
		endcase
	      end
	    end

	function [31:0] cvt_us( input [31:0] d );
	cvt_us = ( ( d * 300 ) + 3 ) / 4 ;
	endfunction
endmodule

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

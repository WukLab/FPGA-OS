`define SIM_SPEED_UP

`timescale 1fs/1fs
(* DowngradeIPIdentifiedWarnings="yes" *)

module xxv_ethernet_0_pkt_gen_mon
(
  input                      gen_clk,
  input                      mon_clk,
  input                      dclk,
  input                      sys_reset,
  input                      send_continuous_pkts, 
  input wire                 restart_tx_rx,
  //// AXI4 Lite interface ports
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
//// RX Signals
  output wire         rx_reset,
  input  wire         user_rx_reset,
//// RX LBUS Signals
  input  wire rx_axis_tvalid,
  input  wire [63:0] rx_axis_tdata,
  input  wire rx_axis_tlast,
  input  wire [7:0] rx_axis_tkeep,
  input  wire rx_axis_tuser,
  input  wire [55:0] rx_preambleout,


//// RX Control Signals


//// RX Stats Signals
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
  input  wire stat_rx_truncated,
  input  wire stat_rx_local_fault,
  input  wire stat_rx_remote_fault,
  input  wire stat_rx_internal_local_fault,
  input  wire stat_rx_received_local_fault,


//// TX Signals
  output wire         tx_reset,
  input  wire         user_tx_reset,

//// TX LBUS Signals
  input  wire tx_axis_tready,
  output wire tx_axis_tvalid,
  output wire [63:0] tx_axis_tdata,
  output wire tx_axis_tlast,
  output wire [7:0] tx_axis_tkeep,
  output wire tx_axis_tuser,
  input  wire tx_unfout,
  output wire [55:0] tx_preamblein,

//// TX Control Signals
  output wire ctl_tx_send_lfi,
  output wire ctl_tx_send_rfi,
  output wire ctl_tx_send_idle,



//// TX Stats Signals
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
  input  wire stat_tx_local_fault,


    output reg  [4:0]  completion_status,
    output wire        rx_gt_locked_led,
    output wire        rx_block_lock_led
   );

  parameter PKT_NUM         = 20;    //// Many Internal Counters are based on PKT_NUM = 20
  parameter FIXED_PACKET_LENGTH = 256;
  parameter MIN_LENGTH          = 64;
  parameter MAX_LENGTH          = 9000;

  wire [2:0] data_pattern_select;
  wire insert_crc;
  wire [4:0] completion_status_int;
  wire stat_rx_aligned;
  wire stat_rx_synced;
  wire pktgen_enable;
  reg  pktgen_enable_int;
  wire pktgen_enable_sync;
  
  wire tx_total_bytes_overflow;
  wire tx_sent_overflow;
  wire [31:0] tx_packet_count;
  wire [47:0] tx_sent_count;
  reg  [47:0] tx_sent_count_int;
  wire [47:0] tx_sent_count_sync;
  wire [63:0] tx_total_bytes;
  reg  [63:0] tx_total_bytes_int;
  wire [63:0] tx_total_bytes_sync;
  wire tx_time_out;
  reg  tx_time_out_int;
  wire tx_time_out_sync;
  wire tx_done;
  reg  tx_done_int;
  wire tx_done_sync;

  wire stat_rx_block_lock_sync;
  wire [31:0] rx_error_count;
  wire [31:0] rx_prot_err_count; 
  wire [63:0] rx_total_bytes;
  reg  [63:0] rx_total_bytes_int;
  wire [63:0] rx_total_bytes_sync;
  wire [47:0] rx_packet_count;
  reg  [47:0] rx_packet_count_int;
  wire [47:0] rx_packet_count_sync;
  wire rx_packet_count_overflow;
  wire rx_total_bytes_overflow;
  wire rx_prot_err_overflow;
  wire rx_error_overflow;
  
  wire rx_errors;
  reg  rx_errors_int;
  wire rx_errors_sync;
  wire rx_block_lock_sync;
  wire [31:0] rx_data_err_count;
  wire rx_data_err;
  assign rx_data_err = |rx_data_err_count; 
  wire rx_data_err_overflow;


  //// AXI4 Lite interface ports
  assign s_axi_aclk = dclk;
  assign s_axi_aresetn = ~sys_reset;
  wire axi_fsm_restart;
  assign pm_tick = 1'b0;


 xxv_ethernet_0_axi4_lite_user_if	u_axi4_lite_user_if (
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

  assign rx_errors            = |rx_prot_err_count || |rx_error_count ;
  assign tx_packet_count      = send_continuous_pkts ? 32'hFFFFFFFF : PKT_NUM;
  assign stat_rx_status       = stat_rx_block_lock_sync ;
  assign stat_rx_aligned      = stat_rx_block_lock_sync ;
  assign stat_rx_synced       = stat_rx_block_lock_sync ;
  assign data_pattern_select  = 3'd0;
  assign clear_count          = 1'b0;
  assign insert_crc           = 1'b0;

xxv_ethernet_0_user_cdc_sync i_xxv_ethernet_0_core_cdc_sync_block_lock_syncer (
    .clk                 (dclk),
    .signal_in           (stat_rx_block_lock),
    .signal_out          (stat_rx_block_lock_sync)
  );

xxv_ethernet_0_user_cdc_sync i_xxv_ethernet_0_core_cdc_sync_block_lock_syncer_gen (
    .clk                 (gen_clk),
    .signal_in           (stat_rx_block_lock),
    .signal_out          (rx_block_lock_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_total_bytes_int  <= tx_total_bytes;
  end
  
xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (64)
  ) i_xxv_ethernet_2_tx_total_bytes_syncer (
    .clk          (dclk ),
    .signal_in    (tx_total_bytes_int),
    .signal_out   (tx_total_bytes_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_sent_count_int <= tx_sent_count;
  end

xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (48)
  ) i_xxv_ethernet_2_tx_packet_count_syncer (
    .clk          (dclk ),
    .signal_in    (tx_sent_count_int),
    .signal_out   (tx_sent_count_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_time_out_int   <= tx_time_out ;
  end

xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_xxv_ethernet_0_tx_time_out_syncer (
    .clk          (dclk ),
    .signal_in    (tx_time_out_int),
    .signal_out   (tx_time_out_sync)
  );

  always @(posedge gen_clk)
  begin
      tx_done_int       <= tx_done ;
  end

xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_xxv_ethernet_0_tx_done_syncer (
    .clk          (dclk ),
    .signal_in    (tx_done_int),
    .signal_out   (tx_done_sync)
  );

  always @(posedge mon_clk)
  begin
      rx_packet_count_int <= rx_packet_count;
  end

xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (48)
  ) i_xxv_ethernet_0_rx_packet_count_syncer (
    .clk          (dclk ),
    .signal_in    (rx_packet_count_int),
    .signal_out   (rx_packet_count_sync)
  );

  always @(posedge mon_clk)
  begin
      rx_total_bytes_int  <= rx_total_bytes;
  end

xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (64)
  ) i_xxv_ethernet_0_rx_total_bytes_syncer (
    .clk          (dclk ),
    .signal_in    (rx_total_bytes_int),
    .signal_out   (rx_total_bytes_sync)
  );

  always @(posedge mon_clk)
  begin
      rx_errors_int       <= rx_errors;
  end

xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_xxv_ethernet_0_rx_errors_syncer (
    .clk          (dclk ),
    .signal_in    (rx_errors_int),
    .signal_out   (rx_errors_sync)
  );


  reg rx_data_err_reg;

  always@ (posedge mon_clk)
  begin
      rx_data_err_reg <= rx_data_err;
  end

  wire rx_data_err_sync;
xxv_ethernet_0_cdc_sync_2stage 
  #(
    .WIDTH        (1)
  ) i_xxv_ethernet_0_rx_data_err_syncer (
    .clk          (dclk ),
    .signal_in    (rx_data_err_reg),
    .signal_out   (rx_data_err_sync)
  );

  wire pktgen_enable_tmp;
  assign pktgen_enable_tmp = send_continuous_pkts ? send_continuous_pkts : pktgen_enable;

  always@ (posedge dclk)
  begin
      pktgen_enable_int <= pktgen_enable_tmp;
  end

xxv_ethernet_0_user_cdc_sync i_xxv_ethernet_0_core_cdc_sync_pkt_gen_enable (
    .clk                 (gen_clk),
    .signal_in           (pktgen_enable_int),
    .signal_out          (pktgen_enable_sync)
);

	xxv_ethernet_0_example_fsm_axis i_EXAMPLE_FSM  (
		  .dclk                        (dclk),
		  .fsm_reset                   (sys_reset | restart_tx_rx | axi_fsm_restart ),
		  .stat_rx_block_lock          (stat_rx_block_lock_sync),
		  .stat_rx_synced              (stat_rx_synced),
		  .stat_rx_aligned             (stat_rx_aligned),
		  .stat_rx_status              (stat_rx_status),
		  .tx_timeout                  (tx_time_out_sync),
		  .tx_done                     (tx_done_sync),
		  .ok_to_start                 (1'b1),
		  .rx_packet_count             (rx_packet_count_sync),
		  .rx_total_bytes              (rx_total_bytes_sync),
		  .rx_errors                   (rx_errors_sync),
		  .rx_data_errors              (rx_data_err_sync),
		  .tx_sent_count               (tx_sent_count_sync),
		  .tx_total_bytes              (tx_total_bytes_sync),
		  .sys_reset                   (   ),
		  .pktgen_enable               (pktgen_enable),
		  .completion_status           (completion_status_int)
	);

  always @( posedge dclk, posedge sys_reset  )
  begin
      if ( sys_reset == 1'b1 )
      begin
          completion_status    <= 5'b0;
      end
      else
      begin
          completion_status    <= completion_status_int;
      end
  end

xxv_ethernet_0_axis_traffic_gen_mon #(
  .FIXED_PACKET_LENGTH ( FIXED_PACKET_LENGTH ),
  .MIN_LENGTH     ( MIN_LENGTH ),
  .MAX_LENGTH     ( MAX_LENGTH )
) i_xxv_ethernet_0_TRAFFIC_GENERATOR (
	.tx_clk (gen_clk),
	.tx_resetn (user_tx_reset || restart_tx_rx),
	.rx_clk (mon_clk),
	.rx_resetn (user_rx_reset || restart_tx_rx),
	.sys_reset (sys_reset),
	.pktgen_enable (pktgen_enable_sync),

	.rx_reset (rx_reset),
	.tx_reset (tx_reset),
	.insert_crc (insert_crc),
	.tx_packet_count (tx_packet_count),
	.clear_count (clear_count),

	// RX LBUS Signals
	.rx_axis_tvalid (rx_axis_tvalid),
	.rx_axis_tdata (rx_axis_tdata),
	.rx_axis_tlast (rx_axis_tlast),
	.rx_axis_tkeep (rx_axis_tkeep),
	.rx_axis_tuser (rx_axis_tuser),
	.rx_preambleout (rx_preambleout),

	.rx_lane_align (rx_block_lock_sync),

	// TX LBUS Signals
	.tx_axis_tready (tx_axis_tready),
	.tx_axis_tvalid (tx_axis_tvalid),
	.tx_axis_tdata (tx_axis_tdata),
	.tx_axis_tlast (tx_axis_tlast),
	.tx_axis_tkeep (tx_axis_tkeep),
	.tx_axis_tuser (tx_axis_tuser),
	.tx_unfout (tx_unfout),
	.tx_preamblein (tx_preamblein),
	.tx_time_out (tx_time_out),
	.tx_done (tx_done),
	.rx_protocol_error (rx_protocol_error),
	.rx_packet_count (rx_packet_count),
	.rx_total_bytes (rx_total_bytes),
	.rx_prot_err_count (rx_prot_err_count),
	.rx_error_count (rx_error_count),
	.rx_packet_count_overflow (rx_packet_count_overflow),
	.rx_total_bytes_overflow (rx_total_bytes_overflow),
	.rx_prot_err_overflow (rx_prot_err_overflow),
	.rx_error_overflow (rx_error_overflow),
	.tx_sent_count (tx_sent_count),
	.tx_sent_overflow (tx_sent_overflow),
	.tx_total_bytes (tx_total_bytes),
	.tx_total_bytes_overflow (tx_total_bytes_overflow),
	.rx_data_err_count (rx_data_err_count),
	.rx_data_err_overflow (rx_data_err_overflow),
	.rx_gt_locked_led (rx_gt_locked_led),
	.rx_block_lock_led (rx_block_lock_led),

	// TX Control Signals
	.ctl_tx_send_lfi (ctl_tx_send_lfi),
	.ctl_tx_send_rfi (ctl_tx_send_rfi),
	.ctl_tx_send_idle (ctl_tx_send_idle),

	// RX Stats Signals
	.stat_rx_block_lock (stat_rx_block_lock),
	.stat_rx_framing_err_valid (stat_rx_framing_err_valid),
	.stat_rx_framing_err (stat_rx_framing_err),
	.stat_rx_hi_ber (stat_rx_hi_ber),
	.stat_rx_valid_ctrl_code (stat_rx_valid_ctrl_code),
	.stat_rx_bad_code (stat_rx_bad_code),
	.stat_rx_total_packets (stat_rx_total_packets),
	.stat_rx_total_good_packets (stat_rx_total_good_packets),
	.stat_rx_total_bytes (stat_rx_total_bytes),
	.stat_rx_total_good_bytes (stat_rx_total_good_bytes),
	.stat_rx_packet_small (stat_rx_packet_small),
	.stat_rx_jabber (stat_rx_jabber),
	.stat_rx_packet_large (stat_rx_packet_large),
	.stat_rx_oversize (stat_rx_oversize),
	.stat_rx_undersize (stat_rx_undersize),
	.stat_rx_toolong (stat_rx_toolong),
	.stat_rx_fragment (stat_rx_fragment),
	.stat_rx_packet_64_bytes (stat_rx_packet_64_bytes),
	.stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes),
	.stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes),
	.stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes),
	.stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes),
	.stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes),
	.stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes),
	.stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes),
	.stat_rx_bad_fcs (stat_rx_bad_fcs),
	.stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs),
	.stat_rx_stomped_fcs (stat_rx_stomped_fcs),
	.stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes),
	.stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes),
	.stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes),
	.stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes),
	.stat_rx_bad_preamble (stat_rx_bad_preamble),
	.stat_rx_bad_sfd (stat_rx_bad_sfd),
	.stat_rx_got_signal_os (stat_rx_got_signal_os),
	.stat_rx_test_pattern_mismatch (stat_rx_test_pattern_mismatch),
	.stat_rx_truncated (stat_rx_truncated),
	.stat_rx_local_fault (stat_rx_local_fault),
	.stat_rx_remote_fault (stat_rx_remote_fault),
	.stat_rx_internal_local_fault (stat_rx_internal_local_fault),
	.stat_rx_received_local_fault (stat_rx_received_local_fault),

	// TX Stats Signals
	.stat_tx_total_packets (stat_tx_total_packets),
	.stat_tx_total_bytes (stat_tx_total_bytes),
	.stat_tx_total_good_packets (stat_tx_total_good_packets),
	.stat_tx_total_good_bytes (stat_tx_total_good_bytes),
	.stat_tx_packet_64_bytes (stat_tx_packet_64_bytes),
	.stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes),
	.stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes),
	.stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes),
	.stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes),
	.stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes),
	.stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes),
	.stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes),
	.stat_tx_packet_small (stat_tx_packet_small),
	.stat_tx_packet_large (stat_tx_packet_large),
	.stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes),
	.stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes),
	.stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes),
	.stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes),
	.stat_tx_bad_fcs (stat_tx_bad_fcs),
	.stat_tx_frame_error (stat_tx_frame_error),
	.stat_tx_local_fault (stat_tx_local_fault),
	.stat_tx_block_lock (rx_block_lock_sync)
);

endmodule


(* DowngradeIPIdentifiedWarnings="yes" *)
module xxv_ethernet_0_cdc_sync_2stage
#(
 parameter WIDTH  = 1
)
(
 input  clk,
 input  [WIDTH-1:0] signal_in,
 output wire [WIDTH-1:0]  signal_out
);

                          wire [WIDTH-1:0] sig_in_cdc_from;
 (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] s_out_d2_cdc_to;
 (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] data_out_d3;

assign sig_in_cdc_from = signal_in;
assign signal_out      = data_out_d3;

always @(posedge clk) 
begin
  s_out_d2_cdc_to  <= sig_in_cdc_from;
  data_out_d3      <= s_out_d2_cdc_to;
end

endmodule

(* DowngradeIPIdentifiedWarnings="yes" *)
  module xxv_ethernet_0_user_cdc_sync (
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

module xxv_ethernet_0_axis_traffic_gen_mon (
  input  wire tx_clk,
  input  wire rx_clk,
  input  wire tx_resetn,
  input  wire rx_resetn,
  input  wire sys_reset,

//// RX Control Signals


//// RX Stats Signals
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
  input  wire stat_rx_truncated,
  input  wire stat_rx_local_fault,
  input  wire stat_rx_remote_fault,
  input  wire stat_rx_internal_local_fault,
  input  wire stat_rx_received_local_fault,

//// TX Control Signals
  output wire ctl_tx_send_lfi,
  output wire ctl_tx_send_rfi,
  output wire ctl_tx_send_idle,


//// TX Stats Signals
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
  input  wire stat_tx_local_fault,

  input wire stat_tx_block_lock,
  input  pktgen_enable,
  output wire tx_reset,
  output wire rx_reset,
  input  wire insert_crc,
  input  wire [31:0] tx_packet_count,
  input  wire clear_count,
//// RX LBUS Signals
  input  wire rx_axis_tvalid,
  input  wire [63:0] rx_axis_tdata,
  input  wire rx_axis_tlast,
  input  wire [7:0] rx_axis_tkeep,
  input  wire rx_axis_tuser,
  input  wire [55:0] rx_preambleout,

  input  wire rx_lane_align,
//// TX LBUS Signals
  input  wire tx_axis_tready,
  output reg tx_axis_tvalid,
  output reg [63:0] tx_axis_tdata,
  output reg tx_axis_tlast,
  output reg [7:0] tx_axis_tkeep,
  output reg tx_axis_tuser,
  output wire [55:0] tx_preamblein,
  input  wire tx_unfout,

  output wire tx_time_out,
  output wire tx_done,
  output wire rx_protocol_error,
  output wire [47:0] rx_packet_count,
  output wire [63:0] rx_total_bytes,
  output wire [31:0] rx_prot_err_count,
  output wire [31:0] rx_error_count,
  output wire rx_packet_count_overflow,
  output wire rx_total_bytes_overflow,
  output wire rx_prot_err_overflow,
  output wire rx_error_overflow,
  output wire [47:0] tx_sent_count,
  output wire tx_sent_overflow,
  output wire [63:0] tx_total_bytes,
  output wire tx_total_bytes_overflow,
  output wire [31:0] rx_data_err_count,
  output wire rx_data_err_overflow,
  output wire rx_gt_locked_led,
  output wire rx_block_lock_led

);
  parameter FIXED_PACKET_LENGTH = 9_000;
  parameter MIN_LENGTH          = 64;
  parameter MAX_LENGTH          = 9000;

  wire tx_enain;
  wire tx_sopin;
  wire [64-1:0] tx_datain;
  wire tx_eopin;
  wire [3-1:0] tx_mtyin;
  wire tx_errin;
  wire tx_rdyout;
  wire tx_ovfout = 1'b0;

  wire fifo_tx_enain;
  wire fifo_tx_sopin;
  wire [64-1:0] fifo_tx_datain;
  wire fifo_tx_eopin;
  wire [3-1:0] fifo_tx_mtyin;
  wire fifo_tx_errin;
  wire loc_traf_tx_busy;
  wire rx_gt_locked_led_int;

  // RX
  reg [64-1:0] rx_dataout;
  reg rx_enaout;
  reg rx_sopout;
  reg rx_eopout;
  reg rx_errout;
  reg [3-1:0] rx_mtyout;
  reg rx_inframe_r;
assign rx_gt_locked_led = ~tx_resetn & rx_gt_locked_led_int;
assign  tx_preamblein        = 56'b0;

xxv_ethernet_0_axis_pkt_gen i_PKT_GEN  (
	// Generator to send 1 packet
	  .clk ( tx_clk ),
	  .reset ( tx_resetn ),
	  .enable ( pktgen_enable ),
	  .tx_rdyout ( tx_rdyout ),
	  .tx_ovfout ( tx_ovfout ),
	  .rx_lane_align ( rx_lane_align ),
	  .packet_count ( tx_packet_count ),
	  .insert_crc ( insert_crc ),
	  .tx_reset ( tx_reset ),

	  .tx_datain ( tx_datain ),
	  .tx_enain ( tx_enain ),
	  .tx_sopin ( tx_sopin ),
	  .tx_eopin ( tx_eopin ),
	  .tx_errin ( tx_errin ),
	  .tx_mtyin ( tx_mtyin ),
	  .time_out ( tx_time_out ),
	  .busy ( loc_traf_tx_busy),
	  .done ( tx_done ),

	//// TX Control Signals
	  .ctl_tx_send_lfi (ctl_tx_send_lfi),
	  .ctl_tx_send_rfi (ctl_tx_send_rfi),
	  .ctl_tx_send_idle (ctl_tx_send_idle),

	//// TX Stats Signals
	  .stat_tx_total_packets (stat_tx_total_packets),
	  .stat_tx_total_bytes (stat_tx_total_bytes),
	  .stat_tx_total_good_packets (stat_tx_total_good_packets),
	  .stat_tx_total_good_bytes (stat_tx_total_good_bytes),
	  .stat_tx_packet_64_bytes (stat_tx_packet_64_bytes),
	  .stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes),
	  .stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes),
	  .stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes),
	  .stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes),
	  .stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes),
	  .stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes),
	  .stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes),
	  .stat_tx_packet_small (stat_tx_packet_small),
	  .stat_tx_packet_large (stat_tx_packet_large),
	  .stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes),
	  .stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes),
	  .stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes),
	  .stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes),
	  .stat_tx_bad_fcs (stat_tx_bad_fcs),
	  .stat_tx_frame_error (stat_tx_frame_error),
	  .stat_tx_local_fault (stat_tx_local_fault)
);

xxv_ethernet_0_axis_pkt_mon  
#(  .MIN_LENGTH (MIN_LENGTH),
    .MAX_LENGTH (MAX_LENGTH)
  )	i_PKT_CHK(

	  .clk ( rx_clk ),
	  .reset ( rx_resetn ),
	  .clear_count ( clear_count ),
	  .sys_reset ( sys_reset ),
	//// RX LBUS Signals

	  .rx_dataout ( rx_dataout ),
	  .rx_enaout ( rx_enaout ),
	  .rx_sopout ( rx_sopout ),
	  .rx_eopout ( rx_eopout ),
	  .rx_errout ( rx_errout ),
	  .rx_mtyout ( rx_mtyout ),
	//// RX Control Signals


	//// RX Stats Signals
	  .stat_rx_block_lock (stat_rx_block_lock),
	  .stat_rx_framing_err_valid (stat_rx_framing_err_valid),
	  .stat_rx_framing_err (stat_rx_framing_err),
	  .stat_rx_hi_ber (stat_rx_hi_ber),
	  .stat_rx_valid_ctrl_code (stat_rx_valid_ctrl_code),
	  .stat_rx_bad_code (stat_rx_bad_code),
	  .stat_rx_total_packets (stat_rx_total_packets),
	  .stat_rx_total_good_packets (stat_rx_total_good_packets),
	  .stat_rx_total_bytes (stat_rx_total_bytes),
	  .stat_rx_total_good_bytes (stat_rx_total_good_bytes),
	  .stat_rx_packet_small (stat_rx_packet_small),
	  .stat_rx_jabber (stat_rx_jabber),
	  .stat_rx_packet_large (stat_rx_packet_large),
	  .stat_rx_oversize (stat_rx_oversize),
	  .stat_rx_undersize (stat_rx_undersize),
	  .stat_rx_toolong (stat_rx_toolong),
	  .stat_rx_fragment (stat_rx_fragment),
	  .stat_rx_packet_64_bytes (stat_rx_packet_64_bytes),
	  .stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes),
	  .stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes),
	  .stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes),
	  .stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes),
	  .stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes),
	  .stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes),
	  .stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes),
	  .stat_rx_bad_fcs (stat_rx_bad_fcs),
	  .stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs),
	  .stat_rx_stomped_fcs (stat_rx_stomped_fcs),
	  .stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes),
	  .stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes),
	  .stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes),
	  .stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes),
	  .stat_rx_bad_preamble (stat_rx_bad_preamble),
	  .stat_rx_bad_sfd (stat_rx_bad_sfd),
	  .stat_rx_got_signal_os (stat_rx_got_signal_os),
	  .stat_rx_test_pattern_mismatch (stat_rx_test_pattern_mismatch),
	  .stat_rx_truncated (stat_rx_truncated),
	  .stat_rx_local_fault (stat_rx_local_fault),
	  .stat_rx_remote_fault (stat_rx_remote_fault),
	  .stat_rx_internal_local_fault (stat_rx_internal_local_fault),
	  .stat_rx_received_local_fault (stat_rx_received_local_fault),


	  .rx_reset ( rx_reset ),
	  .protocol_error ( rx_protocol_error ),
	  .packet_count ( rx_packet_count ),
	  .total_bytes ( rx_total_bytes ),
	  .prot_err_count ( rx_prot_err_count ),
	  .error_count ( rx_error_count ),
	  .packet_count_overflow ( rx_packet_count_overflow ),
	  .total_bytes_overflow ( rx_total_bytes_overflow ),
	  .prot_err_overflow ( rx_prot_err_overflow ),
	  .error_overflow ( rx_error_overflow ),
	  .rx_gt_locked_led (rx_gt_locked_led_int),
	  .rx_block_lock_led (rx_block_lock_led)
);

  always @( posedge rx_clk  )
    begin
      if ( rx_resetn == 1'b1 )
     begin
        rx_mtyout <= 'b0;
        rx_enaout <= 'b0;
        rx_eopout <= 'b0;
        rx_sopout <= 'b0;
        rx_errout <= 'b0;
        rx_dataout <= 'b0;
        rx_inframe_r <= 'b0;
     end else
     begin
        rx_mtyout <= 'd0;
        case (rx_axis_tkeep)
          ({8{1'b1}} >> 0) : rx_mtyout <= 0;
          ({8{1'b1}} >> 1) : rx_mtyout <= 1;
          ({8{1'b1}} >> 2) : rx_mtyout <= 2;
          ({8{1'b1}} >> 3) : rx_mtyout <= 3;
          ({8{1'b1}} >> 4) : rx_mtyout <= 4;
          ({8{1'b1}} >> 5) : rx_mtyout <= 5;
          ({8{1'b1}} >> 6) : rx_mtyout <= 6;
          ({8{1'b1}} >> 7) : rx_mtyout <= 7;
        endcase
        if ( rx_inframe_r == 1'b0 ) begin
           rx_inframe_r <= rx_axis_tvalid;
           rx_sopout <= rx_axis_tvalid;
        end else begin
           rx_inframe_r <= ~(rx_axis_tlast && rx_axis_tvalid);
           rx_sopout <= 'b0;
        end
        rx_eopout  <= rx_axis_tlast;
        rx_enaout  <= rx_axis_tvalid;
        rx_eopout  <= rx_axis_tlast;
        rx_errout  <= rx_axis_tuser;
        rx_dataout[(8-1-0)*8+:8] <= rx_axis_tdata[0*8+:8];
        rx_dataout[(8-1-1)*8+:8] <= rx_axis_tdata[1*8+:8];
        rx_dataout[(8-1-2)*8+:8] <= rx_axis_tdata[2*8+:8];
        rx_dataout[(8-1-3)*8+:8] <= rx_axis_tdata[3*8+:8];
        rx_dataout[(8-1-4)*8+:8] <= rx_axis_tdata[4*8+:8];
        rx_dataout[(8-1-5)*8+:8] <= rx_axis_tdata[5*8+:8];
        rx_dataout[(8-1-6)*8+:8] <= rx_axis_tdata[6*8+:8];
        rx_dataout[(8-1-7)*8+:8] <= rx_axis_tdata[7*8+:8];
    end
  end

 always @*
  begin

    tx_axis_tdata[(8-1-0)*8+:8] = fifo_tx_datain[0*8+:8];
    tx_axis_tdata[(8-1-1)*8+:8] = fifo_tx_datain[1*8+:8];
    tx_axis_tdata[(8-1-2)*8+:8] = fifo_tx_datain[2*8+:8];
    tx_axis_tdata[(8-1-3)*8+:8] = fifo_tx_datain[3*8+:8];
    tx_axis_tdata[(8-1-4)*8+:8] = fifo_tx_datain[4*8+:8];
    tx_axis_tdata[(8-1-5)*8+:8] = fifo_tx_datain[5*8+:8];
    tx_axis_tdata[(8-1-6)*8+:8] = fifo_tx_datain[6*8+:8];
    tx_axis_tdata[(8-1-7)*8+:8] = fifo_tx_datain[7*8+:8];
    tx_axis_tvalid = fifo_tx_enain; // keep valid.
    tx_axis_tlast  = fifo_tx_eopin;
    tx_axis_tuser  = fifo_tx_eopin && fifo_tx_errin;

    case (fifo_tx_mtyin)
      0 : tx_axis_tkeep = {8{1'b1}} >> 0;
      1 : tx_axis_tkeep = {8{1'b1}} >> 1;
      2 : tx_axis_tkeep = {8{1'b1}} >> 2;
      3 : tx_axis_tkeep = {8{1'b1}} >> 3;
      4 : tx_axis_tkeep = {8{1'b1}} >> 4;
      5 : tx_axis_tkeep = {8{1'b1}} >> 5;
      6 : tx_axis_tkeep = {8{1'b1}} >> 6;
      7 : tx_axis_tkeep = {8{1'b1}} >> 7;
    endcase

  end

  xxv_ethernet_0_buf #(
      .IS_0_LATENCY ( 1 )
  ) i_xxv_ethernet_0_axi_fifo (

     .clk ( tx_clk ),
     .reset ( tx_resetn ),

     .tx_datain( tx_datain),
     .tx_enain ( tx_enain ),
     .tx_sopin ( tx_sopin ),
     .tx_eopin ( tx_eopin ),
     .tx_errin ( tx_errin ),
     .tx_mtyin ( tx_mtyin ),

     .tx_dataout( fifo_tx_datain),
     .tx_enaout ( fifo_tx_enain ),
     .tx_sopout ( fifo_tx_sopin ),
     .tx_eopout ( fifo_tx_eopin ),
     .tx_errout ( fifo_tx_errin ),
     .tx_mtyout ( fifo_tx_mtyin ),
     .tx_rdyin  ( tx_axis_tready ),
     .tx_rdyout ( tx_rdyout )
  );

xxv_ethernet_0_traf_chk1 i_xxv_ethernet_0_TRAF_CHK2 (                         // Counter for packets sent

  .clk ( tx_clk ),
  .reset ( tx_resetn ),
  .enable ( pktgen_enable || loc_traf_tx_busy ),
  .clear_count ( clear_count ),

  .rx_dataout ( tx_datain ),
  .rx_enaout ( tx_enain ),
  .rx_sopout ( tx_sopin ),
  .rx_eopout ( tx_eopin ),
  .rx_errout ( tx_errin ),
  .rx_mtyout ( tx_mtyin ),
  .protocol_error ( ),
  .packet_count ( tx_sent_count ),
  .total_bytes ( tx_total_bytes ),
  .prot_err_count ( ),
  .error_count ( ),
  .packet_count_overflow ( tx_sent_overflow ),
  .total_bytes_overflow ( tx_total_bytes_overflow ),
  .prot_err_overflow ( ),
  .error_overflow ( )
);

xxv_ethernet_0_traf_data_chk i_xxv_ethernet_0_TRAF_DATA_CHK (

  .clk ( rx_clk ),
  .reset ( rx_resetn ),
  .clear_count ( clear_count ),
  .enable ( 1'b1 ),

  .rx_dataout ( rx_dataout ),
  .rx_enaout ( rx_enaout ),
  .rx_sopout ( rx_sopout ),
  .rx_eopout ( rx_eopout ),
  .rx_errout ( rx_errout ),
  .rx_mtyout ( rx_mtyout ),

  .error_count ( rx_data_err_count ),
  .error_overflow ( rx_data_err_overflow )
);

endmodule

module xxv_ethernet_0_buf (
  input  wire clk,
  input  wire reset,
  input wire [63:0] tx_datain,
  input wire tx_enain,
  input wire tx_sopin,
  input wire tx_eopin,
  input wire tx_errin,
  input wire [2:0] tx_mtyin,

  output wire [63:0] tx_dataout,
  output wire tx_enaout,
  output wire tx_sopout,
  output wire tx_eopout,
  output wire tx_errout,
  output wire [2:0] tx_mtyout,
  input  wire tx_rdyin,
  output  reg tx_rdyout
);

parameter integer IS_0_LATENCY = 0;                      // default to single cycle latency
reg [70:0] rd_buf[0:7];
reg [2:0] waddr;

generate
if ( IS_0_LATENCY ) begin               // If this is a zero latency implementation

reg [2:0] waddr_p1;


wire my_tx_enaout;
assign { tx_dataout, my_tx_enaout, tx_sopout, tx_eopout, tx_errout, tx_mtyout } = rd_buf[0];
assign tx_enaout = my_tx_enaout;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        waddr <= 3'h0;
        waddr_p1 <= 3'h1;
        tx_rdyout <= 0;
        for(i=0;i<8;i=i+1) rd_buf[i] <= 71'h0;
      end
      else begin

        if(tx_rdyin) for(i=1;i<8;i=i+1) rd_buf[i-1] <= rd_buf[i];

        tx_rdyout <= (waddr < 3'd4 );

        case({|tx_enain,tx_rdyin})
          2'b01: begin
                   waddr <=  |waddr ? waddr-1 : waddr  ;
                   waddr_p1 <= |waddr ? waddr : 3'h1;
                 end
          2'b10: begin
                   rd_buf[waddr_p1] <= { tx_datain, tx_enain, tx_sopin, tx_eopin, tx_errin, tx_mtyin };
                   waddr <= ( &waddr_p1 ? waddr : waddr + 1 ) ;
                   waddr_p1 <= ( &waddr_p1 ? waddr_p1 : waddr + 2 ) ;
                 end
          2'b11: rd_buf[waddr] <= { tx_datain, tx_enain, tx_sopin, tx_eopin, tx_errin, tx_mtyin };
        endcase
      end
    end

end             // End of zero latency block
else begin      // Begining of single cycle latency block

reg [63:0] loc_tx_dataout;
reg loc_tx_enaout;
reg loc_tx_sopout;
reg loc_tx_eopout;
reg loc_tx_errout;
reg [2:0] loc_tx_mtyout;

reg [70:0] qd1;
wire [70:0] rd1;
reg [2:0] raddr;

assign { tx_dataout, tx_enaout, tx_sopout, tx_eopout, tx_errout, tx_mtyout } = { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } ;

integer i;
always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        qd1 <= 71'h0;
        waddr <= 3'h0;
        raddr <= 3'h0;
        tx_rdyout <= 0;
        for(i=0;i<8;i=i+1) rd_buf[i] <= 71'h0;
        { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= 71'h0;
      end
      else begin
        if(tx_rdyin && (raddr != waddr) ) begin
          { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= rd_buf[raddr];
          raddr <= ( raddr + 1 ) % 8 ;
        end
        else begin
          { loc_tx_dataout, loc_tx_enaout, loc_tx_sopout, loc_tx_eopout, loc_tx_errout, loc_tx_mtyout } <= 71'hx;
          loc_tx_enaout <= 0;
        end
        tx_rdyout <= tx_rdyin;
        if(|tx_enain)begin
          rd_buf[waddr] <= { tx_datain, tx_enain, tx_sopin, tx_eopin, tx_errin, tx_mtyin };
          waddr <= ( waddr + 1 ) % 8 ;
        end
      end
    end

end
endgenerate

endmodule
module xxv_ethernet_0_axis_pkt_gen
 (
  input  wire        clk,
  input  wire        enable,
  input  wire        reset,

//// TX LBUS Signals
//// TX Control Signals
  output wire ctl_tx_send_lfi,
  output wire ctl_tx_send_rfi,
  output wire ctl_tx_send_idle,

//// TX Stats Signals
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
  input  wire stat_tx_local_fault,

  input  wire tx_ovfout,
  input  wire tx_rdyout,
  output reg [64-1:0] tx_datain,
  output reg  tx_enain,
  output reg  tx_sopin,
  output reg  tx_eopin,
  output reg  tx_errin,
  output reg [3-1:0] tx_mtyin,
  input  wire [31:0] packet_count,
  input  wire        rx_lane_align,
  input  wire        insert_crc,
  output wire        time_out,
  output wire        tx_reset,
  output reg         busy,
  output wire        done
);


  parameter integer FIXED_PACKET_LENGTH = 9_000;
  parameter integer TRAF_MIN_LENGTH     = 64;
  parameter integer TRAF_MAX_LENGTH     = 9000;
               
  reg [1:0] dly_cntr;
  reg dly_rdyout;
  reg tx_enain_reg;
  reg [63:0] tx_datain_reg;
  reg tx_sopin_reg;
  reg tx_eopin_reg;
  reg tx_errin_reg;
  reg [2:0] tx_mtyin_reg;

  assign tx_reset                   = 1'b0;

  assign ctl_tx_send_rfi            = 1'b0;
  assign ctl_tx_send_lfi            = 1'b0;
  assign ctl_tx_send_idle           = 1'b0;


  reg [1:0] q_en;
  reg [31:0] rand1;
  wire [31:0] nxt_rand1;
  wire [63:0] nxt_d;
  reg [63:0] d_buff;
  reg [31:0] counter;
  reg [2:0] bsy_cntr;
  
  reg  lane_mask;
  
  reg [29:0] op_timer;
  reg [31:0] packet_counter;
  reg en_stop;
  
  wire ready =  rx_lane_align && tx_rdyout && ~tx_ovfout ;
  
  
  localparam [32:0] DATA_POLYNOMIAL = 33'b100001000001010000000010010000001;
  localparam [31:0] init_crc = 32'b11010111011110111101100110001011;
  
  
  localparam [47:0] dest_addr   = 48'hFF_FF_FF_FF_FF_FF;            // Broadcast
  localparam [47:0] source_addr = 48'h14_FE_B5_DD_9A_82;            // Hardware address of xowjcoppens40
  localparam [15:0] length_type = 16'h0600;                       // XEROX NS IDP
  localparam [111:0] eth_header = { dest_addr, source_addr, length_type} ;
  
  /* Parameter definitions of STATE variables for 2 bit state machine */
  localparam [2:0]  S0 = 3'b000,
                    S1 = 3'b001,
                    S2 = 3'b011,
                    S3 = 3'b010,
                    S4 = 3'b110,
                    S5 = 3'b111,
                    S6 = 3'b101,
                    S7 = 3'b100;
  
  reg [2:0] state;

xxv_ethernet_0_pktprbs_gen #(
  .BIT_COUNT(64)
) i_xxv_ethernet_0_PKT_PRBS_GEN (
  .ip(rand1),
  .op(nxt_rand1),
  .datout(nxt_d)
);

reg [7:0] header_bit_count ;

// reg gen_length;
// reg [3:0] pwr_up;
wire [16:0] pkt_len;
reg set_eop;
reg set_sop;

xxv_ethernet_0_pkt_len_gen
 #(
 .min(TRAF_MIN_LENGTH),
 .max(TRAF_MAX_LENGTH)
 ) i_xxv_ethernet_0_PKT_LEN_GEN  (
  .clk      ( clk ),
  .reset   ( reset ),
//.enable   ( gen_length ),
  .enable   ( 1'b1 ),
  .pkt_len  ( pkt_len )
  );

assign time_out = ~|op_timer,
       done     = (state==S7);

always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    tx_datain <= 64'd0 ;
    tx_enain <= 0 ;
    tx_sopin <= 0 ;
    tx_eopin <= 0 ;
    tx_errin <= 0 ;
    tx_mtyin <= 0 ;
    state <= S0;
    q_en <= 0;
    rand1 <= init_crc;
    counter <= 0;
    d_buff <= 64'd0 ;
    op_timer <= 30'd390625000 ;
//  pwr_up <= 0;
    set_eop <= 0;
    set_sop <= 0;
    lane_mask <= 0;
    packet_counter <= 0;
    bsy_cntr <= 0;
    en_stop <= 0;
    header_bit_count <= 0;
  end
  else begin
//  pwr_up <= ~&pwr_up ? pwr_up+1 : pwr_up;
//  gen_length <= ~&pwr_up;             // This flushes the length pipe
    tx_datain <= 64'd0 ;                // default to zero
    tx_enain <= 0 ;
    tx_sopin <= 0 ;
    tx_eopin <= 0 ;
    tx_errin <= 0 ;
    tx_mtyin <= 0 ;

    q_en <= {q_en, enable};

    case(state)
      S0: if (q_en == 2'b01) state <= S1;
      S1: if (ready) state <= S2;
      S2: begin
            packet_counter <= packet_count;
            en_stop <= ~&packet_count;
            rand1 <= init_crc;
//          gen_length <= 1'b1;
            state <= S3;
          end
      S3: begin
            counter <= pkt_len;
            set_eop <= pkt_len<8;
            set_sop <= 1'b1;
            d_buff <= swapn(nxt_d);
            rand1 <= nxt_rand1;
            state <= |packet_count ? S4 : S7;
             if ( en_stop ) packet_counter <= packet_counter-1;
            header_bit_count <= 8'd111;
          end
      S4: if (tx_rdyout) begin :zulu
            rand1 <= nxt_rand1;
            d_buff <= swapn(nxt_d);
            tx_sopin <= set_sop;
            tx_eopin <= set_eop;
            tx_enain <= 1'b1;
            tx_datain <= d_buff;
            header_bit_count <= header_bit_count[7] ? header_bit_count : header_bit_count - 64 ;
            if(!header_bit_count[7]) begin            // if there is some header left to send, then send it
              if(header_bit_count<63) tx_datain[63-:48] <= eth_header[0+:48] ;
              else tx_datain <= eth_header[header_bit_count-:64] ;
            end
            set_sop <= 0;
            if(set_eop)begin
              state <= (|packet_counter && |q_en) ? S4 : S7;
              if ( en_stop ) packet_counter <= packet_counter-1;
              counter <= pkt_len;                       // get length of next packet to send
              set_eop <= pkt_len<8;
              set_sop <= 1'b1;
              header_bit_count <= 8'd111;
              tx_mtyin <= 8 - counter;
//            gen_length <= 1'b1;
            end
            else begin
              state <= S4;
              counter <= counter - 8;
              set_eop <= counter < 2*8;
            end
          end
      S7: state <= |q_en ? S7 : S0;

    endcase

    case(state)
      S0,S7:   op_timer <= 30'd390625000 ;
      S4:      if(tx_rdyout) op_timer <= 30'd390625000 ;
      default: op_timer <= |op_timer ? op_timer - 1 : op_timer ;
    endcase

    if ( state <= S0 ) begin
      bsy_cntr <= |bsy_cntr ? bsy_cntr - 1 : bsy_cntr ;             // Hold the busy signal for 8 additional cycles.
      busy <= |bsy_cntr;
    end
    else begin
      busy <= 1'b1;
      bsy_cntr <= {3{1'b1}};
    end

  end
end


function [63:0]  swapn (input [63:0]  d);
integer i;
for (i=0; i<=(63); i=i+8) swapn[i+:8] = d[(63-i)-:8];
endfunction

endmodule

module xxv_ethernet_0_pktprbs_gen (
  input   wire [31:0] ip,
  output  wire [31:0] op,
  output  wire [64-1:0] datout
);

//     G(x) = x32 + x27 + x21 + x19 + x10 + x7 + 1
  parameter BIT_COUNT = 64;
localparam [32:0] CRC_POLYNOMIAL = 33'b100001000001010000000010010000001;

localparam REMAINDER_SIZE = 32;

generate

case (BIT_COUNT)

  512: begin :gen_512_loop

          assign op[0] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 op[1] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 op[2] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 op[3] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 op[4] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 op[5] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 op[6] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 op[7] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 op[8] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 op[9] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 op[10] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 op[11] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 op[12] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 op[13] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 op[14] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 op[15] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 op[16] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 op[17] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 op[18] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 op[19] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 op[20] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 op[21] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 op[22] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 op[23] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 op[24] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 op[25] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 op[26] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 op[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 op[28] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 op[29] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 op[30] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 op[31] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31];

          assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                 datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                 datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                 datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                 datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                 datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                 datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                 datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                 datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                 datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                 datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                 datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                 datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                 datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                 datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                 datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                 datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                 datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                 datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                 datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                 datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                 datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                 datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                 datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                 datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                 datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                 datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                 datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                 datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                 datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                 datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                 datout[128] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[129] = ip[3]^ip[4]^ip[5]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[130] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[131] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[132] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[133] = ip[0]^ip[1]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[134] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[135] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[136] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[137] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[138] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[139] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[140] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[24]^ip[30]^ip[31],
                 datout[141] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[19]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[142] = ip[1]^ip[5]^ip[8]^ip[10]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[143] = ip[0]^ip[4]^ip[7]^ip[9]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[144] = ip[3]^ip[8]^ip[9]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[145] = ip[2]^ip[7]^ip[8]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[146] = ip[1]^ip[6]^ip[7]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[147] = ip[0]^ip[5]^ip[6]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[148] = ip[4]^ip[5]^ip[6]^ip[9]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[149] = ip[3]^ip[4]^ip[5]^ip[8]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[150] = ip[2]^ip[3]^ip[4]^ip[7]^ip[16]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[151] = ip[1]^ip[2]^ip[3]^ip[6]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[152] = ip[0]^ip[1]^ip[2]^ip[5]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[153] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[154] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[155] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[18]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[156] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[17]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[157] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[158] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[15]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[159] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[13]^ip[16]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[161] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[162] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[163] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[164] = ip[3]^ip[4]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[165] = ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[166] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[167] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[168] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[169] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[170] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[171] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[172] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[173] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[174] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[175] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[176] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[177] = ip[0]^ip[3]^ip[4]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[178] = ip[2]^ip[3]^ip[6]^ip[9]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[179] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[180] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[181] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[182] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[183] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[184] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[22]^ip[25]^ip[28]^ip[29],
                 datout[185] = ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[186] = ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[187] = ip[1]^ip[2]^ip[3]^ip[6]^ip[10]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[188] = ip[0]^ip[1]^ip[2]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[189] = ip[0]^ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[190] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[191] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[192] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[193] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[194] = ip[1]^ip[2]^ip[4]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[195] = ip[0]^ip[1]^ip[3]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[196] = ip[0]^ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[197] = ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[198] = ip[0]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[199] = ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[200] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[201] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[202] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[203] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[204] = ip[1]^ip[3]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[205] = ip[0]^ip[2]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[206] = ip[1]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[207] = ip[0]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[208] = ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[19]^ip[21]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[209] = ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[18]^ip[20]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[210] = ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[17]^ip[19]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[211] = ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[16]^ip[18]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[212] = ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[15]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27],
                 datout[213] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[14]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26],
                 datout[214] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[13]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25],
                 datout[215] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[216] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[217] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[218] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[219] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[220] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[221] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[222] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[223] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[24]^ip[28]^ip[30],
                 datout[224] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[225] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[226] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[227] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[228] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[229] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[230] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[231] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[232] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[233] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[234] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[235] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[236] = ip[0]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[237] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[238] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[239] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[240] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[241] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[242] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[243] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[244] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[245] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[246] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[247] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[248] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[249] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[250] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[251] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[252] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[253] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[254] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[255] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[18]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[256] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[257] = ip[0]^ip[5]^ip[7]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[258] = ip[4]^ip[10]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[259] = ip[3]^ip[9]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[260] = ip[2]^ip[8]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[261] = ip[1]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[262] = ip[0]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[263] = ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[264] = ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[265] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[266] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[19]^ip[21]^ip[22]^ip[28],
                 datout[267] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[18]^ip[20]^ip[21]^ip[27],
                 datout[268] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[17]^ip[19]^ip[20]^ip[26],
                 datout[269] = ip[0]^ip[3]^ip[4]^ip[5]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[31],
                 datout[270] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[15]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[271] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[14]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[272] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[273] = ip[0]^ip[1]^ip[3]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[274] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[275] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[276] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[277] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[278] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[279] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[280] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[281] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[282] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[283] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[284] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[285] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[286] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[287] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[288] = ip[0]^ip[3]^ip[4]^ip[5]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[289] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[290] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[291] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[292] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[293] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[294] = ip[1]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[295] = ip[0]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[296] = ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[297] = ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[298] = ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[299] = ip[0]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[300] = ip[1]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[301] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[302] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[303] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[304] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[305] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29],
                 datout[306] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28],
                 datout[307] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27],
                 datout[308] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[25]^ip[31],
                 datout[309] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[24]^ip[30],
                 datout[310] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29],
                 datout[311] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[312] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[313] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[314] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[315] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[316] = ip[1]^ip[3]^ip[5]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[317] = ip[0]^ip[2]^ip[4]^ip[6]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[318] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[319] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[320] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[321] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[322] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[323] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[324] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[325] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[326] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[327] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[328] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[329] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[330] = ip[1]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[28]^ip[30]^ip[31],
                 datout[331] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[27]^ip[29]^ip[30],
                 datout[332] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[333] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[334] = ip[0]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[27]^ip[29]^ip[31],
                 datout[335] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[30]^ip[31],
                 datout[336] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[27]^ip[29]^ip[30],
                 datout[337] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[29],
                 datout[338] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[339] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[340] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[341] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[342] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[343] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[344] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[345] = ip[1]^ip[4]^ip[10]^ip[11]^ip[12]^ip[14]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[346] = ip[0]^ip[3]^ip[9]^ip[10]^ip[11]^ip[13]^ip[19]^ip[22]^ip[23]^ip[27]^ip[29]^ip[30],
                 datout[347] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[31],
                 datout[348] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[19]^ip[20]^ip[21]^ip[27]^ip[28]^ip[30],
                 datout[349] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[18]^ip[19]^ip[20]^ip[26]^ip[27]^ip[29],
                 datout[350] = ip[3]^ip[5]^ip[6]^ip[7]^ip[17]^ip[19]^ip[20]^ip[25]^ip[28]^ip[31],
                 datout[351] = ip[2]^ip[4]^ip[5]^ip[6]^ip[16]^ip[18]^ip[19]^ip[24]^ip[27]^ip[30],
                 datout[352] = ip[1]^ip[3]^ip[4]^ip[5]^ip[15]^ip[17]^ip[18]^ip[23]^ip[26]^ip[29],
                 datout[353] = ip[0]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[22]^ip[25]^ip[28],
                 datout[354] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[355] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[356] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[357] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[358] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[359] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[360] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[361] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[362] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[363] = ip[1]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[29]^ip[31],
                 datout[364] = ip[0]^ip[1]^ip[2]^ip[3]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30],
                 datout[365] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[366] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[367] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[368] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[369] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[370] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[371] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[372] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[373] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[374] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[375] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[376] = ip[0]^ip[2]^ip[6]^ip[11]^ip[14]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[377] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[18]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[378] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[379] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[380] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[381] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[382] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[383] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[384] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[385] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[386] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[387] = ip[0]^ip[1]^ip[2]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[388] = ip[0]^ip[1]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[389] = ip[0]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[390] = ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[391] = ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[392] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[393] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[394] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[395] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[396] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[397] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[398] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[399] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[400] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[401] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[402] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[403] = ip[0]^ip[2]^ip[6]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[404] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[405] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[406] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[407] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[408] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[409] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[25]^ip[26]^ip[28],
                 datout[410] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[411] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[412] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[413] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[414] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[415] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[416] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[417] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^
                         ip[28]^ip[29]^ip[31],
                 datout[418] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[419] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[420] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[15]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[421] = ip[0]^ip[1]^ip[2]^ip[8]^ip[11]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[422] = ip[0]^ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[423] = ip[0]^ip[5]^ip[8]^ip[12]^ip[16]^ip[17]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[424] = ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[425] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[426] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[427] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[428] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[429] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[430] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30],
                 datout[431] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[432] = ip[1]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[18]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[433] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[434] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[435] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[436] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[437] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[438] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[439] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[440] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[441] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^
                         ip[30]^ip[31],
                 datout[442] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[443] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[444] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[445] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[446] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[447] = ip[1]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[448] = ip[0]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[449] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[31],
                 datout[450] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30],
                 datout[451] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[452] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[453] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[454] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[455] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[17]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[456] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[457] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[458] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[25]^ip[27]^ip[29],
                 datout[459] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[28]^ip[31],
                 datout[460] = ip[1]^ip[3]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[461] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[462] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[463] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[464] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[465] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[466] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[467] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[468] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[19]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[469] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[20]^ip[22]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[470] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[471] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[472] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[473] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[474] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[475] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[476] = ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[477] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[11]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[478] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[479] = ip[0]^ip[2]^ip[5]^ip[12]^ip[15]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[480] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[481] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[482] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[483] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[484] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[485] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[486] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 datout[487] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 datout[488] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 datout[489] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[490] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[491] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[492] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[493] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[494] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[495] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[496] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[497] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[498] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[499] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[500] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 datout[501] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 datout[502] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 datout[503] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 datout[504] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 datout[505] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[506] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[507] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[508] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[509] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[510] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[511] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31];


       end // gen_512_loop

       default: begin :gen_rtl_loop

                  reg [(BIT_COUNT-1):0] mdat;
                  reg [REMAINDER_SIZE:0] md, nCRC [0:(BIT_COUNT-1)];                       // temp vaiables used in CRC calculation

                  always @(ip) begin :crc_loop
                    integer i;
                    nCRC[0] = {ip,^(CRC_POLYNOMIAL & {ip,1'b0})};
                    for(i=1;i<BIT_COUNT;i=i+1) begin                     // Calculate remaining CRC for all other data bits in parallel
                      md = nCRC[i-1];
                      mdat[i-1] = md[0];
                      nCRC[i] = {md,^(CRC_POLYNOMIAL & {md[(REMAINDER_SIZE-1):0],1'b0})};
                    end
                    md = nCRC[(BIT_COUNT-1)];
                    mdat[(BIT_COUNT-1)] = md[0];
                  end

                  assign op = md;                          // The output polynomial is the very last entry in the array
                  assign datout  = mdat;

                end             // gen_rtl_loop

endcase

endgenerate

endmodule



module xxv_ethernet_0_traf_chk1 (
  input wire clk,
  input wire reset,
  input wire enable,
  input wire clear_count,

  input wire [63:0] rx_dataout,
  input wire rx_enaout,
  input wire rx_sopout,
  input wire rx_eopout,
  input wire rx_errout,
  input wire [2:0] rx_mtyout,

  output reg protocol_error,
  output wire [47:0] packet_count,
  output wire [63:0] total_bytes,
  output wire [31:0] prot_err_count,
  output wire [31:0] error_count,
  output wire packet_count_overflow,
  output wire prot_err_overflow,
  output wire error_overflow,
  output wire total_bytes_overflow
);

/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;
reg [48:0] pct_cntr;
reg [32:0] perr_cntr, err_cntr;

reg [1:0] state ;
reg [1:0] q_en;
reg [3:0] delta_bytes;
(* keep = "true" *) reg [64:0] byte_cntr;
reg inc_pct_cntr;
reg inc_err_cntr;

assign packet_count           = pct_cntr[48] ? {48{1'b1}} : pct_cntr[47:0],
       packet_count_overflow  = pct_cntr[48],
       prot_err_count         = perr_cntr[32] ? {32{1'b1}} : perr_cntr[31:0],
       prot_err_overflow      = perr_cntr[32],
       error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32],
       total_bytes            = byte_cntr[64] ? {64{1'b1}} : byte_cntr[63:0],
       total_bytes_overflow   = byte_cntr[64];

integer i;
always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    q_en <= 0;
    state <= S0;
    protocol_error <= 0;
    pct_cntr <= 49'h0;
    err_cntr <= 33'h0;
    perr_cntr <= 33'h0;
    byte_cntr <= 65'h0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    delta_bytes <= 0;
  end
  else begin
    delta_bytes <= 0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    protocol_error <= 0;
    q_en <= {q_en, enable};

    case (state)
      S0: if (q_en == 2'b01) state <= S1;

      S1: if(rx_enaout)begin
            case({rx_sopout,rx_eopout})
              2'b01: protocol_error <= 1'b1;
              2'b10: begin
                       state <= S2;
                       delta_bytes <= 4'd8;
                     end
              2'b11: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       inc_pct_cntr <= 1'b1;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                     end
            endcase
          end
      S2: if(rx_enaout)begin
            case({rx_sopout,rx_eopout})
              2'b01: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       inc_pct_cntr <= 1'b1;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                       state <= S1;
                     end
              2'b10: begin
                       protocol_error <= 1'b1;
                       delta_bytes <= 4'd8;
                     end
              2'b11: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                       inc_pct_cntr <= 1'b1;
                       protocol_error <= 1'b1;
                     end
              default: delta_bytes <= 4'd8;
            endcase
          end
      default: state <= S0;
    endcase

    if(~|q_en) state <= S0;
    if(!byte_cntr[64]) byte_cntr <= byte_cntr + {1'b0,delta_bytes};
    if(protocol_error && !perr_cntr[32]) perr_cntr <= perr_cntr + 1;
    if(inc_pct_cntr && !pct_cntr[48])  pct_cntr <= pct_cntr + 1;
    if(inc_err_cntr && !err_cntr[32]) err_cntr <= err_cntr + 1;
    if(clear_count)begin
      byte_cntr <= 65'h0;
      pct_cntr <= 49'h0;
      err_cntr <= 33'h0;
      perr_cntr <= 33'h0;
    end
  end
end

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off
  reg [8*12-1:0] state_text;                    // Enumerated type conversion to text
  always @(state) case (state)
    S0: state_text = "S0" ;
    S1: state_text = "S1" ;
    S2: state_text = "S2" ;
    S3: state_text = "S3" ;
  endcase
`endif

endmodule

module xxv_ethernet_0_pkt_len_gen (
  input  wire clk,
  input  wire reset,
  input  wire enable,
  output reg [16:0] pkt_len
  );

  parameter integer min=64;
  parameter integer max=9000;
localparam integer pkt_diff = max - min + 1;

localparam [32:0] CRC_POLYNOMIAL = 33'b100001000001010000000010010000001;
localparam [31:0] init_crc = 32'b11010111011110111101100110001011;

reg [31:0] p1[0:15], p2[0:7], p3[0:3], p4[0:1], p5;

reg [31:0] CRC;

integer i;
always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    for(i=0;i<16;i=i+1) p1[i]<=0;
    for(i=0;i<8;i=i+1)  p2[i]<=0;
    for(i=0;i<4;i=i+1)  p3[i]<=0;
    for(i=0;i<2;i=i+1)  p4[i]<=0;
                        p5   <=0;
    CRC <= init_crc;
  end
  else begin
    if(enable)begin
      for(i=0;i<16;i=i+1) p1[i] <= CRC[i] ? (pkt_diff << i) : 0;
      for(i=0;i<16;i=i+2) p2[i/2] <= p1[i] + p1[i+1];
      for(i=0;i<16;i=i+4) p3[i/4] <= p2[i/2] + p2[i/2+1];
      for(i=0;i<16;i=i+8) p4[i/8] <= p3[i/4] + p3[i/4+1];
      p5 <= p4[0] + p4[1];
      pkt_len <= {1'b0,p5[31:16]} + min;
      CRC <= {CRC,^(CRC_POLYNOMIAL & {CRC,1'b0})};
    end
  end
end


endmodule
module xxv_ethernet_0_axis_pkt_mon (

  input wire clk,
  input wire reset,
  input wire clear_count,
  input wire sys_reset,
//// RX Control Signals


//// RX Stats Signals
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
  input  wire stat_rx_truncated,
  input  wire stat_rx_local_fault,
  input  wire stat_rx_remote_fault,
  input  wire stat_rx_internal_local_fault,
  input  wire stat_rx_received_local_fault,

//// RX LBUS Signals
  input wire [64-1:0] rx_dataout,
  input wire rx_enaout,
  input wire rx_sopout,
  input wire rx_eopout,
  input wire rx_errout,
  input wire [3-1:0] rx_mtyout,

  output wire rx_reset,
  output reg protocol_error,
  output wire [47:0] packet_count,
  output wire [63:0] total_bytes,
  output wire [31:0] prot_err_count,
  output wire [31:0] error_count,
  output wire packet_count_overflow,
  output wire prot_err_overflow,
  output wire error_overflow,
  output wire total_bytes_overflow,
  output reg rx_gt_locked_led,
  output reg rx_block_lock_led 
);
  parameter MIN_LENGTH     = 64;
  parameter MAX_LENGTH     = 9000;
wire   enable;
reg [48:0] pct_cntr;
reg [32:0] perr_cntr, err_cntr;
wire       rx_block_lock;
reg        rx_gt_locked_led_1d;
reg        rx_gt_locked_led_2d;
reg        rx_gt_locked_led_3d;
reg        rx_block_lock_led_1d;
reg        rx_block_lock_led_2d;
reg        rx_block_lock_led_3d;
reg [1:0]  state ;
reg [1:0]  q_en;
reg [3:0]  delta_bytes;
reg [64:0] byte_cntr;
reg        inc_pct_cntr;
reg        inc_err_cntr;

assign enable                     = 1'b1;
assign rx_reset                   = 1'b0;
assign rx_block_lock              = stat_rx_block_lock;




/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;

assign packet_count           = pct_cntr[48] ? {48{1'b1}} : pct_cntr[47:0],
       packet_count_overflow  = pct_cntr[48],
       prot_err_count         = perr_cntr[32] ? {32{1'b1}} : perr_cntr[31:0],
       prot_err_overflow      = perr_cntr[32],
       error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32],
       total_bytes            = byte_cntr[64] ? {64{1'b1}} : byte_cntr[63:0],
       total_bytes_overflow   = byte_cntr[64];

integer i;
always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    q_en <= 0;
    state <= S0;
    protocol_error <= 0;
    pct_cntr <= 49'h0;
    err_cntr <= 33'h0;
    perr_cntr <= 33'h0;
    byte_cntr <= 65'h0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    delta_bytes <= 0;
  end
  else begin
    delta_bytes <= 0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    protocol_error <= 0;
    q_en <= {q_en, enable};

    case (state)
      S0: if (q_en == 2'b01) state <= S1;

      S1: if(rx_enaout)begin
            case({rx_sopout,rx_eopout})
              2'b01: protocol_error <= 1'b1;
              2'b10: begin
                       state <= S2;
                       delta_bytes <= 4'd8;
                     end
              2'b11: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       inc_pct_cntr <= 1'b1;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                     end
            endcase
          end
      S2: if(rx_enaout)begin
            case({rx_sopout,rx_eopout})
              2'b01: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       inc_pct_cntr <= 1'b1;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                       state <= S1;
                     end
              2'b10: begin
                       protocol_error <= 1'b1;
                       delta_bytes <= 4'd8;
                     end
              2'b11: begin
                       delta_bytes <= 4'd8 - {1'b0,rx_mtyout} ;
                       if(rx_errout) inc_err_cntr <= 1'b1;
                       inc_pct_cntr <= 1'b1;
                       protocol_error <= 1'b1;
                     end
              default: delta_bytes <= 4'd8;
            endcase
          end
      default: state <= S0;
    endcase

    if(~|q_en) state <= S0;
    if(!byte_cntr[64]) byte_cntr <= byte_cntr + {1'b0,delta_bytes};
    if(protocol_error && !perr_cntr[32]) perr_cntr <= perr_cntr + 1;
    if(inc_pct_cntr && !pct_cntr[48])  pct_cntr <= pct_cntr + 1;
    if(inc_err_cntr && !err_cntr[32]) err_cntr <= err_cntr + 1;
    if(clear_count)begin
      byte_cntr <= 65'h0;
      pct_cntr <= 49'h0;
      err_cntr <= 33'h0;
      perr_cntr <= 33'h0;
    end
  end
end

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off
  reg [8*12-1:0] state_text;                    // Enumerated type conversion to text
  always @(state) case (state)
    S0: state_text = "S0" ;
    S1: state_text = "S1" ;
    S2: state_text = "S2" ;
    S3: state_text = "S3" ;
  endcase
`endif


   //////////////////////////////////////////////////
    ////Registering the LED ports
    //////////////////////////////////////////////////

    always @( posedge clk )
    begin
        if ( reset == 1'b1 )
        begin
            rx_gt_locked_led_1d     <= 1'b0;
            rx_gt_locked_led_2d     <= 1'b0;
            rx_gt_locked_led_3d     <= 1'b0;
            rx_block_lock_led_1d    <= 1'b0;
            rx_block_lock_led_2d    <= 1'b0;
            rx_block_lock_led_3d    <= 1'b0;
        end
        else
        begin
            rx_gt_locked_led_1d     <= ~reset;
            rx_gt_locked_led_2d     <= rx_gt_locked_led_1d;
            rx_gt_locked_led_3d     <= rx_gt_locked_led_2d;
            rx_block_lock_led_1d    <= rx_block_lock;
            rx_block_lock_led_2d    <= rx_block_lock_led_1d;
            rx_block_lock_led_3d    <= rx_block_lock_led_2d;
        end
    end

   //////////////////////////////////////////////////
    ////Assign RX LED Output ports with ASYN sys_reset
    //////////////////////////////////////////////////
    always @( posedge clk, posedge sys_reset  )
    begin
        if ( sys_reset == 1'b1 )
        begin
            rx_gt_locked_led     <= 1'b0;
            rx_block_lock_led    <= 1'b0;
        end
        else
        begin
            rx_gt_locked_led     <= rx_gt_locked_led_3d;
            rx_block_lock_led    <= rx_block_lock_led_3d;
        end
    end


endmodule


module xxv_ethernet_0_traf_data_chk (

  input wire clk,
  input wire reset,
  input wire enable,
  input wire clear_count,

  input wire [63:0] rx_dataout,
  input wire rx_enaout,
  input wire rx_sopout,
  input wire rx_eopout,
  input wire rx_errout,
  input wire [2:0] rx_mtyout,

  output wire [31:0] error_count,
  output wire error_overflow
);
reg [32:0] err_cntr;
assign error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32];

localparam [47:0] dest_addr   = 48'hFF_FF_FF_FF_FF_FF;            // Broadcast
localparam [47:0] source_addr = 48'h14_FE_B5_DD_9A_82;            // Hardware address of xowjcoppens40
localparam [15:0] length_type = 16'h0600;                       // XEROX NS IDP
localparam [111:0] eth_header = { dest_addr, source_addr, length_type} ;
/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;
reg [1:0] state[0:2];
reg [7:0] header_bit_count ;

reg [31:0] crc_ip1;
reg [31:0] crc_ip2[0:1];
wire [31:0] nxt_crc;
reg set_derr;

wire [ 63:0] dat1,dat2;
wire [ 63:0] exp1,exp2;

xxv_ethernet_0_pktprbs_gen
 #(
  .BIT_COUNT ( 64 )
) i_PKTPRBS_GEN1 (
  .ip         ( crc_ip1 ),
  .op         (  ),
  .datout     ( dat1 )
);

xxv_ethernet_0_pktprbs_gen
 #(
  .BIT_COUNT ( 64 )
) i_PKTPRBS_GEN2 (
  .ip         ( crc_ip2[1] ),
  .op         ( nxt_crc ),
  .datout     ( dat2 )
);

assign exp1 = swapn ( dat1 ) ;
assign exp2 = swapn ( dat2 ) ;

reg [ 63:0] zzmask[0:2];
reg [ 63:0] cmpr[0:2];
reg [ 63:0] d_dat[0:2];
reg [2:0] d_ena;
reg [2:0] d_sop;
reg [2:0] d_eop;
reg [2:0] v_pkt;

integer i;

always @( posedge clk )
    begin
      if ( reset == 1'b1 ) begin
        set_derr <= 0;
        crc_ip1 <= 0;
        crc_ip2[0] <= 0;
        crc_ip2[1] <= 0;
        err_cntr <= 33'h0;
        d_ena <= 0;
        d_sop <= 0;
        d_eop <= 0;
        v_pkt <= 0;
        header_bit_count <= 8'd111;
        for (i=0; i<=2; i=i+1) state[i] <= S0;

        for (i=0; i<=2; i=i+1) zzmask[i] <= 64'h0;
        for (i=0; i<=2; i=i+1) cmpr[i] <= 64'h0;
        for (i=0; i<=2; i=i+1) d_dat[i] <= 64'h0;

      end
      else begin :read_loop
        reg loc_sop,loc_eop;
        loc_sop = |( rx_enaout & rx_sopout ) ;
        loc_eop = |( rx_enaout & rx_eopout ) ;

        d_ena <= {d_ena, |rx_enaout && enable};
        d_sop <= {d_sop, loc_sop };
        d_eop <= {d_eop, loc_eop };
        v_pkt <= {v_pkt, ( loc_sop || v_pkt[0] ) && ~loc_eop};
        for (i=1; i<=2; i=i+1) state[i] <= state[i-1] ;

        d_dat[0] <= rx_dataout;
        for (i=1; i<=2; i=i+1) zzmask[i] <= zzmask[i-1] ;
        for (i=1; i<=2; i=i+1) cmpr[i] <= cmpr[i-1] ;
        for (i=1; i<=2; i=i+1) d_dat[i] <= d_dat[i-1] ;
        zzmask[0] <= loc_eop ? {64{1'b1}} << {rx_mtyout,3'd0} : {64{1'b1}};
        if(rx_enaout) begin
          if ( rx_sopout || v_pkt[0] ) header_bit_count <= ( header_bit_count <= 64 ) ? 0 : header_bit_count - 64 ;
          else header_bit_count <= 111 ;
        end

        if(rx_enaout) case ( state[0] )
          S0: if ( rx_sopout && !rx_eopout ) state[0] <= S1;
          S1: if ( ( header_bit_count < 64 ) && !rx_eopout ) state[0] <= S2;
          S2: if ( rx_sopout || rx_eopout || ~v_pkt[0] ) state[0] <= S0 ;
              else if ( v_pkt[0] && !rx_eopout ) state[0] <= S3 ;
          S3: if ( rx_sopout || rx_eopout || ~v_pkt[0] ) state[0] <= S0 ;
        endcase

        case ( state[0] )
          S0: cmpr[0] <= eth_header[111-:64] ;
          S1: crc_ip1 <= crc_swapn(rx_dataout[0+:32]) << 16 ;
          S2: crc_ip1[0+:16] <= crc_swapn(rx_dataout[63-:32]) >> 16 ;
          default: crc_ip1 <= 32'hx;
        endcase


        case (state[1])
          S1: begin
                 cmpr[1] <= { eth_header[0+:48],16'h0} ;
                 zzmask[1][0+:16] <= 16'h0;
              end
          S2: begin
                 cmpr[1] <= {16'h0,exp1[63-:48]};
                 zzmask[1][63-:16] <= 16'h0;
              end
          S3: cmpr[1] <= exp2;
        endcase


        if (rx_enaout) crc_ip2[0] <= crc_swapn(rx_dataout[0+:32]);
        if(d_ena[0]) case (state[1])
          S2:       crc_ip2[1] <= crc_ip2[0];
          default:  crc_ip2[1] <= nxt_crc;
        endcase

        set_derr <= |{(cmpr[1] ^ d_dat[1]) & zzmask[1] } && d_ena[1] && |v_pkt[1+:2];
        if(set_derr && !err_cntr[32]) err_cntr <= err_cntr + 1;

        if(clear_count) err_cntr <= 33'h0;

      end
    end

function [63:0]  swapn (input [63:0]  d);
integer i;
for (i=0; i<=(63); i=i+8) swapn[i+:8] = d[(63-i)-:8];
endfunction

function [31:0] crc_swapn (input [31:0] d);
integer i;
for (i=0; i<=31; i=i+1) crc_swapn[i] = d[{i[5:3],~i[2:0]}];
endfunction


endmodule
module xxv_ethernet_0_example_fsm_axis #( 
 parameter VL_LANES_PER_GENERATOR = 1
) (
input wire dclk,
input wire fsm_reset,
input wire [VL_LANES_PER_GENERATOR-1:0] stat_rx_block_lock,
input wire [VL_LANES_PER_GENERATOR-1:0] stat_rx_synced,
input wire stat_rx_aligned,
input wire stat_rx_status,
input wire tx_timeout,
input wire tx_done,
input wire ok_to_start,

input wire [47:0] rx_packet_count,
input wire [63:0] rx_total_bytes,
input wire  rx_errors,
input wire  rx_data_errors,
input wire [47:0] tx_sent_count,
input wire [63:0] tx_total_bytes,


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
reg rx_packet_count_mismatch;
reg rx_byte_count_mismatch;
reg rx_non_zero_error_count;
reg tx_zero_sent;

always @( posedge dclk )
    begin
      if ( fsm_reset == 1'b1 ) begin
        common_timer <= 0;
        state <= S0;
        sys_reset <= 1'b0 ;
        pktgen_enable <= 1'b0;
        completion_status <= NO_START ;
        rx_packet_count_mismatch <= 0;
        rx_byte_count_mismatch <= 0;
        rx_non_zero_error_count <= 0;
        tx_zero_sent <= 0;
      end
      else begin :check_loop
        integer i;
        common_timer <= |common_timer ? common_timer - 1 : common_timer;
        rx_non_zero_error_count <=  rx_data_errors ;
        rx_packet_count_mismatch <= 0;
        rx_byte_count_mismatch <= 0;
        tx_zero_sent <= 0;
        for ( i = 0; i < GENERATOR_COUNT; i=i+1 ) begin
          if ( tx_total_bytes[(64 * i)+:64] != rx_total_bytes[(64 * i)+:64] ) rx_byte_count_mismatch <= 1'b1;
          if ( tx_sent_count[(48 * i)+:48] != rx_packet_count[(48 * i)+:48] ) rx_packet_count_mismatch <= 1'b1;         // Check all generators for received counts equal transmitted count
          if ( ~|tx_sent_count[(48 * i)+:48] ) tx_zero_sent <= 1'b1;                                                       // If any channel fails to send any data, flag zero-sent
        end
        case ( state )
          S0: state <= ok_to_start ? S1 : S0;
          S1: begin
`ifdef SIM_SPEED_UP
                common_timer <= cvt_us ( 32'd100 );               // If this is the example simulation then only wait for 100 us
`else
                common_timer <= cvt_us ( 32'd10_000 );               // Wait for 10ms...do nothing; settling time for MMCs, oscilators, QPLLs etc.
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
                common_timer <= cvt_us( 5 );                    // Allow about 5 us for the reset to propagate into the downstream hardware
                sys_reset <= 1'b0;     // Clear the reset
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
                 if(tx_timeout || ~tx_done) completion_status <= TX_TIMED_OUT;
                 else if(rx_packet_count_mismatch) completion_status <= SENT_COUNT_MISMATCH;
                 else if(rx_byte_count_mismatch) completion_status <= BYTE_COUNT_MISMATCH;
                 else if(rx_errors) completion_status <= LBUS_PROTOCOL;
                 else if(rx_non_zero_error_count) completion_status <= BIT_ERRORS_IN_DATA;
                 else if(tx_zero_sent) completion_status <= NO_DATA_SENT;
               end
          S15: state <= S15;            // Finish and wait forever
        endcase
      end
    end


function [31:0] cvt_us( input [31:0] d );
cvt_us = ( ( d * 300 ) + 3 ) / 4 ;
endfunction

endmodule

`timescale 1 ps / 1 ps

module top
   (ddr4_sdram_c1_act_n,
    ddr4_sdram_c1_adr,
    ddr4_sdram_c1_ba,
    ddr4_sdram_c1_bg,
    ddr4_sdram_c1_ck_c,
    ddr4_sdram_c1_ck_t,
    ddr4_sdram_c1_cke,
    ddr4_sdram_c1_cs_n,
    ddr4_sdram_c1_dm_n,
    ddr4_sdram_c1_dq,
    ddr4_sdram_c1_dqs_c,
    ddr4_sdram_c1_dqs_t,
    ddr4_sdram_c1_odt,
    ddr4_sdram_c1_reset_n,
    default_250mhz_clk1_clk_n,
    default_250mhz_clk1_clk_p,
    dip_switches_4bits_tri_i,
    led_8bits_tri_o,
    reset,
    rs232_uart_rxd,
    rs232_uart_txd);
  output ddr4_sdram_c1_act_n;
  output [16:0]ddr4_sdram_c1_adr;
  output [1:0]ddr4_sdram_c1_ba;
  output ddr4_sdram_c1_bg;
  output ddr4_sdram_c1_ck_c;
  output ddr4_sdram_c1_ck_t;
  output ddr4_sdram_c1_cke;
  output ddr4_sdram_c1_cs_n;
  inout [7:0]ddr4_sdram_c1_dm_n;
  inout [63:0]ddr4_sdram_c1_dq;
  inout [7:0]ddr4_sdram_c1_dqs_c;
  inout [7:0]ddr4_sdram_c1_dqs_t;
  output ddr4_sdram_c1_odt;
  output ddr4_sdram_c1_reset_n;
  input default_250mhz_clk1_clk_n;
  input default_250mhz_clk1_clk_p;
  input [3:0]dip_switches_4bits_tri_i;
  output [7:0]led_8bits_tri_o;
  input reset;
  input rs232_uart_rxd;
  output rs232_uart_txd;
  wire [31:0]to_pr_0;

  wire ddr4_sdram_c1_act_n;
  wire [16:0]ddr4_sdram_c1_adr;
  wire [1:0]ddr4_sdram_c1_ba;
  wire ddr4_sdram_c1_bg;
  wire ddr4_sdram_c1_ck_c;
  wire ddr4_sdram_c1_ck_t;
  wire ddr4_sdram_c1_cke;
  wire ddr4_sdram_c1_cs_n;
  wire [7:0]ddr4_sdram_c1_dm_n;
  wire [63:0]ddr4_sdram_c1_dq;
  wire [7:0]ddr4_sdram_c1_dqs_c;
  wire [7:0]ddr4_sdram_c1_dqs_t;
  wire ddr4_sdram_c1_odt;
  wire ddr4_sdram_c1_reset_n;
  wire default_250mhz_clk1_clk_n;
  wire default_250mhz_clk1_clk_p;
  wire [3:0]dip_switches_4bits_tri_i;
  wire [31:0]from_pr_0;
  wire [7:0]led_8bits_tri_o;
  wire reset;
  wire rs232_uart_rxd;
  wire rs232_uart_txd;
  
  wire clk_100_0;
  wire [31:0]from_pr_0;
  wire [31:0]to_pr_0;

  config_mb config_mb_i
       (.ddr4_sdram_c1_act_n(ddr4_sdram_c1_act_n),
        .ddr4_sdram_c1_adr(ddr4_sdram_c1_adr),
        .ddr4_sdram_c1_ba(ddr4_sdram_c1_ba),
        .ddr4_sdram_c1_bg(ddr4_sdram_c1_bg),
        .ddr4_sdram_c1_ck_c(ddr4_sdram_c1_ck_c),
        .ddr4_sdram_c1_ck_t(ddr4_sdram_c1_ck_t),
        .ddr4_sdram_c1_cke(ddr4_sdram_c1_cke),
        .ddr4_sdram_c1_cs_n(ddr4_sdram_c1_cs_n),
        .ddr4_sdram_c1_dm_n(ddr4_sdram_c1_dm_n),
        .ddr4_sdram_c1_dq(ddr4_sdram_c1_dq),
        .ddr4_sdram_c1_dqs_c(ddr4_sdram_c1_dqs_c),
        .ddr4_sdram_c1_dqs_t(ddr4_sdram_c1_dqs_t),
        .ddr4_sdram_c1_odt(ddr4_sdram_c1_odt),
        .ddr4_sdram_c1_reset_n(ddr4_sdram_c1_reset_n),
        .default_250mhz_clk1_clk_n(default_250mhz_clk1_clk_n),
        .default_250mhz_clk1_clk_p(default_250mhz_clk1_clk_p),
        .dip_switches_4bits_tri_i(dip_switches_4bits_tri_i),
        .from_pr_0(from_pr_0),
        .led_8bits_tri_o(led_8bits_tri_o),
        .reset(reset),
        .rs232_uart_rxd(rs232_uart_rxd),
        .rs232_uart_txd(rs232_uart_txd),
        .to_pr_0(to_pr_0),
        .clk_100(clk_100_0));

  pr_loopback inst_rp_0 (
    .clock (clk_100_0),
    .in (to_pr_0),
    .out (from_pr_0)
  );

  wire lp_1;
  pr_loopback inst_rp_1 (
    .clock (clk_100_0),
    .in (lp_1),
    .out (lp_1)
  );

  wire lp_2;
  pr_loopback inst_rp_2 (
    .clock (clk_100_0),
    .in (lp_2),
    .out (lp_2)
  );

  wire lp_3;
  pr_loopback inst_rp_3 (
    .clock (clk_100_0),
    .in (lp_3),
    .out (lp_3)
  );

endmodule

/*
 * Black-box definition
 */
module pr_loopback(
    input clock,
    input [31:0] in,
    output reg [31:0] out
    );
endmodule

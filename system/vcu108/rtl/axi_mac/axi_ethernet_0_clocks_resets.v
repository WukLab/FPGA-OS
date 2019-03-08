// Description: This is a clocks and resets wrapper for Example Design of AXI Ethernet IP.
//              It instantiates clock wizard and reset generator modules.

`timescale 1ps/1ps

module axi_ethernet_0_clocks_resets
(
// System clock input
    input clk_300,
    input clk_125,
    input clk_100,
    input clk_166,
    input clk_50,
    input mmcm_locked_i,

// asynchronous control/resets
    input soft_rst  ,

// locked status signal
    output mmcm_locked_out ,

//reset outputs
    output axi_lite_resetn ,
    output axis_rstn       ,
    output sys_out_rst     ,

// clock outputs
    output gtx_clk_bufg  ,
    output ref_clk_bufg  ,
    output ref_clk_50_bufg,
    output axis_clk_bufg,
    output axi_lite_clk_bufg 
);

wire axis_clk_int, axi_lite_clk_int, axi_lite_reset_int, axis_rst_int, sys_rst_int;

assign sys_rst_int       = ~mmcm_locked_i || soft_rst;
assign axis_clk_bufg     = axis_clk_int;
assign axi_lite_clk_bufg = axi_lite_clk_int;
assign sys_out_rst       = sys_rst_int;
assign axi_lite_resetn   = ~axi_lite_reset_int;
assign axis_rstn         = ~axis_rst_int;
assign mmcm_locked_out   = mmcm_locked_i;

assign gtx_clk_bufg = clk_125; 
assign ref_clk_bufg = clk_300;
assign ref_clk_50_bufg = clk_50;
assign axis_clk_int = clk_100;
assign axi_lite_clk_int = clk_100;

axi_ethernet_0_reset_sync axi_lite_reset_gen (
    .clk       (axi_lite_clk_int  ),
    .reset_in  (sys_rst_int       ),
    .reset_out (axi_lite_reset_int) 
);

axi_ethernet_0_reset_sync axi_str_reset_gen (
    .clk       (axis_clk_int),
    .reset_in  (sys_rst_int ),
    .reset_out (axis_rst_int) 
);

endmodule 

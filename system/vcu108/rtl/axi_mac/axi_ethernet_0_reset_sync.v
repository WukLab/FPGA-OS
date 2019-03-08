//----------------------------------------------------------------------------------------------------------------------
// Title      : Verilog Example Level Module
// File       : axi_ethernet_0_reset_sync.v
// Author     : Xilinx Inc.
// ########################################################################################################################
// ##
// # (c) Copyright 2012-2016 Xilinx, Inc. All rights reserved.
// #
// # This file contains confidential and proprietary information of Xilinx, Inc. and is protected under U.S. and
// # international copyright and other intellectual property laws. 
// #
// # DISCLAIMER
// # This disclaimer is not a license and does not grant any rights to the materials distributed herewith. Except as
// # otherwise provided in a valid license issued to you by Xilinx, and to the maximum extent permitted by applicable law:
// # (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND
// # CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// # INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether in contract or tort,
// # including negligence, or under any other theory of liability) for any loss or damage of any kind or nature related to,
// # arising under or in connection with these materials, including for any direct, or any indirect, special, incidental, or
// # consequential loss or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered as a
// # result of any action brought by a third party) even if such damage or loss was reasonably foreseeable or Xilinx had
// # been advised of the possibility of the same.
// #
// # CRITICAL APPLICATIONS
// # Xilinx products are not designed or intended to be fail-safe, or for use in any application requiring fail-safe
// # performance, such as life-support or safety devices or systems, Class III medical devices, nuclear facilities,
// # applications related to the deployment of airbags, or any other applications that could lead to death, personal injury,
// # or severe property or environmental damage (individually and collectively, "Critical Applications"). Customer assumes
// # the sole risk and liability of any use of Xilinx products in Critical Applications, subject only to applicable laws and
// # regulations governing limitations on product liability.
// #
// # THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
// #
// ########################################################################################################################
// Description: This is a reset synchronizer of AXI Ethernet IP.
//              It contains other resources required for an example.
//----------------------------------------------------------------------------------------------------------------------

`timescale 1ps/1ps

module axi_ethernet_0_reset_sync (
  input  wire clk,
  input  wire reset_in,
  output wire reset_out
);

  // Use 5 flip-flops as a single synchronizer, and tag each declaration with the appropriate synthesis attribute to
  // enable clustering. Each flip-flop in the synchronizer is asynchronously reset so that the downstream logic is also
  // asynchronously reset but encounters no reset assertion latency. The removal of reset is synchronous, so that the
  // downstream logic is also removed from reset synchronously. This module is designed for active-high reset use.

  (* ASYNC_REG = "TRUE" *) reg axi_eth_ex_des_reset_sync0  = 1'b0;
  (* ASYNC_REG = "TRUE" *) reg axi_eth_ex_des_reset_sync1  = 1'b0;
  (* ASYNC_REG = "TRUE" *) reg axi_eth_ex_des_reset_sync2  = 1'b0;
  (* ASYNC_REG = "TRUE" *) reg axi_eth_ex_des_reset_sync3  = 1'b0;
                           reg axi_eth_ex_des_reset_sync4  = 1'b0;

  always @(posedge clk, posedge reset_in) begin
    if (reset_in) begin
      axi_eth_ex_des_reset_sync0 <= 1'b1;
      axi_eth_ex_des_reset_sync1 <= 1'b1;
      axi_eth_ex_des_reset_sync2 <= 1'b1;
      axi_eth_ex_des_reset_sync3 <= 1'b1;
    end
    else begin
      axi_eth_ex_des_reset_sync0 <= 1'b0;
      axi_eth_ex_des_reset_sync1 <= axi_eth_ex_des_reset_sync0;
      axi_eth_ex_des_reset_sync2 <= axi_eth_ex_des_reset_sync1;
      axi_eth_ex_des_reset_sync3 <= axi_eth_ex_des_reset_sync2;
    end
  end
  always @(posedge clk) begin
      axi_eth_ex_des_reset_sync4 <= axi_eth_ex_des_reset_sync3;
  end

  assign reset_out = axi_eth_ex_des_reset_sync4;


endmodule

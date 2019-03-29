

/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : MIG
//  /   /         Filename           : sim_tb_top.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR3_SDRAM
// Purpose          :
//                   Top-level testbench for testing Memory interface.
//                   Instantiates:
//                     1. IP_TOP (top-level representing FPGA, contains core,
//                        clocking, built-in testbench/memory checker and other
//                        support structures)
//                     2. Memory Model
//                     3. Miscellaneous clock generation and reset logic
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

`ifdef XILINX_SIMULATOR
module short(in1, in1);
inout in1;
endmodule
`endif

module ddr3_tb_top_new (
     c0_ddr3_addr,
     c0_ddr3_ba,
     c0_ddr3_ras_n,
     c0_ddr3_cas_n,
     c0_ddr3_we_n,
     c0_ddr3_cke,
     c0_ddr3_odt,
     c0_ddr3_cs_n,
     c0_ddr3_ck_p,
     c0_ddr3_ck_n,
     c0_ddr3_reset_n,
     c0_ddr3_dm,
     c0_ddr3_dq,
     c0_ddr3_dqs_n,
     c0_ddr3_dqs_p         
);

  localparam ADDR_WIDTH                = 16;
  localparam DQ_WIDTH                  = 64;
  localparam DQS_WIDTH                 = 8;
  localparam DM_WIDTH                  = 8;
  localparam DRAM_WIDTH                = 8;
  localparam RANK_WIDTH                = 1;
  localparam tCK                       = 938 ; //DDR3 interface clock period in ps
  localparam real SYSCLK_PERIOD        = tCK;
  localparam NUM_PHYSICAL_PARTS        = (DQ_WIDTH/DRAM_WIDTH) ;
  parameter CS_WIDTH                   = 1;
  parameter ODT_WIDTH                  = 1;
  parameter CA_MIRROR                      = "OFF";

  localparam MRS                       = 3'b000;
  localparam REF                       = 3'b001;
  localparam PRE                       = 3'b010;
  localparam ACT                       = 3'b011;
  localparam WR                        = 3'b100;
  localparam RD                        = 3'b101;
  localparam ZQC                       = 3'b110;
  localparam NOP                       = 3'b111;

  //initial begin
  //   $shm_open("waves.shm");
  //   $shm_probe("ACMTF");
  //end

  wire  [15:0]          c0_ddr3_addr_sdram[1:0];
  wire  [2:0]           c0_ddr3_ba_sdram[1:0];

  input  [15:0]         c0_ddr3_addr;
  input  [2:0]          c0_ddr3_ba;
  input                 c0_ddr3_ras_n;
  input                 c0_ddr3_cas_n;
  input                 c0_ddr3_we_n;
  input  [0:0]          c0_ddr3_cke;
  input  [0:0]          c0_ddr3_odt;
  input  [0:0]          c0_ddr3_cs_n;

  wire  [0:0] c0_ddr3_ck_p_int;
  wire  [0:0] c0_ddr3_ck_n_int;

  input  c0_ddr3_ck_p;
  input  c0_ddr3_ck_n;
  input                 c0_ddr3_reset_n;
  input  [7:0]          c0_ddr3_dm;
  inout  [63:0]         c0_ddr3_dq;
  inout  [7:0]          c0_ddr3_dqs_n;
  inout  [7:0]          c0_ddr3_dqs_p;

  wire                      c0_data_compare_error;

  reg  [31:0]          cmdName;

  // Input clock is assumed to be equal to the memory clock frequency
  // User should change the parameter as necessary if a different input
  // clock frequency is used
  localparam real CLKIN_PERIOD_NS = 14071 / 1000.0;

  assign c0_ddr3_ck_p = c0_ddr3_ck_p_int[0];
  assign c0_ddr3_ck_n = c0_ddr3_ck_n_int[0];


  assign c0_ddr3_addr_sdram[0] = c0_ddr3_addr;

  assign c0_ddr3_addr_sdram[1] = (CA_MIRROR == "ON") ? 
  {c0_ddr3_addr[ADDR_WIDTH-1:9], 
  c0_ddr3_addr[7], c0_ddr3_addr[8], 
  c0_ddr3_addr[5], c0_ddr3_addr[6], 
  c0_ddr3_addr[3], c0_ddr3_addr[4], 
  c0_ddr3_addr[2:0]} : 
  c0_ddr3_addr; 
  
  assign c0_ddr3_ba_sdram[0] = c0_ddr3_ba; 
  
  assign c0_ddr3_ba_sdram[1] = (CA_MIRROR == "ON") ? 
  {c0_ddr3_ba[2], 
  c0_ddr3_ba[0], 
  c0_ddr3_ba[1]} : 
  c0_ddr3_ba;



always @(*)
  if (c0_ddr3_cs_n == 4'b1111) cmdName = "DSEL";
  else
  casez ({c0_ddr3_ras_n, c0_ddr3_cas_n, c0_ddr3_we_n})
    ACT:     cmdName = "ACT";
    MRS:     cmdName = "MRS";
    REF:     cmdName = "REF";
    PRE:     cmdName = "PRE";
    WR:      cmdName = "WR";
    RD:      cmdName = "RD";
    ZQC:     cmdName = "ZQC";
    NOP:     cmdName = "NOP";
   default:  cmdName = "***";
endcase


  //===========================================================================
  //                         Memory Model instantiation
  //===========================================================================

genvar r;
genvar i;
generate
  if (DRAM_WIDTH == 4) begin: mem_model_x4
    for (r = 0; r < RANK_WIDTH ; r=r+1) begin:memRank
    for (i = 0; i < (DQ_WIDTH/DRAM_WIDTH) ; i=i+1) begin:memModel
      ddr3 u_ddr3_x4 (
          .tdqs_n  ()
         ,.addr    (c0_ddr3_addr_sdram[r])
         ,.ba      (c0_ddr3_ba_sdram[r])
         ,.cas_n   (c0_ddr3_cas_n)
         ,.cke     (c0_ddr3_cke[r%2])
         ,.odt     (c0_ddr3_odt[r%2])
         ,.ras_n   (c0_ddr3_ras_n)
         ,.we_n    (c0_ddr3_we_n)
         ,.ck      (c0_ddr3_ck_p)
         ,.ck_n    (c0_ddr3_ck_n)
         ,.cs_n    (c0_ddr3_cs_n[r])
  
         ,.rst_n   (c0_ddr3_reset_n)
         ,.dm_tdqs (c0_ddr3_dm[i])
         ,.dq      (c0_ddr3_dq[i*4+:4])
         ,.dqs     (c0_ddr3_dqs_p[i])
         ,.dqs_n   (c0_ddr3_dqs_n[i])
      );
    end
    end
  end

  else if (DRAM_WIDTH == 8) begin: mem_model_x8
    for (r = 0; r < RANK_WIDTH ; r=r+1) begin:memRank
    for (i = 0; i < DQ_WIDTH/DRAM_WIDTH; i=i+1) begin:memModel
      ddr3 u_ddr3_x8 (
          .tdqs_n  ()

         ,.addr    (c0_ddr3_addr_sdram[r])
         ,.ba      (c0_ddr3_ba_sdram[r])
         ,.cas_n   (c0_ddr3_cas_n)
         ,.cke     (c0_ddr3_cke[r])
         ,.odt     (c0_ddr3_odt[r])
         ,.ras_n   (c0_ddr3_ras_n)
         ,.we_n    (c0_ddr3_we_n)

         ,.ck      (c0_ddr3_ck_p)
         ,.ck_n    (c0_ddr3_ck_n)
         ,.cs_n    (c0_ddr3_cs_n[r])
         ,.rst_n   (c0_ddr3_reset_n)
         ,.dm_tdqs (c0_ddr3_dm[i])
         ,.dq      (c0_ddr3_dq[i*8+:8])
         ,.dqs     (c0_ddr3_dqs_p[i])
         ,.dqs_n   (c0_ddr3_dqs_n[i])
      );
    end
    end
  end
  else begin: mem_model_x16
      if (DQ_WIDTH/16) begin: mem
    for (r = 0; r < RANK_WIDTH ; r=r+1) begin:memRank
        for (i = 0; i < (DQ_WIDTH/DRAM_WIDTH); i=i+1) begin:memModel
          ddr3 u_ddr3_x16 (
              .tdqs_n  ()

         ,.addr    (c0_ddr3_addr_sdram[r])
         ,.ba      (c0_ddr3_ba_sdram[r])
         ,.cas_n   (c0_ddr3_cas_n)
         ,.cke     (c0_ddr3_cke[r])
         ,.odt     (c0_ddr3_odt[r])
         ,.ras_n   (c0_ddr3_ras_n)
         ,.we_n    (c0_ddr3_we_n)
         ,.ck      (c0_ddr3_ck_p)
         ,.ck_n    (c0_ddr3_ck_n)
         ,.cs_n    (c0_ddr3_cs_n[r])
         ,.rst_n   (c0_ddr3_reset_n)

             ,.dm_tdqs (c0_ddr3_dm[(2*(i+1)-1):(2*i)])
             ,.dq      (c0_ddr3_dq[16*(i+1)-1:16*(i)])
             ,.dqs     (c0_ddr3_dqs_p[(2*(i+1)-1):(2*i)])
             ,.dqs_n   (c0_ddr3_dqs_n[(2*(i+1)-1):(2*i)])
          );
        end
        end
      end

      if (DQ_WIDTH%16) begin: mem_extra_bits
    for (r = 0; r < RANK_WIDTH ; r=r+1) begin:memRank
          ddr3 u_ddr3_x16 (
              .tdqs_n  ()

         ,.addr    (c0_ddr3_addr_sdram[r])
         ,.ba      (c0_ddr3_ba_sdram[r])
         ,.cas_n   (c0_ddr3_cas_n)
         ,.cke     (c0_ddr3_cke[r])
         ,.odt     (c0_ddr3_odt[r])
         ,.ras_n   (c0_ddr3_ras_n)
         ,.we_n    (c0_ddr3_we_n)
         ,.ck      (c0_ddr3_ck_p)
         ,.ck_n    (c0_ddr3_ck_n)
         ,.cs_n    (c0_ddr3_cs_n[r])
         ,.rst_n   (c0_ddr3_reset_n)

             ,.dm_tdqs ({ c0_ddr3_dm[DM_WIDTH-1],
                          c0_ddr3_dm[DM_WIDTH-1]})
             ,.dq      ({ c0_ddr3_dq[DQ_WIDTH-1:(DQ_WIDTH-8)],
                          c0_ddr3_dq[DQ_WIDTH-1:(DQ_WIDTH-8)]})
             ,.dqs     ({ c0_ddr3_dqs_p[DQS_WIDTH-1],
                          c0_ddr3_dqs_p[DQS_WIDTH-1]})
             ,.dqs_n   ({ c0_ddr3_dqs_n[DQS_WIDTH-1],
                          c0_ddr3_dqs_n[DQS_WIDTH-1]})
          );
      end
      end
  end
endgenerate

   
endmodule

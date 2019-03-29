

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
// Design Name      : DDR4_SDRAM
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

module ddr4_tb_top (
     c0_ddr4_act_n,
     c0_ddr4_adr,
     c0_ddr4_ba,
     c0_ddr4_bg,
     c0_ddr4_cke,
     c0_ddr4_odt,
     c0_ddr4_cs_n,
     c0_ddr4_ck_t_int,
     c0_ddr4_ck_c_int,
     c0_ddr4_reset_n,
     c0_ddr4_dm_dbi_n,
     c0_ddr4_dq,
     c0_ddr4_dqs_c,
     c0_ddr4_dqs_t
);

  localparam ADDR_WIDTH                    = 17;
  localparam DQ_WIDTH                      = 64;
  localparam DQS_WIDTH                     = 8;
  localparam DM_WIDTH                      = 8;
  localparam DRAM_WIDTH                    = 16;
  localparam tCK                           = 833 ; //DDR4 interface clock period in ps
  localparam real SYSCLK_PERIOD            = tCK; 
  localparam NUM_PHYSICAL_PARTS = (DQ_WIDTH/DRAM_WIDTH) ;
  localparam           CLAMSHELL_PARTS = (NUM_PHYSICAL_PARTS/2);
  localparam           ODD_PARTS = ((CLAMSHELL_PARTS*2) < NUM_PHYSICAL_PARTS) ? 1 : 0;
  parameter RANK_WIDTH                       = 1;
  parameter CS_WIDTH                       = 1;
  parameter ODT_WIDTH                      = 1;
  parameter CA_MIRROR                      = "OFF";


  localparam MRS                           = 3'b000;
  localparam REF                           = 3'b001;
  localparam PRE                           = 3'b010;
  localparam ACT                           = 3'b011;
  localparam WR                            = 3'b100;
  localparam RD                            = 3'b101;
  localparam ZQC                           = 3'b110;
  localparam NOP                           = 3'b111;

  import arch_package::*;
  parameter UTYPE_density CONFIGURED_DENSITY = _4G;

  // Input clock is assumed to be equal to the memory clock frequency
  // User should change the parameter as necessary if a different input
  // clock frequency is used
  localparam real CLKIN_PERIOD_NS = 3332 / 1000.0;

  //initial begin
  //   $shm_open("waves.shm");
  //   $shm_probe("ACMTF");
  //end

  reg  [16:0]     c0_ddr4_adr_sdram[1:0];
  reg  [1:0]      c0_ddr4_ba_sdram[1:0];
  reg  [0:0]      c0_ddr4_bg_sdram[1:0];


  input           c0_ddr4_act_n;
  input  [16:0]   c0_ddr4_adr;
  input  [1:0]    c0_ddr4_ba;
  input  [0:0]    c0_ddr4_bg;
  input  [0:0]    c0_ddr4_cke;
  input  [0:0]    c0_ddr4_odt;
  input  [0:0]    c0_ddr4_cs_n;

  input  [0:0]    c0_ddr4_ck_t_int;
  input  [0:0]    c0_ddr4_ck_c_int;

  wire            c0_ddr4_ck_t;
  wire            c0_ddr4_ck_c;

  input           c0_ddr4_reset_n;

  inout  [7:0]    c0_ddr4_dm_dbi_n;
  inout  [63:0]   c0_ddr4_dq;
  inout  [7:0]    c0_ddr4_dqs_c;
  inout  [7:0]    c0_ddr4_dqs_t;

  reg  [31:0] cmdName;
  bit  en_model;
  tri        model_enable = en_model;

  assign c0_ddr4_ck_t = c0_ddr4_ck_t_int[0];
  assign c0_ddr4_ck_c = c0_ddr4_ck_c_int[0];

  always @( * ) begin
     c0_ddr4_adr_sdram[0]   <=  c0_ddr4_adr;
     c0_ddr4_adr_sdram[1]   <=  (CA_MIRROR == "ON") ?
                                       {c0_ddr4_adr[ADDR_WIDTH-1:14],
                                        c0_ddr4_adr[11], c0_ddr4_adr[12],
                                        c0_ddr4_adr[13], c0_ddr4_adr[10:9],
                                        c0_ddr4_adr[7], c0_ddr4_adr[8],
                                        c0_ddr4_adr[5], c0_ddr4_adr[6],
                                        c0_ddr4_adr[3], c0_ddr4_adr[4],
                                        c0_ddr4_adr[2:0]} :
                                        c0_ddr4_adr;
     c0_ddr4_ba_sdram[0]    <=  c0_ddr4_ba;
     c0_ddr4_ba_sdram[1]    <=  (CA_MIRROR == "ON") ?
                                        {c0_ddr4_ba[0],
                                         c0_ddr4_ba[1]} :
                                         c0_ddr4_ba;
     c0_ddr4_bg_sdram[0]    <=  c0_ddr4_bg;
     c0_ddr4_bg_sdram[1]    <=  c0_ddr4_bg;
  end



  reg [ADDR_WIDTH-1:0] DDR4_ADRMOD[RANK_WIDTH-1:0];

  always @(*)
    if (c0_ddr4_cs_n == 4'b1111)
      cmdName = "DSEL";
    else
    if (c0_ddr4_act_n)
      casez (DDR4_ADRMOD[0][16:14])
       MRS:     cmdName = "MRS";
       REF:     cmdName = "REF";
       PRE:     cmdName = "PRE";
       WR:      cmdName = "WR";
       RD:      cmdName = "RD";
       ZQC:     cmdName = "ZQC";
       NOP:     cmdName = "NOP";
      default:  cmdName = "***";
      endcase
    else
      cmdName = "ACT";

   reg wr_en ;
   always@(posedge c0_ddr4_ck_t)begin
     if(!c0_ddr4_reset_n)begin
       wr_en <= #100 1'b0 ;
     end else begin
       if(cmdName == "WR")begin
         wr_en <= #100 1'b1 ;
       end else if (cmdName == "RD")begin
         wr_en <= #100 1'b0 ;
       end
     end
   end

genvar rnk;
generate
for (rnk = 0; rnk < CS_WIDTH; rnk++) begin:rankup
 always @(*)
    if (c0_ddr4_act_n)
      casez (c0_ddr4_adr_sdram[0][16:14])
      WR, RD: begin
        DDR4_ADRMOD[rnk] = c0_ddr4_adr_sdram[rnk] & 18'h1C7FF;
      end
      default: begin
        DDR4_ADRMOD[rnk] = c0_ddr4_adr_sdram[rnk];
      end
      endcase
    else begin
      DDR4_ADRMOD[rnk] = c0_ddr4_adr_sdram[rnk];
    end
end
endgenerate

  //===========================================================================
  //                         Memory Model instantiation
  //===========================================================================
  genvar i;
  genvar r;
  genvar s;

  generate
    if (DRAM_WIDTH == 4) begin: mem_model_x4

      DDR4_if #(.CONFIGURED_DQ_BITS (4)) iDDR4[0:(RANK_WIDTH*NUM_PHYSICAL_PARTS)-1]();
      for (r = 0; r < RANK_WIDTH; r++) begin:memModels_Ri
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:memModel
        ddr4_model  #
          (
           .CONFIGURED_DQ_BITS (4),
           .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
           ) ddr4_model(
            .model_enable (model_enable),
            .iDDR4        (iDDR4[(r*NUM_PHYSICAL_PARTS)+i])
        );
        end
      end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQ
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQ1
          for (s = 0; s < 4; s++) begin:tranDQp
            `ifdef XILINX_SIMULATOR
             short bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*4]);
             `else
              tran bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*4]);
             `endif
       end
    end
      end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQS
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQS1
        `ifdef XILINX_SIMULATOR
        short bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
        short bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
        `else
          tran bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
          tran bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
        `endif
      end
      end

       for (r = 0; r < RANK_WIDTH; r++) begin:ADDR_RANKS
         for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:ADDR_R

           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BG        = c0_ddr4_bg_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BA        = c0_ddr4_ba_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[r][ADDR_WIDTH-1] : 1'b0;
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR      = DDR4_ADRMOD[r][13:0];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CS_n = c0_ddr4_cs_n[r];

         end
       end

     for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ACT_n     = c0_ddr4_act_n;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RAS_n_A16 = DDR4_ADRMOD[r][16];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CAS_n_A15 = DDR4_ADRMOD[r][15];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].WE_n_A14  = DDR4_ADRMOD[r][14];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CKE       = c0_ddr4_cke[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ODT       = c0_ddr4_odt[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PARITY  = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].TEN     = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ZQ      = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PWR     = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_CA = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_DQ = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RESET_n = c0_ddr4_reset_n;
      end
      end
    end
    else if (DRAM_WIDTH == 8) begin: mem_model_x8

      DDR4_if #(.CONFIGURED_DQ_BITS(8)) iDDR4[0:(RANK_WIDTH*NUM_PHYSICAL_PARTS)-1]();

      for (r = 0; r < RANK_WIDTH; r++) begin:memModels_Ri1
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:memModel1
            ddr4_model #(
              .CONFIGURED_DQ_BITS(8),
              .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
                ) ddr4_model(
              .model_enable (model_enable)
             ,.iDDR4        (iDDR4[(r*NUM_PHYSICAL_PARTS)+i])
           );
         end
       end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQ2
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQ12
          for (s = 0; s < 8; s++) begin:tranDQ2
           `ifdef XILINX_SIMULATOR
           short bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*8]);
           `else
            tran bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*8]);
           `endif
          end
        end
      end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQS2
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQS12
        `ifdef XILINX_SIMULATOR
          short bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
          short bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
          short bidiDM(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n, c0_ddr4_dm_dbi_n[i]);
        `else
          tran bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
          tran bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
          tran bidiDM(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n, c0_ddr4_dm_dbi_n[i]);
        `endif
        end
      end

       for (r = 0; r < RANK_WIDTH; r++) begin:ADDR_RANKS
         for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:ADDR_R

           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BG        = c0_ddr4_bg_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BA        = c0_ddr4_ba_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[r][ADDR_WIDTH-1] : 1'b0;
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR      = DDR4_ADRMOD[r][13:0];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CS_n = c0_ddr4_cs_n[r];

         end
       end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS1
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL1
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ACT_n     = c0_ddr4_act_n;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RAS_n_A16 = DDR4_ADRMOD[r][16];
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CAS_n_A15 = DDR4_ADRMOD[r][15];
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].WE_n_A14  = DDR4_ADRMOD[r][14];

          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CKE       = c0_ddr4_cke[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ODT       = c0_ddr4_odt[r];
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PARITY  = 1'b0;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].TEN     = 1'b0;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ZQ      = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PWR     = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_CA = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_DQ = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RESET_n = c0_ddr4_reset_n;
         end
      end

    end else begin: mem_model_x16

      if (DQ_WIDTH/16) begin: mem

      DDR4_if #(.CONFIGURED_DQ_BITS (16)) iDDR4[0:(RANK_WIDTH*NUM_PHYSICAL_PARTS)-1]();

        for (r = 0; r < RANK_WIDTH; r++) begin:memModels_Ri2
          for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:memModel2
            ddr4_model  #
            (
             .CONFIGURED_DQ_BITS (16),
             .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
             )  ddr4_model(
                .model_enable (model_enable),
                .iDDR4        (iDDR4[(r*NUM_PHYSICAL_PARTS)+i])
            );
          end
        end

        for (r = 0; r < RANK_WIDTH; r++) begin:tranDQ3
          for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQ13
            for (s = 0; s < 16; s++) begin:tranDQ2
              `ifdef XILINX_SIMULATOR
              short bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*16]);
              `else
              tran bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*16]);
              `endif
            end
          end
        end

        for (r = 0; r < RANK_WIDTH; r++) begin:tranDQS3
          for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQS13
          `ifdef XILINX_SIMULATOR
            short bidiDQS0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[0], c0_ddr4_dqs_t[(2*i)]);
            short bidiDQS0_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[0], c0_ddr4_dqs_c[(2*i)]);
            short bidiDM0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[0], c0_ddr4_dm_dbi_n[(2*i)]);
            short bidiDQS1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[1], c0_ddr4_dqs_t[((2*i)+1)]);
            short bidiDQS1_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[1], c0_ddr4_dqs_c[((2*i)+1)]);
            short bidiDM1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[1], c0_ddr4_dm_dbi_n[((2*i)+1)]);

          `else
            tran bidiDQS0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[0], c0_ddr4_dqs_t[(2*i)]);
            tran bidiDQS0_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[0], c0_ddr4_dqs_c[(2*i)]);
            tran bidiDM0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[0], c0_ddr4_dm_dbi_n[(2*i)]);
            tran bidiDQS1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[1], c0_ddr4_dqs_t[((2*i)+1)]);
            tran bidiDQS1_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[1], c0_ddr4_dqs_c[((2*i)+1)]);
            tran bidiDM1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[1], c0_ddr4_dm_dbi_n[((2*i)+1)]);
          `endif
        end
      end

       for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS
         for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL

           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BG        = c0_ddr4_bg_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BA        = c0_ddr4_ba_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[r][ADDR_WIDTH-1] : 1'b0;
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR      = DDR4_ADRMOD[r][13:0];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CS_n = c0_ddr4_cs_n[r];

         end
       end

    for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS1
      for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL1
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ACT_n     = c0_ddr4_act_n;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RAS_n_A16 = DDR4_ADRMOD[r][16];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CAS_n_A15 = DDR4_ADRMOD[r][15];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].WE_n_A14  = DDR4_ADRMOD[r][14];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CKE       = c0_ddr4_cke[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ODT       = c0_ddr4_odt[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PARITY  = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].TEN     = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ZQ      = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PWR     = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_CA = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_DQ = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RESET_n = c0_ddr4_reset_n;
          end
        end
      end

      if (DQ_WIDTH%16) begin: mem_extra_bits
       // DDR4 X16 dual rank is not supported
        DDR4_if #(.CONFIGURED_DQ_BITS (16)) iDDR4[(DQ_WIDTH/DRAM_WIDTH):(DQ_WIDTH/DRAM_WIDTH)]();

        ddr4_model  #
          (
           .CONFIGURED_DQ_BITS (16),
           .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
           )  ddr4_model(
            .model_enable (model_enable),
            .iDDR4        (iDDR4[(DQ_WIDTH/DRAM_WIDTH)])
        );

        for (i = (DQ_WIDTH/DRAM_WIDTH)*16; i < DQ_WIDTH; i=i+1) begin:tranDQ
          `ifdef XILINX_SIMULATOR
          short bidiDQ(iDDR4[i/16].DQ[i%16], c0_ddr4_dq[i]);
          short bidiDQ_msb(iDDR4[i/16].DQ[(i%16)+8], c0_ddr4_dq[i]);
          `else
          tran bidiDQ(iDDR4[i/16].DQ[i%16], c0_ddr4_dq[i]);
          tran bidiDQ_msb(iDDR4[i/16].DQ[(i%16)+8], c0_ddr4_dq[i]);
          `endif
        end

        `ifdef XILINX_SIMULATOR
        short bidiDQS0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[0], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        short bidiDQS0_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[0], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        short bidiDM0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[0], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        short bidiDQS1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[1], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        short bidiDQS1_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[1], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        short bidiDM1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[1], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        `else
        tran bidiDQS0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[0], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        tran bidiDQS0_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[0], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        tran bidiDM0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[0], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        tran bidiDQS1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[1], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        tran bidiDQS1_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[1], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        tran bidiDM1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[1], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        `endif

        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ACT_n = c0_ddr4_act_n;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].RAS_n_A16 = DDR4_ADRMOD[0][16];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CAS_n_A15 = DDR4_ADRMOD[0][15];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].WE_n_A14 = DDR4_ADRMOD[0][14];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CKE = c0_ddr4_cke[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ODT = c0_ddr4_odt[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].BG = c0_ddr4_bg_sdram[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].BA = c0_ddr4_ba_sdram[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[0][ADDR_WIDTH-1] : 1'b0;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ADDR = DDR4_ADRMOD[0][13:0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].RESET_n = c0_ddr4_reset_n;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].TEN     = 1'b0;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ZQ      = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].PWR     = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].VREF_CA = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].VREF_DQ = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CS_n = c0_ddr4_cs_n[0];
      end
    end
  endgenerate

endmodule

/*
 * This whole thing is built on top of AXI MAC's reference design.
 * We mainly changed the clock generation and replaced its packet
 * generation/checker with our LegoFPGA BD design.
 *
 * What we want out of the reference design is simple
 * - Two AXI-Stream RX and TX interface
 * - A state machine to bring PHY up
 *
 *
 * FIXME
 * Current combination/naming is a mess. Change later.
 * So both axi mac and qspf mac can use the same LegoFPGA diagram.
 */

`timescale 1ns / 1ps

module top(
    // asynchronous reset
    input          sys_rst              ,
    output         mtrlb_pktchk_error   ,
    output         mtrlb_activity_flash ,
    output         phy_rst_n            ,

    input          sgmii_rxn            ,
    input          sgmii_rxp            ,
    output         sgmii_txn            ,
    output         sgmii_txp            ,

    input          mgt_clk_n            ,
    input          mgt_clk_p            ,

    inout          mdio                 ,
    output         mdc                  ,

    input   [3:0]  control_data         ,
    input          control_valid        ,
    output         control_ready        ,
    input          start_config         ,

    // VCU108: 125MHz clock input from board
    input          sysclk_125_clk_p,
    input          sysclk_125_clk_n
);

  wire clk_300, clk_125, clk_100, clk_166, clk_50;
  wire mmcm_lock_i, mmcm_lock_i_2;

  clock_axi_eth clk_gen (
        .clk_in1_p_0(sysclk_125_clk_p),
        .clk_in1_n_0(sysclk_125_clk_n),
        
        .mmcm_locked_i(mmcm_locked_i),
        .mmcm_lock_i_2(mmcm_lock_i_2),
        
        .clk_300(clk_300),
        .clk_125(clk_125),
        .clk_100(clk_100),
        .clk_166(clk_166),
        .clk_50(clk_50)
  );

  axi_ethernet_0_example system (
      .sys_rst              (sys_rst),
      .start_config         (start_config),
 
      .mtrlb_pktchk_error   (mtrlb_pktchk_error),
      .mtrlb_activity_flash (mtrlb_activity_flash),

      .control_data         (control_data  ),
      .control_valid        (control_valid ),
      .control_ready        (control_ready ),
      .mgt_clk_p            (mgt_clk_p),
      .mgt_clk_n            (mgt_clk_n),
      .sgmii_rxn            (sgmii_rxn),
      .sgmii_rxp            (sgmii_rxp),
      .sgmii_txn            (sgmii_txn),
      .sgmii_txp            (sgmii_txp),
      .phy_rst_n            (phy_rst_n),

      .mdc                  (mdc),
      .mdio                 (mdio),

      .clk_300(clk_300),
      .clk_125(clk_125),
      .clk_100(clk_100),
      .clk_166(clk_166),
      .clk_50(clk_50),
      .mmcm_locked_i(mmcm_locked_i)
   );

endmodule

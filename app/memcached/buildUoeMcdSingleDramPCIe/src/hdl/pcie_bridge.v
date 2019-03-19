`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.03.2014 14:42:56
// Design Name: 
// Module Name: pcie_and_stats
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pcie_bridge
   (
  input [7:0]pcie_7x_mgt_rxn,
  input [7:0]pcie_7x_mgt_rxp,
  output [7:0]pcie_7x_mgt_txn,
  output [7:0]pcie_7x_mgt_txp,
  input pcie_clkp, 
  input pcie_clkn,
  input pcie_reset,
  
  output clkOut,
  output user_lnk_up,
  
    //address write
  output  [31: 0] pcie_axi_AWADDR,
  output  pcie_axi_AWVALID,
  input pcie_axi_AWREADY,
     
  //data write
  output  [31: 0]   pcie_axi_WDATA,
  output  [3: 0] pcie_axi_WSTRB,
  output  pcie_axi_WVALID,
  input pcie_axi_WREADY,
     
  //write response (handhake)
  input [1:0] pcie_axi_BRESP,
  input pcie_axi_BVALID,
  output  pcie_axi_BREADY,
     
  //address read
  output  [31: 0] pcie_axi_ARADDR,
  output  pcie_axi_ARVALID,
  input pcie_axi_ARREADY,
     
  //data read
  input [31: 0] pcie_axi_RDATA,
  input [1:0] pcie_axi_RRESP,
  input pcie_axi_RVALID,
  output  pcie_axi_RREADY
 );
  
  wire sys_clk;
  wire GND_1;
  wire [11:0]axi_bram_ctrl_1_bram_porta_ADDR;
  wire axi_bram_ctrl_1_bram_porta_CLK;
  wire [31:0]axi_bram_ctrl_1_bram_porta_DIN;
  wire [31:0]axi_bram_ctrl_1_bram_porta_DOUT;
  wire axi_bram_ctrl_1_bram_porta_EN;
  wire axi_bram_ctrl_1_bram_porta_RST;
  wire [3:0]axi_bram_ctrl_1_bram_porta_WE;

  
   wire [63:0]pcie3_7x_0_m_axis_cq_TDATA;
   wire [1:0]pcie3_7x_0_m_axis_cq_TKEEP;
   wire pcie3_7x_0_m_axis_cq_TLAST;
   wire [21:0]pcie3_7x_0_m_axis_cq_TREADY;
   wire [84:0]pcie3_7x_0_m_axis_cq_TUSER;
   wire pcie3_7x_0_m_axis_cq_TVALID;
  wire [7:0]pcie3_7x_0_pcie_7x_mgt_rxn;
  wire [7:0]pcie3_7x_0_pcie_7x_mgt_rxp;
  wire [7:0]pcie3_7x_0_pcie_7x_mgt_txn;
  wire [7:0]pcie3_7x_0_pcie_7x_mgt_txp;
  wire pcie3_7x_0_user_clk;
  wire pcie3_7x_0_user_lnk_up;
  wire [63:0]pcie_2_axilite_0_m_axis_cc_TDATA;
  wire [1:0]pcie_2_axilite_0_m_axis_cc_TKEEP;
  wire pcie_2_axilite_0_m_axis_cc_TLAST;
  wire [3:0]pcie_2_axilite_0_m_axis_cc_TREADY;
  wire [32:0]pcie_2_axilite_0_m_axis_cc_TUSER;
  wire pcie_2_axilite_0_m_axis_cc_TVALID;
  
  assign pcie3_7x_0_pcie_7x_mgt_rxn = pcie_7x_mgt_rxn[7:0];
  assign pcie3_7x_0_pcie_7x_mgt_rxp = pcie_7x_mgt_rxp[7:0];
  assign pcie_7x_mgt_txn[7:0] = pcie3_7x_0_pcie_7x_mgt_txn;
  assign pcie_7x_mgt_txp[7:0] = pcie3_7x_0_pcie_7x_mgt_txp;
   
 
 assign clkOut= pcie3_7x_0_user_clk;
 assign user_lnk_up = pcie3_7x_0_user_lnk_up;
 
//assign pcie3_7x_0_m_axis_cq_TUSER = 85'b0;
//assign pcie_2_axilite_0_m_axis_cc_TUSER = 33'b0;
  
GND GND(.G(GND_1));
       
       
       IBUFDS_GTE2 #(
            .CLKCM_CFG("TRUE"),   // Refer to Transceiver User Guide
            .CLKRCV_TRST("TRUE"), // Refer to Transceiver User Guide
            .CLKSWING_CFG(2'b11)  // Refer to Transceiver User Guide
         )
         IBUFDS_GTE2_inst (
            .O(sys_clk),         // 1-bit output: Refer to Transceiver User Guide
            .ODIV2(),            // 1-bit output: Refer to Transceiver User Guide
            .CEB(GND_1),          // 1-bit input: Refer to Transceiver User Guide
            .I(pcie_clkp),        // 1-bit input: Refer to Transceiver User Guide
            .IB(pcie_clkn)        // 1-bit input: Refer to Transceiver User Guide
         );  
        
        
pcie2axilite_sub_pcie3_7x_0 pcie3_7x_0
       (.cfg_interrupt_int({GND_1,GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_attr({GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_function_number({GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_int({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_pending_status({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_select({GND_1,GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_tph_present(GND_1),
        .cfg_interrupt_msi_tph_st_tag({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .cfg_interrupt_msi_tph_type({GND_1,GND_1}),
        .cfg_interrupt_pending({GND_1,GND_1}),
        .int_pclk_sel_slave({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .m_axis_cq_tdata(pcie3_7x_0_m_axis_cq_TDATA),
        .m_axis_cq_tkeep(pcie3_7x_0_m_axis_cq_TKEEP),
        .m_axis_cq_tlast(pcie3_7x_0_m_axis_cq_TLAST),
        .m_axis_cq_tready(pcie3_7x_0_m_axis_cq_TREADY),
        .m_axis_cq_tuser(pcie3_7x_0_m_axis_cq_TUSER),
        .m_axis_cq_tvalid(pcie3_7x_0_m_axis_cq_TVALID),
        .m_axis_rc_tready({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .pci_exp_rxn(pcie3_7x_0_pcie_7x_mgt_rxn),
        .pci_exp_rxp(pcie3_7x_0_pcie_7x_mgt_rxp),
        .pci_exp_txn(pcie3_7x_0_pcie_7x_mgt_txn),
        .pci_exp_txp(pcie3_7x_0_pcie_7x_mgt_txp),
        .s_axis_cc_tdata(pcie_2_axilite_0_m_axis_cc_TDATA),
        .s_axis_cc_tkeep(pcie_2_axilite_0_m_axis_cc_TKEEP),
        .s_axis_cc_tlast(pcie_2_axilite_0_m_axis_cc_TLAST),
        .s_axis_cc_tready(pcie_2_axilite_0_m_axis_cc_TREADY),
        .s_axis_cc_tuser(pcie_2_axilite_0_m_axis_cc_TUSER),
        .s_axis_cc_tvalid(pcie_2_axilite_0_m_axis_cc_TVALID),
        .s_axis_rq_tdata({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .s_axis_rq_tkeep({GND_1,GND_1}),
        .s_axis_rq_tlast(GND_1),
        .s_axis_rq_tuser({GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1,GND_1}),
        .s_axis_rq_tvalid(GND_1),
        .sys_clk(sys_clk),
        .sys_reset(pcie_reset),
        .user_clk(pcie3_7x_0_user_clk),
        .user_lnk_up(pcie3_7x_0_user_lnk_up));
        
        
pcie2axilite_sub_pcie_2_axilite_0 pcie_2_axilite_0
       (.axi_aresetn(pcie3_7x_0_user_lnk_up),
        .axi_clk(pcie3_7x_0_user_clk),
        .m_axi_araddr(pcie_axi_ARADDR),
        .m_axi_arprot(),
        .m_axi_arready(pcie_axi_ARREADY),
        .m_axi_arvalid(pcie_axi_ARVALID),
        .m_axi_awaddr(pcie_axi_AWADDR),
        .m_axi_awprot(),
        .m_axi_awready(pcie_axi_AWREADY),
        .m_axi_awvalid(pcie_axi_AWVALID),
        .m_axi_bready(pcie_axi_BREADY),
        .m_axi_bresp(pcie_axi_BRESP),
        .m_axi_bvalid(pcie_axi_BVALID),
        .m_axi_rdata(pcie_axi_RDATA),
        .m_axi_rready(pcie_axi_RREADY),
        .m_axi_rresp(pcie_axi_RRESP),
        .m_axi_rvalid(pcie_axi_RVALID),
        .m_axi_wdata(pcie_axi_WDATA),
        .m_axi_wready(pcie_axi_WREADY),
        .m_axi_wstrb(pcie_axi_WSTRB),
        .m_axi_wvalid(pcie_axi_WVALID),
        .m_axis_cc_tdata(pcie_2_axilite_0_m_axis_cc_TDATA),
        .m_axis_cc_tkeep(pcie_2_axilite_0_m_axis_cc_TKEEP),
        .m_axis_cc_tlast(pcie_2_axilite_0_m_axis_cc_TLAST),
        .m_axis_cc_tready(pcie_2_axilite_0_m_axis_cc_TREADY),
        .m_axis_cc_tuser(pcie_2_axilite_0_m_axis_cc_TUSER),
        .m_axis_cc_tvalid(pcie_2_axilite_0_m_axis_cc_TVALID),
        .s_axis_cq_tdata(pcie3_7x_0_m_axis_cq_TDATA),
        .s_axis_cq_tkeep(pcie3_7x_0_m_axis_cq_TKEEP),
        .s_axis_cq_tlast(pcie3_7x_0_m_axis_cq_TLAST),
        .s_axis_cq_tready(pcie3_7x_0_m_axis_cq_TREADY),
        .s_axis_cq_tuser(pcie3_7x_0_m_axis_cq_TUSER),
        .s_axis_cq_tvalid(pcie3_7x_0_m_axis_cq_TVALID));

endmodule


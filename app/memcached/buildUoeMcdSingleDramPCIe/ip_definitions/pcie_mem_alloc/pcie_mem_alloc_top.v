module pcie_mem_alloc_top (
    input axi_clk,
    input axi_resetn,
    
    /* signals from and to mcd_pipeline */
    input [31:0] mcd2alloc_data,	// Address reclamation
    input        mcd2alloc_valid,
    output       mcd2alloc_ready,
    
    output [31:0] alloc2mcd_dram_data,	// Address assignment for DRAM
    output        alloc2mcd_dram_valid,
    input         alloc2mcd_dram_ready,
           
    /* flush req from memcached */ 
    input  mcd2alloc_flushReq,                                               
    output alloc2mcd_flushAck,                                              
    input  mcd2alloc_flushDone,
     
    /* pcie ports - out till the top */
    input  [7:0] pcie_7x_mgt_rxn,
    input  [7:0] pcie_7x_mgt_rxp,
    output [7:0] pcie_7x_mgt_txn,
    output [7:0] pcie_7x_mgt_txp,
    input        pcie_clkp,
    input        pcie_clkn,
    input        pcie_reset
);
      wire [31: 0] pcie_axi_AWADDR;
      wire pcie_axi_AWVALID;
      wire pcie_axi_AWREADY;
      wire [31: 0]   pcie_axi_WDATA;
      wire [3: 0] pcie_axi_WSTRB;
      wire pcie_axi_WVALID;
      wire pcie_axi_WREADY;
      wire [1:0] pcie_axi_BRESP;
      wire pcie_axi_BVALID;
      wire pcie_axi_BREADY;
      wire [31: 0] pcie_axi_ARADDR;
      wire pcie_axi_ARVALID;
      wire pcie_axi_ARREADY;
      wire [31: 0] pcie_axi_RDATA;
      wire [1:0] pcie_axi_RRESP;
      wire pcie_axi_RVALID;
      wire pcie_axi_RREADY;

      wire pcie_clk;
      wire pcie_user_lnk_up;
        

pcie_mem_alloc u_mcd_pcie_alloc (
        .ACLK      (axi_clk),
        .Axi_resetn(axi_resetn),
        .stats0_data('b0),
        .stats1_data('b0),
        .stats2_data('b0),
        .stats3_data('b0),
        .pcie_axi_AWADDR (pcie_axi_AWADDR),
        .pcie_axi_AWVALID(pcie_axi_AWVALID),
        .pcie_axi_AWREADY(pcie_axi_AWREADY),
        .pcie_axi_WDATA  (pcie_axi_WDATA),
        .pcie_axi_WSTRB  (pcie_axi_WSTRB),
        .pcie_axi_WVALID (pcie_axi_WVALID),
        .pcie_axi_WREADY (pcie_axi_WREADY),
        .pcie_axi_BRESP  (pcie_axi_BRESP),
        .pcie_axi_BVALID (pcie_axi_BVALID),
        .pcie_axi_BREADY (pcie_axi_BREADY),
        .pcie_axi_ARADDR (pcie_axi_ARADDR),
        .pcie_axi_ARVALID(pcie_axi_ARVALID),
        .pcie_axi_ARREADY(pcie_axi_ARREADY),
        .pcie_axi_RDATA  (pcie_axi_RDATA),
        .pcie_axi_RRESP  (pcie_axi_RRESP),
        .pcie_axi_RVALID (pcie_axi_RVALID),
        .pcie_axi_RREADY (pcie_axi_RREADY),
        .pcieClk         (pcie_clk),
        .pcie_user_lnk_up(pcie_user_lnk_up),
        .memcached2memAllocation_data (mcd2alloc_data),
        .memcached2memAllocation_valid(mcd2alloc_valid),
        .memcached2memAllocation_ready(mcd2alloc_ready),
        .memAllocation2memcached_dram_data (alloc2mcd_dram_data),
        .memAllocation2memcached_dram_valid(alloc2mcd_dram_valid),
        .memAllocation2memcached_dram_ready(alloc2mcd_dram_ready),
        .flushReq(mcd2alloc_flushReq),
        .flushAck(alloc2mcd_flushAck),
        .flushDone(mcd2alloc_flushDone)
); 


pcie_bridge pcie_bridge_inst(
    .pcie_7x_mgt_rxn(pcie_7x_mgt_rxn),
    .pcie_7x_mgt_rxp(pcie_7x_mgt_rxp),
    .pcie_7x_mgt_txn(pcie_7x_mgt_txn),
    .pcie_7x_mgt_txp(pcie_7x_mgt_txp),
    .pcie_clkp      (pcie_clkp), 
    .pcie_clkn      (pcie_clkn),
    .pcie_reset     (~pcie_reset),
    .clkOut         (pcie_clk),
    .user_lnk_up    (pcie_user_lnk_up),
    .pcie_axi_AWADDR (pcie_axi_AWADDR),
    .pcie_axi_AWVALID(pcie_axi_AWVALID),
    .pcie_axi_AWREADY(pcie_axi_AWREADY),
    .pcie_axi_WDATA  (pcie_axi_WDATA),
    .pcie_axi_WSTRB  (pcie_axi_WSTRB),
    .pcie_axi_WVALID (pcie_axi_WVALID),
    .pcie_axi_WREADY (pcie_axi_WREADY),
    .pcie_axi_BRESP  (pcie_axi_BRESP),
    .pcie_axi_BVALID (pcie_axi_BVALID),
    .pcie_axi_BREADY (pcie_axi_BREADY),
    .pcie_axi_ARADDR (pcie_axi_ARADDR),
    .pcie_axi_ARVALID(pcie_axi_ARVALID),
    .pcie_axi_ARREADY(pcie_axi_ARREADY),
    .pcie_axi_RDATA  (pcie_axi_RDATA),
    .pcie_axi_RRESP  (pcie_axi_RRESP),
    .pcie_axi_RVALID (pcie_axi_RVALID),
    .pcie_axi_RREADY (pcie_axi_RREADY)
);

endmodule

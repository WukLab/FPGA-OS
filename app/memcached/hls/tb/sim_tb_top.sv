module sim_tb_top ();

memcachedPipeline_top DUT (
 input          mem_clk,
 input          mem_resetn,
 input          apclk,
 input          apresetn,
 input   [31:0] alloc2app_tdata, 
 output         alloc2app_tready,
 input          alloc2app_tvalid,
 input          alloc2app_flushAck,
 output         app2alloc_flushDone,
 output         app2alloc_flushReq,
 input   [63:0] from_net_tdata,                
 input    [7:0] from_net_tkeep,
 input          from_net_tlast,                
 output         from_net_tready,               
 input  [111:0] from_net_tuser,
 input          from_net_tvalid,               
 output  [31:0] app2alloc_tdata,
 input          app2alloc_tready,       
 output         app2alloc_tvalid,       
 output  [63:0] to_net_tdata,
 output   [7:0] to_net_tkeep,                  
 output         to_net_tlast,                  
 input          to_net_tready,                 
 output [111:0] to_net_tuser,                  
 output         to_net_tvalid,                
 output  [31:0] toDRAM_araddr,
 output   [1:0] toDRAM_arburst,
 output   [3:0] toDRAM_arcache,
 output   [4:0] toDRAM_arid,
 output   [7:0] toDRAM_arlen,
 output   [2:0] toDRAM_arprot,
 input          toDRAM_arready,
 output   [2:0] toDRAM_arsize,
 output         toDRAM_arvalid,
 output   [3:0] toDRAM_arqos,
 output         toDRAM_arlock,
 output   [3:0] toDRAM_arregion,
 output  [31:0] toDRAM_awaddr,
 output   [1:0] toDRAM_awburst,
 output   [3:0] toDRAM_awcache,
 output   [4:0] toDRAM_awid,
 output   [7:0] toDRAM_awlen,
 output   [2:0] toDRAM_awprot,
 input          toDRAM_awready,
 output   [2:0] toDRAM_awsize,
 output         toDRAM_awvalid,
 output   [3:0] toDRAM_awregion,
 output         toDRAM_awlock,
 output   [3:0] toDRAM_awqos,
 input    [4:0] toDRAM_bid,
 output         toDRAM_bready,
 input    [1:0] toDRAM_bresp,
 input          toDRAM_bvalid,
 input  [511:0] toDRAM_rdata,
 input    [4:0] toDRAM_rid,
 input          toDRAM_rlast,
 output         toDRAM_rready,
 input    [1:0] toDRAM_rresp,
 input          toDRAM_rvalid,
 output [511:0] toDRAM_wdata,
 output         toDRAM_wlast,
 input          toDRAM_wready,
 output  [63:0] toDRAM_wstrb, 
 output         toDRAM_wvalid
);

dummyPCIeJoint u_pcie_alloc (
        .ap_clk (apclk),
        .ap_rst (apresetn),
        .inData_V_V_dout    (app2alloc_tdata),
        .inData_V_V_empty_n (app2alloc_tready),
        .inData_V_V_read    (app2alloc_tvalid),
        .outDataFlash_V_V_din   ('h0),
        .outDataFlash_V_V_full_n('h0),
        .outDataFlash_V_V_write ('h0),
        .outDataDram_V_V_din    (alloc2app_tdata),
        .outDataDram_V_V_full_n (alloc2app_tready),
        .outDataDram_V_V_write  (alloc2app_tvalid),
        .flushReq_V  (app2alloc_flushReq),
        .flushAck_V  (alloc2app_flushAck),
        .flushDone_V (app2alloc_flushDone)
);

/*
axis_driver u_driver( 
     .fromNet
);
*/

endmodule

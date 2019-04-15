`define SIM_SPEED_UP

`timescale 1fs/1fs

module board
(
);
    localparam   [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b010;

    wire [7:0] h2c_pci_exp_txp;
wire [7:0] h2c_pci_exp_txn;
    wire [7:0] c2h_pci_exp_txp;
wire [7:0] c2h_pci_exp_txn;
wire       user_lnk_up;

    reg       sys_rst_n;
    
wire       pcie_dedicated_100_clk_p;
wire       pcie_dedicated_100_clk_n;
wire       sysclk_125_clk_p;
wire       sysclk_125_clk_n;
wire       default_sysclk_300_clk_p;
wire       default_sysclk_300_clk_n;

reg        pcie_dedicated_100_clk_ref;
reg        sysclk_125_clk_ref;
reg        sysclk_300_clk_ref;

	wire        ddr4_act_n;
	wire [16:0] ddr4_adr;
	wire [1:0]  ddr4_ba;
	wire        ddr4_bg;
	wire        ddr4_ck_c;
	wire        ddr4_ck_t;
	wire        ddr4_cke;
	wire        ddr4_cs_n;
	wire [7:0]  ddr4_dm_n;
	wire [63:0] ddr4_dq;
	wire [7:0]  ddr4_dqs_c;
	wire [7:0]  ddr4_dqs_t;
	wire        ddr4_odt;
	wire        ddr4_reset_n;

        /*
         * don't change instance name, keep it compliant with Xilinx testbench
         */
	legofpga_pcie EP (
		.pcie_dedicated_100_clk_n	(pcie_dedicated_100_clk_n),
		.pcie_dedicated_100_clk_p	(pcie_dedicated_100_clk_p),
		.default_sysclk_125_clk_n	(sysclk_125_clk_n),
		.default_sysclk_125_clk_p	(sysclk_125_clk_p),
		.default_sysclk_300_clk_n	(default_sysclk_300_clk_n),
		.default_sysclk_300_clk_p	(default_sysclk_300_clk_p),
		
                .sys_rst_n        (sys_rst_n),
		
		.user_lnk_up		(user_lnk_up),

		.pci_exp_rxp			(h2c_pci_exp_txp),
		.pci_exp_rxn			(h2c_pci_exp_txn),
		.pci_exp_txp			(c2h_pci_exp_txp),
		.pci_exp_txn			(c2h_pci_exp_txn),
        
		/* DRAM interface */
		.ddr4_sdram_c1_act_n          (ddr4_act_n),
		.ddr4_sdram_c1_adr	      (ddr4_adr),
		.ddr4_sdram_c1_ba	      (ddr4_ba),
		.ddr4_sdram_c1_bg	      (ddr4_bg),
		.ddr4_sdram_c1_ck_c	      (ddr4_ck_c),
		.ddr4_sdram_c1_ck_t	      (ddr4_ck_t),
		.ddr4_sdram_c1_cke	      (ddr4_cke),
		.ddr4_sdram_c1_cs_n	      (ddr4_cs_n),
		.ddr4_sdram_c1_dm_n	      (ddr4_dm_n),
		.ddr4_sdram_c1_dq	      (ddr4_dq),
		.ddr4_sdram_c1_dqs_c          (ddr4_dqs_c),
		.ddr4_sdram_c1_dqs_t          (ddr4_dqs_t),
		.ddr4_sdram_c1_odt	      (ddr4_odt),
		.ddr4_sdram_c1_reset_n        (ddr4_reset_n)
	);
	
	
    
    ddr4_tb_top MEM_MODEL (
	//
	// TODO: feed mc_enable_model accordingly
	//
        .c0_ddr4_act_n            (ddr4_act_n),
        .c0_ddr4_adr              (ddr4_adr),
        .c0_ddr4_ba               (ddr4_ba),
        .c0_ddr4_bg               (ddr4_bg),
        .c0_ddr4_ck_c_int         (ddr4_ck_c),
        .c0_ddr4_ck_t_int         (ddr4_ck_t),
        .c0_ddr4_cke              (ddr4_cke),
        .c0_ddr4_cs_n             (ddr4_cs_n),
        .c0_ddr4_dm_dbi_n         (ddr4_dm_n),
        .c0_ddr4_dq               (ddr4_dq),
        .c0_ddr4_dqs_c            (ddr4_dqs_c),
        .c0_ddr4_dqs_t            (ddr4_dqs_t),
        .c0_ddr4_odt              (ddr4_odt),
        .c0_ddr4_reset_n          (ddr4_reset_n)
    );
    
    
    /*
     * PCIE receiver simulation
     */
     xilinx_pcie3_uscale_rp
     #(
        .PF0_DEV_CAP_MAX_PAYLOAD_SIZE(PF0_DEV_CAP_MAX_PAYLOAD_SIZE)
        //ONLY FOR RP
     ) RP (
   
       // SYS Inteface
       .sys_clk_n(pcie_dedicated_100_clk_n),
       .sys_clk_p(pcie_dedicated_100_clk_p),
       .sys_rst_n                  ( sys_rst_n ),
       // PCI-Express Serial Interface
       .pci_exp_txn(h2c_pci_exp_txp),
       .pci_exp_txp(h2c_pci_exp_txn),
       .pci_exp_rxn(c2h_pci_exp_txp),
       .pci_exp_rxp(c2h_pci_exp_txn)
     
     
     );


    initial
    begin
    `ifdef SIM_SPEED_UP
    `else
      $display("****************");
      $display("INFO : Simulation time may be longer. For faster simulation, please use SIM_SPEED_UP option. For more information refer product guide.");
      $display("****************");
    `endif

      pcie_dedicated_100_clk_ref = 1; 
      sysclk_125_clk_ref = 1;
      sysclk_300_clk_ref = 1;

      $display("[%t] : System Reset Is Asserted...", $realtime);
      sys_rst_n = 1'b0;
      repeat (600) @(posedge pcie_dedicated_100_clk_ref);
      $display("[%t] : System Reset Is De-asserted...", $realtime);
      sys_rst_n = 1'b1;
      
      
      // One lock
      $display("INFO : waiting for the PCIE link up..........");
      wait(user_lnk_up);
      $display("INFO : PCIE link ACTIVE");

      //
      // Having above two signals asserted is not enough.
      // We should use the `mac_ready` as the green light.
      // Once `mac_ready` is asserted, this TB can send stuff.
      // `mac_ready` is in top_mac_qsfp.c, not exported now.
      //

      $display("TB idle.");
      repeat(12)
        #8_00_000_000;

    end


    always
        #5000000.000 pcie_dedicated_100_clk_ref = ~pcie_dedicated_100_clk_ref;
        
    always
        #1666666.667 sysclk_300_clk_ref = ~sysclk_300_clk_ref;
        
    always
        #4000000.000 sysclk_125_clk_ref = ~sysclk_125_clk_ref;

    assign pcie_dedicated_100_clk_p = pcie_dedicated_100_clk_ref;
    assign default_sysclk_300_clk_p = sysclk_300_clk_ref;
    assign sysclk_125_clk_p         = sysclk_125_clk_ref;

    assign pcie_dedicated_100_clk_n = ~pcie_dedicated_100_clk_ref;
    assign default_sysclk_300_clk_n = ~sysclk_300_clk_ref;
    assign sysclk_125_clk_n         = ~sysclk_125_clk_ref;

endmodule

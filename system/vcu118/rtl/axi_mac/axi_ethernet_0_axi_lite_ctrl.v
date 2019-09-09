//----------------------------------------------------------------------------------------------------------------------
// Title      : Verilog Example Level Module
// File       : axi_ethernet_0_axi_lite_ctrl.v
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
// Description: This is an AXI Lite state machine of Example Design of AXI Ethernet IP.
//              This state machine configures AXI Ethernet.
//----------------------------------------------------------------------------------------------------------------------

`timescale 1ps/1ps

module axi_ethernet_0_axi_lite_ctrl (
    input             axi_lite_resetn  ,
    output  [17 : 0]  m_axi_araddr              , 
    input             m_axi_arready             , 
    output            m_axi_arvalid             , 
    output  [17 : 0]  m_axi_awaddr              , 
    input             m_axi_awready             , 
    output            m_axi_awvalid             , 
    output            m_axi_bready              , 
    input   [1 : 0]   m_axi_bresp               , 
    input             m_axi_bvalid              , 
    input   [31 : 0]  m_axi_rdata               , 
    output            m_axi_rready              , 
    input   [1 : 0]   m_axi_rresp               , 
    input             m_axi_rvalid              , 
    output  [31 : 0]  m_axi_wdata               , 
    input             m_axi_wready              , 
    output  [3 : 0]   m_axi_wstrb               , 
    output            m_axi_wvalid              , 

    input   [7:0]     cmnd_data                 , 
    input             cmnd_data_valid  ,
    output            cmnd_data_ready           , 

    input             start_config     ,

    output            ex_des_mtr_slv_lb_mode,
    output            ex_des_en_slvlb_addr_swap , 
    output            ex_des_blink_on_tx        , 
    output            soft_rst_except_to_mmcm   , 
    output  [1:0]     ex_des_line_speed         , 
    output            pat_chk_en_pkt_drop_chk   , 
    output            pat_chk_enable            , 
    output            pat_chk_rst_error         , 
    output  [4:0]     pat_gen_en_pkt_types      , 
    output            pat_gen_enable            , 
    output            pat_gen_da_sa_swap_en     ,

    input             axi_lite_clk
);


// order of ext phy programming R27, R0.speed, R0.autoneg, R0.Duplex , R0.reset, R0.loopback,  R0.Isolate .

localparam  AXICONFIGSTARTUP        = 1,
            SETMDIOFREQ             = 2,
            INTPHYDISANISOSETLB     = 3,
            SETEXTPHYPHYTYPE        = 4,
            RESETEXTPHYSETPHYTYPE   = 5,
            SETEXTPHYINLOOPBACK     = 6,
            SELECTEXTPHYFIBRBANK    = 7,
            SETEXTPHYFIBRINLPBK     = 8,
            RESETRECEIVER           = 9,
            RESETTRANSMITTER        = 10,
            SET1588TXCMDINLINE      = 11,
            SET1588RXTSINLINE       = 12,
            DISABLEFLOWCONTROL      = 13,
            CONFIG1FRAMEFILTER1     = 14,
            CONFIG1FRAMEFILTER2     = 15,
            SETTMACSPEED10          = 19,
            SETTMACSPEED100         = 20,
            SETTMACSPEED1000        = 21,
            RESETEXTPHYSETSPEED     = 25,
            SETEXTPHYINLBSP         = 28,
            SETSLAVELOOPBACK        = 40,
            SETMASTERLOOPBACK       = 41,
            RESETPATCHKERROR        = 43,
            RESETPATCHKERROR1       = 44,
            RESETPATCHKERROR2       = 45,
            INVALIDCMNDCMD          = 46,
            SETTOGGLEEXTPHYLB       = 50,
            STARTAXIWRTRANS         = 51,
            STARTAXIRDTRANS         = 52,
            APPLYAXIRST2EXTPHY      = 53,
            ASSERTSOFTRESET         = 54,
            STARTREPROGRAMREG       = 55,
            TOGGLEADDRSWAPSLB       = 56,
            TOGGLEADDRSWAPMTR       = 62,
            TOGGLEPATGENEN          = 57,
            TOGGLEPATCHKEN          = 58,
            TOGGLETXACTIVITY        = 59,
            POLLCONTROLSTATE        = 60,
            LASTSTATE               = 61,
            AXICONFIGIDLE           = 0  ;

localparam  CONFR0_LBEN             = 14,
            CONFR0_SPEEDSELLSB      = 13,
            CONFR0_ANEN             = 12,
            CONFR0_PDNDIS           = 11,
            CONFR0_ISDIS            = 10,
            CONFR0_SPEEDSELMSB      =  6,
            CONFR0_DUPLEX           =  8,
            CONFR0_RESET            = 15 ;

localparam  CONFIG_MDIOCLKFREQ             = 32'h68,
            CONFIG_EPHY_PHYTYPE_CFG        = 32'h0000,
            CONFIG_EPHY_FIBRBANKSEL_CFG    = 32'h0001,
            CONFIG_EPHY_MDIOR0_W_CTRL      = {3'h0, 5'd7, 3'h0, 5'd00, 8'h48, 8'h00},
            CONFIG_EPHY_MDIOR0_R_CTRL      = {3'h0, 5'd7, 3'h0, 5'd00, 8'h88, 8'h00},
            CONFIG_EPHY_MDIOPT_W_CTRL      = {3'h0, 5'd7, 3'h0, 5'd27, 8'h48, 8'h00},
            CONFIG_EPHY_MDIOBANKSEL_W_CTRL = {3'h0, 5'd7, 3'h0, 5'd22, 8'h48, 8'h00},
            CONFIG_IPHY_MDIOR0_W_CTRL      = {3'h0, 5'd1, 3'h0, 5'd00, 8'h48, 8'h00},
            CONFIG_IPHY_MDIOR0_R_CTRL      = {3'h0, 5'd1, 3'h0, 5'd00, 8'h88, 8'h00},
            ADDR_MDIOFREQ                  = 32'h500,
            ADDR_MDIOWRADDR                = 32'h508,
            ADDR_MDIORDADDR                = 32'h50C,
            ADDR_MDIOCTRLADDR              = 32'h504,
            ADDR_RXCTRL                    = 32'h404,
            ADDR_TXCTRL                    = 32'h408,
            ADDR_FLOWCTRL                  = 32'h708,
            ADDR_SPEEDCONFIG               = 32'h410,
            ADDR_CONFIGFRMFLTR1            = 32'h710,
            ADDR_CONFIGFRMFLTR2            = 32'h714   ;

localparam  CMNDSETSPEED1000            = 8'h1 ,
            CMNDSETSPEED100             = 8'h2 ,
            CMNDSETSPEED10              = 8'h3 ,
            CMNDTGLEADDRSWAP            = 8'h8 ,
            CMNDTGLEADDRSWAPMTR         = 8'h8 ,
            CMNDSETMASTERLOOPBACK       = 8'h5 ,
            CMNDTOGGLEEXTPHYLB          = 8'hC ,
            CMNDSETSLAVELOOPBACK        = 8'h9 ,
            CMNDAPPLYSOFTRESET          = 8'h6 ,
            CMNDTGLEPATGENEN            = 8'hB ,
            CMNDTGLEPATCHKEN            = 8'hA ,
            CMNDREPROGRAMREG            = 8'h0 ,
            CMNDRESETPATCHKERROR        = 8'h4 ,
            CMNDWRITE2AXILREG           = 8'hD ,
            CMNDREADAXILREG             = 8'h7 ,
            CMNDTGLETXACTIVITY          = 8'hE ;

localparam  AXILWRITE = 5'h1,
            AXILREAD1 = 5'h2,
            AXILREAD2 = 5'h3,
            AXILWAIT  = 5'h1f,
            AXILIDLE  = 5'h0;

localparam  MDIOGETSTATUS        = 1,
            MDIOPOLLSTATUS       = 2,
            MDIOWRITEDATA        = 3,
            MDIOWRITECTRL        = 4,
            MDIOWRITEDONE        = 5,
            MDIOWAITWRITECMPLTE  = 6,
            MDIOREADCTRL         = 7,
            MDIOWAITREADCMPLTE   = 8,
            MDIOPOLLREADSTATUS   = 9,
            MDIOFETCHRDDATA      = 10,
            MDIOREADDATA         = 11,
            MDIOIDLE             = 0;

function [6:0] get_ns_axi_config  ;
    input [7:0] cmnd_data    ;
begin
    case (cmnd_data)
        CMNDSETSPEED1000       : begin get_ns_axi_config = SETTMACSPEED1000   ;  end
        CMNDSETSPEED100        : begin get_ns_axi_config = SETTMACSPEED100    ;  end
        CMNDSETSPEED10         : begin get_ns_axi_config = SETTMACSPEED10     ;  end
        CMNDSETSLAVELOOPBACK   : begin get_ns_axi_config = SETSLAVELOOPBACK   ;  end
        CMNDSETMASTERLOOPBACK  : begin get_ns_axi_config = SETMASTERLOOPBACK  ;  end
        CMNDRESETPATCHKERROR   : begin get_ns_axi_config = RESETPATCHKERROR   ;  end
        CMNDREPROGRAMREG       : begin get_ns_axi_config = STARTREPROGRAMREG  ;  end
        CMNDTOGGLEEXTPHYLB     : begin get_ns_axi_config = SETTOGGLEEXTPHYLB  ;  end
        CMNDWRITE2AXILREG      : begin get_ns_axi_config = STARTAXIWRTRANS    ;  end
        CMNDREADAXILREG        : begin get_ns_axi_config = STARTAXIRDTRANS    ;  end
        CMNDTGLEADDRSWAP       : begin get_ns_axi_config = TOGGLEADDRSWAPSLB  ;  end
        CMNDTGLEADDRSWAPMTR    : begin get_ns_axi_config = TOGGLEADDRSWAPMTR  ;  end
        CMNDTGLEPATGENEN       : begin get_ns_axi_config = TOGGLEPATGENEN     ;  end
        CMNDTGLEPATCHKEN       : begin get_ns_axi_config = TOGGLEPATCHKEN     ;  end
        CMNDTGLETXACTIVITY     : begin get_ns_axi_config = TOGGLETXACTIVITY   ;  end
        CMNDAPPLYSOFTRESET     : begin get_ns_axi_config = ASSERTSOFTRESET    ;  end
        default                : begin get_ns_axi_config = INVALIDCMNDCMD     ;  end
    endcase
end
endfunction

wire axil_wr_cen, axil_rd_cen, mdio_rd_cen, axi_config_init_delay_done, axi_config_init_delay_2_done, start_config_sync;
wire mdio_wr_cen ;
reg  done_mdio_wr;
reg set_axilc_rd_cen, set_axilc_wr_cen, set_axilm_rd_cen, set_axilm_wr_cen, start_config_sync_d1, cmnd_data_fetched;
reg set_mdioc_rd_cen, set_mdioc_wr_cen, set_mdiom_rd_cen, set_mdiom_wr_cen, done_mdio_rd;
reg [4:0] axi_lite_cs = 0, mdio_access_ns = 0;
reg [4:0] mdio_access_cs;
reg [6:0] axi_config_ns, axi_config_ps;
reg [11:0] axi_config_init_delay_1 = 1, axi_config_init_delay_2 = 1;
reg [51:0] axil_rd_ctrl = 0;
reg [51:0] axil_wr_ctrl = 0;
reg [64:0] mdio_rd_ctrl = 0;
reg [64:0] mdio_wr_ctrl = 0;
reg [ 6:0] axi_config_cs;

reg rst_chk_err = 0, cmnd_data_valid_d1 = 0, set_in_band = 0;
reg set_m_s_lb = 0, set_slb_adswp = 1, set_patchk_en = 0, set_patgen_en = 0, set_blink_ontx = 0, set_isolate_en = 0, set_autoneg_en = 0, set_intphy_lb = 0, set_arst2_ephy = 0, set_soft_rst = 0;
reg set_slv_lb = 0, set_mtr_lb = 0, set_extphy_lb = 1;
reg [1:0] set_speed = 2'h2;

assign axi_config_init_delay_done   = (axi_config_init_delay_1 == 0);
assign axi_config_init_delay_2_done = (axi_config_init_delay_2 == 0);

assign cmnd_data_ready           = cmnd_data_fetched            ;
assign ex_des_mtr_slv_lb_mode    = set_m_s_lb                   ;
assign ex_des_en_slvlb_addr_swap = !set_m_s_lb && set_slb_adswp ;
assign ex_des_blink_on_tx        = set_blink_ontx               ;
assign ex_des_line_speed         = set_speed                    ;
assign pat_chk_en_pkt_drop_chk   = 1'b1                         ;
assign pat_chk_enable            = set_patchk_en  && set_m_s_lb ;
assign pat_chk_rst_error         = rst_chk_err                  ;
assign pat_gen_en_pkt_types      = 5'h0                         ;
assign pat_gen_enable            = set_patgen_en  && set_m_s_lb ;
assign pat_gen_da_sa_swap_en     = 0 ;
assign soft_rst_except_to_mmcm   = set_soft_rst                 ;

always @ (posedge axi_lite_clk) begin
    if (axi_lite_resetn == 1'b0) begin
        rst_chk_err  <= 1; start_config_sync_d1 <= 0;
        set_m_s_lb <= 0;         set_mtr_lb <= 0;         set_slv_lb <= 0;         set_speed  <= 2; 
        set_extphy_lb <= 1; set_slb_adswp <= 1; set_patgen_en <= 1; set_patchk_en <= 1;
        set_soft_rst <= 0; set_blink_ontx <= 0;
        set_isolate_en <= 0; set_autoneg_en <= 0; set_intphy_lb <= 0;
        cmnd_data_valid_d1 <= 0;
        axi_config_init_delay_1 <= 12'h4FF;  /// Initial wait little more than 15 ms. The rst to mdio would be applied for 10 ms.
        axi_config_init_delay_2 <= 12'h4FF;  /// Initial wait little more than 15 ms. The rst to mdio would be applied for 10 ms.
    end else begin
        start_config_sync_d1 <= start_config_sync;
        rst_chk_err  <= (axi_config_cs == RESETPATCHKERROR || axi_config_cs == RESETPATCHKERROR1 || axi_config_cs == RESETPATCHKERROR2) ? 1 : 0 ;
        set_mtr_lb <= (axi_config_cs == SETSLAVELOOPBACK) ? 0 : (axi_config_cs == SETMASTERLOOPBACK) ? 1 : set_mtr_lb;
        set_slv_lb <= (axi_config_cs == SETSLAVELOOPBACK) ? 1 : (axi_config_cs == SETMASTERLOOPBACK) ? 0 : set_slv_lb;
        set_speed <=  (axi_config_cs == SETTMACSPEED10) ? 0 : ((axi_config_cs == SETTMACSPEED100) ? 1 : ((axi_config_cs == SETTMACSPEED1000) ? 2 : set_speed));
        set_m_s_lb <= (axi_config_cs == LASTSTATE) ? ((set_slv_lb && ~set_mtr_lb) ? 0 : 1) : set_m_s_lb;
        set_slb_adswp <= (axi_config_cs == TOGGLEADDRSWAPSLB) ? ~set_slb_adswp : set_slb_adswp;
        set_patgen_en <= (axi_config_cs == TOGGLEPATGENEN) ? ~set_patgen_en : set_patgen_en;
        set_patchk_en <= (axi_config_cs == TOGGLEPATCHKEN) ? ~set_patchk_en : set_patchk_en;
        set_blink_ontx <= (axi_config_cs == TOGGLETXACTIVITY) ? ~set_blink_ontx : set_blink_ontx;
        set_extphy_lb <= set_slv_lb ? 0 : ((axi_config_cs == SETTOGGLEEXTPHYLB) ? !set_extphy_lb : set_extphy_lb);
        set_soft_rst  <= (axi_config_cs == ASSERTSOFTRESET) ? 1 : 0;
        set_isolate_en <= set_isolate_en; set_autoneg_en <= set_autoneg_en; set_intphy_lb <= set_intphy_lb;
        cmnd_data_valid_d1 <= (cmnd_data_fetched) ? 0 : (cmnd_data_valid ? 1 : cmnd_data_valid_d1);
        axi_config_init_delay_1 <= (axi_config_init_delay_done) ? 0 : ((axi_config_init_delay_2_done) ? (axi_config_init_delay_1 - 1) : axi_config_init_delay_1);
        axi_config_init_delay_2 <= (axi_config_init_delay_done) ? 0 : ((axi_config_init_delay_2_done) ?  12'h4FF   : (axi_config_init_delay_2 - 1));
    end
end

// Configuration of AXI Ethernet using below Control State Machine
// Basic configuration at startup
always @ (posedge axi_lite_clk or negedge axi_lite_resetn) begin
    if (axi_lite_resetn == 1'b0) begin
        axi_config_cs <= AXICONFIGIDLE;
        axi_config_ps <= AXICONFIGIDLE;
    end else begin
        if (cmnd_data_valid && ~cmnd_data_valid_d1) begin
            axi_config_cs <= POLLCONTROLSTATE;
        end else if (cmnd_data_fetched) begin
            axi_config_cs <= axi_config_ps;
        end else begin
            axi_config_cs <= axi_config_ns;
        end
        if (cmnd_data_valid && ~cmnd_data_valid_d1) begin
            axi_config_ps <= axi_config_ns;
        end else begin
            axi_config_ps <= axi_config_ps;
        end
    end
end

always @ * begin
    set_axilc_wr_cen = 0; set_axilc_rd_cen = 0;
    set_mdioc_wr_cen = 0; set_mdioc_rd_cen = 0;
    cmnd_data_fetched = 0; axi_config_ns = axi_config_cs;
    case(axi_config_cs)
        AXICONFIGIDLE : begin
            if (start_config_sync || axi_config_init_delay_done) begin
                axi_config_ns = AXICONFIGSTARTUP;
            end
        end
        AXICONFIGSTARTUP : begin
            axi_config_ns = SETMDIOFREQ;
        end
        SETMDIOFREQ : begin
            if (axil_wr_cen) begin
                axi_config_ns = SETMDIOFREQ;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = SETEXTPHYINLOOPBACK;
            end
        end
        SETEXTPHYPHYTYPE: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETEXTPHYPHYTYPE;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = RESETEXTPHYSETPHYTYPE;
            end
        end
        RESETEXTPHYSETPHYTYPE: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = RESETEXTPHYSETPHYTYPE;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = SETEXTPHYINLOOPBACK;
            end
        end
        SETEXTPHYINLOOPBACK: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETEXTPHYINLOOPBACK;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = INTPHYDISANISOSETLB;
            end
        end
        INTPHYDISANISOSETLB : begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = INTPHYDISANISOSETLB;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = RESETRECEIVER;
            end
        end
        SELECTEXTPHYFIBRBANK: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SELECTEXTPHYFIBRBANK;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = SETEXTPHYFIBRINLPBK;
            end
        end
        SETEXTPHYFIBRINLPBK: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETEXTPHYFIBRINLPBK;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = RESETRECEIVER;
            end
        end
        RESETRECEIVER : begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = RESETRECEIVER;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = RESETTRANSMITTER;
            end
        end
        RESETTRANSMITTER : begin
            if (axil_wr_cen) begin
                axi_config_ns = RESETTRANSMITTER;
            end else begin
                set_axilc_wr_cen = 1;
                if (set_in_band) begin
                    axi_config_ns = SET1588TXCMDINLINE;
                end else begin
                    axi_config_ns = DISABLEFLOWCONTROL;
                end
            end
        end
        SET1588TXCMDINLINE : begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SET1588TXCMDINLINE;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = SET1588RXTSINLINE;
            end
        end
        SET1588RXTSINLINE : begin
            if (axil_wr_cen) begin
                axi_config_ns = SET1588RXTSINLINE;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = DISABLEFLOWCONTROL;
            end
        end
        DISABLEFLOWCONTROL : begin
            if (axil_wr_cen) begin
                axi_config_ns = DISABLEFLOWCONTROL;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = CONFIG1FRAMEFILTER1;
            end
        end
        CONFIG1FRAMEFILTER1 : begin
            if (axil_wr_cen) begin
                axi_config_ns = CONFIG1FRAMEFILTER1;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = CONFIG1FRAMEFILTER2;
            end
        end
        CONFIG1FRAMEFILTER2 : begin
            if (axil_wr_cen) begin
                axi_config_ns = CONFIG1FRAMEFILTER2;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = LASTSTATE;
            end
        end
        SETTMACSPEED10 : begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETTMACSPEED10;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = RESETEXTPHYSETSPEED;
            end
        end
        SETTMACSPEED100 : begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETTMACSPEED100;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = RESETEXTPHYSETSPEED;
            end
        end
        SETTMACSPEED1000 : begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETTMACSPEED1000;
            end else begin
                set_axilc_wr_cen = 1;
                axi_config_ns = RESETEXTPHYSETSPEED;
            end
        end
        RESETEXTPHYSETSPEED: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = RESETEXTPHYSETSPEED;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = SETEXTPHYINLBSP;
            end
        end
        SETEXTPHYINLBSP: begin
            if (axil_wr_cen || mdio_wr_cen) begin
                axi_config_ns = SETEXTPHYINLBSP;
            end else begin
                set_mdioc_wr_cen = 1;
                axi_config_ns = LASTSTATE;
                cmnd_data_fetched = cmnd_data_valid_d1;
            end
        end
        SETSLAVELOOPBACK : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        SETMASTERLOOPBACK : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        APPLYAXIRST2EXTPHY : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        TOGGLEADDRSWAPSLB : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        TOGGLETXACTIVITY : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        TOGGLEPATGENEN : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        TOGGLEPATCHKEN : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        STARTAXIWRTRANS : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        STARTAXIRDTRANS : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        STARTREPROGRAMREG : begin
            axi_config_ns = AXICONFIGSTARTUP;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        ASSERTSOFTRESET : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        SETTOGGLEEXTPHYLB : begin
            axi_config_ns = AXICONFIGSTARTUP;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        RESETPATCHKERROR : begin
            axi_config_ns = RESETPATCHKERROR1;
        end
        RESETPATCHKERROR1 : begin
            axi_config_ns = RESETPATCHKERROR2;
        end
        RESETPATCHKERROR2 : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
        end
        INVALIDCMNDCMD : begin
            axi_config_ns = LASTSTATE;
            cmnd_data_fetched = cmnd_data_valid_d1;
            $display ("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $display ("++ %d ++ The control word sent is is not valid. ", $time);
            $display ("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
        end
        POLLCONTROLSTATE: begin
            axi_config_ns = get_ns_axi_config (cmnd_data);
        end
        LASTSTATE: begin
            if (start_config_sync && !start_config_sync_d1) begin
                axi_config_ns = AXICONFIGSTARTUP;
            end else begin
            axi_config_ns = LASTSTATE;
        end
        end
        default : axi_config_ns = AXICONFIGIDLE;
    endcase
end

//------------------------------------------------
// MDIO setup - split from main state machine to make more manageable
// MDIO Transmit and receive state machine.
assign mdio_wr_cen = mdio_wr_ctrl[64];
assign mdio_rd_cen = mdio_rd_ctrl[64];

always @ (posedge axi_lite_clk) begin
    if (axi_lite_resetn == 1'b0) begin
        mdio_access_cs <= MDIOIDLE;
    end else begin
        mdio_access_cs <= mdio_access_ns;
    end
end

always @ * begin
    set_axilm_wr_cen = 0; set_axilm_rd_cen = 0;
    done_mdio_rd = 0; done_mdio_wr = 0; mdio_access_ns = mdio_access_cs;
    case(mdio_access_cs)
        MDIOIDLE : begin
            if (mdio_rd_cen || mdio_wr_cen) begin
                mdio_access_ns = MDIOGETSTATUS;
            end else begin
                mdio_access_ns = MDIOIDLE;
            end
        end
        MDIOGETSTATUS : begin
            if (axil_rd_cen) begin
                mdio_access_ns = MDIOGETSTATUS;
            end else begin
                set_axilm_rd_cen = 1;
                mdio_access_ns = MDIOPOLLSTATUS;
            end
        end
        MDIOPOLLSTATUS : begin
            if (axil_rd_cen) begin
                mdio_access_ns = MDIOPOLLSTATUS;
            end else begin
                if (axil_rd_ctrl[7]) begin
                    if (mdio_rd_cen) begin
                        mdio_access_ns = MDIOREADCTRL;
                    end else if (mdio_wr_cen) begin
                        mdio_access_ns = MDIOWRITEDATA;
                    end
                end else begin
                    mdio_access_ns = MDIOGETSTATUS;
                end
            end
        end
        MDIOWRITEDATA : begin
            if (axil_wr_cen) begin
                mdio_access_ns = MDIOWRITEDATA;
            end else begin
                mdio_access_ns = MDIOWRITECTRL;
                set_axilm_wr_cen = 1;
            end
        end
        MDIOWRITECTRL : begin
            if (axil_wr_cen) begin
                mdio_access_ns = MDIOWRITECTRL;
            end else begin
                set_axilm_wr_cen = 1;
                mdio_access_ns = MDIOWAITWRITECMPLTE;
            end
        end
        MDIOWAITWRITECMPLTE : begin
            if (axil_wr_cen) begin
                mdio_access_ns = MDIOWAITWRITECMPLTE;
            end else begin
                set_axilm_rd_cen = 1;
                mdio_access_ns = MDIOWRITEDONE;
            end
        end
        MDIOWRITEDONE : begin
            if (axil_rd_cen) begin
                mdio_access_ns = MDIOWRITEDONE;
            end else begin
                if (axil_rd_ctrl[7]) begin
                    done_mdio_wr = 1;
                    mdio_access_ns = MDIOIDLE;
                end else begin
                    mdio_access_ns = MDIOWAITWRITECMPLTE;
                end
            end
        end
        MDIOREADCTRL : begin
            if (axil_wr_cen) begin
                mdio_access_ns = MDIOREADCTRL;
            end else begin
                mdio_access_ns = MDIOWAITREADCMPLTE;
                set_axilm_wr_cen = 1;
            end
        end
        MDIOWAITREADCMPLTE : begin
            if (axil_wr_cen) begin
                mdio_access_ns = MDIOWAITREADCMPLTE;
            end else begin
                set_axilm_rd_cen = 1;
                mdio_access_ns = MDIOPOLLREADSTATUS;
            end
        end
        MDIOPOLLREADSTATUS : begin
            if (axil_rd_cen) begin
                mdio_access_ns = MDIOPOLLREADSTATUS;
            end else begin
                if (axil_rd_ctrl[7]) begin
                    mdio_access_ns = MDIOFETCHRDDATA;
                end else begin
                    mdio_access_ns = MDIOWAITREADCMPLTE;
                end
            end
        end
        MDIOFETCHRDDATA : begin
            if (axil_rd_cen) begin
                mdio_access_ns = MDIOFETCHRDDATA;
            end else begin
                mdio_access_ns = MDIOREADDATA;
            end
        end
        MDIOREADDATA : begin
            if (axil_rd_cen) begin
                mdio_access_ns = MDIOREADDATA;
            end else begin
                done_mdio_rd    = 1;
                mdio_access_ns = MDIOIDLE;
            end
        end
        default : mdio_access_ns = MDIOIDLE;
    endcase
end

// AXI Lite Interface signals.
assign  m_axi_wstrb            = 4'hF;
assign  m_axi_awaddr           = axil_wr_ctrl[49:32];
assign  m_axi_wdata            = axil_wr_ctrl[31:0];
assign  m_axi_araddr           = axil_rd_ctrl[49:32];
assign  m_axi_rready           = 1;
assign  m_axi_bready           = 1;

assign  m_axi_awvalid          = (axi_lite_cs == AXILWRITE) ? 1 : 0;
assign  m_axi_wvalid           = (axi_lite_cs == AXILWRITE) ? 1 : 0;
assign  m_axi_arvalid          = (axi_lite_cs == AXILREAD1) ? 1 : 0;

assign axil_wr_cen = axil_wr_ctrl[51];
assign axil_rd_cen = axil_rd_ctrl[51];

// AXI Lite Transmit and receive state machine.
always @ (posedge axi_lite_clk) begin
    if (axi_lite_resetn == 1'b0) begin
        axi_lite_cs <= AXILIDLE;
    end else begin
        case(axi_lite_cs)
            AXILIDLE : begin
                if (axil_rd_cen) begin
                    axi_lite_cs <= AXILREAD1;
                end else if (axil_wr_cen) begin
                    axi_lite_cs <= AXILWRITE;
                end else begin
                    axi_lite_cs <= AXILIDLE;
                end
            end
            AXILWRITE : begin
                if (m_axi_wready) begin
                    axi_lite_cs   <= AXILIDLE;
                end else begin
                    axi_lite_cs <= AXILWRITE;
                end
            end
            AXILREAD1 : begin
                if (m_axi_arready) begin
                    axi_lite_cs   <= AXILREAD2;
                end else begin
                    axi_lite_cs   <= AXILREAD1;
                end
            end
            AXILREAD2 : begin
                if (m_axi_rvalid) begin
                    axi_lite_cs   <= AXILIDLE;
                end else begin
                    axi_lite_cs   <= AXILREAD2;
                end
            end
            default : axi_lite_cs <= AXILIDLE;
        endcase
    end
end

// Writing to control registers of axi lite fsm
always @ (posedge axi_lite_clk) begin
    if (axi_lite_resetn == 1'b0) begin
        axil_rd_ctrl <= 0;
    end else begin
        if (m_axi_rvalid && (axi_lite_cs == AXILREAD2)) begin
            axil_rd_ctrl[51] <= 0;
            axil_rd_ctrl[31:0] <= m_axi_rdata;
        end else begin
            if (set_axilc_rd_cen || set_axilm_rd_cen) begin
                if (mdio_access_cs == MDIOGETSTATUS) begin
                    axil_rd_ctrl[49:32] <= ADDR_MDIOCTRLADDR;
                end else if (mdio_access_cs == MDIOWAITWRITECMPLTE) begin
                    axil_rd_ctrl[49:32] <= ADDR_MDIOCTRLADDR;
                end else if (mdio_access_cs == MDIOWAITREADCMPLTE) begin
                    axil_rd_ctrl[49:32] <= ADDR_MDIOCTRLADDR;
                end else if (mdio_access_cs == MDIOFETCHRDDATA) begin
                    axil_rd_ctrl[49:32] <= ADDR_MDIORDADDR;
                end else begin
                    axil_rd_ctrl[49:32] <= axil_rd_ctrl[49:32];
                end
                axil_rd_ctrl[51] <= 1;
            end else begin
                axil_rd_ctrl <= axil_rd_ctrl;
        end
        end
    end
end

always @ (posedge axi_lite_clk) begin
    if (axi_lite_resetn == 1'b0) begin
        axil_wr_ctrl <= 0;
    end else begin
        if (m_axi_wready && (axi_lite_cs == AXILWRITE)) begin
            axil_wr_ctrl[51] <= 0;
        end else begin
            if (set_axilc_wr_cen || set_axilm_wr_cen) begin
                axil_wr_ctrl[51] <= 1;
                if (mdio_access_cs == MDIOWRITEDATA) begin
                    axil_wr_ctrl[49:32] <= ADDR_MDIOWRADDR;
                    axil_wr_ctrl[31:0]  <= mdio_wr_ctrl[31:0];
                end else if (mdio_access_cs == MDIOWRITECTRL) begin
                    axil_wr_ctrl[49:32] <= ADDR_MDIOCTRLADDR;
                    axil_wr_ctrl[31:0]  <= mdio_wr_ctrl[63:32];
                end else if (mdio_access_cs == MDIOREADCTRL) begin
                    axil_wr_ctrl[49:32] <= ADDR_MDIOCTRLADDR;
                    axil_wr_ctrl[31:0]  <= mdio_rd_ctrl[63:32];
                end else if (axi_config_cs == SETMDIOFREQ) begin
                    axil_wr_ctrl[49:32] <= ADDR_MDIOFREQ;
                    axil_wr_ctrl[31:0]  <= CONFIG_MDIOCLKFREQ;
                end else if (axi_config_cs == RESETRECEIVER) begin
                    axil_wr_ctrl[49:32] <= ADDR_RXCTRL;
                    axil_wr_ctrl[31:0]  <= 32'h9000_0000 ;
                end else if (axi_config_cs == RESETTRANSMITTER) begin
                    axil_wr_ctrl[49:32] <= ADDR_TXCTRL;
                    axil_wr_ctrl[31:0]  <= 32'h9000_0000 ;
                end else if (axi_config_cs == SET1588RXTSINLINE) begin
                    axil_wr_ctrl[49:32] <= ADDR_RXCTRL;
                    axil_wr_ctrl[31:0]  <= 32'h1040_0000 ;
                end else if (axi_config_cs == SET1588TXCMDINLINE) begin
                    axil_wr_ctrl[49:32] <= ADDR_TXCTRL;
                    axil_wr_ctrl[31:0]  <= 32'h1040_0000 ;
                end else if (axi_config_cs == DISABLEFLOWCONTROL) begin
                    axil_wr_ctrl[49:32] <= ADDR_FLOWCTRL;
                    axil_wr_ctrl[31:0]  <= 32'h0 ;
                end else if (axi_config_cs == CONFIG1FRAMEFILTER1) begin
                    axil_wr_ctrl[49:32] <= ADDR_CONFIGFRMFLTR1;
                    axil_wr_ctrl[31:0]  <= 32'h040302DA ;
                end else if (axi_config_cs == CONFIG1FRAMEFILTER2) begin
                    axil_wr_ctrl[49:32] <= ADDR_CONFIGFRMFLTR2;
                    axil_wr_ctrl[31:0]  <= 32'h0605;
                end else if (axi_config_cs == SETTMACSPEED1000) begin
                    axil_wr_ctrl[49:32] <= ADDR_SPEEDCONFIG;
                    axil_wr_ctrl[31:0]  <= 32'h80000000;
                end else if (axi_config_cs == SETTMACSPEED100) begin
                    axil_wr_ctrl[49:32] <= ADDR_SPEEDCONFIG;
                    axil_wr_ctrl[31:0]  <= 32'h40000000;
                end else if (axi_config_cs == SETTMACSPEED10) begin
                    axil_wr_ctrl[49:32] <= ADDR_SPEEDCONFIG;
                    axil_wr_ctrl[31:0]  <= 32'h00000000;
                end else begin
                    axil_wr_ctrl[49:32] <= 0;
                    axil_wr_ctrl[31:0]  <= 0;
                end
            end else begin
                axil_wr_ctrl <= axil_wr_ctrl;
            end
        end
    end
end

always @ (posedge axi_lite_clk) begin
    if (axi_lite_resetn == 1'b0) begin
        mdio_wr_ctrl <= 0;
        mdio_rd_ctrl <= 0;
    end else begin
        if (done_mdio_rd) begin
            mdio_rd_ctrl[64] <= 0;
            mdio_rd_ctrl[31:0] <= axil_rd_ctrl[31:0];
        end else begin
            if (set_mdiom_rd_cen || set_mdioc_rd_cen) begin
                mdio_rd_ctrl[64] <= 1;
                mdio_rd_ctrl[63:32] <= 0;
                mdio_rd_ctrl[31:0] <=  0;
            end else begin
                mdio_rd_ctrl <= mdio_rd_ctrl;
            end
        end

        if (done_mdio_wr) begin
            mdio_wr_ctrl[64] <= 0;
        end else begin
            if (set_mdioc_wr_cen || set_mdiom_wr_cen) begin
                mdio_wr_ctrl[64] <= 1;
                if ((axi_config_cs == SETEXTPHYINLOOPBACK) || (axi_config_cs == SETEXTPHYFIBRINLPBK) || (axi_config_cs == SETEXTPHYINLBSP)) begin
                    mdio_wr_ctrl[63:32] <= CONFIG_EPHY_MDIOR0_W_CTRL;
                    mdio_wr_ctrl[31: 0] <= {16'h0, 1'b0, set_extphy_lb, set_speed[0], set_autoneg_en, 2'b0, 3'b010, set_speed[1], 6'h0 };
                end else if ((axi_config_cs == RESETEXTPHYSETPHYTYPE) || (axi_config_cs == RESETEXTPHYSETSPEED)) begin
                    mdio_wr_ctrl[63:32] <= CONFIG_EPHY_MDIOR0_W_CTRL;
                    mdio_wr_ctrl[31: 0] <= {16'h0, 1'b1, set_extphy_lb, set_speed[0], set_autoneg_en, 2'b0, 3'b010, set_speed[1], 6'h0 };
                end else if (axi_config_cs == INTPHYDISANISOSETLB) begin
                    mdio_wr_ctrl[63:32] <= CONFIG_IPHY_MDIOR0_W_CTRL;
                    mdio_wr_ctrl[31: 0] <= {16'h0, 1'b0, set_intphy_lb, 1'b0, set_autoneg_en, 1'b0, set_isolate_en, 3'b010, 1'b1, 6'h0 };
                end else if (axi_config_cs == SETEXTPHYPHYTYPE) begin
                    mdio_wr_ctrl[63:32] <= CONFIG_EPHY_MDIOPT_W_CTRL;
                    mdio_wr_ctrl[31: 0] <= CONFIG_EPHY_PHYTYPE_CFG;
                end else if (axi_config_cs == SELECTEXTPHYFIBRBANK) begin
                    mdio_wr_ctrl[63:32] <= CONFIG_EPHY_MDIOBANKSEL_W_CTRL;
                    mdio_wr_ctrl[31: 0] <= CONFIG_EPHY_FIBRBANKSEL_CFG;
                end else begin
                    mdio_wr_ctrl[63:32] <= 0;
                    mdio_wr_ctrl[31:0] <=  0;
                end
            end else begin
                    mdio_wr_ctrl <= mdio_wr_ctrl;
            end
        end
    end
end

axi_ethernet_0_bit_sync    start_config_sync_inst    (.clk(axi_lite_clk), .data_in(start_config), .data_out(start_config_sync));

endmodule


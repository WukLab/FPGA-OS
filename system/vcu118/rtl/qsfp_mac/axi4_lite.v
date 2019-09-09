`timescale 1fs/1fs
(* DowngradeIPIdentifiedWarnings="yes" *)

module xxv_ethernet_0_axi4_lite_user_if
   (
    input  wire            rx_gt_locked,
    input  wire            stat_rx_aligned,
    input  [4:0]           completion_status,
    output reg             restart,
    output reg             stat_reg_compare, 

    input                  s_axi_aclk,
    input                  s_axi_sreset,
    input                  s_axi_pm_tick,
    output  [31:0]         s_axi_awaddr,
    output                 s_axi_awvalid,
    
    input                  s_axi_awready,
    
    output  [31:0]         s_axi_wdata,
    output  [3:0]          s_axi_wstrb,
    output                 s_axi_wvalid,
    input                  s_axi_wready,
    
    input   [1:0]          s_axi_bresp,
    input                  s_axi_bvalid,
    output                 s_axi_bready,
    
    output  [31:0]         s_axi_araddr,
    output                 s_axi_arvalid,
    input                  s_axi_arready,
    input   [31:0]         s_axi_rdata,
    input   [1:0]          s_axi_rresp,
    input                  s_axi_rvalid,
    output                 s_axi_rready

    );
    //// axi_user_prestate
    parameter STATE_AXI_IDLE            = 0;
    parameter STATE_GT_LOCKED           = 1;
    parameter STATE_AXI_VERSION_READ    = 2;
    parameter STATE_WAIT_RX_ALIGNED     = 3;
    parameter STATE_AXI_WR              = 4;
    parameter STATE_WAIT_SANITY_DONE    = 5;
    parameter STATE_AXI_RD_WR           = 6;
    parameter STATE_READ_STATS          = 7;
    parameter STATE_READ_DONE           = 8;
    parameter STATE_TEST_DONE           = 9;
    parameter STATE_INVALID_AXI_RD_WR   = 10;
    //// axi_reg_map address
    parameter  ADDR_GT_RESET_REG                        =  32'h00000000;
    parameter  ADDR_RESET_REG                           =  32'h00000004;
    parameter  ADDR_MODE_REG                            =  32'h00000008;
    parameter  ADDR_CONFIG_TX_REG1                      =  32'h0000000C;
    parameter  ADDR_CONFIG_RX_REG1                      =  32'h00000014;
    parameter  ADDR_CORE_VERSION_REG                    =  32'h00000024;
    parameter  ADDR_TICK_REG                            =  32'h00000020;

    parameter  ADDR_AN_CONTROL_REG1			=  32'h000000e0;
    parameter  ADDR_LT_CONTROL_REG1			=  32'h00000100;


    parameter  ADDR_STAT_TX_TOTAL_PACKETS_LSB           =  32'h00000700;
    parameter  ADDR_STAT_TX_TOTAL_PACKETS_MSB           =  32'h00000704;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_PACKETS_LSB      =  32'h00000708;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_PACKETS_MSB      =  32'h0000070C;
    parameter  ADDR_STAT_TX_TOTAL_BYTES_LSB             =  32'h00000710;
    parameter  ADDR_STAT_TX_TOTAL_BYTES_MSB             =  32'h00000714;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_BYTES_LSB        =  32'h00000718;
    parameter  ADDR_STAT_TX_TOTAL_GOOD_BYTES_MSB        =  32'h0000071C;


    parameter  ADDR_STAT_RX_TOTAL_PACKETS_LSB           =  32'h00000808;
    parameter  ADDR_STAT_RX_TOTAL_PACKETS_MSB           =  32'h0000080C;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_PACKETS_LSB      =  32'h00000810;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_PACKETS_MSB      =  32'h00000814;
    parameter  ADDR_STAT_RX_TOTAL_BYTES_LSB             =  32'h00000818;
    parameter  ADDR_STAT_RX_TOTAL_BYTES_MSB             =  32'h0000081C;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_BYTES_LSB        =  32'h00000820;
    parameter  ADDR_STAT_RX_TOTAL_GOOD_BYTES_MSB        =  32'h00000824;




    ////State Registers for TX
    reg  [3:0]     axi_user_prestate;

    reg  [31:0]    axi_wr_data;
    reg  [31:0]    axi_read_data;
    wire [31:0]    axi_rd_data;
    reg  [31:0]    axi_wr_addr, axi_rd_addr;
    reg  [3:0]     axi_wr_strobe;
    reg            axi_wr_data_valid;
    reg            axi_wr_addr_valid;
    reg            axi_rd_addr_valid;
    reg            axi_rd_req;
    reg            axi_wr_req;
    wire           axi_wr_ack;
    wire           axi_rd_ack;
    wire           axi_wr_err;
    wire           axi_rd_err;
    reg  [7:0]     rd_wr_cntr; 
    reg  [47:0]    tx_total_pkt, tx_total_bytes, tx_total_good_pkts, tx_total_good_bytes;
    reg  [47:0]    rx_total_pkt, rx_total_bytes, rx_total_good_pkts, rx_total_good_bytes;
    reg            init_rx_aligned;
    reg            init_stat_read;
    reg            init_sanity_done;
    wire           stat_rx_aligned_sync;
    wire           gt_locked_sync;


    wire           pm_tick_r;
    reg            version_reg_read;
    
    

    
    //////////////////////////////////////////////////
    ////State Machine 
    //////////////////////////////////////////////////
    always @( posedge s_axi_aclk )
    begin
        if ( s_axi_sreset == 1'b1 )
        begin
            axi_user_prestate         <= STATE_AXI_IDLE;
            axi_rd_addr               <= 32'd0;
            axi_rd_addr_valid         <= 1'b0;
            axi_wr_data               <= 32'd0;
            axi_read_data             <= 32'd0;
            axi_wr_addr               <= 32'd0;
            axi_wr_addr_valid         <= 1'b0;
            axi_wr_data_valid         <= 1'b0;
            axi_wr_strobe             <= 4'd0;
            axi_rd_req                <= 1'b0;
            axi_wr_req                <= 1'b0;
            rd_wr_cntr                <= 8'd0;
            init_rx_aligned           <= 1'b0;
            init_stat_read            <= 1'b0;
            init_sanity_done          <= 1'b0;
            restart                   <= 1'b0;
            version_reg_read          <= 1'b0;
            stat_reg_compare          <= 1'b0;
            tx_total_pkt              <= 48'd0;
            tx_total_bytes            <= 48'd0;
            tx_total_good_pkts        <= 48'd0;
            tx_total_good_bytes       <= 48'd0;
            rx_total_pkt              <= 48'd0;
            rx_total_bytes            <= 48'd0;
            rx_total_good_pkts        <= 48'd0;
            rx_total_good_bytes       <= 48'd0;
        end
        else
        begin
        case (axi_user_prestate)
            STATE_AXI_IDLE            :
                                     begin
                                         axi_rd_addr               <= 32'd0;
                                         axi_rd_addr_valid         <= 1'b0;
                                         axi_wr_data               <= 32'd0;
                                         axi_read_data             <= 32'd0;
                                         axi_wr_addr               <= 32'd0;
                                         axi_wr_addr_valid         <= 1'b0;
                                         axi_wr_data_valid         <= 1'b0;
                                         axi_wr_strobe             <= 4'd0;
                                         axi_rd_req                <= 1'b0;
                                         axi_wr_req                <= 1'b0;
                                         rd_wr_cntr                <= 8'd0;
                                         init_rx_aligned           <= 1'b0;
                                         init_stat_read            <= 1'b0;
                                         restart                   <= 1'b0;
                                         stat_reg_compare          <= 1'b0;
                                         init_sanity_done          <= 1'b0;
                                         version_reg_read          <= 1'b0;
                                         tx_total_pkt              <= 48'd0;
                                         tx_total_bytes            <= 48'd0;
                                         tx_total_good_pkts        <= 48'd0;
                                         tx_total_good_bytes       <= 48'd0;
                                         rx_total_pkt              <= 48'd0;
                                         rx_total_bytes            <= 48'd0;
                                         rx_total_good_pkts        <= 48'd0;
                                         rx_total_good_bytes       <= 48'd0;
					                 

                                         //// State transition
                                         if  (gt_locked_sync == 1'b1)
                                         begin
                                             axi_user_prestate <= STATE_GT_LOCKED;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                     end
            STATE_GT_LOCKED          :
                                     begin
                                         axi_rd_addr             <= 32'd0;
                                         axi_rd_addr_valid       <= 1'b1;
                                         axi_wr_data             <= 32'd0;
                                         axi_read_data           <= 32'd0;
                                         axi_wr_addr             <= 32'd0;
                                         axi_wr_addr_valid       <= 1'b0;
                                         axi_wr_data_valid       <= 1'b0;
                                         axi_wr_strobe           <= 4'd0;
                                         axi_rd_req              <= 1'b0;
                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         init_sanity_done        <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else 
                                             axi_user_prestate <= STATE_AXI_VERSION_READ;
                                     end

            STATE_AXI_VERSION_READ   :
		                     begin
                                        case (rd_wr_cntr)
                                             'd0     : begin
                                                           $display( "           AXI4 Lite Read Started for Core Version Reg..." );
                                                           axi_rd_addr             <= ADDR_CORE_VERSION_REG;
                                                           axi_rd_addr_valid       <= 1'b1;
                                                           axi_rd_req              <= 1'b1;
                                                           axi_wr_req              <= 1'b0;
                                                           version_reg_read        <= 1'b1;
                                                       end
                                             'd1     : begin
                                                           $display( "   Core_Version  =  %d.%0d",  axi_read_data[7:0], axi_read_data[15:8] ); 
                                                           
                                                           axi_rd_addr             <= 32'h0;
                                                           axi_rd_addr_valid       <= 1'b0;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b0;
                                                           version_reg_read        <= 1'b0;
                                                       end
                                             default : begin
                                                           axi_rd_addr             <= 32'h0;
                                                           axi_rd_addr_valid       <= 1'b0;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b0;
                                                           version_reg_read        <= 1'b0;                                             
                                                       end
                                         endcase
                                       
                                        if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                        else if  (rd_wr_cntr == 8'd1)
                                              begin
                                                  axi_user_prestate <= STATE_AXI_WR;
                                                  rd_wr_cntr              <= 8'd0;
                                              end
                                              else
                                                  axi_user_prestate <= STATE_AXI_RD_WR;
                                     end

            STATE_AXI_RD_WR          :
                                     begin
                                         if (s_axi_awready == 1'b1 )
                                         begin
                                             axi_wr_addr             <= 32'd0;
                                             axi_wr_addr_valid       <= 1'b0;
                                             axi_wr_req              <= 1'b0;
                                         end
                                         if (s_axi_wready == 1'b1  ) 
                                         begin
                                             axi_wr_data             <= 32'd0;
                                             axi_wr_data_valid       <= 1'b0;
                                             axi_wr_strobe           <= 4'd0;
                                         end
                                         if (s_axi_arready == 1'b1  )
                                         begin
                                             axi_rd_addr             <= 32'd0;
                                             axi_rd_addr_valid       <= 1'b0;
                                             axi_rd_req              <= 1'b0;
                                         end
                                         
                                         //// State transition
                                         if (pm_tick_r == 1'b1)
                                         begin
                                            rd_wr_cntr        <= rd_wr_cntr + 8'd1;
                                            axi_user_prestate <= STATE_READ_STATS;
                                         end
                                         else if  ((axi_wr_ack == 1'b1 && axi_wr_err == 1'b1) || (axi_rd_ack == 1'b1 && axi_rd_err == 1'b1))
                                         begin
                                             $display("ERROR : INVALID AXI4 Lite READ/WRITE OPERATION OCCURED, APPLY SYS_RESET TO RECOVER ..........");
                                             axi_user_prestate <= STATE_INVALID_AXI_RD_WR;
                                         end
                                         else if  ((axi_wr_ack == 1'b1 && axi_wr_err == 1'b0) || (axi_rd_ack == 1'b1 && axi_rd_err == 1'b0))
                                         begin
                                             rd_wr_cntr              <= rd_wr_cntr + 8'd1;
                                             axi_read_data           <= axi_rd_data;
                                             

                                             if  (init_rx_aligned == 1'b1 )
                                                 axi_user_prestate <= STATE_AXI_WR;
                                              else if (version_reg_read == 1'b1)
                                                   axi_user_prestate <= STATE_AXI_VERSION_READ;
                                             else if  (init_stat_read == 1'b1)
                                                 axi_user_prestate <= STATE_READ_STATS;
                                             else
                                                 axi_user_prestate <= STATE_AXI_RD_WR;
                                         end
                                     end
            STATE_WAIT_RX_ALIGNED    :
                                     begin
                                                                             
                                         axi_rd_addr             <= 32'd0;
                                         axi_rd_addr_valid       <= 1'b1;
                                         axi_wr_data             <= 32'd0;
                                         axi_read_data           <= 32'd0;
                                         axi_wr_addr             <= 32'd0;
                                         axi_wr_addr_valid       <= 1'b0;
					 axi_wr_data_valid       <= 1'b0;
					 axi_wr_strobe           <= 4'd0;
                                         axi_rd_req              <= 1'b0;
                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         
                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if  (stat_rx_aligned_sync == 1'b1)
                                         begin
                                             axi_user_prestate <= STATE_WAIT_SANITY_DONE;
                                         end
                                         else
                                             axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
                                     end

                      STATE_AXI_WR   :
                                     begin
                                         init_rx_aligned         <= 1'b1;
                                         
                                         case (rd_wr_cntr)
                                             'd0     : begin
                                                           $display( "           AXI4 Lite Write Started to MODE_REG ..." );
                                                           $display( " AXI_WR rd_wr_cntr=%d", rd_wr_cntr);
                                                           axi_wr_addr             <= ADDR_MODE_REG;    //// ADDR_MODE_REG 
                                                           axi_wr_data             <= 32'hC000_0000;	// loopback
                                                           //axi_wr_data             <= 32'h4000_0000;	// no loopback
                                                           axi_wr_addr_valid       <= 1'b1;
                                                           axi_wr_data_valid       <= 1'b1;
                                                           axi_wr_strobe           <= 4'hF;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b1;
                                                           init_rx_aligned         <= 1'b1;
                                                       end
                                             'd1     : begin
                                                           $display("INFO : AXI write completed to GT loopback register as Internal loopback ");
                                                           $display( "           AXI4 Lite Write Started to Config the Core CTL_* Ports ..." );
                                                           $display( " AXI_WR rd_wr_cntr=%d", rd_wr_cntr);
                                                           axi_wr_addr             <= ADDR_CONFIG_RX_REG1;
                                                           axi_wr_data             <= 32'h0000_0033;     // ctl_rx_enbale
                                                           axi_wr_addr_valid       <= 1'b1;
                                                           axi_wr_data_valid       <= 1'b1;
                                                           axi_wr_strobe           <= 4'hF;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b1;
                                                           
                                                       end
                                             'd2     : begin 
                                                           $display( " AXI_WR rd_wr_cntr=%d", rd_wr_cntr);
                                                           axi_wr_data             <= 32'h0000_3003;     // ctl_tx_enbale
                                                           axi_wr_addr             <= ADDR_CONFIG_TX_REG1;   
                                                           axi_wr_addr_valid       <= 1'b1;
                                                           axi_wr_data_valid       <= 1'b1;
                                                           axi_wr_strobe           <= 4'hF;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b1;
                                                           
                                                       end
                                             'd3     : begin 
                                                           $display( " AXI_WR rd_wr_cntr=%d", rd_wr_cntr);
                                                           axi_wr_data             <= 32'h0000_0001;     
                                                           axi_wr_addr             <= ADDR_GT_RESET_REG;   
                                                           axi_wr_addr_valid       <= 1'b1;
                                                           axi_wr_data_valid       <= 1'b1;
                                                           axi_wr_strobe           <= 4'hF;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b1;
                                                           
                                                       end
                                             'd4     : begin 
                                                           $display( " AXI_WR rd_wr_cntr=%d", rd_wr_cntr);
                                                           axi_wr_data             <= 32'h0000_0000;     
                                                           axi_wr_addr             <= ADDR_GT_RESET_REG;   
                                                           axi_wr_addr_valid       <= 1'b1;
                                                           axi_wr_data_valid       <= 1'b1;
                                                           axi_wr_strobe           <= 4'hF;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b1;
                                                           
                                                       end
                                             'd5     :  begin
                                                           $display( " AXI_WR rd_wr_cntr=%d", rd_wr_cntr);
                                                          axi_wr_data             <= 32'h00000001;   //// If input pin pm_tick = 1'b0, then AXI pm tick write 1'b1 will happen thru AXI interface
                                                          axi_wr_addr             <= ADDR_TICK_REG;  //// ADDR_TICK_REG
                                                          axi_wr_addr_valid       <= 1'b1;
                                                          axi_wr_data_valid       <= 1'b1;
                                                          axi_wr_strobe           <= 4'hF;
                                                          axi_rd_req              <= 1'b0;
                                                          axi_wr_req              <= 1'b1;
                                                        end
/*
                                             'd6     :  begin
                                                           $display( " AXI_WR rd_wr_cntr=%d AN", rd_wr_cntr);
							  // (bit 0) ctl_autoneg_enable = 1
							  // (bit 1) ctl_autonet_bypass = 0
                                                          axi_wr_data             <= 32'h00000001;
                                                          axi_wr_addr             <= ADDR_AN_CONTROL_REG1;
                                                          axi_wr_addr_valid       <= 1'b1;
                                                          axi_wr_data_valid       <= 1'b1;
                                                          axi_wr_strobe           <= 4'hF;
                                                          axi_rd_req              <= 1'b0;
                                                          axi_wr_req              <= 1'b1;
                                                        end
                                             'd7     :  begin
                                                           $display( " AXI_WR rd_wr_cntr=%d LT", rd_wr_cntr);
							  // (bit 0) ctl_lt_training_enable = 1
                                                          axi_wr_data             <= 32'h00000001;
                                                          axi_wr_addr             <= ADDR_LT_CONTROL_REG1;
                                                          axi_wr_addr_valid       <= 1'b1;
                                                          axi_wr_data_valid       <= 1'b1;
                                                          axi_wr_strobe           <= 4'hF;
                                                          axi_rd_req              <= 1'b0;
                                                          axi_wr_req              <= 1'b1;
                                                        end
*/
                                              default : begin
                                                           axi_wr_data             <= 32'h0;
                                                           axi_wr_addr             <= 32'h0;
                                                           axi_wr_addr_valid       <= 1'b0;
                                                           axi_wr_data_valid       <= 1'b0;
                                                           axi_wr_strobe           <= 4'h0;
                                                           axi_rd_req              <= 1'b0;
                                                           axi_wr_req              <= 1'b0;
                                                       end
                                                       
                                         endcase


                                            if  (rd_wr_cntr == 8'd6)
				            begin
                                              axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
					      init_rx_aligned   <= 1'b0;
                                              restart           <= 1'b0;
                                               $display( "           AXI4 Lite Write Completed" );
                                               $display( "           Reset release to GTWIZARD IP" );
					    end
                 			    else 
                                              axi_user_prestate <= STATE_AXI_RD_WR;
				            end
        

            STATE_WAIT_SANITY_DONE   :
                                      begin
                                         axi_rd_addr             <= 32'd0;
                                         axi_rd_addr_valid       <= 1'b0;
                                         axi_wr_data             <= 32'd0;
                                         axi_read_data           <= 32'd0;
                                         axi_wr_addr             <= 32'd0;
                                         axi_wr_addr_valid       <= 1'b0;
                                         axi_wr_data_valid       <= 1'b0;
                                         axi_wr_strobe           <= 4'd0;
                                         axi_rd_req              <= 1'b0;
                                         axi_wr_req              <= 1'b0;
                                        
                                         init_rx_aligned         <= 1'b0;
                                         restart                 <= 1'b0;
                                        
                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else if (( completion_status != 5'h1F ) && ( completion_status != 5'h0 )) 
                                         begin
                                             axi_user_prestate <= STATE_READ_STATS;
                                           
                                         end
                                         else
                                             axi_user_prestate <= STATE_WAIT_SANITY_DONE;
                                     end
            STATE_READ_STATS         : 
                                     begin
                                         init_stat_read          <= 1'b1;
                                         
                                         case (rd_wr_cntr)
                                             'd0       : begin
                                                             if (pm_tick_r == 1'b1)
                                                             begin
                                                                $display( "           PM Tick input is driven as %b", pm_tick_r );
                                                                axi_rd_addr             <= ADDR_STAT_TX_TOTAL_PACKETS_LSB;
                                                                axi_rd_addr_valid       <= 1'b1;
                                                                axi_rd_req              <= 1'b1;
                                                                axi_wr_req              <= 1'b0;
                                                             end
                                                             else
                                                             begin
                                                                $display( "           PM Tick is written through AXI4 Lite" );
                                                                axi_wr_data             <= 32'h00000001;   //// If input pin pm_tick = 1'b0, then AXI pm tick write 1'b1 will happen thru AXI interface
                                                                axi_wr_addr             <= ADDR_TICK_REG;  //// ADDR_TICK_REG
                                                                axi_wr_addr_valid       <= 1'b1;
                                                                axi_wr_data_valid       <= 1'b1;
                                                                axi_wr_strobe           <= 4'hF;
                                                                axi_rd_req              <= 1'b0;
                                                                axi_wr_req              <= 1'b1;
                                                             end
                                                       end
                                             'd1       : begin
                                                             $display( "           AXI4 Lite Read Started for TX and RX Stats..." );
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_PACKETS_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                       end
                                             'd2       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_PACKETS_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_pkt[31:0]              <= axi_read_data;
                                                       end
                                             'd3       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_PACKETS_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_pkt[47:32]             <= axi_read_data[15:0];
                                                       end
                                             'd4       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_PACKETS_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_good_pkts[31:0]        <= axi_read_data;
                                                       end
                                             'd5       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_BYTES_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_good_pkts[47:32]       <= axi_read_data[15:0];
                                                       end
                                             'd6       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_BYTES_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_bytes[31:0]            <= axi_read_data;
                                                       end
                                             'd7       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_BYTES_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_bytes[47:32]           <= axi_read_data[15:0];
                                                       end
                                             'd8       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_TX_TOTAL_GOOD_BYTES_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_good_bytes[31:0]       <= axi_read_data;
                                                       end
                                             'd9       : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_PACKETS_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             tx_total_good_bytes[47:32]      <= axi_read_data[15:0];
                                                       end
                                             'd10      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_PACKETS_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_pkt[31:0]              <= axi_read_data;
                                                       end
                                             'd11      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_PACKETS_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_pkt[47:32]             <= axi_read_data[15:0];
                                                       end
                                             'd12      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_PACKETS_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_good_pkts[31:0]        <= axi_read_data;
                                                       end
                                             'd13      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_BYTES_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_good_pkts[47:32]       <= axi_read_data[15:0];
                                                       end
                                             'd14      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_BYTES_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_bytes[31:0]            <= axi_read_data;
                                                       end
                                             'd15      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_BYTES_LSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_bytes[47:32]           <= axi_read_data[15:0];
                                                       end
                                             'd16      : begin
                                                             axi_rd_addr                     <= ADDR_STAT_RX_TOTAL_GOOD_BYTES_MSB;
                                                             axi_rd_addr_valid               <= 1'b1;
                                                             axi_rd_req                      <= 1'b1;
                                                             axi_wr_req                      <= 1'b0;
                                                             rx_total_good_bytes[31:0]       <= axi_read_data;
                                                       end
                                              default : begin
                                                             axi_wr_data                      <= 32'h0;
                                                             axi_wr_addr                      <= 32'h0;
                                                             axi_wr_addr_valid                <= 1'b0;
                                                             axi_wr_data_valid                <= 1'b0;
                                                             axi_wr_strobe                    <= 4'h0;
                                                             axi_rd_req                       <= 1'b0;
                                                             axi_wr_req                       <= 1'b0;
                                                             axi_rd_addr                      <= 32'd0;
                                                             axi_rd_addr_valid                <= 1'b0;
                                                       end
                                         endcase

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                         begin
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         end
                                         else if  (rd_wr_cntr == 8'd17)
                                         begin
                                             axi_user_prestate <= STATE_READ_DONE;
                                         end
                                         else
                                             axi_user_prestate <= STATE_AXI_RD_WR;
                                     end
            STATE_READ_DONE          :
                                     begin
                                         axi_rd_addr             <= 32'd0;
                                         axi_rd_addr_valid       <= 1'b0;
                                         axi_wr_data             <= 32'd0;
                                         axi_wr_addr             <= 32'd0;
                                         axi_wr_addr_valid       <= 1'b0;
                                         axi_wr_data_valid       <= 1'b0;
                                         axi_wr_strobe           <= 4'd0;
                                         axi_rd_req              <= 1'b0;
                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_stat_read          <= 1'b0;

                                         $display( "               STAT_TX_TOTAL_PACKETS           = %d,     STAT_RX_TOTAL_PACKETS           = %d", tx_total_pkt, rx_total_pkt );
                                         $display( "               STAT_TX_TOTAL_GOOD_PACKETS      = %d,     STAT_RX_TOTAL_GOOD_PACKETS      = %d", tx_total_good_pkts, rx_total_good_pkts );
                                         $display( "               STAT_TX_TOTAL_BYTES             = %d,     STAT_RX_TOTAL_BYTES             = %d", tx_total_bytes, rx_total_bytes );
                                         $display( "               STAT_TX_TOTAL_GOOD_BYTES        = %d,     STAT_RX_TOTAL_GOOD_BYTES        = %d", tx_total_good_bytes, rx_total_good_bytes );
                                         $display( "           AXI4 Lite Read Completed" );
                                         if  ((tx_total_pkt == rx_total_pkt) && (tx_total_good_pkts == rx_total_good_pkts) && 
                                              (tx_total_bytes == rx_total_bytes) && (tx_total_good_bytes == rx_total_good_bytes))
                                             stat_reg_compare <= 1'b1;
                                         else 
                                             stat_reg_compare <= 1'b0; 

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else 
                                             axi_user_prestate <= STATE_TEST_DONE;
                                     end
             STATE_TEST_DONE         :
                                     begin
                                         axi_rd_addr             <= 32'd0;
                                         axi_rd_addr_valid       <= 1'b0;
                                         axi_wr_data             <= 32'd0;
                                         axi_wr_addr             <= 32'd0;
                                         axi_wr_addr_valid       <= 1'b0;
                                         axi_wr_data_valid       <= 1'b0;
                                         axi_wr_strobe           <= 4'd0;
                                         axi_rd_req              <= 1'b0;
                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_stat_read          <= 1'b0;
                                         stat_reg_compare        <= 1'b0; 

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                        else if (( completion_status == 5'h1F ) || ( completion_status == 5'h0 ))
                                             axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
                                         else
                                             axi_user_prestate <= STATE_TEST_DONE;
                                     end
             STATE_INVALID_AXI_RD_WR :
                                     begin
                                         axi_rd_addr             <= 32'd0;
                                         axi_rd_addr_valid       <= 1'b0;
                                         axi_wr_data             <= 32'd0;
                                         axi_wr_addr             <= 32'd0;
                                         axi_wr_addr_valid       <= 1'b0;
                                         axi_wr_data_valid       <= 1'b0;
                                         axi_wr_strobe           <= 4'd0;
                                         axi_rd_req              <= 1'b0;
                                         axi_wr_req              <= 1'b0;
                                         rd_wr_cntr              <= 8'd0;
                                         init_rx_aligned         <= 1'b0;
                                         init_stat_read          <= 1'b0;

                                         //// State transition
                                         if  (gt_locked_sync == 1'b0)
                                             axi_user_prestate <= STATE_AXI_IDLE;
                                         else
                                             axi_user_prestate <= STATE_INVALID_AXI_RD_WR;
                                     end
            default                  :
                                     begin
                                         axi_rd_addr               <= 32'd0;
                                         axi_rd_addr_valid         <= 1'b0;
                                         axi_wr_data               <= 32'd0;
                                         axi_read_data             <= 32'd0;
                                         axi_wr_addr               <= 32'd0;
                                         axi_wr_addr_valid         <= 1'b0;
                                         axi_wr_data_valid         <= 1'b0;
                                         axi_wr_strobe             <= 4'd0;
                                         axi_rd_req                <= 1'b0;
                                         axi_wr_req                <= 1'b0;
                                         rd_wr_cntr                <= 8'd0;
                                         init_rx_aligned           <= 1'b0;
                                         init_stat_read            <= 1'b0;
                                         restart                   <= 1'b0;
                                         version_reg_read          <= 1'b0;
                                         init_sanity_done          <= 1'b1;
                                         tx_total_pkt              <= 48'd0;
                                         tx_total_bytes            <= 48'd0;
                                         tx_total_good_pkts        <= 48'd0;
                                         tx_total_good_bytes       <= 48'd0;
                                         rx_total_pkt              <= 48'd0;
                                         rx_total_bytes            <= 48'd0;
                                         rx_total_good_pkts        <= 48'd0;
                                         rx_total_good_bytes       <= 48'd0;
				                        
                                         axi_user_prestate         <= STATE_AXI_IDLE;
                                     end
            endcase
        end
    end

xxv_ethernet_0_axi4_lite_rd_wr_if i_xxv_ethernet_0_axi4_lite_rd_wr_if
  (
    .axi_aclk(s_axi_aclk),
    .axi_sreset(s_axi_sreset),
    .axi_bresp(s_axi_bresp),
    .axi_bvalid(s_axi_bvalid),
    .axi_bready(s_axi_bready),
    .axi_rdata(s_axi_rdata),
    .axi_rresp(s_axi_rresp),
    .axi_rvalid(s_axi_rvalid),
    .axi_rready(s_axi_rready),
    .axi_awaddr(s_axi_awaddr),
    .axi_awvalid(s_axi_awvalid),
    .axi_awready(s_axi_awready),
    .axi_wdata(s_axi_wdata),
    .axi_wstrb(s_axi_wstrb),
    .axi_wvalid(s_axi_wvalid),
    .axi_wready(s_axi_wready),
    .axi_araddr(s_axi_araddr),
    .axi_arvalid(s_axi_arvalid),
    .axi_arready(s_axi_arready),
    .usr_write_req(axi_wr_req),
    .usr_read_req(axi_rd_req),
    .usr_rdata(axi_rd_data),
    .usr_araddr(axi_rd_addr),
    .usr_arvalid(axi_rd_addr_valid),
    .usr_awaddr(axi_wr_addr),
    .usr_awvalid(axi_wr_addr_valid),
    .usr_wdata(axi_wr_data),
    .usr_wvalid(axi_wr_data_valid),
    .usr_wstrb(axi_wr_strobe),    
    .usr_wrack(axi_wr_ack),
    .usr_rdack(axi_rd_ack),
    .usr_wrerr(axi_wr_err),
    .usr_rderr(axi_rd_err)
  );
 


   xxv_ethernet_0_cdc_sync_axi i_xxv_ethernet_0_cdc_sync_rx_gt_locked_led
  (
   .clk              (s_axi_aclk),
   .signal_in        (rx_gt_locked), 
   .signal_out       (gt_locked_sync)
  );
  
   xxv_ethernet_0_cdc_sync_axi i_xxv_ethernet_0_cdc_sync_stat_rx_aligned
  (
   .clk              (s_axi_aclk),
   .signal_in        (stat_rx_aligned), 
   .signal_out       (stat_rx_aligned_sync)
  );
 
  


  assign pm_tick_r        = s_axi_pm_tick;
    ////----------------------------------------END TX Module-----------------------//

endmodule

(* DowngradeIPIdentifiedWarnings="yes" *)
module xxv_ethernet_0_axi4_lite_rd_wr_if
  (

  input  wire                    axi_aclk,
  input  wire                    axi_sreset,

  input  wire                    usr_write_req,
  input  wire                    usr_read_req,

  //// write side from usr
  input  wire [31:0]             usr_awaddr,
  input  wire                    usr_awvalid,
  input  wire [31:0]             usr_wdata,
  input  wire                    usr_wvalid,
  input  wire [3:0]              usr_wstrb,

  //// write response from axi
  input  wire [1:0]              axi_bresp,
  input  wire                    axi_bvalid,
  output wire                    axi_bready,

  //// read side from usr
  input  wire [31:0]             usr_araddr,
  input  wire                    usr_arvalid,

  //// read side from axi
  input  wire [31:0]             axi_rdata,
  input  wire [1:0]              axi_rresp,
  
  input  wire                    axi_rvalid,
  output wire                    axi_rready,
  output wire                    axi_arvalid,
  input  wire                    axi_arready,

  //// write side to axi
  output wire [31:0]             axi_awaddr,
  output wire                    axi_awvalid,
  input  wire                    axi_awready,

  output wire [31:0]             axi_wdata,
  output wire [3:0]              axi_wstrb,
  output wire                    axi_wvalid,
  input  wire                    axi_wready,

  //// read side to usr
  output wire [31:0]             usr_rdata,
  output wire [31:0]             axi_araddr, 
  output wire                    usr_wrack,
  output wire                    usr_rdack,
  output wire                    usr_wrerr,
  output wire                    usr_rderr
  );

  //// States
  parameter IDLE_STATE  = 0;
  parameter WRITE_STATE = 1;
  parameter READ_STATE  = 2;
  parameter ACK_STATE   = 3;

  reg [2:0] pstate;

  reg [31:0]             axi_awaddr_r;
  reg                    axi_awvalid_r;
  reg [31:0]             axi_wdata_r;
  reg [31:0]             axi_rdata_r;
  reg [3:0]              axi_wstrb_r;
  reg                    axi_wvalid_r;

  reg [31:0]             usr_araddr_r;
  reg                    usr_wrack_r;
  reg                    usr_rdack_r;
  reg                    usr_wrerr_r;
  reg                    usr_rderr_r;

  reg                    axi_arvalid_r;
  reg                    axi_bready_r;
  reg                    axi_rready_r;

  assign axi_awaddr   =  axi_awaddr_r;
  assign axi_awvalid  =  axi_awvalid_r;
  assign axi_wdata    =  axi_wdata_r;
  assign axi_wstrb    =  axi_wstrb_r;
  assign axi_wvalid   =  axi_wvalid_r;

  assign usr_rdata    =  axi_rdata_r;
  assign axi_bready   =  axi_bready_r;
  assign axi_rready   =  axi_rready_r;
  assign axi_arvalid  =  axi_arvalid_r;
  assign axi_araddr   =  usr_araddr_r;

  assign usr_wrack    =  usr_wrack_r;
  assign usr_rdack    =  usr_rdack_r;
  assign usr_wrerr    =  usr_wrerr_r;
  assign usr_rderr    =  usr_rderr_r;

//////////////////////////////////////////////////////////////////////////////
//// Implement axi_bready generation
////
////  axi_bready is asserted for one s_axi_aclk clock cycle when 
////  axi_bvalid is asserted. axi_bready is
////  de-asserted when reset is low.
//////////////////////////////////////////////////////////////////////////////
  always @(posedge axi_aclk)
  begin
     if (axi_sreset == 1'b1)
     begin
        axi_bready_r  <=  1'b0;
     end
     else
     begin
        if ((~axi_bready_r) && (axi_bvalid))
           axi_bready_r  <=  1'b1;
        else
           axi_bready_r  <=  1'b0;
     end
  end

//////////////////////////////////////////////////////////////////////////////
//// Implement axi_rready generation
////
////  axi_rready is asserted for one axi_aclk clock cycle when
////  axi_rvalid is asserted. axi_rready is
////  de-asserted when reset (active low) is asserted.
//////////////////////////////////////////////////////////////////////////////
  always @(posedge axi_aclk)
  begin
     if (axi_sreset == 1'b1)
     begin
        axi_rready_r  <=  1'b0;
     end
     else
     begin
        if ((~axi_rready_r) && (axi_rvalid))
           axi_rready_r  <=  1'b1;
        else
           axi_rready_r  <=  1'b0;
     end
  end

//////////////////////////////////////////////////////////////////////////////
//// State machine flow
//////////////////////////////////////////////////////////////////////////////
  always @(posedge axi_aclk)
  begin
     if (axi_sreset == 1'b1)
     begin
        pstate        <=  IDLE_STATE;

        axi_arvalid_r <=  1'b0;
        usr_araddr_r  <=  32'd0;
        axi_rdata_r   <=  32'd0;

        axi_awvalid_r <=  1'b0;
        axi_awaddr_r  <=  32'd0;
        axi_wvalid_r  <=  1'b0;
        axi_wdata_r   <=  32'd0;
        axi_wstrb_r   <=  4'd0;

        usr_wrack_r   <=  1'b0;
        usr_rdack_r   <=  1'b0;
        usr_wrerr_r   <=  1'b0;
        usr_rderr_r   <=  1'b0;
     end
     else
     begin
        case (pstate)
                IDLE_STATE    : begin
                                    if (usr_read_req == 1'b1)
                                    begin
                                       pstate        <=  READ_STATE;
                                       axi_arvalid_r <=  usr_arvalid;
                                       usr_araddr_r  <=  usr_araddr;
                                    end
                                    else if (usr_write_req == 1'b1)
                                    begin
                                       pstate        <=  WRITE_STATE;
                                       axi_awvalid_r <=  usr_awvalid;
                                       axi_awaddr_r  <=  usr_awaddr;
                                       axi_wvalid_r  <=  usr_wvalid;
                                       axi_wdata_r   <=  usr_wdata;
                                       axi_wstrb_r   <=  usr_wstrb;
                                    end
                                    else
                                    begin
                                       pstate        <=  IDLE_STATE;
                                       axi_arvalid_r <=  1'b0;
                                       usr_araddr_r  <=  32'd0;
                                       axi_rdata_r   <=  32'd0;

                                       axi_awvalid_r <=  1'b0;
                                       axi_awaddr_r  <=  32'd0;
                                       axi_wvalid_r  <=  1'b0;
                                       axi_wdata_r   <=  32'd0;
                                       axi_wstrb_r   <=  4'd0;

                                       usr_wrack_r   <=  1'b0;
                                       usr_rdack_r   <=  1'b0;
                                       usr_wrerr_r   <=  1'b0;
                                       usr_rderr_r   <=  1'b0;
                                    end
                                 end

                WRITE_STATE    : begin
                                    if ((axi_bvalid == 1'b1) && (axi_bready_r == 1'b1))
                                    begin
                                       pstate        <=  ACK_STATE;
                                       usr_wrack_r   <=  1'b1;
                                       if (axi_bresp == 2'b10)
                                          usr_wrerr_r <=  1'b1;
                                       else
                                          usr_wrerr_r <=  1'b0;
                                    end
                                    else
                                    begin
                                       pstate        <=  WRITE_STATE;
                                       axi_awvalid_r <=  usr_awvalid;
                                       axi_awaddr_r  <=  usr_awaddr;
                                       axi_wvalid_r  <=  usr_wvalid;
                                       axi_wdata_r   <=  usr_wdata;
                                       axi_wstrb_r   <=  usr_wstrb;
                                    end
                                 end

                READ_STATE     : begin
                                    if ((axi_rvalid == 1'b1) && (axi_rready_r == 1'b1)) begin
                                       pstate        <=  ACK_STATE;
                                       axi_rdata_r   <=  axi_rdata;
                                       usr_rdack_r   <=  1'b1;
                                       if (axi_rresp == 2'b10)
                                          usr_rderr_r <=  1'b1;
                                       else
                                          usr_rderr_r <=  1'b0;
                                    end
                                    else
                                    begin
                                       pstate        <=  READ_STATE;
                                       axi_arvalid_r <=  usr_arvalid;
                                       usr_araddr_r  <=  usr_araddr;
                                    end
                                 end

                ACK_STATE      : begin
                                    pstate        <=  IDLE_STATE;
                                    usr_wrack_r   <=  1'b0;
                                    usr_rdack_r   <=  1'b0;
                                    usr_wrerr_r   <=  1'b0;
                                    usr_rderr_r   <=  1'b0;
                                 end

                default        : begin
                                    pstate                   <=  IDLE_STATE;
                                    axi_arvalid_r            <=  1'b0;
                                    usr_araddr_r             <=  32'd0;
                                    axi_rdata_r              <=  32'd0;
                                    
                                    axi_awvalid_r            <=  1'b0;
                                    axi_awaddr_r             <=  32'd0;
                                    axi_wvalid_r             <=  1'b0;
                                    axi_wdata_r              <=  32'd0;
                                    axi_wstrb_r              <=  4'd0;
                                    
                                    usr_wrack_r              <=  1'b0;
                                    usr_rdack_r              <=  1'b0;
                                    usr_wrerr_r              <=  1'b0;
                                    usr_rderr_r              <=  1'b0;
                                 end
        endcase
     end
  end

endmodule


(* DowngradeIPIdentifiedWarnings="yes" *)
module xxv_ethernet_0_cdc_sync_axi (
 input clk,
 input signal_in,
 output wire signal_out
);

                          wire sig_in_cdc_from ;
 (* ASYNC_REG = "TRUE" *) reg  s_out_d2_cdc_to;
 (* ASYNC_REG = "TRUE" *) reg  s_out_d3;

assign sig_in_cdc_from = signal_in;
assign signal_out      = s_out_d3;

always @(posedge clk) 
begin
  s_out_d2_cdc_to  <= sig_in_cdc_from;
  s_out_d3         <= s_out_d2_cdc_to;
end

endmodule

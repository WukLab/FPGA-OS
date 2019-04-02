/* ------------------------------------------------------------------------------
 * Title      : AXI-S Master Acknowledgment Buffer
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : ack_queue_512.v
 * -----------------------------------------------------------------------------
 * Description: Sends a cumulative acknowledgement packet out on Sysnet_tx,
 *              one packet per app. Interfaces with each app's instance
 *              of Libnet using a 32 bit sequence number input port per
 *              app. While not sending packets out to sysnet, the queue
 *              accepts new updates to the expected sequence number,
 *              which will be transmitted the next time the queue is 
 *              selected by Sysnet. If no updates have been received from
 *              an instance of libnet, it sends out an ack with the default
 *              expected sequence number (0).
 *
 * -----------------------------------------------------------------------------
 */
 
`timescale 1ns / 1ps


module ack_queue
(
    output reg [511:0]      tx_tdata,
    output reg [63:0]       tx_tkeep,
    output reg              tx_tvalid,
    output reg [63:0]       tx_tuser,
    output reg              tx_tlast,
    input  wire             tx_tready,
    input  wire             clk,
    input  wire             resetn,
    input  wire [31:0]      seq0_in,
    input  wire             seq0_valid,
    input  wire [31:0]      seq1_in,
    input  wire             seq1_valid
    );
    
    /* Ethernet Header (14B) */
    parameter MAC_DEST = 48'hA1B1C1D1E1F1;
    parameter MAC_SRC  = 48'h121212121212;
    parameter ETHTYPE  = 16'h0800;
    
    /* IP Header (20B) */
    parameter IP_WORD0 = 32'hAAAAAAAA;
    parameter IP_WORD1 = 32'hAAAAAAAA;
    parameter IP_WORD2 = 32'hAAAAAAAA;
    parameter IP_WORD3 = 32'hAAAAAAAA;
    parameter IP_WORD4 = 32'hAAAAAAAA;
    
    /* UDP Header (8B) */
    parameter PORT_SRC = 16'hBBBB;
    parameter PORT_DST = 16'hBBBB;
    parameter LENGTH   = 16'hBBBB;
    parameter CHECKSUM = 16'hBBBB;
    
    /* LEGO HEADER (22B with padding) */
    localparam      APP_ID0 = 8'h00;
    localparam      APP_ID1 = 8'h01;
    reg [31:0]      seq0_num = 32'h0;
    reg [31:0]      seq1_num = 32'h0;
    localparam      ACK = 1'b1;
    localparam      SYN = 1'b0;
    localparam      PAD = 134'b0;
    
    localparam [1:0] IDLE = 2'b00,
                     APP0 = 2'b01,
                     APP1 = 2'b10;
                     
    reg [1:0]   state = IDLE;
    
    
    always @ (posedge clk) begin
        if(!resetn) begin
            state <= IDLE;
            tx_tvalid <= 0;
            seq0_num <= 32'h0;
            seq1_num <= 32'h0;
        end else begin 
            case (state)
             
                IDLE: begin
                    tx_tvalid <= 1'b0;
                    if (tx_tready) begin
                        state <= APP0;
                    end else begin
                        state <= IDLE;
                    end
                    if (seq0_valid) begin
                        seq0_num <= seq0_in;
                    end
                    if (seq1_valid) begin
                        seq1_num <= seq1_in;
                    end
                end
                
                APP0: begin
                    if (!tx_tready) begin
                        state <= APP0;
                    end else begin
                        state <= APP1;
                        tx_tvalid <= 1'b1;
                        tx_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                        tx_tuser <= 64'hFFFFFFFFFFFFFFFF;
                        tx_tlast <= 1'b0;
                        tx_tdata <= {PAD,
                                     SYN,
                                     ACK,
                                     seq0_num,
                                     APP_ID0,
                                     CHECKSUM,
                                     LENGTH,
                                     PORT_DST,
                                     PORT_SRC,
                                     IP_WORD4,
                                     IP_WORD3,
                                     IP_WORD2,
                                     IP_WORD1,
                                     IP_WORD0,
                                     ETHTYPE,
                                     MAC_SRC,
                                     MAC_DEST};
                   end
                end
                
                APP1: begin
                    if (!tx_tready) begin
                        state <= APP1;
                    end else begin
                        state <= IDLE;
                        tx_tvalid <= 1'b1;
                        tx_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                        tx_tuser <= 64'hFFFFFFFFFFFFFFFF;
                        tx_tlast <= 1'b1;
                        tx_tdata <= {PAD,
                                     SYN,
                                     ACK,
                                     seq1_num,
                                     APP_ID1,
                                     CHECKSUM,
                                     LENGTH,
                                     PORT_DST,
                                     PORT_SRC,
                                     IP_WORD4,
                                     IP_WORD3,
                                     IP_WORD2,
                                     IP_WORD1,
                                     IP_WORD0,
                                     ETHTYPE,
                                     MAC_SRC,
                                     MAC_DEST};
                   end
                end
            endcase
        end
    end  
endmodule

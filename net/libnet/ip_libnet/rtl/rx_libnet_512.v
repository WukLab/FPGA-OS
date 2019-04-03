/* ------------------------------------------------------------------------------
 * Title      : AXI-S Receive Libnet
 * Project    : LegoFPGA 
 * -----------------------------------------------------------------------------
 * File       : rx_libnet_512.v
 * -----------------------------------------------------------------------------
 * Description: Axi-S slave connected to sysnet, forwards packets on to app if
 *              the expected sequence number matches the sequence number of the
 *              current packet. If the sequence number does not match the 
 *              expected sequence number, the packet is dropped. Acknowledgements
 *              are transmitted to the ack queue via the 32-bit seq_expected 
 *              interface.The sync (SYN) bit is used by the host to reset the 
 *              expected sequence number of libnet to a known state. When the 
 *              SYN bit is 1, libnet sets seq_expected to the sequence number
 *              included in that packet, and any payload data included in that 
 *              packet is dropped.
 *
 * -----------------------------------------------------------------------------
 */
 
`timescale 1ns / 1ps
//`define CONFIG_HEADER_RIP_OFF

module rx_libnet_512(
    output reg [511:0]      tx_tdata,
    output reg [63:0]       tx_tkeep,
    output reg              tx_tvalid,
    output reg [63:0]       tx_tuser,
    output reg              tx_tlast,
    input  wire             tx_tready,
    output reg [31:0]       seq_expected,
    output reg              seq_valid,
    input  wire             clk,
    input  wire             resetn,
    input wire [511:0]      rx_tdata,
    input wire [63:0]       rx_tkeep,
    input wire              rx_tvalid,
    input wire [63:0]       rx_tuser,
    input wire              rx_tlast,
    output reg              rx_tready
    );
    
    parameter CURRENT_SEQ_LSB = 344;
    parameter CURRENT_SEQ_MSB = 375;
    parameter ACK_FLAG = 376;
    parameter SYN_FLAG = 377;
    
    
    localparam [1:0] PARSE_HEADER = 2'b00,
                     STREAM_PACKET = 2'b01,
                     DROP_PACKET = 2'b10;
                     
     reg [1:0] state = PARSE_HEADER;
                     
    always @(posedge clk) begin
        if (!resetn) begin
            tx_tvalid <= 1'b0;
            rx_tready <= 1'b0;
            seq_expected <= 32'h0;
            seq_valid <= 1'b0;
            state <= PARSE_HEADER;
        end
        else begin
            case (state)
            
                /* Header is not transmitted to Application */
                PARSE_HEADER: begin
                    rx_tready <= 1'b1;
                    if (!rx_tvalid) begin
                        state <= PARSE_HEADER;
                        tx_tvalid <= 1'b0;
                    end else begin
                        if (rx_tdata[SYN_FLAG]) begin
                            seq_expected <= rx_tdata[CURRENT_SEQ_MSB:CURRENT_SEQ_LSB];
                            seq_valid <= 1'b1;
                            tx_tvalid <= 1'b0;
                            if (rx_tlast) begin
                                state <= PARSE_HEADER;
                            end else begin
                                state <= DROP_PACKET;
                            end
                        end else begin
                            if (rx_tdata[CURRENT_SEQ_MSB:CURRENT_SEQ_LSB] == seq_expected) begin
                                seq_expected <= seq_expected + 1;
                                seq_valid <= 1'b1;
                                state <= STREAM_PACKET;
                                `ifdef CONFIG_HEADER_RIP_OFF
                                tx_tvalid <= 1'b0;
                                `endif
                                `ifndef CONFIG_HEADER_RIP_OFF
                                tx_tvalid <= rx_tvalid;
                                tx_tdata <= rx_tdata;
                                tx_tkeep <= rx_tkeep;
                                tx_tuser <= rx_tuser;
                                tx_tlast <= rx_tlast;
                                `endif
                            end else begin
                                state <= DROP_PACKET;
                                tx_tvalid <= 1'b0;
                            end
                        end
                    end
                end
                
                STREAM_PACKET: begin
                   if (!rx_tvalid) begin
                       tx_tvalid <= 1'b0;
                       rx_tready <= 1'b1;
                       state <= STREAM_PACKET;
                   end else begin
                       /* Frame is valid so transmit to app */
                       tx_tdata <= rx_tdata;
                       tx_tkeep <= rx_tkeep;
                       tx_tvalid <= 1'b1;
                       tx_tuser <= rx_tuser;
                       tx_tlast <= rx_tlast;
                       
                       /* If app's receive interface isn't ready, stall until it is */
                       if (!tx_tready) begin
                           rx_tready <= 1'b0;
                           state <= STREAM_PACKET;
                       end else begin
                           rx_tready <= 1'b1;
                           if (rx_tlast) begin
                               state <= PARSE_HEADER;
                           end else begin
                               state <= STREAM_PACKET;
                           end
                       end
                   end
                end
                
                DROP_PACKET: begin
                    tx_tvalid <= 1'b0;
                    rx_tready <= 1'b1;
                    if (rx_tvalid && rx_tlast) begin
                        state <= PARSE_HEADER;
                    end else begin
                        state <= DROP_PACKET;
                    end
                end       
            endcase
        end
    end
endmodule


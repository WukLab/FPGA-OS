/* ------------------------------------------------------------------------------
 * Title      : 512 bit Reliable Libnet Receiver Testbench
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : rx_libnet_512_tb.v
 * -----------------------------------------------------------------------------
 * Description: Reads data from an input file and transmits it
 *              across the AXIS Tx interface to Libnet. 
 *              Libnet drops packets if the sequence nubmer of the packet
 *              does not match the expected sequence number, otherwise it sends
 *              the packet back to the testbench where it is written to an output
 *              file. The testbench closes the files and finishes the simulation
 *              after no data is received for a given threshold of time.
 *
 *              Input file format:
 *
 *              First line          -   [pktsize]
 *              Next pktsize lines  -   [tdata] [tkeep]
 *              (Repeat for however many packets need to be sent)
 *
 *              pktsize = ceiling (#packet bytes / 64), represented in base 10
 *              tdata = 64 bytes of payload data, represented in base 16
 *              tkeep = 8 bytes to indicate valid channels, represented in base 16
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps
`define LOOPBACK_DISABLED

module rx_libnet_512_tb(
       );
parameter IN_FILEPATH="/home/aaron/FPGAmain/FPGA/system/vcu108/generated_vivado_project/generated_vivado_project.srcs/sim_1/new/test_inputs.txt";
parameter OUT_FILEPATH="/home/aaron/FPGAmain/FPGA/system/vcu108/generated_vivado_project/generated_vivado_project.srcs/sim_1/new/test_outputs.txt";
parameter CLK_PERIOD = 20.48;
parameter TIMEOUT_THRESH = 10000;

integer infd, outfd;
integer pktlen, finished, timeout, timedout;
reg clk, resetn;

/* Testbench TX AXIS signals */
reg [511:0] tx_tdata;
reg [63:0] tx_tkeep;
reg [63:0] tx_tuser;
reg tx_tvalid, tx_tlast;
wire tx_tready;

/* Testbench RX AXIS signals */
wire [511:0] rx_tdata;
wire [63:0] rx_tkeep;
wire [63:0] rx_tuser;
wire rx_tvalid, rx_tlast;
reg rx_tready;

/* Wires to connect DUT output to Loopback input */
`ifndef LOOPBACK_DISABLED
wire [511:0] inter_tdata;
wire [63:0] inter_tkeep;
wire [63:0] inter_tuser;
wire inter_tvalid, inter_tlast;
wire inter_tready;
`endif

/* Transmit input file Data */
initial begin
    resetn = 0;
    # CLK_PERIOD;
    resetn =1;
    finished = 0;
    pktlen = 1;
    tx_tkeep = 64'hFFFFFFFFFFFFFFFF;
    tx_tvalid = 0;
    tx_tlast = 0;
    tx_tuser = 64'hFFFFFFFFFFFFFFFF;
    infd = $fopen(IN_FILEPATH,"r");
    if (infd == 0) begin
        $display("ERROR, input file not found\n");
        $finish;
        end
    
    /* Read and transmit each line */
    while (!finished) begin
        $fscanf(infd,"%d\n",pktlen);
        while (pktlen != 0) begin
            if (tx_tready) begin
                $fscanf(infd,"%h %h\n",tx_tdata, tx_tkeep);
                pktlen = pktlen - 1; 
                tx_tvalid = 1;
                tx_tlast = 0;
                if ($feof(infd)) begin
                    finished = 1;
                    end
                end
            else begin
                tx_tvalid = 0;
                end
                
            if (!finished && (pktlen != 0)) begin
                # CLK_PERIOD;
                end
            end
         tx_tlast = 1;
         # CLK_PERIOD;
         tx_tvalid = 0;
         end
     end

/* Receive Data from DUT and write to output file */
initial begin
    outfd = $fopen(OUT_FILEPATH,"w");
    rx_tready = 1;
    timeout = 0;
    timedout = 0;
    if (outfd == 0) begin
        $display("ERROR, can't write output file\n");
        $finish;
        end
    while (!timedout) begin
        if ( rx_tvalid) begin
            $fdisplay(outfd,"%h %h", rx_tdata, rx_tkeep);
            timeout = 0;
            # CLK_PERIOD;
            end
        else begin
            # CLK_PERIOD;
            timeout = timeout + 1;
            end
        if (timeout > TIMEOUT_THRESH) begin
                timedout = 1;
                end
        end
       /* Timeout occurred close files and end simulation */
       $fclose(infd);
       $fclose(outfd);
       $display("SUCCESS - Simulation ended due to RX timeout");
       $finish;
    end
    

/* Clock Generation (48.828125 MHz / 20.48 ns) */
initial begin
    clk = 0;
    forever # (CLK_PERIOD/2) clk = ~clk;
    end

/* Instantiate DUT with Xilinx AXI Loopback module*/
`ifndef LOOPBACK_DISABLED
rx_libnet_512 DUT (
    .clk(clk),
    .resetn(resetn),
    .seq_expected(),
    .seq_valid(),
    .rx_tdata(tx_tdata),
    .rx_tkeep(tx_tkeep),
    .rx_tvalid(tx_tvalid),
    .rx_tuser(tx_tuser),
    .rx_tlast(tx_tlast),
    .rx_tready(tx_tready),
    .tx_tdata(inter_tdata),
    .tx_tkeep(inter_tkeep),
    .tx_tvalid(inter_tvalid),
    .tx_tuser(inter_tuser),
    .tx_tlast(inter_tlast),
    .tx_tready(inter_tready)
);

/* Xilinx loopback module (512-bit axis slave) */
axi_traffic_gen_0 LOOPBACK (
    .s_axi_aclk(clk),
    .s_axi_aresetn(resetn),
    .s_axis_2_tready(inter_tready),
    .s_axis_2_tdata(inter_tdata),
    .s_axis_2_tkeep(inter_tkeep),
    .s_axis_2_tvalid(inter_tvalid),
    .s_axis_2_tlast(inter_tlast),
    .s_axis_2_tuser(inter_tuser),
    .m_axis_2_tready(rx_tready),
    .m_axis_2_tdata(rx_tdata),
    .m_axis_2_tkeep(rx_tkeep),
    .m_axis_2_tvalid(rx_tvalid),
    .m_axis_2_tlast(rx_tlast),
    .m_axis_2_tuser(rx_tuser));
`endif

/* Instantiate DUT without Xilinx AXI Loopback module*/
`ifdef LOOPBACK_DISABLED
rx_libnet_512 DUT (
    .clk(clk),
    .resetn(resetn),
    .seq_expected(),
    .seq_valid(),
    .rx_tdata(tx_tdata),
    .rx_tkeep(tx_tkeep),
    .rx_tvalid(tx_tvalid),
    .rx_tuser(tx_tuser),
    .rx_tlast(tx_tlast),
    .rx_tready(tx_tready),
    .tx_tdata(rx_tdata),
    .tx_tkeep(rx_tkeep),
    .tx_tvalid(rx_tvalid),
    .tx_tuser(rx_tuser),
    .tx_tlast(rx_tlast),
    .tx_tready(rx_tready)
);
`endif
endmodule
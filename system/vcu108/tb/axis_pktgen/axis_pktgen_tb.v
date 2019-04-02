/* ------------------------------------------------------------------------------
 * Title      : AXI-S Packet generator / monitor testbench
 * Project    : LegoFPGA 
 * ------------------------------------------------------------------------------
 * File       : axis_pktgen_tb.v
 * -----------------------------------------------------------------------------
 * Description: Reads data from an input file and transmits it
 *              across the AXIS Tx interface. Data received from  the Rx interface
 *              is written to an output file. Closes files and finishes simulation
 *              after no data is received for a given threshold of time.
 *
 *              Input file format:
 *
 *              First line          -   [pktsize]
 *              Next pktsize lines  -   [tdata] [tkeep]
 *              (Repeat for however many packets need to be sent)
 *
 *              pktsize = ceiling (#packet bytes / 8), represented in base 10
 *              tdata = 8 bytes of payload data, represented in base 16
 *              tkeep = 1 byte to indicate valid channels, represented in base 16
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps

 
module axis_pktgen_tb(
    );
    parameter IN_FILEPATH="/home/aaron/FPGAmain/FPGA/system/vcu108/generated_vivado_project/generated_vivado_project.srcs/sim_1/new/test_inputs.txt";
    parameter OUT_FILEPATH="/home/aaron/FPGAmain/FPGA/system/vcu108/generated_vivado_project/generated_vivado_project.srcs/sim_1/new/test_outputs.txt";
    parameter CLK_PERIOD = 2.56;
    parameter TIMEOUT_THRESH = 100;
    
    integer infd, outfd;
    integer pktlen, finished, timeout, timedout;
    reg clk, resetn;
    
    /* Testbench TX AXIS signals */
    reg [63:0] tx_tdata;
    reg [7:0] tx_tkeep;
    reg tx_tvalid, tx_tuser, tx_tlast;
    wire tx_tready;
    
    /* Testbench RX AXIS signals */
    wire [63:0] rx_tdata;
    wire [7:0] rx_tkeep;
    wire rx_tvalid, rx_tuser, rx_tlast;
    reg rx_tready;
    
    /* Transmit input file Data */
    initial begin
        resetn = 0;
        # CLK_PERIOD;
        resetn =1;
        finished = 0;
        pktlen = 1;
        tx_tkeep = 8'hFF;
        tx_tvalid = 0;
        tx_tlast = 0;
        tx_tuser = 1;
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
           $finish("Simulation ended due to RX timeout");
        end
        
    
    /* Clock Generation (390.625 MHz / 2.56 ns) */
    initial begin
        clk = 0;
        forever # (CLK_PERIOD/2) clk = ~clk;
        end
    
    /* Instantiate DUT */
    axi_traffic_gen_0 LOOPBACK (
        .s_axi_aclk(clk),
        .s_axi_aresetn(resetn),
        .s_axis_2_tready(tx_tready),
        .s_axis_2_tdata(tx_tdata),
        .s_axis_2_tkeep(tx_tkeep),
        .s_axis_2_tvalid(tx_tvalid),
        .s_axis_2_tlast(tx_tlast),
        .s_axis_2_tuser(tx_tuser),
        .m_axis_2_tready(rx_tready),
        .m_axis_2_tdata(rx_tdata),
        .m_axis_2_tkeep(rx_tkeep),
        .m_axis_2_tvalid(rx_tvalid),
        .m_axis_2_tlast(rx_tlast),
        .m_axis_2_tuser(rx_tuser));
        
endmodule

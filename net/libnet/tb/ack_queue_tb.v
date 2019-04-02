`timescale 1ns / 1ps

module ack_queue_tb(
    );
    
    parameter OUT_FILEPATH="/home/aaron/FPGAmain/FPGA/system/vcu108/generated_vivado_project/generated_vivado_project.srcs/sim_1/new/ACK_QUEUE_outputs.txt";
    parameter CLK_PERIOD = 20.48;
    parameter RUNTIME = 10;
    
    integer outfd;
    integer i;
    reg clk, resetn;
    
    /* Testbench RX AXIS signals */
    wire [511:0] rx_tdata;
    wire [63:0] rx_tkeep;
    wire [63:0] rx_tuser;
    wire rx_tvalid, rx_tlast;
    reg rx_tready;
    
    /* Ack Queue input signals */
    reg [31:0]      seq0_in;
    reg             seq0_valid;
    reg [31:0]      seq1_in;
    reg             seq1_valid;
    
    /* Provide input stimulus to DUT */
    initial begin
        resetn = 0;
        # CLK_PERIOD;
        resetn = 1;
        seq0_in = 32'h1;
        seq0_valid = 1'b1;
        # (CLK_PERIOD * 10);
        seq1_in = 32'h1;
        seq1_valid = 1'b1;
        # (CLK_PERIOD * 10);
        seq1_in = 32'h5;
        seq0_in = 32'h1;
        # (CLK_PERIOD * 10);
        seq1_in = 32'hF;
        seq0_in = 32'h3;
    end
    
    /* Receive Data from DUT and write to output file */
    initial begin
        outfd = $fopen(OUT_FILEPATH,"w");
        rx_tready = 0;
        # (CLK_PERIOD * 10);
        rx_tready = 1;
        if (outfd == 0) begin
            $display("ERROR, can't write output file\n");
            $finish;
            end
        for (i=0; i <RUNTIME; i= i+1) begin
            if ( rx_tvalid) begin
                /* Get Acks from APP0 and APP1 and write to file */
                $fdisplay(outfd,"%h %h", rx_tdata, rx_tkeep);
                # CLK_PERIOD;
                $fdisplay(outfd,"%h %h\n", rx_tdata, rx_tkeep);
            end else begin
                # CLK_PERIOD;
            end
                
            /* Simulate Sysnet Receiving from apps (not the queue) */
            if(rx_tlast && rx_tvalid) begin
                rx_tready = 0;
                # (CLK_PERIOD * 10);
                rx_tready = 1;
            end
        end
       /* Close file and end simulation */
       $fclose(outfd);
       $display("SUCCESS - Simulation complete");
       $finish;
    end
        
    
    /* Clock Generation (48.828125 MHz / 20.48 ns) */
    initial begin
        clk = 0;
        forever # (CLK_PERIOD/2) clk = ~clk;
        end
        
    /* Instantiate DUT */
    ack_queue DUT (
        .tx_tdata(rx_tdata),
        .tx_tkeep(rx_tkeep),
        .tx_tvalid(rx_tvalid),
        .tx_tuser(rx_tuser),
        .tx_tlast(rx_tlast),
        .tx_tready(rx_tready),
        .clk(clk),
        .resetn(resetn),
        .seq0_in(seq0_in),
        .seq0_valid(seq0_valid),
        .seq1_in(seq1_in),
        .seq1_valid(seq1_valid)
    );
    
endmodule

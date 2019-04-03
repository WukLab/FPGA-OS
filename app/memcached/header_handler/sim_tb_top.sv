`timescale 1ns/1ps

module sim_tb_top ();

reg clk, reset_n, rdy, rdy1;
wire [63:0] tdata, tdata1;
wire [7:0] tkeep, tkeep1;
wire tlast, tlast1;
wire tvalid, tvalid1;
wire tready, tready1;
reg [63:0] usr, usr1;
reg netready, appready;

localparam real CLK_PERIOD = 8.0;
localparam RESET_DELAY = 200;

initial begin
    clk = 0;
    reset_n = 0;
    rdy  = 0;
    rdy1 = 0;
    appready = 1;
    netready = 1;

    #RESET_DELAY

    @(posedge clk);

    reset_n = 1;
    repeat(20) @(posedge clk);
    rdy  = 1;
    repeat(300) @(posedge clk);
    rdy1 = 1;
end

initial begin
    wait(reset_n);
    forever begin
        netready = 1;
        #(50*CLK_PERIOD);
        @(posedge clk);
        netready = 0;
        #(10*CLK_PERIOD);
        @(posedge clk);
    end
end

initial begin    
    wait(reset_n);
    forever begin 
        #(40*CLK_PERIOD);
        @(posedge clk);
        appready = 0;
        #(9*CLK_PERIOD);
        @(posedge clk);
        appready = 1;
    end
end

always 
    #(CLK_PERIOD/2) clk = ~clk;


header_handler DUT (
    .apclk(clk),
    .apresetn(reset_n),

    .fromNet_axis_tdata(tdata),
    .fromNet_axis_tkeep(tkeep),
    .fromNet_axis_tuser(usr),
    .fromNet_axis_tlast(tlast),
    .fromNet_axis_tvalid(tvalid),
    .fromNet_axis_tready(tready),
    
    .fromApp_axis_tdata (tdata1),
    .fromApp_axis_tkeep (tkeep1),
    .fromApp_axis_tuser (usr1),
    .fromApp_axis_tlast (tlast1),
    .fromApp_axis_tvalid(tvalid1),
    .fromApp_axis_tready(tready1),

    .toApp_axis_tdata(),
    .toApp_axis_tkeep(),
    .toApp_axis_tuser(),
    .toApp_axis_tlast(),
    .toApp_axis_tvalid(),
    .toApp_axis_tready(appready),

    .toNet_axis_tdata(),
    .toNet_axis_tkeep(),
    .toNet_axis_tuser(),
    .toNet_axis_tlast(),
    .toNet_axis_tvalid(),
    .toNet_axis_tready(netready)
);

packet_gen #(.FD("./input1.txt")) fromnet_driver (    
    .clk   (clk),
    .rst_n (reset_n),
    .ready (rdy),

    .toNet_tdata (tdata),
    .toNet_tkeep (tkeep),
    .toNet_tvalid(tvalid),
    .toNet_tlast (tlast),
    .toNet_tready(tready)
);

packet_gen #(.FD("./input2.txt")) fromApp_driver (    
    .clk   (clk),
    .rst_n (reset_n),
    .ready (rdy1),

    .toNet_tdata (tdata1),
    .toNet_tkeep (tkeep1),
    .toNet_tvalid(tvalid1),
    .toNet_tlast (tlast1),
    .toNet_tready(tready1)
);

endmodule

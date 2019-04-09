`timescale 1ns/1ps

module sim_tb_top ();

reg clk, reset_n, rdy, rdy1;
wire [63:0] tdata, tdata1, app_data, net_data;
wire [7:0] tkeep, tkeep1, app_keep, net_keep;
wire tlast, tlast1, app_last, net_last;
wire tvalid, tvalid1, app_valid, net_valid;
wire tready, tready1;
reg [63:0] usr, usr1;
reg netready, appready, nstart, astart, net_ready, app_ready;
integer fOut1, fOut2;

localparam real CLK_PERIOD = 8.0;
localparam RESET_DELAY = 200;

initial begin
    fOut2 = $fopen("outNet.txt", "w+");
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

    wait (fromApp_driver.done === 1);
    repeat(30) @(posedge clk);

    $fclose(fOut2);
end

initial begin
    fOut1 = $fopen("outApp.txt", "w+");

    wait (fromnet_driver.done === 1);
    repeat(30) @(posedge clk);

    $fclose(fOut1);
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

always @(posedge clk) begin
    app_ready <= appready;
    net_ready <= netready;
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

    .toApp_axis_tdata(app_data),
    .toApp_axis_tkeep(app_keep),
    .toApp_axis_tuser(app_user),
    .toApp_axis_tlast(app_last),
    .toApp_axis_tvalid(app_valid),
    .toApp_axis_tready(app_ready),

    .toNet_axis_tdata(net_data),
    .toNet_axis_tkeep(net_keep),
    .toNet_axis_tuser(net_user),
    .toNet_axis_tlast(net_last),
    .toNet_axis_tvalid(net_valid),
    .toNet_axis_tready(net_ready)
);

packet_gen #(.FD("./input1.txt")) fromnet_driver (    
    .clk   (clk),
    .rst_n (reset_n),
    .ready (rdy),

    .out_tdata (tdata),
    .out_tkeep (tkeep),
    .out_tvalid(tvalid),
    .out_tlast (tlast),
    .out_tready(tready)
);

packet_gen #(.FD("./input2.txt")) fromApp_driver (    
    .clk   (clk),
    .rst_n (reset_n),
    .ready (rdy1),

    .out_tdata (tdata1),
    .out_tkeep (tkeep1),
    .out_tvalid(tvalid1),
    .out_tlast (tlast1),
    .out_tready(tready1)
);

/* monitor */
always @(posedge clk) begin
    if (~reset_n ) begin
        astart <= 0;
        nstart <= 0;
    end else begin
        if (app_valid & app_ready) begin
            if (~astart) begin
                $fdisplay(fOut1, "4");
                astart <= 1;
            end
            $fdisplay(fOut1, "%h %h", app_data, app_keep);
            if (app_last) begin
                astart <= 0;
            end
        end
        if (net_valid & net_ready) begin
            if (~nstart) begin
                $fdisplay(fOut2, "7");
                nstart <= 1;
            end
            $fdisplay(fOut2, "%h %h", net_data, net_keep);
            if (net_last) begin
                nstart <= 0;
            end
        end
    end
end

endmodule

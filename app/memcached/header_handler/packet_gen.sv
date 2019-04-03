module packet_gen (
    input  clk,
    input  rst_n,
    input  ready,

    output [63:0] toNet_tdata,
    output  [7:0] toNet_tkeep,
    output        toNet_tvalid,
    output        toNet_tlast,
    input         toNet_tready
);

reg tvalid, tlast;
reg [63:0] tdata;
reg [7:0] tkeep;
reg [31:0] num_pkts;
integer random_delay = 'h10;
reg status, flag = 0, done, start;
integer fd;

assign toNet_tdata    = tdata;
assign toNet_tkeep    = tkeep;
assign toNet_tvalid   = tvalid;
assign toNet_tlast    = tlast;

parameter FD="./input.txt";

initial begin
    /* If the file does not exist, then fd will be zero */
    fd = $fopen(FD, "r");
    /*
    if (fd)
        $display("File was opened successfully : %0d", fd);
    else
        $display("File was NOT opened successfully : %0d", fd);

    */
    /* wait for reset deassertion */
    wait (rst_n === 1);

    /* wait for reset deassertion */
    wait (done === 1);
    
    // 3. Close the file descriptor
    $fclose(fd);
end

always @(posedge clk) begin
    if (~rst_n | ~ready) begin
         tvalid <= 'b0;
         tdata  <= 'b0;
         tkeep  <= 'b0;
         tlast  <= 'b0;
         done   <= 0;
         start  <= 0;
    end
    // start driving packets
    else if (fd != 0 & ready & ~done) begin
        if (! $feof(fd)) begin
            if (~start) begin
                start <= $fscanf(fd, "%d\n", num_pkts);
            end
            else if (random_delay > 0) begin
                random_delay <= random_delay - 1;
            end 
            else if (num_pkts >= 0) begin
                 if (~flag) begin
                     if (num_pkts > 0) begin
                         if ((tvalid & toNet_tready) | ~tvalid) begin 
                             $fscanf(fd, "%h %h\n", tdata, tkeep);
                             num_pkts <= num_pkts - 1;
                             if (num_pkts == 1) begin
                                 tlast <= 1;
                             end
                         end
                     end
                     tvalid <= 1;
                 end
                 if (~toNet_tready) begin
                     flag <= 1;
                 end else if (flag) begin
                     flag <= 0;
                     tvalid <= 0;
                 end
                 if (num_pkts == 0) begin
                     tvalid <= 'b0;
                     tdata  <= 'b0;
                     tkeep  <= 'b0;
                     tlast  <= 'b0;
                     start  <= 0;
                     random_delay <= $urandom_range(0, 20);
                 end
            end /* all packets for current operation sent */
        end /*file read*/
        else begin
            done   <= 1;
            tvalid <= 'b0;
            tdata  <= 'b0;
            tkeep  <= 'b0;
            tlast  <= 'b0;
            start  <= 0;
        end
    end
end

endmodule

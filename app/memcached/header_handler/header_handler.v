module header_handler (
    input apclk,
    input apresetn,

    input  [63:0] fromNet_axis_tdata,
    input   [7:0] fromNet_axis_tkeep,
    input  [63:0] fromNet_axis_tuser,
    input         fromNet_axis_tlast,
    input         fromNet_axis_tvalid,
    output        fromNet_axis_tready,
    
    input  [63:0] fromApp_axis_tdata,
    input   [7:0] fromApp_axis_tkeep,
    input  [63:0] fromApp_axis_tuser,
    input         fromApp_axis_tlast,
    input         fromApp_axis_tvalid,
    output        fromApp_axis_tready,

    output [63:0] toApp_axis_tdata,
    output  [7:0] toApp_axis_tkeep,
    output [63:0] toApp_axis_tuser,
    output        toApp_axis_tlast,
    output        toApp_axis_tvalid,
    input         toApp_axis_tready,

    output [63:0] toNet_axis_tdata,
    output  [7:0] toNet_axis_tkeep,
    output [63:0] toNet_axis_tuser,
    output        toNet_axis_tlast,
    output        toNet_axis_tvalid,
    input         toNet_axis_tready
);

/* ETH0 | ETH1 | Lego | PAD | DATA
*   8B  |  6B  |  7B  |  3B |
*/
reg [63:0] eth_hdr0;
reg [47:0] eth_hdr1;
reg [55:0] lego_hdr;
reg header_striped;
reg [1:0] wait_cnt, count;

reg [63:0] tx_data;
reg  [7:0] tx_keep;
reg [63:0] tx_user;
reg        tx_last;
reg        tx_en, rd_en;

reg [1:0] rx_state;
reg       state;
           
wire [63:0] tmp_tdata;
wire  [7:0] tmp_tkeep;
wire [63:0] tmp_tuser;
wire        tmp_tlast;
wire [136:0] data_in, data_out;
wire         wr_en, full, empty;

assign fromApp_axis_tready = ~full;
assign data_in = { fromApp_axis_tlast,
                   fromApp_axis_tuser,
                   fromApp_axis_tkeep,
                   fromApp_axis_tdata };

assign tmp_tdata = rd_en ? data_out[63:0]   : tmp_tdata;
assign tmp_tkeep = rd_en ? data_out[71:64]  : tmp_tkeep;
assign tmp_tuser = rd_en ? data_out[135:72] : tmp_tuser;
assign tmp_tlast = rd_en ? data_out[136]    : tmp_tlast;

assign wr_en = fromApp_axis_tvalid & fromApp_axis_tready;

/* RX side state machine */
localparam IDLE = 2'b00, PARSE_HDR1 = 2'b10, PARSE_HDR2 = 2'b11, PARSE_STREAM = 2'b01;
/* TX side state machine */
localparam HDR = 1'b0, DATA = 1'b1;

assign fromNet_axis_tready = (rx_state != PARSE_STREAM) ? 1'b1 : toApp_axis_tready;
/* Data is just pass through from net to app */
assign toApp_axis_tdata   = (rx_state == PARSE_STREAM) ? fromNet_axis_tdata  : 'b0;
assign toApp_axis_tkeep   = (rx_state == PARSE_STREAM) ? fromNet_axis_tkeep  : 'b0;
assign toApp_axis_tuser   = (rx_state == PARSE_STREAM) ? fromNet_axis_tuser  : 'b0;
assign toApp_axis_tlast   = (rx_state == PARSE_STREAM) ? fromNet_axis_tlast  : 'b0;
assign toApp_axis_tvalid  = (rx_state == PARSE_STREAM) ? fromNet_axis_tvalid : 'b0;

assign toNet_axis_tdata   = tx_data  ;
assign toNet_axis_tkeep   = tx_keep  ;
assign toNet_axis_tuser   = tx_user  ;
assign toNet_axis_tlast   = tx_last  ;
assign toNet_axis_tvalid  = tx_en ;

/* RX side -- get from NET and forward to App */
always @(posedge apclk) begin
    if (~apresetn) begin
        rx_state       <= IDLE;
        wait_cnt       <= 0;
        header_striped <= 0;
    end else begin
        case(rx_state)
            IDLE : begin
                       if (fromNet_axis_tvalid) begin
                           if ( ~header_striped ) begin
                               rx_state <= PARSE_HDR1;
                               eth_hdr0 <= fromNet_axis_tdata;
                           end else if (wait_cnt == 2) begin
                               rx_state <= PARSE_STREAM;
                               wait_cnt <= 0;
                           end else begin
                               wait_cnt <= wait_cnt + 1;
                           end
                       end
                   end
            PARSE_HDR1 : begin
                             if (fromNet_axis_tvalid) begin
                                 rx_state           <= PARSE_HDR2;
                                 eth_hdr1        <= fromNet_axis_tdata[63:16];
                                 lego_hdr[55:40] <= fromNet_axis_tdata[15:0];
                             end
                         end
            PARSE_HDR2 : begin
                             if (fromNet_axis_tvalid) begin
                                 rx_state           <= PARSE_STREAM;
                                 lego_hdr[39:0]  <= fromNet_axis_tdata[63:24];
                                 header_striped  <= 1'b1;
                             end
                         end
            PARSE_STREAM : begin
                               if (fromNet_axis_tvalid & fromNet_axis_tready) begin
                                   if (fromNet_axis_tlast) begin
                                       rx_state <= IDLE;
                                   end
                               end
                           end
        endcase
    end
end

/* TX sm*/
always @( posedge apclk ) begin
    if (~apresetn) begin
        state <= HDR;
    end else begin
        case (state) 
            HDR : begin
                      if ( (fromApp_axis_tvalid | ~empty) & count == 0 ) begin
                          tx_en   <= 1;
                          tx_data <= eth_hdr0;
                          tx_last <= 'b0;
                          tx_keep <= 'hFF;
                          count   <= count + 1;
                      end else if (count == 1) begin
                          if (toNet_axis_tready) begin
                              tx_data <= {eth_hdr1, lego_hdr[55:40]};
                              tx_keep <= 'hFF;
                              count   <= count + 1;
                          end
                      end else if (count == 2) begin
                          if (toNet_axis_tready) begin
                              tx_data <= {lego_hdr[39:0], 'b0};
                              tx_keep <= 'hFF;
                              state   <= DATA;
                              count   <= 0;
                              rd_en   <= 1;
                          end
                      end else begin
                          tx_en   <= 'b0;
                          tx_data <= 'b0;
                          tx_keep <= 'b0;
                          tx_last <= 'b0;
                          count   <= 'b0;
                          rd_en   <= 'b0;
                      end
                  end
            DATA : begin
                       if ( toNet_axis_tready ) begin
                           rd_en   <= 1;
                           tx_data <= tmp_tdata;
                           tx_keep <= tmp_tkeep;
                           tx_user <= tmp_tuser;
                           tx_last <= tmp_tlast;
                       end else begin
                           rd_en   <= 0;
                       end
                       if (tmp_tlast & toNet_axis_tready) begin
                           rd_en   <= 0;
                           state   <= HDR;
                       end
                   end
        endcase
    end
end

/* TX side -- from app -> 5 deep fifo -> TX*/
sync_fifo #(.DW(137), .FIFO_DEPTH(4)) APP_STREAM_BUF (
    .clk      (apclk),
    .rst_     (apresetn),
    .rd_en    (rd_en),
    .wr_en    (wr_en),
    .fifo_in  (data_in),
    .fifo_out (data_out),
    .full     (full),
    .empty    (empty)
);

endmodule

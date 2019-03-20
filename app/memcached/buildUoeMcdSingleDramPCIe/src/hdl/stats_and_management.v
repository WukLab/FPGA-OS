/*******************************************************************************
 *
 *  NetFPGA-10G http://www.netfpga.org
 *
 *  File:
 *       stats_to_axi.v
 *
 *  Library:
 *
 *  Author:
 *        Michaela Blott
 *
 *  Description:
 *        AXI4-Lite for registers
 *
 *  Copyright notice:
 *        Copyright (C) 2010, 2011 Xilinx, Inc.
 *
 *  Licence:
 *        This file is part of the NetFPGA 10G development base package.
 *
 *        This file is free code: you can redistribute it and/or modify it under
 *        the terms of the GNU Lesser General Public License version 2.1 as
 *        published by the Free Software Foundation.
 *
 *        This package is distributed in the hope that it will be useful, but
 *        WITHOUT ANY WARRANTY; without even the implied warranty of
 *        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *        Lesser General Public License for more details.
 *
 *        You should have received a copy of the GNU Lesser General Public
 *        License along with the NetFPGA source package.  If not, see
 *        http://www.gnu.org/licenses/.
 *
 */
 
module stats_to_axi
#(
    // Master AXI Stream Data Width
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32,
    parameter STATS_WIDTH=32,
    parameter REVISION=32'h1
)
(
	//clock and reset
   input  ACLK,
   input  ARESETN,

   //address write
   input  [ADDR_WIDTH-1: 0] AWADDR,
   input  AWVALID,
   output reg AWREADY,

   //data write
   input  [DATA_WIDTH-1: 0]   WDATA,
   input  [DATA_WIDTH/8-1: 0] WSTRB,
   input  WVALID,
   output reg WREADY,

	//write response (handhake)
   output reg [1:0] BRESP,
   output reg BVALID,
   input  BREADY,

	//address read
   input  [ADDR_WIDTH-1: 0] ARADDR,
   input  ARVALID,
   output reg ARREADY,

	//data read
   output reg [DATA_WIDTH-1: 0] RDATA,
   output reg [1:0] RRESP,
   output reg RVALID,
   input  RREADY,

   //incoming data from the stats modules. must be in pcie clock domain
   input  [STATS_WIDTH-1:0] stats0_in,//stats 0
   input  [STATS_WIDTH-1:0] stats1_in,//stats1, connected to a different stats module instance
   input  [STATS_WIDTH-1:0] stats2_in,
   input  [STATS_WIDTH-1:0] stats3_in,
   
   
   //interface to memory allocation unit. for every value store we have 3 queues of free addresses
   //one queue for small, medium and large sized values each.
   //'small' 
    output  reg [31:0]  free1,
    output  reg free1_wr,
    input   free1_full,
        
    output  reg [31:0]  free2,
    output  reg free2_wr,
    input   free2_full,
                   
    output  reg [31:0]  free3,            
    output  reg free3_wr,
    input   free3_full,
    
    output  reg [31:0]  free4,            
    output  reg free4_wr,
    input   free4_full,
    
    
    //'medium'
    output  reg [31:0]  free1M,
    output  reg free1M_wr,
    input   free1M_full,
        
    output  reg [31:0]  free2M,
    output  reg free2M_wr,
    input   free2M_full,
                   
    output  reg [31:0]  free3M,            
    output  reg free3M_wr,
    input   free3M_full,
    
    output  reg [31:0]  free4M,            
    output  reg free4M_wr,
    input   free4M_full,
    
    
    //'large'
    output  reg [31:0]  free1L,
    output  reg free1L_wr,
    input   free1L_full,
        
    output  reg [31:0]  free2L,
    output  reg free2L_wr,
    input   free2L_full,
                   
    output  reg [31:0]  free3L,            
    output  reg free3L_wr,
    input   free3L_full,
    
    output  reg [31:0]  free4L,            
    output  reg free4L_wr,
    input   free4L_full,
    
    //fifo for icap  
    output  reg [31:0]  icap,
    output  reg icap_wr,
    input   icap_full,
    
    //address return fifo
    input   [31:0]  del1,
    output  reg del1_rd,
    input   del1_ety,
    
    //software initiated reset
    output reg SC_reset,
    
    //flush protocol
    input flushreq,
    output reg flushack,
    input flushdone
    
);
  
    localparam AXI_RESP_OK = 2'b00;
    localparam AXI_RESP_SLVERR = 2'b10;

    localparam WRITE_IDLE = 0;
    localparam WRITE_RESPONSE = 1;
    localparam WRITE_DATA = 2;

    localparam READ_IDLE = 0;
    localparam READ_RESPONSE = 1;
    localparam READ_WAIT = 2;
    
//for now all addresses are of the form C000XXXX because of the axi crossbar that does some unnecessary address translation
//    -- register interface of the CAPI2                                        corresponding address (hex):
//            stats1           : in std_logic_vector(31 downto 0);              0
//            stats2           : in std_logic_vector(31 downto 0);              4
//            stats3           : in std_logic_vector(31 downto 0);              8
//            stats4           : in std_logic_vector(31 downto 0);              c

//            del1             : in std_logic_vector(31 downto 0);              20
//            del1_rd          : out std_logic;
//            del1_ety         : in std_logic;

//            free1            : out std_logic_vector(31 downto 0);             30
//            free1_wr         : out std_logic;                                 
//            free1_full       : in std_logic;     in topmost bit when read
//            free2            : out std_logic_vector(31 downto 0);             34
//            free2_wr         : out std_logic;
//            free2_full       : in std_logic;     in topmost bit when read                 
//            free3            : out std_logic_vector(31 downto 0);             38              
//            free3_wr         : out std_logic;
//            free3_full       : in std_logic;     in topmost bit when read
//            free4            : out std_logic_vector(31 downto 0);             3c              
//            free4_wr         : out std_logic;
//            free4_full       : in std_logic;     in topmost bit when read
//            
//            same for free 1M...free4M at addresses 40-4c.  Share the same rw registers for debug as free1-free4
//            same for free1L...free4L              
//
//            icap            : out std_logic_vector(31 downto 0);             f4    
//            icap_wr         : out std_logic;
//            icap_full       : in std_logic;     in topmost bit when read    


    //the starting C is from the settings of pcie2axilite core
    
    localparam STATS0_ADDR = 32'h00000000;
    localparam STATS1_ADDR = 32'h00000004;
    localparam STATS2_ADDR = 32'h00000008;
    localparam STATS3_ADDR = 32'h0000000C;
    localparam RESET_ADDR  = 32'h00000010;
    localparam DEL1_ADDR   = 32'h00000020;
    
    localparam FREE1_ADDR  = 32'h00000030;
    localparam FREE2_ADDR  = 32'h00000034;
    localparam FREE3_ADDR  = 32'h00000038;
    localparam FREE4_ADDR  = 32'h0000003c;
    
    localparam FREE1M_ADDR  = 32'h00000040;
    localparam FREE2M_ADDR  = 32'h00000044;
    localparam FREE3M_ADDR  = 32'h00000048;
    localparam FREE4M_ADDR  = 32'h0000004c;
    
    localparam FREE1L_ADDR  = 32'h00000050;
    localparam FREE2L_ADDR  = 32'h00000054;
    localparam FREE3L_ADDR  = 32'h00000058;
    localparam FREE4L_ADDR  = 32'h0000005c;
    
    
    localparam FLUSHREQ    = 32'h000000e0;
    localparam FLUSHACK    = 32'h000000e4;
    localparam FLUSHDONE   = 32'h000000e8;
    localparam REVISION_ADDR = 32'h000000f0;
    localparam ICAP_ADDR   = 32'h000000f4;
    //localparam REVISION=32'h1;
  
    reg [1:0] write_state, write_state_next;
    reg [1:0] read_state, read_state_next;
    reg [ADDR_WIDTH-1:0] read_addr, read_addr_next;
    reg [ADDR_WIDTH-1:0] write_addr, write_addr_next;
    reg [2:0] counter, counter_next;
    reg [1:0] BRESP_next;
    
    reg [31:0] free1_next,free2_next,free3_next,free4_next,icap_next;
    reg [31:0] free1M_next,free2M_next,free3M_next,free4M_next;
    reg [31:0] free1L_next,free2L_next,free3L_next,free4L_next;
    
    reg free1_wr_next,free2_wr_next,free3_wr_next,free4_wr_next,icap_wr_next;
    reg free1M_wr_next,free2M_wr_next,free3M_wr_next,free4M_wr_next;
    reg free1L_wr_next,free2L_wr_next,free3L_wr_next,free4L_wr_next;
    
    
    reg flushack_next;
    
    reg SC_reset_next;
       
    //4 read-write registers, attached to the lower 31 bits of the "free" regs. Mostly for driver testing
    reg[31:0] rw_0,rw_1,rw_2,rw_3;
    reg[31:0] rw_0_next,rw_1_next,rw_2_next,rw_3_next;
    
    
    reg del1_rd_next;//control of the read enable signal for del1
    
    
    localparam WAIT_COUNT = 2;

    always @(*) begin
        read_state_next = read_state;
        ARREADY = 1'b1;
        read_addr_next = read_addr;
        counter_next = counter;
        RDATA = 0;
        RRESP = AXI_RESP_OK;
        RVALID = 1'b0;
        
       del1_rd_next=1'b0;
        
        case(read_state)
            READ_IDLE: begin
                counter_next = 0;
                if(ARVALID) begin
                    read_addr_next = ARADDR;
                    read_state_next = READ_WAIT;
                end
            end

            READ_WAIT: begin
                counter_next = counter + 1;
                ARREADY = 1'b0;
                if(counter == WAIT_COUNT)
                    read_state_next = READ_RESPONSE;
            end

            READ_RESPONSE: begin
                RVALID = 1'b1;
                ARREADY = 1'b0;
				
				//master tries to read one of the regs
				// address decode. valid address of this transaction in read_addr
				case(read_addr)
                    STATS0_ADDR:    RDATA=stats0_in[DATA_WIDTH-1:0];
                    STATS1_ADDR:    RDATA=stats1_in[DATA_WIDTH-1:0];
                    STATS2_ADDR:    RDATA=stats2_in[DATA_WIDTH-1:0];
                    STATS3_ADDR:    RDATA=stats3_in[DATA_WIDTH-1:0];
                    DEL1_ADDR:begin
                                    del1_rd_next=!del1_ety;//if del1 not empty, consume an element
                                    RDATA[31]=del1_ety;
                                    RDATA[30:0]=del1[30:0];
                    end
                    FREE1_ADDR:    RDATA={free1_full,rw_0[30:0]};
                    FREE1M_ADDR:    RDATA={free1M_full,rw_0[30:0]};
                    FREE1L_ADDR:    RDATA={free1L_full,rw_0[30:0]};
                    FREE2_ADDR:    RDATA={free2_full,rw_1[30:0]};
                    FREE2M_ADDR:    RDATA={free2M_full,rw_1[30:0]};
                    FREE2L_ADDR:    RDATA={free2L_full,rw_1[30:0]};
                    FREE3_ADDR:    RDATA={free3_full,rw_2[30:0]};
                    FREE3M_ADDR:    RDATA={free3M_full,rw_2[30:0]};
                    FREE3L_ADDR:    RDATA={free3L_full,rw_2[30:0]};
                    FREE4_ADDR:    RDATA={free4_full,rw_3[30:0]};
                    FREE4M_ADDR:    RDATA={free4M_full,rw_3[30:0]};
                    FREE4L_ADDR:    RDATA={free4L_full,rw_3[30:0]};
                    FLUSHREQ:       RDATA={31'h0,flushreq};
                    FLUSHDONE:      RDATA={31'h0,flushdone};
                    REVISION_ADDR:  RDATA=REVISION;
                    ICAP_ADDR  :    RDATA={icap_full,31'h0};
                    default: RDATA=32'hffffffff;
				endcase
              
				//no error response. If ever needed, do:
				//RRESP=AXI_RESP_SLVERR;
				
                if(RREADY) begin//                           danger: may be multiple cycles in this state!
                    read_state_next = READ_IDLE;
                end
            end
        endcase
        
    end

    always @(*) begin
        write_state_next = write_state;
        write_addr_next = write_addr;
       // count_reset_control_next = count_reset_control;
        AWREADY = 1'b1;
        WREADY = 1'b0;
        BVALID = 1'b0;
        BRESP_next = BRESP;
        rw_0_next=rw_0;
        rw_1_next=rw_1;
        rw_2_next=rw_2;
        rw_3_next=rw_3;
        
        //defaults: no fresh data
       free1_wr_next=1'b0;
       free2_wr_next=1'b0;
       free3_wr_next=1'b0;
       free4_wr_next=1'b0;
       icap_wr_next=1'b0;
       free1_next=free1;
       free2_next=free2;
       free3_next=free3;
       free4_next=free4;
        free1M_next=free1;
        free2M_next=free2;
        free3M_next=free3;
        free4M_next=free4;
        free1L_next=free1;
        free2L_next=free2;
        free3L_next=free3;
        free4L_next=free4;
       icap_next=icap;
       
//       if(flushdone) begin
//            flushack_next=1'b0;
//       end else begin
//           flushack_next=flushack; 
//       end
       flushack_next=1'b0; //only needs to go high at least 1 cycle
       
       SC_reset_next=1'b0;//high 1 cycle. bridge top makes sure software defined reset is held a few cycles
       
        case(write_state)
            WRITE_IDLE: begin
                write_addr_next = AWADDR;
                if(AWVALID) begin
                    write_state_next = WRITE_DATA;
                end
            end
            WRITE_DATA: begin
                AWREADY = 1'b0;
                WREADY = 1'b1;
                if(WVALID) begin
                    //I am being written to.
                    //address in write_addr, data in WDATA
                   
                   
                    // address decode
                    case(write_addr)
                    STATS0_ADDR:;
                    STATS1_ADDR:;
                    STATS2_ADDR:;
                    STATS3_ADDR:;
                    RESET_ADDR: SC_reset_next=1'b1;
                    DEL1_ADDR:;
                    FREE1_ADDR: begin
                        rw_0_next=WDATA;//this register can be read out later
                        free1_next=WDATA;//push the data out
                        free1_wr_next=1'b1;//notify recipient FIFO of the new data
                    end
                    FREE2_ADDR: begin
                        rw_1_next=WDATA;
                        free2_next=WDATA;
                        free2_wr_next=1'b1;
                    end
                    FREE3_ADDR: begin
                        rw_2_next=WDATA;
                        free3_next=WDATA;
                        free3_wr_next=1'b1;
                    end
                    FREE4_ADDR: begin
                        rw_3_next=WDATA;
                        free4_next=WDATA;
                        free4_wr_next=1'b1;
                    end
                    FREE1M_ADDR: begin
                        rw_0_next=WDATA;//this register can be read out later
                        free1M_next=WDATA;//push the data out
                        free1M_wr_next=1'b1;//notify recipient FIFO of the new data
                    end
                    FREE2M_ADDR: begin
                        rw_1_next=WDATA;
                        free2M_next=WDATA;
                        free2M_wr_next=1'b1;
                    end
                    FREE3M_ADDR: begin
                        rw_2_next=WDATA;
                        free3M_next=WDATA;
                        free3M_wr_next=1'b1;
                    end
                    FREE4M_ADDR: begin
                        rw_3_next=WDATA;
                        free4M_next=WDATA;
                        free4M_wr_next=1'b1;
                    end
                    FREE1L_ADDR: begin
                        rw_0_next=WDATA;//this register can be read out later
                        free1L_next=WDATA;//push the data out
                        free1L_wr_next=1'b1;//notify recipient FIFO of the new data
                    end
                    FREE2L_ADDR: begin
                        rw_1_next=WDATA;
                        free2L_next=WDATA;
                        free2L_wr_next=1'b1;
                    end
                    FREE3L_ADDR: begin
                        rw_2_next=WDATA;
                        free3L_next=WDATA;
                        free3L_wr_next=1'b1;
                    end
                    FREE4L_ADDR: begin
                        rw_3_next=WDATA;
                        free4L_next=WDATA;
                        free4L_wr_next=1'b1;
                    end
                    ICAP_ADDR: begin
                        icap_next=WDATA;
                        icap_wr_next=1'b1;
                    end
                    FLUSHACK: flushack_next=1'b1;
                    default:;
                    endcase
                    
                   
                    //no error ever if needed, set
                    //BRESP_next=AXI_RESP_SLVERR;
                    write_state_next = WRITE_RESPONSE;
                end
            end
            WRITE_RESPONSE: begin
                AWREADY = 1'b0;
                BVALID = 1'b1;
                if(BREADY) begin
                    write_state_next = WRITE_IDLE;
                end
            end
        endcase
    end

    always @(posedge ACLK) begin
        if(~ARESETN) begin
            write_state <= WRITE_IDLE;
            read_state <= READ_IDLE;
            read_addr <= 0;
            write_addr <= 0;
            BRESP <= AXI_RESP_OK;
            
            rw_0<=32'h0;
            rw_1<=32'h0;
            rw_2<=32'h0;
            rw_3<=32'h0;
            
            free1<=32'h0;
            free2<=32'h0;
            free3<=32'h0;
            icap<=32'h0;
            
            free1_wr<=1'b0;
            free2_wr<=1'b0;
            free3_wr<=1'b0;
            icap_wr<=1'b0;
           
            del1_rd=1'b0;
            SC_reset=1'b0;
            flushack=1'b0;
        end
        else begin
            write_state <= write_state_next;
            read_state <= read_state_next;
            read_addr <= read_addr_next;
            write_addr <= write_addr_next;
            BRESP <= BRESP_next;
            
            
            rw_0<=rw_0_next;
            rw_1<=rw_1_next;
            rw_2<=rw_2_next;
            rw_3<=rw_3_next;
            
            free1<=free1_next;
            free2<=free2_next;
            free3<=free3_next;
            free4<=free4_next;
            
            icap<=icap_next;
            
            free1_wr<=free1_wr_next;
            free2_wr<=free2_wr_next;
            free3_wr<=free3_wr_next;
            free4_wr<=free4_wr_next;
            icap_wr<=icap_wr_next;
            
            del1_rd=del1_rd_next;
            
            flushack=flushack_next;
            SC_reset=SC_reset_next;
        end
        
        counter <= counter_next;
    end

endmodule

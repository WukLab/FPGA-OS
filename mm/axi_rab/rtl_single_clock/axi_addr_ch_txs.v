/* ------------------------------------------------------------------------------
 * Description: This is the address channel transitter that sends the 
 *              translated address to the slave which can be memory system or
 *              some intermediate module.
 * -----------------------------------------------------------------------------
 */

`timescale 1ns / 1ps

module axi_addr_ch_txs #(
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter USER_WIDTH = 2
)
(
    input                  tx_clk,
    input                  reset_,
    input   [ID_WIDTH-1:0] in_id,
    input            [7:0] in_len,
    input            [2:0] in_size,
    input            [1:0] in_burst,
    input            [2:0] in_prot,
    input            [3:0] in_cache,
    input [USER_WIDTH-1:0] in_user,
    input                  in_lock,
    
    output reg   [ID_WIDTH-1:0] out_id,
    output reg [ADDR_WIDTH-1:0] out_addr,
    output reg            [7:0] out_len,
    output reg            [2:0] out_size,
    output reg            [1:0] out_burst,
    output reg            [2:0] out_prot,
    output reg            [3:0] out_cache,
    output reg [USER_WIDTH-1:0] out_user,
    output reg                  out_lock,
    output reg                  out_valid,
    input                       in_ready,
    
/* interface with the translation logic */
    input [ADDR_WIDTH-1:0] phy_addr,
    input                  t_done
);

always @(posedge tx_clk) begin
    if(~reset_) begin
        {out_id, out_addr, out_len, out_size, out_burst, out_prot, out_user, out_cache, out_lock} <= 'h0;
        out_valid <= 1'b0;
    end else begin
        if (t_done & ~out_valid) begin
            out_id    <= in_id; 
            out_addr  <= phy_addr;
            out_len   <= in_len;
            out_size  <= in_size;
            out_burst <= in_burst;
            out_prot  <= in_prot;
            out_cache <= in_cache;
            out_user  <= in_user;
            out_lock  <= in_lock;
            out_valid <= 1'b1;
        end else if (in_ready & out_valid) begin
            out_valid <= 1'b0;
        end
    end
end

endmodule

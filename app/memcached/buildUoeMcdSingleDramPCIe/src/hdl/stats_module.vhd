----------------------------------------------------------------------------------
-- Company: XILINX
-- Engineer: Stephan Koster
-- 
-- Create Date: 07.03.2014 15:16:37
-- Design Name: stats module
-- Module Name: stats_module - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Sniffs an axi streaming bus, gathers stats and exposes them in a register
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use IEEE.STD_LOGIC_MISC.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity stats_module is
    Generic(
        data_size: INTEGER:=64;
        period_counter_size: INTEGER :=22
    );
    Port ( 
   ACLK               : in  std_logic;
   RESET              : in  std_logic;
   
   M_AXIS_TDATA       : out std_logic_vector (data_size-1 downto 0);
   M_AXIS_TSTRB       : out std_logic_vector (7 downto 0);
   M_AXIS_TVALID      : out std_logic;
   M_AXIS_TREADY      : in  std_logic;
   M_AXIS_TLAST       : out std_logic;
   
   S_AXIS_TDATA       : in  std_logic_vector (data_size-1 downto 0);
   S_AXIS_TSTRB       : in  std_logic_vector (7 downto 0);
   S_AXIS_TUSER       : in  std_logic_vector (127 downto 0);
   S_AXIS_TVALID      : in  std_logic;
   S_AXIS_TREADY      : out std_logic;
   S_AXIS_TLAST       : in  std_logic;

   --Expose the gathered stats
   STATS_DATA         : out std_logic_vector(31 downto 0)
);
end stats_module;

architecture Behavioral of stats_module is
    
    signal rst,clk: std_logic;--rename hard to type signals
    signal busycount: std_logic_vector(31 downto 0);--counts how many cycles both ready and valid are on
    signal idlecount: std_logic_vector(31 downto 0);--so far does nothing
    
    signal period_tracker: std_logic_vector(period_counter_size-1 downto 0);--measuring period ends on rollaround
    signal count_reset:std_logic;
    
begin
    
    rst<=RESET;
    clk<=ACLK;
    
    --axi stream signals pass straight through from master to slave. We just read Ready and Valid signals
    
      M_AXIS_TDATA       <=     S_AXIS_TDATA;
      M_AXIS_TSTRB       <=     S_AXIS_TSTRB;
      M_AXIS_TVALID      <=     S_AXIS_TVALID;
      S_AXIS_TREADY      <=     M_AXIS_TREADY;
      M_AXIS_TLAST       <=     S_AXIS_TLAST;
      
    
    generate_period:process(rst,clk)
    begin
        if(rst='1') then
            period_tracker<=(others=>'0');
        elsif(rising_edge(clk)) then
            period_tracker<=std_logic_vector(unsigned(period_tracker)+1);
            count_reset<=AND_REDUCE( period_tracker);--bitwise and
        end if;
    
    end process;
    
    process(rst,clk)
    begin
        if(rst='1') then
            --reset state
            busycount<=(others=>'0');
            STATS_DATA<=(others=>'0');
        elsif(rising_edge(clk)) then
            --write the output signal with the stats when the period counter rolls around
            if(count_reset='1') then
                --STATS_DATA(31)<='1';
                STATS_DATA(period_counter_size downto 0)<=busycount(period_counter_size downto 0);
                busycount<=(others=>'0');
            else
                --sniff the axi stream signals, gather stats                        
               if(M_AXIS_TREADY='1' and S_AXIS_TVALID='1') then
                   busycount<=std_logic_vector(unsigned(busycount)+1);
               end if;
            end if;
            
        end if;
    end process;
    
end Behavioral;

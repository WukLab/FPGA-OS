-------------------------------------------------------------------------------
--
-- Title       : local_link_sink.vhd - part of the Groucher simulation environment
--
-- Description : This code models the behavior of a local link sink device
--
--               Files:      writes the received data and control into a data file 
--                           every clock cycle 
--                           The characters in the text file are interpreted as hex
--                           Organization is MSB to LSB 
--                           padded with 0s on the MSBs to multiples of 4
-- data bus ' ' ctl signals(valid, done) 
--                           takes the flow ctl signal either through the parameters
--                           or from a file. this is determined through the 
--                           generic BPR_PARA
--               Interface:  the processing starts after rst de-asserts 
--                           the data and control signals are plainly recorded 
--                           the backpressure is driven either from file input
--                           or throught the parameters
--               Parameters: data width
--                           length width 
--                           rem width 
--                           l_present: indicates whether the length inetrface exists or not
--                           bpr_para: when true then DST_RDY_N is driven through
--                                     the following paramters:
--                           bpr_delay: waits for bpr_Delay*clock ticks before 
--                                     commencing assertion   
--                           bpr_period: indicates how often backpressure is asserted
--                                     in clock ticks
--                           bpr_duration: inidcates for how long backpressure is 
--                                     asserted within one period.  
--                                     DURATION < PERIOD!
--                           BPR_FILENAME : file name of input backpressure file
--                           PKT_FILENAME : filename of output data file
--
--
-- ----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_TEXTIO.all;

LIBRARY STD;
USE STD.TEXTIO.ALL;

entity kvs_tbStatsMonitorHDLNode is
generic (
   D_WIDTH : integer := 64;
   PKT_FILENAME : string := "pkt.out.txt"
);
port (
    clk : in  std_logic;
    rst : in  std_logic;
    udp_in_ready        : out std_logic; 
    udp_in_valid        : in std_logic; 
    udp_in_data         : in std_logic_vector (D_WIDTH-1 downto 0)
);
end kvs_tbStatsMonitorHDLNode;


architecture structural of kvs_tbStatsMonitorHDLNode is

constant FD_WIDTH  : integer := ((D_WIDTH-1) / 4)*4 + 4;
begin

udp_in_ready <= '1';

-- write process for the received packet
write_pktfile_p : process
	FILE pkt_file : TEXT OPEN WRITE_MODE IS PKT_FILENAME;
	variable l  : line;
	variable d : character := 'D';
	variable blank : character := ' ';
	variable dat_vector : std_logic_vector(FD_WIDTH-1 downto 0);
	variable ctl_vector : std_logic_vector(3 downto 0);
	variable eop : std_logic;
	variable modulus : std_logic_vector(2 downto 0);
begin
	if (D_WIDTH=0) then
		assert false report "D_WIDTH and R_WIDTH must be greater than 0" severity failure;
	end if;

	wait until rst='0'; 
	while TRUE loop
	-- write each cycle
		wait until CLK'event and CLK='1';
		-- padding
		dat_vector(D_WIDTH-1 downto 0) := udp_in_data(D_WIDTH-1 downto 0);
		dat_vector(FD_WIDTH-1 downto D_WIDTH) := (others => '0');
		ctl_vector(3 downto 0) := '0' & '0' & udp_in_valid & '0'; -- udp_in_done is deprecated
		-- compose output line and mas modulus.
		write(l,d);
		hwrite(l, dat_vector(FD_WIDTH-1 downto 64));
		hwrite(l, dat_vector(63 downto 0));
		write(l,blank);
		hwrite(l, ctl_vector);
		-- writing
		writeline(pkt_file, l);
	end loop;
end process;

end structural;

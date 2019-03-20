-------------------------------------------------------------------------------
--
-- Title       : local_link_source.vhd - part of the Groucher simulation environment
--
-- Description : This code models the behavior of a local link source device
--               to drive a Grouch module with optional status and length interfaces
--
--               Files:      reads from a file data and control inputs
--                           if a line starts with capital W then the following number if interpreted
--                           as an integer, and the program waits for this integer * cycles
--                           if a line starts with a captial D then the rest is interpreted as follows:
-- data bus '' ctl signals( * - DONE - EMPTY -ALMOST)
--                           the bit size of the values must be at least the size of the bus rounded to the next 4
--                           and is always interpreted as hex.
--                           Organization is MSB to LSB
--                           length and status are optional
--                           if their widths (generics S_WIDTH and L_WIDTH) are set to 0, then
--                           we won't parse for them in the file
--               Interface:  the processing starts after rst de-asserts
--                           drives a standard tx interface (local link + len + sts)
--               Parameters: data width
--                           bpr_sensitive
--                           pkt_filename
--
-- ----------------------------------------------------------------------------
-- DONE is ignored....
-- DONE is ignored....
-- ----------------------------------------------------------------------------
-- Changelog:
-- 2 Control Flow Bugs fixed.


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.STD_LOGIC_TEXTIO.all;

LIBRARY STD;
USE STD.TEXTIO.ALL;

entity kvs_tbDriverHDLNode is
generic (
   D_WIDTH : integer := 64;
   BPR_SENSITIVE : Boolean := true; -- decides whether we react to backpressure or not
   --PKT_FILENAME : string := "/home/kimonk/vc709sim/pkt.in.2.txt"
   PKT_FILENAME : string := "pkt.in.txt"
);
port (
    clk                     : in  std_logic;
    rst                     : in  std_logic;
    udp_out_ready           : in    std_logic;
    udp_out_valid           : out   std_logic;
    udp_out_keep           	: out   std_logic_vector(7 downto 0);
    udp_out_user          	: out   std_logic_vector(111 downto 0);
    udp_out_last           	: out   std_logic;
    udp_out_data            : out   std_logic_vector (63 downto 0)
);
end kvs_tbDriverHDLNode;


architecture rtl of kvs_tbDriverHDLNode is
   -- read width from file- roudns each value up to the next multiple of 4
   constant FD_WIDTH    : integer := ((D_WIDTH-1) / 4)*4 + 4;

   --signal item_consumed : std_logic;
begin

read_file_p : process
   FILE data_file 			: TEXT OPEN READ_MODE IS PKT_FILENAME;
   variable c 				: character;
   variable wait_period 	: integer;
   variable l 				: line;
   variable read_dat 		: std_logic_vector(63 downto 0);
   variable read_keep 		: std_logic_vector(7 downto 0);
   variable read_ctl 		: std_logic_vector(3 downto 0);
   variable item_consumed 	: std_logic;
   variable cntCorrection 	: integer;
   variable firstRun		: integer; 
   --variable read_ctl_buf : std_logic_Vector(3 downto 0) := (others => '1');

begin
	if (D_WIDTH=0) then
		assert false report "D_WIDTH and R_WIDTH must be greater than 0" severity failure;
	end if;

   -- assign defaults for rest
	udp_out_valid 	<= '0';
	udp_out_last 	<= '0';
	udp_out_data 	<=(others => '0');
	udp_out_keep 	<=(others => '0');
	udp_out_user	<=(others => '0');
	item_consumed 	:= '0';
	firstRun		:= 0;

	wait_period := 1;

	wait until CLK'event and CLK='1';
	while (not endfile(data_file)) loop
		READLINE(data_file, l);
		READ(l, c);
		case c is
		when 'W' =>	-- wait
			READ(l,wait_period);
			cntCorrection := 1;
			for i in 0 to wait_period -1 loop
				udp_out_valid <= '0';
				wait until CLK'event and CLK='1';
			end loop;
		when others => 
			-- parse data line
			HREAD(l,read_dat);
			READ(l,c);--blank
			HREAD(l,read_keep);
			READ(l,c);--blank
			HREAD(l,read_ctl);
			udp_out_data <= read_dat;
			udp_out_keep <= read_keep;
			if (read_ctl = 1) then
				udp_out_last <= '1';
			else
				udp_out_last <= '0';
			end if;
			udp_out_valid <= '1';
			wait until udp_out_ready = '1' and CLK'event and CLK='1';
		end case;
		--wait until CLK'event and CLK='1';
	end loop;

	wait until CLK'event and CLK='1';
	-- following delay is to ensure the last bit of data
	-- is through the simulation
	wait for 1000 * 1000 ns;
	-- then terminate the simulation
	--if (endfile(data_file)) then
	--   assert false report "End of simulation." severity failure;
	--end if;
end process;

end rtl;
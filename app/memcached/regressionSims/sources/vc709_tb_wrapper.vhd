LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY vc709_tb_wrapper IS
END vc709_tb_wrapper;
 
ARCHITECTURE behavior OF vc709_tb_wrapper IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT prototypeWrapper
    PORT(
         clk         : IN  std_logic;
         rst         : IN  std_logic);
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: prototypeWrapper PORT MAP (
          clk => clk,
          rst => rst);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 20 ns;	
		rst <= '1';
		wait for clk_period*3;
		rst <= '0';
      wait;
   end process;

END;

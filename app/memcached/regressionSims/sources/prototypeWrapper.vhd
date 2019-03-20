library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity prototypeWrapper is
    Generic (DRAM_WIDTH 		: integer := 512;
			 FLASH_WIDTH		: integer := 64;
			 DRAM_CMD_WIDTH 	: integer := 40;
			 FLASH_CMD_WIDTH	: integer := 48);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC);
end prototypeWrapper;

architecture Structural of prototypeWrapper is
signal input_to_mcd_tvalid			: std_logic;
signal input_to_mcd_tready			: std_logic;
signal input_to_mcd_tdata			: std_logic_vector(63 downto 0);
signal input_to_mcd_tuser			: std_logic_vector(111 downto 0);
signal input_to_mcd_tkeep			: std_logic_vector(7 downto 0);
signal input_to_mcd_tlast			: std_logic;

signal mcd_to_output_tvalid			: std_logic;
signal mcd_to_output_tready			: std_logic;
signal mcd_to_output_tdata			: std_logic_vector(63 downto 0);
signal mcd_to_output_tuser			: std_logic_vector(111 downto 0);
signal mcd_to_output_tkeep			: std_logic_vector(7 downto 0);
signal mcd_to_output_tlast			: std_logic;


-- DRAM model connections
signal  ht_dramRdData_data          : std_logic_vector(DRAM_WIDTH-1 downto 0);
signal  ht_dramRdData_valid         : std_logic;
signal  ht_dramRdData_ready          : std_logic;
-- ht_cmd_dramRdData: Push Output, 16b
signal  ht_cmd_dramRdData_data      : std_logic_vector(DRAM_CMD_WIDTH-1 downto 0);
signal  ht_cmd_dramRdData_valid     : std_logic;
signal  ht_cmd_dramRdData_ready     : std_logic;
-- ht_dramWrData:     Push Output, 512b
signal  ht_dramWrData_data          : std_logic_vector(DRAM_WIDTH-1 downto 0);
signal  ht_dramWrData_valid         : std_logic;
signal  ht_dramWrData_ready         : std_logic;
-- ht_cmd_dramWrData: Push Output, 16b
signal  ht_cmd_dramWrData_data      : std_logic_vector(DRAM_CMD_WIDTH-1 downto 0);
signal  ht_cmd_dramWrData_valid     : std_logic;
signal  ht_cmd_dramWrData_ready     : std_logic;
-- Update DRAM Connection
-- upd_dramRdData:     Pull Input, 512b
signal  upd_dramRdData_data         : std_logic_vector(DRAM_WIDTH-1 downto 0);
signal  upd_dramRdData_valid        : std_logic;
signal  upd_dramRdData_ready         : std_logic;
-- upd_cmd_dramRdData: Push Output, 16b
signal  upd_cmd_dramRdData_data     : std_logic_vector(DRAM_CMD_WIDTH-1 downto 0);
signal  upd_cmd_dramRdData_valid    : std_logic;
signal  upd_cmd_dramRdData_ready    : std_logic;
-- upd_dramWrData:     Push Output, 512b
signal  upd_dramWrData_data         : std_logic_vector(DRAM_WIDTH-1 downto 0);
signal  upd_dramWrData_valid        : std_logic;
signal  upd_dramWrData_ready        : std_logic;
-- upd_cmd_dramWrData: Push Output, 16b
signal  upd_cmd_dramWrData_data     : std_logic_vector(DRAM_CMD_WIDTH-1 downto 0);
signal  upd_cmd_dramWrData_valid    : std_logic;
signal  upd_cmd_dramWrData_ready    : std_logic;
-- Update Flash Connection
-- upd_flashRdData:     Pull Input, 64b
signal  upd_flashRdData_data         : std_logic_vector(FLASH_WIDTH-1 downto 0);
signal  upd_flashRdData_valid        : std_logic;
signal  upd_flashRdData_ready         : std_logic;
-- upd_cmd_flashRdData: Push Output, 48b
signal  upd_cmd_flashRdData_data     : std_logic_vector(FLASH_CMD_WIDTH-1 downto 0);
signal  upd_cmd_flashRdData_valid    : std_logic;
signal  upd_cmd_flashRdData_ready    : std_logic;
-- upd_flashWrData:     Push Output, 64b
signal  upd_flashWrData_data         : std_logic_vector(FLASH_WIDTH-1 downto 0);
signal  upd_flashWrData_valid        : std_logic;
signal  upd_flashWrData_ready        : std_logic;
-- upd_cmd_flashWrData: Push Output, 48b
signal  upd_cmd_flashWrData_data     : std_logic_vector(FLASH_CMD_WIDTH-1 downto 0);
signal  upd_cmd_flashWrData_valid    : std_logic;
signal  upd_cmd_flashWrData_ready    : std_logic;
--signal udp_out_ready_inv         : std_logic;
signal aresetn                   	: std_logic;
--------------------------------------------------------------------------------------
signal statsIn2monitor_data			 : std_logic_vector(63 downto 0);
signal statsIn2monitor_ready		 : std_logic;
signal statsIn2monitor_valid 		 : std_logic;
signal statsOut2monitor_data		 : std_logic_vector(63 downto 0);
signal statsOut2monitor_ready		 : std_logic;
signal statsOut2monitor_valid 		 : std_logic;
--------------------------------------------------------------------------------------
signal statsCollector2monitor_data		: std_logic_vector(183 downto 0);
signal statsCollector2monitor_valid		: std_logic;
signal statsCollector2monitor_ready		: std_logic;

signal driver2statsCollector_data		: std_logic_vector(173 downto 0);
signal driver2statsCollector_data_im	: std_logic_vector(183 downto 0);
signal driver2statsCollector_valid		: std_logic;
signal driver2statsCollector_ready		: std_logic;
------------------Memory Allocation Signals-------------------------------------------
signal memcached2memAllocation_data			: std_logic_vector(31 downto 0);	-- Address reclamation
signal memcached2memAllocation_valid		: std_logic;
signal memcached2memAllocation_ready		: std_logic;
signal memAllocation2memcached_dram_data	: std_logic_vector(31 downto 0);	-- Address assignment for DRAM
signal memAllocation2memcached_dram_valid	: std_logic;
signal memAllocation2memcached_dram_ready	: std_logic;
signal memAllocation2memcached_flash_data	: std_logic_vector(31 downto 0);	-- Address assignment for SSD
signal memAllocation2memcached_flash_valid	: std_logic;
signal memAllocation2memcached_flash_ready	: std_logic;

signal flushReq								: std_logic;
signal flushAck								: std_logic;
signal flushDone							: std_logic;

begin



aresetn <=  NOT rst;

myReader: entity work.kvs_tbDriverHDLNode(rtl)
          port map(clk              => clk,
                   rst              => rst,
                   udp_out_ready    => input_to_mcd_tready,
                   udp_out_valid    => input_to_mcd_tvalid,
                   udp_out_keep    	=> input_to_mcd_tkeep,
                   udp_out_last    	=> input_to_mcd_tlast,
				   				 udp_out_user		=> input_to_mcd_tuser,
                   udp_out_data     => input_to_mcd_tdata);

myMonitor:     entity work.kvs_tbMonitorHDLNode(structural)  
				generic map(D_WIDTH		 	=> 64,
							PKT_FILENAME 	=> "pkt.out.txt")
				port map(clk             	=> clk,
						 rst             	=> rst,
						 udp_in_ready    	=> mcd_to_output_tready,
						 udp_in_valid    	=> mcd_to_output_tvalid,
						 udp_in_keep    	=> mcd_to_output_tkeep,
						 udp_in_user    	=> mcd_to_output_tuser,
						 udp_in_last   		=> mcd_to_output_tlast,
						 udp_in_data    	=> mcd_to_output_tdata);

				   
-- Hash Table DRAM model instantiation
dramHash:      entity work.dramModel
               port map(ap_clk                  => clk,
	                    ap_rst_n                => aresetn,
	                    -- ht_dramRdData:     Pull Input, 512b
	                    rdDataOut_V_V_TVALID	=> ht_dramRdData_valid,
	                    rdDataOut_V_V_TREADY	=> ht_dramRdData_ready,
	                    rdDataOut_V_V_TDATA 	=> ht_dramRdData_data,
	                    -- ht_cmd_dramRdData: Push Output, 10b
	                    rdCmdIn_V_TDATA    		=> ht_cmd_dramRdData_data,
	                    rdCmdIn_V_TVALID   		=> ht_cmd_dramRdData_valid,
	                    rdCmdIn_V_TREADY   		=> ht_cmd_dramRdData_ready,
	                    -- ht_dramWrData:     Push Output, 512b
	                    wrDataIn_V_V_TDATA 		=> ht_dramWrData_data,
	                    wrDataIn_V_V_TVALID		=> ht_dramWrData_valid,
	                    wrDataIn_V_V_TREADY 	=> ht_dramWrData_ready,
	                    -- ht_cmd_dramWrData: Push Output, 10b
	                    wrCmdIn_V_TDATA    		=> ht_cmd_dramWrData_data,
	                    wrCmdIn_V_TVALID   		=> ht_cmd_dramWrData_valid,
	                    wrCmdIn_V_TREADY   		=> ht_cmd_dramWrData_ready);
	
-- Update Table DRAM model instantiation
dramUpd:       entity work.dramModel
               port map(ap_clk                  => clk,
   	                    ap_rst_n                => aresetn,
   	                    -- ht_dramRdData:     Pull Input, 512b
  	                    rdDataOut_V_V_TVALID    => upd_dramRdData_valid,
   	                    rdDataOut_V_V_TREADY    => upd_dramRdData_ready,
   	                    rdDataOut_V_V_TDATA     => upd_dramRdData_data,
   	                    -- ht_cmd_dramRdData: Push Output, 10b
   	                    rdCmdIn_V_TDATA    		=> upd_cmd_dramRdData_data,
   	                    rdCmdIn_V_TVALID   		=> upd_cmd_dramRdData_valid,
   	                    rdCmdIn_V_TREADY   		=> upd_cmd_dramRdData_ready,
   	                    -- ht_dramWrData:     Push Output, 512b
   	                    wrDataIn_V_V_TDATA      => upd_dramWrData_data,
   	                    wrDataIn_V_V_TVALID     => upd_dramWrData_valid,
   	                    wrDataIn_V_V_TREADY     => upd_dramWrData_ready,
   	                    -- ht_cmd_dramWrData: Push Output, 10b
   	                    wrCmdIn_V_TDATA   		=> upd_cmd_dramWrData_data,
   	                    wrCmdIn_V_TVALID   		=> upd_cmd_dramWrData_valid,
   	                    wrCmdIn_V_TREADY   		=> upd_cmd_dramWrData_ready);

						--udp_in_data_im <= "0000000000" & udp_in_data;
						--udp_in_data_im <= "000" & udp_in_data;


flashUpd:       entity work.flashModel
                port map(ap_clk                  => clk,
   	                     ap_rst_n                => aresetn,
   	                     -- ht_dramRdData:     Pull Input, 64b
  	                     rdDataOut_V_V_TVALID    => upd_flashRdData_valid,
   	                     rdDataOut_V_V_TREADY    => upd_flashRdData_ready,
   	                     rdDataOut_V_V_TDATA     => upd_flashRdData_data,
   	                     -- ht_cmd_dramRdData: Push Output, 48b
   	                     rdCmdIn_V_TDATA    		=> upd_cmd_flashRdData_data,
   	                     rdCmdIn_V_TVALID   		=> upd_cmd_flashRdData_valid,
   	                     rdCmdIn_V_TREADY   		=> upd_cmd_flashRdData_ready,
   	                     -- ht_dramWrData:     Push Output, 64b
   	                     wrDataIn_V_V_TDATA      => upd_flashWrData_data,
   	                     wrDataIn_V_V_TVALID     => upd_flashWrData_valid,
   	                     wrDataIn_V_V_TREADY     => upd_flashWrData_ready,
   	                     -- ht_cmd_dramWrData: Push Output, 48b
   	                     wrCmdIn_V_TDATA   		=> upd_cmd_flashWrData_data,
   	                     wrCmdIn_V_TVALID   		=> upd_cmd_flashWrData_valid,
   	                     wrCmdIn_V_TREADY   		=> upd_cmd_flashWrData_ready);

-- Dummy PCIe memory allocation module 
memAllocator: entity work.dummypciejoint_top
			  port map(inData_V_V_TVALID			=>  memcached2memAllocation_valid,
					   inData_V_V_TREADY			=>	memcached2memAllocation_ready,
					   inData_V_V_TDATA				=>	memcached2memAllocation_data,
					   outDataDram_V_V_TVALID		=>	memAllocation2memcached_dram_valid,
					   outDataDram_V_V_TREADY		=>	memAllocation2memcached_dram_ready,
					   outDataDram_V_V_TDATA		=>	memAllocation2memcached_dram_data,
					   outDataFlash_V_V_TVALID		=>	memAllocation2memcached_flash_valid,
					   outDataFlash_V_V_TREADY		=>	memAllocation2memcached_flash_ready,
					   outDataFlash_V_V_TDATA		=> 	memAllocation2memcached_flash_data,
					   flushReq_V					=>	flushReq,
					   flushAck_V					=>  flushAck,
					   flushDone_V					=> 	flushDone, 
					   aresetn						=> 	aresetn,
					   aclk							=> 	clk);
					
-- memcached Pipeline Instantiation
myMemcachedPipeline:	entity work.memcachedpipeline
						port map   (hashTableMemRdCmd_V_TVALID 			=> ht_cmd_dramRdData_valid,
									hashTableMemRdCmd_V_TREADY 			=> ht_cmd_dramRdData_ready,
									hashTableMemRdCmd_V_TDATA 			=> ht_cmd_dramRdData_data,
									hashTableMemRdData_V_V_TVALID 		=> ht_dramRdData_valid,
									hashTableMemRdData_V_V_TREADY 		=> ht_dramRdData_ready,
									hashTableMemRdData_V_V_TDATA 		=> ht_dramRdData_data,
									hashTableMemWrCmd_V_TVALID 			=> ht_cmd_dramWrData_valid,
									hashTableMemWrCmd_V_TREADY 			=> ht_cmd_dramWrData_ready,
									hashTableMemWrCmd_V_TDATA 			=> ht_cmd_dramWrData_data,
									hashTableMemWrData_V_V_TVALID 		=> ht_dramWrData_valid,
									hashTableMemWrData_V_V_TREADY 		=> ht_dramWrData_ready,
									hashTableMemWrData_V_V_TDATA 		=> ht_dramWrData_data,
									inData_TVALID 						=> input_to_mcd_tvalid,
									inData_TREADY 						=> input_to_mcd_tready,
									inData_TDATA 						=> input_to_mcd_tdata,
									inData_TKEEP						=> input_to_mcd_tkeep,
									inData_TLAST 						=> input_to_mcd_tlast,
									inData_TUSER 						=> input_to_mcd_tuser,
									outData_TVALID 						=> mcd_to_output_tvalid,
									outData_TREADY 						=> mcd_to_output_tready,
									outData_TDATA 						=> mcd_to_output_tdata,
									outData_TUSER 						=> mcd_to_output_tuser,
									outData_TKEEP 						=> mcd_to_output_tkeep,
									outData_TLAST 						=> mcd_to_output_tlast,
									dramValueStoreMemRdCmd_V_TVALID 	=> upd_cmd_dramRdData_valid,
									dramValueStoreMemRdCmd_V_TREADY 	=> upd_cmd_dramRdData_ready,
									dramValueStoreMemRdCmd_V_TDATA 		=> upd_cmd_dramRdData_data,
									dramValueStoreMemRdData_V_V_TVALID 	=> upd_dramRdData_valid,
									dramValueStoreMemRdData_V_V_TREADY 	=> upd_dramRdData_ready,
									dramValueStoreMemRdData_V_V_TDATA 	=> upd_dramRdData_data,
									dramValueStoreMemWrCmd_V_TVALID 	=> upd_cmd_dramWrData_valid,
									dramValueStoreMemWrCmd_V_TREADY 	=> upd_cmd_dramWrData_ready,
									dramValueStoreMemWrCmd_V_TDATA 		=> upd_cmd_dramWrData_data,
									dramValueStoreMemWrData_V_V_TVALID 	=> upd_dramWrData_valid,
									dramValueStoreMemWrData_V_V_TREADY 	=> upd_dramWrData_ready,
									dramValueStoreMemWrData_V_V_TDATA 	=> upd_dramWrData_data,
									flashValueStoreMemRdCmd_V_TVALID 	=> upd_cmd_flashRdData_valid,
									flashValueStoreMemRdCmd_V_TREADY 	=> upd_cmd_flashRdData_ready,
									flashValueStoreMemRdCmd_V_TDATA 	=> upd_cmd_flashRdData_data,
									flashValueStoreMemRdData_V_V_TVALID => upd_flashRdData_valid,
									flashValueStoreMemRdData_V_V_TREADY => upd_flashRdData_ready,
									flashValueStoreMemRdData_V_V_TDATA 	=> upd_flashRdData_data,
									flashValueStoreMemWrCmd_V_TVALID 	=> upd_cmd_flashWrData_valid,
									flashValueStoreMemWrCmd_V_TREADY 	=> upd_cmd_flashWrData_ready,
									flashValueStoreMemWrCmd_V_TDATA 	=> upd_cmd_flashWrData_data,
									flashValueStoreMemWrData_V_V_TVALID => upd_flashWrData_valid,
									flashValueStoreMemWrData_V_V_TREADY => upd_flashWrData_ready,
									flashValueStoreMemWrData_V_V_TDATA 	=> upd_flashWrData_data,
									addressReturnOut_V_V_TDATA			=> memcached2memAllocation_data,
									addressReturnOut_V_V_TVALID			=> memcached2memAllocation_valid,
									addressReturnOut_V_V_TREADY			=> memcached2memAllocation_ready,
									addressAssignDramIn_V_V_TDATA		=> memAllocation2memcached_dram_data,
									addressAssignDramIn_V_V_TVALID		=> memAllocation2memcached_dram_valid,
									addressAssignDramIn_V_V_TREADY		=> memAllocation2memcached_dram_ready,
									addressAssignFlashIn_V_V_TDATA		=> memAllocation2memcached_flash_data,
									addressAssignFlashIn_V_V_TVALID		=> memAllocation2memcached_flash_valid,
									addressAssignFlashIn_V_V_TREADY		=> memAllocation2memcached_flash_ready,
									ap_rst_n							=> aresetn,
									ap_clk 								=> clk,
									flushReq_V							=> flushReq,
									flushAck_V							=> flushAck,
									flushDone_V							=> flushDone);
end Structural;

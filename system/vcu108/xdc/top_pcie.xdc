#
# XDC for PCIe
#

#
# Clock for MC
#
#create_clock -name default_sysclk_300_clk_p -period 3.333 [get_ports default_sysclk_300_clk_p]
set_property PACKAGE_PIN G31 [get_ports default_sysclk_300_clk_p]
set_property PACKAGE_PIN F31 [get_ports default_sysclk_300_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports default_sysclk_300_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports default_sysclk_300_clk_n]

#
# PCIe clock
#
create_clock -period 10.000 -name pcie_dedicated_100_clk [get_ports pcie_dedicated_100_clk_p]
set_property LOC GTHE3_COMMON_X0Y1 [get_cells refclk_ibuf]

#
# PCIe reset
#
set_false_path -from [get_ports sys_rst_n]
set_property LOC [get_package_pins -filter {PIN_FUNC == IO_T3U_N12_PERSTN0_65}] [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]

#
# I/O Ports
#
set_property PACKAGE_PIN AL24 [get_ports user_lnk_up]
set_property IOSTANDARD LVCMOS18 [get_ports user_lnk_up]

#
# Any other Constraints
# (From reference design)
set_false_path -through [get_pins u_pcie/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst/CFGMAX*]
set_false_path -through [get_nets u_pcie/inst/cfg_max*]


# ignore signal probe's path
#set_false_path -from [get_pins u_LegoFPGA/mc_ddr4_wrapper/mc_ddr4_core/inst/div_clk_rst_r1_reg/C] -to [get_pins {u_LegoFPGA/ila_0/inst/ila_core_inst/u_trig/U_TM/N_DDR_MODE.G_NMU[0].U_M/allx_typeA_match_detection.ltlib_v1_0_0_allx_typeA_inst/probeDelay1_reg[0]/D}]
#set_false_path -from [get_pins u_LegoFPGA/mc_ddr4_wrapper/mc_ddr4_core/inst/div_clk_rst_r1_reg/C] -to [get_pins u_LegoFPGA/ila_0/inst/ila_core_inst/srlopt/D]



###############################################################################
# Flash Programming Settings: Uncomment as required by your design
# Items below between < > must be updated with correct values to work properly.
###############################################################################
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DIV-1 [current_design]
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type1 [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

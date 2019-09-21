#
# Copyright (c) 2019, Wuklab@UCSD. All rights reserved.
#

#
# Clock for PCIe (100 MHz)
#
#create_clock -period 10.000 -name pcie_dedicated_100_clk [get_ports pcie_dedicated_100_clk_p]
create_clock -period 10.000 [get_ports pcie_dedicated_100_clk_p]
set_property PACKAGE_PIN AC9 [get_ports pcie_dedicated_100_clk_p]
set_property PACKAGE_PIN AC8 [get_ports pcie_dedicated_100_clk_n]

#
# Clock for Memory Controller (250 MHz)
#
#create_clock -period 4.000 -name default_sysclk_250_clk [get_ports default_sysclk_250_clk_p]
create_clock -period 4.000 [get_ports default_sysclk_250_clk_p]
set_property BOARD_PIN {default_250mhz_clk1_n} [get_ports default_sysclk_250_clk_n]
set_property BOARD_PIN {default_250mhz_clk1_p} [get_ports default_sysclk_250_clk_p]

#
# Reset for PCIe
#
set_false_path -from [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]
set_property PACKAGE_PIN AM17 [get_ports sys_rst_n]

#
# I/O Ports
#
set_property PACKAGE_PIN AV34 [get_ports user_lnk_up]
set_property IOSTANDARD LVCMOS12 [get_ports user_lnk_up]
set_property DRIVE 8 [get_ports user_lnk_up]
set_false_path -to [get_ports -filter NAME=~user_lnk_up]

#
# Any other Constraints
# (From reference design)
#set_false_path -through [get_pins u_pcie/xdma_0/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst/CFGMAX*]
#set_false_path -through [get_nets u_pcie/xdma_0/inst/cfg_max*]


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

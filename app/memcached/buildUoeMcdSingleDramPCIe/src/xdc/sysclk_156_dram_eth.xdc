

##GT Ref clk differential pair for 10gig eth.  MGTREFCLK0P_116
create_clock -period 6.400 -name xgemac_clk_156 [get_ports xphy_refclk_p]
set_property PACKAGE_PIN T5 [get_ports xphy_refclk_n]
set_property PACKAGE_PIN T6 [get_ports xphy_refclk_p]

set_false_path -from [get_cells aresetn_r_reg]

set_property PACKAGE_PIN U3 [get_ports xphy0_rxn]
set_property PACKAGE_PIN U4 [get_ports xphy0_rxp]
set_property PACKAGE_PIN T1 [get_ports xphy0_txn]
set_property PACKAGE_PIN T2 [get_ports xphy0_txp]

# SFP TX Disable for 10G PHY. Chip package 1157 on alpha data board only breaks out 2 transceivers!
set_property PACKAGE_PIN AC34 [get_ports {sfp_tx_disable[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sfp_tx_disable[0]}]
set_property PACKAGE_PIN AA34 [get_ports {sfp_tx_disable[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sfp_tx_disable[1]}]

set_property PACKAGE_PIN AA23 [get_ports sfp_on]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_on]

set_false_path -from [get_ports pok_dram]

set_property PACKAGE_PIN AH10 [get_ports {c0_ddr3_dm[0]}]
set_property PACKAGE_PIN AF9 [get_ports {c0_ddr3_dm[1]}]
set_property PACKAGE_PIN AM13 [get_ports {c0_ddr3_dm[2]}]
set_property PACKAGE_PIN AL10 [get_ports {c0_ddr3_dm[3]}]
set_property PACKAGE_PIN AL20 [get_ports {c0_ddr3_dm[4]}]
set_property PACKAGE_PIN AJ24 [get_ports {c0_ddr3_dm[5]}]
set_property PACKAGE_PIN AD22 [get_ports {c0_ddr3_dm[6]}]
set_property PACKAGE_PIN AD15 [get_ports {c0_ddr3_dm[7]}]
set_property PACKAGE_PIN AM23 [get_ports {c0_ddr3_dm[8]}]

set_property VCCAUX_IO NORMAL [get_ports {c0_ddr3_dm[*]}]
set_property SLEW FAST [get_ports {c0_ddr3_dm[*]}]
set_property IOSTANDARD SSTL15 [get_ports {c0_ddr3_dm[*]}]


set_property PACKAGE_PIN B32 [get_ports {c1_ddr3_dm[0]}]
set_property PACKAGE_PIN A30 [get_ports {c1_ddr3_dm[1]}]
set_property PACKAGE_PIN E24 [get_ports {c1_ddr3_dm[2]}]
set_property PACKAGE_PIN B26 [get_ports {c1_ddr3_dm[3]}]
set_property PACKAGE_PIN U31 [get_ports {c1_ddr3_dm[4]}]
set_property PACKAGE_PIN R29 [get_ports {c1_ddr3_dm[5]}]
set_property PACKAGE_PIN K34 [get_ports {c1_ddr3_dm[6]}]
set_property PACKAGE_PIN N34 [get_ports {c1_ddr3_dm[7]}]
set_property PACKAGE_PIN P25 [get_ports {c1_ddr3_dm[8]}]

set_property VCCAUX_IO NORMAL [get_ports {c1_ddr3_dm[*]}]
set_property SLEW FAST [get_ports {c1_ddr3_dm[*]}]
set_property IOSTANDARD SSTL15 [get_ports {c1_ddr3_dm[*]}]
# DDR3 SDRAM
set_property PACKAGE_PIN AA24 [get_ports {dram_on[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dram_on[*]}]
set_property PACKAGE_PIN AB25 [get_ports {dram_on[1]}]
set_property PACKAGE_PIN AA31 [get_ports pok_dram]
set_property IOSTANDARD LVCMOS18 [get_ports pok_dram]

#if use pcie add following constraints
set_clock_groups -name pcie_gmac_async -asynchronous \
-group [get_clocks xgemac_clk_156 ] \
-group [get_clocks userclk1]

#if use dram channel 1
set_clock_groups -name dram_gmac_async -asynchronous \
-group [get_clocks xgemac_clk_156 ] \
-group [get_clocks clk_pll_i_1]

set_clock_groups -name dram_gmac_async_1 -asynchronous \
-group [get_clocks xgemac_clk_156 ] \
-group [get_clocks clk_pll_i]

set_clock_groups -name async_1 -asynchronous \
-group [get_clocks clk156_buf ] \
-group [get_clocks clk_pll_i]

set_clock_groups -name async_2 -asynchronous \
-group [get_clocks clk156_buf ] \
-group [get_clocks clk_pll_i_1]

set_clock_groups -name async_3 -asynchronous \
-group [get_clocks clk156_buf ] \
-group [get_clocks userclk1]

set_false_path -from [get_cells n10g_interface_inst/xgbaser_gt_wrapper_inst/reset_pulse_reg[0]]
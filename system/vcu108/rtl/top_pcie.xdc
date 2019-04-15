### Transceiver Reference Clock Placement
### Transceivers should be adjacent to allow timing constraints to be met easily.
### Full details of available transceiver locations can be found
### in the appropriate transceiver User Guide, or use the Transceiver Wizard.

# Primary Clock
#
# Primary clocks are mostly added via clock wizard in BD.
# Each one of them has associcated board xdc. So we don't
# need to worry most of them.
#
# For this one, Vivado already figured out its a primary clock
# and will run create_clock for us. We only need to specify location.
set_property PACKAGE_PIN AF38 [get_ports default_sysclk_125_clk_p]
set_property PACKAGE_PIN AF39 [get_ports default_sysclk_125_clk_n]

#create_clock -name default_sysclk_300_clk_p -period 3.333 [get_ports default_sysclk_300_clk_p]
set_property PACKAGE_PIN G31 [get_ports default_sysclk_300_clk_p]
set_property PACKAGE_PIN F31 [get_ports default_sysclk_300_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports default_sysclk_300_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports default_sysclk_300_clk_n]

# Rename generated clock
# dclk is a 100MHZ output clock from clock wizard
create_generated_clock -name dclk [get_pins {u_clock_gen/sys_clkwiz_125/inst/mmcme3_adv_inst/CLKOUT0}]

# PCIE clock
create_clock -period 10.000 -name pcie_dedicated_100_clk [get_ports pcie_dedicated_100_clk_p]
set_property LOC GTHE3_COMMON_X0Y1 [get_cells refclk_ibuf]

##### SYS RESET###########
set_property LOC [get_package_pins -filter {PIN_FUNC == IO_T3U_N12_PERSTN0_65}] [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]

### Below XDC constraints are for VCU108 board with xcvu095-ffva2104-2-e-es2 device
### Change these constraints as per your board and device

### I/O Ports
set_property PACKAGE_PIN AL24 [get_ports user_lnk_up]
set_property IOSTANDARD LVCMOS18 [get_ports user_lnk_up]


### Any other Constraints

# ignore signal probe's path
set_false_path -from [get_pins u_LegoFPGA/mc_ddr4_wrapper/mc_ddr4_core/inst/div_clk_rst_r1_reg/C] -to [get_pins {u_LegoFPGA/ila_0/inst/ila_core_inst/u_trig/U_TM/N_DDR_MODE.G_NMU[0].U_M/allx_typeA_match_detection.ltlib_v1_0_0_allx_typeA_inst/probeDelay1_reg[0]/D}]
set_false_path -from [get_pins u_LegoFPGA/mc_ddr4_wrapper/mc_ddr4_core/inst/div_clk_rst_r1_reg/C] -to [get_pins u_LegoFPGA/ila_0/inst/ila_core_inst/srlopt/D]

set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 2.56
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 2.56
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks dclk] -datapath_only 2.56
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks dclk] -datapath_only 2.56
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10.000
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10.000


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

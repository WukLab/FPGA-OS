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
set_property PACKAGE_PIN AF38 [get_ports default_sysclk_161_clk_p]
set_property PACKAGE_PIN AF39 [get_ports default_sysclk_161_clk_n]

# Rename generated clock
# dclk is a 100MHZ output clock from clock wizard
create_generated_clock -name dclk [get_pins {u_clock_gen/sys_clkwiz_125/inst/mmcme3_adv_inst/CLKOUT0}]

### Below XDC constraints are for VCU108 board with xcvu095-ffva2104-2-e-es2 device
### Change these constraints as per your board and device

### LEDs (Check Table 1-32)
set_property PACKAGE_PIN AT32 [get_ports rx_gt_locked_led_0]
set_property IOSTANDARD LVCMOS12 [get_ports rx_gt_locked_led_0]

set_property PACKAGE_PIN AV34 [get_ports rx_block_lock_led_0]
set_property IOSTANDARD LVCMOS12 [get_ports rx_block_lock_led_0]

### Any other Constraints  
set_false_path -to [get_cells -hierarchical -filter {NAME =~ */i_*_axi_if_top/*/i_*_syncer/*meta_reg*}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ */i_*_SYNC*/*stretch_reg*}]
set_false_path -to [get_cells -hierarchical -filter {NAME=~ */i*syncer/*d2_cdc_to*}]

set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 2.56
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 2.56
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks dclk] -datapath_only 2.56
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks dclk] -datapath_only 2.56
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10.000
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10.000

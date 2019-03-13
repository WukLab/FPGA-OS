#------------------------------------------------------------------------------
# XXV_ETHERNET example design-level XDC file
# ----------------------------------------------------------------------------------------------------------------------
## init_clk should be lesser or equal to reference clock.
### Transceiver Reference Clock Placement
### Transceivers should be adjacent to allow timing constraints to be met easily. 
### Full details of available transceiver locations can be found
### in the appropriate transceiver User Guide, or use the Transceiver Wizard.
create_clock -period 10.000 [get_ports dclk]
set_property IOSTANDARD LVCMOS18 [get_ports dclk]
### These are sample constraints, please use correct constraints for your device 
### update the gt_refclk pin location accordingly and un-comment the below two lines 
  #set_property PACKAGE_PIN AK38 [get_ports gt_refclk_p]
  #set_property PACKAGE_PIN AK39 [get_ports gt_refclk_n]

###Board constraints to be added here
### Below XDC constraints are for VCU108 board with xcvu095-ffva2104-2-e-es2 device
### Change these constraints as per your board and device
#### Push Buttons
###set_property PACKAGE_PIN D9 [get_ports sys_reset]
set_property IOSTANDARD LVCMOS18 [get_ports sys_reset]

#set_property LOC A10 [get_ports restart_tx_rx_0]
set_property IOSTANDARD LVCMOS18 [get_ports restart_tx_rx_0]

### LEDs
#set_property PACKAGE_PIN AT32 [get_ports rx_gt_locked_led_0]
set_property IOSTANDARD LVCMOS18 [get_ports rx_gt_locked_led_0]
##
#set_property PACKAGE_PIN AV34 [get_ports rx_block_lock_led_0]
set_property IOSTANDARD LVCMOS18 [get_ports rx_block_lock_led_0]
##
#set_property PACKAGE_PIN AY30 [get_ports completion_status[0]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[0]]
##
#set_property PACKAGE_PIN BB32 [get_ports completion_status[1]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[1]]
##
#set_property PACKAGE_PIN BF32 [get_ports completion_status[2]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[2]]
##
#set_property PACKAGE_PIN AV36 [get_ports completion_status[3]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[3]]
##
#set_property PACKAGE_PIN AY35 [get_ports completion_status[4]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[4]]







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

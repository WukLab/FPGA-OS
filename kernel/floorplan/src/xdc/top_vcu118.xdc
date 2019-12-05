set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */addn_ui_clkout1}]
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}]

set_property LOCK_PINS {I0:A6} [get_cells {config_mb_i/dummy_net_dram_0/inst/to_pr[0]_INST_0}]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]

#
# PR XDC
#

# Create one PR region and associate module
create_pblock pb_0
add_cells_to_pblock [get_pblocks pb_0] [get_cells -quiet [list inst_rp_0]]
resize_pblock [get_pblocks pb_0] -add {SLICE_X16Y545:SLICE_X23Y594}
resize_pblock [get_pblocks pb_0] -add {DSP48E2_X1Y218:DSP48E2_X2Y237}
set_property SNAPPING_MODE ON [get_pblocks pb_0]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pb_0]
#set_property CONTAIN_ROUTING 0 [get_pblocks rp_1_pblock_0]

create_pblock pb_1
add_cells_to_pblock [get_pblocks pb_1] [get_cells -quiet [list inst_rp_1]]
resize_pblock [get_pblocks pb_1] -add {SLICE_X146Y545:SLICE_X152Y592}
resize_pblock [get_pblocks pb_1] -add {DSP48E2_X17Y218:DSP48E2_X17Y235}
set_property SNAPPING_MODE ON [get_pblocks pb_1]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pb_1]
#set_property CONTAIN_ROUTING 0 [get_pblocks rp_1_pblock_0]

create_pblock pb_2
add_cells_to_pblock [get_pblocks pb_2] [get_cells -quiet [list inst_rp_2]]
resize_pblock [get_pblocks pb_2] -add {SLICE_X18Y6:SLICE_X24Y51}
resize_pblock [get_pblocks pb_2] -add {DSP48E2_X2Y4:DSP48E2_X2Y19}
set_property SNAPPING_MODE ON [get_pblocks pb_2]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pb_2]
#set_property CONTAIN_ROUTING 0 [get_pblocks rp_1_pblock_0]

create_pblock pb_3
add_cells_to_pblock [get_pblocks pb_3] [get_cells -quiet [list inst_rp_3]]
resize_pblock [get_pblocks pb_3] -add {SLICE_X146Y6:SLICE_X152Y54}
set_property SNAPPING_MODE ON [get_pblocks pb_3]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pb_3]
#set_property CONTAIN_ROUTING 0 [get_pblocks rp_1_pblock_0]

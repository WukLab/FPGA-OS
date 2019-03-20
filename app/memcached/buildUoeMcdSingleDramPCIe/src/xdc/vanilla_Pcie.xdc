#pcie constraints for alpha data board
#The constraints for the actual data channels are provided by the ip core.
set_property PACKAGE_PIN W27 [get_ports pcie_reset]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_reset]
set_property PULLUP true [get_ports pcie_reset]
set_property PACKAGE_PIN F5 [get_ports pcie_clkn]

set_false_path -from [get_ports pcie_reset]
#set_clock_groups -name pcie_async -asynchronous -group [get_clocks -of_objects [get_pins pcie2axilite_bridge_i/pcie_and_stats_i/pcie3_7x_0/user_clk] ] -group [get_clocks clk156]



#end of the definitions necessary for PCIe.





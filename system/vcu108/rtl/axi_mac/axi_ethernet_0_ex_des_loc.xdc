## ########################################################################################################################
## ##
## # (c) Copyright 2012-2016 Xilinx, Inc. All rights reserved.
## #
## # This file contains confidential and proprietary information of Xilinx, Inc. and is protected under U.S. and
## # international copyright and other intellectual property laws. 
## #
## # DISCLAIMER
## # This disclaimer is not a license and does not grant any rights to the materials distributed herewith. Except as
## # otherwise provided in a valid license issued to you by Xilinx, and to the maximum extent permitted by applicable law:
## # (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND
## # CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## # INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether in contract or tort,
## # including negligence, or under any other theory of liability) for any loss or damage of any kind or nature related to,
## # arising under or in connection with these materials, including for any direct, or any indirect, special, incidental, or
## # consequential loss or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered as a
## # result of any action brought by a third party) even if such damage or loss was reasonably foreseeable or Xilinx had
## # been advised of the possibility of the same.
## #
## # CRITICAL APPLICATIONS
## # Xilinx products are not designed or intended to be fail-safe, or for use in any application requiring fail-safe
## # performance, such as life-support or safety devices or systems, Class III medical devices, nuclear facilities,
## # applications related to the deployment of airbags, or any other applications that could lead to death, personal injury,
## # or severe property or environmental damage (individually and collectively, "Critical Applications"). Customer assumes
## # the sole risk and liability of any use of Xilinx products in Critical Applications, subject only to applicable laws and
## # regulations governing limitations on product liability.
## #
## # THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
## #
## ########################################################################################################################


# This file has LOC constraints for example design.

set_property PACKAGE_PIN  g31   [get_ports clk_in_p]
set_property IOSTANDARD   DIFF_SSTL12  [get_ports clk_in_p]
set_property PACKAGE_PIN  e36   [get_ports sys_rst]
set_property IOSTANDARD   LVCMOS18  [get_ports sys_rst]
set_property PACKAGE_PIN  e34   [get_ports start_config]
set_property IOSTANDARD   LVCMOS18  [get_ports start_config]
set_property PACKAGE_PIN  at32   [get_ports mtrlb_activity_flash]
set_property IOSTANDARD   LVCMOS18  [get_ports mtrlb_activity_flash]
set_property PACKAGE_PIN  av34   [get_ports mtrlb_pktchk_error]
set_property IOSTANDARD   LVCMOS18  [get_ports mtrlb_pktchk_error]

set_property PACKAGE_PIN  bc40   [get_ports control_data[0]]
set_property IOSTANDARD   lvcmos18  [get_ports control_data[0]]
set_property PACKAGE_PIN  L19   [get_ports control_data[1]]
set_property IOSTANDARD   lvcmos18  [get_ports control_data[1]]
set_property PACKAGE_PIN  c37   [get_ports control_data[2]]
set_property IOSTANDARD   lvcmos18  [get_ports control_data[2]]
set_property PACKAGE_PIN  c38   [get_ports control_data[3]]
set_property IOSTANDARD   lvcmos18  [get_ports control_data[3]]
set_property PACKAGE_PIN  a10   [get_ports control_valid]
set_property IOSTANDARD   lvcmos18  [get_ports control_valid]
set_property PACKAGE_PIN  bb32   [get_ports control_ready]
set_property IOSTANDARD   lvcmos18  [get_ports control_ready]


## Phy in SGMII LVDS mode
set_property LOC BITSLICE_RX_TX_X1Y103 [get_cells -hier -nocase -regexp {.*/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}]
set_property LOC AL20 [get_ports *txp]
set_property LOC AU19 [get_ports *rxp]


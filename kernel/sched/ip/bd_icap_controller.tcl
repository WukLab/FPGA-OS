# Proc to create BD icap_controller
proc cr_bd_icap_controller { parentCell } {
# The design that will be created by this Tcl proc contains the following 
# module references:
# icape3_wrapper, strip



  # CHANGE DESIGN NAME HERE
  set design_name icap_controller

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:clk_wiz:6.0\
  Wuklab.UCSD:hls:icap_controller_hls:1.0\
  xilinx.com:ip:ila:6.2\
  xilinx.com:ip:vio:3.0\
  "

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

  }

  ##################################################################
  # CHECK Modules
  ##################################################################
  set bCheckModules 1
  if { $bCheckModules == 1 } {
     set list_check_mods "\ 
  icape3_wrapper\
  strip\
  "

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

  if { $bCheckIPsPassed != 1 } {
    common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set sysclk_125 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sysclk_125 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $sysclk_125

  # Create ports

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sysclk_125} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_0

  # Create instance: icap_controller_hls_0, and set properties
  set icap_controller_hls_0 [ create_bd_cell -type ip -vlnv Wuklab.UCSD:hls:icap_controller_hls:1.0 icap_controller_hls_0 ]

  # Create instance: icape3_wrapper_0, and set properties
  set block_name icape3_wrapper
  set block_cell_name icape3_wrapper_0
  if { [catch {set icape3_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $icape3_wrapper_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_0

  # Create instance: ila_1, and set properties
  set ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_1 ]
  set_property -dict [ list \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_1

  # Create instance: ila_2, and set properties
  set ila_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_2 ]
  set_property -dict [ list \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_PROBE5_WIDTH {32} \
   CONFIG.C_PROBE6_WIDTH {32} \
 ] $ila_2

  # Create instance: strip_0, and set properties
  set block_name strip
  set block_cell_name strip_0
  if { [catch {set strip_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $strip_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: vio_0, and set properties
  set vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0 ]
  set_property -dict [ list \
   CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
   CONFIG.C_NUM_PROBE_IN {0} \
   CONFIG.C_PROBE_OUT0_INIT_VAL {0x0} \
 ] $vio_0

  # Create interface connections
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins icap_controller_hls_0/from_icap_V_V] [get_bd_intf_pins strip_0/data_to_hls]
connect_bd_intf_net -intf_net [get_bd_intf_nets axis_data_fifo_0_M_AXIS] [get_bd_intf_pins ila_1/SLOT_0_AXIS] [get_bd_intf_pins strip_0/data_to_hls]
  connect_bd_intf_net -intf_net icap_controller_hls_0_to_icap_V_V [get_bd_intf_pins icap_controller_hls_0/to_icap_V_V] [get_bd_intf_pins strip_0/data_from_hls]
connect_bd_intf_net -intf_net [get_bd_intf_nets icap_controller_hls_0_to_icap_V_V] [get_bd_intf_pins ila_0/SLOT_0_AXIS] [get_bd_intf_pins strip_0/data_from_hls]
  connect_bd_intf_net -intf_net sysclk_125_1 [get_bd_intf_ports sysclk_125] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]

  # Create port connections
  connect_bd_net -net clk_1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins icap_controller_hls_0/ap_clk] [get_bd_pins icape3_wrapper_0/CLK] [get_bd_pins ila_0/clk] [get_bd_pins ila_1/clk] [get_bd_pins ila_2/clk] [get_bd_pins strip_0/clk] [get_bd_pins vio_0/clk]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins icap_controller_hls_0/ap_rst_n] [get_bd_pins ila_2/probe7]
  connect_bd_net -net icap_controller_hls_0_CSIB_to_icap_V [get_bd_pins icap_controller_hls_0/CSIB_to_icap_V] [get_bd_pins strip_0/CSIB_from_hls]
  connect_bd_net -net icap_controller_hls_0_CSIB_to_icap_V_ap_vld [get_bd_pins icap_controller_hls_0/CSIB_to_icap_V_ap_vld] [get_bd_pins strip_0/CSIB_from_hls_valid]
  connect_bd_net -net icap_controller_hls_0_RDWRB_to_icap_V [get_bd_pins icap_controller_hls_0/RDWRB_to_icap_V] [get_bd_pins strip_0/RDWRB_from_hls]
  connect_bd_net -net icap_controller_hls_0_RDWRB_to_icap_V_ap_vld [get_bd_pins icap_controller_hls_0/RDWRB_to_icap_V_ap_vld] [get_bd_pins strip_0/RDWRB_from_hls_valid]
  connect_bd_net -net icape3_wrapper_0_AVAIL [get_bd_pins icape3_wrapper_0/AVAIL] [get_bd_pins ila_2/probe2] [get_bd_pins strip_0/AVAIL_from_icap]
  connect_bd_net -net icape3_wrapper_0_O [get_bd_pins icape3_wrapper_0/O] [get_bd_pins ila_2/probe6] [get_bd_pins strip_0/data_from_icap]
  connect_bd_net -net icape3_wrapper_0_PRDONE [get_bd_pins icape3_wrapper_0/PRDONE] [get_bd_pins ila_2/probe3] [get_bd_pins strip_0/PRDONE_from_icap]
  connect_bd_net -net icape3_wrapper_0_PRERROR [get_bd_pins icape3_wrapper_0/PRERROR] [get_bd_pins ila_2/probe4] [get_bd_pins strip_0/PRERROR_from_icap]
  connect_bd_net -net strip_0_AVAIL_to_hls [get_bd_pins icap_controller_hls_0/AVAIL_from_icap_V] [get_bd_pins strip_0/AVAIL_to_hls]
  connect_bd_net -net strip_0_CSIB_to_icap [get_bd_pins icape3_wrapper_0/CSIB] [get_bd_pins ila_2/probe0] [get_bd_pins strip_0/CSIB_to_icap]
  connect_bd_net -net strip_0_PRDONE_to_hls [get_bd_pins icap_controller_hls_0/PRDONE_from_icap_V] [get_bd_pins strip_0/PRDONE_to_hls]
  connect_bd_net -net strip_0_PRERROR_to_hls [get_bd_pins icap_controller_hls_0/PRERROR_from_icap_V] [get_bd_pins strip_0/PRERROR_to_hls]
  connect_bd_net -net strip_0_RDWRB_to_icap [get_bd_pins icape3_wrapper_0/RDWRB] [get_bd_pins ila_2/probe1] [get_bd_pins strip_0/RDWRB_to_icap]
  connect_bd_net -net strip_0_data_to_icap [get_bd_pins icape3_wrapper_0/I] [get_bd_pins ila_2/probe5] [get_bd_pins strip_0/data_to_icap]
  connect_bd_net -net vio_0_probe_out0 [get_bd_pins icap_controller_hls_0/start_test_V] [get_bd_pins ila_2/probe8] [get_bd_pins vio_0/probe_out0]

  # Create address segments

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 6.8.11  2018-08-07 bk=1.4403 VDI=40 GEI=35 GUI=JA:9.0 TLS
#  -string -flagsOSRD
preplace port sysclk_125 -pg 1 -y 550 -defaultsOSRD
preplace inst strip_0 -pg 1 -lvl 2 -y 370 -defaultsOSRD
preplace inst vio_0 -pg 1 -lvl 2 -y 770 -defaultsOSRD
preplace inst ila_0 -pg 1 -lvl 2 -y 640 -defaultsOSRD
preplace inst icap_controller_hls_0 -pg 1 -lvl 3 -y 710 -defaultsOSRD
preplace inst icape3_wrapper_0 -pg 1 -lvl 3 -y 140 -defaultsOSRD
preplace inst ila_1 -pg 1 -lvl 3 -y 910 -defaultsOSRD
preplace inst ila_2 -pg 1 -lvl 3 -y 410 -defaultsOSRD
preplace inst clk_wiz_0 -pg 1 -lvl 1 -y 550 -defaultsOSRD
preplace netloc clk_wiz_0_locked 1 1 2 N 560 790
preplace netloc icap_controller_hls_0_RDWRB_to_icap_V 1 1 3 290 840 NJ 840 1330
preplace netloc strip_0_AVAIL_to_hls 1 2 1 750
preplace netloc icap_controller_hls_0_to_icap_V_V 1 1 3 270 570 NJ 570 1330
preplace netloc icape3_wrapper_0_AVAIL 1 2 1 830
preplace netloc icap_controller_hls_0_CSIB_to_icap_V 1 1 3 280 830 NJ 830 1340
preplace netloc vio_0_probe_out0 1 2 1 840J
preplace netloc sysclk_125_1 1 0 1 N
preplace netloc icape3_wrapper_0_PRDONE 1 2 1 820
preplace netloc strip_0_PRDONE_to_hls 1 2 1 760
preplace netloc clk_1 1 1 2 260 200 780
preplace netloc strip_0_data_to_icap 1 2 1 760
preplace netloc icape3_wrapper_0_PRERROR 1 2 1 810
preplace netloc strip_0_PRERROR_to_hls 1 2 1 740
preplace netloc axis_data_fifo_0_M_AXIS 1 2 1 770
preplace netloc icape3_wrapper_0_O 1 2 1 790
preplace netloc icap_controller_hls_0_RDWRB_to_icap_V_ap_vld 1 1 3 310 540 830J 580 1340
preplace netloc strip_0_RDWRB_to_icap 1 2 1 840
preplace netloc icap_controller_hls_0_CSIB_to_icap_V_ap_vld 1 1 3 300 550 810J 560 1350
preplace netloc strip_0_CSIB_to_icap 1 2 1 800
levelinfo -pg 1 0 140 530 1090 1380 -top 0 -bot 980
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_icap_controller()
cr_bd_icap_controller ""
set_property REGISTERED_WITH_MANAGER "1" [get_files icap_controller.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files icap_controller.bd ] 

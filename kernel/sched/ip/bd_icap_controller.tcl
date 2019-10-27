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
  Wuklab.UCSD:hls:icap_controller_hls:1.0\
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

  # Create ports
  set clk [ create_bd_port -dir I -type clk clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {rst_n} \
   CONFIG.FREQ_HZ {100000000} \
 ] $clk
  set rst_n [ create_bd_port -dir I -type rst rst_n ]

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
  
  # Create interface connections
  connect_bd_intf_net -intf_net icap_controller_hls_0_to_icap_V_V [get_bd_intf_pins icap_controller_hls_0/to_icap_V_V] [get_bd_intf_pins strip_0/data_from_hls]
  connect_bd_intf_net -intf_net strip_0_data_to_hls [get_bd_intf_pins icap_controller_hls_0/from_icap_V_V] [get_bd_intf_pins strip_0/data_to_hls]
  connect_bd_intf_net -intf_net strip_0_with_ICAP [get_bd_intf_pins icape3_wrapper_0/ICAP] [get_bd_intf_pins strip_0/with_ICAP]

  # Create port connections
  connect_bd_net -net ap_rst_n_0_1 [get_bd_ports rst_n] [get_bd_pins icap_controller_hls_0/ap_rst_n]
  connect_bd_net -net clk_1 [get_bd_ports clk] [get_bd_pins icap_controller_hls_0/ap_clk] [get_bd_pins icape3_wrapper_0/clk] [get_bd_pins strip_0/clk]
  connect_bd_net -net icap_controller_hls_0_CSIB_to_icap_V [get_bd_pins icap_controller_hls_0/CSIB_to_icap_V] [get_bd_pins strip_0/CSIB_from_hls]
  connect_bd_net -net icap_controller_hls_0_CSIB_to_icap_V_ap_vld [get_bd_pins icap_controller_hls_0/CSIB_to_icap_V_ap_vld] [get_bd_pins strip_0/CSIB_from_hls_valid]
  connect_bd_net -net icap_controller_hls_0_RDWRB_to_icap_V [get_bd_pins icap_controller_hls_0/RDWRB_to_icap_V] [get_bd_pins strip_0/RDWRB_from_hls]
  connect_bd_net -net icap_controller_hls_0_RDWRB_to_icap_V_ap_vld [get_bd_pins icap_controller_hls_0/RDWRB_to_icap_V_ap_vld] [get_bd_pins strip_0/RDWRB_from_hls_valid]
  connect_bd_net -net strip_0_AVAIL_to_hls [get_bd_pins icap_controller_hls_0/AVAIL_from_icap_V] [get_bd_pins strip_0/AVAIL_to_hls]
  connect_bd_net -net strip_0_PRDONE_to_hls [get_bd_pins icap_controller_hls_0/PRDONE_from_icap_V] [get_bd_pins strip_0/PRDONE_to_hls]
  connect_bd_net -net strip_0_PRERROR_to_hls [get_bd_pins icap_controller_hls_0/PRERROR_from_icap_V] [get_bd_pins strip_0/PRERROR_to_hls]

  # Create address segments

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 6.8.11  2018-08-07 bk=1.4403 VDI=40 GEI=35 GUI=JA:9.0 TLS
#  -string -flagsOSRD
preplace port clk -pg 1 -y 100 -defaultsOSRD
preplace port rst_n -pg 1 -y 130 -defaultsOSRD
preplace inst strip_0 -pg 1 -lvl 1 -y 130 -defaultsOSRD
preplace inst icap_controller_hls_0 -pg 1 -lvl 2 -y 140 -defaultsOSRD
preplace inst icape3_wrapper_0 -pg 1 -lvl 2 -y 340 -defaultsOSRD
preplace netloc icap_controller_hls_0_RDWRB_to_icap_V 1 0 3 60 240 470J 30 1000
preplace netloc strip_0_AVAIL_to_hls 1 1 1 480
preplace netloc icap_controller_hls_0_to_icap_V_V 1 0 3 30 10 NJ 10 1010
preplace netloc strip_0_data_to_hls 1 1 1 480
preplace netloc strip_0_with_ICAP 1 1 1 460
preplace netloc icap_controller_hls_0_CSIB_to_icap_V 1 0 3 30 260 NJ 260 980
preplace netloc strip_0_PRDONE_to_hls 1 1 1 450
preplace netloc clk_1 1 0 2 10 280 490
preplace netloc strip_0_PRERROR_to_hls 1 1 1 440
preplace netloc icap_controller_hls_0_RDWRB_to_icap_V_ap_vld 1 0 3 50 270 NJ 270 1010
preplace netloc ap_rst_n_0_1 1 0 2 20J 20 500J
preplace netloc icap_controller_hls_0_CSIB_to_icap_V_ap_vld 1 0 3 40 250 NJ 250 990
levelinfo -pg 1 -10 250 740 1040 -top 0 -bot 410
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

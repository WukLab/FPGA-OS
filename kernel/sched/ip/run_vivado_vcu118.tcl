# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "generated_vivado_project"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "run_vivado_vcu118.tcl"

# Help information for this script
proc help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/generated_vivado_project"]"

# Create project
create_project -f ${_xil_proj_name_} "./generated_vivado_project" -part xcvu9p-flga2104-2L-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:vcu118:part0:2.0" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "dsa.accelerator_binary_content" -value "bitstream" -objects $obj
set_property -name "dsa.accelerator_binary_format" -value "xclbin2" -objects $obj
set_property -name "dsa.board_id" -value "vcu118" -objects $obj
set_property -name "dsa.description" -value "Vivado generated DSA" -objects $obj
set_property -name "dsa.dr_bd_base_address" -value "0" -objects $obj
set_property -name "dsa.emu_dir" -value "emu" -objects $obj
set_property -name "dsa.flash_interface_type" -value "bpix16" -objects $obj
set_property -name "dsa.flash_offset_address" -value "0" -objects $obj
set_property -name "dsa.flash_size" -value "1024" -objects $obj
set_property -name "dsa.host_architecture" -value "x86_64" -objects $obj
set_property -name "dsa.host_interface" -value "pcie" -objects $obj
set_property -name "dsa.num_compute_units" -value "60" -objects $obj
set_property -name "dsa.platform_state" -value "pre_synth" -objects $obj
set_property -name "dsa.uses_pr" -value "1" -objects $obj
set_property -name "dsa.vendor" -value "xilinx" -objects $obj
set_property -name "dsa.version" -value "0.0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "33" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "33" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "33" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "33" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "33" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "33" -objects $obj
set_property -name "webtalk.xcelium_export_sim" -value "3" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "33" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "48" -objects $obj

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../../generated_ip"]" $obj
update_ip_catalog -rebuild

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
# Import local files from the original project
set files [list \
 [file normalize "${origin_dir}/rtl/strip.v"]\
 [file normalize "${origin_dir}/rtl/icape3.v"]\
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top_auto_set" -value "0" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj


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

make_wrapper -files [get_files ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/icap_controller/icap_controller.bd] -top
add_files -norecurse ${origin_dir}/generated_vivado_project/generated_vivado_project.srcs/sources_1/bd/icap_controller/hdl/icap_controller_wrapper.v

ipx::package_project -root_dir ../../../generated_ip/sched_ip_icap_controller_vcu118 -vendor wuklab -library user -taxonomy UserIP -module icap_controller -import_files

update_ip_catalog -rebuild

puts "INFO: Project created:${_xil_proj_name_}"
exit

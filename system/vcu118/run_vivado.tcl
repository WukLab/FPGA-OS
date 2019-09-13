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
set script_file "run_vivado_pcie.tcl"

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
set orig_proj_dir "[file normalize "$origin_dir/"]"

# Create project
# VCU118 Chip
create_project ${_xil_proj_name_} "./generated_vivado_project" -part xcvu9p-flga2104-2L-e

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
set_property -name "dsa.vendor" -value "xilinx" -objects $obj
set_property -name "dsa.version" -value "0.0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj

# Add IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../../generated_ip"]" $obj
update_ip_catalog -rebuild

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
# Import local files from the original project
set files [list \
 [file normalize "${origin_dir}/rtl/top_pcie_c2h_rdm.v"]\
 [file normalize "${origin_dir}/rtl/top_pcie_c2h_kvs.v"]\
 [file normalize "${origin_dir}/rtl/top_pcie_rdm.v"]\
 [file normalize "${origin_dir}/rtl/top_pcie_kvs.v"]\
 [file normalize "${origin_dir}/rtl/cdc_sync.v"]\
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top_auto_set" -value "0" -objects $obj


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/xdc/top_pcie.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$origin_dir/xdc/top_pcie.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${origin_dir}/tb/top_pcie_rdm_tb.v"] \
 [file normalize "${origin_dir}/tb/top_pcie_kvs_tb.v"] \
 [file normalize "${origin_dir}/tb/rdm/bd_rdm_for_pcie_tb.v"] \
 [file normalize "${origin_dir}/tb/kvs/bd_kvs_for_pcie_tb.v"] \
 [file normalize "${origin_dir}/tb/kvs/output.txt"] \
 [file normalize "${origin_dir}/tb/kvs/input.txt"] \
 [file normalize "${origin_dir}/tb/ddr4_model/MemoryArray.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/StateTableCore.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/StateTable.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/arch_defines.v"] \
 [file normalize "${origin_dir}/tb/ddr4_model/arch_package.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/ddr4_sdram_model_wrapper.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/proj_package.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/timing_tasks.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/ddr4_model.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/ddr4_tb_top.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/interface.sv"] \
 [file normalize "${origin_dir}/tb/ddr4_model/temp_mem.txt"] \
 [file normalize "${origin_dir}/tb/ddr4_model/temp_second_mem.txt"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pci_exp_usrapp_com.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pcie3_uscale_rp_top.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pci_exp_usrapp_pl.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pci_exp_usrapp_cfg.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pci_exp_usrapp_tx.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/xilinx_pcie_uscale_rp.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pcie3_uscale_rp_core_top.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pci_exp_usrapp_rx.v"] \
 [file normalize "${origin_dir}/tb/pcie_rp/pci_exp_expect_tasks.vh"] \
 [file normalize "${origin_dir}/tb/pcie_rp/tests.vh"] \
 [file normalize "${origin_dir}/tb/pcie_rp/board_common.vh"] \
 [file normalize "${origin_dir}/tb/pcie_rp/sample_tests.vh"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset file properties for remote files
set file "$origin_dir/tb/ddr4_model/MemoryArray.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/StateTableCore.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/StateTable.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/arch_defines.v"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/arch_package.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/ddr4_sdram_model_wrapper.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/proj_package.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/timing_tasks.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/ddr4_model.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/ddr4_tb_top.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/tb/ddr4_model/interface.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$origin_dir/tb/pcie_rp/pci_exp_expect_tasks.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/pcie_rp/tests.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/pcie_rp/board_common.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$origin_dir/tb/pcie_rp/sample_tests.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "board" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

#
# Create Block Diagrams
# (On-demand, enable blocks you need.)
#
source scripts/bd_sysclk.tcl
source scripts/bd_sysclk_300.tcl
source scripts/bd_xdma_raw.tcl
source scripts/bd_xdma_c2h_bypass.tcl

#source scripts/bd_KVS_pcie_all.tcl
#source scripts/bd_KVS_pcie_raw.tcl

source scripts/bd_RDM_pcie_all.tcl
source scripts/bd_RDM_pcie_raw.tcl

#source scripts/bd_RDM_seg_pcie_raw.tcl
#source scripts/bd_RDM_KVS_pcie_raw.tcl

puts "INFO: Project created:${_xil_proj_name_}"
exit

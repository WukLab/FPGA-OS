#
# Copyright (c) Yizhou Shan 2019. All rights reserved.
#

proc add_prj { prj } {
   upvar resultDir resultDir
   global srcDir

   if {[file exists $prj]} {
      puts "\tParsing PRJ file: $prj"
      set source [open $prj r]
      set source_data [read $source]
      close $source
      #Remove quotes from PRJ file
      regsub -all {\"} $source_data {} source_data
      set prj_lines [split $source_data "\n" ]
      set line_count 0
      foreach line $prj_lines {
         incr line_count
         #Ignore empty and commented lines
         if {[llength $line] > 0 && ![string match -nocase "#*" $line]} {
            if {[llength $line]!=3} {
               set errMsg "\nERROR: Line $line_count is invalid format. Should be:\n\t<file_type> <library> <file>"
               error $errMsg
            }
            lassign $line type lib file
            if {![string match -nocase $type "dcp"]     && \
                ![string match -nocase $type "xci"]     && \
                ![string match -nocase $type "header"]  && \
                ![string match -nocase $type "system"]  && \
                ![string match -nocase $type "verilog"] && \
                ![string match -nocase $type "vhdl"]} {
               set errMsg "\nERROR: File type $type is not a supported value.\n"
               append errMsg "Supported types are:\n\tdcp\n\txci\n\theader\n\tsystem\n\tverilog\n\tvhdl\n\t"
               error $errMsg
            }
            if {[file exists ${srcDir}/$file]} {
               set file ${srcDir}/$file
               command "add_files $file" "$resultDir/add_files.log"
               if {[string match -nocase $type "vhdl"]} {
                  command "set_property LIBRARY $lib \[get_files $file\]"
               }
               if {[string match -nocase $type "system"]} {
                  command "set_property FILE_TYPE SystemVerilog \[get_files $file\]"
               }
               if {[string match -nocase $type "header"]} {
                   command "set_property FILE_TYPE {Verilog Header} \[get_files $file\]"
                   command "set_property IS_GLOBAL_INCLUDE TRUE \[get_files $file\]"
               }
            } elseif {[file exists $file]} {
               command "add_files $file"
               if {[string match -nocase $type "vhdl"]} {
                  command "set_property LIBRARY $lib \[get_files $file\]"
               }
               if {[string match -nocase $type "system"]} {
                  command "set_property FILE_TYPE SystemVerilog \[get_files $file\]"
               }
               if {[string match -nocase $type "header"]} {
                   command "set_property FILE_TYPE {Verilog Header} \[get_files $file\]"
               }
            } else {
               puts "ERROR: Could not find file \"$file\" on line $line_count."
               set error 1
            }
         }
      }
      if {[info exists error]} {
         set errMsg "\nERROR: Files not found. Check messages for more details.\n"
         error $errMsg
      }
   } else {
      set errMsg "\nERROR: Could not find PRJ file $prj"
      error $errMsg
   }
}

# Add all BD files in list
proc add_bd { files } {
	upvar resultDir resultDir

	foreach file $files {
		if {[string length file] > 0} {
			if {[file exists $file]} {
				if {[regexp {.*\.tcl} $file]} {
				   set argv "$resultDir/bd/"
				   source $file
				   puts "$design_name"
				   generate_target all [get_files $argv/$design_name/$design_name.bd]
				}
			} else {
				set errMsg "\nERROR: Could not find specified BD file: $file" 
				error $errMsg
			}
		}
	}
}

###############################################################
### Add all system Verilog files 
###############################################################
proc add_sysvlog { sysvlog } {
   set files [join $sysvlog]
   foreach file $files {
      if {[file exists $file]} {
         command "add_files $file"
         command "set_property FILE_TYPE SystemVerilog \[get_files $file\]"
      } else {
         puts "ERROR: Could not find file \"$file\"."
         set error 1;
      }
   }
   if {[info exists error]} {
      set errMsg "\nERROR: Files not found. Check messages for more details.\n"
      error $errMsg
   }
}

###############################################################
### Add all Verilog files 
###############################################################
proc add_vlog { vlog } {
   set files [join $vlog]
   foreach file $files {
      if {[file exists $file]} {
         command "add_files $file"
      } else {
         puts "ERROR: Could not find file \"$file\"."
         set error 1;
      }
   }
   if {[info exists error]} {
      set errMsg "\nERROR: Files not found. Check messages for more details.\n"
      error $errMsg
   }
}

###############################################################
### Add all VHDL files 
###############################################################
proc add_vhdl { vhdl } {
   set index 0
   while {$index < [llength $vhdl]} {
      set lib [lindex $vhdl [expr $index+1]]
      foreach file [lindex $vhdl $index] {
         if {[file exists $file]} {
            command "add_files $file"
            command "set_property LIBRARY $lib \[get_files $file\]"
         } else {
            puts "ERROR: Could not find file \"$file\"."
            set error 1;
         }
      }
      set index [expr $index+2]
   }
   if {[info exists error]} {
      set errMsg "\nERROR: Files not found. Check messages for more details.\n"
      error $errMsg
   }
}

proc synthesize { module } {
	global tclParams
	global part
	global board
	global synthDir
	global srcDir
	global verbose
	global RFH

	set moduleName  [get_attribute module $module moduleName]
	set topLevel    [get_attribute module $module top_level]
	set prj         [get_attribute module $module prj]
	set includes    [get_attribute module $module includes]
	set generics    [get_attribute module $module generics]
	set vlogHeaders [get_attribute module $module vlog_headers]
	set vlogDefines [get_attribute module $module vlog_defines]
	set sysvlog     [get_attribute module $module sysvlog]
	set vlog        [get_attribute module $module vlog]
	set vhdl        [get_attribute module $module vhdl]
	set ip          [get_attribute module $module ip]
	set ipRepo      [get_attribute module $module ipRepo]
	set bd          [get_attribute module $module bd]
	set cores       [get_attribute module $module cores]
	set xdc         [get_attribute module $module xdc]
	set synthXDC    [get_attribute module $module synthXDC]
	set options     [get_attribute module $module synth_options]

	set resultDir "$synthDir/$module"

	# Clean-out and re-make the synthesis directory for this module
	command "file mkdir $synthDir"
	command "file delete -force $resultDir"
	command "file mkdir $resultDir"

	# Open local log files
	set rfh [open "$resultDir/run.log" w]
	set cfh [open "$resultDir/command.log" w]
	set wfh [open "$resultDir/critical.log" w]

	set vivadoVer [version]
	puts $rfh "Running Vivado version $vivadoVer"
	puts $rfh "Running synthesis for module: $module"
	puts $rfh "Writing results to: $resultDir"

	set synth_start [clock seconds]

	# Set Tcl Params
	if {[info exists tclParams] && [llength $tclParams] > 0} {
		set_parameters $tclParams
	}

	# Create in-memory project
	command "create_project -in_memory -part $part" "$resultDir/create_project.log"

	# Turn on source management for mod ref
	command "set_property source_mgmt_mode All \[current_project\]"

	if {[info exists board] && [llength $board]} {
		command "set_property board_part $board \[current_project\]"
	}

	# Setup any IP Repositories 
	if {$ipRepo != ""} {
		command "set_property ip_repo_paths \{$ipRepo\} \[current_fileset\]"
		command "update_ip_catalog -rebuild"
	}

	set start_time [clock seconds]
	if {[llength $prj] > 0} {
		add_prj $prj
		set end_time [clock seconds]
		log_time add_prj $start_time $end_time 1 "Process PRJ file"
	} else {
		# Read in System Verilog
		if {[llength $sysvlog] > 0} {
			add_sysvlog $sysvlog
		}

		# Read in Verilog
		if {[llength $vlog] > 0} {
			add_vlog $vlog
		}

		# Read in VHDL
		if {[llength $vhdl] > 0} {
			add_vhdl $vhdl
		}
		set end_time [clock seconds]
		log_time add_files $start_time $end_time 1 "Add source files"
	}

	# Read IP from Catalog
	if {[llength $ip] > 0} {
		add_ip $ip
		set end_time [clock seconds]
		log_time add_ip $start_time $end_time 0 "Add XCI files and generate/synthesize IP"
	}
      
	# Read IPI systems
	if {[llength $bd] > 0} {
		set start_time [clock seconds]
		add_bd $bd
		set end_time [clock seconds]
		log_time add_bd $start_time $end_time 0 "Add/generate IPI block design"
	}
   
   #### Read in IP Netlists 
   if {[llength $cores] > 0} {
      set start_time [clock seconds]
      add_cores $cores
      set end_time [clock seconds]
      log_time add_cores $start_time $end_time 0 "Add synthesized IP (DCP, NGC, EDIF)"
   }
   
   #### Read in synthXDC files
   if {[llength $synthXDC] > 0} {
      set start_time [clock seconds]
      add_xdc $synthXDC 2
      set end_time [clock seconds]
      log_time add_xdc $start_time $end_time 0 "Add synthesis only XDC files"
   }

   #### Read in XDC file
   if {[llength $xdc] > 0} {
      set start_time [clock seconds]
      add_xdc $xdc 1 
      set end_time [clock seconds]
      log_time add_xdc $start_time $end_time 0 "Add XDC files"
   }

   if {[llength $xdc] == 0 && [llength $synthXDC] == 0} {
      puts "Info: No XDC file specified for $module"
   }

   #### Set Verilog Headers 
   if {[llength $vlogHeaders] > 0} {
      foreach file $vlogHeaders {
         command "set_property file_type {Verilog Header} \[get_files $file\]"
      }
   }
   
   #### Set Verilog Defines
   if {$vlogDefines != ""} {
      command "set_property verilog_define \{$vlogDefines\} \[current_fileset\]"
   }
   
   #### Set Include Directories
   if {$includes != ""} {
      command "set_property include_dirs \{$includes\} \[current_fileset\]"
   }
   
   #### Set Generics
   if {$generics != ""} {
      command "set_property generic $generics \[current_fileset\]"
   }
   
	# Synthesis
	puts "Running synth_design for $module"
	set start_time [clock seconds]
	if {$topLevel} {
		command "synth_design -mode default $options -top $moduleName -part $part" "$resultDir/${moduleName}_synth_design.rds"
	} else {
		#command "synth_design -mode out_of_context $options -top $moduleName -part $part" "$resultDir/${moduleName}_synth_design.rds"
		command "synth_design -mode out_of_context $options -top [lindex [find_top] 0] -part $part" "$resultDir/${moduleName}_synth_design.rds"
	}
	set end_time [clock seconds]
	log_time synth_design $start_time $end_time 0 "$moduleName $options"
   
	set start_time [clock seconds]
	command "write_checkpoint -force $resultDir/${moduleName}_synth.dcp" "$resultDir/write_checkpoint.log"
	set end_time [clock seconds]
	log_time write_checkpiont $start_time $end_time 0 "Write out synthesis DCP"
   
	if {$verbose >= 1} {
		set start_time [clock seconds]
		command "report_utilization -file $resultDir/${moduleName}_utilization_synth.rpt"
		set end_time [clock seconds]
		log_time report_utilization $start_time $end_time 0 "Report Synthesis Utilization of $module"
	}

	set synth_end [clock seconds]
	log_time final $synth_start $synth_end
	command "close_project"
	command "puts \"#HD: Synthesis of module $module complete\\n\""
	close $rfh
	close $cfh
	close $wfh
}

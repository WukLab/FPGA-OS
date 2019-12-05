###############################################################
# Find netlist for specified module
###############################################################
proc get_module_file { module } {
   global verbose
   global synthDir
   global ipDir
   global netlistDir
   
   if {![info exists synthDir]} {
      set synthDir "."
   }
   if {![info exists ipDir]} {
      set ipDir "."
   }
   if {![info exists netlistDir]} {
      set netlistDir "."
   }

   set moduleName [get_attribute module $module moduleName]
   set synthDCP   [get_attribute module $module synthCheckpoint]
   set searchFiles [list $synthDCP \
                         $synthDir/$module/${moduleName}_synth.dcp  \
                         $ipDir/$module/${moduleName}.xci           \
                         $netlistDir/$module/${moduleName}.edf      \
                         $netlistDir/$module/${moduleName}.edn      \
                         $netlistDir/$module/${moduleName}.ngc      \
                   ]
   set moduleFile ""
   foreach file $searchFiles {
      if {[file exists $file]} {
         set moduleFile $file
         break
      }
   } 
   if {![llength $moduleFile]} {
      #If verbose==0 to generate scripts only, no file may exist if synthesis has not been run.
      #Instead of erroring in this case, just return default file of $synthDir/...
      if {!$verbose} {
         set moduleFile "$synthDir/$module/${moduleName}_synth.dcp"
         return $moduleFile
      }
      set errMsg "\nERROR: No synthesis netlist or checkpoint file found for $module."
      append errMsg "\nSearched directories:"
      foreach file $searchFiles {
         append errMsg "\t$file\n"
      }
      error $errMsg
   }
   return $moduleFile
}

###############################################################
# Generate Partial ICAP/PCAP formated BIN files
# Must have Partial Bitstreams already generated
###############################################################
proc generate_pr_binfiles { config } {
   upvar bitDir bitDir

   set top           [get_attribute impl $config top]
   set partitions    [get_attribute impl $config partitions]
   set icap          [get_attribute impl $config cfgmem.icap]
   set pcap          [get_attribute impl $config cfgmem.pcap]
   set offset        [get_attribute impl $config cfgmem.offset]
   set size          [get_attribute impl $config cfgmem.size]
   set interface     [get_attribute impl $config cfgmem.interface]
   if {$icap || $pcap} {
      foreach partition $partitions {
         lassign $partition module cell state name type level dcp
         if {![llength $name]} {
            set name [lindex [split $cell "/"] end]
         }
         if {![string match $cell $top]} {
            set pblock [get_pblocks -quiet -of [get_cells $cell]]
            if {[string match "greybox" $state]} {
               set bitName "${pblock}_greybox_partial"
            } else {
               set bitName "${pblock}_${module}_partial"
            }
            set bitFile "$bitDir/${bitName}.bit"
            if {![file exists $bitFile]} {
               puts "\tCritical Warning: No bit file found for $cell ($module) in configuration $config. Skipping BIN file generation. Expected file \n\t$bitFile.\n\tRun write_bitstream first to generate the expected file."
               return 
            }
            if {$icap} {
               set logFile "$bitDir/write_cfgmem_${config}_${name}_icap.log"
               set msg "\t#HD: Generating ICAP formatted BIN file for $name of Configuration $config"
               command "puts \"$msg\""
               set start_time [clock seconds]
               set binFile "$bitDir/${config}_${pblock}_partial_icap.bin"
               #command "write_cfgmem -force -format BIN -interface $interface -loadbit \"$offset $bitFile\" -size $size $binFile" $logFile
               command "write_cfgmem -force -format BIN -interface $interface -loadbit \"$offset $bitFile\" $binFile" $logFile
               set end_time [clock seconds]
               log_time write_cfgmem $start_time $end_time 1 "Generate ICAP format bin file for ${config}(${name})"
            }
            if {$pcap} {
               set logFile "$bitDir/write_cfgmem_${config}_${name}_pcap.log"
               set msg "\t#HD: Generating PCAP formatted BIN file for $name of Configuration $config"
               command "puts \"$msg\""
               set start_time [clock seconds]
               set binFile "$bitDir/${config}_${pblock}_partial_pcap.bin"
               #command "write_cfgmem -force -format BIN -interface $interface -disablebitswap -loadbit \"$offset $bitFile\" -size $size $binFile" $logFile 
               command "write_cfgmem -force -format BIN -interface $interface -disablebitswap -loadbit \"$offset $bitFile\" $binFile" $logFile 
               set end_time [clock seconds]
               log_time write_cfgmem $start_time $end_time 1 "Generate PCAP format bin file for ${config}(${name})"
            }
         }
      }
   } else {
      puts "\tINFO: Skipping partial BIN file generation for Configuration $config."
   }
}

###############################################################
# Genearte Partial Bitstreams  
###############################################################
proc generate_pr_bitstreams { configs } {
   global dcpDir bitDir implDir

   #Set a default directory to write bitstreams if not already defined
   if {![info exists bitDir]} {
      set bitDir "./Bitstreams"
   }

   #command "file delete -force $bitDir"
   if {![file exists $bitDir]} {
      command "file mkdir $bitDir"
   }

   foreach config $configs {
      set top               [get_attribute impl $config top]
      set partitions        [get_attribute impl $config partitions]
      set post_phys         [get_attribute impl $config post_phys]
      set bitstream         [get_attribute impl $config bitstream]
      set bitstream.pre     [get_attribute impl $config bitstream.pre]
      set bitOptions        [get_attribute impl $config bitstream_options]
      set bitSettings       [get_attribute impl $config bitstream_settings]
      set partialOptions    [get_attribute impl $config partial_bitstream_options]
      set partialSettings   [get_attribute impl $config partial_bitstream_settings]
      if {$bitstream} {
         set start_time [clock seconds]
         set msg "\t#HD: Running write_bitstream on $config"
         command "puts \"$msg\""
         set logFile "$bitDir/write_bitstream_${config}.log"
         if {$post_phys} {
            set configFile "$implDir/$config/${top}_post_phys_opt.dcp"
         } else {
            set configFile "$implDir/$config/${top}_route_design.dcp"
         }
         if {[file exists $configFile]} {
            command "open_checkpoint $configFile" "$bitDir/open_checkpoint_$config.log"

            #Run any pre.hook scripts for write_bitstream
            foreach script ${bitstream.pre} {
               if {[file exists $script]} {
                  puts "\t#HD: Running pre-bitstream script $script"
                  command "source $script" "$bitDir/pre_bitstream_script.log"
               } else {
                  set errMsg "\nERROR: Script $script specified for pre-bitstream does not exist"
                  error $errMsg
               }
            }

            #Apply config settings for full bit file
            foreach setting $bitSettings {
               puts "\tSetting property $setting"
               command "set_property $setting \[current_design\]"
            }
            #Generate full Bitstream
            foreach partition $partitions {
               lassign $partition module cell state name type level dcp
               if {[string match $cell $top]} {
                  #Generate full bitstream only
                  command "write_bitstream -force $bitOptions $bitDir/${config}_full -no_partial_bitfile" "$bitDir/${config}_full.log"
               }
            }

            #Check for dbg_hub in Static and write out probes
            if {[llength [get_cells -quiet -hier -filter REF_NAME==dbg_hub_CV]]} {
               command "write_debug_probes -force -no_partial_ltxfile $bitDir/${config}_full.ltx" "$bitDir/write_debug_probes_$config.log"
            }

            #Apply any partial specfic config settings (ie. compression)
            foreach setting $partialSettings {
               puts "\tSetting property $setting"
               command "set_property $setting \[current_design\]"
            }
            #Check for specific options for partial bit files. Otherwise default to full settings.
            if {[llength $partialOptions]} {
               set bitOptions $partialOptions
            }
            #Generate partials using -cell for better naming
            foreach partition $partitions {
               lassign $partition module cell state name type level dcp
               if {![string match $cell $top]} {
                  set pblock [get_pblocks -quiet -of [get_cells $cell]]
                  if {[string match "greybox" $state]} {
                     set bitName "${pblock}_greybox_partial"
                  } else {
                     set bitName "${pblock}_${module}_partial"
                  }
                  command "write_bitstream -force $bitOptions -cell $cell $bitDir/$bitName" "$bitDir/$bitName.log"
                  #Check for dbg_bridge in RM and write out probes
                  if {[llength [get_cells -quiet -hier -filter "REF_NAME=~debug_bridge* && NAME=~$cell/*"]]} {
                     command "write_debug_probes -force -cell $cell $bitDir/${bitName}.ltx" "$bitDir/write_debug_probes_$module.log"
                  }
               }
            }
         } else {
            puts "\tInfo: Skipping write_bitstream for configuration $config because the file \'$configFile\' could not be found."
            continue
         }

         set end_time [clock seconds]
         log_time write_bitstream $start_time $end_time 1 $config
         generate_pr_binfiles $config 
         command "close_project" "$bitDir/temp.log"
      } else {
         puts "\tSkipping write_bitstream for Configuration $config with attribute \"bitstream\" set to \'$bitstream\'"
      }
   }
}

###############################################################
# Verify all configurations 
###############################################################
proc verify_configs { configs } {
   global implDir

   set configNames ""
   set configFiles ""
   foreach config $configs {
      set verify [get_attribute impl $config verify]
      set post_phys [get_attribute impl $config post_phys]
      #Check if configuration has verify attribute set
      if {$verify} {
         set configTop [get_attribute impl $config top]
         if {$post_phys} {
            set configFile $implDir/$config/${configTop}_post_phys_opt.dcp
         } else {
            set configFile $implDir/$config/${configTop}_route_design.dcp
         }
         #Even with verify set, check if routed DCP exists before adding to the list to be verified
         if {[file exists $configFile]} {
            lappend configFiles $configFile
            lappend configNames $config
         } else {
            puts "\tInfo: Skipping Configuration $config with attribute \"verify\" to \'$verify\' because file \'$configFile\' cannot be found."
         }
      } else {
         puts "\tInfo: Skipping Configuration $config with attribute \"verify\" set to \'$verify\'"
      }
   }
   
   if {[llength $configFiles] > 1} {
      set start_time [clock seconds]
      set initialConfig [lindex $configNames 0]
      set initialConfigFile [lindex $configFiles 0]
      set additionalConfigs [lrange $configNames 1 end]
      set additionalConfigFiles [lrange $configFiles 1 end]
      set msg "#HD: Running pr_verify between initial Configuration \'$initialConfig\' and subsequent configurations \'$additionalConfigs\'"
      command "puts \"$msg\""
      set logFile "pr_verify_results.log"
      command "pr_verify -full_check -initial $initialConfigFile -additional \{$additionalConfigFiles\}" $logFile
      #Parse log file for errors or successful results
      if {[file exists $logFile]} {
         set lfh [open $logFile r]
         set log_data [read $lfh]
         close $lfh
         set log_lines [split $log_data "\n" ]
         foreach line $log_lines {
            if {[string match "*Vivado 12-3253*" $line] || [string match "*ERROR:*" $line]} {
               puts "$line"
            }
         }
      }
      set end_time [clock seconds]
      log_time pr_verify $start_time $end_time 1 "[llength $configs] Configurations"
   }
}

###############################################################
# Add all XDC files in list, and mark as OOC if applicable
###############################################################
proc add_xdc { xdc {synth 0} {cell ""} } {
   #Flatten list if nested lists exist
   set files [join [join $xdc]]
   foreach file $files {
      if {[file exists $file]} {
         puts "\t#HD: Adding 'xdc' file $file"
         command "add_files $file"
         set file_split [split $file "/"]
         set fileName [lindex $file_split end]
         if { $synth ==2 || [string match "*synth*" $fileName] } { 
            if {[string match "*ooc*" $fileName]} {
               command "set_property USED_IN {synthesis out_of_context} \[get_files $file\]"
            } else {
               command "set_property USED_IN {synthesis} \[get_files $file\]"
            }
         } elseif { $synth==1 } {
            if {[string match "*ooc*" $fileName]} {
               command "set_property USED_IN {synthesis implementation out_of_context} \[get_files $file\]"
            } else {
               command "set_property USED_IN {synthesis implementation} \[get_files $file\]"
            }
         } else {
            if {[string match "*ooc*" $fileName]} {
               command "set_property USED_IN {implementation out_of_context} \[get_files $file\]"
            } else {
               command "set_property USED_IN {implementation} \[get_files $file\]"
            }
         }

         if {[llength $cell]} {
            #Check if this file is already scoped to another partition
            if {[llength [get_property SCOPED_TO_CELLS [get_files $file]]]} {
               set cells [get_property SCOPED_TO_CELLS [get_files $file]]
               lappend cells $cell
               command "set_property SCOPED_TO_CELLS \{$cells\} \[get_files $file\]"
            } else {
               command "set_property SCOPED_TO_CELLS \{$cell\} \[get_files $file\]"
            }
         }

         #Set all partition scoped XDC to late by default. May need to review.
         if {[string match "*late*" $fileName] || [llength $cell]} {
            command "set_property PROCESSING_ORDER late \[get_files $file\]"
         } elseif {[string match "*early*" $fileName]} {
            command "set_property PROCESSING_ORDER early \[get_files $file\]"
         }
      } else {
         set errMsg "\nERROR: Could not find specified XDC: $file" 
         error $errMsg 
      }
   }
}

###############################################################
# A proc to read in XDC files post link_design 
###############################################################
proc readXDC { xdc {cell ""} } {
   upvar resultDir resultDir

   puts "\tReading XDC files"
   #Flatten list if nested lists exist
   set files [join [join $xdc]]
   foreach file $files {
      if {[file exists $file]} {
         if {![llength $cell]} {
            command "read_xdc $file" "$resultDir/read_xdc.log"
         } else {
            command "read_xdc -cell $cell $file" "$resultDir/read_xdc_cell.log"
         }
      } else {
         set errMsg "\nERROR: Could not find specified XDC: $file" 
         error $errMsg 
      }
   }
}

###############################################################
### Add all XCI files in list
###############################################################
proc add_ip { ips } {
   global verbose
   upvar resultDir resultDir

   foreach ip $ips {
      if {[string length ip] > 0} { 
         if {[file exists $ip]} {
            set ip_split [split $ip "/"] 
            set xci [lindex $ip_split end]
            set ipPathList [lrange $ip_split 0 end-1]
            set ipPath [join $ipPathList "/"]
            set ipName [lindex [split $xci "."] 0]
            set ipType [lindex [split $xci "."] end]
            puts "\t#HD: Adding \'$ipType\' file $xci"
            command "add_files $ipPath/$xci" "$resultDir/${ipName}_add.log"
            if {[string match $ipType "bd"] || $verbose==0} {
               return
            }
            if {[get_property GENERATE_SYNTH_CHECKPOINT [get_files $ipPath/$xci]]} {
               if {![file exists $ipPath/${ipName}.dcp]} {
                  puts "\tSynthesizing IP $ipName"
                  command "synth_ip \[get_files $ipPath/$xci]" "$resultDir/${ipName}_synth.log"
               }
            } else {
               puts "\tGenerating output for IP $ipName"
               command "generate_target all \[get_ips $ipName]" "$resultDir/${ipName}_generate.log"
            }
         } else {
            set errMsg "\nERROR: Could not find specified IP file: $ip" 
            error $errMsg
         }
      }
   }
}

###############################################################
# Add all core netlists in list 
###############################################################
proc add_cores { cores } {
   #Flatten list if nested lists exist
   set files [join [join $cores]]
   foreach file $files {
      if {[string length $file] > 0} { 
         if {[file exists $file]} {
            #Comment this out to prevent adding files 1 at a time. Add all at once instead.
            puts "\t#HD: Adding core file $file"
            command "add_files $file"
         } else {
            set errMsg "\nERROR: Could not find specified core file: $file" 
            error $errMsg
         }
      }
   }
}

#==============================================================
# TCL proc for running DRC on post-route_design to catch 
# Critical Warnings. These will be errors in write_bitstream. 
# Catches unroutes, antennas, etc. 
#==============================================================
proc check_drc { module {ruleDeck default} {quiet 0} } {
   upvar reportDir reportDir

   if {[info exists reportDir]==0} {
      set reportDir "."
   }
   puts "\t#HD: Running report_drc with ruledeck $ruleDeck.\n\tResults saved to $reportDir/${module}_drc_$ruleDeck.rpt" 
   command "report_drc -ruledeck $ruleDeck -name $module -file $reportDir/${module}_drc_$ruleDeck.rpt" "$reportDir/temp.log"
   set Advisories   [get_drc_violations -quiet -name $module -filter {SEVERITY=~"Advisory"}]
   set Warnings     [get_drc_violations -quiet -name $module -filter {SEVERITY=~"Warning"}]
   set CritWarnings [get_drc_violations -quiet -name $module -filter {SEVERITY=~"Critical Warning"}]
   set Errors       [get_drc_violations -quiet -name $module -filter {SEVERITY=~"Error"}]
   puts "\tAdvisories: [llength $Advisories]; Warnings: [llength $Warnings]; Critical Warnings: [llength $CritWarnings]; Errors: [llength $Errors];"

   if {[llength $Errors]} {
      if {!$quiet} {
         set errMsg "\nERROR: DRC found [llength $Errors] errors ($Errors)."
      } else {
         puts "\tCritical Warning: DRC found [llength $Errors] errors ($Errors)."
      }
      foreach error $Errors {
         puts "\n\t${error}: [get_property DESCRIPTION [get_drc_violations -name $module $error]]"
      }
      #Stop the script for Errors, unless user specifies quiet as true
      if {!$quiet} {
         error $errMsg
      }
   }

   if {[llength $CritWarnings]} {
      if {!$quiet} {
         set errMsg "\nERROR: DRC found [llength $CritWarnings] Critical Warnings ($CritWarnings)."
      } else {
         puts "\tCritical Warning: DRC found [llength $CritWarnings] Critical Warnings ($CritWarnings)."
      }
      foreach cw $CritWarnings {
         puts "\n\t${cw}: [get_property DESCRIPTION [get_drc_violations -name $module $cw]]"
      }
      #Stop the script for Critcal Warnings, unless user specifies quiet as true
      if {!$quiet} {
         error $errMsg
      }
   }
}

#==============================================================
# TCL proc for print out rule information for given ruledecks 
# Use get_drc_ruledecks to list valid ruledecks
#==============================================================
proc printRuleDecks { {decks ""} } {
   if {[llength $decks]} {
      set rules [get_drc_checks -of [get_drc_ruledecks $decks]]
      foreach rule $rules {
         set name [get_property NAME [get_drc_checks $rule]]
         set description [get_property DESCRIPTION [get_drc_checks $rule]]
         set severity [get_property SEVERITY [get_drc_checks $rule]]
         puts "\t${name}(${severity}): ${description}"
      }
   } else {
      puts "Rule Decks:\n\t[join [get_drc_ruledecks] "\n\t"]"
   }
}

#==============================================================
# TCL proc for print out rule information for given rules
#==============================================================
proc printRules { rules } {
   foreach rule $rules {
      set name [get_property NAME [get_drc_checks $rule]]
      set description [get_property DESCRIPTION [get_drc_checks $rule]]
      set severity [get_property SEVERITY [get_drc_checks $rule]]
      puts "\t${name}(${severity}): $description"
   }
}

#==============================================================
# FOR TESTING ONLY!!!!
# TCL proc to Detect and fix unsafe timing paths to temporarily
# clean up incorretly constrained design.
#==============================================================
proc fix_timing {} {
   set clk_intr [split [report_clock_interaction -return_string] \n]
   foreach line $clk_intr {
      if { [regexp {^(\S+)\s+(\S+)\s+\S+.*Timed \(unsafe\).*} $line full src dst]} {
         set_false_path -from [get_clocks $src] -to [get_clocks $dst]
      }
   }
}

proc impl_step {phase instance {options none} {directive none} {pre none} {settings none} } {
   global dcpLevel
   global verbose
   upvar  impl impl 
   upvar  resultDir resultDir
   upvar  reportDir reportDir

   #Make sure $phase is valid and set checkpoint in case no design is open
   if {[string match $phase "opt_design"]} {
      set checkpoint1 "$resultDir/${instance}_link_design.dcp"
   } elseif {[string match $phase "place_design"]} {
      set checkpoint1 "$resultDir/${instance}_opt_design.dcp"
   } elseif {[string match $phase "phys_opt_design"]} {
      set checkpoint1 "$resultDir/${instance}_place_design.dcp"
   } elseif {[string match $phase "route_design"]} {
      set checkpoint1 "$resultDir/${instance}_phys_opt_design.dcp"
      set checkpoint2 "$resultDir/${instance}_place_design.dcp"
   } elseif {[string match $phase "post_phys_opt"]} {
      set checkpoint1 "$resultDir/${instance}_route_design.dcp"
   } elseif {[string match $phase "write_bitstream"]} {
      set checkpoint1 "$resultDir/${instance}_post_phys_opt.dcp"
      set checkpoint2 "$resultDir/${instance}_route_design.dcp"
   } else {
      set errMsg "\nERROR: Value $phase is not a recognized step of implementation. Valid values are \"opt_design\", \"place_design\", \"phys_opt_design\", or \"route_design\"."
      error $errMsg
   }
   #If no design is open
   if { [catch {current_instance > $resultDir/temp.log} errMsg] && $verbose > 0 } {
      puts "\tNo open design" 
      if {[info exists checkpoint1] || [info exists checkpoint2]} {
         if {[file exists $checkpoint1]} {
            puts "\tOpening checkpoint $checkpoint1 for $instance"
            command "open_checkpoint $checkpoint1" "$resultDir/open_checkpoint_${instance}_$phase.log"
            if { [catch {current_instance > $resultDir/temp.log} errMsg] } {
               command "link_design"
            }
         } elseif {[file exists $checkpoint2]} {
            puts "\tOpening checkpoint $checkpoint2 for $instance"
            command "open_checkpoint $checkpoint2" "$resultDir/open_checkpoint_${instance}_$phase.log"
            if { [catch {current_instance > $resultDir/temp.log} errMsg] } {
               command "link_design"
            }
         } else {
            set errMsg "\nERROR: Checkpoint file not found. Please rerun necessary steps."
            error $errMsg
         }
      } else {
        set errMsg "\nERROR: No checkpoint defined."
        error $errMsg
      }
   }
  
   #Run any specified pre-phase scripts
   if {![string match $pre "none"] && ![string match $pre ""] } {
      foreach script $pre {
         if {[file exists $script]} {
            puts "\t#HD: Running pre-$phase script $script"
            command "source $script" "$resultDir/pre_${phase}_script.log"
         } else {
            set errMsg "\nERROR: Script $script specified for pre-${phase} does not exist"
            error $errMsg
         }
      }
   }
 
   #Append options or directives to command
   if {[string match $phase "write_bitstream"]} {
      set impl_step "$phase -force -file $resultDir/$instance"
   } elseif {[string match $phase "post_phys_opt"]} {
      set impl_step "phys_opt_design"
   } else {
      set impl_step $phase
   }

   if {[string match $options "none"]==0 && [string match $options ""]==0} {
      append impl_step " $options"
   }
   if {[string match $directive "none"]==0 && [string match $directive ""]==0} {
      append impl_step " -directive $directive"
   }
   if {[string match $settings "none"]==0 && [string match $settings ""]==0} {
      foreach setting $settings {
         puts "\tSetting property $setting"
         command "set_property $setting \[current_design]"
      }
   }

   #Run the specified Implementation phase
   puts "\n\t#HD: Running $impl_step for $impl"

   set log "$resultDir/${instance}_$phase.log"
   puts "\tWriting Results to $log"

   set start_time [clock seconds]
   puts "\t$phase start time: \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
   command "$impl_step" "$log"
   set end_time [clock seconds]
   log_time $phase $start_time $end_time 0 "$impl_step" 
   command "puts \"\t#HD: Completed: $phase\""
   puts "\t################################"
      
   #Write out checkpoint for successfully completed phase
   if {($dcpLevel > 0 || [string match $phase "route_design"]) && ![string match $phase "write_bitstream"]} {
      set start_time [clock seconds]
      puts "\tWriting post-$phase checkpoint: $resultDir/${instance}_$phase.dcp \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]\n"
      command "write_checkpoint -force $resultDir/${instance}_$phase.dcp" "$resultDir/write_checkpoint.log"
      set end_time [clock seconds]
      log_time write_checkpoint $start_time $end_time 0 "Post-$phase checkpoint"
   }

   #Write out additional reports controled by verbose level
   if {$verbose > 1 || [string match $phase "route_design"]} {
      set start_time [clock seconds]
      command "report_utilization -file $reportDir/${instance}_utilization_${phase}.rpt" "$resultDir/temp.log"
      set end_time [clock seconds]
      log_time report_utilization $start_time $end_time
   }

   if {[string match $phase "route_design"]} {
      set start_time [clock seconds]
      command "report_route_status -file $reportDir/${instance}_route_status.rpt" "$resultDir/temp.log"
      set end_time [clock seconds]
      log_time report_route_status $start_time $end_time
   }
}

proc implement {impl} {
	global tclParams 
	global board
	global part
	global dcpLevel
	global verbose
	global implDir
	global xdcDir
	global dcpDir
	global RFH

	set top                 [get_attribute impl $impl top]
	set name                [get_attribute impl $impl name]
	set implXDC             [get_attribute impl $impl implXDC]
	set cellXDC             [get_attribute impl $impl cellXDC]
	set cores               [get_attribute impl $impl cores]
	set ip                  [get_attribute impl $impl ip]
	set ipRepo              [get_attribute impl $impl ipRepo]
	set hd                  [get_attribute impl $impl hd.impl]
	set pr                  [get_attribute impl $impl pr.impl]
	set hd.budget           [get_attribute impl $impl hd.budget]
	set budgetExclude       [get_attribute impl $impl hd.budget_exclude]
	set partitions          [get_attribute impl $impl partitions]
	set link                [get_attribute impl $impl link]
	set opt                 [get_attribute impl $impl opt]
	set opt.pre             [get_attribute impl $impl opt.pre]
	set opt_options         [get_attribute impl $impl opt_options]
	set opt_directive       [get_attribute impl $impl opt_directive]
	set place               [get_attribute impl $impl place]
	set place.pre           [get_attribute impl $impl place.pre]
	set place_options       [get_attribute impl $impl place_options]
	set place_directive     [get_attribute impl $impl place_directive]
	set phys                [get_attribute impl $impl phys]
	set phys.pre            [get_attribute impl $impl phys.pre]
	set phys_options        [get_attribute impl $impl phys_options]
	set phys_directive      [get_attribute impl $impl phys_directive]
	set route               [get_attribute impl $impl route]
	set route.pre           [get_attribute impl $impl route.pre]
	set route_options       [get_attribute impl $impl route_options]
	set route_directive     [get_attribute impl $impl route_directive]
	set post_phys           [get_attribute impl $impl post_phys]
	set post_phys.pre       [get_attribute impl $impl post_phys.pre]
	set post_phys_options   [get_attribute impl $impl post_phys_options]
	set post_phys_directive [get_attribute impl $impl post_phys_directive]
	set bitstream           [get_attribute impl $impl bitstream]
	set bitstream.pre       [get_attribute impl $impl bitstream.pre]
	set bitstream_options   [get_attribute impl $impl bitstream_options]
	set bitstream_settings  [get_attribute impl $impl bitstream_settings]
	set drc.quiet           [get_attribute impl $impl drc.quiet]

	#if {($hd && $pr)} {
	#	set errMsg "\nERROR: Implementation $impl has more than one of the following flow variables set to 1"
	#	append errMsg "\n\thd.impl($hd)\n\tpr.impl($pr)\n"
	#	append errMsg "Only one of these variables can be set true at one time. To run multiple flows, create separate implementation runs."
	#	error $errMsg
	#}

	set resultDir "$implDir/$impl"
	set reportDir "$resultDir/reports"

	command "file mkdir $implDir"
	command "file delete -force $resultDir"
	command "file mkdir $resultDir"
	command "file mkdir $reportDir"
   
	# Open local log files
	set rfh [open "$resultDir/run.log" w]
	set cfh [open "$resultDir/command.log" w]
	set wfh [open "$resultDir/critical.log" w]

	set vivadoVer [version]
	puts $rfh "Info: Running Vivado version $vivadoVer"

	command "puts \"#HD: Running implementation $impl\""
	puts "\tWriting results to: $resultDir"
	puts "\tWriting reports to: $reportDir"
	puts $rfh "\n#HD: Running implementation $impl"
	puts $rfh "Writing results to: $resultDir"
	puts $rfh "Writing reports to: $reportDir"
	puts $RFH "\n#HD: Running implementation $impl"
	puts $RFH "Writing results to: $resultDir"
	puts $RFH "Writing reports to: $reportDir"
	set impl_start [clock seconds]

	# Set Tcl Params
	if {[info exists tclParams] && [llength $tclParams] > 0} {
		set_parameters $tclParams
	}

	# Create in-memory project
	command "create_project -in_memory -part $part" "$resultDir/create_project.log"
	if {[info exists board] && [llength $board]} {
		command "set_property board_part $board \[current_project\]"
	}   

	# Setup any IP Repositories 
	if {$ipRepo != ""} {
		command "set_property ip_repo_paths \{$ipRepo\} \[current_fileset\]"
		command "update_ip_catalog -rebuild"
	}

	# Linking
	if {$link} {
		# Determine state of Top (import or implement). 
		set topState "implement"
		foreach partition $partitions {
			lassign $partition module cell state name type level dcp
			if {[string match $cell $top]} {
				set topState $state 
				if {[llength $dcp]} {
					set topFile $dcp
				}
			}
		}

		 # If DCP for top is not defined in Partition settings, try and find it.
		 if {![info exist topFile] || ![llength $topFile]} {
			 foreach module [get_modules] {
			 	set moduleName [get_attribute module $module moduleName]
			 	if {[string match $top $moduleName]} {
					break
				}
			 }

			 if {[string match $topState "implement"]} {
			 	set topFile [get_module_file $module]
			 } elseif {[string match $topState "import"]} {
				 if {$pr} {
				 	set topFile "$dcpDir/${top}_static.dcp"
				 } else {
				 	set topFile "$dcpDir/${top}_routed.dcp"
				 }
			 } else {
			 	set errMsg "\nERROR: State of Top module $top is set to illegal state $topState." 
			 	error $errMsg
			 }
		 }

		# Add file if it exists, or if $verbose=0 for testing
		if {[file exists $topFile] || !$verbose} {
			set type [lindex [split $topFile .] end]
			puts "\t#HD: Adding \'$type\' file $topFile for $top"
			command "add_files $topFile"
		} else {
			set errMsg "\nERROR: Specified file $topFile cannot be found on disk. Verify path is correct, and that all dependencies have been run." 
			error $errMsg
		}

		# Read in top-level cores/ip/XDC if Top is being implemented
		# All Partition core/ip/XDC should be defined as Module attributes
		if {[string match $topState "implement"]} { 
			# Read in IP Netlists 
			if {[llength $cores] > 0} {
				add_cores $cores
			}
			# Read IP XCI files
			if {[llength $ip] > 0} {
				add_ip $ip
			}

			# Read in XDC files
			if {[llength $implXDC] > 0} {
				if {[string match $topState "implement"]} {
					add_xdc $implXDC
				} else {
					puts "\tInfo: Skipping top-level XDC files because $top is set to $topState."
				}
			} else {
				puts "\tWarning: No top-level XDC files were specified."
			}
		}

		# Always read in RP/RM specific XDC files
		if {[llength $cellXDC] > 0} {
			foreach data $cellXDC {
				lassign $data cell xdc 
				puts "\tAdding scoped XDC files for $cell"
				add_xdc $xdc 0 $cell
			}
		}

		# Read in Partition netlist, cores, ip, and XDC if module is being implemented
		foreach partition $partitions {
		   lassign $partition module cell state name type level dcp
		   if {![llength $name]} {
		      set name [lindex [split $cell "/"] end]
		   }

		   if {![string match "greybox" $state]} {
		      set moduleName [get_attribute module $module moduleName]
		   } else {
		      set moduleName $module
		   }

		   #Process each partition that is not Top. Ignore greybox Partitions
		   if {![string match $moduleName $top] && ![string match "greybox" $state]} {
		      #Find correct file to be used for Partition
		      if {[llength $dcp] && ![string match $state "greybox"]} {
			 set partitionFile $dcp
		      } else {
			 #if partition has state=implement, load synth netlist
			 if {[string match $state "implement"]} {
			    set partitionFile [get_module_file $module]
			 } elseif {[string match $state "import"]} {
			    #TODO: Name used to be based on Pblock to uniquify. Now no open design with new link_design flow,
			    #      so no way to query Pblock name. This code will not work if RPs have same name at the end of hierarchy.
			    #      Project flow names these cell DCPs based of full hierachy name, which can have issues of its own
			    #      if the hierarchy name is very long.  Need to revisit to develop a solution.
			    set partitionFile "$dcpDir/${name}_${module}_route_design.dcp"
			 } else {
			    set errMsg "\nERROR: Invalid state \"$state\" in settings for $name\($impl)."
			    append errMsg"Valid states are \"implement\", \"import\", or \"greybox\".\n" 
			    error $errMsg
			 }

		      }
		      #Add the partition source file to the in-memory project
		      if {![file exists $partitionFile] && $verbose} {
			 set errMsg "ERROR: Partition \'$cell\' with state \'$state\' is set to use the file:\n$partitionFile\n\nThis file does not exist."
			 error $errMsg
		      }
		      set fileSplit [split $partitionFile "."]
		      set fileType [lindex $fileSplit end]
		      set start_time [clock seconds]
		      puts "\tAdding file $partitionFile for $cell ($module) \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
		      command "add_file $partitionFile"
		      #Check if file is an XCI. SCOPED_TO_CELLS not supported for XCI
		      if {![string match [lindex [split $partitionFile .] end] "xci"]} {
			 #Check if this file is already scoped to another partition
			 if {[llength [get_property SCOPED_TO_CELLS [get_files $partitionFile]]]} {
			    set cells [get_property SCOPED_TO_CELLS [get_files $partitionFile]]
			    lappend cells $cell
			    command "set_property SCOPED_TO_CELLS \{$cells\} \[get_files $partitionFile\]"
			 } else {
			    command "set_property SCOPED_TO_CELLS \{$cell\} \[get_files $partitionFile\]"
			 }
		      }

		      #Add Module specific implementation sources   
		      if {[string match $state "implement"]} { 
			 #Read in Module IP if module is not imported or greybox
			 set moduleIP [get_attribute module $module ip]
			 if {[llength $moduleIP] > 0} {
			    puts "\tAdding module ip files for $cell ($module)"
			    add_ip $moduleIP
			 }

			 #Read in Module cores if module is not imported or greybox
			 set moduleCores [get_attribute module $module cores]
			 if {[llength $moduleCores] > 0} {
			    puts "\tAdding module core files for $cell ($module)"
			    add_cores $moduleCores
			 }
		      }

			 #Read in scoped module impl XDC even if module is imported since routed cell DCPs won't have timing constraints
			 set implXDC [get_attribute module $module implXDC]
			 if {[llength $implXDC] > 0} {
			    puts "\tAdding scoped XDC files for $cell"
			    add_xdc $implXDC 0 $cell
			 } else {
			    puts "\tInfo: No scoped XDC files specified for $cell"
			 }
		   }; #End: Process each partition that is not Top and not greybox
		}; #End: Foreach partition

		###########################################################
		# Link the top-level design with no black boxes (unless greybox) 
		###########################################################
		set start_time [clock seconds]
		puts "\t#HD: Running link_design for $top \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
		set partitionCells ""
		foreach partition $partitions {
			lassign $partition module cell state name type level dcp
			if {![string match $cell $top]} {
				lappend partitionCells $cell
			}
		}

		if {$pr} {
		   set linkCommand "link_design -mode default -reconfig_partitions \{$partitionCells\} -part $part -top $top"
		   command $linkCommand "$resultDir/${top}_link_design.log"
		} elseif {$hd} {
		   set linkCommand "link_design -mode default -partitions \{$partitionCells\} -part $part -top $top"
		   command $linkCommand "$resultDir/${top}_link_design.log"
		} else {
		   set linkCommand "link_design -mode default -part $part -top $top"
		   command $linkCommand "$resultDir/${top}_link_design.log"
		}
		set end_time [clock seconds]
		log_time link_design $start_time $end_time 1 $linkCommand
	   
	   ##############################################
	   # Process Grey Box Partitions 
	   ##############################################
	   foreach partition $partitions {
	      lassign $partition module cell state name type level dcp
	      if {![llength $name]} {
		 set name [lindex [split $cell "/"] end]
	      }

	      if {![string match "greybox" $state]} {
		 set moduleName [get_attribute module $module moduleName]
	      } else {
		 set moduleName $module
	      }
	      if {![string match $moduleName $top]} {
		 if {[string match "greybox" $state]} {
		    #If any greybox partition exist, need to run post-route DRC check in quiet mode
		    set drc.quiet 1

		    #Process greybox partitions. Name can be random, so just grab name from partition def.
		    puts "\tInfo: Cell $cell will be implemented as a grey box."
		    set partitionFile "NA"

		    #Insert LUT1 for greybox partition
		    if {$verbose && ![get_property IS_BLACKBOX [get_cells $cell]]} {
		       set start_time [clock seconds]
		       puts "\tCritical Warning: Partition cell \'$cell\' is not a blackbox. This likely occurred because OOC synthesis was not used. This can cause illegal optimization. Please verify it is intentional that this cell is not a blackbox at this stage in the flow.\nResolution: Caving out cell to make required blackbox. \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
		       command "update_design -cells $cell -black_box" "$resultDir/update_design_blackbox_$name.log"
		       set end_time [clock seconds]
		       log_time update_design $start_time $end_time 0 "Create blackbox for $name"
		    }
		    command "set_msg_config -quiet -id \"Constraints 18-514\" -suppress"
		    command "set_msg_config -quiet -id \"Constraints 18-515\" -suppress"
		    command "set_msg_config -quiet -id \"Constraints 18-402\" -suppress"
		    set start_time [clock seconds]
		    puts "\t#HD: Inserting LUT1 buffers on interface of $name \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
		    command "update_design -cells $cell -buffer_ports" "$resultDir/update_design_bufferport_$name.log"
		    set end_time [clock seconds]
		    log_time update_design $start_time $end_time 0 "Convert blackbox partition $name to greybox"
		    set budgetXDC $xdcDir/${module}_budget.xdc
		    if {![file exists $budgetXDC] || ${hd.budget}} {
		       set start_time [clock seconds]
		       puts "\t#HD: Creating budget constraints for greybox $name \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
		       create_partition_budget -cell $cell -file $budgetXDC -exclude $budgetExclude
		       set end_time [clock seconds]
		       log_time create_budget $start_time $end_time 0 "Create budget constraints for $name"
		    }
		    set start_time [clock seconds]
		    readXDC $budgetXDC
		    set end_time [clock seconds]
		    log_time read_xdc $start_time $end_time 0 "Read in budget constraints for $name"
		 }; #End: Process greybox partitions
	      }; #End: Process each partition that is not Top
	   }; #End: Foreach partition

	   ##############################################
	   # Lock imported Partitions 
	   ##############################################
	   foreach partition $partitions {
	      lassign $partition module cell state name type level dcp
	      if {![string match "greybox" $state]} {
		 set moduleName [get_attribute module $module moduleName]
	      } else {
		 set moduleName $module
	      }
	      if {![string match $moduleName $top] && [string match $state "import"]} {
		 if {![llength $level]} {
		    set level "routing"
		 }
		 set start_time [clock seconds]
		 puts "\tLocking $cell \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
		 command "lock_design -level $level $cell" "$resultDir/lock_design_$name.log"
		 set end_time [clock seconds]
		 log_time lock_design $start_time $end_time 0 "Locking cell $cell at level routing"
	      }; #End: Process each partition that is not Top
	   }; #End: Foreach partition
	   puts "\t#HD: Completed link_design"
	   puts "\t##########################"

	   ##############################################
	   # Write out final link_design DCP 
	   ##############################################
	   if {$dcpLevel > 0} {
	      set start_time [clock seconds]
	      puts "\tWriting post-link_design checkpoint: $resultDir/${top}_link_design.dcp \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]\n"
	      command "write_checkpoint -force $resultDir/${top}_link_design.dcp" "$resultDir/write_checkpoint.log"
	      set end_time [clock seconds]
	      log_time write_checkpoint $start_time $end_time 0 "Post link_design checkpoint"
	   }

	   if {$verbose > 1} {
	      set start_time [clock seconds]
	      puts "\tRunning report_utilization \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
	      command "report_utilization -file $reportDir/${top}_utilization_link_design.rpt" "$resultDir/temp.log"
	      set end_time [clock seconds]
	      log_time report_utilization $start_time $end_time
	   } 

	   ##############################################
	   # Run Methodology DRCs checks 
	   ##############################################
	   #Run methodology DRCs and catch any Critical Warnings or Error (module ruledeck quiet)
	   if {$verbose > 1} {
	      set start_time [clock seconds]
	      check_drc $top methodology_checks 1
	      set end_time [clock seconds]
	      log_time report_drc $start_time $end_time 0 "methodology checks"
	      #Run timing DRCs and catch any Critical Warnings or Error (module ruledeck quiet)
	      set start_time [clock seconds]
	      check_drc $top timing_checks 1
	      set end_time [clock seconds]
	      log_time report_drc $start_time $end_time 0 "timing_checks"
	   }
	}; #END: if $link

   ############################################################################################
   # Implementation steps: opt_design, place_design, phys_opt_design, route_design
   ############################################################################################
   #Determine if all partitions (including top) are being imported
   set allImport 1
   foreach partition $partitions {
      lassign $partition module cell state name type level dcp
      if {![string match "import" $state]} { 
         set allImport 0
         break
      }
   }
   if {$allImport} {
      if {$hd} {
         set skipOpt 1
         set skipPlace 1
         set skipPhysOpt 1
         set skipRoute 0
      } elseif {$pr} {
         set skipOpt 1
         set skipPlace 1
         set skipPhysOpt 1
         set skipRoute 1
      } else {
         set errMsg "\nERROR: Implementation has all partitions set to import, but supported partition flow not detected."
         lappend errMsg "\nVerify the either HD or PR attribute is set to \'1\'."
         error $errMsg
      }
   } else {
      set skipOpt 0
      set skipPlace 0
      set skipPhysOpt 0
      set skipRoute 0
   }
   
   if {$opt && !$skipOpt} {
      impl_step opt_design $top $opt_options $opt_directive ${opt.pre}
   }

   if {$place && !$skipPlace} {
      impl_step place_design $top $place_options $place_directive ${place.pre}
   }

   if {$phys && !$skipPhysOpt} {
      impl_step phys_opt_design $top $phys_options $phys_directive ${phys.pre}
   }

   if {$route && !$skipRoute} {
      impl_step route_design $top $route_options $route_directive ${route.pre}
 
      if {$post_phys} {
         impl_step post_phys_opt $top $post_phys_options $post_phys_directive ${post_phys.pre}
      }

      #Run report_timing_summary on final design
      set start_time [clock seconds]
      puts "\tRunning report_timing_summary: $reportDir/${top}_timing_summary.rpt \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
      command "report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file $reportDir/${top}_timing_summary.rpt" "$resultDir/temp.log"
      set end_time [clock seconds]
      log_time report_timing $start_time $end_time 0 "Timing Summary"

      #Report PR specific statitics for debug and analysis
      if {$pr} {
         set start_time
         puts "\tRunning report_design_stauts: $reportDir/${top}_design_status.rpt \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
         command "debug::report_design_status" "$reportDir/${top}_design_status.rpt"
      }

      if {$verbose} {
         getTimingInfo
      }
      set impl_end [clock seconds]
      log_time final $impl_start $impl_end 
   }

   #For PR, don't write out bitstreams until after PR_VERIFY has run. See run.tcl
   #For HD, run write_bitstream prior to creating blackbox or DRC errors will occur.
   if {$bitstream && !$pr} {
      impl_step write_bitstream $top $bitstream_options none ${bitstream.pre} $bitstream_settings
   } else {
      #If skipping write_bitstream, run a final DRC that catches any Critical Warnings (module ruledeck quiet)
      set start_time [clock seconds]
      check_drc $top bitstream_checks ${drc.quiet}
      set end_time [clock seconds]
      log_time report_drc $start_time $end_time 0 "bitstream_checks"
   }
   
   set extras_start [clock seconds]
   if {![file exists $dcpDir]} {
      command "file mkdir $dcpDir"
   }   

   if {$hd || $pr} {
      #Write out cell checkpoints for all Partitions and create black_box 
      puts $rfh "\n#HD: Running implementation $impl"
      puts $RFH "\n#HD: Running implementation $impl"
      #Generate a new header for a table the first time through
      set header 1
      foreach partition $partitions {
         lassign $partition module cell state name type level dcp
         #Don't try to get moduleName for greybox Partitions as the name can be random
         if {![string match "greybox" $state]} { 
            set moduleName [get_attribute module $module moduleName]
         } else {
            set moduleName $module
         }
  
         if {![string match $moduleName $top]} {
            #Only write out cell DCPs for implemented cells
            if {([string match $state "implement"])} {
               if {![llength $name]} {
                  set name [lindex [split $cell "/"] end]
               }
               set start_time [clock seconds]
               set dcp "$resultDir/${name}_${module}_route_design.dcp"
               #Lock the netlist of the cell to prevent MLO optimizations when cell DCP is reused.
               #Cannot lock placement/routing at this stage, or the carver will not be able to remove the cell.
               command "lock_design -level logical -cell $cell" "$resultDir/lock_$name.log"
               command "write_checkpoint -force -cell $cell $dcp" "$resultDir/write_checkpoint.log"
               set end_time [clock seconds]
               log_time write_checkpoint $start_time $end_time $header "Write cell checkpoint for $cell"
               set header 0

               #BEGIN - TEST HD PARTITION IMPORT USING PR 
               if {$hd && $pr} {
                  #Post Process partition DCP to get rid of clock routes and PartPin info. 
                  puts "\tProcessing routed DCP for $cell to remove PhysDB for external clocks"
                  command "open_checkpoint $dcp" "$resultDir/open_checkpoint.log"
                  set clockNets [get_nets -filter TYPE==LOCAL_CLOCK]
                  foreach net $clockNets {
                     command "reset_property HD.PARTPIN_LOCS \[get_ports -of \[get_nets $net\]\]"
                  }
                  command "route_design -unroute -nets \[get_nets \{$clockNets\}\]" "$resultDir/${name}_unroute.log"
                  command "write_checkpoint -force $dcp" "$resultDir/write_checkpoint.log"
                  command "close_design"
               }
               #END - TEST HD PARTITION IMPORT USING PR 
               command "file copy -force $dcp $dcpDir"
            }

            #Carve out all implemented partitions if Top/Static was implemented
            if {[string match $topState "implement"]} {
               set start_time [clock seconds]
               puts "\tCarving out $cell to be a black box \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
               #unlock cells before carving them if they were imported
               if {[string match $state "import"]} {
                  command "lock_design -unlock -level placement $cell" "$reportDir/unlock_$name.log"
               }
               command "update_design -cell $cell -black_box" "$resultDir/carve_$name.log"
               set end_time [clock seconds]
               log_time update_design $start_time $end_time $header "Carve out (blackbox) $cell"
               set header 0
            }
         }
      }
   }

   #Write out implemented version of Top for import in subsequent runs
   if {$pr || $hd} {
      foreach partition $partitions {
         lassign $partition module cell state name type level dcp
         #Skip this step for greybox partitions to avoid errors in getting moduleName property
         if {[string match "greybox" $state]} { 
            continue
         }
         set moduleName [get_attribute module $module moduleName]
         if {[string match $moduleName $top] && [string match $state "implement"]} {
            set start_time [clock seconds]
            puts "\t#HD: Locking $top and exporting results \[[clock format $start_time -format {%a %b %d %H:%M:%S %Y}]\]"
            command "lock_design -level routing" "$resultDir/lock_design_$top.log"
            set end_time [clock seconds]
            log_time lock_design $start_time $end_time 0 "Lock placement and routing of $top"
            if {$hd} {
               set topDCP "$resultDir/${top}_routed.dcp"
            }
            if {$pr} {
               set topDCP "$resultDir/${top}_static.dcp"
            } 
            set start_time [clock seconds]
            command "write_checkpoint -force $topDCP" "$resultDir/write_checkpoint.log"
            command "file copy -force $topDCP $dcpDir"
            set end_time [clock seconds]
            log_time write_checkpoint $start_time $end_time 0 "Write out locked Static checkpoint"
         }
      }
   }

   set extras_end [clock seconds]
   log_time final $extras_start $extras_end 
   command "puts \"#HD: Implementation $impl complete\\n\""
   command "close_project"
   close $rfh
   close $cfh
   close $wfh
}

#
# Copyright (c) Yizhou Shan 2019. All rights reserved.
#

list_runs

# Run Synthesis on any modules requiring synthesis
foreach module [get_modules synth] {
	synthesize $module
}

# Run PR configurations
foreach config [sort_configurations [get_implementations "impl pr.impl" &&]]  {
	#Override directives if directive file is specified
	if {[info exists useDirectives]} {
		puts "#HD: Overriding directives for configuration $config"
		set_directives impl $config
	}
	implement $config
}

# Run Assembly and Flat implementations
foreach impl [get_implementations "impl !pr.impl" &&]  {
	#Override directives if directive file is specified
	if {[info exists useDirectives]} {
		puts "#HD: Overriding directives for implementation $impl"
		set_directives impl $impl
	}
	implement $impl
}

# Run PR verify 
set configurations [get_implementations "pr.impl verify" &&]
if {[llength  $configurations] > 1} {
	verify_configs $configurations
}

# Genearte PR bitstreams 
set configurations [get_implementations "pr.impl bitstream" &&]
if {[llength  $configurations] > 0} {
	## Set Tcl Params
	if {[info exists tclParams] && [llength $tclParams] > 0} {
		set_parameters $tclParams
	}
	generate_pr_bitstreams $configurations
}

close $RFH
close $CFH
close $WFH

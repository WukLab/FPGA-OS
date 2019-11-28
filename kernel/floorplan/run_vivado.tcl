#
# Copyright (c) 2019, Wuklab. All rights reserved.
#

set xboard		"vcu118"
set nr_generated_hook	"[lindex $argv 0]"
set module_prefix	"[lindex $argv 1]"
set global_ip_repo	"[lindex $argv 2]"

set run.topSynth	1 ;#synthesize static
set run.rmSynth		1 ;#synthesize RM variants
set run.prImpl		1 ;#implement each static + RM configuration
set run.prVerify	0 ;#verify RMs are compatible with static
set run.writeBitstream	0 ;#generate full and partial bitstreams

# Generate the RP definitions and the associated RM modules
# The RP region is named as rp_x
# The RM module is named as generated_rp_module_x
set i 0
while {$i < $nr_generated_hook} {
	set module_name "${module_prefix}_$i"
	set rp_name "rp_$i"
	set rm_variants($rp_name) "$module_name"

	puts "$i  $rp_name $module_name"

	lappend rm_config(initial) $rp_name $module_name

	incr i
}

# RM Configurations (Valid combinations of RM variants)
# 1. Define initial configuration: rm_config(initial)
# 2. Define additional configurations: rm_config(xyz)
#set module1_variant1 "shift_right"
#set module2_variant1 "count_up"
#set rm_config(initial)   "$rp1 $module1_variant1 $rp2 $module2_variant1"

#set module1_variant2 "shift_left"
#set module2_variant2 "count_down"
#set rm_config(reconfig1) "$rp1 $module1_variant2 $rp2 $module2_variant2"

set srcDir	"."
set rtlDir	"$srcDir/src"
set xdcDir	"$srcDir/src/xdc"
set coreDir	"$srcDir/cores"
set netlistDir	"$srcDir/netlist"
set tclDir	"$srcDir/scripts"

# Output Directories
set synthDir	"./generated_synth"
set implDir	"./generated_implement"
set dcpDir	"./generated_checkpoint"
set bitDir	"./generated_bitstreams"
set rm_dir	"./generated_modules"

source $tclDir/synth.tcl
source $tclDir/impl.tcl
source $tclDir/pr_utils.tcl
source $tclDir/log_utils.tcl
source $tclDir/hd_utils.tcl
source $tclDir/design_utils.tcl

switch $xboard {
	vcu108 {
		set device       "xcvu095"
		set package      "-ffva2104"
		set speed        "-2-e"
	}
	vcu118 {
		set device       "xcvu9p"
		set package      "-flga2104"
		set speed        "-2l-e"
		set board        "xilinx.com:vcu118:part0:2.3"
	}
	default {
		set device       "xcvu9p"
		set package      "-flga2104"
		set speed        "-2l-e"
		set board        "xilinx.com:vcu118:part0:2.3"
	}
}
set part         $device$package$speed
check_part $part

#  Run Settings
set verbose      1
set dcpLevel     1

#
# This is the top-level static base.
#
set top "top"
set static "static"
add_module $static
set_attribute module $static moduleName	$top
set_attribute module $static top_level	1
set_attribute module $static vlog	[list [glob $rtlDir/$top/*.v]]
set_attribute module $static bd		[list [glob $rtlDir/$top/bd/*.tcl]]
set_attribute module $static synth	${run.topSynth}
set_attribute module $static ipRepo	${global_ip_repo}

#
# This creates all the RM modules.variant
# moduleName is more like the RP name
#
foreach rp [array names rm_variants] {
	foreach rm $rm_variants($rp) {
		set variant $rm
		add_module $variant
		set_attribute module $variant	moduleName	$rp
		set_attribute module $variant	vlog		[list [glob $rm_dir/$variant/*.v]]
		#set_attribute module $variant	bd		[list [glob $rm_dir/$variant/bd/*.tcl]]

		# Common settings
		set_attribute module $variant	synth		${run.rmSynth}
		set_attribute module $variant	ipRepo		${global_ip_repo}
	}
}

# Configuration (Implementation) Definition 
foreach cfg_name [array names rm_config] {
	if {$cfg_name=="initial"} {
		set state "implement"
	} else {
		set state "import"
	}
    
	set config "config"
	set partition_list [list [list $static $top $state]]

	#
	# {rp rm_variant} -> {rp_x generated_rp_module_x}
	#
	foreach {rp rm_variant} $rm_config($cfg_name) {
		set module_inst inst_${rp}

		# Do not append the name..
		#set config "${config}_${rm_variant}"

		set partition [list $rm_variant $module_inst implement]
		lappend partition_list $partition
	}

	set config "${config}_${state}"
  
	add_implementation $config
	set_attribute impl $config top		$top
	set_attribute impl $config implXDC	[list $xdcDir/${top}_$xboard.xdc]

	set_attribute impl $config partitions	$partition_list

	set_attribute impl $config pr.impl	${run.prImpl}
	set_attribute impl $config impl		${run.prImpl} 
	set_attribute impl $config verify	${run.prVerify} 
	set_attribute impl $config bitstream	${run.writeBitstream} 

	#set_attribute impl $config bitstream_settings [list <options_go_here>]
}

source $tclDir/run.tcl

#exit

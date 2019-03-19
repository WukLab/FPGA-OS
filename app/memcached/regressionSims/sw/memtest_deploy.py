#!/usr/bin/python

# ------------------------------------------------------------------------------
# KVS Regression Testing
# ------------------------------------------------------------------------------
#
# To run regression tests, a environment configuration and simulation setups
# are required. These are two python files specified at the command prompt.
# The number of parallel processes can be specified as well
#   ./memcached_deploy env sim [#proc=1]
# See env.* and sim.* for examples.
#
# Environment Configuration ----------------------------------------------------
# This python script must export a variable 'env' with the fields
#   vsim, xlibs, simbase, simdir
# defined. See examples for explanation.
#
# Simulation Configuration -----------------------------------------------------
# This python script must export a variable 'simulations'. It is an array of
# simulation setups. A simulation setup is a variable with the fields
#   name, requests, golden-response, backpressure, runtime
# defined. See examples for explanation.

################################################################################

import imp
import sys
import os
import shutil
import subprocess
import datetime
import multiprocessing
import time

################################################################################

kvs_run = """
onbreak {exit -code 1}
onerror {exit -code 1}

vlib work
vmap work work

vlog /proj/gsd/vivado/Vivado/2013.2/data/verilog/src/glbl.v
vlog ../../../../hls/memcachedPipeline_prj/solution1/impl/ip/hdl/verilog/*.v
vlog ../../../../hls/dramModel_prj/solution1/impl/ip/hdl/verilog/*.v
vlog ../../../../hls/flashModel_prj/solution1/impl/ip/hdl/verilog/*.v
vlog ../../../../hls/dummyPCIeJoint_prj/solution1/impl/ip/hdl/verilog/*.v
vcom ../../../sources/kvs_tbMonitorHDLNode.vhdl
vcom ../../../sources/kvs_tbDriverHDLNode.vhdl
vcom ../../../sources/prototypeWrapper.vhd
vcom ../../../sources/vc709_tb_wrapper.vhd

transcript file modelsim.load.log
vsim -L unisims_ver -L unisim -t ps -novopt +notimingchecks -c vc709_tb_wrapper work.glbl

#mem load -infile ../../../../hls/dramModel_prj/solution1/impl/ip/hdl/verilog/memAccess_memArray_V_ram.dat -format bin /vc709_tb_wrapper/uut/dramHash/bramModel_U/memAccess_U0/memArray_V_U/memAccess_memArray_V_ram_U
#mem load -infile ../../../../hls/dramModel_prj/solution1/impl/ip/hdl/verilog/memAccess_memArray_V_ram.dat -format bin /vc709_tb_wrapper/uut/dramUpd/bramModel_U/memAccess_U0/memArray_V_U/memAccess_memArray_V_ram_U 
#mem load -infile ../../../../hls/flashModel_prj/solution1/impl/ip/hdl/verilog/flashMemAccess_memArray_V_ram.dat -format bin /vc709_tb_wrapper/uut/flashUpd/flashModel_U/flashMemAccess_U0/memArray_V_U/flashMemAccess_memArray_V_ram_U 

log -r /vc709_tb_wrapper/uut/myMemcachedPipeline/*
log -r /vc709_tb_wrapper/uut/dramHash/* 
log -r /vc709_tb_wrapper/uut/dramUpd/*  
log -r /vc709_tb_wrapper/uut/flashUpd/* 
log -r /vc709_tb_wrapper/uut/myMonitor/*
log -r /vc709_tb_wrapper/uut/myReader/*
log -r /vc709_tb_wrapper/uut/memAllocator/*

radix hex
# Simulation Run
run __RUNTIME__
quit -force
"""

################################################################################

def run_simulation((env, simulation)):
	"""
	Performs setup, running and verification of `simulation`.
	Expects absolute paths in `env`.
	Directory `env['simdir']` must exist.
	"""
	# Uses tuple arg instead of 2 args to be used with map function

	def log(s):
		time = datetime.datetime.now().strftime("%a %H:%M")
		sys.stdout.write("Log %d, %s: %s\n" % (os.getpid(), time, s))
		sys.stdout.flush() # hope this cleans the log

	start_time = datetime.datetime.now()
	log("Setup %s" % simulation['name'])
	#print "STATUS:%d: Setup %s" % (os.getpid(), simulation['name'])

	# create absolute paths
	simulation['requests'] = os.path.expanduser(simulation['requests'])
	simulation['golden-response'] = os.path.expanduser(simulation['golden-response'])
	simulation['backpressure'] = os.path.expanduser(simulation['backpressure'])

	# creating directory
	DST = env['simdir'] + "/" + simulation['name']
	if os.path.exists(DST):
		log("WARNING: Replacing %s" % DST)
		#print "STATUS:%d: WARNING: Replacing %s" % (os.getpid(), DST)
		shutil.rmtree(DST)
	os.mkdir(DST)

	# setup simulation
	os.symlink(env['xlibs'], DST+"/modelsim.ini")                    					# modelsim.ini
	shutil.copy(simulation['requests'], DST+"/pkt.in.txt")           					# Requests
	shutil.copy(simulation['backpressure'], DST+"/bpr.txt")          					# BPR
	#print simulation['simbase'] + "/bramModel_memArray_V_ram.dat"
	#shutil.copy(env['simbase'] + "/bramModel_memArray_V_ram.dat", DST+"/bramModel_memArray_V_ram.dat")          	# BRAM Init
	dofile = open(DST+"/simrun.do", "w")                             					# .do file
	dofile.write(kvs_run.replace("__RUNTIME__", simulation['runtime']))
	dofile.close()

	# run simulation
	log("Running %s (%s)" % (simulation['name'], simulation['runtime']))
	#print "STATUS:%d: Running %s (%s)" % (os.getpid(), simulation['name'], simulation['runtime'])
	fnull = open("/dev/null", "w")
	runresult = subprocess.call(
		[env['vsim'], '-c', '-do', 'simrun.do'],
		cwd=DST, stdout=fnull)
	fnull.close()

	# verify result
	log("Verifying %s" % simulation['name'])
	#print "STATUS:%d: Verifying %s" % (os.getpid(), simulation['name'])
	if runresult == 0:
		vfile = open(DST+"/verification.txt", "w")
		gold = simulation['golden-response']
		silver = DST+"/pkt.out.txt"
		cmp = os.path.abspath(os.path.dirname(__file__))+"/memtest_compare.py"
		if subprocess.call([sys.executable, cmp, gold, silver], stdout=vfile) == 0:
			simulation['result'] = 0
		else:
			simulation['result'] = 1
		vfile.close()
	else:
		simulation['result'] = 2

	end_time = datetime.datetime.now()
	simulation['clocktime'] = end_time - start_time
	log("Finished %s. Took %ds. Status: %d." % (
		simulation['name'],
		simulation['clocktime'].seconds,
		simulation['result']
	))
	"""
	print "STATUS:%d: Finished %s. Took %ss. Status: %d." % (
		os.getpid(),
		simulation['name'],
		simulation['clocktime'].seconds,
		simulation['result']
	)
	"""

	return simulation

################################################################################

def run_set(env, simulations, name = None, poolsize=1):
	start_time = datetime.datetime.now()

	# support for '~' as homedir
	env['vsim'] = os.path.expanduser(env['vsim'])
	env['xlibs'] = os.path.expanduser(env['xlibs'])
	env['simbase'] = os.path.expanduser(env['simbase'])
	env['simdir'] = os.path.expanduser(env['simdir'])

	print "-"*80
	print "KVS REGRESSION TESTING"
	print "-"*80
	print "Start                :", start_time.strftime("%Y-%m-%d %H:%M:%S")
	print "PID                  :", os.getpid()
	print "Worker pool          :", poolsize
	print "Simulation source    :", env['simbase']
	print "Deployment directory :", env['simdir']
	print "Testset              :", name
	print

	# check for simdir
	if not os.path.exists(env['simdir']):
		print "Log: Creating " + env['simdir']
		os.makedirs(env['simdir'])

	# run the simulations
	# Need to pass env to the function. Cannot use lambda because it's not
	# serializable which is needed by the worker pool. Thus, zip is used.
	pool = multiprocessing.Pool(processes=poolsize)
	pairs = zip([env]*len(simulations), simulations)
	simulations = pool.map(run_simulation, pairs)
	#simulations = map(run_simulation, pairs)

	end_time = datetime.datetime.now()

	# print result
	time.sleep(10) # let's hope this is enough to flush the output of the worker processes
	print
	overall = True
	for simu in simulations:
		if simu['result'] != 0:
			overall = False
	if overall:
		print "%-30s : PASSED   :                     : %s" % ("Overall", end_time - start_time)
	else:
		print "%-30s : FAILED   :                     : %s" % ("Overall", end_time - start_time)
	print '-'*80
	
	for simu in simulations:
		if simu['result'] == 0:
			print "%-30s : PASSED   :                     : %s" % (simu['name'], str(simu['clocktime']))
		elif simu['result'] == 1:
			print "%-30s : FAILED   : see verfication.txt : %s" % (simu['name'], str(simu['clocktime']))
		else:
			print "%-30s : RUNERROR : run manually        : %s" % (simu['name'], str(simu['clocktime']))

	print
	#print "Start :", start_time.strftime("%Y-%m-%d %H:%M:%S")
	#print "End   :", end_time.strftime("%Y-%m-%d %H:%M:%S"),
	#print "(%s)" % (end_time - start_time)
	print "Finished", end_time.strftime("%Y-%m-%d %H:%M:%S")

################################################################################

if __name__ == "__main__":
	if len(sys.argv) < 3:
		print "Usage: ./memtest_deploy env tests [#proc]"
		print "Open script for help."
		sys.exit(2)
	env = imp.load_source("env", sys.argv[1])
	sim = imp.load_source("sim", sys.argv[2])
	proc = 8
	if len(sys.argv) > 3:
		proc = int(sys.argv[3])
	run_set(env.env, sim.simulations, sys.argv[2], proc)

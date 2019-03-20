HLS implementation of Memcached pipeline
==================================================

This readme file contains following sections:


1. OVERVIEW
2. SOFTWARE TOOLS AND SYSTEM REQUIREMENTS
3. DESIGN FILE HIERARCHY
4. INSTALLATION AND OPERATING INSTRUCTIONS
5. OTHER INFORMATION (OPTIONAL)
6. SUPPORT
7. LICENSE
8. CONTRIBUTING
9. Acknowledgements
10. REVISION HISTORY

## 1.OVERVIEW

This HLS example gives the pipelined memcached implementation. The main pipeline stages of memcached include request parser, hash table, value store and response formatter. Both HLS and RTL testbenches are provided to allow users to simulate the design in HLS or modelsim.

## 2. SOFTWARE TOOLS AND SYSTEM REQUIREMENT
* Xilinx Vivado 2015.1 and ModelSim 10.1a

## 3. Design FILE HIERARCHY 

...
   |	CONTRIBUTING.md
   | 	LICENSE.md
   |    README.md
   |
	 +--doc         										: contains the memcached HLS deisgn document 
   +--hls         										: memcached pipeline HLS implementation
   +--scripts     										: contains a cshell scripts to creat all Vivado HLS project
	 +--buildUoeMcdSingleDramPCIe				: contains all source and scripts used to create .bit files for the ADM-PCIE-7V3 card
	 |
	 |----+src													: contains the latest tcp and udp offload HLS code same as in ../tcp_ip, and board specificfiles for build .bit file
	 |----+scripts											: contains the .sh and .tcl script to create a UOE+MCD with one dram channel for value store and one dram channel for hash table and host-side memory allocation code
	 |----+host_side_software					  : contains the host-side memory management code and udp-mcd test client. The UoeMcdSingleDramPCIe.pdf descrips the steps to compile and use these code to test the FPGA implementation. The UoeMcdSingleDramPCIePort1.tcc is a spirent configuration file used to test the FPGA implementation.	
   +--regressionSims									: memcached RTL simulation related files
   |
   |-----+bpr     : backpressure data files used to generated back pressure signals in rtl simulation
   |-----+config  : configue file desicribes the input packets and golder reference packets
   |-----+pkt : input and golden reference packets
   |-----+sources : rtl driver,  monitor and wrapper code for simulation
   |-----+sw      : python code for start rtl simulation process, record the simulation results and compare the results with the golden reference
   |-----+testgen : python code for generating pkt inputs and golden reference for the rtl simulation


## 4. INSTALLATION AND OPERATION INSTRUCTIONS

* HLS simulation steps:

 1. If you have aleady created memcachedPipeline_prj, then navigate to memcachedPipeline_prj, and enter following command to open the vivado_hls project
		vivado_hls vivado_hls.app
 2. if you have not created this project, then navigate to the hls directory and use vivado_hls 2015.1 to create this project via following command
		vivado_hls -f run_hls.memcachedPipeline.tcl
 3. after you opened the vivado_hls project, click "c simulation in the gui", and enter following parameters in the command argument window of the popped up dialogue.
		../../../../../hls/pkt.in.txt    ../../../../../hls/pkt.out.txt
 4. after the csimulation finishes, you will see pkt.out.txt is generated.


* RTL simulation steps:

1. make sure vivado 2015.1 is in your PATH
2. navigate to scripts and run "source ./make_hls.csh" to sythesize memcahed pipeline hls modules. When the running process of this script finishes, you should see a group of hls projects being created in hls directory
3. edit regressionSims/sw/env.server to point the environment variables to the path of your modelsim, modelsim.ini, sources folder in the regressionSim folder and rtl simulation results
4. navigate to regresssionSim/sw and run following command to start the RTL simulation. You might need to change the path of python2.6 to the path you are using
/usr/bin/python2.6 memtest_deploy.py env.server ../config/sim.allseqs.hls
5. In the end, you should see TEST PASSED message

* Steps for creating a memcached with DRAM and SSD as Value store and x86-based host side memory management for ADM-PCIE-7V3 card:

1. navigate to buildUoeMcdSingleDramPCIe/scripts directory
2. edit build_system.sh file to:
			change the HLS_2015_1 variable in build_system.sh to point to the vivado_hls 2015.1
			change the vivado_USED variable in build_system.sh to point to the vivado vivado 2016.2
3. run ./build_system.sh
4. at the end of step 3, a UoeMcdSingleDramPCIe_top.bit file should be generated and stored under directory buildUoeMcdSingleDramPCIe/runTimeStamp/prj/prj.runs/impl_1
5. follow section 3 "System Testing" in buildUoeMcdSingleDramPCIe/UoeMcdSingleDramPCIe.pdf to test the bit file.


## 5. OTHER INFORMATION

[Vivado HLS User Guide][]

## 6. SUPPORT

For questions and to get help on this project or your own projects, visit the [Vivado HLS Forums][]. 

## 7. License
The source for this project is licensed under the [3-Clause BSD License][]

## 8. Contributing code
Please refer to and read the [Contributing][] document for guidelines on how to contribute code to this open source project. The code in the `/master` branch is considered to be stable, and all pull-requests should be made against the `/develop` branch.

## 9. Acknowledgements
This project is written by developers at [Xilinx](http://www.xilinx.com/) with other contributors listed below:

## 10. REVISION HISTORY

Date		|	Readme Version		|	Revision Description
------------|-----------------------|-------------------------
JUNE2016		|	1.0					|	Initial Xilinx release
NOV2016     | 1.1					| added scripts and source for creating memcached that uses DRAM and BRAM as value store, x86-based host side memory managemen

[Contributing]: CONTRIBUTING.md 
[3-Clause BSD License]: LICENSE.md
[Full Documentation]: http://www.xilinx.com/support/documentation/application_notes/xapp1273-reed-solomon-erasure.pdf
[Vivado HLS Forums]: https://forums.xilinx.com/t5/High-Level-Synthesis-HLS/bd-p/hls 
[Vivado HLS User Guide]: http://www.xilinx.com/support/documentation/sw_manuals/xilinx2015_4/ug902-vivado-high-level-synthesis.pdf

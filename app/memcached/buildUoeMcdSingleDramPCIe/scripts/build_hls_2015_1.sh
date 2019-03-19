#!/bin/sh
################################################################################
# Author: Lisa Liu
# Date:	2016/11/07
#
# Usage:
#			./build_hls_2015_1.sh
# Vivado_hls version:
#			2015.1
################################################################################
##cadman add -t xilinx -v 2015.1 -p vivado_gsd
##create ./run folder to store all intermediate results

source "$1"

BUILDDIR="$PWD"

echo "BUILDDIR is $BUILDDIR"

# cp ../scripts/tcl/*.tcl ./

 vivado_hls -f run_hls.memcachedPipeline.tcl
 vivado_hls -f run_hls.readConverter.tcl
 vivado_hls -f run_hls.writeConverter.tcl
 vivado_hls -f run_hls.flashModel.tcl

echo "Finished kvs HLS kernel synthesis"

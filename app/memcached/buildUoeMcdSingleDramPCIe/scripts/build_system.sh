#!/bin/sh
################################################################################
# Author: Lisa Liu
# Date:	2016/11/07
#
# Usage:
#			./build_system.sh
# Vivado_hls version:
#			2015.1
# Vivado version:
#			2016.2
################################################################################
BSTAMP=`date +%Y%m%d-%H%M%S`
RUN_DIR="../run${BSTAMP}"

mkdir -p "$RUN_DIR"
if [ $? -ne 0 ]; then
    echo "Could not create output directory"
    exit 1
fi

cd "${RUN_DIR}"
cp ../scripts/*.sh ./
cp ../scripts/tcl/*.tcl ./

HLS_2015_1="/opt/Xilinx/SDK/2018.2/settings64.sh"
VIVADO_USED="/opt/Xilinx/SDK/2018.2/settings64.sh"

./build_hls_2015_1.sh "$HLS_2015_1"
./build_tcp_ip_2015_1.sh "$HLS_2015_1"

source "$VIVADO_USED"
vivado -mode tcl -source create_prj.tcl

exit 0

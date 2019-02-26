#!/bin/bash
#
# Copyright (c) 2019, Wuklab, Purdue University
#

# Change the absolute path to your own one.
VIVADO_HLS="/opt/Xilinx/Vivado/2018.2/bin/vivado_hls"

# Hardcoded through projects
GENERATED_HLS_PROJECT="generated_hls_project"
HLS_DIR="$PWD"

# Customize
HLS_IP_CORES=(rx tx)
GENERATED_IP_REPO="${HLS_DIR}/../../generated_ip"

# Check if the shared IP repo exists
if [ ! -d "$GENERATED_IP_REPO" ]; then
	mkdir "$GENERATED_IP_REPO"
fi

# Rolling for each HLS IP in this directory
for ip in "${HLS_IP_CORES[@]}"; do
	eval cd ${HLS_DIR}/${ip}

	# Run the HLS script
	eval ${VIVADO_HLS} -f run_hls.tcl

	if [ ! -d "${GENERATED_IP_REPO}/net_sysnet_${ip}" ]; then
		mkdir "${GENERATED_IP_REPO}/net_sysnet_${ip}"
	fi
	#eval cd "${GENERATED_IP_REPO}/${ip}"

	zipname=`ls ${GENERATED_HLS_PROJECT}/solution1/impl/ip/*.zip`
	zipname=$(basename ${zipname})
	zipnamelen=${#zipname}

	# Skip the suffix ".zip"
	zipdir=${zipname:0:${zipnamelen}-4}

	# Copy the IP archive into shared IP repo
	eval cp ${GENERATED_HLS_PROJECT}/solution1/impl/ip/${zipname} ${GENERATED_IP_REPO}/net_sysnet_${ip}/
	unzip -o ${GENERATED_IP_REPO}/net_sysnet_${ip}/${zipname} -d ${GENERATED_IP_REPO}/net_sysnet_${ip}/${zipdir}
done

#!/bin/bash
#
# Copyright (c) 2019, Wuklab, Purdue University
#
# This script automate the process of creating multiple HLS projects.
# It should be a level higher than run_hls.tcl. This is used to run
# multiple run_hls.tcl scripts.
#
# To customize
# 1) Modify HLS_IP_CORES list
# 2) Modify GENERATED_IP_REPO to reflect the path

# Change the absolute path to your own one.
vivado_hls='/opt/Xilinx/Vivado/2018.2/bin/vivado_hls'

# Customize
HLS_IP_CORES=(hls_dram_read)
GENERATED_IP_REPO="${HLS_DIR}/../generated_ip"

# Hardcoded through projects
GENERATED_HLS_PROJECT="generated_hls_project"
HLS_DIR="$PWD"

# Check if the shared IP repo exists
if [ ! -d "$GENERATED_IP_REPO" ]; then
	mkdir "$GENERATED_IP_REPO"
fi

# Rolling for each HLS IP in this directory
for ip in "${HLS_IP_CORES[@]}"; do
	eval cd ${HLS_DIR}/${ip}

	# Run the HLS script
	eval ${vivado_hls} -f run_hls.tcl

	if [ ! -d "${GENERATED_IP_REPO}/${ip}" ]; then
		mkdir "${GENERATED_IP_REPO}/${ip}"
	fi
	#eval cd "${GENERATED_IP_REPO}/${ip}"

	zipname=`ls ${GENERATED_HLS_PROJECT}/solution1/impl/ip/*.zip`
	zipname=$(basename ${zipname})
	zipnamelen=${#zipname}

	# Skip the suffix ".zip"
	zipdir=${zipname:0:${zipnamelen}-4}

	# Copy the IP archive into shared IP repo
	eval cp ${GENERATED_HLS_PROJECT}/solution1/impl/ip/${zipname} ${GENERATED_IP_REPO}/${ip}/
	unzip -o ${GENERATED_IP_REPO}/${ip}/${zipname} -d ${GENERATED_IP_REPO}/${ip}/${zipdir}
done

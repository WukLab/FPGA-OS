#!/bin/bash
#
# Copyright (c) 2019, Wuklab, UCSD
#

TARGET_BOARD=$1

# Change the absolute path to your own one.
VIVADO_HLS='vivado_hls'

# Hardcoded through projects
GENERATED_HLS_PROJECT="generated_hls_project"
HLS_DIR="$PWD"

# Customize: sub-folders 
HLS_IP_CORES=(hls_rx_256 hls_rx_512)

# Customize: relative path
GENERATED_IP_FOLDER="${HLS_DIR}/../../generated_ip"

# Customize: new IP folder prefix
PREFIX=net_libnet

# Check if the shared IP repo exists
if [ ! -d "$GENERATED_IP_FOLDER" ]; then
	mkdir "$GENERATED_IP_FOLDER"
fi

# Rolling for each HLS IP in this directory
for ip in "${HLS_IP_CORES[@]}"; do
	NEW_IP_REPO="${GENERATED_IP_FOLDER}/${PREFIX}_${ip}_${TARGET_BOARD}"
	eval cd ${HLS_DIR}/${ip}

	# Run the HLS script
	eval ${VIVADO_HLS} -f run_hls_${TARGET_BOARD}.tcl

	if [ ! -d ${NEW_IP_REPO} ]; then
		mkdir ${NEW_IP_REPO}
	fi

	zipname=`ls ${GENERATED_HLS_PROJECT}/solution1/impl/ip/*.zip`
	zipname=$(basename ${zipname})
	zipnamelen=${#zipname}

	# Skip the suffix ".zip"
	zipdir=${zipname:0:${zipnamelen}-4}

	# Copy the IP archive into shared IP repo
	eval cp ${GENERATED_HLS_PROJECT}/solution1/impl/ip/${zipname} ${NEW_IP_REPO}/
	unzip -o ${NEW_IP_REPO}/${zipname} -d ${NEW_IP_REPO}/${zipdir}
done

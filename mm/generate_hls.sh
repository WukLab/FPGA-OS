#!/bin/bash
#
# Copyright (c) 2019, Wuklab, UCSD
#
# This script automate the process of creating multiple HLS projects.
# It should be a level higher than run_hls.tcl. This is used to run
# multiple run_hls.tcl scripts.
#
# To customize
# - Modify GENERATED_IP_FOLDER to reflect the path

TARGET_BOARD=$1
HLS_IP=$2
IP_NAME_PREFIX=$3

# Customize: relative path
HLS_DIR="$PWD"
GENERATED_IP_FOLDER="${HLS_DIR}/../generated_ip"

# Change the absolute path to your own one.
VIVADO_HLS='vivado_hls'

# Hardcoded through projects
GENERATED_HLS_PROJECT="generated_hls_project"

# Check if the shared IP repo exists
if [ ! -d "$GENERATED_IP_FOLDER" ]; then
	mkdir "$GENERATED_IP_FOLDER"
fi

IFS=',' read -r -a HLS_IP_CORES <<< "$HLS_IP"
for ip in "${HLS_IP_CORES[@]}"; do
	NEW_IP_REPO="${GENERATED_IP_FOLDER}/${IP_NAME_PREFIX}_${ip}_${TARGET_BOARD}"
	eval cd ${HLS_DIR}/${ip}

	# Run the HLS script accoding to board
	eval ${VIVADO_HLS} -f run_hls.tcl -tclargs ${TARGET_BOARD}

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

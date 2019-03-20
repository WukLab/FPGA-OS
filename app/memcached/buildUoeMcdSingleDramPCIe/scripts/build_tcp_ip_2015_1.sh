#!/usr/local/bin/bash
################################################################################
# Author: Lisa Liu
# Date:	2016/07/29
#
# Usage:
#			./make_tcp_ip.sh
# Vivado_hls version:
#			2015.1
################################################################################
source "$1"
BUILDDIR="$PWD"

echo "BUILDDIR is $BUILDDIR"


 vivado_hls -f run_hls.arp_server.tcl

 vivado_hls -f run_hls.dhcp_client.tcl

 vivado_hls -f run_hls.icmp_server.tcl

 vivado_hls -f run_hls.ip_handler.tcl

 vivado_hls -f run_hls.mac_ip_encode.tcl

 vivado_hls -f run_hls.udpCore.tcl

 vivado_hls -f run_hls.udpAppMux.tcl

 vivado_hls -f run_hls.udpShim.tcl

echo "Finished tcp_ip core synthesis"
echo "Create ipRepository"

IPREPOSITORYDIR="$BUILDDIR/ipRepository"

if [ -d "$IPREPOSITORYDIR" ]; then
	echo "$PWD"
else
	mkdir "$IPREPOSITORYDIR"
	echo "create directory $IPREPOSITORYDIR"
fi


 cp -R ./arp_server_prj ./ipRepository 
 cp -R ./dhcp_prj ./ipRepository
 cp -R ./icmpServer_prj ./ipRepository
 cp -R ./ipHandler_prj ./ipRepository
 cp -R ./macIpEncode_prj ./ipRepository
 cp -R ./udp_prj ./ipRepository
 cp -R ./udpAppMux_prj ./ipRepository
 cp -R ./udpShim_prj ./ipRepository

echo "finished UOE preparation for creating vivado projec."


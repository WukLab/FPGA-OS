/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/* System-level headers */

#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

using namespace hls;

void net_loopback(hls::stream<struct net_axis_512> *from_net,
		  hls::stream<struct net_axis_512> *to_net)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net

	struct net_axis_512 current;

	if (from_net->empty())
		return;

	current = from_net->read();
	to_net->write(current);
}

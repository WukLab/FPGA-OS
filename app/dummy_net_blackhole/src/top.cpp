/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/* System-level headers */

#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

using namespace hls;

void dummy_net_blackhole(hls::stream<struct net_axis_512> *from_net)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis both port=from_net

	if (from_net->empty())
		return;

	from_net->read();
}

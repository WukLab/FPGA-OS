/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/* System-level headers */

#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

using namespace hls;

void dummy_net_pktgen(hls::stream<struct net_axis_512> *to_net,
		      ap_uint<1> enabled)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE ap_none port=enabled

	struct net_axis_512 current;
	static ap_uint<512> data = 0;

	if (!enabled)
		return;

	current.keep = 0xffffffffffffffff;
	current.user = 0;
	current.data = data;
	data++;

	if (data.to_int() == 16) {
		current.last = 1;
		data = 0;
	} else
		current.last = 0;
	to_net->write(current);
}

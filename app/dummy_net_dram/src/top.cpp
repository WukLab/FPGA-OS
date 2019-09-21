/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/* System-level headers */

#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

using namespace hls;

#if 0
void dummy_net_dram(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net, ap_uint<512> *dram)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=off

	struct net_axis_512 current;

	if (from_net->empty())
		return;

	current = from_net->read();
	to_net->write(current);

	/* Just to use the dram interface */
	dram[0] = current.data;
}
#endif

void dummy_net_dram(hls::stream<struct net_axis_64> *from_net,
		    hls::stream<struct net_axis_64> *to_net, ap_uint<512> *dram)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=off

	struct net_axis_64 current;
	static int i = 0;

	if (from_net->empty())
		return;

	current = from_net->read();
	to_net->write(current);

	/* Just to use the dram interface */
	dram[i++] = current.data;
}

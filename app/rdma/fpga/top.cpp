/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "top.hpp"
#include <fpga/axis_net.h>
#include <uapi/net_header.h>

using namespace hls;

void app_rdma(stream<struct net_axis_512> *from_net,
	      stream<struct net_axis_512> *to_net, char *dram)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS PIPELINE

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=direct

	struct net_axis_512 tmp;

	if (!from_net->empty()) {
		tmp = from_net->read();
		to_net->write(tmp);
		*dram = 0;
	}
}

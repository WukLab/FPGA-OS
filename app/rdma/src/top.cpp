/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "top.hpp"

using namespace hls;

void app_rdma(stream<struct net_axis<NET_DATA_WIDTH> > *from_mac,
	      stream<struct net_axis<NET_DATA_WIDTH> > *to_mac, char *dram)
{
#pragma HLS PIPELINE

#pragma HLS INTERFACE axis both port=from_mac
#pragma HLS INTERFACE axis both port=to_mac
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=direct

	*dram = 0;
}

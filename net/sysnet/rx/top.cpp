/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "top.hpp"

using namespace hls;

void sysnet_rx(stream<struct net_axis<NET_DATA_WIDTH> > *from_mac,
	       stream<struct net_axis<NET_DATA_WIDTH> > *to_router)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE axis both port=from_mac
#pragma HLS INTERFACE axis both port=to_router

	struct net_axis<NET_DATA_WIDTH>	tmp;

	if (!from_mac->empty()) {
		tmp = from_mac->read();
		to_router->write(tmp);
	}
}

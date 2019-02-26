/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "top.hpp"

void sysnet_tx(hls::stream<struct net_axis<NET_DATA_WIDTH> > *from_router,
	       hls::stream<struct net_axis<NET_DATA_WIDTH> > *to_mac)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE axis both port=from_router
#pragma HLS INTERFACE axis both port=to_mac

	struct net_axis<NET_DATA_WIDTH>	tmp;

	if (!from_router->empty()) {
		tmp = from_router->read();
		to_mac->write(tmp);
	}
}

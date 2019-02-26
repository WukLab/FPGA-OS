/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _SYSNET_TX_TOP_HPP_
#define _SYSNET_TX_TOP_HPP_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include "../../include/net.hpp"

void sysnet_tx(hls::stream<struct net_axis<NET_DATA_WIDTH> > *from_router,
	       hls::stream<struct net_axis<NET_DATA_WIDTH> > *to_mac);

#endif /* _SYSNET_TX_TOP_HPP_ */

/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _APP_RDMA_TOP_HPP_
#define _APP_RDMA_TOP_HPP_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include "../../../net/include/net.hpp"

void app_rdma(hls::stream<struct net_axis<NET_DATA_WIDTH> > *from_mac,
	      hls::stream<struct net_axis<NET_DATA_WIDTH> > *to_mac,
	      char *dram);

#endif /* _APP_RDMA_TOP_HPP_ */

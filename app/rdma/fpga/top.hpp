/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _APP_RDMA_TOP_HPP_
#define _APP_RDMA_TOP_HPP_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include <fpga/axis_net.h>
#include <uapi/net_header.h>

void app_rdma(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net, char *dram);

#endif /* _APP_RDMA_TOP_HPP_ */

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

struct request {
	unsigned long	address;
	unsigned long	length;

	struct net_axis_512 eth_header;
	struct net_axis_512 app_header;
};

void app_rdma(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net,
	      ap_uint<512> *dram_in, ap_uint<512> *dram_out);
#endif /* _APP_RDMA_TOP_HPP_ */

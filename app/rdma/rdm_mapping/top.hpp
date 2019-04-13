/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _APP_RDMA_TOP_HPP_
#define _APP_RDMA_TOP_HPP_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include <fpga/axis_net.h>
#include <fpga/axis_mapping.h>
#include <uapi/net_header.h>

#define PI_ALLOC_SUCCEED	0
#define PI_ALLOC_FAIL		1

#define PI_MAP_SUCCEED		0
#define PI_MAP_FAIL		1

struct pipeline_info {
	char		opcode;
	unsigned long	va;
	unsigned long	length;

	/*
	 * nr_units to read
	 * calculated from length.
	 */
	unsigned long	nr_units;

	unsigned long	pa;
	unsigned long	pa_index;
	ap_uint<1>	map_status;

	ap_uint<1>	alloc_status;
	unsigned long	alloc_pa;
	unsigned long	alloc_va;

	struct net_axis_512 eth_header;
	struct net_axis_512 app_header;
};

#endif /* _APP_RDMA_TOP_HPP_ */

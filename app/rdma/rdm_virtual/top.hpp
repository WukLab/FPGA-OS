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

#if 1
# define CONFIG_ENABLE_SEGMENT
#endif

#define NR_SEGMENT_ENTRIES	64

struct segment_entry {
	/* [base, limit) */
	unsigned long	va_base;
	unsigned long	va_limit;
	unsigned long	pa_base;
} __attribute__((__packed__));

void app_rdm_virtual(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net,
	      ap_uint<512> *dram_in, ap_uint<512> *dram_out,
	      volatile struct app_rdma_stats *stats);

#endif /* _APP_RDMA_TOP_HPP_ */

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

	unsigned long	nr_packet;
	struct net_axis_512 eth_header;
	struct net_axis_512 app_header;
};

#define MEM_BUS_WIDTH	512
#define MEM_BUS_TKEEP	64

/*
 * This is the AXI-Stream format required by datamover.
 * The width of data and keep can be configured though.
 */
struct axis_mem {
	ap_uint<MEM_BUS_WIDTH>	data;
	ap_uint<MEM_BUS_TKEEP>	keep;
	ap_uint<1>		last;
};

/*
 * This is the internal commands to request memory access.
 * We convert this one to dm_cmd at dm.cpp
 */
struct mem_cmd {
	ap_uint<64>	address;
	ap_uint<64>	length;
	int		nr_units;
};

/*
 * This is the command word sent over to Datamover.
 * Defined at PG022 Figure 2-1 Command Word Layout.
 * NOTE: when you configure the Datamover, make btt 23 bits.
 */
#define DM_CMD_TYPE_FIXED	0
#define DM_CMD_TYPE_INCR	1
struct dm_cmd {
	ap_uint<23>	btt;
	ap_uint<1>	type;
	ap_uint<6>	dsa;
	ap_uint<1>	eof;
	ap_uint<1>	drr;
	ap_uint<32>	start_address;
	ap_uint<4>	tag;
	ap_uint<4>	rsvd;
};

struct segment_entry {
	/* [base, limit) */
	unsigned long	va_base;
	unsigned long	va_limit;
	unsigned long	pa_base;
};

#endif /* _APP_RDMA_TOP_HPP_ */

/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _MAPPING_DM_HPP_H_
#define _MAPPING_DM_HPP_H_

#include "top.hpp"

using namespace hls;

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
	ap_uint<32>	address;
	ap_uint<8>	length;
	int		info;
};

struct data_info {
	ap_uint<MEM_BUS_WIDTH>	data;
	int info;
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

#endif /* _MAPPING_DM_HPP_H_ */

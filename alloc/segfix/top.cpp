/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <fpga/config/alloc_segfix.h>
#include <fpga/channel/alloc_seg.h>
#include "internal.h"

using namespace hls;

struct segfix_entry table[NR_SEGFIX_ENTRIES];
ap_uint<64> base_pa;

void allocator_segfix(stream<struct alloc_seg_in> *in,
		      stream<struct alloc_seg_out> *out)
{
	struct alloc_seg_in din;
	struct alloc_seg_out dout;

	if (in->empty())
		return;

	din = in->read();

	dout.addr_len = 0x1000;
	dout.ret = 0;
	out->write(dout);
}

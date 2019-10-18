/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <fpga/config/alloc_segfix.h>
#include <fpga/channel/alloc_seg.h>
#include <fpga/channel/axi_rab.h>
#include "internal.h"

using namespace hls;

struct segfix_entry table[NR_SEGFIX_ENTRIES];
ap_uint<64> base_pa;

void mm_segfix_hls(stream<struct alloc_seg_in> *ctl_in, stream<struct alloc_seg_out> *ctl_out,
		   stream<struct rab_request> *rd_in, stream<struct rab_reply> *rd_out,
		   stream<struct rab_request> *wr_in, stream<struct rab_reply> *wr_out)
{
#pragma HLS PIPELINE II=1
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS DATA_PACK variable=ctl_int
#pragma HLS DATA_PACK variable=ctl_out
#pragma HLS DATA_PACK variable=rd_in
#pragma HLS DATA_PACK variable=rd_out
#pragma HLS DATA_PACK variable=wr_in
#pragma HLS DATA_PACK variable=wr_out

#pragma HLS INTERFACE axis port=ctl_int
#pragma HLS INTERFACE axis port=ctl_out
#pragma HLS INTERFACE axis port=rd_in
#pragma HLS INTERFACE axis port=rd_out
#pragma HLS INTERFACE axis port=wr_in
#pragma HLS INTERFACE axis port=wr_out

	struct alloc_seg_in cin;
	struct alloc_seg_out cout;
	struct rab_request rdin, wrin;
	struct rab_reply rdout, wrout;

	if (!ctl_in->empty())
		cin = ctl_in->read();
	else if (!rd_in->empty())
		rdin = rd_in->read();
	else if (!wr_in->empty())
		wrin = wr_in->read();

	ctl_out->write(cout);
	rd_out->write(rdout);
	wr_out->write(wrout);
}

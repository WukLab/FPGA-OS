/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <fpga/config/alloc_segfix.h>
#include <fpga/config/process.h>
#include <fpga/config/memory.h>
#include <fpga/channel/alloc_seg.h>
#include <fpga/channel/axi_rab.h>
#include "internal.h"

using namespace hls;

void mm_segvar_hls(stream<struct alloc_seg_in> *ctl_in, stream<struct alloc_seg_out> *ctl_out,
		   stream<struct rab_request> *rd_in, stream<struct rab_reply> *rd_out,
		   stream<struct rab_request> *wr_in, stream<struct rab_reply> *wr_out);

int main(void)
{
	stream<struct alloc_seg_in> ctl_in;
	stream<struct alloc_seg_out> ctl_out;
	stream<struct rab_request> rd_in, wr_in;
	stream<struct rab_reply> rd_out, wr_out;

	struct alloc_seg_in d_ctl_in;
	struct alloc_seg_out d_ctl_out;
	struct rab_request d_rd_in, d_wr_in;
	struct rab_reply d_rd_out, d_wr_out;

	int i, nr_cycles;

	/* Prepare inputs */
	d_ctl_in.opcode = SEG_ALLOC;
	d_ctl_in.addr_len = 0x1000;
	ctl_in.write(d_ctl_in);

	d_rd_in.in_addr = 0x2000;
	d_rd_in.pid = 0;
	d_rd_in.in_len = 1;
	d_rd_in.in_size = 2;
	rd_in.write(d_rd_in);

	d_wr_in.in_addr = 0x3000;
	d_wr_in.pid = 0;
	d_wr_in.in_len = 1;
	d_wr_in.in_size = 2;
	wr_in.write(d_wr_in);

	nr_cycles = 500;
	for (i = 0; i < nr_cycles; i++) {
		mm_segvar_hls(&ctl_in, &ctl_out, &rd_in, &rd_out, &wr_in, &wr_out);

		if (!ctl_out.empty()) {
			d_ctl_out = ctl_out.read();
			printf("[cc %3d] Control output: [%#lx, %d]\n",
				i, d_ctl_out.addr_len.to_long(), d_ctl_out.ret.to_int());
		}
		if (!rd_out.empty()) {
			d_rd_out = rd_out.read();
			printf("[cc %3d] DataPath RD: [%#lx, %d]\n",
				i, d_rd_out.out_addr.to_long(), d_rd_out.drop.to_int());
		}
		if (!wr_out.empty()) {
			d_wr_out = wr_out.read();
			printf("[cc %3d] DataPath WR: [%#lx, %d]\n",
				i, d_wr_out.out_addr.to_long(), d_wr_out.drop.to_int());
		}
	}
}

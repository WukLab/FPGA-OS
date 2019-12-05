/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#define DEBUG

#ifndef DEBUG
#define dp(fmt, ...)                                                                               \
	do {                                                                                       \
	} while (0)
#else
#define dp(fmt, ...) printf(fmt, ##__VA_ARGS__)
#endif

#include <iostream>

#include "internal.hpp"

using namespace hls;
using namespace std;

void test_init()
{
	dp("----Test Initilization----\n");

	stream<struct mem_cmd_in> ctrl_in;
	stream<struct mem_cmd_out> ctrl_out;
	stream<struct alloc_seg_in> seg_alloc_req;
	stream<struct alloc_seg_out> seg_alloc_ret;

	stream<struct buddy_alloc_if> buddy_alloc_req;
	stream<struct buddy_alloc_ret_if> buddy_alloc_ret;

	stream<unsigned long> init_buddy_addr;
	stream<ap_uint<PA_WIDTH> > init_tbl_addr;
	stream<unsigned long> init_heap_addr;

	int _cycle;

	struct mem_cmd_in init_cmd = { MEM_CMD_INIT, 0 };

#define NR_CYCLES_RUN 10

	ctrl_in.write(init_cmd);

	for (_cycle = 0; _cycle < NR_CYCLES_RUN; _cycle++) {
		coord_top(&ctrl_in, &ctrl_out, &seg_alloc_req, &seg_alloc_ret, &buddy_alloc_req,
			  &buddy_alloc_ret, &init_buddy_addr, &init_tbl_addr, &init_heap_addr);

		if (!ctrl_out.empty()) {
			auto cmd_res = ctrl_out.read();
			dp("[cycle %3d] control out: [ouput: %#x retcode: %#d]\n", _cycle,
			   cmd_res.addr_len, cmd_res.ret);
		}

		if (!seg_alloc_req.empty()) {
			auto seg_req = seg_alloc_req.read();
			dp("[cycle %3d] segment allocation request: [len: %#x op: %#d]\n", _cycle,
			   seg_req.addr_len.to_uint(), seg_req.opcode.to_uint());
			struct alloc_seg_out seg_ret = { 0x1000, SEG_SUCCESS };
			dp("(seg allocator) alloc %#x bytes\n", seg_ret.addr_len.to_uint());
			seg_alloc_ret.write(seg_ret);
		}

		if (!buddy_alloc_req.empty()) {
			auto buddy_req = buddy_alloc_req.read();
			dp("[cycle %3d] buddy allocation request: [order: %#d op: %#d]\n", _cycle,
			   buddy_req.order.to_uint(), buddy_req.opcode.to_uint());
			struct buddy_alloc_ret_if buddy_ret = { BUDDY_SUCCESS, 0x10000 * _cycle };
			dp("(buddy allocator) alloc %#x bytes\n", buddy_ret.addr.to_uint());
			buddy_alloc_ret.write(buddy_ret);
		}

		if (!init_buddy_addr.empty()) {
			dp("[cycle %3d] set initial physical allocator address: %#x\n", _cycle,
			   init_buddy_addr.read());
		}

		if (!init_tbl_addr.empty()) {
			dp("[cycle %3d] set initial mapping table address: %#x\n", _cycle,
			   init_tbl_addr.read().to_uint64());
		}

		if (!init_heap_addr.empty()) {
			dp("[cycle %3d] set initial heap allocator address: %#x\n", _cycle,
			   init_heap_addr.read());
		}
	}

	dp("----Test Initilization finished----\n");
}

int main()
{
	test_init();
}

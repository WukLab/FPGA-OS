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

#include "top.h"

using namespace hls;

int main()
{
	stream<struct buddy_alloc_if> buddy_req_high("high priority req channel");
	stream<struct buddy_alloc_ret_if> buddy_ret_high;
	stream<struct buddy_alloc_if> buddy_req_low("low priority req channel");
	stream<struct buddy_alloc_ret_if> buddy_ret_low;

	stream<struct buddy_alloc_if> fwd_buddy_req;
	stream<struct buddy_alloc_ret_if> fwd_buddy_ret;

	struct buddy_alloc_if buddy_req;
	struct buddy_alloc_ret_if buddy_ret;

	int _cycle, i;

#define NR_CYCLES_RUN 20

	for (_cycle = 1; _cycle <= NR_CYCLES_RUN; _cycle++) {
#define NR_REQ 4
		if (_cycle <= NR_REQ) {
			buddy_req = { BUDDY_ALLOC, 0, _cycle };
			buddy_req_high.write(buddy_req);
			dp("[cycle %2d] channel high write req: [op: %#d, addr: %#x, order: %#d]\n",
			   _cycle, buddy_req.opcode.to_uint(), buddy_req.addr.to_uint(),
			   buddy_req.order.to_uint());

			buddy_req = { BUDDY_FREE, 0x1000 * _cycle, 0 };
			buddy_req_low.write(buddy_req);
			dp("[cycle %2d] channel low write req: [op: %#d, addr: %#x, order: %#d]\n",
			   _cycle, buddy_req.opcode.to_uint(), buddy_req.addr.to_uint(),
			   buddy_req.order.to_uint());
		}

		buddy_alloc_mux(&buddy_req_high, &buddy_ret_high, &buddy_req_low, &buddy_ret_low,
				&fwd_buddy_req, &fwd_buddy_ret);

		if (!fwd_buddy_req.empty()) {
			auto req = fwd_buddy_req.read();
			struct buddy_alloc_ret_if ret;
			switch (req.opcode) {
			case BUDDY_ALLOC:
				ret.addr = _cycle * 0x1000;
				ret.stat = BUDDY_SUCCESS;
				break;
			case BUDDY_FREE:
				ret.addr = 0;
				ret.stat = BUDDY_SUCCESS;
				break;
			}
			fwd_buddy_ret.write(ret);
		}

		if (!buddy_ret_high.empty()) {
			buddy_ret = buddy_ret_high.read();
			dp("[cycle %2d] channel high read ret: [stat: %#d, addr: %#x]\n", _cycle,
			   buddy_ret.stat.to_uint(), buddy_ret.addr.to_uint());
		}

		if (!buddy_ret_low.empty()) {
			buddy_ret = buddy_ret_low.read();
			dp("[cycle %2d] channel low read ret: [stat: %#d, addr: %#x]\n", _cycle,
			   buddy_ret.stat.to_uint(), buddy_ret.addr.to_uint());
		}
	}
}

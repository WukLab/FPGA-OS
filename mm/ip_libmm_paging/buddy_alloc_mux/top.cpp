/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "top.h"

using namespace hls;

enum MUX_STATUS {
	MUX_SEND,
	MUX_RET
};

void buddy_alloc_mux(stream<struct buddy_alloc_if>	*buddy_alloc_req_1,
		     stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret_1,
		     stream<struct buddy_alloc_if>	*buddy_alloc_req_2,
		     stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret_2,
		     
		     stream<struct buddy_alloc_if>	*fwd_buddy_alloc_req,
		     stream<struct buddy_alloc_ret_if>	*fwd_buddy_alloc_ret)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both register port=buddy_alloc_req_1
#pragma HLS INTERFACE axis both port=buddy_alloc_ret_1
#pragma HLS INTERFACE axis both register port=buddy_alloc_req_2
#pragma HLS INTERFACE axis both port=buddy_alloc_ret_2
#pragma HLS INTERFACE axis both port=fwd_buddy_alloc_req
#pragma HLS INTERFACE axis both port=fwd_buddy_alloc_ret

#pragma HLS DATA_PACK variable=buddy_alloc_req_1
#pragma HLS DATA_PACK variable=buddy_alloc_ret_1
#pragma HLS DATA_PACK variable=buddy_alloc_req_2
#pragma HLS DATA_PACK variable=buddy_alloc_ret_2
#pragma HLS DATA_PACK variable=fwd_buddy_alloc_req
#pragma HLS DATA_PACK variable=fwd_buddy_alloc_ret

	struct buddy_alloc_if alloc_req;
	struct buddy_alloc_ret_if alloc_ret;

	static MUX_STATUS state = MUX_SEND;
	static ap_uint<1> channel;

	switch (state) {
	case MUX_SEND:
		if (!buddy_alloc_req_1->empty()) {
			alloc_req = buddy_alloc_req_1->read();
			fwd_buddy_alloc_req->write(alloc_req);
			channel = 0;
			state = MUX_RET;
		} else if (!buddy_alloc_req_2->empty()) {
			alloc_req = buddy_alloc_req_2->read();
			fwd_buddy_alloc_req->write(alloc_req);
			channel = 1;
			state = MUX_RET;
		}
		break;
	case MUX_RET:
		if (fwd_buddy_alloc_ret->empty())
			break;
		alloc_ret = fwd_buddy_alloc_ret->read();
		if (channel == 0)
			buddy_alloc_ret_1->write(alloc_ret);
		else
			buddy_alloc_ret_2->write(alloc_ret);
		state = MUX_SEND;
		break;
	}
}

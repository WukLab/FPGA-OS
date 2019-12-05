/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "internal.hpp"

using namespace hls;

const unsigned int AXI_DEPTH = 0x10000;

enum COORD_STATUS {
	COORD_IDLE,
	COORD_INIT,
	COORD_ALLOC,
	COORD_FREE
};

void coord_top(stream<struct mem_cmd_in>		*ctrl_in,
	       stream<struct mem_cmd_out>		*ctrl_out,

	       stream<struct alloc_seg_in>		*seg_alloc_req,
	       stream<struct alloc_seg_out>		*seg_alloc_ret,
	       stream<struct buddy_alloc_if>		*buddy_alloc_req,
	       stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret,

	       stream<unsigned long>			*init_buddy_addr,
	       stream<ap_uint<PA_WIDTH> >		*init_tbl_addr,
	       stream<unsigned long>			*init_heap_addr)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=ctrl_in
#pragma HLS INTERFACE axis both port=ctrl_out
#pragma HLS INTERFACE axis both port=seg_alloc_req
#pragma HLS INTERFACE axis both port=seg_alloc_ret
#pragma HLS INTERFACE axis both register port=buddy_alloc_req
#pragma HLS INTERFACE axis both register port=buddy_alloc_ret

#pragma HLS INTERFACE axis both port=init_buddy_addr
#pragma HLS INTERFACE axis both port=init_tbl_addr
#pragma HLS INTERFACE axis both port=init_heap_addr

#pragma HLS DATA_PACK variable=ctrl_in
#pragma HLS DATA_PACK variable=ctrl_out
#pragma HLS DATA_PACK variable=seg_alloc_req
#pragma HLS DATA_PACK variable=seg_alloc_ret
#pragma HLS DATA_PACK variable=buddy_alloc_req
#pragma HLS DATA_PACK variable=buddy_alloc_ret

	static COORD_STATUS state = COORD_IDLE;

	enum FUNCTION_STATUS ret;
	enum mem_cmd_opcode opcode;

	static struct mem_cmd_in command_req;
	struct mem_cmd_out command_res;

	switch (state) {
	case COORD_IDLE:
		if (ctrl_in->empty())
			break;
		command_req = ctrl_in->read();
		opcode = command_req.opcode;
		switch (opcode) {
		case MEM_CMD_INIT:
			state = COORD_INIT;
			break;
		case MEM_CMD_ALLOC:
			state = COORD_ALLOC;
			break;
		case MEM_CMD_FREE:
			state = COORD_FREE;
			break;
		}
		break;
	case COORD_INIT:
		ret = init(buddy_alloc_req, buddy_alloc_ret,
			   seg_alloc_req, seg_alloc_ret,
			   init_buddy_addr, init_tbl_addr, init_heap_addr);
		if (ret == FUNC_DOWN) {
			PR("[init]: down\n");
			state = COORD_IDLE;
			command_res.addr_len = 0;
			command_res.ret = MEM_CMD_SUCCESS;
			ctrl_out->write(command_res);
		} else if (ret == FUNC_FAILED) {
			PR("[init]: failed\n");
			state = COORD_IDLE;
			command_res.addr_len = 0;
			command_res.ret = MEM_CMD_FAILED;
			ctrl_out->write(command_res);
		}
		break;
	case COORD_ALLOC:
		break;
	case COORD_FREE:
		break;
	}
}

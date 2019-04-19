/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#define ENABLE_PR

#include <string.h>
#include <fpga/axis_net.h>
#include <fpga/axis_buddy.h>
#include <fpga/axis_mapping.h>
#include <fpga/kernel.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>

#include "top.hpp"
#include "../include/rdma.h"
#include "../include/hls.h"

using namespace hls;

enum PARSER_STATE {
	PARSER_ETH_HEADER,
	PARSER_APP_HEADER,
	PARSER_STREAM,
};

static void parser(stream<struct net_axis_512> *d_in,
		   stream<struct net_axis_512> *d_out,
		   stream<struct pipeline_info> *pi_out)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum PARSER_STATE state = PARSER_ETH_HEADER;
	static struct pipeline_info pi;
	struct net_axis_512 d = { 0 };

	switch (state) {
	case PARSER_ETH_HEADER:
		if (d_in->empty())
			break;
		d = d_in->read();
		pi.eth_header = d;
		state = PARSER_APP_HEADER;
		break;
	case PARSER_APP_HEADER:
		if (d_in->empty())
			break;
		d = d_in->read();
		pi.app_header = d;

		pi.opcode  = pi.app_header.data(7, 0);
		pi.va      = pi.app_header.data(71, 8);
		pi.length  = pi.app_header.data(135, 72);
		pi.nr_units = pi.app_header.data(135, 72) / NR_BYTES_AXIS_512;

		/* Only write has more incoming data */
		if (pi.opcode == APP_RDMA_OPCODE_WRITE)
			state = PARSER_STREAM;
		else
			state = PARSER_ETH_HEADER;

		pi_out->write(pi);
		break;
	case PARSER_STREAM:
		if (d_in->empty())
			break;
		d = d_in->read();
		d_out->write(d);

		if (d.last == 1)
			state = PARSER_ETH_HEADER;
		break;
	};
}

/*
 * A real simple native virtual address
 * allocation function.
 */
#define RDM_VA_PAGE_SIZE	(0x1000)
static unsigned long rdm_alloc_va(unsigned long length)
{
#pragma HLS INLINE
	static unsigned long __alloc_va = 0x1000;
	unsigned long ret;

	ret = __alloc_va;
	__alloc_va += round_up(length, RDM_VA_PAGE_SIZE);

	PR("len: %x, ret: %x, __alloc_va: %x\n", length, ret, __alloc_va);
	return ret;
}

enum ALLOC_STATE {
	ALLOC_IDLE,
	ALLOC_WRITE_STREAM,
	ALLOC_WAIT_ALLOC,
};

static void alloc_address(stream<struct pipeline_info> *pi_in,
		  stream<struct pipeline_info> *pi_out,
		  stream<struct net_axis_512> *d_in,
		  stream<struct net_axis_512> *d_out,
		  stream<struct buddy_alloc_if> *alloc_req,
		  stream<struct buddy_alloc_ret_if> *alloc_ret)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum ALLOC_STATE state = ALLOC_IDLE;
	static struct pipeline_info pi;
	struct net_axis_512 d;

	switch (state) {
	case ALLOC_IDLE:
		if (pi_in->empty())
			break;
		pi = pi_in->read();

		/* Only ALLOC sends requests to buddy. */
		if (pi.opcode == APP_RDMA_OPCODE_ALLOC) {
			struct buddy_alloc_if req;

			// XXX calculate order based on length
			req.order = 1; 

			req.addr = 0;
			req.opcode = BUDDY_ALLOC;
			alloc_req->write(req);
			state = ALLOC_WAIT_ALLOC;
			break;
		} else if (pi.opcode == APP_RDMA_OPCODE_READ) {
			pi_out->write(pi);
			state = ALLOC_IDLE;
			break;
		} else if (pi.opcode == APP_RDMA_OPCODE_WRITE) {
			pi_out->write(pi);
			state = ALLOC_WRITE_STREAM;
			break;
		}
		break;
	case ALLOC_WRITE_STREAM:
		if (d_in->empty())
			break;
		d = d_in->read();
		d_out->write(d);
		if (d.last == 1)
			state = ALLOC_IDLE;
		break;
	case ALLOC_WAIT_ALLOC:
		if (!alloc_ret->empty()) {
			struct buddy_alloc_ret_if ret;

			ret = alloc_ret->read();
			if (ret.stat == 0) {
				pi.alloc_status = PI_ALLOC_SUCCEED;
				pi.alloc_pa = ret.addr.to_uint();
				pi.alloc_va = rdm_alloc_va(pi.length);
			} else {
				pi.alloc_status = PI_ALLOC_FAIL;
				pi.alloc_pa = 0;
				pi.alloc_va = 0;
			}
			pi_out->write(pi);
			state = ALLOC_IDLE;
		}
		break;
	}
}

enum MAP_STATE {
	MAP_IDLE,
	MAP_WAIT_MAP,
	MAP_STREAM
};

static void map(stream<struct pipeline_info> *pi_in,
		stream<struct pipeline_info> *pi_out,
		stream<struct net_axis_512> *d_in,
		stream<struct net_axis_512> *d_out,
		stream<struct mapping_request> *map_req,
		stream<struct mapping_reply> *map_ret)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum MAP_STATE state = MAP_IDLE;
	static struct pipeline_info pi;
	struct net_axis_512 d = { 0 };
	struct mapping_request req = { 0 };
	struct mapping_reply ret = { 0 };

	switch (state) {
	case MAP_IDLE:
		if (pi_in->empty())
			break;
		pi = pi_in->read();

		/*
		 * Send requests to mapping IP
		 * Alloc will use SET, read/write use GET.
		 */
		if (pi.opcode == APP_RDMA_OPCODE_ALLOC) {
			if (pi.alloc_status == PI_ALLOC_SUCCEED) {
				/*
				 * [key, value] = [va, pa]
				 */
				req.address = pi.alloc_va;
				req.length = pi.alloc_pa;
				req.opcode = MAPPING_SET;
			} else {
				/*
				 * If allocation already failed,
				 * no need to do SET.
				 */
				pi_out->write(pi);
				break;
			}
		} else {
			req.address = pi.va;
			req.length = 0;
			req.opcode = MAPPING_REQUEST_READ;
		}
		map_req->write(req);

		state = MAP_WAIT_MAP;
		break;
	case MAP_WAIT_MAP:
		if (map_ret->empty())
			break;
		ret = map_ret->read();

		if (ret.status == 0) {
			pi.map_status = PI_MAP_SUCCEED;
			pi.pa = ret.address;
			pi.pa_index = pi.pa / NR_BYTES_AXIS_512;
		} else {
			pi.map_status = PI_MAP_FAIL;
		}

		if (pi.opcode == APP_RDMA_OPCODE_WRITE)
			state = MAP_STREAM;
		else
			state = MAP_IDLE;

		pi_out->write(pi);
		break;
	case MAP_STREAM:
		if (d_in->empty())
			break;
		d = d_in->read();
		d_out->write(d);
		if (d.last == 1)
			state = MAP_IDLE;
		break;
	};
}

enum ACCESS_STATE {
	ACCESS_IDLE,
	ACCESS_OUT_APP,
	ACCESS_WRITE,
	ACCESS_READ,
};

static void access(stream<struct pipeline_info> *pi_in,
		   stream<struct pipeline_info> *pi_out,
		   stream<struct net_axis_512> *d_in,
		   stream<struct net_axis_512> *d_out,
		   ap_uint<512> *dram)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static struct pipeline_info pi;
	static enum ACCESS_STATE state = ACCESS_IDLE;
	struct net_axis_512 d = { 0 };
	static int offset = 0;

	switch (state) {
	case ACCESS_IDLE:
		if (pi_in->empty())
			break;
		pi = pi_in->read();
		offset = 0;

		if (pi.opcode != APP_RDMA_OPCODE_WRITE)
			d_out->write(pi.eth_header);
		state = ACCESS_OUT_APP;
		break;
	case ACCESS_OUT_APP:
		if (pi.opcode == APP_RDMA_OPCODE_ALLOC) {
			if (pi.alloc_status == PI_ALLOC_SUCCEED) {
				pi.app_header.data(7, 0) = APP_RDMA_OPCODE_REPLY_ALLOC;
				pi.app_header.data(71, 8) = pi.alloc_va;
				pi.app_header.data(135, 72) = pi.alloc_pa;
				PR("alloc_va: %#lx, alloc_pa: %#lx\n",
					pi.app_header.data(71,8).to_uint(), pi.app_header.data(135,72).to_uint());
			} else {
				pi.app_header.data(7, 0) = APP_RDMA_OPCODE_REPLY_ALLOC_ERROR;
				pi.app_header.data(71, 8) = 0;
				pi.app_header.data(135, 72) = 0;
			}
			pi.app_header.last = 1;
			d_out->write(pi.app_header);

			state = ACCESS_IDLE;
			break;
		} else if (pi.opcode == APP_RDMA_OPCODE_READ) {
			if (pi.map_status == PI_MAP_SUCCEED) {
				pi.app_header.data(7, 0) = APP_RDMA_OPCODE_REPLY_READ;
				pi.app_header.last = 0;
				state = ACCESS_READ;
			} else {
				pi.app_header.data(7, 0) = APP_RDMA_OPCODE_REPLY_READ_ERROR;
				pi.app_header.last = 1;
				state = ACCESS_IDLE;
			}
			d_out->write(pi.app_header);
			break;
		} else if (pi.opcode == APP_RDMA_OPCODE_WRITE) {
			state = ACCESS_WRITE;
			break;
		}
		break;
	case ACCESS_WRITE:
		if (d_in->empty())
			break;
		d = d_in->read();

		if (pi.map_status == PI_MAP_SUCCEED) {
			dram[offset + pi.pa_index] = d.data;
			offset++;
		}

		if (d.last == 1)
			state = ACCESS_IDLE;
		break;
	case ACCESS_READ:
		d.keep(NR_BYTES_AXIS_512 - 1, 0) = 0xffffffffffffffff;
		d.data = dram[offset + pi.pa_index];
		offset++;

		if (offset >= pi.nr_units) {
			d.last = 1;
			state = ACCESS_IDLE;
		} else
			d.last = 0;

		d_out->write(d);
		break;
	};
}

static void reply(stream<struct net_axis_512> *to_net,
		  stream<struct pipeline_info> *pi_in,
		  stream<struct net_axis_512> *d_in)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	struct net_axis_512 current = { 0 };
	struct pipeline_info pi = { 0 };

	if (!d_in->empty()) {
		current = d_in->read();
		to_net->write(current);
	}
	if (!pi_in->empty()) {
		pi = pi_in->read();
	}
}

void buffering(stream<struct net_axis_512> *d_in,
	       stream<struct net_axis_512> *d_out)
{
#pragma HLS INLINE off
#pragma HLS PIPELINE
	if (!d_in->empty()) {
		struct net_axis_512 d;
		d = d_in->read();
		d_out->write(d);
	}
}

void rdm_mapping(stream<struct net_axis_512> *from_net,
	         stream<struct net_axis_512> *to_net,
	         ap_uint<512> *dram,
		 stream<struct buddy_alloc_if> *alloc_req,
		 stream<struct buddy_alloc_ret_if> *alloc_ret,
		 stream<struct mapping_request> *map_req,
		 stream<struct mapping_reply> *map_ret)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATAFLOW

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE axis both port=alloc_req
#pragma HLS INTERFACE axis both port=alloc_ret
#pragma HLS INTERFACE axis both port=map_req
#pragma HLS INTERFACE axis both port=map_ret

#pragma HLS INTERFACE m_axi depth=64 port=dram  offset=off

#pragma HLS DATA_PACK variable=alloc_req
#pragma HLS DATA_PACK variable=alloc_ret
#pragma HLS DATA_PACK variable=map_req
#pragma HLS DATA_PACK variable=map_ret

	static stream<struct pipeline_info> PI_parser_to_alloc("PI_parser_to_alloc");
	static stream<struct pipeline_info> PI_alloc_to_map("PI_alloc_to_map");
	static stream<struct pipeline_info> PI_map_to_access("PI_map_to_access");
	static stream<struct pipeline_info> PI_access_to_reply("PI_access_to_reply");

#pragma HLS STREAM variable=PI_parser_to_alloc	depth=256
#pragma HLS STREAM variable=PI_alloc_to_map	depth=256
#pragma HLS STREAM variable=PI_map_to_access	depth=256
#pragma HLS STREAM variable=PI_access_to_reply	depth=256

#if 0
#pragma HLS DATA_PACK variable=PI_parser_to_alloc
#pragma HLS DATA_PACK variable=PI_alloc_to_map   
#pragma HLS DATA_PACK variable=PI_map_to_access  
#pragma HLS DATA_PACK variable=PI_access_to_reply
#endif

	static stream<struct net_axis_512> D_buffer_to_parser("D_buffer_to_parser");
	static stream<struct net_axis_512> D_parser_to_alloc("D_parser_to_alloc");
	static stream<struct net_axis_512> D_alloc_to_map("D_alloc_to_map");
	static stream<struct net_axis_512> D_map_to_access("D_map_to_access");
	static stream<struct net_axis_512> D_access_to_reply("D_access_to_reply");

#pragma HLS STREAM variable=D_buffer_to_parser	depth=256
#pragma HLS STREAM variable=D_parser_to_alloc	depth=256
#pragma HLS STREAM variable=D_alloc_to_map	depth=256
#pragma HLS STREAM variable=D_map_to_access	depth=256
#pragma HLS STREAM variable=D_access_to_reply	depth=256

#if 0
#pragma HLS DATA_PACK variable=D_buffer_to_parser
#pragma HLS DATA_PACK variable=D_parser_to_alloc
#pragma HLS DATA_PACK variable=D_alloc_to_map
#pragma HLS DATA_PACK variable=D_map_to_access
#pragma HLS DATA_PACK variable=D_access_to_reply
#endif

	buffering(from_net, &D_buffer_to_parser);

	parser(&D_buffer_to_parser, &D_parser_to_alloc, &PI_parser_to_alloc);

	/*
	 * The original name of this function is simply alloc().
	 * But Vivado Simulation will complain it fail to find
	 * all of io ports of this func.. After changing to alloc_address()
	 * it passed.. isn't this some bug of Vivado?
	 */
	alloc_address(&PI_parser_to_alloc, &PI_alloc_to_map, &D_parser_to_alloc, &D_alloc_to_map,
		alloc_req, alloc_ret);

	map(&PI_alloc_to_map, &PI_map_to_access, &D_alloc_to_map, &D_map_to_access,
		map_req, map_ret);

	access(&PI_map_to_access, &PI_access_to_reply, &D_map_to_access, &D_access_to_reply, dram);

	reply(to_net, &PI_access_to_reply, &D_access_to_reply);
}

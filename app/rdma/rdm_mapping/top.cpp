/*
 * Copyright (c) 2019，Wuklab, UCSD.
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

unsigned long nr_rdm_packet = 1;

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
	static int offset = 0;

	switch (state) {
	case PARSER_ETH_HEADER:
		if (d_in->empty())
			break;
		d = d_in->read();

		pi.nr_packet = nr_rdm_packet;
		pi.eth_header = d;
		offset = 0;

		nr_rdm_packet++;
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
		pi.length  = round_up(pi.length, NR_BYTES_AXIS_512);
		pi.nr_units = round_up(pi.length, NR_BYTES_AXIS_512) / NR_BYTES_AXIS_512;

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

		/*
		 * We mark the end of the packet based on write length.
		 * It's functionaly correct also convenient for testing.
		 */
		if (d.last == 1) {
			state = PARSER_ETH_HEADER;
		} else if (offset == (pi.nr_units - 1)) {
			state = PARSER_ETH_HEADER;
			d.last = 1;
		} else {
			offset++;
		}
		d_out->write(d);
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
		stream<struct mapping_request> *map_req,
		stream<struct mapping_reply> *map_ret,
		stream<struct mem_cmd> *fifo_DRAM_rd_cmd,
		stream<struct mem_cmd> *fifo_DRAM_wr_cmd,
		stream<ap_uint<512> > *fifo_DRAM_wr_data)
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
			struct mem_cmd cmd;

			pi.map_status = PI_MAP_SUCCEED;
			pi.pa = ret.address;
			pi.pa_index = pi.pa / NR_BYTES_AXIS_512;

			/* Length has been roundup to 64B aligned */
			cmd.address = pi.pa;
			cmd.length = pi.length;
			cmd.nr_units = pi.nr_units;

			if (pi.opcode == APP_RDMA_OPCODE_READ) {
				fifo_DRAM_rd_cmd->write(cmd);
				PR("DRAM rd cmd: addr: %x, len: %x\n",
						cmd.address.to_uint(), cmd.length.to_uint());
			} else if (pi.opcode == APP_RDMA_OPCODE_WRITE) {
				fifo_DRAM_wr_cmd->write(cmd);
				PR("DRAM wr cmd: addr: %x, len: %x nr_units: %d\n",
						cmd.address.to_uint(), cmd.length.to_uint(),
						cmd.nr_units);
			}
		} else {
			pi.map_status = PI_MAP_FAIL;
		}

		if (pi.opcode == APP_RDMA_OPCODE_WRITE)
			state = MAP_STREAM;
		else {
			state = MAP_IDLE;
		}

		pi_out->write(pi);
		break;
	case MAP_STREAM:
		if (d_in->empty())
			break;
		d = d_in->read();
		fifo_DRAM_wr_data->write(d.data);

		if (d.last == 1)
			state = MAP_IDLE;
		break;
	};
}

enum ACCESS_STATE {
	ACCESS_IDLE,
	ACCESS_OUT_APP,
	ACCESS_READ,
};

static void access(stream<struct pipeline_info> *pi_in,
		stream<struct pipeline_info> *pi_out,
		stream<struct net_axis_512> *d_out,
		stream<ap_uint<512> > *fifo_DRAM_rd_data)
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

		d_out->write(pi.eth_header);
		state = ACCESS_OUT_APP;
		break;
	case ACCESS_OUT_APP:
		/*
		 * Update the nr_packet field for all reply packets
		 * The host reply on this field..
		 */
		pi.app_header.data(199, 136) = pi.nr_packet;

		/*
		 * Each request has a reply.
		 * Update the opcode part so the sender knows which reply it is.
		 */
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

			/* alloc reply has two units */
			pi.app_header.last = 1;
			state = ACCESS_IDLE;
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
		} else if (pi.opcode == APP_RDMA_OPCODE_WRITE) {
			/* Write reply only has two units */
			pi.app_header.data(7, 0) = APP_RDMA_OPCODE_REPLY_WRITE;
			pi.app_header.last = 1;
			state = ACCESS_IDLE;
		}
		d_out->write(pi.app_header);
		break;
	case ACCESS_READ:
		if (fifo_DRAM_rd_data->empty())
			break;
		d.data = fifo_DRAM_rd_data->read();
		d.keep(NR_BYTES_AXIS_512 - 1, 0) = 0xffffffffffffffff;

		offset++;

		if (offset == pi.nr_units) {
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

/*
 * I @mem_read_cmd: memory read commands from this IP
 * O @mem_read_data: internal read data buffer
 * O @dm_read_cmd: cooked requests sent to datamover
 * I @dm_read_data: data from datamover
 * I @dm_read_status: status from datamover
 */
void DRAM_rd_pipe(stream<struct mem_cmd> *mem_read_cmd,
		stream<ap_uint<512> > *mem_read_data,
		stream<struct dm_cmd> *dm_read_cmd,
		stream<struct axis_mem> *dm_read_data,
		stream<ap_uint<8> > *dm_read_status)
{
#pragma HLS PIPELINE
#pragma HLS INLINE
#pragma HLS INTERFACE ap_ctrl_none port=return

	/*
	 * Read commands from internal FIFO,
	 * cook it and send over to datamover.
	 */
	if (!mem_read_cmd->empty() && !dm_read_cmd->full()) {
		struct mem_cmd in_cmd;
		struct dm_cmd out_cmd;

		in_cmd = mem_read_cmd->read();

		out_cmd.start_address = in_cmd.address(31,0);
		out_cmd.btt = in_cmd.length(22, 0);
		out_cmd.type = DM_CMD_TYPE_INCR;
		out_cmd.dsa = 0;
		out_cmd.eof = 1;
		out_cmd.drr = 0;
		out_cmd.rsvd = 0;
		dm_read_cmd->write(out_cmd);
	}

	if (!dm_read_data->empty() && !mem_read_data->full()) {
		struct axis_mem in;

		in = dm_read_data->read();
		mem_read_data->write(in.data);
	}

	if (!dm_read_status->empty()) {
		ap_uint<8> status;
		status = dm_read_status->read();
	}
}

enum DRAM_WR_PIPE_STATE {
	DRAM_DM_IDLE,
	DRAM_DM_STRAM,
	DRAM_DM_STATUS
};

/*
 * I @mem_write_cmd: memory write commands from this IP
 * I @mem_write_data: internal write data buffer
 * O @dm_write_cmd: cooked requests sent to datamover
 * O @dm_write_data: data to datamover
 * I @dm_write_status: status from datamover
 */
void DRAM_wr_pipe(stream<struct mem_cmd> *mem_write_cmd,
		stream<ap_uint<512> > *mem_write_data,
		stream<struct dm_cmd> *dm_write_cmd,
		stream<struct axis_mem> *dm_write_data,
		stream<ap_uint<8> > *dm_write_status)
{
#pragma HLS PIPELINE
#pragma HLS INLINE
#pragma HLS INTERFACE ap_ctrl_none port=return

	static int nr_written = 0;
	static int nr_units = 0;
	static enum DRAM_WR_PIPE_STATE state = DRAM_DM_IDLE;

	switch (state) {
	case DRAM_DM_IDLE:
		if (!mem_write_cmd->empty() && !dm_write_cmd->full()) {
			struct mem_cmd in_cmd;
			struct dm_cmd out_cmd;

			in_cmd = mem_write_cmd->read();
			nr_written = 0;
			nr_units = in_cmd.nr_units;
			PR("addr: %x len: %x nr_units: %d\n",
					in_cmd.address.to_uint(),
					in_cmd.length.to_uint(),
					in_cmd.nr_units);

			out_cmd.start_address = in_cmd.address(31,0);
			out_cmd.btt = in_cmd.length(22, 0);
			out_cmd.type = DM_CMD_TYPE_INCR;
			out_cmd.dsa = 0;
			out_cmd.eof = 1;
			out_cmd.drr = 0;
			out_cmd.rsvd = 0;
			dm_write_cmd->write(out_cmd);

			state = DRAM_DM_STRAM;
		}
		if (!dm_write_status->empty()) {
			ap_uint<8> status;
			status = dm_write_status->read();
		}
		break;
	case DRAM_DM_STRAM:
		if (!mem_write_data->empty() && !dm_write_data->full()) {
			ap_uint<512> in;
			struct axis_mem out;

			out.data = mem_write_data->read();
			out.keep = 0xFFFFFFFFFFFFFFFF;

			nr_written++;
			PR("nr_written: %d nr_units: %d\n", nr_written, nr_units);
			if (nr_written == nr_units) {
				out.last = 1;
				state = DRAM_DM_IDLE;
			} else
				out.last = 0;
			dm_write_data->write(out);
		}
		break;
	};
}

void rdm_mapping(stream<struct net_axis_512> *from_net,
		stream<struct net_axis_512> *to_net,
		stream<struct buddy_alloc_if> *alloc_req,
		stream<struct buddy_alloc_ret_if> *alloc_ret,
		stream<struct mapping_request> *map_req,
		stream<struct mapping_reply> *map_ret,
		stream<struct dm_cmd> *DRAM_rd_cmd,
		stream<struct dm_cmd> *DRAM_wr_cmd,
		stream<struct axis_mem> *DRAM_rd_data,
		stream<struct axis_mem> *DRAM_wr_data,
		stream<ap_uint<8> > *DRAM_rd_status,
		stream<ap_uint<8> > *DRAM_wr_status)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATAFLOW

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE axis both port=alloc_req
#pragma HLS INTERFACE axis both port=alloc_ret
#pragma HLS INTERFACE axis both port=map_req
#pragma HLS INTERFACE axis both port=map_ret
#pragma HLS INTERFACE axis both port=DRAM_rd_cmd
#pragma HLS INTERFACE axis both port=DRAM_wr_cmd
#pragma HLS INTERFACE axis both port=DRAM_rd_data
#pragma HLS INTERFACE axis both port=DRAM_wr_data
#pragma HLS INTERFACE axis both port=DRAM_rd_status
#pragma HLS INTERFACE axis both port=DRAM_wr_status

#pragma HLS DATA_PACK variable=alloc_req
#pragma HLS DATA_PACK variable=alloc_ret
#pragma HLS DATA_PACK variable=map_req
#pragma HLS DATA_PACK variable=map_ret
#pragma HLS DATA_PACK variable=DRAM_rd_cmd
#pragma HLS DATA_PACK variable=DRAM_wr_cmd

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
	static stream<struct net_axis_512> D_access_to_reply("D_access_to_reply");

#pragma HLS STREAM variable=D_buffer_to_parser	depth=512
#pragma HLS STREAM variable=D_parser_to_alloc	depth=512
#pragma HLS STREAM variable=D_alloc_to_map	depth=512
#pragma HLS STREAM variable=D_access_to_reply	depth=512

#if 0
#pragma HLS DATA_PACK variable=D_buffer_to_parser
#pragma HLS DATA_PACK variable=D_parser_to_alloc
#pragma HLS DATA_PACK variable=D_alloc_to_map
#pragma HLS DATA_PACK variable=D_access_to_reply
#endif

	static stream<struct mem_cmd> fifo_DRAM_rd_cmd("fifo_DRAM_rd_cmd");
	static stream<struct mem_cmd> fifo_DRAM_wr_cmd("fifo_DRAM_wr_cmd");
	static stream<ap_uint<512> > fifo_DRAM_rd_data("fifo_DRAM_rd_data");
	static stream<ap_uint<512> > fifo_DRAM_wr_data("fifo_DRAM_wr_data");
#pragma HLS STREAM variable=fifo_DRAM_rd_cmd	depth=256
#pragma HLS STREAM variable=fifo_DRAM_wr_cmd	depth=256
#pragma HLS STREAM variable=fifo_DRAM_rd_data	depth=256
#pragma HLS STREAM variable=fifo_DRAM_wr_data	depth=256
#pragma HLS DATA_PACK variable=fifo_DRAM_rd_cmd
#pragma HLS DATA_PACK variable=fifo_DRAM_wr_cmd

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

	map(&PI_alloc_to_map, &PI_map_to_access, &D_alloc_to_map,
			map_req, map_ret, &fifo_DRAM_rd_cmd, &fifo_DRAM_wr_cmd, &fifo_DRAM_wr_data);

	access(&PI_map_to_access, &PI_access_to_reply, &D_access_to_reply, &fifo_DRAM_rd_data);

	reply(to_net, &PI_access_to_reply, &D_access_to_reply);

	DRAM_rd_pipe(&fifo_DRAM_rd_cmd, &fifo_DRAM_rd_data,
			DRAM_rd_cmd, DRAM_rd_data, DRAM_rd_status);

	DRAM_wr_pipe(&fifo_DRAM_wr_cmd, &fifo_DRAM_wr_data,
			DRAM_wr_cmd, DRAM_wr_data, DRAM_wr_status);
}

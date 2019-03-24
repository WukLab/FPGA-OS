/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/* System-level headers */
#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

#include "top.hpp"
#include "../include/rdma.h"

using namespace hls;

enum APP_RDMA_STATE {
	APP_RDMA_ETH_HEADER,
	APP_RDMA_APP_HEADER,
	APP_RDMA_INVALID_READ,
	APP_RDMA_APP_DATA,
};

#ifdef CONFIG_APP_RDMA_STAT
static unsigned long nr_requests = 0;
static inline void inc_nr_requests(void)
{
	nr_requests++;
}
static inline unsigned long get_nr_requests(void)
{
	return nr_requests;
}
#else
static inline void inc_nr_requests(void) { }
static inline unsigned long get_nr_requests(void) { return 0; }
#endif

//#define CONFIG_RDMA_LOOPBACK_TEST
#ifdef CONFIG_RDMA_LOOPBACK_TEST
# define RDM_FPGA_TEST_APP_ID	(1)
#endif

static void handle_error(void)
{

}

enum handle_read_state {
	READ_IDLE,
	READ_HDR_ETH,
	READ_HDR_APP,
	READ_DATAFLOW
};

/*
 * Reply packet format:
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   | (opcode: REPLY_READ)
 * 	64B |          Data         | (read data if any)
 * 	...
 *
 * Both address and length must be 64B aligned
 */
#define MAX_READ_LOOPS	4
#define MAX_READ_LENGTH	(MAX_READ_LOOPS * NR_BYTES_AXIS_512)
template <int _unused>
static void handle_read(stream<struct request> *req_s,
			stream<struct net_axis_512> *to_net,
			ap_uint<512> *dram)
{
#if 1
#pragma HLS PIPELINE

	struct net_axis_512 tmp;

	static enum handle_read_state read_state = READ_IDLE;
	static unsigned int offset = 0;
	static unsigned int start_index = 0;
	static unsigned long address = 0, length = 0;
	static struct request req;

	switch (read_state) {
	case READ_IDLE:
		if (req_s->empty())
			return;
		req = req_s->read();

		length = req.length;
		address = req.address;

		start_index = req.address / NR_BYTES_AXIS_512;
		offset = 0;

		read_state = READ_HDR_ETH;
		break;
	case READ_HDR_ETH:
#ifdef CONFIG_RDMA_LOOPBACK_TEST
		/* loopback test, output to rdm_fpga_test */
		set_app_id(&(req.eth_header), RDM_FPGA_TEST_APP_ID);
#endif

		to_net->write(req.eth_header);

		read_state = READ_HDR_APP;
		break;
	case READ_HDR_APP:
		if ((length == 0) || (address % NR_BYTES_AXIS_512 != 0) ||
		    (length % NR_BYTES_AXIS_512) != 0) {
			req.app_header.data(7, 0)= APP_RDMA_OPCODE_REPLY_READ_ERROR;
			req.app_header.last = 1;
			to_net->write(req.app_header);

			read_state = READ_IDLE;
		} else {
			req.app_header.data(7, 0)= APP_RDMA_OPCODE_REPLY_READ;
			req.app_header.last = 0;
			to_net->write(req.app_header);

			read_state = READ_DATAFLOW;
		}
		break;
	case READ_DATAFLOW:
#ifdef CONFIG_RDMA_LOOPBACK_TEST
		tmp.data = offset + 1;
#else
		tmp.data = dram[start_index + offset];
#endif
		tmp.keep(NR_BYTES_AXIS_512 - 1, 0) = 0xffffffffffffffff;
		offset++;

		if (length == NR_BYTES_AXIS_512)
			tmp.last = 1;
		else {
			tmp.last = 0;
			length = length - NR_BYTES_AXIS_512;
		}
		to_net->write(tmp);

		if (tmp.last == 1)
			read_state = READ_IDLE;
		break;
	};
#endif
}

static inline void narrow_memcpy_to_axi_512(ap_uint<512> &to, ap_uint<512> &from, int n)
{
#pragma HLS INLINE

	switch (n) {
	case 1:		to(7, 0)	= from(7, 0);		break;
	case 2:		to(15, 0)	= from(15, 0);		break;
	case 3:		to(23, 0)	= from(23, 0);		break;
	case 4:		to(31, 0)	= from(31, 0);		break;
	case 5:		to(39, 0)	= from(39, 0);		break;
	case 6:		to(47, 0)	= from(47, 0);		break;
	case 7:		to(55, 0)	= from(55, 0);		break;
	case 8:		to(63, 0)	= from(63, 0);		break;
	case 9:		to(71, 0)	= from(71, 0);		break;
	case 10:	to(79, 0)	= from(79, 0);		break;
	case 11:	to(87, 0)	= from(87, 0);		break;
	case 12:	to(95, 0)	= from(95, 0);		break;
	case 13:	to(103, 0)	= from(103, 0);		break;
	case 14:	to(111, 0)	= from(111, 0);		break;
	case 15:	to(119, 0)	= from(119, 0);		break;
	default:
		// TODO
		to(n * 8 - 1, 0) = from(n * 8 - 1, 0);
		break;
	}
}

enum handle_write_state {
	WRITE_IDLE,
	WRITE_DATAFLOW
};

/*
 * Both address and length must be 64B aligned.
 * We can detect unaligned address, but not unaligned length.
 * Length will be aligned UP to 64B. For example, if a user
 * tries to write 65B, it eventually will write 128B.
 */
static void handle_write(stream<struct request> *req_s,
			 stream<struct net_axis_512> *data_s,
			 ap_uint<512> *dram)
{
#pragma HLS PIPELINE II=1

	unsigned int index;
	struct request req;
	struct net_axis_512 data;

	static long nr_remain;
	static unsigned int start_index = 0;
	static unsigned int offset = 0;
	static unsigned long address, length;
	static enum handle_write_state write_state = WRITE_IDLE;

	switch (write_state) {
	case WRITE_IDLE:
		if (req_s->empty())
			return;
		req = req_s->read();

		length = req.length;
		address = req.address;
		start_index = req.address / NR_BYTES_AXIS_512;
		offset = 0;

		if (address % NR_BYTES_AXIS_512 == 0)
			write_state = WRITE_DATAFLOW;
		break;
	case WRITE_DATAFLOW:
		if (data_s->empty())
			return;
		data = data_s->read();

		index = start_index + offset;
		offset++;

#ifndef CONFIG_RDMA_LOOPBACK_TEST
		dram[index] = data.data;
#endif
		if (data.last)
			write_state = WRITE_IDLE;
		break;
	};
}

/*
 * Incoming Packet
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */
static void parser(stream<struct net_axis_512> *from_net,
		   stream<struct request> *s_req_read,
		   stream<struct request> *s_req_write,
		   stream<struct net_axis_512> *s_data_write)
{
#pragma HLS PIPELINE II=1

	static enum APP_RDMA_STATE app_state = APP_RDMA_ETH_HEADER;
	static struct request req;
	static struct net_axis_512 eth_header, app_header;

	char opcode;
	struct net_axis_512 current;

	switch (app_state) {
	case APP_RDMA_ETH_HEADER:
		if (from_net->empty())
			break;
		current = from_net->read();
		eth_header = current;

		inc_nr_requests();
		app_state = APP_RDMA_APP_HEADER;
		break;
	case APP_RDMA_APP_HEADER:
		if (from_net->empty())
			break;
		current = from_net->read();
		app_header = current;

		/* Extract APP header info */
		opcode		= app_header.data(7, 0);
		req.address	= app_header.data(71, 8);
		req.length	= app_header.data(135, 72);

		req.eth_header = eth_header;
		req.app_header = app_header;

		switch (opcode) {
		case APP_RDMA_OPCODE_READ:
			if (app_header.last) {
				s_req_read->write(req);
				app_state = APP_RDMA_ETH_HEADER;
			} else
				app_state = APP_RDMA_INVALID_READ;
			break;
		default:
			/* Otherwise to other OPCODE handlers */
			app_state = APP_RDMA_APP_DATA;
			break;
		}
		break;
	case APP_RDMA_INVALID_READ:
		/*
		 * This state is here to skip extra units
		 * from a READ request. A read only has two units.
		 * Instead of handling this case within IDLE, we simply skip
		 * all these invalid units.
		 */
		if (from_net->empty())
			break;
		current = from_net->read();
		if (current.last)
			app_state = APP_RDMA_ETH_HEADER;
		break;
	case APP_RDMA_APP_DATA:
		if (from_net->empty())
			break;
		current = from_net->read();

		switch (opcode) {
		case APP_RDMA_OPCODE_WRITE:
			s_req_write->write(req);
			s_data_write->write(current);
			break;
		default:
			/*
			 * Ignore all other opcodes
			 * Go back to IDLE state
			 */
			app_state = APP_RDMA_ETH_HEADER;
			break;
		};

		if (current.last)
			app_state = APP_RDMA_ETH_HEADER;
		break;
	};
}

static void merger(stream<struct net_axis_512> *to_net,
		   stream<struct net_axis_512> *from_read)
{
	struct net_axis_512 current;

	if (from_read->empty())
		return;

	current = from_read->read();
	to_net->write(current);
}

void app_rdma(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net,
	      ap_uint<512> *dram_in, ap_uint<512> *dram_out)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATAFLOW

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE m_axi depth=64 port=dram_in  bundle=MEM  offset=direct
#pragma HLS INTERFACE m_axi depth=64 port=dram_out bundle=MEM  offset=direct

	static stream<struct request> s_req_read("s_req_read");
	static stream<struct request> s_req_write("s_req_write");
	static stream<struct net_axis_512> s_data_write("s_data_write");
	static stream<struct net_axis_512> s_data_read("s_data_read");
#pragma HLS STREAM variable=s_req_read depth=2 dim=1
#pragma HLS STREAM variable=s_req_write depth=2 dim=1
#pragma HLS STREAM variable=s_data_read depth=2 dim=1
#pragma HLS STREAM variable=s_data_write depth=2 dim=1

	parser(from_net, &s_req_read, &s_req_write, &s_data_write);

	handle_read<1>(&s_req_read, &s_data_read, dram_in);
	handle_write(&s_req_write, &s_data_write, dram_out);

	merger(to_net, &s_data_read);
}

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

/* Saved states */
struct net_axis_512 eth_header, app_header;

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

static void handle_error(void)
{

}

/*
 * Reply packet format:
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   | (opcode: REPLY_READ)
 * 	64B |          Data         | (read data if any)
 * 	...
 */
#define MAX_READ_LOOPS	4
#define MAX_READ_LENGTH	(MAX_READ_LOOPS * NR_BYTES_AXIS_512)
static void handle_read(unsigned long address, unsigned long length,
			stream<struct net_axis_512> *to_net,
			ap_uint<512> *dram)
{
#pragma HLS PIPELINE
#pragma HLS INLINE

	struct net_axis_512 tmp;
	ap_uint<512> cache;
	unsigned int offset = 0, index;

	/* Output Eth/IP/UDP/Lego header */
	to_net->write(eth_header);

	/*
	 * FIXME
	 * Now assume the starting address is 64B aligned
	 */
	if ((length == 0) || (address % NR_BYTES_AXIS_512 != 0)) {
		app_header.data(7, 0)= APP_RDMA_OPCODE_REPLY_READ_ERROR;
		app_header.last = 1;
		to_net->write(app_header);
		return;
	} else {
		app_header.data(7, 0)= APP_RDMA_OPCODE_REPLY_READ;
		app_header.last = 0;
		to_net->write(app_header);
	}

	/* Sanity check */
	if (length > MAX_READ_LENGTH)
		length = MAX_READ_LENGTH;

	index = address / NR_BYTES_AXIS_512;
	while (length) {
	/* Set max according the above MAX_READ_LOOPS */
	#pragma HLS LOOP_TRIPCOUNT min=1 max=4 avg=1

		tmp.keep(NR_BYTES_AXIS_512 - 1, 0) = 0xffffffffffffffff;
		cache = dram[index + offset];

		/* Now decice which part should stay */
		if (length >= NR_BYTES_AXIS_512) {
			tmp.data = cache;
			if (length > NR_BYTES_AXIS_512) {
				tmp.last = 0;
				length = length - NR_BYTES_AXIS_512;
			} else
				tmp.last = 1;
		} else {
			int end = length * 8 - 1;
			tmp.data = 0;
			tmp.data(end, 0) = cache(end, 0);
			tmp.keep(NR_BYTES_AXIS_512 - 1, length) = 0;
			tmp.last = 1;
		}
		to_net->write(tmp);
		offset++;

		if (tmp.last == 1)
			break;
	}
}

/*
 * @address: dstination adress
 * @length: in bytes
 *
 * This function can only serve one WRITE request at one time.
 * And different from handle_read(), this function will have a minimum
 * state: nr_written. Because this function will be repeatly invoked
 * during data streaming phase.
 *
 */
static void handle_write(unsigned long address, unsigned long length,
			 struct net_axis_512 axis_data,
			 ap_uint<512> *dram)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE
	static unsigned int offset = 0;
	static unsigned int nr_written = 0;
	unsigned int index;
	long nr_remain;

 	/*
	 * FIXME
	 * Assume the starting address is always 64B aligned.
	 * Otherwise skip.
	 */
	if (address % NR_BYTES_AXIS_512)
		return;

	index = (address / NR_BYTES_AXIS_512) + offset;
	nr_remain = length - nr_written;

	if (nr_remain >= NR_BYTES_AXIS_512) {
		dram[index] = axis_data.data;
		offset++;
		nr_written = offset * NR_BYTES_AXIS_512;
	} else {
		int end;

		end = nr_remain * 8 - 1;
		dram[index](end, 0) = axis_data.data(end, 0);
	}

	if (axis_data.last)
		offset = 0;
}

/*
 * Packet
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */
void app_rdma(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net,
	      ap_uint<512> *dram)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS PIPELINE

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=off

	static enum APP_RDMA_STATE state = APP_RDMA_ETH_HEADER;
	static char opcode;
	static unsigned long address, length;

	struct net_axis_512 current;

	switch (state) {
	case APP_RDMA_ETH_HEADER:
		if (from_net->empty())
			break;
		current = from_net->read();
		eth_header = current;

		inc_nr_requests();
		state = APP_RDMA_APP_HEADER;
		break;
	case APP_RDMA_APP_HEADER:
		if (from_net->empty())
			break;
		current = from_net->read();
		app_header = current;

		/* Extract APP header info */
		opcode	= app_header.data(7, 0);
		address	= app_header.data(71, 8);
		length	= app_header.data(135, 72);

		/*
		 * Handle read related requests
		 *
		 * FIXME:
		 * Reads currently are blocking requests.
		 * We are not taking any new data in while handling reads.
		 */
		switch (opcode) {
		case APP_RDMA_OPCODE_READ:
			if (app_header.last) {
				handle_read(address, length, to_net, dram);
				state = APP_RDMA_ETH_HEADER;
			} else
				state = APP_RDMA_INVALID_READ;
			break;
		default:
			/* Otherwise to other OPCODE handlers */
			state = APP_RDMA_APP_DATA;
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
			state = APP_RDMA_ETH_HEADER;
		break;
	case APP_RDMA_APP_DATA:
		if (from_net->empty())
			break;
		current = from_net->read();

		switch (opcode) {
		case APP_RDMA_OPCODE_WRITE:
			handle_write(address, length, current, dram);
			break;
		default:
			/*
			 * Ignore all other opcodes
			 * Go back to IDLE state
			 */
			state = APP_RDMA_ETH_HEADER;
			break;
		};

		if (current.last)
			state = APP_RDMA_ETH_HEADER;
		break;
	};
}

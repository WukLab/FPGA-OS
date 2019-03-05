/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/* System-level headers */
#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>

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
 * 	64B |          Data         | (read data)
 * 	...
 */
#define MAX_READ_LENGTH	1024
static void handle_read(unsigned long address, unsigned long length,
			stream<struct net_axis_512> *to_net, char *dram)
{
#pragma HLS PIPELINE
	int nr_read, i;
	struct net_axis_512 tmp;

	/* Output headers */
	to_net->write(eth_header);

	/*
	 * In the original packet, the app_header
	 * is the last unit thus has the LAST asserted.
	 * If length is valid, clear it.
	 */
	if (length > 0)
		app_header.last = 0;
	else
		app_header.last = 1;
	app_header.data(7, 0)= APP_RDMA_OPCODE_REPLY_READ;
	to_net->write(app_header);

	/* Output data */
	nr_read = 0;
	if (length > MAX_READ_LENGTH)
		length = MAX_READ_LENGTH;

	while (nr_read < length) {
#pragma HLS LOOP_TRIPCOUNT min=1 max=1024 avg=128

		tmp.data = 0;
		for (i = 0; i < NR_BYTES_AXIS_512; i++) {
#pragma HLS LOOP_TRIPCOUNT min=64 max=64 avg=64
			int start, end;

			start = i * NR_BITS_PER_BYTE;
			end = (i + 1) * NR_BITS_PER_BYTE - 1;

#ifdef __SYNTHESIS__
			dram = dram + (address + nr_read);
#else
			dram = (char *)(address + nr_read);
#endif
			tmp.data(end, start) = *dram;

			nr_read++;

			/* Last unit case (can be partial )*/
			if (nr_read == length)
				break;
		}

		if (nr_read == length)
			tmp.last = 1;
		else
			tmp.last = 0;

		to_net->write(tmp);
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
 */
static void handle_write(unsigned long address, unsigned long length,
			 struct net_axis_512 axis_data, char *dram)
{
#pragma HLS PIPELINE
	static unsigned long nr_written = 0;
	int i;
	char *dst;

	/*
	 * FIXME
	 * 1) We leave app BUG here: length is not checked.
	 * Leave this during development phase.
	 *
	 * 2) And should check TKEEP here!
	 */
	for (i = 0; i < NR_BYTES_AXIS_512; i++) {
		int start, end;

		start = i * NR_BITS_PER_BYTE;
		end = (i + 1) * NR_BITS_PER_BYTE - 1;

#ifdef __SYNTHESIS__
		dram = dram + (address + nr_written);
#else
		dram = (char *)(address + nr_written);
#endif
		*dram = axis_data.data(end, start);

		nr_written++;
	}

	/* Reset states if last unit */
	if (axis_data.last)
		nr_written = 0;
}

/*
 * Packet
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */
#if 1
void app_rdma(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net, char *dram)
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
#else

void app_rdma(hls::stream<struct net_axis_512> *from_net,
	      hls::stream<struct net_axis_512> *to_net, char *dram)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS PIPELINE

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=off
	struct net_axis_512 tmp = {0, 0, 0};

	if (from_net->empty())
		return;

	tmp = from_net->read();
	tmp.data(7,0) = 0xff;
	to_net->write(tmp);
	*dram = 0;
}
#endif

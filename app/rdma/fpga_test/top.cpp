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

#define DST_APP_ID	(0)
#define MY_APP_ID	(1)


int nr_read = 1;

struct net_axis_512 eth_header;
struct net_axis_512 app_header_read;
struct net_axis_512 app_header_write;

/*
 * Packet Format
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */

void send_write(stream<struct net_axis_512> *out,
		unsigned long address, unsigned long length)
{

}

void send_read(stream<struct net_axis_512> *out,
		unsigned long address, unsigned long length)
{
#pragma HLS PIPELINE

	out->write(eth_header);

	set_hdr_address(&app_header_read, address);
	set_hdr_length(&app_header_read, length);
	out->write(app_header_read);
}

void __app_rdma_test(hls::stream<struct net_axis_512> *from_net,
		     hls::stream<struct net_axis_512> *to_net,
		     int *dram)
{
	unsigned long address, length;

	/*
	 * The ethernet header is shared by both read and write test.
	 * The only things matters in loopback testing is destination app ID.
	 */
	eth_header.last = 0;
	eth_header.user = 0;
	eth_header.keep = 0xffffffffffffffff;
	set_app_id(&eth_header, DST_APP_ID);

	/* Read request only has two units */
	app_header_read.last = 1;
	app_header_read.user = 0;
	app_header_read.keep = 0xffffffffffffffff;
	set_hdr_opcode(&app_header_read, APP_RDMA_OPCODE_READ);

	/* Write request must have more than two units */
	app_header_write.last = 0;
	app_header_write.user = 0;
	app_header_write.keep = 0xffffffffffffffff;
	set_hdr_opcode(&app_header_write, APP_RDMA_OPCODE_WRITE);

	if (nr_read) {
		address = 64;
		length = 128;
		send_read(to_net, address, length);
		nr_read--;
		*dram = 0x66881122;
	}

	if (!from_net->empty()) {
		struct net_axis_512 tmp;
		tmp = from_net->read();
	}
}

void counter(unsigned long *tsc)
{
#pragma HLS PROTOCOL fixed
#pragma HLS LATENCY min=0 max=0
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INLINE
#pragma HLS PIPELINE off
	static unsigned long local_tsc = 0;

	*tsc = local_tsc;
	local_tsc++;
}

void app_rdma_test(hls::stream<struct net_axis_512> *from_net,
		   hls::stream<struct net_axis_512> *to_net,
		   int *dram)
{
#pragma HLS INTERFACE ap_ctrl_hs port=return

#pragma HLS INTERFACE m_axi depth=256 port=dram offset=off
#pragma HLS INTERFACE axis register both port=from_net
#pragma HLS INTERFACE axis register both port=to_net
#pragma HLS DATAFLOW

	unsigned long tsc = 0;

	__app_rdma_test(from_net, to_net, dram);
	counter(&tsc);
}

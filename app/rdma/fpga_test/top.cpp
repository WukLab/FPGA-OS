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

#define BASE_ADDRESS	(0x100000)
#define NR_ROUNDS	(1)
#define NR_DIFF_LENGTH	(32)
static unsigned long test_length[NR_DIFF_LENGTH] = {64, 128, 256, 512, 1024, 2048, 4096};
static unsigned long acc_tsc_read[NR_DIFF_LENGTH];
static unsigned long acc_tsc_write[NR_DIFF_LENGTH];

static struct app_rdma_stats cached_stats = {0, 0};

static inline void inc_nr_read(void)
{
#pragma HLS INLINE
	cached_stats.nr_read++;
}

static inline void inc_nr_write(void)
{
#pragma HLS INLINE
	cached_stats.nr_write++;
}

/*
 * Packet Format
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */

void send_write(stream<struct net_axis_512> *from_net, stream<struct net_axis_512> *to_net,
		unsigned long address, unsigned long length, volatile unsigned long *tsc,
		int index)
{
#pragma HLS PIPELINE
#pragma INLINE
	unsigned long start_tsc, end_tsc;
	struct net_axis_512 current;
	unsigned long units;
	int i;

	start_tsc = *tsc;
	to_net->write(eth_header);

	set_hdr_address(&app_header_write, address);
	set_hdr_length(&app_header_write, length);
	to_net->write(app_header_write);

	units = length / NR_BYTES_AXIS_512;

	for (i = 0; i < units; i++) {
		current.keep = 0xffffffffffffffff;
		current.user = 0;
		current.data = i + 0x1;

		if (i == (units - 1))
			current.last = 1;
		else
			current.last = 0;
		to_net->write(current);
	}
	end_tsc = *tsc;

	acc_tsc_write[index] += (end_tsc - start_tsc);
}

void send_read(stream<struct net_axis_512> *from_net, stream<struct net_axis_512> *to_net,
	       unsigned long address, unsigned long length, volatile unsigned long *tsc,
	       int index)
{
#pragma HLS PIPELINE
#pragma INLINE

	unsigned long start_tsc, end_tsc;
	struct net_axis_512 current;

	to_net->write(eth_header);

	set_hdr_address(&app_header_read, address);
	set_hdr_length(&app_header_read, length);
	to_net->write(app_header_read);

	start_tsc = *tsc;
	while (1) {
		if (from_net->empty())
			continue;

		current = from_net->read();
		if (current.last == 1)
			break;
	}
	end_tsc = *tsc;

	acc_tsc_read[index] += (end_tsc - start_tsc);
}

void test_read(stream<struct net_axis_512> *from_net, stream<struct net_axis_512> *to_net,
	       unsigned long *dram, volatile unsigned long *tsc,
	       volatile struct app_rdma_stats *stats)
{
	unsigned long address, length;
	int i, j;

	address = BASE_ADDRESS;

	for (i = 0; i < NR_DIFF_LENGTH; i++) {
		if (test_length[i] == 0)
			continue;

		for (j = 0; j < NR_ROUNDS; j++) {
			inc_nr_read();
			stats->nr_read = cached_stats.nr_read;
			send_read(from_net, to_net, address, test_length[i], tsc, i);
		}
	}

#ifndef DISABLE_DRAM_ACCESS
	for (i = 0; i < NR_DIFF_LENGTH; i++)
		dram[i] = acc_tsc_read[i];
#endif
}

void test_write(stream<struct net_axis_512> *from_net, stream<struct net_axis_512> *to_net,
		unsigned long *dram, volatile unsigned long *tsc,
		volatile struct app_rdma_stats *stats)
{
	unsigned long address, length;
	int i, j;

	address = BASE_ADDRESS;

	for (i = 0; i < NR_DIFF_LENGTH; i++) {
		if (test_length[i] == 0)
			continue;

		for (j = 0; j < NR_ROUNDS; j++) {
			inc_nr_write();
			stats->nr_write = cached_stats.nr_write;
			send_write(from_net, to_net, address, test_length[i], tsc, i);
		}
	}

#ifndef DISABLE_DRAM_ACCESS
	/* First portion is used by read stats */
	for (i = 0; i < NR_DIFF_LENGTH; i++)
		dram[i + NR_DIFF_LENGTH] = acc_tsc_write[i];
#endif
}

void app_rdma_test(hls::stream<struct net_axis_512> *from_net,
		   hls::stream<struct net_axis_512> *to_net,
		   unsigned long *dram, volatile unsigned long *tsc,
		   volatile struct app_rdma_stats *stats,
		   volatile unsigned int *test_state)
{
#pragma HLS INTERFACE ap_ctrl_hs port=return
#pragma HLS PIPELINE

#pragma HLS INTERFACE axis register both port=from_net
#pragma HLS INTERFACE axis register both port=to_net
#pragma HLS INTERFACE m_axi depth=256 port=dram offset=off
#pragma HLS INTERFACE ap_none port=tsc
#pragma HLS INTERFACE ap_none port=stats
#pragma HLS INTERFACE ap_none port=test_state

	static bool tested = false;
	int i;

	if (tested == true) {
		stats->nr_read = cached_stats.nr_read;
		stats->nr_write = cached_stats.nr_write;
		return;
	}

	for (i = 0; i < NR_DIFF_LENGTH; i++) {
		acc_tsc_read[i] = 0;
		acc_tsc_write[i] = 0;
	}

	/*
	 * The ethernet header is shared by both read and write test.
	 * The only things matters in loopback testing is destination app ID.
	 */
	eth_header.last = 0;
	eth_header.user = 0;
	eth_header.keep = 0xffffffffffffffff;
	eth_header.data(7, 0) = 0x66;
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

	*test_state = 1;
	test_read(from_net, to_net, dram, tsc, stats);
	*test_state = 2;
	test_write(from_net, to_net, dram, tsc, stats);
	*test_state = 3;

	tested = true;
}

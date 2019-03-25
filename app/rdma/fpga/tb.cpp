/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>

#include <stdio.h>
#include <stdlib.h>

#include "top.hpp"
#include "../include/rdma.h"

using namespace hls;

/* must >= 2 */
#define NR_UNITS_PER_PKT	(4)
#define NR_PACKETS		(5)
#define BUF_SIZE		(1024)

int main(void)
{
	char *dram;
	int i, j, k;
	struct net_axis_512 tmp;
	stream<struct net_axis_512> input, output;
	struct app_rdma_stats stats = {0, 0};

	dram = (char *)malloc(BUF_SIZE);
	if (!dram) {
		printf("Unable to malloc\n");
		return -1;
	}
	memset(dram, 0x0, BUF_SIZE);

	if ((NR_UNITS_PER_PKT * NR_BYTES_AXIS_512) > BUF_SIZE) {
		printf("Message size larger than buffer size, write may overflow\n");
		exit(-1);
	}
	if (NR_UNITS_PER_PKT < 2) {
		printf("Must have at least 2 units\n");
		exit(-1);
	}

	/*
	 * Packet
	 * 	64B | Eth | IP | UDP | Lego |
	 * 	64B | App header |    pad   |
	 * 	64B |          Data         | (if write)
	 * 	...
	 * 	N B |          Data         |
	 */
	for (i = 0; i < NR_PACKETS; i++) {
next_pkt:
		for (j = 0; j < NR_UNITS_PER_PKT; j++) {
			tmp.last = 0;
			tmp.data = 0;
			tmp.keep = 0;

			for (k = 0; k < NR_BYTES_AXIS_512; k++) {
				int start, end;

				start = k * NR_BITS_PER_BYTE;
				end = (k + 1) * NR_BITS_PER_BYTE - 1;

				tmp.data(end, start) = k + 1;
				tmp.keep(k, k) = 1;
			}

			/* The first packet: WRITE */
			if (i != 1 && i != 2) {
				/* The first unit is eth/ip/udp/lego header */
				if (j == 0) {
					tmp.data(47, 0) = 0xAABBCCDDEEFF;
				}
				/* The second unit is app header */
				if (j == 1) {
					tmp.data(7, 0) = APP_RDMA_OPCODE_WRITE;
					tmp.data(71, 8) = i * 64 *2;
					tmp.data(135, 72) = 6;
					printf("write %llu\n", i * 64 *2);
				}
			}
			/* The second packet: READ */
			if (i == 1 || i == 2) {
				/* The first unit is eth/ip/udp/lego header */
				if (j == 0) {
					tmp.data(47, 0) = 0xAABBCCDDEEFF;
				} else if (j == 1) {
				/* The second unit is app header */
					tmp.data(7, 0) = APP_RDMA_OPCODE_READ;
					tmp.data(71, 8) = 0;
					tmp.data(135, 72) = 64;
					printf("read %llu\n", i * 64 *2);

					/* Read should only have two units */
					tmp.last = 1;
					input.write(tmp);
					break;
				} else
					exit(-1);
			}

			/* Last unit of the pkt */
			if (j == (NR_UNITS_PER_PKT - 1))
				tmp.last = 1;
			else
				tmp.last = 0;
			input.write(tmp);
		}
	}

	printf("before stat: %d %d\n", stats.nr_read, stats.nr_write);
	for (i = 0; i < NR_PACKETS * NR_UNITS_PER_PKT * 100; i++)
		app_rdma(&input, &output, (ap_uint<512> *)dram, (ap_uint<512> *)dram,
			 &stats);

	printf("after stat: %d %d\n", stats.nr_read, stats.nr_write);

	/*
	 * Verilog results
	 * - Write: Check buf content
	 * - Read: check output stream content
	 */

#define NR_BYTES_PER_LINE	(64)
	printf("DRAM Content:\n");
	for (i = 0; i < BUF_SIZE; i++) {
		if (i % NR_BYTES_PER_LINE == 0)
			printf("[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
		printf("%02x ", dram[i]);
		if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
			printf("\n");
	}

	printf("Read Content: \n");

	i = j = 0;
	while (!output.empty()) {
		tmp = output.read();
		printf("unit[%d] last=%d keep=%#llx\n", i, tmp.last.to_uint(), tmp.keep.to_ulong());
		for (j = 0; j < NR_BYTES_AXIS_512; j++) {
			int start, end;
			unsigned char c;

			start = j * NR_BITS_PER_BYTE;
			end = (j + 1) * NR_BITS_PER_BYTE - 1;
			c = tmp.data(end, start).to_uint();

			if (i % NR_BYTES_PER_LINE == 0)
				printf("[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
			printf("%02x ", c);
			if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
				printf("\n");
			i++;
		}
	}
}

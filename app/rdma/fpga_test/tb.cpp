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

/*
 * Packet
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */
int main(void)
{
	int *dram;
	int i, j, k;
	struct net_axis_512 tmp;
	stream<struct net_axis_512> input, output;

	dram = (int *)malloc(10000);

	for (i = 0; i < 6; i++)
		app_rdma_test(&input, &output, dram);

	/*
	 * Verilog results
	 * - Write: Check buf content
	 * - Read: check output stream content
	 */
#define NR_BYTES_PER_LINE	(64)
	printf("Network output Content: \n");

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

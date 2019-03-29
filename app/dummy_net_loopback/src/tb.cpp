/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <stdio.h>
#include <stdlib.h>
#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

#include "top.hpp"

using namespace hls;

void net_loopback(hls::stream<struct net_axis_512> *from_net,
		  hls::stream<struct net_axis_512> *to_net,
		  volatile unsigned long *tsc,
		  volatile struct lp_stats *stats,
		  bool has_eth_lego_header);

#define NR_BYTES_PER_LINE 64

int main(void)
{
	stream<struct net_axis_512> input, output;
	struct lp_stats stats;
	unsigned long tsc;
	bool has_eth_lego_header;
	int i, j, k;
	struct net_axis_512 tmp;

	for (i = 1; i <= NR_MAX_UNITS; i++) {
		for (j = 0; j < NR_TESTS_PER_LEN; j++) {
			for (k = 0; k < i; k++) {
				tmp.data = k + 0x101;
				tmp.keep = 0xffffffffffffffff;
				if (k == (i - 1))
					tmp.last = 1;
				else
					tmp.last = 0;

				input.write(tmp);
			}
		}
	}

	net_loopback(&input, &output, &tsc, &stats, has_eth_lego_header);

	i = j = k = 0;
	while (!output.empty()) {
		tmp = output.read();

		printf("\n    Unit[%d] last=%d keep=%#llx\n", k, tmp.last.to_uint(), tmp.keep.to_ulong());
		for (j = 0; j < NR_BYTES_AXIS_512; j++) {
			int start, end;
			unsigned char c;

			start = j * 8;
			end = (j + 1) * 8 - 1;
			c = tmp.data(end, start).to_uint();

			if (i % NR_BYTES_PER_LINE == 0)
				printf("\t[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
			printf("%02x ", c);
			if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
				printf("\n");
			i++;
		}
		k++;
	}
}

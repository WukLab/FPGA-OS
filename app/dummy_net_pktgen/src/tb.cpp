/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <stdio.h>
#include <stdlib.h>
#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

using namespace hls;

void dummy_net_pktgen(hls::stream<struct net_axis_512> *to_net,
		      ap_uint<1> enabled);

#define N 40

int main(void)
{
	stream<struct net_axis_512> out;
	struct net_axis_512 current;
	ap_uint<1> enabled;
	int i;

	enabled = 0;
	for (i = 0; i < N; i++)
		dummy_net_pktgen(&out, enabled);

	if (!out.empty())
		printf("BUG: enabled=0, but there is output.\n");

	enabled = 1;
	for (i = 0; i < N; i++)
		dummy_net_pktgen(&out, enabled);

	i = 0;
	if (out.empty())
		printf("BUG: enable=1, but no output.");
	while (!out.empty()) {
		current = out.read();

		printf("[%d] data=%lld last=%u\n", i, current.data.to_long(),
			current.last.to_uint());
	}
}

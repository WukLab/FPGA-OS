/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_512.hpp"

using namespace hls;

#define N 3

int main(void)
{
	stream<struct net_axis_512> input[NR_SYSNET_TX_PORTS], output;
	struct net_axis_512 tmp;
	int i, j;

	for (j = 0; j < NR_SYSNET_TX_PORTS; j++) {
		for (i = 0; i < 3; i++) {
			;
		}
	}
}
